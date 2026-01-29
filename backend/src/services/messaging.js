const prisma = require('../config/prisma');
const axios = require('axios');

// Providers Config (Env variables would be used here in prod)
const WHATSAPP_API_URL = process.env.WHATSAPP_API_URL || 'https://graph.facebook.com/v17.0/YOUR_PHONE_ID/messages';
const SMS_API_URL = process.env.SMS_API_URL || 'https://api.netgsm.com.tr/sms/send';

/**
 * Universal Message Sender
 * @param {string} channel - 'whatsapp' | 'sms'
 * @param {string} recipient - Phone number
 * @param {string} content - Message text
 * @param {string} userId - Optional: Staff ID sending the message
 */
exports.sendMessage = async (channel, recipient, content, userId = null, conversationId = null) => {
    let status = 'pending';
    let errorLog = null;

    try {
        console.log(`[Messaging] Sending ${channel} to ${recipient}: ${content}`);

        if (channel === 'whatsapp') {
            // await sendWhatsApp(recipient, content);
            status = 'sent'; // Simulator
        } else if (channel === 'sms') {
            // await sendSMS(recipient, content);
            status = 'sent'; // Simulator
        } else {
            throw new Error(`Unsupported channel: ${channel}`);
        }

    } catch (e) {
        console.error(`[Messaging] Failed:`, e.message);
        status = 'failed';
        errorLog = e.message;
    }

    // STRICT REQUIREMENT: Log to DB
    const log = await prisma.messageLog.create({
        data: {
            type: channel.toUpperCase(), // WHATSAPP, SMS
            recipient: recipient,
            content: content,
            status: status,
            // metadata: errorLog ? JSON.stringify({ error: errorLog }) : null
        }
    });

    // If part of a conversation, also log there (for UI chat history)
    if (conversationId) {
        await prisma.message.create({
            data: {
                content: content,
                isFromUser: false, // Outbound
                conversationId: conversationId,
                userId: userId
            }
        });
    }

    return log;
};

// -- Private Adapters --

async function sendWhatsApp(to, text) {
    // Implementation for Meta Cloud API
    /*
    await axios.post(WHATSAPP_API_URL, {
        messaging_product: "whatsapp",
        to: to,
        text: { body: text }
    }, { headers: { Authorization: `Bearer ${process.env.WA_TOKEN}` } });
    */
    return true;
}

async function sendSMS(to, text) {
    // Implementation for NetGSM or Twilio
    return true;
}
