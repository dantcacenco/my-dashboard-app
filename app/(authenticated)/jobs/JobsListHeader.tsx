'use client'

import { useRouter } from 'next/navigation'
import { Plus } from 'lucide-react'

interface JobsListHeaderProps {
  userRole?: string
}

export default function JobsListHeader({ userRole = 'technician' }: JobsListHeaderProps) {
  const router = useRouter()

  return (
    <div className="flex justify-between items-center mb-6">
      <h1 className="text-2xl font-bold">
        {userRole === 'technician' ? 'My Assigned Jobs' : 'Jobs'}
      </h1>
      {userRole !== 'technician' && (
        <button
          onClick={() => router.push('/jobs/new')}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 flex items-center gap-2"
        >
          <Plus className="h-4 w-4" />
          New Job
        </button>
      )}
    </div>
  )
}
