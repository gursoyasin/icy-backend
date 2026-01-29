const prisma = require('../config/prisma');

// FINANCE
exports.getInvoices = async (req, res, next) => {
    try {
        const inv = await prisma.invoice.findMany({ where: { patientId: req.params.id } });
        res.json(inv);
    } catch (e) { next(e); }
};

exports.generateInvoice = async (req, res, next) => {
    try {
        const { patientId, amount, description } = req.body;
        if (!amount || amount <= 0) throw new Error("Invalid amount");

        const eInvoiceNumber = `GIB${new Date().getFullYear()}${Math.floor(Math.random() * 1000000000)}`;

        const invoice = await prisma.invoice.create({
            data: {
                patientId,
                amount: parseFloat(amount),
                description,
                status: 'paid',
                eInvoiceNumber
            }
        });
        res.json(invoice);
    } catch (e) { next(e); }
};

// ADMIN (Clinic Onboarding)
exports.createClinic = async (req, res, next) => {
    try {
        const { clinicName, city, adminName, email, password } = req.body;

        const branch = await prisma.branch.create({
            data: {
                name: clinicName,
                city: city || 'İstanbul',
                address: 'Yeni Kayıt'
            }
        });

        const user = await prisma.user.create({
            data: {
                name: adminName,
                email: email,
                password: password, // Should be hashed
                role: 'admin',
                branchId: branch.id
            }
        });

        res.json({ success: true, branch, user });
    } catch (e) { next(e); }
};
