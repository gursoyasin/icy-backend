const prisma = require('../config/prisma');
const axios = require('axios');

// IYS (İleti Yönetim Sistemi) Integration Service
// This usually requires a certified integrator or direct SOAP/REST integration.
// For V1, we will implement the "Consent Management" logic within our DB,
// and structure a method to sync with IYS API when credentials are provided.

exports.checkConsent = async (recipient, type) => {
    // 1. Check Local Opt-out
    const optOut = await prisma.optOut.findUnique({
        where: { contact: recipient } // Simplified unique check
    });

    if (optOut && (optOut.channel === 'ALL' || optOut.channel === type)) {
        return false; // BLOCKED
    }

    return true; // ALLOWED (Default opt-in usually requires explicit consent for marketing, but for transactional it's ok)
};

exports.addConsent = async (recipient, type, source) => {
    // Save to IYS Log
    await prisma.iYSLog.create({
        data: {
            recipient,
            type,
            source,
            status: 'active'
        }
    });

    // TODO: Sync with Real IYS API
    // await axios.post(IYS_API_URL, { ... })
    console.log(`[IYS] Consent added for ${recipient} via ${source}`);
};

exports.removeConsent = async (recipient, type, reason) => {
    // Create Opt-Out Record
    await prisma.optOut.create({
        data: {
            contact: recipient,
            channel: type,
            reason: reason
        }
    });

    // Update IYS STATUS
    // TODO: Sync to IYS API
    console.log(`[IYS] Consent removed for ${recipient}`);
};
