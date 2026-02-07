const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const bcrypt = require('bcryptjs');
const readline = require('readline');

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

const question = (query) => new Promise((resolve) => rl.question(query, resolve));

async function main() {
    console.log('\n🏥 --- ESTESOFT NEO / ZENITH KİRACI OLUŞTURUCU ---\n');

    try {
        // 1. Get Clinic Details (Support ARGV or Interactive)
        const args = process.argv.slice(2);

        let clinicName, slug, adminName, adminEmail, password;

        if (args.length >= 5) {
            [clinicName, slug, adminName, adminEmail, password] = args;
        } else {
            clinicName = await question('Klinik Adı (Örn: 4PM Nişantaşı): ');
            if (!clinicName) throw new Error("Klinik adı zorunludur.");

            slug = await question(`Slug (örn: 4pm-nisantasi) [Varsayılan: ${slugify(clinicName)}]: `);
            if (!slug) slug = slugify(clinicName);

            adminName = await question('Yönetici Adı Soyadı (Örn: Berna Akyar): ');
            adminEmail = await question('Yönetici Email (Örn: berna@4pm.com): ');
            password = await question('Geçici Şifre: ');
        }

        if (!clinicName || !slug || !adminName || !adminEmail || !password) {
            throw new Error("Eksik bilgi! Lütfen tüm alanları doldurun.");
        }

        console.log(`\n⏳ Oluşturuluyor: ${clinicName} (${slug})...\n`);

        // 2. Create Clinic
        const clinic = await prisma.clinic.create({
            data: {
                name: clinicName,
                slug: slug,
                plan: 'PRO',
                isActive: true,
                contactInfo: adminEmail
            }
        });

        // 3. Create Default Branch
        const branch = await prisma.branch.create({
            data: {
                name: `${clinicName} Merkez`,
                city: 'İstanbul',
                clinicId: clinic.id
            }
        });

        // 4. Create Admin User
        const hashedPassword = await bcrypt.hash(password, 10);
        const user = await prisma.user.create({
            data: {
                name: adminName,
                email: adminEmail,
                role: 'admin', // CLINIC OWNER
                password: hashedPassword,
                clinicId: clinic.id,
                branchId: branch.id,
                isActive: true
            }
        });

        console.log('✅ KİRACI BAŞARIYLA OLUŞTURULDU!');
        console.log('--------------------------------------------------');
        console.log(`🏨 Klinik:  ${clinic.name}`);
        console.log(`🔗 Slug:    ${clinic.slug}`);
        console.log(`👤 Admin:   ${user.name}`);
        console.log(`📧 Email:   ${user.email}`);
        console.log(`🔑 Şifre:   ${password}`);
        console.log(`🆔 ClinicID: ${clinic.id}`);
        console.log('--------------------------------------------------');

    } catch (error) {
        console.error('\n❌ HATA:', error.message);
        if (error.code === 'P2002') {
            console.error('⚠️  Bu slug veya email zaten kullanımda!');
        }
    } finally {
        await prisma.$disconnect();
        rl.close();
    }
}

function slugify(text) {
    return text.toString().toLowerCase()
        .replace(/\s+/g, '-')           // Replace spaces with -
        .replace(/[^\w\-]+/g, '')       // Remove all non-word chars
        .replace(/\-\-+/g, '-')         // Replace multiple - with single -
        .replace(/^-+/, '')             // Trim - from start of text
        .replace(/-+$/, '');            // Trim - from end of text
}

main();
