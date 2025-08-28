const { createClient } = require('@supabase/supabase-js')
require('dotenv').config({ path: '.env.local' })

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY

const supabase = createClient(supabaseUrl, supabaseKey)

async function createStatusSync() {
  console.log('=== CREATING STATUS SYNC SYSTEM ===\n')
  
  // Define the status mapping
  const statusMapping = {
    // Proposal to Job status mapping
    proposalToJob: {
      'draft': 'not_scheduled',
      'sent': 'not_scheduled', 
      'viewed': 'not_scheduled',
      'approved': 'scheduled',
      'rejected': 'cancelled'
    },
    // Job to Proposal status mapping
    jobToProposal: {
      'not_scheduled': 'sent',
      'scheduled': 'approved', 
      'in-progress': 'approved',
      'completed': 'approved',
      'cancelled': 'rejected'
    }
  }
  
  console.log('Status Mapping Defined:')
  console.log('Proposal -> Job:', statusMapping.proposalToJob)
  console.log('Job -> Proposal:', statusMapping.jobToProposal)
  
  try {
    // First, let's create the proper job statuses if they don't exist
    console.log('\n=== UPDATING JOB STATUSES ===')
    
    // We need to expand job statuses to include: not_scheduled, scheduled, in-progress, completed, cancelled
    const { data: jobs, error: jobsError } = await supabase
      .from('jobs')
      .select('id, job_number, status, proposal_id')
    
    if (jobsError) {
      console.error('Error getting jobs:', jobsError)
      return
    }
    
    console.log(`Found ${jobs.length} jobs to potentially update`)
    
    // For each job with a proposal_id, sync the status
    for (const job of jobs) {
      if (job.proposal_id) {
        const { data: proposal, error: propError } = await supabase
          .from('proposals')  
          .select('status')
          .eq('id', job.proposal_id)
          .single()
        
        if (propError) {
          console.error(`Error getting proposal for job ${job.job_number}:`, propError)
          continue
        }
        
        // Map proposal status to job status
        const expectedJobStatus = statusMapping.proposalToJob[proposal.status]
        
        if (expectedJobStatus && expectedJobStatus !== job.status) {
          console.log(`Updating job ${job.job_number}: "${job.status}" -> "${expectedJobStatus}" (based on proposal status: "${proposal.status}")`)
          
          const { error: updateError } = await supabase
            .from('jobs')
            .update({ status: expectedJobStatus })
            .eq('id', job.id)
          
          if (updateError) {
            console.error(`Error updating job ${job.job_number}:`, updateError)
          } else {
            console.log(`✓ Successfully updated job ${job.job_number}`)
          }
        } else {
          console.log(`Job ${job.job_number} status "${job.status}" is already correct for proposal status "${proposal.status}"`)
        }
      }
    }
    
  } catch (error) {
    console.error('Error in status sync:', error)
  }
}

createStatusSync()
