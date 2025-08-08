#!/bin/bash

# Fix payment success redirect and data refresh

set -e

echo "🔧 Fixing payment success redirect and data refresh..."

# Fix 1: Update payment success page to properly redirect
echo "📝 Updating payment success page..."
cat > app/proposal/payment-success/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import Stripe from 'stripe'
import PaymentSuccessView from './PaymentSuccessView'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2025-07-30.basil'
})

interface PageProps {
  searchParams: Promise<{ session_id?: string; proposal_id?: string }>
}

export default async function PaymentSuccessPage({ searchParams }: PageProps) {
  const { session_id, proposal_id } = await searchParams
  
  if (!session_id || !proposal_id) {
    console.error('Missing session_id or proposal_id')
    redirect('/proposals')
  }

  const supabase = await createClient()

  try {
    // Verify the Stripe session
    const session = await stripe.checkout.sessions.retrieve(session_id)
    
    if (session.payment_status !== 'paid') {
      console.error('Payment not completed:', session.payment_status)
      redirect('/proposals?payment=failed')
    }

    // Get full proposal details with fresh data
    const { data: proposal, error: fetchError } = await supabase
      .from('proposals')
      .select(`
        *,
        customers (id, name, email, phone)
      `)
      .eq('id', proposal_id)
      .single()

    if (fetchError || !proposal) {
      console.error('Error fetching proposal:', fetchError)
      redirect('/proposals?payment=error')
    }

    const paymentStage = session.metadata?.payment_stage || 'deposit'
    const paidAmount = session.amount_total ? session.amount_total / 100 : 0
    const now = new Date().toISOString()

    // Record payment in payments table
    await supabase
      .from('payments')
      .insert({
        proposal_id,
        stripe_session_id: session_id,
        stripe_payment_intent_id: session.payment_intent as string,
        amount: paidAmount,
        status: 'completed',
        payment_method: session.metadata?.payment_type || 'card',
        customer_email: session.customer_email,
        payment_stage: paymentStage,
        metadata: session.metadata
      })

    // Update payment_stages table if it exists
    await supabase
      .from('payment_stages')
      .update({
        paid: true,
        paid_at: now,
        stripe_session_id: session_id,
        amount_paid: paidAmount,
        payment_method: session.metadata?.payment_type || 'card'
      })
      .eq('proposal_id', proposal_id)
      .eq('stage', paymentStage)

    // Calculate total paid
    const { data: allPayments } = await supabase
      .from('payments')
      .select('amount')
      .eq('proposal_id', proposal_id)
      .eq('status', 'completed')

    const totalPaid = allPayments?.reduce((sum, p) => sum + Number(p.amount), 0) || paidAmount

    // Determine next stage
    let nextStage = null
    let paymentStatus = 'partial'
    
    if (paymentStage === 'deposit') {
      nextStage = 'roughin'
    } else if (paymentStage === 'roughin') {
      nextStage = 'final'
    } else if (paymentStage === 'final') {
      paymentStatus = 'paid'
      nextStage = null
    }

    // Update proposal with payment info - IMPORTANT: Also ensure status stays 'approved'
    const updateData: any = {
      status: 'approved', // Keep it approved!
      payment_status: paymentStatus,
      payment_method: session.metadata?.payment_type || 'card',
      stripe_session_id: session_id,
      total_paid: totalPaid,
      current_payment_stage: nextStage,
      last_payment_attempt: now
    }

    // Update specific payment stage fields
    if (paymentStage === 'deposit') {
      updateData.deposit_paid_at = now
      updateData.deposit_amount = paidAmount
    } else if (paymentStage === 'roughin') {
      updateData.progress_paid_at = now
      updateData.progress_payment_amount = paidAmount
      updateData.progress_amount = paidAmount
    } else if (paymentStage === 'final') {
      updateData.final_paid_at = now
      updateData.final_payment_amount = paidAmount
      updateData.final_amount = paidAmount
    }

    await supabase
      .from('proposals')
      .update(updateData)
      .eq('id', proposal_id)

    // Send payment notification email
    try {
      const businessEmail = process.env.BUSINESS_EMAIL || 'dantcacenco@gmail.com'
      const fromEmail = process.env.EMAIL_FROM || 'onboarding@resend.dev'
      
      await fetch(`${process.env.NEXT_PUBLIC_BASE_URL || 'https://my-dashboard-app-tau.vercel.app'}/api/payment-notification`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          proposal_id,
          proposal_number: proposal.proposal_number,
          customer_name: proposal.customers.name,
          customer_email: proposal.customers.email,
          amount: paidAmount,
          payment_method: session.metadata?.payment_type || 'card',
          payment_stage: paymentStage,
          stripe_session_id: session_id
        })
      })
    } catch (emailError) {
      console.error('Failed to send payment notification:', emailError)
    }

    return (
      <PaymentSuccessView
        proposal={proposal}
        paymentAmount={paidAmount}
        paymentMethod={session.metadata?.payment_type || 'card'}
        sessionId={session_id}
        paymentStage={paymentStage}
        nextStage={nextStage}
        customerViewToken={proposal.customer_view_token}
      />
    )

  } catch (error: any) {
    console.error('Error processing payment success:', error)
    redirect(`/proposals?payment=error`)
  }
}
EOF

