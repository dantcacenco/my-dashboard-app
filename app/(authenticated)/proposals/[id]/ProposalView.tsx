'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Edit, Send, FileText, DollarSign, Calendar, User, MapPin, Phone, Mail } from 'lucide-react'
import CreateJobModal from './CreateJobModal'
import SendProposal from './SendProposal'

interface ProposalViewProps {
  proposal: any
  userRole: string | null
  userId: string
}

export default function ProposalView({ proposal, userRole, userId }: ProposalViewProps) {
  const router = useRouter()
  const [showCreateJobModal, setShowCreateJobModal] = useState(false)
  const [showSendModal, setShowSendModal] = useState(false)

  const handleEdit = () => {
    router.push(`/proposals/${proposal.id}/edit`)
  }

  const handleSendComplete = () => {
    setShowSendModal(false)
    router.refresh()
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

  // Calculate totals - only count selected add-ons
  const services = proposal.proposal_items?.filter((item: any) => !item.is_addon) || []
  const addons = proposal.proposal_items?.filter((item: any) => item.is_addon) || []
  
  // Services are always included, add-ons only if selected
  const subtotal = services.reduce((sum: number, item: any) => sum + (item.total_price || 0), 0) +
                   addons.filter((item: any) => item.is_selected).reduce((sum: number, item: any) => sum + (item.total_price || 0), 0)
  
  const taxAmount = subtotal * (proposal.tax_rate || 0)
  const total = subtotal + taxAmount

  // Customer view URL
  const customerViewUrl = proposal.customer_view_token 
    ? `${window.location.origin}/proposal/view/${proposal.customer_view_token}`
    : null

  return (
    <div className="p-6">
      {/* Header */}
      <div className="flex justify-between items-start mb-6">
        <div>
          <h1 className="text-3xl font-bold">Proposal #{proposal.proposal_number}</h1>
          <p className="text-muted-foreground mt-1">{proposal.title}</p>
        </div>
        
        <div className="flex items-center gap-4">
          <span className={`px-3 py-1 rounded-full text-sm font-semibold ${getStatusColor(proposal.status)}`}>
            {proposal.status.charAt(0).toUpperCase() + proposal.status.slice(1)}
          </span>
          
          <div className="flex gap-2">
            {proposal.status === 'draft' && (
              <>
                <Button onClick={handleEdit} variant="outline">
                  <Edit className="h-4 w-4 mr-2" />
                  Edit
                </Button>
                <Button onClick={() => setShowSendModal(true)}>
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
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Content */}
        <div className="lg:col-span-2 space-y-6">
          {/* Customer Info */}
          <Card>
            <CardHeader>
              <CardTitle>Customer Information</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="flex items-center gap-2">
                  <User className="h-4 w-4 text-gray-500" />
                  <span>{proposal.customers?.name || 'No customer'}</span>
                </div>
                <div className="flex items-center gap-2">
                  <Mail className="h-4 w-4 text-gray-500" />
                  <span>{proposal.customers?.email || '-'}</span>
                </div>
                <div className="flex items-center gap-2">
                  <Phone className="h-4 w-4 text-gray-500" />
                  <span>{proposal.customers?.phone || '-'}</span>
                </div>
                <div className="flex items-center gap-2">
                  <MapPin className="h-4 w-4 text-gray-500" />
                  <span>{proposal.customers?.address || '-'}</span>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Services */}
          {services.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle>Services</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {services.map((item: any) => (
                    <div key={item.id} className="border rounded-lg p-4 bg-gray-50">
                      <div className="flex justify-between items-start">
                        <div>
                          <h4 className="font-medium">{item.name}</h4>
                          <p className="text-sm text-gray-600 mt-1">{item.description}</p>
                          <div className="text-sm text-gray-500 mt-2">
                            Qty: {item.quantity} @ ${item.unit_price?.toFixed(2)}
                          </div>
                        </div>
                        <div className="text-right">
                          <div className="font-bold text-green-600">
                            ${item.total_price?.toFixed(2)}
                          </div>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Add-ons */}
          {addons.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle>Optional Add-ons</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {addons.map((item: any) => (
                    <div key={item.id} className={`border rounded-lg p-4 ${item.is_selected ? 'bg-orange-50 border-orange-200' : 'bg-gray-50 opacity-60'}`}>
                      <div className="flex justify-between items-start">
                        <div>
                          <div className="flex items-center gap-2">
                            <input
                              type="checkbox"
                              checked={item.is_selected}
                              disabled
                              className="w-4 h-4"
                            />
                            <h4 className="font-medium">{item.name}</h4>
                            <Badge variant="secondary" className="bg-orange-200 text-orange-800">Add-on</Badge>
                          </div>
                          <p className="text-sm text-gray-600 mt-1 ml-6">{item.description}</p>
                          <div className="text-sm text-gray-500 mt-2 ml-6">
                            Qty: {item.quantity} @ ${item.unit_price?.toFixed(2)}
                          </div>
                        </div>
                        <div className="text-right">
                          <div className={`font-bold ${item.is_selected ? 'text-green-600' : 'text-gray-400'}`}>
                            ${item.total_price?.toFixed(2)}
                          </div>
                          {!item.is_selected && (
                            <div className="text-xs text-gray-500">Not selected</div>
                          )}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
                <div className="mt-4 p-3 bg-blue-50 rounded text-sm text-blue-700">
                  Note: Add-ons will only be included in the total when selected by the customer
                </div>
              </CardContent>
            </Card>
          )}
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Totals */}
          <Card>
            <CardHeader>
              <CardTitle>Proposal Summary</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                <div className="flex justify-between">
                  <span>Services Subtotal:</span>
                  <span>${services.reduce((sum: number, item: any) => sum + (item.total_price || 0), 0).toFixed(2)}</span>
                </div>
                {addons.filter((item: any) => item.is_selected).length > 0 && (
                  <div className="flex justify-between text-orange-600">
                    <span>Selected Add-ons:</span>
                    <span>+${addons.filter((item: any) => item.is_selected).reduce((sum: number, item: any) => sum + (item.total_price || 0), 0).toFixed(2)}</span>
                  </div>
                )}
                <div className="flex justify-between font-medium">
                  <span>Subtotal:</span>
                  <span>${subtotal.toFixed(2)}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span>Tax ({(proposal.tax_rate * 100).toFixed(1)}%):</span>
                  <span>${taxAmount.toFixed(2)}</span>
                </div>
                <div className="flex justify-between font-bold text-lg border-t pt-3">
                  <span>Total:</span>
                  <span className="text-green-600">${total.toFixed(2)}</span>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Customer View Link */}
          {customerViewUrl && proposal.status !== 'draft' && (
            <Card>
              <CardHeader>
                <CardTitle>Customer Access</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  <p className="text-sm text-gray-600">
                    Customer can view this proposal at:
                  </p>
                  <div className="p-2 bg-gray-50 rounded break-all">
                    <a 
                      href={customerViewUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-blue-600 hover:text-blue-800 text-sm"
                    >
                      {customerViewUrl}
                    </a>
                  </div>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Dates */}
          <Card>
            <CardHeader>
              <CardTitle>Timeline</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-gray-500">Created:</span>
                  <span>{new Date(proposal.created_at).toLocaleDateString()}</span>
                </div>
                {proposal.sent_date && (
                  <div className="flex justify-between">
                    <span className="text-gray-500">Sent:</span>
                    <span>{new Date(proposal.sent_date).toLocaleDateString()}</span>
                  </div>
                )}
                {proposal.valid_until && (
                  <div className="flex justify-between">
                    <span className="text-gray-500">Valid Until:</span>
                    <span>{new Date(proposal.valid_until).toLocaleDateString()}</span>
                  </div>
                )}
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Modals */}
      {showSendModal && (
        <SendProposal
          proposalId={proposal.id}
          proposalNumber={proposal.proposal_number}
          customer={proposal.customers}
          total={total}
          onSent={handleSendComplete}
          onCancel={() => setShowSendModal(false)}
        />
      )}

      {showCreateJobModal && (
        <CreateJobModal
          proposal={proposal}
          onClose={() => {
            setShowCreateJobModal(false)
            router.push('/jobs')
          }}        />
      )}
    </div>
  )
}
