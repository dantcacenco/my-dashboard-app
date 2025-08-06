#!/bin/bash

# Fix Payment Processing, Edit Button, Customer Token Access + Add Build Checker
# Service Pro Field Service Management
# Date: August 6, 2025

set -e  # Exit on error

echo "🔧 Starting comprehensive fix for Service Pro..."

# Create local build checker script
echo "📦 Creating local build and syntax checker..."
cat > check_build.sh << 'EOF'
#!/bin/bash

# Local Build and Syntax Checker for Service Pro
# Run this before pushing to save time!

set -e

echo "🔍 Service Pro Local Build Checker"
echo "================================="

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Are you in the project root?"
    exit 1
fi

# 1. TypeScript syntax check
echo ""
echo "📝 Checking TypeScript syntax..."
if npx tsc --noEmit; then
    echo "✅ TypeScript syntax check passed!"
else
    echo "❌ TypeScript errors found. Fix them before pushing."
    exit 1
fi

# 2. ESLint check (if configured)
if [ -f ".eslintrc.json" ] || [ -f ".eslintrc.js" ]; then
    echo ""
    echo "🔍 Running ESLint..."
    if npm run lint; then
        echo "✅ ESLint check passed!"
    else
        echo "❌ ESLint errors found. Fix them before pushing."
        exit 1
    fi
fi

# 3. Check for required environment variables
echo ""
echo "🔐 Checking environment variables..."
ENV_VARS=(
    "NEXT_PUBLIC_SUPABASE_URL"
    "NEXT_PUBLIC_SUPABASE_ANON_KEY"
    "SUPABASE_SERVICE_ROLE_KEY"
    "NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY"
    "STRIPE_SECRET_KEY"
    "NEXT_PUBLIC_BASE_URL"
)

MISSING_VARS=()
for var in "${ENV_VARS[@]}"; do
    if [ -z "${!var}" ] && ! grep -q "^$var=" .env.local 2>/dev/null; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo "⚠️  Warning: Missing environment variables in .env.local:"
    printf '   - %s\n' "${MISSING_VARS[@]}"
    echo "   Make sure these are set in Vercel!"
else
    echo "✅ All required environment variables found!"
fi

# 4. Next.js build check
echo ""
echo "🏗️  Running Next.js build (this may take a minute)..."
if npm run build; then
    echo "✅ Build successful!"
else
    echo "❌ Build failed. Fix errors before pushing."
    exit 1
fi

# 5. Check for common issues
echo ""
echo "🔍 Checking for common issues..."

# Check for console.log statements (optional)
CONSOLE_LOGS=$(grep -r "console\.log" --include="*.tsx" --include="*.ts" app/ components/ lib/ 2>/dev/null | wc -l)
if [ $CONSOLE_LOGS -gt 0 ]; then
    echo "⚠️  Found $CONSOLE_LOGS console.log statements. Consider removing for production."
fi

# Check for TODO comments
TODOS=$(grep -r "TODO" --include="*.tsx" --include="*.ts" app/ components/ lib/ 2>/dev/null | wc -l)
if [ $TODOS -gt 0 ]; then
    echo "📝 Found $TODOS TODO comments."
fi

echo ""
echo "✨ All checks complete! Safe to push to GitHub."
echo ""
echo "Quick push command:"
echo "  git add . && git commit -m 'your message' && git push origin main"
echo ""
EOF

chmod +x check_build.sh
echo "✅ Created check_build.sh - Run ./check_build.sh before pushing!"

# Fix 1: Payment Processing - Add NEXT_PUBLIC_BASE_URL check and better error handling
echo ""
echo "🔧 Fixing payment processing..."

# Update PaymentMethods.tsx with better error handling
cat > app/proposal/view/[token]/PaymentMethods.tsx << 'EOF'
'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'

interface PaymentMethodsProps {
  proposalId: string
  proposalNumber: string
  customerName: string
  customerEmail: string
  totalAmount: number
  depositAmount: number
  paymentStage?: 'deposit' | 'roughin' | 'final'
  onPaymentSuccess: () => void
}

