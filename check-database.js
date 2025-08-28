const { createClient } = require('@supabase/supabase-js');

// Your Supabase credentials
const supabaseUrl = 'https://dqcxwekmehrqkigcufug.supabase.co';
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxY3h3ZWttZWhycWtpZ2N1ZnVnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzA5NDk0NiwiZXhwIjoyMDY4NjcwOTQ2fQ.W2NurXdGtch5rjaKal2hnBKwsCxC39h-GQyzrpRBqJk';

// Create Supabase client with service role (full access)
const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function checkDatabaseState() {
  console.log('🔍 Checking current database state...\n');
  
  // 1. Check if we can connect and read proposals
  const { data: proposals, error } = await supabase
    .from('proposals')
    .select('id, status, proposal_number')
    .limit(5);
    
  if (error) {
    console.log('❌ Error connecting to database:', error.message);
    return { canConnect: false };
  }
  
  console.log('✅ Successfully connected to database!');
  console.log('Sample proposals:');
  proposals.forEach(p => {
    console.log(`  - ${p.proposal_number}: status = "${p.status}"`);
  });
  
  // 2. Check if we can read jobs
  const { data: jobs, error: jobError } = await supabase
    .from('jobs')
    .select('id, status, proposal_id')    .limit(5);
    
  if (!jobError) {
    console.log('\nSample jobs:');
    jobs.forEach(j => {
      console.log(`  - Job ${j.id.slice(0,8)}: status = "${j.status}", proposal_id = ${j.proposal_id ? j.proposal_id.slice(0,8) : 'none'}`);
    });
  }
  
  // 3. Test if new statuses work
  console.log('\n🧪 Testing new payment statuses...');
  
  // Get a test proposal
  const { data: testProposal } = await supabase
    .from('proposals')
    .select('id, status')
    .eq('status', 'draft')
    .limit(1)
    .single();
    
  if (testProposal) {
    console.log(`\nTesting with proposal ${testProposal.id.slice(0,8)}...`);
    console.log(`Current status: "${testProposal.status}"`);
    
    // Try to set a new payment status
    const { error: updateError } = await supabase
      .from('proposals')
      .update({ status: 'deposit paid' })
      .eq('id', testProposal.id);
      
    if (updateError) {
      console.log('❌ Cannot set status to "deposit paid"');
      console.log(`   Error: ${updateError.message}`);
      console.log('   → Database constraints need to be updated!');
      return { needsMigration: true };
    } else {
      console.log('✅ Successfully set status to "deposit paid"!');
      
      // Restore original status
      await supabase
        .from('proposals')
        .update({ status: testProposal.status })
        .eq('id', testProposal.id);
        
      console.log('   (Status restored to original)');
      return { needsMigration: false };
    }
  } else {
    console.log('⚠️  No draft proposals found to test with');
    
    // Try a different approach - just try to insert a test row
    const testId = 'test-' + Date.now();
    const { error: insertError } = await supabase
      .from('proposals')
      .insert({
        id: crypto.randomUUID(),
        proposal_number: testId,
        title: 'Test Proposal',
        status: 'deposit paid',
        subtotal: 100,
        tax_rate: 0.08,
        tax_amount: 8,
        total: 108,
        customer_id: (await supabase.from('customers').select('id').limit(1).single()).data.id,
        created_by: (await supabase.from('auth.users').select('id').limit(1).single()).data?.id || '00000000-0000-0000-0000-000000000000'
      });
      
    if (insertError) {
      console.log('❌ Cannot create proposal with "deposit paid" status');
      console.log(`   Error: ${insertError.message}`);
      console.log('   → Database constraints need to be updated!');
      return { needsMigration: true };
    } else {
      console.log('✅ New payment statuses are working!');
      // Clean up test proposal
      await supabase.from('proposals').delete().eq('proposal_number', testId);
      return { needsMigration: false };
    }
  }
}

// Run the check
checkDatabaseState()
  .then(result => {
    console.log('\n' + '='.repeat(60));
    console.log('📊 DATABASE CHECK COMPLETE');
    console.log('='.repeat(60));
    
    if (result.needsMigration === true) {
      console.log('\n⚠️  ACTION REQUIRED: Database needs migration!');
      console.log('\n📝 Next Steps:');
      console.log('1. Go to Supabase SQL Editor');
      console.log('2. Run: sql-migrations/01-update-proposal-statuses.sql');
      console.log('3. Run: sql-migrations/02-create-sync-triggers.sql');
      console.log('4. Run: sql-migrations/03-test-sync-system.sql');
      console.log('\nOr I can try to execute them programmatically if you prefer.');
    } else if (result.needsMigration === false) {
      console.log('\n✅ Database is already updated with new statuses!');
      console.log('   Sync triggers may still need to be created.');
    }
  })
  .catch(err => {
    console.error('Error:', err);
  });