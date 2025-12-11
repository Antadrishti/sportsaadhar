import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { apiClient } from '@/App';
import { toast } from 'sonner';
import { getTestMetrics, formatMetric } from '@/utils/testMetrics';
import { Button } from '@/components/ui/button';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog';
import { Textarea } from '@/components/ui/textarea';
import {
  ArrowLeft,
  CheckCircle2,
  XCircle,
  Flag,
  Clock,
  MapPin,
  Mail,
  Phone,
  Calendar,
  Zap,
  Star,
  Activity,
  TrendingUp,
  Award,
  History,
  User,
  FileText
} from 'lucide-react';

const StatusBadge = ({ status }) => {
  const badges = {
    verified: { class: 'badge-verified', icon: CheckCircle2, label: 'Verified' },
    flagged: { class: 'badge-flagged', icon: XCircle, label: 'Flagged' },
    pending: { class: 'badge-pending', icon: Clock, label: 'Pending' },
  };

  const badge = badges[status] || badges.pending;
  const Icon = badge.icon;

  return (
    <span className={`inline-flex items-center gap-1 px-3 py-1 text-sm font-medium rounded-full ${badge.class}`}>
      <Icon className="w-4 h-4" />
      {badge.label}
    </span>
  );
};

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

const InfoItem = ({ icon: Icon, label, value }) => (
  <div className="flex items-start gap-3">
    <Icon className="w-4 h-4 text-[#64748B] mt-0.5" />
    <div>
      <p className="text-xs text-[#64748B] uppercase tracking-wider">{label}</p>
      <p className="text-sm font-medium text-[#0F172A]">{value || 'N/A'}</p>
    </div>
  </div>
);

const CategoryScoreCard = ({ category, score }) => {
  const colors = {
    strength: 'bg-[#1E3A8A]',
    endurance: 'bg-[#0EA5E9]',
    flexibility: 'bg-emerald-500',
    agility: 'bg-amber-500',
    speed: 'bg-red-500'
  };

  return (
    <div className="text-center p-4 bg-[#F8FAFC] rounded-sm">
      <div className="relative w-16 h-16 mx-auto mb-2">
        <svg className="w-full h-full progress-ring" viewBox="0 0 36 36">
          <path
            className="text-[#E2E8F0]"
            stroke="currentColor"
            strokeWidth="3"
            fill="none"
            d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
          />
          <path
            className={`${colors[category]?.replace('bg-', 'text-') || 'text-[#0F172A]'}`}
            stroke="currentColor"
            strokeWidth="3"
            fill="none"
            strokeLinecap="round"
            strokeDasharray={`${score}, 100`}
            d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
          />
        </svg>
        <span className="absolute inset-0 flex items-center justify-center text-sm font-heading font-bold">
          {score?.toFixed(0) || 0}
        </span>
      </div>
      <p className="text-xs text-[#64748B] uppercase tracking-wider capitalize">{category}</p>
    </div>
  );
};

const TestResultRow = ({ result }) => {
  const testMetricsConfig = getTestMetrics(result.testName);

  // Get the primary metric value for display
  const getMetricDisplay = () => {
    if (!testMetricsConfig) {
      return `Score: ${result.comparisonScore?.toFixed(1) || 'N/A'}`;
    }

    const primaryMetric = testMetricsConfig.primaryMetric;
    const value = result[primaryMetric];

    if (value === null || value === undefined) {
      return 'N/A';
    }

    // Format based on metric type
    if (primaryMetric === 'timeTaken') {
      const mins = Math.floor(value / 60);
      const secs = (value % 60).toFixed(1);
      return `${mins}:${secs.padStart(4, '0')}`;
    } else if (primaryMetric === 'speed') {
      return `${value.toFixed(2)} m/s`;
    } else if (primaryMetric === 'distance') {
      // For reps tests, show as integer
      if (result.testName?.includes('ups')) {
        return `${Math.round(value)} reps`;
      }
      return `${value} cm`;
    }

    return formatMetric(result.testName, primaryMetric, value);
  };

  return (
    <div className="flex items-center justify-between py-3 px-4 border-b border-[#F1F5F9] last:border-0 hover:bg-[#F8FAFC] transition-colors">
      <div className="flex items-center gap-4">
        <div className="w-10 h-10 bg-[#F1F5F9] rounded-sm flex items-center justify-center">
          <Activity className="w-5 h-5 text-[#64748B]" />
        </div>
        <div>
          <p className="font-medium text-[#0F172A]">{result.testName}</p>
          <p className="text-xs text-[#64748B]">{result.category} • {result.testType}</p>
        </div>
      </div>
      <div className="flex items-center gap-6">
        <div className="text-right">
          <p className="font-mono font-medium text-[#FF9933]">
            {getMetricDisplay()}
          </p>
          <p className="text-xs text-[#64748B]">
            {new Date(result.date).toLocaleDateString()}
          </p>
        </div>
        <RatingBadge rating={result.performanceRating} />
        {result.isPersonalBest && (
          <span className="px-2 py-0.5 text-xs font-medium bg-amber-100 text-amber-700 rounded-full">
            PB
          </span>
        )}
      </div>
    </div>
  );
};

