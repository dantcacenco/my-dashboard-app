import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient()
    const data = await request.json()
    
    // Generate job number
    const jobNumber = `JOB-${Date.now()}-${Math.floor(Math.random() * 1000).toString().padStart(3, '0')}`
    
    // Use proposal title if available, otherwise create a default title
    let jobTitle = data.title
    if (!jobTitle && data.proposal_id) {
      // If creating from a proposal and no title provided, fetch the proposal title
      const { data: proposal } = await supabase
        .from('proposals')
        .select('title')
        .eq('id', data.proposal_id)
        .single()
      
      jobTitle = proposal?.title || `Job ${jobNumber}`
    } else if (!jobTitle) {
      jobTitle = `Job ${jobNumber}`
    }
    
    const { data: job, error } = await supabase
      .from('jobs')
      .insert({
        job_number: jobNumber,
        customer_id: data.customer_id,
        customer_name: data.customer_name,
        service_address: data.service_address,
        title: jobTitle,  // Use the proper title
        description: data.description,
        job_type: data.job_type || 'installation',
        status: 'not_scheduled',
        proposal_id: data.proposal_id || null,
        value: data.value || 0,
        scheduled_date: data.scheduled_date || null,
        scheduled_time: data.scheduled_time || null,
        created_at: new Date().toISOString()
      })
      .select()
      .single()

    if (error) {
      console.error('Job creation error:', error)
      return NextResponse.json({ error: error.message }, { status: 400 })
    }

    return NextResponse.json(job)
  } catch (error) {
    console.error('Job creation error:', error)
    return NextResponse.json({ error: 'Failed to create job' }, { status: 500 })
  }
}

export async function GET(request: NextRequest) {
  try {
    const supabase = await createClient()
    
    const { data: jobs, error } = await supabase
      .from('jobs')
      .select(`
        *,
        customers (
          id,
          name,
          email,
          phone,
          address
        ),
        job_technicians (
          technician_id,
          profiles (
            id,
            full_name,
            email
          )
        )
      `)
      .order('created_at', { ascending: false })

    if (error) {
      console.error('Jobs fetch error:', error)
      return NextResponse.json({ error: error.message }, { status: 400 })
    }

    return NextResponse.json(jobs || [])
  } catch (error) {
    console.error('Jobs fetch error:', error)
    return NextResponse.json({ error: 'Failed to fetch jobs' }, { status: 500 })
  }
}
