'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card } from '@/components/ui/card'
import { X, Loader2, Check, Copy } from 'lucide-react'
import { toast } from 'sonner'

interface AddTechnicianModalProps {
  onClose: () => void
  onSuccess: () => void
}

export default function AddTechnicianModal({ onClose, onSuccess }: AddTechnicianModalProps) {
  const [isLoading, setIsLoading] = useState(false)
  const [showCredentials, setShowCredentials] = useState(false)
  const [credentials, setCredentials] = useState<{email: string, password: string} | null>(null)
  const [formData, setFormData] = useState({
    fullName: '',
    email: '',
    phone: '',
    temporaryPassword: ''
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!formData.fullName || !formData.email || !formData.temporaryPassword) {
      toast.error('Please fill in all required fields')
      return
    }

    if (formData.temporaryPassword.length < 6) {
      toast.error('Password must be at least 6 characters')
      return
    }

    setIsLoading(true)

    try {
      const response = await fetch('/api/technicians/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: formData.email,
          password: formData.temporaryPassword,
          full_name: formData.fullName,
          phone: formData.phone
        })
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Failed to create technician')
      }

      // Show credentials
      setCredentials({
        email: formData.email,
        password: formData.temporaryPassword
      })
      setShowCredentials(true)
      
      toast.success('Technician created successfully!')
      
      // Wait a bit then close
      setTimeout(() => {
        onSuccess()
      }, 3000)
      
    } catch (error: any) {
      toast.error(error.message || 'Failed to create technician')
      setIsLoading(false)
    }
  }

  const copyToClipboard = (text: string, label: string) => {
    navigator.clipboard.writeText(text)
    toast.success(`${label} copied to clipboard`)
  }

  if (showCredentials && credentials) {
    return (
      <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
        <div className="bg-white rounded-lg p-6 w-full max-w-md">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-xl font-semibold">Technician Created!</h2>
            <button
              onClick={onClose}
              className="text-gray-500 hover:text-gray-700"
            >
              <X className="h-5 w-5" />
            </button>
          </div>

          <div className="space-y-4">
            <div className="flex items-center gap-2 text-green-600 mb-4">
              <Check className="h-5 w-5" />
              <span className="font-medium">Account created successfully</span>
            </div>

            <Card className="p-4 bg-blue-50 border-blue-200">
              <p className="text-sm font-medium mb-3">Share these credentials with the technician:</p>
              
              <div className="space-y-2">
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-600">Email:</span>
                  <div className="flex items-center gap-2">
                    <code className="bg-white px-2 py-1 rounded text-sm">{credentials.email}</code>
                    <button
                      onClick={() => copyToClipboard(credentials.email, 'Email')}
                      className="text-blue-600 hover:text-blue-800"
                    >
                      <Copy className="h-4 w-4" />
                    </button>
                  </div>
                </div>
                
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-600">Password:</span>
                  <div className="flex items-center gap-2">
                    <code className="bg-white px-2 py-1 rounded text-sm">{credentials.password}</code>
                    <button
                      onClick={() => copyToClipboard(credentials.password, 'Password')}
                      className="text-blue-600 hover:text-blue-800"
                    >
                      <Copy className="h-4 w-4" />
                    </button>
                  </div>
                </div>
              </div>

              <p className="text-xs text-gray-600 mt-3">
                The technician should change their password after first login.
              </p>
            </Card>

            <Button onClick={onClose} className="w-full">
              Done
            </Button>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 w-full max-w-md">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-semibold">Add New Technician</h2>
          <button
            onClick={onClose}
            className="text-gray-500 hover:text-gray-700"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <Label htmlFor="fullName">Full Name *</Label>
            <Input
              id="fullName"
              type="text"
              value={formData.fullName}
              onChange={(e) => setFormData({ ...formData, fullName: e.target.value })}
              placeholder="John Smith"
              required
            />
          </div>

          <div>
            <Label htmlFor="email">Email Address *</Label>
            <Input
              id="email"
              type="email"
              value={formData.email}
              onChange={(e) => setFormData({ ...formData, email: e.target.value })}
              placeholder="john@example.com"
              required
            />
            <p className="text-xs text-muted-foreground mt-1">
              This will be their login email
            </p>
          </div>

          <div>
            <Label htmlFor="phone">Phone Number</Label>
            <Input
              id="phone"
              type="tel"
              value={formData.phone}
              onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
              placeholder="(555) 123-4567"
            />
          </div>

          <div>
            <Label htmlFor="password">Temporary Password *</Label>
            <Input
              id="password"
              type="text"
              value={formData.temporaryPassword}
              onChange={(e) => setFormData({ ...formData, temporaryPassword: e.target.value })}
              placeholder="Min 6 characters"
              required
              minLength={6}
            />
            <p className="text-xs text-muted-foreground mt-1">
              You'll be able to copy this after creation
            </p>
          </div>

          <div className="flex gap-3 pt-4">
            <Button
              type="button"
              variant="outline"
              onClick={onClose}
              className="flex-1"
              disabled={isLoading}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              className="flex-1"
              disabled={isLoading}
            >
              {isLoading ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Creating...
                </>
              ) : (
                'Create Technician'
              )}
            </Button>
          </div>
        </form>
      </div>
    </div>
  )
}