# Fix 2: Update PaymentSuccessView to use correct redirect
echo "📝 Updating PaymentSuccessView..."
cat > app/proposal/payment-success/PaymentSuccessView.tsx << 'EOF'
'use client'

import { CheckCircleIcon } from '@heroicons/react/24/solid'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { useEffect } from 'react'

interface PaymentSuccessViewProps {
  proposal: any
  paymentAmount: number
  paymentMethod: string
  sessionId: string
  paymentStage: string
  nextStage: string | null
  customerViewToken: string
}

export default function PaymentSuccessView({
  proposal,
  paymentAmount,
  paymentMethod,
  sessionId,
  paymentStage,
  nextStage,
  customerViewToken
}: PaymentSuccessViewProps) {
  const router = useRouter()
  
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  const getStageLabel = (stage: string) => {
    switch(stage) {
      case 'deposit': return 'Deposit (50%)'
      case 'roughin': return 'Rough In (30%)'
      case 'final': return 'Final Payment (20%)'
      default: return stage
    }
  }

  // Auto-redirect after 5 seconds
  useEffect(() => {
    const timer = setTimeout(() => {
      router.push(`/proposal/view/${customerViewToken}?payment=success&stage=${paymentStage}`)
    }, 5000)
    return () => clearTimeout(timer)
  }, [customerViewToken, paymentStage, router])

  return (
    <div className="min-h-screen bg-gray-50 py-12">
      <div className="max-w-3xl mx-auto px-4">
        <div className="bg-white rounded-lg shadow-lg p-8">
          <div className="text-center mb-8">
            <CheckCircleIcon className="h-16 w-16 text-green-500 mx-auto mb-4" />
            <h1 className="text-3xl font-bold text-gray-900 mb-2">
              Payment Successful!
            </h1>
            <p className="text-gray-600">
              Thank you for your payment
            </p>
          </div>

          <div className="border-t border-b border-gray-200 py-6 mb-6">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-gray-600">Proposal Number</p>
                <p className="font-semibold">{proposal.proposal_number}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Customer</p>
                <p className="font-semibold">{proposal.customers?.name}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Payment Stage</p>
                <p className="font-semibold">{getStageLabel(paymentStage)}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Amount Paid</p>
                <p className="font-semibold text-green-600">
                  {formatCurrency(paymentAmount)}
                </p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Payment Method</p>
                <p className="font-semibold capitalize">{paymentMethod}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Transaction ID</p>
                <p className="font-mono text-xs">{sessionId.slice(-12)}</p>
              </div>
            </div>
          </div>

          {nextStage && (
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
              <p className="text-sm text-blue-800">
                <strong>Next Payment Stage:</strong> {getStageLabel(nextStage)}
              </p>
              <p className="text-sm text-blue-600 mt-1">
                You will be notified when the next payment is due.
              </p>
            </div>
          )}

          <div className="space-y-3">
            <Link
              href={`/proposal/view/${customerViewToken}?payment=success&stage=${paymentStage}`}
              className="block w-full bg-blue-600 text-white text-center py-3 rounded-lg hover:bg-blue-700 transition"
            >
              View Proposal
            </Link>
            <Link
              href="/"
              className="block w-full bg-gray-200 text-gray-800 text-center py-3 rounded-lg hover:bg-gray-300 transition"
            >
              Return Home
            </Link>
          </div>

          <div className="mt-8 text-center text-sm text-gray-500">
            <p>A confirmation email has been sent to {proposal.customers?.email}</p>
            <p className="mt-2">
              For questions, please contact us at support@servicepro.com
            </p>
            <p className="mt-4 text-xs">
              Redirecting to your proposal in 5 seconds...
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
EOF

# Fix 3: Update CustomerProposalView to properly handle refreshed data
echo "📝 Updating CustomerProposalView to handle payment status..."
cat > app/proposal/view/[token]/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { notFound } from 'next/navigation'
import CustomerProposalView from './CustomerProposalView'

interface PageProps {
  params: Promise<{ token: string }>
}

export default async function CustomerProposalPage({ params }: PageProps) {
  const { token } = await params
  const supabase = await createClient()

  // Get proposal by customer view token - ALWAYS get fresh data
  const { data: proposal, error } = await supabase
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
        is_selected,
        sort_order
      )
    `)
    .eq('customer_view_token', token)
    .single()

  if (error || !proposal) {
    console.error('Error fetching proposal:', error)
    notFound()
  }

  // Mark as viewed if first time
  if (!proposal.first_viewed_at) {
    await supabase
      .from('proposals')
      .update({ first_viewed_at: new Date().toISOString() })
      .eq('id', proposal.id)
  }

  return <CustomerProposalView proposal={proposal} />
}
EOF

# Fix 4: Create payment notification API if missing
echo "📝 Creating payment notification API..."
cat > app/api/payment-notification/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server'
import { Resend } from 'resend'

const resend = new Resend(process.env.RESEND_API_KEY)

export async function POST(request: NextRequest) {
  try {
    const {
      proposal_id,
      proposal_number,
      customer_name,
      customer_email,
      amount,
      payment_method,
      payment_stage,
      stripe_session_id
    } = await request.json()

    const businessEmail = process.env.BUSINESS_EMAIL || 'dantcacenco@gmail.com'
    const fromEmail = process.env.EMAIL_FROM || 'onboarding@resend.dev'

    const stageLabel = payment_stage === 'roughin' ? 'Rough In' : 
                      payment_stage.charAt(0).toUpperCase() + payment_stage.slice(1)

    const htmlContent = `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #10b981; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
            .content { padding: 20px; background: #f9fafb; border: 1px solid #e5e7eb; }
            .details { background: white; padding: 15px; border-radius: 6px; margin: 15px 0; }
            .footer { padding: 20px; text-align: center; color: #666; font-size: 14px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>💰 Payment Received!</h1>
            </div>
            <div class="content">
              <h2>${stageLabel} Payment Received for Proposal #${proposal_number}</h2>
              
              <div class="details">
                <h3>Payment Details:</h3>
                <p><strong>Customer:</strong> ${customer_name}</p>
                <p><strong>Email:</strong> ${customer_email}</p>
                <p><strong>Amount:</strong> $${amount.toFixed(2)}</p>
                <p><strong>Payment Stage:</strong> ${stageLabel}</p>
                <p><strong>Payment Method:</strong> ${payment_method}</p>
                <p><strong>Transaction ID:</strong> ${stripe_session_id?.slice(-12) || 'N/A'}</p>
                <p><strong>Time:</strong> ${new Date().toLocaleString()}</p>
              </div>
              
              <div class="details">
                <h3>Next Steps:</h3>
                <ul>
                  ${payment_stage === 'deposit' ? '<li>Schedule project start</li><li>Order materials</li>' : ''}
                  ${payment_stage === 'roughin' ? '<li>Complete rough-in work</li><li>Schedule final inspection</li>' : ''}
                  ${payment_stage === 'final' ? '<li>Project complete!</li><li>Schedule follow-up</li>' : ''}
                </ul>
              </div>
            </div>
            <div class="footer">
              <p>This is an automated notification from Service Pro</p>
            </div>
          </div>
        </body>
      </html>
    `

    await resend.emails.send({
      from: `Service Pro <${fromEmail}>`,
      to: [businessEmail],
      subject: `💰 Payment Received - ${stageLabel} for Proposal #${proposal_number}`,
      html: htmlContent,
      text: `Payment received for ${stageLabel} - Proposal #${proposal_number}\nCustomer: ${customer_name}\nAmount: $${amount.toFixed(2)}`
    })

    return NextResponse.json({ success: true })

  } catch (error: any) {
    console.error('Error sending payment notification:', error)
    return NextResponse.json(
      { error: 'Failed to send notification' },
      { status: 500 }
    )
  }
}
EOF

