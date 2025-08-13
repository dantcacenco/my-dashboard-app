#!/bin/bash

echo "🔧 Converting navigation to horizontal top bar..."

# Update Navigation component to horizontal layout
cat > components/Navigation.tsx << 'EOF'
'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { LayoutDashboard, FileText, Users, Briefcase, DollarSign, LogOut, UserCog, Calendar } from 'lucide-react'
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

  // Define navigation items based on role
  const navItems = userRole === 'technician' ? [
    { href: '/technician', label: 'My Tasks', icon: Calendar },
  ] : [
    { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { href: '/proposals', label: 'Proposals', icon: FileText },
    { href: '/customers', label: 'Customers', icon: Users },
    { href: '/jobs', label: 'Jobs', icon: Briefcase },
    { href: '/invoices', label: 'Invoices', icon: DollarSign },
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

# Update the authenticated layout to use horizontal navigation
cat > app/\(authenticated\)/layout.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import Navigation from '@/components/Navigation'

export default async function AuthenticatedLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect('/auth/login')
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Navigation />
      <main className="w-full">
        {children}
      </main>
    </div>
  )
}
EOF

# Also update the technician layout to match
cat > app/\(authenticated\)/technician/layout.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export default async function TechnicianLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) redirect('/auth/login')

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Only technicians can access this section
  if (profile?.role !== 'technician') {
    redirect('/dashboard')
  }

  return <>{children}</>
}
EOF

# Commit the changes
git add .
git commit -m "feat: convert navigation to horizontal top bar layout"
git push origin main

echo "✅ Navigation converted to horizontal layout!"
echo ""
echo "Changes made:"
echo "1. Navigation is now a horizontal bar at the top"
echo "2. Logo on the left, menu items in the center, user info on the right"
echo "3. Clean, modern appearance with proper spacing"
echo "4. Active items highlighted in blue"
echo "5. Role-based menu items still work"
echo ""
echo "Deploy to see the new horizontal navigation!"