#!/bin/bash
echo "🔧 Fixing payment progress display and redirect issues..."

# First, update the proposal approval API to properly initialize payment amounts
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
          payment_status: 'pending',
          // Initialize payment tracking to 0
          total_paid: 0,
          deposit_paid_at: null,
          progress_paid_at: null,
          final_paid_at: null,
          progress_payment_amount: null,
          final_payment_amount: null
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
    echo "❌ Error updating proposal-approval route"
    exit 1
fi

# Now update the create-payment API to use customer_view_token in redirect URLs
cat > app/api/create-payment/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server'
import Stripe from 'stripe'
import { createClient } from '@/lib/supabase/server'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2025-07-30.basil'
})

export async function POST(request: NextRequest) {
  try {
    const {
      proposal_id,
      proposal_number,
      customer_name,
      customer_email,
      amount,
      payment_type,
      description,
      payment_stage
    } = await request.json()

    if (!proposal_id || !amount || !customer_email) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    // Get the customer_view_token for the proposal
    const supabase = await createClient()
    const { data: proposal, error: fetchError } = await supabase
      .from('proposals')
      .select('customer_view_token')
      .eq('id', proposal_id)
      .single()

    if (fetchError || !proposal || !proposal.customer_view_token) {
      console.error('Error fetching proposal:', fetchError)
      return NextResponse.json(
        { error: 'Proposal not found' },
        { status: 404 }
      )
    }

    // Define payment method types based on selection
    const paymentMethodTypes = payment_type === 'ach' 
      ? ['us_bank_account' as const] 
      : ['card' as const]

    // Create Stripe checkout session
    const session = await stripe.checkout.sessions.create({
      payment_method_types: paymentMethodTypes,
      line_items: [
        {
          price_data: {
            currency: 'usd',
            product_data: {
              name: `Service Pro - ${description}`,
              description: `${description} for HVAC services proposal ${proposal_number}`,
              images: [] // Add your logo URL here if you have one
            },
            unit_amount: Math.round(amount * 100) // Convert to cents
          },
          quantity: 1
        }
      ],
      mode: 'payment',
      customer_email: customer_email,
      success_url: `${process.env.NEXT_PUBLIC_BASE_URL}/proposal/payment-success?session_id={CHECKOUT_SESSION_ID}&proposal_id=${proposal_id}`,
      cancel_url: `${process.env.NEXT_PUBLIC_BASE_URL}/proposal/view/${proposal.customer_view_token}?payment=cancelled`,
      metadata: {
        proposal_id,
        proposal_number,
        customer_name,
        payment_type: payment_type || 'card',
        payment_stage: payment_stage || 'deposit',
        customer_view_token: proposal.customer_view_token
      },
      billing_address_collection: 'required',
      phone_number_collection: {
        enabled: true
      },
      // For ACH payments, add additional configuration
      ...(payment_type === 'ach' && {
        payment_method_options: {
          us_bank_account: {
            financial_connections: {
              permissions: ['payment_method']
            }
          }
        }
      })
    })

    return NextResponse.json({ 
      checkout_url: session.url,
      session_id: session.id 
    })

  } catch (error) {
    console.error('Error creating Stripe checkout session:', error)
    return NextResponse.json(
      { error: 'Failed to create payment session' },
      { status: 500 }
    )
  }
}
EOF

# Check for errors
if [ $? -ne 0 ]; then
    echo "❌ Error updating create-payment route"
    exit 1
fi

# Update payment-success page to use customer_view_token for redirect
cat > app/proposal/payment-success/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import Stripe from 'stripe'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2025-07-30.basil'
})

interface PageProps {
  searchParams: Promise<{ session_id?: string; proposal_id?: string }>
}

