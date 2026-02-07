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
            await sendWhatsApp(recipient, content);
            status = 'sent';
        } else if (channel === 'sms') {
            await sendSMS(recipient, content);
            status = 'sent';
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
    // Meta Cloud API Implementation
    const url = process.env.WHATSAPP_API_URL;
    const token = process.env.WA_TOKEN;

    if (!url || !token) {
        console.warn("[Messaging] WhatsApp credentials missing. Skipping.");
        throw new Error("WhatsApp credentials missing");
    }

    const response = await axios.post(url, {
        messaging_product: "whatsapp",
        to: to,
        type: "text",
        text: { body: text }
    }, {
        headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
        }
    });

    return response.data;
}

async function sendSMS(to, text) {
    // NetGSM XML API Implementation
    const url = process.env.SMS_API_URL || 'https://api.netgsm.com.tr/sms/send/xml';
    const user = process.env.NETGSM_USER;
    const pass = process.env.NETGSM_PASS;
    const header = process.env.NETGSM_HEADER;

    if (!user || !pass || !header) {
        console.warn("[Messaging] NetGSM credentials missing. Skipping.");
        throw new Error("NetGSM credentials missing");
    }

    const xmlData = `<?xml version="1.0"?>
    <mainbody>
        <header>
            <company dil="TR">Netgsm</company>
            <usercode>${user}</usercode>
            <password>${pass}</password>
            <type>1:n</type>
            <msgheader>${header}</msgheader>
        </header>
        <body>
            <msg><![CDATA[${text}]]></msg>
            <no>${to}</no>
        </body>
    </mainbody>`;

    const response = await axios.post(url, xmlData, {
        headers: { 'Content-Type': 'text/xml' }
    });

    // NetGSM returns 00, 01, 02 etc. as plain text or small XML
    // Checks for successful response code (starts with 00 usually means success id)
    if (response.data && response.data.toString().startsWith("0")) {
        return response.data;
    } else {
        throw new Error(`NetGSM Error: ${response.data}`);
    }
}
