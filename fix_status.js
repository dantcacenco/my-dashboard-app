const fs = require('fs')
const path = require('path')

const filePath = path.join(__dirname, 'app/proposal/view/[token]/CustomerProposalView.tsx')
let content = fs.readFileSync(filePath, 'utf8')

// Replace 'accepted' with 'approved' in the handleApprove function
content = content.replace(
  "status: 'accepted',",
  "status: 'approved',"
)

// Also fix the condition that shows payment stages
content = content.replace(
  "if (proposal.status === 'accepted' || proposal.status === 'approved')",
  "if (proposal.status === 'approved')"
)

// Fix the polling condition
content = content.replace(
  "if (proposal.status === 'accepted' && proposal.payment_stage !== 'complete')",
  "if (proposal.status === 'approved')"
)

fs.writeFileSync(filePath, content)
console.log('✅ Fixed status value to use "approved" instead of "accepted"')
