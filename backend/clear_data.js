const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log('🗑️ Clearing database...');

    // Delete dependent records first
    await prisma.message.deleteMany({});
    await prisma.conversation.deleteMany({});
    await prisma.appointment.deleteMany({});
    await prisma.transfer.deleteMany({});
    await prisma.accommodation.deleteMany({});
    await prisma.invoice.deleteMany({});
    await prisma.photoEntry.deleteMany({});
    await prisma.callLog.deleteMany({});
    await prisma.notification.deleteMany({});

    // Delete main records
    await prisma.patient.deleteMany({});

    // Optional: Keep the user so you don't have to re-register
    // await prisma.user.deleteMany({}); 

    console.log('✅ All patients and related data cleared.');
    console.log('ℹ️ Admin user (Dr. Yacn) was KEPT so you can still login.');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
