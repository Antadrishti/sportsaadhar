import { useState, useEffect } from 'react';
import { apiClient, API } from '@/App';
import { toast } from 'sonner';
import { Button } from '@/components/ui/button';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Checkbox } from '@/components/ui/checkbox';
import {
  Download,
  FileJson,
  FileSpreadsheet,
  Loader2
} from 'lucide-react';

const ExportPage = () => {
  const [exportType, setExportType] = useState('candidates');
  const [format, setFormat] = useState('json');
  const [filterOptions, setFilterOptions] = useState(null);
  const [loading, setLoading] = useState(false);
  
  // Filters
  const [state, setState] = useState('');
  const [gender, setGender] = useState('');
  const [verificationStatus, setVerificationStatus] = useState('');
  const [testType, setTestType] = useState('');
  const [limit, setLimit] = useState('1000');
  
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
  
  const handleExport = async () => {
    try {
      setLoading(true);
      
      const params = new URLSearchParams();
      params.append('format', format);
      params.append('type', exportType);
      params.append('limit', limit);
      
      if (state && state !== 'all') params.append('state', state);
      if (gender && gender !== 'all') params.append('gender', gender);
      if (verificationStatus && verificationStatus !== 'all') params.append('verificationStatus', verificationStatus);
      if (testType && testType !== 'all') params.append('testType', testType);
      
      if (format === 'csv') {
        // Download CSV file
        const response = await fetch(`${API}/admin/export?${params.toString()}`);
        const blob = await response.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `sai_export_${exportType}_${new Date().toISOString().split('T')[0]}.csv`;
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(url);
        a.remove();
        toast.success('CSV file downloaded');
      } else {
        // Preview JSON
        const response = await apiClient.get(`/admin/export?${params.toString()}`);
        const dataStr = JSON.stringify(response.data, null, 2);
        const blob = new Blob([dataStr], { type: 'application/json' });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `sai_export_${exportType}_${new Date().toISOString().split('T')[0]}.json`;
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(url);
        a.remove();
        toast.success(`Exported ${response.data.count} records`);
      }
    } catch (err) {
      console.error('Export failed:', err);
      toast.error('Export failed');
    } finally {
      setLoading(false);
    }
  };
  
  return (
    <div className="space-y-6" data-testid="export-page">
      {/* Header */}
      <div>
        <h1 className="text-2xl lg:text-3xl font-heading font-bold tracking-tight text-[#0F172A]">
          Export Data
        </h1>
        <p className="text-[#64748B] mt-1">
          Export candidates or test results as CSV or JSON
        </p>
      </div>
      
      {/* Export Configuration */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Left - Options */}
        <div className="stat-card space-y-6">
          <h2 className="font-heading font-bold text-lg text-[#0F172A]">
            Export Options
          </h2>
          
          {/* Data Type */}
          <div>
            <label className="text-sm font-medium text-[#64748B] block mb-2">Data Type</label>
            <div className="grid grid-cols-2 gap-4">
              <button
                className={`p-4 rounded-sm border-2 text-left transition-colors ${
                  exportType === 'candidates' 
                    ? 'border-[#0F172A] bg-[#F8FAFC]' 
                    : 'border-[#E2E8F0] hover:border-[#CBD5E1]'
                }`}
                onClick={() => setExportType('candidates')}
                data-testid="export-type-candidates"
              >
                <p className="font-medium text-[#0F172A]">Candidates</p>
                <p className="text-sm text-[#64748B]">User profiles & progress</p>
              </button>
              <button
                className={`p-4 rounded-sm border-2 text-left transition-colors ${
                  exportType === 'test-results' 
                    ? 'border-[#0F172A] bg-[#F8FAFC]' 
                    : 'border-[#E2E8F0] hover:border-[#CBD5E1]'
                }`}
                onClick={() => setExportType('test-results')}
                data-testid="export-type-tests"
              >
                <p className="font-medium text-[#0F172A]">Test Results</p>
                <p className="text-sm text-[#64748B]">Assessment records</p>
              </button>
            </div>
          </div>
          
          {/* Format */}
          <div>
            <label className="text-sm font-medium text-[#64748B] block mb-2">Format</label>
            <div className="grid grid-cols-2 gap-4">
              <button
                className={`p-4 rounded-sm border-2 text-left transition-colors flex items-center gap-3 ${
                  format === 'json' 
                    ? 'border-[#0F172A] bg-[#F8FAFC]' 
                    : 'border-[#E2E8F0] hover:border-[#CBD5E1]'
                }`}
                onClick={() => setFormat('json')}
                data-testid="format-json"
              >
                <FileJson className="w-8 h-8 text-[#FF9933]" />
                <div>
                  <p className="font-medium text-[#0F172A]">JSON</p>
                  <p className="text-xs text-[#64748B]">Structured data</p>
                </div>
              </button>
              <button
                className={`p-4 rounded-sm border-2 text-left transition-colors flex items-center gap-3 ${
                  format === 'csv' 
                    ? 'border-[#0F172A] bg-[#F8FAFC]' 
                    : 'border-[#E2E8F0] hover:border-[#CBD5E1]'
                }`}
                onClick={() => setFormat('csv')}
                data-testid="format-csv"
              >
                <FileSpreadsheet className="w-8 h-8 text-emerald-500" />
                <div>
                  <p className="font-medium text-[#0F172A]">CSV</p>
                  <p className="text-xs text-[#64748B]">Spreadsheet format</p>
                </div>
              </button>
            </div>
          </div>
          
          {/* Limit */}
          <div>
            <label className="text-sm font-medium text-[#64748B] block mb-2">Max Records</label>
            <Select value={limit} onValueChange={setLimit}>
              <SelectTrigger data-testid="limit-select">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="100">100 records</SelectItem>
                <SelectItem value="500">500 records</SelectItem>
                <SelectItem value="1000">1,000 records</SelectItem>
                <SelectItem value="5000">5,000 records</SelectItem>
                <SelectItem value="10000">10,000 records</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>
        
        {/* Right - Filters */}
        <div className="stat-card space-y-6">
          <h2 className="font-heading font-bold text-lg text-[#0F172A]">
            Filters (Optional)
          </h2>
          
          {exportType === 'candidates' ? (
            <>
              <div>
                <label className="text-sm font-medium text-[#64748B] block mb-2">State</label>
                <Select value={state} onValueChange={setState}>
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
              </div>
              
              <div>
                <label className="text-sm font-medium text-[#64748B] block mb-2">Gender</label>
                <Select value={gender} onValueChange={setGender}>
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
              </div>
              
              <div>
                <label className="text-sm font-medium text-[#64748B] block mb-2">Verification Status</label>
                <Select value={verificationStatus} onValueChange={setVerificationStatus}>
                  <SelectTrigger data-testid="filter-verification">
                    <SelectValue placeholder="All Status" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Status</SelectItem>
                    <SelectItem value="verified">Verified</SelectItem>
                    <SelectItem value="flagged">Flagged</SelectItem>
                    <SelectItem value="pending">Pending</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </>
          ) : (
            <>
              <div>
                <label className="text-sm font-medium text-[#64748B] block mb-2">Test Type</label>
                <Select value={testType} onValueChange={setTestType}>
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
              </div>
              
              <div>
                <label className="text-sm font-medium text-[#64748B] block mb-2">Gender</label>
                <Select value={gender} onValueChange={setGender}>
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
              </div>
            </>
          )}
        </div>
      </div>
      
      {/* Export Button */}
      <div className="stat-card">
        <div className="flex items-center justify-between">
          <div>
            <p className="font-medium text-[#0F172A]">Ready to export</p>
            <p className="text-sm text-[#64748B]">
              {exportType === 'candidates' ? 'Candidate profiles' : 'Test results'} as {format.toUpperCase()}
            </p>
          </div>
          <Button
            size="lg"
            className="bg-[#1E3A8A] hover:bg-[#1E3A8A]/90"
            onClick={handleExport}
            disabled={loading}
            data-testid="export-btn"
          >
            {loading ? (
              <><Loader2 className="w-4 h-4 mr-2 animate-spin" /> Exporting...</>
            ) : (
              <><Download className="w-4 h-4 mr-2" /> Export Data</>
            )}
          </Button>
        </div>
      </div>
    </div>
  );
};

export default ExportPage;
