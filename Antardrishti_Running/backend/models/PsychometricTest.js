const mongoose = require('mongoose');

const psychometricTestSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  answers: [{
    section: {
      type: String,
      required: true,
      enum: ['mental_toughness', 'focus', 'stress', 'teamwork'],
    },
    questionId: {
      type: Number,
      required: true,
      min: 1,
      max: 5,
    },
    question: {
      type: String,
      required: true,
    },
    answer: {
      type: String,
      required: true,
    },
  }],
  overallScore: {
    type: Number,
    required: true,
    min: 0,
    max: 100,
  },
  sectionScores: {
    mental_toughness: {
      type: Number,
      min: 0,
      max: 100,
    },
    focus: {
      type: Number,
      min: 0,
      max: 100,
    },
    stress: {
      type: Number,
      min: 0,
      max: 100,
    },
    teamwork: {
      type: Number,
      min: 0,
      max: 100,
    },
  },
  completedAt: {
    type: Date,
    default: Date.now,
  },
  analysisStatus: {
    type: String,
    enum: ['pending', 'analyzed'],
    default: 'pending',
  },
});

// Index for faster queries
psychometricTestSchema.index({ userId: 1, completedAt: -1 });

const PsychometricTest = mongoose.model('PsychometricTest', psychometricTestSchema);

module.exports = PsychometricTest;


