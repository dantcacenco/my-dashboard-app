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
