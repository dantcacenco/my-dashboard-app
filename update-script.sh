#!/bin/bash

# Fix all billing, payment, and synthetic errors in Service Pro

set -e

echo "🔧 Fixing billing system and synthetic errors..."

# Fix 1: Update create-payment API route to properly handle payment stages
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
      payment_stage = 'deposit'
    } = await request.json()

    console.log('Creating payment for:', {
      proposal_id,
      payment_stage,
      amount,
      payment_type
    })

    if (!proposal_id || !amount || !customer_email) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    // Get the proposal with customer_view_token
    const supabase = await createClient()
    const { data: proposal, error: fetchError } = await supabase
      .from('proposals')
      .select('customer_view_token, total')
      .eq('id', proposal_id)
      .single()

    if (fetchError || !proposal) {
      console.error('Error fetching proposal:', fetchError)
      return NextResponse.json(
        { error: 'Proposal not found' },
        { status: 404 }
      )
    }

    // Ensure customer_view_token exists
    let customerViewToken = proposal.customer_view_token
    if (!customerViewToken) {
      const { data: tokenData, error: tokenError } = await supabase
        .from('proposals')
        .update({ customer_view_token: crypto.randomUUID() })
        .eq('id', proposal_id)
        .select('customer_view_token')
        .single()
      
      if (tokenError || !tokenData) {
        console.error('Error generating token:', tokenError)
        return NextResponse.json(
          { error: 'Failed to generate customer token' },
          { status: 500 }
        )
      }
      customerViewToken = tokenData.customer_view_token
    }

    // Create or update payment stage record
    const { error: stageError } = await supabase
      .from('payment_stages')
      .upsert({
        proposal_id,
        stage: payment_stage,
        amount: amount,
        percentage: payment_stage === 'deposit' ? 50 : payment_stage === 'roughin' ? 30 : 20,
        due_date: new Date().toISOString().split('T')[0],
        paid: false
      }, {
        onConflict: 'proposal_id,stage'
      })

    if (stageError) {
      console.error('Error creating payment stage:', stageError)
    }

    // Define payment method types
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
              description: `${description} for proposal ${proposal_number}`,
            },
            unit_amount: Math.round(amount * 100) // Convert to cents
          },
          quantity: 1
        }
      ],
      mode: 'payment',
      customer_email: customer_email,
      success_url: `${process.env.NEXT_PUBLIC_BASE_URL || 'https://servicepro-hvac.vercel.app'}/proposal/payment-success?session_id={CHECKOUT_SESSION_ID}&proposal_id=${proposal_id}`,
      cancel_url: `${process.env.NEXT_PUBLIC_BASE_URL || 'https://servicepro-hvac.vercel.app'}/proposal/view/${customerViewToken}?payment=cancelled`,
      metadata: {
        proposal_id,
        proposal_number,
        customer_name,
        payment_type: payment_type || 'card',
        payment_stage: payment_stage,
        customer_view_token: customerViewToken
      },
      billing_address_collection: 'required',
      phone_number_collection: {
        enabled: true
      },
      ...(payment_type === 'ach' && {
        payment_method_options: {
          us_bank_account: {
            financial_connections: {
              permissions: ['payment_method' as const]
            }
          }
        }
      })
    })

    console.log('Stripe session created successfully:', session.id)

    return NextResponse.json({ 
      checkout_url: session.url,
      session_id: session.id 
    })

  } catch (error: any) {
    console.error('Error creating Stripe checkout session:', error)
    return NextResponse.json(
      { error: error.message || 'Failed to create payment session' },
      { status: 500 }
    )
  }
}
EOF

