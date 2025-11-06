export const USER_ROLES = {
  SUPER_ADMIN: 'super_admin',
  ADMIN: 'admin',
  USER: 'user',
} as const

export const FEEDBACK_CATEGORIES = {
  GENERAL: 'general',
  BUG: 'bug',
} as const

export const FEEDBACK_STATUS = {
  PENDING: 'pending',
  RESOLVED: 'resolved',
} as const

export const API_ENDPOINTS = {
  AUTH: {
    LOGIN: '/admin/auth/login',
    ME: '/admin/auth/me',
    LOGOUT: '/admin/auth/logout',
    REFRESH: '/admin/auth/refresh',
  },
  DASHBOARD: {
    METRICS: '/admin/dashboard/metrics',
    ACTIVITY: '/admin/dashboard/activity',
  },
  USERS: '/admin/users',
  FEEDBACKS: '/admin/feedbacks',
} as const

export const PAGINATION_DEFAULTS = {
  PAGE: 1,
  LIMIT: 10,
} as const

export const DATE_FORMATS = {
  DISPLAY: 'dd/MM/yyyy',
  DISPLAY_WITH_TIME: 'dd/MM/yyyy HH:mm',
  API: 'yyyy-MM-dd',
} as const
