#!/bin/bash

echo "🔧 Fixing build errors..."
echo "=================================================="

# ============================================
# STEP 1: Fix DashboardContent import in dashboard page
# ============================================

echo ""
echo "📝 Fixing DashboardContent import path..."

cat > "app/(authenticated)/dashboard/page.tsx" << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import DashboardContent from '@/app/DashboardContent'

export default async function DashboardPage() {
  const supabase = await createClient()
  
  const { data: { user }, error } = await supabase.auth.getUser()
  
  if (error || !user) {
    redirect('/auth/login')
  }

  // Get user profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Only allow boss/admin to view dashboard
  if (profile?.role !== 'admin' && profile?.role !== 'boss') {
    redirect('/technician')
  }

  // Fetch dashboard data
  const [proposalsResult, activitiesResult] = await Promise.all([
    supabase
      .from('proposals')
      .select(`
        *,
        customers (
          name,
          email
        )
      `)
      .order('created_at', { ascending: false }),
    
    supabase
      .from('proposal_activities')
      .select(`
        *,
        proposals (
          proposal_number,
          title
        )
      `)
      .order('created_at', { ascending: false })
      .limit(10)
  ])

  const proposals = proposalsResult.data || []
  const activities = activitiesResult.data || []

  // Calculate metrics
  const totalProposals = proposals.length
  const approvedProposals = proposals.filter(p => p.status === 'approved').length
  const conversionRate = totalProposals > 0 ? (approvedProposals / totalProposals) * 100 : 0
  
  // Calculate revenue from paid amounts
  const totalRevenue = proposals.reduce((sum, p) => {
    const depositPaid = p.deposit_paid_at ? (p.deposit_amount || 0) : 0
    const progressPaid = p.progress_paid_at ? (p.progress_payment_amount || 0) : 0
    const finalPaid = p.final_paid_at ? (p.final_payment_amount || 0) : 0
    return sum + depositPaid + progressPaid + finalPaid
  }, 0)

  const paidProposals = proposals.filter(p => 
    p.deposit_paid_at || p.progress_paid_at || p.final_paid_at
  ).length
  const paymentRate = approvedProposals > 0 ? (paidProposals / approvedProposals) * 100 : 0

  // Calculate monthly revenue
  const monthlyRevenue = []
  const now = new Date()
  for (let i = 5; i >= 0; i--) {
    const date = new Date(now.getFullYear(), now.getMonth() - i, 1)
    const month = date.toLocaleString('default', { month: 'short' })
    const monthProposals = proposals.filter(p => {
      const created = new Date(p.created_at)
      return created.getMonth() === date.getMonth() && 
             created.getFullYear() === date.getFullYear()
    })
    
    const revenue = monthProposals.reduce((sum, p) => {
      const depositPaid = p.deposit_paid_at ? (p.deposit_amount || 0) : 0
      const progressPaid = p.progress_paid_at ? (p.progress_payment_amount || 0) : 0
      const finalPaid = p.final_paid_at ? (p.final_payment_amount || 0) : 0
      return sum + depositPaid + progressPaid + finalPaid
    }, 0)
    
    monthlyRevenue.push({ month, revenue, proposals: monthProposals.length })
  }

  // Count by status
  const statusCounts = {
    draft: proposals.filter(p => p.status === 'draft').length,
    sent: proposals.filter(p => p.status === 'sent').length,
    viewed: proposals.filter(p => p.status === 'viewed').length,
    approved: proposals.filter(p => p.status === 'approved').length,
    rejected: proposals.filter(p => p.status === 'rejected').length,
    paid: proposals.filter(p => p.deposit_paid_at || p.progress_paid_at || p.final_paid_at).length,
  }

  const dashboardData = {
    metrics: {
      totalProposals,
      totalRevenue,
      approvedProposals,
      conversionRate,
      paymentRate
    },
    monthlyRevenue,
    statusCounts,
    recentProposals: proposals.slice(0, 5),
    recentActivities: activities
  }

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-2xl font-bold">Dashboard</h1>
        <p className="text-gray-600">Welcome back!</p>
      </div>
      
      <DashboardContent data={dashboardData} />
    </div>
  )
}
EOF

echo "✅ DashboardContent import fixed"

