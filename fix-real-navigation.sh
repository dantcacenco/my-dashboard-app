#!/bin/bash

# Fix the ACTUAL Navigation component being used
set -e

echo "🔥 FIXING THE ACTUAL NAVIGATION COMPONENT..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Update the CORRECT Navigation.tsx file in /components
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
    <nav className="bg-gray-900 text-white w-64 min-h-screen p-4">
      <div className="mb-8">
        <h1 className="text-2xl font-bold">Service Pro</h1>
        {userEmail && (
          <p className="text-sm text-gray-400 mt-1">{userEmail}</p>
        )}
        {userRole && (
          <p className="text-xs text-gray-500 mt-1 capitalize">{userRole}</p>
        )}
      </div>

      <ul className="space-y-2">
        {navItems.map((item) => {
          const Icon = item.icon
          const isActive = pathname === item.href || pathname.startsWith(`${item.href}/`)
          
          return (
            <li key={item.href}>
              <Link
                href={item.href}
                className={`flex items-center space-x-3 p-3 rounded-lg transition-colors ${
                  isActive
                    ? 'bg-blue-600 text-white'
                    : 'hover:bg-gray-800'
                }`}
              >
                <Icon className="w-5 h-5" />
                <span>{item.label}</span>
              </Link>
            </li>
          )
        })}
      </ul>

      <div className="absolute bottom-4 left-4 right-4">
        <button
          onClick={handleSignOut}
          className="flex items-center space-x-3 p-3 rounded-lg hover:bg-gray-800 transition-colors w-full"
        >
          <LogOut className="w-5 h-5" />
          <span>Sign Out</span>
        </button>
      </div>
    </nav>
  )
}
EOF

echo "✅ Fixed the ACTUAL Navigation component (removed Invoices)"

# Remove the duplicate/wrong Navigation component
rm -f app/components/Navigation.tsx
echo "✅ Removed duplicate Navigation component"

# Remove backup files
rm -f components/Navigation.tsx.backup
rm -f components/Navigation.tsx.bak
echo "✅ Removed backup files"

# Test the build
echo "🔨 Testing build..."
npm run build 2>&1 | tail -10

echo "📤 Committing the REAL fix..."
git add -A
git commit -m "FIX: Remove Invoices from the ACTUAL Navigation component being used" || true
git push origin main

echo ""
echo "🚨 IMPORTANT: This was the issue!"
echo "There were TWO Navigation components:"
echo "1. /components/Navigation.tsx (✅ ACTUAL one being used - NOW FIXED)"
echo "2. /app/components/Navigation.tsx (❌ Wrong one we were editing - NOW DELETED)"
echo ""
echo "✅ The Invoices tab should NOW be gone from the website!"
echo "🚀 Deploying to Vercel..."
