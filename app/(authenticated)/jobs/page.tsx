import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Plus, Eye, MapPin } from 'lucide-react'

export default async function JobsPage() {
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/login')

  const { data: jobs, error } = await supabase
    .from('jobs')
    .select(`
      *,
      customers (
        name,
        email,
        phone,
        address
      )
    `)
    .order('created_at', { ascending: false })

  if (error) {
    console.error('Error fetching jobs:', error)
  }

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-3xl font-bold">Jobs</h1>
          <p className="text-muted-foreground">Manage your service jobs</p>
        </div>
        <Button>
          <Plus className="h-4 w-4 mr-2" />
          New Job
        </Button>
      </div>

      <Card>
        <CardHeader>
          <div className="flex justify-between items-center">
            <CardTitle>All Jobs</CardTitle>
            <div className="flex gap-2">
              <Button variant="outline" size="sm">List View</Button>
              <Button variant="outline" size="sm">Grid View</Button>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b">
                  <th className="text-left py-3 px-4">Job #</th>
                  <th className="text-left py-3 px-4">Customer</th>
                  <th className="text-left py-3 px-4">Address</th>
                  <th className="text-left py-3 px-4">Type</th>
                  <th className="text-center py-3 px-4">Status</th>
                  <th className="text-center py-3 px-4">Tasks</th>
                  <th className="text-left py-3 px-4">Created</th>
                  <th className="text-center py-3 px-4">Actions</th>
                </tr>
              </thead>
              <tbody>
                {jobs?.map((job) => (
                  <tr key={job.id} className="border-b hover:bg-gray-50">
                    <td className="py-3 px-4">
                      <Link 
                        href={`/jobs/${job.id}`}
                        className="font-medium text-blue-600 hover:text-blue-800"
                      >
                        {job.job_number}
                      </Link>
                    </td>
                    <td className="py-3 px-4">
                      {job.customers ? (
                        <div>
                          <div className="font-medium">{job.customers.name}</div>
                          <div className="text-sm text-muted-foreground">{job.customers.email}</div>
                        </div>
                      ) : (
                        <span className="text-muted-foreground">No customer</span>
                      )}
                    </td>
                    <td className="py-3 px-4">
                      {job.service_address ? (
                        <div className="flex items-center gap-1">
                          <MapPin className="h-3 w-3 text-muted-foreground" />
                          <span className="text-sm">
                            {job.service_address}
                            {job.service_city && `, ${job.service_city}`}
                            {job.service_state && `, ${job.service_state}`}
                          </span>
                        </div>
                      ) : (
                        <span className="text-muted-foreground text-sm">No address</span>
                      )}
                    </td>
                    <td className="py-3 px-4">
                      <span className="text-sm capitalize">{job.job_type}</span>
                    </td>
                    <td className="py-3 px-4 text-center">
                      <Badge variant={
                        job.status === 'completed' ? 'default' :
                        job.status === 'in_progress' ? 'secondary' :
                        'outline'
                      }>
                        {job.status.replace('_', ' ')}
                      </Badge>
                    </td>
                    <td className="py-3 px-4 text-center">
                      <span className="text-sm">0 tasks</span>
                    </td>
                    <td className="py-3 px-4">
                      <span className="text-sm">
                        {new Date(job.created_at).toLocaleDateString()}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-center">
                      <Link href={`/jobs/${job.id}`}>
                        <Button size="sm" variant="outline">
                          <Eye className="h-4 w-4 mr-1" />
                          View
                        </Button>
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {(!jobs || jobs.length === 0) && (
              <div className="text-center py-8 text-muted-foreground">
                No jobs found
              </div>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
