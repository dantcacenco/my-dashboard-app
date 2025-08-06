# Service Pro - Field Service Management App
## Complete Project Scope & Development Plan

---

## 🎯 **Core Purpose**
A full-featured, modular web app for HVAC service businesses, modeled after Housecall Pro. Multi-tenant SaaS architecture allowing multiple companies to run under subdomains (company1.service-pro.com, company2.service-pro.com).

---

## 🏗️ **Technical Architecture**

### **Tech Stack**
- **Frontend**: Next.js (React-based PWA)
- **Backend**: Next.js API routes
- **Database**: Supabase (PostgreSQL)
- **Hosting**: Vercel (multi-tenant support)
- **File Storage**: Vercel Blob
- **Payments**: Stripe
- **Email**: SendGrid
- **SMS**: Twilio
- **Authentication**: Custom backend system

### **Progressive Web App Features**
- Installs to home screen like native app
- GPS tracking capability
- Camera access for photo uploads
- Offline functionality
- Works on all devices (iOS, Android, desktop)

### **Multi-Tenant SaaS Model**
- One codebase serves all clients
- Subdomain routing (company1.service-pro.com)
- Database isolation per tenant
- Centralized updates benefit all clients
- Monthly subscription revenue model

---

## 🔐 **Authentication & User Roles**

### **User Roles**
- **Admin/Boss**: Full system access, all features
- **Technician**: Limited to assigned jobs, time tracking, photo uploads
- **Customer**: Portal access to view invoices, proposals, schedule service

### **Authentication System**
- Custom backend (not Google Auth)
- Role-based permissions
- Secure login/logout
- Password reset functionality

---

## 📇 **Customer Management (CRM)**
- Create, view, edit, delete customer records
- Customer fields: name, phone, email, address, notes
- Link customers to jobs, invoices, proposals
- Customer communication history log
- Customer portal access

---

## 📅 **Job Scheduling & Dispatching**

### **Job Management**
- Schedule jobs for customers
- Assign technician(s) to jobs
- Job fields: date, time, location, customer, type
- Job types: Installation, Repair, Maintenance, Emergency

### **Job Status Tracking**
- Scheduled → In Progress → Needs Attention → Complete
- Cancellation/rescheduling workflow
- Auto-email notifications on status changes

### **Calendar Views**
- Boss: See all jobs and technicians
- Technicians: Only their assigned jobs
- Date/technician filtering
- List and calendar view options

---

## 🧰 **Technician Portal (Mobile-Optimized)**

### **Core Features**
- View assigned jobs only
- GPS clock-in/clock-out tracking
- Upload before/after photos (multiple photos)
- Log time worked on each job
- Record materials used (serial numbers, models)
- Mark jobs complete
- Large buttons, mobile-friendly interface

### **Photo Management**
- Tag photos as "before" or "after"
- Multiple photo upload capability
- Attach photos to specific jobs
- Cloud storage with backup

---

## 💰 **Proposal System (Phase 1 Priority)**

### **Proposal Creation**
- Boss creates proposals using master pricing database (HVAC-focused)
- Add-ons with checkbox selection (no quantities)
- Proposals never expire
- Email proposal link to customers

### **Customer Interaction**
- View proposal in browser
- Select optional add-ons (updates total in real-time)
- Digital signature capability (typed or drawn)
- Click "Approve" → sends signed proposal to boss
- Automatic redirect to payment page

### **Workflow Integration**
- Approved proposal → triggers invoice creation
- Automatic 50% upfront deposit invoice
- Generates payment link

---

## 💵 **Invoicing & Payment System**

### **Invoice Features**
- Tied to jobs and customers
- Line items: labor, materials, add-ons
- Tax calculation based on customer address
- Invoice status: Draft, Sent, Paid, Overdue
- Print-friendly format

### **Payment Processing**
- Stripe integration
- Accept credit cards, ACH, wire transfers
- Split payment system (50% upfront, 30% mid-project, 20% completion)
- **Manual payment triggers only** (no automatic charges)

### **Payment Reminders**
- Email reminders for due payments
- If not paid in 2 days: second email + boss notification
- Dashboard shows: "Proposal Sent" → "Proposal Approved" → "Invoice Paid 50%"

