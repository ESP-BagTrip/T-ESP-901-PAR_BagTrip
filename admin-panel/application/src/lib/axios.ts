import axios from 'axios';
import { getCookie, deleteCookie } from 'cookies-next';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api';

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

apiClient.interceptors.request.use(
  (config) => {
    const token = getCookie('auth-token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;
    
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      
      try {
        const refreshToken = getCookie('refresh-token');
        if (refreshToken) {
          const response = await axios.post(`${API_BASE_URL}/admin/auth/refresh`, {
            refreshToken,
          });
          
          const { token } = response.data;
          document.cookie = `auth-token=${token}; path=/; httpOnly=false; secure=${process.env.NODE_ENV === 'production'}; samesite=lax`;
          
          return apiClient(originalRequest);
        }
      } catch {
        deleteCookie('auth-token');
        deleteCookie('refresh-token');
        window.location.href = '/login';
      }
    }
    
    return Promise.reject(error);
  }
);