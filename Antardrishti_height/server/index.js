require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const { router: authRouter, authMiddleware } = require('./routes/auth');
const profileRouter = require('./routes/profile');
const testsRouter = require('./routes/tests');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI)
    .then(() => console.log('✅ Connected to MongoDB'))
    .catch(err => console.error('❌ MongoDB connection error:', err));

// Routes
app.use('/api/auth', authRouter);
app.use('/api/profile', authMiddleware, profileRouter);
app.use('/api/tests', authMiddleware, testsRouter);

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Error handler
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Something went wrong!' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
});