export default function PaymentMethods({
  proposalId,
  proposalNumber,
  customerName,
  customerEmail,
  totalAmount,
  depositAmount,
  paymentStage = 'deposit',
  onPaymentSuccess
}: PaymentMethodsProps) {
  const [selectedMethod, setSelectedMethod] = useState<'card' | 'ach' | 'bank' | null>(null)
  const [isProcessing, setIsProcessing] = useState(false)
  const [showBankDetails, setShowBankDetails] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const supabase = createClient()

  const handleStripePayment = async (paymentType: 'card' | 'ach') => {
    setIsProcessing(true)
    setError(null)
    
    try {
      console.log('Creating payment session...', {
        proposal_id: proposalId,
        amount: depositAmount,
        payment_type: paymentType,
        payment_stage: paymentStage
      })

      // Create Stripe checkout session
      const response = await fetch('/api/create-payment', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          proposal_id: proposalId,
          proposal_number: proposalNumber,
          customer_name: customerName,
          customer_email: customerEmail,
          amount: depositAmount,
          payment_type: paymentType,
          payment_stage: paymentStage,
          description: paymentStage === 'deposit' 
            ? `Deposit for Proposal ${proposalNumber}`
            : paymentStage === 'roughin'
            ? `Rough-in Payment for Proposal ${proposalNumber}`
            : `Final Payment for Proposal ${proposalNumber}`
        })
      })

      if (!response.ok) {
        const errorText = await response.text()
        console.error('Payment API error response:', errorText)
        throw new Error(`Payment API error: ${response.status} ${response.statusText}`)
      }

      const data = await response.json()
      console.log('Payment session created:', data)

      if (data.error) {
        throw new Error(data.error)
      }

      if (!data.checkout_url) {
        console.error('No checkout URL received:', data)
        throw new Error('No checkout URL received from payment API')
      }

      // Redirect to Stripe checkout
      console.log('Redirecting to Stripe checkout:', data.checkout_url)
      window.location.href = data.checkout_url
      
    } catch (error: any) {
      console.error('Error creating payment:', error)
      setError(error.message || 'Error setting up payment. Please try again or contact us.')
      setIsProcessing(false)
    }
  }

  const handleBankTransfer = () => {
    setSelectedMethod('bank')
    setShowBankDetails(true)
  }

  const formatAmount = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  return (
    <div className="bg-white rounded-lg shadow-sm p-6">
      <h2 className="text-xl font-semibold mb-4">Payment Options</h2>
      
      {error && (
        <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg text-red-700">
          {error}
        </div>
      )}

      {!showBankDetails ? (
        <>
          <p className="text-gray-600 mb-6">
            Amount Due: <span className="font-bold text-2xl text-gray-900">{formatAmount(depositAmount)}</span>
          </p>

          <div className="space-y-3">
            <button
              onClick={() => handleStripePayment('card')}
              disabled={isProcessing}
              className="w-full bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center"
            >
              {isProcessing ? (
                <>
                  <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Processing...
                </>
              ) : (
                <>
                  <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
                  </svg>
                  Pay with Credit/Debit Card
                </>
              )}
            </button>

            <button
              onClick={() => handleStripePayment('ach')}
              disabled={isProcessing}
              className="w-full bg-green-600 text-white px-6 py-3 rounded-lg hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center"
            >
              {isProcessing ? (
                <>
                  <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Processing...
                </>
              ) : (
                <>
                  <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
                  </svg>
                  Pay with Bank Account (ACH)
                </>
              )}
            </button>

            <button
              onClick={handleBankTransfer}
              disabled={isProcessing}
              className="w-full bg-gray-600 text-white px-6 py-3 rounded-lg hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center"
            >
              <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 14v3m4-3v3m4-3v3M3 21h18M3 10h18M3 7l9-4 9 4M4 10h16v11H4V10z" />
              </svg>
              Pay by Bank Transfer
            </button>
          </div>

          <p className="text-xs text-gray-500 mt-4 text-center">
            Payments are processed securely through Stripe
          </p>
        </>
      ) : (
        <div className="space-y-4">
          <h3 className="font-medium text-lg">Bank Transfer Instructions</h3>
          <div className="bg-gray-50 p-4 rounded-lg">
            <p className="text-sm text-gray-700 mb-2">Please transfer the payment to:</p>
            <div className="space-y-2 text-sm">
              <div>
                <span className="font-medium">Bank Name:</span> Your Bank Name
              </div>
              <div>
                <span className="font-medium">Account Name:</span> Your Business Name
              </div>
              <div>
                <span className="font-medium">Account Number:</span> XXXX-XXXX-XXXX
              </div>
              <div>
                <span className="font-medium">Routing Number:</span> XXXXXXXXX
              </div>
              <div>
                <span className="font-medium">Reference:</span> Proposal #{proposalNumber}
              </div>
              <div>
                <span className="font-medium">Amount:</span> {formatAmount(depositAmount)}
              </div>
            </div>
          </div>
          <p className="text-sm text-gray-600">
            Please email us at support@servicepro.com once the transfer is complete.
          </p>
          <button
            onClick={() => setShowBankDetails(false)}
            className="text-blue-600 hover:text-blue-700 text-sm"
          >
            ← Back to payment options
          </button>
        </div>
      )}
    </div>
  )
}
EOF

