#!/bin/bash
set -e

echo "🔍 Checking database schema..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Create a temporary Node script to check the database
cat > check-db-schema.js << 'EOF'
const { createClient } = require('@supabase/supabase-js')

// Using environment variables (these should be in .env.local)
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl || !supabaseKey) {
  console.log('❌ Missing Supabase credentials in environment')
  process.exit(1)
}

const supabase = createClient(supabaseUrl, supabaseKey)

async function checkSchema() {
  console.log('📊 Checking Database Schema\n')
  console.log('=' .repeat(50))
  
  // Check proposals table
  console.log('\n📋 PROPOSALS TABLE:')
  const { data: proposalCols, error: pError } = await supabase
    .rpc('get_table_columns', { table_name: 'proposals' })
    .limit(1)
  
  if (pError) {
    // Try alternative method
    const { data: sample } = await supabase
      .from('proposals')
      .select('*')
      .limit(1)
    
    if (sample && sample[0]) {
      console.log('Columns:', Object.keys(sample[0]).join(', '))
    }
  }
  
  // Check proposal_items table
  console.log('\n📋 PROPOSAL_ITEMS TABLE:')
  const { data: itemSample } = await supabase
    .from('proposal_items')
    .select('*')
    .limit(1)
  
  if (itemSample && itemSample[0]) {
    console.log('Columns:', Object.keys(itemSample[0]).join(', '))
  }
  
  // Check if sent_date exists
  console.log('\n🔍 Checking specific columns:')
  const { data: proposal, error } = await supabase
    .from('proposals')
    .select('id, sent_at, created_at, updated_at')
    .limit(1)
    .single()
  
  if (proposal) {
    console.log('✅ Available date columns:', Object.keys(proposal).filter(k => k.includes('at') || k.includes('date')))
  }
  
  // Check API routes
  console.log('\n📂 Checking API routes:')
  const fs = require('fs')
  const path = require('path')
  
  const apiPath = path.join(process.cwd(), 'app/api')
  if (fs.existsSync(apiPath)) {
    const routes = fs.readdirSync(apiPath)
    routes.forEach(route => {
      console.log(`  - /api/${route}`)
    })
  }
  
  console.log('\n✅ Schema check complete!')
}

checkSchema().catch(console.error)
EOF

# Create a temporary .env for this check only (will be deleted)
cat > .env.temp << 'EOF'
NEXT_PUBLIC_SUPABASE_URL="https://dqcxwekmehrqkigcufug.supabase.co"
SUPABASE_SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxY3h3ZWttZWhycWtpZ2N1ZnVnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzA5NDk0NiwiZXhwIjoyMDY4NjcwOTQ2fQ.W2NurXdGtch5rjaKal2hnBKwsCxC39h-GQyzrpRBqJk"
EOF

# Run the check with temp env
node -r dotenv/config check-db-schema.js dotenv_config_path=.env.temp

# Clean up immediately
rm -f check-db-schema.js .env.temp

echo ""
echo "🎯 Now I know your actual database schema!"
echo "📝 I'll use this information to write correct queries"
