#!/bin/bash
echo "🔧 Creating proposal approval API endpoint..."

# Create the api directory if it doesn't exist
mkdir -p app/api/proposal-approval

# Create the proposal-approval API route
cat > app/api/proposal-approval/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const {
      proposalId,
      approved,
      customerName,
      selectedAddons,
      finalTotal,
      customerNotes
    } = body

    if (!proposalId) {
      return NextResponse.json(
        { error: 'Proposal ID is required' },
        { status: 400 }
      )
    }

    const supabase = await createClient()

    // Get the current proposal to verify it exists
    const { data: proposal, error: fetchError } = await supabase
      .from('proposals')
      .select(`
        *,
        customers (
          id,
          name,
          email,
          phone,
          address
        ),
        proposal_items (
          id,
          name,
          description,
          quantity,
          unit_price,
          total_price,
          is_addon,
          is_selected
        )
      `)
      .eq('id', proposalId)
      .single()

    if (fetchError || !proposal) {
      console.error('Error fetching proposal:', fetchError)
      return NextResponse.json(
        { error: 'Proposal not found' },
        { status: 404 }
      )
    }

    // Check if proposal is already approved or rejected
    if (proposal.status === 'approved' || proposal.status === 'rejected') {
      return NextResponse.json(
        { error: 'Proposal has already been processed' },
        { status: 400 }
      )
    }

    if (approved) {
      // Handle approval
      if (!customerName) {
        return NextResponse.json(
          { error: 'Customer signature is required for approval' },
          { status: 400 }
        )
      }

      // Update selected addons if any
      if (selectedAddons && selectedAddons.length > 0) {
        const { error: addonError } = await supabase
          .from('proposal_items')
          .update({ is_selected: true })
          .eq('proposal_id', proposalId)
          .in('id', selectedAddons)

        if (addonError) {
          console.error('Error updating addons:', addonError)
        }
      }

      // Calculate final total based on selected items
      const selectedItems = proposal.proposal_items.filter((item: any) => 
        !item.is_addon || (item.is_addon && selectedAddons?.includes(item.id))
      )
      
      const subtotal = selectedItems.reduce((sum: number, item: any) => 
        sum + item.total_price, 0
      )
      
      const taxAmount = subtotal * proposal.tax_rate
      const total = subtotal + taxAmount

      // Update proposal with approval
      const { data: updatedProposal, error: updateError } = await supabase
        .from('proposals')
        .update({
          status: 'approved',
          approved_at: new Date().toISOString(),
          signed_at: new Date().toISOString(),
          signature_data: customerName,
          customer_notes: customerNotes,
          subtotal: subtotal,
          tax_amount: taxAmount,
          total: total,
          // Set payment amounts for the 50/30/20 split
          deposit_amount: total * 0.5,
          progress_amount: total * 0.3,
          final_amount: total * 0.2,
          deposit_percentage: 0.5,
          progress_percentage: 0.3,
          final_percentage: 0.2,
          current_payment_stage: 'pending_deposit',
          payment_status: 'pending'
        })
        .eq('id', proposalId)
        .select(`
          *,
          customers (
            id,
            name,
            email,
            phone,
            address
          ),
          proposal_items (
            id,
            name,
            description,
            quantity,
            unit_price,
            total_price,
            is_addon,
            is_selected
          )
        `)
        .single()

      if (updateError) {
        console.error('Error updating proposal:', updateError)
        return NextResponse.json(
          { error: 'Failed to approve proposal' },
          { status: 500 }
        )
      }

      // Log the approval activity
      await supabase
        .from('proposal_activities')
        .insert({
          proposal_id: proposalId,
          activity_type: 'proposal_approved',
          description: `Proposal approved by ${customerName}`,
          metadata: {
            customer_name: customerName,
            customer_notes: customerNotes,
            selected_addons: selectedAddons,
            final_total: total
          }
        })

      // Send notification email to business owner
      try {
        const emailResponse = await fetch(`${process.env.NEXT_PUBLIC_BASE_URL}/api/proposal-notification`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            type: 'approved',
            proposalId: proposalId,
            proposalNumber: proposal.proposal_number,
            customerName: proposal.customers.name,
            customerEmail: proposal.customers.email,
            signedBy: customerName,
            total: total,
            notes: customerNotes
          }),
        })

        if (!emailResponse.ok) {
          console.error('Failed to send approval notification email')
        }
      } catch (emailError) {
        console.error('Error sending email notification:', emailError)
        // Don't fail the approval if email fails
      }

      return NextResponse.json({ 
        success: true, 
        proposal: updatedProposal,
        message: 'Proposal approved successfully' 
      })

    } else {
      // Handle rejection
      if (!customerNotes) {
        return NextResponse.json(
          { error: 'Reason for rejection is required' },
          { status: 400 }
        )
      }

      const { data: updatedProposal, error: updateError } = await supabase
        .from('proposals')
        .update({
          status: 'rejected',
          rejected_at: new Date().toISOString(),
          customer_notes: customerNotes
        })
        .eq('id', proposalId)
        .select(`
          *,
          customers (
            id,
            name,
            email,
            phone,
            address
          ),
          proposal_items (
            id,
            name,
            description,
            quantity,
            unit_price,
            total_price,
            is_addon,
            is_selected
          )
        `)
        .single()

      if (updateError) {
        console.error('Error rejecting proposal:', updateError)
        return NextResponse.json(
          { error: 'Failed to reject proposal' },
          { status: 500 }
        )
      }

      // Log the rejection activity
      await supabase
        .from('proposal_activities')
        .insert({
          proposal_id: proposalId,
          activity_type: 'proposal_rejected',
          description: 'Proposal rejected by customer',
          metadata: {
            reason: customerNotes
          }
        })

      // Send notification email to business owner
      try {
        const emailResponse = await fetch(`${process.env.NEXT_PUBLIC_BASE_URL}/api/proposal-notification`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            type: 'rejected',
            proposalId: proposalId,
            proposalNumber: proposal.proposal_number,
            customerName: proposal.customers.name,
            customerEmail: proposal.customers.email,
            reason: customerNotes
          }),
        })

        if (!emailResponse.ok) {
          console.error('Failed to send rejection notification email')
        }
      } catch (emailError) {
        console.error('Error sending email notification:', emailError)
        // Don't fail the rejection if email fails
      }

      return NextResponse.json({ 
        success: true, 
        proposal: updatedProposal,
        message: 'Proposal rejected' 
      })
    }

  } catch (error) {
    console.error('Error processing proposal approval:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
EOF

# Check for errors
if [ $? -ne 0 ]; then
    echo "❌ Error creating proposal-approval route"
    exit 1
fi

# Commit and push
git add .
git commit -m "feat: create proposal approval API endpoint

- Handles both approval and rejection flows
- Updates proposal status and signature data
- Calculates final totals with selected add-ons
- Sets up payment amounts for 50/30/20 split
- Logs activities in proposal_activities table
- Sends email notifications (if endpoint exists)"

git push origin main

echo "✅ Proposal approval API created successfully!"
echo ""
echo "📝 Features implemented:"
echo "- ✅ Approve proposals with digital signature"
echo "- ✅ Reject proposals with reason"
echo "- ✅ Update selected add-ons"
echo "- ✅ Calculate final totals"
echo "- ✅ Set payment stage amounts (50/30/20)"
echo "- ✅ Activity logging"
echo "- ✅ Email notifications (optional)"
echo ""
echo "🧪 Test the approval flow now - it should work!"