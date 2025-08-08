import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function POST(request: Request) {
  try {
    const { proposalId, email } = await request.json()

    if (!proposalId || !email) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    const supabase = await createClient()

    // Check if proposal exists
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

    // Generate token if it doesn't exist
    let token = proposal.customer_view_token
    if (!token) {
      // Generate a random token
      token = Math.random().toString(36).substring(2) + Date.now().toString(36)
      
      // Update proposal with token
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
      // Just update status to sent
      await supabase
        .from('proposals')
        .update({ status: 'sent' })
        .eq('id', proposalId)
    }

    // Here you would normally send an email
    // For now, we'll just return success
    console.log(`Proposal ${proposal.proposal_number} sent to ${email}`)
    console.log(`View link: ${process.env.NEXT_PUBLIC_BASE_URL || 'http://localhost:3000'}/proposal/view/${token}`)

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
