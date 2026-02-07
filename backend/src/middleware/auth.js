const prisma = require('../config/prisma');
const logger = require('../utils/logger');

// Real Auth Middleware Simulation
// In a real production app, we would verify JWT here: jwt.verify(token, process.env.SECRET)
const jwt = require('jsonwebtoken');
const authenticate = async (req, res, next) => {
    const authHeader = req.headers.authorization;

    // Public Routes Bypass
    if (req.path.startsWith('/api/booking') || req.path.startsWith('/api/webhooks') || req.path.startsWith('/api/auth/login') || req.path.startsWith('/api/auth/register')) {
        return next();
    }

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: "Unauthorized: No token provided" });
    }

    const token = authHeader.split(' ')[1];

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // Optimistic Approach: Trust token payload to save DB call
        // Or Safe Approach: Fetch user from DB to ensure they still exist
        const user = await prisma.user.findUnique({
            where: { id: decoded.id },
            include: { branch: true }
        });

        if (!user) {
            return res.status(401).json({ error: "Unauthorized: User no longer exists" });
        }

        req.user = user;
        req.user.clinicId = user.branch?.clinicId; // Multi-tenancy context
        next();

    } catch (e) {
        logger.warn(`Auth Failed: ${e.message}`);
        return res.status(401).json({ error: "Unauthorized: Invalid token" });
    }
};

// RBAC Guard
const requireRole = (role) => (req, res, next) => {
    const roles = ['staff', 'doctor', 'admin'];
    const userRoleIndex = roles.indexOf(req.user.role);
    const requiredRoleIndex = roles.indexOf(role);

    if (userRoleIndex < requiredRoleIndex) {
        logger.warn(`Access Denied. User: ${req.user.role}, Required: ${role}`);
        return res.status(403).json({ error: "Access denied: Insufficient permissions" });
    }
    next();
};

module.exports = { authenticate, requireRole };
