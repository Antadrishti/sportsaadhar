import { useState, useEffect, useCallback } from 'react';
import { apiClient } from '@/App';
import { useNavigate } from 'react-router-dom';
import { toast } from 'sonner';
import { getTestMetrics, formatMetric, getMetricColumns } from '@/utils/testMetrics';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Search,
  Filter,
  ChevronLeft,
  ChevronRight,
  Activity,
  Award,
  User
} from 'lucide-react';

const RatingBadge = ({ rating }) => {
  const classes = {
    gold: 'badge-gold',
    silver: 'badge-silver',
    bronze: 'badge-bronze',
  };

  return (
    <span className={`px-2 py-0.5 text-xs font-medium rounded-full capitalize ${classes[rating] || 'bg-slate-100 text-slate-600'}`}>
      {rating || 'N/A'}
    </span>
  );
};

const TestResultRow = ({ result, onUserClick }) => {
  const testMetricsConfig = getTestMetrics(result.testName);
  const metricColumns = testMetricsConfig ? getMetricColumns(result.testName) : [];

  // Render raw metric value based on test type
  const renderMetricValue = () => {
    if (!testMetricsConfig) {
      // Fallback to comparison score if no config
      return result.comparisonScore?.toFixed(1) || 'N/A';
    }

    // Get the primary metric for this test
    const primaryMetric = testMetricsConfig.primaryMetric;
    return formatMetric(result.testName, primaryMetric, result[primaryMetric]);
  };

  // Render secondary metric if available
  const renderSecondaryMetric = () => {
    if (!testMetricsConfig || metricColumns.length < 2) return null;
    const secondaryMetric = metricColumns[1].field;
    return formatMetric(result.testName, secondaryMetric, result[secondaryMetric]);
  };

  return (
    <tr className="hover:bg-[#F8FAFC]/50 transition-colors" data-testid={`test-row-${result.id}`}>
      <td className="px-4 py-3">
        <div
          className="flex items-center gap-3 cursor-pointer hover:text-[#FF9933]"
          onClick={() => onUserClick(result.userId)}
        >
          <div className="w-8 h-8 bg-[#F1F5F9] rounded-full flex items-center justify-center">
            <span className="text-xs font-medium text-[#64748B]">
              {result.userName?.charAt(0) || '?'}
            </span>
          </div>
          <div>
            <p className="font-medium text-[#0F172A]">{result.userName || 'Unknown'}</p>
            <p className="text-xs text-[#64748B]">{result.userState}</p>
          </div>
        </div>
      </td>
      <td className="px-4 py-3">
        <div>
          <p className="font-medium text-[#0F172A]">{result.testName}</p>
          <p className="text-xs text-[#64748B]">{result.testType}</p>
        </div>
      </td>
      <td className="px-4 py-3 text-sm">{result.category}</td>
      <td className="px-4 py-3 font-mono text-sm text-[#FF9933]">
        {renderMetricValue()}
      </td>
      <td className="px-4 py-3 font-mono text-sm text-[#64748B]">
        {renderSecondaryMetric() || '-'}
      </td>
      <td className="px-4 py-3">
        <RatingBadge rating={result.performanceRating} />
      </td>
      <td className="px-4 py-3 text-sm text-[#64748B]">
        {new Date(result.date).toLocaleDateString()}
      </td>
      <td className="px-4 py-3">
        {result.isPersonalBest && (
          <span className="px-2 py-0.5 text-xs font-medium bg-amber-100 text-amber-700 rounded-full">
            PB
          </span>
        )}
      </td>
    </tr>
  );
};

