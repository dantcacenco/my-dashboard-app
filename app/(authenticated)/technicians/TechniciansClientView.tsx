'use client'

import React, { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Plus, Mail, Phone, UserCheck, RefreshCw } from 'lucide-react'
import AddTechnicianModal from './AddTechnicianModal'

interface Technician {
  id: string
  email: string
  full_name: string | null
  phone: string | null
  is_active?: boolean
  created_at: string
  role: string
}

export default function TechniciansClientView({ technicians }: { technicians: Technician[] }) {
  const [showAddModal, setShowAddModal] = useState(false)
  const router = useRouter()

  const handleRefresh = () => {
    router.refresh()
    window.location.reload()
  }

  const activeTechnicians = technicians.filter(t => t.is_active !== false)
  const inactiveTechnicians = technicians.filter(t => t.is_active === false)

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-3xl font-bold">Technicians</h1>
          <p className="text-muted-foreground">
            Total: {technicians.length} technicians in database
          </p>
        </div>
        <div className="flex gap-2">
          <Button
            variant="outline"
            onClick={handleRefresh}
          >
            <RefreshCw className="h-4 w-4 mr-2" />
            Force Refresh
          </Button>
          <Button onClick={() => setShowAddModal(true)}>
            <Plus className="h-4 w-4 mr-2" />
            Add Technician
          </Button>
        </div>
      </div>

      {/* Debug info */}
      {technicians.length > 0 && (
        <Card className="mb-6 bg-blue-50 border-blue-200">
          <CardContent className="p-4">
            <p className="text-sm">
              <strong>Debug Info:</strong> Found {technicians.length} total technicians
              ({activeTechnicians.length} active, {inactiveTechnicians.length} inactive)
            </p>
          </CardContent>
        </Card>
      )}

      {/* Active Technicians */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Active Technicians ({activeTechnicians.length})</CardTitle>
        </CardHeader>
        <CardContent>
          {activeTechnicians.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              <p>No active technicians found</p>
              <p className="text-sm mt-2">Click "Add Technician" to create one</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {activeTechnicians.map((tech) => (
                <Card key={tech.id} className="border">
                  <CardContent className="p-4">
                    <div className="flex justify-between items-start mb-3">
                      <div className="flex items-center gap-2">
                        <div className="h-10 w-10 rounded-full bg-blue-100 flex items-center justify-center">
                          <span className="text-blue-600 font-semibold">
                            {(tech.full_name || tech.email || 'T').charAt(0).toUpperCase()}
                          </span>
                        </div>
                        <div>
                          <div className="font-medium">
                            {tech.full_name || 'No name set'}
                          </div>
                          <Badge variant="outline" className="mt-1">
                            <UserCheck className="h-3 w-3 mr-1" />
                            Active
                          </Badge>
                        </div>
                      </div>
                    </div>
                    <div className="space-y-1 text-sm text-muted-foreground">
                      <div className="flex items-center gap-1">
                        <Mail className="h-3 w-3" />
                        {tech.email}
                      </div>
                      {tech.phone && (
                        <div className="flex items-center gap-1">
                          <Phone className="h-3 w-3" />
                          {tech.phone}
                        </div>
                      )}
                      <div className="text-xs text-gray-400 mt-2">
                        Created: {new Date(tech.created_at).toLocaleDateString()}
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Inactive Technicians */}
      {inactiveTechnicians.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Inactive Technicians ({inactiveTechnicians.length})</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {inactiveTechnicians.map((tech) => (
                <Card key={tech.id} className="border opacity-60">
                  <CardContent className="p-4">
                    <div className="flex items-center gap-2">
                      <div className="h-10 w-10 rounded-full bg-gray-100 flex items-center justify-center">
                        <span className="text-gray-600 font-semibold">
                          {(tech.full_name || tech.email || 'T').charAt(0).toUpperCase()}
                        </span>
                      </div>
                      <div>
                        <div className="font-medium">
                          {tech.full_name || 'No name set'}
                        </div>
                        <Badge variant="destructive" className="mt-1">
                          Inactive
                        </Badge>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Raw data display for debugging */}
      <details className="mt-6">
        <summary className="cursor-pointer text-sm text-gray-600 hover:text-gray-900">
          Show raw data (for debugging)
        </summary>
        <pre className="mt-2 p-4 bg-gray-100 rounded text-xs overflow-auto">
          {JSON.stringify(technicians, null, 2)}
        </pre>
      </details>

      {showAddModal && (
        <AddTechnicianModal
          onClose={() => setShowAddModal(false)}
          onSuccess={() => {
            setShowAddModal(false)
            handleRefresh()
          }}
        />
      )}
    </div>
  )
}
