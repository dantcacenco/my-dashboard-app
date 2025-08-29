import { NextResponse } from 'next/server'
import { getEmailUsageStats } from '@/lib/email-tracking'

export async function GET() {
  try {
    const stats = await getEmailUsageStats()
    return NextResponse.json(stats)
  } catch (error) {
    console.error('Failed to get email usage:', error)
    return NextResponse.json(
      { today: 0, month: 0, todayRemaining: 100, monthRemaining: 3000 },
      { status: 500 }
    )
  }
}