const cron = require('node-cron');
const prisma = require('../config/prisma');
const messaging = require('./messaging');
const ivrService = require('./ivrService');
const logger = require('../utils/logger');

// Schedule: Every day at 09:00 AM
cron.schedule('0 9 * * *', async () => {
    logger.info('[Cron] Running Daily Jobs...');
    try {
        await checkBirthdays();
        await checkPostOpRetention();
        await checkReminders(); // Next day reminders
    } catch (e) {
        logger.error(`[Cron] Daily Job Failed: ${e.message}`);
    }
});

async function checkBirthdays() {
    logger.info('[Cron] Checking birthdays...');
    // Postgres specific query to match day and month regardless of year
    // prisma doesn't support this natively well without raw query or filtering in code
    // For scale, raw query is better.

    try {
        const today = new Date();
        const month = today.getMonth() + 1; // JS months are 0-indexed
        const day = today.getDate();

        // Raw query for efficiency
        const birthdayPatients = await prisma.$queryRaw`
            SELECT * FROM "Patient"
            WHERE EXTRACT(MONTH FROM "dateOfBirth") = ${month}
            AND EXTRACT(DAY FROM "dateOfBirth") = ${day}
            AND "status" = 'active'
        `;

        for (const patient of birthdayPatients) {
            if (patient.phoneNumber) {
                // Determine language or default to TR
                const lang = patient.language || 'tr';
                const message = lang === 'en'
                    ? `Happy Birthday ${patient.fullName}! We wish you a healthy and happy year. - ZENITH`
                    : `Mutlu Yıllar ${patient.fullName}! Yeni yaşınızda sağlık ve mutluluk dileriz. - ZENITH`;

                // Send SMS/WA
                await messaging.sendMessage('whatsapp', patient.phoneNumber, message);
                logger.info(`[Cron] Birthday message sent to ${patient.email || patient.fullName}`);
            }
        }
    } catch (e) {
        logger.error(`[Cron] Birthday Check Error: ${e.message}`);
    }
}

async function checkPostOpRetention() {
    logger.info('[Cron] Checking post-op retention...');

    // Find appointments completed X days ago (e.g. 30 days for PRP)
    const daysAgo = 30;
    const targetDateStart = new Date();
    targetDateStart.setDate(targetDateStart.getDate() - daysAgo);
    targetDateStart.setHours(0, 0, 0, 0);

    const targetDateEnd = new Date(targetDateStart);
    targetDateEnd.setHours(23, 59, 59, 999);

    try {
        const appointments = await prisma.appointment.findMany({
            where: {
                status: 'completed',
                date: {
                    gte: targetDateStart,
                    lte: targetDateEnd
                },
                type: { contains: 'Hair Transplant', mode: 'insensitive' } // Assuming type string
            },
            include: { patient: true }
        });

        for (const app of appointments) {
            if (app.patient?.phoneNumber) {
                const message = `Merhaba ${app.patient.fullName}, saç ekimi operasyonunuzun üzerinden 1 ay geçti. PRP tedavisi ile sonucu güçlendirmenin tam zamanı! Randevu için: +905555555555`;
                await messaging.sendMessage('whatsapp', app.patient.phoneNumber, message);
                logger.info(`[Cron] Retention message sent to ${app.patient.fullName}`);
            }
        }
    } catch (e) {
        logger.error(`[Cron] Retention Check Error: ${e.message}`);
    }
}

async function checkReminders() {
    logger.info('[Cron] Checking appointment reminders...');

    try {
        // Find appointments tomorrow (24h from now window)
        const startWindow = new Date();
        startWindow.setDate(startWindow.getDate() + 1);
        startWindow.setHours(0, 0, 0, 0);

        const endWindow = new Date(startWindow);
        endWindow.setHours(23, 59, 59, 999);

        const appointments = await prisma.appointment.findMany({
            where: {
                date: { gte: startWindow, lte: endWindow },
                status: 'scheduled'
            },
            include: { patient: true }
        });

        for (const app of appointments) {
            if (app.patient?.phoneNumber) {
                const timeString = new Date(app.date).toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' });
                const message = `Hatırlatma: Yarın saat ${timeString} randevunuz bulunmaktadır. Lütfen zamanında geliniz. - ZENITH`;

                // Send WhatsApp
                await messaging.sendMessage('whatsapp', app.patient.phoneNumber, message);

                // Trigger IVR Call if it's a critical logic (optional)
                // await ivrService.makeConfirmationCall(app); 

                logger.info(`[Cron] Reminder sent to ${app.patient.fullName}`);
            }
        }
    } catch (e) {
        logger.error(`[Cron] Reminder Check Error: ${e.message}`);
    }
}

module.exports = cron;
