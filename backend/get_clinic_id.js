const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log('🔍 Fetching Admin Details...');

    const user = await prisma.user.findUnique({
        where: { email: 'admin@icy.com' },
        include: {
            branch: {
                include: {
                    clinic: true
                }
            }
        }
    });

    if (!user) {
        console.log('❌ User not found!');
        return;
    }

    console.log('👤 User:', user.email, 'Role:', user.role);

    if (user.branch) {
        console.log('🏥 Branch Name:', user.branch.name);
        console.log('🆔 Branch ID:', user.branch.id);

        if (user.branch.clinic) {
            console.log('🏢 Clinic Name:', user.branch.clinic.name);
            console.log('🔑 Clinic ID:', user.branch.clinic.id);
        } else {
            console.log('⚠️ No Clinic linked to this Branch (clinicId is null).');
            // Allow fixing this on the fly
            const newClinic = await prisma.clinic.create({
                data: {
                    name: 'ICY Clinic (Main)',
                    contactInfo: user.email
                }
            });
            await prisma.branch.update({
                where: { id: user.branch.id },
                data: { clinicId: newClinic.id }
            });
            console.log('✅ Created & Linked New Clinic:', newClinic.id);
        }
    } else {
        console.log('⚠️ User has no branch!');
    }
}

main()
    .catch(e => console.error(e))
    .finally(async () => await prisma.$disconnect());
