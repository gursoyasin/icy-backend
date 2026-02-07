const prisma = require('../config/prisma');

// VoIP Webhook (Verimor / Bulutsantralim Standard)
exports.webhook = async (req, res, next) => {
    try {
        // Expected payload varies by provider. 
        // Example: { caller: "0532xxx", callee: "0850xxx", direction: "IN", event: "RINGING" }
        const { caller, direction, event } = req.body;

        console.log(`[VoIP] Call Event: ${event} from ${caller}`);

        if (event === 'RINGING' && direction === 'IN') {
            // 1. Find Patient
            const patient = await prisma.patient.findFirst({
                where: { phoneNumber: caller }
            });

            // 2. Emit Socket Event to Frontend (for Pop-up)
            const io = req.app.get('io');
            if (io) {
                io.emit('call_incoming', {
                    callerNumber: caller,
                    patientName: patient ? patient.fullName : 'Bilinmeyen Numara',
                    patientId: patient ? patient.id : null
                });
            }
        }

        // 3. Log to DB
        if (event === 'HANGUP') {
            await prisma.callWebhookLog.create({
                data: {
                    provider: 'verimor', // Default
                    caller: caller || 'Unknown',
                    callee: req.body.callee || 'Clinic',
                    direction: direction || 'IN',
                    status: 'completed',
                    rawPayload: JSON.stringify(req.body)
                }
            });

            // Also add to simplified CallLog linked to Patient
            const patient = await prisma.patient.findFirst({
                where: { phoneNumber: caller }
            });

            await prisma.callLog.create({
                data: {
                    callerNumber: caller,
                    direction: direction === 'IN' ? 'inbound' : 'outbound',
                    status: 'answered', // Simplified
                    duration: req.body.duration || 0,
                    patientId: patient ? patient.id : null
                }
            });
        }

        res.json({ success: true });
    } catch (e) { next(e); }
};
