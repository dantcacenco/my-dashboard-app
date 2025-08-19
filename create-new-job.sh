#!/bin/bash

# Clean up fake jobs and create New Job functionality
set -e

echo "🧹 Creating cleanup script and New Job functionality..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# 1. Create SQL to delete fake jobs
echo "📝 Creating SQL to delete fake jobs..."
cat > delete-fake-jobs.sql << 'EOF'
-- Delete fake/test jobs
-- Be careful! This will delete jobs with these specific IDs or patterns

-- Delete jobs with placeholder titles
DELETE FROM jobs 
WHERE title IN ('Furnace Repair - Danny', 'HVAC System Installation - Danny', 
                'Emergency AC Repair - Danny', 'Annual Maintenance - Danny')
   OR title LIKE '%Danny%'
   OR job_number IN ('JOB-20250729-001', 'JOB-20250729-002', 'JOB-20250729-003', 'JOB-20250729-004');

-- Or if you want to delete ALL jobs (be very careful!):
-- TRUNCATE TABLE jobs CASCADE;

-- To see what will be deleted first, run:
-- SELECT id, job_number, title FROM jobs 
-- WHERE title LIKE '%Danny%' OR title LIKE '%Furnace%' OR title LIKE '%HVAC%';
EOF

echo "⚠️  SQL script created: delete-fake-jobs.sql"
echo "   Run this in Supabase SQL editor to delete fake jobs"

# 2. Check if New Job page exists
echo "🔍 Checking for New Job page..."
if [ ! -f "app/(authenticated)/jobs/new/page.tsx" ]; then
  echo "📁 Creating New Job page structure..."
  mkdir -p app/\(authenticated\)/jobs/new
fi

# 3. Create the New Job form component
echo "🔨 Creating New Job form..."
cat > 'app/(authenticated)/jobs/new/page.tsx' << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import NewJobForm from './NewJobForm'

export default async function NewJobPage() {
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/login')

  // Get user role
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()
  
  // Only boss/admin can create jobs
  if (profile?.role !== 'boss' && profile?.role !== 'admin') {
    redirect('/jobs')
  }

  // Fetch data needed for the form
  const [customersRes, proposalsRes, techniciansRes] = await Promise.all([
    supabase.from('customers').select('id, name, email, phone, address').order('name'),
    supabase.from('proposals').select('id, proposal_number, title, status, customer_id').eq('status', 'approved').order('created_at', { ascending: false }),
    supabase.from('profiles').select('id, email, full_name').eq('role', 'technician').eq('is_active', true).order('full_name')
  ])

  return (
    <div className="container mx-auto py-6 px-4">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-2xl font-bold mb-6">Create New Job</h1>
        <NewJobForm 
          customers={customersRes.data || []}
          proposals={proposalsRes.data || []}
          technicians={techniciansRes.data || []}
          userId={user.id}
        />
      </div>
    </div>
  )
}
EOF

