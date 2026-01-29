const prisma = require('../config/prisma');

// 1. Get All Campaigns
exports.getCampaigns = async (req, res, next) => {
    try {
        const campaigns = await prisma.campaign.findMany({
            orderBy: { createdAt: 'desc' },
            include: { logs: { take: 5 } } // Preview of logs
        });
        res.json(campaigns);
    } catch (e) {
        next(e);
    }
};

// 2. Create & Send Campaign (Real Logic)
exports.createCampaign = async (req, res, next) => {
    try {
        const { title, message, channel, targetAudience } = req.body;

        // A. Determine Audience
        let whereCondition = {};
        if (targetAudience === 'leads') {
            whereCondition = { status: 'lead' };
        } else if (targetAudience === 'retention') {
            whereCondition = { status: 'treated' }; // or other logic
        } else {
            // All active
            whereCondition = { status: { not: 'deleted' } };
        }

        const audience = await prisma.patient.findMany({
            where: whereCondition,
            select: { id: true, fullName: true, phoneNumber: true, email: true }
        });

        if (audience.length === 0) {
            return res.status(400).json({ message: "Hedef kitlede hasta bulunamadı." });
        }

        // B. Create Campaign Record
        const campaign = await prisma.campaign.create({
            data: {
                title,
                message,
                channel,
                targetAudience,
                sentCount: audience.length,
                status: 'processing'
            }
        });

        // C. Send via Messaging Service (Logs automatically to MessageLog)
        const messaging = require('../services/messaging');

        // Parallel processing for speed
        await Promise.all(audience.map(async (p) => {
            const recipient = (channel === 'email') ? p.email : p.phoneNumber;
            if (!recipient) return; // Skip invalid

            await messaging.sendMessage(
                channel === 'email' ? 'sms' : channel, // Fallback email to SMS for now as adapter supports whatsapp/sms
                recipient,
                message,
                req.user.id
            );
        }));

        // Log Campaign Stats (CampaignLog table kept for analytics grouping)
        const logsData = audience.map(p => ({
            campaignId: campaign.id,
            recipient: (channel === 'email') ? (p.email || "no-email") : (p.phoneNumber || "no-phone"),
            status: 'sent'
        }));

        if (logsData.length > 0) {
            await prisma.campaignLog.createMany({
                data: logsData
            });
        }

        // Update status
        await prisma.campaign.update({
            where: { id: campaign.id },
            data: { status: 'completed' }
        });

        res.json({
            success: true,
            campaignId: campaign.id,
            sentCount: audience.length,
            message: `${audience.length} kişiye kampanya gönderildi.`
        });

    } catch (e) {
        next(e);
    }
};
