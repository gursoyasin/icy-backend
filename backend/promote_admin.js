const prisma = require('./src/config/prisma');

async function makeAdmin(email) {
    try {
        console.log(`Promoting ${email} to ADMIN...`);
        const user = await prisma.user.update({
            where: { email },
            data: { role: 'admin' }
        });
        console.log("Success! User updated:", user);
    } catch (e) {
        console.error("Error updating user:", e);
    } finally {
        await prisma.$disconnect();
    }
}

// Promoting the likely active user
makeAdmin('name@clinic.com');
makeAdmin('gursoyasin@gmail.com');
