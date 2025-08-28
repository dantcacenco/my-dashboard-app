const { createClient } = require('@supabase/supabase-js')
require('dotenv').config({ path: '.env.local' })

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY
const supabase = createClient(supabaseUrl, supabaseKey)

async function updateProposalConstraints() {
  console.log('=== UPDATING PROPOSAL STATUS CONSTRAINTS ===\n')
  
  try {
    // First, let's see the current constraint
    console.log('Current allowed statuses: draft, sent, viewed, approved, rejected')
    console.log('New statuses to add: deposit paid, rough-in paid, final paid, completed')
    
    // Drop the existing constraint
    const dropConstraintSQL = `
      ALTER TABLE proposals 
      DROP CONSTRAINT IF EXISTS proposals_status_check;
    `
    
    console.log('Dropping existing constraint...')
    const { error: dropError } = await supabase.rpc('exec_sql', { 
      sql: dropConstraintSQL 
    })
    
    if (dropError && !dropError.message.includes('does not exist')) {
      console.error('Error dropping constraint:', dropError)
      return
    }
    
    // Add new constraint with all statuses
    const addConstraintSQL = `
      ALTER TABLE proposals 
      ADD CONSTRAINT proposals_status_check 
      CHECK (status IN (
        'draft',
        'sent', 
        'approved',
        'rejected',
        'deposit paid',
        'rough-in paid', 
        'final paid',
        'completed'
      ));
    `
    
    console.log('Adding new constraint with expanded statuses...')
    const { error: addError } = await supabase.rpc('exec_sql', { 
      sql: addConstraintSQL 
    })
    
    if (addError) {
      console.error('Error adding constraint:', addError)
      return
    }
    
    console.log('✅ Database constraints updated successfully')
    console.log('\nNew allowed proposal statuses:')
    console.log('- draft (default)')
    console.log('- sent (auto-set when email sent)')
    console.log('- approved (customer approval)')
    console.log('- rejected (customer rejection)')
    console.log('- deposit paid (50% payment complete)')
    console.log('- rough-in paid (30% payment complete)')
    console.log('- final paid (20% payment complete)')
    console.log('- completed (admin manual completion)')
    
  } catch (error) {
    console.error('Database update failed:', error)
  }
}

updateProposalConstraints()
