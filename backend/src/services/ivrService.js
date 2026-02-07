const axios = require('axios');
const prisma = require('../config/prisma');
const logger = require('../utils/logger');

class IVRService {
    constructor() {
        // NetGSM or Twilio Credentials
        this.user = process.env.NETGSM_USER;
        this.pass = process.env.NETGSM_PASS;
        this.header = process.env.NETGSM_HEADER;
    }

    async makeConfirmationCall(appointment) {
        // Example: NetGSM IYS/Voice API logic
        // In a real scenario, this initiates a call with a specific audio file or TTS text.
        // "Sayın {name}, yarın {time} randevunuz var. Onaylamak için 1'e, iptal için 2'ye basın."

        const phone = appointment.patient.phoneNumber;
        const name = appointment.patient.fullName;
        const date = new Date(appointment.date).toLocaleString('tr-TR');

        logger.info(`[IVR] Initiating call to ${name} (${phone}) for appointment on ${date}`);

        // Mock Provider Call
        // await axios.post('https://api.netgsm.com.tr/voice/call', { ... });

        // Log the attempt
        await prisma.callLog.create({
            data: {
                callerNumber: "SYSTEM", // Outbound
                direction: "outbound",
                status: "initiated",
                duration: 0,
                patientId: appointment.patientId
            }
        });

        return true;
    }

    async handleWebhook(payload) {
        // Payload from provider: { callId, dtmf: "1", ... }
        const { callId, dtmf, phone } = payload;

        logger.info(`[IVR] DTMF Received: ${dtmf} from ${phone}`);

        if (dtmf === '1') {
            // Confirm Appointment
            // Find appointment by phone (simplified) because we don't have callId linked yet in this mock
            const patient = await prisma.patient.findFirst({ where: { phoneNumber: phone } });
            if (patient) {
                const appt = await prisma.appointment.findFirst({
                    where: {
                        patientId: patient.id,
                        status: 'scheduled',
                        date: { gte: new Date() }
                    }
                });

                if (appt) {
                    await prisma.appointment.update({
                        where: { id: appt.id },
                        data: { status: 'confirmed' }
                    });
                    logger.info(`[IVR] Appointment confirmed for ${patient.fullName}`);
                }
            }
        } else if (dtmf === '2') {
            // Cancel logic...
            logger.info(`[IVR] Appointment cancellation requested by ${phone}`);
        }
    }
}

module.exports = new IVRService();
