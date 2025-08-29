import pg from 'pg'
const { Client } = pg

const client = new Client({
  connectionString: 'postgresql://postgres.dqcxwekmehrqkigcufug:sedho4-zebban-cAppoz@aws-0-us-west-1.pooler.supabase.com:5432/postgres',
  ssl: {
    rejectUnauthorized: false
  }
})

async function runMigration() {
  try {
    console.log('🚀 Connecting to database...')
    await client.connect()
    console.log('✅ Connected successfully!')

    console.log('📦 Creating time_entries table...')
    
    // Create table
    await client.query(`
      CREATE TABLE IF NOT EXISTS time_entries (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
        technician_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
        start_time TIMESTAMP WITH TIME ZONE NOT NULL,
        end_time TIMESTAMP WITH TIME ZONE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      )
    `)
    console.log('✅ Table created!')

    // Create indexes
    console.log('🔧 Creating indexes...')
    await client.query('CREATE INDEX IF NOT EXISTS idx_time_entries_job_id ON time_entries(job_id)')
    await client.query('CREATE INDEX IF NOT EXISTS idx_time_entries_technician_id ON time_entries(technician_id)')
    await client.query('CREATE INDEX IF NOT EXISTS idx_time_entries_start_time ON time_entries(start_time)')
    console.log('✅ Indexes created!')

    // Enable RLS
    console.log('🔒 Enabling RLS...')
    await client.query('ALTER TABLE time_entries ENABLE ROW LEVEL SECURITY')
    console.log('✅ RLS enabled!')

    // Drop existing policies
    const policies = [
      'Technicians can view own time entries',
      'Technicians can insert own time entries',
      'Technicians can update own time entries',
      'Admins can view all time entries'
    ]
    
    for (const policy of policies) {
      try {
        await client.query(`DROP POLICY IF EXISTS "${policy}" ON time_entries`)
      } catch (e) {
        // Ignore if policy doesn't exist
      }
    }

    // Create policies
    console.log('📜 Creating RLS policies...')
    
    await client.query(`
      CREATE POLICY "Technicians can view own time entries" ON time_entries
      FOR SELECT USING (auth.uid() = technician_id)
    `)
    
    await client.query(`
      CREATE POLICY "Technicians can insert own time entries" ON time_entries
      FOR INSERT WITH CHECK (auth.uid() = technician_id)
    `)
    
    await client.query(`
      CREATE POLICY "Technicians can update own time entries" ON time_entries
      FOR UPDATE USING (auth.uid() = technician_id)
    `)
    
    await client.query(`
      CREATE POLICY "Admins can view all time entries" ON time_entries
      FOR SELECT USING (
        EXISTS (
          SELECT 1 FROM profiles 
          WHERE profiles.id = auth.uid() 
          AND (profiles.role = 'admin' OR profiles.role = 'boss')
        )
      )
    `)
    console.log('✅ Policies created!')

    // Create trigger function
    console.log('⚡ Creating trigger...')
    await client.query(`
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = NOW();
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql
    `)
    
    await client.query('DROP TRIGGER IF EXISTS update_time_entries_updated_at ON time_entries')
    
    await client.query(`
      CREATE TRIGGER update_time_entries_updated_at
      BEFORE UPDATE ON time_entries
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column()
    `)
    console.log('✅ Trigger created!')

    // Verify table exists
    const result = await client.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'time_entries'
    `)
    
    console.log('\n🎉 Migration completed successfully!')
    console.log('📊 Table structure:')
    result.rows.forEach(row => {
      console.log(`   - ${row.column_name}: ${row.data_type}`)
    })

  } catch (error) {
    console.error('❌ Migration failed:', error.message)
  } finally {
    await client.end()
  }
}

runMigration()