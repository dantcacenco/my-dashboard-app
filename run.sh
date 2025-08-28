#!/bin/bash

# Debug Technician Assignment Issues (Fixed Version)
# Run as: ./debug_technicians_fixed.sh from my-dashboard-app directory

set -e

echo "Debugging Technician Assignment Issues..."
echo "======================================="

# Check we're in the right directory
if [[ ! -f "package.json" ]] || [[ ! -d "app" ]]; then
    echo "Error: Must run from my-dashboard-app project root directory"
    exit 1
fi

# Restore from backup first to start clean
if [[ -f "app/(authenticated)/jobs/[id]/JobDetailView.tsx.backup" ]]; then
    cp app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx.backup app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx
    echo "Restored from backup to start clean"
fi

# Backup the current file
cp app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx.backup

echo "1. Adding comprehensive debugging to JobDetailView..."

# Create the debug function as a separate file first to avoid quote issues
cat > temp_debug_function.txt << 'FUNC_EOF'
  const loadAssignedTechnicians = async () => {
    console.log('=== TECHNICIAN ASSIGNMENT DEBUG START ===')
    console.log('Job ID:', job.id)
    console.log('Job Number:', job.job_number)
    
    try {
      // First, let's check what's in the job_technicians table for this job
      const { data: rawAssignments, error: rawError } = await supabase
        .from('job_technicians')
        .select('*')
        .eq('job_id', job.id)
      
      console.log('Raw job_technicians query result:', {
        data: rawAssignments,
        error: rawError,
        count: rawAssignments?.length || 0
      })
      
      // Now let's try the full query with profile joins
      const { data: fullData, error: fullError } = await supabase
        .from('job_technicians')
        .select(`
          *,
          profiles!technician_id (
            id,
            email,
            full_name,
            role
          )
        `)
        .eq('job_id', job.id)
      
      console.log('Full technician assignment query result:', {
        data: fullData,
        error: fullError,
        count: fullData?.length || 0
      })
      
      if (fullData && fullData.length > 0) {
        console.log('Individual assignment records:')
        fullData.forEach((assignment, index) => {
          console.log(`Assignment ${index}:`, {
            id: assignment.id,
            job_id: assignment.job_id,
            technician_id: assignment.technician_id,
            assigned_at: assignment.assigned_at,
            profile: assignment.profiles
          })
        })
      }
      
      // Let's also check if the technician exists in profiles
      const { data: techProfile, error: techError } = await supabase
        .from('profiles')
        .select('*')
        .eq('email', 'technician@gmail.com')
        .single()
      
      console.log('Technician profile lookup:', {
        data: techProfile,
        error: techError
      })
      
      // Set the assigned technicians - but let's see what we're setting
      const processedData = fullData?.map((item: any) => {
        console.log('Processing assignment item:', item)
        return item.profiles || item
      }) || []
      
      console.log('Processed technician data for setState:', processedData)
      
      setAssignedTechnicians(processedData)
      console.log('=== TECHNICIAN ASSIGNMENT DEBUG END ===')
      
    } catch (error) {
      console.error('Error in loadAssignedTechnicians:', error)
      setAssignedTechnicians([])
    }
  }
FUNC_EOF

# Now use Node.js to safely replace the function
node - << 'NODE_EOF'
const fs = require('fs');

let content = fs.readFileSync('app/(authenticated)/jobs/[id]/JobDetailView.tsx', 'utf8');
const newFunction = fs.readFileSync('temp_debug_function.txt', 'utf8');

// Find and replace the loadAssignedTechnicians function
const functionPattern = /const loadAssignedTechnicians = async \(\) => \{[\s\S]*?\n  \}/;

if (functionPattern.test(content)) {
  content = content.replace(functionPattern, newFunction.trim());
  console.log('Successfully replaced loadAssignedTechnicians function');
} else {
  console.log('Could not find existing function, will add it');
  // Find a good place to add it (after openFileViewer or similar)
  const insertPattern = /(const openFileViewer[\s\S]*?\n  \})/;
  if (insertPattern.test(content)) {
    content = content.replace(insertPattern, '$1\n\n' + newFunction.trim());
    console.log('Added function after openFileViewer');
  }
}

// Add debug button to the technician section
const titlePattern = /(<CardTitle className="flex items-center gap-2">\s*<User className="h-5 w-5" \/>\s*Assigned Technicians\s*<\/CardTitle>)/;
const debugButton = '$1\n                <Button size="sm" variant="outline" onClick={() => { console.log("Manual debug trigger"); loadAssignedTechnicians(); }}>Debug Reload</Button>';

