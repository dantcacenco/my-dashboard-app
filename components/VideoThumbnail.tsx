'use client'

import { useEffect, useRef, useState } from 'react'
import { Play } from 'lucide-react'

interface VideoThumbnailProps {
  videoUrl: string
  onClick: () => void
  caption?: string
}

export default function VideoThumbnail({ videoUrl, onClick, caption }: VideoThumbnailProps) {
  const videoRef = useRef<HTMLVideoElement>(null)
  const [thumbnail, setThumbnail] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    const video = videoRef.current
    if (!video) return

    const captureFrame = () => {
      const canvas = document.createElement('canvas')
      canvas.width = video.videoWidth
      canvas.height = video.videoHeight
      const ctx = canvas.getContext('2d')
      if (ctx) {
        ctx.drawImage(video, 0, 0, canvas.width, canvas.height)
        setThumbnail(canvas.toDataURL())
        setIsLoading(false)
      }
    }

    video.addEventListener('loadeddata', () => {
      video.currentTime = 1 // Seek to 1 second for thumbnail
    })

    video.addEventListener('seeked', captureFrame)

    return () => {
      video.removeEventListener('loadeddata', captureFrame)
      video.removeEventListener('seeked', captureFrame)
    }
  }, [videoUrl])

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
        crossOrigin="anonymous"
        preload="metadata"
      />
      
      {/* Display thumbnail or placeholder */}
      {isLoading ? (
        <div className="w-full h-full flex items-center justify-center bg-gray-200">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-gray-600" />
        </div>
      ) : thumbnail ? (
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
      <div className="absolute inset-0 flex items-center justify-center bg-black/30 opacity-0 group-hover:opacity-100 transition-opacity">
        <div className="bg-white/90 rounded-full p-3">
          <Play className="h-8 w-8 text-gray-800" />
        </div>
      </div>
      
      {/* Video badge */}
      <span className="absolute bottom-2 left-2 text-xs bg-black/70 text-white px-2 py-1 rounded">
        Video
      </span>
    </button>
  )
}
