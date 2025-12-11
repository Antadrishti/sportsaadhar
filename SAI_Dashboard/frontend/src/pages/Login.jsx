import { useState } from 'react';
import { useAuth } from '@/context/AuthContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Lock, User, AlertCircle } from 'lucide-react';

const Login = () => {
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const { login } = useAuth();

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setLoading(true);

        // Simulate a small delay for UX
        await new Promise(resolve => setTimeout(resolve, 500));

        const success = login(username, password);
        if (!success) {
            setError('Invalid username or password');
        }
        setLoading(false);
    };

    return (
        <div className="min-h-screen bg-gradient-to-br from-[#F8FAFC] via-[#E0F2FE] to-[#F0FDF4] flex items-center justify-center p-4">
            <div className="w-full max-w-md">
                {/* Logo and Title */}
                <div className="text-center mb-8">
                    <div className="mb-4 flex justify-center">
                        <img
                            src="/logo.jpg"
                            alt="SAI Logo"
                            className="w-24 h-24 object-contain rounded-xl shadow-lg"
                        />
                    </div>
                    <h1 className="text-3xl font-heading font-bold text-[#0F172A] tracking-tight">
                        SAI Admin Dashboard
                    </h1>
                    <p className="text-[#64748B] mt-2">Sports Authority of India</p>
                </div>

                {/* Login Form */}
                <div className="bg-white rounded-xl shadow-xl border border-[#E2E8F0] p-8">
                    <h2 className="text-xl font-heading font-semibold text-[#0F172A] mb-6 text-center">
                        Sign In
                    </h2>

                    <form onSubmit={handleSubmit} className="space-y-5">
                        {error && (
                            <div className="flex items-center gap-2 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
                                <AlertCircle className="w-4 h-4" />
                                {error}
                            </div>
                        )}

                        <div>
                            <label className="block text-sm font-medium text-[#0F172A] mb-2">
                                Username
                            </label>
                            <div className="relative">
                                <User className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-[#64748B]" />
                                <Input
                                    type="text"
                                    value={username}
                                    onChange={(e) => setUsername(e.target.value)}
                                    placeholder="Enter username"
                                    className="pl-10"
                                    required
                                    data-testid="username-input"
                                />
                            </div>
                        </div>

                        <div>
                            <label className="block text-sm font-medium text-[#0F172A] mb-2">
                                Password
                            </label>
                            <div className="relative">
                                <Lock className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-[#64748B]" />
                                <Input
                                    type="password"
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    placeholder="Enter password"
                                    className="pl-10"
                                    required
                                    data-testid="password-input"
                                />
                            </div>
                        </div>

                        <Button
                            type="submit"
                            className="w-full bg-gradient-to-r from-[#1E3A8A] to-[#1D4ED8] hover:from-[#1E3A8A]/90 hover:to-[#1D4ED8]/90 text-white font-medium py-2.5"
                            disabled={loading}
                            data-testid="login-btn"
                        >
                            {loading ? 'Signing in...' : 'Sign In'}
                        </Button>
                    </form>

                    <p className="mt-6 text-center text-xs text-[#94A3B8]">
                        Admin access only. Unauthorized access is prohibited.
                    </p>
                </div>

                <p className="mt-6 text-center text-sm text-[#64748B]">
                    © 2025 Sports Authority of India
                </p>
            </div>
        </div>
    );
};

export default Login;
