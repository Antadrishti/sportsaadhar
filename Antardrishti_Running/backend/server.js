const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const connectDB = require('./config/database');
const authRoutes = require('./routes/auth');
const testResultsRoutes = require('./routes/testResults');
const progressRoutes = require('./routes/progress');
const leaderboardRoutes = require('./routes/leaderboard');
const psychometricRoutes = require('./routes/psychometric');

// Load environment variables
dotenv.config();

// Connect to MongoDB
connectDB();

// Initialize Express app
const app = express();

// Middleware
app.use(cors()); // Enable CORS for Flutter app
app.use(express.json()); // Parse JSON bodies
app.use(express.urlencoded({ extended: true })); // Parse URL-encoded bodies

// Routes
app.use('/auth', authRoutes);
app.use('/test-results', testResultsRoutes);
app.use('/progress', progressRoutes);
app.use('/leaderboard', leaderboardRoutes);
app.use('/psychometric', psychometricRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'OK', message: 'Antardrishti Backend is running' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// Start server
const PORT = process.env.PORT || 3000;
// Bind to 0.0.0.0 to allow connections from emulator (10.0.2.2) and network devices
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📍 Health check: http://localhost:${PORT}/health`);
  console.log(`📍 For Android emulator: http://10.0.2.2:${PORT}/health`);
  console.log(`📍 For iOS simulator: http://localhost:${PORT}/health`);
});




