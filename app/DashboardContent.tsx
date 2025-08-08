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
