import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { getBillComClient, shouldUseBillCom } from '@/lib/billcom/client'
import Stripe from 'stripe'

// Initialize Stripe (keeping for fallback and current use)
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || '', {
  apiVersion: '2025-07-30.basil',
})

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { proposalId, amount, paymentStage, customerEmail, useStripe } = body

    const supabase = await createClient()

    // Get proposal details
    const { data: proposal, error: proposalError } = await supabase
      .from('proposals')
      .select('*')
      .eq('id', proposalId)
      .single()

    if (proposalError || !proposal) {
      return NextResponse.json(
        { error: 'Proposal not found' },
        { status: 404 }
      )
    }

    // Determine payment processor
    // Only use Bill.com if explicitly requested AND configured
    const useBillCom = useStripe === false && shouldUseBillCom()

    if (useBillCom) {
      // Use Bill.com
      try {
        const billcom = getBillComClient()
        
        // Create invoice in Bill.com
        const invoice = await billcom.createInvoice({
          customerId: proposal.customer_id,
          invoiceNumber: `${proposal.proposal_number}-${paymentStage}`,
          date: new Date().toISOString(),
          dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(), // 7 days
          amount: amount,
          description: `${paymentStage} payment for Proposal #${proposal.proposal_number}`,
          lineItems: [{
            description: `${paymentStage} Payment - ${proposal.title}`,
            amount: amount
          }]
        })

        // Send invoice to customer
        await billcom.sendInvoice(invoice.id, customerEmail)

        // Get payment URL
        const paymentUrl = await billcom.getPaymentUrl(invoice.id)

        // Update proposal with Bill.com invoice ID
        await supabase
          .from('proposals')
          .update({
            payment_initiated_at: new Date().toISOString(),
            last_payment_attempt: new Date().toISOString()
          })
          .eq('id', proposalId)

        return NextResponse.json({
          success: true,
          paymentUrl: paymentUrl,
          invoiceId: invoice.id,
          processor: 'billcom'
        })
      } catch (billcomError: any) {
        console.error('Bill.com error, falling back to Stripe:', billcomError)
        // Fall through to Stripe
      }
    }

    // Use Stripe (default or fallback)
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [
        {
          price_data: {
            currency: 'usd',
            product_data: {
              name: `${paymentStage} Payment - Proposal #${proposal.proposal_number}`,
              description: proposal.title,
            },
            unit_amount: Math.round(amount * 100), // Convert to cents for Stripe
          },
          quantity: 1,
        },
      ],
      mode: 'payment',
      success_url: `${process.env.NEXT_PUBLIC_BASE_URL || request.headers.get('origin')}/proposal/payment-success?session_id={CHECKOUT_SESSION_ID}&proposal_id=${proposalId}`,
      cancel_url: `${process.env.NEXT_PUBLIC_BASE_URL || request.headers.get('origin')}/proposal/view/${proposal.customer_view_token}`,
      customer_email: customerEmail,
      metadata: {
        proposal_id: proposalId,
        payment_stage: paymentStage,
      },
    })

    // Update proposal with session ID
    await supabase
      .from('proposals')
      .update({
        stripe_session_id: session.id,
        payment_initiated_at: new Date().toISOString(),
        last_payment_attempt: new Date().toISOString()
      })
      .eq('id', proposalId)

    return NextResponse.json({
      success: true,
      paymentUrl: session.url,
      sessionId: session.id,
      processor: 'stripe'
    })
  } catch (error: any) {
    console.error('Payment API error:', error)
    return NextResponse.json(
      { error: error.message || 'Failed to create payment session' },
      { status: 500 }
    )
  }
}
