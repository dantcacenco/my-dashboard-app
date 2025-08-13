#!/bin/bash

echo "🔧 Fixing authentication and routing issues..."
echo "=================================================="

# ============================================
# STEP 1: Fix middleware to use /auth/login
# ============================================

echo ""
echo "📝 Updating middleware to redirect to /auth/login..."

cat > lib/supabase/middleware.ts << 'EOF'
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
EOF

echo "✅ Middleware updated"

# ============================================
# STEP 2: Update auth/login page to handle role-based redirect
# ============================================

echo ""
echo "📝 Updating login page with proper layout and redirects..."

cat > app/auth/login/page.tsx << 'EOF'
import { LoginForm } from "@/components/login-form";

export default function LoginPage() {
  return (
    <div className="flex min-h-screen w-full items-center justify-center p-6 md:p-10 bg-gray-50">
      <div className="w-full max-w-sm">
        <LoginForm />
      </div>
    </div>
  );
}
EOF

echo "✅ Login page updated"

# ============================================
# STEP 3: Update login form to redirect based on role
# ============================================

echo ""
echo "📝 Updating login form component..."

cat > components/login-form.tsx << 'EOF'
"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { useRouter } from "next/navigation";

export function LoginForm() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const router = useRouter();
  const supabase = createClient();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setIsLoading(true);

    try {
      // Sign in
      const { data: authData, error: signInError } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (signInError) {
        setError(signInError.message);
        setIsLoading(false);
        return;
      }

      if (authData.user) {
        // Get user profile to determine role
        const { data: profile } = await supabase
          .from('profiles')
          .select('role')
          .eq('id', authData.user.id)
          .single();

        // Redirect based on role
        if (profile?.role === 'technician') {
          router.push('/technician');
        } else if (profile?.role === 'boss' || profile?.role === 'admin') {
          router.push('/');
        } else {
          // Default to dashboard
          router.push('/');
        }
      }
    } catch (err: any) {
      setError(err.message || "An error occurred during login");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Card className="w-full">
      <CardHeader className="space-y-1">
        <div className="flex items-center justify-center mb-4">
          <div className="w-12 h-12 bg-blue-600 rounded-lg flex items-center justify-center">
            <span className="text-white font-bold text-xl">S</span>
          </div>
        </div>
        <CardTitle className="text-2xl text-center">Service Pro</CardTitle>
        <CardDescription className="text-center">
          Sign in to your account
        </CardDescription>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="email">Email</Label>
            <Input
              id="email"
              type="email"
              placeholder="name@example.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              disabled={isLoading}
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="password">Password</Label>
            <Input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              disabled={isLoading}
            />
          </div>
          {error && (
            <div className="text-sm text-red-600 text-center">
              {error}
            </div>
          )}
          <Button
            type="submit"
            className="w-full"
            disabled={isLoading}
          >
            {isLoading ? "Signing in..." : "Sign in"}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}
EOF

echo "✅ Login form updated with role-based redirect"

# ============================================
# STEP 4: Update root layout to conditionally show navigation
# ============================================

echo ""
echo "📝 Updating root layout to handle navigation visibility..."

cat > app/layout.tsx << 'EOF'
import { Inter } from "next/font/google";
import "./globals.css";
import { Toaster } from "@/components/ui/toaster";

export const metadata = {
  title: "Service Pro - HVAC Management",
  description: "Field Service Management for HVAC Businesses",
};

const inter = Inter({ subsets: ["latin"] });

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={inter.className} suppressHydrationWarning>
      <body className="bg-gray-50 text-gray-900">
        {children}
        <Toaster />
      </body>
    </html>
  );
}
EOF

echo "✅ Root layout updated"

# ============================================
# STEP 5: Create authenticated layout for protected pages
# ============================================

echo ""
echo "📝 Creating authenticated layout wrapper..."

# Create the authenticated directory with escaped parentheses
mkdir -p "app/(authenticated)"

cat > "app/(authenticated)/layout.tsx" << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import Navigation from '@/components/Navigation'

export default async function AuthenticatedLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const supabase = await createClient()
  
  const { data: { user }, error } = await supabase.auth.getUser()
  
  if (error || !user) {
    redirect('/auth/login')
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Navigation />
      <main className="flex-1">
        {children}
      </main>
    </div>
  )
}
EOF

echo "✅ Authenticated layout created"

# ============================================
# STEP 6: Move dashboard content to authenticated folder
# ============================================

echo ""
echo "📝 Moving dashboard to authenticated folder..."

# Move the current page.tsx to dashboard folder in authenticated
mkdir -p "app/(authenticated)/dashboard"

# Move the existing page.tsx content to dashboard
if [ -f "app/page.tsx" ]; then
  mv app/page.tsx "app/(authenticated)/dashboard/page.tsx"
fi

echo "✅ Dashboard moved"

# ============================================
# STEP 7: Create new root page that redirects
# ============================================

echo ""
echo "📝 Creating root redirect page..."

cat > app/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export default async function RootPage() {
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    redirect('/auth/login')
  }

  // Get user profile to determine role
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Redirect based on role
  if (profile?.role === 'technician') {
    redirect('/technician')
  }
  
  // Default to dashboard for boss/admin
  redirect('/dashboard')
}
EOF

echo "✅ Root redirect page created"

# ============================================
# STEP 8: Move other protected pages
# ============================================

echo ""
echo "📝 Moving protected pages to authenticated folder..."

