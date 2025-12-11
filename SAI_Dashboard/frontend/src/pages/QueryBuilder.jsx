import { useState, useEffect } from 'react';
import { apiClient } from '@/App';
import { toast } from 'sonner';
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
  Plus,
  Trash2,
  Play,
  ChevronDown,
  ChevronRight,
  Code,
  Copy,
  Users,
  X,
  ClipboardList
} from 'lucide-react';

const OPERATORS = [
  { value: '$eq', label: 'Equals' },
  { value: '$ne', label: 'Not Equals' },
  { value: '$gt', label: 'Greater Than' },
  { value: '$gte', label: 'Greater Than or Equal' },
  { value: '$lt', label: 'Less Than' },
  { value: '$lte', label: 'Less Than or Equal' },
  { value: '$regex', label: 'Contains' },
  { value: '$in', label: 'In List' },
];

const CANDIDATE_FIELDS = [
  { value: 'name', label: 'Name', type: 'string' },
  { value: 'age', label: 'Age', type: 'number' },
  { value: 'gender', label: 'Gender', type: 'string' },
  { value: 'state', label: 'State', type: 'string' },
  { value: 'city', label: 'City', type: 'string' },
  { value: 'currentXP', label: 'Current XP', type: 'number' },
  { value: 'currentLevel', label: 'Level', type: 'number' },
  { value: 'testsCompleted', label: 'Tests Completed', type: 'number' },
  // Combined Test + Metric filters (format: testFilter.TestName.metric)
  { value: 'testFilter.1600m Run.timeTaken', label: '1600m Run - Time (sec)', type: 'number', isTestMetric: true },
  { value: 'testFilter.1600m Run.speed', label: '1600m Run - Speed (m/s)', type: 'number', isTestMetric: true },
  { value: 'testFilter.800m Run.timeTaken', label: '800m Run - Time (sec)', type: 'number', isTestMetric: true },
  { value: 'testFilter.800m Run.speed', label: '800m Run - Speed (m/s)', type: 'number', isTestMetric: true },
  { value: 'testFilter.30m Sprint.timeTaken', label: '30m Sprint - Time (sec)', type: 'number', isTestMetric: true },
  { value: 'testFilter.30m Sprint.speed', label: '30m Sprint - Speed (m/s)', type: 'number', isTestMetric: true },
  { value: 'testFilter.4×10m Shuttle Run.timeTaken', label: 'Shuttle Run - Time (sec)', type: 'number', isTestMetric: true },
  { value: 'testFilter.4×10m Shuttle Run.speed', label: 'Shuttle Run - Speed (m/s)', type: 'number', isTestMetric: true },
  { value: 'testFilter.Sit-ups (1 min).distance', label: 'Sit-ups - Reps', type: 'number', isTestMetric: true },
  { value: 'testFilter.Push-ups (1 min).distance', label: 'Push-ups - Reps', type: 'number', isTestMetric: true },
  { value: 'testFilter.Sit and Reach.distance', label: 'Sit and Reach - Distance (cm)', type: 'number', isTestMetric: true },
  { value: 'testFilter.Standing Broad Jump.distance', label: 'Standing Broad Jump - Distance (cm)', type: 'number', isTestMetric: true },
  { value: 'testFilter.Standing Vertical Jump.distance', label: 'Standing Vertical Jump - Height (cm)', type: 'number', isTestMetric: true },
  { value: 'testFilter.Medicine Ball Throw.distance', label: 'Medicine Ball Throw - Distance (m)', type: 'number', isTestMetric: true },
  // Category scores
  { value: 'categoryScores.strength', label: 'Strength Score', type: 'number' },
  { value: 'categoryScores.endurance', label: 'Endurance Score', type: 'number' },
  { value: 'categoryScores.flexibility', label: 'Flexibility Score', type: 'number' },
  { value: 'categoryScores.agility', label: 'Agility Score', type: 'number' },
  { value: 'categoryScores.speed', label: 'Speed Score', type: 'number' },
  { value: 'verification.status', label: 'Verification Status', type: 'string' },
];

