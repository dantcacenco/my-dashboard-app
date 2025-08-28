const { createClient } = require('@supabase/supabase-js')
require('dotenv').config({ path: '.env.local' })

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY

const supabase = createClient(supabaseUrl, supabaseKey)

async function backupAndUpdateStatuses() {
  console.log('=== BACKING UP CURRENT DATA ===\n')
  
  try {
    // 1. Backup current proposals
    const { data: proposals, error: proposalsError } = await supabase
      .from('proposals')
      .select('*')
    
    if (proposalsError) throw proposalsError
    
    console.log(`Backing up ${proposals.length} proposals...`)
    require('fs').writeFileSync(
      'backup_proposals.json', 
      JSON.stringify(proposals, null, 2)
    )
    
    // 2. Backup current jobs  
    const { data: jobs, error: jobsError } = await supabase
      .from('jobs')
      .select('*')
    
    if (jobsError) throw jobsError
    
    console.log(`Backing up ${jobs.length} jobs...`)
    require('fs').writeFileSync(
      'backup_jobs.json',
      JSON.stringify(jobs, null, 2)
    )
    
    console.log('✅ Backup completed\n')
    
    // 3. Map current statuses to new ones
    console.log('=== MAPPING CURRENT STATUSES ===')
    
    const statusMapping = {
      'draft': 'draft',
      'sent': 'sent', 
      'viewed': 'sent', // viewed -> sent (closest equivalent)
      'approved': 'approved',
      'rejected': 'rejected'
    }
    
    // 4. Update each proposal to new status format
    let updatedCount = 0
    
    for (const proposal of proposals) {
      const newStatus = statusMapping[proposal.status] || 'draft'
      
      if (proposal.status !== newStatus) {
        console.log(`Updating proposal ${proposal.proposal_number}: ${proposal.status} -> ${newStatus}`)
        
        const { error: updateError } = await supabase
          .from('proposals')
          .update({ status: newStatus })
          .eq('id', proposal.id)
        
        if (updateError) {
          console.error(`Error updating proposal ${proposal.id}:`, updateError)
        } else {
          updatedCount++
        }
      }
    }
    
    console.log(`\n✅ Updated ${updatedCount} proposal statuses`)
    console.log('\n=== READY FOR DATABASE CONSTRAINT UPDATE ===')
    console.log('Next step: Update database constraint to allow new statuses')
    console.log('New allowed statuses: draft, sent, approved, rejected, deposit_paid, rough_in_paid, final_paid, completed')
    
  } catch (error) {
    console.error('Error during backup/update:', error)
  }
}

backupAndUpdateStatuses()
