#!/bin/bash
echo "🔧 Changing Progress to Rough-In and fixing payment error handling..."

# Update CustomerProposalView to use "Rough-In" instead of "Progress"
sed -i 's/30% Progress/30% Rough-In/g' app/proposal/view/\[token\]/CustomerProposalView.tsx
sed -i 's/progress/roughin/g' app/proposal/view/\[token\]/CustomerProposalView.tsx
sed -i 's/Progress Payment/Rough-In Payment/g' app/proposal/view/\[token\]/CustomerProposalView.tsx
sed -i 's/Pay Progress/Pay Rough-In/g' app/proposal/view/\[token\]/CustomerProposalView.tsx
sed -i 's/roughin payment first/rough-in payment first/g' app/proposal/view/\[token\]/CustomerProposalView.tsx
sed -i 's/Complete deposit payment first/Complete deposit payment first/g' app/proposal/view/\[token\]/CustomerProposalView.tsx
sed -i 's/Complete roughin payment first/Complete rough-in payment first/g' app/proposal/view/\[token\]/CustomerProposalView.tsx

# Fix the payment stage names to match
sed -i "s/'deposit' | 'progress' | 'final'/'deposit' | 'roughin' | 'final'/g" app/proposal/view/\[token\]/CustomerProposalView.tsx
sed -i "s/getPaymentStageStatus('progress')/getPaymentStageStatus('roughin')/g" app/proposal/view/\[token\]/CustomerProposalView.tsx
sed -i "s/handlePayment('progress')/handlePayment('roughin')/g" app/proposal/view/\[token\]/CustomerProposalView.tsx
sed -i "s/currentPaymentStage === 'progress'/currentPaymentStage === 'roughin'/g" app/proposal/view/\[token\]/CustomerProposalView.tsx
sed -i "s/stage === 'progress'/stage === 'roughin'/g" app/proposal/view/\[token\]/CustomerProposalView.tsx
sed -i "s/case 'progress':/case 'roughin':/g" app/proposal/view/\[token\]/CustomerProposalView.tsx

# Update the payment success page to handle roughin stage and better error handling
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
    console.error('Missing session_id or proposal_id in payment success page')
    redirect('/proposals')
  }

  const supabase = await createClient()
  let customerViewToken: string | null = null

  try {
    // First get the proposal to have the customer_view_token for redirects
    const { data: proposalData, error: proposalError } = await supabase
      .from('proposals')
      .select('customer_view_token')
      .eq('id', proposal_id)
      .single()

    if (proposalError || !proposalData) {
      console.error('Error fetching proposal for redirect:', proposalError)
      redirect('/proposals')
    }

    customerViewToken = proposalData.customer_view_token

    // Verify the Stripe session
    console.log('Verifying Stripe session:', session_id)
    const session = await stripe.checkout.sessions.retrieve(session_id)
    
    if (session.payment_status !== 'paid') {
      console.error('Payment not completed, status:', session.payment_status)
      redirect(`/proposal/view/${customerViewToken}?payment=failed`)
    }

    // Get full proposal details
    const { data: proposal, error: fetchError } = await supabase
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

    if (fetchError || !proposal) {
      console.error('Error fetching full proposal:', fetchError)
      redirect(`/proposal/view/${customerViewToken}?payment=error`)
    }

    // Determine which payment stage was completed
    const paymentStage = session.metadata?.payment_stage || 'deposit'
    console.log('Processing payment for stage:', paymentStage)
    
    const now = new Date().toISOString()
    const paidAmount = session.amount_total ? session.amount_total / 100 : 0

    // Update proposal with payment information based on stage
    const updateData: any = {
      payment_method: session.metadata?.payment_type || 'card',
      stripe_session_id: session_id,
    }

    switch (paymentStage) {
      case 'deposit':
        updateData.payment_status = 'deposit_paid'
        updateData.deposit_paid_at = now
        updateData.deposit_amount = paidAmount
        updateData.current_payment_stage = 'deposit'
        updateData.total_paid = paidAmount
        break
      case 'roughin':
        updateData.payment_status = 'roughin_paid'
        updateData.progress_paid_at = now
        updateData.progress_payment_amount = paidAmount
        updateData.current_payment_stage = 'roughin'
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

    console.log('Updating proposal with:', updateData)

    const { error: updateError } = await supabase
      .from('proposals')
      .update(updateData)
      .eq('id', proposal_id)

    if (updateError) {
      console.error('Error updating proposal:', updateError)
      throw updateError
    }

    // Log the payment activity
    const { error: activityError } = await supabase
      .from('proposal_activities')
      .insert({
        proposal_id: proposal_id,
        activity_type: `${paymentStage}_payment_received`,
        description: `${paymentStage === 'roughin' ? 'Rough-in' : paymentStage.charAt(0).toUpperCase() + paymentStage.slice(1)} payment received via ${session.metadata?.payment_type || 'card'}`,
        metadata: {
          stripe_session_id: session_id,
          amount: paidAmount,
          payment_method: session.metadata?.payment_type || 'card',
          customer_email: proposal.customers.email,
          payment_stage: paymentStage
        }
      })

    if (activityError) {
      console.error('Error logging activity:', activityError)
      // Don't fail the payment process if activity logging fails
    }

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
    console.log('Payment processed successfully, redirecting to:', `/proposal/view/${customerViewToken}`)
    redirect(`/proposal/view/${customerViewToken}?payment=success&stage=${paymentStage}`)

  } catch (error) {
    console.error('Error processing payment success:', error)
    
    // Use the token we got earlier, or try to fetch it again
    if (!customerViewToken) {
      const { data } = await supabase
        .from('proposals')
        .select('customer_view_token')
        .eq('id', proposal_id)
        .single()
      
      customerViewToken = data?.customer_view_token || proposal_id
    }
    
    redirect(`/proposal/view/${customerViewToken}?payment=error`)
  }
}
EOF

# Check for errors
if [ $? -ne 0 ]; then
    echo "❌ Error updating payment-success page"
    exit 1
fi

# Update create-payment to use roughin stage
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

    console.log('Creating payment for stage:', payment_stage, 'amount:', amount)

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

    console.log('Stripe session created:', session.id)

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

# Fix the success message alert to handle roughin
sed -i "s/Your \${stage} payment/Your \${stage === 'roughin' ? 'rough-in' : stage} payment/g" app/proposal/view/\[token\]/CustomerProposalView.tsx

# Commit and push
git add .
git commit -m "fix: change Progress to Rough-In and improve payment error handling

- Changed all 'Progress' references to 'Rough-In' in UI
- Added detailed console logging for payment debugging
- Improved error handling in payment success page
- Ensure customer_view_token is always available for redirects
- Fixed payment stage naming consistency (roughin)
- Better error messages for troubleshooting"

git push origin main

echo "✅ Changes completed successfully!"
echo ""
echo "📝 Changes made:"
echo "- 'Progress' → 'Rough-In' throughout the UI"
echo "- Added detailed console logging to track payment flow"
echo "- Improved error handling to identify issues"
echo "- Payment updates only happen AFTER Stripe confirms payment"
echo ""
echo "🔍 To debug the error:"
echo "1. Open browser Developer Console (F12)"
echo "2. Try the rough-in payment again"
echo "3. Check the Console tab for error messages"
echo "4. Check the Network tab for failed requests"
echo ""
echo "The payment IS being properly verified through Stripe before updating the database."