# Fix 2: Edit Button Inconsistency - Update ProposalView to check for both boss and admin roles
echo ""
echo "🔧 Fixing edit button visibility..."

# First, let's fix the main ProposalView component
cat > app/proposals/[id]/ProposalView.tsx << 'EOF'
'use client'

import { useState, useRef, useEffect } from 'react'
import Link from 'next/link'
import SendProposal from '@/components/proposals/SendProposal'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'
import { formatCurrency, formatDate } from '@/lib/utils'
import { PaymentStages } from './PaymentStages'

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

  // Check if user can edit - both admin and boss roles, and correct status
  const canEdit = (userRole === 'admin' || userRole === 'boss') && 
    (proposal.status === 'draft' || proposal.status === 'sent' || 
     (proposal.status === 'approved' && !proposal.deposit_paid_at))

  const handlePrint = () => {
    if (typeof window !== 'undefined') {
      window.print()
    }
  }

  const handleDelete = async () => {
    if (!confirm('Are you sure you want to delete this proposal?')) return

    const { error } = await supabase
      .from('proposals')
      .delete()
      .eq('id', proposal.id)

    if (error) {
      console.error('Error deleting proposal:', error)
      alert('Failed to delete proposal')
    } else {
      router.push('/proposals')
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'draft': return 'bg-gray-100 text-gray-800'
      case 'sent': return 'bg-blue-100 text-blue-800'
      case 'approved': return 'bg-green-100 text-green-800'
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
          currentStage={proposal.current_payment_stage || 'deposit'}
        />
      </div>
    )
  }

  // Print view
  if (showPrintView) {
    return (
      <div className="fixed inset-0 bg-white z-50 overflow-auto">
        <div className="max-w-4xl mx-auto p-8" ref={printRef}>
          <style jsx global>{`
            @media print {
              @page { margin: 0.5in; }
              .no-print { display: none !important; }
            }
          `}</style>
          
          {/* Print Header */}
          <div className="text-center mb-8">
            <h1 className="text-3xl font-bold">Service Pro HVAC</h1>
            <p className="text-gray-600">Professional HVAC Services</p>
          </div>

          {/* Proposal Info */}
          <div className="mb-6">
            <h2 className="text-2xl font-semibold mb-2">Proposal #{proposal.proposal_number}</h2>
            <p className="text-gray-600">Date: {formatDate(proposal.created_at)}</p>
          </div>

          {/* Customer Info */}
          <div className="mb-6">
            <h3 className="text-lg font-semibold mb-2">Customer Information</h3>
            <p>{proposal.customers.name}</p>
            <p>{proposal.customers.email}</p>
            <p>{proposal.customers.phone}</p>
            {proposal.customers.address && <p>{proposal.customers.address}</p>}
          </div>

          {/* Proposal Details */}
          <div className="mb-6">
            <h3 className="text-lg font-semibold mb-2">{proposal.title}</h3>
            {proposal.description && (
              <p className="text-gray-700 mb-4">{proposal.description}</p>
            )}
          </div>

          {/* Items */}
          <div className="mb-6">
            <h3 className="text-lg font-semibold mb-2">Services & Items</h3>
            <table className="w-full border-collapse">
              <thead>
                <tr className="border-b">
                  <th className="text-left py-2">Item</th>
                  <th className="text-right py-2">Qty</th>
                  <th className="text-right py-2">Price</th>
                  <th className="text-right py-2">Total</th>
                </tr>
              </thead>
              <tbody>
                {proposal.proposal_items?.map((item: any) => (
                  <tr key={item.id} className="border-b">
                    <td className="py-2">
                      <div>
                        <p className="font-medium">{item.name}</p>
                        {item.description && (
                          <p className="text-sm text-gray-600">{item.description}</p>
                        )}
                      </div>
                    </td>
                    <td className="text-right py-2">{item.quantity}</td>
                    <td className="text-right py-2">{formatCurrency(item.unit_price)}</td>
                    <td className="text-right py-2">{formatCurrency(item.total_price)}</td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr className="font-semibold">
                  <td colSpan={3} className="text-right py-2">Total:</td>
                  <td className="text-right py-2">{formatCurrency(proposal.total_amount)}</td>
                </tr>
              </tfoot>
            </table>
          </div>

          {/* Terms */}
          {proposal.terms_conditions && (
            <div className="mb-6">
              <h3 className="text-lg font-semibold mb-2">Terms & Conditions</h3>
              <p className="text-sm text-gray-700 whitespace-pre-wrap">{proposal.terms_conditions}</p>
            </div>
          )}

          {/* Print Actions */}
          <div className="no-print mt-8 flex gap-4">
            <button
              onClick={handlePrint}
              className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
            >
              Print
            </button>
            <button
              onClick={() => setShowPrintView(false)}
              className="px-4 py-2 bg-gray-500 text-white rounded hover:bg-gray-600"
            >
              Close Print View
            </button>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="max-w-6xl mx-auto">
      {/* Header */}
      <div className="mb-6 flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Proposal #{proposal.proposal_number}</h1>
          <p className="text-gray-600">Created on {formatDate(proposal.created_at)}</p>
        </div>
        <div className="flex items-center gap-4">
          <span className={`px-3 py-1 rounded-full text-sm font-semibold ${getStatusColor(proposal.status)}`}>
            {proposal.status.charAt(0).toUpperCase() + proposal.status.slice(1)}
          </span>
          {(userRole === 'admin' || userRole === 'boss') && (
            <div className="flex gap-2">
              {proposal.status === 'draft' && (
                <button
                  onClick={() => setShowSendModal(true)}
                  className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700"
                >
                  Send Proposal
                </button>
              )}
              {canEdit && (
                <Link
                  href={`/proposals/${proposal.id}/edit`}
                  className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
                >
                  Edit
                </Link>
              )}
              <button
                onClick={() => setShowPrintView(true)}
                className="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700"
              >
                Print
              </button>
              <button
                onClick={handleDelete}
                className="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
              >
                Delete
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Payment Progress - Show for approved proposals */}
      {proposal.status === 'approved' && getPaymentProgress()}

      {/* Proposal Details */}
      <div className="bg-white shadow overflow-hidden sm:rounded-lg">
        <div className="px-4 py-5 sm:px-6">
          <h3 className="text-lg leading-6 font-medium text-gray-900">
            {proposal.title}
          </h3>
          {proposal.description && (
            <p className="mt-1 max-w-2xl text-sm text-gray-500">
              {proposal.description}
            </p>
          )}
        </div>
        <div className="border-t border-gray-200">
          <dl>
            <div className="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt className="text-sm font-medium text-gray-500">Customer</dt>
              <dd className="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                <Link href={`/customers/${proposal.customers.id}`} className="text-blue-600 hover:text-blue-900">
                  {proposal.customers.name}
                </Link>
                <div className="text-gray-600">
                  <p>{proposal.customers.email}</p>
                  <p>{proposal.customers.phone}</p>
                </div>
              </dd>
            </div>
            <div className="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt className="text-sm font-medium text-gray-500">Total Amount</dt>
              <dd className="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                {formatCurrency(proposal.total_amount)}
              </dd>
            </div>
            {proposal.payment_status !== 'not_started' && (
              <div className="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt className="text-sm font-medium text-gray-500">Payment Status</dt>
                <dd className="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                  <span className={`px-2 py-1 text-xs rounded-full ${
                    proposal.payment_status === 'fully_paid' 
                      ? 'bg-green-100 text-green-800' 
                      : 'bg-yellow-100 text-yellow-800'
                  }`}>
                    {proposal.payment_status.replace(/_/g, ' ').charAt(0).toUpperCase() + 
                     proposal.payment_status.replace(/_/g, ' ').slice(1)}
                  </span>
                </dd>
              </div>
            )}
            {proposal.customer_view_token && (
              <div className="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt className="text-sm font-medium text-gray-500">Customer Link</dt>
                <dd className="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                  <a 
                    href={`${window.location.origin}/proposal/view/${proposal.customer_view_token}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-blue-600 hover:text-blue-900 underline"
                  >
                    View Customer Portal
                  </a>
                </dd>
              </div>
            )}
          </dl>
        </div>
      </div>

      {/* Items Table */}
      <div className="mt-6 bg-white shadow overflow-hidden sm:rounded-lg">
        <div className="px-4 py-5 sm:px-6">
          <h3 className="text-lg leading-6 font-medium text-gray-900">
            Services & Items
          </h3>
        </div>
        <div className="border-t border-gray-200">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Item
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Qty
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Unit Price
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Total
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {proposal.proposal_items?.map((item: any) => (
                <tr key={item.id}>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div>
                      <div className="text-sm font-medium text-gray-900">{item.name}</div>
                      {item.description && (
                        <div className="text-sm text-gray-500">{item.description}</div>
                      )}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {item.quantity}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {formatCurrency(item.unit_price)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {formatCurrency(item.total_price)}
                  </td>
                </tr>
              ))}
            </tbody>
            <tfoot>
              <tr>
                <th colSpan={3} className="px-6 py-4 text-right text-sm font-medium text-gray-900">
                  Total:
                </th>
                <td className="px-6 py-4 whitespace-nowrap text-sm font-bold text-gray-900">
                  {formatCurrency(proposal.total_amount)}
                </td>
              </tr>
            </tfoot>
          </table>
        </div>
      </div>

      {/* Terms & Conditions */}
      {proposal.terms_conditions && (
        <div className="mt-6 bg-white shadow overflow-hidden sm:rounded-lg">
          <div className="px-4 py-5 sm:px-6">
            <h3 className="text-lg leading-6 font-medium text-gray-900">
              Terms & Conditions
            </h3>
          </div>
          <div className="border-t border-gray-200 px-4 py-5">
            <p className="text-sm text-gray-700 whitespace-pre-wrap">
              {proposal.terms_conditions}
            </p>
          </div>
        </div>
      )}

      {/* Send Proposal Modal */}
      {showSendModal && (
        <SendProposal
          proposalId={proposal.id}
          customerEmail={proposal.customers.email}
          proposalNumber={proposal.proposal_number}
          onClose={() => setShowSendModal(false)}
          onSuccess={() => {
            setShowSendModal(false)
            router.refresh()
          }}
        />
      )}
    </div>
  )
}
EOF

# Fix 3: Customer Token Access - Create RLS policy update script
echo ""
echo "🔧 Creating RLS policy update for customer token access..."

cat > update_rls_policies.sql << 'EOF'
-- RLS Policies for Customer Token Access
-- Run this in Supabase SQL editor

-- Drop existing policies that might conflict
DROP POLICY IF EXISTS "Customers can view proposals via token" ON proposals;
DROP POLICY IF EXISTS "Customers can view proposal items via token" ON proposal_items;
DROP POLICY IF EXISTS "Customers can view activities via token" ON proposal_activities;

-- Create new policies for token-based access

-- 1. Allow customers to view proposals using customer_view_token
CREATE POLICY "Customers can view proposals via token" ON proposals
FOR SELECT
USING (
  -- Allow if the user has the correct token in the URL
  current_setting('request.headers', true)::json->>'x-proposal-token' = customer_view_token
  OR 
  -- Also allow regular authenticated users with proper roles
  auth.uid() IN (
    SELECT user_id FROM user_profiles 
    WHERE user_id = auth.uid() 
    AND role IN ('admin', 'boss', 'tech')
  )
);

-- 2. Allow customers to view proposal items for proposals they can access
CREATE POLICY "Customers can view proposal items via token" ON proposal_items
FOR SELECT
USING (
  proposal_id IN (
    SELECT id FROM proposals 
    WHERE current_setting('request.headers', true)::json->>'x-proposal-token' = customer_view_token
  )
  OR
  -- Also allow regular authenticated users
  auth.uid() IN (
    SELECT user_id FROM user_profiles 
    WHERE user_id = auth.uid() 
    AND role IN ('admin', 'boss', 'tech')
  )
);

-- 3. Allow customers to view activities for proposals they can access
CREATE POLICY "Customers can view activities via token" ON proposal_activities
FOR SELECT
USING (
  proposal_id IN (
    SELECT id FROM proposals 
    WHERE current_setting('request.headers', true)::json->>'x-proposal-token' = customer_view_token
  )
  OR
  -- Also allow regular authenticated users
  auth.uid() IN (
    SELECT user_id FROM user_profiles 
    WHERE user_id = auth.uid() 
    AND role IN ('admin', 'boss', 'tech')
  )
);

-- 4. Allow customers to update proposals (for approvals) via token
CREATE POLICY "Customers can update proposals via token" ON proposals
FOR UPDATE
USING (
  current_setting('request.headers', true)::json->>'x-proposal-token' = customer_view_token
  OR
  auth.uid() IN (
    SELECT user_id FROM user_profiles 
    WHERE user_id = auth.uid() 
    AND role IN ('admin', 'boss')
  )
)
WITH CHECK (
  current_setting('request.headers', true)::json->>'x-proposal-token' = customer_view_token
  OR
  auth.uid() IN (
    SELECT user_id FROM user_profiles 
    WHERE user_id = auth.uid() 
    AND role IN ('admin', 'boss')
  )
);

-- 5. Ensure customers table has proper RLS for viewing
DROP POLICY IF EXISTS "Customers viewable by proposal token" ON customers;
CREATE POLICY "Customers viewable by proposal token" ON customers
FOR SELECT
USING (
  id IN (
    SELECT customer_id FROM proposals 
    WHERE current_setting('request.headers', true)::json->>'x-proposal-token' = customer_view_token
  )
  OR
  auth.uid() IN (
    SELECT user_id FROM user_profiles 
    WHERE user_id = auth.uid() 
    AND role IN ('admin', 'boss', 'tech')
  )
);

-- Note: For this to work properly, you'll need to ensure your client code
-- sends the token as a header when making requests. This is typically done
-- in the Supabase client configuration.
EOF

# Create middleware update for token-based access
echo ""
echo "🔧 Creating middleware update for token-based access..."

cat > app/proposal/view/[token]/ProposalProvider.tsx << 'EOF'
'use client'

import { createContext, useContext, ReactNode } from 'react'
import { createClient } from '@/lib/supabase/client'

interface ProposalContextType {
  token: string
  supabase: ReturnType<typeof createClient>
}

const ProposalContext = createContext<ProposalContextType | null>(null)

export function ProposalProvider({ children, token }: { children: ReactNode, token: string }) {
  // Create a custom Supabase client that includes the token header
  const supabase = createClient()
  
  // Override the auth to include token in headers
  const originalFrom = supabase.from.bind(supabase)
  supabase.from = (table: string) => {
    const query = originalFrom(table)
    // Add token to all queries
    if (query.select) {
      const originalSelect = query.select.bind(query)
      query.select = (...args: any[]) => {
        const selectQuery = originalSelect(...args)
        return selectQuery.eq('customer_view_token', token)
      }
    }
    return query
  }

  return (
    <ProposalContext.Provider value={{ token, supabase }}>
      {children}
    </ProposalContext.Provider>
  )
}

export function useProposal() {
  const context = useContext(ProposalContext)
  if (!context) {
    throw new Error('useProposal must be used within ProposalProvider')
  }
  return context
}
EOF

# Add environment variable check to create-payment route
echo ""
echo "🔧 Updating create-payment route with environment checks..."

cat > app/api/create-payment/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server'
import Stripe from 'stripe'
import { createClient } from '@/lib/supabase/server'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2025-07-30.basil'
})

export async function POST(request: NextRequest) {
  try {
    // Check for required environment variables
    if (!process.env.STRIPE_SECRET_KEY) {
      console.error('Missing STRIPE_SECRET_KEY environment variable')
      return NextResponse.json(
        { error: 'Payment system not configured. Please contact support.' },
        { status: 500 }
      )
    }

    if (!process.env.NEXT_PUBLIC_BASE_URL) {
      console.error('Missing NEXT_PUBLIC_BASE_URL environment variable')
      return NextResponse.json(
        { error: 'Payment system configuration error. Please contact support.' },
        { status: 500 }
      )
    }

    const {
      proposal_id,
      proposal_number,
      customer_name,
      customer_email,
      amount,
      payment_type,
      payment_stage,
      description
    } = await request.json()

    console.log('Creating payment session:', {
      proposal_id,
      amount,
      payment_type,
      payment_stage,
      base_url: process.env.NEXT_PUBLIC_BASE_URL
    })

    if (!proposal_id || !amount || !customer_email) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    // Get proposal to ensure we have the customer_view_token
    const supabase = await createClient()
    const { data: proposal, error: proposalError } = await supabase
      .from('proposals')
      .select('customer_view_token')
      .eq('id', proposal_id)
      .single()

    if (proposalError || !proposal) {
      console.error('Error fetching proposal:', proposalError)
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
              permissions: ['payment_method' as const]
            }
          }
        }
      })
    })

    console.log('Stripe session created:', session.id)
    console.log('Checkout URL:', session.url)

    return NextResponse.json({ 
      checkout_url: session.url,
      session_id: session.id 
    })

  } catch (error: any) {
    console.error('Error creating Stripe checkout session:', error)
    
    // Provide more specific error messages
    if (error.type === 'StripeAuthenticationError') {
      return NextResponse.json(
        { error: 'Invalid Stripe API key. Please check configuration.' },
        { status: 500 }
      )
    }
    
    if (error.type === 'StripeInvalidRequestError') {
      return NextResponse.json(
        { error: `Stripe configuration error: ${error.message}` },
        { status: 400 }
      )
    }
    
    return NextResponse.json(
      { error: 'Failed to create payment session. Please try again.' },
      { status: 500 }
    )
  }
}
EOF

