'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { ArrowLeft, Edit, Send, FileText, DollarSign, Calendar, User } from 'lucide-react'
import Link from 'next/link'
import CreateJobModal from './CreateJobModal'
import ProposalItemsDisplay from '@/components/ProposalItemsDisplay'

interface ProposalViewProps {
  proposal: any
  userRole: string
}

export default function ProposalView({ proposal, userRole }: ProposalViewProps) {
  const router = useRouter()
  const [showCreateJobModal, setShowCreateJobModal] = useState(false)

  const handleEdit = () => {
    router.push(`/proposals/${proposal.id}/edit`)
  }

  const handleSendProposal = () => {
    router.push(`/proposals/${proposal.id}/send`)
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'draft': return 'bg-gray-100 text-gray-800'
      case 'sent': return 'bg-blue-100 text-blue-800'
      case 'accepted': return 'bg-green-100 text-green-800'
      case 'rejected': return 'bg-red-100 text-red-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  // Format items for ProposalItemsDisplay
  const formattedItems = proposal.proposal_items?.map((item: any) => ({
    id: item.id,
    item_type: item.item_type,
    title: item.title,
    description: item.description,
    quantity: item.quantity,
    unit_price: item.unit_price,
    total_price: item.total_price
  })) || []

  return (
    <div className="max-w-4xl mx-auto p-6">
      {/* Header */}
      <div className="flex justify-between items-center mb-6">
        <div className="flex items-center gap-4">
          <Link href="/proposals">
            <Button variant="ghost" size="sm">
              <ArrowLeft className="h-4 w-4 mr-2" />
              Back to Proposals
            </Button>
          </Link>
          <h1 className="text-2xl font-bold">Proposal {proposal.proposal_number}</h1>
          <span className={`px-3 py-1 rounded-full text-sm font-medium ${getStatusColor(proposal.status)}`}>
            {proposal.status.charAt(0).toUpperCase() + proposal.status.slice(1)}
          </span>
        </div>
        
        <div className="flex gap-2">
          {proposal.status === 'draft' && (
            <>
              <Button onClick={handleEdit} variant="outline">
                <Edit className="h-4 w-4 mr-2" />
                Edit
              </Button>
              <Button onClick={handleSendProposal}>
                <Send className="h-4 w-4 mr-2" />
                Send Proposal
              </Button>
            </>
          )}
          {proposal.status === 'sent' && userRole === 'boss' && (
            <Button onClick={() => setShowCreateJobModal(true)} variant="default">
              <FileText className="h-4 w-4 mr-2" />
              Create Job
            </Button>
          )}
          {proposal.status === 'accepted' && !proposal.job_created && (
            <Button onClick={() => setShowCreateJobModal(true)} variant="default">
              <FileText className="h-4 w-4 mr-2" />
              Create Job
            </Button>
          )}
        </div>
      </div>

      {/* Proposal Info */}
      <div className="bg-white rounded-lg shadow-sm border p-6 mb-6">
        <h2 className="text-xl font-semibold mb-4">{proposal.title}</h2>
        {proposal.description && (
          <p className="text-gray-600 mb-6">{proposal.description}</p>
        )}
        
        <div className="grid grid-cols-2 gap-4 text-sm">
          <div className="flex items-center gap-2">
            <User className="h-4 w-4 text-gray-500" />
            <span className="text-gray-500">Customer:</span>
            <span className="font-medium">{proposal.customers?.name || proposal.customer_name}</span>
          </div>
          <div className="flex items-center gap-2">
            <Calendar className="h-4 w-4 text-gray-500" />
            <span className="text-gray-500">Created:</span>
            <span className="font-medium">{new Date(proposal.created_at).toLocaleDateString()}</span>
          </div>
        </div>
      </div>

      {/* Items Section with ProposalItemsDisplay */}
      <div className="bg-white rounded-lg shadow-sm border p-6 mb-6">
        <h2 className="text-xl font-semibold mb-4">Items</h2>
        <ProposalItemsDisplay 
          items={formattedItems}
          taxRate={proposal.tax_rate || 0.08}
          showCheckboxes={false}
        />
      </div>

      {/* Payment Terms */}
      {proposal.payment_stages && proposal.payment_stages.length > 0 && (
        <div className="bg-white rounded-lg shadow-sm border p-6">
          <h2 className="text-xl font-semibold mb-4">Payment Terms</h2>
          <div className="space-y-3">
            {proposal.payment_stages.map((stage: any, index: number) => (
              <div key={stage.id || index} className="flex justify-between items-center p-3 bg-gray-50 rounded">
                <div>
                  <span className="font-medium">{stage.stage_name}</span>
                  <span className="text-sm text-gray-500 ml-2">({stage.percentage}%)</span>
                </div>
                <span className="font-semibold">${stage.amount.toFixed(2)}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Create Job Modal */}
      {showCreateJobModal && (
        <CreateJobModal
          open={showCreateJobModal}
          onClose={() => setShowCreateJobModal(false)}
          proposal={proposal}
        />
      )}
    </div>
  )
}
