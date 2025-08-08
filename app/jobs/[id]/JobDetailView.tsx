'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { MapPin, Phone, Mail, Calendar, User, ChevronLeft, Camera, Clock, CheckCircle, AlertCircle, XCircle } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { Job } from '@/app/types';
import { toast } from 'sonner';
import PhotoUpload from './PhotoUpload';

interface JobDetailViewProps {
  jobId: string;
}

export default function JobDetailView({ jobId }: JobDetailViewProps) {
  const [job, setJob] = useState<Job | null>(null);
  const [loading, setLoading] = useState(true);
  const [updating, setUpdating] = useState(false);
  const router = useRouter();
  const supabase = createClient();

  useEffect(() => {
    fetchJob();
  }, [jobId]);

  const fetchJob = async () => {
    try {
      const { data, error } = await supabase
        .from('jobs')
        .select(`
          *,
          customers (
            id,
            name,
            email,
            phone
          ),
          proposals (
            id,
            proposal_number,
            subtotal,
            tax_amount,
            total
          ),
          profiles!jobs_assigned_technician_id_fkey (
            id,
            full_name
          )
        `)
        .eq('id', jobId)
        .single();

      if (error) throw error;
      setJob(data);
    } catch (error) {
      console.error('Error fetching job:', error);
      toast.error('Failed to load job details');
    } finally {
      setLoading(false);
    }
  };

  const updateJobStatus = async (newStatus: string) => {
    if (!job) return;
    
    setUpdating(true);
    try {
      const { error } = await supabase
        .from('jobs')
        .update({ 
          status: newStatus,
          updated_at: new Date().toISOString()
        })
        .eq('id', job.id);

      if (error) throw error;

      toast.success('Job status updated successfully');
      await fetchJob();
    } catch (error: any) {
      console.error('Error updating status:', error);
      toast.error(error.message || 'Failed to update job status');
    } finally {
      setUpdating(false);
    }
  };

  const getStatusBadgeVariant = (status: string) => {
    switch (status) {
      case 'scheduled':
        return 'secondary';
      case 'in_progress':
        return 'default';
      case 'needs_attention':
        return 'destructive';
      case 'completed':
        return 'success';
      case 'cancelled':
        return 'outline';
      default:
        return 'secondary';
    }
  };

  const getNextStatus = (currentStatus: string) => {
    switch (currentStatus) {
      case 'scheduled':
        return { status: 'in_progress', label: 'Start Job', icon: Clock };
      case 'in_progress':
        return { status: 'completed', label: 'Complete Job', icon: CheckCircle };
      case 'needs_attention':
        return { status: 'in_progress', label: 'Resume Job', icon: Clock };
      case 'completed':
        return null;
      case 'cancelled':
        return null;
      default:
        return null;
    }
  };

  if (loading) {
    return <div className="flex justify-center items-center h-64">Loading...</div>;
  }

  if (!job) {
    return <div className="text-center text-gray-500">Job not found</div>;
  }

  const customer = job.customers;
  const proposal = job.proposals;
  const technician = job.profiles;
  const nextStatusAction = getNextStatus(job.status);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <Button
          variant="ghost"
          onClick={() => router.push('/jobs')}
          className="flex items-center"
        >
          <ChevronLeft className="mr-2 h-4 w-4" />
          Back to Jobs
        </Button>
        <Badge variant={getStatusBadgeVariant(job.job_type)}>
          {job.job_type.charAt(0).toUpperCase() + job.job_type.slice(1)}
        </Badge>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center justify-between">
              Job Status
              <Badge variant={getStatusBadgeVariant(job.status)}>
                {job.status.split('_').map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(' ')}
              </Badge>
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <p className="text-sm text-gray-500">Current Status:</p>
              <p className="font-medium">{job.status.split('_').map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(' ')}</p>
            </div>
            
            {nextStatusAction && (
              <Button
                onClick={() => updateJobStatus(nextStatusAction.status)}
                disabled={updating}
                className="w-full"
              >
                <nextStatusAction.icon className="mr-2 h-4 w-4" />
                {nextStatusAction.label}
              </Button>
            )}

            {job.status === 'in_progress' && (
              <Button
                onClick={() => updateJobStatus('needs_attention')}
                disabled={updating}
                variant="destructive"
                className="w-full"
              >
                <AlertCircle className="mr-2 h-4 w-4" />
                Mark as Needs Attention
              </Button>
            )}

            {(job.status === 'scheduled' || job.status === 'in_progress') && (
              <Button
                onClick={() => updateJobStatus('cancelled')}
                disabled={updating}
                variant="outline"
                className="w-full"
              >
                <XCircle className="mr-2 h-4 w-4" />
                Cancel Job
              </Button>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Customer Information</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <p className="text-sm text-gray-500">Name</p>
              <p className="font-medium">{customer?.name || 'N/A'}</p>
            </div>
            <div>
              <p className="text-sm text-gray-500">Contact</p>
              <div className="space-y-1">
                {customer?.phone && (
                  <a href={`tel:${customer.phone}`} className="flex items-center text-blue-600 hover:underline">
                    <Phone className="mr-2 h-4 w-4" />
                    {customer.phone}
                  </a>
                )}
                {customer?.email && (
                  <a href={`mailto:${customer.email}`} className="flex items-center text-blue-600 hover:underline">
                    <Mail className="mr-2 h-4 w-4" />
                    {customer.email}
                  </a>
                )}
              </div>
            </div>
            <div>
              <p className="text-sm text-gray-500">Service Address</p>
              <div className="flex items-start">
                <MapPin className="mr-2 h-4 w-4 mt-0.5 text-gray-400" />
                <p className="font-medium">{job.service_address || 'Same as billing'}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Schedule & Assignment</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <p className="text-sm text-gray-500">Scheduled</p>
              <div className="flex items-center">
                <Calendar className="mr-2 h-4 w-4 text-gray-400" />
                <p className="font-medium">
                  {job.scheduled_date
                    ? new Date(job.scheduled_date).toLocaleDateString('en-US', {
                        weekday: 'long',
                        year: 'numeric',
                        month: 'long',
                        day: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit'
                      })
                    : 'Not scheduled'}
                </p>
              </div>
            </div>
            <div>
              <p className="text-sm text-gray-500">Assigned Technician</p>
              <div className="flex items-center">
                <User className="mr-2 h-4 w-4 text-gray-400" />
                <p className="font-medium">{technician?.full_name || 'Not assigned'}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        {proposal && (
          <Card>
            <CardHeader>
              <CardTitle>Related Proposal</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <p className="text-sm text-gray-500">Proposal Number</p>
                <p className="font-medium">{proposal.proposal_number}</p>
              </div>
              <div>
                <p className="text-sm text-gray-500">Amount</p>
                <p className="font-medium text-lg">${proposal.total.toFixed(2)}</p>
              </div>
              <Button
                variant="outline"
                onClick={() => router.push(`/proposals/${proposal.id}`)}
                className="w-full"
              >
                View Proposal
              </Button>
            </CardContent>
          </Card>
        )}
      </div>

      {job.status === 'in_progress' && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center">
              <Camera className="mr-2 h-5 w-5" />
              Job Photos
            </CardTitle>
          </CardHeader>
          <CardContent>
            <PhotoUpload jobId={job.id} onPhotoUploaded={fetchJob} />
          </CardContent>
        </Card>
      )}
    </div>
  );
}
