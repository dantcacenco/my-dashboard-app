#!/bin/bash

# Fix Proposal Approval Constraint Violation
# Simple fix with proper calculations and error handling

set -e

echo "🔧 Fixing proposal approval constraint violation..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Update only the handleApprove function in CustomerProposalView
echo "📝 Updating handleApprove function with proper calculations..."

cat > fix-approval-temp.js << 'EOF'
  // Handle proposal approval - FIXED version with proper calculations
  const handleApprove = async () => {
    setIsProcessing(true)
    setError('')

    try {
      // First update selected add-ons
      for (const addon of addons) {
        const { error: addonError } = await supabase
          .from('proposal_items')
          .update({ is_selected: selectedAddons.has(addon.id) })
          .eq('id', addon.id)
        
        if (addonError) {
          console.error('Error updating addon:', addonError)
        }
      }

      // Calculate payment amounts with proper rounding to avoid floating point issues
      const total = Math.round(totals.total * 100) / 100
      const depositAmount = Math.round((total * 0.5) * 100) / 100
      const progressAmount = Math.round((total * 0.3) * 100) / 100
      const finalAmount = Math.round((total * 0.2) * 100) / 100

      // Ensure amounts add up exactly to total (handle rounding differences)
      const sumOfPayments = depositAmount + progressAmount + finalAmount
      const difference = Math.round((total - sumOfPayments) * 100) / 100
      
      // Adjust final payment if there's a rounding difference
      const adjustedFinalAmount = finalAmount + difference

      console.log('Approval calculations:', {
        subtotal: totals.subtotal,
        tax: totals.taxAmount,
        total,
        deposit: depositAmount,
        progress: progressAmount,
        final: adjustedFinalAmount,
        sum: depositAmount + progressAmount + adjustedFinalAmount
      })

      // Update proposal with calculated values
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
      }

      console.log('Updating proposal with:', updateData)

      const { data: updateResult, error: updateError } = await supabase
        .from('proposals')
        .update(updateData)
        .eq('id', proposal.id)
        .select()
        .single()

      if (updateError) {
        console.error('Full update error:', updateError)
        throw new Error(updateError.message || 'Failed to approve proposal')
      }

      console.log('Update successful:', updateResult)

      // Refresh the proposal data to show payment stages
      await refreshProposal()
      
    } catch (err: any) {
      console.error('Approval error:', err)
      setError(err.message || 'Failed to approve proposal. Please try again.')
    } finally {
      setIsProcessing(false)
    }
  }
EOF

# Use DC to edit the file
echo "🔧 Applying fix to CustomerProposalView..."
