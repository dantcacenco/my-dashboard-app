'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'

interface PricingItem {
  id: string
  name: string
  description: string
  price: number
  category: string
  unit: string
}

interface AddNewPricingItemProps {
  onPricingItemAdded: (newItem: PricingItem) => void
  onCancel: () => void
  userId: string
}

export default function AddNewPricingItem({ onPricingItemAdded, onCancel, userId }: AddNewPricingItemProps) {
  const [isLoading, setIsLoading] = useState(false)
  const [newItem, setNewItem] = useState({
    name: '',
    description: '',
    price: '',
    category: 'Service',
    unit: 'each'
  })

  const supabase = createClient()

  const categories = [
    'Service',
    'Material',
    'Labor',
    'Equipment',
    'Parts',
    'Installation',
    'Maintenance',
    'Repair',
    'Inspection',
    'Other'
  ]

  const units = [
    'each',
    'hour',
    'sq ft',
    'linear ft',
    'gallon',
    'pound',
    'ton',
    'unit',
    'lot',
    'service'
  ]

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!newItem.name.trim() || !newItem.price || parseFloat(newItem.price) <= 0) {
      alert('Please fill in name and valid price')
      return
    }

    setIsLoading(true)

    try {
      const { data, error } = await supabase
        .from('pricing_items')
        .insert({
          name: newItem.name.trim(),
          description: newItem.description.trim(),
          price: parseFloat(newItem.price),
          category: newItem.category,
          unit: newItem.unit,
          is_active: true,
          created_by: userId
        })
        .select()
        .single()

      if (error) throw error

      // Call the callback to add the new item to the list
      onPricingItemAdded(data)
      
      // Reset form
      setNewItem({
        name: '',
        description: '',
        price: '',
        category: 'Service',
        unit: 'each'
      })

      alert('Service/Material added successfully!')
      onCancel()

    } catch (error) {
      console.error('Error adding pricing item:', error)
      alert('Error adding item. Please try again.')
    } finally {
      setIsLoading(false)
    }
  }

  const handleCancel = () => {
    setNewItem({
      name: '',
      description: '',
      price: '',
      category: 'Service',
      unit: 'each'
    })
    onCancel()
  }

  return (
    <div className="bg-white border-2 border-blue-200 rounded-lg p-6 mb-6">
      <div className="flex justify-between items-center mb-4">
        <h3 className="text-lg font-semibold text-blue-900">Add New Service/Material</h3>
        <button
          onClick={handleCancel}
          className="text-gray-400 hover:text-gray-600"
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Name *
            </label>
            <input
              type="text"
              value={newItem.name}
              onChange={(e) => setNewItem({ ...newItem, name: e.target.value })}
              placeholder="e.g., HVAC System Installation"
              className="w-full p-2 border border-gray-300 rounded focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Price *
            </label>
            <div className="relative">
              <span className="absolute left-3 top-2 text-gray-500">$</span>
              <input
                type="number"
                step="0.01"
                min="0"
                value={newItem.price}
                onChange={(e) => setNewItem({ ...newItem, price: e.target.value })}
                placeholder="0.00"
                className="w-full pl-8 p-2 border border-gray-300 rounded focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                required
              />
            </div>
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Description
          </label>
          <textarea
            value={newItem.description}
            onChange={(e) => setNewItem({ ...newItem, description: e.target.value })}
            placeholder="Detailed description of the service or material..."
            rows={3}
            className="w-full p-2 border border-gray-300 rounded focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          />
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Category
            </label>
            <select
              value={newItem.category}
              onChange={(e) => setNewItem({ ...newItem, category: e.target.value })}
              className="w-full p-2 border border-gray-300 rounded focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              {categories.map(category => (
                <option key={category} value={category}>{category}</option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Unit
            </label>
            <select
              value={newItem.unit}
              onChange={(e) => setNewItem({ ...newItem, unit: e.target.value })}
              className="w-full p-2 border border-gray-300 rounded focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              {units.map(unit => (
                <option key={unit} value={unit}>{unit}</option>
              ))}
            </select>
          </div>
        </div>

        <div className="flex gap-3 pt-4 border-t">
          <button
            type="submit"
            disabled={isLoading}
            className="flex-1 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:bg-gray-400"
          >
            {isLoading ? 'Adding...' : 'Add Service/Material'}
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

      <div className="mt-4 p-3 bg-blue-50 rounded text-sm text-blue-800">
        <p><strong>Tip:</strong> This will be added to your global pricing library and available for all future proposals.</p>
      </div>
    </div>
  )
}