---

## 📧 **Notification System**

### **Multi-Channel Notifications**
Users can choose preferences for each notification type:
- **Email** (most popular)
- **SMS/Text** (Twilio integration)
- **Push Notifications** (limited, PWA-based)

### **Notification Types**
- Job updates (assigned, status changes, completed)
- Payment reminders
- Maintenance reminders
- Emergency/urgent communications
- System updates

### **User Control**
Settings page with toggles for each notification method per category.

---

## 📑 **Equipment & Materials Tracking**

### **Equipment Records**
- Record installed equipment: name, model, serial number, install date
- Link equipment to specific jobs and customers
- Show equipment details on invoices/proposals

### **Materials Tracking**
- Log materials used per job
- Serial number tracking
- Integration with job completion process

---

## ⏱️ **Time & Labor Tracking**
- Technicians log start/stop times per job
- GPS verification of location
- Total hours calculation per job
- Exportable for payroll
- QuickBooks compatibility (future integration)

---

## 📧 **Automated Maintenance System**
- After "Installation" jobs: store install date
- Automatic 6-month maintenance reminder emails
- Email content: "Time to schedule maintenance" + scheduling link
- Boss email address as sender

---

## 📊 **Admin Dashboard**
- Upcoming jobs overview
- Outstanding invoices tracking
- Technician workload view
- Revenue metrics
- Real-time job status updates

---

## 🔧 **Additional Features**

### **System Features**
- Version control (Git-based deployment)
- Environment variables for secrets
- Scheduled tasks for maintenance reminders
- Backup/export functionality for all data
- Multi-tenant database isolation

### **Future Integrations**
- QuickBooks integration (payroll, accounting)
- Inventory management with barcode scanning
- Recurring service contracts with automatic billing
- Material inventory tracking and low-stock alerts

---

## 💰 **SaaS Business Model**

### **Pricing Structure**
- Monthly subscription per company
- Estimated: $29-99/month per company
- Subdomain hosting included
- Unlimited users per company

### **Scaling Economics**
- Vercel hosting: ~$20/month base + usage
- Can host 100-200 companies before reaching $50/month
- 50 companies × $29/month = $1,450 revenue vs ~$25 costs
- **98% profit margins at scale**

---

## 📱 **Mobile Experience**
- Progressive Web App (PWA)
- Installs to home screen
- Native app feel and performance
- GPS tracking
- Camera access for photos
- Offline capability
- Works on iOS, Android, desktop

---

## 🔄 **Development Phases**

### **Phase 1: Core Proposal → Payment Flow** ⭐ (Priority)
- Authentication system (custom backend)
- Customer management (CRM)
- Proposal builder with master pricing database
- Digital signature capability
- Payment processing (Stripe integration)
- Basic email notifications

### **Phase 2: Job Management**
- Job scheduling and dispatching
- Technician portal (mobile-optimized)
- Photo upload and management
- GPS tracking and time logging
- Job status workflow

### **Phase 3: Advanced Features**
- Split payment system with reminders
- Notification preference system
- Tax calculation
- Print-friendly formats
- Basic reporting dashboard

### **Phase 4: Business Intelligence**
- Admin dashboard with metrics
- Maintenance reminder automation
- Advanced reporting
- Export/backup functionality

### **Phase 5: Scale & Integrate**
- Multi-tenant architecture optimization
- QuickBooks integration
- Inventory management system
- Recurring service contracts
- Performance optimization

---

## 📋 **Notes for Later Development**
- ❌ Job templates/checklists (handled physically by business)
- ❌ Weather integration (not needed)
- ❌ Customer satisfaction surveys (not needed)
- 📋 QuickBooks integration (Phase 5)
- 📋 Inventory barcode scanning (Phase 5)
- 📋 Recurring billing automation (Phase 5)

---

## 🎯 **Success Metrics**
- User adoption rate by technicians
- Proposal-to-conversion rate
- Payment collection time reduction
- Customer satisfaction (indirect)
- Revenue per client company
- System uptime and reliability

---

*This document serves as the complete reference for the Service Pro field service management application development project.*