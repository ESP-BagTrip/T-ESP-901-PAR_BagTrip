import { describe, it, expect, vi, beforeEach } from 'vitest'
import type { NextRequest } from 'next/server'

vi.mock('next/server', () => {
  const NextResponse = {
    next: vi.fn(() => ({ type: 'next' })),
    redirect: vi.fn((url: URL) => ({ type: 'redirect', url: url.toString() })),
  }
  return { NextRequest: vi.fn(), NextResponse }
})

function createMockRequest(pathname: string, hasToken = false) {
  return {
    nextUrl: { pathname },
    url: 'http://localhost:3000',
    cookies: {
      get: vi.fn((name: string) =>
        hasToken && name === 'access_token' ? { value: 'test-token' } : undefined
      ),
    },
  } as unknown as NextRequest
}

describe('middleware', () => {
  let middleware: (request: NextRequest) => unknown
  let NextResponse: { next: ReturnType<typeof vi.fn>; redirect: ReturnType<typeof vi.fn> }

  beforeEach(async () => {
    vi.clearAllMocks()
    const mod = await import('@/middleware')
    middleware = mod.middleware
    const serverMod = await import('next/server')
    NextResponse = serverMod.NextResponse as unknown as typeof NextResponse
  })

  it('should allow public route / without token', () => {
    const request = createMockRequest('/')
    middleware(request)
    expect(NextResponse.next).toHaveBeenCalled()
  })

  it('should allow public route /login without token', () => {
    const request = createMockRequest('/login')
    middleware(request)
    expect(NextResponse.next).toHaveBeenCalled()
  })

  it('should redirect protected route /dashboard to /login without token', () => {
    const request = createMockRequest('/dashboard')
    middleware(request)
    expect(NextResponse.redirect).toHaveBeenCalled()
    const redirectUrl = NextResponse.redirect.mock.calls[0][0]
    expect(redirectUrl.toString()).toContain('/login')
  })

  it('should allow protected route /dashboard with token', () => {
    const request = createMockRequest('/dashboard', true)
    middleware(request)
    expect(NextResponse.next).toHaveBeenCalled()
  })

  it('should allow /login with token (public route takes precedence)', () => {
    const request = createMockRequest('/login', true)
    middleware(request)
    expect(NextResponse.next).toHaveBeenCalled()
    expect(NextResponse.redirect).not.toHaveBeenCalled()
  })

  it('should redirect /users without token', () => {
    const request = createMockRequest('/users')
    middleware(request)
    expect(NextResponse.redirect).toHaveBeenCalled()
  })

  it('should redirect /feedbacks without token', () => {
    const request = createMockRequest('/feedbacks')
    middleware(request)
    expect(NextResponse.redirect).toHaveBeenCalled()
  })

  it('should allow unknown route with next()', () => {
    const request = createMockRequest('/unknown-route')
    middleware(request)
    expect(NextResponse.next).toHaveBeenCalled()
  })
})
