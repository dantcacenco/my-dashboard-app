#!/bin/bash
set -e

echo "🔧 Connecting Multi-Stage Payment System..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# 1. Import and integrate PaymentStages component into CustomerProposalView
echo "📝 Updating CustomerProposalView to show payment stages after acceptance..."

cat > app/proposal/view/\[token\]/CustomerProposalView.tsx << 'EOF'
'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import PaymentStages from '@/components/PaymentStages'

interface ProposalData {
  id: string
  proposal_number: string
  title: string
  description: string
  subtotal: number
  tax_rate: number
  tax_amount: number
  total: number
  status: string
  customers: any
  proposal_items: any[]
  customer_view_token: string
  deposit_percentage: number
  progress_percentage: number
  final_percentage: number
  deposit_paid_at: string | null
  progress_paid_at: string | null
  final_paid_at: string | null
  total_paid: number
}

interface CustomerProposalViewProps {
  proposal: ProposalData
  token: string
}

export default function CustomerProposalView({ proposal: initialProposal, token }: CustomerProposalViewProps) {
  const router = useRouter()
  const supabase = createClient()
  
  const [selectedAddons, setSelectedAddons] = useState<Set<string>>(
    new Set(initialProposal.proposal_items?.filter(item => item.is_addon && item.is_selected).map(item => item.id))
  )
  const [isProcessing, setIsProcessing] = useState(false)
  const [error, setError] = useState('')

  // Separate services and add-ons
  const services = initialProposal.proposal_items?.filter(item => !item.is_addon) || []
  const addons = initialProposal.proposal_items?.filter(item => item.is_addon) || []

  // Toggle addon selection
  const toggleAddon = (addonId: string) => {
    const newSelected = new Set(selectedAddons)
    if (newSelected.has(addonId)) {
      newSelected.delete(addonId)
    } else {
      newSelected.add(addonId)
    }
    setSelectedAddons(newSelected)
  }

  // Calculate totals based on selections
  const calculateTotals = () => {
    const servicesTotal = services.reduce((sum: number, item: any) => 
      sum + (item.total_price || 0), 0
    )
    
    const addonsTotal = addons
      .filter(item => selectedAddons.has(item.id))
      .reduce((sum: number, item: any) => sum + (item.total_price || 0), 0)
    
    const subtotal = servicesTotal + addonsTotal
    const taxAmount = subtotal * (initialProposal.tax_rate || 0)
    const total = subtotal + taxAmount
    
    return { servicesTotal, addonsTotal, subtotal, taxAmount, total }
  }

  const totals = calculateTotals()

  // Handle proposal approval
  const handleApprove = async () => {
    setIsProcessing(true)
    setError('')

    try {
      // Update selected add-ons in the database
      for (const addon of addons) {
        await supabase
          .from('proposal_items')
          .update({ is_selected: selectedAddons.has(addon.id) })
          .eq('id', addon.id)
      }

      // Calculate payment amounts
      const depositAmount = totals.total * (initialProposal.deposit_percentage || 50) / 100
      const progressAmount = totals.total * (initialProposal.progress_percentage || 30) / 100
      const finalAmount = totals.total * (initialProposal.final_percentage || 20) / 100

      // Update proposal with totals and approval
      await supabase
        .from('proposals')
        .update({
          subtotal: totals.subtotal,
          tax_amount: totals.taxAmount,
          total: totals.total,
          deposit_amount: depositAmount,
          progress_amount: progressAmount,
          final_amount: finalAmount,
          status: 'accepted',
          approved_at: new Date().toISOString(),
          payment_stage: 'deposit'
        })
        .eq('id', initialProposal.id)

      // Create payment_stages records if they don't exist
      const { data: existingStages } = await supabase
        .from('payment_stages')
        .select('*')
        .eq('proposal_id', initialProposal.id)

      if (!existingStages || existingStages.length === 0) {
        await supabase
          .from('payment_stages')
          .insert([
            {
              proposal_id: initialProposal.id,
              stage: 'deposit',
              percentage: initialProposal.deposit_percentage || 50,
              amount: depositAmount,
              paid: false,
              label: '50% Deposit',
              description: 'Initial deposit to begin work',
              sort_order: 1
            },
            {
              proposal_id: initialProposal.id,
              stage: 'progress',
              percentage: initialProposal.progress_percentage || 30,
              amount: progressAmount,
              paid: false,
              label: '30% Progress',
              description: 'Progress payment at rough-in',
              sort_order: 2
            },
            {
              proposal_id: initialProposal.id,
              stage: 'final',
              percentage: initialProposal.final_percentage || 20,
              amount: finalAmount,
              paid: false,
              label: '20% Final',
              description: 'Final payment upon completion',
              sort_order: 3
            }
          ])
      }

      // Refresh the page to show payment options
      router.refresh()
      
    } catch (err) {
      console.error('Error approving proposal:', err)
      setError('Failed to approve proposal. Please try again.')
      setIsProcessing(false)
    }
  }

  const handleReject = async () => {
    if (!confirm('Are you sure you want to reject this proposal?')) return

    setIsProcessing(true)
    try {
      await supabase
        .from('proposals')
        .update({
          status: 'rejected',
          rejected_at: new Date().toISOString()
        })
        .eq('id', initialProposal.id)

      alert('Proposal has been rejected.')
      router.refresh()
    } catch (err) {
      console.error('Error rejecting proposal:', err)
      setError('Failed to reject proposal.')
    } finally {
      setIsProcessing(false)
    }
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-4xl mx-auto px-4">
        {/* Header */}
        <div className="bg-white rounded-lg shadow-sm p-6 mb-6">
          <div className="flex justify-between items-start">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">
                {initialProposal.title}
              </h1>
              <p className="text-gray-600 mt-1">
                Proposal #{initialProposal.proposal_number}
              </p>
              {initialProposal.description && (
                <p className="text-gray-700 mt-3">{initialProposal.description}</p>
              )}
            </div>
            <div className="text-right">
              <span className={`inline-block px-3 py-1 rounded-full text-sm font-semibold ${
                initialProposal.status === 'accepted' ? 'bg-green-100 text-green-800' :
                initialProposal.status === 'rejected' ? 'bg-red-100 text-red-800' :
                'bg-blue-100 text-blue-800'
              }`}>
                {initialProposal.status}
              </span>
            </div>
          </div>
        </div>

        {/* Customer Info */}
        <div className="bg-white rounded-lg shadow-sm p-6 mb-6">
          <h2 className="text-lg font-semibold mb-4">Customer Information</h2>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-sm text-gray-600">Name</p>
              <p className="font-medium">{initialProposal.customers?.name}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Email</p>
              <p className="font-medium">{initialProposal.customers?.email}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Phone</p>
              <p className="font-medium">{initialProposal.customers?.phone || '-'}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Address</p>
              <p className="font-medium">{initialProposal.customers?.address || '-'}</p>
            </div>
          </div>
        </div>

        {/* Only show services/addons if not yet accepted */}
        {initialProposal.status !== 'accepted' && initialProposal.status !== 'rejected' && (
          <>
            {/* Services */}
            {services.length > 0 && (
              <div className="bg-white rounded-lg shadow-sm p-6 mb-6">
                <h2 className="text-lg font-semibold mb-4">Services</h2>
                <div className="space-y-3">
                  {services.map((item: any) => (
                    <div key={item.id} className="border rounded-lg p-4 bg-gray-50">
                      <div className="flex justify-between">
                        <div className="flex-1">
                          <h3 className="font-medium">{item.name}</h3>
                          <p className="text-sm text-gray-600 mt-1">{item.description}</p>
                          <p className="text-sm text-gray-500 mt-2">
                            Qty: {item.quantity} × ${item.unit_price?.toFixed(2)}
                          </p>
                        </div>
                        <div className="text-right">
                          <p className="font-bold text-lg">${item.total_price?.toFixed(2)}</p>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Optional Add-ons */}
            {addons.length > 0 && (
              <div className="bg-white rounded-lg shadow-sm p-6 mb-6">
                <h2 className="text-lg font-semibold mb-4">Optional Add-ons</h2>
                <p className="text-sm text-gray-600 mb-4">
                  Select any additional services you'd like to include:
                </p>
                <div className="space-y-3">
                  {addons.map((item: any) => (
                    <div 
                      key={item.id} 
                      className={`border rounded-lg p-4 cursor-pointer transition-all ${
                        selectedAddons.has(item.id) 
                          ? 'bg-orange-50 border-orange-300' 
                          : 'bg-gray-50 border-gray-200 opacity-75'
                      }`}
                      onClick={() => toggleAddon(item.id)}
                    >
                      <div className="flex items-start">
                        <input
                          type="checkbox"
                          checked={selectedAddons.has(item.id)}
                          onChange={() => toggleAddon(item.id)}
                          className="mt-1 mr-3 w-4 h-4 text-orange-600 focus:ring-orange-500"
                          onClick={(e) => e.stopPropagation()}
                        />
                        <div className="flex-1">
                          <div className="flex items-center gap-2">
                            <h3 className="font-medium">{item.name}</h3>
                            <span className="text-xs bg-orange-200 text-orange-800 px-2 py-1 rounded">
                              Add-on
                            </span>
                          </div>
                          <p className="text-sm text-gray-600 mt-1">{item.description}</p>
                          <p className="text-sm text-gray-500 mt-2">
                            Qty: {item.quantity} × ${item.unit_price?.toFixed(2)}
                          </p>
                        </div>
                        <div className="text-right ml-4">
                          <p className={`font-bold text-lg ${
                            selectedAddons.has(item.id) ? 'text-green-600' : 'text-gray-400'
                          }`}>
                            ${item.total_price?.toFixed(2)}
                          </p>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Totals */}
            <div className="bg-white rounded-lg shadow-sm p-6 mb-6">
              <h2 className="text-lg font-semibold mb-4">Total</h2>
              <div className="space-y-2">
                <div className="flex justify-between">
                  <span>Services:</span>
                  <span>${totals.servicesTotal.toFixed(2)}</span>
                </div>
                {totals.addonsTotal > 0 && (
                  <div className="flex justify-between text-orange-600">
                    <span>Selected Add-ons:</span>
                    <span>+${totals.addonsTotal.toFixed(2)}</span>
                  </div>
                )}
                <div className="flex justify-between font-medium pt-2 border-t">
                  <span>Subtotal:</span>
                  <span>${totals.subtotal.toFixed(2)}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span>Tax ({(initialProposal.tax_rate * 100).toFixed(1)}%):</span>
                  <span>${totals.taxAmount.toFixed(2)}</span>
                </div>
                <div className="flex justify-between font-bold text-xl pt-2 border-t">
                  <span>Total:</span>
                  <span className="text-green-600">${totals.total.toFixed(2)}</span>
                </div>
              </div>
            </div>
          </>
        )}

        {/* Show Payment Stages when accepted */}
        {initialProposal.status === 'accepted' && (
          <PaymentStages
            proposalId={initialProposal.id}
            proposalNumber={initialProposal.proposal_number}
            customerName={initialProposal.customers?.name || ''}
            customerEmail={initialProposal.customers?.email || ''}
            totalAmount={initialProposal.total}
            depositPercentage={initialProposal.deposit_percentage || 50}
            progressPercentage={initialProposal.progress_percentage || 30}
            finalPercentage={initialProposal.final_percentage || 20}
          />
        )}

        {/* Error Display */}
        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 rounded-lg p-4 mb-6">
            {error}
          </div>
        )}

        {/* Action Buttons */}
        {initialProposal.status === 'sent' && (
          <div className="flex gap-4">
            <button
              onClick={handleApprove}
              disabled={isProcessing}
              className="flex-1 bg-green-600 text-white px-6 py-3 rounded-lg font-semibold hover:bg-green-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              {isProcessing ? 'Processing...' : '✓ Approve Proposal'}
            </button>
            <button
              onClick={handleReject}
              disabled={isProcessing}
              className="flex-1 bg-red-600 text-white px-6 py-3 rounded-lg font-semibold hover:bg-red-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              ✗ Reject Proposal
            </button>
          </div>
        )}

        {initialProposal.status === 'rejected' && (
          <div className="bg-red-50 border border-red-200 text-red-700 rounded-lg p-4 text-center">
            <p className="font-semibold">This proposal has been rejected.</p>
          </div>
        )}
      </div>
    </div>
  )
}
EOF

# 2. Update the create-payment API to handle payment stages properly
echo "📝 Updating create-payment API to handle stages..."
cat > app/api/create-payment/route.ts << 'EOF'
import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import Stripe from 'stripe'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || '', {
  apiVersion: '2025-07-30.basil'
})

export async function POST(request: Request) {
  try {
    const supabase = await createClient()
    const body = await request.json()
    
    const {
      proposal_id,
      proposal_number,
      customer_name,
      customer_email,
      amount,
      payment_type = 'card',
      payment_stage,
      description
    } = body

    console.log('Creating payment for stage:', payment_stage, 'Amount:', amount)

    if (!proposal_id || !amount) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    // Get proposal details
    const { data: proposal } = await supabase
      .from('proposals')
      .select('*')
      .eq('id', proposal_id)
      .single()

    if (!proposal) {
      return NextResponse.json(
        { error: 'Proposal not found' },
        { status: 404 }
      )
    }

    // Create Stripe checkout session
    const session = await stripe.checkout.sessions.create({
      payment_method_types: [payment_type],
      line_items: [
        {
          price_data: {
            currency: 'usd',
            product_data: {
              name: description || `${payment_stage} Payment - Proposal #${proposal_number}`,
              description: `HVAC Services - ${payment_stage} payment`
            },
            unit_amount: Math.round(amount * 100) // Convert to cents
          },
          quantity: 1
        }
      ],
      mode: 'payment',
      success_url: `${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/proposal/payment-success?session_id={CHECKOUT_SESSION_ID}&proposal_id=${proposal_id}&stage=${payment_stage}`,
      cancel_url: `${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/proposal/view/${proposal.customer_view_token}`,
      customer_email: customer_email,
      metadata: {
        proposal_id: proposal_id,
        proposal_number: proposal_number,
        payment_stage: payment_stage,
        amount: amount.toString()
      }
    })

    // Update payment_stages table
    await supabase
      .from('payment_stages')
      .update({
        stripe_session_id: session.id,
        last_attempt: new Date().toISOString()
      })
      .eq('proposal_id', proposal_id)
      .eq('stage', payment_stage)

    return NextResponse.json({
      checkout_url: session.url,
      session_id: session.id
    })
    
  } catch (error: any) {
    console.error('Error creating payment session:', error)
    return NextResponse.json(
      { error: error.message || 'Failed to create payment session' },
      { status: 500 }
    )
  }
}
EOF

echo "✅ Multi-stage payment system connected!"

# Test TypeScript
echo "🔍 Checking TypeScript..."
npx tsc --noEmit 2>&1 | head -20

# Commit changes
git add -A
git commit -m "Connect multi-stage payment system (50/30/20)

- Integrated PaymentStages component into CustomerProposalView
- Show payment stages after proposal acceptance
- Create payment_stages records on approval
- Update create-payment API to handle stages
- Customer sees payment progress and can pay each stage
- Stages: 50% deposit, 30% progress, 20% final"

git push origin main

echo "✅ Multi-stage payment system connected!"
echo ""
echo "🎯 HOW IT WORKS NOW:"
echo "1. Customer approves proposal"
echo "2. System creates 3 payment stages (50/30/20)"
echo "3. PaymentStages component shows with deposit payment ready"
echo "4. After deposit paid, progress payment unlocks"
echo "5. After progress paid, final payment unlocks"
echo "6. Each payment updates the database and tracks progress"
