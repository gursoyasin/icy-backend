const prisma = require('../config/prisma');

exports.getDailySummary = async (req, res, next) => {
    try {
        const today = new Date();
        const start = new Date(today.setHours(0, 0, 0, 0));
        const end = new Date(today.setHours(23, 59, 59, 999));

        const appointments = await prisma.appointment.findMany({
            where: { date: { gte: start, lte: end } },
            include: { doctor: true }
        });

        const total = appointments.length;
        const noshows = appointments.filter(a => a.status === 'no-show').length;
        const completed = appointments.filter(a => a.status === 'completed' || a.status === 'arrived').length;

        let report = `📅 *Günlük Özet Raporu (${start.toLocaleDateString()})*\n\n`;
        report += `✅ Toplam Randevu: ${total}\n`;
        report += `👨‍⚕️ Tamamlanan: ${completed}\n`;
        report += `❌ Gelmeyen (No-Show): ${noshows}\n`;
        // Estimated Revenue (Avg 2500 TL per appointment)
        report += `💰 Tahmini Ciro: ${(completed * 2500).toLocaleString('tr-TR')} TL\n\n`;

        report += `*Doktor Bazlı:*\n`;
        const doctorStats = {};
        appointments.forEach(a => {
            const name = a.doctor.name || 'Bilinmeyen';
            if (!doctorStats[name]) doctorStats[name] = 0;
            doctorStats[name]++;
        });

        for (const [doc, count] of Object.entries(doctorStats)) {
            report += `- ${doc}: ${count} randevu\n`;
        }

        res.json({
            success: true,
            reportText: report,
            stats: { total, noshows, completed }
        });

    } catch (e) { next(e); }
};
