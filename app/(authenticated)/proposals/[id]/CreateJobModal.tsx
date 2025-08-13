'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { X, Briefcase, Loader2 } from 'lucide-react'
import { toast } from 'sonner'
import { useRouter } from 'next/navigation'
import TechnicianSearch from '@/components/technician/TechnicianSearch'

interface CreateJobModalProps {
  proposal: any
  onClose: () => void
}

export default function CreateJobModal({ proposal, onClose }: CreateJobModalProps) {
  const router = useRouter()
  const [isCreating, setIsCreating] = useState(false)
  const [selectedTechnicians, setSelectedTechnicians] = useState<any[]>([])
  const [formData, setFormData] = useState({
    title: proposal.title || 'HVAC System Installation',
    job_type: 'installation',
    service_address: proposal.customers?.[0]?.address || '',
    service_city: proposal.customers?.[0]?.city || '',
    service_state: proposal.customers?.[0]?.state || '',
    service_zip: proposal.customers?.[0]?.zip || '',
    scheduled_date: '',
    scheduled_time: '',
    notes: ''
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsCreating(true)

    try {
      const response = await fetch('/api/jobs/create-from-proposal', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          proposalId: proposal.id,
          jobData: formData,
          technicianIds: selectedTechnicians.map(t => t.id)
        })
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Failed to create job')
      }

      toast.success(`Job ${data.jobNumber} created successfully!`)
      router.push(`/jobs/${data.jobId}`)
    } catch (error: any) {
      toast.error(error.message || 'Failed to create job')
      setIsCreating(false)
    }
  }

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-semibold">Create Job from Proposal</h2>
          <button onClick={onClose} className="text-gray-500 hover:text-gray-700">
            <X className="h-5 w-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <Label>Customer</Label>
            <div className="p-3 bg-gray-50 rounded-md">
              <div className="font-medium">{proposal.customers?.[0]?.name || 'No customer'}</div>
              <div className="text-sm text-gray-600">{proposal.customers?.[0]?.email}</div>
            </div>
          </div>

          <div>
            <Label htmlFor="title">Job Title</Label>
            <Input
              id="title"
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              required
            />
          </div>

          <div>
            <Label htmlFor="job_type">Job Type</Label>
            <select
              id="job_type"
              className="w-full px-3 py-2 border rounded-md"
              value={formData.job_type}
              onChange={(e) => setFormData({ ...formData, job_type: e.target.value })}
            >
              <option value="installation">Installation</option>
              <option value="repair">Repair</option>
              <option value="maintenance">Maintenance</option>
              <option value="inspection">Inspection</option>
            </select>
          </div>

          <div>
            <Label>Service Address</Label>
            <Input
              value={formData.service_address}
              onChange={(e) => setFormData({ ...formData, service_address: e.target.value })}
              placeholder="123 Main St"
            />
            <div className="grid grid-cols-3 gap-2 mt-2">
              <Input
                value={formData.service_city}
                onChange={(e) => setFormData({ ...formData, service_city: e.target.value })}
                placeholder="City"
              />
              <Input
                value={formData.service_state}
                onChange={(e) => setFormData({ ...formData, service_state: e.target.value })}
                placeholder="State"
              />
              <Input
                value={formData.service_zip}
                onChange={(e) => setFormData({ ...formData, service_zip: e.target.value })}
                placeholder="ZIP"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="scheduled_date">Scheduled Date</Label>
              <Input
                id="scheduled_date"
                type="date"
                value={formData.scheduled_date}
                onChange={(e) => setFormData({ ...formData, scheduled_date: e.target.value })}
              />
            </div>
            <div>
              <Label htmlFor="scheduled_time">Scheduled Time</Label>
              <Input
                id="scheduled_time"
                type="time"
                value={formData.scheduled_time}
                onChange={(e) => setFormData({ ...formData, scheduled_time: e.target.value })}
              />
            </div>
          </div>

          <div>
            <Label>Assign Technicians</Label>
            <TechnicianSearch
              selectedTechnicians={selectedTechnicians}
              onAddTechnician={(tech) => setSelectedTechnicians([...selectedTechnicians, tech])}
              onRemoveTechnician={(id) => setSelectedTechnicians(selectedTechnicians.filter(t => t.id !== id))}
            />
          </div>

          <div>
            <Label htmlFor="notes">Notes</Label>
            <textarea
              id="notes"
              className="w-full px-3 py-2 border rounded-md"
              rows={3}
              value={formData.notes}
              onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
              placeholder="Additional notes..."
            />
          </div>

          <div className="flex gap-3 pt-4">
            <Button type="button" variant="outline" onClick={onClose} className="flex-1">
              Cancel
            </Button>
            <Button type="submit" className="flex-1" disabled={isCreating}>
              {isCreating ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Creating Job...
                </>
              ) : (
                <>
                  <Briefcase className="h-4 w-4 mr-2" />
                  Create Job
                </>
              )}
            </Button>
          </div>
        </form>
      </div>
    </div>
  )
}
