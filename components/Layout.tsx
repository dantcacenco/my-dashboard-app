'use client'

import Navigation from './Navigation'

interface LayoutProps {
  children: React.ReactNode
}

export default function Layout({ children }: LayoutProps) {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Top Navigation */}
      <Navigation />
      
      {/* Main Content */}
      <main className="flex-1">
        {children}
      </main>
    </div>
  )
}