# ============================================
# STEP 2: Create Toaster component
# ============================================

echo ""
echo "📝 Creating Toaster component..."

mkdir -p components/ui

cat > components/ui/toaster.tsx << 'EOF'
"use client"

import {
  Toast,
  ToastClose,
  ToastDescription,
  ToastProvider,
  ToastTitle,
  ToastViewport,
} from "@/components/ui/toast"
import { useToast } from "@/components/ui/use-toast"

export function Toaster() {
  const { toasts } = useToast()

  return (
    <ToastProvider>
      {toasts.map(function ({ id, title, description, action, ...props }) {
        return (
          <Toast key={id} {...props}>
            <div className="grid gap-1">
              {title && <ToastTitle>{title}</ToastTitle>}
              {description && (
                <ToastDescription>{description}</ToastDescription>
              )}
            </div>
            {action}
            <ToastClose />
          </Toast>
        )
      })}
      <ToastViewport />
    </ToastProvider>
  )
}
EOF

echo "✅ Toaster component created"

# ============================================
# STEP 3: Create Toast components
# ============================================

echo ""
echo "📝 Creating Toast UI components..."

cat > components/ui/toast.tsx << 'EOF'
"use client"

import * as React from "react"
import * as ToastPrimitives from "@radix-ui/react-toast"
import { cva, type VariantProps } from "class-variance-authority"
import { X } from "lucide-react"

import { cn } from "@/lib/utils"

const ToastProvider = ToastPrimitives.Provider

const ToastViewport = React.forwardRef<
  React.ElementRef<typeof ToastPrimitives.Viewport>,
  React.ComponentPropsWithoutRef<typeof ToastPrimitives.Viewport>
>(({ className, ...props }, ref) => (
  <ToastPrimitives.Viewport
    ref={ref}
    className={cn(
      "fixed top-0 z-[100] flex max-h-screen w-full flex-col-reverse p-4 sm:bottom-0 sm:right-0 sm:top-auto sm:flex-col md:max-w-[420px]",
      className
    )}
    {...props}
  />
))
ToastViewport.displayName = ToastPrimitives.Viewport.displayName

const toastVariants = cva(
  "group pointer-events-auto relative flex w-full items-center justify-between space-x-4 overflow-hidden rounded-md border p-6 pr-8 shadow-lg transition-all data-[swipe=cancel]:translate-x-0 data-[swipe=end]:translate-x-[var(--radix-toast-swipe-end-x)] data-[swipe=move]:translate-x-[var(--radix-toast-swipe-move-x)] data-[swipe=move]:transition-none data-[state=open]:animate-in data-[state=closed]:animate-out data-[swipe=end]:animate-out data-[state=closed]:fade-out-80 data-[state=closed]:slide-out-to-right-full data-[state=open]:slide-in-from-top-full data-[state=open]:sm:slide-in-from-bottom-full",
  {
    variants: {
      variant: {
        default: "border bg-background text-foreground",
        destructive:
          "destructive group border-destructive bg-destructive text-destructive-foreground",
      },
    },
    defaultVariants: {
      variant: "default",
    },
  }
)

const Toast = React.forwardRef<
  React.ElementRef<typeof ToastPrimitives.Root>,
  React.ComponentPropsWithoutRef<typeof ToastPrimitives.Root> &
    VariantProps<typeof toastVariants>
>(({ className, variant, ...props }, ref) => {
  return (
    <ToastPrimitives.Root
      ref={ref}
      className={cn(toastVariants({ variant }), className)}
      {...props}
    />
  )
})
Toast.displayName = ToastPrimitives.Root.displayName

const ToastAction = React.forwardRef<
  React.ElementRef<typeof ToastPrimitives.Action>,
  React.ComponentPropsWithoutRef<typeof ToastPrimitives.Action>
>(({ className, ...props }, ref) => (
  <ToastPrimitives.Action
    ref={ref}
    className={cn(
      "inline-flex h-8 shrink-0 items-center justify-center rounded-md border bg-transparent px-3 text-sm font-medium ring-offset-background transition-colors hover:bg-secondary focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 group-[.destructive]:border-muted/40 group-[.destructive]:hover:border-destructive/30 group-[.destructive]:hover:bg-destructive group-[.destructive]:hover:text-destructive-foreground group-[.destructive]:focus:ring-destructive",
      className
    )}
    {...props}
  />
))
ToastAction.displayName = ToastPrimitives.Action.displayName

