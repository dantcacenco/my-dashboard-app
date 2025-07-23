'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'
import CustomerSearch from './CustomerSearch'
import ServiceSearch from './ServiceSearch'
import AddNewPricingItem from './AddNewPricingItem'

interface Customer {
  id: string
  name: string
  email: string
  phone: string
  address: string
}

interface PricingItem {
  id: string
  name: string
  description: string
  price: number
  category: string
  unit: string
}

interface ProposalItem {
  id: string
  name: string
  description: string
  quantity: number
  unit_price: number
  total_price: number
  is_addon: boolean
  is_selected: boolean
}

interface ProposalBuilderProps {
  customers: Customer[]
  pricingItems: PricingItem[]
  userId: string
}

export default function ProposalBuilder({ customers: initialCustomers, pricingItems: initialPricingItems, userId }: ProposalBuilderProps) {
  const [customers, setCustomers] = useState(initialCustomers)
  const [pricingItems, setPricingItems] = useState(initialPricingItems)
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null)
  const [proposalTitle, setProposalTitle] = useState('')
  const [proposalDescription, setProposalDescription] = useState('')
  const [proposalItems, setProposalItems] = useState<ProposalItem[]>([])
  const [taxRate, setTaxRate] = useState(0.08) // 8% default tax rate
  const [isLoading, setIsLoading] = useState(false)
  const [showAddItem, setShowAddItem] = useState(false)
  const [showAddNewPricing, setShowAddNewPricing] = useState(false)

  const router = useRouter()
  const supabase = createClient()

  // Calculate totals
  const subtotal = proposalItems
    .filter(item => item.is_selected)
    .reduce((sum, item) => sum + item.total_price, 0)
  const taxAmount = subtotal * taxRate
  const total = subtotal + taxAmount

  // Add new pricing item to the list
  const handleNewPricingItemAdded = (newItem: PricingItem) => {
    setPricingItems([...pricingItems, newItem])
    setShowAddNewPricing(false)
    setShowAddItem(true) // Go back to the service search
  }

  // Add item to proposal
  const addItem = (item: PricingItem, isAddon: boolean) => {
    const newItem: ProposalItem = {
      id: `temp-${Date.now()}`,
      name: item.name,
      description: item.description,
      quantity: 1,
      unit_price: item.price,
      total_price: item.price,
      is_addon: isAddon,
      is_selected: !isAddon // Main items selected by default, add-ons not selected
    }
    setProposalItems([...proposalItems, newItem])
    setShowAddItem(false)
  }

  // Update item quantity
  const updateItemQuantity = (itemId: string, quantity: number) => {
    setProposalItems(proposalItems.map(item =>
      item.id === itemId
        ? { ...item, quantity, total_price: item.unit_price * quantity }
        : item
    ))
  }

  // Remove item
  const removeItem = (itemId: string) => {
    setProposalItems(proposalItems.filter(item => item.id !== itemId))
  }

  // Toggle addon selection
  const toggleAddon = (itemId: string) => {
    setProposalItems(proposalItems.map(item =>
      item.id === itemId
        ? { ...item, is_selected: !item.is_selected }
        : item
    ))
  }

