'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { toast } from 'sonner'
import { ArrowLeft, Loader2, Plus } from 'lucide-react'
import Link from 'next/link'

interface NewJobFormProps {
  customers: any[]
  proposals: any[]
  technicians: any[]
  userId: string
}

export default function NewJobForm({ customers, proposals, technicians, userId }: NewJobFormProps) {
  const router = useRouter()
  const supabase = createClient()
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [selectedTechnicians, setSelectedTechnicians] = useState<string[]>([])
  
  const [formData, setFormData] = useState({
    customer_id: '',
    proposal_id: '',
    title: '',
    description: '',
    job_type: 'repair',
    status: 'scheduled',
    service_address: '',
    scheduled_date: '',
    scheduled_time: '',
    total_value: '',
    notes: ''
  })

  // Debug logging on mount
  useEffect(() => {
    console.log('NewJobForm mounted with:', {
      customersCount: customers.length,
      proposalsCount: proposals.length,
      techniciansCount: technicians.length,
      userId: userId
    })
  }, [])

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  const handleCustomerChange = (customerId: string) => {
    console.log('Customer changed:', customerId)
    const customer = customers.find(c => c.id === customerId)
    if (customer) {
      setFormData(prev => ({
        ...prev,
        customer_id: customerId,
        service_address: customer.address || ''
      }))
    }
  }

  const handleProposalChange = (proposalId: string) => {
    console.log('Proposal changed:', proposalId)
    
    if (!proposalId) {
      setFormData(prev => ({
        ...prev,
        proposal_id: '',
        title: '',
        description: '',
        total_value: ''
      }))
      return
    }
    
    const proposal = proposals.find(p => p.id === proposalId)
    
    if (proposal) {
      const selectedItems = proposal.proposal_items?.filter((item: any) => 
        item.is_selected !== false
      ) || []
      
      const description = selectedItems.map((item: any) => 
        `${item.quantity}x ${item.name}${item.description ? ': ' + item.description : ''}`
      ).join('\n')

      const newFormData = {
        ...formData,
        proposal_id: proposalId,
        customer_id: proposal.customer_id,
        title: proposal.title || '',
        description: description,
        total_value: proposal.total?.toString() || '0',
        service_address: proposal.customers?.address || ''
      }
      
      console.log('Setting form data from proposal:', newFormData)
      setFormData(newFormData)
      
      if (proposal.customer_id) {
        handleCustomerChange(proposal.customer_id)
      }
    }
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
    
    console.log('=== SUBMITTING JOB ===')
    console.log('Form data:', formData)
    console.log('Selected technicians:', selectedTechnicians)
    console.log('User ID:', userId)
    
    // Validation
    if (!formData.customer_id) {
      console.error('No customer selected')
      toast.error('Please select a customer')
      return
    }
    
    if (!formData.title) {
      console.error('No job title')
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
      
      console.log('Sending request to /api/jobs:', requestBody)
      
      const response = await fetch('/api/jobs', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(requestBody)
      })

      console.log('Response status:', response.status)
      const data = await response.json()
      console.log('Response data:', data)

      if (!response.ok) {
        console.error('API error:', data)
        throw new Error(data.error || data.details || 'Failed to create job')
      }

      if (!data.job || !data.job.id) {
        console.error('No job ID in response:', data)
        throw new Error('Job created but no ID returned')
      }

      console.log('Job created successfully:', data.job)
      toast.success(`Job ${data.job.job_number} created successfully!`)
      
      // Navigate to the new job
      console.log('Navigating to:', `/jobs/${data.job.id}`)
      router.push(`/jobs/${data.job.id}`)
      
    } catch (error: any) {
      console.error('=== JOB CREATION ERROR ===')
      console.error('Error details:', error)
      console.error('Error message:', error.message)
      console.error('Error stack:', error.stack)
      
      toast.error(error.message || 'Failed to create job')
      setIsSubmitting(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <div className="flex items-center gap-4 mb-6">
        <Link href="/jobs">
          <button
            type="button"
            className="flex items-center gap-2 text-gray-600 hover:text-gray-900"
          >
            <ArrowLeft className="h-4 w-4" />
            Back to Jobs
          </button>
        </Link>
      </div>

      {/* Debug Info Box */}
      <div className="bg-yellow-50 border border-yellow-200 rounded p-3 text-xs">
        <div className="font-bold mb-1">Debug Info (Remove in production):</div>
        <div>Customer ID: {formData.customer_id || 'Not selected'}</div>
        <div>Title: {formData.title || 'Empty'}</div>
        <div>Technicians: {selectedTechnicians.length} selected</div>
        <button
          type="button"
          onClick={() => console.log('Current form state:', { formData, selectedTechnicians })}
          className="mt-1 px-2 py-1 bg-yellow-200 rounded text-xs"
        >
          Log Form State to Console
        </button>
      </div>

      {/* Link to Proposal */}
      <div className="bg-blue-50 p-4 rounded-lg">
        <h3 className="font-medium mb-3">Link to Proposal (Optional)</h3>
        <select
          value={formData.proposal_id}
          onChange={(e) => handleProposalChange(e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-md"
        >
          <option value="">No proposal linked</option>
          {proposals.map((proposal) => (
            <option key={proposal.id} value={proposal.id}>
              {proposal.proposal_number} - {proposal.title} | {proposal.customers?.address || 'No address'} | {formatCurrency(proposal.total || 0)}
            </option>
          ))}
        </select>
      </div>

      {/* Customer Selection */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">
          Customer * <span className="text-red-500">(Required)</span>
        </label>
        <select
          required
          value={formData.customer_id}
          onChange={(e) => handleCustomerChange(e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-md"
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
          Job Title * <span className="text-red-500">(Required)</span>
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
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
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
          Total Value ($)
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
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
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
      <div>
        <h3 className="font-medium mb-3">
          Assign Technicians 
          <span className="text-sm text-gray-500 ml-2">
            ({technicians?.length || 0} available)
          </span>
        </h3>
        <div className="space-y-2 max-h-48 overflow-y-auto border rounded-lg p-3">
          {technicians && technicians.length > 0 ? (
            technicians.map((tech) => (
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
            ))
          ) : (
            <p className="text-sm text-gray-500">No active technicians found</p>
          )}
        </div>
        {selectedTechnicians.length > 0 && (
          <p className="text-sm text-gray-600 mt-2">
            {selectedTechnicians.length} technician(s) selected
          </p>
        )}
      </div>

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

      {/* Submit Buttons */}
      <div className="flex justify-end gap-3 pt-4">
        <Link href="/jobs">
          <button
            type="button"
            className="px-4 py-2 text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-md"
          >
            Cancel
          </button>
        </Link>
        <button
          type="submit"
          disabled={isSubmitting || !formData.customer_id || !formData.title}
          className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
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
        </button>
      </div>
    </form>
  )
}
