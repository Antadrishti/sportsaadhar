const mongoose = require('mongoose');

const testResultSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    testId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Test',
        required: true
    },
    value: {
        type: Number,
        required: true
    },
    unit: {
        type: String,
        required: true
    },
    metadata: {
        deviceInfo: { type: String, default: '' },
        notes: { type: String, default: '' }
    },
    takenAt: {
        type: Date,
        default: Date.now
    }
}, {
    timestamps: true
});

// Index for efficient queries
testResultSchema.index({ userId: 1, testId: 1, takenAt: -1 });

module.exports = mongoose.model('TestResult', testResultSchema);