// Save proposal
  const saveProposal = async () => {
    if (!selectedCustomer || !proposalTitle.trim() || proposalItems.length === 0) {
      alert('Please fill in all required fields and add at least one item.')
      return
    }

    setIsLoading(true)

    try {
      // Generate proposal number
      const proposalNumber = `PROP-${Date.now()}`

      // Create proposal
      const { data: proposal, error: proposalError } = await supabase
        .from('proposals')
        .insert({
          proposal_number: proposalNumber,
          customer_id: selectedCustomer.id,
          title: proposalTitle.trim(),
          description: proposalDescription.trim(),
          subtotal,
          tax_rate: taxRate,
          tax_amount: taxAmount,
          total,
          status: 'draft',
          created_by: userId
        })
        .select()
        .single()

      if (proposalError) throw proposalError

      // Create proposal items
      const itemsToInsert = proposalItems.map(item => ({
        proposal_id: proposal.id,
        name: item.name,
        description: item.description,
        quantity: item.quantity,
        unit_price: item.unit_price,
        total_price: item.total_price,
        is_addon: item.is_addon,
        is_selected: item.is_selected
      }))

      const { error: itemsError } = await supabase
        .from('proposal_items')
        .insert(itemsToInsert)

      if (itemsError) throw itemsError

      // Log the creation
      await supabase
        .from('proposal_activities')
        .insert({
          proposal_id: proposal.id,
          activity_type: 'created',
          description: `Proposal created by user`,
          metadata: {
            total_amount: total,
            items_count: proposalItems.length
          }
        })

      router.push(`/proposals/${proposal.id}`)

    } catch (error) {
      console.error('Error saving proposal:', error)
      alert('Error saving proposal. Please try again.')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Create New Proposal</h1>
          <p className="text-gray-600 mt-2">Build a detailed proposal for your customer</p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Main Content */}
          <div className="lg:col-span-2 space-y-6">
            
            {/* Customer Selection */}
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-lg font-medium mb-4">Customer Information</h2>
              {selectedCustomer ? (
                <div className="flex justify-between items-start p-4 bg-blue-50 rounded-lg">
                  <div>
                    <h3 className="font-medium">{selectedCustomer.name}</h3>
                    <p className="text-sm text-gray-600">{selectedCustomer.email}</p>
                    <p className="text-sm text-gray-600">{selectedCustomer.phone}</p>
                    {selectedCustomer.address && (
                      <p className="text-sm text-gray-600">{selectedCustomer.address}</p>
                    )}
                  </div>
                  <button
                    onClick={() => setSelectedCustomer(null)}
                    className="text-blue-600 hover:text-blue-800 text-sm"
                  >
                    Change Customer
                  </button>
                </div>
              ) : (
                <CustomerSearch
                  customers={customers}
                  onCustomerSelect={setSelectedCustomer}
                  onCustomerAdded={(newCustomer) => {
                    setCustomers([...customers, newCustomer])
                    setSelectedCustomer(newCustomer)
                  }}
                  userId={userId}
                />
              )}
            </div>

            {/* Proposal Details */}
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-lg font-medium mb-4">Proposal Details</h2>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Project Title *
                  </label>
                  <input
                    type="text"
                    value={proposalTitle}
                    onChange={(e) => setProposalTitle(e.target.value)}
                    placeholder="e.g., HVAC System Installation"
                    className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Description
                  </label>
                  <textarea
                    value={proposalDescription}
                    onChange={(e) => setProposalDescription(e.target.value)}
                    rows={3}
                    placeholder="Project overview and scope of work..."
                    className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
              </div>
            </div>

            {/* Items Section */}
            <div className="bg-white rounded-lg shadow p-6">
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-lg font-medium">Services & Materials</h2>
                <button
                  onClick={() => setShowAddItem(true)}
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                >
                  Add Item
                </button>
              </div>

              {/* Add New Pricing Item Section */}
              {showAddNewPricing && (
                <AddNewPricingItem
                  onPricingItemAdded={handleNewPricingItemAdded}
                  onCancel={() => {
                    setShowAddNewPricing(false)
                    setShowAddItem(true) // Go back to service search
                  }}
                  userId={userId}
                />
              )}

              {/* Add Item Section */}
              {showAddItem && !showAddNewPricing && (
                <ServiceSearch
                  pricingItems={pricingItems}
                  onAddItem={addItem}
                  onClose={() => setShowAddItem(false)}
                  onShowAddNew={() => {
                    setShowAddItem(false)
                    setShowAddNewPricing(true)
                  }}
                />
              )}

              {/* Current Items */}
              <div className="space-y-3">
                {proposalItems.length === 0 ? (
                  <p className="text-gray-500 text-center py-8">No items added yet. Click Add Item to get started.</p>
                ) : (
                  <>
                    {/* Main Services */}
                    <div className="space-y-3">
                      <h4 className="font-medium text-gray-900">Services & Materials:</h4>
                      {proposalItems.filter(item => !item.is_addon).map(item => (
                        <div key={item.id} className="border rounded-lg p-4 border-gray-200">
                          <div className="flex justify-between items-start">
                            <div className="flex-1">
                              <h4 className="font-medium">{item.name}</h4>
                              <p className="text-sm text-gray-600 mt-1">{item.description}</p>
                              
                              <div className="flex items-center gap-4 mt-2">
                                <div className="flex items-center gap-2">
                                  <label className="text-sm">Qty:</label>
                                  <input
                                    type="number"
                                    min="1"
                                    value={item.quantity}
                                    onChange={(e) => updateItemQuantity(item.id, parseInt(e.target.value) || 1)}
                                    className="w-16 p-1 border border-gray-300 rounded text-sm"
                                  />
                                </div>
                                <span className="text-sm">@ ${item.unit_price.toFixed(2)}</span>
                                <span className="font-bold text-green-600">${item.total_price.toFixed(2)}</span>
                              </div>
                            </div>
                            
                            <button
                              onClick={() => removeItem(item.id)}
                              className="text-red-600 hover:text-red-800 ml-4"
                            >
                              Remove
                            </button>
                          </div>
                        </div>
                      ))}
                    </div>

                    {/* Add-ons */}
                    {proposalItems.filter(item => item.is_addon).length > 0 && (
                      <div className="space-y-3 mt-6">
                        <h4 className="font-medium text-gray-900">Add-ons:</h4>
                        {proposalItems.filter(item => item.is_addon).map(item => (
                          <div key={item.id} className="border rounded-lg p-4 border-orange-200 bg-orange-50">
                            <div className="flex justify-between items-start">
                              <div className="flex-1">
                                <div className="flex items-center gap-2">
                                  <input
                                    type="checkbox"
                                    checked={item.is_selected}
                                    onChange={() => toggleAddon(item.id)}
                                    className="w-4 h-4"
                                  />
                                  <h4 className="font-medium">{item.name}</h4>
                                  <span className="text-xs bg-orange-200 px-2 py-1 rounded">Add-on</span>
                                </div>
                                <p className="text-sm text-gray-600 mt-1 ml-6">{item.description}</p>
                                
                                <div className="flex items-center gap-4 mt-2 ml-6">
                                  <div className="flex items-center gap-2">
                                    <label className="text-sm">Qty:</label>
                                    <input
                                      type="number"
                                      min="1"
                                      value={item.quantity}
                                      onChange={(e) => updateItemQuantity(item.id, parseInt(e.target.value) || 1)}
                                      className="w-16 p-1 border border-gray-300 rounded text-sm"
                                    />
                                  </div>
                                  <span className="text-sm">@ ${item.unit_price.toFixed(2)}</span>
                                  <span className="font-bold text-green-600">${item.total_price.toFixed(2)}</span>
                                </div>
                              </div>
                              
                              <button
                                onClick={() => removeItem(item.id)}
                                className="text-red-600 hover:text-red-800 ml-4"
                              >
                                Remove
                              </button>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </>
                )}
              </div>
            </div>
          </div>

          {/* Sidebar */}
          <div className="space-y-6">
            {/* Totals */}
            <div className="bg-white rounded-lg shadow p-6">
              <h3 className="font-medium text-gray-900 mb-4">Proposal Total</h3>
              <div className="space-y-3">
                <div className="flex justify-between">
                  <span>Subtotal:</span>
                  <span>${subtotal.toFixed(2)}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span>Tax:</span>
                  <div className="flex items-center gap-2">
                    <input
                      type="number"
                      step="0.01"
                      min="0"
                      max="1"
                      value={taxRate}
                      onChange={(e) => setTaxRate(parseFloat(e.target.value) || 0)}
                      className="w-16 p-1 text-xs border border-gray-300 rounded"
                    />
                    <span className="text-sm">({(taxRate * 100).toFixed(1)}%)</span>
                  </div>
                </div>
                <div className="flex justify-between">
                  <span>Tax Amount:</span>
                  <span>${taxAmount.toFixed(2)}</span>
                </div>
                <div className="border-t pt-3 flex justify-between font-bold text-lg">
                  <span>Total:</span>
                  <span className="text-green-600">${total.toFixed(2)}</span>
                </div>
              </div>
            </div>

            {/* Actions */}
            <div className="bg-white rounded-lg shadow p-6">
              <h3 className="font-medium text-gray-900 mb-4">Actions</h3>
              <div className="space-y-3">
                <button
                  onClick={saveProposal}
                  disabled={isLoading || !selectedCustomer || !proposalTitle.trim() || proposalItems.length === 0}
                  className="w-full px-4 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400 font-medium"
                >
                  {isLoading ? 'Saving...' : 'Save Proposal'}
                </button>
                <button
                  onClick={() => router.push('/proposals')}
                  className="w-full px-4 py-2 text-blue-600 hover:text-blue-800 text-sm"
                >
                  ← Back to Proposals
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}