const prisma = require('../config/prisma');

const SYSTEM_CLINIC_SLUG = "zenith-system";

module.exports = async (req, res, next) => {
    try {
        // 1. User must be authenticated (already handled by verifyToken, but let's be safe)
        if (!req.user) {
            return res.status(401).json({ error: "Unauthorized" });
        }

        // 2. User must be 'admin'
        if (req.user.role !== 'admin') {
            return res.status(403).json({ error: "Access Denied: Admins Only" });
        }

        // 3. User must belong to the System Clinic
        // We check the clinic slug of the user's clinic
        const userClinic = await prisma.clinic.findUnique({
            where: { id: req.user.clinicId }
        });

        if (!userClinic || userClinic.slug !== SYSTEM_CLINIC_SLUG) {
            return res.status(403).json({ error: "Access Denied: Platform Admins Only" });
        }

        // If all pass, allow
        next();
    } catch (e) {
        console.error("Platform Auth Error:", e);
        res.status(500).json({ error: "Internal Server Error during Auth Check" });
    }
};
