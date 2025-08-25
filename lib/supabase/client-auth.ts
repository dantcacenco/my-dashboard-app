'use client'

import { createBrowserClient } from '@supabase/ssr'

export function createClient() {
  // These will be replaced at runtime by Next.js public env vars
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
  const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
  
  // During build, return a mock client if vars aren't available
  if (!supabaseUrl || !supabaseAnonKey) {
    if (typeof window === 'undefined') {
      // Server-side during build - return null
      return null as any
    }
    // Client-side - these should be available
    console.error('Missing Supabase environment variables')
  }
  
  return createBrowserClient(
    supabaseUrl || '',
    supabaseAnonKey || ''
  )
}
