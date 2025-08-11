'use client';

import { useState, useEffect } from 'react';
import { createClientComponentClient } from '@supabase/auth-helpers-nextjs';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { CheckCircle, XCircle, AlertCircle, RefreshCw, Database, Shield, Route, User } from 'lucide-react';

export const dynamic = 'force-dynamic';

export default function DiagnosticPage() {
  const [diagnostics, setDiagnostics] = useState<any>({
    auth: null,
    database: {},
    routing: [],
    permissions: [],
    environment: {},
    errors: []
  });
  const [loading, setLoading] = useState(true);
  const supabase = createClientComponentClient();

  const runDiagnostics = async () => {
    setLoading(true);
    const results: any = {
      auth: null,
      database: {},
      routing: [],
      permissions: [],
      environment: {},
      errors: []
    };

    try {
      // Check authentication
      const { data: { user }, error: authError } = await supabase.auth.getUser();
      if (authError) {
        results.errors.push({ type: 'auth', message: authError.message });
      }
      results.auth = user;

      // Get user profile and role
      if (user) {
        const { data: profile, error: profileError } = await supabase
          .from('profiles')
          .select('*, organizations(*)')
          .eq('id', user.id)
          .single();
        
        if (profileError) {
          results.errors.push({ type: 'profile', message: profileError.message });
        } else {
          results.auth = { ...user, profile };
        }
      }

      // Test database connectivity and tables
      const tables = ['proposals', 'customers', 'jobs', 'invoices', 'profiles'];
      for (const table of tables) {
        try {
          const { count, error } = await supabase
            .from(table)
            .select('*', { count: 'exact', head: true });
          
          results.database[table] = {
            accessible: !error,
            count: count || 0,
            error: error?.message
          };
        } catch (e: any) {
          results.database[table] = {
            accessible: false,
            error: e.message
          };
        }
      }

      // Check routing patterns
      const routes = [
        { path: '/', name: 'Dashboard', requiresAuth: true },
        { path: '/proposals', name: 'Proposals', requiresAuth: true },
        { path: '/customers', name: 'Customers', requiresAuth: true },
        { path: '/jobs', name: 'Jobs', requiresAuth: true },
        { path: '/invoices', name: 'Invoices', requiresAuth: true },
        { path: '/technicians', name: 'Technicians', requiresAuth: true },
        { path: '/technician', name: 'Technician Portal', requiresAuth: true },
        { path: '/proposal/view/[token]', name: 'Customer Proposal View', requiresAuth: false },
        { path: '/auth/signin', name: 'Sign In', requiresAuth: false },
      ];
      results.routing = routes;

      // Test RLS permissions
      if (user) {
        const permissionTests = [
          {
            name: 'Read own proposals',
            test: async () => {
              const { data, error } = await supabase
                .from('proposals')
                .select('id')
                .limit(1);
              return { success: !error, error: error?.message };
            }
          },
          {
            name: 'Read customers',
            test: async () => {
              const { data, error } = await supabase
                .from('customers')
                .select('id')
                .limit(1);
              return { success: !error, error: error?.message };
            }
          }
        ];

        for (const test of permissionTests) {
          try {
            const result = await test.test();
            results.permissions.push({
              name: test.name,
              ...result
            });
          } catch (e: any) {
            results.permissions.push({
              name: test.name,
              success: false,
              error: e.message
            });
          }
        }
      }

      // Check environment variables (only on client side)
      if (typeof window !== 'undefined') {
        results.environment = {
          NEXT_PUBLIC_SUPABASE_URL: !!process.env.NEXT_PUBLIC_SUPABASE_URL,
          NEXT_PUBLIC_SUPABASE_ANON_KEY: !!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
          NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY: !!process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY,
          NODE_ENV: process.env.NODE_ENV || 'production',
        };
      }

    } catch (e: any) {
      results.errors.push({ type: 'general', message: e.message });
    }

    setDiagnostics(results);
    setLoading(false);
  };

  useEffect(() => {
    runDiagnostics();
  }, []);

  const StatusIcon = ({ success }: { success: boolean }) => {
    return success ? 
      <CheckCircle className="w-4 h-4 text-green-500" /> : 
      <XCircle className="w-4 h-4 text-red-500" />;
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="container mx-auto p-6 max-w-7xl">
      <Card>
        <CardHeader>
          <div className="flex justify-between items-center">
            <div>
              <CardTitle>Service Pro Diagnostics</CardTitle>
              <CardDescription>System health check and troubleshooting tools</CardDescription>
            </div>
            <Button 
              onClick={runDiagnostics} 
              disabled={loading}
              variant="outline"
            >
              <RefreshCw className={`w-4 h-4 mr-2 ${loading ? 'animate-spin' : ''}`} />
              Refresh
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {diagnostics.errors.length > 0 && (
            <Alert className="mb-6" variant="destructive">
              <AlertCircle className="h-4 w-4" />
              <AlertDescription>
                <strong>Errors detected:</strong>
                <ul className="mt-2 list-disc list-inside">
                  {diagnostics.errors.map((error: any, i: number) => (
                    <li key={i}>{error.type}: {error.message}</li>
                  ))}
                </ul>
              </AlertDescription>
            </Alert>
          )}

          <Tabs defaultValue="auth" className="w-full">
            <TabsList className="grid w-full grid-cols-5">
              <TabsTrigger value="auth">
                <User className="w-4 h-4 mr-2" />
                Auth
              </TabsTrigger>
              <TabsTrigger value="database">
                <Database className="w-4 h-4 mr-2" />
                Database
              </TabsTrigger>
              <TabsTrigger value="routing">
                <Route className="w-4 h-4 mr-2" />
                Routes
              </TabsTrigger>
              <TabsTrigger value="permissions">
                <Shield className="w-4 h-4 mr-2" />
                RLS
              </TabsTrigger>
              <TabsTrigger value="environment">
                <AlertCircle className="w-4 h-4 mr-2" />
                Env
              </TabsTrigger>
            </TabsList>

            <TabsContent value="auth">
              <Card>
                <CardHeader>
                  <CardTitle className="text-lg">Authentication Status</CardTitle>
                </CardHeader>
                <CardContent>
                  {diagnostics.auth ? (
                    <div className="space-y-2">
                      <div className="flex items-center gap-2">
                        <StatusIcon success={true} />
                        <span className="font-medium">Authenticated</span>
                      </div>
                      <div className="pl-6 space-y-1 text-sm">
                        <p><strong>User ID:</strong> {diagnostics.auth.id}</p>
                        <p><strong>Email:</strong> {diagnostics.auth.email}</p>
                        <p><strong>Role:</strong> 
                          <Badge className="ml-2" variant={diagnostics.auth.profile?.role === 'boss' ? 'default' : 'secondary'}>
                            {diagnostics.auth.profile?.role || 'No role'}
                          </Badge>
                        </p>
                        {diagnostics.auth.profile?.organizations && (
                          <p><strong>Organization:</strong> {diagnostics.auth.profile.organizations.name || 'None'}</p>
                        )}
                      </div>
                    </div>
                  ) : (
                    <div className="flex items-center gap-2">
                      <StatusIcon success={false} />
                      <span>Not authenticated</span>
                    </div>
                  )}
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="database">
              <Card>
                <CardHeader>
                  <CardTitle className="text-lg">Database Tables</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-2">
                    {Object.entries(diagnostics.database || {}).map(([table, info]: [string, any]) => (
                      <div key={table} className="flex items-center justify-between py-2 border-b">
                        <div className="flex items-center gap-2">
                          <StatusIcon success={info.accessible} />
                          <span className="font-mono text-sm">{table}</span>
                        </div>
                        <div className="flex items-center gap-4">
                          {info.accessible && (
                            <Badge variant="outline">{info.count} rows</Badge>
                          )}
                          {info.error && (
                            <span className="text-xs text-red-500">{info.error}</span>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="routing">
              <Card>
                <CardHeader>
                  <CardTitle className="text-lg">Application Routes</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-2">
                    {diagnostics.routing.map((route: any) => (
                      <div key={route.path} className="flex items-center justify-between py-2 border-b">
                        <div className="flex items-center gap-2">
                          <span className="font-mono text-sm">{route.path}</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <span className="text-sm text-muted-foreground">{route.name}</span>
                          <Badge variant={route.requiresAuth ? 'default' : 'secondary'}>
                            {route.requiresAuth ? 'Protected' : 'Public'}
                          </Badge>
                        </div>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="permissions">
              <Card>
                <CardHeader>
                  <CardTitle className="text-lg">RLS Permissions</CardTitle>
                </CardHeader>
                <CardContent>
                  {diagnostics.auth ? (
                    <div className="space-y-2">
                      {diagnostics.permissions.map((perm: any, i: number) => (
                        <div key={i} className="flex items-center justify-between py-2 border-b">
                          <div className="flex items-center gap-2">
                            <StatusIcon success={perm.success} />
                            <span className="text-sm">{perm.name}</span>
                          </div>
                          {perm.error && (
                            <span className="text-xs text-red-500">{perm.error}</span>
                          )}
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p className="text-sm text-muted-foreground">Sign in to test permissions</p>
                  )}
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="environment">
              <Card>
                <CardHeader>
                  <CardTitle className="text-lg">Environment Variables</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-2">
                    {Object.entries(diagnostics.environment || {}).map(([key, value]) => (
                      <div key={key} className="flex items-center justify-between py-2 border-b">
                        <span className="font-mono text-sm">{key}</span>
                        {typeof value === 'boolean' ? (
                          <StatusIcon success={value} />
                        ) : (
                          <Badge variant="outline">{String(value)}</Badge>
                        )}
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>

          <div className="mt-6 p-4 bg-muted rounded-lg">
            <h3 className="font-medium mb-2">Quick Actions</h3>
            <div className="flex gap-2 flex-wrap">
              <Button variant="outline" size="sm" asChild>
                <a href="/proposals">Test Proposals Page</a>
              </Button>
              <Button variant="outline" size="sm" asChild>
                <a href="/api/health">API Health Check</a>
              </Button>
              <Button variant="outline" size="sm" onClick={() => {
                if (typeof window !== 'undefined') {
                  navigator.clipboard.writeText(JSON.stringify(diagnostics, null, 2));
                  alert('Diagnostics copied to clipboard');
                }
              }}>
                Copy Diagnostics JSON
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
