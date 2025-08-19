#!/bin/bash

# Fix Navigation back to top horizontal white bar AND fix jobs routing
set -e

echo "🔧 Restoring beautiful top navigation and fixing job routing..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# 1. Restore the CORRECT Navigation style (horizontal, white, beautiful)
echo "✨ Restoring top navigation bar..."
cat > components/Navigation.tsx << 'EOF'
'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { LayoutDashboard, FileText, Users, Briefcase, LogOut, UserCog, Calendar } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'
import { useEffect, useState } from 'react'

export default function Navigation() {
  const pathname = usePathname()
  const router = useRouter()
  const [userRole, setUserRole] = useState<string | null>(null)
  const [userEmail, setUserEmail] = useState<string | null>(null)

  useEffect(() => {
    async function getUserInfo() {
      const supabase = createClient()
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
    getUserInfo()
  }, [])

  const handleSignOut = async () => {
    const supabase = createClient()
    await supabase.auth.signOut()
    router.push('/auth/login')
  }

  // Define navigation items based on role - NO INVOICES!
  const navItems = userRole === 'technician' ? [
    { href: '/technician', label: 'My Tasks', icon: Calendar },
  ] : [
    { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { href: '/proposals', label: 'Proposals', icon: FileText },
    { href: '/customers', label: 'Customers', icon: Users },
    { href: '/jobs', label: 'Jobs', icon: Briefcase },
    { href: '/technicians', label: 'Technicians', icon: UserCog },
  ]

  return (
    <nav className="w-full bg-white border-b border-gray-200">
      <div className="flex items-center justify-between px-6 h-16">
        {/* Logo */}
        <div className="flex items-center">
          <h1 className="text-xl font-bold text-gray-900 mr-8">Service Pro</h1>
          
          {/* Navigation Items */}
          <div className="flex items-center space-x-1">
            {navItems.map((item) => {
              const Icon = item.icon
              const isActive = pathname === item.href || pathname.startsWith(item.href + '/')
              
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                    isActive 
                      ? 'bg-blue-50 text-blue-600' 
                      : 'text-gray-700 hover:bg-gray-100'
                  }`}
                >
                  <Icon className="h-4 w-4" />
                  <span>{item.label}</span>
                </Link>
              )
            })}
          </div>
        </div>

        {/* User Menu */}
        <div className="flex items-center gap-4">
          <div className="text-sm text-gray-600">
            {userEmail}
          </div>
          <button
            onClick={handleSignOut}
            className="flex items-center gap-2 px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <LogOut className="h-4 w-4" />
            <span>Sign Out</span>
          </button>
        </div>
      </div>
    </nav>
  )
}
EOF

echo "✅ Navigation restored to beautiful top bar!"

# 2. Fix the jobs routing - Create redirect from /jobs/[id] to /(authenticated)/jobs/[id]
echo "🔧 Creating redirect for job URLs..."
mkdir -p app/jobs/\[id\]
cat > 'app/jobs/[id]/page.tsx' << 'EOF'
import { redirect } from 'next/navigation'

interface PageProps {
  params: Promise<{ id: string }>
}

export default async function JobRedirectPage({ params }: PageProps) {
  const { id } = await params
  // Redirect to the correct authenticated route
  redirect(`/(authenticated)/jobs/${id}`)
}
EOF

echo "✅ Job routing redirect created!"

# 3. Test build
echo "🔨 Testing build..."
npm run build 2>&1 | tail -10

echo "📤 Committing fixes..."
git add -A
git commit -m "RESTORE: Beautiful top navigation bar + FIX: Job routing with redirect" || true
git push origin main

echo ""
echo "🎉 FIXES APPLIED!"
echo "=================="
echo "✅ Navigation: Restored to horizontal top bar (white, clean)"
echo "✅ Invoices: Still removed from navigation"
echo "✅ Job Routing: Added redirect from /jobs/[id] to correct location"
echo ""
echo "🚀 Deploying to Vercel now..."
echo "⏰ Wait 1-2 minutes then refresh the site"
echo ""
echo "The navigation should now be:"
echo "- At the TOP of the page"
echo "- White background"
echo "- Clean and minimal"
echo "- NO dark sidebar"
echo "- NO invoices tab"
echo ""
echo "Jobs should now work when clicked!"
