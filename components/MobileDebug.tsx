'use client'

import { useEffect, useState } from 'react'

interface MobileDebugProps {
  data: any
  title?: string
}

export default function MobileDebug({ data, title = 'Debug Info' }: MobileDebugProps) {
  const [showDebug, setShowDebug] = useState(false)
  const [isMinimized, setIsMinimized] = useState(false)

  useEffect(() => {
    // Check if debug mode is enabled in URL
    const params = new URLSearchParams(window.location.search)
    if (params.get('debug') === 'true') {
      setShowDebug(true)
      console.log('Debug mode enabled. Data:', data)
    }
  }, [data])

  if (!showDebug) return null

  return (
    <div 
      className={`fixed z-50 bg-black text-green-400 rounded-lg font-mono shadow-2xl transition-all ${
        isMinimized 
          ? 'bottom-4 right-4 w-auto p-2' 
          : 'bottom-0 left-0 right-0 max-h-[50vh] overflow-auto p-4'
      }`}
      style={{ fontSize: '10px' }}
    >
      <div className="flex justify-between items-center mb-2">
        <div className="font-bold">🐛 {title}</div>
        <button 
          onClick={() => setIsMinimized(!isMinimized)}
          className="px-2 py-1 bg-green-400 text-black rounded text-xs ml-4"
        >
          {isMinimized ? '📖' : '📕'}
        </button>
      </div>
      
      {!isMinimized && (
        <div className="space-y-2">
          <pre className="whitespace-pre-wrap break-all">
            {JSON.stringify(data, null, 2)}
          </pre>
          
          <div className="mt-4 space-y-1">
            <div>URL: {typeof window !== 'undefined' ? window.location.href : ''}</div>
            <div>User Agent: {typeof navigator !== 'undefined' ? navigator.userAgent : ''}</div>
            <div>Screen: {typeof window !== 'undefined' ? `${window.screen.width}x${window.screen.height}` : ''}</div>
          </div>
        </div>
      )}
    </div>
  )
}
