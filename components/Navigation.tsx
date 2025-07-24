'use client'

import { useState } from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'

export default function Navigation() {
  const pathname = usePathname()
  const router = useRouter()
  const [isLoading, setIsLoading] = useState(false)
  const supabase = createClient()

  // Navigation links
  const navigationLinks = [
    {
      name: 'Dashboard',
      href: '/'
    },
    {
      name: 'Proposals',
      href: '/proposals'
    },
    {
      name: 'Customers',
      href: '/customers'
    },
    {
      name: 'Jobs',
      href: '/jobs'
    },
    {
      name: 'Invoices',
      href: '/invoices'
    }
  ]

  // Check if link is active
  const isActive = (href: string) => {
    // Exact match for root/dashboard
    if (href === '/') {
      return pathname === '/'
    }
    // For other routes, check if pathname starts with href
    return pathname.startsWith(href)
  }

  // Handle sign out
  const handleSignOut = async () => {
    setIsLoading(true)
    try {
      await supabase.auth.signOut()
      router.push('/auth/signin')
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
            <Link href="/" className="flex items-center">
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
                  <p className="text-sm font-medium text-gray-900">Admin</p>
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