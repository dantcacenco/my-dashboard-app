#!/bin/bash

echo "🔧 Implementing Tasks System for Service Pro..."

# Create the Tasks List component for jobs
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

# Create the CreateTaskModal component
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
      // Pre-fill address from job's service address
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
      // Get current user
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) throw new Error('Not authenticated')

      // Create the task
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

      // Assign technicians if selected
      if (selectedTechnicians.length > 0) {
        const assignments = selectedTechnicians.map((techId, index) => ({
          task_id: task.id,
          technician_id: techId,
          assigned_by: user.id,
          is_lead: index === 0 // First technician is lead
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

# Create the EditTaskModal component
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
    // Set initial technicians
    const techIds = task.task_technicians?.map((tt: any) => tt.technician_id) || []
    setSelectedTechnicians(techIds)
  }, [task])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)

    try {
      // Get current user
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) throw new Error('Not authenticated')

      // Update the task
      const { error: taskError } = await supabase
        .from('tasks')
        .update({
          ...formData,
          updated_at: new Date().toISOString()
        })
        .eq('id', task.id)

      if (taskError) throw taskError

      // Update technician assignments
      // First delete existing assignments
      await supabase
        .from('task_technicians')
        .delete()
        .eq('task_id', task.id)

      // Then add new assignments
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

# Update JobDetailView to include Tasks tab
cat > app/jobs/[id]/JobDetailView_update.tsx << 'EOF'
// Add this import at the top
import TasksList from './TasksList'

// In the Tabs section, add a new Tasks tab after the Details tab:
<TabsContent value="tasks" className="mt-4">
  <TasksList jobId={job.id} canEdit={userRole === 'boss' || userRole === 'admin'} />
</TabsContent>

// Also add the Tasks tab trigger in TabsList:
<TabsTrigger value="tasks">Tasks</TabsTrigger>
EOF

echo "
📝 Manual update needed for JobDetailView.tsx:

1. Import TasksList at the top:
   import TasksList from './TasksList'

2. Add Tasks tab trigger after Details:
   <TabsTrigger value=\"tasks\">Tasks</TabsTrigger>

3. Add Tasks tab content after details tab:
   <TabsContent value=\"tasks\" className=\"mt-4\">
     <TasksList jobId={job.id} canEdit={userRole === 'boss' || userRole === 'admin'} />
   </TabsContent>
"

# Commit changes
git add .
git commit -m "feat: implement tasks system with create/edit/delete functionality"
git push origin main

echo "✅ Tasks system implementation complete!"
echo ""
echo "Features added:"
echo "- Task creation with technician assignment"
echo "- Task editing and status updates"
echo "- Task deletion"
echo "- Visual task cards with status badges"
echo "- Technician assignment using existing TechnicianSearch component"
echo ""
echo "Next steps:"
echo "1. Test task creation from job detail page"
echo "2. Verify technician assignments work"
echo "3. Implement time tracking for tasks"
echo "4. Add task completion workflow"