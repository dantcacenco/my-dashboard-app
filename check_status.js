const { createClient } = require('@supabase/supabase-js')
require('dotenv').config({ path: '.env.local' })

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
)

async function checkStatus() {
  // Get existing status values
  const { data } = await supabase
    .from('proposals')
    .select('status')
    .not('status', 'is', null)
  
  const uniqueStatuses = [...new Set(data?.map(p => p.status) || [])]
  console.log('Existing status values in database:', uniqueStatuses)
  
  // Check proposals that look approved
  const { data: approved } = await supabase
    .from('proposals')
    .select('status, approved_at, deposit_amount')
    .not('approved_at', 'is', null)
    .limit(5)
  
  console.log('\nApproved proposals status:', approved?.map(p => p.status))
}

checkStatus().then(() => process.exit(0)).catch(console.error)
