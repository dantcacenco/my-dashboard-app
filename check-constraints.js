const { createClient } = require('@supabase/supabase-js')
require('dotenv').config({ path: '.env.local' })

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
)

async function checkConstraints() {
  try {
    // Get table constraints
    const { data: constraints, error } = await supabase
      .rpc('get_table_constraints', { table_name: 'proposals' })
      .select('*')
    
    if (error) {
      // Try alternative method
      const { data, error: altError } = await supabase
        .from('information_schema.check_constraints')
        .select('*')
        .ilike('constraint_name', '%proposal%')
      
      if (altError) {
        console.log('Could not fetch constraints directly')
      } else {
        console.log('Constraints:', data)
      }
    } else {
      console.log('Constraints:', constraints)
    }

    // Test with sample data
    console.log('\nTesting update with sample values...')
    
    // Get a test proposal
    const { data: testProposal } = await supabase
      .from('proposals')
      .select('*')
      .eq('status', 'sent')
      .limit(1)
      .single()
    
    if (testProposal) {
      console.log('Test proposal total:', testProposal.total)
      console.log('Calculated deposits:')
      console.log('  Deposit (50%):', testProposal.total * 0.5)
      console.log('  Progress (30%):', testProposal.total * 0.3)
      console.log('  Final (20%):', testProposal.total * 0.2)
      console.log('  Sum:', (testProposal.total * 0.5) + (testProposal.total * 0.3) + (testProposal.total * 0.2))
    }

  } catch (err) {
    console.error('Error:', err)
  }
}

checkConstraints()
