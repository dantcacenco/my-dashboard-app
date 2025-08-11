#!/bin/bash

echo "🔧 Setting up technician user and storage for Service Pro..."

# First, create SQL file for Supabase setup
cat > supabase_setup.sql << 'EOF'
-- 1. Create storage bucket for job photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('job-photos', 'job-photos', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Set up storage policies for job photos
CREATE POLICY "Authenticated users can upload job photos" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'job-photos');

CREATE POLICY "Anyone can view job photos" ON storage.objects
FOR SELECT TO public
USING (bucket_id = 'job-photos');

CREATE POLICY "Authenticated users can update job photos" ON storage.objects
FOR UPDATE TO authenticated
USING (bucket_id = 'job-photos');

CREATE POLICY "Authenticated users can delete job photos" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'job-photos');

-- 3. Check if we need to add RLS policies for jobs table
-- Allow boss and technicians to update job status
CREATE POLICY "Users can update their organization's jobs" ON jobs
FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND (profiles.role = 'boss' OR profiles.role = 'admin' OR profiles.role = 'technician')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND (profiles.role = 'boss' OR profiles.role = 'admin' OR profiles.role = 'technician')
  )
);

-- 4. Create a test technician (AFTER creating user in Auth Dashboard)
-- IMPORTANT: First create user in Supabase Auth with:
-- Email: technician@servicepro.com
-- Password: Test123!
-- Then uncomment and run this with the actual auth user ID:

-- INSERT INTO profiles (id, email, full_name, role, phone)
-- VALUES (
--     'REPLACE_WITH_AUTH_USER_ID', -- Get this from auth.users table after creating user
--     'technician@servicepro.com',
--     'John Smith',
--     'technician',
--     '828-555-0100'
-- )
-- ON CONFLICT (id) DO UPDATE SET
--     role = 'technician',
--     full_name = 'John Smith',
--     phone = '828-555-0100';

-- 5. Verify tables exist
SELECT 'Checking job_time_entries table...' as status;
SELECT COUNT(*) as count FROM job_time_entries;

SELECT 'Checking job_photos table...' as status;
SELECT COUNT(*) as count FROM job_photos;

SELECT 'Checking job_materials table...' as status;
SELECT COUNT(*) as count FROM job_materials;

SELECT 'Checking job_activity_log table...' as status;
SELECT COUNT(*) as count FROM job_activity_log;
EOF

# Now fix the job status update issue in JobDetailView
cat > app/jobs/\[id\]/JobDetailView.tsx << 'EOF'
'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { createClientComponentClient } from '@supabase/auth-helpers-nextjs';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Textarea } from '@/components/ui/textarea';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { MapPin, Phone, Clock, Calendar, User, AlertCircle, Camera, CheckCircle, PlayCircle, PauseCircle } from 'lucide-react';
import { format } from 'date-fns';
import PhotoUpload from './PhotoUpload';
import type { Job, Customer, Proposal } from '@/app/types';

interface JobDetailViewProps {
  jobId: string;
}

