import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { Resend } from 'resend'
import { trackEmailSend } from '@/lib/email-tracking'

const resend = new Resend(process.env.RESEND_API_KEY)

export async function POST(request: Request) {
  try {
    const body = await request.json()
    const { proposalId, proposalNumber, email, customerName, message, total } = body

    if (!proposalId || !email || !proposalNumber) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    const supabase = await createClient()

    // Generate customer view token if it doesn't exist
    const { data: proposal } = await supabase
      .from('proposals')
      .select('customer_view_token')
      .eq('id', proposalId)
      .single()

    let token = proposal?.customer_view_token

    if (!token) {
      token = crypto.randomUUID()
      await supabase
        .from('proposals')
        .update({ 
          customer_view_token: token,
          sent_at: new Date().toISOString(),
          status: 'sent'
        })
        .eq('id', proposalId)
    } else {
      // Just update status to sent
      await supabase
        .from('proposals')
        .update({ 
          sent_at: new Date().toISOString(),
          status: 'sent'
        })
        .eq('id', proposalId)
    }

    const proposalUrl = `${process.env.NEXT_PUBLIC_BASE_URL || 'https://my-dashboard-app-tau.vercel.app'}/proposal/view/${token}`

    // Send email using Resend
    try {
      const { data: emailData, error: emailError } = await resend.emails.send({
        from: process.env.EMAIL_FROM || 'onboarding@resend.dev',
        to: email,
        replyTo: process.env.REPLY_TO_EMAIL || process.env.BUSINESS_EMAIL || 'dantcacenco@gmail.com',
        subject: `Your Proposal #${proposalNumber} is Ready`,
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2>Your Proposal is Ready</h2>
            <p>Hi ${customerName || 'Customer'},</p>
            <div style="white-space: pre-wrap;">${message || 'Please find attached your proposal for HVAC services.'}</div>
            <p style="margin-top: 20px;">
              <a href="${proposalUrl}" 
                 style="display: inline-block; background: #3b82f6; color: white; padding: 12px 24px; 
                        text-decoration: none; border-radius: 6px;">
                View Proposal
              </a>
            </p>
            <p style="color: #666; font-size: 14px; margin-top: 20px;">
              If the button doesn't work, copy and paste this link:<br>
              ${proposalUrl}
            </p>
          </div>
        `
      })

      if (emailError) {
        console.error('Email send error:', emailError)
        // Don't fail the whole request if email fails
      } else {
        // Track email send for limit monitoring
        await trackEmailSend()
      }
    } catch (emailErr) {
      console.error('Email service error:', emailErr)
      // Continue even if email fails
    }

    return NextResponse.json({ 
      success: true, 
      token,
      proposalUrl 
    })

  } catch (error: any) {
    console.error('Send proposal error:', error)
    return NextResponse.json(
      { error: error.message || 'Failed to send proposal' },
      { status: 500 }
    )
  }
}