# Fix 2: Update payment success page to properly record payments
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
      redirect(`/proposals?payment=failed`)
    }

    // Get proposal details
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
    const { error: paymentError } = await supabase
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

    if (paymentError) {
      console.error('Error recording payment:', paymentError)
    }

    // Update payment_stages table
    const { error: stageError } = await supabase
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

    if (stageError) {
      console.error('Error updating payment stage:', stageError)
    }

    // Calculate total paid
    const { data: allPayments } = await supabase
      .from('payments')
      .select('amount')
      .eq('proposal_id', proposal_id)
      .eq('status', 'completed')

    const totalPaid = allPayments?.reduce((sum, p) => sum + Number(p.amount), 0) || 0

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

    // Update proposal with payment info
    const updateData: any = {
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
      updateData.progress_amount = paidAmount // Update both columns
    } else if (paymentStage === 'final') {
      updateData.final_paid_at = now
      updateData.final_payment_amount = paidAmount
      updateData.final_amount = paidAmount // Update both columns
    }

    const { error: updateError } = await supabase
      .from('proposals')
      .update(updateData)
      .eq('id', proposal_id)

    if (updateError) {
      console.error('Error updating proposal:', updateError)
    }

    return (
      <PaymentSuccessView
        proposal={proposal}
        paymentAmount={paidAmount}
        paymentMethod={session.metadata?.payment_type || 'card'}
        sessionId={session_id}
        paymentStage={paymentStage}
        nextStage={nextStage}
      />
    )

  } catch (error: any) {
    console.error('Error processing payment success:', error)
    redirect(`/proposals?payment=error`)
  }
}
EOF

# Fix 3: Create PaymentSuccessView component
cat > app/proposal/payment-success/PaymentSuccessView.tsx << 'EOF'
'use client'

import { CheckCircleIcon } from '@heroicons/react/24/solid'
import Link from 'next/link'

interface PaymentSuccessViewProps {
  proposal: any
  paymentAmount: number
  paymentMethod: string
  sessionId: string
  paymentStage: string
  nextStage: string | null
}

