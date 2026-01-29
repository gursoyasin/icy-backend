const prisma = require('./src/config/prisma');

async function check() {
    try {
        const users = await prisma.user.findMany({
            include: { branch: true }
        });
        console.log("Users in DB:");
        console.log(JSON.stringify(users, null, 2));
    } catch (e) {
        console.error(e);
    } finally {
        await prisma.$disconnect();
    }
}

check();
