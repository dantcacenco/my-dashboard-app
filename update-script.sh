#!/bin/bash

echo "🔧 Implementing Complete Tasks System for Service Pro..."

# First, create all the Task components

# Create TasksList component
cat > app/jobs/[id]/TasksList.tsx << 'EOF'
'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Plus, Calendar, Clock, MapPin, User, Edit, Trash2 } from 'lucide-react'
import { format } from 'date-fns'
import CreateTaskModal from './CreateTaskModal'
import EditTaskModal from './EditTaskModal'

interface Task {
  id: string
  task_number: string
  title: string
  task_type: string
  scheduled_date: string
  scheduled_start_time: string
  scheduled_end_time: string | null
  status: string
  address: string | null
  notes: string | null
  task_technicians: {
    technician_id: string
    profiles: {
      full_name: string
      email: string
    }
  }[]
}

interface TasksListProps {
  jobId: string
  canEdit: boolean
}

export default function TasksList({ jobId, canEdit }: TasksListProps) {
  const [tasks, setTasks] = useState<Task[]>([])
  const [loading, setLoading] = useState(true)
  const [showCreateModal, setShowCreateModal] = useState(false)
  const [editingTask, setEditingTask] = useState<Task | null>(null)
  const supabase = createClient()

  useEffect(() => {
    fetchTasks()
  }, [jobId])

  const fetchTasks = async () => {
    try {
      const { data, error } = await supabase
        .from('tasks')
        .select(`
          *,
          task_technicians (
            technician_id,
            profiles (
              full_name,
              email
            )
          )
        `)
        .eq('job_id', jobId)
        .order('scheduled_date', { ascending: true })
        .order('scheduled_start_time', { ascending: true })

      if (error) throw error
      setTasks(data || [])
    } catch (error) {
      console.error('Error fetching tasks:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleDeleteTask = async (taskId: string) => {
    if (!confirm('Are you sure you want to delete this task?')) return

    try {
      const { error } = await supabase
        .from('tasks')
        .delete()
        .eq('id', taskId)

      if (error) throw error
      await fetchTasks()
    } catch (error) {
      console.error('Error deleting task:', error)
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed': return 'bg-green-500'
      case 'in_progress': return 'bg-blue-500'
      case 'scheduled': return 'bg-gray-500'
      case 'cancelled': return 'bg-red-500'
      default: return 'bg-gray-400'
    }
  }

  const getTaskTypeColor = (type: string) => {
    switch (type) {
      case 'service_call': return 'bg-purple-500'
      case 'repair': return 'bg-orange-500'
      case 'maintenance': return 'bg-blue-500'
      case 'rough_in': return 'bg-indigo-500'
      case 'startup': return 'bg-green-500'
      case 'meeting': return 'bg-pink-500'
      case 'office': return 'bg-gray-500'
      default: return 'bg-gray-400'
    }
  }

  if (loading) {
    return <div className="text-center py-4">Loading tasks...</div>
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h3 className="text-lg font-semibold">Tasks</h3>
        {canEdit && (
          <Button onClick={() => setShowCreateModal(true)} size="sm">
            <Plus className="h-4 w-4 mr-2" />
            Add Task
          </Button>
        )}
      </div>

      {tasks.length === 0 ? (
        <Card>
          <CardContent className="text-center py-8">
            <p className="text-gray-500">No tasks scheduled yet</p>
            {canEdit && (
              <Button 
                onClick={() => setShowCreateModal(true)} 
                className="mt-4"
                variant="outline"
              >
                <Plus className="h-4 w-4 mr-2" />
                Create First Task
              </Button>
            )}
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-4">
          {tasks.map((task) => (
            <Card key={task.id}>
              <CardHeader className="pb-3">
                <div className="flex justify-between items-start">
                  <div className="space-y-1">
                    <CardTitle className="text-base">
                      {task.task_number}: {task.title}
                    </CardTitle>
                    <div className="flex gap-2">
                      <Badge className={getTaskTypeColor(task.task_type)} variant="secondary">
                        {task.task_type.replace('_', ' ')}
                      </Badge>
                      <Badge className={getStatusColor(task.status)} variant="secondary">
                        {task.status}
                      </Badge>
                    </div>
                  </div>
                  {canEdit && (
                    <div className="flex gap-2">
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={() => setEditingTask(task)}
                      >
                        <Edit className="h-4 w-4" />
                      </Button>
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={() => handleDeleteTask(task.id)}
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  )}
                </div>
              </CardHeader>
              <CardContent className="space-y-2">
                <div className="flex items-center gap-2 text-sm text-gray-600">
                  <Calendar className="h-4 w-4" />
                  {format(new Date(task.scheduled_date), 'MMM d, yyyy')}
                </div>
                <div className="flex items-center gap-2 text-sm text-gray-600">
                  <Clock className="h-4 w-4" />
                  {task.scheduled_start_time}
                  {task.scheduled_end_time && ` - ${task.scheduled_end_time}`}
                </div>
                {task.address && (
                  <div className="flex items-center gap-2 text-sm text-gray-600">
                    <MapPin className="h-4 w-4" />
                    {task.address}
                  </div>
                )}
                {task.task_technicians.length > 0 && (
                  <div className="flex items-center gap-2 text-sm text-gray-600">
                    <User className="h-4 w-4" />
                    {task.task_technicians.map(tt => tt.profiles.full_name).join(', ')}
                  </div>
                )}
                {task.notes && (
                  <p className="text-sm text-gray-600 mt-2">{task.notes}</p>
                )}
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {showCreateModal && (
        <CreateTaskModal
          jobId={jobId}
          onClose={() => setShowCreateModal(false)}
          onSuccess={() => {
            setShowCreateModal(false)
            fetchTasks()
          }}
        />
      )}

      {editingTask && (
        <EditTaskModal
          task={editingTask}
          onClose={() => setEditingTask(null)}
          onSuccess={() => {
            setEditingTask(null)
            fetchTasks()
          }}
        />
      )}
    </div>
  )
}
EOF

# Create CreateTaskModal component
cat > app/jobs/[id]/CreateTaskModal.tsx << 'EOF'
'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { TechnicianSearch } from '@/components/technician/TechnicianSearch'
import { format } from 'date-fns'

interface CreateTaskModalProps {
  jobId: string
  onClose: () => void
  onSuccess: () => void
}

export default function CreateTaskModal({ jobId, onClose, onSuccess }: CreateTaskModalProps) {
  const [loading, setLoading] = useState(false)
  const [selectedTechnicians, setSelectedTechnicians] = useState<string[]>([])
  const [jobData, setJobData] = useState<any>(null)
  const [formData, setFormData] = useState({
    title: '',
    task_type: 'service_call',
    scheduled_date: format(new Date(), 'yyyy-MM-dd'),
    scheduled_start_time: '09:00',
    scheduled_end_time: '17:00',
    address: '',
    notes: ''
  })
  
  const supabase = createClient()

  useEffect(() => {
    fetchJobData()
  }, [jobId])

  const fetchJobData = async () => {
    const { data } = await supabase
      .from('jobs')
      .select('*, customers(*)')
      .eq('id', jobId)
      .single()
    
    if (data) {
      setJobData(data)
      setFormData(prev => ({
        ...prev,
        address: data.service_address || data.customers?.address || ''
      }))
    }
  }

  const generateTaskNumber = () => {
    const date = new Date()
    const dateStr = format(date, 'yyyyMMdd')
    const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0')
    return `TASK-${dateStr}-${random}`
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)

    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) throw new Error('Not authenticated')

      const { data: task, error: taskError } = await supabase
        .from('tasks')
        .insert({
          task_number: generateTaskNumber(),
          job_id: jobId,
          ...formData,
          created_by: user.id,
          status: 'scheduled'
        })
        .select()
        .single()

      if (taskError) throw taskError

      if (selectedTechnicians.length > 0) {
        const assignments = selectedTechnicians.map((techId, index) => ({
          task_id: task.id,
          technician_id: techId,
          assigned_by: user.id,
          is_lead: index === 0
        }))

        const { error: assignError } = await supabase
          .from('task_technicians')
          .insert(assignments)

        if (assignError) throw assignError
      }

      onSuccess()
    } catch (error) {
      console.error('Error creating task:', error)
      alert('Failed to create task')
    } finally {
      setLoading(false)
    }
  }

  return (
    <Dialog open={true} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Create New Task</DialogTitle>
        </DialogHeader>
        
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <Label htmlFor="title">Task Title</Label>
            <Input
              id="title"
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              required
            />
          </div>

          <div>
            <Label htmlFor="task_type">Task Type</Label>
            <Select
              value={formData.task_type}
              onValueChange={(value) => setFormData({ ...formData, task_type: value })}
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="service_call">Service Call</SelectItem>
                <SelectItem value="repair">Repair</SelectItem>
                <SelectItem value="maintenance">Maintenance</SelectItem>
                <SelectItem value="rough_in">Rough In</SelectItem>
                <SelectItem value="startup">Startup</SelectItem>
                <SelectItem value="meeting">Meeting</SelectItem>
                <SelectItem value="office">Office</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div className="grid grid-cols-3 gap-4">
            <div>
              <Label htmlFor="scheduled_date">Date</Label>
              <Input
                id="scheduled_date"
                type="date"
                value={formData.scheduled_date}
                onChange={(e) => setFormData({ ...formData, scheduled_date: e.target.value })}
                required
              />
            </div>
            <div>
              <Label htmlFor="scheduled_start_time">Start Time</Label>
              <Input
                id="scheduled_start_time"
                type="time"
                value={formData.scheduled_start_time}
                onChange={(e) => setFormData({ ...formData, scheduled_start_time: e.target.value })}
                required
              />
            </div>
            <div>
              <Label htmlFor="scheduled_end_time">End Time</Label>
              <Input
                id="scheduled_end_time"
                type="time"
                value={formData.scheduled_end_time}
                onChange={(e) => setFormData({ ...formData, scheduled_end_time: e.target.value })}
              />
            </div>
          </div>

          <div>
            <Label htmlFor="address">Service Address</Label>
            <Input
              id="address"
              value={formData.address}
              onChange={(e) => setFormData({ ...formData, address: e.target.value })}
            />
          </div>

          <div>
            <Label>Assign Technicians</Label>
            <TechnicianSearch
              selectedTechnicians={selectedTechnicians}
              onSelectionChange={setSelectedTechnicians}
            />
          </div>

          <div>
            <Label htmlFor="notes">Notes</Label>
            <Textarea
              id="notes"
              value={formData.notes}
              onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
              rows={3}
            />
          </div>

          <div className="flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={onClose}>
              Cancel
            </Button>
            <Button type="submit" disabled={loading}>
              {loading ? 'Creating...' : 'Create Task'}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}
EOF

# Create EditTaskModal component
cat > app/jobs/[id]/EditTaskModal.tsx << 'EOF'
'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { TechnicianSearch } from '@/components/technician/TechnicianSearch'

interface EditTaskModalProps {
  task: any
  onClose: () => void
  onSuccess: () => void
}

export default function EditTaskModal({ task, onClose, onSuccess }: EditTaskModalProps) {
  const [loading, setLoading] = useState(false)
  const [selectedTechnicians, setSelectedTechnicians] = useState<string[]>([])
  const [formData, setFormData] = useState({
    title: task.title,
    task_type: task.task_type,
    scheduled_date: task.scheduled_date,
    scheduled_start_time: task.scheduled_start_time,
    scheduled_end_time: task.scheduled_end_time || '',
    status: task.status,
    address: task.address || '',
    notes: task.notes || ''
  })
  
  const supabase = createClient()

  useEffect(() => {
    const techIds = task.task_technicians?.map((tt: any) => tt.technician_id) || []
    setSelectedTechnicians(techIds)
  }, [task])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)

    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) throw new Error('Not authenticated')

      const { error: taskError } = await supabase
        .from('tasks')
        .update({
          ...formData,
          updated_at: new Date().toISOString()
        })
        .eq('id', task.id)

      if (taskError) throw taskError

      await supabase
        .from('task_technicians')
        .delete()
        .eq('task_id', task.id)

      if (selectedTechnicians.length > 0) {
        const assignments = selectedTechnicians.map((techId, index) => ({
          task_id: task.id,
          technician_id: techId,
          assigned_by: user.id,
          is_lead: index === 0
        }))

        const { error: assignError } = await supabase
          .from('task_technicians')
          .insert(assignments)

        if (assignError) throw assignError
      }

      onSuccess()
    } catch (error) {
      console.error('Error updating task:', error)
      alert('Failed to update task')
    } finally {
      setLoading(false)
    }
  }

  return (
    <Dialog open={true} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Edit Task: {task.task_number}</DialogTitle>
        </DialogHeader>
        
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <Label htmlFor="title">Task Title</Label>
            <Input
              id="title"
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              required
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="task_type">Task Type</Label>
              <Select
                value={formData.task_type}
                onValueChange={(value) => setFormData({ ...formData, task_type: value })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="service_call">Service Call</SelectItem>
                  <SelectItem value="repair">Repair</SelectItem>
                  <SelectItem value="maintenance">Maintenance</SelectItem>
                  <SelectItem value="rough_in">Rough In</SelectItem>
                  <SelectItem value="startup">Startup</SelectItem>
                  <SelectItem value="meeting">Meeting</SelectItem>
                  <SelectItem value="office">Office</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div>
              <Label htmlFor="status">Status</Label>
              <Select
                value={formData.status}
                onValueChange={(value) => setFormData({ ...formData, status: value })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="scheduled">Scheduled</SelectItem>
                  <SelectItem value="in_progress">In Progress</SelectItem>
                  <SelectItem value="completed">Completed</SelectItem>
                  <SelectItem value="cancelled">Cancelled</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="grid grid-cols-3 gap-4">
            <div>
              <Label htmlFor="scheduled_date">Date</Label>
              <Input
                id="scheduled_date"
                type="date"
                value={formData.scheduled_date}
                onChange={(e) => setFormData({ ...formData, scheduled_date: e.target.value })}
                required
              />
            </div>
            <div>
              <Label htmlFor="scheduled_start_time">Start Time</Label>
              <Input
                id="scheduled_start_time"
                type="time"
                value={formData.scheduled_start_time}
                onChange={(e) => setFormData({ ...formData, scheduled_start_time: e.target.value })}
                required
              />
            </div>
            <div>
              <Label htmlFor="scheduled_end_time">End Time</Label>
              <Input
                id="scheduled_end_time"
                type="time"
                value={formData.scheduled_end_time}
                onChange={(e) => setFormData({ ...formData, scheduled_end_time: e.target.value })}
              />
            </div>
          </div>

          <div>
            <Label htmlFor="address">Service Address</Label>
            <Input
              id="address"
              value={formData.address}
              onChange={(e) => setFormData({ ...formData, address: e.target.value })}
            />
          </div>

          <div>
            <Label>Assign Technicians</Label>
            <TechnicianSearch
              selectedTechnicians={selectedTechnicians}
              onSelectionChange={setSelectedTechnicians}
            />
          </div>

          <div>
            <Label htmlFor="notes">Notes</Label>
            <Textarea
              id="notes"
              value={formData.notes}
              onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
              rows={3}
            />
          </div>

          <div className="flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={onClose}>
              Cancel
            </Button>
            <Button type="submit" disabled={loading}>
              {loading ? 'Updating...' : 'Update Task'}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}
EOF

# Now, completely replace the JobDetailView.tsx file with Tasks tab included
cat > app/jobs/[id]/JobDetailView.tsx << 'EOF'
'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { createAdminClient } from '@/lib/supabase/admin'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Textarea } from '@/components/ui/textarea'
import { Calendar, Clock, User, MapPin, DollarSign, Briefcase, Edit, ChevronLeft, FileText, Upload, Camera, Users, ClipboardList } from 'lucide-react'
import { format } from 'date-fns'
import EditJobModal from './EditJobModal'
import PhotoUpload from './PhotoUpload'
import { TechnicianSearch } from '@/components/technician/TechnicianSearch'
import TasksList from './TasksList'

interface JobDetailViewProps {
  job: any
}

export default function JobDetailView({ job: initialJob }: JobDetailViewProps) {
  const [job, setJob] = useState(initialJob)
  const [loading, setLoading] = useState(false)
  const [showEditModal, setShowEditModal] = useState(false)
  const [selectedTechnicians, setSelectedTechnicians] = useState<string[]>([])
  const [technicians, setTechnicians] = useState<any[]>([])
  const [userRole, setUserRole] = useState<string | null>(null)
  const [bossNotes, setBossNotes] = useState(job.boss_notes || '')
  const [completionNotes, setCompletionNotes] = useState(job.completion_notes || '')
  const [savingNotes, setSavingNotes] = useState(false)
  
  const router = useRouter()
  const supabase = createClient()
  const adminClient = createAdminClient()

  useEffect(() => {
    fetchUserRole()
    fetchJobTechnicians()
  }, [job.id])

  const fetchUserRole = async () => {
    const { data: { user } } = await supabase.auth.getUser()
    if (user) {
      const { data: profile } = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single()
      
      setUserRole(profile?.role || null)
    }
  }

  const fetchJobTechnicians = async () => {
    const { data } = await adminClient
      .from('job_technicians')
      .select('technician_id, profiles!job_technicians_technician_id_fkey(id, full_name, email)')
      .eq('job_id', job.id)
    
    if (data) {
      const techIds = data.map(jt => jt.technician_id)
      const techProfiles = data.map(jt => jt.profiles).filter(Boolean)
      setSelectedTechnicians(techIds)
      setTechnicians(techProfiles)
    }
  }

  const handleStatusUpdate = async (newStatus: string) => {
    setLoading(true)
    try {
      const updateData: any = { 
        status: newStatus,
        updated_at: new Date().toISOString()
      }
      
      if (newStatus === 'in_progress' && !job.actual_start_time) {
        updateData.actual_start_time = new Date().toISOString()
      } else if (newStatus === 'completed' && !job.actual_end_time) {
        updateData.actual_end_time = new Date().toISOString()
      }

      const { data, error } = await supabase
        .from('jobs')
        .update(updateData)
        .eq('id', job.id)
        .select()
        .single()

      if (error) throw error

      setJob(data)
      
      const { data: { user } } = await supabase.auth.getUser()
      if (user) {
        await supabase.from('job_activity_log').insert({
          job_id: job.id,
          user_id: user.id,
          activity_type: 'status_change',
          description: `Status changed from ${job.status} to ${newStatus}`,
          old_value: job.status,
          new_value: newStatus
        })
      }
    } catch (error) {
      console.error('Failed to update status:', error)
      alert('Failed to update job status')
    } finally {
      setLoading(false)
    }
  }

  const handleTechnicianUpdate = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) return

      await adminClient
        .from('job_technicians')
        .delete()
        .eq('job_id', job.id)

      if (selectedTechnicians.length > 0) {
        const assignments = selectedTechnicians.map(techId => ({
          job_id: job.id,
          technician_id: techId,
          assigned_by: user.id
        }))

        await adminClient
          .from('job_technicians')
          .insert(assignments)
      }

      await fetchJobTechnicians()
      alert('Technicians updated successfully')
    } catch (error) {
      console.error('Error updating technicians:', error)
      alert('Failed to update technicians')
    }
  }

  const handleNotesUpdate = async (noteType: 'boss_notes' | 'completion_notes') => {
    setSavingNotes(true)
    try {
      const value = noteType === 'boss_notes' ? bossNotes : completionNotes
      
      const { error } = await supabase
        .from('jobs')
        .update({ 
          [noteType]: value,
          updated_at: new Date().toISOString()
        })
        .eq('id', job.id)

      if (error) throw error
      
      setJob({ ...job, [noteType]: value })
      alert('Notes saved successfully')
    } catch (error) {
      console.error('Error saving notes:', error)
      alert('Failed to save notes')
    } finally {
      setSavingNotes(false)
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed': return 'bg-green-500'
      case 'in_progress': return 'bg-blue-500'
      case 'pending': return 'bg-yellow-500'
      case 'cancelled': return 'bg-red-500'
      default: return 'bg-gray-500'
    }
  }

  const canEdit = userRole === 'boss' || userRole === 'admin'

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button
            variant="ghost"
            size="sm"
            onClick={() => router.push('/jobs')}
          >
            <ChevronLeft className="h-4 w-4 mr-1" />
            Back to Jobs
          </Button>
          <h1 className="text-2xl font-bold">Job #{job.job_number}</h1>
          <Badge className={getStatusColor(job.status)} variant="secondary">
            {job.status.replace('_', ' ')}
          </Badge>
        </div>
        {canEdit && (
          <Button onClick={() => setShowEditModal(true)}>
            <Edit className="h-4 w-4 mr-2" />
            Edit Job
          </Button>
        )}
      </div>

      <Tabs defaultValue="overview" className="space-y-4">
        <TabsList>
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="tasks">Tasks</TabsTrigger>
          <TabsTrigger value="technicians">Technicians</TabsTrigger>
          <TabsTrigger value="files">Files</TabsTrigger>
          <TabsTrigger value="photos">Photos</TabsTrigger>
          <TabsTrigger value="notes">Notes</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-4">
          <div className="grid gap-4 md:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle>Job Details</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex items-center gap-2 text-sm">
                  <Briefcase className="h-4 w-4 text-gray-500" />
                  <span className="font-medium">Type:</span>
                  <span>{job.job_type}</span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <Calendar className="h-4 w-4 text-gray-500" />
                  <span className="font-medium">Scheduled:</span>
                  <span>
                    {job.scheduled_date ? format(new Date(job.scheduled_date), 'MMM d, yyyy') : 'Not scheduled'}
                    {job.scheduled_time && ` at ${job.scheduled_time}`}
                  </span>
                </div>
                {job.estimated_duration && (
                  <div className="flex items-center gap-2 text-sm">
                    <Clock className="h-4 w-4 text-gray-500" />
                    <span className="font-medium">Duration:</span>
                    <span>{job.estimated_duration}</span>
                  </div>
                )}
                <div className="flex items-center gap-2 text-sm">
                  <DollarSign className="h-4 w-4 text-gray-500" />
                  <span className="font-medium">Value:</span>
                  <span>${Number(job.total_value || 0).toFixed(2)}</span>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Customer Information</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="space-y-1">
                  <p className="font-medium">{job.customer_name}</p>
                  {job.customer_email && (
                    <p className="text-sm text-gray-600">{job.customer_email}</p>
                  )}
                  {job.customer_phone && (
                    <p className="text-sm text-gray-600">{job.customer_phone}</p>
                  )}
                </div>
                {job.service_address && (
                  <div className="flex items-start gap-2 text-sm">
                    <MapPin className="h-4 w-4 text-gray-500 mt-0.5" />
                    <div>
                      <p>{job.service_address}</p>
                      {(job.service_city || job.service_state || job.service_zip) && (
                        <p>
                          {[job.service_city, job.service_state, job.service_zip]
                            .filter(Boolean)
                            .join(', ')}
                        </p>
                      )}
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>
          </div>

          {job.description && (
            <Card>
              <CardHeader>
                <CardTitle>Description</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-sm text-gray-600 whitespace-pre-wrap">{job.description}</p>
              </CardContent>
            </Card>
          )}

          <Card>
            <CardHeader>
              <CardTitle>Status Management</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex gap-2">
                {job.status === 'pending' && (
                  <Button
                    onClick={() => handleStatusUpdate('in_progress')}
                    disabled={loading}
                  >
                    Start Job
                  </Button>
                )}
                {job.status === 'in_progress' && (
                  <>
                    <Button
                      onClick={() => handleStatusUpdate('completed')}
                      disabled={loading}
                      variant="default"
                    >
                      Complete Job
                    </Button>
                    <Button
                      onClick={() => handleStatusUpdate('pending')}
                      disabled={loading}
                      variant="outline"
                    >
                      Pause Job
                    </Button>
                  </>
                )}
                {job.status === 'completed' && (
                  <Button
                    onClick={() => handleStatusUpdate('in_progress')}
                    disabled={loading}
                    variant="outline"
                  >
                    Reopen Job
                  </Button>
                )}
                {job.status !== 'cancelled' && job.status !== 'completed' && (
                  <Button
                    onClick={() => handleStatusUpdate('cancelled')}
                    disabled={loading}
                    variant="destructive"
                  >
                    Cancel Job
                  </Button>
                )}
              </div>
              
              {job.actual_start_time && (
                <p className="text-sm text-gray-600 mt-4">
                  Started: {format(new Date(job.actual_start_time), 'MMM d, yyyy h:mm a')}
                </p>
              )}
              {job.actual_end_time && (
                <p className="text-sm text-gray-600">
                  Completed: {format(new Date(job.actual_end_time), 'MMM d, yyyy h:mm a')}
                </p>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="tasks" className="mt-4">
          <TasksList jobId={job.id} canEdit={canEdit} />
        </TabsContent>

        <TabsContent value="technicians" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Assigned Technicians</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {canEdit ? (
                <>
                  <TechnicianSearch
                    selectedTechnicians={selectedTechnicians}
                    onSelectionChange={setSelectedTechnicians}
                  />
                  <Button 
                    onClick={handleTechnicianUpdate}
                    disabled={loading}
                  >
                    Update Technicians
                  </Button>
                </>
              ) : (
                <div className="space-y-2">
                  {technicians.length > 0 ? (
                    technicians.map((tech) => (
                      <div key={tech.id} className="flex items-center gap-2 p-2 border rounded">
                        <User className="h-4 w-4 text-gray-500" />
                        <span>{tech.full_name}</span>
                        <span className="text-sm text-gray-500">({tech.email})</span>
                      </div>
                    ))
                  ) : (
                    <p className="text-gray-500">No technicians assigned</p>
                  )}
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="files" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Files & Documents</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center">
                <Upload className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <p className="text-gray-600 mb-2">File upload coming soon</p>
                <p className="text-sm text-gray-500">You'll be able to upload PDFs, documents, and other files here</p>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="photos" className="space-y-4">
          <PhotoUpload jobId={job.id} />
        </TabsContent>

        <TabsContent value="notes" className="space-y-4">
          {(userRole === 'boss' || userRole === 'admin') && (
            <Card>
              <CardHeader>
                <CardTitle>Boss Notes (Private)</CardTitle>
              </CardHeader>
              <CardContent className="space-y-2">
                <Textarea
                  value={bossNotes}
                  onChange={(e) => setBossNotes(e.target.value)}
                  placeholder="Private notes only visible to boss/admin..."
                  rows={4}
                />
                <Button 
                  onClick={() => handleNotesUpdate('boss_notes')}
                  disabled={savingNotes}
                >
                  Save Boss Notes
                </Button>
              </CardContent>
            </Card>
          )}

          <Card>
            <CardHeader>
              <CardTitle>Completion Notes</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              <Textarea
                value={completionNotes}
                onChange={(e) => setCompletionNotes(e.target.value)}
                placeholder="Notes about job completion..."
                rows={4}
                disabled={!canEdit && userRole !== 'technician'}
              />
              {(canEdit || userRole === 'technician') && (
                <Button 
                  onClick={() => handleNotesUpdate('completion_notes')}
                  disabled={savingNotes}
                >
                  Save Completion Notes
                </Button>
              )}
            </CardContent>
          </Card>

          {job.notes && (
            <Card>
              <CardHeader>
                <CardTitle>General Notes</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-sm text-gray-600 whitespace-pre-wrap">{job.notes}</p>
              </CardContent>
            </Card>
          )}
        </TabsContent>
      </Tabs>

      {showEditModal && (
        <EditJobModal
          job={job}
          onClose={() => setShowEditModal(false)}
          onSuccess={(updatedJob) => {
            setJob(updatedJob)
            setShowEditModal(false)
          }}
        />
      )}
    </div>
  )
}
EOF

# Commit all changes
git add .
git commit -m "feat: complete tasks system implementation with automatic JobDetailView update"
git push origin main

echo "✅ Complete Tasks System Implementation Done!"
echo ""
echo "Features added:"
echo "- TasksList component with full CRUD operations"
echo "- CreateTaskModal for adding new tasks"
echo "- EditTaskModal for updating existing tasks"
echo "- Automatic JobDetailView update with Tasks tab"
echo "- Task status management (scheduled, in_progress, completed, cancelled)"
echo "- Technician assignment to tasks"
echo "- Visual badges for task types and statuses"
echo ""
echo "No manual updates needed - everything is automated!"