'use client'

import { useEffect, useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Progress } from '@/components/ui/progress'
import { AlertCircle, Mail } from 'lucide-react'
import { Alert, AlertDescription } from '@/components/ui/alert'

interface EmailUsage {
  today: number
  month: number
  todayRemaining: number
  monthRemaining: number
}

export function EmailUsageWidget() {
  const [usage, setUsage] = useState<EmailUsage | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchUsage()
  }, [])

  const fetchUsage = async () => {
    try {
      const response = await fetch('/api/email-usage')
      const data = await response.json()
      setUsage(data)
    } catch (error) {
      console.error('Failed to fetch email usage:', error)
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <Card>
        <CardContent className="p-6">
          <div className="animate-pulse space-y-2">
            <div className="h-4 bg-gray-200 rounded w-1/2"></div>
            <div className="h-8 bg-gray-200 rounded"></div>
          </div>
        </CardContent>
      </Card>
    )
  }

  if (!usage) return null

  const todayPercentage = (usage.today / 100) * 100
  const monthPercentage = (usage.month / 3000) * 100
  const isNearDailyLimit = usage.today >= 90
  const isNearMonthlyLimit = usage.month >= 2700

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Mail className="w-5 h-5" />
          Email Usage (Resend)
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Daily Usage */}
        <div>
          <div className="flex justify-between text-sm mb-1">
            <span>Today</span>
            <span className={isNearDailyLimit ? 'text-red-600 font-semibold' : ''}>
              {usage.today} / 100
            </span>
          </div>
          <Progress 
            value={todayPercentage} 
            className={isNearDailyLimit ? 'bg-red-100' : ''}
          />
          {isNearDailyLimit && (
            <Alert className="mt-2 border-red-200 bg-red-50">
              <AlertCircle className="h-4 w-4 text-red-600" />
              <AlertDescription className="text-red-800">
                Approaching daily limit! Only {usage.todayRemaining} emails remaining today.
                <a href="https://resend.com/billing" 
                   target="_blank" 
                   rel="noopener noreferrer"
                   className="underline ml-1 font-semibold">
                  Upgrade to Pro
                </a>
              </AlertDescription>
            </Alert>
          )}
        </div>

        {/* Monthly Usage */}
        <div>
          <div className="flex justify-between text-sm mb-1">
            <span>This Month</span>
            <span className={isNearMonthlyLimit ? 'text-orange-600 font-semibold' : ''}>
              {usage.month} / 3,000
            </span>
          </div>
          <Progress 
            value={monthPercentage}
            className={isNearMonthlyLimit ? 'bg-orange-100' : ''}
          />
          {isNearMonthlyLimit && (
            <Alert className="mt-2 border-orange-200 bg-orange-50">
              <AlertCircle className="h-4 w-4 text-orange-600" />
              <AlertDescription className="text-orange-800">
                Approaching monthly limit! Only {usage.monthRemaining} emails remaining.
              </AlertDescription>
            </Alert>
          )}
        </div>

        {/* Plan Info */}
        <div className="text-xs text-gray-500 pt-2 border-t">
          <p>Free Plan: 100/day, 3,000/month</p>
          <p>Pro Plan: Unlimited daily, 5,000/month ($20/mo)</p>
        </div>
      </CardContent>
    </Card>
  )
}