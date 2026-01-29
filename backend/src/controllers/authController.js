const prisma = require('../config/prisma');
const logger = require('../utils/logger');

exports.login = async (req, res, next) => {
    const { email, password } = req.body;
    try {
        const user = await prisma.user.findUnique({
            where: { email },
            include: { branch: true }
        });

        if (!user) return res.status(401).json({ error: "User not found" });

        // Verify password
        const bcrypt = require('bcryptjs');
        const isValid = await bcrypt.compare(password, user.password);
        if (!isValid) return res.status(401).json({ error: "Invalid credentials" });

        logger.info(`User logged in: ${email}`);

        res.json({
            token: "valid-jwt-token-signed-by-server", // In real prod, sign this with jsonwebtoken secret
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

exports.register = async (req, res, next) => {
    try {
        const { name, email, password, role } = req.body;

        const existing = await prisma.user.findUnique({ where: { email } });
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
                branchId: req.user.branchId
            }
        });

        res.json(user);
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
