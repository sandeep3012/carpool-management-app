# CarPool Management — UI/UX Architecture Plan

## Design Philosophy

**Inspired by**: Splitwise + Google Wallet + Google Calendar
**Style**: Material 3, modern, colorful, premium feel
**Goals**: Fast data entry, transparent expense tracking, beautiful settlements

---

## Screen Navigation Hierarchy

### App Flow (Role-Based)

```
┌─────────────────────────────────────────┐
│          Splash Screen                  │
│      (2 sec + auth check)               │
└──────────────┬──────────────────────────┘
               │
       ┌───────▼────────┐
       │  Check Auth?   │
       └───┬────────┬───┘
           │        │
      NO   │        │    YES
           │        │
      ┌────▼──┐    ┌──▼─────────────┐
      │ Login │    │ Check Role?     │
      └────┬──┘    └──┬─────────┬────┘
           │          │         │
           │     ADMIN│         │MEMBER
           │          │         │
     ┌─────▼──────┐ ┌─▼─────────▼──┐
     │ Main Home  │ │  Main Home    │
     │ (Admin)    │ │  (Member)     │
     │            │ │               │
     └──────┬─────┘ └─────┬─────────┘
            │             │
     ┌──────▼─────────────▼──┐
     │  Bottom Navigation    │
     │  • Dashboard          │
     │  • Trips/Calendar     │
     │  • Settlements        │
     │  • Reports (admin)    │
     │  • Settings           │
     └───────────────────────┘
```

---

## Bottom Navigation Strategy

### Tab Structure

```
Admin View (5 tabs):
┌────────┬────────┬────────┬────────┬────────┐
│ 📊     │ 🗓️     │ 🏦     │ 📈     │ ⚙️     │
│ Dash   │ Trips  │ Settle │ Reports│ Settings
└────────┴────────┴────────┴────────┴────────┘

Member View (4 tabs):
┌────────┬────────┬────────┬────────┐
│ 📊     │ 🗓️     │ 🏦     │ ⚙️     │
│ Dash   │ Trips  │ Settle │ Settings
└────────┴────────┴────────┴────────┘
```

### Tab Features

| Tab | Admin Features | Member Features |
|-----|---|---|
| **Dashboard** | Summary, quick actions | Summary, my expenses |
| **Trips** | Full calendar, create, edit | View calendar only |
| **Settlements** | Approve/generate, audit | View only |
| **Reports** | All reports + audit logs | My summary only |
| **Settings** | Members, app config | Profile, notifications |

---

## Screen Breakdown

### 1. Dashboard Screen

**Purpose**: Monthly overview + quick actions

**Sections** (scrollable):
```
┌─────────────────────────────┐
│  Month: May 2026            │
│  ← | May | →                │
├─────────────────────────────┤
│  Summary Cards (3-card row)  │
│  ┌──────┐ ┌──────┐ ┌──────┐ │
│  │Total │ │Settle│ │You   │ │
│  │Exp   │ │Pending│ │Owe  │ │
│  │₹4200 │ │₹1200 │ │₹150 │ │
│  └──────┘ └──────┘ └──────┘ │
├─────────────────────────────┤
│  Quick Actions              │
│  ┌──────────────────────┐   │
│  │ + New Trip           │   │
│  │ → View Settlement    │   │
│  │ 📄 Latest Report     │   │
│  └──────────────────────┘   │
├─────────────────────────────┤
│  Recent Activity            │
│  • Trip added (Today)       │
│  • Expense modified (Wed)   │
│  • Settlement pending (Fri) │
├─────────────────────────────┤
│  Upcoming Drives            │
│  (Sorted by date)           │
│  ┌──────────────────────┐   │
│  │ May 16 (Tomorrow)    │   │
│  │ 🚗 You are driving   │   │
│  │ 4 passengers         │   │
│  └──────────────────────┘   │
│  ┌──────────────────────┐   │
│  │ May 17 (Friday)      │   │
│  │ 🚗 John is driving   │   │
│  │ 5 passengers         │   │
│  └──────────────────────┘   │
└─────────────────────────────┘
```

