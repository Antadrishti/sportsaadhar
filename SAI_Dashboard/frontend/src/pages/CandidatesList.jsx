import { useState, useEffect, useCallback } from 'react';
import { apiClient } from '@/App';
import { useNavigate, useSearchParams } from 'react-router-dom';
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
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog';
import { Textarea } from '@/components/ui/textarea';
import {
  Search,
  Filter,
  LayoutGrid,
  LayoutList,
  ChevronLeft,
  ChevronRight,
  CheckCircle2,
  XCircle,
  Clock,
  Eye,
  Flag,
  MoreHorizontal,
  Download
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
    <span className={`inline-flex items-center gap-1 px-2 py-0.5 text-xs font-medium rounded-full ${badge.class}`}>
      <Icon className="w-3 h-3" />
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

const CandidateCard = ({ candidate, onView, onVerify, onFlag }) => {
  const verification = candidate.verification?.status || 'pending';
  const bestTest = candidate.testProgress?.[0];
  
  return (
    <div className="candidate-card" data-testid={`candidate-card-${candidate.id}`}>
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 bg-[#F1F5F9] rounded-full flex items-center justify-center">
            <span className="text-lg font-heading font-bold text-[#64748B]">
              {candidate.name?.charAt(0) || '?'}
            </span>
          </div>
          <div>
            <h3 className="font-heading font-bold text-[#0F172A]">{candidate.name}</h3>
            <p className="text-sm text-[#64748B]">{candidate.city}, {candidate.state}</p>
          </div>
        </div>
        <StatusBadge status={verification} />
      </div>
      
      <div className="grid grid-cols-3 gap-4 mb-4">
        <div>
          <p className="text-xs text-[#64748B] uppercase tracking-wider">Age</p>
          <p className="font-mono font-medium text-[#0F172A]">{candidate.age || 'N/A'}</p>
        </div>
        <div>
          <p className="text-xs text-[#64748B] uppercase tracking-wider">Gender</p>
          <p className="font-mono font-medium text-[#0F172A]">{candidate.gender || 'N/A'}</p>
        </div>
        <div>
          <p className="text-xs text-[#64748B] uppercase tracking-wider">XP</p>
          <p className="font-mono font-medium text-[#FF9933]">{candidate.currentXP || 0}</p>
        </div>
      </div>
      
      {bestTest && (
        <div className="bg-[#F8FAFC] p-3 rounded-sm mb-4">
          <p className="text-xs text-[#64748B] mb-1">Best Performance</p>
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium text-[#0F172A]">{bestTest.testName}</span>
            <RatingBadge rating={bestTest.bestRating} />
          </div>
        </div>
      )}
      
      <div className="flex items-center gap-2">
        <Button
          variant="outline"
          size="sm"
          className="flex-1"
          onClick={() => onView(candidate.id)}
          data-testid={`view-btn-${candidate.id}`}
        >
          <Eye className="w-4 h-4 mr-1" />
          View
        </Button>
        {verification !== 'verified' && (
          <Button
            size="sm"
            className="bg-emerald-500 hover:bg-emerald-600"
            onClick={() => onVerify(candidate.id)}
            data-testid={`verify-btn-${candidate.id}`}
          >
            <CheckCircle2 className="w-4 h-4" />
          </Button>
        )}
        {verification !== 'flagged' && (
          <Button
            variant="outline"
            size="sm"
            className="text-red-500 border-red-200 hover:bg-red-50"
            onClick={() => onFlag(candidate.id)}
            data-testid={`flag-btn-${candidate.id}`}
          >
            <Flag className="w-4 h-4" />
          </Button>
        )}
      </div>
    </div>
  );
};

const CandidateRow = ({ candidate, onView, onVerify, onFlag }) => {
  const verification = candidate.verification?.status || 'pending';
  const bestTest = candidate.testProgress?.[0];
  
  return (
    <tr className="hover:bg-[#F8FAFC]/50 transition-colors" data-testid={`candidate-row-${candidate.id}`}>
      <td className="px-4 py-3">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 bg-[#F1F5F9] rounded-full flex items-center justify-center">
            <span className="text-xs font-medium text-[#64748B]">
              {candidate.name?.charAt(0) || '?'}
            </span>
          </div>
          <div>
            <p className="font-medium text-[#0F172A]">{candidate.name}</p>
            <p className="text-xs text-[#64748B] font-mono">{candidate.id?.slice(-8)}</p>
          </div>
        </div>
      </td>
      <td className="px-4 py-3 font-mono text-sm">{candidate.age || '-'}</td>
      <td className="px-4 py-3 text-sm">{candidate.gender || '-'}</td>
      <td className="px-4 py-3 text-sm">
        <span className="truncate max-w-[150px] block" title={`${candidate.city}, ${candidate.state}`}>
          {candidate.city}, {candidate.state}
        </span>
      </td>
      <td className="px-4 py-3">
        {bestTest ? (
          <div>
            <p className="text-sm text-[#0F172A]">{bestTest.testName}</p>
            <RatingBadge rating={bestTest.bestRating} />
          </div>
        ) : (
          <span className="text-sm text-[#64748B]">No tests</span>
        )}
      </td>
      <td className="px-4 py-3 font-mono text-sm text-[#FF9933]">{candidate.currentXP || 0}</td>
      <td className="px-4 py-3">
        <StatusBadge status={verification} />
      </td>
      <td className="px-4 py-3">
        <div className="flex items-center gap-1">
          <Button
            variant="ghost"
            size="sm"
            onClick={() => onView(candidate.id)}
            data-testid={`table-view-btn-${candidate.id}`}
          >
            <Eye className="w-4 h-4" />
          </Button>
          {verification !== 'verified' && (
            <Button
              variant="ghost"
              size="sm"
              className="text-emerald-600 hover:text-emerald-700 hover:bg-emerald-50"
              onClick={() => onVerify(candidate.id)}
            >
              <CheckCircle2 className="w-4 h-4" />
            </Button>
          )}
          {verification !== 'flagged' && (
            <Button
              variant="ghost"
              size="sm"
              className="text-red-500 hover:text-red-600 hover:bg-red-50"
              onClick={() => onFlag(candidate.id)}
            >
              <Flag className="w-4 h-4" />
            </Button>
          )}
        </div>
      </td>
    </tr>
  );
};

const CandidatesList = () => {
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  
  const [candidates, setCandidates] = useState([]);
  const [loading, setLoading] = useState(true);
  const [viewMode, setViewMode] = useState('table');
  const [filterOptions, setFilterOptions] = useState(null);
  const [showFilters, setShowFilters] = useState(false);
  
  // Pagination
  const [page, setPage] = useState(parseInt(searchParams.get('page') || '1'));
  const [limit] = useState(25);
  const [total, setTotal] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  
  // Filters
  const [search, setSearch] = useState(searchParams.get('search') || '');
  const [state, setState] = useState(searchParams.get('state') || '');
  const [gender, setGender] = useState(searchParams.get('gender') || '');
  const [verificationStatus, setVerificationStatus] = useState(searchParams.get('status') || '');
  const [sort, setSort] = useState(searchParams.get('sort') || 'createdAt:desc');
  
  // Action modal
  const [actionModal, setActionModal] = useState({ open: false, type: '', candidateId: '' });
  const [actionNote, setActionNote] = useState('');
  
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
  
  // Fetch candidates
  const fetchCandidates = useCallback(async () => {
    try {
      setLoading(true);
      const params = {
        page,
        limit,
        sort,
      };
      
      if (search) params.search = search;
      if (state) params.state = state;
      if (gender) params.gender = gender;
      if (verificationStatus) params.verificationStatus = verificationStatus;
      
      const response = await apiClient.get('/admin/candidates', { params });
      setCandidates(response.data.results || []);
      setTotal(response.data.total || 0);
      setTotalPages(response.data.totalPages || 1);
    } catch (err) {
      console.error('Failed to fetch candidates:', err);
      toast.error('Failed to load candidates');
    } finally {
      setLoading(false);
    }
  }, [page, limit, search, state, gender, verificationStatus, sort]);
  
  useEffect(() => {
    fetchCandidates();
  }, [fetchCandidates]);
  
  // Update URL params
  useEffect(() => {
    const params = new URLSearchParams();
    if (page > 1) params.set('page', page.toString());
    if (search) params.set('search', search);
    if (state) params.set('state', state);
    if (gender) params.set('gender', gender);
    if (verificationStatus) params.set('status', verificationStatus);
    if (sort !== 'createdAt:desc') params.set('sort', sort);
    setSearchParams(params);
  }, [page, search, state, gender, verificationStatus, sort, setSearchParams]);
  
  const handleView = (id) => {
    navigate(`/candidates/${id}`);
  };
  
  const handleVerify = (id) => {
    setActionModal({ open: true, type: 'verify', candidateId: id });
  };
  
  const handleFlag = (id) => {
    setActionModal({ open: true, type: 'flag', candidateId: id });
  };
  
  const executeAction = async () => {
    try {
      await apiClient.patch(`/admin/candidates/${actionModal.candidateId}/verify`, {
        action: actionModal.type === 'verify' ? 'verified' : 'flagged',
        note: actionNote,
        adminId: 'SAI_ADMIN_001'
      });
      
      toast.success(`Candidate ${actionModal.type === 'verify' ? 'verified' : 'flagged'} successfully`);
      setActionModal({ open: false, type: '', candidateId: '' });
      setActionNote('');
      fetchCandidates();
    } catch (err) {
      console.error('Action failed:', err);
    }
  };
  
  const clearFilters = () => {
    setSearch('');
    setState('');
    setGender('');
    setVerificationStatus('');
    setSort('createdAt:desc');
    setPage(1);
  };
  
  return (
    <div className="space-y-6" data-testid="candidates-list">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl lg:text-3xl font-heading font-bold tracking-tight text-[#0F172A]">
            Candidates
          </h1>
          <p className="text-[#64748B] mt-1">
            {total} registered athletes
          </p>
        </div>
        
        <div className="flex items-center gap-2">
          <Button
            variant={viewMode === 'table' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setViewMode('table')}
            data-testid="view-mode-table"
          >
            <LayoutList className="w-4 h-4" />
          </Button>
          <Button
            variant={viewMode === 'card' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setViewMode('card')}
            data-testid="view-mode-card"
          >
            <LayoutGrid className="w-4 h-4" />
          </Button>
        </div>
      </div>
      
      {/* Filters */}
      <div className="stat-card">
        <div className="flex flex-wrap items-center gap-4">
          <div className="flex-1 min-w-[200px]">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#64748B]" />
              <Input
                placeholder="Search by name, email, or ID..."
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
        </div>
        
        {showFilters && (
          <div className="mt-4 pt-4 border-t border-[#E2E8F0] grid grid-cols-1 md:grid-cols-4 gap-4 animate-in">
            <Select value={state} onValueChange={(v) => { setState(v); setPage(1); }}>
              <SelectTrigger data-testid="filter-state">
                <SelectValue placeholder="All States" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All States</SelectItem>
                {filterOptions?.states?.map((s) => (
                  <SelectItem key={s} value={s}>{s}</SelectItem>
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
            
            <Select value={verificationStatus} onValueChange={(v) => { setVerificationStatus(v); setPage(1); }}>
              <SelectTrigger data-testid="filter-status">
                <SelectValue placeholder="All Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Status</SelectItem>
                <SelectItem value="verified">Verified</SelectItem>
                <SelectItem value="flagged">Flagged</SelectItem>
                <SelectItem value="pending">Pending</SelectItem>
              </SelectContent>
            </Select>
            
            <Select value={sort} onValueChange={(v) => { setSort(v); setPage(1); }}>
              <SelectTrigger data-testid="filter-sort">
                <SelectValue placeholder="Sort by" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="createdAt:desc">Newest First</SelectItem>
                <SelectItem value="createdAt:asc">Oldest First</SelectItem>
                <SelectItem value="name:asc">Name A-Z</SelectItem>
                <SelectItem value="name:desc">Name Z-A</SelectItem>
                <SelectItem value="currentXP:desc">Highest XP</SelectItem>
                <SelectItem value="age:asc">Age (Low to High)</SelectItem>
              </SelectContent>
            </Select>
            
            <div className="md:col-span-4">
              <Button variant="ghost" size="sm" onClick={clearFilters}>
                Clear All Filters
              </Button>
            </div>
          </div>
        )}
      </div>
      
      {/* Content */}
      {loading ? (
        <div className="space-y-4" data-testid="loading-skeleton">
          {viewMode === 'table' ? (
            <div className="stat-card overflow-hidden">
              <div className="space-y-3">
                {[1, 2, 3, 4, 5].map((i) => (
                  <div key={i} className="h-12 skeleton" />
                ))}
              </div>
            </div>
          ) : (
            <div className="candidate-grid">
              {[1, 2, 3, 4, 5, 6].map((i) => (
                <div key={i} className="h-48 skeleton" />
              ))}
            </div>
          )}
        </div>
      ) : candidates.length === 0 ? (
        <div className="stat-card text-center py-12" data-testid="no-results">
          <p className="text-[#64748B]">No candidates found</p>
          <Button variant="outline" className="mt-4" onClick={clearFilters}>
            Clear Filters
          </Button>
        </div>
      ) : viewMode === 'table' ? (
        <div className="stat-card overflow-hidden p-0">
          <div className="overflow-x-auto">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Candidate</th>
                  <th>Age</th>
                  <th>Gender</th>
                  <th>Region</th>
                  <th>Latest Test</th>
                  <th>XP</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {candidates.map((candidate) => (
                  <CandidateRow
                    key={candidate.id}
                    candidate={candidate}
                    onView={handleView}
                    onVerify={handleVerify}
                    onFlag={handleFlag}
                  />
                ))}
              </tbody>
            </table>
          </div>
        </div>
      ) : (
        <div className="candidate-grid">
          {candidates.map((candidate) => (
            <CandidateCard
              key={candidate.id}
              candidate={candidate}
              onView={handleView}
              onVerify={handleVerify}
              onFlag={handleFlag}
            />
          ))}
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
              data-testid="prev-page-btn"
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
              data-testid="next-page-btn"
            >
              <ChevronRight className="w-4 h-4" />
            </Button>
          </div>
        </div>
      )}
      
      {/* Action Modal */}
      <Dialog open={actionModal.open} onOpenChange={(open) => setActionModal({ ...actionModal, open })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {actionModal.type === 'verify' ? 'Verify Candidate' : 'Flag Candidate'}
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
              data-testid="action-note-input"
            />
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setActionModal({ open: false, type: '', candidateId: '' })}>
              Cancel
            </Button>
            <Button
              className={actionModal.type === 'verify' ? 'bg-emerald-500 hover:bg-emerald-600' : 'bg-red-500 hover:bg-red-600'}
              onClick={executeAction}
              data-testid="confirm-action-btn"
            >
              {actionModal.type === 'verify' ? 'Verify' : 'Flag'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default CandidatesList;