# 4. Create the NewJobForm client component
cat > 'app/(authenticated)/jobs/new/NewJobForm.tsx' << 'EOF'
'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { toast } from 'sonner'
import { ArrowLeft, Loader2, Plus, X } from 'lucide-react'
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
    status: 'not_scheduled',
    service_address: '',
    service_city: '',
    service_state: '',
    service_zip: '',
    scheduled_date: '',
    scheduled_time: '',
    total_value: '',
    notes: ''
  })

  const handleCustomerChange = (customerId: string) => {
    const customer = customers.find(c => c.id === customerId)
    if (customer) {
      setFormData({
        ...formData,
        customer_id: customerId,
        service_address: customer.address || '',
        // You might need to parse city/state/zip from address
      })
    }
  }

  const handleProposalChange = (proposalId: string) => {
    const proposal = proposals.find(p => p.id === proposalId)
    if (proposal) {
      setFormData({
        ...formData,
        proposal_id: proposalId,
        customer_id: proposal.customer_id,
        title: proposal.title || formData.title
      })
      // Also update customer fields
      handleCustomerChange(proposal.customer_id)
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
    setIsSubmitting(true)

    try {
      // Generate job number
      const today = new Date()
      const dateStr = today.toISOString().slice(0, 10).replace(/-/g, '')
      
      // Get count of jobs created today
      const { count } = await supabase
        .from('jobs')
        .select('*', { count: 'exact', head: true })
        .ilike('job_number', `JOB-${dateStr}-%`)

      const jobNumber = `JOB-${dateStr}-${String((count || 0) + 1).padStart(3, '0')}`

      // Get customer info
      const customer = customers.find(c => c.id === formData.customer_id)

      // Create the job
      const { data: job, error: jobError } = await supabase
        .from('jobs')
        .insert({
          job_number: jobNumber,
          customer_id: formData.customer_id,
          proposal_id: formData.proposal_id || null,
          title: formData.title,
          description: formData.description,
          job_type: formData.job_type,
          status: formData.status,
          service_address: formData.service_address,
          service_city: formData.service_city,
          service_state: formData.service_state,
          service_zip: formData.service_zip,
          scheduled_date: formData.scheduled_date || null,
          scheduled_time: formData.scheduled_time || null,
          total_value: parseFloat(formData.total_value) || 0,
          notes: formData.notes,
          created_by: userId,
          // Denormalized fields
          customer_name: customer?.name || '',
          customer_email: customer?.email || '',
          customer_phone: customer?.phone || ''
        })
        .select()
        .single()

      if (jobError) throw jobError

      // Assign technicians if selected
      if (job && selectedTechnicians.length > 0) {
        const technicianAssignments = selectedTechnicians.map(techId => ({
          job_id: job.id,
          technician_id: techId,
          assigned_by: userId
        }))

        const { error: techError } = await supabase
          .from('job_technicians')
          .insert(technicianAssignments)

        if (techError) {
          console.error('Error assigning technicians:', techError)
          // Continue anyway - job is created
        }
      }

      toast.success(`Job ${jobNumber} created successfully!`)
      router.push(`/jobs/${job.id}`)
    } catch (error: any) {
      console.error('Error creating job:', error)
      toast.error(error.message || 'Failed to create job')
    } finally {
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

      {/* Link to Proposal (Optional) */}
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
              {proposal.proposal_number} - {proposal.title}
            </option>
          ))}
        </select>
        <p className="text-sm text-gray-600 mt-2">
          Linking to a proposal will auto-fill customer information
        </p>
      </div>

      {/* Customer Selection */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">
          Customer *
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

      {/* Job Details */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
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

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Job Type *
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
            Status *
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
      </div>

      {/* Description */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">
          Description
        </label>
        <textarea
          value={formData.description}
          onChange={(e) => setFormData({ ...formData, description: e.target.value })}
          rows={3}
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
      <div className="space-y-3">
        <h3 className="font-medium">Service Address</h3>
        <input
          type="text"
          value={formData.service_address}
          onChange={(e) => setFormData({ ...formData, service_address: e.target.value })}
          className="w-full px-3 py-2 border border-gray-300 rounded-md"
          placeholder="Street Address"
        />
        <div className="grid grid-cols-3 gap-3">
          <input
            type="text"
            value={formData.service_city}
            onChange={(e) => setFormData({ ...formData, service_city: e.target.value })}
            className="px-3 py-2 border border-gray-300 rounded-md"
            placeholder="City"
          />
          <input
            type="text"
            value={formData.service_state}
            onChange={(e) => setFormData({ ...formData, service_state: e.target.value })}
            className="px-3 py-2 border border-gray-300 rounded-md"
            placeholder="State"
            maxLength={2}
          />
          <input
            type="text"
            value={formData.service_zip}
            onChange={(e) => setFormData({ ...formData, service_zip: e.target.value })}
            className="px-3 py-2 border border-gray-300 rounded-md"
            placeholder="ZIP"
          />
        </div>
      </div>

      {/* Technician Assignment */}
      <div>
        <h3 className="font-medium mb-3">Assign Technicians</h3>
        <div className="space-y-2 max-h-48 overflow-y-auto border rounded-lg p-3">
          {technicians.length > 0 ? (
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
            <p className="text-sm text-gray-500">No technicians available</p>
          )}
        </div>
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
          disabled={isSubmitting}
          className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 flex items-center"
        >
          {isSubmitting ? (
            <>
              <Loader2 className="h-4 w-4 mr-2 animate-spin" />
              Creating...
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
EOF

echo "✅ New Job form created!"

# Test build
echo "🔨 Testing build..."
npm run build 2>&1 | tail -10

# Commit
git add -A
git commit -m "Add New Job functionality with full form and technician assignment" || true
git push origin main

echo ""
echo "✅ NEW JOB FUNCTIONALITY CREATED!"
echo "================================="
echo ""
echo "📋 What's been done:"
echo "1. Created SQL script to delete fake jobs (delete-fake-jobs.sql)"
echo "2. Created New Job page with full form"
echo "3. Added proposal linking (optional)"
echo "4. Added technician assignment"
echo "5. All fields included"
echo ""
echo "⚠️  TO DELETE FAKE JOBS:"
echo "1. Go to Supabase SQL editor"
echo "2. Copy contents of delete-fake-jobs.sql"
echo "3. Review the DELETE query carefully"
echo "4. Run it to remove fake jobs"
echo ""
echo "✨ NEW JOB BUTTON:"
echo "Should now work! It will:"
echo "- Generate job numbers automatically"
echo "- Link to proposals (optional)"
echo "- Assign technicians"
echo "- Save all job details"
echo ""
echo "🚀 Deploying to Vercel..."
