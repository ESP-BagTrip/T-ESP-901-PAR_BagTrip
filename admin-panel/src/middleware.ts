import { NextRequest, NextResponse } from 'next/server'

const PROTECTED_PREFIX = '/app'
const PUBLIC_ROUTES = new Set(['/', '/login'])

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl
  const token = request.cookies.get('access_token')?.value

  // Compat: /dashboard (legacy) → /app (permanent redirect)
  if (pathname === '/dashboard' || pathname.startsWith('/dashboard/')) {
    const url = request.nextUrl.clone()
    url.pathname = pathname === '/dashboard' ? '/app' : pathname.replace('/dashboard', '/app')
    return NextResponse.redirect(url, 308)
  }

  // Public routes: always allowed
  if (PUBLIC_ROUTES.has(pathname)) {
    // Redirect authenticated users away from /login
    if (pathname === '/login' && token) {
      return NextResponse.redirect(new URL(PROTECTED_PREFIX, request.url))
    }
    return NextResponse.next()
  }

  // Protected area: require token
  if (pathname.startsWith(PROTECTED_PREFIX) && !token) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  return NextResponse.next()
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico|.*\\.png$).*)'],
}
