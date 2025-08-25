'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'
import CustomerSearch from '../../new/CustomerSearch'
import ServiceSearch from '../../new/ServiceSearch'
import AddNewPricingItem from '../../new/AddNewPricingItem'

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

interface ProposalData {
  id: string
  proposal_number: string
  title: string
  description: string
  subtotal: number
  tax_rate: number
  tax_amount: number
  total: number
  status: string
  customer_id: string
  customers: Customer
  proposal_items: ProposalItem[]
}

interface ProposalEditorProps {
  proposal: ProposalData
  customers: Customer[]
  pricingItems: PricingItem[]
  userId: string
}

export default function ProposalEditor({ proposal, customers: initialCustomers, pricingItems: initialPricingItems, userId }: ProposalEditorProps) {
  const [customers, setCustomers] = useState(initialCustomers)
  const [pricingItems, setPricingItems] = useState(initialPricingItems)
  const [selectedCustomer, setSelectedCustomer] = useState<Customer>(proposal.customers)
  const [proposalTitle, setProposalTitle] = useState(proposal.title)
  const [proposalDescription, setProposalDescription] = useState(proposal.description || '')
  const [proposalItems, setProposalItems] = useState<ProposalItem[]>(proposal.proposal_items)
  const [taxRate, setTaxRate] = useState(proposal.tax_rate)
  const [isLoading, setIsLoading] = useState(false)
  const [showAddItem, setShowAddItem] = useState(false)
  const [showAddNewPricing, setShowAddNewPricing] = useState(false)
  const [showCustomerSearch, setShowCustomerSearch] = useState(false)

  const router = useRouter()
  const supabase = createClient()

  // Calculate totals
  const subtotal = proposalItems
    .filter(item => item.is_selected)
    .reduce((sum, item) => sum + item.total_price, 0)
  const taxAmount = subtotal * taxRate
  const total = subtotal + taxAmount

  // Add item to proposal
  const handleAddItem = (item: PricingItem, isAddon: boolean) => {
    // Check if item already exists
    const existingItem = proposalItems.find(pi => 
      pi.name === item.name && pi.is_addon === isAddon
    )
    
    if (existingItem) {
      // Update quantity instead of adding duplicate
      setProposalItems(proposalItems.map(pi => 
        pi.id === existingItem.id 
          ? { 
              ...pi, 
              quantity: pi.quantity + 1, 
              total_price: pi.unit_price * (pi.quantity + 1) 
            }
          : pi
      ))
    } else {
      // Add new item
      const newItem: ProposalItem = {
        id: `temp-${Date.now()}-${Math.random()}`,
        name: item.name,
        description: item.description,
        quantity: 1,
        unit_price: item.price,
        total_price: item.price,
        is_addon: isAddon,
        is_selected: true
      }
      setProposalItems([...proposalItems, newItem])
    }
    setShowAddItem(false)
  }
                  onShowAddNew={() => setShowAddNewPricing(true)}
                />
              )}

              {/* Add New Pricing Item Modal */}
              {showAddNewPricing && (
                <AddNewPricingItem
                  
                  onCancel={() => setShowAddNewPricing(false)}
                  onPricingItemAdded={handlePricingItemAdded}
                  userId={userId}
                />
              )}

              {/* Items List */}
              <div className="space-y-4">
                {/* Services */}
                {proposalItems.filter(item => !item.is_addon).length > 0 && (
                  <>
                    <h3 className="font-medium text-gray-700">Services</h3>
                    {proposalItems.filter(item => !item.is_addon).map(item => (
                      <div key={item.id} className="border rounded-lg p-4">
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
                  </>
                )}

                {/* Add-ons */}
                {proposalItems.filter(item => item.is_addon).length > 0 && (
                  <div className="space-y-3 mt-6">
                    <h3 className="font-medium text-gray-700">Optional Add-ons</h3>
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
                              <span className="text-xs bg-orange-200 text-orange-800 px-2 py-1 rounded">Add-on</span>
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
                                  disabled={!item.is_selected}
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
                      className="w-20 px-2 py-1 border border-gray-300 rounded text-sm"
                      placeholder="0.00"
                    />
                    <span className="text-sm text-gray-600">
                      (${taxAmount.toFixed(2)})
                    </span>
                  </div>
                </div>
                <div className="flex justify-between font-bold text-lg border-t pt-3">
                  <span>Total:</span>
                  <span className="text-green-600">${total.toFixed(2)}</span>
                </div>
              </div>
            </div>

            {/* Actions */}
            <div className="bg-white rounded-lg shadow p-6">
              <div className="space-y-3">
                <button
                  onClick={updateProposal}
                  disabled={isLoading}
                  className="w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isLoading ? 'Updating...' : 'Update Proposal'}
                </button>
                
                <button
                  onClick={() => router.push(`/proposals/${proposal.id}`)}
                  className="w-full px-4 py-2 bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
