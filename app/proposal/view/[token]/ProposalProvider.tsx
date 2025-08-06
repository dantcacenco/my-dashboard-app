'use client'

import { createContext, useContext, ReactNode } from 'react'

interface ProposalContextType {
  token: string
}

const ProposalContext = createContext<ProposalContextType | null>(null)

export function ProposalProvider({ children, token }: { children: ReactNode, token: string }) {
  return (
    <ProposalContext.Provider value={{ token }}>
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
