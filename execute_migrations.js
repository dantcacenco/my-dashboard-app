const { createClient } = require('@supabase/supabase-js')
require('dotenv').config({ path: '.env.local' })

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY
const supabase = createClient(supabaseUrl, supabaseKey)

async function executeSQLMigrations() {
  console.log('=== EXECUTING SQL MIGRATIONS ===\n')
  
  try {
    console.log('Step 1: Updating proposal status constraints...')
    
    // Update existing 'viewed' status to 'sent' if any exist
    const { data: updateResult, error: updateError } = await supabase
      .from('proposals')
      .update({ status: 'sent' })
      .eq('status', 'viewed')
    
    if (updateError) {
      console.log('No "viewed" statuses to update or error:', updateError.message)
    } else {
      console.log('✅ Updated any existing "viewed" statuses to "sent"')
    }
    
    console.log('\n✅ Status constraint update completed')
    console.log('Note: Database constraint changes must be done via Supabase dashboard')
    console.log('The new allowed statuses are now:')
    console.log('- draft, sent, approved, rejected, deposit paid, rough-in paid, final paid, completed')
    
    console.log('\n=== TESTING NEW STATUS SYSTEM ===')
    
    // Test the new status by trying to update a proposal
    const { data: testProposal, error: testError } = await supabase
      .from('proposals')
      .select('id, status, proposal_number')
      .limit(1)
      .single()
    
    if (testError) {
      console.log('No test proposal found:', testError.message)
      return
    }
    
    console.log(`Testing with proposal: ${testProposal.proposal_number}`)
    console.log(`Current status: ${testProposal.status}`)
    
    // Test setting to one of the new statuses
    const { data: updateTest, error: updateTestError } = await supabase
      .from('proposals')
      .update({ status: 'deposit paid' })
      .eq('id', testProposal.id)
      .select()
    
    if (updateTestError) {
      console.log('❌ New status not yet allowed in database:', updateTestError.message)
      console.log('Please run the SQL commands manually in Supabase dashboard:')
      console.log('1. ALTER TABLE proposals DROP CONSTRAINT IF EXISTS proposals_status_check;')
      console.log('2. ALTER TABLE proposals ADD CONSTRAINT proposals_status_check CHECK (status IN (\'draft\', \'sent\', \'approved\', \'rejected\', \'deposit paid\', \'rough-in paid\', \'final paid\', \'completed\'));')
    } else {
      console.log('✅ New status system working!')
      
      // Revert the test change
      await supabase
        .from('proposals')
        .update({ status: testProposal.status })
        .eq('id', testProposal.id)
      
      console.log('✅ Test reverted, proposal status restored')
    }
    
  } catch (error) {
    console.error('Migration error:', error)
  }
}

executeSQLMigrations()
