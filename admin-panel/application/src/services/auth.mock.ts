import type { AuthResponse, LoginCredentials, User } from '@/types';

const mockUsers = [
  {
    id: '1',
    email: 'admin@bagtrip.com',
    firstName: 'Admin',
    lastName: 'System',
    role: 'super_admin' as const,
    isActive: true,
    createdAt: '2024-01-01T00:00:00Z',
    updatedAt: '2024-01-01T00:00:00Z',
  },
  {
    id: '2',
    email: 'manager@bagtrip.com',
    firstName: 'Jean',
    lastName: 'Dupont',
    role: 'admin' as const,
    isActive: true,
    createdAt: '2024-01-01T00:00:00Z',
    updatedAt: '2024-01-01T00:00:00Z',
  },
  {
    id: '3',
    email: 'user@bagtrip.com',
    firstName: 'Marie',
    lastName: 'Martin',
    role: 'user' as const,
    isActive: true,
    createdAt: '2024-01-01T00:00:00Z',
    updatedAt: '2024-01-01T00:00:00Z',
  },
];

const delay = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

export const mockAuthService = {
  async login(credentials: LoginCredentials): Promise<AuthResponse> {
    await delay(1000); // Simulate network delay

    const user = mockUsers.find(u => u.email === credentials.email);
    
    if (!user) {
      throw new Error('Utilisateur introuvable');
    }

    // Mock password validation (accept any password for demo)
    const validPasswords = ['admin123', 'manager123', 'user123'];
    if (!validPasswords.includes(credentials.password)) {
      throw new Error('Mot de passe incorrect');
    }

    // Generate mock tokens
    const token = btoa(JSON.stringify({
      id: user.id,
      email: user.email,
      role: user.role,
      exp: Date.now() + 24 * 60 * 60 * 1000, // 24h
    }));

    const refreshToken = btoa(JSON.stringify({
      id: user.id,
      exp: Date.now() + 30 * 24 * 60 * 60 * 1000, // 30 days
    }));

    return {
      user,
      token,
      refreshToken,
    };
  },

  async logout(): Promise<void> {
    await delay(500);
    // Mock logout - just resolve
  },

  async getCurrentUser(): Promise<User> {
    await delay(800);
    
    // Try to get user from stored token
    if (typeof window !== 'undefined') {
      const token = document.cookie
        .split('; ')
        .find(row => row.startsWith('auth-token='))
        ?.split('=')[1];

      if (token) {
        try {
          const decoded = JSON.parse(atob(token));
          const user = mockUsers.find(u => u.id === decoded.id);
          
          if (user && decoded.exp > Date.now()) {
            return user;
          }
        } catch {
          console.error('Invalid token');
        }
      }
    }

    throw new Error('Token invalide ou expiré');
  },

  async refreshToken(refreshToken: string): Promise<{ token: string }> {
    await delay(600);

    try {
      const decoded = JSON.parse(atob(refreshToken));
      
      if (decoded.exp <= Date.now()) {
        throw new Error('Refresh token expiré');
      }

      const user = mockUsers.find(u => u.id === decoded.id);
      if (!user) {
        throw new Error('Utilisateur introuvable');
      }

      const newToken = btoa(JSON.stringify({
        id: user.id,
        email: user.email,
        role: user.role,
        exp: Date.now() + 24 * 60 * 60 * 1000, // 24h
      }));

      return { token: newToken };
    } catch {
      throw new Error('Impossible de rafraîchir le token');
    }
  },
};