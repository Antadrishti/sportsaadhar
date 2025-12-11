import { useState, useEffect } from 'react';
import { apiClient } from '@/App';
import { useNavigate } from 'react-router-dom';
import {
  Users,
  CheckCircle2,
  AlertTriangle,
  Clock,
  TrendingUp,
  MapPin,
  Zap,
  Target,
  Activity,
  ChevronRight
} from 'lucide-react';

const StatCard = ({ title, value, subtitle, icon: Icon, trend, color = 'primary' }) => {
  const colorClasses = {
    primary: 'bg-[#1E3A8A] text-white',
    accent: 'bg-[#0EA5E9] text-white',
    success: 'bg-emerald-500 text-white',
    warning: 'bg-amber-500 text-white',
    error: 'bg-red-500 text-white',
  };
  
  return (
    <div className="stat-card" data-testid={`stat-${title.toLowerCase().replace(/\s/g, '-')}`}>
      <div className="flex items-start justify-between">
        <div>
          <p className="text-xs uppercase tracking-wider text-[#64748B] font-medium mb-1">
            {title}
          </p>
          <p className="text-3xl font-heading font-bold tracking-tight text-[#0F172A]">
            {value}
          </p>
          {subtitle && (
            <p className="text-sm text-[#64748B] mt-1">{subtitle}</p>
          )}
        </div>
        <div className={`w-10 h-10 rounded-sm flex items-center justify-center ${colorClasses[color]}`}>
          <Icon className="w-5 h-5" />
        </div>
      </div>
      {trend && (
        <div className="mt-3 flex items-center gap-1 text-sm">
          <TrendingUp className="w-4 h-4 text-emerald-500" />
          <span className="text-emerald-600 font-medium">{trend}</span>
        </div>
      )}
    </div>
  );
};

const CategoryScoreBar = ({ category, score, color }) => (
  <div className="flex items-center gap-3" data-testid={`category-${category}`}>
    <span className="text-sm text-[#64748B] w-24 capitalize">{category}</span>
    <div className="flex-1 h-2 bg-[#F1F5F9] rounded-full overflow-hidden">
      <div 
        className={`h-full rounded-full transition-all duration-500 ${color}`}
        style={{ width: `${score}%` }}
      />
    </div>
    <span className="text-sm font-mono font-medium text-[#0F172A] w-12 text-right">
      {score?.toFixed(0) || 0}%
    </span>
  </div>
);

const StateDistributionItem = ({ state, count, avgXP, maxCount }) => (
  <div className="flex items-center gap-3" data-testid={`state-${state}`}>
    <MapPin className="w-4 h-4 text-[#64748B]" />
    <span className="text-sm text-[#0F172A] w-32 truncate">{state}</span>
    <div className="flex-1 h-2 bg-[#F1F5F9] rounded-full overflow-hidden">
      <div 
        className="h-full bg-[#0EA5E9] rounded-full"
        style={{ width: `${(count / maxCount) * 100}%` }}
      />
    </div>
    <span className="text-sm font-mono text-[#64748B] w-16 text-right">{count}</span>
  </div>
);

const RecentCandidateRow = ({ candidate, onClick }) => (
  <div 
    className="flex items-center justify-between py-3 px-4 hover:bg-[#F8FAFC] cursor-pointer transition-colors"
    onClick={onClick}
    data-testid={`recent-candidate-${candidate.id}`}
  >
    <div className="flex items-center gap-3">
      <div className="w-8 h-8 bg-[#F1F5F9] rounded-full flex items-center justify-center">
        <span className="text-xs font-medium text-[#64748B]">
          {candidate.name?.charAt(0) || '?'}
        </span>
      </div>
      <div>
        <p className="text-sm font-medium text-[#0F172A]">{candidate.name}</p>
        <p className="text-xs text-[#64748B]">{candidate.city}, {candidate.state}</p>
      </div>
    </div>
    <div className="flex items-center gap-3">
      <span className="text-sm font-mono text-[#FF9933]">
        {candidate.currentXP || 0} XP
      </span>
      <ChevronRight className="w-4 h-4 text-[#CBD5E1]" />
    </div>
  </div>
);

