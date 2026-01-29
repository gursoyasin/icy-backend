const prisma = require('./src/config/prisma');

async function checkDoctors() {
    try {
        console.log("Checking for Doctors/Admin...");
        const doctors = await prisma.user.findMany({
            where: {
                OR: [
                    { role: 'doctor' },
                    { role: 'admin' }
                ]
            }
        });
        console.log(`Found ${doctors.length} doctors/admins.`);
        console.log(JSON.stringify(doctors, null, 2));
    } catch (e) {
        console.error(e);
    } finally {
        await prisma.$disconnect();
    }
}

checkDoctors();
