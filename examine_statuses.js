const { createClient } = require('@supabase/supabase-js')
require('dotenv').config({ path: '.env.local' })

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY

const supabase = createClient(supabaseUrl, supabaseKey)

async function examineStatuses() {
  console.log('=== PROPOSAL AND JOB STATUS ANALYSIS ===\n')
  
  try {
    // Get all unique proposal statuses
    console.log('1. PROPOSAL STATUSES:')
    const { data: proposalStatuses, error: propStatusError } = await supabase
      .from('proposals')
      .select('status')
      .not('status', 'is', null)
    
    if (propStatusError) {
      console.error('Error getting proposal statuses:', propStatusError)
    } else {
      const uniquePropStatuses = [...new Set(proposalStatuses.map(p => p.status))]
      console.log('Unique proposal statuses found:', uniquePropStatuses)
    }
    
    // Get all unique job statuses
    console.log('\n2. JOB STATUSES:')
    const { data: jobStatuses, error: jobStatusError } = await supabase
      .from('jobs')
      .select('status')
      .not('status', 'is', null)
    
    if (jobStatusError) {
      console.error('Error getting job statuses:', jobStatusError)
    } else {
      const uniqueJobStatuses = [...new Set(jobStatuses.map(j => j.status))]
      console.log('Unique job statuses found:', uniqueJobStatuses)
    }
    
    // Check current job and proposal relationship
    console.log('\n3. CURRENT JOB-PROPOSAL STATUS MISMATCH:')
    const jobId = '3915209b-93f8-4474-990f-533090b98138'
    
    const { data: jobData, error: jobError } = await supabase
      .from('jobs')
      .select('id, job_number, status, proposal_id')
      .eq('id', jobId)
      .single()
    
    if (jobError) {
      console.error('Error getting job:', jobError)
      return
    }
    
    console.log(`Job ${jobData.job_number}: status = "${jobData.status}"`)
    
    if (jobData.proposal_id) {
      const { data: proposalData, error: proposalError } = await supabase
        .from('proposals')
        .select('id, proposal_number, status')
        .eq('id', jobData.proposal_id)
        .single()
      
      if (proposalError) {
        console.error('Error getting proposal:', proposalError)
      } else {
        console.log(`Linked Proposal ${proposalData.proposal_number}: status = "${proposalData.status}"`)
        console.log(`MISMATCH: Job is "${jobData.status}" but Proposal is "${proposalData.status}"`)
      }
    }
    
    // Get all job-proposal pairs to see patterns
    console.log('\n4. ALL JOB-PROPOSAL STATUS PAIRS:')
    const { data: allPairs, error: pairsError } = await supabase
      .from('jobs')
      .select(`
        job_number,
        status,
        proposal_id,
        proposals!inner (
          proposal_number,
          status
        )
      `)
      .not('proposal_id', 'is', null)
    
    if (pairsError) {
      console.error('Error getting job-proposal pairs:', pairsError)
    } else {
      allPairs.forEach(pair => {
        console.log(`${pair.job_number}: JOB="${pair.status}" | PROPOSAL="${pair.proposals.status}"`)
      })
    }
    
  } catch (error) {
    console.error('General error:', error)
  }
}

examineStatuses()
