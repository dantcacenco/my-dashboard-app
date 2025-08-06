import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function POST(request: NextRequest) {
  try {
    const { proposalId, customerEmail, proposalNumber, token } = await request.json()

    if (!proposalId || !customerEmail || !proposalNumber || !token) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    const supabase = await createClient()

    // Log the activity
    await supabase
      .from('proposal_activities')
      .insert({
        proposal_id: proposalId,
        activity_type: 'sent_to_customer',
        description: `Proposal sent to ${customerEmail}`,
        metadata: {
          customer_email: customerEmail,
          proposal_number: proposalNumber,
          view_link: `${process.env.NEXT_PUBLIC_BASE_URL}/proposal/view/${token}`
        }
      })

    // In a real app, you would send an email here
    // For now, we'll just return success
    console.log(`Would send email to ${customerEmail} with link: ${process.env.NEXT_PUBLIC_BASE_URL}/proposal/view/${token}`)

    return NextResponse.json({ success: true })

  } catch (error) {
    console.error('Error sending proposal:', error)
    return NextResponse.json(
      { error: 'Failed to send proposal' },
      { status: 500 }
    )
  }
}
