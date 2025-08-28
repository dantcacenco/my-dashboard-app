const { createClient } = require('@supabase/supabase-js')
require('dotenv').config({ path: '.env.local' })

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY
const supabase = createClient(supabaseUrl, supabaseKey)
const fs = require('fs')

async function createBackup() {
  console.log('=== CREATING DATABASE BACKUP ===\n')
  
  try {
    // Backup jobs
    const { data: jobs, error: jobsError } = await supabase
      .from('jobs')
      .select('*')
    
    if (jobsError) throw jobsError

    // Backup proposals  
    const { data: proposals, error: proposalsError } = await supabase
      .from('proposals')
      .select('*')
    
    if (proposalsError) throw proposalsError

    // Create backup object
    const backup = {
      timestamp: new Date().toISOString(),
      jobs: jobs,
      proposals: proposals
    }

    // Save backup to file
    const backupFilename = `database_backup_${new Date().toISOString().replace(/[:.]/g, '-')}.json`
    fs.writeFileSync(backupFilename, JSON.stringify(backup, null, 2))
    
    console.log(`✅ Backup created: ${backupFilename}`)
    console.log(`📊 Jobs backed up: ${jobs.length}`)
    console.log(`📊 Proposals backed up: ${proposals.length}`)
    
  } catch (error) {
    console.error('❌ Backup failed:', error)
  }
}

createBackup()
