#!/bin/bash
echo "🔧 Fixing job status constraint and navigation issues..."

# Fix 1: Update JobDetailView to use correct status values
echo "📝 Updating JobDetailView with correct status values..."
cat > app/jobs/[id]/JobDetailView.tsx << 'EOF'
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
EOF

# Fix 2: Update navigation components to use correct href values
echo "📝 Fixing ProposalsList navigation links..."
cat > app/proposals/ProposalsList.tsx << 'EOF'
'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { Proposal } from '@/app/types';
import { createClient } from '@/lib/supabase/client';
import Link from 'next/link';
import { Plus, Send, Eye, Grid3X3, List } from 'lucide-react';
import { toast } from 'sonner';
import SendProposalModal from './SendProposalModal';

export default function ProposalsList({ initialProposals }: { initialProposals: Proposal[] }) {
  const router = useRouter();
  const [proposals, setProposals] = useState<Proposal[]>(initialProposals);
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('list');
  const [sendModalOpen, setSendModalOpen] = useState(false);
  const [selectedProposal, setSelectedProposal] = useState<Proposal | null>(null);
  const supabase = createClient();

  useEffect(() => {
    const channel = supabase
      .channel('proposals_changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'proposals' }, () => {
        fetchProposals();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  const fetchProposals = async () => {
    const { data, error } = await supabase
      .from('proposals')
      .select(`
        *,
        customers!inner (
          id,
          name,
          email,
          phone
        )
      `)
      .order('updated_at', { ascending: false });

    if (!error && data) {
      setProposals(data);
    }
  };

  const handleSendProposal = (proposal: Proposal) => {
    setSelectedProposal(proposal);
    setSendModalOpen(true);
  };

  const getStatusBadge = (status: string | null, paidAt?: string | null) => {
    if (paidAt) {
      return <Badge className="bg-purple-100 text-purple-800">Paid</Badge>;
    }
    
    switch (status) {
      case 'draft':
        return <Badge variant="secondary">Draft</Badge>;
      case 'sent':
        return <Badge className="bg-blue-100 text-blue-800">Sent</Badge>;
      case 'approved':
        return <Badge className="bg-green-100 text-green-800">Approved</Badge>;
      case 'rejected':
        return <Badge className="bg-red-100 text-red-800">Rejected</Badge>;
      default:
        return <Badge variant="secondary">Draft</Badge>;
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Proposals</h1>
          <p className="text-muted-foreground">
            Manage your service proposals
          </p>
        </div>
        <div className="flex gap-2">
          <div className="flex gap-1 bg-muted rounded-md p-1">
            <Button
              variant={viewMode === 'grid' ? 'secondary' : 'ghost'}
              size="sm"
              onClick={() => setViewMode('grid')}
            >
              <Grid3X3 className="h-4 w-4" />
            </Button>
            <Button
              variant={viewMode === 'list' ? 'secondary' : 'ghost'}
              size="sm"
              onClick={() => setViewMode('list')}
            >
              <List className="h-4 w-4" />
            </Button>
          </div>
          <Button asChild>
            <Link href="/proposals/new">
              <Plus className="mr-2 h-4 w-4" />
              New Proposal
            </Link>
          </Button>
        </div>
      </div>

      {viewMode === 'grid' ? (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {proposals.map((proposal) => (
            <Card key={proposal.id} className="hover:shadow-lg transition-shadow">
              <CardHeader>
                <div className="flex justify-between items-start">
                  <div>
                    <CardTitle className="text-lg">{proposal.proposal_number}</CardTitle>
                    <p className="text-sm text-muted-foreground mt-1">
                      {proposal.customers?.name || 'No customer'}
                    </p>
                  </div>
                  {getStatusBadge(proposal.status, proposal.deposit_paid_at)}
                </div>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div>
                    <p className="text-sm text-muted-foreground">Amount</p>
                    <p className="text-2xl font-bold">${(proposal.total || 0).toFixed(2)}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Last Updated</p>
                    <p className="text-sm">
                      {new Date(proposal.updated_at).toLocaleDateString()}
                    </p>
                  </div>
                  <div className="flex gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      className="flex-1"
                      asChild
                    >
                      <Link href={`/proposals/${proposal.id}`}>
                        <Eye className="mr-2 h-4 w-4" />
                        View
                      </Link>
                    </Button>
                    {proposal.status === 'draft' && (
                      <Button
                        size="sm"
                        className="flex-1 bg-green-600 hover:bg-green-700"
                        onClick={() => handleSendProposal(proposal)}
                      >
                        <Send className="mr-2 h-4 w-4" />
                        Send
                      </Button>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : (
        <Card>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Proposal #</TableHead>
                <TableHead>Customer</TableHead>
                <TableHead>Amount</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Updated</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {proposals.map((proposal) => (
                <TableRow key={proposal.id}>
                  <TableCell className="font-medium">{proposal.proposal_number}</TableCell>
                  <TableCell>{proposal.customers?.name || 'No customer'}</TableCell>
                  <TableCell>${(proposal.total || 0).toFixed(2)}</TableCell>
                  <TableCell>{getStatusBadge(proposal.status, proposal.deposit_paid_at)}</TableCell>
                  <TableCell>{new Date(proposal.updated_at).toLocaleDateString()}</TableCell>
                  <TableCell className="text-right">
                    <div className="flex justify-end gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        asChild
                      >
                        <Link href={`/proposals/${proposal.id}`}>
                          <Eye className="mr-2 h-4 w-4" />
                          View
                        </Link>
                      </Button>
                      {proposal.status === 'draft' && (
                        <Button
                          size="sm"
                          className="bg-green-600 hover:bg-green-700"
                          onClick={() => handleSendProposal(proposal)}
                        >
                          <Send className="mr-2 h-4 w-4" />
                          Send
                        </Button>
                      )}
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </Card>
      )}

      {sendModalOpen && selectedProposal && (
        <SendProposalModal
          proposal={selectedProposal}
          open={sendModalOpen}
          onOpenChange={setSendModalOpen}
          onSent={fetchProposals}
        />
      )}
    </div>
  );
}
EOF

# Fix 3: Update DashboardContent to use correct Link href
echo "📝 Fixing DashboardContent navigation link..."
cat > app/DashboardContent.tsx << 'EOF'
'use client';

import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { DollarSign, FileText, Users, Briefcase } from 'lucide-react';
import Link from 'next/link';
import { createClient } from '@/lib/supabase/client';

export default function DashboardContent() {
  const [stats, setStats] = useState({
    totalRevenue: 0,
    activeProposals: 0,
    totalCustomers: 0,
    activeJobs: 0
  });
  const [loading, setLoading] = useState(true);
  const supabase = createClient();

  useEffect(() => {
    fetchDashboardStats();
  }, []);

  const fetchDashboardStats = async () => {
    try {
      // Fetch revenue from paid proposals
      const { data: proposals, error: proposalsError } = await supabase
        .from('proposals')
        .select('deposit_amount, progress_payment_amount, final_payment_amount, deposit_paid_at, progress_paid_at, final_paid_at, total');

      if (!proposalsError && proposals) {
        const totalRevenue = proposals.reduce((sum, proposal) => {
          let proposalRevenue = 0;
          
          // Add deposits
          if (proposal.deposit_paid_at && proposal.deposit_amount) {
            proposalRevenue += proposal.deposit_amount;
          }
          
          // Add progress payments
          if (proposal.progress_paid_at && proposal.progress_payment_amount) {
            proposalRevenue += proposal.progress_payment_amount;
          }
          
          // Add final payments
          if (proposal.final_paid_at && proposal.final_payment_amount) {
            proposalRevenue += proposal.final_payment_amount;
          }
          
          // If no staged payments but deposit is paid, count full amount
          if (proposal.deposit_paid_at && !proposal.deposit_amount && proposal.total) {
            proposalRevenue = proposal.total;
          }
          
          return sum + proposalRevenue;
        }, 0);

        const activeProposals = proposals.filter(p => 
          !p.deposit_paid_at || 
          (p.deposit_paid_at && (!p.progress_paid_at || !p.final_paid_at))
        ).length;

        setStats(prev => ({ ...prev, totalRevenue, activeProposals }));
      }

      // Fetch total customers
      const { count: customersCount } = await supabase
        .from('customers')
        .select('*', { count: 'exact', head: true });

      if (customersCount !== null) {
        setStats(prev => ({ ...prev, totalCustomers: customersCount }));
      }

      // Fetch active jobs
      const { count: jobsCount } = await supabase
        .from('jobs')
        .select('*', { count: 'exact', head: true })
        .in('status', ['scheduled', 'in_progress', 'needs_attention']);

      if (jobsCount !== null) {
        setStats(prev => ({ ...prev, activeJobs: jobsCount }));
      }
    } catch (error) {
      console.error('Error fetching dashboard stats:', error);
    } finally {
      setLoading(false);
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);
  };

  if (loading) {
    return <div className="flex justify-center items-center h-64">Loading...</div>;
  }

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Dashboard</h1>
        <p className="text-muted-foreground">
          Welcome to your service management dashboard
        </p>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Revenue</CardTitle>
            <DollarSign className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{formatCurrency(stats.totalRevenue)}</div>
            <p className="text-xs text-muted-foreground">From all paid proposals</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Active Proposals</CardTitle>
            <FileText className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.activeProposals}</div>
            <Link href="/proposals" className="text-xs text-blue-600 hover:underline">
              View all proposals
            </Link>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Customers</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalCustomers}</div>
            <Link href="/customers" className="text-xs text-blue-600 hover:underline">
              View all customers
            </Link>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Active Jobs</CardTitle>
            <Briefcase className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.activeJobs}</div>
            <Link href="/jobs" className="text-xs text-blue-600 hover:underline">
              View all jobs
            </Link>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
EOF

# Check for errors
if [ $? -ne 0 ]; then
    echo "❌ Error writing files"
    exit 1
fi

# Check TypeScript compilation
echo "🔍 Checking TypeScript compilation..."
npx tsc --noEmit

# Commit and push
git add .
git commit -m "fix: job status constraint error and navigation redirects

- Updated JobDetailView to use correct status values (scheduled, in_progress, needs_attention, completed, cancelled)
- Fixed navigation links in ProposalsList using correct Link components with href
- Fixed DashboardContent 'View all proposals' link to use correct href
- Removed underscores from status display labels for better readability"
git push origin main

echo "✅ Fixed job status constraint and navigation issues!"
echo ""
echo "📝 Summary of changes:"
echo "1. Job status now uses correct values that match database constraints"
echo "2. All navigation links now properly route to /proposals instead of dashboard"
echo "3. Status update buttons show appropriate options based on current status"
echo ""
echo "🔧 Next steps:"
echo "1. Test the 'Start Job' button - it should change status from 'scheduled' to 'in_progress'"
echo "2. Verify all navigation links work correctly"
echo "3. Check that job status updates are saved properly"