import { useState, useEffect, useCallback } from 'react';
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
  ChevronLeft,
  ChevronRight,
  FileText,
  Search,
  Filter,
  CheckCircle2,
  Flag,
  Download,
  Eye,
  RefreshCw
} from 'lucide-react';

const ActionIcon = ({ action }) => {
  if (action?.includes('verify') || action?.includes('verified')) {
    return <CheckCircle2 className="w-4 h-4 text-emerald-500" />;
  }
  if (action?.includes('flag')) {
    return <Flag className="w-4 h-4 text-red-500" />;
  }
  if (action?.includes('export')) {
    return <Download className="w-4 h-4 text-[#FF9933]" />;
  }
  if (action?.includes('view')) {
    return <Eye className="w-4 h-4 text-[#64748B]" />;
  }
  return <RefreshCw className="w-4 h-4 text-[#64748B]" />;
};

const AuditLogRow = ({ log }) => (
  <tr className="hover:bg-[#F8FAFC]/50 transition-colors" data-testid={`audit-row-${log.id}`}>
    <td className="px-4 py-3">
      <div className="flex items-center gap-3">
        <div className="w-8 h-8 bg-[#F1F5F9] rounded-full flex items-center justify-center">
          <ActionIcon action={log.action} />
        </div>
        <div>
          <p className="font-medium text-[#0F172A] capitalize">{log.action?.replace(/_/g, ' ')}</p>
          <p className="text-xs text-[#64748B]">{log.targetType}</p>
        </div>
      </div>
    </td>
    <td className="px-4 py-3 font-mono text-sm text-[#64748B]">
      {log.targetId?.slice(-12) || 'N/A'}
    </td>
    <td className="px-4 py-3 text-sm">{log.adminId}</td>
    <td className="px-4 py-3 text-sm text-[#64748B] max-w-[200px] truncate">
      {log.note || '-'}
    </td>
    <td className="px-4 py-3 text-sm text-[#64748B]">
      {new Date(log.timestamp).toLocaleString()}
    </td>
    <td className="px-4 py-3">
      {log.before && (
        <span className="px-2 py-0.5 text-xs bg-red-50 text-red-600 rounded">
          From: {JSON.stringify(log.before).slice(0, 30)}...
        </span>
      )}
    </td>
    <td className="px-4 py-3">
      {log.after && (
        <span className="px-2 py-0.5 text-xs bg-emerald-50 text-emerald-600 rounded">
          To: {JSON.stringify(log.after).slice(0, 30)}...
        </span>
      )}
    </td>
  </tr>
);

const AuditLogs = () => {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showFilters, setShowFilters] = useState(false);
  
  // Pagination
  const [page, setPage] = useState(1);
  const [limit] = useState(25);
  const [total, setTotal] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  
  // Filters
  const [targetId, setTargetId] = useState('');
  const [adminId, setAdminId] = useState('');
  const [action, setAction] = useState('');
  
  const fetchLogs = useCallback(async () => {
    try {
      setLoading(true);
      const params = { page, limit };
      
      if (targetId) params.targetId = targetId;
      if (adminId) params.adminId = adminId;
      if (action) params.action = action;
      
      const response = await apiClient.get('/admin/audit', { params });
      setLogs(response.data.results || []);
      setTotal(response.data.total || 0);
      setTotalPages(response.data.totalPages || 1);
    } catch (err) {
      console.error('Failed to fetch audit logs:', err);
      toast.error('Failed to load audit logs');
    } finally {
      setLoading(false);
    }
  }, [page, limit, targetId, adminId, action]);
  
  useEffect(() => {
    fetchLogs();
  }, [fetchLogs]);
  
  const clearFilters = () => {
    setTargetId('');
    setAdminId('');
    setAction('');
    setPage(1);
  };
  
  return (
    <div className="space-y-6" data-testid="audit-logs">
      {/* Header */}
      <div>
        <h1 className="text-2xl lg:text-3xl font-heading font-bold tracking-tight text-[#0F172A]">
          Audit Logs
        </h1>
        <p className="text-[#64748B] mt-1">
          {total} admin actions recorded
        </p>
      </div>
      
      {/* Filters */}
      <div className="stat-card">
        <div className="flex flex-wrap items-center gap-4">
          <Button
            variant="outline"
            onClick={() => setShowFilters(!showFilters)}
            data-testid="toggle-filters-btn"
          >
            <Filter className="w-4 h-4 mr-2" />
            Filters
          </Button>
          
          <Button
            variant="ghost"
            onClick={fetchLogs}
            data-testid="refresh-btn"
          >
            <RefreshCw className="w-4 h-4 mr-2" />
            Refresh
          </Button>
        </div>
        
        {showFilters && (
          <div className="mt-4 pt-4 border-t border-[#E2E8F0] grid grid-cols-1 md:grid-cols-4 gap-4 animate-in">
            <div>
              <label className="text-sm font-medium text-[#64748B] block mb-2">Target ID</label>
              <Input
                placeholder="Search by target ID..."
                value={targetId}
                onChange={(e) => { setTargetId(e.target.value); setPage(1); }}
                data-testid="filter-target-id"
              />
            </div>
            
            <div>
              <label className="text-sm font-medium text-[#64748B] block mb-2">Admin ID</label>
              <Input
                placeholder="Filter by admin..."
                value={adminId}
                onChange={(e) => { setAdminId(e.target.value); setPage(1); }}
                data-testid="filter-admin-id"
              />
            </div>
            
            <div>
              <label className="text-sm font-medium text-[#64748B] block mb-2">Action Type</label>
              <Select value={action} onValueChange={(v) => { setAction(v); setPage(1); }}>
                <SelectTrigger data-testid="filter-action">
                  <SelectValue placeholder="All Actions" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Actions</SelectItem>
                  <SelectItem value="verify">Verification</SelectItem>
                  <SelectItem value="flag">Flag</SelectItem>
                  <SelectItem value="export">Export</SelectItem>
                </SelectContent>
              </Select>
            </div>
            
            <div className="flex items-end">
              <Button variant="ghost" onClick={clearFilters}>
                Clear Filters
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
      ) : logs.length === 0 ? (
        <div className="stat-card text-center py-12" data-testid="no-results">
          <FileText className="w-12 h-12 text-[#CBD5E1] mx-auto mb-4" />
          <p className="text-[#64748B]">No audit logs found</p>
          <p className="text-sm text-[#94A3B8] mt-1">
            Admin actions will appear here when verification or export actions are performed.
          </p>
        </div>
      ) : (
        <div className="stat-card overflow-hidden p-0">
          <div className="overflow-x-auto">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Action</th>
                  <th>Target ID</th>
                  <th>Admin</th>
                  <th>Note</th>
                  <th>Timestamp</th>
                  <th>Before</th>
                  <th>After</th>
                </tr>
              </thead>
              <tbody>
                {logs.map((log) => (
                  <AuditLogRow key={log.id} log={log} />
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

export default AuditLogs;
