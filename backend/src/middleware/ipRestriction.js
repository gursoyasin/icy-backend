const prisma = require('../config/prisma');
const logger = require('../utils/logger');

// Middleware to check if user's IP is allowed
const ipRestriction = async (req, res, next) => {
    try {
        const user = req.user; // Assumes verifyToken middleware ran before

        // If no user or no IPs defined, allow
        if (!user || !user.allowedIPs || user.allowedIPs.length === 0) {
            return next();
        }

        const clientIP = req.headers['x-forwarded-for'] || req.socket.remoteAddress;

        // Normalize IP (handle ::ffff: prefix etc if needed, but simple string match for now)
        // In production, robust IP parsing libraries (like 'ipaddr.js') are better.
        // For now, strict string inclusion.

        const isAllowed = user.allowedIPs.includes(clientIP);

        if (!isAllowed) {
            logger.warn(`[Security] Blocked access from IP ${clientIP} for user ${user.email}`);
            return res.status(403).json({ error: "Access Denied: IP Address not allowed." });
        }

        next();

    } catch (e) {
        logger.error(`[Security] IP Check Error: ${e.message}`);
        next(); // Fail open or closed? Fail open for now to avoid accidental lockouts during dev.
    }
};

module.exports = ipRestriction;
