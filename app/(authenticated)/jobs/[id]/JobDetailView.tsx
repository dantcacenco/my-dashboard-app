'use client'

import { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { 
  ArrowLeft, Edit, MapPin, Phone, Mail, Calendar, 
  User, Plus, Upload, Camera
} from 'lucide-react'
import Link from 'next/link'
import { toast } from 'sonner'

interface JobDetailViewProps {
  job: any
  userRole: string
  availableTechnicians: any[]
}

export default function JobDetailView({ job, userRole, availableTechnicians }: JobDetailViewProps) {
  const [assignedTechs, setAssignedTechs] = useState<string[]>([])
  const [isAssigning, setIsAssigning] = useState(false)

  const handleAssignTechnician = async (techId: string) => {
    if (assignedTechs.includes(techId)) {
      toast.info('Technician already assigned')
      return
    }

    setIsAssigning(true)
    setAssignedTechs([...assignedTechs, techId])
    toast.success('Technician assigned successfully')
    setIsAssigning(false)
  }

  // Simple function to determine badge variant - TypeScript safe
  const getBadgeVariant = (status: string) => {
    if (status === 'completed') return 'default' as const
    if (status === 'in_progress') return 'secondary' as const
    if (status === 'cancelled') return 'destructive' as const
    return 'outline' as const
  }

  const copyAddress = () => {
    const address = `${job.service_address || ''}${job.service_city ? `, ${job.service_city}` : ''}${job.service_state ? `, ${job.service_state}` : ''} ${job.service_zip || ''}`
    navigator.clipboard.writeText(address.trim())
    toast.success('Address copied to clipboard')
  }

  return (
    <div className="p-6">
      {/* Header */}
      <div className="flex items-center gap-4 mb-6">
        <Link href="/jobs">
          <Button variant="ghost" size="icon">
            <ArrowLeft className="h-5 w-5" />
          </Button>
        </Link>
        <div className="flex-1">
          <h1 className="text-3xl font-bold">{job.job_number}</h1>
          <p className="text-muted-foreground">{job.title || 'Untitled Job'}</p>
        </div>
        {(userRole === 'boss' || userRole === 'admin') && (
          <Button>
            <Edit className="h-4 w-4 mr-2" />
            Edit Job
          </Button>
        )}
      </div>

      {/* Main Info Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        {/* Customer Info */}
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-sm font-medium">Customer</CardTitle>
          </CardHeader>
          <CardContent>
            {job.customers ? (
              <div className="space-y-2">
                <div className="font-medium">{job.customers.name}</div>
                {job.customers.email && (
                  <div className="flex items-center gap-1 text-sm text-muted-foreground">
                    <Mail className="h-3 w-3" />
                    {job.customers.email}
                  </div>
                )}
                {job.customers.phone && (
                  <div className="flex items-center gap-1 text-sm text-muted-foreground">
                    <Phone className="h-3 w-3" />
                    {job.customers.phone}
                  </div>
                )}
              </div>
            ) : (
              <span className="text-muted-foreground">No customer info</span>
            )}
          </CardContent>
        </Card>

        {/* Job Info */}
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-sm font-medium">Job Details</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">Type:</span>
                <span className="text-sm font-medium capitalize">{job.job_type || 'Not set'}</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">Status:</span>
                <Badge variant={getBadgeVariant(job.status || 'scheduled')}>
                  {(job.status || 'scheduled').replace('_', ' ')}
                </Badge>
              </div>
              {job.scheduled_date && (
                <div className="flex items-center gap-1 text-sm">
                  <Calendar className="h-3 w-3 text-muted-foreground" />
                  {new Date(job.scheduled_date).toLocaleDateString()}
                  {job.scheduled_time && ` at ${job.scheduled_time}`}
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Service Location */}
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-sm font-medium">Service Location</CardTitle>
          </CardHeader>
          <CardContent>
            {job.service_address ? (
              <div className="space-y-1">
                <div className="flex items-start gap-1">
                  <MapPin className="h-3 w-3 text-muted-foreground mt-1" />
                  <div className="text-sm">
                    <div>{job.service_address}</div>
                    {(job.service_city || job.service_state || job.service_zip) && (
                      <div>
                        {job.service_city && `${job.service_city}, `}
                        {job.service_state} {job.service_zip}
                      </div>
                    )}
                  </div>
                </div>
                <Button 
                  variant="outline" 
                  size="sm" 
                  className="w-full mt-2"
                  onClick={copyAddress}
                >
                  Copy Address
                </Button>
              </div>
            ) : (
              <span className="text-muted-foreground text-sm">No address set</span>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Tabs Section */}
      <Tabs defaultValue="overview" className="w-full">
        <TabsList>
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="technicians">Technicians</TabsTrigger>
          <TabsTrigger value="files">Files</TabsTrigger>
          <TabsTrigger value="photos">Photos</TabsTrigger>
          <TabsTrigger value="notes">Notes</TabsTrigger>
        </TabsList>

        {/* Overview Tab */}
        <TabsContent value="overview" className="mt-4">
          <Card>
            <CardHeader>
              <CardTitle>Job Overview</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div>
                  <h3 className="font-medium mb-2">Description</h3>
                  <p className="text-sm text-muted-foreground">
                    {job.description || 'No description provided'}
                  </p>
                </div>
                {job.notes && (
                  <div>
                    <h3 className="font-medium mb-2">Notes</h3>
                    <p className="text-sm text-muted-foreground">{job.notes}</p>
                  </div>
                )}
                {job.proposals && (
                  <div>
                    <h3 className="font-medium mb-2">Related Proposal</h3>
                    <div className="flex items-center justify-between p-3 border rounded">
                      <div>
                        <div className="font-medium">{job.proposals.proposal_number}</div>
                        <div className="text-sm text-muted-foreground">{job.proposals.title}</div>
                      </div>
                      <Link href={`/proposals/${job.proposal_id}`}>
                        <Button variant="outline" size="sm">View</Button>
                      </Link>
                    </div>
                  </div>
                )}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Technicians Tab */}
        <TabsContent value="technicians" className="mt-4">
          <Card>
            <CardHeader>
              <CardTitle>Assigned Technicians</CardTitle>
            </CardHeader>
            <CardContent>
              {(userRole === 'boss' || userRole === 'admin') && (
                <div className="mb-4">
                  <Label className="text-sm font-medium">Assign Technician</Label>
                  <div className="flex gap-2 mt-2">
                    <select 
                      className="flex-1 px-3 py-2 border rounded-md"
                      onChange={(e) => e.target.value && handleAssignTechnician(e.target.value)}
                      disabled={isAssigning}
                    >
                      <option value="">Select a technician...</option>
                      {availableTechnicians.map((tech) => (
                        <option key={tech.id} value={tech.id}>
                          {tech.full_name || tech.email}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>
              )}
              
              {assignedTechs.length > 0 ? (
                <div className="space-y-2">
                  {assignedTechs.map((techId) => {
                    const tech = availableTechnicians.find(t => t.id === techId)
                    return tech ? (
                      <div key={techId} className="flex items-center gap-2 p-2 border rounded">
                        <User className="h-4 w-4 text-muted-foreground" />
                        <span className="text-sm">{tech.full_name || tech.email}</span>
                      </div>
                    ) : null
                  })}
                </div>
              ) : (
                <div className="text-center py-8 text-muted-foreground">
                  No technicians assigned yet
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* Files Tab */}
        <TabsContent value="files" className="mt-4">
          <Card>
            <CardHeader>
              <div className="flex justify-between items-center">
                <CardTitle>Files</CardTitle>
                <Button size="sm">
                  <Upload className="h-4 w-4 mr-2" />
                  Upload Files
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              <div className="text-center py-8 text-muted-foreground">
                No files uploaded yet
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Photos Tab */}
        <TabsContent value="photos" className="mt-4">
          <Card>
            <CardHeader>
              <div className="flex justify-between items-center">
                <CardTitle>Photos</CardTitle>
                <Button size="sm">
                  <Camera className="h-4 w-4 mr-2" />
                  Upload Photos
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              <div className="text-center py-8 text-muted-foreground">
                No photos uploaded yet
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Notes Tab */}
        <TabsContent value="notes" className="mt-4">
          <Card>
            <CardHeader>
              <CardTitle>Notes</CardTitle>
            </CardHeader>
            <CardContent>
              {job.boss_notes && (userRole === 'boss' || userRole === 'admin') && (
                <div className="p-3 bg-yellow-50 rounded mb-4">
                  <p className="text-sm font-medium mb-1">Boss Notes:</p>
                  <p className="text-sm whitespace-pre-wrap">{job.boss_notes}</p>
                </div>
              )}
              {job.completion_notes && (
                <div className="p-3 bg-green-50 rounded">
                  <p className="text-sm font-medium mb-1">Completion Notes:</p>
                  <p className="text-sm whitespace-pre-wrap">{job.completion_notes}</p>
                </div>
              )}
              {!job.boss_notes && !job.completion_notes && (
                <div className="text-center py-8 text-muted-foreground">
                  No notes added yet
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}
