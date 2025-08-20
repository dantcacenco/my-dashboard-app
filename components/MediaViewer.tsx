'use client'

import { useState, useEffect } from 'react'
import { X, ChevronLeft, ChevronRight, Download, ExternalLink } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'

interface MediaViewerProps {
  items: Array<{
    id: string
    url: string
    name?: string
    caption?: string
    type: 'photo' | 'file'
    mime_type?: string
  }>
  initialIndex: number
  onClose: () => void
}

export default function MediaViewer({ items, initialIndex, onClose }: MediaViewerProps) {
  const [currentIndex, setCurrentIndex] = useState(initialIndex)
  const [imageError, setImageError] = useState(false)
  const supabase = createClient()
  
  const currentItem = items[currentIndex]
  
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
      if (e.key === 'ArrowLeft') goToPrevious()
      if (e.key === 'ArrowRight') goToNext()
    }
    
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [currentIndex])
  
  const goToPrevious = () => {
    setCurrentIndex((prev) => (prev > 0 ? prev - 1 : items.length - 1))
    setImageError(false)
  }
  
  const goToNext = () => {
    setCurrentIndex((prev) => (prev < items.length - 1 ? prev + 1 : 0))
    setImageError(false)
  }
  
  const handleDownload = async () => {
    try {
      // For files in storage, we need to fetch with proper auth
      const response = await fetch(currentItem.url)
      const blob = await response.blob()
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = currentItem.name || currentItem.caption || 'download'
      document.body.appendChild(a)
      a.click()
      window.URL.revokeObjectURL(url)
      document.body.removeChild(a)
    } catch (error) {
      console.error('Download failed:', error)
      // Fallback to opening in new tab
      window.open(currentItem.url, '_blank')
    }
  }
  
  const isImage = currentItem.type === 'photo' || 
    (currentItem.mime_type && currentItem.mime_type.startsWith('image/'))
  
  const isPDF = currentItem.mime_type === 'application/pdf'
  
  return (
    <div className="fixed inset-0 z-50 bg-black/90 flex items-center justify-center" onClick={onClose}>
      {/* Close button */}
      <button
        onClick={onClose}
        className="absolute top-4 right-4 text-white hover:text-gray-300 z-50"
      >
        <X className="h-8 w-8" />
      </button>
      
      {/* Navigation buttons */}
      {items.length > 1 && (
        <>
          <button
            onClick={(e) => {
              e.stopPropagation()
              goToPrevious()
            }}
            className="absolute left-4 top-1/2 -translate-y-1/2 text-white hover:text-gray-300 bg-black/50 rounded-full p-2"
          >
            <ChevronLeft className="h-8 w-8" />
          </button>
          
          <button
            onClick={(e) => {
              e.stopPropagation()
              goToNext()
            }}
            className="absolute right-4 top-1/2 -translate-y-1/2 text-white hover:text-gray-300 bg-black/50 rounded-full p-2"
          >
            <ChevronRight className="h-8 w-8" />
          </button>
        </>
      )}
      
      {/* Content */}
      <div 
        className="max-w-7xl max-h-[90vh] mx-auto flex flex-col items-center"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header with file info */}
        <div className="bg-black/70 text-white p-4 rounded-t-lg w-full flex justify-between items-center">
          <div>
            <h3 className="font-semibold">
              {currentItem.name || currentItem.caption || 'Untitled'}
            </h3>
            <p className="text-sm text-gray-300">
              {currentIndex + 1} of {items.length}
            </p>
          </div>
          
          <div className="flex gap-2">
            <button
              onClick={handleDownload}
              className="p-2 hover:bg-white/20 rounded"
              title="Download"
            >
              <Download className="h-5 w-5" />
            </button>
            <button
              onClick={() => window.open(currentItem.url, '_blank')}
              className="p-2 hover:bg-white/20 rounded"
              title="Open in new tab"
            >
              <ExternalLink className="h-5 w-5" />
            </button>
          </div>
        </div>
        
        {/* Media content */}
        <div className="bg-white rounded-b-lg overflow-hidden max-h-[70vh] flex items-center justify-center">
          {isImage && !imageError ? (
            <img
              src={currentItem.url}
              alt={currentItem.caption || currentItem.name}
              className="max-w-full max-h-[70vh] object-contain"
              onError={() => setImageError(true)}
            />
          ) : isPDF ? (
            <iframe
              src={currentItem.url}
              className="w-[90vw] max-w-4xl h-[70vh]"
              title={currentItem.name}
            />
          ) : (
            <div className="p-12 text-center">
              <div className="mb-4">
                <svg
                  className="mx-auto h-24 w-24 text-gray-400"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                  />
                </svg>
              </div>
              <h3 className="text-lg font-medium text-gray-900 mb-2">
                {currentItem.name || 'File'}
              </h3>
              <p className="text-sm text-gray-500 mb-4">
                {currentItem.mime_type || 'Unknown file type'}
              </p>
              <div className="flex gap-2 justify-center">
                <button
                  onClick={handleDownload}
                  className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
                >
                  Download File
                </button>
                <button
                  onClick={() => window.open(currentItem.url, '_blank')}
                  className="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700"
                >
                  Open in New Tab
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
