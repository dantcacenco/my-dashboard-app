'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { 
  Select, 
  SelectContent, 
  SelectItem, 
  SelectTrigger, 
  SelectValue 
} from '@/components/ui/select'
import { Label } from '@/components/ui/label'
import { X, Camera, DollarSign } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'

interface RecordManualPaymentProps {
  proposalId: string
  proposalNumber: string
  depositAmount: number
  progressAmount: number
  finalAmount: number
  totalAmount: number
  totalPaid?: number
  onClose: () => void
  onSuccess: () => void
}

export default function RecordManualPayment({
  proposalId,
  proposalNumber,
  depositAmount,
  progressAmount,
  finalAmount,
  totalAmount,
  totalPaid = 0,
  onClose,
  onSuccess
}: RecordManualPaymentProps) {
  const [stage, setStage] = useState<string>('deposit')
  const [method, setMethod] = useState<string>('check')
  const [amount, setAmount] = useState<string>('')
  const [checkNumber, setCheckNumber] = useState('')
  const [notes, setNotes] = useState('')
  const [checkImage, setCheckImage] = useState<File | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [error, setError] = useState('')

  // Calculate remaining payable amount
  const remainingPayable = totalAmount - totalPaid
  const maxPayableAmount = remainingPayable.toFixed(2)

  // Set suggested amount based on stage
  const setSuggestedAmount = (selectedStage: string) => {
    setStage(selectedStage)
    if (selectedStage === 'deposit') setAmount(depositAmount.toFixed(2))
    else if (selectedStage === 'progress') setAmount(progressAmount.toFixed(2))
    else if (selectedStage === 'final') setAmount(finalAmount.toFixed(2))
  }

  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setCheckImage(e.target.files[0])
    }
  }

  const handleSubmit = async () => {
    if (!amount || parseFloat(amount) <= 0) {
      setError('Please enter a valid amount')
      return
    }

    // Check if payment exceeds remaining payable amount
    if (parseFloat(amount) > remainingPayable) {
      setError(`Payment cannot exceed remaining balance of $${maxPayableAmount}`)
      return
    }

    setIsSubmitting(true)
    setError('')

    try {
      const supabase = createClient()
      
      // Upload check image if provided (with better error handling)
      let checkImageUrl = null
      if (checkImage && method === 'check') {
        console.log('Attempting to upload check image:', checkImage.name, checkImage.size)
        
        // First check if bucket exists
        const { data: buckets } = await supabase.storage.listBuckets()
        const bucketExists = buckets?.some(b => b.name === 'check-images')
        
        if (!bucketExists) {
          console.warn('check-images bucket does not exist. Skipping image upload.')
          // Continue without image upload rather than failing
        } else {
          const fileName = `${proposalId}/${Date.now()}_${checkImage.name.replace(/[^a-zA-Z0-9.-]/g, '_')}`
          console.log('Uploading to:', fileName)
          
          const { data: uploadData, error: uploadError } = await supabase.storage
            .from('check-images')
            .upload(fileName, checkImage, {
              contentType: checkImage.type,
              upsert: false
            })
          
          if (uploadError) {
            console.error('Error uploading check image:', uploadError)
            // Continue without image rather than failing entire payment
          } else {
            console.log('Upload successful:', uploadData)
            // Get public URL
            const { data: { publicUrl } } = supabase.storage
              .from('check-images')
              .getPublicUrl(fileName)
            
            checkImageUrl = publicUrl
            console.log('Check image URL:', checkImageUrl)
          }
        }
      }

      // Get current user
      const { data: { user } } = await supabase.auth.getUser()
      
      // Record manual payment
      const { error: paymentError } = await supabase
        .from('manual_payments')
        .insert({
          proposal_id: proposalId,
          payment_stage: stage,
          amount: parseFloat(amount),
          payment_method: method,
          check_number: checkNumber || null,
          notes: notes || null,
          check_image_url: checkImageUrl,
          recorded_by: user?.id
        })

      if (paymentError) throw paymentError

      onSuccess()
      onClose()
    } catch (err: any) {
      console.error('Error recording payment:', err)
      setError(err.message || 'Failed to record payment')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 max-w-md w-full max-h-[90vh] overflow-y-auto">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-bold">Record Manual Payment</h2>
          <button onClick={onClose} className="text-gray-500 hover:text-gray-700">
            <X className="h-5 w-5" />
          </button>
        </div>

        <p className="text-sm text-gray-600 mb-4">
          Proposal #{proposalNumber}
        </p>

        {remainingPayable > 0 && (
          <div className="mb-4 p-3 bg-blue-50 text-blue-700 rounded">
            <p className="text-sm">
              <strong>Remaining Balance:</strong> ${maxPayableAmount}
            </p>
            <p className="text-xs mt-1">
              Payments will automatically cascade to the next stage if you overpay the current stage.
            </p>
          </div>
        )}

        {error && (
          <div className="mb-4 p-3 bg-red-100 text-red-700 rounded">
            {error}
          </div>
        )}

        <div className="space-y-4">
          <div>
            <Label>Payment Stage</Label>
            <Select value={stage} onValueChange={setSuggestedAmount}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="deposit">Deposit (50% - ${depositAmount.toFixed(2)})</SelectItem>
                <SelectItem value="progress">Progress/Rough-in (30% - ${progressAmount.toFixed(2)})</SelectItem>
                <SelectItem value="final">Final (20% - ${finalAmount.toFixed(2)})</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div>
            <Label>Payment Method</Label>
            <Select value={method} onValueChange={setMethod}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="check">Check</SelectItem>
                <SelectItem value="cash">Cash</SelectItem>
                <SelectItem value="other">Other</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div>
            <Label>Amount</Label>
            <div className="relative">
              <DollarSign className="absolute left-3 top-3 h-4 w-4 text-gray-500" />
              <Input
                type="number"
                step="0.01"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                className="pl-9"
                placeholder="0.00"
              />
            </div>
          </div>

          {method === 'check' && (
            <div>
              <Label>Check Number</Label>
              <Input
                value={checkNumber}
                onChange={(e) => setCheckNumber(e.target.value)}
                placeholder="1234"
              />
            </div>
          )}

          {method === 'check' && (
            <div>
              <Label>Check Image (Optional)</Label>
              <div className="mt-1">
                <input
                  type="file"
                  accept="image/*"
                  onChange={handleImageUpload}
                  className="hidden"
                  id="check-upload"
                />
                <label
                  htmlFor="check-upload"
                  className="flex items-center justify-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 cursor-pointer"
                >
                  <Camera className="h-4 w-4 mr-2" />
                  {checkImage ? checkImage.name : 'Upload Check Image'}
                </label>
              </div>
            </div>
          )}

          <div>
            <Label>Notes (Optional)</Label>
            <Textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Any additional notes..."
              rows={3}
            />
          </div>
        </div>

        <div className="flex justify-end gap-2 mt-6">
          <Button variant="outline" onClick={onClose} disabled={isSubmitting}>
            Cancel
          </Button>
          <Button onClick={handleSubmit} disabled={isSubmitting}>
            {isSubmitting ? 'Recording...' : 'Record Payment'}
          </Button>
        </div>
      </div>
    </div>
  )
}