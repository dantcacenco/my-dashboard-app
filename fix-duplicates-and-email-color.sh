#!/bin/bash
set -e

echo "🔧 Fixing duplicate items display and email button color..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# 1. Fix the proposal display to combine duplicates
echo "📝 Updating ProposalView to combine duplicate items..."
cat > combine-duplicates.sh << 'SCRIPT'
#!/bin/bash

# Update ProposalView.tsx to combine duplicate items
cat > app/\(authenticated\)/proposals/\[id\]/ProposalView.tsx << 'EOF'
'use client'

import { useState, useRef } from 'react'
import Link from 'next/link'
import SendProposal from '@/components/proposals/SendProposal'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'
import { formatCurrency, formatDate } from '@/lib/utils'
import PaymentStages from './PaymentStages'

interface ProposalViewProps {
  proposal: any
  userRole: string | null
  userId: string
}

export default function ProposalView({ proposal, userRole, userId }: ProposalViewProps) {
  const [showSendModal, setShowSendModal] = useState(false)
  const [showPrintView, setShowPrintView] = useState(false)
  const printRef = useRef<HTMLDivElement>(null)
  const router = useRouter()
  const supabase = createClient()

  // Combine duplicate items by name
  const combineItems = (items: any[]) => {
    const itemMap = new Map()
    
    items.forEach(item => {
      const key = item.name
      if (itemMap.has(key)) {
        const existing = itemMap.get(key)
        existing.quantity += item.quantity || 1
        existing.total_price = existing.unit_price * existing.quantity
      } else {
        itemMap.set(key, { ...item })
      }
    })
    
    return Array.from(itemMap.values())
  }

  // Separate and combine services and add-ons
  const allItems = proposal.proposal_items || []
  const services = combineItems(allItems.filter((item: any) => !item.is_addon))
  const addons = combineItems(allItems.filter((item: any) => item.is_addon))

  const handleSendProposal = async () => {
    try {
      const { data: updatedProposal } = await supabase
        .from('proposals')
        .update({
          status: 'sent',
          sent_at: new Date().toISOString()
        })
        .eq('id', proposal.id)
        .select()
        .single()

      if (updatedProposal) {
        router.refresh()
      }
    } catch (error) {
      console.error('Error sending proposal:', error)
    }
    setShowSendModal(false)
  }

  const getStatusBadgeClass = (status: string) => {
    switch (status) {
      case 'draft': return 'bg-gray-100 text-gray-800'
      case 'sent': return 'bg-blue-100 text-blue-800'
      case 'accepted': return 'bg-green-100 text-green-800'
      case 'rejected': return 'bg-red-100 text-red-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  const getPaymentProgress = () => {
    if (proposal.payment_status === 'not_started') return null
    
    return (
      <div className="mt-6">
        <PaymentStages
          depositPaidAt={proposal.deposit_paid_at}
          progressPaidAt={proposal.progress_paid_at}
          finalPaidAt={proposal.final_paid_at}
          depositAmount={proposal.deposit_amount || 0}
          progressAmount={proposal.progress_payment_amount || 0}
          finalAmount={proposal.final_payment_amount || 0}
          currentStage={proposal.payment_stage || 'deposit'}
        />
      </div>
    )
  }

  // Print view
  if (showPrintView) {
    return (
      <div className="fixed inset-0 bg-white z-50 overflow-auto">
        <div className="max-w-4xl mx-auto p-8" ref={printRef}>
          {/* Print content */}
          <div className="mb-8">
            <h1 className="text-3xl font-bold">Proposal #{proposal.proposal_number}</h1>
            <p className="text-gray-600 mt-2">{formatDate(proposal.created_at)}</p>
          </div>
          
          <div className="grid grid-cols-2 gap-8 mb-8">
            <div>
              <h3 className="font-semibold mb-2">From:</h3>
              <p>Service Pro HVAC</p>
              <p>Phone: (555) 123-4567</p>
              <p>Email: info@servicepro.com</p>
            </div>
            <div>
              <h3 className="font-semibold mb-2">To:</h3>
              <p>{proposal.customers?.name}</p>
              <p>{proposal.customers?.email}</p>
              <p>{proposal.customers?.phone}</p>
              <p>{proposal.customers?.address}</p>
            </div>
          </div>

          <div className="mb-8">
            <h3 className="font-semibold mb-4">Services</h3>
            <table className="w-full">
              <thead>
                <tr className="border-b">
                  <th className="text-left py-2">Item</th>
                  <th className="text-center py-2">Qty</th>
                  <th className="text-right py-2">Price</th>
                  <th className="text-right py-2">Total</th>
                </tr>
              </thead>
              <tbody>
                {services.map((item: any) => (
                  <tr key={item.id} className="border-b">
                    <td className="py-2">
                      <div>
                        <div className="font-medium">{item.name}</div>
                        <div className="text-sm text-gray-600">{item.description}</div>
                      </div>
                    </td>
                    <td className="text-center py-2">{item.quantity}</td>
                    <td className="text-right py-2">${item.unit_price?.toFixed(2)}</td>
                    <td className="text-right py-2">${item.total_price?.toFixed(2)}</td>
                  </tr>
                ))}
                {addons.filter((item: any) => item.is_selected).map((item: any) => (
                  <tr key={item.id} className="border-b">
                    <td className="py-2">
                      <div>
                        <div className="font-medium">{item.name} (Add-on)</div>
                        <div className="text-sm text-gray-600">{item.description}</div>
                      </div>
                    </td>
                    <td className="text-center py-2">{item.quantity}</td>
                    <td className="text-right py-2">${item.unit_price?.toFixed(2)}</td>
                    <td className="text-right py-2">${item.total_price?.toFixed(2)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="flex justify-end mb-8">
            <div className="w-64">
              <div className="flex justify-between py-2">
                <span>Subtotal:</span>
                <span>${proposal.subtotal?.toFixed(2)}</span>
              </div>
              <div className="flex justify-between py-2">
                <span>Tax ({(proposal.tax_rate * 100).toFixed(1)}%):</span>
                <span>${proposal.tax_amount?.toFixed(2)}</span>
              </div>
              <div className="flex justify-between py-2 font-bold text-lg border-t">
                <span>Total:</span>
                <span>${proposal.total?.toFixed(2)}</span>
              </div>
            </div>
          </div>

          {/* Print actions */}
          <div className="flex justify-center gap-4 print:hidden mt-8">
            <button
              onClick={() => window.print()}
              className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              Print
            </button>
            <button
              onClick={() => setShowPrintView(false)}
              className="px-6 py-2 bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300"
            >
              Close
            </button>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      {/* Header */}
      <div className="mb-8">
        <div className="flex justify-between items-start">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">
              Proposal #{proposal.proposal_number}
            </h1>
            <p className="text-gray-600 mt-2">
              Created {formatDate(proposal.created_at)}
            </p>
          </div>
          <div className="flex gap-2">
            <Link
              href={`/proposals/${proposal.id}/edit`}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              Edit
            </Link>
            <button
              onClick={() => setShowPrintView(true)}
              className="px-4 py-2 bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300"
            >
              Print
            </button>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Main Content */}
        <div className="lg:col-span-2 space-y-6">
          {/* Customer Info */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-lg font-semibold mb-4">Customer Information</h2>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-gray-600">Name</p>
                <p className="font-medium">{proposal.customers?.name}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Email</p>
                <p className="font-medium">{proposal.customers?.email}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Phone</p>
                <p className="font-medium">{proposal.customers?.phone || '-'}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Address</p>
                <p className="font-medium">{proposal.customers?.address || '-'}</p>
              </div>
            </div>
          </div>

          {/* Services */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-lg font-semibold mb-4">Services</h2>
            <div className="space-y-3">
              {services.map((item: any) => (
                <div key={item.id} className="border rounded-lg p-4">
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

          {/* Add-ons */}
          {addons.length > 0 && (
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-lg font-semibold mb-4">Optional Add-ons</h2>
              <p className="text-sm text-gray-600 mb-4">
                Note: Customers can select add-ons when viewing the proposal
              </p>
              <div className="space-y-3">
                {addons.map((item: any) => (
                  <div key={item.id} className="border rounded-lg p-4 border-orange-200 bg-orange-50">
                    <div className="flex justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-2">
                          <h3 className="font-medium">{item.name}</h3>
                          <span className="text-xs bg-orange-200 text-orange-800 px-2 py-1 rounded">
                            Add-on
                          </span>
                          {!item.is_selected && (
                            <span className="text-xs text-gray-500">Not selected</span>
                          )}
                        </div>
                        <p className="text-sm text-gray-600 mt-1">{item.description}</p>
                        <p className="text-sm text-gray-500 mt-2">
                          Qty: {item.quantity} @ ${item.unit_price?.toFixed(2)}
                        </p>
                      </div>
                      <div className="text-right">
                        <p className={`font-bold text-lg ${item.is_selected ? 'text-green-600' : 'text-gray-400'}`}>
                          ${item.total_price?.toFixed(2)}
                        </p>
                        {!item.is_selected && (
                          <p className="text-xs text-gray-500">Not selected</p>
                        )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Status & Actions */}
          <div className="bg-white rounded-lg shadow p-6">
            <div className="mb-4">
              <p className="text-sm text-gray-600 mb-2">Status</p>
              <span className={`inline-block px-3 py-1 rounded-full text-sm font-semibold ${getStatusBadgeClass(proposal.status)}`}>
                {proposal.status}
              </span>
            </div>

            {proposal.status === 'draft' && (
              <button
                onClick={() => setShowSendModal(true)}
                className="w-full px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
              >
                Send to Customer
              </button>
            )}

            {proposal.status === 'sent' && proposal.customer_view_token && (
              <div className="space-y-3">
                <Link
                  href={`/proposal/view/${proposal.customer_view_token}`}
                  target="_blank"
                  className="block w-full px-4 py-2 bg-blue-600 text-white text-center rounded-lg hover:bg-blue-700"
                >
                  View as Customer
                </Link>
                <button
                  onClick={() => setShowSendModal(true)}
                  className="w-full px-4 py-2 bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300"
                >
                  Resend Email
                </button>
              </div>
            )}

            {proposal.sent_at && (
              <p className="text-sm text-gray-600 mt-4">
                Sent: {formatDate(proposal.sent_at)}
              </p>
            )}
          </div>

          {/* Totals */}
          <div className="bg-white rounded-lg shadow p-6">
            <h3 className="font-semibold mb-4">Totals</h3>
            <div className="space-y-2">
              <div className="flex justify-between">
                <span>Subtotal:</span>
                <span>${proposal.subtotal?.toFixed(2)}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span>Tax ({(proposal.tax_rate * 100).toFixed(1)}%):</span>
                <span>${proposal.tax_amount?.toFixed(2)}</span>
              </div>
              <div className="flex justify-between font-bold text-lg pt-2 border-t">
                <span>Total:</span>
                <span className="text-green-600">${proposal.total?.toFixed(2)}</span>
              </div>
            </div>

            {getPaymentProgress()}
          </div>
        </div>
      </div>

      {/* Send Proposal Modal */}
      {showSendModal && (
        <SendProposal
          proposal={proposal}
          onClose={() => setShowSendModal(false)}
          onSend={handleSendProposal}
        />
      )}
    </div>
  )
}
EOF
SCRIPT

chmod +x combine-duplicates.sh
./combine-duplicates.sh
rm combine-duplicates.sh

# 2. Fix email button color to light blue
echo "📝 Changing email button back to light blue..."
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

    // Create HTML email content with light blue design
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
              background-color: #3B82F6;
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
              background-color: #3B82F6;
              color: white !important; 
              text-decoration: none; 
              border-radius: 8px; 
              font-weight: 600;
              font-size: 16px;
              box-shadow: 0 2px 4px rgba(59, 130, 246, 0.25);
            }
            .button:hover {
              background-color: #2563EB;
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

echo "✅ Fixed duplicate display and email button color!"

# Test TypeScript
echo "🔍 Checking TypeScript..."
npx tsc --noEmit 2>&1 | head -20

# Commit
git add -A
git commit -m "Fix duplicate items display and email button color

- Combine duplicate items in ProposalView (show Qty: 3 instead of 3 separate items)
- Match customer view behavior for consistent display
- Change email button back to light blue (#3B82F6) instead of purple gradient
- Maintain rounded corners and clean design"

git push origin main

echo "✅ All fixes applied!"
echo ""
echo "🎯 FIXED:"
echo "1. ✅ Duplicate items now show as Qty: 3 in ProposalView"
echo "2. ✅ Email button is now light blue (#3B82F6)"
echo "3. ✅ Consistent display across edit and customer views"
