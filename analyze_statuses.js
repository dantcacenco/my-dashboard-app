const { createClient } = require('@supabase/supabase-js')
require('dotenv').config({ path: '.env.local' })

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY

const supabase = createClient(supabaseUrl, supabaseKey)

async function analyzeStatuses() {
  console.log('=== STATUS ANALYSIS ===\n')
  
  try {
    // Get all unique proposal statuses
    console.log('1. PROPOSAL STATUSES:')
    const { data: proposalStatuses, error: propError } = await supabase
      .from('proposals')
      .select('status')
      .not('status', 'is', null)
    
    if (propError) {
      console.error('Error getting proposal statuses:', propError)
    } else {
      const uniqueProposalStatuses = [...new Set(proposalStatuses.map(p => p.status))]
      console.log('Unique proposal statuses found:', uniqueProposalStatuses)
    }
    
    // Get all unique job statuses
    console.log('\n2. JOB STATUSES:')
    const { data: jobStatuses, error: jobError } = await supabase
      .from('jobs')
      .select('status')
      .not('status', 'is', null)
    
    if (jobError) {
      console.error('Error getting job statuses:', jobError)
    } else {
      const uniqueJobStatuses = [...new Set(jobStatuses.map(j => j.status))]
      console.log('Unique job statuses found:', uniqueJobStatuses)
    }
    
    // Look at the specific job and proposal from the screenshot
    console.log('\n3. SPECIFIC JOB-PROPOSAL PAIR:')
    const jobId = '3915209b-93f8-4474-990f-533090b98138'
    
    const { data: jobData, error: jobDataError } = await supabase
      .from('jobs')
      .select('id, job_number, status, proposal_id')
      .eq('id', jobId)
      .single()
    
    if (jobDataError) {
      console.error('Error getting job data:', jobDataError)
    } else {
      console.log('Job data:', jobData)
      
      if (jobData.proposal_id) {
        const { data: proposalData, error: proposalDataError } = await supabase
          .from('proposals')
          .select('id, proposal_number, status')
          .eq('id', jobData.proposal_id)
          .single()
        
        if (proposalDataError) {
          console.error('Error getting proposal data:', proposalDataError)
        } else {
          console.log('Related proposal data:', proposalData)
          console.log(`\nSTATUS MISMATCH: Job="${jobData.status}" vs Proposal="${proposalData.status}"`)
        }
      }
    }
    
    // Get sample data to see status patterns
    console.log('\n4. SAMPLE JOB-PROPOSAL PAIRS:')
    const { data: sampleJobs, error: sampleError } = await supabase
      .from('jobs')
      .select(`
        id, job_number, status, proposal_id,
        proposals!jobs_proposal_id_fkey (
          id, proposal_number, status
        )
      `)
      .not('proposal_id', 'is', null)
      .limit(5)
    
    if (sampleError) {
      console.error('Error getting sample jobs:', sampleError)
    } else {
      sampleJobs.forEach(job => {
        console.log(`${job.job_number}: job_status="${job.status}" | proposal_status="${job.proposals?.status}"`)
      })
    }
    
  } catch (error) {
    console.error('General error:', error)
  }
}

analyzeStatuses()