**Interactions**:
- Tap month → date picker (jump to any month)
- Tap summary card → drill into details
- Tap quick action → navigate to screen
- Tap upcoming drive → view/edit trip

---

### 2. Trips/Calendar Screen

**Purpose**: View and manage trips

**Two Modes**:

#### Mode A: Calendar View (Default)
```
┌─────────────────────────────┐
│  May 2026                   │
│  Week view or Month view    │
│  [Week] [Month]             │
├─────────────────────────────┤
│  Su  Mo  Tu  We  Th  Fr  Sa │
│                    1   2   3 │
│  4   5   6   7   8   9  10  │
│  11  12  13  14 [15] 16  17 │
│  18  19  20  21  22  23  24 │
│  25  26  27  28  29  30  31 │
│                             │
│  Selected date: May 15      │
│  ├─ 🚗 You driving (5 ppl)  │
│  └─ ₹840 total expense      │
├─────────────────────────────┤
│  Legend                     │
│  🚗 You driving             │
│  👥 Other driver            │
│  ⚠️  Multiple trips (future) │
└─────────────────────────────┘
```

#### Mode B: List View
```
┌─────────────────────────────┐
│  Upcoming Trips             │
│  Filter: [May] ▼            │
├─────────────────────────────┤
│  May 14                     │
│  🚗 John driving            │
│  5 passengers, ₹840 share   │
│  ├─ Tap to view details     │
│                             │
│  May 15                     │
│  🚗 YOU driving             │
│  4 passengers, ₹1050 pay    │
│  ├─ Tap to edit             │
│                             │
│  May 16                     │
│  🚗 Sarah driving           │
│  3 passengers, ₹720 share   │
└─────────────────────────────┘
```

---

### 3. Trip Detail & Edit Screen

**Purpose**: View/edit single trip

**Trip Detail View**:
```
┌─────────────────────────────┐
│  Trip: May 16, 2026         │
│  [Edit]                     │
├─────────────────────────────┤
│  Driver: You                │
│  Status: Active             │
│                             │
│  Basic Info                 │
│  ├─ Date: May 16           │
│  ├─ Distance: 45 km        │
│  └─ Lock: 🔓 Unlocked      │
│                             │
│  Passengers (4)             │
│  ├─ You (driver)            │
│  ├─ John ✓                  │
│  ├─ Sarah ✓                 │
│  ├─ Mike ✓                  │
│  └─ [+ Add guest]           │
│                             │
│  Expenses                   │
│  ├─ Fuel: ₹405             │
│  ├─ Toll: ₹200             │
│  ├─ Parking: ₹50           │
│  └─ Other: ₹100            │
│  ──────────────            │
│  Total: ₹755               │
│  Per person: ₹189          │
│                             │
│  [Edit] [Lock] [Delete]    │
└─────────────────────────────┘
```

**Trip Edit Mode** (Admin only):
```
┌─────────────────────────────┐
│  Edit Trip                  │
├─────────────────────────────┤
│  Date:        [May 16 ▼]   │
│  Driver:      [You ▼]       │
│  Distance:    [45 km  ]     │
│                             │
│  Passengers                 │
│  ☑ You (driver)             │
│  ☑ John                     │
│  ☑ Sarah                    │
│  ☑ Mike                     │
│  ☐ Jane                     │
│  [+ Add guest]              │
│                             │
│  Expenses                   │
│  ├─ [Fuel] [₹405]          │
│  ├─ [Toll] [₹200]          │
│  ├─ [Parking] [₹50]        │
│  └─ [Other] [₹100]         │
│                             │
│  Auto-calculated:          │
│  → Total: ₹755             │
│  → Per person: ₹189        │
│                             │
│  [Save] [Cancel] [Delete]  │
└─────────────────────────────┘
```

