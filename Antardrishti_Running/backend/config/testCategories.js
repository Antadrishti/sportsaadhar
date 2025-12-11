/**
 * Test-to-Category Mapping for Category-Based Physical Scoring
 * 
 * Defines which physical tests belong to which performance categories
 * and their weights in calculating the overall physical score.
 */

const TEST_CATEGORIES = {
  // STRENGTH: Upper body and core muscular strength
  strength: {
    tests: ['sit_ups', 'push_ups', 'medicine_ball_throw'],
    weight: 0.20, // 20% of overall physical score
    description: 'Upper body and core muscular strength',
  },
  
  // ENDURANCE: Cardiovascular endurance and stamina
  endurance: {
    tests: ['800m_run', '1600m_run'],
    weight: 0.25, // 25% of overall physical score
    description: 'Cardiovascular endurance and stamina',
  },
  
  // FLEXIBILITY: Range of motion and flexibility
  flexibility: {
    tests: ['sit_and_reach'],
    weight: 0.15, // 15% of overall physical score
    description: 'Range of motion and flexibility',
  },
  
  // AGILITY: Change of direction and body control
  agility: {
    tests: ['4x10_shuttle'],
    weight: 0.20, // 20% of overall physical score
    description: 'Change of direction and body control',
  },
  
  // SPEED: Explosive power and acceleration
  speed: {
    tests: ['30m_sprint', 'standing_vertical_jump', 'standing_broad_jump'],
    weight: 0.20, // 20% of overall physical score
    description: 'Explosive power and acceleration',
  },
};

// Height is NOT included in physical score - it's just a measurement
const MEASUREMENT_TESTS = ['height'];

/**
 * Get category for a given test ID
 * @param {string} testId - Test identifier
 * @returns {string|null} - Category name or null if not found or is measurement
 */
function getTestCategory(testId) {
  for (const [category, data] of Object.entries(TEST_CATEGORIES)) {
    if (data.tests.includes(testId)) {
      return category;
    }
  }
  
  if (MEASUREMENT_TESTS.includes(testId)) {
    return 'measurement';
  }
  
  return null;
}

/**
 * Get all tests in a category
 * @param {string} category - Category name
 * @returns {Array} - Array of test IDs in the category
 */
function getTestsInCategory(category) {
  return TEST_CATEGORIES[category]?.tests || [];
}

/**
 * Get category weight
 * @param {string} category - Category name
 * @returns {number} - Weight (0-1)
 */
function getCategoryWeight(category) {
  return TEST_CATEGORIES[category]?.weight || 0;
}

/**
 * Check if a test is a measurement (not scored)
 * @param {string} testId - Test identifier
 * @returns {boolean}
 */
function isMeasurementTest(testId) {
  return MEASUREMENT_TESTS.includes(testId);
}

/**
 * Get all categories
 * @returns {Array} - Array of category names
 */
function getAllCategories() {
  return Object.keys(TEST_CATEGORIES);
}

/**
 * Validate category weights sum to 1.0
 * @returns {boolean}
 */
function validateCategoryWeights() {
  const totalWeight = Object.values(TEST_CATEGORIES).reduce(
    (sum, cat) => sum + cat.weight,
    0
  );
  return Math.abs(totalWeight - 1.0) < 0.001; // Allow small floating point errors
}

module.exports = {
  TEST_CATEGORIES,
  MEASUREMENT_TESTS,
  getTestCategory,
  getTestsInCategory,
  getCategoryWeight,
  isMeasurementTest,
  getAllCategories,
  validateCategoryWeights,
};


