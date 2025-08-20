'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Plus, Search, Users } from 'lucide-react'
import AddCustomerModal from './AddCustomerModal'

export default function CustomersPage() {
  const [customers, setCustomers] = useState<any[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [showAddModal, setShowAddModal] = useState(false)
  const [userId, setUserId] = useState<string>('')
  
  const supabase = createClient()
  const router = useRouter()

  useEffect(() => {
    checkAuth()
    fetchCustomers()
  }, [])

  const checkAuth = async () => {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      router.push('/auth/login')
    } else {
      setUserId(user.id)
    }
  }

  const fetchCustomers = async () => {
    setIsLoading(true)
    try {
      const { data, error } = await supabase
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

      if (error) throw error
      setCustomers(data || [])
    } catch (error) {
      console.error('Error fetching customers:', error)
    } finally {
      setIsLoading(false)
    }
  }

  const handleCustomerAdded = (newCustomer: any) => {
    setCustomers([...customers, newCustomer])
    setShowAddModal(false)
  }

  if (isLoading) {
    return (
      <div className="p-6 flex justify-center items-center">
        <div className="text-gray-500">Loading customers...</div>
      </div>
    )
  }

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-3xl font-bold">Customers</h1>
          <p className="text-muted-foreground">Manage your customer relationships</p>
        </div>
        <Button onClick={() => setShowAddModal(true)}>
          <Plus className="h-4 w-4 mr-2" />
          Add Customer
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Users className="h-5 w-5" />
            All Customers ({customers.length})
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
                {customers.map((customer) => {
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
                        {activeJobs > 0 && (
                          <Badge variant="default">{activeJobs} active</Badge>
                        )}
                        {customer.jobs?.length > 0 && (
                          <span className="text-sm text-gray-500 ml-2">
                            ({customer.jobs.length} total)
                          </span>
                        )}
                      </td>
                      <td className="py-3 px-4 text-right font-medium">
                        ${totalRevenue.toFixed(2)}
                      </td>
                      <td className="py-3 px-4 text-right">
                        <span className={totalPaid > 0 ? 'text-green-600' : 'text-gray-400'}>
                          ${totalPaid.toFixed(2)}
                        </span>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
            
            {customers.length === 0 && (
              <div className="text-center py-8 text-gray-500">
                No customers yet. Click "Add Customer" to get started.
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      <AddCustomerModal
        isOpen={showAddModal}
        onClose={() => setShowAddModal(false)}
        onCustomerAdded={handleCustomerAdded}
        userId={userId}
      />
    </div>
  )
}
