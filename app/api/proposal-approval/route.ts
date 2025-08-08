import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function POST(request: NextRequest) {
  try {
    const { proposalId, approved, customerNotes } = await request.json()

    if (!proposalId) {
      return NextResponse.json(
        { error: 'Proposal ID is required' },
        { status: 400 }
      )
    }

    const supabase = await createClient()
    const now = new Date().toISOString()

    const updateData: any = {
      status: approved ? 'approved' : 'rejected',
      customer_notes: customerNotes || null
    }

    if (approved) {
      updateData.approved_at = now
    } else {
      updateData.rejected_at = now
    }

    const { data: proposal, error } = await supabase
      .from('proposals')
      .update(updateData)
      .eq('id', proposalId)
      .select(`
        *,
        customers (
          id,
          name,
          email,
          phone
        )
      `)
      .single()

    if (error) {
      console.error('Error updating proposal:', error)
      return NextResponse.json(
        { error: 'Failed to update proposal' },
        { status: 500 }
      )
    }

    return NextResponse.json({ 
      success: true,
      proposal 
    })

  } catch (error: any) {
    console.error('Error in proposal approval:', error)
    return NextResponse.json(
      { error: error.message || 'Failed to process approval' },
      { status: 500 }
    )
  }
}
