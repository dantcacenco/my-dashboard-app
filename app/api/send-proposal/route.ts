import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function POST(request: Request) {
  try {
    const { proposalId, email, emailContent } = await request.json()

    if (!proposalId || !email) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    const supabase = await createClient()

    const { data: proposal, error: fetchError } = await supabase
      .from('proposals')
      .select('id, proposal_number, customer_view_token, status')
      .eq('id', proposalId)
      .single()

    if (fetchError || !proposal) {
      console.error('Error fetching proposal:', fetchError)
      return NextResponse.json(
        { error: 'Proposal not found' },
        { status: 404 }
      )
    }

    let token = proposal.customer_view_token
    if (!token) {
      token = Math.random().toString(36).substring(2) + Date.now().toString(36)
      
      const { error: updateError } = await supabase
        .from('proposals')
        .update({ 
          customer_view_token: token,
          status: 'sent'
        })
        .eq('id', proposalId)

      if (updateError) {
        console.error('Error updating proposal:', updateError)
        return NextResponse.json(
          { error: 'Failed to update proposal' },
          { status: 500 }
        )
      }
    } else {
      await supabase
        .from('proposals')
        .update({ status: 'sent' })
        .eq('id', proposalId)
    }

    console.log('=== SENDING PROPOSAL EMAIL ===')
    console.log(`Proposal: ${proposal.proposal_number}`)
    console.log(`To: ${email}`)
    console.log(`Token: ${token}`)
    console.log('Email Content:')
    console.log(emailContent)
    console.log('==============================')

    return NextResponse.json({
      success: true,
      token: token,
      message: 'Proposal sent successfully'
    })

  } catch (error) {
    console.error('Error in send-proposal API:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
