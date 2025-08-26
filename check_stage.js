
const { createClient } = require('@supabase/supabase-js')
require('dotenv').config({ path: '.env.local' })

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
)

async function checkPaymentStage() {
  // Try different payment_stage values to see what works
  const testValues = [
    null,
    '',
    'pending',
    'deposit',
    'deposit_pending',
    'deposit_paid',
    'progress',
    'final',
    'complete',
    'none'
  ]
  
  console.log('Testing payment_stage values...')
  
  // Get a test proposal
  const { data: proposals } = await supabase
    .from('proposals')
    .select('id, status, payment_stage')
    .limit(5)
  
  console.log('\nCurrent proposals:', proposals)
  
  // Check what payment_stage values exist
  const { data: existingStages } = await supabase
    .from('proposals')
    .select('payment_stage')
    .not('payment_stage', 'is', null)
  
  const uniqueStages = [...new Set(existingStages?.map(p => p.payment_stage) || [])]
  console.log('\nExisting payment_stage values in database:', uniqueStages)
}

checkPaymentStage().then(() => process.exit(0))
