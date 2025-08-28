const { Client } = require('pg')
require('dotenv').config({ path: '.env.local' })

// Extract connection details from Supabase URL
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY

// Parse Supabase URL to get PostgreSQL connection details
const url = new URL(supabaseUrl)
const projectRef = url.hostname.split('.')[0]

const client = new Client({
  host: `db.${projectRef}.supabase.co`,
  port: 5432,
  database: 'postgres',
  user: 'postgres',
  password: 'postgres123', // This might need to be different
  ssl: { rejectUnauthorized: false }
})

async function executeSQLDirectly() {
  console.log('=== EXECUTING SQL MIGRATIONS DIRECTLY ===\n')
  
  try {
    await client.connect()
    console.log('✅ Connected to PostgreSQL database')
    
    console.log('\nStep 1: Updating proposal status constraints...')
    
    // Drop existing constraint
    await client.query(`
      ALTER TABLE proposals DROP CONSTRAINT IF EXISTS proposals_status_check;
    `)
    console.log('✅ Dropped existing constraint')
    
    // Add new constraint
    await client.query(`
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
    `)
    console.log('✅ Added new constraint with expanded statuses')
    
    console.log('\nStep 2: Creating sync functions...')
    
    // Create sync functions and triggers
    await client.query(`
      CREATE OR REPLACE FUNCTION sync_job_to_proposal()
      RETURNS TRIGGER AS $$
      BEGIN
        IF NEW.proposal_id IS NOT NULL THEN
          UPDATE proposals 
          SET status = CASE 
            WHEN NEW.status = 'scheduled' THEN 'approved'
            WHEN NEW.status = 'in_progress' THEN 'rough-in paid'
            WHEN NEW.status = 'completed' THEN 'completed'
            WHEN NEW.status = 'cancelled' THEN 'rejected'
            ELSE 'draft'
          END,
          updated_at = NOW()
          WHERE id = NEW.proposal_id;
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    `)
    console.log('✅ Created sync_job_to_proposal function')
    
    await client.query(`
      CREATE OR REPLACE FUNCTION sync_proposal_to_job()
      RETURNS TRIGGER AS $$
      BEGIN
        UPDATE jobs 
        SET status = CASE 
          WHEN NEW.status IN ('approved', 'deposit paid') THEN 'scheduled'
          WHEN NEW.status IN ('rough-in paid', 'final paid') THEN 'in_progress' 
          WHEN NEW.status = 'completed' THEN 'completed'
          WHEN NEW.status = 'rejected' THEN 'cancelled'
          ELSE 'not_scheduled'
        END,
        updated_at = NOW()
        WHERE proposal_id = NEW.id;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    `)
    console.log('✅ Created sync_proposal_to_job function')
    
    console.log('\nStep 3: Creating triggers...')
    
    await client.query(`
      DROP TRIGGER IF EXISTS trigger_sync_job_to_proposal ON jobs;
      CREATE TRIGGER trigger_sync_job_to_proposal
        AFTER UPDATE OF status ON jobs
        FOR EACH ROW
        WHEN (OLD.status IS DISTINCT FROM NEW.status)
        EXECUTE FUNCTION sync_job_to_proposal();
    `)
    console.log('✅ Created job-to-proposal trigger')
    
    await client.query(`
      DROP TRIGGER IF EXISTS trigger_sync_proposal_to_job ON proposals;
      CREATE TRIGGER trigger_sync_proposal_to_job
        AFTER UPDATE OF status ON proposals
        FOR EACH ROW
        WHEN (OLD.status IS DISTINCT FROM NEW.status)
        EXECUTE FUNCTION sync_proposal_to_job();
    `)
    console.log('✅ Created proposal-to-job trigger')
    
    console.log('\n=== MIGRATION COMPLETE ===')
    console.log('✅ All database changes applied successfully')
    console.log('✅ Bidirectional status sync is now active')
    
  } catch (error) {
    console.error('❌ Migration failed:', error.message)
    
    if (error.message.includes('password authentication failed')) {
      console.log('\n🔑 Need the correct database password.')
      console.log('Options:')
      console.log('1. Find password in Supabase dashboard > Settings > Database')
      console.log('2. Install Supabase CLI and use: supabase db push')
      console.log('3. Execute SQL manually in Supabase SQL Editor')
    }
  } finally {
    await client.end()
  }
}

executeSQLDirectly()
