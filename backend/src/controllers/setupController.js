const prisma = require('../config/prisma');
const bcrypt = require('bcryptjs');

exports.initTenant = async (req, res, next) => {
    try {
        const { secret, clinicName, slug, adminName, adminEmail, password } = req.body;

        // Simple security check using JWT_SECRET as a master key for setup
        if (secret !== process.env.JWT_SECRET) {
            return res.status(403).json({ error: "Unauthorized Setup Key" });
        }

        // 1. Create Clinic
        const clinic = await prisma.clinic.upsert({
            where: { slug: slug },
            update: {}, // No update, just ensure it exists
            create: {
                name: clinicName,
                slug: slug,
                plan: 'PRO',
                isActive: true,
                contactInfo: adminEmail
            }
        });

        // 2. Create Branch
        const branchName = `${clinicName} Merkez`;
        const branch = await prisma.branch.upsert({
            where: {
                clinicId_name: {
                    clinicId: clinic.id,
                    name: branchName
                }
            },
            update: {},
            create: {
                name: branchName,
                city: 'İstanbul',
                clinicId: clinic.id
            }
        });

        // 3. Create Admin User
        const hashedPassword = await bcrypt.hash(password, 10);
        const user = await prisma.user.upsert({
            where: {
                clinicId_email: {
                    email: adminEmail,
                    clinicId: clinic.id
                }
            },
            update: {
                password: hashedPassword, // Update password if re-initializing
                branchId: branch.id,
                role: 'admin',
                name: adminName
            },
            create: {
                name: adminName,
                email: adminEmail,
                role: 'admin',
                password: hashedPassword,
                clinicId: clinic.id,
                branchId: branch.id,
                isActive: true
            }
        });

        res.json({
            success: true,
            message: "Tenant initialized successfully",
            clinic: clinic.name,
            user: user.email,
            credentials: {
                email: user.email,
                password: password
            }
        });

    } catch (e) {
        next(e);
    }
};
