const prisma = require('../config/prisma');

// FINANCE
exports.getInvoices = async (req, res, next) => {
    try {
        const inv = await prisma.invoice.findMany({ where: { patientId: req.params.id } });
        res.json(inv);
    } catch (e) { next(e); }
};

const eInvoiceService = require('../services/eInvoiceService');

exports.generateInvoice = async (req, res, next) => {
    try {
        const { patientId, amount, description, performerId } = req.body; // performerId added
        if (!amount || amount <= 0) throw new Error("Invalid amount");

        // 1. Create Invoice
        const invoice = await prisma.invoice.create({
            data: {
                patientId,
                amount: parseFloat(amount),
                description,
                status: 'paid', // Assuming instant payment for simplicity
                invoiceDate: new Date()
            }
        });

        // 2. Try E-Invoice Integration through Service
        try {
            await eInvoiceService.createEInvoice(invoice.id);
        } catch (err) {
            console.error("[Finance] E-Invoice Failed:", err.message);
            // Don't fail the request, just log.
        }

        // 3. Commission Calculation
        if (performerId) {
            const performer = await prisma.user.findUnique({ where: { id: performerId } });
            if (performer) {
                // Find Rule
                const rule = await prisma.commissionRule.findFirst({
                    where: {
                        OR: [
                            { userId: performer.id },
                            { role: performer.role }
                        ]
                    },
                    orderBy: { userId: 'desc' } // Specific user rule takes precedence
                });

                if (rule) {
                    let commission = 0;
                    if (rule.type === 'percentage') {
                        commission = (amount * rule.value) / 100;
                    } else {
                        commission = rule.value;
                    }

                    // Update Performance Record
                    const currentMonth = new Date().toISOString().slice(0, 7); // YYYY-MM

                    const perf = await prisma.staffPerformance.findFirst({
                        where: { userId: performer.id, month: currentMonth }
                    });

                    if (perf) {
                        await prisma.staffPerformance.update({
                            where: { id: perf.id },
                            data: {
                                actualAmount: perf.actualAmount + amount,
                                commissionEarned: perf.commissionEarned + commission
                            }
                        });
                    } else {
                        await prisma.staffPerformance.create({
                            data: {
                                userId: performer.id,
                                month: currentMonth,
                                targetAmount: 100000, // Default Target
                                actualAmount: amount,
                                commissionEarned: commission
                            }
                        });
                    }

                    // Create Financial Transaction (Expense for Clinic)
                    // We need a CurrentAccount for the staff
                    // For now, simpler implementation: Just log via console or update 'balance' if User had one.
                    console.log(`[Finance] Commission calculated for ${performer.name}: ${commission} TRY`);
                }
            }
        }

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
