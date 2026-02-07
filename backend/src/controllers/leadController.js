const prisma = require('../config/prisma');
const automation = require('../services/automation');

exports.webhook = async (req, res, next) => {
    try {
        console.log('[Lead Webhook] Payload:', req.body);

        // Standard Facebook Lead Gen Payload Structure (Simplified)
        // Usually comes as entry -> changes -> value -> form_id, leadgen_id
        // For this V1, we assume a simplified JSON from a middleware/connector (like Zapier or Converions API)
        // Expected: { fullName, phoneNumber, email, source, formId }

        const { fullName, phoneNumber, email, source, platform } = req.body;

        if (!fullName || !phoneNumber) {
            return res.status(400).json({ error: "Missing required fields: fullName, phoneNumber" });
        }

        // 1. Create or Update Patient (Lead)
        // Check if phone exists
        let patient = await prisma.patient.findFirst({
            where: { phoneNumber: phoneNumber }
        });

        if (patient) {
            // Update existing? Or just log?
            // For leads, if exists, maybe just update notes or create a new task
            console.log(`[Lead] Existing patient found: ${patient.id}`);
        } else {
            patient = await prisma.patient.create({
                data: {
                    fullName,
                    phoneNumber,
                    email,
                    source: source || platform || 'Social Media',
                    status: 'lead',
                    notes: `Lead from Form. Platform: ${platform}`
                }
            });
            console.log(`[Lead] Created new lead: ${patient.id}`);
        }

        // 2. Trigger Automation (CRM Pipeline)
        await automation.triggerWorkflow('lead_received', {
            patientId: patient.id,
            name: fullName,
            phone: phoneNumber,
            source: source
        });

        res.json({ success: true, patientId: patient.id });

    } catch (e) {
        next(e);
    }
};
