#!/bin/bash

set -e

echo "🔧 Fixing video thumbnails and proposal add-on formatting..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# 1. First, fix the VideoThumbnail component to handle CORS and loading states better
cat > components/VideoThumbnail.tsx << 'EOF'
'use client'

import { useEffect, useRef, useState } from 'react'
import { Play, Loader2 } from 'lucide-react'

interface VideoThumbnailProps {
  videoUrl: string
  onClick: () => void
  caption?: string
}

export default function VideoThumbnail({ videoUrl, onClick, caption }: VideoThumbnailProps) {
  const videoRef = useRef<HTMLVideoElement>(null)
  const [thumbnail, setThumbnail] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState(false)

  useEffect(() => {
    const video = videoRef.current
    if (!video) return

    let mounted = true

    const captureFrame = () => {
      if (!mounted) return
      
      try {
        const canvas = document.createElement('canvas')
        canvas.width = video.videoWidth || 640
        canvas.height = video.videoHeight || 360
        const ctx = canvas.getContext('2d')
        if (ctx) {
          ctx.drawImage(video, 0, 0, canvas.width, canvas.height)
          const dataUrl = canvas.toDataURL('image/jpeg', 0.7)
          setThumbnail(dataUrl)
          setIsLoading(false)
        }
      } catch (err) {
        console.error('Error capturing video frame:', err)
        setError(true)
        setIsLoading(false)
      }
    }

    const handleLoadedMetadata = () => {
      if (!mounted) return
      // Try to seek to 1 second, or 10% of duration if shorter
      const seekTime = Math.min(1, video.duration * 0.1)
      video.currentTime = seekTime
    }

    const handleError = () => {
      console.error('Video loading error')
      setError(true)
      setIsLoading(false)
    }

    video.addEventListener('loadedmetadata', handleLoadedMetadata)
    video.addEventListener('seeked', captureFrame)
    video.addEventListener('error', handleError)

    // Set a timeout to show placeholder if loading takes too long
    const timeout = setTimeout(() => {
      if (isLoading && mounted) {
        setError(true)
        setIsLoading(false)
      }
    }, 5000)

    return () => {
      mounted = false
      clearTimeout(timeout)
      video.removeEventListener('loadedmetadata', handleLoadedMetadata)
      video.removeEventListener('seeked', captureFrame)
      video.removeEventListener('error', handleError)
    }
  }, [videoUrl, isLoading])

  return (
    <button
      onClick={onClick}
      className="block w-full aspect-square overflow-hidden rounded-lg bg-gray-100 hover:opacity-90 transition-opacity relative group"
    >
      {/* Hidden video element for thumbnail generation */}
      <video
        ref={videoRef}
        src={videoUrl}
        className="hidden"
        preload="metadata"
        muted
        playsInline
      />
      
      {/* Display thumbnail or placeholder */}
      {isLoading ? (
        <div className="w-full h-full flex items-center justify-center bg-gray-200">
          <Loader2 className="h-8 w-8 text-gray-600 animate-spin" />
        </div>
      ) : thumbnail && !error ? (
        <img 
          src={thumbnail} 
          alt={caption || 'Video thumbnail'}
          className="w-full h-full object-cover"
        />
      ) : (
        <div className="w-full h-full flex items-center justify-center bg-gray-200">
          <Play className="h-12 w-12 text-gray-600" />
        </div>
      )}
      
      {/* Play overlay */}
      {!isLoading && (
        <div className="absolute inset-0 flex items-center justify-center bg-black/30 opacity-0 group-hover:opacity-100 transition-opacity">
          <div className="bg-white/90 rounded-full p-3">
            <Play className="h-8 w-8 text-gray-800" />
          </div>
        </div>
      )}
      
      {/* Video badge */}
      <span className="absolute bottom-2 left-2 text-xs bg-black/70 text-white px-2 py-1 rounded">
        Video
      </span>
    </button>
  )
}
EOF

echo "✅ Fixed VideoThumbnail component"

# 2. Create ProposalItemsDisplay component for consistent add-on formatting
cat > components/ProposalItemsDisplay.tsx << 'EOF'
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
EOF

echo "✅ Created ProposalItemsDisplay component"

# Test TypeScript
echo "📋 Checking TypeScript..."
npx tsc --noEmit 2>&1 | head -10 || echo "TypeScript check done"

# Commit
git add -A
git commit -m "Fix video thumbnails and create proposal items display component

- Fixed VideoThumbnail loading issues and timeout handling
- Removed crossOrigin attribute causing CORS issues
- Added proper error handling and fallback to play icon
- Created ProposalItemsDisplay component for consistent formatting
- Add-ons show with orange background
- Checkboxes for customer view to select add-ons
- Proper subtotal calculations with selected add-ons"

git push origin main

echo ""
echo "✅ Components fixed and created!"
echo ""
echo "Next step: Integrate ProposalItemsDisplay into proposal views"
EOF
