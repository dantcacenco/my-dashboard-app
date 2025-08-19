'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { BriefcaseIcon } from '@heroicons/react/24/outline'

interface CreateJobButtonProps {
  proposalId: string
  customerId: string
  proposalNumber: string
  customerName?: string
  serviceAddress?: string
}

export default function CreateJobButton({ 
  proposalId, 
  customerId, 
  proposalNumber, 
  customerName,
  serviceAddress 
}: CreateJobButtonProps) {
  const [isLoading, setIsLoading] = useState(false)
  const router = useRouter()
  const supabase = createClient()

  const handleCreateJob = async () => {
    if (!confirm('Create a job from this proposal?')) return
    
    setIsLoading(true)
    try {
      // Get user info
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) throw new Error('Not authenticated')

      // Generate job number
      const today = new Date()
      const dateStr = today.toISOString().split('T')[0].replace(/-/g, '')
      const randomNum = Math.floor(Math.random() * 1000).toString().padStart(3, '0')
      const jobNumber = `JOB-${dateStr}-${randomNum}`

      // Create the job
      const { data: newJob, error: jobError } = await supabase
        .from('jobs')
        .insert({
          job_number: jobNumber,
          customer_id: customerId,
          proposal_id: proposalId,
          title: `Service from Proposal ${proposalNumber}`,
          description: `Job created from proposal ${proposalNumber}`,
          job_type: 'installation',
          status: 'not_scheduled',
          service_address: serviceAddress || '',
          created_by: user.id
        })
        .select()
        .single()

      if (jobError) throw jobError

      // Mark proposal as job created
      await supabase
        .from('proposals')
        .update({ job_created: true })
        .eq('id', proposalId)

      // Redirect to the new job
      router.push(`/jobs/${newJob.id}`)
    } catch (error) {
      console.error('Error creating job:', error)
      alert('Failed to create job. Please try again.')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <button
      onClick={handleCreateJob}
      disabled={isLoading}
      className="inline-flex items-center px-4 py-2 bg-black text-white rounded-md hover:bg-gray-800 disabled:opacity-50"
    >
      <BriefcaseIcon className="w-4 h-4 mr-2" />
      {isLoading ? 'Creating...' : 'Create Job'}
    </button>
  )
}
