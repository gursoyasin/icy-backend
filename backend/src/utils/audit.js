const winston = require('winston');

// Dedicated Audit Logger for Legal Compliance (KVKK/GDPR)
const auditLogger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp({
            format: 'YYYY-MM-DD HH:mm:ss'
        }),
        winston.format.printf(({ timestamp, level, message, user, action, target }) => {
            return `[${timestamp}] [${level.toUpperCase()}] OFFICER:${user || 'SYSTEM'} ACTION:${action} TARGET:${target} DESC:${message}`;
        })
    ),
    transports: [
        new winston.transports.File({ filename: 'audit.log' }), // Permanent Legal Record
        new winston.transports.Console() // Dev visibility
    ],
});

exports.logAudit = (userEmail, action, targetId, description) => {
    auditLogger.info(description, {
        user: userEmail,
        action: action,
        target: targetId
    });
};
