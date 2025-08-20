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
