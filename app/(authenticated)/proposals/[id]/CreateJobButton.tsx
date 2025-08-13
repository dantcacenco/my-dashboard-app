'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Briefcase } from 'lucide-react'
import CreateJobModal from './CreateJobModal'

interface CreateJobButtonProps {
  proposal: any
  userRole: string
}

export default function CreateJobButton({ proposal, userRole }: CreateJobButtonProps) {
  const [showModal, setShowModal] = useState(false)

  // Only show for boss/admin on approved proposals
  if (userRole !== 'boss' && userRole !== 'admin') return null
  if (proposal.status !== 'approved') return null

  return (
    <>
      <Button
        onClick={() => setShowModal(true)}
        className="bg-green-600 hover:bg-green-700"
      >
        <Briefcase className="h-4 w-4 mr-2" />
        Create Job
      </Button>

      {showModal && (
        <CreateJobModal
          proposal={proposal}
          onClose={() => setShowModal(false)}
        />
      )}
    </>
  )
}