export default function JobDetailView({ jobId }: JobDetailViewProps) {
  const [job, setJob] = useState<Job | null>(null);
  const [loading, setLoading] = useState(true);
  const [updating, setUpdating] = useState(false);
  const [completionNotes, setCompletionNotes] = useState('');
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();
  const supabase = createClientComponentClient();

  useEffect(() => {
    fetchJob();
  }, [jobId]);

  const fetchJob = async () => {
    try {
      setLoading(true);
      setError(null);
      
      const { data, error } = await supabase
        .from('jobs')
        .select(`
          *,
          customers (
            id,
            name,
            email,
            phone,
            address
          ),
          proposals (
            id,
            proposal_number,
            title,
            total
          ),
          profiles:assigned_technician_id (
            id,
            full_name,
            email,
            phone
          )
        `)
        .eq('id', jobId)
        .single();

      if (error) throw error;
      
      setJob(data as Job);
      setCompletionNotes(data.completion_notes || '');
    } catch (error: any) {
      console.error('Error fetching job:', error);
      setError(error.message || 'Failed to load job');
    } finally {
      setLoading(false);
    }
  };

  const updateJobStatus = async (newStatus: string, additionalData?: any) => {
    try {
      setUpdating(true);
      setError(null);

      const updates: any = {
        status: newStatus,
        updated_at: new Date().toISOString()
      };

      // Add status-specific updates
      if (newStatus === 'in_progress' && !job?.actual_start_time) {
        updates.actual_start_time = new Date().toISOString();
      } else if (newStatus === 'completed') {
        updates.actual_end_time = new Date().toISOString();
        updates.completion_notes = completionNotes;
      }

      // Merge any additional data
      if (additionalData) {
        Object.assign(updates, additionalData);
      }

      const { error } = await supabase
        .from('jobs')
        .update(updates)
        .eq('id', jobId);

      if (error) throw error;

      // Log activity
      await supabase
        .from('job_activity_log')
        .insert({
          job_id: jobId,
          user_id: (await supabase.auth.getUser()).data.user?.id,
          action: `Status changed to ${newStatus}`,
          details: additionalData || {}
        });

      await fetchJob();
      
      // Show success message
      setError(null);
    } catch (error: any) {
      console.error('Error updating job status:', error);
      setError(`Failed to update status: ${error.message || 'Unknown error'}`);
    } finally {
      setUpdating(false);
    }
  };

  const getStatusColor = (status: string) => {
    const colors: Record<string, string> = {
      'scheduled': 'bg-blue-500',
      'in_progress': 'bg-yellow-500',
      'needs_attention': 'bg-red-500',
      'completed': 'bg-green-500',
      'cancelled': 'bg-gray-500'
    };
    return colors[status] || 'bg-gray-500';
  };

  const getNextStatus = () => {
    if (!job) return null;
    
    const statusFlow: Record<string, { next: string; label: string; icon: any }> = {
      'scheduled': { next: 'in_progress', label: 'Start Job', icon: PlayCircle },
      'in_progress': { next: 'completed', label: 'Complete Job', icon: CheckCircle },
      'needs_attention': { next: 'in_progress', label: 'Resume Job', icon: PlayCircle }
    };
    
    return statusFlow[job.status];
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (!job) {
    return (
      <Alert>
        <AlertCircle className="h-4 w-4" />
        <AlertDescription>Job not found</AlertDescription>
      </Alert>
    );
  }

  const nextStatus = getNextStatus();
  const customer = job.customers as Customer;
  const proposal = job.proposals as Proposal | null;
  const technician = job.profiles as any;

  return (
    <div className="container mx-auto p-6 max-w-7xl">
      {error && (
        <Alert className="mb-6" variant="destructive">
          <AlertCircle className="h-4 w-4" />
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}

      <div className="mb-6">
        <Button variant="outline" onClick={() => router.push('/jobs')}>
          ← Back to Jobs
        </Button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2">
          <Card>
            <CardHeader>
              <div className="flex justify-between items-start">
                <div>
                  <CardTitle className="text-2xl">{job.title}</CardTitle>
                  <CardDescription>Job #{job.job_number}</CardDescription>
                </div>
                <Badge className={`${getStatusColor(job.status)} text-white`}>
                  {job.status.replace('_', ' ').toUpperCase()}
                </Badge>
              </div>
            </CardHeader>
            <CardContent>
              <Tabs defaultValue="details" className="w-full">
                <TabsList className="grid w-full grid-cols-4">
                  <TabsTrigger value="details">Details</TabsTrigger>
                  <TabsTrigger value="photos">Photos</TabsTrigger>
                  <TabsTrigger value="notes">Notes</TabsTrigger>
                  <TabsTrigger value="activity">Activity</TabsTrigger>
                </TabsList>

                <TabsContent value="details" className="space-y-4">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <h3 className="font-semibold mb-2">Schedule</h3>
                      <div className="space-y-2 text-sm">
                        <div className="flex items-center gap-2">
                          <Calendar className="h-4 w-4 text-muted-foreground" />
                          <span>{job.scheduled_date ? format(new Date(job.scheduled_date), 'PPP') : 'Not scheduled'}</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <Clock className="h-4 w-4 text-muted-foreground" />
                          <span>{job.scheduled_time || 'No time set'}</span>
                        </div>
                      </div>
                    </div>

                    <div>
                      <h3 className="font-semibold mb-2">Assigned Technician</h3>
                      <div className="space-y-2 text-sm">
                        <div className="flex items-center gap-2">
                          <User className="h-4 w-4 text-muted-foreground" />
                          <span>{technician?.full_name || 'Unassigned'}</span>
                        </div>
                        {technician?.phone && (
                          <div className="flex items-center gap-2">
                            <Phone className="h-4 w-4 text-muted-foreground" />
                            <span>{technician.phone}</span>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>

                  <div>
                    <h3 className="font-semibold mb-2">Job Description</h3>
                    <p className="text-sm text-muted-foreground">
                      {job.description || 'No description provided'}
                    </p>
                  </div>

                  {job.boss_notes && (
                    <div>
                      <h3 className="font-semibold mb-2">Boss Notes</h3>
                      <p className="text-sm text-muted-foreground p-3 bg-yellow-50 rounded">
                        {job.boss_notes}
                      </p>
                    </div>
                  )}

                  <div>
                    <h3 className="font-semibold mb-2">Service Location</h3>
                    <div className="flex items-start gap-2 text-sm">
                      <MapPin className="h-4 w-4 text-muted-foreground mt-0.5" />
                      <div>
                        <p>{job.service_address || customer?.address || 'No address provided'}</p>
                        {(job.service_city || job.service_state || job.service_zip) && (
                          <p>{[job.service_city, job.service_state, job.service_zip].filter(Boolean).join(', ')}</p>
                        )}
                      </div>
                    </div>
                  </div>

                  {job.status === 'in_progress' && (
                    <div>
                      <h3 className="font-semibold mb-2">Completion Notes</h3>
                      <Textarea
                        value={completionNotes}
                        onChange={(e) => setCompletionNotes(e.target.value)}
                        placeholder="Add notes about the completed work..."
                        className="min-h-[100px]"
                      />
                    </div>
                  )}

                  {nextStatus && (
                    <div className="pt-4">
                      <Button
                        onClick={() => updateJobStatus(nextStatus.next)}
                        disabled={updating}
                        className="w-full md:w-auto"
                      >
                        <nextStatus.icon className="h-4 w-4 mr-2" />
                        {updating ? 'Updating...' : nextStatus.label}
                      </Button>

                      {job.status === 'in_progress' && (
                        <Button
                          onClick={() => updateJobStatus('needs_attention')}
                          disabled={updating}
                          variant="destructive"
                          className="w-full md:w-auto ml-0 md:ml-2 mt-2 md:mt-0"
                        >
                          <AlertCircle className="h-4 w-4 mr-2" />
                          Mark Needs Attention
                        </Button>
                      )}
                    </div>
                  )}
                </TabsContent>

                <TabsContent value="photos">
                  <PhotoUpload jobId={jobId} />
                </TabsContent>

                <TabsContent value="notes">
                  <div className="space-y-4">
                    <div>
                      <h3 className="font-semibold mb-2">Job Notes</h3>
                      <p className="text-sm text-muted-foreground">
                        {job.notes || 'No notes added'}
                      </p>
                    </div>
                    {job.completion_notes && (
                      <div>
                        <h3 className="font-semibold mb-2">Completion Notes</h3>
                        <p className="text-sm text-muted-foreground">
                          {job.completion_notes}
                        </p>
                      </div>
                    )}
                  </div>
                </TabsContent>

                <TabsContent value="activity">
                  <div className="text-sm text-muted-foreground">
                    Activity log will be implemented soon
                  </div>
                </TabsContent>
              </Tabs>
            </CardContent>
          </Card>
        </div>

        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Customer Information</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div>
                <p className="font-semibold">{customer?.name}</p>
                {customer?.email && (
                  <p className="text-sm text-muted-foreground">{customer.email}</p>
                )}
                {customer?.phone && (
                  <div className="flex items-center gap-2 mt-1">
                    <Phone className="h-4 w-4 text-muted-foreground" />
                    <span className="text-sm">{customer.phone}</span>
                  </div>
                )}
              </div>
            </CardContent>
          </Card>

          {proposal && (
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Related Proposal</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  <p className="text-sm">
                    <span className="font-semibold">Proposal #:</span> {proposal.proposal_number}
                  </p>
                  <p className="text-sm">
                    <span className="font-semibold">Title:</span> {proposal.title}
                  </p>
                  <p className="text-sm">
                    <span className="font-semibold">Total:</span> ${proposal.total.toFixed(2)}
                  </p>
                  <Button
                    variant="outline"
                    size="sm"
                    className="w-full mt-3"
                    onClick={() => router.push(`/proposals/${proposal.id}`)}
                  >
                    View Proposal
                  </Button>
                </div>
              </CardContent>
            </Card>
          )}

          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Time Tracking</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-2 text-sm">
                {job.actual_start_time && (
                  <div>
                    <span className="font-semibold">Started:</span>
                    <p className="text-muted-foreground">
                      {format(new Date(job.actual_start_time), 'PPp')}
                    </p>
                  </div>
                )}
                {job.actual_end_time && (
                  <div>
                    <span className="font-semibold">Completed:</span>
                    <p className="text-muted-foreground">
                      {format(new Date(job.actual_end_time), 'PPp')}
                    </p>
                  </div>
                )}
                {!job.actual_start_time && (
                  <p className="text-muted-foreground">Not started yet</p>
                )}
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
EOF

echo "✅ Files created successfully!"
echo ""
echo "📋 NEXT STEPS:"
echo ""
echo "1️⃣ RUN THE SQL IN SUPABASE:"
echo "   - Copy the contents of supabase_setup.sql"
echo "   - Go to Supabase SQL Editor"
echo "   - Paste and run the SQL"
echo ""
echo "2️⃣ CREATE TECHNICIAN USER:"
echo "   a) Go to Supabase Dashboard > Authentication > Users"
echo "   b) Click 'Add user' → 'Create new user'"
echo "   c) Enter:"
echo "      Email: technician@servicepro.com"
echo "      Password: Test123!"
echo "   d) Click 'Create user' and copy the User ID"
echo "   e) Update the SQL with the actual User ID"
echo "   f) Run the INSERT statement for the profile"
echo ""
echo "3️⃣ TEST THE FIXES:"
echo "   - Try creating a job from an approved proposal"
echo "   - Test job status updates"
echo "   - Test photo uploads"
echo ""

# Commit changes
git add .
git commit -m "fix: update job status handling and create setup SQL for technician and storage"
git push origin main

echo "✅ Changes committed and pushed!"