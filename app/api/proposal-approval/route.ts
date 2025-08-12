import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { proposalId, action, reason, token } = body

    const supabase = await createClient()

    // Verify the proposal and token
    const { data: proposal, error: proposalError } = await supabase
      .from('proposals')
      .select(`
        *,
        customers (*)
      `)
      .eq('id', proposalId)
      .eq('customer_view_token', token)
      .single()

    if (proposalError || !proposal) {
      return NextResponse.json(
        { error: 'Invalid proposal or token' },
        { status: 404 }
      )
    }

    // Update proposal based on action
    if (action === 'approve') {
      // Update proposal status
      const { error: updateError } = await supabase
        .from('proposals')
        .update({
          status: 'approved',
          approved_at: new Date().toISOString()
        })
        .eq('id', proposalId)

      if (updateError) {
        return NextResponse.json(
          { error: 'Failed to approve proposal' },
          { status: 500 }
        )
      }

      // Auto-create job
      const today = new Date()
      const dateStr = today.toISOString().slice(0, 10).replace(/-/g, '')
      const { count } = await supabase
        .from('jobs')
        .select('*', { count: 'exact', head: true })
        .ilike('job_number', `JOB-${dateStr}-%`)

      const jobNumber = `JOB-${dateStr}-${String((count || 0) + 1).padStart(3, '0')}`

      // Create job
      const { data: job, error: jobError } = await supabase
        .from('jobs')
        .insert({
          job_number: jobNumber,
          customer_id: proposal.customer_id,
          customer_name: proposal.customers?.name || 'Unknown',
          customer_email: proposal.customers?.email,
          customer_phone: proposal.customers?.phone,
          service_address: proposal.customers?.address || '',
          total_value: proposal.total,
          status: 'pending',
          notes: `Auto-created from approved Proposal #${proposal.proposal_number}`,
          created_by: proposal.created_by
        })
        .select()
        .single()

      if (!jobError && job) {
        // Link job to proposal
        await supabase
          .from('job_proposals')
          .insert({
            job_id: job.id,
            proposal_id: proposalId,
            attached_by: proposal.created_by
          })

        // Update proposal with job_id
        await supabase
          .from('proposals')
          .update({ job_id: job.id })
          .eq('id', proposalId)

        // Send email notifications (implement with your email service)
        // TODO: Send email to boss
        // TODO: Send confirmation to customer
      }

      // Log activity
      await supabase
        .from('proposal_activities')
        .insert({
          proposal_id: proposalId,
          activity_type: 'approved',
          description: 'Proposal approved by customer',
          metadata: { job_id: job?.id }
        })

    } else if (action === 'reject') {
      // Update proposal status
      const { error: updateError } = await supabase
        .from('proposals')
        .update({
          status: 'rejected',
          rejected_at: new Date().toISOString(),
          customer_notes: reason
        })
        .eq('id', proposalId)

      if (updateError) {
        return NextResponse.json(
          { error: 'Failed to reject proposal' },
          { status: 500 }
        )
      }

      // Log activity
      await supabase
        .from('proposal_activities')
        .insert({
          proposal_id: proposalId,
          activity_type: 'rejected',
          description: 'Proposal rejected by customer',
          metadata: { reason }
        })
    }

    return NextResponse.json({ success: true })
  } catch (error: any) {
    console.error('Proposal approval error:', error)
    return NextResponse.json(
      { error: error.message || 'Failed to process approval' },
      { status: 500 }
    )
  }
}
