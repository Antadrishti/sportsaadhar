// Test-specific metrics configuration
// Maps each test to its relevant metrics and labels
// NOTE: Database uses 'timeTaken' not 'time', 'distance' for counts/distances

export const TEST_METRICS = {
    '1600m Run': {
        metrics: ['timeTaken', 'speed'],  // Time and Speed for running tests
        labels: { timeTaken: 'Time (min:sec)', speed: 'Speed (m/s)' },
        primaryMetric: 'timeTaken',
        dbFields: ['timeTaken', 'distance', 'speed'],
        sortFields: ['timeTaken', 'speed'],  // Can sort by time or speed
        formatters: {
            timeTaken: (v) => {
                if (!v) return 'N/A';
                const mins = Math.floor(v / 60);
                const secs = (v % 60).toFixed(1);
                return `${mins}:${secs.padStart(4, '0')}`;
            },
            speed: (v) => v ? `${v.toFixed(2)} m/s` : 'N/A'
        }
    },
    '800m Run': {
        metrics: ['timeTaken', 'speed'],
        labels: { timeTaken: 'Time (min:sec)', speed: 'Speed (m/s)' },
        primaryMetric: 'timeTaken',
        dbFields: ['timeTaken', 'distance', 'speed'],
        sortFields: ['timeTaken', 'speed'],
        formatters: {
            timeTaken: (v) => {
                if (!v) return 'N/A';
                const mins = Math.floor(v / 60);
                const secs = (v % 60).toFixed(1);
                return `${mins}:${secs.padStart(4, '0')}`;
            },
            speed: (v) => v ? `${v.toFixed(2)} m/s` : 'N/A'
        }
    },
    '30m Sprint': {
        metrics: ['timeTaken', 'speed'],
        labels: { timeTaken: 'Time (sec)', speed: 'Speed (m/s)' },
        primaryMetric: 'timeTaken',
        dbFields: ['timeTaken', 'speed'],
        sortFields: ['timeTaken', 'speed'],
        formatters: {
            timeTaken: (v) => v ? `${v.toFixed(2)}s` : 'N/A',
            speed: (v) => v ? `${v.toFixed(2)} m/s` : 'N/A'
        }
    },
    '4×10m Shuttle Run': {
        metrics: ['timeTaken', 'speed'],
        labels: { timeTaken: 'Time (sec)', speed: 'Speed (m/s)' },
        primaryMetric: 'timeTaken',
        dbFields: ['timeTaken', 'speed'],
        sortFields: ['timeTaken', 'speed'],
        fixedDistance: 40,  // 4 x 10m = 40m total
        formatters: {
            timeTaken: (v) => v ? `${v.toFixed(2)}s` : 'N/A',
            speed: (v) => v ? `${v.toFixed(2)} m/s` : 'N/A'
        }
    },
    'Sit-ups (1 min)': {
        metrics: ['distance'], // stored as distance but represents reps count
        labels: { distance: 'Reps' },
        primaryMetric: 'distance',
        dbFields: ['distance'],
        isCount: true,
        sortFields: ['distance'],  // Sort by reps
        formatters: {
            distance: (v) => v ? `${Math.round(v)}` : 'N/A'
        }
    },
    'Push-ups (1 min)': {
        metrics: ['distance'], // stored as distance but represents reps count
        labels: { distance: 'Reps' },
        primaryMetric: 'distance',
        dbFields: ['distance'],
        isCount: true,
        sortFields: ['distance'],  // Sort by reps
        formatters: {
            distance: (v) => v ? `${Math.round(v)}` : 'N/A'
        }
    },
    'Sit and Reach': {
        metrics: ['distance'],
        labels: { distance: 'Reach (cm)' },
        primaryMetric: 'distance',
        dbFields: ['distance'],
        sortFields: ['distance'],
        formatters: {
            distance: (v) => v ? `${v.toFixed(1)} cm` : 'N/A'
        }
    },
    'Standing Broad Jump': {
        metrics: ['distance'],
        labels: { distance: 'Distance (cm)' },
        primaryMetric: 'distance',
        dbFields: ['distance'],
        sortFields: ['distance'],
        formatters: {
            distance: (v) => v ? `${v.toFixed(1)} cm` : 'N/A'
        }
    },
    'Standing Vertical Jump': {
        metrics: ['distance'],
        labels: { distance: 'Height (cm)' },
        primaryMetric: 'distance',
        dbFields: ['distance'],
        sortFields: ['distance'],
        formatters: {
            distance: (v) => v ? `${v.toFixed(1)} cm` : 'N/A'
        }
    },
    'Medicine Ball Throw': {
        metrics: ['distance'],
        labels: { distance: 'Distance (m)' },
        primaryMetric: 'distance',
        dbFields: ['distance'],
        sortFields: ['distance'],
        formatters: {
            distance: (v) => v ? `${v.toFixed(2)} m` : 'N/A'
        }
    }
};

// Get metrics config for a test name
export const getTestMetrics = (testName) => {
    return TEST_METRICS[testName] || null;
};

// Format a metric value based on test type
export const formatMetric = (testName, metricName, value) => {
    const config = TEST_METRICS[testName];
    if (!config || !config.formatters[metricName]) {
        return value ?? 'N/A';
    }
    return config.formatters[metricName](value);
};

// Get the display label for a metric
export const getMetricLabel = (testName, metricName) => {
    const config = TEST_METRICS[testName];
    if (!config || !config.labels[metricName]) {
        return metricName;
    }
    return config.labels[metricName];
};

// Get all metric columns for a test
export const getMetricColumns = (testName) => {
    const config = TEST_METRICS[testName];
    if (!config) return [];
    return config.metrics.map(m => ({
        field: m,
        label: config.labels[m]
    }));
};

// Get sort field options for a test (for QueryBuilder sorting)
export const getSortFields = (testName) => {
    const config = TEST_METRICS[testName];
    if (!config || !config.sortFields) return [];
    return config.sortFields.map(f => ({
        field: f,
        label: config.labels[f] || f
    }));
};

export default TEST_METRICS;
