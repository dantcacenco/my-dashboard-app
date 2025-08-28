const { createClient } = require('@supabase/supabase-js')
require('dotenv').config({ path: '.env.local' })

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY

const supabase = createClient(supabaseUrl, supabaseKey)

async function fixStatusMapping() {
  console.log('=== FIXING STATUS MAPPING LOGIC ===\n')
  
  // Better status mapping with hierarchy
  const statusHierarchy = {
    proposal: ['draft', 'sent', 'viewed', 'approved', 'completed', 'rejected'],
    job: ['not_scheduled', 'scheduled', 'in-progress', 'completed', 'cancelled']
  }
  
  // When job advances beyond what proposal shows, proposal should advance too
  const syncMapping = {
    // If job is more advanced, update proposal to match
    jobToProposal: {
      'scheduled': 'approved',      // Job scheduled = Proposal approved  
      'in-progress': 'approved',    // Job in progress = Proposal approved
      'completed': 'completed',     // Job completed = Proposal completed (new status)
      'cancelled': 'rejected'       // Job cancelled = Proposal rejected
    },
    // If proposal changes, update job accordingly  
    proposalToJob: {
      'draft': 'not_scheduled',
      'sent': 'not_scheduled',
      'viewed': 'not_scheduled', 
      'approved': 'scheduled',      // Don't downgrade if job is further along
      'completed': 'completed',
      'rejected': 'cancelled'
    }
  }
  
  console.log('Improved Status Mapping:')
  console.log('Job -> Proposal:', syncMapping.jobToProposal)
  console.log('Proposal -> Job:', syncMapping.proposalToJob)
  
  try {
    // First, add 'completed' as a valid proposal status if needed
    console.log('\n=== CHECKING CURRENT STATUSES ===')
    
    const jobId = '3915209b-93f8-4474-990f-533090b98138'
    
    // Get current job and proposal
    const { data: currentJob, error: jobError } = await supabase
      .from('jobs')
      .select('id, job_number, status, proposal_id')
      .eq('id', jobId)
      .single()
    
    if (jobError) {
      console.error('Error getting current job:', jobError)
      return
    }
    
    const { data: currentProposal, error: propError } = await supabase
      .from('proposals')
      .select('id, proposal_number, status')
      .eq('id', currentJob.proposal_id)
      .single()
    
    if (propError) {
      console.error('Error getting current proposal:', propError)
      return
    }
    
    console.log(`Current Job ${currentJob.job_number}: status = "${currentJob.status}"`)
    console.log(`Current Proposal ${currentProposal.proposal_number}: status = "${currentProposal.status}"`)
    
    // Since job was "completed", proposal should be "completed" too
    // But first, let's revert the wrong change and set job back to completed
    if (currentJob.status === 'scheduled') {
      console.log('\n=== REVERTING JOB STATUS BACK TO COMPLETED ===')
      const { error: revertError } = await supabase
        .from('jobs')
        .update({ status: 'completed' })
        .eq('id', jobId)
      
      if (revertError) {
        console.error('Error reverting job status:', revertError)
      } else {
        console.log('✓ Reverted job status back to completed')
      }
    }
    
    // Now sync proposal to match completed job
    if (currentProposal.status === 'approved' && currentJob.status === 'completed') {
      console.log('\n=== SYNCING PROPOSAL TO MATCH COMPLETED JOB ===')
      
      // For now, keep proposal as "approved" since "completed" might not be a valid proposal status
      // The sync should show both as the same conceptual status in the UI
      console.log('Proposal will remain "approved" but UI should show both as "Completed"')
    }
    
  } catch (error) {
    console.error('Error in status sync:', error)
  }
}

fixStatusMapping()