---

### 4. Quick Trip Entry (Bottom Sheet)

**Used for**: Fast trip creation from dashboard

```
┌─────────────────────────────┐
│  + New Trip                 │  ← Drag handle
├─────────────────────────────┤
│                             │
│  Date:    [Today ▼]         │
│                             │
│  Driver:  [Select ▼]        │
│                             │
│  Distance: [    km]         │
│                             │
│  Quick Add:                 │
│  ☐ You      ☐ John         │
│  ☐ Sarah    ☐ Mike         │
│  ☐ Jane                    │
│                             │
│  Expenses:                  │
│  Fuel:   ₹___ (auto: 405)  │
│  Toll:   ₹___ (optional)   │
│  Other:  ₹___ (optional)   │
│                             │
│  Auto-calculated:          │
│  Per person: ₹___ share    │
│                             │
│  [Create Trip] [Cancel]    │
└─────────────────────────────┘
```

**Interaction Flow**:
1. Tap "+ New Trip" from dashboard
2. Bottom sheet slides up
3. Fields auto-fill (today's date, last distance)
4. Quick checkboxes for common passengers
5. Expenses auto-calculate
6. Tap "Create" → immediate save
7. Optional: tap trip to add more details

---

### 5. Settlements Screen

**Purpose**: View and manage monthly settlements

**Settlements List**:
```
┌─────────────────────────────┐
│  Settlements                │
│  Filter: [All ▼]            │
├─────────────────────────────┤
│  May 2026                   │
│  Status: Draft              │
│  ┌──────────────────────┐   │
│  │ ⚠️ Pending Approval  │   │
│  │                      │   │
│  │ Total to settle:     │   │
│  │ ₹4,200               │   │
│  │                      │   │
│  │ Transactions: 4      │   │
│  │                      │   │
│  │ [View Details]       │   │
│  └──────────────────────┘   │
│                             │
│  April 2026                 │
│  Status: Settled            │
│  ┌──────────────────────┐   │
│  │ ✓ Approved (May 5)   │   │
│  │                      │   │
│  │ Total settled:       │   │
│  │ ₹3,850               │   │
│  │                      │   │
│  │ Transactions: 3      │   │
│  │                      │   │
│  │ [View Details]       │   │
│  └──────────────────────┘   │
└─────────────────────────────┘
```

**Settlement Detail**:
```
┌─────────────────────────────┐
│  Settlement - May 2026      │
│  Status: Pending Approval   │
│  Generated: May 10, 10:30   │
├─────────────────────────────┤
│                             │
│  Monthly Summary            │
│  ├─ Total Trips: 12         │
│  ├─ Total Expenses: ₹4,200 │
│  ├─ Members: 5              │
│  └─ Status: Draft           │
│                             │
│  Individual Balances        │
│  ┌──────────────────────┐   │
│  │ You (admin)          │   │
│  │ Paid: ₹2,100         │   │
│  │ Owes: ₹0             │   │
│  │ Balance: +₹2,100     │   │
│  │ (Collector)          │   │
│  └──────────────────────┘   │
│                             │
│  ┌──────────────────────┐   │
│  │ John                 │   │
│  │ Paid: ₹800           │   │
│  │ Owes: ₹950           │   │
│  │ Balance: -₹150       │   │
│  │ (Pays ₹150 to you)  │   │
│  └──────────────────────┘   │
│                             │
│  Optimized Transactions     │
│  1. John pays ₹150 to you   │
│  2. Sarah pays ₹200 to you  │
│  3. Mike pays ₹350 to you   │
│                             │
│  [Approve] [Reject] [Share] │
└─────────────────────────────┘
```

---

### 6. Reports Screen

**Purpose**: View and export reports

**Reports List**:
```
┌─────────────────────────────┐
│  Reports                    │
├─────────────────────────────┤
│  Monthly Summary (May 2026) │
│  ┌──────────────────────┐   │
│  │ 📊 Expenses by Type  │   │
│  │                      │   │
│  │ Fuel: 65% (₹2,730)  │   │
│  │ Toll: 20% (₹840)    │   │
│  │ Parking: 15% (₹630) │   │
│  │                      │   │
│  │ [View Full Report]   │   │
│  └──────────────────────┘   │
│                             │
│  Per Member Summary         │
│  ┌──────────────────────┐   │
│  │ 👥 Your Summary      │   │
│  │                      │   │
│  │ Trips driven: 4      │   │
│  │ Trips taken: 8       │   │
│  │ Total paid: ₹2,100  │   │
│  │ Total owed: ₹0       │   │
│  │                      │   │
│  │ [View Detailed]      │   │
│  └──────────────────────┘   │
│                             │
│  Export Options             │
│  ├─ [📄 PDF Report]        │
│  ├─ [📧 Email]             │
│  └─ [📱 WhatsApp]          │
└─────────────────────────────┘
```

**Full Report View**:
```
Chart: Monthly Expenses Breakdown
(Bar chart or Pie chart)

Table: Per-Member Breakdown
┌─────────┬──────┬──────┬────────┐
│ Member  │ Paid │ Owes │ Balance│
├─────────┼──────┼──────┼────────┤
│ You     │2100 │ 0    │ +2100  │
│ John    │ 800 │ 950  │ -150   │
│ Sarah   │ 600 │ 800  │ -200   │
│ Mike    │1400 │1050  │ +350   │
│ Jane    │ 300 │ 400  │ -100   │
└─────────┴──────┴──────┴────────┘

Export button (PDF, Email, Share)
```

---

### 7. Member Management (Admin Only)

**Members List**:
```
┌─────────────────────────────┐
│  Members                    │
│  Search: [        ]         │
├─────────────────────────────┤
│  ┌──────────────────────┐   │
│  │ 👤 John              │   │
│  │ john@company.com     │   │
│  │ Status: Active       │   │
│  │ Trips: 12, Owes: ₹50 │   │
│  │ [Edit] [Deactivate]  │   │
│  └──────────────────────┘   │
│                             │
│  ┌──────────────────────┐   │
│  │ 👤 Sarah             │   │
│  │ sarah@company.com    │   │
│  │ Status: Active       │   │
│  │ Trips: 8, Owes: ₹200 │   │
│  │ [Edit] [Deactivate]  │   │
│  └──────────────────────┘   │
│                             │
│  ┌──────────────────────┐   │
│  │ 👤 Mike              │   │
│  │ mike@company.com     │   │
│  │ Status: Inactive     │   │
│  │ [Edit] [Reactivate]  │   │
│  └──────────────────────┘   │
│                             │
│  [+ Add New Member]         │
└─────────────────────────────┘
```

**Edit Member Dialog**:
```
┌─────────────────────────────┐
│  Edit Member                │
├─────────────────────────────┤
│  Name:     [John          ] │
│  Email:    [john@co...    ] │
│  Phone:    [+91-1234-5678 ] │
│  Role:     [Member ▼]      │
│  Status:   [Active ▼]      │
│                             │
│  [Save] [Cancel] [Delete]   │
└─────────────────────────────┘
```

---

### 8. Settings Screen

**Admin Settings**:
```
┌─────────────────────────────┐
│  Settings                   │
├─────────────────────────────┤
│  Profile                    │
│  ├─ Name: Your Name         │
│  ├─ Email: admin@co...      │
│  └─ Phone: +91-98765-43210  │
│                             │
│  App Settings               │
│  ├─ Mileage Rate: 40 km/L  │
│  ├─ Fuel Price: ₹100/L     │
│  ├─ Currency: INR (₹)       │
│  └─ Notification: [✓] On    │
│                             │
│  Data & Sync                │
│  ├─ Last Sync: Just now     │
│  ├─ Pending Sync: 0 items   │
│  └─ [Manual Sync]           │
│                             │
│  About                       │
│  ├─ Version: 1.0.0          │
│  ├─ Build: 1                │
│  └─ [Check for Update]      │
│                             │
│  Account                    │
│  └─ [Logout]                │
└─────────────────────────────┘
```

**Member Settings**:
```
(Same as above, without
 mileage/fuel price settings)
```

---

## Interaction Patterns

### 1. Data Entry UX

**Goal**: Fast, minimal taps

**Pattern**:
```
Dashboard
  ↓
Tap "+ New Trip"
  ↓
Quick Entry Bottom Sheet
  ├─ Pre-filled (today, last distance)
  ├─ Quick checkboxes for passengers
  ├─ Auto-calculated expenses
  ↓
[Create] button
  ↓
Trip saved immediately
  ↓
(Optional: tap to add more details)
```

**Alternative - Detailed Entry**:
```
Tap trip card
  ↓
Trip Detail page
  ↓
Tap [Edit] button
  ↓
Full edit form with all fields
  ↓
[Save] - returns to detail
```

---

### 2. Settlement UX

**Timeline**:
```
End of month (May 31)
  ↓
Admin: Tap "Generate Settlement"
  ↓
System shows preview:
- Summary cards
- Member balances
- Optimized transactions
  ↓
Admin: Review & [Approve]
  ↓
Status changes to "Settled"
  ↓
All members notified
  ↓
Reports available for download
```

---

### 3. Calendar Interactions

**Selection**:
```
Tap date on calendar
  ↓
Show trip(s) for that date
  ↓
Tap trip → Trip Detail
```

**Navigation**:
```
Prev/Next buttons navigate months
OR
Tap "May 2026" → Date Picker → Jump to month
```

---

## Reusable UI Components

### Core Components

| Component | Usage | Material 3 Base |
|---|---|---|
| **AppCard** | Trip cards, summary cards | Material Card |
| **AppButton** | Actions (create, save, delete) | Material Button |
| **AppTextField** | Input fields | Material TextField |
| **AppMoneyInput** | Expense inputs (auto-format) | Material TextField + custom |
| **AppDatePicker** | Date selection | Material DatePicker |
| **AppMemberSelector** | Select passengers | Material Dropdown + Chips |
| **AppExpenseItem** | Expense rows (trip/report) | Custom ListTile |
| **AppTransactionCard** | Settlement transactions | Material Card |
| **AppSummaryCard** | Quick stats (dashboard) | Material Card |
| **AppEmptyState** | No data screens | Custom widget |
| **AppLoadingState** | Loading indicators | CircularProgressIndicator |
| **AppErrorState** | Error screens with retry | Custom widget |
| **AppBottomSheet** | Quick entry, dialogs | Material BottomSheet |
| **AppSnackbar** | Notifications | Material SnackBar |
| **AppCharts** | Reports visualization | fl_chart wrapped |

---

## Empty States

### Empty Dashboard
```
┌─────────────────────────────┐
│  No trips this month        │
│          🚗                 │
│                             │
│  Create your first trip to  │
│  get started!               │
│                             │
│  [+ Create Trip]            │
└─────────────────────────────┘
```

### Empty Settlements
```
┌─────────────────────────────┐
│  No settlements yet         │
│          🏦                 │
│                             │
│  Settlements are generated  │
│  monthly. Check back soon!  │
└─────────────────────────────┘
```

### No Members (Admin)
```
┌─────────────────────────────┐
│  No members added           │
│          👥                 │
│                             │
│  Add members to get started │
│                             │
│  [+ Add Member]             │
└─────────────────────────────┘
```

---

## Loading States

### Skeleton Loading (Trips Calendar)
```
Calendar with light gray
placeholder boxes for:
- Date cells
- Trip cards
```

### Skeleton Loading (Dashboard)
```
Gray shimmer cards for:
- Summary cards
- Recent activity
- Upcoming drives
```

### Explicit Loader
```
Centered circular progress
+ "Loading trips..."
(Use when operation > 1 sec)
```

---

## Error States

### Network Error
```
┌─────────────────────────────┐
│  Connection Failed          │
│          ⚠️                 │
│                             │
│  Unable to sync data.       │
│  Check your connection.     │
│                             │
│  [Retry] [Use Offline]      │
└─────────────────────────────┘
```

### Sync Error
```
┌─────────────────────────────┐
│  Sync Failed                │
│          ⚠️                 │
│                             │
│  Some data couldn't sync.   │
│  Changes saved locally.     │
│                             │
│  [Try Again] [Dismiss]      │
└─────────────────────────────┘
```

### Validation Error
```
Form field highlight (red border)
+ Error message below:
"Please select a valid date"
```

---

## Animation Strategy

### Page Transitions
```
New page slides in from right
Previous page fades out slightly
Duration: 300ms
Curve: easeInOutCubic
```

### Card Animations
```
Cards stagger enter from bottom
Delay: 50ms between cards
Duration: 400ms
Curve: easeOut
```

### Button Interactions
```
Tap feedback:
- Scale: 0.95 → 1.0 (100ms)
- Ripple effect
  
Loading state:
- Spinner rotation (continuous)
```

### Settlement Generation
```
Slide up from bottom (bottom sheet)
List items animate in
Checkmarks appear with bounce
```

### Chart Animations
```
Bars grow from 0 to value (600ms)
Pie slices appear sequentially
Curve: easeOutCubic
```

---

## Role-Based UI Behavior

### Admin-Only Elements

| Feature | Visibility |
|---------|---|
| "+ New Trip" button | Admin only |
| "Edit" on trip cards | Admin only |
| "Generate Settlement" | Admin only |
| "Approve Settlement" | Admin only |
| Reports tab | Both (more features in admin) |
| Members tab | Admin only |
| Audit logs | Admin only |
| Delete buttons | Admin only |
| Settings (full) | Admin only |

### Member-Only Limitations

- Cannot create/edit trips
- Cannot modify expenses
- Can only view own data
- Cannot approve settlements
- Limited reports

### Role-Based Dashboard

**Admin Dashboard**:
- Quick action: "+ New Trip"
- Quick action: "Approve Settlement"
- Pending settlements count
- Recent admin actions
- Sync status

**Member Dashboard**:
- Quick action: "View my settlements"
- My balance this month
- Upcoming drives I'm on
- Recent activities

---

## Mobile-First Interactions

### Thumb Zone Optimization

```
Easy Reach (Thumbs):
┌─────────────────────┐
│  HARD       EASY    │
│  ┌─────────────┐    │
│  │ Status Bar  │    │
│  ├─────────────┤    │
│  │             │    │
│  │  Content    │ EASY
│  │  Area       │    │
│  │             │    │
│  ├─────────────┤    │
│  │ Bottom Nav  │ EASY
│  └─────────────┘    │
└─────────────────────┘

Actions placed in:
- Bottom navigation (easy tap)
- Floating action buttons (easy)
- Bottom sheets (easy)

Avoid:
- Top-right close buttons
- Small action buttons
```

### Gesture Interactions

| Gesture | Action |
|---------|--------|
| Tap | Open trip, select option |
| Long-press | Copy data, quick menu |
| Swipe left | Delete (with confirm) |
| Swipe up | Open bottom sheet, more info |
| Pull-down | Refresh (if syncing) |
| Double-tap | Quick edit |

### Form Optimization

**Quick Entry Bottom Sheet**:
- Minimal fields (max 5)
- Auto-fill previous values
- Dropdown over text input
- Number pad for amounts
- Tab between fields (mobile keyboard)

**Full Forms**:
- One field per view (vertical scrolling)
- Clear labels (large tap targets)
- Input validation inline
- Clear next/prev navigation

---

## Dashboard Quick Actions

### Admin Dashboard
```
3 quick action buttons:
1. + New Trip
2. Generate Settlement
3. View All Members
```

### Member Dashboard
```
3 quick action buttons:
1. View Settlement Details
2. View Reports
3. My Expenses Breakdown
```

---

## Calendar UX Details

### Day Cell Content
```
┌──────────┐
│ 15       │  ← Date number
│ 🚗👥5    │  ← Driver icon + passenger count
│ ₹840     │  ← Total expense
└──────────┘
```

### Selected Day Detail
```
Shown below calendar:
- Trip card(s) for that day
- Tap to expand full details
- Swipe to next/prev day
```

### Month Navigation
```
< May 2026 >
Buttons on either side
Tap month name → date picker popup
```

---

## Settlement Visualization

### Transaction Flow Diagram
```
Circle nodes for members
Arrows showing payment flows
Thickness = amount
Direction = from→to

Example:
John (₹150→) → You
Sarah (₹200→) → You
Mike (←₹50) Mike ← You
```

### Balance Visualization
```
Positive balance (You Owe):
Green progress bar, rightward

Negative balance (They Owe You):
Blue progress bar, leftward
```

---

## Report Export Strategy

### PDF Export
```
- Header: Month, generated date
- Summary table
- Pie/bar chart
- Transaction list
- Footer: Generated by app
```

### WhatsApp Sharing
```
Text format:
---
May Settlement Summary
Total: ₹4,200
John pays ₹150 to Me
Sarah pays ₹200 to Me
...
---
```

### Email Sharing
```
Formatted HTML email
With PDF attachment
```

---

## Navigation Structure Summary

```
TabBar Navigation
    ├── Dashboard
    │   ├── Quick Actions
    │   ├── Summary Cards
    │   └── Recent Activity
    │
    ├── Trips/Calendar
    │   ├── Month Calendar
    │   ├── Trip Detail (nested)
    │   ├── Trip Edit (modal, admin)
    │   └── Quick Entry (bottom sheet)
    │
    ├── Settlements
    │   ├── Settlements List
    │   └── Settlement Detail (nested)
    │       ├── [Approve] (admin)
    │       └── [Share/Export]
    │
    ├── Reports (conditional on role)
    │   ├── Monthly Report
    │   ├── Member Report
    │   └── [Export options]
    │
    └── Settings
        ├── Profile
        ├── App Config (admin only)
        ├── Members (admin only)
        └── [Logout]
```

---

## Interaction Density

### Low-Density Screens
- Dashboard (breathing room)
- Settlement detail (clear structure)

### Medium-Density Screens
- Trips calendar (structured grid)
- Reports table (ordered data)

### Higher-Density Screens
- Members list (search + filtering)
- Detailed trip view (many fields)

---

## Accessibility Considerations

### Color Contrast
- Text on cards: AA minimum
- Action buttons: AAA
- Icons: Paired with labels

### Touch Targets
- Minimum 48x48 dp for buttons
- 56x56 dp preferred
- Spacing between targets

### Readable Fonts
- Body: 14-16 sp
- Headlines: 20-28 sp
- Amount values: 16-18 sp (prominent)

### Semantic Meaning
- Don't rely on color alone
- Icons paired with text labels
- Loading states explicit

---

## Summary: Key UX Principles

✅ **Fast Data Entry**: Minimize fields, auto-fill, quick buttons
✅ **Clear Visualizations**: Cards, charts, transactions clearly shown
✅ **Role-Based Simplicity**: Members see less, admins see everything
✅ **Offline Reliability**: Works without network, syncs when available
✅ **Mobile-First**: Thumb-friendly, gesture-based, tap targets
✅ **Modern Feel**: Material 3, smooth animations, premium colors
✅ **Transparency**: Clear expense breakdown, settlement logic visible
✅ **Scalability**: Tab structure, nested navigation, works for 5-50 members
✅ **Beautiful**: Inspired by Splitwise + Google, not enterprise software
✅ **Consistent**: Reusable components, unified interaction patterns
