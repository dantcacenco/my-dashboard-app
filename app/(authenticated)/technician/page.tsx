import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Calendar, Clock, MapPin, Briefcase } from 'lucide-react'
import Link from 'next/link'

export default async function TechnicianPortal() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) redirect('/auth/login')

  // Get tasks assigned to this technician
  const { data: tasks } = await supabase
    .from('tasks')
    .select(`
      *,
      jobs (
        job_number,
        title,
        customers (
          name,
          phone
        )
      ),
      task_technicians!inner (
        technician_id
      )
    `)
    .eq('task_technicians.technician_id', user.id)
    .order('scheduled_date', { ascending: true })
    .order('scheduled_start_time', { ascending: true })

  // Group tasks by date
  const today = new Date().toISOString().split('T')[0]
  const tomorrow = new Date(Date.now() + 86400000).toISOString().split('T')[0]
  
  const todayTasks = tasks?.filter(t => t.scheduled_date === today) || []
  const tomorrowTasks = tasks?.filter(t => t.scheduled_date === tomorrow) || []
  const upcomingTasks = tasks?.filter(t => t.scheduled_date > tomorrow) || []

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-3xl font-bold">My Tasks</h1>
        <p className="text-muted-foreground">View and manage your assigned tasks</p>
      </div>

      {/* Today's Tasks */}
      {todayTasks.length > 0 && (
        <div className="mb-6">
          <h2 className="text-xl font-semibold mb-3 text-green-600">Today</h2>
          <div className="space-y-3">
            {todayTasks.map((task) => (
              <Link
                key={task.id}
                href={`/technician/tasks/${task.id}`}
                className="block"
              >
                <Card className="hover:shadow-md transition-shadow cursor-pointer">
                  <CardContent className="p-4">
                    <div className="flex justify-between items-start">
                      <div className="flex-1">
                        <div className="font-medium">{task.title}</div>
                        <div className="text-sm text-muted-foreground mt-1">
                          Job: {task.jobs?.job_number} - {task.jobs?.title}
                        </div>
                        {task.jobs?.customers && (
                          <div className="text-sm text-gray-600 mt-1">
                            Customer: {task.jobs.customers.name}
                            {task.jobs.customers.phone && ` • ${task.jobs.customers.phone}`}
                          </div>
                        )}
                        <div className="flex items-center gap-4 mt-2 text-sm">
                          <div className="flex items-center gap-1">
                            <Clock className="h-3 w-3" />
                            {task.scheduled_start_time}
                          </div>
                          {task.address && (
                            <div className="flex items-center gap-1">
                              <MapPin className="h-3 w-3" />
                              {task.address}
                            </div>
                          )}
                        </div>
                      </div>
                      <Badge variant={
                        task.status === 'completed' ? 'default' :
                        task.status === 'in_progress' ? 'secondary' : 'outline'
                      }>
                        {task.status}
                      </Badge>
                    </div>
                  </CardContent>
                </Card>
              </Link>
            ))}
          </div>
        </div>
      )}

      {/* Tomorrow's Tasks */}
      {tomorrowTasks.length > 0 && (
        <div className="mb-6">
          <h2 className="text-xl font-semibold mb-3">Tomorrow</h2>
          <div className="space-y-3">
            {tomorrowTasks.map((task) => (
              <Link
                key={task.id}
                href={`/technician/tasks/${task.id}`}
                className="block"
              >
                <Card className="hover:shadow-md transition-shadow cursor-pointer">
                  <CardContent className="p-4">
                    <div className="flex justify-between items-start">
                      <div className="flex-1">
                        <div className="font-medium">{task.title}</div>
                        <div className="text-sm text-muted-foreground mt-1">
                          Job: {task.jobs?.job_number}
                        </div>
                        <div className="flex items-center gap-4 mt-2 text-sm">
                          <div className="flex items-center gap-1">
                            <Clock className="h-3 w-3" />
                            {task.scheduled_start_time}
                          </div>
                        </div>
                      </div>
                      <Badge variant="outline">{task.task_type}</Badge>
                    </div>
                  </CardContent>
                </Card>
              </Link>
            ))}
          </div>
        </div>
      )}

      {/* No tasks message */}
      {tasks?.length === 0 && (
        <Card>
          <CardContent className="p-8 text-center text-muted-foreground">
            <Briefcase className="h-12 w-12 mx-auto mb-4 text-gray-300" />
            <p>No tasks assigned yet</p>
          </CardContent>
        </Card>
      )}
    </div>
  )
}
