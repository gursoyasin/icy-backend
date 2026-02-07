const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log('🌱 Seeding database with REAL data structures...');

    // 0. Create Clinic (SaaS Tenant)
    const clinic = await prisma.clinic.upsert({
        where: { slug: "zenith-main" },
        update: {},
        create: {
            name: "Zenith Clinic (Main)",
            slug: "zenith-main",
            plan: "ENTERPRISE",
            isActive: true,
            contactInfo: "info@zenith.com"
        }
    });
    console.log(`🏥 Clinic Created/Found: ${clinic.name}`);

    // 1. Create Default Branch linked to Clinic
    const branch = await prisma.branch.upsert({
        where: {
            clinicId_name: {
                clinicId: clinic.id,
                name: "4pm Nişantaşı"
            }
        },
        update: {},
        create: {
            name: "4pm Nişantaşı",
            city: "İstanbul",
            address: "Nişantaşı, Abdi İpekçi Cad. No:42",
            clinicId: clinic.id
        }
    });
    console.log(`📍 Branch Created/Found: ${branch.name}`);

    // 2. Create Admin User (Real World: The Doctor owner)
    const bcrypt = require('bcryptjs');
    const hashedPassword = await bcrypt.hash('password123', 10);

    const user = await prisma.user.upsert({
        where: {
            clinicId_email: {
                email: 'admin@estesoftneo.com',
                clinicId: clinic.id
            }
        },
        update: {
            branchId: branch.id,
            clinicId: clinic.id,
            role: 'admin'
        },
        create: {
            email: 'admin@estesoftneo.com',
            name: 'Dr. Yacn',
            password: hashedPassword,
            role: 'admin',
            branchId: branch.id,
            clinicId: clinic.id
        },
    });
    console.log(`👤 Admin Created: ${user.name} (${user.role})`);

    // 3. Create Staff User
    await prisma.user.upsert({
        where: {
            clinicId_email: {
                email: 'staff@estesoftneo.com',
                clinicId: clinic.id
            }
        },
        update: {},
        create: {
            email: 'staff@estesoftneo.com',
            name: 'Ayşe Asistan',
            password: hashedPassword,
            role: 'staff',
            branchId: branch.id,
            clinicId: clinic.id
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
    console.log(`🔗 Booking Link: zenith.com/book/dr-yacn-consultation`);

    // 5. Create Sample Patients linked to Branch AND Clinic
    const patient1 = await prisma.patient.create({
        data: {
            fullName: "Mehmet Yılmaz (Lead)",
            email: "mehmet@example.com",
            phoneNumber: "+90 555 123 45 67",
            status: "lead",
            notes: "Incoming from Instagram Ad",
            branchId: branch.id,
            clinicId: clinic.id
        }
    });

    const patient2 = await prisma.patient.create({
        data: {
            fullName: "Lisa Mueller (VIP)",
            email: "lisa@example.de",
            phoneNumber: "+49 170 1234567",
            status: "active",
            notes: "Hair Transplant - 3500 Grafts",
            branchId: branch.id,
            clinicId: clinic.id
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
