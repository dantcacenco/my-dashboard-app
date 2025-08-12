'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { CheckCircle } from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

interface PaymentSuccessViewProps {
  proposal: any
}

export default function PaymentSuccessView({ proposal }: PaymentSuccessViewProps) {
  const router = useRouter()
  const [countdown, setCountdown] = useState(5)

  useEffect(() => {
    // Countdown timer
    const timer = setInterval(() => {
      setCountdown((prev) => {
        if (prev <= 1) {
          clearInterval(timer)
          // Redirect to proposal view
          if (proposal.customer_view_token) {
            router.push(`/proposal/view/${proposal.customer_view_token}`)
          } else {
            router.push('/')
          }
          return 0
        }
        return prev - 1
      })
    }, 1000)

    return () => clearInterval(timer)
  }, [proposal, router])

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
      <Card className="max-w-md w-full">
        <CardHeader className="text-center">
          <div className="mx-auto w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mb-4">
            <CheckCircle className="h-10 w-10 text-green-600" />
          </div>
          <CardTitle className="text-2xl">Payment Successful!</CardTitle>
        </CardHeader>
        <CardContent className="text-center space-y-4">
          <p className="text-gray-600">
            Thank you for your payment on Proposal #{proposal.proposal_number}
          </p>
          
          <div className="bg-gray-50 rounded-lg p-4">
            <p className="text-sm text-gray-500 mb-1">Amount Paid</p>
            <p className="text-2xl font-bold text-green-600">
              {formatCurrency(proposal.last_payment_amount || 0)}
            </p>
          </div>

          <div className="pt-4 border-t">
            <p className="text-sm text-gray-600">
              Redirecting to your proposal in {countdown} seconds...
            </p>
          </div>

          <button
            onClick={() => {
              if (proposal.customer_view_token) {
                router.push(`/proposal/view/${proposal.customer_view_token}`)
              }
            }}
            className="text-blue-600 hover:text-blue-700 underline text-sm"
          >
            Click here if not redirected
          </button>
        </CardContent>
      </Card>
    </div>
  )
}