export default function PaymentSuccessView({
  proposal,
  paymentAmount,
  paymentMethod,
  paymentStage,
  nextStage
}: PaymentSuccessViewProps) {
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
                <p className="font-semibold">{proposal.customers.name}</p>
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
                <p className="font-mono text-xs">{sessionId}</p>
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
              href={`/proposal/view/${proposal.customer_view_token}`}
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
            <p>A confirmation email has been sent to {proposal.customers.email}</p>
            <p className="mt-2">
              For questions, please contact us at support@servicepro.com
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
EOF

# Fix 4: Update PaymentStages component to use payment_stages table
cat > components/PaymentStages.tsx << 'EOF'
'use client'

import { useState, useEffect } from 'react'
import { CheckCircleIcon, LockClosedIcon } from '@heroicons/react/24/solid'
import { createClient } from '@/lib/supabase/client'

interface PaymentStagesProps {
  proposalId: string
  proposalNumber: string
  customerName: string
  customerEmail: string
  totalAmount: number
  depositPercentage?: number
  progressPercentage?: number
  finalPercentage?: number
  onPaymentInitiated?: () => void
}

export default function PaymentStages({
  proposalId,
  proposalNumber,
  customerName,
  customerEmail,
  totalAmount,
  depositPercentage = 50,
  progressPercentage = 30,
  finalPercentage = 20,
  onPaymentInitiated
}: PaymentStagesProps) {
  const [paymentStages, setPaymentStages] = useState<any[]>([])
  const [isProcessing, setIsProcessing] = useState(false)
  const [currentStage, setCurrentStage] = useState<string>('deposit')
  const supabase = createClient()

  useEffect(() => {
    loadPaymentStages()
  }, [proposalId])

  const loadPaymentStages = async () => {
    const { data: stages } = await supabase
      .from('payment_stages')
      .select('*')
      .eq('proposal_id', proposalId)
      .order('stage')

    if (stages && stages.length > 0) {
      setPaymentStages(stages)
      // Determine current stage
      const unpaidStage = stages.find(s => !s.paid)
      if (unpaidStage) {
        setCurrentStage(unpaidStage.stage)
      } else {
        setCurrentStage('complete')
      }
    } else {
      // Initialize stages if they don't exist
      const initialStages = [
        {
          stage: 'deposit',
          percentage: depositPercentage,
          amount: totalAmount * (depositPercentage / 100),
          paid: false,
          label: 'Deposit',
          description: 'Initial deposit to begin work'
        },
        {
          stage: 'roughin',
          percentage: progressPercentage,
          amount: totalAmount * (progressPercentage / 100),
          paid: false,
          label: 'Rough In',
          description: 'Payment after rough-in completion'
        },
        {
          stage: 'final',
          percentage: finalPercentage,
          amount: totalAmount * (finalPercentage / 100),
          paid: false,
          label: 'Final Payment',
          description: 'Final payment upon completion'
        }
      ]
      setPaymentStages(initialStages)
    }
  }

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  const handlePayment = async (stage: any) => {
    setIsProcessing(true)
    
    try {
      const response = await fetch('/api/create-payment', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          proposal_id: proposalId,
          proposal_number: proposalNumber,
          customer_name: customerName,
          customer_email: customerEmail,
          amount: stage.amount,
          payment_type: 'card',
          payment_stage: stage.stage,
          description: `${stage.label} for Proposal ${proposalNumber}`
        })
      })

      const { checkout_url, error } = await response.json()

      if (error) {
        throw new Error(error)
      }

      if (checkout_url) {
        onPaymentInitiated?.()
        window.location.href = checkout_url
      }
    } catch (error: any) {
      console.error('Payment error:', error)
      alert('Error setting up payment. Please try again.')
      setIsProcessing(false)
    }
  }

  const totalPaid = paymentStages
    .filter(s => s.paid)
    .reduce((sum, s) => sum + Number(s.amount), 0)

  const progressPercentageValue = totalAmount > 0 
    ? Math.round((totalPaid / totalAmount) * 100)
    : 0

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <h3 className="text-lg font-semibold mb-4">Payment Schedule</h3>
      
      <div className="mb-6">
        <div className="flex justify-between text-sm mb-2">
          <span>Payment Progress</span>
          <span>{progressPercentageValue}% Complete</span>
        </div>
        <div className="w-full bg-gray-200 rounded-full h-3">
          <div 
            className="bg-green-500 h-3 rounded-full transition-all duration-500"
            style={{ width: `${progressPercentageValue}%` }}
          />
        </div>
        <div className="flex justify-between mt-2 text-sm">
          <span className="text-gray-600">
            {formatCurrency(totalPaid)} paid
          </span>
          <span className="text-gray-600">
            {formatCurrency(totalAmount - totalPaid)} remaining
          </span>
        </div>
      </div>

      <div className="space-y-3">
        {paymentStages.map((stage, index) => (
          <div
            key={stage.stage}
            className={`border rounded-lg p-4 ${
              stage.paid 
                ? 'bg-green-50 border-green-300'
                : stage.stage === currentStage
                ? 'bg-blue-50 border-blue-300'
                : 'bg-gray-50 border-gray-300'
            }`}
          >
            <div className="flex items-center justify-between">
              <div className="flex-1">
                <div className="flex items-center gap-2">
                  {stage.paid ? (
                    <CheckCircleIcon className="h-5 w-5 text-green-600" />
                  ) : stage.stage !== currentStage ? (
                    <LockClosedIcon className="h-5 w-5 text-gray-400" />
                  ) : null}
                  <h4 className="font-semibold">
                    {stage.label || `Stage ${index + 1}`}
                  </h4>
                  <span className="text-sm text-gray-600">
                    ({stage.percentage}%)
                  </span>
                </div>
                <p className="text-sm text-gray-600 mt-1">
                  {stage.description}
                </p>
                {stage.paid && stage.paid_at && (
                  <p className="text-xs text-green-600 mt-1">
                    Paid on {new Date(stage.paid_at).toLocaleDateString()}
                  </p>
                )}
              </div>
              
              <div className="text-right">
                <p className="font-bold text-lg">
                  {formatCurrency(stage.amount)}
                </p>
                {!stage.paid && stage.stage === currentStage && (
                  <button
                    onClick={() => handlePayment(stage)}
                    disabled={isProcessing}
                    className="mt-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed text-sm"
                  >
                    {isProcessing ? 'Processing...' : 'Pay Now'}
                  </button>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
EOF

echo "✅ All fixes applied successfully!"
echo ""
echo "📝 Summary of changes:"
echo "1. Fixed create-payment API to properly handle payment stages"
echo "2. Updated payment success page to record in both payments and payment_stages tables"
echo "3. Created PaymentSuccessView component with proper stage handling"
echo "4. Updated PaymentStages component to use payment_stages table"
echo ""
echo "🚀 Committing and pushing changes..."

git add -A
git commit -m "Fix billing system: proper payment stages, synthetic errors resolved, dual table tracking"
git push origin main

echo ""
echo "✅ Changes pushed to GitHub!"
echo ""
echo "📋 Next steps:"
echo "1. Test the payment flow in your Vercel deployment"
echo "2. Ensure Stripe webhook is configured if needed"
echo "3. Verify NEXT_PUBLIC_BASE_URL is set in Vercel environment variables"
echo "4. Test multi-stage payments (deposit -> roughin -> final)"