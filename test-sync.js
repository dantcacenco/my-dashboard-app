const { createClient } = require('@supabase/supabase-js');

// Your Supabase credentials
const supabaseUrl = 'https://dqcxwekmehrqkigcufug.supabase.co';
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxY3h3ZWttZWhycWtpZ2N1ZnVnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzA5NDk0NiwiZXhwIjoyMDY4NjcwOTQ2fQ.W2NurXdGtch5rjaKal2hnBKwsCxC39h-GQyzrpRBqJk';

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function testSyncTriggers() {
  console.log('🔄 Testing Bidirectional Status Synchronization\n');
  console.log('='.repeat(60));
  
  // Find a job with a linked proposal
  const { data: jobs } = await supabase
    .from('jobs')
    .select('id, status, proposal_id')
    .not('proposal_id', 'is', null)
    .limit(5);
    
  if (!jobs || jobs.length === 0) {
    console.log('❌ No jobs with linked proposals found');
    return;
  }
  
  // Get the first job and its proposal
  const job = jobs[0];
  const { data: proposal } = await supabase
    .from('proposals')
    .select('id, status')
    .eq('id', job.proposal_id)
    .single();
    
  if (!proposal) {
    console.log('❌ Could not find proposal for job');
    return;
  }
  
  console.log('📋 Found linked pair:');
  console.log(`  Job: ${job.id.slice(0,8)} (status: "${job.status}")`);
  console.log(`  Proposal: ${proposal.id.slice(0,8)} (status: "${proposal.status}")`);
  console.log('\n' + '-'.repeat(60));
  
  // Test 1: Change proposal status and check if job updates
  console.log('\n🧪 TEST 1: Proposal → Job Sync');
  console.log('  Setting proposal to "deposit paid"...');
  
  await supabase
    .from('proposals')
    .update({ status: 'deposit paid' })
    .eq('id', proposal.id);
    
  // Check job status
  const { data: updatedJob1 } = await supabase
    .from('jobs')
    .select('status')
    .eq('id', job.id)
    .single();
    
  if (updatedJob1.status === 'scheduled') {
    console.log('  ✅ Job automatically changed to "scheduled"!');
  } else {
    console.log(`  ❌ Job status unchanged: "${updatedJob1.status}" (expected: "scheduled")`);
    console.log('     → Sync trigger not working');
  }
  
  // Test 2: Change job status and check if proposal updates  
  console.log('\n🧪 TEST 2: Job → Proposal Sync');
  console.log('  Setting job to "in_progress"...');
  
  await supabase
    .from('jobs')
    .update({ status: 'in_progress' })
    .eq('id', job.id);
    
  // Check proposal status
  const { data: updatedProposal } = await supabase
    .from('proposals')
    .select('status')
    .eq('id', proposal.id)
    .single();
    
  if (updatedProposal.status === 'rough-in paid') {
    console.log('  ✅ Proposal automatically changed to "rough-in paid"!');
  } else {
    console.log(`  ❌ Proposal status: "${updatedProposal.status}" (expected: "rough-in paid")`);
    console.log('     → Sync trigger not working');
  }
  
  // Test 3: Test completed status
  console.log('\n🧪 TEST 3: Completed Status Sync');
  console.log('  Setting job to "completed"...');
  
  await supabase
    .from('jobs')
    .update({ status: 'completed' })
    .eq('id', job.id);
    
  const { data: finalProposal } = await supabase
    .from('proposals')
    .select('status')
    .eq('id', proposal.id)
    .single();
    
  if (finalProposal.status === 'completed') {
    console.log('  ✅ Proposal automatically changed to "completed"!');
  } else {
    console.log(`  ❌ Proposal status: "${finalProposal.status}" (expected: "completed")`);
  }
  
  // Restore original statuses
  console.log('\n🔄 Restoring original statuses...');
  await supabase.from('jobs').update({ status: job.status }).eq('id', job.id);
  await supabase.from('proposals').update({ status: proposal.status }).eq('id', proposal.id);
  
  console.log('\n' + '='.repeat(60));
  console.log('📊 SYNC TEST COMPLETE');
  console.log('='.repeat(60));
  
  // Summary
  const trigger1Works = updatedJob1.status === 'scheduled';
  const trigger2Works = updatedProposal.status === 'rough-in paid';
  const trigger3Works = finalProposal.status === 'completed';
  
  if (trigger1Works && trigger2Works && trigger3Works) {
    console.log('\n✅ ALL SYNC TRIGGERS ARE WORKING PERFECTLY!');
  } else {
    console.log('\n⚠️  SYNC TRIGGERS NEED TO BE CREATED');
    console.log('\nRun this SQL in Supabase:');
    console.log('1. sql-migrations/02-create-sync-triggers.sql');
  }
}

testSyncTriggers().catch(console.error);