import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs';
import { cookies } from 'next/headers';
import { NextResponse } from 'next/server';

export async function GET() {
  try {
    const supabase = createRouteHandlerClient({ cookies });
    
    // Test database connection
    const { error: dbError } = await supabase
      .from('profiles')
      .select('id')
      .limit(1);
    
    // Get auth status
    const { data: { user } } = await supabase.auth.getUser();
    
    return NextResponse.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      database: !dbError ? 'connected' : 'error',
      auth: user ? 'authenticated' : 'anonymous',
      environment: process.env.NODE_ENV,
      version: process.env.npm_package_version || 'unknown'
    });
  } catch (error: any) {
    return NextResponse.json({
      status: 'error',
      timestamp: new Date().toISOString(),
      error: error.message
    }, { status: 500 });
  }
}
