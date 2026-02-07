const prisma = require('../config/prisma');

class RecommendationService {

    // Main function to get next best action for a patient
    async getRecommendation(patientId) {
        const patient = await prisma.patient.findUnique({
            where: { id: patientId },
            include: {
                appointments: { orderBy: { date: 'desc' }, take: 5 },
                transfers: true
            }
        });

        if (!patient) return null;

        const suggestions = [];

        // 1. Post-Op Retention (Hair Transplant -> PRP)
        const lastHT = patient.appointments.find(a => a.type === 'Hair Transplant' && a.status === 'completed');
        if (lastHT) {
            const daysSince = (new Date() - new Date(lastHT.date)) / (1000 * 60 * 60 * 24);
            if (daysSince > 30 && daysSince < 60) {
                suggestions.push({
                    type: "treatment",
                    title: "PRP Tedavisi Zamanı",
                    description: "Ekim sonrası 1. ay PRP tedavisi önerilir.",
                    confidence: 0.95
                });
            }
        }

        // 2. Cross-Sell (Botox -> Filler)
        const lastBotox = patient.appointments.find(a => a.type === 'Botox' && a.status === 'completed');
        if (lastBotox) {
            const daysSince = (new Date() - new Date(lastBotox.date)) / (1000 * 60 * 60 * 24);
            if (daysSince > 90) {
                suggestions.push({
                    type: "recall",
                    title: "Botox Yenileme",
                    description: "Etki süresi azalmış olabilir, kontrol randevusu önerin.",
                    confidence: 0.85
                });
            }
        }

        // 3. AI "Smart" Guess (Mock)
        if (suggestions.length === 0) {
            suggestions.push({
                type: "general",
                title: "Cilt Bakımı Kampanyası",
                description: "Bu hasta profilindeki kişiler genellikle cilt bakımına ilgi duyuyor.",
                confidence: 0.40
            });
        }

        return suggestions;
    }
}

module.exports = new RecommendationService();
