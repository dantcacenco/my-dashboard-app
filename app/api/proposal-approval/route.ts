import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'
import { Resend } from 'resend'
import { getApprovalEmailTemplate } from '@/lib/email-templates'

const resend = new Resend(process.env.RESEND_API_KEY)

export async function POST(request: Request) {
  try {
    const supabase = await createClient()
    const { proposalId, action, rejectionReason, approvedBy } = await request.json()

    console.log('Proposal approval request:', { proposalId, action })

    if (!proposalId || !action) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    // Get proposal details
    const { data: proposal, error: proposalError } = await supabase
      .from('proposals')
      .select('*, customers(*)')
      .eq('id', proposalId)
      .single()

    if (proposalError || !proposal) {
      console.error('Error fetching proposal:', proposalError)
      return NextResponse.json(
        { error: 'Proposal not found', details: proposalError?.message },
        { status: 404 }
      )
    }

    // Update proposal status
    const updateData: any = {}
    const now = new Date().toISOString()

    if (action === 'approve') {
      updateData.status = 'approved'
      updateData.approved_at = now
      updateData.payment_status = 'pending'
      updateData.current_payment_stage = 'deposit'
    } else if (action === 'reject') {
      updateData.status = 'rejected'
      updateData.rejected_at = now
      updateData.customer_notes = rejectionReason || ''
    }

    const { error: updateError } = await supabase
      .from('proposals')
      .update(updateData)
      .eq('id', proposalId)

    if (updateError) {
      console.error('Error updating proposal:', updateError)
      return NextResponse.json(
        { error: 'Failed to update proposal', details: updateError.message },
        { status: 500 }
      )
    }

    // If approved, create payment stages and send notification
    if (action === 'approve') {
      // Calculate payment amounts
      const depositAmount = proposal.total * 0.5
      const progressAmount = proposal.total * 0.3
      const finalAmount = proposal.total * 0.2

      // Create payment stages
      const stages = [
        {
          proposal_id: proposalId,
          stage: 'deposit',
          percentage: 50,
          amount: depositAmount,
          due_date: new Date().toISOString().split('T')[0],
          paid: false
        },
        {
          proposal_id: proposalId,
          stage: 'progress',
          percentage: 30,
          amount: progressAmount,
          due_date: null,
          paid: false
        },
        {
          proposal_id: proposalId,
          stage: 'final',
          percentage: 20,
          amount: finalAmount,
          due_date: null,
          paid: false
        }
      ]

      const { error: stagesError } = await supabase
        .from('payment_stages')
        .insert(stages)

      if (stagesError) {
        console.error('Error creating payment stages:', stagesError)
        // Continue anyway - stages can be created manually
      }

      // Send approval notification email to business
      if (process.env.BUSINESS_EMAIL) {
        const proposalUrl = `${process.env.NEXT_PUBLIC_BASE_URL || 'https://fairairhc.service-pro.app'}/proposals/${proposalId}`
        
        try {
          await resend.emails.send({
            from: process.env.EMAIL_FROM || 'noreply@fairairhc.service-pro.app',
            to: process.env.BUSINESS_EMAIL,
            replyTo: proposal.customers?.email || process.env.REPLY_TO_EMAIL || 'dantcacenco@gmail.com',
            subject: `🎉 Proposal #${proposal.proposal_number} APPROVED by ${proposal.customers?.name || 'Customer'}`,
            html: getApprovalEmailTemplate({
              proposalNumber: proposal.proposal_number,
              customerName: proposal.customers?.name || 'Customer',
              customerEmail: proposal.customers?.email || 'No email',
              customerPhone: proposal.customers?.phone,
              totalAmount: `$${proposal.total.toFixed(2)}`,
              approvedBy: approvedBy || proposal.customers?.name || 'Customer',
              proposalUrl,
              companyName: 'Fair Air HC'
            })
          })
        } catch (emailError) {
          console.error('Failed to send approval notification:', emailError)
          // Don't fail the approval if email fails
        }
      }

      // Log activity
      await supabase
        .from('proposal_activities')
        .insert({
          proposal_id: proposalId,
          activity_type: 'approved',
          description: `Proposal approved by customer`,
          metadata: { payment_stages_created: !stagesError }
        })
    }

    // Return appropriate response for mobile
    return NextResponse.json({
      success: true,
      action: action,
      proposalId: proposalId,
      message: action === 'approve' 
        ? 'Proposal approved successfully. Payment stages created.'
        : 'Proposal rejected.',
      redirectUrl: action === 'approve' 
        ? `/customer-proposal/${proposal.customer_view_token}/payment`
        : `/customer-proposal/${proposal.customer_view_token}`
    })

  } catch (error) {
    console.error('Error in proposal approval:', error)
    return NextResponse.json(
      { 
        error: 'Internal server error', 
        details: error instanceof Error ? error.message : 'Unknown error',
        // Provide mobile-friendly error message
        mobileMessage: 'Something went wrong. Please try again or contact support.'
      },
      { status: 500 }
    )
  }
}