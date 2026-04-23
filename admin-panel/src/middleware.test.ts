import { describe, it, expect } from 'vitest'
import { NextRequest } from 'next/server'
import { middleware } from './middleware'

function createRequest(url: string, cookies: Record<string, string> = {}) {
  const req = new NextRequest(new URL(url, 'http://localhost:3000'))
  for (const [key, value] of Object.entries(cookies)) {
    req.cookies.set(key, value)
  }
  return req
}

describe('middleware', () => {
  describe('legacy /dashboard redirect', () => {
    it('redirects /dashboard to /app with 308', () => {
      const res = middleware(createRequest('/dashboard'))
      expect(res.status).toBe(308)
      expect(new URL(res.headers.get('location')!).pathname).toBe('/app')
    })

    it('redirects /dashboard/settings to /app/settings with 308', () => {
      const res = middleware(createRequest('/dashboard/settings'))
      expect(res.status).toBe(308)
      expect(new URL(res.headers.get('location')!).pathname).toBe('/app/settings')
    })

    it('redirects /dashboard/users/123 to /app/users/123', () => {
      const res = middleware(createRequest('/dashboard/users/123'))
      expect(res.status).toBe(308)
      expect(new URL(res.headers.get('location')!).pathname).toBe('/app/users/123')
    })

    it('redirects /dashboard even with access_token', () => {
      const res = middleware(createRequest('/dashboard', { access_token: 'tok123' }))
      expect(res.status).toBe(308)
      expect(new URL(res.headers.get('location')!).pathname).toBe('/app')
    })

    it('redirects nested /dashboard/ path', () => {
      const res = middleware(createRequest('/dashboard/a/b/c'))
      expect(res.status).toBe(308)
      expect(new URL(res.headers.get('location')!).pathname).toBe('/app/a/b/c')
    })
  })

  describe('public routes', () => {
    it('allows GET / without cookie', () => {
      const res = middleware(createRequest('/'))
      expect(res.status).toBe(200)
      expect(res.headers.get('location')).toBeNull()
    })

    it('allows GET /login without cookie', () => {
      const res = middleware(createRequest('/login'))
      expect(res.status).toBe(200)
      expect(res.headers.get('location')).toBeNull()
    })

    it('redirects /login to /app when access_token is present', () => {
      const res = middleware(createRequest('/login', { access_token: 'tok123' }))
      expect(res.status).toBe(307)
      expect(new URL(res.headers.get('location')!).pathname).toBe('/app')
    })

    it('allows / even when access_token is present (no redirect)', () => {
      const res = middleware(createRequest('/', { access_token: 'tok123' }))
      expect(res.status).toBe(200)
      expect(res.headers.get('location')).toBeNull()
    })
  })

  describe('protected routes', () => {
    it('redirects /app to /login without access_token', () => {
      const res = middleware(createRequest('/app'))
      expect(res.status).toBe(307)
      expect(new URL(res.headers.get('location')!).pathname).toBe('/login')
    })

    it('redirects /app/users to /login without access_token', () => {
      const res = middleware(createRequest('/app/users'))
      expect(res.status).toBe(307)
      expect(new URL(res.headers.get('location')!).pathname).toBe('/login')
    })

    it('redirects /app/settings to /login without access_token', () => {
      const res = middleware(createRequest('/app/settings'))
      expect(res.status).toBe(307)
      expect(new URL(res.headers.get('location')!).pathname).toBe('/login')
    })

    it('allows /app with access_token', () => {
      const res = middleware(createRequest('/app', { access_token: 'tok123' }))
      expect(res.status).toBe(200)
      expect(res.headers.get('location')).toBeNull()
    })

    it('allows /app/users with access_token', () => {
      const res = middleware(createRequest('/app/users', { access_token: 'tok123' }))
      expect(res.status).toBe(200)
      expect(res.headers.get('location')).toBeNull()
    })

    it('allows deeply nested /app route with access_token', () => {
      const res = middleware(createRequest('/app/trips/123/details', { access_token: 'tok123' }))
      expect(res.status).toBe(200)
      expect(res.headers.get('location')).toBeNull()
    })
  })

  describe('other routes (not public, not protected prefix)', () => {
    it('passes through unknown routes without token', () => {
      const res = middleware(createRequest('/some-page'))
      expect(res.status).toBe(200)
      expect(res.headers.get('location')).toBeNull()
    })

    it('passes through unknown routes with token', () => {
      const res = middleware(createRequest('/about', { access_token: 'tok123' }))
      expect(res.status).toBe(200)
      expect(res.headers.get('location')).toBeNull()
    })

    it('treats /application as protected since it starts with /app', () => {
      // /application starts with '/app' so the middleware treats it as protected
      const res = middleware(createRequest('/application'))
      expect(res.status).toBe(307)
      expect(res.headers.get('location')).toContain('/login')
    })
  })
})
