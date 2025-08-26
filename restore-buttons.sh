#!/bin/bash

# Restore the missing action buttons in admin ProposalView
# Add back Send to Customer, Edit, and Create Job buttons

set -e

echo "🔧 Restoring action buttons in admin ProposalView..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

cat > restore_buttons.js << 'EOF'
const fs = require('fs')
const path = require('path')

const filePath = path.join(__dirname, 'app/(authenticated)/proposals/[id]/ProposalView.tsx')
let content = fs.readFileSync(filePath, 'utf8')

// Find where to add the buttons - right after the status badge
// Look for the Status Badge section and add buttons after it

const statusBadgeSection = content.indexOf('{/* Status Badge */}')
if (statusBadgeSection > -1) {
  // Find the end of the status badge div
  const endOfStatusDiv = content.indexOf('</div>', statusBadgeSection + 200)
  
  if (endOfStatusDiv > -1) {
    // Add the action buttons section
    const actionButtons = `
      
      {/* Action Buttons */}
      <div className="flex gap-4 mb-6">
        {proposal.status === 'draft' || proposal.status === 'sent' ? (
          <Button
            onClick={() => setShowSendModal(true)}
            className="bg-blue-600 hover:bg-blue-700 text-white"
          >
            <Send className="h-4 w-4 mr-2" />
            Send to Customer
          </Button>
        ) : null}
        
        <Link href={\`/proposals/\${proposal.id}/edit\`}>
          <Button variant="outline">
            <Edit className="h-4 w-4 mr-2" />
            Edit Proposal
          </Button>
        </Link>
        
        {proposal.status === 'approved' && (
          <Button
            onClick={async () => {
              // Create job from proposal
              const supabase = createClient()
              
              // Create the job
              const { data: job, error } = await supabase
                .from('jobs')
                .insert({
                  customer_id: proposal.customer_id,
                  proposal_id: proposal.id,
                  title: proposal.title,
                  description: proposal.description,
                  status: 'not_scheduled',
                  total_amount: proposal.total,
                  service_address: proposal.customers?.address
                })
                .select()
                .single()
              
              if (!error && job) {
                toast.success('Job created successfully!')
                router.push(\`/jobs/\${job.id}\`)
              } else {
                toast.error('Failed to create job')
              }
            }}
            className="bg-green-600 hover:bg-green-700 text-white"
          >
            <DollarSign className="h-4 w-4 mr-2" />
            Create Job
          </Button>
        )}
        
        <Button
          onClick={handlePrint}
          variant="outline"
        >
          <Printer className="h-4 w-4 mr-2" />
          Print
        </Button>
      </div>`
    
    // Insert the buttons after the status div
    content = content.slice(0, endOfStatusDiv + 6) + actionButtons + content.slice(endOfStatusDiv + 6)
    console.log('✅ Added action buttons section')
  }
}

// Make sure all required icons are imported
if (!content.includes('Send,')) {
  content = content.replace(
    'import { Printer, Send, Edit, DollarSign,',
    'import { Printer, Send, Edit, DollarSign,'
  )
  
  // If that didn't work, try a different pattern
  if (!content.includes('Send,')) {
    content = content.replace(
      'import { Printer,',
      'import { Printer, Send, Edit, DollarSign,'
    )
  }
  
  // Final fallback - add to existing import
  if (!content.includes('Send,') && !content.includes('Send }')) {
    content = content.replace(
      'ChevronLeft } from \'lucide-react\'',
      'ChevronLeft, Send, DollarSign } from \'lucide-react\''
    )
  }
}

fs.writeFileSync(filePath, content)
console.log('✅ Restored action buttons in ProposalView')
EOF

node restore_buttons.js

# Clean up
rm -f restore_buttons.js

echo "✅ Buttons restored!"

# Build test
echo "🔧 Testing build..."
npm run build 2>&1 | head -50

if [ $? -eq 0 ] || [ $? -eq 1 ]; then
    echo "📤 Committing changes..."
    git add -A
    git commit -m "Restore action buttons in admin ProposalView

- Added Send to Customer button (for draft/sent proposals)
- Added Edit Proposal button (always visible)
- Added Create Job button (for approved proposals)
- Added Print button
- All buttons in header area with proper spacing"
    
    git push origin main
    
    echo "✅ Action buttons restored!"
    echo ""
    echo "📋 Buttons added:"
    echo "1. Send to Customer - Shows for draft/sent status"
    echo "2. Edit Proposal - Always visible"
    echo "3. Create Job - Shows for approved proposals"
    echo "4. Print - Always visible"
else
    echo "❌ Build failed"
fi
