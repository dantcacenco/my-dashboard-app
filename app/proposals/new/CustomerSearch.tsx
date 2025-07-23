'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'

interface Customer {
  id: string
  name: string
  email: string
  phone: string
  address: string
}

interface CustomerSearchProps {
  customers: Customer[]
  onCustomerSelect: (customer: Customer) => void
  onCustomerAdded: (customer: Customer) => void
  userId: string
}

export default function CustomerSearch({ customers, onCustomerSelect, onCustomerAdded, userId }: CustomerSearchProps) {
  const [searchTerm, setSearchTerm] = useState('')
  const [showAddNew, setShowAddNew] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [newCustomer, setNewCustomer] = useState({
    name: '',
    email: '',
    phone: '',
    address: ''
  })

  const supabase = createClient()

  // Filter customers based on search term
  const filteredCustomers = customers.filter(customer =>
    customer.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    customer.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
    customer.phone.includes(searchTerm)
  )

  const handleAddNewCustomer = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!newCustomer.name.trim() || !newCustomer.email.trim() || !newCustomer.phone.trim()) {
      alert('Please fill in name, email, and phone number')
      return
    }

    setIsLoading(true)

    try {
      const { data, error } = await supabase
        .from('customers')
        .insert({
          name: newCustomer.name.trim(),
          email: newCustomer.email.trim().toLowerCase(),
          phone: newCustomer.phone.trim(),
          address: newCustomer.address.trim(),
          created_by: userId
        })
        .select()
        .single()

      if (error) throw error

      // Call the callback to add the customer to the list
      onCustomerAdded(data)
      
      // Reset form
      setNewCustomer({
        name: '',
        email: '',
        phone: '',
        address: ''
      })
      setShowAddNew(false)
      
    } catch (error) {
      console.error('Error adding customer:', error)
      alert('Error adding customer. Please try again.')
    } finally {
      setIsLoading(false)
    }
  }

  const handleCancel = () => {
    setNewCustomer({
      name: '',
      email: '',
      phone: '',
      address: ''
    })
    setShowAddNew(false)
  }

  if (showAddNew) {
    return (
      <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-medium text-blue-900">Add New Customer</h3>
          <button
            onClick={handleCancel}
            className="text-gray-400 hover:text-gray-600"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <form onSubmit={handleAddNewCustomer} className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Name *
              </label>
              <input
                type="text"
                value={newCustomer.name}
                onChange={(e) => setNewCustomer({ ...newCustomer, name: e.target.value })}
                placeholder="John Smith"
                className="w-full p-2 border border-gray-300 rounded focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Email *
              </label>
              <input
                type="email"
                value={newCustomer.email}
                onChange={(e) => setNewCustomer({ ...newCustomer, email: e.target.value })}
                placeholder="john@example.com"
                className="w-full p-2 border border-gray-300 rounded focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                required
              />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Phone *
              </label>
              <input
                type="tel"
                value={newCustomer.phone}
                onChange={(e) => setNewCustomer({ ...newCustomer, phone: e.target.value })}
                placeholder="(555) 123-4567"
                className="w-full p-2 border border-gray-300 rounded focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Address
              </label>
              <input
                type="text"
                value={newCustomer.address}
                onChange={(e) => setNewCustomer({ ...newCustomer, address: e.target.value })}
                placeholder="123 Main St, City, State 12345"
                className="w-full p-2 border border-gray-300 rounded focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              />
            </div>
          </div>

          <div className="flex gap-3 pt-4">
            <button
              type="submit"
              disabled={isLoading}
              className="flex-1 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:bg-gray-400"
            >
              {isLoading ? 'Adding...' : 'Add Customer'}
            </button>
            <button
              type="button"
              onClick={handleCancel}
              className="px-4 py-2 border border-gray-300 text-gray-700 rounded hover:bg-gray-50"
            >
              Cancel
            </button>
          </div>
        </form>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex gap-3">
        <input
          type="text"
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          placeholder="Search customers by name, email, or phone..."
          className="flex-1 p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
        />
        <button
          onClick={() => setShowAddNew(true)}
          className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 whitespace-nowrap"
        >
          Add New
        </button>
      </div>

      {searchTerm && (
        <div className="space-y-2 max-h-48 overflow-y-auto">
          {filteredCustomers.length > 0 ? (
            filteredCustomers.map((customer) => (
              <div
                key={customer.id}
                onClick={() => onCustomerSelect(customer)}
                className="p-3 border border-gray-200 rounded-lg hover:bg-gray-50 cursor-pointer"
              >
                <div className="font-medium">{customer.name}</div>
                <div className="text-sm text-gray-600">{customer.email}</div>
                <div className="text-sm text-gray-500">{customer.phone}</div>
                {customer.address && (
                  <div className="text-sm text-gray-500">{customer.address}</div>
                )}
              </div>
            ))
          ) : (
            <div className="p-4 text-center text-gray-500">
              No customers found. Try a different search term or add a new customer.
            </div>
          )}
        </div>
      )}

      {!searchTerm && (
        <div className="text-center text-gray-500 py-8">
          Start typing to search for existing customers or click "Add New" to create one.
        </div>
      )}
    </div>
  )
}