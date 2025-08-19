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
