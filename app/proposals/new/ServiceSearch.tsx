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
}

export default function ServiceSearch({ pricingItems, onAddItem, onClose }: ServiceSearchProps) {
  const [searchTerm, setSearchTerm] = useState('')

  // Fuzzy search function with typo tolerance
  const fuzzyMatch = (text: string, searchTerm: string): number => {
    const lowerText = text.toLowerCase()
    const lowerSearch = searchTerm.toLowerCase()
    
    // Exact match gets highest score
    if (lowerText.includes(lowerSearch)) {
      return 100
    }
    
    // Calculate similarity score based on character matches
    let score = 0
    let searchIndex = 0
    
    for (let i = 0; i < lowerText.length && searchIndex < lowerSearch.length; i++) {
      if (lowerText[i] === lowerSearch[searchIndex]) {
        score += 10
        searchIndex++
      }
    }
    
    // Bonus points if search term length is close to match length
    const lengthDiff = Math.abs(lowerText.length - lowerSearch.length)
    if (lengthDiff <= 2) score += 20
    
    // Check for common typos and abbreviations
    const typoReplacements = [
      ['hvac', 'heating ventilation air conditioning'],
      ['ac', 'air conditioning'],
      ['maintenence', 'maintenance'], // common typo
      ['repiar', 'repair'], // common typo
      ['instalation', 'installation'], // common typo
      ['thermostat', 'thermostate'], // common typo
    ]
    
    for (const [typo, correct] of typoReplacements) {
      if (lowerSearch.includes(typo) && lowerText.includes(correct)) {
        score += 30
      }
      if (lowerSearch.includes(correct) && lowerText.includes(typo)) {
        score += 30
      }
    }
    
    return score
  }

  // Filter and sort items based on search
  const getFilteredItems = () => {
    if (searchTerm.trim() === '') {
      return pricingItems.slice(0, 6)
    }
    
    return pricingItems
      .map(item => ({
        item,
        score: Math.max(
          fuzzyMatch(item.name, searchTerm),
          fuzzyMatch(item.description, searchTerm),
          fuzzyMatch(item.category, searchTerm)
        )
      }))
      .filter(result => result.score > 15) // Minimum threshold for relevance
      .sort((a, b) => b.score - a.score) // Sort by relevance
      .slice(0, 6) // Top 6 results
      .map(result => result.item)
  }

  const handleItemAdd = (item: PricingItem, isAddon: boolean) => {
    onAddItem(item, isAddon)
    setSearchTerm('') // Clear search but keep component open
    // Don't call onClose() - keep the search open
  }

  const handleSuggestionClick = (suggestion: string) => {
    setSearchTerm(suggestion)
  }

  const filteredItems = getFilteredItems()

  return (
    <div className="mb-6 p-4 bg-gray-50 rounded-lg">
      <div className="flex justify-between items-center mb-3">
        <h3 className="font-medium">Add Service or Material</h3>
        <button
          onClick={onClose}
          className="text-gray-400 hover:text-gray-600"
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
      
      {/* Search Input */}
      <div className="mb-4">
        <input
          type="text"
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          placeholder="Search services, materials, or repairs..."
          className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          autoFocus
        />
        <p className="text-xs text-gray-500 mt-1">
          Try: "HVAC", "AC repair", "thermostat", "maintenance", etc.
        </p>
      </div>

      {/* Results */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filteredItems.length === 0 && searchTerm ? (
          <div className="col-span-full text-center py-8 text-gray-500">
            <svg className="w-12 h-12 mx-auto mb-3 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
            <p>No services found matching "{searchTerm}"</p>
            <p className="text-xs mt-1">Try different keywords or check spelling</p>
          </div>
        ) : (
          filteredItems.map(item => (
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
                    onClick={() => handleItemAdd(item, false)}
                    className="px-2 py-1 text-xs bg-blue-600 text-white rounded hover:bg-blue-700"
                  >
                    Add
                  </button>
                  <button
                    onClick={() => handleItemAdd(item, true)}
                    className="px-2 py-1 text-xs bg-orange-600 text-white rounded hover:bg-orange-700"
                  >
                    Add-on
                  </button>
                </div>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Quick suggestions if no search term */}
      {!searchTerm && (
        <div className="mt-4 text-xs text-gray-500">
          <p className="font-medium mb-1">Popular services:</p>
          <div className="flex flex-wrap gap-2">
            {['HVAC', 'AC repair', 'maintenance', 'installation', 'thermostat'].map(suggestion => (
              <button
                key={suggestion}
                onClick={() => handleSuggestionClick(suggestion)}
                className="px-2 py-1 bg-gray-200 text-gray-700 rounded hover:bg-gray-300 transition-colors"
              >
                {suggestion}
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}