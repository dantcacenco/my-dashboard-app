import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  // Log all navigation attempts
  if (request.nextUrl.pathname.startsWith('/proposals')) {
    console.log('[Middleware] Proposal route accessed:', {
      pathname: request.nextUrl.pathname,
      url: request.url,
      headers: Object.fromEntries(request.headers.entries())
    })
  }
  
  return NextResponse.next()
}

export const config = {
  matcher: ['/proposals/:path*']
}
