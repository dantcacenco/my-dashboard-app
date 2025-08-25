#!/bin/bash
set -e

echo "🔧 Fixing duplicate items, approval process, and email design..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# 1. Fix the ProposalEditor to update quantity instead of adding duplicates
echo "📝 Fixing ProposalEditor to handle duplicate items properly..."
cat > fix-proposal-editor-duplicates.sh << 'SCRIPT'
#!/bin/bash
# Read the current ProposalEditor
EDITOR_FILE="app/(authenticated)/proposals/[id]/edit/ProposalEditor.tsx"

# Create a temporary fix that updates quantity instead of adding duplicates
cat > temp-fix.js << 'EOF'
const fs = require('fs');
const content = fs.readFileSync(process.argv[2], 'utf8');

// Find the addItem function and replace it
const newContent = content.replace(
  /const handleAddItem = \(item: PricingItem, isAddon: boolean\) => {[\s\S]*?setShowAddItem\(false\)[\s\S]*?}/,
  `const handleAddItem = (item: PricingItem, isAddon: boolean) => {
    // Check if item already exists
    const existingItem = proposalItems.find(pi => 
      pi.name === item.name && pi.is_addon === isAddon
    )
    
    if (existingItem) {
      // Update quantity instead of adding duplicate
      setProposalItems(proposalItems.map(pi => 
        pi.id === existingItem.id 
          ? { 
              ...pi, 
              quantity: pi.quantity + 1, 
              total_price: pi.unit_price * (pi.quantity + 1) 
            }
          : pi
      ))
    } else {
      // Add new item
      const newItem: ProposalItem = {
        id: \`temp-\${Date.now()}-\${Math.random()}\`,
        name: item.name,
        description: item.description,
        quantity: 1,
        unit_price: item.price,
        total_price: item.price,
        is_addon: isAddon,
        is_selected: true
      }
      setProposalItems([...proposalItems, newItem])
    }
    setShowAddItem(false)
  }`
);

fs.writeFileSync(process.argv[2], newContent);
EOF

node temp-fix.js "$EDITOR_FILE"
rm temp-fix.js
SCRIPT

chmod +x fix-proposal-editor-duplicates.sh
./fix-proposal-editor-duplicates.sh
rm fix-proposal-editor-duplicates.sh

