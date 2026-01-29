const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log('🌱 Seeding database with REAL data structures...');

    // 1. Create Default Branch (Real World: "Main Clinic")
    const branch = await prisma.branch.create({
        data: {
            name: "4pm Nişantaşı",
            city: "İstanbul",
            address: "Nişantaşı, Abdi İpekçi Cad. No:42"
        }
    });
    console.log(`🏥 Branch Created: ${branch.name}`);

    // 2. Create Admin User (Real World: The Doctor owner)
    const bcrypt = require('bcryptjs');
    const hashedPassword = await bcrypt.hash('password123', 10);

    const user = await prisma.user.upsert({
        where: { email: 'admin@estesoftneo.com' },
        update: { branchId: branch.id, role: 'admin' },
        create: {
            email: 'admin@estesoftneo.com',
            name: 'Dr. Yacn',
            password: hashedPassword,
            role: 'admin',
            branchId: branch.id
        },
    });
    console.log(`👤 Admin Created: ${user.name} (${user.role})`);

    // 3. Create Staff User
    await prisma.user.upsert({
        where: { email: 'staff@estesoftneo.com' },
        update: {},
        create: {
            email: 'staff@estesoftneo.com',
            name: 'Ayşe Asistan',
            password: hashedPassword,
            role: 'staff',
            branchId: branch.id
        }
    });

    // 4. Create Public Booking Link
    await prisma.bookingLink.upsert({
        where: { slug: "dr-yacn-consultation" },
        update: { doctorId: user.id },
        create: {
            slug: "dr-yacn-consultation",
            doctorId: user.id
        }
    });
    console.log(`🔗 Booking Link: icy.com/book/dr-yacn-consultation`);

    // 5. Create Sample Patients linked to Branch
    const patient1 = await prisma.patient.create({
        data: {
            fullName: "Mehmet Yılmaz (Lead)",
            email: "mehmet@example.com",
            phoneNumber: "+90 555 123 45 67",
            status: "lead",
            notes: "Incoming from Instagram Ad",
            branchId: branch.id
        }
    });

    const patient2 = await prisma.patient.create({
        data: {
            fullName: "Lisa Mueller (VIP)",
            email: "lisa@example.de",
            phoneNumber: "+49 170 1234567",
            status: "active",
            notes: "Hair Transplant - 3500 Grafts",
            branchId: branch.id
        }
    });

    // 6. Create Real conversations (Whatsapp style)
    const conv = await prisma.conversation.create({
        data: {
            platform: "whatsapp",
            contact: "+49 170 1234567" // Lisa
        }
    });

    await prisma.message.create({
        data: {
            conversationId: conv.id,
            content: "Hello, I am interested in hair transplant.",
            isFromUser: false
        }
    });

    console.log('✅ Real Database Seeded.');
}

main()
    .then(async () => {
        await prisma.$disconnect();
    })
    .catch(async (e) => {
        console.error(e);
        await prisma.$disconnect();
        process.exit(1);
    });
