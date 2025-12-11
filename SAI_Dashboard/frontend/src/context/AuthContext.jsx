import { createContext, useContext, useState, useEffect } from 'react';

// Simple hardcoded credentials
const VALID_USERNAME = 'admin';
const VALID_PASSWORD = 'pass';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
    const [isAuthenticated, setIsAuthenticated] = useState(false);
    const [isLoading, setIsLoading] = useState(true);

    // Check if user is already logged in on mount
    useEffect(() => {
        const token = localStorage.getItem('sai_auth_token');
        if (token === 'authenticated') {
            setIsAuthenticated(true);
        }
        setIsLoading(false);
    }, []);

    const login = (username, password) => {
        if (username === VALID_USERNAME && password === VALID_PASSWORD) {
            localStorage.setItem('sai_auth_token', 'authenticated');
            setIsAuthenticated(true);
            return true;
        }
        return false;
    };

    const logout = () => {
        localStorage.removeItem('sai_auth_token');
        setIsAuthenticated(false);
    };

    return (
        <AuthContext.Provider value={{ isAuthenticated, isLoading, login, logout }}>
            {children}
        </AuthContext.Provider>
    );
};

export const useAuth = () => {
    const context = useContext(AuthContext);
    if (!context) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
};

export default AuthContext;