const GROUP_BY_FIELDS = [
  { value: 'state', label: 'State' },
  { value: 'city', label: 'City' },
  { value: 'gender', label: 'Gender' },
  { value: 'currentLevel', label: 'Level' },
  { value: 'verification.status', label: 'Verification Status' },
];

const FilterCondition = ({ condition, index, onChange, onRemove }) => {
  return (
    <div className="flex items-center gap-2 flex-wrap" data-testid={`condition-${index}`}>
      <Select
        value={condition.field}
        onValueChange={(v) => onChange(index, { ...condition, field: v })}
      >
        <SelectTrigger className="w-[180px]">
          <SelectValue placeholder="Select field" />
        </SelectTrigger>
        <SelectContent>
          {CANDIDATE_FIELDS.map((f) => (
            <SelectItem key={f.value} value={f.value}>{f.label}</SelectItem>
          ))}
        </SelectContent>
      </Select>

      <Select
        value={condition.operator}
        onValueChange={(v) => onChange(index, { ...condition, operator: v })}
      >
        <SelectTrigger className="w-[160px]">
          <SelectValue placeholder="Operator" />
        </SelectTrigger>
        <SelectContent>
          {OPERATORS.map((op) => (
            <SelectItem key={op.value} value={op.value}>{op.label}</SelectItem>
          ))}
        </SelectContent>
      </Select>

      <Input
        value={condition.value}
        onChange={(e) => onChange(index, { ...condition, value: e.target.value })}
        placeholder="Value"
        className="w-[150px]"
        data-testid={`condition-value-${index}`}
      />

      <Button variant="ghost" size="sm" onClick={() => onRemove(index)}>
        <Trash2 className="w-4 h-4 text-red-500" />
      </Button>
    </div>
  );
};

const FilterGroup = ({ group, groupIndex, logic, onConditionChange, onConditionRemove, onAddCondition, onRemoveGroup, onLogicChange }) => {
  return (
    <div className="filter-group" data-testid={`filter-group-${groupIndex}`}>
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          <span className="text-sm font-medium text-[#64748B]">Group {groupIndex + 1}</span>
          <Select value={logic} onValueChange={(v) => onLogicChange(groupIndex, v)}>
            <SelectTrigger className="w-[80px] h-7 text-xs">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="$and">AND</SelectItem>
              <SelectItem value="$or">OR</SelectItem>
            </SelectContent>
          </Select>
        </div>
        {groupIndex > 0 && (
          <Button variant="ghost" size="sm" onClick={() => onRemoveGroup(groupIndex)}>
            <X className="w-4 h-4" />
          </Button>
        )}
      </div>

      <div className="space-y-2">
        {group.map((condition, condIndex) => (
          <FilterCondition
            key={condIndex}
            condition={condition}
            index={condIndex}
            onChange={(idx, newCond) => onConditionChange(groupIndex, idx, newCond)}
            onRemove={(idx) => onConditionRemove(groupIndex, idx)}
          />
        ))}
      </div>

      <Button
        variant="ghost"
        size="sm"
        className="mt-3"
        onClick={() => onAddCondition(groupIndex)}
        data-testid={`add-condition-${groupIndex}`}
      >
        <Plus className="w-4 h-4 mr-1" />
        Add Condition
      </Button>
    </div>
  );
};

