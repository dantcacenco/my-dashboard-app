'use client'

import { createContext, useContext, ReactNode } from 'react'
import { createClient } from '@/lib/supabase/client'

interface ProposalContextType {
  token: string
  supabase: ReturnType<typeof createClient>
}

const ProposalContext = createContext<ProposalContextType | null>(null)

export function ProposalProvider({ children, token }: { children: ReactNode, token: string }) {
  // Create a custom Supabase client that includes the token header
  const supabase = createClient()
  
  // Override the auth to include token in headers
  const originalFrom = supabase.from.bind(supabase)
  supabase.from = (table: string) => {
    const query = originalFrom(table)
    // Add token to all queries
    if (query.select) {
      const originalSelect = query.select.bind(query)
      query.select = (...args: any[]) => {
        const selectQuery = originalSelect(...args)
        return selectQuery.eq('customer_view_token', token)
      }
    }
    return query
  }

  return (
    <ProposalContext.Provider value={{ token, supabase }}>
      {children}
    </ProposalContext.Provider>
  )
}

export function useProposal() {
  const context = useContext(ProposalContext)
  if (!context) {
    throw new Error('useProposal must be used within ProposalProvider')
  }
  return context
}