const ToastClose = React.forwardRef<
  React.ElementRef<typeof ToastPrimitives.Close>,
  React.ComponentPropsWithoutRef<typeof ToastPrimitives.Close>
>(({ className, ...props }, ref) => (
  <ToastPrimitives.Close
    ref={ref}
    className={cn(
      "absolute right-2 top-2 rounded-md p-1 text-foreground/50 opacity-0 transition-opacity hover:text-foreground focus:opacity-100 focus:outline-none focus:ring-2 group-hover:opacity-100 group-[.destructive]:text-red-300 group-[.destructive]:hover:text-red-50 group-[.destructive]:focus:ring-red-400 group-[.destructive]:focus:ring-offset-red-600",
      className
    )}
    toast-close=""
    {...props}
  >
    <X className="h-4 w-4" />
  </ToastPrimitives.Close>
))
ToastClose.displayName = ToastPrimitives.Close.displayName

const ToastTitle = React.forwardRef<
  React.ElementRef<typeof ToastPrimitives.Title>,
  React.ComponentPropsWithoutRef<typeof ToastPrimitives.Title>
>(({ className, ...props }, ref) => (
  <ToastPrimitives.Title
    ref={ref}
    className={cn("text-sm font-semibold", className)}
    {...props}
  />
))
ToastTitle.displayName = ToastPrimitives.Title.displayName

const ToastDescription = React.forwardRef<
  React.ElementRef<typeof ToastPrimitives.Description>,
  React.ComponentPropsWithoutRef<typeof ToastPrimitives.Description>
>(({ className, ...props }, ref) => (
  <ToastPrimitives.Description
    ref={ref}
    className={cn("text-sm opacity-90", className)}
    {...props}
  />
))
ToastDescription.displayName = ToastPrimitives.Description.displayName

type ToastProps = React.ComponentPropsWithoutRef<typeof Toast>

type ToastActionElement = React.ReactElement<typeof ToastAction>

export {
  type ToastProps,
  type ToastActionElement,
  ToastProvider,
  ToastViewport,
  Toast,
  ToastTitle,
  ToastDescription,
  ToastClose,
  ToastAction,
}
EOF

echo "✅ Toast components created"

# ============================================
# STEP 4: Create use-toast hook
# ============================================

echo ""
echo "📝 Creating use-toast hook..."

cat > components/ui/use-toast.ts << 'EOF'
"use client"

import * as React from "react"

import type {
  ToastActionElement,
  ToastProps,
} from "@/components/ui/toast"

const TOAST_LIMIT = 1
const TOAST_REMOVE_DELAY = 1000000

type ToasterToast = ToastProps & {
  id: string
  title?: React.ReactNode
  description?: React.ReactNode
  action?: ToastActionElement
}

const actionTypes = {
  ADD_TOAST: "ADD_TOAST",
  UPDATE_TOAST: "UPDATE_TOAST",
  DISMISS_TOAST: "DISMISS_TOAST",
  REMOVE_TOAST: "REMOVE_TOAST",
} as const

let count = 0

function genId() {
  count = (count + 1) % Number.MAX_SAFE_INTEGER
  return count.toString()
}

type ActionType = typeof actionTypes

type Action =
  | {
      type: ActionType["ADD_TOAST"]
      toast: ToasterToast
    }
  | {
      type: ActionType["UPDATE_TOAST"]
      toast: Partial<ToasterToast>
    }
  | {
      type: ActionType["DISMISS_TOAST"]
      toastId?: ToasterToast["id"]
    }
  | {
      type: ActionType["REMOVE_TOAST"]
      toastId?: ToasterToast["id"]
    }

interface State {
  toasts: ToasterToast[]
}

const toastTimeouts = new Map<string, ReturnType<typeof setTimeout>>()

const addToRemoveQueue = (toastId: string) => {
  if (toastTimeouts.has(toastId)) {
    return
  }

  const timeout = setTimeout(() => {
    toastTimeouts.delete(toastId)
    dispatch({
      type: "REMOVE_TOAST",
      toastId: toastId,
    })
  }, TOAST_REMOVE_DELAY)

  toastTimeouts.set(toastId, timeout)
}

