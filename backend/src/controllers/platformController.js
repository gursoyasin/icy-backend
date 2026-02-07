const prisma = require('../config/prisma');
const bcrypt = require('bcryptjs');

// List All Clinics (Tenants)
exports.listClinics = async (req, res, next) => {
    try {
        const clinics = await prisma.clinic.findMany({
            include: {
                _count: {
                    select: { users: true, branches: true, patients: true }
                }
            },
            orderBy: { createdAt: 'desc' }
        });

        // Hide sensitive info if needed, but for super admin it's mostly fine
        res.json(clinics);
    } catch (e) {
        next(e);
    }
};

// Create a New Tenant (API Version of create_tenant.js)
exports.createClinic = async (req, res, next) => {
    try {
        const { clinicName, slug, adminName, adminEmail, password, plan } = req.body;

        // Validations
        if (!clinicName || !slug || !adminName || !adminEmail || !password) {
            return res.status(400).json({ error: "All fields are required" });
        }

        // Check duplicates
        const existingSlug = await prisma.clinic.findUnique({ where: { slug } });
        if (existingSlug) return res.status(400).json({ error: "Slug already exists" });

        const existingEmail = await prisma.user.findUnique({ where: { email: adminEmail } });
        if (existingEmail) return res.status(400).json({ error: "Email already exists" });

        // Transaction
        const hashedPassword = await bcrypt.hash(password, 12);

        const result = await prisma.$transaction(async (tx) => {
            const clinic = await tx.clinic.create({
                data: {
                    name: clinicName,
                    slug,
                    plan: plan || "PRO",
                    isActive: true,
                    contactInfo: adminEmail
                }
            });

            const branch = await tx.branch.create({
                data: {
                    name: `${clinicName} Merkez`,
                    city: "İstanbul",
                    clinicId: clinic.id
                }
            });

            const user = await tx.user.create({
                data: {
                    name: adminName,
                    email: adminEmail,
                    role: 'admin',
                    password: hashedPassword,
                    clinicId: clinic.id,
                    branchId: branch.id,
                    isActive: true
                }
            });

            return { clinic, user };
        });

        res.json({
            success: true,
            message: "Tenant created successfully",
            clinic: result.clinic,
            admin: result.user.email
        });

    } catch (e) {
        next(e);
    }
};

// Update Clinic Plan or Status
exports.updateClinic = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { plan, isActive } = req.body;

        const clinic = await prisma.clinic.update({
            where: { id },
            data: {
                ...(plan && { plan }),
                ...(typeof isActive === 'boolean' && { isActive })
            }
        });

        res.json(clinic);
    } catch (e) {
        next(e);
    }
};
