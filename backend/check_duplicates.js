// This script checks the LOCAL database.
// To check production, we need to deploy a debug route.

const prisma = new PrismaClient();

async function main() {
    try {
        const users = await prisma.user.findMany({
            where: { email: 'admin@zenith.com' },
            include: { clinic: true, branch: true }
        });

        console.log(`Found ${users.length} users with email 'admin@zenith.com':`);

        users.forEach((u, index) => {
            console.log(`[${index + 1}] ID: ${u.id}`);
            console.log(`    Name: ${u.name}`);
            console.log(`    Clinic: ${u.clinic?.name} (${u.clinicId})`);
            console.log(`    Role: ${u.role}`);
            console.log('---');
        });

    } catch (e) {
        console.error(e);
    } finally {
        await prisma.$disconnect();
    }
}

main();
