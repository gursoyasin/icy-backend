const prisma = require('../config/prisma');

exports.getConversations = async (req, res, next) => {
    try {
        const conversations = await prisma.conversation.findMany({
            include: { messages: { take: 1, orderBy: { createdAt: 'desc' } } }
        });
        res.json(conversations);
    } catch (e) { next(e); }
};

exports.getMessages = async (req, res, next) => {
    try {
        const messages = await prisma.message.findMany({
            where: { conversationId: req.params.id },
            orderBy: { createdAt: 'asc' },
            include: { user: true }
        });
        res.json(messages);
    } catch (e) { next(e); }
};

exports.sendMessage = async (req, res, next) => {
    try {
        const { conversationId, content } = req.body;
        const message = await prisma.message.create({
            data: {
                conversationId,
                content,
                userId: req.user.id,
                isFromUser: true
            }
        });

        const io = req.app.get('io');
        if (io) io.to(conversationId).emit('receive_message', message);

        res.json(message);
    } catch (e) { next(e); }
};

exports.webhook = async (req, res, next) => {
    const { platform } = req.params;
    const payload = req.body;

    // Logger shouldn't be here directly but we can log
    console.log(`Received ${platform} webhook:`, payload);

    try {
        const senderContact = payload.from || payload.sender || "+905550000000";
        const content = payload.message || payload.text || "Media received";
        const channelId = payload.channelId || "UNKNOWN_CHANNEL";

        let conv = await prisma.conversation.findFirst({
            where: { contact: senderContact, platform }
        });

        if (!conv) {
            conv = await prisma.conversation.create({
                data: { platform, contact: senderContact, channelId }
            });
        }

        const msg = await prisma.message.create({
            data: {
                content,
                isFromUser: false,
                conversationId: conv.id
            }
        });

        const io = req.app.get('io');
        if (io) io.emit('new_message', { conversationId: conv.id, message: msg });

        res.json({ status: "processed" });
    } catch (e) { next(e); }
};

exports.getNotifications = async (req, res, next) => {
    // Return empty array for now or fetch from DB if Notification model exists
    // To prevent crash, we return empty list valid JSON.
    res.json([]);
};

exports.getCalls = async (req, res, next) => {
    // Return empty array for now
    res.json([]);
};
