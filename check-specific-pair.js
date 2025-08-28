const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://dqcxwekmehrqkigcufug.supabase.co';
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxY3h3ZWttZWhycWtpZ2N1ZnVnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzA5NDk0NiwiZXhwIjoyMDY4NjcwOTQ2fQ.W2NurXdGtch5rjaKal2hnBKwsCxC39h-GQyzrpRBqJk';

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function checkSpecificJobProposal() {
  // Check the specific job-proposal pair mentioned
  const jobNumber = 'JOB-20250819-001';
  const proposalId = '8532ae78-b34f-430a-95da-4ede2805f3a3';
  
  // Get job details
  const { data: job } = await supabase
    .from('jobs')
    .select('id, job_number, status, proposal_id')
    .eq('job_number', jobNumber)
    .single();
    
  // Get proposal details
  const { data: proposal } = await supabase
    .from('proposals')
    .select('id, status, proposal_number')
    .eq('id', proposalId)
    .single();
    
  console.log('🔍 Checking specific Job-Proposal pair:\n');
  console.log('Job:', {
    number: job?.job_number,
    status: job?.status,
    proposal_id: job?.proposal_id
  });
  
  console.log('\nProposal:', {
    id: proposal?.id,
    number: proposal?.proposal_number,
    status: proposal?.status
  });
  
  console.log('\n📊 Analysis:');
  if (job?.proposal_id === proposalId) {
    console.log('✅ Job and Proposal are correctly linked');
  } else {
    console.log('❌ Job proposal_id does not match:', job?.proposal_id);
  }
  
  console.log('\nStatus mismatch:');
  console.log(`- Job shows: "${job?.status}"`);
  console.log(`- Proposal shows: "${proposal?.status}"`);
  console.log(`- Should display proposal status when more specific`);
}

checkSpecificJobProposal().catch(console.error);