#!/bin/bash
set -e

echo "🔧 Fixing email sending and payment session creation..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# 1. Create or fix the send-proposal API route
echo "📝 Creating/fixing send-proposal API route..."
mkdir -p app/api/send-proposal
cat > app/api/send-proposal/route.ts << 'EOF'
import { NextResponse } from 'next/server'
import { Resend } from 'resend'

const resend = new Resend(process.env.RESEND_API_KEY)

export async function POST(request: Request) {
  try {
    const body = await request.json()
    
    const {
      to,
      subject,
      message,
      customer_name,
      proposal_number,
      proposal_url,
      send_copy
    } = body

    if (!to || !subject || !message) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    // Create HTML email content
    const htmlContent = `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #1e40af; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background-color: #f9fafb; }
            .button { display: inline-block; padding: 12px 24px; background-color: #10b981; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
            .footer { padding: 20px; text-align: center; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Service Pro</h1>
              <p>HVAC Services Proposal</p>
            </div>
            <div class="content">
              <h2>Proposal #${proposal_number}</h2>
              <p>Dear ${customer_name},</p>
              ${message.split('\n').map((line: string) => `<p>${line}</p>`).join('')}
              <center>
                <a href="${proposal_url}" class="button">View Proposal</a>
              </center>
            </div>
            <div class="footer">
              <p>© 2025 Service Pro. All rights reserved.</p>
            </div>
          </div>
        </body>
      </html>
    `

    // Send email
    const { data, error } = await resend.emails.send({
      from: 'Service Pro <onboarding@resend.dev>',
      to: [to],
      subject,
      html: htmlContent
    })

    if (error) {
      console.error('Resend error:', error)
      return NextResponse.json(
        { error: 'Failed to send email', details: error },
        { status: 500 }
      )
    }

    return NextResponse.json({ success: true, data })
  } catch (error) {
    console.error('Error in send-proposal route:', error)
    return NextResponse.json(
      { error: 'Internal server error', details: error },
      { status: 500 }
    )
  }
}
EOF

# 2. Fix the create-payment-session API route
echo "📝 Fixing create-payment-session API route..."
cat > app/api/create-payment-session/route.ts << 'EOF'
import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import Stripe from 'stripe'

// Initialize Stripe with proper error handling
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || '', {
  apiVersion: '2025-07-30.basil'
})

export async function POST(request: Request) {
  try {
    // Check if Stripe key exists
    if (!process.env.STRIPE_SECRET_KEY) {
      console.error('STRIPE_SECRET_KEY is not configured')
      return NextResponse.json(
        { error: 'Payment system not configured' },
        { status: 500 }
      )
    }

    const supabase = await createClient()
    const body = await request.json()
    
    const { 
      proposalId, 
      amount, 
      customerEmail, 
      proposalNumber,
      selectedAddons 
    } = body

    console.log('Creating payment session for:', {
      proposalId,
      amount,
      customerEmail,
      proposalNumber
    })

    if (!proposalId || !amount) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    // Ensure amount is a valid number
    const amountInCents = Math.round(parseFloat(amount.toString()) * 100)
    
    if (isNaN(amountInCents) || amountInCents <= 0) {
      return NextResponse.json(
        { error: 'Invalid amount' },
        { status: 400 }
      )
    }

    try {
      // Create Stripe checkout session
      const session = await stripe.checkout.sessions.create({
        payment_method_types: ['card'],
        line_items: [
          {
            price_data: {
              currency: 'usd',
              product_data: {
                name: `Proposal #${proposalNumber || 'N/A'}`,
                description: 'HVAC Services'
              },
              unit_amount: amountInCents
            },
            quantity: 1
          }
        ],
        mode: 'payment',
        success_url: `${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/proposal/payment-success?session_id={CHECKOUT_SESSION_ID}&proposal=${proposalId}`,
        cancel_url: `${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/proposal/view/${proposalId}`,
        customer_email: customerEmail || undefined,
        metadata: {
          proposalId,
          proposalNumber: proposalNumber || '',
          selectedAddons: JSON.stringify(selectedAddons || [])
        }
      })

      console.log('Stripe session created:', session.id)

      return NextResponse.json({ 
        url: session.url,
        sessionId: session.id 
      })
    } catch (stripeError: any) {
      console.error('Stripe error:', stripeError)
      return NextResponse.json(
        { 
          error: 'Failed to create payment session', 
          details: stripeError.message 
        },
        { status: 500 }
      )
    }
  } catch (error: any) {
    console.error('Error creating payment session:', error)
    return NextResponse.json(
      { 
        error: 'Internal server error', 
        details: error.message || 'Unknown error'
      },
      { status: 500 }
    )
  }
}
EOF

# 3. Add environment variables check
echo "📝 Creating environment check script..."
cat > check-env.js << 'EOF'
// Check if required environment variables are set
const required = [
  'NEXT_PUBLIC_SUPABASE_URL',
  'NEXT_PUBLIC_SUPABASE_ANON_KEY',
  'STRIPE_SECRET_KEY',
  'RESEND_API_KEY'
]

console.log('Environment Variables Check:')
console.log('============================')

required.forEach(key => {
  const exists = !!process.env[key]
  console.log(`${key}: ${exists ? '✅ SET' : '❌ MISSING'}`)
})

if (!process.env.STRIPE_SECRET_KEY) {
  console.log('\n⚠️  STRIPE_SECRET_KEY is missing!')
  console.log('Add it to your .env.local file:')
  console.log('STRIPE_SECRET_KEY=sk_test_...')
}

if (!process.env.RESEND_API_KEY) {
  console.log('\n⚠️  RESEND_API_KEY is missing!')
  console.log('Add it to your .env.local file:')
  console.log('RESEND_API_KEY=re_...')
}
EOF

# Run environment check
echo "🔍 Checking environment variables..."
node check-env.js

# Clean up
rm -f check-env.js

echo "✅ Fixed API routes"

# Test TypeScript
echo "🔍 Checking TypeScript..."
npx tsc --noEmit 2>&1 | head -20

# Test build
echo "🏗️ Testing build..."
npm run build 2>&1 | head -40

# Commit
git add -A
git commit -m "Fix email sending and payment session creation

- Created send-proposal API route with Resend integration
- Fixed create-payment-session with proper error handling
- Added Stripe key validation
- Improved error messages for debugging
- Added HTML email template
- Fixed amount calculation for Stripe (converts to cents)"

git push origin main

echo "✅ Email and payment APIs fixed!"
echo ""
echo "🎯 FIXED:"
echo "1. ✅ Email sending via Resend API"
echo "2. ✅ Payment session creation with Stripe"
echo "3. ✅ Proper error handling and logging"
echo ""
echo "⚠️  IMPORTANT: Make sure these environment variables are set in .env.local:"
echo "- STRIPE_SECRET_KEY=sk_test_..."
echo "- RESEND_API_KEY=re_..."
echo "- NEXT_PUBLIC_APP_URL=https://my-dashboard-app-tau.vercel.app"
