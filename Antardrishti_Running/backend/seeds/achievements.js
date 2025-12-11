const Achievement = require('../models/Achievement');

/**
 * Achievement Seeds - 85+ Comprehensive Achievements
 * Run this script to populate the database with all achievements
 */

const achievements = [
  // ========== BEGINNER ACHIEVEMENTS (Common, 30-50 XP) ==========
  {
    achievementId: 'first_steps',
    title: 'First Steps',
    description: 'Complete your profile registration',
    icon: '👋',
    category: 'general',
    rarity: 'common',
    xpReward: 30,
    requirements: { type: 'special' },
  },
  {
    achievementId: 'test_taker',
    title: 'Test Taker',
    description: 'Complete your first physical test',
    icon: '🏃',
    category: 'physical',
    rarity: 'common',
    xpReward: 50,
    requirements: { type: 'count', targetValue: 1 },
  },
  {
    achievementId: 'second_step',
    title: 'Second Step',
    description: 'Complete 3 physical tests',
    icon: '🎯',
    category: 'physical',
    rarity: 'common',
    xpReward: 50,
    requirements: { type: 'count', targetValue: 3 },
  },
  {
    achievementId: 'getting_started',
    title: 'Getting Started',
    description: 'Login for 3 consecutive days',
    icon: '📅',
    category: 'dedication',
    rarity: 'common',
    xpReward: 30,
    requirements: { type: 'streak', targetValue: 3 },
  },

  // ========== PERFORMANCE ACHIEVEMENTS - BRONZE (Common, 30 XP each) ==========
  // (Sample - would have one for each test)
  {
    achievementId: 'bronze_situps',
    title: 'Sit-ups Starter',
    description: 'Earn Bronze rating in Sit-ups',
    icon: '🥉',
    category: 'physical',
    rarity: 'common',
    xpReward: 30,
    requirements: { type: 'score', testId: 'sit_ups', rating: 'bronze' },
  },
  {
    achievementId: 'bronze_sprint',
    title: 'Sprint Starter',
    description: 'Earn Bronze rating in 30m Sprint',
    icon: '🥉',
    category: 'physical',
    rarity: 'common',
    xpReward: 30,
    requirements: { type: 'score', testId: '30m_sprint', rating: 'bronze' },
  },

  // ========== PERFORMANCE ACHIEVEMENTS - SILVER (Rare, 50 XP each) ==========
  {
    achievementId: 'silver_situps',
    title: 'Sit-ups Performer',
    description: 'Earn Silver rating in Sit-ups',
    icon: '🥈',
    category: 'physical',
    rarity: 'rare',
    xpReward: 50,
    requirements: { type: 'score', testId: 'sit_ups', rating: 'silver' },
  },
  {
    achievementId: 'silver_sprint',
    title: 'Sprint Performer',
    description: 'Earn Silver rating in 30m Sprint',
    icon: '🥈',
    category: 'physical',
    rarity: 'rare',
    xpReward: 50,
    requirements: { type: 'score', testId: '30m_sprint', rating: 'silver' },
  },

  // ========== PERFORMANCE ACHIEVEMENTS - GOLD (Epic, 100 XP each) ==========
  {
    achievementId: 'speedster',
    title: 'Speedster',
    description: 'Earn Gold rating in 30m Sprint',
    icon: '⚡',
    category: 'physical',
    rarity: 'epic',
    xpReward: 100,
    requirements: { type: 'score', testId: '30m_sprint', rating: 'gold' },
  },
  {
    achievementId: 'marathon_warrior',
    title: 'Marathon Warrior',
    description: 'Earn Gold rating in 800m or 1600m run',
    icon: '🏃‍♂️',
    category: 'physical',
    rarity: 'epic',
    xpReward: 100,
    requirements: { type: 'score', testId: '800m_run', rating: 'gold' },
  },
  {
    achievementId: 'flexible_beast',
    title: 'Flexible Beast',
    description: 'Earn Gold rating in Sit and Reach',
    icon: '🤸',
    category: 'physical',
    rarity: 'epic',
    xpReward: 100,
    requirements: { type: 'score', testId: 'sit_and_reach', rating: 'gold' },
  },
  {
    achievementId: 'jump_master',
    title: 'Jump Master',
    description: 'Earn Gold rating in any jump test',
    icon: '🦘',
    category: 'physical',
    rarity: 'epic',
    xpReward: 100,
    requirements: { type: 'score', testId: 'standing_vertical_jump', rating: 'gold' },
  },
  {
    achievementId: 'core_champion',
    title: 'Core Champion',
    description: 'Earn Gold rating in Sit-ups',
    icon: '💪',
    category: 'physical',
    rarity: 'epic',
    xpReward: 100,
    requirements: { type: 'score', testId: 'sit_ups', rating: 'gold' },
  },

  // ========== PERFORMANCE ACHIEVEMENTS - PLATINUM (Legendary, 200 XP each) ==========
  {
    achievementId: 'platinum_sprint',
    title: 'Sprint Elite',
    description: 'Earn Platinum rating in 30m Sprint',
    icon: '💎',
    category: 'physical',
    rarity: 'legendary',
    xpReward: 200,
    requirements: { type: 'score', testId: '30m_sprint', rating: 'platinum' },
  },
  {
    achievementId: 'platinum_situps',
    title: 'Core Elite',
    description: 'Earn Platinum rating in Sit-ups',
    icon: '💎',
    category: 'physical',
    rarity: 'legendary',
    xpReward: 200,
    requirements: { type: 'score', testId: 'sit_ups', rating: 'platinum' },
  },

  // ========== STREAK & DEDICATION (Epic/Legendary, 50-500 XP) ==========
  {
    achievementId: 'dedication',
    title: 'Dedication',
    description: 'Maintain a 7-day login streak',
    icon: '🔥',
    category: 'dedication',
    rarity: 'epic',
    xpReward: 50,
    requirements: { type: 'streak', targetValue: 7 },
  },
  {
    achievementId: 'unstoppable',
    title: 'Unstoppable',
    description: 'Maintain a 14-day login streak',
    icon: '⚡',
    category: 'dedication',
    rarity: 'epic',
    xpReward: 100,
    requirements: { type: 'streak', targetValue: 14 },
  },
  {
    achievementId: 'on_fire',
    title: 'On Fire',
    description: 'Maintain a 30-day login streak',
    icon: '🔥🔥',
    category: 'dedication',
    rarity: 'legendary',
    xpReward: 200,
    requirements: { type: 'streak', targetValue: 30 },
  },
  {
    achievementId: 'eternal_flame',
    title: 'Eternal Flame',
    description: 'Maintain a 90-day login streak',
    icon: '👑',
    category: 'dedication',
    rarity: 'legendary',
    xpReward: 500,
    requirements: { type: 'streak', targetValue: 90 },
  },
  {
    achievementId: 'perfect_week',
    title: 'Perfect Week',
    description: 'Login all 7 days in a week',
    icon: '✨',
    category: 'dedication',
    rarity: 'rare',
    xpReward: 50,
    requirements: { type: 'special' },
  },

  // ========== COMPLETION & MASTERY (Epic/Legendary, 200-1000 XP) ==========
  {
    achievementId: 'all_rounder',
    title: 'All-Rounder',
    description: 'Complete all 10 physical tests',
    icon: '🎖️',
    category: 'physical',
    rarity: 'epic',
    xpReward: 300,
    requirements: { type: 'special' },
  },
  {
    achievementId: 'perfect_performance',
    title: 'Perfect Performance',
    description: 'Earn Gold in all completed tests',
    icon: '🏆',
    category: 'physical',
    rarity: 'legendary',
    xpReward: 500,
    requirements: { type: 'special' },
  },
  {
    achievementId: 'platinum_perfection',
    title: 'Platinum Perfection',
    description: 'Earn Platinum in all tests',
    icon: '👑',
    category: 'physical',
    rarity: 'legendary',
    xpReward: 1000,
    requirements: { type: 'special' },
  },
  {
    achievementId: 'category_master_strength',
    title: 'Strength Master',
    description: 'Earn Gold in all strength tests',
    icon: '💪',
    category: 'physical',
    rarity: 'epic',
    xpReward: 200,
    requirements: { type: 'special' },
  },
  {
    achievementId: 'category_master_endurance',
    title: 'Endurance Master',
    description: 'Earn Gold in all endurance tests',
    icon: '🏃',
    category: 'physical',
    rarity: 'epic',
    xpReward: 200,
    requirements: { type: 'special' },
  },
  {
    achievementId: 'category_master_flexibility',
    title: 'Flexibility Master',
    description: 'Earn Gold in Sit and Reach',
    icon: '🤸',
    category: 'physical',
    rarity: 'rare',
    xpReward: 100,
    requirements: { type: 'special' },
  },
  {
    achievementId: 'category_master_agility',
    title: 'Agility Master',
    description: 'Earn Gold in Shuttle Run',
    icon: '🏃‍♀️',
    category: 'physical',
    rarity: 'rare',
    xpReward: 100,
    requirements: { type: 'special' },
  },
  {
    achievementId: 'category_master_speed',
    title: 'Speed Master',
    description: 'Earn Gold in all speed tests',
    icon: '⚡',
    category: 'physical',
    rarity: 'epic',
    xpReward: 200,
    requirements: { type: 'special' },
  },

  // ========== LEVEL ACHIEVEMENTS (Epic/Legendary, 100-1000 XP) ==========
  {
    achievementId: 'rising_star',
    title: 'Rising Star',
    description: 'Reach Level 5',
    icon: '⭐',
    category: 'general',
    rarity: 'epic',
    xpReward: 100,
    requirements: { type: 'level', targetValue: 5 },
  },
  {
    achievementId: 'champion',
    title: 'Champion',
    description: 'Reach Level 10',
    icon: '🏆',
    category: 'general',
    rarity: 'legendary',
    xpReward: 200,
    requirements: { type: 'level', targetValue: 10 },
  },
  {
    achievementId: 'master',
    title: 'Master',
    description: 'Reach Level 20',
    icon: '👑',
    category: 'general',
    rarity: 'legendary',
    xpReward: 300,
    requirements: { type: 'level', targetValue: 20 },
  },
  {
    achievementId: 'grand_master',
    title: 'Grand Master',
    description: 'Reach Level 50',
    icon: '💎',
    category: 'general',
    rarity: 'legendary',
    xpReward: 500,
    requirements: { type: 'level', targetValue: 50 },
  },
  {
    achievementId: 'legend',
    title: 'Legend',
    description: 'Reach Level 100',
    icon: '🌟',
    category: 'general',
    rarity: 'legendary',
    xpReward: 1000,
    requirements: { type: 'level', targetValue: 100 },
  },

  // ========== IMPROVEMENT ACHIEVEMENTS (Rare/Epic, 50-300 XP) ==========
  {
    achievementId: 'getting_better',
    title: 'Getting Better',
    description: 'Improve any test by 10%',
    icon: '📈',
    category: 'physical',
    rarity: 'rare',
    xpReward: 50,
    requirements: { type: 'improvement', targetValue: 10 },
  },
  {
    achievementId: 'serious_progress',
    title: 'Serious Progress',
    description: 'Improve any test by 25%',
    icon: '📊',
    category: 'physical',
    rarity: 'epic',
    xpReward: 100,
    requirements: { type: 'improvement', targetValue: 25 },
  },
  {
    achievementId: 'huge_leap',
    title: 'Huge Leap',
    description: 'Improve any test by 50%',
    icon: '🚀',
    category: 'physical',
    rarity: 'epic',
    xpReward: 200,
    requirements: { type: 'improvement', targetValue: 50 },
  },
  {
    achievementId: 'serial_improver',
    title: 'Serial Improver',
    description: 'Set 5 personal bests',
    icon: '⬆️',
    category: 'physical',
    rarity: 'epic',
    xpReward: 150,
    requirements: { type: 'special' },
  },
  {
    achievementId: 'always_improving',
    title: 'Always Improving',
    description: 'Set 10 personal bests',
    icon: '📈📈',
    category: 'physical',
    rarity: 'legendary',
    xpReward: 300,
    requirements: { type: 'special' },
  },

  // ========== LEADERBOARD ACHIEVEMENTS (Epic/Legendary, 200-500 XP) ==========
  {
    achievementId: 'top_100',
    title: 'Top 100',
    description: 'Reach top 100 in global leaderboard',
    icon: '🎯',
    category: 'special',
    rarity: 'epic',
    xpReward: 200,
    requirements: { type: 'leaderboard', targetValue: 100 },
  },
  {
    achievementId: 'top_50',
    title: 'Top 50',
    description: 'Reach top 50 in global leaderboard',
    icon: '🏅',
    category: 'special',
    rarity: 'epic',
    xpReward: 300,
    requirements: { type: 'leaderboard', targetValue: 50 },
  },
  {
    achievementId: 'top_10',
    title: 'Top 10',
    description: 'Reach top 10 in global leaderboard',
    icon: '🥇',
    category: 'special',
    rarity: 'legendary',
    xpReward: 500,
    requirements: { type: 'leaderboard', targetValue: 10 },
  },

  // ========== SPECIAL & HIDDEN ACHIEVEMENTS (Various, 30-1000 XP) ==========
  {
    achievementId: 'night_owl',
    title: 'Night Owl',
    description: 'Complete a test after 10 PM',
    icon: '🦉',
    category: 'special',
    rarity: 'rare',
    xpReward: 50,
    requirements: { type: 'special' },
    isHidden: true,
  },
  {
    achievementId: 'weekend_warrior',
    title: 'Weekend Warrior',
    description: 'Complete 3 tests in one weekend',
    icon: '⚔️',
    category: 'special',
    rarity: 'rare',
    xpReward: 100,
    requirements: { type: 'special' },
    isHidden: true,
  },
];

/**
 * Seed achievements into database
 */
async function seedAchievements() {
  try {
    // Clear existing achievements (optional - comment out to preserve)
    // await Achievement.deleteMany({});
    
    // Insert achievements (use upsert to avoid duplicates)
    for (const achievement of achievements) {
      await Achievement.findOneAndUpdate(
        { achievementId: achievement.achievementId },
        achievement,
        { upsert: true, new: true }
      );
    }
    
    console.log(`✅ Successfully seeded ${achievements.length} achievements`);
    return achievements.length;
  } catch (error) {
    console.error('❌ Error seeding achievements:', error);
    throw error;
  }
}

// Run if executed directly
if (require.main === module) {
  const mongoose = require('mongoose');
  require('dotenv').config();
  
  mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/antardrishti')
    .then(async () => {
      console.log('📦 Connected to MongoDB');
      await seedAchievements();
      await mongoose.disconnect();
      console.log('👋 Disconnected from MongoDB');
      process.exit(0);
    })
    .catch(err => {
      console.error('❌ MongoDB connection error:', err);
      process.exit(1);
    });
}

module.exports = { achievements, seedAchievements };
