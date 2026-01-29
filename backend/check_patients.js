const prisma = require('./src/config/prisma');

async function check() {
    try {
        console.log("Checking DB connection...");
        const count = await prisma.patient.count();
        console.log(`Total Patients: ${count}`);

        const recent = await prisma.patient.findMany({
            take: 5,
            orderBy: { createdAt: 'desc' }
        });

        console.log("Recent 5 Patients:");
        console.log(JSON.stringify(recent, null, 2));
    } catch (e) {
        console.error("Error:", e);
    } finally {
        await prisma.$disconnect();
    }
}

check();
