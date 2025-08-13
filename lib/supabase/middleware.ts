import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import { hasEnvVars } from "../utils";

export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({
    request,
  });

  // If the env vars are not set, skip middleware check
  if (!hasEnvVars) {
    return supabaseResponse;
  }

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value),
          );
          supabaseResponse = NextResponse.next({
            request,
          });
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options),
          );
        },
      },
    },
  );

  const { data } = await supabase.auth.getClaims();
  const user = data?.claims;

  // Public paths that don't require authentication
  const publicPaths = [
    '/auth/login',
    '/proposal/view',
    '/proposal/payment-success',
    '/api/proposal-approval',
    '/api/create-payment',
    '/api/stripe/webhook'
  ];

  const pathname = request.nextUrl.pathname;
  
  // Check if current path is public
  const isPublicPath = publicPaths.some(path => pathname.startsWith(path));

  // If user is not authenticated and trying to access protected route
  if (!user && !isPublicPath && pathname !== '/') {
    const url = request.nextUrl.clone();
    url.pathname = "/auth/login";
    return NextResponse.redirect(url);
  }

  // If user IS authenticated and trying to access login page, redirect to appropriate dashboard
  if (user && pathname === '/auth/login') {
    const url = request.nextUrl.clone();
    // We'll handle role-based redirect in the login page itself
    url.pathname = "/";
    return NextResponse.redirect(url);
  }

  return supabaseResponse;
}
