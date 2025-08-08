import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    console.log('Received send-proposal request:', body)

    const { 
      proposalId, 
      proposalNumber, 
      customerEmail, 
      customerName, 
      message,
      token 
    } = body

    // Validate required fields
    if (!proposalId) {
      console.error('Missing proposalId')
      return NextResponse.json(
        { error: 'Missing proposal ID' },
        { status: 400 }
      )
    }

    if (!customerEmail) {
      console.error('Missing customerEmail')
      return NextResponse.json(
        { error: 'Missing customer email' },
        { status: 400 }
      )
    }

    const supabase = await createClient()

    // Ensure proposal has a customer_view_token
    let customerViewToken = token
    
    if (!customerViewToken) {
      const { data: proposal, error: fetchError } = await supabase
        .from('proposals')
        .select('customer_view_token')
        .eq('id', proposalId)
        .single()

      if (fetchError) {
        console.error('Error fetching proposal:', fetchError)
        return NextResponse.json(
          { error: 'Proposal not found' },
          { status: 404 }
        )
      }

      customerViewToken = proposal?.customer_view_token

      if (!customerViewToken) {
        // Generate a new token if it doesn't exist
        customerViewToken = crypto.randomUUID()
        const { error: updateError } = await supabase
          .from('proposals')
          .update({ customer_view_token: customerViewToken })
          .eq('id', proposalId)

        if (updateError) {
          console.error('Error updating token:', updateError)
          return NextResponse.json(
            { error: 'Failed to generate token' },
            { status: 500 }
          )
        }
      }
    }

    // Log the email that would be sent
    const emailData = {
      to: customerEmail,
      subject: `Your Proposal #${proposalNumber} is Ready`,
      from: 'noreply@servicepro.com',
      customerName: customerName || 'Customer',
      message: message || 'Your proposal is ready for review.',
      viewLink: `${process.env.NEXT_PUBLIC_BASE_URL || 'https://my-dashboard-app-tau.vercel.app'}/proposal/view/${customerViewToken}`
    }

    console.log('Email would be sent with:', emailData)

    // Here you would integrate with your email service (SendGrid, Resend, etc.)
    // For now, we'll simulate success
    
    // Update proposal to mark as sent
    const { error: updateError } = await supabase
      .from('proposals')
      .update({ 
        status: 'sent',
        sent_at: new Date().toISOString()
      })
      .eq('id', proposalId)

    if (updateError) {
      console.error('Error updating proposal status:', updateError)
    }

    return NextResponse.json({ 
      success: true,
      token: customerViewToken,
      message: 'Proposal sent successfully',
      emailData: emailData // Return for debugging
    })

  } catch (error: any) {
    console.error('Error in send-proposal API:', error)
    return NextResponse.json(
      { error: error.message || 'Failed to send proposal' },
      { status: 500 }
    )
  }
}
