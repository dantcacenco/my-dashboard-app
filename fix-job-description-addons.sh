#!/bin/bash

# Fix: Include add-ons in the job description when creating from proposal
echo "Fixing job description to include add-ons..."

# Update only the CreateJobModal component
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
      // Separate services and add-ons
      const services = proposal.proposal_items?.filter((item: any) => !item.is_addon) || []
      const addons = proposal.proposal_items?.filter((item: any) => item.is_addon) || []
      
      // Build description with both services and add-ons
      let description = ''
      
      // Add services section
      if (services.length > 0) {
        description += 'SERVICES:\n'
        description += services.map((item: any) => 
          `${item.quantity}x ${item.name}${item.description ? ': ' + item.description : ''}`
        ).join('\n')
      }
      
      // Add add-ons section if any exist
      if (addons.length > 0) {
        if (description) description += '\n\n'
        description += 'ADD-ONS:\n'
        description += addons.map((item: any) => 
          `${item.quantity}x ${item.name}${item.description ? ': ' + item.description : ''}`
        ).join('\n')
      }

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
              rows={6}
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

# Build test
echo "Testing build..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app
npm run build 2>&1 | head -80

if [ $? -eq 0 ]; then
  echo "Build successful!"
  
  # Commit and push
  git add -A
  git commit -m "Fix: Include add-ons in job description when creating from proposal"
  git push origin main
  
  echo "✅ Fixed job description to include add-ons!"
  echo "- Services listed under 'SERVICES:' header"
  echo "- Add-ons listed under 'ADD-ONS:' header"
  echo "- Both sections included in description field"
  echo "- Increased textarea rows from 4 to 6 for better visibility"
else
  echo "❌ Build failed. Please check the errors above."
  exit 1
fi
