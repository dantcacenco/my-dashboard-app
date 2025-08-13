'use client'

import { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Plus, Edit, UserCheck, UserX, Phone, Mail } from 'lucide-react'
import AddTechnicianModal from './AddTechnicianModal'

interface Technician {
  id: string
  email: string
  full_name: string | null
  phone: string | null
  is_active?: boolean
  created_at: string
}

export default function TechniciansView({ technicians }: { technicians: Technician[] }) {
  const [showAddModal, setShowAddModal] = useState(false)
  const [selectedTechnician, setSelectedTechnician] = useState<Technician | null>(null)

  const activeTechnicians = technicians.filter(t => t.is_active !== false)
  const inactiveTechnicians = technicians.filter(t => t.is_active === false)

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-3xl font-bold">Technicians</h1>
          <p className="text-muted-foreground">Manage your field technicians</p>
        </div>
        <Button onClick={() => setShowAddModal(true)}>
          <Plus className="h-4 w-4 mr-2" />
          Add Technician
        </Button>
      </div>

      {/* Active Technicians */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Active Technicians ({activeTechnicians.length})</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {activeTechnicians.map((tech) => (
              <Card key={tech.id} className="border">
                <CardContent className="p-4">
                  <div className="flex justify-between items-start mb-3">
                    <div className="flex items-center gap-2">
                      <div className="h-10 w-10 rounded-full bg-blue-100 flex items-center justify-center">
                        <span className="text-blue-600 font-semibold">
                          {tech.full_name?.charAt(0) || tech.email.charAt(0).toUpperCase()}
                        </span>
                      </div>
                      <div>
                        <div className="font-medium">{tech.full_name || 'No name'}</div>
                        <Badge variant="outline" className="mt-1">
                          <UserCheck className="h-3 w-3 mr-1" />
                          Active
                        </Badge>
                      </div>
                    </div>
                    <Button
                      size="sm"
                      variant="ghost"
                      onClick={() => setSelectedTechnician(tech)}
                    >
                      <Edit className="h-4 w-4" />
                    </Button>
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
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
          {activeTechnicians.length === 0 && (
            <div className="text-center py-8 text-muted-foreground">
              No active technicians
            </div>
          )}
        </CardContent>
      </Card>

      {/* Inactive Technicians */}
      {inactiveTechnicians.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Inactive Technicians</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {inactiveTechnicians.map((tech) => (
                <Card key={tech.id} className="border opacity-60">
                  <CardContent className="p-4">
                    <div className="flex items-center gap-2">
                      <div className="h-10 w-10 rounded-full bg-gray-100 flex items-center justify-center">
                        <span className="text-gray-600 font-semibold">
                          {tech.full_name?.charAt(0) || tech.email.charAt(0).toUpperCase()}
                        </span>
                      </div>
                      <div>
                        <div className="font-medium">{tech.full_name || 'No name'}</div>
                        <Badge variant="destructive" className="mt-1">
                          <UserX className="h-3 w-3 mr-1" />
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

      {showAddModal && (
        <AddTechnicianModal
          onClose={() => setShowAddModal(false)}
          onSuccess={() => {
            setShowAddModal(false)
            window.location.reload()
          }}
        />
      )}
    </div>
  )
}