# Move other protected pages if they exist
for dir in proposals customers jobs invoices technicians diagnostic test-auth; do
  if [ -d "app/$dir" ]; then
    echo "Moving $dir..."
    mv "app/$dir" "app/(authenticated)/$dir"
  fi
done

echo "✅ Protected pages moved"

# ============================================
# STEP 9: Update Navigation paths
# ============================================

echo ""
echo "📝 Updating Navigation component..."

cat > components/Navigation.tsx << 'EOF'
'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'

export default function Navigation() {
  const pathname = usePathname()
  const router = useRouter()
  const [isLoading, setIsLoading] = useState(false)
  const [userRole, setUserRole] = useState<string | null>(null)
  const [userEmail, setUserEmail] = useState<string | null>(null)
  const supabase = createClient()

  useEffect(() => {
    loadUserData()
  }, [])

  const loadUserData = async () => {
    const { data: { user } } = await supabase.auth.getUser()
    if (user) {
      setUserEmail(user.email || null)
      
      const { data: profile } = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single()
      
      setUserRole(profile?.role || null)
    }
  }

  // Define navigation links based on role
  const getNavigationLinks = () => {
    const baseLinks = []
    
    if (userRole === 'boss' || userRole === 'admin') {
      baseLinks.push(
        { name: 'Dashboard', href: '/dashboard' },
        { name: 'Proposals', href: '/proposals' },
        { name: 'Customers', href: '/customers' },
        { name: 'Jobs', href: '/jobs' },
        { name: 'Invoices', href: '/invoices' }
      )
      
      if (userRole === 'boss') {
        baseLinks.push({ name: 'Technicians', href: '/technicians' })
      }
    } else if (userRole === 'technician') {
      baseLinks.push(
        { name: 'My Tasks', href: '/technician' },
        { name: 'Time Tracking', href: '/technician/time' },
        { name: 'Jobs', href: '/jobs' }
      )
    }
    
    return baseLinks
  }

  const navigationLinks = getNavigationLinks()

  // Check if link is active
  const isActive = (href: string) => {
    if (href === '/dashboard' || href === '/') {
      return pathname === '/dashboard' || pathname === '/'
    }
    return pathname.startsWith(href)
  }

  // Handle sign out
  const handleSignOut = async () => {
    setIsLoading(true)
    try {
      await supabase.auth.signOut()
      router.push('/auth/login')
    } catch (error) {
      console.error('Error signing out:', error)
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <nav className="bg-white shadow-sm border-b border-gray-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16">
          
          {/* Left side - Logo */}
          <div className="flex items-center">
            <Link href={userRole === 'technician' ? '/technician' : '/dashboard'} className="flex items-center">
              <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center mr-3">
                <span className="text-white font-bold text-lg">S</span>
              </div>
              <span className="text-xl font-bold text-gray-900">Service Pro</span>
            </Link>
          </div>

          {/* Center - Navigation Links */}
          <div className="flex items-center space-x-8">
            {navigationLinks.map((link) => {
              const active = isActive(link.href)
              
              return (
                <Link
                  key={link.name}
                  href={link.href}
                  className={`${
                    active
                      ? 'border-blue-500 text-blue-600'
                      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                  } inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium transition-colors`}
                >
                  {link.name}
                </Link>
              )
            })}
          </div>

          {/* Right side - User menu */}
          <div className="flex items-center">
            <div className="flex items-center space-x-4">
              <div className="flex items-center">
                <div className="w-8 h-8 bg-gray-300 rounded-full flex items-center justify-center">
                  <svg className="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                  </svg>
                </div>
                <div className="ml-3">
                  <p className="text-sm font-medium text-gray-900">
                    {userRole === 'boss' ? 'Boss' : userRole === 'admin' ? 'Admin' : userRole === 'technician' ? 'Technician' : 'User'}
                  </p>
                  {userEmail && (
                    <p className="text-xs text-gray-500">{userEmail}</p>
                  )}
                </div>
              </div>
              <button
                onClick={handleSignOut}
                disabled={isLoading}
                className="text-gray-400 hover:text-gray-600 disabled:opacity-50 p-2"
                title="Sign Out"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                </svg>
              </button>
            </div>
          </div>

        </div>
      </div>
    </nav>
  )
}
EOF

echo "✅ Navigation component updated"

# ============================================
# STEP 10: Remove protected page if it exists
# ============================================

echo ""
echo "📝 Cleaning up old pages..."

# Remove protected page
if [ -d "app/protected" ]; then
  rm -rf app/protected
fi

# Remove signin page if it exists (we use login)
if [ -d "app/auth/signin" ]; then
  rm -rf app/auth/signin
fi

echo "✅ Old pages cleaned up"

# ============================================
# Commit and push all changes
# ============================================

echo ""
echo "📦 Committing authentication fixes..."

git add -A
git commit -m "fix: complete authentication routing overhaul - clean login, role-based routing, proper navigation"
git push origin main

echo ""
echo "✅✅✅ AUTHENTICATION FIXES COMPLETE! ✅✅✅"
echo ""
echo "Summary of changes:"
echo "1. ✅ All redirects now go to /auth/login (not /auth/signin)"
echo "2. ✅ Clean login page without navigation"
echo "3. ✅ Role-based routing after login:"
echo "   - Boss/Admin → /dashboard"
echo "   - Technician → /technician"
echo "4. ✅ Navigation only shows when authenticated"
echo "5. ✅ Removed /protected page"
echo "6. ✅ Organized pages in (authenticated) folder"
echo ""
echo "The authentication system is now clean and professional!"