const { createClient } = require('@supabase/supabase-js')
require('dotenv').config({ path: '.env.local' })

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY

const supabase = createClient(supabaseUrl, supabaseKey)

// Status mapping functions
function getProposalStatusFromJob(jobStatus) {
  switch (jobStatus) {
    case 'completed':
      return 'completed'
    case 'cancelled':
      return 'rejected'
    case 'scheduled':
    case 'in_progress':
      return 'approved'
    default:
      return 'approved' // Default for active jobs
  }
}

async function syncAllStatuses() {
  console.log('=== SYNCING ALL JOB-PROPOSAL STATUSES ===\n')
  
  try {
    // Get all jobs with their proposals
    const { data: jobs, error: jobsError } = await supabase
      .from('jobs')
      .select(`
        id, job_number, status, proposal_id,
        proposals!jobs_proposal_id_fkey (
          id, proposal_number, status
        )
      `)
      .not('proposal_id', 'is', null)
    
    if (jobsError) {
      console.error('Error getting jobs:', jobsError)
      return
    }
    
    console.log(`Found ${jobs.length} jobs with proposals to sync\n`)
    
    let syncedCount = 0
    
    for (const job of jobs) {
      const currentProposalStatus = job.proposals?.status
      const requiredProposalStatus = getProposalStatusFromJob(job.status)
      
      console.log(`Job ${job.job_number}:`)
      console.log(`  Job Status: ${job.status}`)
      console.log(`  Current Proposal Status: ${currentProposalStatus}`)
      console.log(`  Required Proposal Status: ${requiredProposalStatus}`)
      
      if (currentProposalStatus !== requiredProposalStatus) {
        console.log(`  🔄 SYNCING: ${currentProposalStatus} → ${requiredProposalStatus}`)
        
        const { error: updateError } = await supabase
          .from('proposals')
          .update({ status: requiredProposalStatus })
          .eq('id', job.proposal_id)
        
        if (updateError) {
          console.error(`  ❌ Error updating proposal ${job.proposal_id}:`, updateError)
        } else {
          console.log(`  ✅ Successfully synced`)
          syncedCount++
        }
      } else {
        console.log(`  ✅ Already in sync`)
      }
      console.log('')
    }
    
    console.log(`\n=== SYNC COMPLETE ===`)
    console.log(`Total jobs processed: ${jobs.length}`)
    console.log(`Statuses synced: ${syncedCount}`)
    console.log(`Already in sync: ${jobs.length - syncedCount}`)
    
  } catch (error) {
    console.error('Error during sync:', error)
  }
}

syncAllStatuses()
