import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const supabase = await createClient()
  const { searchParams } = new URL(request.url)
  const jobId = searchParams.get('job_id')
  
  if (!jobId) {
    return NextResponse.json({ error: 'job_id parameter required' }, { status: 400 })
  }

  try {
    console.log('Debug API - Job ID:', jobId)
    
    // 1. Check job exists
    const { data: job, error: jobError } = await supabase
      .from('jobs')
      .select('*')
      .eq('id', jobId)
      .single()
    
    // 2. Check raw job_technicians entries
    const { data: rawAssignments, error: rawError } = await supabase
      .from('job_technicians')
      .select('*')
      .eq('job_id', jobId)
    
    // 3. Check job_technicians with profiles
    const { data: assignments, error: assignError } = await supabase
      .from('job_technicians')
      .select(`
        *,
        profiles!technician_id (
          id,
          email,
          full_name,
          role
        )
      `)
      .eq('job_id', jobId)
    
    // 4. Check specific technician profile
    const { data: techProfile, error: techError } = await supabase
      .from('profiles')
      .select('*')
      .eq('email', 'technician@gmail.com')
    
    // 5. Check all technicians
    const { data: allTechs, error: allTechError } = await supabase
      .from('profiles')
      .select('*')
      .eq('role', 'technician')
    
    return NextResponse.json({
      job: { data: job, error: jobError },
      rawAssignments: { data: rawAssignments, error: rawError },
      assignments: { data: assignments, error: assignError },
      techProfile: { data: techProfile, error: techError },
      allTechs: { data: allTechs, error: allTechError },
      summary: {
        jobExists: !!job,
        jobNumber: job?.job_number,
        assignmentCount: rawAssignments?.length || 0,
        technicianEmail: techProfile?.[0]?.email,
        technicianId: techProfile?.[0]?.id
      }
    })
    
  } catch (error) {
    console.error('Debug API error:', error)
    return NextResponse.json({ 
      error: 'Database query failed', 
      details: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 })
  }
}
