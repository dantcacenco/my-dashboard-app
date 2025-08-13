'use client'

import { Button } from '@/components/ui/button'
import { Wrench, Loader2 } from 'lucide-react'
import { useState } from 'react'
import { toast } from 'sonner'
import { useRouter } from 'next/navigation'

export default function FixOrphanedButton() {
  const [isFixing, setIsFixing] = useState(false)
  const router = useRouter()

  const handleFix = async () => {
    setIsFixing(true)
    try {
      const response = await fetch('/api/technicians/fix-orphaned', {
        method: 'POST'
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Failed to fix orphaned users')
      }

      if (data.fixedUsers.length > 0) {
        toast.success(`Fixed ${data.fixedUsers.length} orphaned technician(s)`)
        router.refresh()
      } else {
        toast.info('No orphaned technicians found')
      }

      console.log('Fix results:', data)
    } catch (error: any) {
      toast.error(error.message || 'Failed to fix orphaned users')
    } finally {
      setIsFixing(false)
    }
  }

  return (
    <Button
      variant="outline"
      size="sm"
      onClick={handleFix}
      disabled={isFixing}
    >
      {isFixing ? (
        <>
          <Loader2 className="h-4 w-4 mr-2 animate-spin" />
          Fixing...
        </>
      ) : (
        <>
          <Wrench className="h-4 w-4 mr-2" />
          Fix Missing Profiles
        </>
      )}
    </Button>
  )
}
