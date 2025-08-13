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

    // Get proposal details
    const { data: proposal, error: proposalError } = await supabase
      .from('proposals')
      .select('*, customers(*)')
      .eq('id', proposalId)
      .single()

    if (proposalError || !proposal) {
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

    // Create the job with provided data
    const { data: newJob, error: jobError } = await supabase
      .from('jobs')
      .insert({
        job_number: jobNumber,
        customer_id: proposal.customer_id,
        proposal_id: proposalId,
        title: jobData.title || proposal.title,
        description: proposal.description,
        job_type: jobData.job_type || 'installation',
        status: 'scheduled',
        service_address: jobData.service_address || proposal.customers?.address || '',
        service_city: jobData.service_city || '',
        service_state: jobData.service_state || '',
        service_zip: jobData.service_zip || '',
        scheduled_date: jobData.scheduled_date || null,
        scheduled_time: jobData.scheduled_time || null,
        notes: jobData.notes || '',
        created_by: user.id
      })
      .select()
      .single()

    if (jobError) {
      console.error('Error creating job:', jobError)
      return NextResponse.json({ error: 'Failed to create job' }, { status: 500 })
    }

    // Assign technicians if provided
    if (technicianIds && technicianIds.length > 0) {
      const assignments = technicianIds.map((techId: string) => ({
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
      jobId: newJob.id,
      jobNumber: newJob.job_number 
    })

  } catch (error) {
    console.error('Error in create job from proposal:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
