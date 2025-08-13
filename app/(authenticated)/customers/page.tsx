import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import Link from 'next/link'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Plus, Search } from 'lucide-react'

export const metadata = {
  title: 'Customers | Service Pro',
}

export default async function CustomersPage() {
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/login')

  // Get customers with job and proposal counts
  const { data: customers, error } = await supabase
    .from('customers')
    .select(`
      *,
      jobs:jobs(count),
      proposals:proposals(count, total)
    `)
    .order('created_at', { ascending: false })

  if (error) {
    console.error('Error fetching customers:', error)
  }

  // Calculate totals for each customer
  const customersWithTotals = customers?.map(customer => {
    const totalRevenue = customer.proposals?.reduce((sum: number, proposal: any) => {
      return sum + (proposal.total || 0)
    }, 0) || 0

    return {
      ...customer,
      totalJobs: customer.jobs?.[0]?.count || 0,
      totalProposals: customer.proposals?.[0]?.count || 0,
      totalRevenue
    }
  }) || []

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

      {/* Search bar */}
      <div className="mb-6">
        <div className="relative max-w-md">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground h-4 w-4" />
          <input
            type="text"
            placeholder="Search customers..."
            className="w-full pl-10 pr-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
      </div>

      {/* Customers list */}
      <Card>
        <CardHeader>
          <CardTitle>All Customers</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b">
                  <th className="text-left py-3 px-4">Name</th>
                  <th className="text-left py-3 px-4">Email</th>
                  <th className="text-left py-3 px-4">Phone</th>
                  <th className="text-center py-3 px-4">Jobs</th>
                  <th className="text-center py-3 px-4">Proposals</th>
                  <th className="text-right py-3 px-4">Total Revenue</th>
                </tr>
              </thead>
              <tbody>
                {customersWithTotals.map((customer) => (
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
                    <td className="py-3 px-4 text-muted-foreground">
                      {customer.email || '-'}
                    </td>
                    <td className="py-3 px-4 text-muted-foreground">
                      {customer.phone || '-'}
                    </td>
                    <td className="py-3 px-4 text-center">
                      <Badge variant="secondary">{customer.totalJobs}</Badge>
                    </td>
                    <td className="py-3 px-4 text-center">
                      <Badge variant="secondary">{customer.totalProposals}</Badge>
                    </td>
                    <td className="py-3 px-4 text-right font-medium">
                      ${customer.totalRevenue.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {customersWithTotals.length === 0 && (
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
