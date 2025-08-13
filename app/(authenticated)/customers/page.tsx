import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import Link from 'next/link'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Plus, Search, Users } from 'lucide-react'

export const metadata = {
  title: 'Customers | Service Pro',
}

export default async function CustomersPage() {
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/login')

  // Get all customers with their proposals and jobs
  const { data: customers, error } = await supabase
    .from('customers')
    .select(`
      *,
      proposals (
        id,
        total,
        status,
        total_paid
      ),
      jobs (
        id,
        status
      )
    `)
    .order('name', { ascending: true })

  if (error) {
    console.error('Error fetching customers:', error)
  }

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-3xl font-bold">Customers</h1>
          <p className="text-muted-foreground">Manage your customer relationships</p>
        </div>
        <Button>
          <Plus className="h-4 w-4 mr-2" />
          Add Customer
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Users className="h-5 w-5" />
            All Customers ({customers?.length || 0})
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b">
                  <th className="text-left py-3 px-4">Name</th>
                  <th className="text-left py-3 px-4">Contact</th>
                  <th className="text-center py-3 px-4">Proposals</th>
                  <th className="text-center py-3 px-4">Jobs</th>
                  <th className="text-right py-3 px-4">Total Revenue</th>
                  <th className="text-right py-3 px-4">Paid</th>
                </tr>
              </thead>
              <tbody>
                {customers?.map((customer) => {
                  const totalRevenue = customer.proposals?.reduce((sum: number, p: any) => sum + (p.total || 0), 0) || 0
                  const totalPaid = customer.proposals?.reduce((sum: number, p: any) => sum + (p.total_paid || 0), 0) || 0
                  const activeJobs = customer.jobs?.filter((j: any) => j.status !== 'completed').length || 0
                  
                  return (
                    <tr 
                      key={customer.id} 
                      className="border-b hover:bg-gray-50 cursor-pointer transition-colors"
                    >
                      <td className="py-3 px-4">
                        <Link 
                          href={`/customers/${customer.id}`}
                          className="font-medium text-blue-600 hover:text-blue-800"
                        >
                          {customer.name}
                        </Link>
                      </td>
                      <td className="py-3 px-4 text-sm">
                        <div>{customer.email || '-'}</div>
                        <div className="text-muted-foreground">{customer.phone || '-'}</div>
                      </td>
                      <td className="py-3 px-4 text-center">
                        <Badge variant="secondary">{customer.proposals?.length || 0}</Badge>
                      </td>
                      <td className="py-3 px-4 text-center">
                        <Badge variant={activeJobs > 0 ? "default" : "secondary"}>
                          {customer.jobs?.length || 0}
                        </Badge>
                      </td>
                      <td className="py-3 px-4 text-right font-medium">
                        ${totalRevenue.toFixed(2)}
                      </td>
                      <td className="py-3 px-4 text-right text-green-600 font-medium">
                        ${totalPaid.toFixed(2)}
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
            {(!customers || customers.length === 0) && (
              <div className="text-center py-8 text-muted-foreground">
                No customers found
              </div>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
