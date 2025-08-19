#!/bin/bash

# Fix Job Form, Technicians, and Payment Issues
echo "🔧 Starting comprehensive fix for job form and payments..."

# 1. Fix the page to fetch all needed proposal data
echo "📝 Fixing new job page to fetch complete proposal data..."
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/\(authenticated\)/jobs/new/page.tsx << 'EOF'
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
    supabase.from('proposals')
      .select(`
        id, 
        proposal_number, 
        title, 
        status, 
        customer_id,
        total,
        customers (
          name,
          address
        ),
        proposal_items (
          name,
          description,
          quantity,
          is_addon,
          is_selected
        )
      `)
      .eq('status', 'approved')
      .order('created_at', { ascending: false }),
    supabase.from('profiles')
      .select('id, email, full_name')
      .eq('role', 'technician')
      .eq('is_active', true)
      .order('full_name')
  ])

  console.log('Technicians fetched:', techniciansRes.data?.length)

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

# 2. Update NewJobForm with all fixes
echo "📝 Rewriting NewJobForm with all improvements..."
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/\(authenticated\)/jobs/new/NewJobForm.tsx << 'EOF'
'use client'

import { useState } from 'react'
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
    status: 'not_scheduled',
    service_address: '',
    scheduled_date: '',
    scheduled_time: '',
    total_value: '',
    notes: ''
  })

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  const handleCustomerChange = (customerId: string) => {
    const customer = customers.find(c => c.id === customerId)
    if (customer) {
      setFormData({
        ...formData,
        customer_id: customerId,
        service_address: customer.address || ''
      })
    }
  }

  const handleProposalChange = (proposalId: string) => {
    const proposal = proposals.find(p => p.id === proposalId)
    if (proposal) {
      // Build description from proposal items
      const selectedItems = proposal.proposal_items?.filter((item: any) => 
        item.is_selected !== false
      ) || []
      
      const description = selectedItems.map((item: any) => 
        `${item.quantity}x ${item.name}${item.description ? ': ' + item.description : ''}`
      ).join('\n')

      setFormData({
        ...formData,
        proposal_id: proposalId,
        customer_id: proposal.customer_id,
        title: proposal.title,
        description: description,
        total_value: proposal.total?.toString() || '',
        service_address: proposal.customers?.address || ''
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
      const response = await fetch('/api/jobs', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          ...formData,
          total_value: parseFloat(formData.total_value) || 0,
          technicianIds: selectedTechnicians
        })
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Failed to create job')
      }

      toast.success(`Job ${data.job.job_number} created successfully!`)
      router.push(`/jobs/${data.job.id}`)
    } catch (error: any) {
      console.error('Error creating job:', error)
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
              {proposal.proposal_number} - {proposal.title} | {proposal.customers?.address || 'No address'} | {formatCurrency(proposal.total || 0)}
            </option>
          ))}
        </select>
        <p className="text-sm text-gray-600 mt-2">
          Linking to a proposal will auto-fill job details
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

      {/* Service Address - SIMPLIFIED TO SINGLE FIELD */}
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

      {/* Technician Assignment - FIXED */}
      <div>
        <h3 className="font-medium mb-3">Assign Technicians</h3>
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
        {technicians && technicians.length > 0 && (
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

# 3. Update the API route to handle simplified address
echo "📝 Updating jobs API route..."
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/api/jobs/route.ts << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function POST(request: Request) {
  try {
    const supabase = await createClient()
    const body = await request.json()

    // Check auth
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    // Validate required fields
    if (!body.customer_id || !body.title) {
      return NextResponse.json({ 
        error: 'Missing required fields: customer_id and title are required' 
      }, { status: 400 })
    }

    // Generate job number
    const today = new Date().toISOString().split('T')[0].replace(/-/g, '')
    const { count } = await supabase
      .from('jobs')
      .select('*', { count: 'exact', head: true })
      .like('job_number', `JOB-${today}-%`)

    const jobNumber = `JOB-${today}-${String((count || 0) + 1).padStart(3, '0')}`

    // Get customer info for denormalized fields
    const { data: customer } = await supabase
      .from('customers')
      .select('name, email, phone')
      .eq('id', body.customer_id)
      .single()

    // Prepare job data - using simplified address
    const jobData = {
      job_number: jobNumber,
      customer_id: body.customer_id,
      proposal_id: body.proposal_id || null,
      title: body.title,
      description: body.description || '',
      job_type: body.job_type || 'repair',
      status: body.status || 'not_scheduled',
      service_address: body.service_address || '',
      service_city: '',  // Keep empty for now
      service_state: '', // Keep empty for now
      service_zip: '',   // Keep empty for now
      scheduled_date: body.scheduled_date || null,
      scheduled_time: body.scheduled_time || null,
      total_value: body.total_value || 0,
      notes: body.notes || '',
      created_by: user.id,
      // Denormalized fields
      customer_name: customer?.name || '',
      customer_email: customer?.email || '',
      customer_phone: customer?.phone || ''
    }

    console.log('Creating job with data:', jobData)

    // Create the job
    const { data: newJob, error: jobError } = await supabase
      .from('jobs')
      .insert(jobData)
      .select()
      .single()

    if (jobError) {
      console.error('Error creating job:', jobError)
      return NextResponse.json({ 
        error: 'Failed to create job',
        details: jobError.message 
      }, { status: 400 })
    }

    // Assign technicians if provided
    if (body.technicianIds && body.technicianIds.length > 0) {
      const assignments = body.technicianIds.map((techId: string) => ({
        job_id: newJob.id,
        technician_id: techId,
        assigned_by: user.id
      }))

      const { error: techError } = await supabase
        .from('job_technicians')
        .insert(assignments)
      
      if (techError) {
        console.error('Error assigning technicians:', techError)
      }
    }

    return NextResponse.json({ 
      success: true,
      job: newJob
    })

  } catch (error) {
    console.error('Error creating job:', error)
    return NextResponse.json({ 
      error: 'Internal server error',
      details: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 })
  }
}

export async function GET() {
  try {
    const supabase = await createClient()
    
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single()

    const userRole = profile?.role || 'technician'

    let query = supabase
      .from('jobs')
      .select(`
        *,
        customers!customer_id (
          name,
          email,
          phone,
          address
        )
      `)
      .order('created_at', { ascending: false })

    if (userRole === 'technician') {
      const { data: assignedJobs } = await supabase
        .from('job_technicians')
        .select('job_id')
        .eq('technician_id', user.id)

      const jobIds = assignedJobs?.map(j => j.job_id) || []
      if (jobIds.length > 0) {
        query = query.in('id', jobIds)
      } else {
        return NextResponse.json({ jobs: [] })
      }
    }

    const { data: jobs, error } = await query

    if (error) {
      console.error('Error fetching jobs:', error)
      return NextResponse.json({ 
        error: 'Failed to fetch jobs',
        details: error.message 
      }, { status: 400 })
    }

    return NextResponse.json({ jobs: jobs || [] })

  } catch (error) {
    console.error('Error fetching jobs:', error)
    return NextResponse.json({ 
      error: 'Internal server error',
      details: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 })
  }
}
EOF

# 4. Create SQL to delete test jobs
echo "📝 Creating SQL to delete test jobs..."
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/delete-test-jobs.sql << 'EOF'
-- Delete all test jobs created on July 29, 2025
DELETE FROM job_technicians 
WHERE job_id IN (
  SELECT id FROM jobs 
  WHERE job_number LIKE 'JOB-20250729-%'
);

DELETE FROM job_photos
WHERE job_id IN (
  SELECT id FROM jobs 
  WHERE job_number LIKE 'JOB-20250729-%'
);

DELETE FROM job_files
WHERE job_id IN (
  SELECT id FROM jobs 
  WHERE job_number LIKE 'JOB-20250729-%'
);

DELETE FROM job_materials
WHERE job_id IN (
  SELECT id FROM jobs 
  WHERE job_number LIKE 'JOB-20250729-%'
);

DELETE FROM job_time_entries
WHERE job_id IN (
  SELECT id FROM jobs 
  WHERE job_number LIKE 'JOB-20250729-%'
);

DELETE FROM job_activity_log
WHERE job_id IN (
  SELECT id FROM jobs 
  WHERE job_number LIKE 'JOB-20250729-%'
);

-- Now delete the jobs themselves
DELETE FROM jobs 
WHERE job_number LIKE 'JOB-20250729-%';

-- Return count of deleted jobs
SELECT 'Deleted ' || COUNT(*) || ' test jobs' as result
FROM jobs 
WHERE job_number LIKE 'JOB-20250729-%';
EOF

echo "🔨 Building the application..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app
npm run build 2>&1 | head -80

# Check if build succeeded
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Commit and push changes
    echo "📦 Committing changes..."
    git add -A
    git commit -m "Fix job creation form: technicians, proposal data, simplified address"
    git push origin main
    
    echo "✅ Fix applied successfully!"
    echo ""
    echo "🎯 What was fixed:"
    echo "1. Proposal dropdown now shows address and total amount"
    echo "2. Auto-fills job title and total value from proposal"
    echo "3. Auto-fills description from proposal items (services + addons)"
    echo "4. Fixed technician selection - now shows all active technicians"
    echo "5. Simplified service address to single field"
    echo "6. Fixed Create Job button functionality"
    echo ""
    echo "📝 To delete test jobs:"
    echo "Run the SQL in delete-test-jobs.sql in Supabase SQL Editor"
    echo ""
    echo "⚠️ Still need to fix:"
    echo "1. Mobile proposal approval error"
    echo "2. Payment showing $0 after Stripe payment"
else
    echo "❌ Build failed. Please check the errors above."
    exit 1
fi
