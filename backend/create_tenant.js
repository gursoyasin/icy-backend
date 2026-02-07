/**
 * create_tenant.js (Production-grade)
 *
 * Usage (argv):
 * node create_tenant.js "Klinik Adı" "slug" "Admin Adı" "admin@email.com" "password"
 *
 * If args missing => interactive mode
 */

const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();
const bcrypt = require("bcryptjs");
const readline = require("readline");
const crypto = require("crypto");

// ----------------------------
// Readline helpers
// ----------------------------
const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
});

const question = (q) => new Promise((resolve) => rl.question(q, resolve));

// ----------------------------
// Validators
// ----------------------------
function isValidEmail(email) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(email).toLowerCase());
}

function isValidSlug(slug) {
    return /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(slug);
}

function normalizeSlug(input) {
    return slugify(input).replace(/-+/g, "-");
}

function slugify(text) {
    return text
        .toString()
        .toLowerCase()
        .trim()
        .replace(/ğ/g, "g")
        .replace(/ü/g, "u")
        .replace(/ş/g, "s")
        .replace(/ı/g, "i")
        .replace(/ö/g, "o")
        .replace(/ç/g, "c")
        .replace(/\s+/g, "-")
        .replace(/[^\w-]+/g, "")
        .replace(/--+/g, "-")
        .replace(/^-+/, "")
        .replace(/-+$/, "");
}

function generateStrongPassword() {
    // 12 chars, URL-safe
    return crypto.randomBytes(9).toString("base64url"); // ~12 chars
}

// ----------------------------
// Main
// ----------------------------
async function main() {
    console.log("\n🏥 --- ESTESOFT NEO / ZENITH KİRACI OLUŞTURUCU (PRO) ---\n");

    try {
        // 0) ENV check
        if (!process.env.DATABASE_URL) {
            throw new Error("DATABASE_URL bulunamadı. .env dosyanı kontrol et.");
        }

        // 1) Parse args
        const args = process.argv.slice(2);

        let clinicName, slug, adminName, adminEmail, password;

        if (args.length >= 4) {
            clinicName = args[0];
            slug = args[1];
            adminName = args[2];
            adminEmail = args[3];
            password = args[4] || ""; // optional
        } else {
            // Interactive
            clinicName = await question("Klinik Adı (Örn: 4PM Nişantaşı): ");
            if (!clinicName) throw new Error("Klinik adı zorunludur.");

            const defaultSlug = normalizeSlug(clinicName);
            slug = await question(`Slug (örn: 4pm-nisantasi) [Varsayılan: ${defaultSlug}]: `);
            if (!slug) slug = defaultSlug;

            adminName = await question("Yönetici Adı Soyadı (Örn: Berna Akyar): ");
            adminEmail = await question("Yönetici Email (Örn: berna@4pm.com): ");

            password = await question("Geçici Şifre (boş bırak = otomatik üret): ");
        }

        // 2) Normalize + validate
        clinicName = String(clinicName || "").trim();
        adminName = String(adminName || "").trim();
        adminEmail = String(adminEmail || "").trim().toLowerCase();
        slug = normalizeSlug(String(slug || "").trim());

        if (!clinicName || !adminName || !adminEmail || !slug) {
            throw new Error("Eksik bilgi! clinicName, slug, adminName, adminEmail zorunlu.");
        }

        if (!isValidEmail(adminEmail)) {
            throw new Error("Geçersiz email formatı.");
        }

        if (!isValidSlug(slug)) {
            throw new Error("Slug formatı hatalı. Sadece a-z, 0-9 ve '-' kullanılabilir.");
        }

        if (!password) {
            password = generateStrongPassword();
            console.log("🔐 Şifre otomatik üretildi.");
        }

        if (String(password).length < 6) {
            throw new Error("Şifre en az 6 karakter olmalı.");
        }

        console.log(`\n⏳ Oluşturuluyor: ${clinicName} (${slug})...\n`);

        // 3) Duplicate checks (pre-flight)
        const existingClinic = await prisma.clinic.findUnique({
            where: { slug },
            select: { id: true, name: true, slug: true },
        });

        if (existingClinic) {
            throw new Error(`Bu slug zaten kullanımda: ${existingClinic.slug} (${existingClinic.name})`);
        }

        // Email uniqueness senin schema'na göre değişir:
        // Eğer email global unique ise:
        const existingUser = await prisma.user.findUnique({
            where: { email: adminEmail },
            select: { id: true, email: true, name: true },
        });

        if (existingUser) {
            throw new Error(`Bu email zaten sistemde var: ${existingUser.email} (${existingUser.name})`);
        }

        // 4) Transaction: clinic + branch + user
        const hashedPassword = await bcrypt.hash(password, 12);

        const result = await prisma.$transaction(async (tx) => {
            const clinic = await tx.clinic.create({
                data: {
                    name: clinicName,
                    slug,
                    plan: "PRO",
                    isActive: true,
                    contactInfo: adminEmail,
                },
            });

            const branch = await tx.branch.create({
                data: {
                    name: `${clinicName} Merkez`,
                    city: "İstanbul",
                    clinicId: clinic.id,
                },
            });

            const user = await tx.user.create({
                data: {
                    name: adminName,
                    email: adminEmail,
                    role: "admin", // schema'n USERROLE ise: "OWNER"
                    password: hashedPassword,
                    clinicId: clinic.id,
                    branchId: branch.id,
                    isActive: true,
                },
            });

            return { clinic, branch, user };
        });

        // 5) Output
        console.log("✅ KİRACI BAŞARIYLA OLUŞTURULDU!");
        console.log("--------------------------------------------------");
        console.log(`🏨 Klinik:    ${result.clinic.name}`);
        console.log(`🔗 Slug:      ${result.clinic.slug}`);
        console.log(`🏢 Şube:      ${result.branch.name}`);
        console.log(`👤 Admin:     ${result.user.name}`);
        console.log(`📧 Email:     ${result.user.email}`);
        console.log(`🔑 Şifre:     ${password}`);
        console.log(`🆔 ClinicID:  ${result.clinic.id}`);
        console.log("--------------------------------------------------");
        console.log("⚠️  Not: İlk girişte şifreyi değiştirmenizi öneririm.\n");
    } catch (error) {
        console.error("\n❌ HATA:", error.message);

        // Prisma unique constraint
        if (error.code === "P2002") {
            console.error("⚠️  Unique constraint hatası (slug veya email çakıştı).");
        }
    } finally {
        await prisma.$disconnect();
        rl.close();
    }
}

main();
