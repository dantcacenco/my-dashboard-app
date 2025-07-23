'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'

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
  pricing_item_id: string
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

export default function ProposalBuilder({ customers, pricingItems, userId }: ProposalBuilderProps) {
  const [selectedCustomer, setSelectedCustomer] = useState('')
  const [proposalTitle, setProposalTitle] = useState('')
  const [proposalDescription, setProposalDescription] = useState('')
  const [proposalItems, setProposalItems] = useState<ProposalItem[]>([])
  const [taxRate, setTaxRate] = useState(0.08) // 8% default tax rate
  const [isLoading, setIsLoading] = useState(false)
  const [showAddItem, setShowAddItem] = useState(false)
  
  const router = useRouter()
  const supabase = createClient()

  // Calculate totals
  const subtotal = proposalItems
    .filter(item => item.is_selected)
    .reduce((sum, item) => sum + item.total_price, 0)
  
  const taxAmount = subtotal * taxRate
  const total = subtotal + taxAmount

  // Add item to proposal
  const addItem = (pricingItem: PricingItem, isAddon: boolean = false) => {
    const newItem: ProposalItem = {
      id: crypto.randomUUID(),
      pricing_item_id: pricingItem.id,
      name: pricingItem.name,
      description: pricingItem.description,
      quantity: 1,
      unit_price: pricingItem.price,
      total_price: pricingItem.price,
      is_addon: isAddon,
      is_selected: !isAddon // Main items selected by default, addons not
    }
    
    setProposalItems([...proposalItems, newItem])
    setShowAddItem(false)
  }

  // Update item quantity
  const updateItemQuantity = (itemId: string, quantity: number) => {
    setProposalItems(items =>
      items.map(item =>
        item.id === itemId
          ? { ...item, quantity, total_price: quantity * item.unit_price }
          : item
      )
    )
  }

  // Toggle addon selection
  const toggleAddon = (itemId: string) => {
    setProposalItems(items =>
      items.map(item =>
        item.id === itemId ? { ...item, is_selected: !item.is_selected } : item
      )
    )
  }

  // Remove item
  const removeItem = (itemId: string) => {
    setProposalItems(items => items.filter(item => item.id !== itemId))
  }

  // Save proposal
  const saveProposal = async () => {
    if (!selectedCustomer || !proposalTitle || proposalItems.length === 0) {
      alert('Please fill in all required fields and add at least one item')
      return
    }

    setIsLoading(true)
    
    try {
      // Generate proposal number
      const { data: proposalNumberData } = await supabase
        .rpc('generate_proposal_number')
      
      const proposalNumber = proposalNumberData

      // Create proposal
      const { data: proposal, error: proposalError } = await supabase
        .from('proposals')
        .insert({
          proposal_number: proposalNumber,
          customer_id: selectedCustomer,
          title: proposalTitle,
          description: proposalDescription,
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

      // Add proposal items
      const itemsToInsert = proposalItems.map((item, index) => ({
        proposal_id: proposal.id,
        pricing_item_id: item.pricing_item_id,
        name: item.name,
        description: item.description,
        quantity: item.quantity,
        unit_price: item.unit_price,
        total_price: item.total_price,
        is_addon: item.is_addon,
        is_selected: item.is_selected,
        sort_order: index
      }))

      const { error: itemsError } = await supabase
        .from('proposal_items')
        .insert(itemsToInsert)

      if (itemsError) throw itemsError

      // Redirect to proposal view
      router.push(`/proposals/${proposal.id}`)
      
    } catch (error) {
      console.error('Error saving proposal:', error)
      alert('Error saving proposal. Please try again.')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
      {/* Left Column - Proposal Details */}
      <div className="lg:col-span-2 space-y-6">
        {/* Basic Info */}
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold mb-4">Proposal Details</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Customer *
              </label>
              <select
                value={selectedCustomer}
                onChange={(e) => setSelectedCustomer(e.target.value)}
                className="w-full p-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                required
              >
                <option value="">Select customer...</option>
                {customers.map(customer => (
                  <option key={customer.id} value={customer.id}>
                    {customer.name} - {customer.email}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Tax Rate (%)
              </label>
              <input
                type="number"
                step="0.01"
                min="0"
                max="1"
                value={taxRate}
                onChange={(e) => setTaxRate(parseFloat(e.target.value) || 0)}
                className="w-full p-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              />
            </div>
          </div>

          <div className="mt-4">
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Proposal Title *
            </label>
            <input
              type="text"
              value={proposalTitle}
              onChange={(e) => setProposalTitle(e.target.value)}
              placeholder="e.g., HVAC System Installation - Main Office"
              className="w-full p-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              required
            />
          </div>

          <div className="mt-4">
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Description
            </label>
            <textarea
              value={proposalDescription}
              onChange={(e) => setProposalDescription(e.target.value)}
              placeholder="Additional details about this proposal..."
              rows={3}
              className="w-full p-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
          </div>
        </div>

        {/* Proposal Items */}
        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-xl font-semibold">Services & Materials</h2>
            <button
              onClick={() => setShowAddItem(!showAddItem)}
              className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:ring-2 focus:ring-blue-500"
            >
              Add Item
            </button>
          </div>

          {/* Add Item Section */}
          {showAddItem && (
            <div className="mb-6 p-4 bg-gray-50 rounded-lg">
              <h3 className="font-medium mb-3">Add Service or Material</h3>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {pricingItems.map(item => (
                  <div key={item.id} className="border border-gray-200 rounded-lg p-3 hover:bg-white cursor-pointer transition-colors">
                    <div className="flex justify-between items-start mb-2">
                      <h4 className="font-medium text-sm">{item.name}</h4>
                      <span className="text-xs bg-gray-100 px-2 py-1 rounded">{item.category}</span>
                    </div>
                    <p className="text-xs text-gray-600 mb-2">{item.description}</p>
                    <div className="flex justify-between items-center">
                      <span className="font-bold text-green-600">${item.price.toFixed(2)}</span>
                      <div className="space-x-1">
                        <button
                          onClick={() => addItem(item, false)}
                          className="px-2 py-1 text-xs bg-blue-600 text-white rounded hover:bg-blue-700"
                        >
                          Add
                        </button>
                        <button
                          onClick={() => addItem(item, true)}
                          className="px-2 py-1 text-xs bg-orange-600 text-white rounded hover:bg-orange-700"
                        >
                          Add-on
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Current Items */}
          <div className="space-y-3">
            {proposalItems.length === 0 ? (
              <p className="text-gray-500 text-center py-8">No items added yet. Click 'Add Item' to get started.</p>
            ) : (
              proposalItems.map(item => (
                <div key={item.id} className={`border rounded-lg p-4 ${item.is_addon ? 'border-orange-200 bg-orange-50' : 'border-gray-200'}`}>
                  <div className="flex justify-between items-start">
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        {item.is_addon && (
                          <input
                            type="checkbox"
                            checked={item.is_selected}
                            onChange={() => toggleAddon(item.id)}
                            className="w-4 h-4"
                          />
                        )}
                        <h4 className="font-medium">{item.name}</h4>
                        {item.is_addon && <span className="text-xs bg-orange-200 px-2 py-1 rounded">Add-on</span>}
                      </div>
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
              ))
            )}
          </div>
        </div>
      </div>

      {/* Right Column - Summary */}
      <div className="space-y-6">
        {/* Proposal Summary */}
        <div className="bg-white rounded-lg shadow p-6 sticky top-6">
          <h2 className="text-xl font-semibold mb-4">Proposal Summary</h2>
          
          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span>Subtotal:</span>
              <span>${subtotal.toFixed(2)}</span>
            </div>
            <div className="flex justify-between">
              <span>Tax ({(taxRate * 100).toFixed(1)}%):</span>
              <span>${taxAmount.toFixed(2)}</span>
            </div>
            <div className="border-t pt-2 flex justify-between font-bold text-lg">
              <span>Total:</span>
              <span className="text-green-600">${total.toFixed(2)}</span>
            </div>
          </div>

          <div className="mt-6 space-y-3">
            <button
              onClick={saveProposal}
              disabled={isLoading || !selectedCustomer || !proposalTitle || proposalItems.length === 0}
              className="w-full px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 disabled:bg-gray-400 disabled:cursor-not-allowed focus:ring-2 focus:ring-green-500"
            >
              {isLoading ? 'Saving...' : 'Save Proposal'}
            </button>
            
            <button
              onClick={() => router.push('/proposals')}
              className="w-full px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50 focus:ring-2 focus:ring-gray-500"
            >
              Cancel
            </button>
          </div>
        </div>

        {/* Quick Stats */}
        <div className="bg-blue-50 rounded-lg p-4">
          <h3 className="font-medium text-blue-900 mb-2">Quick Stats</h3>
          <div className="text-sm space-y-1">
            <div className="flex justify-between">
              <span>Total Items:</span>
              <span>{proposalItems.length}</span>
            </div>
            <div className="flex justify-between">
              <span>Selected Items:</span>
              <span>{proposalItems.filter(item => item.is_selected).length}</span>
            </div>
            <div className="flex justify-between">
              <span>Add-ons:</span>
              <span>{proposalItems.filter(item => item.is_addon).length}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