export default async function PaymentSuccessPage({ searchParams }: PageProps) {
  const { session_id, proposal_id } = await searchParams
  
  if (!session_id || !proposal_id) {
    redirect('/proposals')
  }

  const supabase = await createClient()

  try {
    // Verify the Stripe session
    const session = await stripe.checkout.sessions.retrieve(session_id)
    
    if (session.payment_status !== 'paid') {
      // Get customer_view_token for redirect
      const { data: proposal } = await supabase
        .from('proposals')
        .select('customer_view_token')
        .eq('id', proposal_id)
        .single()
      
      redirect(`/proposal/view/${proposal?.customer_view_token || proposal_id}?payment=failed`)
    }

    // Get proposal details
    const { data: proposal } = await supabase
      .from('proposals')
      .select(`
        *,
        customers (
          id,
          name,
          email,
          phone
        )
      `)
      .eq('id', proposal_id)
      .single()

    if (!proposal) {
      redirect('/proposals')
    }

    // Determine which payment stage was completed
    const paymentStage = session.metadata?.payment_stage || 'deposit'
    const now = new Date().toISOString()

    // Update proposal with payment information based on stage
    const updateData: any = {
      payment_method: session.metadata?.payment_type || 'card',
      stripe_session_id: session_id,
    }

    // Get the actual paid amount
    const paidAmount = session.amount_total ? session.amount_total / 100 : 0

    switch (paymentStage) {
      case 'deposit':
        updateData.payment_status = 'deposit_paid'
        updateData.deposit_paid_at = now
        updateData.deposit_amount = paidAmount
        updateData.current_payment_stage = 'deposit'
        updateData.total_paid = paidAmount
        break
      case 'progress':
        updateData.payment_status = 'progress_paid'
        updateData.progress_paid_at = now
        updateData.progress_payment_amount = paidAmount
        updateData.current_payment_stage = 'progress'
        updateData.total_paid = (proposal.deposit_amount || 0) + paidAmount
        break
      case 'final':
        updateData.payment_status = 'paid'
        updateData.final_paid_at = now
        updateData.final_payment_amount = paidAmount
        updateData.current_payment_stage = 'final'
        updateData.total_paid = (proposal.deposit_amount || 0) + 
                               (proposal.progress_payment_amount || 0) + 
                               paidAmount
        break
    }

    await supabase
      .from('proposals')
      .update(updateData)
      .eq('id', proposal_id)

    // Log the payment activity
    await supabase
      .from('proposal_activities')
      .insert({
        proposal_id: proposal_id,
        activity_type: `${paymentStage}_payment_received`,
        description: `${paymentStage.charAt(0).toUpperCase() + paymentStage.slice(1)} payment received via ${session.metadata?.payment_type || 'card'}`,
        metadata: {
          stripe_session_id: session_id,
          amount: paidAmount,
          payment_method: session.metadata?.payment_type || 'card',
          customer_email: proposal.customers.email,
          payment_stage: paymentStage
        }
      })

    // Send notification email to business
    try {
      await fetch(`${process.env.NEXT_PUBLIC_BASE_URL}/api/payment-notification`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          proposal_id: proposal_id,
          proposal_number: proposal.proposal_number,
          customer_name: proposal.customers.name,
          customer_email: proposal.customers.email,
          amount: paidAmount,
          payment_method: session.metadata?.payment_type || 'card',
          stripe_session_id: session_id,
          payment_stage: paymentStage
        })
      })
    } catch (emailError) {
      console.error('Failed to send payment notification email:', emailError)
      // Don't fail the whole process if email fails
    }

    // Redirect back to proposal view with success message
    redirect(`/proposal/view/${proposal.customer_view_token}?payment=success&stage=${paymentStage}`)

  } catch (error) {
    console.error('Error processing payment success:', error)
    
    // Get customer_view_token for error redirect
    const { data: proposal } = await supabase
      .from('proposals')
      .select('customer_view_token')
      .eq('id', proposal_id)
      .single()
    
    redirect(`/proposal/view/${proposal?.customer_view_token || proposal_id}?payment=error`)
  }
}
EOF

# Check for errors
if [ $? -ne 0 ]; then
    echo "❌ Error updating payment-success page"
    exit 1
fi

# Commit and push
git add .
git commit -m "fix: payment progress display and redirect issues

- Initialize total_paid to 0 on approval (not null)
- Clear all payment amounts on approval to ensure clean state
- Use customer_view_token for all redirects (not proposal ID)
- Fix cancel and error redirects to use correct token
- Properly calculate total_paid after each payment stage"

git push origin main

echo "✅ Payment issues fixed successfully!"
echo ""
echo "📝 Changes made:"
echo "- Progress bar now shows $0.00 (0%) on initial approval"
echo "- All redirects use customer_view_token (no more 404s)"
echo "- Payment success/cancel/error all redirect to correct URL"
echo "- Total paid amount properly tracked through all stages"
echo ""
echo "🧪 Test the flow again:"
echo "1. The progress bar should show 0% and $0.00 paid"
echo "2. Payment should redirect back to the proposal view"
echo "3. Progress bar should update after successful payment"