'use client'

import { useState } from 'react'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { formatCurrency } from '@/lib/utils'
import { FileText, Eye, Edit, Send, CheckCircle, Clock, XCircle, DollarSign, LayoutGrid, List } from 'lucide-react'
import SendProposal from './SendProposal'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"

interface Customer {
  id: string
  name: string
  email: string | null
  phone: string | null
}

interface Proposal {
  id: string
  proposal_number: string
  title: string
  status: 'draft' | 'sent' | 'approved' | 'rejected' | 'paid'
  total: number
  created_at: string
  updated_at: string
  customers: Customer
  customer_view_token: string | null
  customer_approved_at: string | null
  customer_signature: string | null
  payment_status: string | null
  deposit_paid_at: string | null
  progress_paid_at: string | null
  final_paid_at: string | null
}

export interface ProposalsListProps {
  proposals: Proposal[]
  userRole: string
}

export default function ProposalsList({ proposals, userRole }: ProposalsListProps) {
  const [proposalsList, setProposalsList] = useState(proposals)
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid')

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'draft':
        return <FileText className="h-4 w-4" />
      case 'sent':
        return <Send className="h-4 w-4" />
      case 'approved':
        return <CheckCircle className="h-4 w-4" />
      case 'rejected':
        return <XCircle className="h-4 w-4" />
      case 'paid':
        return <DollarSign className="h-4 w-4" />
      default:
        return <Clock className="h-4 w-4" />
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'draft':
        return 'bg-gray-100 text-gray-800'
      case 'sent':
        return 'bg-blue-100 text-blue-800'
      case 'approved':
        return 'bg-green-100 text-green-800'
      case 'rejected':
        return 'bg-red-100 text-red-800'
      case 'paid':
        return 'bg-purple-100 text-purple-800'
      default:
        return 'bg-gray-100 text-gray-800'
    }
  }

  const getPaymentStatus = (proposal: Proposal) => {
    if (proposal.final_paid_at) return 'Fully Paid'
    if (proposal.progress_paid_at) return 'Progress Payment Received'
    if (proposal.deposit_paid_at) return 'Deposit Received'
    if (proposal.payment_status === 'deposit_paid') return 'Deposit Paid'
    if (proposal.payment_status === 'roughin_paid') return 'Rough-In Paid'
    if (proposal.payment_status === 'paid') return 'Fully Paid'
    return null
  }

  const handleProposalSent = (proposalId: string, token: string) => {
    setProposalsList(prev => 
      prev.map(p => 
        p.id === proposalId 
          ? { ...p, status: 'sent' as const, customer_view_token: token }
          : p
      )
    )
  }

  // Sort proposals by updated_at date (most recent first)
  const sortedProposals = [...proposalsList].sort((a, b) => {
    return new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime()
  })

  if (proposalsList.length === 0) {
    return (
      <Card>
        <CardContent className="pt-6">
          <div className="text-center text-muted-foreground">
            No proposals found. Create your first proposal to get started.
          </div>
        </CardContent>
      </Card>
    )
  }

  return (
    <>
      {/* View Toggle Buttons */}
      <div className="flex justify-end mb-4">
        <div className="flex gap-2 border rounded-lg p-1">
          <Button
            variant={viewMode === 'grid' ? 'default' : 'ghost'}
            size="sm"
            onClick={() => setViewMode('grid')}
            className="gap-2"
          >
            <LayoutGrid className="h-4 w-4" />
            Box View
          </Button>
          <Button
            variant={viewMode === 'list' ? 'default' : 'ghost'}
            size="sm"
            onClick={() => setViewMode('list')}
            className="gap-2"
          >
            <List className="h-4 w-4" />
            List View
          </Button>
        </div>
      </div>

      {/* Grid View */}
      {viewMode === 'grid' && (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {proposalsList.map((proposal) => {
            const paymentStatus = getPaymentStatus(proposal)
            
            return (
              <Card key={proposal.id}>
                <CardHeader>
                  <div className="flex justify-between items-start">
                    <div>
                      <CardTitle className="text-lg">{proposal.title}</CardTitle>
                      <CardDescription>
                        #{proposal.proposal_number} • {proposal.customers?.name || 'No customer'}
                      </CardDescription>
                    </div>
                    <Badge className={getStatusColor(proposal.status)}>
                      <span className="mr-1">{getStatusIcon(proposal.status)}</span>
                      {proposal.status}
                    </Badge>
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="space-y-2">
                    <div className="flex justify-between">
                      <span className="text-sm text-muted-foreground">Total Amount:</span>
                      <span className="font-semibold">{formatCurrency(proposal.total)}</span>
                    </div>
                    {paymentStatus && (
                      <div className="flex justify-between">
                        <span className="text-sm text-muted-foreground">Payment:</span>
                        <Badge variant="outline" className="text-xs">
                          {paymentStatus}
                        </Badge>
                      </div>
                    )}
                    {proposal.customer_approved_at && (
                      <div className="flex justify-between">
                        <span className="text-sm text-muted-foreground">Approved:</span>
                        <span className="text-sm">
                          {new Date(proposal.customer_approved_at).toLocaleDateString()}
                        </span>
                      </div>
                    )}
                    <div className="flex justify-between">
                      <span className="text-sm text-muted-foreground">Created:</span>
                      <span className="text-sm">
                        {new Date(proposal.created_at).toLocaleDateString()}
                      </span>
                    </div>
                  </div>
                </CardContent>
                <CardFooter className="gap-2">
                  <Link href={`/proposals/${proposal.id}`} className="flex-1">
                    <Button variant="outline" size="sm" className="w-full">
                      <Eye className="h-4 w-4 mr-1" />
                      View
                    </Button>
                  </Link>
                  {(userRole === 'admin' || userRole === 'boss') && proposal.status === 'draft' && (
                    <Link href={`/proposals/${proposal.id}/edit`} className="flex-1">
                      <Button variant="outline" size="sm" className="w-full">
                        <Edit className="h-4 w-4 mr-1" />
                        Edit
                      </Button>
                    </Link>
                  )}
                  {(userRole === 'admin' || userRole === 'boss') && 
                   (proposal.status === 'draft' || proposal.status === 'sent') && (
                    <SendProposal
                  proposalId={proposal.id}
                  proposalNumber={proposal.proposal_number}
                  customerEmail={proposal.customers?.email || ''}
                  customerName={proposal.customers?.name}
                  currentToken={proposal.customer_view_token}
                  onSent={handleProposalSent}
                  buttonVariant="outline"
                  buttonSize="sm"
                  buttonClassName="flex-1"
                />
                  )}
                </CardFooter>
              </Card>
            )
          })}
        </div>
      )}

      {/* List View */}
      {viewMode === 'list' && (
        <Card>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Proposal #</TableHead>
                <TableHead>Title</TableHead>
                <TableHead>Customer</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Payment</TableHead>
                <TableHead className="text-right">Amount</TableHead>
                <TableHead>Updated</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {sortedProposals.map((proposal) => {
                const paymentStatus = getPaymentStatus(proposal)
                
                return (
                  <TableRow key={proposal.id}>
                    <TableCell className="font-medium">
                      #{proposal.proposal_number}
                    </TableCell>
                    <TableCell>{proposal.title}</TableCell>
                    <TableCell>{proposal.customers?.name || 'No customer'}</TableCell>
                    <TableCell>
                      <Badge className={getStatusColor(proposal.status)}>
                        <span className="mr-1">{getStatusIcon(proposal.status)}</span>
                        {proposal.status}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      {paymentStatus ? (
                        <Badge variant="outline" className="text-xs">
                          {paymentStatus}
                        </Badge>
                      ) : (
                        <span className="text-muted-foreground">-</span>
                      )}
                    </TableCell>
                    <TableCell className="text-right font-semibold">
                      {formatCurrency(proposal.total)}
                    </TableCell>
                    <TableCell>
                      {new Date(proposal.updated_at).toLocaleDateString()}
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="flex justify-end gap-2">
                        <Link href={`/proposals/${proposal.id}`}>
                          <Button variant="ghost" size="sm">
                            <Eye className="h-4 w-4" />
                          </Button>
                        </Link>
                        {(userRole === 'admin' || userRole === 'boss') && proposal.status === 'draft' && (
                          <Link href={`/proposals/${proposal.id}/edit`}>
                            <Button variant="ghost" size="sm">
                              <Edit className="h-4 w-4" />
                            </Button>
                          </Link>
                        )}
                        {(userRole === 'admin' || userRole === 'boss') && 
                         (proposal.status === 'draft' || proposal.status === 'sent') && (
                          <SendProposal
                  proposalId={proposal.id}
                  proposalNumber={proposal.proposal_number}
                  customerEmail={proposal.customers?.email || ''}
                  customerName={proposal.customers?.name}
                  currentToken={proposal.customer_view_token}
                  onSent={handleProposalSent}
                  buttonVariant="outline"
                  buttonSize="sm"
                  buttonClassName="flex-1"
                />
                        )}
                      </div>
                    </TableCell>
                  </TableRow>
                )
              })}
            </TableBody>
          </Table>
        </Card>
      )}
    </>
  )
}
