'use client'

import { Button } from '@/components/ui/button'
import { Briefcase, Loader2 } from 'lucide-react'
import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { toast } from 'sonner'

interface CreateJobButtonProps {
  proposalId: string
  proposalStatus: string
  userRole: string
  hasExistingJob: boolean
}

export default function CreateJobButton({ 
  proposalId, 
  proposalStatus, 
  userRole, 
  hasExistingJob 
}: CreateJobButtonProps) {
  const [isCreating, setIsCreating] = useState(false)
  const router = useRouter()

  // Only show for boss/admin on approved proposals without existing job
  if (userRole !== 'boss' && userRole !== 'admin') return null
  if (proposalStatus !== 'approved') return null
  if (hasExistingJob) return null

  const handleCreateJob = async () => {
    setIsCreating(true)
    try {
      const response = await fetch('/api/jobs/create-from-proposal', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ proposalId })
      })

      const data = await response.json()

      if (!response.ok) {
        if (data.jobId) {
          // Job already exists, navigate to it
          router.push(`/jobs/${data.jobId}`)
        } else {
          throw new Error(data.error || 'Failed to create job')
        }
        return
      }

      toast.success(`Job ${data.jobNumber} created successfully!`)
      router.push(`/jobs/${data.jobId}`)
    } catch (error: any) {
      toast.error(error.message || 'Failed to create job')
      setIsCreating(false)
    }
  }

  return (
    <Button
      onClick={handleCreateJob}
      disabled={isCreating}
      className="bg-green-600 hover:bg-green-700"
    >
      {isCreating ? (
        <>
          <Loader2 className="h-4 w-4 mr-2 animate-spin" />
          Creating Job...
        </>
      ) : (
        <>
          <Briefcase className="h-4 w-4 mr-2" />
          Create Job
        </>
      )}
    </Button>
  )
}
