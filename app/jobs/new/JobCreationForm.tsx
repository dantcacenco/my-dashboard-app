'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { ArrowLeft, Save } from 'lucide-react'
import Link from 'next/link'

interface JobCreationFormProps {
  proposal: any
  technicians: any[]
  customers: any[]
  userId: string
}

export default function JobCreationForm({ 
  proposal, 
  technicians, 
  customers,
  userId 
}: JobCreationFormProps) {
  const router = useRouter()
  const supabase = createClient()
  
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [formData, setFormData] = useState({
    customer_id: proposal?.customer_id || '',
    proposal_id: proposal?.id || null,
    title: proposal?.title || '',
    description: proposal?.description || '',
    job_type: 'installation',
    assigned_technician_id: '',
    scheduled_date: '',
    scheduled_time: '',
    service_address: proposal?.customers?.address || '',
    service_city: '',
    service_state: '',
    service_zip: '',
    boss_notes: ''
  })

  const generateJobNumber = () => {
    const now = new Date()
    const year = now.getFullYear()
    const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0')
    return `JOB-${year}-${random}`
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsSubmitting(true)

    try {
      // Create the job
      const { data: job, error } = await supabase
        .from('jobs')
        .insert({
          ...formData,
          job_number: generateJobNumber(),
          status: 'scheduled',
          created_by: userId,
          estimated_duration: '4 hours' // Default
        })
        .select()
        .single()

      if (error) throw error

      // Update proposal to mark job as created
      if (proposal) {
        await supabase
          .from('proposals')
          .update({ job_created: true })
          .eq('id', proposal.id)
      }

      // Log activity
      await supabase
        .from('job_activity_log')
        .insert({
          job_id: job.id,
          user_id: userId,
          activity_type: 'job_created',
          description: 'Job created from proposal'
        })

      // Navigate to job detail page
      router.push(`/jobs/${job.id}`)
    } catch (error: any) {
      console.error('Error creating job:', error)
      alert('Failed to create job: ' + error.message)
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      <div className="mb-6">
        <Link
          href={proposal ? `/proposals/${proposal.id}` : '/jobs'}
          className="inline-flex items-center text-sm text-gray-600 hover:text-gray-900"
        >
          <ArrowLeft className="h-4 w-4 mr-1" />
          Back to {proposal ? 'Proposal' : 'Jobs'}
        </Link>
      </div>

      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Job Details</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Customer *
              </label>
              <select
                value={formData.customer_id}
                onChange={(e) => setFormData({ ...formData, customer_id: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md"
                required
                disabled={!!proposal}
              >
                <option value="">Select a customer</option>
                {proposal ? (
                  <option value={proposal.customer_id}>
                    {proposal.customers.name}
                  </option>
                ) : (
                  customers.map((customer) => (
                    <option key={customer.id} value={customer.id}>
                      {customer.name}
                    </option>
                  ))
                )}
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Job Type *
              </label>
              <select
                value={formData.job_type}
                onChange={(e) => setFormData({ ...formData, job_type: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md"
                required
              >
                <option value="installation">Installation</option>
                <option value="repair">Repair</option>
                <option value="maintenance">Maintenance</option>
                <option value="emergency">Emergency</option>
              </select>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Title *
            </label>
            <input
              type="text"
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-md"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Description
            </label>
            <textarea
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              rows={3}
              className="w-full px-3 py-2 border border-gray-300 rounded-md"
            />
          </div>
        </CardContent>
      </Card>

      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Assignment & Scheduling</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Assigned Technician
            </label>
            <select
              value={formData.assigned_technician_id}
              onChange={(e) => setFormData({ ...formData, assigned_technician_id: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-md"
            >
              <option value="">Unassigned</option>
              {technicians.map((tech) => (
                <option key={tech.id} value={tech.id}>
                  {tech.full_name || tech.email}
                </option>
              ))}
            </select>
          </div>

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
        </CardContent>
      </Card>

      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Service Address</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Street Address
            </label>
            <input
              type="text"
              value={formData.service_address}
              onChange={(e) => setFormData({ ...formData, service_address: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-md"
            />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                City
              </label>
              <input
                type="text"
                value={formData.service_city}
                onChange={(e) => setFormData({ ...formData, service_city: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                State
              </label>
              <input
                type="text"
                value={formData.service_state}
                onChange={(e) => setFormData({ ...formData, service_state: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md"
                maxLength={2}
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                ZIP Code
              </label>
              <input
                type="text"
                value={formData.service_zip}
                onChange={(e) => setFormData({ ...formData, service_zip: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md"
                maxLength={10}
              />
            </div>
          </div>
        </CardContent>
      </Card>

      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Notes for Technician</CardTitle>
        </CardHeader>
        <CardContent>
          <textarea
            value={formData.boss_notes}
            onChange={(e) => setFormData({ ...formData, boss_notes: e.target.value })}
            rows={4}
            placeholder="Any special instructions or notes for the technician..."
            className="w-full px-3 py-2 border border-gray-300 rounded-md"
          />
        </CardContent>
      </Card>

      <div className="flex justify-end gap-3">
        <Button
          type="button"
          variant="outline"
          onClick={() => router.back()}
        >
          Cancel
        </Button>
        <Button
          type="submit"
          disabled={isSubmitting}
        >
          <Save className="h-4 w-4 mr-1" />
          {isSubmitting ? 'Creating...' : 'Create Job'}
        </Button>
      </div>
    </form>
  )
}
