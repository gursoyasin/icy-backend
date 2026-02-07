const prisma = require('../config/prisma');

exports.getAppointments = async (req, res, next) => {
    try {
        // Logic: Admin/Staff -> See All in Clinic/Branch. Doctor -> See Own.
        let filter = {
            clinicId: req.user.clinicId // Strict Isolation
        };

        // 2. Role Restriction
        if (req.user.role === 'doctor') {
            filter.doctorId = req.user.id;
        } else if (req.user.role !== 'admin') {
            // Staff sees only their branch
            filter.branchId = req.user.branchId;
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
exports.createAppointment = async (req, res, next) => {
    try {
        const { patientId, doctorId, date, type, status, graftCount } = req.body;

        // 1. Conflict Prevention logic
        // Check if doctor has an appointment at this exact time that is NOT cancelled
        const appointmentDate = new Date(date);
        const conflict = await prisma.appointment.findFirst({
            where: {
                clinicId: req.user.clinicId, // Strict
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
                doctorId,
                clinicId: req.user.clinicId,
                branchId: req.user.branchId
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

        res.json(appointment);
    } catch (e) { next(e); }
};

exports.updateAppointmentStatus = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { status } = req.body; // 'arrived', 'no-show', 'completed', 'cancelled'

        // Verify Ownership First
        const current = await prisma.appointment.findFirst({
            where: { id, clinicId: req.user.clinicId }
        });
        if (!current) return res.status(404).json({ error: "Appointment not found" });

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

        // Verify Ownership
        const current = await prisma.appointment.findFirst({
            where: { id, clinicId: req.user.clinicId }
        });
        if (!current) return res.status(404).json({ error: "Appointment not found" });

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
// NOTE: Public booking is tricky with SaaS. The link must belong to a tenant.
// We assume BookingLink -> Doctor -> Clinic hierarchy.
exports.getPublicBookingSlot = async (req, res, next) => {
    try {
        const link = await prisma.bookingLink.findUnique({
            where: { slug: req.params.slug }
        });
        if (!link || !link.isActive) return res.status(404).json({ error: "Link not found" });

        const doctorId = link.doctorId;
        const doctor = await prisma.user.findUnique({ where: { id: doctorId } });
        if (!doctor) return res.status(404).json({ error: "Doctor not found" });

        const clinicId = doctor.clinicId;

        // 1. Fetch Doctor's Schedule for next 7 days
        const start = new Date();
        const end = new Date();
        end.setDate(end.getDate() + 7);

        const busySlots = await prisma.appointment.findMany({
            where: {
                clinicId: clinicId, // SaaS Scope
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

        // Find Doctor and their Clinic
        const doctor = await prisma.user.findUnique({ where: { id: link.doctorId }, include: { branch: true } });
        if (!doctor) return res.status(404).json({ error: "Doctor invalid" });

        const clinicId = doctor.clinicId || doctor.branch?.clinicId;

        // 1. Create/Find Patient (Upsert by phone within Clinic)
        // Note: Public booking might need to be careful with upserts to not expose info.
        // For now, we Create or Find.

        let patient = await prisma.patient.findFirst({
            where: { clinicId, phoneNumber: phone }
        });

        if (!patient) {
            patient = await prisma.patient.create({
                data: {
                    fullName: patientName,
                    phoneNumber: phone,
                    status: 'lead',
                    notes: 'Online Booking',
                    clinicId: clinicId,
                    branchId: doctor.branchId
                }
            });
        }

        // 2. Create Appointment
        const appointment = await prisma.appointment.create({
            data: {
                date: new Date(date),
                type: 'Online Consultation',
                status: 'scheduled',
                doctorId: link.doctorId,
                patientId: patient.id,
                clinicId: clinicId,
                branchId: doctor.branchId
            }
        });

        res.json(appointment);
    } catch (e) { next(e); }
};
