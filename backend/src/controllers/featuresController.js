const prisma = require('../config/prisma');
const fs = require('fs');
const path = require('path');

// AI
exports.queryAI = async (req, res, next) => {
    const { prompt } = req.body;
    const lowerPrompt = prompt.toLowerCase();
    try {
        let answer = "Bu konuda verilerinizi analiz ediyorum...";
        // Basic Rule-Based Response Generation for V1
        if (lowerPrompt.includes("randevu") || lowerPrompt.includes("ajanda")) {
            const count = await prisma.appointment.count({ where: { date: { gte: new Date() } } });
            answer = `Şu an sistemde gelecekteki toplam ${count} randevunuz görünüyor.`;
        } else if (lowerPrompt.includes("hasta")) {
            const count = await prisma.patient.count();
            answer = `Toplamda ${count} kayıtlı hastanız var.`;
        } else if (lowerPrompt.includes("gelir")) {
            const invoices = await prisma.invoice.findMany();
            const total = invoices.reduce((sum, inv) => sum + inv.amount, 0);
            answer = `Şu ana kadar kesilen faturaların toplam tutarı ₺${total.toLocaleString('tr-TR')}.`;
        } else {
            answer = "Neo AI olarak kliniğinizi 7/24 takip ediyorum.";
        }
        res.json({ answer });
    } catch (e) { next(e); }
};

exports.getRecommendations = async (req, res, next) => {
    try {
        const { patientId } = req.params; // Changed from id to patientId to be safe
        const recommendationService = require('../services/recommendationService');
        const suggestions = await recommendationService.getRecommendation(patientId);
        res.json(suggestions || []);
    } catch (e) { next(e); }
};

// Marketing
const messaging = require('../services/messaging');
const emailService = require('../services/emailService');
const iysService = require('../services/iysService');

exports.sendCampaign = async (req, res, next) => {
    try {
        const { title, message, channel, targetAudience } = req.body;

        // 1. Create Campaign Record
        const campaign = await prisma.campaign.create({
            data: {
                title,
                message,
                channel,
                targetAudience,
                status: 'processing'
            }
        });

        // 2. Select Audience
        let patients = [];
        if (targetAudience === 'leads') {
            patients = await prisma.patient.findMany({ where: { status: 'lead' } });
        } else {
            patients = await prisma.patient.findMany(); // All
        }

        // 3. Send Async (Fire & Forget loop)
        // In prod, use a queue (BullMQ). Here: simple loop.
        let sentCount = 0;

        (async () => {
            for (const p of patients) {
                const recipient = channel === 'email' ? p.email : p.phoneNumber;
                if (!recipient) continue;

                // Check Consent / Opt-out
                const allowed = await iysService.checkConsent(recipient, channel.toUpperCase());
                if (!allowed) {
                    console.log(`[Campaign] Skipped ${recipient} due to opt-out`);
                    continue;
                }

                // Append Opt-out Link
                const optOutLink = `https://api.icy.com/public/optout?contact=${recipient}&channel=${channel}`;
                const finalMsg = `${message}\n\nİptal: ${optOutLink}`;

                let success = false;
                if (channel === 'email') {
                    // Email supports HTML
                    success = await emailService.sendEmail(recipient, title, `<p>${message}</p><br><a href="${optOutLink}">Unsubscribe</a>`, campaign.id);
                } else {
                    // SMS / WhatsApp
                    // Messaging Service needs update to return success boolean or throw
                    try {
                        await messaging.sendMessage(channel, recipient, finalMsg, null, null);
                        success = true;
                    } catch (e) { success = false; }
                }

                if (success) {
                    sentCount++;
                    // Log details are handled inside services usually, or here:
                    await prisma.campaignLog.create({
                        data: {
                            campaignId: campaign.id,
                            recipient: recipient,
                            status: 'sent'
                        }
                    });
                }
            }

            // Update Campaign Stats
            await prisma.campaign.update({
                where: { id: campaign.id },
                data: { status: 'completed', sentCount }
            });
        })();

        res.json({ success: true, campaignId: campaign.id, message: "Campaign started" });
    } catch (e) { next(e); }
};

// Support
exports.createTicket = async (req, res, next) => {
    try {
        const { subject, message } = req.body;
        const ticket = await prisma.supportTicket.create({
            data: { subject, message, userId: req.user.id }
        });
        res.json(ticket);
    } catch (e) { next(e); }
};

// Photos
exports.uploadPhoto = async (req, res, next) => {
    try {
        const { patientId, type, imageBase64, notes } = req.body;
        if (!imageBase64) return res.status(400).json({ error: "No image data" });

        const filename = `photo_${Date.now()}.jpg`;
        // Navigate up from src/controllers to backend/public/uploads
        const filepath = path.join(__dirname, '..', '..', 'public', 'uploads', filename);

        // Ensure directory exists
        const dir = path.dirname(filepath);
        if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

        const base64Data = imageBase64.replace(/^data:image\/\w+;base64,/, "");
        fs.writeFileSync(filepath, base64Data, 'base64');
        const fileUrl = `/uploads/${filename}`;

        const photo = await prisma.photoEntry.create({
            data: {
                patientId,
                beforeUrl: type === 'before' ? fileUrl : null,
                afterUrl: type === 'after' ? fileUrl : null,
                notes: notes || "Yüklenen Fotoğraf",
                date: new Date()
            }
        });
        res.json(photo);
    } catch (e) { next(e); }
};

// Health Tourism
exports.getTransfers = async (req, res, next) => {
    try {
        const transfers = await prisma.transfer.findMany({ where: { patientId: req.params.id } });
        res.json(transfers);
    } catch (e) { next(e); }
};
exports.createTransfer = async (req, res, next) => {
    try {
        const { patientId, pickupTime, pickupLocation, dropoffLocation, driverName } = req.body;
        const transfer = await prisma.transfer.create({
            data: { patientId, pickupTime: new Date(pickupTime), pickupLocation, dropoffLocation, driverName }
        });
        res.json(transfer);
    } catch (e) { next(e); }
};

exports.getAccommodations = async (req, res, next) => {
    try {
        const acc = await prisma.accommodation.findMany({ where: { patientId: req.params.id } });
        res.json(acc);
    } catch (e) { next(e); }
};
exports.createAccommodation = async (req, res, next) => {
    try {
        const { patientId, hotelName, checkInDate, checkOutDate, roomType } = req.body;
        const acc = await prisma.accommodation.create({
            data: { patientId, hotelName, checkInDate: new Date(checkInDate), checkOutDate: new Date(checkOutDate), roomType }
        });
        res.json(acc);
    } catch (e) { next(e); }
};
