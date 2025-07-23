'use client'

import { useState, useRef } from 'react'
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
  selectedCustomer: string
  onCustomerSelect: (customerId: string) => void
  onCustomersUpdate: (customers: Customer[]) => void
  userId: string
}

export default function CustomerSearch({ 
  customers, 
  selectedCustomer, 
  onCustomerSelect, 
  onCustomersUpdate,
  userId 
}: CustomerSearchProps) {
  const [searchTerm, setSearchTerm] = useState('')
  const [showDropdown, setShowDropdown] = useState(false)
  const [showAddForm, setShowAddForm] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  
  // New customer form state
  const [newCustomer, setNewCustomer] = useState({
    name: '',
    email: '',
    phone: '',
    address: ''
  })

  const supabase = createClient()

  // Get display name for selected customer
  const getSelectedCustomerName = () => {
    if (selectedCustomer) {
      const customer = customers.find(c => c.id === selectedCustomer)
      return customer ? customer.name : ''
    }
    return searchTerm
  }

  // Filter customers based on search term
  const getFilteredCustomers = () => {
    if (searchTerm.trim() === '') {
      return customers.slice(0, 4)
    }
    
    return customers
      .filter(customer => 
        customer.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        customer.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
        customer.phone.includes(searchTerm)
      )
      .slice(0, 4)
  }

  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value
    setSearchTerm(value)
    setShowDropdown(true)
    setShowAddForm(false)
    
    // Clear selection if search changes
    if (selectedCustomer) {
      onCustomerSelect('')
    }
  }

  const handleSearchFocus = () => {
    setShowDropdown(true)
    // If there's a selected customer, show their name in search
    if (selectedCustomer && !searchTerm) {
      const customer = customers.find(c => c.id === selectedCustomer)
      if (customer) {
        setSearchTerm(customer.name)
      }
    }
  }

  const handleCustomerSelect = (customer: Customer) => {
    setSearchTerm(customer.name)
    onCustomerSelect(customer.id)
    setShowDropdown(false)
    setShowAddForm(false)
  }

  const handleAddNewClick = () => {
    setShowAddForm(true)
    setShowDropdown(false)
    setNewCustomer({ ...newCustomer, name: searchTerm })
  }

  const handleAddCustomer = async () => {
    if (!newCustomer.name.trim() || !newCustomer.email.trim()) {
      alert('Name and email are required')
      return
    }

    setIsLoading(true)
    
    try {
      const { data, error } = await supabase
        .from('customers')
        .insert({
          name: newCustomer.name.trim(),
          email: newCustomer.email.trim(),
          phone: newCustomer.phone.trim(),
          address: newCustomer.address.trim(),
          created_by: userId
        })
        .select()
        .single()

      if (error) throw error

      // Update the customers list
      const updatedCustomers = [...customers, data]
      onCustomersUpdate(updatedCustomers)
      
      // Select the new customer
      handleCustomerSelect(data)
      
      // Reset form
      setNewCustomer({ name: '', email: '', phone: '', address: '' })
      setShowAddForm(false)
      
    } catch (error) {
      console.error('Error adding customer:', error)
      alert('Error adding customer. Please try again.')
    } finally {
      setIsLoading(false)
    }
  }

  const handleCancelAdd = () => {
    setShowAddForm(false)
    setNewCustomer({ name: '', email: '', phone: '', address: '' })
  }

  const handleClickOutside = () => {
    setShowDropdown(false)
    setShowAddForm(false)
  }

  const filteredCustomers = getFilteredCustomers()

  return (
    <div className="relative">
      <label className="block text-sm font-medium text-gray-700 mb-1">
        Customer *
      </label>
      
      {/* Search Input */}
      <input
        type="text"
        value={getSelectedCustomerName()}
        onChange={handleSearchChange}
        onFocus={handleSearchFocus}
        onBlur={() => setTimeout(handleClickOutside, 150)} // Delay to allow clicks
        placeholder="Search customers..."
        className="w-full p-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
        required
      />

      {/* Dropdown Results */}
      {showDropdown && (
        <div className="absolute z-10 w-full mt-1 bg-white border border-gray-300 rounded-md shadow-lg max-h-64 overflow-y-auto">
          {filteredCustomers.map(customer => (
            <div
              key={customer.id}
              onClick={() => handleCustomerSelect(customer)}
              className="p-3 hover:bg-gray-50 cursor-pointer border-b border-gray-100"
            >
              <div className="font-medium text-gray-900">{customer.name}</div>
              <div className="text-sm text-gray-600">{customer.email}</div>
              <div className="text-xs text-gray-500">{customer.phone}</div>
            </div>
          ))}
          
          {/* Add New Customer Option */}
          <div
            onClick={handleAddNewClick}
            className="p-3 hover:bg-blue-50 cursor-pointer flex items-center text-blue-600 font-medium"
          >
            <svg className="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
            </svg>
            Add New Customer
          </div>
          
          {filteredCustomers.length === 0 && searchTerm && (
            <div className="p-3 text-gray-500 text-sm">
              No customers found matching "{searchTerm}"
            </div>
          )}
        </div>
      )}

      {/* Add Customer Form */}
      {showAddForm && (
        <div className="absolute z-20 w-full mt-1 bg-white border border-gray-300 rounded-md shadow-lg p-4">
          <h3 className="font-medium text-gray-900 mb-3">Add New Customer</h3>
          
          <div className="space-y-3">
            <div>
              <label className="block text-xs font-medium text-gray-700 mb-1">Name *</label>
              <input
                type="text"
                value={newCustomer.name}
                onChange={(e) => setNewCustomer({ ...newCustomer, name: e.target.value })}
                className="w-full p-2 text-sm border border-gray-300 rounded focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
                placeholder="Customer name"
              />
            </div>
            
            <div>
              <label className="block text-xs font-medium text-gray-700 mb-1">Email *</label>
              <input
                type="email"
                value={newCustomer.email}
                onChange={(e) => setNewCustomer({ ...newCustomer, email: e.target.value })}
                className="w-full p-2 text-sm border border-gray-300 rounded focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
                placeholder="customer@email.com"
              />
            </div>
            
            <div>
              <label className="block text-xs font-medium text-gray-700 mb-1">Phone</label>
              <input
                type="tel"
                value={newCustomer.phone}
                onChange={(e) => setNewCustomer({ ...newCustomer, phone: e.target.value })}
                className="w-full p-2 text-sm border border-gray-300 rounded focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
                placeholder="555-1234"
              />
            </div>
            
            <div>
              <label className="block text-xs font-medium text-gray-700 mb-1">Address</label>
              <textarea
                value={newCustomer.address}
                onChange={(e) => setNewCustomer({ ...newCustomer, address: e.target.value })}
                className="w-full p-2 text-sm border border-gray-300 rounded focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
                placeholder="123 Main St, City, State"
                rows={2}
              />
            </div>
          </div>
          
          <div className="flex gap-2 mt-4">
            <button
              onClick={handleAddCustomer}
              disabled={isLoading}
              className="flex-1 px-3 py-2 text-sm bg-blue-600 text-white rounded hover:bg-blue-700 disabled:bg-gray-400"
            >
              {isLoading ? 'Adding...' : 'Add Customer'}
            </button>
            <button
              onClick={handleCancelAdd}
              className="px-3 py-2 text-sm border border-gray-300 text-gray-700 rounded hover:bg-gray-50"
            >
              Cancel
            </button>
          </div>
        </div>
      )}
    </div>
  )
}