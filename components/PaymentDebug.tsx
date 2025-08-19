'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'

interface PaymentDebugProps {
  proposalId: string
}

export default function PaymentDebug({ proposalId }: PaymentDebugProps) {
  const [debugInfo, setDebugInfo] = useState<any>(null)
  const [showDebug, setShowDebug] = useState(false)
  const supabase = createClient()

  useEffect(() => {
    // Check if debug mode is enabled in URL
    const params = new URLSearchParams(window.location.search)
    if (params.get('debug') === 'true') {
      setShowDebug(true)
      fetchDebugInfo()
    }
  }, [])

  const fetchDebugInfo = async () => {
    const { data: proposal } = await supabase
      .from('proposals')
      .select('*')
      .eq('id', proposalId)
      .single()

    const { data: stages } = await supabase
      .from('payment_stages')
      .select('*')
      .eq('proposal_id', proposalId)
      .order('stage')

    const { data: payments } = await supabase
      .from('payments')
      .select('*')
      .eq('proposal_id', proposalId)
      .order('created_at', { ascending: false })

    setDebugInfo({
      proposal,
      stages,
      payments
    })
  }

  if (!showDebug || !debugInfo) return null

  return (
    <div className="fixed bottom-4 right-4 w-96 max-h-96 overflow-auto bg-black text-green-400 p-4 rounded-lg font-mono text-xs">
      <div className="mb-2 font-bold">🐛 PAYMENT DEBUG</div>
      
      <div className="mb-2">
        <div className="font-bold">Proposal Status:</div>
        <div>Payment Status: {debugInfo.proposal?.payment_status}</div>
        <div>Current Stage: {debugInfo.proposal?.current_payment_stage}</div>
        <div>Total: ${debugInfo.proposal?.total}</div>
        <div>Total Paid: ${debugInfo.proposal?.total_paid || 0}</div>
      </div>

      <div className="mb-2">
        <div className="font-bold">Payment Stages:</div>
        {debugInfo.stages?.map((stage: any) => (
          <div key={stage.id} className="ml-2">
            {stage.stage}: ${stage.amount} - {stage.paid ? '✅ PAID' : '❌ UNPAID'}
            {stage.paid_at && <div className="ml-4 text-xs">Paid: {new Date(stage.paid_at).toLocaleString()}</div>}
          </div>
        ))}
      </div>

      <div className="mb-2">
        <div className="font-bold">Payment Records:</div>
        {debugInfo.payments?.map((payment: any) => (
          <div key={payment.id} className="ml-2 mb-1">
            ${payment.amount} - {payment.payment_stage} - {payment.status}
            <div className="ml-4 text-xs">{new Date(payment.created_at).toLocaleString()}</div>
          </div>
        ))}
      </div>

      <button 
        onClick={fetchDebugInfo}
        className="mt-2 px-2 py-1 bg-green-400 text-black rounded text-xs"
      >
        Refresh Debug Info
      </button>
    </div>
  )
}
