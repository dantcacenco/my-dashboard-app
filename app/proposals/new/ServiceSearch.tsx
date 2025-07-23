'use client'

import { useState } from 'react'

interface PricingItem {
  id: string
  name: string
  description: string
  price: number
  category: string
  unit: string
}

interface ServiceSearchProps {
  pricingItems: PricingItem[]
  onAddItem: (item: PricingItem, isAddon: boolean) => void
  onClose: () => void
  onShowAddNew: () => void
}

export default function ServiceSearch({ pricingItems, onAddItem, onClose, onShowAddNew }: ServiceSearchProps) {
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedCategory, setSelectedCategory] = useState('all')

  // Get unique categories
  const categories = ['all', ...Array.from(new Set(pricingItems.map(item => item.category)))]

  // Filter items based on search and category
  const filteredItems = pricingItems.filter(item => {
    const matchesSearch = item.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         item.description.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         item.category.toLowerCase().includes(searchTerm.toLowerCase())
    
    const matchesCategory = selectedCategory === 'all' || item.category === selectedCategory
    
    return matchesSearch && matchesCategory
  })

  const addItemToProposal = (item: PricingItem, isAddon: boolean) => {
    onAddItem(item, isAddon)
    // Don't close the search - let user add multiple items
  }

  return (
    <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-4">
      <div className="flex justify-between items-center mb-3">
        <h3 className="font-medium">Add Service or Material</h3>
        <div className="flex items-center gap-2">
          <button
            onClick={onShowAddNew}
            className="flex items-center px-3 py-1 text-sm bg-green-600 text-white rounded hover:bg-green-700"
          >
            <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
            </svg>
            Add New
          </button>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
      </div>

      <div className="space-y-3">
        {/* Search and Filter */}
        <div className="flex gap-3">
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Search services and materials..."
            className="flex-1 p-2 border border-gray-300 rounded focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          />
          <select
            value={selectedCategory}
            onChange={(e) => setSelectedCategory(e.target.value)}
            className="p-2 border border-gray-300 rounded focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          >
            {categories.map(category => (
              <option key={category} value={category}>
                {category === 'all' ? 'All Categories' : category}
              </option>
            ))}
          </select>
        </div>

        {/* Results */}
        <div className="max-h-64 overflow-y-auto space-y-2">
          {filteredItems.length > 0 ? (
            filteredItems.map((item) => (
              <div key={item.id} className="bg-white border border-gray-200 rounded-lg p-3">
                <div className="flex justify-between items-start">
                  <div className="flex-1">
                    <h4 className="font-medium">{item.name}</h4>
                    <p className="text-sm text-gray-600 mt-1">{item.description}</p>
                    <div className="flex items-center gap-4 mt-2 text-sm">
                      <span className="bg-gray-100 px-2 py-1 rounded">{item.category}</span>
                      <span>per {item.unit}</span>
                      <span className="font-bold text-green-600">${item.price.toFixed(2)}</span>
                    </div>
                  </div>
                  <div className="flex gap-2 ml-4">
                    <button
                      onClick={() => addItemToProposal(item, false)}
                      className="px-3 py-1 bg-blue-600 text-white rounded text-sm hover:bg-blue-700"
                    >
                      Add Service
                    </button>
                    <button
                      onClick={() => addItemToProposal(item, true)}
                      className="px-3 py-1 bg-orange-600 text-white rounded text-sm hover:bg-orange-700"
                    >
                      Add as Add-on
                    </button>
                  </div>
                </div>
              </div>
            ))
          ) : (
            <div className="text-center text-gray-500 py-4">
              {searchTerm || selectedCategory !== 'all' 
                ? 'No items found. Try a different search term or category.'
                : 'No services available. Click "Add New" to create one.'
              }
            </div>
          )}
        </div>

        {/* Instructions */}
        <div className="text-xs text-blue-700 bg-blue-100 p-2 rounded">
          💡 <strong>Tip:</strong> You can add multiple items. Click "Add Service" for main services or "Add as Add-on" for optional extras. Close this panel when you're done.
        </div>
      </div>
    </div>
  )
}