content = content.replace(titlePattern, debugButton);

// Add a debug message when no technicians are found
const noTechPattern = /(\{assignedTechnicians\.length === 0 && userRole !== 'boss' && \(\s*<p className="text-muted-foreground">No technicians assigned yet<\/p>\s*\)\})/;
const debugMessage = `{assignedTechnicians.length === 0 && (
                  <div className="p-2 bg-yellow-50 border border-yellow-200 rounded">
                    <p className="text-sm text-yellow-800">
                      No technicians assigned (Debug: Check console for assignment data)
                    </p>
                  </div>
                )}`;

content = content.replace(noTechPattern, debugMessage);

fs.writeFileSync('app/(authenticated)/jobs/[id]/JobDetailView.tsx', content);
console.log('JobDetailView updated with debugging');
NODE_EOF

# Clean up temp file
rm temp_debug_function.txt

echo "2. Creating database inspection API endpoint..."

# Create a debug API endpoint to inspect the database directly
cat > app/api/debug-technicians/route.ts << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const supabase = await createClient()
  const { searchParams } = new URL(request.url)
  const jobId = searchParams.get('job_id')
  
  if (!jobId) {
    return NextResponse.json({ error: 'job_id parameter required' }, { status: 400 })
  }

  try {
    console.log('Debug API - Job ID:', jobId)
    
    // 1. Check job exists
    const { data: job, error: jobError } = await supabase
      .from('jobs')
      .select('*')
      .eq('id', jobId)
      .single()
    
    // 2. Check raw job_technicians entries
    const { data: rawAssignments, error: rawError } = await supabase
      .from('job_technicians')
      .select('*')
      .eq('job_id', jobId)
    
    // 3. Check job_technicians with profiles
    const { data: assignments, error: assignError } = await supabase
      .from('job_technicians')
      .select(`
        *,
        profiles!technician_id (
          id,
          email,
          full_name,
          role
        )
      `)
      .eq('job_id', jobId)
    
    // 4. Check specific technician profile
    const { data: techProfile, error: techError } = await supabase
      .from('profiles')
      .select('*')
      .eq('email', 'technician@gmail.com')
    
    // 5. Check all technicians
    const { data: allTechs, error: allTechError } = await supabase
      .from('profiles')
      .select('*')
      .eq('role', 'technician')
    
    return NextResponse.json({
      job: { data: job, error: jobError },
      rawAssignments: { data: rawAssignments, error: rawError },
      assignments: { data: assignments, error: assignError },
      techProfile: { data: techProfile, error: techError },
      allTechs: { data: allTechs, error: allTechError },
      summary: {
        jobExists: !!job,
        jobNumber: job?.job_number,
        assignmentCount: rawAssignments?.length || 0,
        technicianEmail: techProfile?.[0]?.email,
        technicianId: techProfile?.[0]?.id
      }
    })
    
  } catch (error) {
    console.error('Debug API error:', error)
    return NextResponse.json({ 
      error: 'Database query failed', 
      details: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 })
  }
}
EOF

echo "3. Running TypeScript check..."
if ! npx tsc --noEmit; then
    echo "TypeScript errors found. Restoring backup..."
    cp app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx.backup app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx
    exit 1
fi

echo "4. Git commit and push..."
git add -A
git commit -m "Debug: Add comprehensive technician assignment debugging (Fixed)

- Fixed quote escaping issues from previous script
- Added extensive console logging to loadAssignedTechnicians function
- Shows raw database queries and results step by step
- Added visual debug indicators when no technicians assigned
- Created debug API endpoint at /api/debug-technicians
- Added manual Debug Reload button to technician section
- Logs individual assignment records and profile data
- Uses Node.js for safer string manipulation"

if ! git push origin main; then
    echo "Git push failed, but changes committed locally"
fi

echo ""
echo "SUCCESS! Fixed technician debugging added!"
echo "========================================"
echo ""
echo "DEBUGGING STEPS:"
echo "1. Visit: https://my-dashboard-app-tau.vercel.app/jobs/3915209b-93f8-4474-990f-533090b98138"
echo "2. Open browser console (F12)"
echo "3. Look for debug output starting with '=== TECHNICIAN ASSIGNMENT DEBUG START ==='"
echo "4. Click the 'Debug Reload' button in the Assigned Technicians section"
echo "5. Check API: https://my-dashboard-app-tau.vercel.app/api/debug-technicians?job_id=3915209b-93f8-4474-990f-533090b98138"
echo ""
echo "This will show exactly what data exists in the database vs what's displayed"

# Cleanup
rm -f app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx.backup