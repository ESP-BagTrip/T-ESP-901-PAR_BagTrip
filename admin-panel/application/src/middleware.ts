import { NextRequest, NextResponse } from 'next/server'

const publicRoutes = ['/', '/login']
const protectedRoutes = ['/dashboard', '/test', '/users', '/feedbacks']

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl
  const token = request.cookies.get('auth-token')?.value

  // Allow public routes without authentication
  if (publicRoutes.includes(pathname)) {
    return NextResponse.next()
  }

  // Protect admin routes
  if (protectedRoutes.some(route => pathname.startsWith(route)) && !token) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  // Redirect authenticated users from login page to dashboard
  if (pathname === '/login' && token) {
    return NextResponse.redirect(new URL('/dashboard', request.url))
  }

  return NextResponse.next()
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico|.*\\.png$).*)'],
}
