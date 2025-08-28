const { createClient } = require('@supabase/supabase-js')
require('dotenv').config({ path: '.env.local' })

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY

const supabase = createClient(supabaseUrl, supabaseKey)

async function exploreSchema() {
  console.log('=== DATABASE SCHEMA EXPLORATION ===\n')
  
  try {
    // Focus on key tables related to jobs and proposals
    const keyTables = ['jobs', 'proposals', 'customers', 'job_technicians', 'profiles']
    
    for (const tableName of keyTables) {
      console.log(`\n=== TABLE: ${tableName.toUpperCase()} ===`)
      
      // Get sample data to understand structure
      const { data: sampleData, error: sampleError } = await supabase
        .from(tableName)
        .select('*')
        .limit(2)
      
      if (sampleError) {
        console.error(`Error getting sample data for ${tableName}:`, sampleError)
        continue
      }
      
      if (sampleData && sampleData.length > 0) {
        console.log('Sample data structure:')
        const firstRow = sampleData[0]
        Object.keys(firstRow).forEach(key => {
          const value = firstRow[key]
          const type = typeof value
          console.log(`  - ${key}: ${type} (example: ${value})`)
        })
        
        console.log('\nFirst few rows:')
        sampleData.forEach((row, index) => {
          console.log(`  Row ${index + 1}:`, JSON.stringify(row, null, 2))
        })
      } else {
        console.log('\nNo data found in table')
      }
    }
    
    // Examine the specific job we're working with
    console.log('\n=== SPECIFIC JOB ANALYSIS ===')
    const jobId = '3915209b-93f8-4474-990f-533090b98138'
    
    const { data: jobData, error: jobError } = await supabase
      .from('jobs')
      .select(`
        *,
        customers (
          id, name, email
        ),
        proposals (
          id, proposal_number, status, total_amount
        )
      `)
      .eq('id', jobId)
      .single()
    
    if (jobError) {
      console.error('Error getting job data:', jobError)
    } else {
      console.log('Job details:', JSON.stringify(jobData, null, 2))
    }
    
    // Check job-proposal relationships
    console.log('\n=== JOB-PROPOSAL RELATIONSHIPS ===')
    const { data: allJobs, error: allJobsError } = await supabase
      .from('jobs')
      .select('id, job_number, proposal_id, customer_id')
      .limit(10)
    
    if (allJobsError) {
      console.error('Error getting job relationships:', allJobsError)
    } else {
      console.log('Jobs with proposal_id:')
      allJobs?.forEach(job => {
        console.log(`  Job ${job.job_number}: proposal_id=${job.proposal_id}, customer_id=${job.customer_id}`)
      })
    }
    
  } catch (error) {
    console.error('General error:', error)
  }
}

exploreSchema()
