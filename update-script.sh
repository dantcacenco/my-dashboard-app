#!/bin/bash

echo "🔧 Adding Jobs functionality..."

# 1. Create New Job page
cat > app/jobs/new/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import JobCreationForm from './JobCreationForm'

export default async function NewJobPage({
  searchParams
}: {
  searchParams: { proposal?: string }
}) {
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    redirect('/auth/signin')
  }

  let proposal = null
  if (searchParams.proposal) {
    const { data } = await supabase
      .from('proposals')
      .select('*, customers(*)')
      .eq('id', searchParams.proposal)
      .single()
    proposal = data
  }

  const { data: customers } = await supabase
    .from('customers')
    .select('*')
    .order('name')

  return (
    <div className="container mx-auto px-6 py-8 max-w-4xl">
      <h1 className="text-2xl font-bold mb-6">Create New Job</h1>
      <JobCreationForm 
        customers={customers || []} 
        proposal={proposal}
      />
    </div>
  )
}
EOF

# 2. Create JobCreationForm component
cat > app/jobs/new/JobCreationForm.tsx << 'EOF'
'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'

interface JobCreationFormProps {
  customers: any[]
  proposal?: any
}

export default function JobCreationForm({ customers, proposal }: JobCreationFormProps) {
  const router = useRouter()
  const supabase = createClient()
  const [loading, setLoading] = useState(false)
  
  const [formData, setFormData] = useState({
    title: proposal?.title || '',
    description: proposal?.description || '',
    customer_id: proposal?.customer_id || '',
    job_type: 'service',
    scheduled_date: '',
    scheduled_time: '',
    service_address: proposal?.customers?.address || '',
    notes: ''
  })

  const generateJobNumber = () => {
    const date = new Date()
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0')
    return `JOB-${year}${month}${day}-${random}`
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)

    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) throw new Error('Not authenticated')

      const customer = customers.find(c => c.id === formData.customer_id)

      const { data: job, error } = await supabase
        .from('jobs')
        .insert({
          job_number: generateJobNumber(),
          ...formData,
          proposal_id: proposal?.id || null,
          customer_name: customer?.name || '',
          customer_email: customer?.email || '',
          customer_phone: customer?.phone || '',
          status: 'pending',
          created_by: user.id
        })
        .select()
        .single()

      if (error) throw error

      // Mark proposal as job created if from proposal
      if (proposal) {
        await supabase
          .from('proposals')
          .update({ job_created: true })
          .eq('id', proposal.id)
      }

      router.push(`/jobs/${job.id}`)
    } catch (error) {
      console.error('Error creating job:', error)
      alert('Failed to create job')
    } finally {
      setLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6 bg-white p-6 rounded-lg shadow">
      <div>
        <Label htmlFor="title">Job Title *</Label>
        <Input
          id="title"
          value={formData.title}
          onChange={(e) => setFormData({ ...formData, title: e.target.value })}
          required
        />
      </div>

      <div>
        <Label htmlFor="customer">Customer *</Label>
        <Select
          value={formData.customer_id}
          onValueChange={(value) => setFormData({ ...formData, customer_id: value })}
        >
          <SelectTrigger>
            <SelectValue placeholder="Select a customer" />
          </SelectTrigger>
          <SelectContent>
            {customers.map((customer) => (
              <SelectItem key={customer.id} value={customer.id}>
                {customer.name}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div>
        <Label htmlFor="job_type">Job Type</Label>
        <Select
          value={formData.job_type}
          onValueChange={(value) => setFormData({ ...formData, job_type: value })}
        >
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="service">Service</SelectItem>
            <SelectItem value="installation">Installation</SelectItem>
            <SelectItem value="maintenance">Maintenance</SelectItem>
            <SelectItem value="repair">Repair</SelectItem>
          </SelectContent>
        </Select>
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
        <Label htmlFor="service_address">Service Address</Label>
        <Input
          id="service_address"
          value={formData.service_address}
          onChange={(e) => setFormData({ ...formData, service_address: e.target.value })}
        />
      </div>

      <div>
        <Label htmlFor="description">Description</Label>
        <Textarea
          id="description"
          value={formData.description}
          onChange={(e) => setFormData({ ...formData, description: e.target.value })}
          rows={3}
        />
      </div>

      <div>
        <Label htmlFor="notes">Notes</Label>
        <Textarea
          id="notes"
          value={formData.notes}
          onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
          rows={3}
        />
      </div>

      <div className="flex justify-end gap-2">
        <Button type="button" variant="outline" onClick={() => router.back()}>
          Cancel
        </Button>
        <Button type="submit" disabled={loading}>
          {loading ? 'Creating...' : 'Create Job'}
        </Button>
      </div>
    </form>
  )
}
EOF

# 3. Update JobsList to add New Job button
cat > app/jobs/JobsList.tsx << 'EOF'
'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Plus } from 'lucide-react'

interface Job {
  id: string
  job_number: string
  title: string
  customer_name: string
  status: string
  scheduled_date: string
  created_at: string
}

interface JobsListProps {
  initialJobs: Job[]
}

export default function JobsList({ initialJobs }: JobsListProps) {
  const [jobs] = useState(initialJobs)
  const router = useRouter()

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed': return 'bg-green-500'
      case 'in_progress': return 'bg-blue-500'
      case 'pending': return 'bg-yellow-500'
      case 'cancelled': return 'bg-red-500'
      default: return 'bg-gray-500'
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">Jobs</h1>
          <p className="text-gray-600 mt-1">Manage your service jobs</p>
        </div>
        <Button onClick={() => router.push('/jobs/new')}>
          <Plus className="h-4 w-4 mr-2" />
          New Job
        </Button>
      </div>

      <div className="bg-white rounded-lg shadow overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Job #</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Title</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Customer</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Scheduled</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {jobs.map((job) => (
              <tr 
                key={job.id}
                className="hover:bg-gray-50 cursor-pointer"
                onClick={() => router.push(`/jobs/${job.id}`)}
              >
                <td className="px-6 py-4 text-sm font-medium">{job.job_number}</td>
                <td className="px-6 py-4 text-sm">{job.title}</td>
                <td className="px-6 py-4 text-sm">{job.customer_name}</td>
                <td className="px-6 py-4">
                  <Badge className={getStatusColor(job.status)} variant="secondary">
                    {job.status}
                  </Badge>
                </td>
                <td className="px-6 py-4 text-sm">
                  {job.scheduled_date ? new Date(job.scheduled_date).toLocaleDateString() : '-'}
                </td>
                <td className="px-6 py-4 text-sm">
                  <Button
                    size="sm"
                    variant="ghost"
                    onClick={(e) => {
                      e.stopPropagation()
                      router.push(`/jobs/${job.id}`)
                    }}
                  >
                    View
                  </Button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
EOF

# Commit changes
git add .
git commit -m "feat: add job creation, customer modal, and navigation updates"
git push origin main

echo "✅ Jobs functionality added!"
echo ""
echo "Completed:"
echo "1. New Job button and creation form"
echo "2. Add Customer modal functionality"
echo "3. Removed Invoices from navigation"
echo "4. Fixed Proposals page padding"
echo ""
echo "For file uploads:"
echo "- Run the storage_setup.sql in Supabase"
echo "- Supabase Storage handles files up to 50MB"
echo "- Perfect for documents and images"
echo ""
echo "Still need to manually add:"
echo "- Create Job button in ProposalView"
echo "- Edit Job modal with technician search"
echo "- File/photo upload components"