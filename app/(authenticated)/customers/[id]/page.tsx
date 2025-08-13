import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { notFound } from 'next/navigation'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Edit, Mail, Phone, MapPin, DollarSign, Briefcase, FileText, Clock } from 'lucide-react'
import Link from 'next/link'

export default async function CustomerDetailPage({ 
  params 
}: { 
  params: Promise<{ id: string }> 
}) {
  const { id } = await params
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/login')

  // Fetch customer with all related data
  const { data: customer, error: customerError } = await supabase
    .from('customers')
    .select(`
      *,
      proposals:proposals(*),
      jobs:jobs(*)
    `)
    .eq('id', id)
    .single()

  if (customerError || !customer) {
    notFound()
  }

  // Calculate stats
  const totalProposals = customer.proposals?.length || 0
  const approvedProposals = customer.proposals?.filter((p: any) => p.status === 'approved').length || 0
  const totalJobs = customer.jobs?.length || 0
  const activeJobs = customer.jobs?.filter((j: any) => j.status === 'in_progress').length || 0
  const totalRevenue = customer.proposals?.reduce((sum: number, p: any) => sum + (p.total || 0), 0) || 0
  const paidRevenue = customer.proposals?.reduce((sum: number, p: any) => sum + (p.total_paid || 0), 0) || 0

  return (
    <div className="p-6">
      {/* Header Section */}
      <div className="mb-6">
        <div className="flex justify-between items-start">
          <div>
            <h1 className="text-3xl font-bold">{customer.name}</h1>
            <div className="flex items-center gap-4 mt-2 text-muted-foreground">
              {customer.email && (
                <div className="flex items-center gap-1">
                  <Mail className="h-4 w-4" />
                  <span>{customer.email}</span>
                </div>
              )}
              {customer.phone && (
                <div className="flex items-center gap-1">
                  <Phone className="h-4 w-4" />
                  <span>{customer.phone}</span>
                </div>
              )}
              {customer.address && (
                <div className="flex items-center gap-1">
                  <MapPin className="h-4 w-4" />
                  <span>{customer.address}</span>
                </div>
              )}
            </div>
          </div>
          <Button>
            <Edit className="h-4 w-4 mr-2" />
            Edit Customer
          </Button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Total Proposals
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{totalProposals}</div>
            <p className="text-xs text-muted-foreground">
              {approvedProposals} approved
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Total Jobs
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{totalJobs}</div>
            <p className="text-xs text-muted-foreground">
              {activeJobs} active
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Total Revenue
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              ${totalRevenue.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
            </div>
            <p className="text-xs text-muted-foreground">
              ${paidRevenue.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} paid
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Active Jobs
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{activeJobs}</div>
            <p className="text-xs text-muted-foreground">
              In progress
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Tabs Section */}
      <Tabs defaultValue="proposals" className="w-full">
        <TabsList>
          <TabsTrigger value="proposals">Proposals</TabsTrigger>
          <TabsTrigger value="jobs">Jobs</TabsTrigger>
          <TabsTrigger value="activity">Activity</TabsTrigger>
        </TabsList>

        <TabsContent value="proposals" className="mt-4">
          <Card>
            <CardHeader>
              <CardTitle>Proposals</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {customer.proposals?.map((proposal: any) => (
                  <Link
                    key={proposal.id}
                    href={`/proposals/${proposal.id}`}
                    className="block p-4 border rounded-lg hover:bg-gray-50 transition-colors"
                  >
                    <div className="flex justify-between items-start">
                      <div>
                        <div className="font-medium">{proposal.title}</div>
                        <div className="text-sm text-muted-foreground">
                          {proposal.proposal_number} • Created {new Date(proposal.created_at).toLocaleDateString()}
                        </div>
                      </div>
                      <div className="text-right">
                        <Badge variant={
                          proposal.status === 'approved' ? 'default' :
                          proposal.status === 'sent' ? 'secondary' :
                          proposal.status === 'draft' ? 'outline' : 'destructive'
                        }>
                          {proposal.status}
                        </Badge>
                        <div className="font-medium mt-1">
                          ${proposal.total?.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                        </div>
                      </div>
                    </div>
                  </Link>
                ))}
                {(!customer.proposals || customer.proposals.length === 0) && (
                  <div className="text-center py-8 text-muted-foreground">
                    No proposals yet
                  </div>
                )}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="jobs" className="mt-4">
          <Card>
            <CardHeader>
              <CardTitle>Jobs</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {customer.jobs?.map((job: any) => (
                  <Link
                    key={job.id}
                    href={`/jobs/${job.id}`}
                    className="block p-4 border rounded-lg hover:bg-gray-50 transition-colors"
                  >
                    <div className="flex justify-between items-start">
                      <div>
                        <div className="font-medium">{job.title}</div>
                        <div className="text-sm text-muted-foreground">
                          {job.job_number} • {job.scheduled_date ? `Scheduled ${new Date(job.scheduled_date).toLocaleDateString()}` : 'Not scheduled'}
                        </div>
                      </div>
                      <div className="text-right">
                        <Badge variant={
                          job.status === 'completed' ? 'default' :
                          job.status === 'in_progress' ? 'secondary' :
                          job.status === 'scheduled' ? 'outline' : 'destructive'
                        }>
                          {job.status}
                        </Badge>
                        {job.assigned_technician_id && (
                          <div className="text-sm text-muted-foreground mt-1">
                            Assigned
                          </div>
                        )}
                      </div>
                    </div>
                  </Link>
                ))}
                {(!customer.jobs || customer.jobs.length === 0) && (
                  <div className="text-center py-8 text-muted-foreground">
                    No jobs yet
                  </div>
                )}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="activity" className="mt-4">
          <Card>
            <CardHeader>
              <CardTitle>Activity Timeline</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {/* Combine proposals and jobs into timeline */}
                {[
                  ...(customer.proposals?.map((p: any) => ({
                    type: 'proposal',
                    date: p.created_at,
                    title: `Proposal ${p.proposal_number} created`,
                    status: p.status,
                    amount: p.total,
                    id: p.id
                  })) || []),
                  ...(customer.jobs?.map((j: any) => ({
                    type: 'job',
                    date: j.created_at,
                    title: `Job ${j.job_number} created`,
                    status: j.status,
                    id: j.id
                  })) || [])
                ]
                  .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
                  .slice(0, 20)
                  .map((activity, index) => (
                    <div key={index} className="flex gap-3">
                      <div className="flex-shrink-0">
                        <div className={`h-8 w-8 rounded-full flex items-center justify-center ${
                          activity.type === 'proposal' ? 'bg-blue-100' : 'bg-green-100'
                        }`}>
                          {activity.type === 'proposal' ? (
                            <FileText className="h-4 w-4 text-blue-600" />
                          ) : (
                            <Briefcase className="h-4 w-4 text-green-600" />
                          )}
                        </div>
                      </div>
                      <div className="flex-1">
                        <div className="font-medium">{activity.title}</div>
                        <div className="text-sm text-muted-foreground">
                          {new Date(activity.date).toLocaleDateString()} at {new Date(activity.date).toLocaleTimeString()}
                        </div>
                        {activity.amount && (
                          <div className="text-sm font-medium mt-1">
                            ${activity.amount.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                          </div>
                        )}
                      </div>
                      <Badge variant="outline">{activity.status}</Badge>
                    </div>
                  ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}
