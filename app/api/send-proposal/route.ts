import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { Resend } from 'resend'
import { trackEmailSend } from '@/lib/email-tracking'
import { getProposalEmailTemplate, getCopyEmailTemplate } from '@/lib/email-templates'

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

    const proposalUrl = `${process.env.NEXT_PUBLIC_BASE_URL || 'https://fairairhc.service-pro.app'}/proposal/view/${token}`

    // Send email using Resend
    try {
      // Send to customer
      const { data: emailData, error: emailError } = await resend.emails.send({
        from: process.env.EMAIL_FROM || 'noreply@fairairhc.service-pro.app',
        to: email,
        replyTo: process.env.REPLY_TO_EMAIL || 'dantcacenco@gmail.com',
        subject: `Your Proposal #${proposalNumber} is Ready`,
        html: getProposalEmailTemplate({
          customerName,
          proposalNumber,
          message,
          proposalUrl,
          companyName: 'Fair Air HC'
        })
      })

      if (emailError) {
        console.error('Email send error:', emailError)
      } else {
        // Track email send for limit monitoring
        await trackEmailSend()
        
        // Send copy to business email
        if (process.env.BUSINESS_EMAIL) {
          await resend.emails.send({
            from: process.env.EMAIL_FROM || 'noreply@fairairhc.service-pro.app',
            to: process.env.BUSINESS_EMAIL,
            subject: `[COPY] Proposal #${proposalNumber} sent to ${customerName}`,
            html: getCopyEmailTemplate({
              proposalNumber,
              customerName: customerName || 'Customer',
              customerEmail: email,
              message,
              proposalUrl,
              companyName: 'Fair Air HC'
            })
          })
        }
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
