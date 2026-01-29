const prisma = require('../config/prisma');

exports.bookAppointment = async (req, res, next) => {
    try {
        const { fullName, phoneNumber, email, date, notes } = req.body;

        // 1. Find or Create Patient
        let patient = await prisma.patient.findFirst({
            where: {
                OR: [
                    { phoneNumber: phoneNumber },
                    { email: email }
                ]
            }
        });

        if (!patient) {
            patient = await prisma.patient.create({
                data: {
                    fullName,
                    phoneNumber,
                    email,
                    source: 'Web',
                    status: 'lead' // Flag as Lead until confirmed
                }
            });
        }

        // 2. Assign to a Doctor (Find first admin or doctor)
        // In a real app, the web form allows selecting a doctor.
        // For now, we assign to the first available admin/doctor user.
        const doctor = await prisma.user.findFirst({
            where: { role: { in: ['admin', 'doctor'] } }
        });

        if (!doctor) {
            throw new Error("Sistemde randevu alabilecek doktor bulunamadı.");
        }

        // 3. Create Appointment
        // Parse the local date string to a Date object.
        // If date string is "2026-01-29T14:30", new Date() usually creates it in local time or UTC depending on environment.
        // We will assume the input is local time and we want to preserve it.
        const appointmentDate = new Date(date);

        const appointment = await prisma.appointment.create({
            data: {
                date: appointmentDate,
                type: `Web Booking: ${notes || 'Ön Görüşme'}`, // Append notes to Type since Appointment doesn't have notes
                status: 'scheduled',
                patientId: patient.id,
                doctorId: doctor.id,
            }
        });

        // 4. Trigger Notification (Optional: Add Notification logic here)

        res.status(201).json({ success: true, appointmentId: appointment.id });
    } catch (e) {
        next(e);
    }
};
