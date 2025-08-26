import subprocess
import json

# Read .env.local to get database credentials
env_vars = {}
with open('.env.local', 'r') as f:
    for line in f:
        if '=' in line and not line.startswith('#'):
            key, value = line.strip().split('=', 1)
            env_vars[key] = value.strip('"').strip("'")

# Extract connection details from DATABASE_URL
db_url = env_vars.get('DATABASE_URL', '')
if not db_url:
    db_url = env_vars.get('NEXT_PUBLIC_SUPABASE_URL', '').replace('https://', 'postgresql://postgres:')
    
print("Checking database constraints...")

# Create a simple Node.js script to check via Supabase
node_script = '''
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
  
  console.log('\\nCurrent proposals:', proposals)
  
  // Check what payment_stage values exist
  const { data: existingStages } = await supabase
    .from('proposals')
    .select('payment_stage')
    .not('payment_stage', 'is', null)
  
  const uniqueStages = [...new Set(existingStages?.map(p => p.payment_stage) || [])]
  console.log('\\nExisting payment_stage values in database:', uniqueStages)
}

checkPaymentStage().then(() => process.exit(0))
'''

with open('check_stage.js', 'w') as f:
    f.write(node_script)

subprocess.run(['node', 'check_stage.js'])
