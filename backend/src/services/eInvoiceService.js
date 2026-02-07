const prisma = require('../config/prisma');
const axios = require('axios');
const xmlbuilder = require('xmlbuilder'); // You might need to add this dependency

exports.createEInvoice = async (invoiceId) => {
    // 1. Fetch Invoice Data
    const invoice = await prisma.invoice.findUnique({
        where: { id: invoiceId },
        include: { patient: true }
    });

    if (!invoice) throw new Error("Invoice not found");

    // 2. Fetch Active E-Invoice Profile
    const profile = await prisma.eInvoiceProfile.findFirst({
        where: { isActive: true }
    });

    if (!profile) {
        console.warn("[E-Invoice] No active profile found. Skipping.");
        return null;
    }

    // 3. Adapter Logic (Example: BizimHesap / Sovos / NetGSM)
    // Construct XML UBL 2.1
    const xml = xmlbuilder.create('Invoice')
        .ele('cbc:UBLVersionID', '2.1').up()
        .ele('cbc:ID', invoice.id).up()
        .ele('cbc:IssueDate', new Date().toISOString().split('T')[0]).up()
        .ele('cac:AccountingSupplierParty', { /* ... Clinic Info ... */ }).up()
        .ele('cac:AccountingCustomerParty')
        .ele('cac:Party')
        .ele('cac:PartyName')
        .ele('cbc:Name', invoice.patient.fullName).up()
        .up()
        .up()
        .up()
        .ele('cac:LegalMonetaryTotal')
        .ele('cbc:PayableAmount', { 'currencyID': 'TRY' }, invoice.amount).up()
        .up()
        .end({ pretty: true });

    // 4. Send to Provider
    // Mocking the API call for V1 as we don't have real credentials
    console.log(`[E-Invoice] Sending to ${profile.provider}...`);
    // const response = await axios.post(PROVIDER_URL, { xml, apiKey: profile.apiKey });

    // 5. Update Invoice with GIB Number
    const gibNumber = `GIB${new Date().getFullYear()}${Math.floor(Math.random() * 1000000000)}`; // Mock response

    await prisma.invoice.update({
        where: { id: invoiceId },
        data: { eInvoiceNumber: gibNumber }
    });

    return gibNumber;
};
