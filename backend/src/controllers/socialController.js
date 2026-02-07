const prisma = require('../config/prisma');
const logger = require('../utils/logger');
const messaging = require('../services/messaging');

// GET /api/social/webhook (Verification)
exports.verifyWebhook = (req, res) => {
    const mode = req.query['hub.mode'];
    const token = req.query['hub.verify_token'];
    const challenge = req.query['hub.challenge'];

    if (mode && token) {
        if (mode === 'subscribe' && token === process.env.META_WEBHOOK_VERIFY_TOKEN) {
            logger.info('[Social] Webhook verified');
            res.status(200).send(challenge);
        } else {
            res.sendStatus(403);
        }
    } else {
        res.sendStatus(400); // Invalid request
    }
};

// POST /api/social/webhook (Event)
exports.handleWebhook = async (req, res) => {
    try {
        const body = req.body;

        if (body.object === 'page' || body.object === 'instagram') {

            // Iterate over each entry - there may be multiple if batched
            for (const entry of body.entry) {
                // Get the webhook event. entry.messaging is an array, but usually contains one event
                const webhookEvent = entry.messaging[0];

                const senderId = webhookEvent.sender.id;
                const recipientId = webhookEvent.recipient.id;
                const messageText = webhookEvent.message?.text;

                if (messageText) {
                    logger.info(`[Social] Received message from ${senderId}: ${messageText}`);

                    // Find or Create Conversation
                    // Note: senderId is Page Scoped ID (PSID)

                    let conversation = await prisma.conversation.findFirst({
                        where: {
                            channelId: senderId,
                            platform: body.object === 'instagram' ? 'instagram' : 'facebook'
                        }
                    });

                    if (!conversation) {
                        conversation = await prisma.conversation.create({
                            data: {
                                platform: body.object === 'instagram' ? 'instagram' : 'facebook',
                                contact: senderId, // Store PSID as contact for social
                                channelId: senderId,
                                metadata: { pageId: recipientId }
                            }
                        });
                    }

                    // Save Message
                    await prisma.message.create({
                        data: {
                            conversationId: conversation.id,
                            content: messageText,
                            isFromUser: true // From external user to us
                        }
                    });

                    // Optional: Auto-reply or notify staff via Socket.io
                }
            }

            res.status(200).send('EVENT_RECEIVED');
        } else {
            res.sendStatus(404);
        }
    } catch (e) {
        logger.error(`[Social] Webhook Error: ${e.message}`);
        res.sendStatus(500);
    }
};

// POST /api/social/reply
exports.replyToMessage = async (req, res) => {
    try {
        const { conversationId, content } = req.body;

        const conversation = await prisma.conversation.findUnique({
            where: { id: conversationId }
        });

        if (!conversation) return res.status(404).json({ error: "Conversation not found" });

        // Use Messaging Service or Direct API call to reply
        // Implementation depends on platform (WA, IG, FB)
        // For now logging it mockly

        logger.info(`[Social] Replying to ${conversation.contact} via ${conversation.platform}: ${content}`);

        // Save reply in DB
        await prisma.message.create({
            data: {
                conversationId: conversation.id,
                content: content,
                isFromUser: false // From clinic staff
            }
        });

        res.json({ success: true });

    } catch (e) {
        logger.error(`[Social] Reply Error: ${e.message}`);
        res.status(500).json({ error: e.message });
    }
};

// GET /api/conversations
exports.getConversations = async (req, res, next) => {
    try {
        const conversations = await prisma.conversation.findMany({
            orderBy: { updatedAt: 'desc' },
            include: {
                messages: {
                    orderBy: { createdAt: 'desc' },
                    take: 1
                }
            }
        });

        // Format for frontend
        const data = conversations.map(c => ({
            id: c.id,
            platform: c.platform,
            contact: c.contact,
            lastMessage: c.messages[0]?.content || '',
            updatedAt: c.updatedAt
        }));

        res.json(data);
    } catch (e) { next(e); }
};

// GET /api/conversations/:id/messages
exports.getMessages = async (req, res, next) => {
    try {
        const { id } = req.params;
        const messages = await prisma.message.findMany({
            where: { conversationId: id },
            orderBy: { createdAt: 'asc' }
        });
        res.json(messages);
    } catch (e) { next(e); }
};

// POST /api/messages (New Conversation or Reply)
exports.sendMessage = async (req, res, next) => {
    // Basic wrapper, in real app might need to create conversation if not exists
    // For now assuming existing conversationId is passed, similar to replyToMessage
    return exports.replyToMessage(req, res, next);
};
