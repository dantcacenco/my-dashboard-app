#!/bin/bash

# Enhancement: Create Job button opens in modal with pre-filled proposal data
echo "Enhancing Create Job functionality with modal view..."

# First, create the CreateJobModal component
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/\(authenticated\)/proposals/\[id\]/CreateJobModal.tsx << 'EOF'
'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { toast } from 'sonner'
import { Loader2, Plus, X } from 'lucide-react'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'

interface CreateJobModalProps {
  proposal: any
  isOpen: boolean
  onClose: () => void
}

export default function CreateJobModal({ proposal, isOpen, onClose }: CreateJobModalProps) {
  const router = useRouter()
  const supabase = createClient()
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [selectedTechnicians, setSelectedTechnicians] = useState<string[]>([])
  const [technicians, setTechnicians] = useState<any[]>([])
  const [customers, setCustomers] = useState<any[]>([])
  
  const [formData, setFormData] = useState({
    customer_id: '',
    proposal_id: '',
    title: '',
    description: '',
    job_type: 'installation',
    status: 'not_scheduled',
    service_address: '',
    scheduled_date: '',
    scheduled_time: '',
    total_value: '',
    notes: ''
  })

  // Load technicians and customers
  useEffect(() => {
    const loadData = async () => {
      // Fetch technicians
      const { data: techData } = await supabase
        .from('profiles')
        .select('id, email, full_name, role, is_active')
        .eq('role', 'technician')
        .eq('is_active', true)

      setTechnicians(techData || [])

      // Fetch customers
      const { data: custData } = await supabase
        .from('customers')
        .select('id, name, email, phone, address')
        .order('name')

      setCustomers(custData || [])
    }

    loadData()
  }, [])

  // Pre-populate form when proposal changes or modal opens
  useEffect(() => {
    if (proposal && isOpen) {
      // Extract items for description
      const selectedItems = proposal.proposal_items?.filter((item: any) => 
        !item.is_addon || item.is_selected === true
      ) || []
      
      const description = selectedItems.map((item: any) => 
        `${item.quantity}x ${item.name}${item.description ? ': ' + item.description : ''}`
      ).join('\n')

      // Determine job type based on proposal content
      let jobType = 'installation'
      const lowerTitle = (proposal.title || '').toLowerCase()
      const lowerDesc = description.toLowerCase()
      
      if (lowerTitle.includes('repair') || lowerDesc.includes('repair')) {
        jobType = 'repair'
      } else if (lowerTitle.includes('maintenance') || lowerDesc.includes('maintenance')) {
        jobType = 'maintenance'
      } else if (lowerTitle.includes('inspection') || lowerDesc.includes('inspection')) {
        jobType = 'inspection'
      }

      setFormData({
        customer_id: proposal.customer_id || '',
        proposal_id: proposal.id,
        title: `Job from Proposal #${proposal.proposal_number}`,
        description: description,
        job_type: jobType,
        status: 'not_scheduled',
        service_address: proposal.customers?.address || '',
        scheduled_date: '',
        scheduled_time: '',
        total_value: (proposal.total || 0).toString(),
        notes: proposal.notes || ''
      })
    }
  }, [proposal, isOpen])

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  const toggleTechnician = (techId: string) => {
    setSelectedTechnicians(prev =>
      prev.includes(techId)
        ? prev.filter(id => id !== techId)
        : [...prev, techId]
    )
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    // Validation
    if (!formData.customer_id) {
      toast.error('Please select a customer')
      return
    }
    
    if (!formData.title) {
      toast.error('Please enter a job title')
      return
    }
    
    setIsSubmitting(true)
    
    try {
      const requestBody = {
        ...formData,
        total_value: parseFloat(formData.total_value) || 0,
        technicianIds: selectedTechnicians
      }
      
      const response = await fetch('/api/jobs', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(requestBody)
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || data.details || 'Failed to create job')
      }

      if (!data.job || !data.job.id) {
        throw new Error('Job created but no ID returned')
      }

      toast.success(`Job ${data.job.job_number} created successfully!`)
      onClose()
      router.push(`/jobs/${data.job.id}`)
      
    } catch (error: any) {
      console.error('Job creation error:', error)
      toast.error(error.message || 'Failed to create job')
      setIsSubmitting(false)
    }
  }

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-3xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Create Job from Proposal #{proposal?.proposal_number}</DialogTitle>
          <DialogDescription>
            Create a new job based on this approved proposal. The job details have been pre-filled.
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4 mt-4">
          {/* Customer (pre-selected and disabled) */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Customer
            </label>
            <select
              required
              disabled
              value={formData.customer_id}
              className="w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-50"
            >
              <option value="">Select a customer</option>
              {customers.map((customer) => (
                <option key={customer.id} value={customer.id}>
                  {customer.name} - {customer.email}
                </option>
              ))}
            </select>
          </div>

          {/* Job Title */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Job Title *
            </label>
            <input
              type="text"
              required
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-md"
              placeholder="e.g., AC Installation, Furnace Repair"
            />
          </div>

          {/* Job Type and Status */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Job Type
              </label>
              <select
                value={formData.job_type}
                onChange={(e) => setFormData({ ...formData, job_type: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md"
              >
                <option value="installation">Installation</option>
                <option value="repair">Repair</option>
                <option value="maintenance">Maintenance</option>
                <option value="inspection">Inspection</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Status
              </label>
              <select
                value={formData.status}
                onChange={(e) => setFormData({ ...formData, status: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md"
              >
                <option value="not_scheduled">Not Scheduled</option>
                <option value="scheduled">Scheduled</option>
                <option value="in_progress">In Progress</option>
                <option value="completed">Completed</option>
                <option value="cancelled">Cancelled</option>
              </select>
            </div>
          </div>

          {/* Total Value */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Total Value
            </label>
            <input
              type="number"
              step="0.01"
              value={formData.total_value}
              onChange={(e) => setFormData({ ...formData, total_value: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-md"
              placeholder="0.00"
            />
          </div>

          {/* Description */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Description
            </label>
            <textarea
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              rows={4}
              className="w-full px-3 py-2 border border-gray-300 rounded-md"
              placeholder="Describe the work to be done..."
            />
          </div>

          {/* Schedule */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Scheduled Date
              </label>
              <input
                type="date"
                value={formData.scheduled_date}
                onChange={(e) => setFormData({ ...formData, scheduled_date: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Scheduled Time
              </label>
              <input
                type="time"
                value={formData.scheduled_time}
                onChange={(e) => setFormData({ ...formData, scheduled_time: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md"
              />
            </div>
          </div>

          {/* Service Address */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Service Address
            </label>
            <input
              type="text"
              value={formData.service_address}
              onChange={(e) => setFormData({ ...formData, service_address: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-md"
              placeholder="Full service address"
            />
          </div>

          {/* Technician Assignment */}
          {technicians.length > 0 && (
            <div>
              <h3 className="font-medium mb-2">
                Assign Technicians
                <span className="text-sm text-gray-500 ml-2">
                  ({technicians.length} available)
                </span>
              </h3>
              <div className="space-y-2 max-h-40 overflow-y-auto border rounded-lg p-3">
                {technicians.map((tech) => (
                  <label
                    key={tech.id}
                    className="flex items-center gap-3 p-2 hover:bg-gray-50 rounded cursor-pointer"
                  >
                    <input
                      type="checkbox"
                      checked={selectedTechnicians.includes(tech.id)}
                      onChange={() => toggleTechnician(tech.id)}
                      className="h-4 w-4 text-blue-600"
                    />
                    <span>{tech.full_name || tech.email}</span>
                  </label>
                ))}
              </div>
              {selectedTechnicians.length > 0 && (
                <p className="text-sm text-gray-600 mt-2">
                  {selectedTechnicians.length} technician(s) selected
                </p>
              )}
            </div>
          )}

          {/* Notes */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Internal Notes
            </label>
            <textarea
              value={formData.notes}
              onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
              rows={3}
              className="w-full px-3 py-2 border border-gray-300 rounded-md"
              placeholder="Any additional notes..."
            />
          </div>

          {/* Proposal Details Summary */}
          <div className="bg-blue-50 p-4 rounded-lg">
            <h4 className="font-medium text-sm mb-2">Proposal Summary</h4>
            <div className="text-sm space-y-1">
              <p>Proposal #{proposal?.proposal_number}</p>
              <p>Customer: {proposal?.customers?.name}</p>
              <p>Total: {formatCurrency(proposal?.total || 0)}</p>
            </div>
          </div>

          {/* Submit Buttons */}
          <div className="flex justify-end gap-3 pt-4">
            <Button
              type="button"
              variant="outline"
              onClick={onClose}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              disabled={isSubmitting || !formData.customer_id || !formData.title}
            >
              {isSubmitting ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Creating Job...
                </>
              ) : (
                <>
                  <Plus className="h-4 w-4 mr-2" />
                  Create Job
                </>
              )}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}
EOF

# Now update the ProposalView to use the modal
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/\(authenticated\)/proposals/\[id\]/ProposalView.tsx << 'EOF'
'use client'

import { useState, useRef } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Printer, Send, Edit, ChevronLeft, Plus } from 'lucide-react'
import Link from 'next/link'
import { PaymentStages } from './PaymentStages'
import SendProposal from './SendProposal'
import CreateJobModal from './CreateJobModal'
import { useRouter } from 'next/navigation'
import { toast } from 'sonner'

interface ProposalViewProps {
  proposal: any
  userRole: string
}

export default function ProposalView({ proposal, userRole }: ProposalViewProps) {
  const printRef = useRef<HTMLDivElement>(null)
  const [showPrintView, setShowPrintView] = useState(false)
  const [showSendModal, setShowSendModal] = useState(false)
  const [showCreateJobModal, setShowCreateJobModal] = useState(false)
  const router = useRouter()

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'long',
      day: 'numeric',
      year: 'numeric'
    })
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'draft': return 'bg-gray-500'
      case 'sent': return 'bg-blue-500'
      case 'viewed': return 'bg-purple-500'
      case 'approved':
      case 'accepted': return 'bg-green-500'
      case 'rejected': return 'bg-red-500'
      default: return 'bg-gray-500'
    }
  }

  const handlePrint = () => {
    setShowPrintView(true)
    setTimeout(() => {
      window.print()
      setShowPrintView(false)
    }, 100)
  }

  const handleSendSuccess = () => {
    toast.success('Proposal sent successfully!')
    router.refresh()
  }

  // Check if proposal is approved or has payments
  const canCreateJob = proposal.status === 'approved' || 
                      proposal.status === 'deposit_paid' || 
                      proposal.status === 'progress_paid' || 
                      proposal.status === 'final_paid'

  // Show admin controls for boss or admin roles
  const isAdmin = userRole === 'admin' || userRole === 'boss'
  
  return (
    <div className="space-y-6">
      {/* Action Buttons for Admin/Boss */}
      {isAdmin && (
        <div className="flex gap-2 mb-6">
          <Button onClick={() => router.back()} variant="outline" size="sm">
            <ChevronLeft className="h-4 w-4 mr-1" />
            Back
          </Button>
          <Button 
            onClick={() => setShowSendModal(true)} 
            variant="outline" 
            size="sm"
            disabled={!proposal.customers?.email}
          >
            <Send className="h-4 w-4 mr-1" />
            Send to Customer
          </Button>
          <Link href={`/proposals/${proposal.id}/edit`}>
            <Button variant="outline" size="sm">
              <Edit className="h-4 w-4 mr-1" />
              Edit
            </Button>
          </Link>
          <Button 
            onClick={() => setShowCreateJobModal(true)} 
            variant="default" 
            size="sm"
            disabled={!canCreateJob}
            title={!canCreateJob ? "Proposal must be approved before creating a job" : ""}
          >
            <Plus className="h-4 w-4 mr-1" />
            Create Job
          </Button>
          <Button onClick={handlePrint} variant="outline" size="sm">
            <Printer className="h-4 w-4 mr-1" />
            Print
          </Button>
        </div>
      )}

      {/* Status Badge */}
      <div>
        <Badge className={`${getStatusColor(proposal.status)} text-white`}>
          {proposal.status.charAt(0).toUpperCase() + proposal.status.slice(1)}
        </Badge>
        {proposal.sent_at && (
          <span className="ml-2 text-sm text-gray-500">
            Sent on {formatDate(proposal.sent_at)}
          </span>
        )}
      </div>

      {/* Customer Information */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Customer Information</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-sm text-gray-500">Name</p>
              <p className="font-medium">{proposal.customers?.name || 'No customer'}</p>
            </div>
            <div>
              <p className="text-sm text-gray-500">Email</p>
              <p className="font-medium">{proposal.customers?.email || '-'}</p>
            </div>
            <div>
              <p className="text-sm text-gray-500">Phone</p>
              <p className="font-medium">{proposal.customers?.phone || '-'}</p>
            </div>
            <div>
              <p className="text-sm text-gray-500">Address</p>
              <p className="font-medium">{proposal.customers?.address || '-'}</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Services */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Services</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {proposal.proposal_items?.filter((item: any) => !item.is_addon).map((item: any) => (
              <div key={item.id} className="flex justify-between items-start">
                <div className="flex-1">
                  <h4 className="font-medium">{item.name}</h4>
                  {item.description && (
                    <p className="text-sm text-gray-600">{item.description}</p>
                  )}
                  <p className="text-sm text-gray-500">Qty: {item.quantity} × {formatCurrency(item.unit_price)}</p>
                </div>
                <p className="font-medium">{formatCurrency(item.total_price)}</p>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Optional Add-ons */}
      {proposal.proposal_items?.some((item: any) => item.is_addon) && (
        <Card className="mb-6">
          <CardHeader>
            <CardTitle>Optional Add-ons</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {proposal.proposal_items.filter((item: any) => item.is_addon).map((item: any) => (
                <div key={item.id} className="flex justify-between items-start">
                  <div className="flex-1">
                    <h4 className="font-medium">{item.name}</h4>
                    {item.description && (
                      <p className="text-sm text-gray-600">{item.description}</p>
                    )}
                    <p className="text-sm text-gray-500">Qty: {item.quantity} × {formatCurrency(item.unit_price)}</p>
                  </div>
                  <p className="font-medium">{formatCurrency(item.total_price)}</p>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Totals */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Totals</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            <div className="flex justify-between">
              <span>Subtotal:</span>
              <span>{formatCurrency(proposal.subtotal || 0)}</span>
            </div>
            <div className="flex justify-between">
              <span>Tax ({((proposal.tax_rate || 0) * 100).toFixed(1)}%):</span>
              <span>{formatCurrency(proposal.tax_amount || 0)}</span>
            </div>
            <div className="flex justify-between font-bold text-lg border-t pt-2">
              <span>Total:</span>
              <span>{formatCurrency(proposal.total || 0)}</span>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Payment Progress - Show for approved proposals */}
      {(proposal.status === 'approved' || proposal.status === 'deposit_paid' || 
        proposal.status === 'progress_paid' || proposal.status === 'final_paid') && (
        <div className="mt-6">
          <PaymentStages 
            depositPaidAt={proposal.deposit_paid_at}
            progressPaidAt={proposal.progress_paid_at}
            finalPaidAt={proposal.final_paid_at}
            depositAmount={proposal.deposit_amount || 0}
            progressPaymentAmount={proposal.progress_payment_amount || 0}
            finalPaymentAmount={proposal.final_payment_amount || 0}
            currentStage={
              proposal.final_paid_at ? 'complete' :
              proposal.progress_paid_at ? 'final' :
              proposal.deposit_paid_at ? 'roughin' : 'deposit'
            }
          />
        </div>
      )}

      {/* Send Proposal Modal */}
      {showSendModal && (
        <SendProposal
          proposalId={proposal.id}
          proposalNumber={proposal.proposal_number}
          customerEmail={proposal.customers?.email}
          customerName={proposal.customers?.name}
          total={proposal.total}
          onClose={() => setShowSendModal(false)}
          onSuccess={handleSendSuccess}
        />
      )}

      {/* Create Job Modal */}
      {showCreateJobModal && (
        <CreateJobModal
          proposal={proposal}
          isOpen={showCreateJobModal}
          onClose={() => setShowCreateJobModal(false)}
        />
      )}
    </div>
  )
}
EOF

# Build test
echo "Testing build..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app
npm run build 2>&1 | head -80

if [ $? -eq 0 ]; then
  echo "Build successful!"
  
  # Commit and push
  git add -A
  git commit -m "Enhanced Create Job button with modal view and pre-filled proposal data"
  git push origin main
  
  echo "✅ Successfully enhanced Create Job functionality!"
  echo "- Opens in modal dialog instead of navigating to new page"
  echo "- Pre-fills all fields with proposal data"
  echo "- Automatically detects job type from proposal content"
  echo "- Customer field pre-selected and locked"
  echo "- Includes proposal summary in the modal"
  echo "- Technician assignment available"
  echo "- Navigates to job page after creation"
else
  echo "❌ Build failed. Please check the errors above."
  exit 1
fi
