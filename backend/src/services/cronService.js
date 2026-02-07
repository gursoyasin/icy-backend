const cron = require('node-cron');
const prisma = require('../config/prisma');
const messaging = require('./messaging');

// Schedule: Every day at 09:00 AM
cron.schedule('0 9 * * *', async () => {
    console.log('[Cron] Running Daily Jobs...');
    await checkBirthdays();
    await checkPostOpRetention();
});

async function checkBirthdays() {
    // Mock logic: In real app, Patient model needs 'birthDate'
    // Assuming we added it or using a tag.
    console.log('[Cron] Checking birthdays...');
    // const today = new Date();
    // const patients = await prisma.patient.findMany({ where: { birthDate: ... } });
    // for (const p of patients) { messaging.sendMessage('sms', p.phoneNumber, "Mutlu Yıllar!", "birthday"); }
}

async function checkPostOpRetention() {
    console.log('[Cron] Checking post-op retention...');
    // Find appointments completed 1 day ago
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);

    // In a real query we'd filter by status='completed' and date=yesterday
    // For V1, just logging the check.
}

module.exports = cron;
