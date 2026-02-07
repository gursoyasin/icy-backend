const cron = require('node-cron');
const prisma = require('../config/prisma');
const messaging = require('./messaging');

// Schedule: Every day at 09:00 AM
cron.schedule('0 9 * * *', async () => {
    console.log('[Cron] Running Daily Jobs...');
    await checkBirthdays();
    await checkPostOpRetention();
    await checkReminders();
});

async function checkBirthdays() {
    console.log('[Cron] Checking birthdays...');
    // Mock logic: In real app, Patient model needs 'birthDate'
}

async function checkPostOpRetention() {
    console.log('[Cron] Checking post-op retention...');
    // Find appointments completed 30 days ago and suggest follow-up (PRP etc.)
}

async function checkReminders() {
    console.log('[Cron] Checking appointment reminders...');
    const ivrService = require('./ivrService');
    const messaging = require('./messaging');

    // 1. Find appointments in ~24 hours
    const startWindow = new Date(Date.now() + 23 * 60 * 60 * 1000); // 23 hours from now
    const endWindow = new Date(Date.now() + 25 * 60 * 60 * 1000);   // 25 hours from now

    // In real Prisma:
    /*
    const appointments = await prisma.appointment.findMany({
        where: {
            date: { gte: startWindow, lte: endWindow },
            status: 'scheduled'
        },
        include: { patient: true }
    });
    
    for (const app of appointments) {
        // Send WhatsApp
        await messaging.sendMessage('whatsapp', app.patient.phoneNumber, `Randevu Hatırlatma: Yarın saat ${app.date} randevunuz var.`);
        
        // Trigger IVR Call if not confirmed
        await ivrService.makeConfirmationCall(app);
    }
    */
}

module.exports = cron;
