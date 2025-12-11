import { useState, useEffect, useCallback } from "react";
import "@/App.css";
import { BrowserRouter, Routes, Route, NavLink, useNavigate, useParams } from "react-router-dom";
import axios from "axios";
import { Toaster } from "@/components/ui/sonner";
import { toast } from "sonner";

// Components
import Dashboard from "@/pages/Dashboard";
import CandidatesList from "@/pages/CandidatesList";
import CandidateProfile from "@/pages/CandidateProfile";
import TestResults from "@/pages/TestResults";
import QueryBuilder from "@/pages/QueryBuilder";
import ExportPage from "@/pages/ExportPage";
import AuditLogs from "@/pages/AuditLogs";
import Login from "@/pages/Login";
import { AuthProvider, useAuth } from "@/context/AuthContext";

import {
  LayoutDashboard,
  Users,
  ClipboardList,
  Search,
  Download,
  FileText,
  Menu,
  X,
  WifiOff,
  LogOut
} from "lucide-react";

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL || 'http://localhost:8000';
export const API = `${BACKEND_URL}/api`;

// API client with error handling
export const apiClient = axios.create({
  baseURL: API,
  timeout: 30000,
});

apiClient.interceptors.response.use(
  response => response,
  error => {
    const message = error.response?.data?.detail || error.message || "An error occurred";
    toast.error(message);
    return Promise.reject(error);
  }
);

// Sidebar Navigation
const navItems = [
  { path: "/", icon: LayoutDashboard, label: "Dashboard" },
  { path: "/candidates", icon: Users, label: "Candidates" },
  { path: "/test-results", icon: ClipboardList, label: "Test Results" },
  { path: "/query-builder", icon: Search, label: "Query Builder" },
  { path: "/export", icon: Download, label: "Export" },
  { path: "/audit-logs", icon: FileText, label: "Audit Logs" },
];

const Sidebar = ({ isOpen, onClose }) => {
  return (
    <>
      {/* Overlay for mobile */}
      {isOpen && (
        <div
          className="lg:hidden fixed inset-0 bg-black/20 z-40"
          onClick={(e) => { e.stopPropagation(); onClose(); }}
          data-testid="sidebar-overlay"
          role="button"
          tabIndex={-1}
          onKeyDown={(e) => e.key === 'Escape' && onClose()}
        />
      )}

      <aside
        className={`sidebar ${isOpen ? 'sidebar-open' : ''} z-50`}
        data-testid="sidebar"
      >
        <div className="p-6 border-b border-border">
          <div className="flex items-center gap-3">
            <img
              src="/logo.jpg"
              alt="SAI Logo"
              className="w-10 h-10 rounded-md object-contain"
            />
            <div>
              <h1 className="font-heading font-bold text-lg tracking-tight text-[#0F172A]" data-testid="app-title">
                SAI Admin
              </h1>
              <p className="text-xs text-[#64748B]">Sports Authority</p>
            </div>
          </div>
        </div>

        <nav className="flex-1 p-4" data-testid="sidebar-nav">
          <ul className="space-y-1">
            {navItems.map((item) => (
              <li key={item.path}>
                <NavLink
                  to={item.path}
                  onClick={onClose}
                  className={({ isActive }) =>
                    `flex items-center gap-3 px-3 py-2.5 rounded-sm text-sm font-medium transition-colors duration-200 ${isActive
                      ? 'bg-[#1E3A8A] text-white'
                      : 'text-[#64748B] hover:bg-[#EFF6FF] hover:text-[#1E3A8A]'
                    }`
                  }
                  data-testid={`nav-${item.label.toLowerCase().replace(' ', '-')}`}
                >
                  <item.icon className="w-4 h-4" />
                  {item.label}
                </NavLink>
              </li>
            ))}
          </ul>
        </nav>

        <div className="p-4 border-t border-border">
          <div className="px-3 py-2 text-xs text-[#64748B]">
            <p>Version 1.0.0</p>
            <p>Hackathon Demo</p>
          </div>
        </div>
      </aside>
    </>
  );
};

const Layout = ({ children }) => {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [isOffline, setIsOffline] = useState(false);

  useEffect(() => {
    const handleOnline = () => setIsOffline(false);
    const handleOffline = () => setIsOffline(true);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  return (
    <div className="app-layout">
      <Sidebar isOpen={sidebarOpen} onClose={() => setSidebarOpen(false)} />

      <main className={`main-content ${sidebarOpen ? '' : ''}`}>
        {/* Top bar */}
        <header className="bg-white border-b border-border px-6 py-4 sticky top-0 z-30">
          <div className="flex items-center justify-between">
            <button
              className="lg:hidden p-2 hover:bg-[#F8FAFC] rounded-sm"
              onClick={() => setSidebarOpen(!sidebarOpen)}
              data-testid="mobile-menu-btn"
            >
              {sidebarOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </button>

            <div className="hidden lg:block" />

            <div className="flex items-center gap-4">
              <span className="text-sm text-[#64748B]" data-testid="admin-label">
                Admin
              </span>
              <LogoutButton />
            </div>
          </div>
        </header>

        {/* Offline banner */}
        {isOffline && (
          <div className="offline-banner" data-testid="offline-banner">
            <WifiOff className="w-4 h-4" />
            <span>You are offline. Showing cached data.</span>
          </div>
        )}

        {/* Page content */}
        <div className="p-6 lg:p-8">
          {children}
        </div>
      </main>
    </div>
  );
};

// Logout button component
const LogoutButton = () => {
  const { logout } = useAuth();
  return (
    <button
      onClick={logout}
      className="flex items-center gap-1 px-3 py-1.5 text-sm text-[#64748B] hover:text-red-600 hover:bg-red-50 rounded-md transition-colors"
      data-testid="logout-btn"
    >
      <LogOut className="w-4 h-4" />
      Logout
    </button>
  );
};

// Main App with Auth
const AppContent = () => {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#F8FAFC]">
        <div className="text-center">
          <img src="/logo.jpg" alt="SAI" className="w-16 h-16 mx-auto mb-4 rounded-lg" />
          <p className="text-[#64748B]">Loading...</p>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Login />;
  }

  return (
    <Layout>
      <Routes>
        <Route path="/" element={<Dashboard />} />
        <Route path="/candidates" element={<CandidatesList />} />
        <Route path="/candidates/:id" element={<CandidateProfile />} />
        <Route path="/test-results" element={<TestResults />} />
        <Route path="/query-builder" element={<QueryBuilder />} />
        <Route path="/export" element={<ExportPage />} />
        <Route path="/audit-logs" element={<AuditLogs />} />
      </Routes>
    </Layout>
  );
};

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Toaster position="top-right" richColors />
        <AppContent />
      </AuthProvider>
    </BrowserRouter>
  );
}

export default App;