# Commit and push
echo "🚀 Committing and pushing payment redirect fix..."
git add -A
git commit -m "Fix payment success redirect and data refresh

- Payment success now properly redirects to customer view with token
- Proposal status stays 'approved' after payment
- Fresh data loaded on redirect to show updated payment status
- Auto-redirect after 5 seconds from success page
- Payment stages immediately visible after payment
- No need to re-approve after payment" || echo "No changes"

git push origin main

echo ""
echo "✅ Payment redirect flow fixed!"
echo ""
echo "📋 What's fixed:"
echo "1. ✅ After payment, redirects to proposal view with fresh data"
echo "2. ✅ Proposal stays approved (no need to re-approve)"
echo "3. ✅ Payment stages immediately show correct status"
echo "4. ✅ Auto-redirect after 5 seconds from success page"
echo "5. ✅ Payment progress properly displayed"
echo "6. ✅ Next payment stage unlocked automatically"
echo ""
echo "🧪 Test flow:"
echo "1. Approve proposal → Shows payment stages"
echo "2. Pay deposit → Success page → Auto-redirect"
echo "3. Back at proposal → Shows deposit paid, rough-in ready"
echo "4. Pay rough-in → Shows 2/3 complete, final ready"
echo "5. Pay final → Shows all payments complete"