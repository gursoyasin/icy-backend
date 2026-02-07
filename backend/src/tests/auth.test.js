const { TextEncoder, TextDecoder } = require('util');
global.TextEncoder = TextEncoder;
global.TextDecoder = TextDecoder;
global.setImmediate = global.setImmediate || ((fn, ...args) => global.setTimeout(fn, 0, ...args));

const request = require('supertest');
const app = require('../app');
const prisma = require('../config/prisma');

// Mock Prisma
jest.mock('../config/prisma', () => ({
    user: {
        findUnique: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
    },
}));

const bcrypt = require('bcryptjs');
jest.mock('bcryptjs');
const jwt = require('jsonwebtoken');
jest.mock('jsonwebtoken');

describe('Auth Endpoints', () => {

    beforeEach(() => {
        jest.clearAllMocks();
    });

    describe('POST /api/auth/login', () => {
        it('should return 401 if user not found', async () => {
            prisma.user.findUnique.mockResolvedValue(null);

            const res = await request(app)
                .post('/api/auth/login')
                .send({ email: 'test@example.com', password: 'password' });

            if (res.statusCode !== 401) {
                console.log('Error Body:', JSON.stringify(res.body, null, 2));
            }
            expect(res.statusCode).toEqual(401);
            expect(res.body).toHaveProperty('error', 'User not found');
        });

        it('should return 401 if password invalid', async () => {
            prisma.user.findUnique.mockResolvedValue({
                id: '1', email: 'test@example.com', password: 'hashed_password'
            });
            bcrypt.compare.mockResolvedValue(false);

            const res = await request(app)
                .post('/api/auth/login')
                .send({ email: 'test@example.com', password: 'wrongpassword' });

            expect(res.statusCode).toEqual(401);
            expect(res.body).toHaveProperty('error', 'Invalid credentials');
        });

        it('should return 200 and token if credentials valid', async () => {
            const mockUser = { id: '1', email: 'test@example.com', password: 'hashed_password', role: 'staff' };
            prisma.user.findUnique.mockResolvedValue(mockUser);
            bcrypt.compare.mockResolvedValue(true);
            jwt.sign.mockReturnValue('valid_token');

            const res = await request(app)
                .post('/api/auth/login')
                .send({ email: 'test@example.com', password: 'password' });

            expect(res.statusCode).toEqual(200);
            expect(res.body).toHaveProperty('token', 'valid_token');
        });
    });
});
