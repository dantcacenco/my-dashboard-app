#!/bin/bash

# Fix: Display PDFs inline in MediaViewer instead of download buttons
# Run as: ./fix_pdf_inline.sh from my-dashboard-app directory

set -e

echo "Modifying MediaViewer to display PDFs inline..."
echo "============================================="

# Backup MediaViewer
cp components/MediaViewer.tsx components/MediaViewer.tsx.backup

# Update MediaViewer to show PDFs inline
cat > components/MediaViewer.tsx << 'EOF'
'use client'

import { useState, useEffect } from 'react'
import { X, ChevronLeft, ChevronRight, Download, ExternalLink, FileText, Image } from 'lucide-react'

interface MediaViewerProps {
  items: Array<{
    id: string
    url: string
    name?: string
    caption?: string
    type: 'photo' | 'video' | 'file'
    mime_type?: string
  }>
  initialIndex: number
  onClose: () => void
}

export default function MediaViewer({ items, initialIndex, onClose }: MediaViewerProps) {
  const [currentIndex, setCurrentIndex] = useState(initialIndex)
  const [imageError, setImageError] = useState(false)
  
  const currentItem = items[currentIndex]
  
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
      if (e.key === 'ArrowLeft') goToPrevious()
      if (e.key === 'ArrowRight') goToNext()
    }
    
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [])

  const goToPrevious = () => {
    setCurrentIndex(prev => prev > 0 ? prev - 1 : items.length - 1)
    setImageError(false)
  }

  const goToNext = () => {
    setCurrentIndex(prev => prev < items.length - 1 ? prev + 1 : 0)
    setImageError(false)
  }

  const handleDownload = () => {
    const link = document.createElement('a')
    link.href = currentItem.url
    link.download = currentItem.name || 'download'
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
  }

  const openInNewTab = () => {
    window.open(currentItem.url, '_blank')
  }

  const renderContent = () => {
    const { mime_type, url, name, type } = currentItem

    console.log('MediaViewer rendering:', { type, mime_type, name })

    // Handle images
    if (type === 'photo' || mime_type?.startsWith('image/')) {
      return (
        <div className="flex items-center justify-center h-full max-h-[90vh]">
          {imageError ? (
            <div className="flex flex-col items-center text-white">
              <Image className="w-16 h-16 mb-4 opacity-50" />
              <p>Failed to load image</p>
              <button 
                onClick={openInNewTab}
                className="mt-2 px-4 py-2 bg-blue-600 rounded hover:bg-blue-700"
              >
                Open in New Tab
              </button>
            </div>
          ) : (
            <img
              src={url}
              alt={name || 'Media'}
              className="max-w-full max-h-full object-contain rounded"
              onError={() => setImageError(true)}
            />
          )}
        </div>
      )
    }

    // Handle videos
    if (type === 'video' || mime_type?.startsWith('video/')) {
      return (
        <div className="flex items-center justify-center h-full max-h-[90vh]">
          <video 
            controls 
            className="max-w-full max-h-full rounded"
            poster=""
            preload="metadata"
          >
            <source src={url} type={mime_type || 'video/mp4'} />
            Your browser does not support the video tag.
          </video>
        </div>
      )
    }

    // Handle PDFs - Show inline instead of download buttons
    if (mime_type?.includes('pdf')) {
      return (
        <div className="w-full h-full flex flex-col">
          <div className="flex-1 min-h-0">
            <iframe
              src={url}
              className="w-full h-full border-0"
              title={name || 'PDF Document'}
              onError={(e) => {
                console.error('PDF iframe load error:', e)
                // Fallback to object tag if iframe fails
                const iframe = e.target as HTMLIFrameElement
                const container = iframe.parentElement
                if (container) {
                  container.innerHTML = `
                    <object data="${url}" type="application/pdf" class="w-full h-full">
                      <div class="flex flex-col items-center justify-center h-full text-white">
                        <div class="text-center mb-6">
                          <h3 class="text-xl mb-2">${name}</h3>
                          <p class="text-gray-300 mb-6">PDF cannot be displayed inline in this browser</p>
                          <div class="flex gap-4">
                            <button onclick="window.open('${url}', '_blank')" class="px-6 py-3 bg-blue-600 rounded-lg hover:bg-blue-700 flex items-center gap-2">
                              Open in New Tab
                            </button>
                            <a href="${url}" download="${name}" class="px-6 py-3 bg-gray-600 rounded-lg hover:bg-gray-700 flex items-center gap-2 text-white no-underline">
                              Download PDF
                            </a>
                          </div>
                        </div>
                      </div>
                    </object>
                  `
                }
              }}
            />
          </div>
        </div>
      )
    }

    // Handle other file types
    return (
      <div className="flex flex-col items-center justify-center h-full text-white">
        <FileText className="w-16 h-16 mb-4 opacity-70" />
        <h3 className="text-xl mb-2">{name}</h3>
        <p className="text-gray-300 mb-6">{mime_type || 'File'}</p>
        <div className="flex gap-4">
          <button 
            onClick={handleDownload}
            className="px-6 py-3 bg-blue-600 rounded-lg hover:bg-blue-700 flex items-center gap-2"
          >
            <Download className="w-4 h-4" />
            Download File
          </button>
          <button 
            onClick={openInNewTab}
            className="px-6 py-3 bg-gray-600 rounded-lg hover:bg-gray-700 flex items-center gap-2"
          >
            <ExternalLink className="w-4 h-4" />
            Open in New Tab
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-95 z-50 flex flex-col">
      {/* Top bar with controls */}
      <div className="flex items-center justify-between p-4 bg-black bg-opacity-50">
        <div className="flex items-center gap-4">
          {/* Download and open buttons for PDFs */}
          {currentItem.mime_type?.includes('pdf') && (
            <div className="flex gap-2">
              <button 
                onClick={handleDownload}
                className="p-2 bg-blue-600 rounded-lg hover:bg-blue-700 text-white flex items-center gap-2"
                title="Download PDF"
              >
                <Download className="w-4 h-4" />
                <span className="hidden sm:inline">Download</span>
              </button>
              <button 
                onClick={openInNewTab}
                className="p-2 bg-gray-600 rounded-lg hover:bg-gray-700 text-white flex items-center gap-2"
                title="Open in New Tab"
              >
                <ExternalLink className="w-4 h-4" />
                <span className="hidden sm:inline">New Tab</span>
              </button>
            </div>
          )}
        </div>

        <div className="text-white text-center flex-1">
          <p className="font-medium">{currentItem.name}</p>
          {items.length > 1 && (
            <p className="text-gray-300 text-sm">
              {currentIndex + 1} of {items.length}
            </p>
          )}
        </div>

        <button
          onClick={onClose}
          className="p-2 text-white hover:text-gray-300 rounded-lg hover:bg-white hover:bg-opacity-10"
        >
          <X className="w-6 h-6" />
        </button>
      </div>

      {/* Navigation buttons */}
      {items.length > 1 && (
        <>
          <button
            onClick={goToPrevious}
            className="absolute left-4 top-1/2 transform -translate-y-1/2 text-white hover:text-gray-300 z-10 p-2 rounded-lg hover:bg-white hover:bg-opacity-10"
          >
            <ChevronLeft className="w-8 h-8" />
          </button>
          <button
            onClick={goToNext}
            className="absolute right-4 top-1/2 transform -translate-y-1/2 text-white hover:text-gray-300 z-10 p-2 rounded-lg hover:bg-white hover:bg-opacity-10"
          >
            <ChevronRight className="w-8 h-8" />
          </button>
        </>
      )}

      {/* Main content area */}
      <div className="flex-1 min-h-0 p-4">
        {renderContent()}
      </div>
    </div>
  )
}
EOF

echo "Running TypeScript check..."
if ! npx tsc --noEmit; then
    echo "TypeScript errors found. Restoring backup..."
    cp components/MediaViewer.tsx.backup components/MediaViewer.tsx
    exit 1
fi

echo "Git commit and push..."
git add -A
git commit -m "Fix: Display PDFs inline in browser instead of download buttons

- Modified MediaViewer to show PDFs using iframe for inline viewing
- Added fallback to object tag if iframe fails
- PDFs now display directly in the viewer instead of showing download buttons
- Kept download and new tab options in top bar for PDFs
- Improved layout with proper flex structure for full-height PDF viewing
- Added error handling for PDFs that cannot be displayed inline"

git push origin main

echo ""
echo "SUCCESS! PDFs now display inline in the browser!"
echo "=============================================="
echo ""
echo "Changes made:"
echo "- PDFs now render inline using iframe"
echo "- Download/New Tab buttons moved to top bar"
echo "- Full-height PDF viewing experience"
echo "- Fallback handling for browsers that can't display PDFs"
echo ""
echo "Test now: Click on any PDF file and it should display directly in the viewer!"