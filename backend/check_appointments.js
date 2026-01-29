const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    const apps = await prisma.appointment.findMany({
        include: { patient: true, doctor: true }
    });
    console.log("Count:", apps.length);
    if (apps.length > 0) {
        console.log("First Appointment Raw Date:", apps[0].date);
        console.log("First Appointment JSON:", JSON.stringify(apps[0], null, 2));
    }
}

main().finally(() => prisma.$disconnect());
