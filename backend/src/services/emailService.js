const nodemailer = require('nodemailer');
const prisma = require('../config/prisma');

// SMTP Config
const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: process.env.SMTP_PORT || 587,
    secure: false, // true for 465, false for other ports
    auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
    },
});

exports.sendEmail = async (to, subject, html, campaignId = null) => {
    let status = 'sent';
    let errorLog = null;

    try {
        console.log(`[Email] Sending to ${to}: ${subject}`);

        if (!process.env.SMTP_USER) {
            console.warn("[Email] SMTP Not Configured. Skipping.");
            throw new Error("SMTP Credentials Missing");
        }

        const info = await transporter.sendMail({
            from: process.env.SMTP_FROM || '"Klinik" <no-reply@clinic.com>',
            to: to,
            subject: subject,
            html: html,
        });

        console.log(`[Email] Sent: ${info.messageId}`);
    } catch (e) {
        console.error(`[Email] Failed:`, e.message);
        status = 'failed';
        errorLog = e.message;
    }

    // Log to DB
    await prisma.emailLog.create({
        data: {
            recipient: to,
            subject: subject,
            status: status,
            error: errorLog,
            campaignId: campaignId
        }
    });

    return status === 'sent';
};
