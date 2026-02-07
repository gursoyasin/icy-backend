const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const path = require('path');
const logger = require('./utils/logger');
require('./services/cronService'); // Init Cron Jobs
// const appRoutes = require('./routes/index'); // Will create this next

const app = express();
app.set('trust proxy', 1); // Enable trust for Render/Cloudflare proxy

// 1. GLOBAL MIDDLEWARES
// Set security HTTP headers
app.use(helmet({
    crossOriginResourcePolicy: false, // Allow loading images from public
}));

// Implement CORS
app.use(cors()); // In prod, restrict access to specific domain

// Limit requests from same API
const limiter = rateLimit({
    max: 200, // 200 requests per hour
    windowMs: 60 * 60 * 1000,
    message: 'Too many requests from this IP, please try again in an hour!'
});
app.use('/api', limiter);

// Body parser, reading data from body into req.body
app.use(express.json({ limit: '50mb' }));

// Serving static files
// Serving static files
app.use(express.static(path.join(__dirname, '..', 'public'))); // backend/src/../public -> backend/public

// Request Logger Middleware
app.use((req, res, next) => {
    logger.info(`${req.method} ${req.url}`);
    next();
});

// 2. ROUTES
const appRoutes = require('./routes/index');
app.use('/api', appRoutes);
// app.use('/', appRoutes); // If we have non-api paths? No.

// SPA Catch-all (Serve React App for non-API routes)
app.get(/(.*)/, (req, res) => {
    res.sendFile(path.join(__dirname, '..', 'public', 'index.html'));
});

// 3. ERROR HANDLING MIDDLEWARE
const globalErrorHandler = require('./middleware/errorHandler');
app.use(globalErrorHandler);

module.exports = app;