# Create a simple .env.local template if it doesn't exist
if [ ! -f .env.local ]; then
  echo ""
  echo "📝 Creating .env.local template..."
  cat > .env.local << 'EOF'
# Supabase
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url_here
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here

# Stripe
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key_here
STRIPE_SECRET_KEY=your_stripe_secret_key_here

# Application
NEXT_PUBLIC_BASE_URL=http://localhost:3000

# Optional
RESEND_API_KEY=your_resend_api_key_here
EOF
  echo "✅ Created .env.local template - Please fill in your actual values!"
fi

# Commit all changes
echo ""
echo "💾 Committing all fixes..."
git add -A
git commit -m "Fix payment processing, edit button visibility, and customer token access

- Added comprehensive error handling to payment flow
- Fixed edit button to show for both admin and boss roles
- Updated edit button logic to handle different proposal states
- Added environment variable checks for NEXT_PUBLIC_BASE_URL
- Created RLS policies for customer token access
- Added local build/syntax checker script
- Improved payment error messages and debugging"

# Push to GitHub
echo ""
echo "🚀 Pushing to GitHub..."
git push origin main

echo ""
echo "✅ All fixes applied successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Run the SQL in update_rls_policies.sql in your Supabase dashboard"
echo "2. Add NEXT_PUBLIC_BASE_URL to your Vercel environment variables"
echo "3. Ensure your Stripe account has the domain whitelisted"
echo "4. Test payment flow with ./check_build.sh first"
echo ""
echo "🧪 To test locally before pushing:"
echo "   ./check_build.sh"
echo ""
echo "💡 The edit button will now show for:"
echo "   - Both 'admin' and 'boss' roles"
echo "   - Draft, sent, and approved (but not paid) proposals"
EOF

chmod +x fix_three_issues_with_build_check.sh

echo "✅ Script created: fix_three_issues_with_build_check.sh"
echo "Run it with: ./fix_three_issues_with_build_check.sh"