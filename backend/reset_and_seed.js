const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
    console.log('🔥 TOTAL SYSTEM RESET INITIATED...');

    // 1. DELETE EVERYTHING (Reverse Order of Reference)
    console.log('Deleting dependent records...');
    await prisma.messageLog.deleteMany({});
    await prisma.automationLog.deleteMany({});
    await prisma.campaignLog.deleteMany({});
    await prisma.campaign.deleteMany({});
    await prisma.surveyResult.deleteMany({});
    await prisma.callLog.deleteMany({});
    await prisma.photoEntry.deleteMany({});
    await prisma.invoice.deleteMany({});
    await prisma.accommodation.deleteMany({});
    await prisma.transfer.deleteMany({});
    await prisma.supportTicket.deleteMany({});
    await prisma.message.deleteMany({});
    await prisma.conversation.deleteMany({});
    await prisma.notification.deleteMany({});
    await prisma.appointment.deleteMany({});
    await prisma.bookingLink.deleteMany({});

    console.log('Deleting core records...');
    await prisma.patient.deleteMany({});
    await prisma.user.deleteMany({});
    await prisma.branch.deleteMany({});
    await prisma.clinic.deleteMany({});

    console.log('✅ ALL DATA WIPED.');

    // 2. CREATE FRESH STRUCTURE
    console.log('🌱 Creating new Account: yasin@klinik.com');

    // Create Clinic
    const clinic = await prisma.clinic.create({
        data: {
            name: "Yasin Clinic",
            contactInfo: "yasin@klinik.com"
        }
    });

    // Create Branch
    const branch = await prisma.branch.create({
        data: {
            name: "Merkez Şube",
            city: "İstanbul",
            clinicId: clinic.id
        }
    });

    // Create User (Admin)
    const hashedPassword = await bcrypt.hash('password123', 10);
    const user = await prisma.user.create({
        data: {
            email: "yasin@klinik.com",
            name: "Yasin",
            password: hashedPassword,
            role: "admin",
            branchId: branch.id
        }
    });

    // Booking Link
    await prisma.bookingLink.create({
        data: {
            slug: "yasin-consultation",
            doctorId: user.id
        }
    });

    console.log(`
    =========================================
    🎉 NEW ACCOUNT CREATED
    =========================================
    User:     yasin@klinik.com
    Password: password123
    Role:     Admin
    Branch:   ${branch.name}
    Link:     /book/yasin-consultation
    =========================================
    `);
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
