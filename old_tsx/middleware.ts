import { NextRequest, NextResponse } from 'next/server'

const AUTH_PATHS = ['/login', '/register', '/forgot-password', '/reset-password', '/verify-email']
const AZUBI_PATHS = ['/dashboard', '/profile', '/reviews/new', '/my-reviews', '/bookmarks', '/notifications', '/settings']
const BETRIEB_PATHS = ['/betrieb-dashboard', '/betrieb-profile', '/betrieb-reviews', '/betrieb-analytics', '/betrieb-team', '/betrieb-subscription', '/betrieb-reports', '/betrieb-settings']

const SESSION_COOKIE_NAMES = [
  'sb-access-token',
  'sb:token',
  'supabase-auth-token',
  'karriko-session',
]

const ROLE_COOKIE_NAMES = ['karriko-role', 'sb-role', 'user-role']

function hasPrefix(pathname: string, candidates: string[]) {
  return candidates.some((candidate) => pathname === candidate || pathname.startsWith(`${candidate}/`))
}

function getSessionState(request: NextRequest) {
  const hasSession = SESSION_COOKIE_NAMES.some((name) => Boolean(request.cookies.get(name)?.value))
  const roleCookie = ROLE_COOKIE_NAMES.map((name) => request.cookies.get(name)?.value).find(Boolean)

  return {
    hasSession,
    role: roleCookie?.toLowerCase(),
  }
}

function redirectTo(request: NextRequest, pathname: string) {
  const url = new URL(pathname, request.url)
  return NextResponse.redirect(url)
}

function loginRedirect(request: NextRequest) {
  const url = new URL('/login', request.url)
  url.searchParams.set('next', request.nextUrl.pathname)
  return NextResponse.redirect(url)
}

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl
  const { hasSession, role } = getSessionState(request)

  if (hasPrefix(pathname, AUTH_PATHS)) {
    if (!hasSession) {
      return NextResponse.next()
    }

    if (role === 'betrieb' || role === 'company') {
      return redirectTo(request, '/betrieb-dashboard')
    }

    return redirectTo(request, '/dashboard')
  }

  const isAzubiRoute = hasPrefix(pathname, AZUBI_PATHS)
  const isBetriebRoute = hasPrefix(pathname, BETRIEB_PATHS)

  if (!isAzubiRoute && !isBetriebRoute) {
    return NextResponse.next()
  }

  if (!hasSession) {
    return loginRedirect(request)
  }

  if (isAzubiRoute && (role === 'betrieb' || role === 'company')) {
    return redirectTo(request, '/betrieb-dashboard')
  }

  if (isBetriebRoute && (role === 'azubi' || role === 'student')) {
    return redirectTo(request, '/dashboard')
  }

  return NextResponse.next()
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|assets|api).*)'],
}