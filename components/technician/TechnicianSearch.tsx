'use client'

import { useState, useEffect, useRef } from 'react'
import { createClient } from '@/lib/supabase/client'
import { User, X } from 'lucide-react'

interface Technician {
  id: string
  full_name: string | null
  email: string
}

interface TechnicianSearchProps {
  selectedTechnicians: Technician[]
  onAddTechnician: (tech: Technician) => void
  onRemoveTechnician: (techId: string) => void
  jobId?: string
}

export default function TechnicianSearch({ 
  selectedTechnicians, 
  onAddTechnician, 
  onRemoveTechnician,
  jobId 
}: TechnicianSearchProps) {
  const [searchTerm, setSearchTerm] = useState('')
  const [technicians, setTechnicians] = useState<Technician[]>([])
  const [filteredTechnicians, setFilteredTechnicians] = useState<Technician[]>([])
  const [showDropdown, setShowDropdown] = useState(false)
  const dropdownRef = useRef<HTMLDivElement>(null)
  const supabase = createClient()

  useEffect(() => {
    async function fetchTechnicians() {
      const { data } = await supabase
        .from('profiles')
        .select('id, full_name, email')
        .eq('role', 'technician')
        .eq('is_active', true)
        .order('full_name')
      
      if (data) {
        setTechnicians(data)
      }
    }
    fetchTechnicians()
  }, [])

  useEffect(() => {
    if (searchTerm) {
      const filtered = technicians.filter(tech => {
        const isAlreadySelected = selectedTechnicians.some(st => st.id === tech.id)
        if (isAlreadySelected) return false
        
        const searchLower = searchTerm.toLowerCase()
        return (
          tech.full_name?.toLowerCase().includes(searchLower) ||
          tech.email.toLowerCase().includes(searchLower)
        )
      })
      setFilteredTechnicians(filtered)
      setShowDropdown(filtered.length > 0)
    } else {
      setFilteredTechnicians([])
      setShowDropdown(false)
    }
  }, [searchTerm, technicians, selectedTechnicians])

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setShowDropdown(false)
      }
    }
    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  const handleSelectTechnician = async (tech: Technician) => {
    onAddTechnician(tech)
    setSearchTerm('')
    setShowDropdown(false)
    
    if (jobId) {
      try {
        await supabase
          .from('job_technicians')
          .insert({
            job_id: jobId,
            technician_id: tech.id
          })
      } catch (error) {
        console.error('Error assigning technician:', error)
      }
    }
  }

  const handleRemoveTechnician = async (techId: string) => {
    onRemoveTechnician(techId)
    
    if (jobId) {
      try {
        await supabase
          .from('job_technicians')
          .delete()
          .eq('job_id', jobId)
          .eq('technician_id', techId)
      } catch (error) {
        console.error('Error removing technician:', error)
      }
    }
  }

  return (
    <div className="space-y-3">
      <div className="relative" ref={dropdownRef}>
        <div className="flex flex-wrap items-center gap-2 p-2 border rounded-lg min-h-[42px] bg-white">
          {selectedTechnicians.map((tech) => (
            <div
              key={tech.id}
              className="flex items-center gap-1 px-2 py-1 bg-blue-100 text-blue-700 rounded-md text-sm"
            >
              <User className="h-3 w-3" />
              <span>{tech.full_name || tech.email}</span>
              <button
                onClick={() => handleRemoveTechnician(tech.id)}
                className="ml-1 hover:bg-blue-200 rounded p-0.5"
              >
                <X className="h-3 w-3" />
              </button>
            </div>
          ))}
          
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder={selectedTechnicians.length === 0 ? "Search for technicians..." : "Add more..."}
            className="flex-1 min-w-[150px] outline-none text-sm"
          />
        </div>

        {showDropdown && (
          <div className="absolute z-10 w-full mt-1 bg-white border rounded-lg shadow-lg max-h-60 overflow-y-auto">
            {filteredTechnicians.map((tech) => (
              <button
                key={tech.id}
                onClick={() => handleSelectTechnician(tech)}
                className="w-full px-3 py-2 text-left hover:bg-gray-100 flex items-center gap-2"
              >
                <User className="h-4 w-4 text-gray-400" />
                <div>
                  <div className="font-medium text-sm">{tech.full_name || 'No name'}</div>
                  <div className="text-xs text-gray-500">{tech.email}</div>
                </div>
              </button>
            ))}
          </div>
        )}
      </div>
      
      {selectedTechnicians.length === 0 && (
        <p className="text-xs text-gray-500">Start typing to search for technicians</p>
      )}
    </div>
  )
}
