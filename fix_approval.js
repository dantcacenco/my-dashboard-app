const fs = require('fs')
const path = require('path')

const filePath = path.join(__dirname, 'app/proposal/view/[token]/CustomerProposalView.tsx')
let content = fs.readFileSync(filePath, 'utf8')

// Find the handleApprove function and fix it
const oldUpdate = `      // Update proposal status to accepted
      const updateData = {
        status: 'accepted',
        subtotal: Math.round(totals.subtotal * 100) / 100,
        tax_amount: Math.round(totals.taxAmount * 100) / 100,
        total: total,
        deposit_amount: depositAmount,
        progress_payment_amount: progressAmount,
        final_payment_amount: adjustedFinalAmount,
        payment_stage: 'deposit',
        approved_at: new Date().toISOString()
      }`

const newUpdate = `      // Update proposal status to accepted
      const updateData = {
        status: 'accepted',
        subtotal: Math.round(totals.subtotal * 100) / 100,
        tax_amount: Math.round(totals.taxAmount * 100) / 100,
        total: total,
        deposit_amount: depositAmount,
        progress_payment_amount: progressAmount,
        final_payment_amount: adjustedFinalAmount,
        // payment_stage removed - may not exist or have constraint
        approved_at: new Date().toISOString()
      }`

if (content.includes(oldUpdate)) {
    content = content.replace(oldUpdate, newUpdate)
    fs.writeFileSync(filePath, content)
    console.log('✅ Fixed handleApprove - removed payment_stage field')
} else {
    console.log('⚠️ Could not find exact match, trying alternative fix...')
    
    // Alternative: just remove the payment_stage line
    const regex = /payment_stage:\s*['"]deposit['"]\s*,?\s*\n/g
    content = content.replace(regex, '')
    fs.writeFileSync(filePath, content)
    console.log('✅ Removed payment_stage line from update')
}
