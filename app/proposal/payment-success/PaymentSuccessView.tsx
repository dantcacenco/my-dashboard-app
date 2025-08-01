'use client'

interface Customer {
  id: string
  name: string
  email: string
  phone: string
}

interface Proposal {
  id: string
  proposal_number: string
  title: string
  total: number
  customers: Customer
}

interface PaymentSuccessViewProps {
  proposal: Proposal
  paymentAmount: number
  paymentMethod: string
  sessionId: string
}

export default function PaymentSuccessView({
  proposal,
  paymentAmount,
  paymentMethod,
  sessionId
}: PaymentSuccessViewProps) {
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  const getPaymentMethodDisplay = (method: string) => {
    switch (method) {
      case 'card':
        return 'Credit/Debit Card'
      case 'ach':
        return 'ACH Bank Transfer'
      default:
        return 'Card Payment'
    }
  }

  const handlePrint = () => {
    window.print()
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Success Header */}
        <div className="bg-white rounded-lg shadow-sm p-8 mb-6 text-center">
          <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-8 h-8 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
          </div>
          
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Payment Successful!</h1>
          <p className="text-lg text-gray-600 mb-4">
            Thank you for your deposit payment. Your project is now scheduled to begin.
          </p>
          
          <div className="bg-green-50 border border-green-200 rounded-lg p-4">
            <p className="text-green-800 font-medium">
              🎉 Your deposit of {formatCurrency(paymentAmount)} has been received
            </p>
          </div>
        </div>

        {/* Payment Details */}
        <div className="bg-white rounded-lg shadow-sm p-6 mb-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">Payment Details</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <span className="text-sm font-medium text-gray-700">Proposal Number:</span>
              <p className="text-gray-900">{proposal.proposal_number}</p>
            </div>
            <div>
              <span className="text-sm font-medium text-gray-700">Customer:</span>
              <p className="text-gray-900">{proposal.customers[0].name}</p>
            </div>
            <div>
              <span className="text-sm font-medium text-gray-700">Payment Method:</span>
              <p className="text-gray-900">{getPaymentMethodDisplay(paymentMethod)}</p>
            </div>
            <div>
              <span className="text-sm font-medium text-gray-700">Transaction ID:</span>
              <p className="text-gray-900 font-mono text-sm">{sessionId.slice(-12)}</p>
            </div>
            <div>
              <span className="text-sm font-medium text-gray-700">Deposit Amount:</span>
              <p className="text-lg font-bold text-green-600">{formatCurrency(paymentAmount)}</p>
            </div>
            <div>
              <span className="text-sm font-medium text-gray-700">Remaining Balance:</span>
              <p className="text-lg font-semibold text-gray-900">
                {formatCurrency(proposal.total - paymentAmount)}
              </p>
            </div>
          </div>
        </div>

        {/* Project Details */}
        <div className="bg-white rounded-lg shadow-sm p-6 mb-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">Project Information</h2>
          
          <div className="space-y-3">
            <div>
              <span className="text-sm font-medium text-gray-700">Project:</span>
              <p className="text-gray-900">{proposal.title}</p>
            </div>
            <div>
              <span className="text-sm font-medium text-gray-700">Total Project Value:</span>
              <p className="text-xl font-bold text-gray-900">{formatCurrency(proposal.total)}</p>
            </div>
            <div>
              <span className="text-sm font-medium text-gray-700">Payment Date:</span>
              <p className="text-gray-900">{new Date().toLocaleDateString('en-US', {
                year: 'numeric',
                month: 'long',
                day: 'numeric'
              })}</p>
            </div>
          </div>
        </div>

        {/* Next Steps */}
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-6 mb-6">
          <h2 className="text-xl font-semibold text-blue-900 mb-4">What Happens Next?</h2>
          
          <div className="space-y-3">
            <div className="flex items-start">
              <div className="w-6 h-6 bg-blue-600 text-white rounded-full flex items-center justify-center text-sm font-bold mr-3 mt-0.5">
                1
              </div>
              <div>
                <p className="font-medium text-blue-900">Project Scheduling</p>
                <p className="text-blue-800 text-sm">We'll contact you within 24 hours to schedule your project start date.</p>
              </div>
            </div>
            
            <div className="flex items-start">
              <div className="w-6 h-6 bg-blue-600 text-white rounded-full flex items-center justify-center text-sm font-bold mr-3 mt-0.5">
                2
              </div>
              <div>
                <p className="font-medium text-blue-900">Material Preparation</p>
                <p className="text-blue-800 text-sm">Our team will prepare all necessary materials and equipment for your project.</p>
              </div>
            </div>
            
            <div className="flex items-start">
              <div className="w-6 h-6 bg-blue-600 text-white rounded-full flex items-center justify-center text-sm font-bold mr-3 mt-0.5">
                3
              </div>
              <div>
                <p className="font-medium text-blue-900">Project Completion</p>
                <p className="text-blue-800 text-sm">Upon completion, we'll collect the remaining balance of {formatCurrency(proposal.total - paymentAmount)}.</p>
              </div>
            </div>
          </div>
        </div>

        {/* Contact Information */}
        <div className="bg-white rounded-lg shadow-sm p-6 mb-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">Contact Information</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <span className="text-sm font-medium text-gray-700">Phone:</span>
              <p className="text-gray-900">(555) 123-4567</p>
            </div>
            <div>
              <span className="text-sm font-medium text-gray-700">Email:</span>
              <p className="text-gray-900">info@servicepro.com</p>
            </div>
          </div>
          
          <div className="mt-4 p-4 bg-gray-50 rounded-lg">
            <p className="text-sm text-gray-600">
              <strong>Questions about your project?</strong> Contact us anytime. We're here to ensure your HVAC project exceeds expectations.
            </p>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex gap-4 justify-center print:hidden">
          <button
            onClick={handlePrint}
            className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium"
          >
            Print Receipt
          </button>
          <a
            href={`mailto:${proposal.customers[0].email}?subject=Payment Receipt - ${proposal.proposal_number}&body=Thank you for your payment! Your receipt is attached.`}
            className="px-6 py-3 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 font-medium"
          >
            Email Receipt
          </a>
        </div>

        {/* Footer */}
        <div className="text-center text-gray-500 text-sm py-8">
          <p>© 2025 Service Pro - Professional HVAC Services</p>
          <p>Thank you for choosing Service Pro for your HVAC needs!</p>
        </div>
      </div>
    </div>
  )
}