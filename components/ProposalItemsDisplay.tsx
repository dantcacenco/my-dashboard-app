'use client'

import { useState, useEffect } from 'react'
import { Checkbox } from '@/components/ui/checkbox'

interface ProposalItem {
  id?: string
  item_type: 'service' | 'add_on'
  title: string
  description?: string
  quantity: number
  unit_price: number
  total_price: number
}

interface ProposalItemsDisplayProps {
  items: ProposalItem[]
  taxRate?: number
  showCheckboxes?: boolean
  onTotalChange?: (total: number) => void
  className?: string
}

export default function ProposalItemsDisplay({ 
  items, 
  taxRate = 0.08, 
  showCheckboxes = false,
  onTotalChange,
  className = ''
}: ProposalItemsDisplayProps) {
  const [selectedAddOns, setSelectedAddOns] = useState<Set<string>>(new Set())
  
  const services = items.filter(item => item.item_type === 'service')
  const addOns = items.filter(item => item.item_type === 'add_on')
  
  const servicesSubtotal = services.reduce((sum, item) => sum + item.total_price, 0)
  const selectedAddOnsTotal = addOns
    .filter(item => !showCheckboxes || selectedAddOns.has(item.id || item.title))
    .reduce((sum, item) => sum + item.total_price, 0)
  
  const subtotal = servicesSubtotal + selectedAddOnsTotal
  const tax = subtotal * taxRate
  const total = subtotal + tax

  useEffect(() => {
    if (onTotalChange) {
      onTotalChange(total)
    }
  }, [total, onTotalChange])

  const toggleAddOn = (itemId: string) => {
    const newSelected = new Set(selectedAddOns)
    if (newSelected.has(itemId)) {
      newSelected.delete(itemId)
    } else {
      newSelected.add(itemId)
    }
    setSelectedAddOns(newSelected)
  }

  return (
    <div className={className}>
      {/* Services Section */}
      {services.length > 0 && (
        <div className="mb-6">
          <h3 className="font-semibold text-lg mb-3">Services & Materials:</h3>
          <div className="space-y-3">
            {services.map((item, index) => (
              <div key={item.id || index} className="bg-white p-4 rounded-lg border">
                <div className="flex justify-between items-start">
                  <div className="flex-1">
                    <h4 className="font-medium">{item.title}</h4>
                    {item.description && (
                      <p className="text-sm text-gray-600 mt-1">{item.description}</p>
                    )}
                    <div className="flex items-center gap-4 mt-2 text-sm">
                      <span>Qty: {item.quantity}</span>
                      <span>@ ${item.unit_price.toFixed(2)}</span>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="font-semibold text-lg">${item.total_price.toFixed(2)}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Add-ons Section */}
      {addOns.length > 0 && (
        <div className="mb-6">
          <h3 className="font-semibold text-lg mb-3">Add-ons:</h3>
          <div className="space-y-3">
            {addOns.map((item, index) => (
              <div 
                key={item.id || index} 
                className={`p-4 rounded-lg border ${
                  !showCheckboxes || selectedAddOns.has(item.id || item.title)
                    ? 'bg-orange-50 border-orange-200' 
                    : 'bg-gray-50 border-gray-200'
                }`}
              >
                <div className="flex items-start gap-3">
                  {showCheckboxes && (
                    <Checkbox
                      checked={selectedAddOns.has(item.id || item.title)}
                      onCheckedChange={() => toggleAddOn(item.id || item.title)}
                      className="mt-1"
                    />
                  )}
                  <div className="flex-1">
                    <div className="flex justify-between items-start">
                      <div>
                        <h4 className="font-medium flex items-center gap-2">
                          {item.title}
                          <span className="text-xs bg-orange-200 text-orange-800 px-2 py-0.5 rounded">
                            Add-on
                          </span>
                        </h4>
                        {item.description && (
                          <p className="text-sm text-gray-600 mt-1">{item.description}</p>
                        )}
                        <div className="flex items-center gap-4 mt-2 text-sm">
                          <span>Qty: {item.quantity}</span>
                          <span>@ ${item.unit_price.toFixed(2)}</span>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className={`font-semibold text-lg ${
                          showCheckboxes && !selectedAddOns.has(item.id || item.title)
                            ? 'text-gray-400 line-through' 
                            : ''
                        }`}>
                          ${item.total_price.toFixed(2)}
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Totals Section */}
      <div className="border-t pt-4 space-y-2">
        <div className="flex justify-between text-sm">
          <span>Services Subtotal:</span>
          <span>${servicesSubtotal.toFixed(2)}</span>
        </div>
        {selectedAddOnsTotal > 0 && (
          <div className="flex justify-between text-sm">
            <span>Add-ons Subtotal:</span>
            <span>${selectedAddOnsTotal.toFixed(2)}</span>
          </div>
        )}
        <div className="flex justify-between font-medium">
          <span>Subtotal:</span>
          <span>${subtotal.toFixed(2)}</span>
        </div>
        <div className="flex justify-between text-sm">
          <span>Tax ({(taxRate * 100).toFixed(1)}%):</span>
          <span>${tax.toFixed(2)}</span>
        </div>
        <div className="flex justify-between text-lg font-bold border-t pt-2">
          <span>Total:</span>
          <span className="text-green-600">${total.toFixed(2)}</span>
        </div>
      </div>
    </div>
  )
}
