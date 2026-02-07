const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
    console.log('🚀 Creating Production Admin Account...');

    // 1. Ensure a Branch exists
    let branch = await prisma.branch.findFirst({ where: { name: 'Merkez Klinik' } });
    if (!branch) {
        branch = await prisma.branch.create({
            data: {
                name: 'Merkez Klinik',
                city: 'İstanbul',
                address: 'Merkez'
            }
        });
        console.log('✅ Branch Created:', branch.name);
    } else {
        console.log('ℹ️ Branch already exists:', branch.name);
    }

    // 2. Create Admin User
    const email = 'admin@zenith.com';
    const password = 'password123';
    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await prisma.user.upsert({
        where: { email },
        update: {
            role: 'admin',
            branchId: branch.id
        },
        create: {
            email,
            name: 'Süper Yönetici',
            password: hashedPassword,
            role: 'admin',
            branchId: branch.id
        }
    });

    console.log('\n🎉 ADMIN USER READY:');
    console.log('Email:', email);
    console.log('Password:', password);
}

main()
    .catch(e => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
