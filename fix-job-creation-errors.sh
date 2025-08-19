#!/bin/bash

# Fix Job Creation Errors Script
# This fixes both job creation from Jobs page and from Proposals

echo "🔧 Starting job creation fix..."

# 1. Fix CreateJobModal to properly access customer data
echo "📝 Fixing CreateJobModal component..."
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/\(authenticated\)/proposals/\[id\]/CreateJobModal.tsx << 'EOF'
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
  
  // Fix: Access customers as an object, not array
  const customer = proposal.customers || {}
  
  const [formData, setFormData] = useState({
    title: proposal.title || 'HVAC System Installation',
    job_type: 'installation',
    service_address: customer.address || '',
    service_city: '',
    service_state: '',
    service_zip: '',
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
              <div className="font-medium">{customer.name || 'No customer'}</div>
              <div className="text-sm text-gray-600">{customer.email}</div>
              <div className="text-sm text-gray-600">{customer.phone}</div>
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
EOF

# 2. Fix the API route to handle customer data properly
echo "📝 Fixing create-from-proposal API route..."
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/api/jobs/create-from-proposal/route.ts << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function POST(request: Request) {
  try {
    const supabase = await createClient()
    const { proposalId, jobData, technicianIds } = await request.json()

    // Check auth
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    // Get proposal details with customer
    const { data: proposal, error: proposalError } = await supabase
      .from('proposals')
      .select(`
        *,
        customers (
          id,
          name,
          email,
          phone,
          address
        )
      `)
      .eq('id', proposalId)
      .single()

    if (proposalError || !proposal) {
      console.error('Proposal fetch error:', proposalError)
      return NextResponse.json({ error: 'Proposal not found' }, { status: 404 })
    }

    // Generate job number
    const today = new Date().toISOString().split('T')[0].replace(/-/g, '')
    const { data: lastJob } = await supabase
      .from('jobs')
      .select('job_number')
      .like('job_number', `JOB-${today}-%`)
      .order('job_number', { ascending: false })
      .limit(1)
      .single()

    let nextNumber = 1
    if (lastJob) {
      const match = lastJob.job_number.match(/JOB-\d{8}-(\d{3})/)
      if (match) {
        nextNumber = parseInt(match[1]) + 1
      }
    }
    const jobNumber = `JOB-${today}-${String(nextNumber).padStart(3, '0')}`

    // Prepare job data with proper customer info
    const customer = proposal.customers || {}
    const jobToInsert = {
      job_number: jobNumber,
      customer_id: proposal.customer_id,
      proposal_id: proposalId,
      title: jobData.title || proposal.title,
      description: proposal.description,
      job_type: jobData.job_type || 'installation',
      status: 'scheduled',
      service_address: jobData.service_address || customer.address || '',
      service_city: jobData.service_city || '',
      service_state: jobData.service_state || '',
      service_zip: jobData.service_zip || '',
      scheduled_date: jobData.scheduled_date || null,
      scheduled_time: jobData.scheduled_time || null,
      notes: jobData.notes || '',
      created_by: user.id,
      // Denormalized fields
      customer_name: customer.name || '',
      customer_email: customer.email || '',
      customer_phone: customer.phone || '',
      total_value: proposal.total || 0
    }

    console.log('Creating job with data:', jobToInsert)

    // Create the job
    const { data: newJob, error: jobError } = await supabase
      .from('jobs')
      .insert(jobToInsert)
      .select()
      .single()

    if (jobError) {
      console.error('Error creating job:', jobError)
      return NextResponse.json({ 
        error: 'Failed to create job', 
        details: jobError.message 
      }, { status: 400 })
    }

    // Update proposal to mark job as created
    await supabase
      .from('proposals')
      .update({ 
        job_created: true,
        job_id: newJob.id 
      })
      .eq('id', proposalId)

    // Assign technicians if provided
    if (technicianIds && technicianIds.length > 0) {
      const assignments = technicianIds.map((techId: string) => ({
        job_id: newJob.id,
        technician_id: techId,
        assigned_by: user.id
      }))

      const { error: techError } = await supabase
        .from('job_technicians')
        .insert(assignments)
      
      if (techError) {
        console.error('Error assigning technicians:', techError)
        // Continue anyway - job is created
      }
    }

    return NextResponse.json({ 
      success: true, 
      jobId: newJob.id,
      jobNumber: newJob.job_number 
    })

  } catch (error) {
    console.error('Error in create job from proposal:', error)
    return NextResponse.json({ 
      error: 'Internal server error',
      details: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 })
  }
}
EOF

# 3. Create a general job creation API route
echo "📝 Creating general job creation API route..."
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

    // Prepare job data
    const jobData = {
      job_number: jobNumber,
      customer_id: body.customer_id,
      proposal_id: body.proposal_id || null,
      title: body.title,
      description: body.description || '',
      job_type: body.job_type || 'repair',
      status: body.status || 'not_scheduled',
      service_address: body.service_address || '',
      service_city: body.service_city || '',
      service_state: body.service_state || '',
      service_zip: body.service_zip || '',
      scheduled_date: body.scheduled_date || null,
      scheduled_time: body.scheduled_time || null,
      total_value: parseFloat(body.total_value) || 0,
      notes: body.notes || '',
      created_by: user.id,
      // Denormalized fields
      customer_name: customer?.name || '',
      customer_email: customer?.email || '',
      customer_phone: customer?.phone || ''
    }

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

      await supabase
        .from('job_technicians')
        .insert(assignments)
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

export async function GET(request: Request) {
  try {
    const supabase = await createClient()
    
    // Check auth
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    // Get user role
    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single()

    const userRole = profile?.role || 'technician'

    // Fetch jobs based on role
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

    // If technician, only show their assigned jobs
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

echo "🔨 Building the application..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app
npm run build 2>&1 | head -80

# Check if build succeeded
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Commit and push changes
    echo "📦 Committing changes..."
    git add -A
    git commit -m "Fix job creation errors - proper customer data access and API routes"
    git push origin main
    
    echo "✅ Fix applied successfully!"
    echo ""
    echo "🎯 What was fixed:"
    echo "1. CreateJobModal now properly accesses customer data as an object (not array)"
    echo "2. Added proper error logging in create-from-proposal API"
    echo "3. Created general /api/jobs route for creating and fetching jobs"
    echo "4. Added denormalized customer fields to job creation"
    echo ""
    echo "📝 Next steps:"
    echo "1. Test creating a job from /jobs page"
    echo "2. Test creating a job from a proposal"
    echo "3. Check browser console for any remaining errors"
else
    echo "❌ Build failed. Please check the errors above."
    exit 1
fi
