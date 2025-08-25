'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { createClient } from '@/lib/supabase/client';
import Link from 'next/link';
import { Plus, Send, Eye, Grid3X3, List } from 'lucide-react';
import { toast } from 'sonner';

interface ProposalListProps {
  initialProposals: any[];
}

export default function ProposalsList({ initialProposals }: ProposalListProps) {
  const router = useRouter();
  const [proposals, setProposals] = useState(initialProposals);
  const [viewMode, setViewMode] = useState<string>('list');
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

    if (data) {
      setProposals(data);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'draft': return 'bg-gray-100 text-gray-800';
      case 'sent': return 'bg-blue-100 text-blue-800';
      case 'viewed': return 'bg-purple-100 text-purple-800';
      case 'approved':
      case 'accepted': return 'bg-green-100 text-green-800';
      case 'rejected': return 'bg-red-100 text-red-800';
      case 'paid': return 'bg-emerald-100 text-emerald-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const formatDate = (date: string) => {
    return new Date(date).toLocaleDateString('en-US', {
      month: 'numeric',
      day: 'numeric',
      year: 'numeric'
    });
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(amount);
  };

  const handleSendProposal = async (proposalId: string, e: React.MouseEvent) => {
    e.stopPropagation();
    router.push(`/proposals/${proposalId}`);
  };

  if (viewMode === 'grid') {
    return (
      <div>
        <div className="flex justify-between items-center mb-6">
          <div>
            <h1 className="text-2xl font-bold">Proposals</h1>
            <p className="text-gray-600">Manage your service proposals</p>
          </div>
          <div className="flex gap-2">
            <div className="flex bg-gray-100 rounded-lg p-1">
              <button
                onClick={() => setViewMode('grid')}
                className={`p-2 rounded ${viewMode === 'grid' ? 'bg-white shadow' : ''}`}
              >
                <Grid3X3 className="h-4 w-4" />
              </button>
              <button
                onClick={() => setViewMode('list')}
                className={`p-2 rounded ${viewMode === 'list' ? 'bg-white shadow' : ''}`}
              >
                <List className="h-4 w-4" />
              </button>
            </div>
            <Link href="/proposals/new">
              <Button>
                <Plus className="h-4 w-4 mr-2" />
                New Proposal
              </Button>
            </Link>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {proposals.map((proposal) => (
            <Card key={proposal.id} className="hover:shadow-lg transition-shadow">
              <CardHeader>
                <div className="flex justify-between items-start">
                  <Link href={`/proposals/${proposal.id}`} className="hover:underline">
                    <CardTitle className="text-lg">{proposal.proposal_number}</CardTitle>
                  </Link>
                  <Badge className={getStatusColor(proposal.status)}>
                    {proposal.status}
                  </Badge>
                </div>
                <p className="text-sm text-gray-600">
                  {proposal.customers?.name || 'No customer'}
                </p>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  <p className="text-2xl font-bold">{formatCurrency(proposal.total || 0)}</p>
                  <p className="text-sm text-gray-500">Updated {formatDate(proposal.updated_at)}</p>
                  <div className="flex gap-2 pt-2">
                    <Link href={`/proposals/${proposal.id}`} className="flex-1">
                      <Button variant="outline" className="w-full" size="sm">
                        <Eye className="h-4 w-4 mr-2" />
                        View
                      </Button>
                    </Link>
                    {proposal.status === 'draft' && (
                      <Button 
                        size="sm" 
                        className="flex-1 bg-green-600 hover:bg-green-700"
                        onClick={(e) => handleSendProposal(proposal.id, e)}
                      >
                        <Send className="h-4 w-4 mr-2" />
                        Send
                      </Button>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-2xl font-bold">Proposals</h1>
          <p className="text-gray-600">Manage your service proposals</p>
        </div>
        <div className="flex gap-2">
          <div className="flex bg-gray-100 rounded-lg p-1">
            <button
              onClick={() => setViewMode('grid')}
              className={`p-2 rounded ${viewMode === 'grid' ? 'bg-white shadow' : ''}`}
            >
              <Grid3X3 className="h-4 w-4" />
            </button>
            <button
              onClick={() => setViewMode('list')}
              className={`p-2 rounded ${viewMode === 'list' ? 'bg-white shadow' : ''}`}
            >
              <List className="h-4 w-4" />
            </button>
          </div>
          <Link href="/proposals/new">
            <Button>
              <Plus className="h-4 w-4 mr-2" />
              New Proposal
            </Button>
          </Link>
        </div>
      </div>

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
                <TableCell>
                  <Link 
                    href={`/proposals/${proposal.id}`} 
                    className="font-medium hover:underline text-blue-600"
                  >
                    {proposal.proposal_number}
                  </Link>
                </TableCell>
                <TableCell>{proposal.customers?.name || 'No customer'}</TableCell>
                <TableCell>{formatCurrency(proposal.total || 0)}</TableCell>
                <TableCell>
                  <Badge className={getStatusColor(proposal.status)}>
                    {proposal.status}
                  </Badge>
                </TableCell>
                <TableCell>{formatDate(proposal.updated_at)}</TableCell>
                <TableCell className="text-right">
                  <div className="flex justify-end gap-2">
                    <Link href={`/proposals/${proposal.id}`}>
                      <Button variant="ghost" size="sm">
                        <Eye className="h-4 w-4 mr-2" />
                        View
                      </Button>
                    </Link>
                    {proposal.status === 'draft' && (
                      <Button 
                        size="sm" 
                        className="bg-green-600 hover:bg-green-700"
                        onClick={(e) => handleSendProposal(proposal.id, e)}
                      >
                        <Send className="h-4 w-4 mr-2" />
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
    </div>
  );
}
