import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function POST(request: NextRequest) {
  try {
    const { proposalId, proposalNumber, customerEmail, customerName, message } = await request.json()

    if (!proposalId || !customerEmail) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    const supabase = await createClient()

    // Ensure proposal has a customer_view_token
    const { data: proposal, error: fetchError } = await supabase
      .from('proposals')
      .select('customer_view_token')
      .eq('id', proposalId)
      .single()

    if (fetchError) {
      return NextResponse.json(
        { error: 'Proposal not found' },
        { status: 404 }
      )
    }

    let token = proposal.customer_view_token
    if (!token) {
      token = crypto.randomUUID()
      const { error: updateError } = await supabase
        .from('proposals')
        .update({ customer_view_token: token })
        .eq('id', proposalId)

      if (updateError) {
        return NextResponse.json(
          { error: 'Failed to generate token' },
          { status: 500 }
        )
      }
    }

    // Here you would normally send an email using your email service
    // For now, we'll just return success
    console.log('Sending proposal email:', {
      to: customerEmail,
      proposalNumber,
      customerName,
      message,
      viewLink: `${process.env.NEXT_PUBLIC_BASE_URL}/proposal/view/${token}`
    })

    return NextResponse.json({ 
      success: true,
      token,
      message: 'Proposal sent successfully'
    })

  } catch (error: any) {
    console.error('Error sending proposal:', error)
    return NextResponse.json(
      { error: 'Failed to send proposal' },
      { status: 500 }
    )
  }
}
