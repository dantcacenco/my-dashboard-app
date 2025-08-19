'use client'

import React, { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Plus, Mail, Phone, UserCheck, UserX, RefreshCw, Edit2, Trash2 } from 'lucide-react'
import AddTechnicianModal from './AddTechnicianModal'
import EditTechnicianModal from './EditTechnicianModal'
import { toast } from 'sonner'
import { createClient } from '@/lib/supabase/client'

interface Technician {
  id: string
  email: string
  full_name: string | null
  phone: string | null
  is_active?: boolean
  created_at: string
  role: string
}

export default function TechniciansClientView({ technicians: initialTechnicians }: { technicians: Technician[] }) {
  const [technicians, setTechnicians] = useState(initialTechnicians)
  const [showAddModal, setShowAddModal] = useState(false)
  const [editingTechnician, setEditingTechnician] = useState<Technician | null>(null)
  const [isRefreshing, setIsRefreshing] = useState(false)
  const router = useRouter()
  const supabase = createClient()

  const handleRefresh = async () => {
    setIsRefreshing(true)
    try {
      const { data } = await supabase
        .from('profiles')
        .select('*')
        .eq('role', 'technician')
        .order('created_at', { ascending: false })
      
      if (data) {
        setTechnicians(data)
        toast.success('Technicians list refreshed')
      }
    } catch (error) {
      toast.error('Failed to refresh technicians')
    } finally {
      setIsRefreshing(false)
    }
  }



  const handleDelete = async (techId: string, email: string) => {
    if (!confirm(`Are you sure you want to permanently delete ${email}? This cannot be undone.`)) {
      return
    }

    try {
      const response = await fetch(`/api/technicians/${techId}`, {
        method: 'DELETE'
      })

      if (!response.ok) {
        throw new Error('Failed to delete technician')
      }

      toast.success('Technician deleted successfully')
      setTechnicians(technicians.filter(t => t.id !== techId))
    } catch (error) {
      toast.error('Failed to delete technician')
    }
  }

  const activeTechnicians = technicians.filter(t => t.is_active !== false)
  const inactiveTechnicians = technicians.filter(t => t.is_active === false)

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-3xl font-bold">Technicians</h1>
          <p className="text-muted-foreground">
            Manage your field technicians
          </p>
        </div>
        <div className="flex gap-2">
          <Button
            variant="outline"
            size="icon"
            onClick={handleRefresh}
            disabled={isRefreshing}
          >
            <RefreshCw className={`h-4 w-4 ${isRefreshing ? 'animate-spin' : ''}`} />
          </Button>
          <Button onClick={() => setShowAddModal(true)}>
            <Plus className="h-4 w-4 mr-2" />
            Add Technician
          </Button>
        </div>
      </div>

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
                    <div className="flex justify-between items-start mb-2">
                      <div className="flex items-center">
                        <UserCheck className="h-4 w-4 text-green-500 mr-2" />
                        <Badge variant="outline" className="text-xs">Active</Badge>
                      </div>
                      <div className="flex gap-1">
                        <button
                          onClick={() => setEditingTechnician(tech)}
                          className="text-gray-500 hover:text-gray-700"
                        >
                          <Edit2 className="h-4 w-4" />
                        </button>
                        <button
                          onClick={() => handleDelete(tech.id, tech.email)}
                          className="text-red-500 hover:text-red-700"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </div>
                    </div>
                    <h3 className="font-medium text-gray-900">
                      {tech.full_name || 'No name set'}
                    </h3>
                    <div className="mt-2 space-y-1">
                      <div className="flex items-center text-sm text-gray-600">
                        <Mail className="h-3 w-3 mr-2" />
                        {tech.email}
                      </div>
                      {tech.phone && (
                        <div className="flex items-center text-sm text-gray-600">
                          <Phone className="h-3 w-3 mr-2" />
                          {tech.phone}
                        </div>
                      )}
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
                <Card key={tech.id} className="border opacity-75">
                  <CardContent className="p-4">
                    <div className="flex justify-between items-start mb-2">
                      <div className="flex items-center">
                        <UserX className="h-4 w-4 text-gray-400 mr-2" />
                        <Badge variant="secondary" className="text-xs">Inactive</Badge>
                      </div>
                      <div className="flex gap-1">
                        <button
                          onClick={() => setEditingTechnician(tech)}
                          className="text-gray-500 hover:text-gray-700"
                        >
                          <Edit2 className="h-4 w-4" />
                        </button>
                        <button
                          onClick={() => handleDelete(tech.id, tech.email)}
                          className="text-red-500 hover:text-red-700"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </div>
                    </div>
                    <h3 className="font-medium text-gray-700">
                      {tech.full_name || 'No name set'}
                    </h3>
                    <div className="mt-2 space-y-1">
                      <div className="flex items-center text-sm text-gray-500">
                        <Mail className="h-3 w-3 mr-2" />
                        {tech.email}
                      </div>
                      {tech.phone && (
                        <div className="flex items-center text-sm text-gray-500">
                          <Phone className="h-3 w-3 mr-2" />
                          {tech.phone}
                        </div>
                      )}
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
          onSuccess={() => handleRefresh()}
        />
      )}

      {editingTechnician && (
        <EditTechnicianModal
          technician={editingTechnician}
          onClose={() => setEditingTechnician(null)}
          onSuccess={() => handleRefresh()}
        />
      )}
    </div>
  )
}
