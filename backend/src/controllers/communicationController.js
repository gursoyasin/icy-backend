const prisma = require('../config/prisma');
const iysService = require('../services/iysService');

exports.optOut = async (req, res, next) => {
    try {
        const { contact, channel, reason } = req.body;

        if (!contact || !channel) {
            return res.status(400).json({ error: "Contact and channel required" });
        }

        // 1. Create Local Opt-Out Record
        await prisma.optOut.create({
            data: {
                contact,
                channel: channel.toUpperCase(), // SMS, EMAIL, ALL
                reason
            }
        });

        // 2. Sync with IYS (Remove Consent)
        await iysService.removeConsent(contact, channel.toUpperCase(), reason);

        res.json({ success: true, message: "Unsubscribed successfully" });
    } catch (e) {
        // Handle unique constraint violation (already opted out)
        if (e.code === 'P2002') {
            return res.json({ success: true, message: "Already unsubscribed" });
        }
        next(e);
    }
};
