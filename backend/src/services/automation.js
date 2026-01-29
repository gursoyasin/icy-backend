const axios = require('axios');
const prisma = require('../config/prisma');

// Base N8N Webhook URL (configured via ENV)
const N8N_BASE_URL = process.env.N8N_WEBHOOK_URL || 'http://localhost:5678/webhook';

/**
 * Triggers an n8n workflow via Webhook
 * @param {string} trigger - Event name (e.g. 'appointment_created')
 * @param {object} payload - Data to send (e.g. appointment details)
 */
async function triggerWorkflow(trigger, payload) {
    const url = `${N8N_BASE_URL}/${trigger}`;

    try {
        console.log(`[Automation] Triggering ${trigger} to ${url}...`);

        // Ensure AutomationLog is created
        await prisma.automationLog.create({
            data: {
                workflowName: trigger,
                trigger: 'backend_event',
                status: 'pending',
                metadata: JSON.stringify(payload)
            }
        });

        // In real prod, enable valid axios call:
        // await axios.post(url, payload);

        console.log(`[Automation] Simulated sending to n8n: Success`);

        // Update Log to success
        // In real implementation, capture response ID

    } catch (error) {
        console.error(`[Automation] Failed to trigger ${trigger}:`, error.message);

        await prisma.automationLog.create({
            data: {
                workflowName: trigger,
                trigger: 'backend_event',
                status: 'failed',
                metadata: JSON.stringify({ error: error.message, payload })
            }
        });
    }
}

module.exports = {
    triggerWorkflow
};