const ActivityLogRow = ({ log }) => (
  <div className="flex items-center justify-between py-3 px-4 border-b border-[#F1F5F9] last:border-0">
    <div className="flex items-center gap-3">
      <div className="w-8 h-8 bg-[#F1F5F9] rounded-full flex items-center justify-center">
        <History className="w-4 h-4 text-[#64748B]" />
      </div>
      <div>
        <p className="text-sm font-medium text-[#0F172A] capitalize">{log.activityType}</p>
        <p className="text-xs text-[#64748B]">
          {new Date(log.activityDate).toLocaleString()}
        </p>
      </div>
    </div>
    {log.metadata?.xpEarned && (
      <span className="text-sm font-mono text-[#FF9933]">+{log.metadata.xpEarned} XP</span>
    )}
  </div>
);

const CandidateProfile = () => {
  const { id } = useParams();
  const navigate = useNavigate();

  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [actionModal, setActionModal] = useState({ open: false, type: '' });
  const [actionNote, setActionNote] = useState('');

  useEffect(() => {
    const fetchCandidate = async () => {
      try {
        setLoading(true);
        const response = await apiClient.get(`/admin/candidates/${id}`);
        setData(response.data);
      } catch (err) {
        console.error('Failed to fetch candidate:', err);
        toast.error('Failed to load candidate profile');
      } finally {
        setLoading(false);
      }
    };

    fetchCandidate();
  }, [id]);

  const executeAction = async () => {
    try {
      await apiClient.patch(`/admin/candidates/${id}/verify`, {
        action: actionModal.type === 'verify' ? 'verified' : actionModal.type === 'flag' ? 'flagged' : 'pending',
        note: actionNote,
        adminId: 'SAI_ADMIN_001'
      });

      toast.success(`Candidate ${actionModal.type === 'verify' ? 'verified' : actionModal.type === 'flag' ? 'flagged' : 'unverified'} successfully`);
      setActionModal({ open: false, type: '' });
      setActionNote('');

      // Refresh data
      const response = await apiClient.get(`/admin/candidates/${id}`);
      setData(response.data);
    } catch (err) {
      console.error('Action failed:', err);
    }
  };

  if (loading) {
    return (
      <div className="space-y-6" data-testid="profile-loading">
        <div className="h-8 w-32 skeleton" />
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 h-96 skeleton" />
          <div className="h-96 skeleton" />
        </div>
      </div>
    );
  }

  if (!data?.candidate) {
    return (
      <div className="text-center py-12" data-testid="profile-not-found">
        <p className="text-[#64748B]">Candidate not found</p>
        <Button className="mt-4" onClick={() => navigate('/candidates')}>
          Back to List
        </Button>
      </div>
    );
  }

  const { candidate, testResults, activityLogs } = data;
  const verification = candidate.verification?.status || 'pending';

  return (
    <div className="space-y-6" data-testid="candidate-profile">
      {/* Back button */}
      <Button
        variant="ghost"
        onClick={() => navigate('/candidates')}
        className="-ml-2"
        data-testid="back-btn"
      >
        <ArrowLeft className="w-4 h-4 mr-2" />
        Back to Candidates
      </Button>

      {/* Header */}
      <div className="stat-card">
        <div className="flex flex-col lg:flex-row lg:items-start lg:justify-between gap-6">
          <div className="flex items-start gap-4">
            <div className="w-20 h-20 bg-[#F1F5F9] rounded-full flex items-center justify-center">
              <span className="text-2xl font-heading font-bold text-[#64748B]">
                {candidate.name?.charAt(0) || '?'}
              </span>
            </div>
            <div>
              <div className="flex items-center gap-3 mb-2">
                <h1 className="text-2xl font-heading font-bold tracking-tight text-[#0F172A]">
                  {candidate.name}
                </h1>
                <StatusBadge status={verification} />
              </div>
              <p className="text-[#64748B] flex items-center gap-2">
                <MapPin className="w-4 h-4" />
                {candidate.city}, {candidate.state}
              </p>
              <p className="text-xs font-mono text-[#94A3B8] mt-1">ID: {candidate.id}</p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            {verification !== 'verified' && (
              <Button
                className="bg-emerald-500 hover:bg-emerald-600"
                onClick={() => setActionModal({ open: true, type: 'verify' })}
                data-testid="verify-profile-btn"
              >
                <CheckCircle2 className="w-4 h-4 mr-2" />
                Verify
              </Button>
            )}
            {verification !== 'flagged' && (
              <Button
                variant="outline"
                className="text-red-500 border-red-200 hover:bg-red-50"
                onClick={() => setActionModal({ open: true, type: 'flag' })}
                data-testid="flag-profile-btn"
              >
                <Flag className="w-4 h-4 mr-2" />
                Flag
              </Button>
            )}
            {verification !== 'pending' && (
              <Button
                variant="outline"
                onClick={() => setActionModal({ open: true, type: 'unverify' })}
                data-testid="unverify-profile-btn"
              >
                <XCircle className="w-4 h-4 mr-2" />
                Reset Status
              </Button>
            )}
          </div>
        </div>
      </div>

      {/* Main content */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left column - Details */}
        <div className="space-y-6">
          {/* Personal Info */}
          <div className="stat-card">
            <h2 className="font-heading font-bold text-lg text-[#0F172A] mb-4 flex items-center gap-2">
              <User className="w-5 h-5" />
              Personal Information
            </h2>
            <div className="space-y-4">
              <InfoItem icon={Calendar} label="Age" value={candidate.age} />
              <InfoItem icon={User} label="Gender" value={candidate.gender} />
              <InfoItem icon={Activity} label="Height" value={`${candidate.height} cm`} />
              <InfoItem icon={Activity} label="Weight" value={`${candidate.weight} kg`} />
              <InfoItem icon={Mail} label="Email" value={candidate.email} />
              <InfoItem icon={Phone} label="Phone" value={candidate.phoneNumber} />
              <InfoItem icon={FileText} label="Aadhaar" value={candidate.aadhaarNumber?.slice(-4).padStart(12, '****')} />
            </div>
          </div>

          {/* XP & Level */}
          <div className="stat-card">
            <h2 className="font-heading font-bold text-lg text-[#0F172A] mb-4 flex items-center gap-2">
              <Zap className="w-5 h-5" />
              Progress
            </h2>
            <div className="grid grid-cols-2 gap-4 mb-4">
              <div className="text-center p-4 bg-[#1E3A8A] rounded-sm">
                <p className="text-2xl font-heading font-bold text-white">
                  {candidate.currentXP || 0}
                </p>
                <p className="text-xs text-white/70 uppercase tracking-wider">Total XP</p>
              </div>
              <div className="text-center p-4 bg-[#0EA5E9] rounded-sm">
                <p className="text-2xl font-heading font-bold text-white">
                  {candidate.currentLevel || 1}
                </p>
                <p className="text-xs text-white/70 uppercase tracking-wider">Level</p>
              </div>
            </div>
            <div className="text-center p-3 bg-[#F8FAFC] rounded-sm">
              <p className="font-medium text-[#0F172A]">{candidate.levelTitle || 'Beginner'}</p>
              <p className="text-xs text-[#64748B]">
                {candidate.testsCompleted || 0} / {candidate.totalTests || 10} Tests Completed
              </p>
            </div>
          </div>

          {/* Streaks */}
          <div className="stat-card">
            <h2 className="font-heading font-bold text-lg text-[#0F172A] mb-4 flex items-center gap-2">
              <TrendingUp className="w-5 h-5" />
              Streaks
            </h2>
            <div className="grid grid-cols-2 gap-4">
              <div className="text-center p-3 bg-[#F8FAFC] rounded-sm">
                <p className="text-xl font-heading font-bold text-[#0F172A]">
                  {candidate.currentStreak || 0}
                </p>
                <p className="text-xs text-[#64748B]">Current Streak</p>
              </div>
              <div className="text-center p-3 bg-[#F8FAFC] rounded-sm">
                <p className="text-xl font-heading font-bold text-[#0F172A]">
                  {candidate.longestStreak || 0}
                </p>
                <p className="text-xs text-[#64748B]">Longest Streak</p>
              </div>
            </div>
          </div>
        </div>

        {/* Right column - Tests & Activity */}
        <div className="lg:col-span-2 space-y-6">
          {/* Category Scores */}
          <div className="stat-card">
            <h2 className="font-heading font-bold text-lg text-[#0F172A] mb-4 flex items-center gap-2">
              <Award className="w-5 h-5" />
              Category Scores
            </h2>
            <div className="grid grid-cols-5 gap-4">
              {candidate.categoryScores && Object.entries(candidate.categoryScores).map(([category, score]) => (
                <CategoryScoreCard key={category} category={category} score={score} />
              ))}
            </div>
          </div>

          {/* Tabs for Tests & Activity */}
          <Tabs defaultValue="tests" className="stat-card p-0">
            <TabsList className="w-full justify-start border-b border-[#E2E8F0] rounded-none px-4 pt-4">
              <TabsTrigger value="tests" className="data-[state=active]:border-b-2 data-[state=active]:border-[#0F172A]">
                Test Results ({testResults?.length || 0})
              </TabsTrigger>
              <TabsTrigger value="activity" className="data-[state=active]:border-b-2 data-[state=active]:border-[#0F172A]">
                Activity Log ({activityLogs?.length || 0})
              </TabsTrigger>
            </TabsList>

            <TabsContent value="tests" className="mt-0">
              <div className="max-h-[500px] overflow-y-auto">
                {testResults?.length > 0 ? (
                  testResults.map((result) => (
                    <TestResultRow key={result.id} result={result} />
                  ))
                ) : (
                  <p className="text-center py-8 text-[#64748B]">No test results yet</p>
                )}
              </div>
            </TabsContent>

            <TabsContent value="activity" className="mt-0">
              <div className="max-h-[500px] overflow-y-auto">
                {activityLogs?.length > 0 ? (
                  activityLogs.map((log) => (
                    <ActivityLogRow key={log.id} log={log} />
                  ))
                ) : (
                  <p className="text-center py-8 text-[#64748B]">No activity logs yet</p>
                )}
              </div>
            </TabsContent>
          </Tabs>

          {/* Verification Info */}
          {candidate.verification && (
            <div className="stat-card">
              <h2 className="font-heading font-bold text-lg text-[#0F172A] mb-4">
                Verification Details
              </h2>
              <div className="space-y-2 text-sm">
                <p><span className="text-[#64748B]">Status:</span> <StatusBadge status={verification} /></p>
                <p><span className="text-[#64748B]">Admin ID:</span> {candidate.verification.adminId}</p>
                <p><span className="text-[#64748B]">Updated:</span> {new Date(candidate.verification.updatedAt).toLocaleString()}</p>
                {candidate.verification.note && (
                  <p><span className="text-[#64748B]">Note:</span> {candidate.verification.note}</p>
                )}
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Action Modal */}
      <Dialog open={actionModal.open} onOpenChange={(open) => setActionModal({ ...actionModal, open })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {actionModal.type === 'verify' ? 'Verify Candidate' :
                actionModal.type === 'flag' ? 'Flag Candidate' : 'Reset Verification Status'}
            </DialogTitle>
          </DialogHeader>
          <div className="py-4">
            <label className="text-sm font-medium text-[#0F172A]">
              Note (optional)
            </label>
            <Textarea
              placeholder="Add a note for the audit log..."
              value={actionNote}
              onChange={(e) => setActionNote(e.target.value)}
              className="mt-2"
              data-testid="action-note-textarea"
            />
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setActionModal({ open: false, type: '' })}>
              Cancel
            </Button>
            <Button
              className={
                actionModal.type === 'verify' ? 'bg-emerald-500 hover:bg-emerald-600' :
                  actionModal.type === 'flag' ? 'bg-red-500 hover:bg-red-600' : ''
              }
              onClick={executeAction}
              data-testid="confirm-action-btn"
            >
              {actionModal.type === 'verify' ? 'Verify' :
                actionModal.type === 'flag' ? 'Flag' : 'Reset'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default CandidateProfile;
