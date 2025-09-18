import { apiClient } from '@/lib/axios';
import { API_ENDPOINTS } from '@/utils/constants';
import { mockAuthService } from './auth.mock';
import type { AuthResponse, LoginCredentials, User, ApiResponse } from '@/types';

// Use mock service in development when no backend is available
const USE_MOCK = process.env.NODE_ENV === 'development';

const realAuthService = {
  async login(credentials: LoginCredentials): Promise<AuthResponse> {
    const response = await apiClient.post<ApiResponse<AuthResponse>>(
      API_ENDPOINTS.AUTH.LOGIN,
      credentials
    );
    return response.data.data;
  },

  async logout(): Promise<void> {
    await apiClient.post(API_ENDPOINTS.AUTH.LOGOUT);
  },

  async getCurrentUser(): Promise<User> {
    const response = await apiClient.get<ApiResponse<User>>(API_ENDPOINTS.AUTH.ME);
    return response.data.data;
  },

  async refreshToken(refreshToken: string): Promise<{ token: string }> {
    const response = await apiClient.post<ApiResponse<{ token: string }>>(
      API_ENDPOINTS.AUTH.REFRESH,
      { refreshToken }
    );
    return response.data.data;
  },
};

export const authService = USE_MOCK ? mockAuthService : realAuthService;