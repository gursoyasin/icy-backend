const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    try {
        const user = await prisma.user.findFirst({
            where: { email: 'admin@zenith.com' },
            include: { clinic: true, branch: true }
        });

        if (user) {
            console.log('User found:');
            console.log('ID:', user.id);
            console.log('Name:', user.name);
            console.log('Email:', user.email);
            console.log('Role:', user.role);
            console.log('Clinic:', user.clinic?.name);
            console.log('Branch:', user.branch?.name);
        } else {
            console.log('User admin@zenith.com not found.');
        }
    } catch (e) {
        console.error(e);
    } finally {
        await prisma.$disconnect();
    }
}

main();
