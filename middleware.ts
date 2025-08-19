import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  // List of paths that require authentication
  const protectedPaths = ['/dashboard', '/jobs', '/proposals', '/customers', '/technicians']
  
  const path = request.nextUrl.pathname
  
  // Check if the path requires authentication
  const isProtectedPath = protectedPaths.some(protectedPath => 
    path.startsWith(protectedPath)
  )
  
  if (isProtectedPath) {
    // The actual auth check is handled by Supabase in the layouts
    // This middleware just ensures the routes exist
    return NextResponse.next()
  }
  
  return NextResponse.next()
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - auth (authentication pages)
     * - proposal/view (public proposal views)
     */
    '/((?!api|_next/static|_next/image|favicon.ico|auth|proposal/view).*)',
  ],
}
