import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function POST(request: Request) {
  try {
    const supabase = await createClient()
    const { proposalId } = await request.json()

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

    // Check if job already exists
    const { data: existingJob } = await supabase
      .from('job_proposals')
      .select('job_id')
      .eq('proposal_id', proposalId)
      .single()

    if (existingJob) {
      return NextResponse.json({ 
        error: 'Job already exists for this proposal',
        jobId: existingJob.job_id 
      }, { status: 400 })
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

    // Create the job
    const { data: newJob, error: jobError } = await supabase
      .from('jobs')
      .insert({
        job_number: jobNumber,
        customer_id: proposal.customer_id,
        proposal_id: proposalId,
        title: proposal.title,
        description: proposal.description,
        job_type: 'installation',
        status: 'scheduled',
        service_address: proposal.customers?.address || '',
        created_by: user.id
      })
      .select()
      .single()

    if (jobError) {
      console.error('Error creating job:', jobError)
      return NextResponse.json({ error: 'Failed to create job' }, { status: 500 })
    }

    // Create job-proposal link
    await supabase
      .from('job_proposals')
      .insert({
        job_id: newJob.id,
        proposal_id: proposalId,
        attached_by: user.id
      })

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