const ResultsTable = ({ results, grouped, groupByFields, testFilters = [] }) => {
  // Build metric columns from testFilters
  const metricColumns = testFilters.map(tf => ({
    testName: tf.testName,
    metric: tf.metric,
    label: `${tf.testName.replace(/\s*\(.*\)/, '')} ${tf.metric === 'distance' ? (tf.testName.includes('ups') ? 'Reps' : 'Dist') : tf.metric === 'timeTaken' ? 'Time' : 'Speed'}`
  }));

  if (grouped) {
    // Get field labels for display
    const getFieldLabel = (key) => {
      const cleanKey = key.replace(/_/g, '.');
      const field = GROUP_BY_FIELDS.find(f => f.value === cleanKey || f.value.replace('.', '_') === key);
      return field?.label || key;
    };

    return (
      <div className="space-y-2">
        {results.map((row, idx) => {
          // Build the display string from _id values
          const groupValues = Object.entries(row._id || {}).map(([key, value]) => {
            return value || 'N/A';
          });
          const displayLabel = groupValues.join(' → ');

          return (
            <div key={idx} className="p-4 bg-[#F8FAFC] rounded-sm border border-[#E2E8F0] hover:border-[#0EA5E9] transition-colors">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span className="text-base font-medium text-[#0F172A]">
                    {displayLabel}
                  </span>
                </div>
                <div className="flex items-center gap-4">
                  <span className="px-3 py-1 bg-[#1E3A8A] text-white text-sm font-mono rounded-sm">
                    {row.count} candidates
                  </span>
                  {row.avgXP && (
                    <span className="text-sm text-[#64748B]">
                      Avg XP: <span className="font-mono text-[#FF9933]">{Math.round(row.avgXP)}</span>
                    </span>
                  )}
                  {row.avgAge && (
                    <span className="text-sm text-[#64748B]">
                      Avg Age: <span className="font-mono">{Math.round(row.avgAge)}</span>
                    </span>
                  )}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    );
  }

  return (
    <div className="overflow-x-auto">
      <table className="data-table">
        <thead>
          <tr>
            <th>Name</th>
            <th>Age</th>
            <th>Gender</th>
            <th>State</th>
            <th>XP</th>
            <th>Level</th>
            {metricColumns.map((mc, i) => (
              <th key={i} className="text-[#FF9933]">{mc.label}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {results.map((row) => (
            <tr key={row.id || row._id} className="hover:bg-[#F8FAFC]/50">
              <td className="px-4 py-3 font-medium">{row.name}</td>
              <td className="px-4 py-3 font-mono text-sm">{row.age}</td>
              <td className="px-4 py-3 text-sm">{row.gender}</td>
              <td className="px-4 py-3 text-sm">{row.state}</td>
              <td className="px-4 py-3 font-mono text-sm text-[#FF9933]">{row.currentXP}</td>
              <td className="px-4 py-3 font-mono text-sm">{row.currentLevel}</td>
              {metricColumns.map((mc, i) => {
                const testData = row.testMetrics?.[mc.testName];
                const value = testData?.[mc.metric];
                let displayValue = value ?? 'N/A';
                if (mc.metric === 'timeTaken' && value) {
                  const mins = Math.floor(value / 60);
                  const secs = (value % 60).toFixed(1);
                  displayValue = `${mins}:${secs.padStart(4, '0')}`;
                } else if (mc.metric === 'speed' && value) {
                  displayValue = `${value.toFixed(2)} m/s`;
                } else if (value) {
                  displayValue = Math.round(value);
                }
                return (
                  <td key={i} className="px-4 py-3 font-mono text-sm text-[#FF9933]">
                    {displayValue}
                  </td>
                );
              })}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

const QueryBuilder = () => {
  const [filterGroups, setFilterGroups] = useState([[{ field: '', operator: '$eq', value: '' }]]);
  const [groupLogics, setGroupLogics] = useState(['$and']);
  const [groupBy, setGroupBy] = useState([]);
  const [sortField, setSortField] = useState('createdAt');
  const [sortDir, setSortDir] = useState('desc');
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(25);

  const [results, setResults] = useState(null);
  const [loading, setLoading] = useState(false);
  const [showJson, setShowJson] = useState(false);

  const buildQueryObject = () => {
    const filters = {};

    filterGroups.forEach((group, groupIdx) => {
      const conditions = group
        .filter(c => c.field && c.operator && c.value)
        .map(c => {
          const fieldType = CANDIDATE_FIELDS.find(f => f.value === c.field)?.type || 'string';
          let value = c.value;

          if (fieldType === 'number') {
            value = parseFloat(value);
          }

          if (c.operator === '$eq') {
            return { [c.field]: value };
          } else if (c.operator === '$regex') {
            return { [c.field]: { $regex: value, $options: 'i' } };
          } else if (c.operator === '$in') {
            return { [c.field]: { $in: value.split(',').map(v => v.trim()) } };
          } else {
            return { [c.field]: { [c.operator]: value } };
          }
        });

      if (conditions.length > 0) {
        const logic = groupLogics[groupIdx] || '$and';
        if (groupIdx === 0) {
          if (conditions.length === 1) {
            Object.assign(filters, conditions[0]);
          } else {
            filters[logic] = conditions;
          }
        } else {
          if (!filters.$and) filters.$and = [];
          filters.$and.push({ [logic]: conditions });
        }
      }
    });

    return {
      filters,
      sort: [{ field: sortField, dir: sortDir }],
      groupBy,
      aggregate: groupBy.length > 0 ? [
        { op: 'avg', field: 'currentXP', alias: 'avgXP' },
        { op: 'avg', field: 'age', alias: 'avgAge' }
      ] : [],
      page,
      limit
    };
  };

  const executeQuery = async () => {
    try {
      setLoading(true);
      const queryObj = buildQueryObject();
      const response = await apiClient.post('/admin/query', queryObj);
      setResults(response.data);
      toast.success(`Found ${response.data.total} results`);
    } catch (err) {
      console.error('Query failed:', err);
      toast.error('Query failed');
    } finally {
      setLoading(false);
    }
  };

  const addCondition = (groupIdx) => {
    const newGroups = [...filterGroups];
    newGroups[groupIdx].push({ field: '', operator: '$eq', value: '' });
    setFilterGroups(newGroups);
  };

  const removeCondition = (groupIdx, condIdx) => {
    const newGroups = [...filterGroups];
    newGroups[groupIdx].splice(condIdx, 1);
    if (newGroups[groupIdx].length === 0) {
      newGroups[groupIdx].push({ field: '', operator: '$eq', value: '' });
    }
    setFilterGroups(newGroups);
  };

  const updateCondition = (groupIdx, condIdx, newCond) => {
    const newGroups = [...filterGroups];
    newGroups[groupIdx][condIdx] = newCond;
    setFilterGroups(newGroups);
  };

  const addGroup = () => {
    setFilterGroups([...filterGroups, [{ field: '', operator: '$eq', value: '' }]]);
    setGroupLogics([...groupLogics, '$and']);
  };

  const removeGroup = (groupIdx) => {
    const newGroups = filterGroups.filter((_, idx) => idx !== groupIdx);
    const newLogics = groupLogics.filter((_, idx) => idx !== groupIdx);
    setFilterGroups(newGroups);
    setGroupLogics(newLogics);
  };

  const updateGroupLogic = (groupIdx, logic) => {
    const newLogics = [...groupLogics];
    newLogics[groupIdx] = logic;
    setGroupLogics(newLogics);
  };

  const toggleGroupBy = (field) => {
    if (groupBy.includes(field)) {
      setGroupBy(groupBy.filter(f => f !== field));
    } else {
      setGroupBy([...groupBy, field]);
    }
  };

  const copyQuery = () => {
    navigator.clipboard.writeText(JSON.stringify(buildQueryObject(), null, 2));
    toast.success('Query copied to clipboard');
  };

  const resetQuery = () => {
    setFilterGroups([[{ field: '', operator: '$eq', value: '' }]]);
    setGroupLogics(['$and']);
    setGroupBy([]);
    setSortField('createdAt');
    setSortDir('desc');
    setResults(null);
  };

  return (
    <div className="space-y-6" data-testid="query-builder">
      {/* Header */}
      <div>
        <h1 className="text-2xl lg:text-3xl font-heading font-bold tracking-tight text-[#0F172A]">
          Query Builder
        </h1>
        <p className="text-[#64748B] mt-1">
          Build complex filters with AND/OR logic
        </p>
      </div>

      {/* Query Builder */}
      <div className="stat-card">
        <div className="flex items-center justify-between mb-6">
          <h2 className="font-heading font-bold text-lg text-[#0F172A] flex items-center gap-2">
            <Search className="w-5 h-5" />
            Filter Conditions
          </h2>
          <div className="flex items-center gap-2">
            <Button variant="outline" size="sm" onClick={resetQuery}>
              Reset
            </Button>
            <Button variant="outline" size="sm" onClick={addGroup}>
              <Plus className="w-4 h-4 mr-1" />
              Add Group
            </Button>
          </div>
        </div>

        <div className="space-y-4">
          {filterGroups.map((group, groupIdx) => (
            <FilterGroup
              key={groupIdx}
              group={group}
              groupIndex={groupIdx}
              logic={groupLogics[groupIdx]}
              onConditionChange={updateCondition}
              onConditionRemove={removeCondition}
              onAddCondition={addCondition}
              onRemoveGroup={removeGroup}
              onLogicChange={updateGroupLogic}
            />
          ))}
        </div>
      </div>

      {/* Group By */}
      <div className="stat-card">
        <h2 className="font-heading font-bold text-lg text-[#0F172A] mb-4 flex items-center gap-2">
          <Users className="w-5 h-5" />
          Group By
        </h2>
        <div className="flex flex-wrap gap-2">
          {GROUP_BY_FIELDS.map((field) => (
            <Button
              key={field.value}
              variant={groupBy.includes(field.value) ? 'default' : 'outline'}
              size="sm"
              onClick={() => toggleGroupBy(field.value)}
              data-testid={`groupby-${field.value}`}
            >
              {field.label}
            </Button>
          ))}
        </div>
      </div>

      {/* Sort & Pagination */}
      <div className="stat-card">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div>
            <label className="text-sm font-medium text-[#64748B] block mb-2">Sort By</label>
            <Select value={sortField} onValueChange={setSortField}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {CANDIDATE_FIELDS.map((f) => (
                  <SelectItem key={f.value} value={f.value}>{f.label}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div>
            <label className="text-sm font-medium text-[#64748B] block mb-2">Direction</label>
            <Select value={sortDir} onValueChange={setSortDir}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="asc">Ascending</SelectItem>
                <SelectItem value="desc">Descending</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div>
            <label className="text-sm font-medium text-[#64748B] block mb-2">Per Page</label>
            <Select value={limit.toString()} onValueChange={(v) => setLimit(parseInt(v))}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="10">10</SelectItem>
                <SelectItem value="25">25</SelectItem>
                <SelectItem value="50">50</SelectItem>
                <SelectItem value="100">100</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div className="flex items-end">
            <Button
              className="w-full bg-[#1E3A8A] hover:bg-[#1E3A8A]/90"
              onClick={executeQuery}
              disabled={loading}
              data-testid="execute-query-btn"
            >
              <Play className="w-4 h-4 mr-2" />
              {loading ? 'Running...' : 'Run Query'}
            </Button>
          </div>
        </div>
      </div>

      {/* JSON Preview */}
      <div className="stat-card">
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-heading font-bold text-lg text-[#0F172A] flex items-center gap-2">
            <Code className="w-5 h-5" />
            Query JSON
          </h2>
          <div className="flex items-center gap-2">
            <Button variant="outline" size="sm" onClick={copyQuery} data-testid="copy-query-btn">
              <Copy className="w-4 h-4 mr-1" />
              Copy
            </Button>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setShowJson(!showJson)}
            >
              {showJson ? <ChevronDown className="w-4 h-4" /> : <ChevronRight className="w-4 h-4" />}
            </Button>
          </div>
        </div>
        {showJson && (
          <pre className="json-preview" data-testid="query-json-preview">
            {JSON.stringify(buildQueryObject(), null, 2)}
          </pre>
        )}
      </div>

      {/* Results */}
      {results && (
        <div className="stat-card" data-testid="query-results">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-heading font-bold text-lg text-[#0F172A]">
              Results ({results.total})
            </h2>
            <span className="text-sm text-[#64748B]">
              Page {results.page} of {results.totalPages}
            </span>
          </div>

          {results.results?.length > 0 ? (
            <ResultsTable results={results.results} grouped={results.grouped} groupByFields={groupBy} testFilters={results.testFilters || []} />
          ) : (
            <p className="text-center py-8 text-[#64748B]">No results found</p>
          )}
        </div>
      )}
    </div>
  );
};

export default QueryBuilder;