const Dashboard = () => {
  const navigate = useNavigate();
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  useEffect(() => {
    const fetchStats = async () => {
      try {
        setLoading(true);
        const response = await apiClient.get('/admin/dashboard');
        setStats(response.data);
        setError(null);
      } catch (err) {
        setError('Failed to load dashboard data');
        console.error(err);
      } finally {
        setLoading(false);
      }
    };
    
    fetchStats();
  }, []);
  
  if (loading) {
    return (
      <div className="space-y-6" data-testid="dashboard-loading">
        <div className="h-8 w-48 skeleton" />
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {[1, 2, 3, 4].map(i => (
            <div key={i} className="h-32 skeleton" />
          ))}
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="h-64 skeleton" />
          <div className="h-64 skeleton" />
        </div>
      </div>
    );
  }
  
  if (error) {
    return (
      <div className="text-center py-12" data-testid="dashboard-error">
        <p className="text-red-500">{error}</p>
        <button 
          className="mt-4 px-4 py-2 bg-[#1E3A8A] text-white rounded-sm"
          onClick={() => window.location.reload()}
        >
          Retry
        </button>
      </div>
    );
  }
  
  const categoryColors = {
    strength: 'bg-[#1E3A8A]',
    endurance: 'bg-[#0EA5E9]',
    flexibility: 'bg-emerald-500',
    agility: 'bg-amber-500',
    speed: 'bg-red-500'
  };
  
  const maxStateCount = Math.max(...(stats?.candidatesByState?.map(s => s.count) || [1]));
  
  return (
    <div className="space-y-8" data-testid="dashboard">
      {/* Header */}
      <div>
        <h1 className="text-2xl lg:text-3xl font-heading font-bold tracking-tight text-[#0F172A]">
          Dashboard
        </h1>
        <p className="text-[#64748B] mt-1">Sports Authority of India - Assessment Overview</p>
      </div>
      
      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          title="Total Candidates"
          value={stats?.totalCandidates || 0}
          subtitle="Registered athletes"
          icon={Users}
          color="primary"
        />
        <StatCard
          title="Total Assessments"
          value={stats?.totalTests || 0}
          subtitle="Tests completed"
          icon={Activity}
          color="accent"
        />
        <StatCard
          title="Verified Rate"
          value={`${stats?.verification?.verifiedRate || 0}%`}
          subtitle={`${stats?.verification?.verified || 0} verified`}
          icon={CheckCircle2}
          color="success"
        />
        <StatCard
          title="Flagged"
          value={stats?.verification?.flagged || 0}
          subtitle={`${stats?.verification?.flaggedRate || 0}% of total`}
          icon={AlertTriangle}
          color="warning"
        />
      </div>
      
      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Category Averages */}
        <div className="stat-card">
          <div className="flex items-center justify-between mb-6">
            <h2 className="font-heading font-bold text-lg text-[#0F172A]">
              Average Scores by Category
            </h2>
            <Target className="w-5 h-5 text-[#64748B]" />
          </div>
          <div className="space-y-4">
            {stats?.categoryAverages && Object.entries({
              strength: stats.categoryAverages.avgStrength,
              endurance: stats.categoryAverages.avgEndurance,
              flexibility: stats.categoryAverages.avgFlexibility,
              agility: stats.categoryAverages.avgAgility,
              speed: stats.categoryAverages.avgSpeed
            }).map(([category, score]) => (
              <CategoryScoreBar
                key={category}
                category={category}
                score={score}
                color={categoryColors[category]}
              />
            ))}
          </div>
        </div>
        
        {/* State Distribution */}
        <div className="stat-card">
          <div className="flex items-center justify-between mb-6">
            <h2 className="font-heading font-bold text-lg text-[#0F172A]">
              Candidates by State
            </h2>
            <MapPin className="w-5 h-5 text-[#64748B]" />
          </div>
          <div className="space-y-3">
            {stats?.candidatesByState?.slice(0, 6).map((item) => (
              <StateDistributionItem
                key={item.state}
                state={item.state}
                count={item.count}
                avgXP={item.avgXP}
                maxCount={maxStateCount}
              />
            ))}
          </div>
        </div>
      </div>
      
      {/* Bottom Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Test Type Distribution */}
        <div className="stat-card">
          <div className="flex items-center justify-between mb-6">
            <h2 className="font-heading font-bold text-lg text-[#0F172A]">
              Test Type Distribution
            </h2>
            <Zap className="w-5 h-5 text-[#64748B]" />
          </div>
          <div className="space-y-3">
            {stats?.testTypeDistribution?.slice(0, 5).map((item) => (
              <div key={item.testType} className="flex items-center justify-between py-2 border-b border-[#F1F5F9] last:border-0">
                <span className="text-sm text-[#0F172A]">{item.testType}</span>
                <div className="flex items-center gap-4">
                  <span className="text-sm font-mono text-[#64748B]">{item.count} tests</span>
                  <span className="text-sm font-mono font-medium text-[#FF9933]">
                    Avg: {item.avgScore?.toFixed(1)}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
        
        {/* Performance Rating Distribution */}
        <div className="stat-card">
          <div className="flex items-center justify-between mb-6">
            <h2 className="font-heading font-bold text-lg text-[#0F172A]">
              Performance Ratings
            </h2>
            <Activity className="w-5 h-5 text-[#64748B]" />
          </div>
          <div className="grid grid-cols-3 gap-4">
            {['gold', 'silver', 'bronze'].map((rating) => (
              <div 
                key={rating}
                className={`text-center p-4 rounded-sm ${rating === 'gold' ? 'bg-amber-50' : rating === 'silver' ? 'bg-slate-100' : 'bg-orange-50'}`}
                data-testid={`rating-${rating}`}
              >
                <p className={`text-2xl font-heading font-bold ${
                  rating === 'gold' ? 'text-amber-600' : 
                  rating === 'silver' ? 'text-slate-600' : 'text-orange-700'
                }`}>
                  {stats?.performanceRatings?.[rating] || 0}
                </p>
                <p className="text-xs uppercase tracking-wider text-[#64748B] mt-1 capitalize">
                  {rating}
                </p>
              </div>
            ))}
          </div>
        </div>
      </div>
      
      {/* Recent Candidates */}
      <div className="stat-card">
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-heading font-bold text-lg text-[#0F172A]">
            Recent Candidates
          </h2>
          <button
            className="text-sm text-[#FF9933] hover:underline"
            onClick={() => navigate('/candidates')}
            data-testid="view-all-candidates-btn"
          >
            View All
          </button>
        </div>
        <div className="divide-y divide-[#F1F5F9]">
          {stats?.recentCandidates?.map((candidate) => (
            <RecentCandidateRow
              key={candidate.id}
              candidate={candidate}
              onClick={() => navigate(`/candidates/${candidate.id}`)}
            />
          ))}
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