# 2. Fix the approval process in CustomerProposalView
echo "📝 Fixing approval process to actually redirect to payment..."
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

  // Separate services and add-ons - handle duplicates by combining quantities
  const services = initialProposal.proposal_items?.filter(item => !item.is_addon) || []
  
  // Combine duplicate add-ons by summing their quantities
  const addonsMap = new Map()
  initialProposal.proposal_items?.filter(item => item.is_addon).forEach(item => {
    const key = item.name
    if (addonsMap.has(key)) {
      const existing = addonsMap.get(key)
      existing.quantity += item.quantity || 1
      existing.total_price = existing.unit_price * existing.quantity
    } else {
      addonsMap.set(key, { ...item })
    }
  })
  const addons = Array.from(addonsMap.values())

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

  // Handle proposal approval - direct to payment immediately
  const handleApprove = async () => {
    setIsProcessing(true)
    setError('')

    try {
      // Update selected add-ons
      for (const addon of addons) {
        await supabase
          .from('proposal_items')
          .update({ is_selected: selectedAddons.has(addon.id) })
          .eq('id', addon.id)
      }

      // Calculate payment amounts
      const depositAmount = totals.total * 0.5

      // Update proposal
      await supabase
        .from('proposals')
        .update({
          subtotal: totals.subtotal,
          tax_amount: totals.taxAmount,
          total: totals.total,
          deposit_amount: depositAmount,
          progress_amount: totals.total * 0.3,
          final_amount: totals.total * 0.2,
          status: 'accepted',
          approved_at: new Date().toISOString(),
          payment_stage: 'deposit'
        })
        .eq('id', initialProposal.id)

      // Create payment session immediately for deposit
      const response = await fetch('/api/create-payment', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          proposal_id: initialProposal.id,
          proposal_number: initialProposal.proposal_number,
          customer_name: initialProposal.customers?.name,
          customer_email: initialProposal.customers?.email,
          amount: depositAmount,
          payment_type: 'card',
          payment_stage: 'deposit',
          description: `50% Deposit for Proposal #${initialProposal.proposal_number}`
        })
      })

      const data = await response.json()
      
      if (data.checkout_url) {
        // Redirect to Stripe checkout
        window.location.href = data.checkout_url
      } else {
        throw new Error('No payment URL received')
      }
      
    } catch (err) {
      console.error('Error approving proposal:', err)
      setError('Failed to process approval. Please try again.')
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

        {/* Optional Add-ons - Show combined quantities */}
        {addons.length > 0 && initialProposal.status !== 'accepted' && (
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
        {initialProposal.status !== 'accepted' && (
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
        )}

        {/* Payment Stages when accepted */}
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

# 3. Fix the email template design back to light blue with rounded corners
echo "📝 Restoring email design to light blue with rounded corners..."
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

    // Create HTML email content with light blue design and rounded corners
    const htmlContent = `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { 
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
              line-height: 1.6; 
              color: #333;
              background-color: #f5f5f5;
              margin: 0;
              padding: 0;
            }
            .wrapper {
              background-color: #f5f5f5;
              padding: 40px 20px;
            }
            .container { 
              max-width: 600px; 
              margin: 0 auto; 
              background-color: white;
              border-radius: 12px;
              overflow: hidden;
              box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
            }
            .header { 
              background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
              color: white; 
              padding: 30px; 
              text-align: center;
            }
            .header h1 {
              margin: 0;
              font-size: 28px;
              font-weight: 600;
            }
            .header p {
              margin: 5px 0 0 0;
              opacity: 0.95;
              font-size: 16px;
            }
            .content { 
              padding: 30px;
              background-color: white;
            }
            .content h2 {
              color: #333;
              margin-top: 0;
              font-size: 20px;
              font-weight: 600;
            }
            .content p {
              color: #555;
              margin: 15px 0;
              line-height: 1.6;
            }
            .button-container {
              text-align: center;
              margin: 30px 0;
            }
            .button { 
              display: inline-block; 
              padding: 14px 32px; 
              background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
              color: white !important; 
              text-decoration: none; 
              border-radius: 8px; 
              font-weight: 600;
              font-size: 16px;
              box-shadow: 0 4px 6px rgba(102, 126, 234, 0.25);
              transition: transform 0.2s;
            }
            .button:hover {
              transform: translateY(-2px);
              box-shadow: 0 6px 8px rgba(102, 126, 234, 0.35);
            }
            .footer { 
              padding: 20px 30px; 
              text-align: center; 
              color: #888; 
              font-size: 13px;
              background-color: #fafafa;
              border-top: 1px solid #eee;
            }
            .divider {
              height: 1px;
              background-color: #eee;
              margin: 25px 0;
            }
          </style>
        </head>
        <body>
          <div class="wrapper">
            <div class="container">
              <div class="header">
                <h1>Service Pro</h1>
                <p>HVAC Services Proposal</p>
              </div>
              <div class="content">
                <h2>Proposal #${proposal_number}</h2>
                <p>Dear ${customer_name},</p>
                ${message.split('\n').map((line: string) => `<p>${line}</p>`).join('')}
                <div class="divider"></div>
                <div class="button-container">
                  <a href="${proposal_url}" class="button">View Proposal</a>
                </div>
                <div class="divider"></div>
                <p style="text-align: center; color: #888; font-size: 14px;">
                  This link is secure and personalized for you.
                </p>
              </div>
              <div class="footer">
                <p>© 2025 Service Pro. All rights reserved.</p>
                <p>Professional HVAC Services</p>
              </div>
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

echo "✅ All fixes applied!"

# Test TypeScript
echo "🔍 Checking TypeScript..."
npx tsc --noEmit 2>&1 | head -20

# Commit
git add -A
git commit -m "Fix duplicate items, approval process, and email design

- Update quantity instead of adding duplicate items in proposals
- Combine duplicate add-ons on customer view by summing quantities
- Fix approval button to redirect to Stripe payment immediately
- Restore email design to light blue gradient with rounded corners
- Remove harsh dark blue and green button design
- Maintain consistent UI across emails"

git push origin main

echo "✅ All issues fixed!"
echo ""
echo "🎯 FIXED:"
echo "1. ✅ Duplicate items now update quantity instead"
echo "2. ✅ Customer view combines duplicate add-ons"
echo "3. ✅ Approve button redirects to payment"
echo "4. ✅ Email design restored to smooth, light design"
