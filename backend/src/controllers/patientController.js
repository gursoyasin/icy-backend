const prisma = require('../config/prisma');

// 1. Get All Patients (with Search & Pagination implementation plan)
exports.getPatients = async (req, res, next) => {
    try {
        const { search, limit } = req.query;

        let where = {};

        // STRICT MULTI-TENANCY: Clinic Isolation
        // Admin sees ALL branches in the clinic.
        // Staff/Doctor sees ONLY their branch (Optional refinement, but user said "Admin sees all")

        // Base Rule: Must belong to User's Clinic
        where.branch = { clinicId: req.user.clinicId };

        // Sub-rule: If NOT Admin, restrict to specific branch? 
        // User scenario didn't specify Staff/Doctor cross-branch access, but keeping it strict for now.
        // If Role != Admin -> Restrict to Branch
        if (req.user.role !== 'admin') {
            where.branchId = req.user.branchId;
        }

        // Search Implementation (B4)
        if (search) {
            where.OR = [
                { fullName: { contains: search } }, // Case-insensitive handled by DB usually, or need mode: 'insensitive' if PG
                { phoneNumber: { contains: search } }
            ];
        }

        const patients = await prisma.patient.findMany({
            where: where,
            orderBy: { createdAt: 'desc' },
            take: limit ? parseInt(limit) : undefined
        });

        res.json(patients);
    } catch (e) { next(e); }
};

// 2. Get Single Patient (B4)
exports.getPatient = async (req, res, next) => {
    try {
        const { id } = req.params;
        const patient = await prisma.patient.findUnique({
            where: { id },
            include: {
                appointments: { orderBy: { date: 'desc' } },
                invoices: true,
                photos: true
            }
        });

        if (!patient) return res.status(404).json({ error: "Patient not found" });

        // Security Check: Isolation
        if (req.user.role !== 'admin' && patient.branchId !== req.user.branchId) {
            return res.status(403).json({ error: "Access denied" });
        }

        // Hide sensitive info for Assistant/Staff
        if (req.user.role === 'staff') {
            patient.notes = null; // Hide Treatment Notes
            patient.invoices = []; // Hide Finances
        }

        res.json(patient);
    } catch (e) { next(e); }
};

// 3. Create Patient (Existing)
exports.createPatient = async (req, res, next) => {
    try {
        const patient = await prisma.patient.create({
            data: {
                ...req.body,
                branchId: req.user.branchId
            }
        });
        res.json(patient);
    } catch (e) { next(e); }
};

// 4. Update Patient & Notes (B4)
exports.updatePatient = async (req, res, next) => {
    try {
        const { id } = req.params;
        const updateData = req.body;

        // If appending a note (Special Helper)
        if (updateData.appendNote) {
            const current = await prisma.patient.findUnique({ where: { id }, select: { notes: true } });
            const newNote = `\n[${new Date().toLocaleDateString()}] ${updateData.appendNote}`;
            updateData.notes = (current.notes || "") + newNote;
            delete updateData.appendNote;
        }

        const patient = await prisma.patient.update({
            where: { id },
            data: updateData
        });

        // LEGAL: Audit Update
        const audit = require('../utils/audit');
        audit.logAudit(req.user.email, 'UPDATE_PATIENT', id, `Updated fields: ${Object.keys(updateData).join(', ')}`);

        res.json(patient);
    } catch (e) { next(e); }
};

// 5. Delete Patient (Existing)
exports.deletePatient = async (req, res, next) => {
    const audit = require('../utils/audit');
    try {
        const patientId = req.params.id;

        // 1. LEGAL: Audit Initiation
        audit.logAudit(req.user.email, 'DELETE_INIT', patientId, 'Right TO Be Forgotten request started');

        // Manual Cascade for safety
        await prisma.appointment.deleteMany({ where: { patientId } });
        await prisma.transfer.deleteMany({ where: { patientId } });
        await prisma.accommodation.deleteMany({ where: { patientId } });
        await prisma.invoice.deleteMany({ where: { patientId } });
        await prisma.photoEntry.deleteMany({ where: { patientId } });
        await prisma.callLog.deleteMany({ where: { patientId } });
        await prisma.surveyResult.deleteMany({ where: { patientId } });

        await prisma.patient.delete({ where: { id: patientId } });

        // 2. LEGAL: Audit Completion
        audit.logAudit(req.user.email, 'DELETE_COMPLETE', patientId, 'Patient and all sub-records permanently destroyed');

        res.json({ success: true });
    } catch (e) { next(e); }
};
