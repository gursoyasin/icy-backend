const prisma = require('../config/prisma');
const logger = require('../utils/logger');

// Real Auth Middleware Simulation
// In a real production app, we would verify JWT here: jwt.verify(token, process.env.SECRET)
const authenticate = async (req, res, next) => {
    const authHeader = req.headers.authorization;

    // Allow certain public routes to bypass auth (e.g. Booking, Webhooks)
    // Note: In a real app, explicit public paths in express router are better, but this mimics the old logic for safety.
    if (req.path.startsWith('/api/booking') || req.path.startsWith('/api/webhooks') || req.path.startsWith('/api/auth/login')) {
        return next();
    }

    if (authHeader) {
        // Special case for SaaS Admin Panel
        if (authHeader.includes('mock-admin-token')) {
            const admin = await prisma.user.findFirst({
                where: { role: 'admin' },
                include: { branch: true }
            });
            if (admin) {
                req.user = admin;
                logger.info(`Authenticated as Admin: ${admin.email}`);
                return next();
            }
        }

        // Default Mock Logic: First found user
        const user = await prisma.user.findFirst({
            include: {
                branch: {
                    include: { clinic: true }
                }
            }
        });

        if (user) {
            req.user = user;
            // STRICT MULTI-TENANCY INJECTION
            req.user.clinicId = user.branch?.clinicId;
            return next();
        }
    }

    // DEV MODE HACK: Attach default admin if no header
    const defaultUser = await prisma.user.findFirst({
        where: { role: 'admin' },
        include: {
            branch: {
                include: { clinic: true }
            }
        }
    });

    if (defaultUser) {
        req.user = defaultUser;
        // STRICT MULTI-TENANCY INJECTION
        req.user.clinicId = defaultUser.branch?.clinicId;
        return next();
    }

    return res.status(401).json({ error: "Unauthorized" });
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
