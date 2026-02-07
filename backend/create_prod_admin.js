const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();
const bcrypt = require("bcryptjs");

const SYSTEM_CLINIC_SLUG = "zenith-system"; // Fixed slug for system clinic
const SYSTEM_CLINIC_NAME = "ZENITH SYSTEM";
const SYSTEM_BRANCH_NAME = "Genel Merkez";

async function main() {
    console.log("\n🚀 --- ZENITH PLATFORM ADMIN OLUŞTURUCU (PRO) ---\n");

    const email = process.argv[2] || "admin@zenith.com";
    const password = process.argv[3] || "password123";

    // Validate inputs
    if (!email || !password) {
        console.error("Kullanım: node create_prod_admin.js <email> <password>");
        process.exit(1);
    }

    console.log(`Hedef Email: ${email}`);

    try {
        const hashedPassword = await bcrypt.hash(password, 12);

        const result = await prisma.$transaction(async (tx) => {
            // 1. Ensure System Clinic Exists
            let clinic = await tx.clinic.findUnique({
                where: { slug: SYSTEM_CLINIC_SLUG },
            });

            if (!clinic) {
                console.log("⚙️  System Clinic oluşturuluyor...");
                clinic = await tx.clinic.create({
                    data: {
                        name: SYSTEM_CLINIC_NAME,
                        slug: SYSTEM_CLINIC_SLUG,
                        plan: "ENTERPRISE",
                        isActive: true, // Always active
                        contactInfo: "system@zenith.com",
                    },
                });
            } else {
                console.log("✅ System Clinic mevcut.");
            }

            // 2. Ensure System Branch Exists
            // Using findFirst because composite unique might vary or just to be safe
            let branch = await tx.branch.findFirst({
                where: {
                    clinicId: clinic.id,
                    name: SYSTEM_BRANCH_NAME,
                },
            });

            if (!branch) {
                console.log("⚙️  System Branch oluşturuluyor...");
                branch = await tx.branch.create({
                    data: {
                        name: SYSTEM_BRANCH_NAME,
                        city: "İstanbul",
                        clinicId: clinic.id,
                    },
                });
            } else {
                console.log("✅ System Branch mevcut.");
            }

            // 3. Upsert Admin User
            console.log("👤 Admin kullanıcısı ayarlanıyor...");

            // Check if user exists to decide on log message
            const existingUser = await tx.user.findUnique({ where: { email } });
            const action = existingUser ? "GÜNCELLENDİ" : "OLUŞTURULDU";

            const user = await tx.user.upsert({
                where: { email },
                update: {
                    name: "Süper Yönetici",
                    password: hashedPassword,
                    role: "admin",
                    clinicId: clinic.id,
                    branchId: branch.id,
                    isActive: true,
                },
                create: {
                    name: "Süper Yönetici",
                    email,
                    password: hashedPassword,
                    role: "admin",
                    clinicId: clinic.id,
                    branchId: branch.id,
                    isActive: true,
                },
            });

            return { clinic, branch, user, action };
        });

        console.log("\n✅ İŞLEM BAŞARILI!");
        console.log("--------------------------------------------------");
        console.log(`🏥 System Clinic: ${result.clinic.name} (${result.clinic.slug})`);
        console.log(`🏢 System Branch: ${result.branch.name}`);
        console.log(`👤 Super Admin:   ${result.user.email} [${result.action}]`);
        console.log(`🔑 Şifre:         ${password}`);
        console.log("--------------------------------------------------");
        console.log("⚠️  Bu hesap 'System Clinic'e bağlıdır ve tüm platformu yönetebilir.");
        console.log("⚠️  PROD ortamında şifreyi değiştirmeyi unutmayın.\n");

    } catch (e) {
        console.error("\n❌ HATA OLUŞTU:", e);
        process.exit(1);
    } finally {
        await prisma.$disconnect();
    }
}

main();
