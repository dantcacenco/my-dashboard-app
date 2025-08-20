#!/bin/bash
set -e

echo "🔧 Fixing multiple issues: Add Customer, Send Proposal, and Add-ons calculation..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# 1. Create AddCustomerModal component
echo "📦 Creating AddCustomerModal component..."
cat > app/\(authenticated\)/customers/AddCustomerModal.tsx << 'EOF'
'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { X } from 'lucide-react'

interface AddCustomerModalProps {
  isOpen: boolean
  onClose: () => void
  onCustomerAdded: (customer: any) => void
  userId: string
}

export default function AddCustomerModal({ isOpen, onClose, onCustomerAdded, userId }: AddCustomerModalProps) {
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [phone, setPhone] = useState('')
  const [address, setAddress] = useState('')
  const [notes, setNotes] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')

  const supabase = createClient()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!name.trim()) {
      setError('Customer name is required')
      return
    }

    setIsLoading(true)
    setError('')

    try {
      const { data, error: insertError } = await supabase
        .from('customers')
        .insert({
          name: name.trim(),
          email: email.trim() || null,
          phone: phone.trim() || null,
          address: address.trim() || null,
          notes: notes.trim() || null,
          created_by: userId,
          updated_by: userId
        })
        .select()
        .single()

      if (insertError) throw insertError

      onCustomerAdded(data)
      
      // Reset form
      setName('')
      setEmail('')
      setPhone('')
      setAddress('')
      setNotes('')
      
      onClose()
    } catch (err: any) {
      console.error('Error adding customer:', err)
      setError(err.message || 'Failed to add customer')
    } finally {
      setIsLoading(false)
    }
  }

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 w-full max-w-md">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-semibold">Add New Customer</h2>
          <button
            onClick={onClose}
            className="text-gray-500 hover:text-gray-700"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {error && (
          <div className="mb-4 p-3 bg-red-50 border border-red-200 text-red-700 rounded">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Name *
            </label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
              placeholder="John Doe"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Email
            </label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
              placeholder="john@example.com"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Phone
            </label>
            <input
              type="tel"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
              placeholder="(555) 123-4567"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Address
            </label>
            <input
              type="text"
              value={address}
              onChange={(e) => setAddress(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
              placeholder="123 Main St, City, State ZIP"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Notes
            </label>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              rows={3}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
              placeholder="Additional notes..."
            />
          </div>

          <div className="flex gap-3">
            <button
              type="submit"
              disabled={isLoading}
              className="flex-1 py-2 px-4 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              {isLoading ? 'Adding...' : 'Add Customer'}
            </button>
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50"
            >
              Cancel
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
EOF

# 2. Update Customers page to use the modal
echo "📝 Updating customers page..."
cat > app/\(authenticated\)/customers/page.tsx << 'EOF'
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
EOF

# 3. Fix ProposalView - remove debug, fix Send button, fix add-ons calculation
echo "🔨 Fixing ProposalView component..."
cat > app/\(authenticated\)/proposals/\[id\]/ProposalView.tsx << 'EOF'
'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Edit, Send, FileText, DollarSign, Calendar, User, MapPin, Phone, Mail } from 'lucide-react'
import CreateJobModal from './CreateJobModal'
import SendProposal from './SendProposal'

interface ProposalViewProps {
  proposal: any
  userRole: string | null
  userId: string
}

export default function ProposalView({ proposal, userRole, userId }: ProposalViewProps) {
  const router = useRouter()
  const [showCreateJobModal, setShowCreateJobModal] = useState(false)
  const [showSendModal, setShowSendModal] = useState(false)

  const handleEdit = () => {
    router.push(`/proposals/${proposal.id}/edit`)
  }

  const handleSendComplete = () => {
    setShowSendModal(false)
    router.refresh()
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'draft': return 'bg-gray-100 text-gray-800'
      case 'sent': return 'bg-blue-100 text-blue-800'
      case 'accepted': return 'bg-green-100 text-green-800'
      case 'rejected': return 'bg-red-100 text-red-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  // Calculate totals - only count selected add-ons
  const services = proposal.proposal_items?.filter((item: any) => !item.is_addon) || []
  const addons = proposal.proposal_items?.filter((item: any) => item.is_addon) || []
  
  // Services are always included, add-ons only if selected
  const subtotal = services.reduce((sum: number, item: any) => sum + (item.total_price || 0), 0) +
                   addons.filter((item: any) => item.is_selected).reduce((sum: number, item: any) => sum + (item.total_price || 0), 0)
  
  const taxAmount = subtotal * (proposal.tax_rate || 0)
  const total = subtotal + taxAmount

  // Customer view URL
  const customerViewUrl = proposal.customer_view_token 
    ? `${window.location.origin}/proposal/view/${proposal.customer_view_token}`
    : null

  return (
    <div className="p-6">
      {/* Header */}
      <div className="flex justify-between items-start mb-6">
        <div>
          <h1 className="text-3xl font-bold">Proposal #{proposal.proposal_number}</h1>
          <p className="text-muted-foreground mt-1">{proposal.title}</p>
        </div>
        
        <div className="flex items-center gap-4">
          <span className={`px-3 py-1 rounded-full text-sm font-semibold ${getStatusColor(proposal.status)}`}>
            {proposal.status.charAt(0).toUpperCase() + proposal.status.slice(1)}
          </span>
          
          <div className="flex gap-2">
            {proposal.status === 'draft' && (
              <>
                <Button onClick={handleEdit} variant="outline">
                  <Edit className="h-4 w-4 mr-2" />
                  Edit
                </Button>
                <Button onClick={() => setShowSendModal(true)}>
                  <Send className="h-4 w-4 mr-2" />
                  Send Proposal
                </Button>
              </>
            )}
            {proposal.status === 'sent' && userRole === 'boss' && (
              <Button onClick={() => setShowCreateJobModal(true)} variant="default">
                <FileText className="h-4 w-4 mr-2" />
                Create Job
              </Button>
            )}
            {proposal.status === 'accepted' && !proposal.job_created && (
              <Button onClick={() => setShowCreateJobModal(true)} variant="default">
                <FileText className="h-4 w-4 mr-2" />
                Create Job
              </Button>
            )}
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Content */}
        <div className="lg:col-span-2 space-y-6">
          {/* Customer Info */}
          <Card>
            <CardHeader>
              <CardTitle>Customer Information</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="flex items-center gap-2">
                  <User className="h-4 w-4 text-gray-500" />
                  <span>{proposal.customers?.name || 'No customer'}</span>
                </div>
                <div className="flex items-center gap-2">
                  <Mail className="h-4 w-4 text-gray-500" />
                  <span>{proposal.customers?.email || '-'}</span>
                </div>
                <div className="flex items-center gap-2">
                  <Phone className="h-4 w-4 text-gray-500" />
                  <span>{proposal.customers?.phone || '-'}</span>
                </div>
                <div className="flex items-center gap-2">
                  <MapPin className="h-4 w-4 text-gray-500" />
                  <span>{proposal.customers?.address || '-'}</span>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Services */}
          {services.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle>Services</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {services.map((item: any) => (
                    <div key={item.id} className="border rounded-lg p-4 bg-gray-50">
                      <div className="flex justify-between items-start">
                        <div>
                          <h4 className="font-medium">{item.name}</h4>
                          <p className="text-sm text-gray-600 mt-1">{item.description}</p>
                          <div className="text-sm text-gray-500 mt-2">
                            Qty: {item.quantity} @ ${item.unit_price?.toFixed(2)}
                          </div>
                        </div>
                        <div className="text-right">
                          <div className="font-bold text-green-600">
                            ${item.total_price?.toFixed(2)}
                          </div>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Add-ons */}
          {addons.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle>Optional Add-ons</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {addons.map((item: any) => (
                    <div key={item.id} className={`border rounded-lg p-4 ${item.is_selected ? 'bg-orange-50 border-orange-200' : 'bg-gray-50 opacity-60'}`}>
                      <div className="flex justify-between items-start">
                        <div>
                          <div className="flex items-center gap-2">
                            <input
                              type="checkbox"
                              checked={item.is_selected}
                              disabled
                              className="w-4 h-4"
                            />
                            <h4 className="font-medium">{item.name}</h4>
                            <Badge variant="secondary" className="bg-orange-200 text-orange-800">Add-on</Badge>
                          </div>
                          <p className="text-sm text-gray-600 mt-1 ml-6">{item.description}</p>
                          <div className="text-sm text-gray-500 mt-2 ml-6">
                            Qty: {item.quantity} @ ${item.unit_price?.toFixed(2)}
                          </div>
                        </div>
                        <div className="text-right">
                          <div className={`font-bold ${item.is_selected ? 'text-green-600' : 'text-gray-400'}`}>
                            ${item.total_price?.toFixed(2)}
                          </div>
                          {!item.is_selected && (
                            <div className="text-xs text-gray-500">Not selected</div>
                          )}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
                <div className="mt-4 p-3 bg-blue-50 rounded text-sm text-blue-700">
                  Note: Add-ons will only be included in the total when selected by the customer
                </div>
              </CardContent>
            </Card>
          )}
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Totals */}
          <Card>
            <CardHeader>
              <CardTitle>Proposal Summary</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                <div className="flex justify-between">
                  <span>Services Subtotal:</span>
                  <span>${services.reduce((sum: number, item: any) => sum + (item.total_price || 0), 0).toFixed(2)}</span>
                </div>
                {addons.filter((item: any) => item.is_selected).length > 0 && (
                  <div className="flex justify-between text-orange-600">
                    <span>Selected Add-ons:</span>
                    <span>+${addons.filter((item: any) => item.is_selected).reduce((sum: number, item: any) => sum + (item.total_price || 0), 0).toFixed(2)}</span>
                  </div>
                )}
                <div className="flex justify-between font-medium">
                  <span>Subtotal:</span>
                  <span>${subtotal.toFixed(2)}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span>Tax ({(proposal.tax_rate * 100).toFixed(1)}%):</span>
                  <span>${taxAmount.toFixed(2)}</span>
                </div>
                <div className="flex justify-between font-bold text-lg border-t pt-3">
                  <span>Total:</span>
                  <span className="text-green-600">${total.toFixed(2)}</span>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Customer View Link */}
          {customerViewUrl && proposal.status !== 'draft' && (
            <Card>
              <CardHeader>
                <CardTitle>Customer Access</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  <p className="text-sm text-gray-600">
                    Customer can view this proposal at:
                  </p>
                  <div className="p-2 bg-gray-50 rounded break-all">
                    <a 
                      href={customerViewUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-blue-600 hover:text-blue-800 text-sm"
                    >
                      {customerViewUrl}
                    </a>
                  </div>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Dates */}
          <Card>
            <CardHeader>
              <CardTitle>Timeline</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-gray-500">Created:</span>
                  <span>{new Date(proposal.created_at).toLocaleDateString()}</span>
                </div>
                {proposal.sent_date && (
                  <div className="flex justify-between">
                    <span className="text-gray-500">Sent:</span>
                    <span>{new Date(proposal.sent_date).toLocaleDateString()}</span>
                  </div>
                )}
                {proposal.valid_until && (
                  <div className="flex justify-between">
                    <span className="text-gray-500">Valid Until:</span>
                    <span>{new Date(proposal.valid_until).toLocaleDateString()}</span>
                  </div>
                )}
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Modals */}
      {showSendModal && (
        <SendProposal
          proposalId={proposal.id}
          proposalNumber={proposal.proposal_number}
          customer={proposal.customers}
          total={total}
          onSent={handleSendComplete}
          onCancel={() => setShowSendModal(false)}
        />
      )}

      {showCreateJobModal && (
        <CreateJobModal
          proposal={proposal}
          onClose={() => setShowCreateJobModal(false)}
          onJobCreated={() => {
            setShowCreateJobModal(false)
            router.push('/jobs')
          }}
        />
      )}
    </div>
  )
}
EOF

echo "✅ All components created/updated"

# Test TypeScript
echo "🔍 Checking TypeScript..."
npx tsc --noEmit 2>&1 | head -20

# Test build
echo "🏗️ Testing build..."
npm run build 2>&1 | head -40

# Commit changes
echo "📦 Committing changes..."
git add -A
git commit -m "Fix multiple issues: Add Customer modal, Send Proposal, and add-ons calculation

- Created AddCustomerModal component with all required fields
- Updated Customers page to use the modal (converted to client component)
- Fixed Send Proposal button to use modal instead of non-existent route
- Removed debug code from ProposalView
- Fixed add-ons calculation: only count selected add-ons in subtotal
- Added visual distinction for selected vs unselected add-ons
- Added note explaining add-on selection behavior"

git push origin main

echo "✅ All fixes deployed!"
echo ""
echo "🎯 COMPLETED:"
echo "1. ✅ Add Customer modal now functional"
echo "2. ✅ Send Proposal button fixed (uses modal, not route)"
echo "3. ✅ Debug code removed from proposal view"
echo "4. ✅ Add-ons only count toward subtotal when selected"
echo ""
echo "📝 HOW IT WORKS NOW:"
echo "- Add Customer button opens modal with name, email, phone, address, notes"
echo "- Send Proposal opens email modal with Stripe payment link generation"
echo "- Add-ons show as 'Not selected' by default"
echo "- Only selected add-ons count in the subtotal"
echo "- Customer can select add-ons when viewing proposal"
