const prisma = require('../config/prisma');

exports.getAppointments = async (req, res, next) => {
    try {
        // Logic: Admin/Staff -> See All in Clinic. Doctor -> See Own.
        let filter = {};

        // 1. STRICT MULTI-TENANCY: Clinic Isolation
        filter.patient = {
            branch: { clinicId: req.user.clinicId }
        };

        // 2. Role Restriction
        if (req.user.role === 'doctor') {
            filter.doctorId = req.user.id;
        }

        const appointments = await prisma.appointment.findMany({
            where: filter,
            include: { patient: true },
            orderBy: { date: 'asc' }
        });

        const mapped = appointments.map(a => ({
            id: a.id,
            patientId: a.patientId,
            date: a.date,
            type: a.type,
            status: a.status,
            patientName: a.patient.fullName,
            doctorId: a.doctorId,
            graftCount: a.graftCount
        }));

        res.json(mapped);
    } catch (e) { next(e); }
};



// Internal Create (with n8n trigger)
// Internal Create (with n8n trigger)
exports.createAppointment = async (req, res, next) => {
    try {
        const { patientId, doctorId, date, type, status, graftCount } = req.body;

        // 1. Conflict Prevention logic
        // Check if doctor has an appointment at this exact time that is NOT cancelled
        const appointmentDate = new Date(date);
        const conflict = await prisma.appointment.findFirst({
            where: {
                doctorId: doctorId,
                date: appointmentDate,
                status: { not: 'cancelled' }
            }
        });

        if (conflict) {
            return res.status(409).json({ error: "Bu saatte doktorun başka bir randevusu var." });
        }

        const appointment = await prisma.appointment.create({
            data: {
                date: appointmentDate,
                type,
                status: status || 'scheduled',
                graftCount: graftCount || 0,
                patientId,
                doctorId
            },
            include: {
                patient: true,
                doctor: true
            }
        });

        // 2. AUTOMATION FIRE: T-24h Reminder Workflow
        const automation = require('../services/automation');
        const messaging = require('../services/messaging');

        // Fire and Forget
        automation.triggerWorkflow('appointment_created', {
            appointmentId: appointment.id,
            patientName: appointment.patient.fullName,
            phoneNumber: appointment.patient.phoneNumber,
            date: appointment.date,
            doctorName: appointment.doctor.name
        });

        // Send Confirmation SMS/WhatsApp
        if (appointment.patient.phoneNumber) {
            const message = `Sn. ${appointment.patient.fullName}, ${appointmentDate.toLocaleString('tr-TR')} tarihli randevunuz oluşturulmuştur.`;
            // Defaulting to SMS for now, could be dynamic
            messaging.sendMessage('sms', appointment.patient.phoneNumber, message);
        }

        // PRD: Automation Trigger "Appointment Created"
        // (Redundant block removed)

        res.json(appointment);
    } catch (e) { next(e); }
};

exports.updateAppointmentStatus = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { status } = req.body; // 'arrived', 'no-show', 'completed', 'cancelled'

        const appointment = await prisma.appointment.update({
            where: { id },
            data: { status },
            include: { patient: true, doctor: true }
        });

        // PRD: Automation Trigger for Status Change
        if (['arrived', 'no-show', 'completed'].includes(status)) {
            const automation = require('../services/automation');
            const messaging = require('../services/messaging');

            automation.triggerWorkflow('appointment_status_changed', {
                event: status,
                appointmentId: appointment.id,
                patientName: appointment.patient.fullName,
                doctorName: appointment.doctor.name,
                patientPhone: appointment.patient.phoneNumber
            });

            if (status === 'completed' && appointment.patient.phoneNumber) {
                // Example: Post-op survey
                messaging.sendMessage('whatsapp', appointment.patient.phoneNumber, `Sn. ${appointment.patient.fullName}, işleminiz tamamlanmıştır. Geçmiş olsun dileklerimizle.`);
            }
        }

    } catch (e) { next(e); }
};

exports.cancelAppointment = async (req, res, next) => {
    try {
        const { id } = req.params;
        const appointment = await prisma.appointment.update({
            where: { id },
            data: { status: 'cancelled' },
            include: { patient: true, doctor: true }
        });

        // Automation
        const automation = require('../services/automation');
        automation.triggerWorkflow('appointment_status_changed', {
            event: 'cancelled',
            appointmentId: appointment.id,
            patientName: appointment.patient.fullName,
            doctorName: appointment.doctor.name,
            patientPhone: appointment.patient.phoneNumber
        });

        res.json(appointment);
    } catch (e) { next(e); }
};

// Public Booking Flows
exports.getPublicBookingSlot = async (req, res, next) => {
    try {
        const link = await prisma.bookingLink.findUnique({
            where: { slug: req.params.slug }
        });
        if (!link || !link.isActive) return res.status(404).json({ error: "Link not found" });

        const doctorId = link.doctorId;

        // 1. Fetch Doctor's Schedule for next 7 days
        const start = new Date();
        const end = new Date();
        end.setDate(end.getDate() + 7);

        const busySlots = await prisma.appointment.findMany({
            where: {
                doctorId: doctorId,
                status: { not: 'cancelled' },
                date: { gte: start, lte: end }
            },
            select: { date: true }
        });

        // Normalize busy dates to strings for easy lookup
        const busySet = new Set(busySlots.map(a => new Date(a.date).toISOString()));

        // 2. Generate Available Slots (09:00 - 17:00, 1 hour intervals)
        const availableSlots = [];
        for (let d = 0; d < 7; d++) {
            const day = new Date(start);
            day.setDate(day.getDate() + d);

            // Skip Sundays (0) if needed, currently allowing all

            for (let hour = 9; hour < 17; hour++) {
                const slot = new Date(day);
                slot.setHours(hour, 0, 0, 0);

                // Skip past times
                if (slot < new Date()) continue;

                // Check conflict
                if (!busySet.has(slot.toISOString())) {
                    availableSlots.push(slot);
                }
            }
        }

        res.json({ doctorId: link.doctorId, slots: availableSlots });
    } catch (e) { next(e); }
};

exports.createPublicBooking = async (req, res, next) => {
    try {
        const link = await prisma.bookingLink.findUnique({ where: { slug: req.params.slug } });
        if (!link) return res.status(404).json({ error: "Link invalid" });

        const { patientName, phone, date } = req.body;

        // 1. Create Lead Patient
        const patient = await prisma.patient.create({
            data: {
                fullName: patientName,
                phoneNumber: phone,
                status: 'lead',
                notes: 'Online Booking'
            }
        });

        // 2. Create Appointment
        const appointment = await prisma.appointment.create({
            data: {
                date: new Date(date),
                type: 'Online Consultation',
                status: 'scheduled',
                doctorId: link.doctorId,
                patientId: patient.id
            }
        });

        res.json(appointment);
    } catch (e) { next(e); }
};