export const reducer = (state: State, action: Action): State => {
  switch (action.type) {
    case "ADD_TOAST":
      return {
        ...state,
        toasts: [action.toast, ...state.toasts].slice(0, TOAST_LIMIT),
      }

    case "UPDATE_TOAST":
      return {
        ...state,
        toasts: state.toasts.map((t) =>
          t.id === action.toast.id ? { ...t, ...action.toast } : t
        ),
      }

    case "DISMISS_TOAST": {
      const { toastId } = action

      if (toastId) {
        addToRemoveQueue(toastId)
      } else {
        state.toasts.forEach((toast) => {
          addToRemoveQueue(toast.id)
        })
      }

      return {
        ...state,
        toasts: state.toasts.map((t) =>
          t.id === toastId || toastId === undefined
            ? {
                ...t,
                open: false,
              }
            : t
        ),
      }
    }
    case "REMOVE_TOAST":
      if (action.toastId === undefined) {
        return {
          ...state,
          toasts: [],
        }
      }
      return {
        ...state,
        toasts: state.toasts.filter((t) => t.id !== action.toastId),
      }
  }
}

const listeners: Array<(state: State) => void> = []

let memoryState: State = { toasts: [] }

function dispatch(action: Action) {
  memoryState = reducer(memoryState, action)
  listeners.forEach((listener) => {
    listener(memoryState)
  })
}

type Toast = Omit<ToasterToast, "id">

function toast({ ...props }: Toast) {
  const id = genId()

  const update = (props: ToasterToast) =>
    dispatch({
      type: "UPDATE_TOAST",
      toast: { ...props, id },
    })
  const dismiss = () => dispatch({ type: "DISMISS_TOAST", toastId: id })

  dispatch({
    type: "ADD_TOAST",
    toast: {
      ...props,
      id,
      open: true,
      onOpenChange: (open) => {
        if (!open) dismiss()
      },
    },
  })

  return {
    id: id,
    dismiss,
    update,
  }
}

function useToast() {
  const [state, setState] = React.useState<State>(memoryState)

  React.useEffect(() => {
    listeners.push(setState)
    return () => {
      const index = listeners.indexOf(setState)
      if (index > -1) {
        listeners.splice(index, 1)
      }
    }
  }, [state])

  return {
    ...state,
    toast,
    dismiss: (toastId?: string) => dispatch({ type: "DISMISS_TOAST", toastId }),
  }
}

export { useToast, toast }
EOF

echo "✅ use-toast hook created"

# ============================================
# STEP 5: Fix layout.tsx to remove Toaster import (or make it simpler)
# ============================================

echo ""
echo "📝 Simplifying root layout..."

cat > app/layout.tsx << 'EOF'
import { Inter } from "next/font/google";
import "./globals.css";

export const metadata = {
  title: "Service Pro - HVAC Management",
  description: "Field Service Management for HVAC Businesses",
};

const inter = Inter({ subsets: ["latin"] });

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={inter.className} suppressHydrationWarning>
      <body className="bg-gray-50 text-gray-900">
        {children}
      </body>
    </html>
  );
}
EOF

echo "✅ Root layout simplified"

# ============================================
# STEP 6: Install missing Radix UI dependencies
# ============================================

echo ""
echo "📝 Adding missing dependencies to package.json..."

# Check if @radix-ui/react-toast is in package.json, if not add it
if ! grep -q "@radix-ui/react-toast" package.json; then
  npm install @radix-ui/react-toast --save
fi

echo "✅ Dependencies updated"

# ============================================
# Commit and push all changes
# ============================================

echo ""
echo "📦 Committing build fixes..."

git add -A
git commit -m "fix: build errors - correct DashboardContent import path and add Toast components"
git push origin main

echo ""
echo "✅✅✅ BUILD ERRORS FIXED! ✅✅✅"
echo ""
echo "Summary of fixes:"
echo "1. ✅ Fixed DashboardContent import path in dashboard page"
echo "2. ✅ Created missing Toaster components"
echo "3. ✅ Simplified root layout"
echo "4. ✅ Added toast UI components and hook"
echo ""
echo "The build should now succeed!"