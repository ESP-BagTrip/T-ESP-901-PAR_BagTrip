import axios from 'axios'
import { getCookie, deleteCookie } from 'cookies-next'

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000'

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

apiClient.interceptors.request.use(
  config => {
    const token = getCookie('auth-token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  error => Promise.reject(error)
)

apiClient.interceptors.response.use(
  response => response,
  async error => {
    // On 401, just redirect to login (no refresh token support)
    if (error.response?.status === 401) {
      deleteCookie('auth-token')
      if (typeof window !== 'undefined') {
        window.location.href = '/login'
      }
    }

    return Promise.reject(error)
  }
)
