const prisma = require('../config/prisma');
const logger = require('../utils/logger');

const messaging = require('../services/messaging');

exports.login = async (req, res, next) => {
    const { email, password } = req.body;
    try {
        const user = await prisma.user.findFirst({
            where: { email },
            include: { branch: true }
        });

        if (!user) return res.status(401).json({ error: "User not found" });

        // Verify password
        const bcrypt = require('bcryptjs');
        const isValid = await bcrypt.compare(password, user.password);
        if (!isValid) return res.status(401).json({ error: "Invalid credentials" });

        // 2FA Logic
        if (user.twoFactorEnabled) {
            // Generate 6-digit code
            const code = Math.floor(100000 + Math.random() * 900000).toString();
            const expires = new Date(Date.now() + 5 * 60000); // 5 mins

            await prisma.user.update({
                where: { id: user.id },
                data: { twoFactorCode: code, twoFactorExpires: expires }
            });

            // Send Code (Assuming mock phone number if not present user logic usually has phone)
            // For now, send to console or try messaging if user has phone.
            // In User model, we don't strictly have phone, but let's assume we do or use email.
            // Using Email for 2FA as User has email.
            const emailService = require('../services/emailService');
            await emailService.sendEmail(user.email, "Giriş Kodu", `Giriş kodunuz: ${code}`);

            return res.json({ require2fa: true, userId: user.id, message: "Doğrulama kodu e-posta adresinize gönderildi." });
        }

        const jwt = require('jsonwebtoken');
        const token = jwt.sign(
            { id: user.id, role: user.role, branchId: user.branchId },
            process.env.JWT_SECRET,
            { expiresIn: '30d' }
        );

        logger.info(`User logged in: ${email}`);

        res.json({
            token,
            user: {
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                branch: user.branch
            }
        });
    } catch (e) {
        next(e);
    }
};

exports.verify2FA = async (req, res, next) => {
    try {
        const { userId, code } = req.body;
        const user = await prisma.user.findUnique({
            where: { id: userId },
            include: { branch: true }
        });

        if (!user || user.twoFactorCode !== code || new Date() > user.twoFactorExpires) {
            return res.status(401).json({ error: "Geçersiz veya süresi dolmuş kod." });
        }

        // Clear code
        await prisma.user.update({
            where: { id: user.id },
            data: { twoFactorCode: null, twoFactorExpires: null }
        });

        const jwt = require('jsonwebtoken');
        const token = jwt.sign(
            { id: user.id, role: user.role, branchId: user.branchId },
            process.env.JWT_SECRET,
            { expiresIn: '30d' }
        );

        res.json({
            token,
            user: {
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                branch: user.branch
            }
        });

    } catch (e) { next(e); }
};

exports.enable2FA = async (req, res, next) => {
    try {
        await prisma.user.update({
            where: { id: req.user.id },
            data: { twoFactorEnabled: true }
        });
        res.json({ success: true, message: "2FA Aktifleştirildi" });
    } catch (e) { next(e); }
};

exports.register = async (req, res, next) => {
    try {
        const { name, email, password, role } = req.body;

        const existing = await prisma.user.findFirst({ where: { email } });
        if (existing) return res.status(400).json({ error: "Email already in use" });

        // Hash password
        const bcrypt = require('bcryptjs');
        const hashedPassword = await bcrypt.hash(password, 10);

        const user = await prisma.user.create({
            data: {
                name,
                email,
                password: hashedPassword,
                role: role || 'staff',
                branchId: req.user ? req.user.branchId : null // Only if admin creating user
            }
        });

        const jwt = require('jsonwebtoken');
        const token = jwt.sign(
            { id: user.id, role: user.role, branchId: user.branchId },
            process.env.JWT_SECRET,
            { expiresIn: '30d' }
        );

        res.json({ user, token });
    } catch (e) {
        next(e);
    }
};

exports.changePassword = async (req, res, next) => {
    try {
        const { oldPassword, newPassword } = req.body;
        const userId = req.user.id;

        const user = await prisma.user.findUnique({ where: { id: userId } });
        if (!user) return res.status(404).json({ error: "User not found" });

        // Verify old password
        const bcrypt = require('bcryptjs');
        const isValid = await bcrypt.compare(oldPassword, user.password);
        if (!isValid) return res.status(401).json({ error: "Eski şifre hatalı" });

        // Hash new password
        const hashedPassword = await bcrypt.hash(newPassword, 10);
        await prisma.user.update({
            where: { id: userId },
            data: { password: hashedPassword }
        });

        res.json({ message: "Şifre başarıyla güncellendi" });
    } catch (e) {
        next(e);
    }
};

exports.getMe = async (req, res) => {
    res.json(req.user);
};

exports.getDoctors = async (req, res, next) => {
    try {
        const doctors = await prisma.user.findMany({
            where: { role: { in: ['admin', 'doctor'] } },
            select: { id: true, name: true, role: true, email: true }
        });
        res.json(doctors);
    } catch (e) {
        next(e);
    }
};

exports.listUsers = async (req, res, next) => {
    try {
        if (req.user.role !== 'admin') return res.status(403).json({ error: "Unauthorized" });

        const users = await prisma.user.findMany({
            where: { id: { not: req.user.id } }, // Don't list self
            select: { id: true, name: true, role: true, email: true, createdAt: true }
        });
        res.json(users);
    } catch (e) {
        next(e);
    }
};

exports.deleteUser = async (req, res, next) => {
    try {
        if (req.user.role !== 'admin') return res.status(403).json({ error: "Unauthorized" });
        const { id } = req.params;

        await prisma.user.delete({ where: { id } });
        res.json({ message: "Personel silindi" });
    } catch (e) {
        next(e);
    }
};
exports.fixAdminName = async (req, res, next) => {
    try {
        // Find admin by email
        const admin = await prisma.user.findFirst({
            where: { email: 'admin@zenith.com' }
        });

        if (!admin) {
            return res.status(404).json({ error: "Admin user not found" });
        }

        // Update name
        const updated = await prisma.user.update({
            where: { id: admin.id },
            data: { name: 'Süper Yönetici' }
        });

        res.json({
            success: true,
            message: "Admin ismi düzeltildi.",
            user: { email: updated.email, name: updated.name }
        });
    } catch (e) {
        next(e);
    }
};
