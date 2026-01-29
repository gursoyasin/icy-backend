const app = require('./app');
const logger = require('./utils/logger');
const dotenv = require('dotenv');
const http = require('http');
const { Server } = require('socket.io');

dotenv.config();

const PORT = process.env.PORT || 3000;

const server = http.createServer(app);
const io = new Server(server, {
    cors: { origin: "*", methods: ["GET", "POST"] }
});

// Make io accessible globally or pass it to controllers (keeping it simple for now by attaching to app)
app.set('io', io);

// Socket.io Logic
io.on('connection', (socket) => {
    logger.info(`User connected: ${socket.id}`);
    socket.on('join_room', (roomId) => socket.join(roomId));
    socket.on('disconnect', () => logger.info('User disconnected'));
});

server.listen(PORT, '0.0.0.0', () => {
    logger.info(`🚀 PROFESSIONAL Backend running on port ${PORT}`);
    logger.info(`- Environment: ${process.env.NODE_ENV || 'development'}`);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
    logger.error('UNHANDLED REJECTION! 💥 Shutting down...');
    logger.error(err);
    server.close(() => {
        process.exit(1);
    });
});
