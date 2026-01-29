const prisma = require('../config/prisma');

// Basic Stats
exports.getStats = async (req, res, next) => {
    try {
        const branchFilter = req.user.role === 'admin' ? {} : { branchId: req.user.branchId };

        // Date Ranges
        const now = new Date();
        const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
        const startOfLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
        const endOfLastMonth = new Date(now.getFullYear(), now.getMonth(), 0);

        // Helper for Growth Calculation
        const calcGrowth = (current, previous) => {
            if (previous === 0) return current > 0 ? 100 : 0;
            return Math.round(((current - previous) / previous) * 100);
        };

        // 1. Appointments
        const currentAppointments = await prisma.appointment.count({
            where: { date: { gte: startOfMonth } }
        });
        const lastMonthAppointments = await prisma.appointment.count({
            where: { date: { gte: startOfLastMonth, lte: endOfLastMonth } }
        });
        const apptGrowth = calcGrowth(currentAppointments, lastMonthAppointments);

        // 2. Active Patients (New this month)
        const totalPatients = await prisma.patient.count({ where: branchFilter });
        const activePatients = await prisma.patient.count({ where: { ...branchFilter, status: 'active' } });

        const newPatientsCheck = await prisma.patient.count({
            where: { ...branchFilter, createdAt: { gte: startOfMonth } }
        });
        const lastMonthPatients = await prisma.patient.count({
            where: { ...branchFilter, createdAt: { gte: startOfLastMonth, lte: endOfLastMonth } }
        });
        const patientGrowth = calcGrowth(newPatientsCheck, lastMonthPatients);

        // 3. Revenue (Real Invoices)
        const revenueAgg = await prisma.invoice.aggregate({
            _sum: { amount: true },
            where: { invoiceDate: { gte: startOfMonth } }
        });
        const revenue = revenueAgg._sum.amount || 0;

        const lastRevenueAgg = await prisma.invoice.aggregate({
            _sum: { amount: true },
            where: { invoiceDate: { gte: startOfLastMonth, lte: endOfLastMonth } }
        });
        const lastRevenue = lastRevenueAgg._sum.amount || 0;
        const revenueGrowth = calcGrowth(revenue, lastRevenue);

        // Security: Hide sensitive financial data for non-admins
        const isAdmin = req.user.role === 'admin';

        res.json({
            totalPatients,
            activePatients,
            upcomingAppointments: currentAppointments,
            reservedAppointments: await prisma.appointment.count({ where: { date: { gte: now } } }),
            monthlyRevenue: isAdmin ? revenue : 0, // HIDE FOR STAFF/DOCTOR
            trends: {
                appointments: apptGrowth,
                patients: patientGrowth,
                revenue: isAdmin ? revenueGrowth : 0 // HIDE FOR STAFF/DOCTOR
            }
        });
    } catch (e) { next(e); }
};

// Detailed Analytics (Revenue, Sources, Efficiency)
exports.getAnalytics = async (req, res, next) => {
    try {
        const today = new Date();

        // 1. Revenue (Last 7 Days)
        const revenueData = [];
        for (let i = 0; i < 7; i++) {
            const d = new Date(today);
            d.setDate(today.getDate() - i);
            const start = new Date(d.setHours(0, 0, 0, 0));
            const end = new Date(d.setHours(23, 59, 59, 999));

            const dailyInvoices = await prisma.invoice.aggregate({
                where: { createdAt: { gte: start, lte: end } },
                _sum: { amount: true }
            });

            revenueData.push({
                date: start.toISOString().split('T')[0],
                day: start.toLocaleDateString('tr-TR', { weekday: 'short' }),
                amount: dailyInvoices._sum.amount || 0
            });
        }

        // 2. Sources (Real DB Aggregation)
        const sourceGroups = await prisma.patient.groupBy({
            by: ['source'],
            _count: { source: true }
        });

        const sources = sourceGroups.map(g => ({
            label: g.source,
            count: g._count.source
        }));

        // 3. Efficiency & Graft Stats
        const totalLeads = await prisma.patient.count({ where: { status: 'lead' } });
        const totalPatients = await prisma.patient.count();
        const conversionRate = totalPatients > 0 ? ((totalPatients - totalLeads) / totalPatients * 100).toFixed(1) : 0;

        // 4. No-Show Rate
        const totalPastAppointments = await prisma.appointment.count({
            where: { date: { lte: new Date() } }
        });
        const noShowCount = await prisma.appointment.count({
            where: { status: 'no-show', date: { lte: new Date() } }
        });
        const noShowRate = totalPastAppointments > 0 ? ((noShowCount / totalPastAppointments) * 100).toFixed(1) : 0;

        // 5. Doctor Workload (Appointments per Doctor)
        const doctorWorkloadGroup = await prisma.appointment.groupBy({
            by: ['doctorId'],
            _count: { id: true },
            where: { date: { gte: new Date(new Date().setDate(new Date().getDate() - 30)) } } // Last 30 days
        });

        // Resolve Doctor Names
        const doctorWorkload = [];
        for (const work of doctorWorkloadGroup) {
            const doc = await prisma.user.findUnique({ where: { id: work.doctorId } });
            if (doc) {
                doctorWorkload.push({ name: doc.name, count: work._count.id });
            }
        }


        // Graft Count Average
        const graftStats = await prisma.appointment.aggregate({
            _avg: { graftCount: true },
            where: { graftCount: { not: null } }
        });
        const avgGraft = Math.round(graftStats._avg.graftCount || 0);

        res.json({
            revenue: revenueData.reverse(),
            sources: sources,
            conversionRate: conversionRate,
            avgGraft: avgGraft,
            noShowRate: noShowRate,
            doctorWorkload: doctorWorkload
        });
    } catch (e) { next(e); }
};