const TestResults = () => {
  const navigate = useNavigate();
  const [results, setResults] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filterOptions, setFilterOptions] = useState(null);
  const [showFilters, setShowFilters] = useState(true);

  // Pagination
  const [page, setPage] = useState(1);
  const [limit] = useState(25);
  const [total, setTotal] = useState(0);
  const [totalPages, setTotalPages] = useState(1);

  // Filters
  const [search, setSearch] = useState('');
  const [testName, setTestName] = useState('');
  const [testType, setTestType] = useState('');
  const [category, setCategory] = useState('');
  const [gender, setGender] = useState('');
  const [performanceRating, setPerformanceRating] = useState('');
  const [ageGroup, setAgeGroup] = useState('');
  const [sort, setSort] = useState('date:desc');

  // Fetch filter options
  useEffect(() => {
    const fetchFilterOptions = async () => {
      try {
        const response = await apiClient.get('/admin/filter-options');
        setFilterOptions(response.data);
      } catch (err) {
        console.error('Failed to fetch filter options:', err);
      }
    };
    fetchFilterOptions();
  }, []);

  // Fetch results
  const fetchResults = useCallback(async () => {
    try {
      setLoading(true);
      const params = { page, limit, sort };

      if (search) params.search = search;
      if (testName && testName !== 'all') params.testName = testName;
      if (testType && testType !== 'all') params.testType = testType;
      if (category && category !== 'all') params.category = category;
      if (gender && gender !== 'all') params.gender = gender;
      if (performanceRating && performanceRating !== 'all') params.performanceRating = performanceRating;
      if (ageGroup && ageGroup !== 'all') params.ageGroup = ageGroup;

      const response = await apiClient.get('/admin/test-results', { params });
      setResults(response.data.results || []);
      setTotal(response.data.total || 0);
      setTotalPages(response.data.totalPages || 1);
    } catch (err) {
      console.error('Failed to fetch test results:', err);
      toast.error('Failed to load test results');
    } finally {
      setLoading(false);
    }
  }, [page, limit, search, testName, testType, category, gender, performanceRating, ageGroup, sort]);

  useEffect(() => {
    fetchResults();
  }, [fetchResults]);

  const clearFilters = () => {
    setSearch('');
    setTestName('');
    setTestType('');
    setCategory('');
    setGender('');
    setPerformanceRating('');
    setAgeGroup('');
    setSort('date:desc');
    setPage(1);
  };

  const handleUserClick = (userId) => {
    if (userId) {
      navigate(`/candidates/${userId}`);
    }
  };

  return (
    <div className="space-y-6" data-testid="test-results">
      {/* Header */}
      <div>
        <h1 className="text-2xl lg:text-3xl font-heading font-bold tracking-tight text-[#0F172A]">
          Test Results
        </h1>
        <p className="text-[#64748B] mt-1">
          {total} assessment records
        </p>
      </div>

      {/* Filters */}
      <div className="stat-card">
        <div className="flex flex-wrap items-center gap-4">
          <div className="flex-1 min-w-[200px]">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#64748B]" />
              <Input
                placeholder="Search by athlete name..."
                value={search}
                onChange={(e) => { setSearch(e.target.value); setPage(1); }}
                className="pl-10"
                data-testid="search-input"
              />
            </div>
          </div>

          <Button
            variant="outline"
            onClick={() => setShowFilters(!showFilters)}
            data-testid="toggle-filters-btn"
          >
            <Filter className="w-4 h-4 mr-2" />
            Filters
          </Button>

          <Select value={sort} onValueChange={(v) => { setSort(v); setPage(1); }}>
            <SelectTrigger className="w-[180px]" data-testid="sort-select">
              <SelectValue placeholder="Sort by" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="date:desc">Newest First</SelectItem>
              <SelectItem value="date:asc">Oldest First</SelectItem>
              <SelectItem value="comparisonScore:desc">Highest Score</SelectItem>
              <SelectItem value="comparisonScore:asc">Lowest Score</SelectItem>
              <SelectItem value="userName:asc">Name A-Z</SelectItem>
              <SelectItem value="userName:desc">Name Z-A</SelectItem>
            </SelectContent>
          </Select>
        </div>

        {showFilters && (
          <div className="mt-4 pt-4 border-t border-[#E2E8F0] grid grid-cols-1 md:grid-cols-6 gap-4 animate-in">
            <Select value={testName} onValueChange={(v) => { setTestName(v); setPage(1); }}>
              <SelectTrigger data-testid="filter-test-name">
                <SelectValue placeholder="All Tests" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Tests</SelectItem>
                {filterOptions?.testNames?.map((t) => (
                  <SelectItem key={t} value={t}>{t}</SelectItem>
                ))}
              </SelectContent>
            </Select>

            <Select value={testType} onValueChange={(v) => { setTestType(v); setPage(1); }}>
              <SelectTrigger data-testid="filter-test-type">
                <SelectValue placeholder="All Test Types" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Test Types</SelectItem>
                {filterOptions?.testTypes?.map((t) => (
                  <SelectItem key={t} value={t}>{t}</SelectItem>
                ))}
              </SelectContent>
            </Select>

            <Select value={category} onValueChange={(v) => { setCategory(v); setPage(1); }}>
              <SelectTrigger data-testid="filter-category">
                <SelectValue placeholder="All Categories" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Categories</SelectItem>
                {filterOptions?.categories?.map((c) => (
                  <SelectItem key={c} value={c}>{c}</SelectItem>
                ))}
              </SelectContent>
            </Select>

            <Select value={gender} onValueChange={(v) => { setGender(v); setPage(1); }}>
              <SelectTrigger data-testid="filter-gender">
                <SelectValue placeholder="All Genders" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Genders</SelectItem>
                {filterOptions?.genders?.map((g) => (
                  <SelectItem key={g} value={g}>{g}</SelectItem>
                ))}
              </SelectContent>
            </Select>

            <Select value={performanceRating} onValueChange={(v) => { setPerformanceRating(v); setPage(1); }}>
              <SelectTrigger data-testid="filter-rating">
                <SelectValue placeholder="All Ratings" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Ratings</SelectItem>
                {filterOptions?.performanceRatings?.map((r) => (
                  <SelectItem key={r} value={r}>{r}</SelectItem>
                ))}
              </SelectContent>
            </Select>

            <Select value={ageGroup} onValueChange={(v) => { setAgeGroup(v); setPage(1); }}>
              <SelectTrigger data-testid="filter-age-group">
                <SelectValue placeholder="All Age Groups" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Age Groups</SelectItem>
                {filterOptions?.ageGroups?.map((a) => (
                  <SelectItem key={a} value={a}>{a}</SelectItem>
                ))}
              </SelectContent>
            </Select>

            <div className="md:col-span-6">
              <Button variant="ghost" size="sm" onClick={clearFilters}>
                Clear All Filters
              </Button>
            </div>
          </div>
        )}
      </div>

      {/* Content */}
      {loading ? (
        <div className="stat-card overflow-hidden">
          <div className="space-y-3">
            {[1, 2, 3, 4, 5].map((i) => (
              <div key={i} className="h-12 skeleton" />
            ))}
          </div>
        </div>
      ) : results.length === 0 ? (
        <div className="stat-card text-center py-12" data-testid="no-results">
          <p className="text-[#64748B]">No test results found</p>
          <Button variant="outline" className="mt-4" onClick={clearFilters}>
            Clear Filters
          </Button>
        </div>
      ) : (
        <div className="stat-card overflow-hidden p-0">
          <div className="overflow-x-auto">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Athlete</th>
                  <th>Test</th>
                  <th>Category</th>
                  <th className="text-[#FF9933]">Primary Metric</th>
                  <th>Secondary Metric</th>
                  <th>Rating</th>
                  <th>Date</th>
                  <th>PB</th>
                </tr>
              </thead>
              <tbody>
                {results.map((result) => (
                  <TestResultRow
                    key={result.id}
                    result={result}
                    onUserClick={handleUserClick}
                  />
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between" data-testid="pagination">
          <p className="text-sm text-[#64748B]">
            Showing {((page - 1) * limit) + 1} to {Math.min(page * limit, total)} of {total}
          </p>
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setPage(p => Math.max(1, p - 1))}
              disabled={page === 1}
            >
              <ChevronLeft className="w-4 h-4" />
            </Button>
            <span className="text-sm font-medium px-3">
              Page {page} of {totalPages}
            </span>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setPage(p => Math.min(totalPages, p + 1))}
              disabled={page === totalPages}
            >
              <ChevronRight className="w-4 h-4" />
            </Button>
          </div>
        </div>
      )}
    </div>
  );
};

export default TestResults;
