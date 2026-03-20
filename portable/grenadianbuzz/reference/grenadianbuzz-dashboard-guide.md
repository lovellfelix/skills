# GrenadianBuzz Dashboard Reference Guide

**Deep reference for dashboard design, layouts, and workflows for GrenadianBuzz admin/creator tools**

Based on actual dashboard surface: `~/projects/grenadianbuzz/web/dashboard.grenadianbuzz.com`

---

## Table of Contents

1. [Dashboard Architecture](#dashboard-architecture)
2. [Authentication & Access Control](#authentication--access-control)
3. [Content Management Dashboard](#content-management-dashboard)
4. [Moderation Dashboard](#moderation-dashboard)
5. [Analytics & Reporting](#analytics--reporting)
6. [Creator Dashboard](#creator-dashboard)
7. [Admin Settings](#admin-settings)
8. [Real-Time Updates & Notifications](#real-time-updates--notifications)
9. [Responsive Design & Mobile](#responsive-design--mobile)
10. [Performance & UX Patterns](#performance--ux-patterns)

---

## Dashboard Architecture

### Tech Stack

- **Frontend**: React 18+, TypeScript, TailwindCSS
- **State Management**: TanStack Query (React Query) for API caching
- **Charting**: Recharts, Chart.js for analytics
- **Tables**: TanStack React Table for data grids
- **Real-time**: WebSocket connections for live updates
- **Authentication**: JWT (token in localStorage with refresh)
- **API Client**: Axios with request/response interceptors

### Core Navigation

```
Dashboard (/dashboard)
├── Content
│   ├── Articles (/articles)
│   ├── Obituaries (/obituaries)
│   ├── Events (/events)
│   └── Radio Stations (/radio)
├── Moderation
│   ├── Queue (/moderation/queue)
│   ├── Audit Log (/moderation/audit)
│   └── User Reports (/moderation/reports)
├── Analytics
│   ├── Overview (/analytics/overview)
│   ├── Content Performance (/analytics/content)
│   ├── User Engagement (/analytics/engagement)
│   └── Revenue (/analytics/revenue)
├── Creators (if creator role)
│   ├── My Articles (/creators/articles)
│   ├── My Stats (/creators/stats)
│   └── Subscribers (/creators/subscribers)
└── Settings (/settings)
    ├── Profile
    ├── Notification Preferences
    ├── API Keys
    └── Workspace (admin only)
```

---

## Authentication & Access Control

### Login & Session Management

**Login Flow**:
```
1. User enters email + password
2. Backend validates, returns JWT + refresh token
3. JWT stored in localStorage (expires in 24h)
4. Refresh token in secure httpOnly cookie
5. Dashboard checks auth on mount; auto-refreshes if expired
```

**Session Persistence**:
```javascript
// On app load
useEffect(() => {
  const token = localStorage.getItem('token');
  const refreshToken = localStorage.getItem('refreshToken');
  
  if (token && isExpired(token)) {
    refreshToken(refreshToken)
      .then(newToken => setAuthToken(newToken))
      .catch(() => redirectToLogin());
  }
}, []);
```

### Role-Based Access Control (RBAC)

| Role | Endpoints | Content Actions | Moderation | Settings |
|------|-----------|-----------------|------------|----------|
| **admin** | All | CRUD all | Full queue access, bulk actions, escalation | Workspace settings |
| **moderator** | Content, moderation | View all | Queue access, approve/remove | Personal settings only |
| **editor** | Content only | Publish own + draft of others | Flag for review | Personal settings only |
| **creator** | Creator dashboard | CRUD own | Flag own content | Personal settings only |
| **subscriber** | Read-only | View own saves | N/A | Personal settings only |

**Access Control Pattern**:
```javascript
// Protect routes by role
<ProtectedRoute roles={['admin', 'moderator']} path="/moderation">
  <ModerationDashboard />
</ProtectedRoute>

// Show/hide UI elements
{hasRole('admin') && <WorkspaceSettings />}
{hasRole('editor') && <BulkPublish />}
```

---

## Content Management Dashboard

### Articles Management

**List View** (default sorting: published_at:desc):

| Column | Width | Sortable | Filterable | Notes |
|--------|-------|----------|-----------|-------|
| Title | 40% | Yes (search) | Category, author, status | Truncated, hover for full |
| Category | 12% | Yes | Dropdown (category list) | Colored badges |
| Status | 10% | Yes | draft, scheduled, published, archived | Badge with icon |
| Views | 8% | Yes (numeric) | Range filter | Real-time updated |
| Comments | 8% | Yes (numeric) | Count range | Linked to comment thread |
| Published | 10% | Yes | Date range | Relative time (e.g., "2d ago") |
| Actions | 12% | N/A | N/A | Edit, preview, more menu |

**Filters & Search**:
```
Search box (title, content, author name)
Category dropdown (select multi)
Status filter (checkboxes: draft, scheduled, published, archived)
Date range picker (published_at)
Author filter (searchable dropdown)
Engagement filter (views > X, comments > Y)
[Clear Filters] button
```

**Bulk Actions**:
```
Select checkbox in header (all on page)
Bulk action toolbar appears:
  ☑ 5 selected
  [Archive] [Delete] [Publish] [Change Category] [Add Label]
```

**Create/Edit Modal**:

Form sections:
1. **Basic Info**: Title, slug, content (rich editor with markdown toggle)
2. **Metadata**: Category, tags, featured image, description
3. **Publishing**: Status (draft/scheduled), schedule-at date/time, notify users
4. **SEO**: Meta title, meta description, og:image
5. **Advanced**: Author override, source URL, allow comments toggle

**Draft Recovery**:
```
- Auto-save to IndexedDB every 30 seconds
- "You have unsaved changes" warning on browser unload
- "Recover draft" notification if tab closed unexpectedly
- Version history (last 10 versions, clickable timeline)
```

### Obituaries Management

**List View** (default: death_date:desc):

| Column | Notes |
|--------|-------|
| Name | Full name of deceased |
| Death Date | Date of death |
| Age | Calculated from DOB |
| Photos | Count of photos uploaded |
| Status | draft, pending_review, published, flagged |
| Views | Engagement metric |
| Actions | Edit, preview, delete |

**Create Obituary**:
```
Required fields:
  - Name of deceased
  - Date of death
  - Date of birth (age calculation)
  - Biographical information (rich editor)
  
Optional fields:
  - Photo gallery (upload multiple)
  - Surviving family members
  - Funeral arrangements
  - Preferred funeral home
```

**Auto-Verification Workflow**:
```
On publish:
  1. Check spelling via dictionary API
  2. Verify date of death isn't in future
  3. Suggest related articles from archives
  4. Flag if comments mention privacy concerns
```

### Events Management

**Calendar View** (default: month view):
```
- Mini calendar navigation (prev/next month)
- Event dots on dates with events
- Click date → show events for that day
- Toggle event card inline vs. modal
```

**List View** (upcoming events first):

| Column | Notes |
|--------|-------|
| Title | Event name |
| Category | carnival, religious, national_holiday, other |
| Date | Start date + time, relative ("Tomorrow", "in 3 days") |
| Location | City/venue |
| Featured | Toggle star (featured until date) |
| Actions | Edit, duplicate, delete |

**Create Event**:
```
Required:
  - Title
  - Start date/time
  - End date/time
  - Category

Optional:
  - Location
  - Description
  - Featured image
  - Website URL
  - Featured until (date picker)
```

**Recurring Events**:
```
Frequency options: weekly, bi-weekly, monthly, yearly
Repeat until date picker
Generates individual event records (editable independently)
```

### Radio Stations

**List View**:

| Column | Notes |
|--------|-------|
| Station Name | Sortable, searchable |
| Genre | music, news, sports, talk, mixed |
| Language | english, french creole, french |
| Stream URL | Truncated, copy-to-clipboard button |
| Status | online, offline, error |
| Listener Count | Real-time, updated via WebSocket |
| Added | Date added |
| Actions | Edit, health check, delete |

**Health Check Widget**:
```
"Last checked: 2 minutes ago"
Status indicator (green=online, red=offline, yellow=stalled)
Response time (ms)
[Recheck] button
Log of recent checks (hover tooltip)
```

---

## Moderation Dashboard

### Moderation Queue

**Queue View** (default: created_at:asc, urgent first):

| Column | Notes |
|--------|-------|
| Content | Title + type badge (article, comment, user) |
| Flag Reason | spam, offensive, misinformation, harassment, other |
| Flagged By | User name or "System" if auto-flag |
| Time Ago | Created timestamp, relative |
| Priority | High, normal, low (color-coded) |
| Assigned To | Moderator name or unassigned |
| Actions | Approve, remove, escalate, more |

**Filters & Search**:
```
Status: pending, in_review, approved, removed, escalated
Reason: spam, offensive, misinformation, harassment, other
Priority: high, normal, low
Assigned to: (dropdown of moderators or unassigned)
Content type: article, comment, user_profile, other
[Quick Filters]:
  [My Queue] [Escalated] [High Priority] [Unassigned]
```

**Approve/Remove Modal**:

When approving:
```
☐ Notes (optional, visible in audit log)
[Approve] [Cancel]
```

When removing:
```
Reason (dropdown): spam, harassment, misinformation, other
☐ Notify author? (checkbox)
☐ Hide all content from this user? (checkbox, if user is offender)
Notification template (preview):
  "Your content was removed for: [reason]. Appeal: [link]"
[Remove] [Cancel]
```

**Bulk Actions**:
```
Select multiple items
Bulk action toolbar:
  [Approve All (5)] [Remove All (5)] [Escalate All (5)]
  More: [Change Priority] [Assign To] [Add Notes]
```

**Audit Log View**:

| Column | Notes |
|--------|-------|
| Date/Time | When action occurred |
| Action | approve, remove, escalate, assign, note |
| Target | Content title or user |
| Moderator | Who took action |
| Notes | Free-text notes from moderator |

**Search/Filter**:
```
Date range picker
Moderator dropdown
Action filter: approve, remove, escalate
Content type filter
[Export] button (CSV with full details)
```

---

## Analytics & Reporting

### Overview Dashboard

**Key Metrics (widgets)**:

```
[Total Views]        [Total Comments]     [Engagement Rate]
    250K ↑ 12%            45.2K ↑ 8%          3.2% ↓ 0.5%

[New Subscribers]    [Moderation Backlog]  [Revenue (This Month)]
    1.2K ↑ 5%             23 items            $4,250 ↑ 15%
```

**Charts** (all charts are interactive: hover for detail, click legend to toggle series):

1. **Views Trend** (line chart, last 30 days):
   - X-axis: date
   - Y-axis: views
   - Toggles: articles, obituaries, events, total
   - Granularity dropdown: hourly, daily, weekly

2. **Engagement Breakdown** (pie chart):
   - Segments: likes, comments, saves, shares
   - Percentages and absolute counts
   - Click segment to filter to that type

3. **Top Content** (bar chart, horizontal):
   - Top 10 articles by views
   - Bars colored by category
   - Hover for full title and view count

4. **User Geography** (map or list):
   - USA (45%), Canada (20%), UK (15%), other (20%)
   - Clickable regions to drill down
   - Toggle: by country, by region (USA states)

**Time Period Selector**:
```
[Today] [This Week] [This Month] [Last 30d] [Custom Date Range]
```

### Content Performance

**Drill-Down View**:

```
[Category Filter: All]
Content performance table:

| Title | Category | Status | Views | Comments | Likes | Avg Time | CTR |
|-------|----------|--------|-------|----------|-------|----------|-----|

Click row → detailed view with:
  - Full engagement timeline (line chart)
  - Geographic breakdown of views
  - Device breakdown (mobile, tablet, desktop)
  - Referrer breakdown (direct, social, search)
```

### Engagement Trends

**Metrics**:
```
- Comments per article (trend)
- Comment-to-view ratio (trend)
- Like-to-view ratio (trend)
- Share rate (trend)
- Save rate (trend)
```

**Segmentation**:
```
By category (select multi)
By time period (hourly, daily, weekly)
By user segment (geography, subscription tier, device)
Export to CSV
```

### Revenue & Subscriptions

**Subscription Metrics**:
```
- Total revenue (month, trend)
- New subscribers (month)
- Churn rate (month)
- ARPU (average revenue per user)
- Lifetime value (LTV) by cohort
```

**Breakdown Table**:
```
| Tier | Users | MRR | Growth | LTV |
|------|-------|-----|--------|-----|
| Free | 45K | $0 | +8% | $0 |
| Premium | 2.3K | $11.5K | +12% | $240 |
| Family | 800 | $7.2K | +5% | $450 |
| TOTAL | 48.1K | $18.7K | +8% | $38 |
```

---

## Creator Dashboard

**My Articles**:
```
Same list view as admin, but filtered to creator's own articles
Status breakdown: (X draft) (Y scheduled) (Z published)
[Write Article] button
```

**My Stats**:
```
Period selector: [This Month] [Last 30d] [This Year] [All Time]

Key Metrics:
  - Articles published
  - Total views
  - Total comments
  - Total likes
  - Engagement rate
  - Follower growth

Charts:
  1. Views over time (area chart)
  2. Top articles (bar chart)
  3. Engagement breakdown (pie chart)
  4. Subscriber growth (line chart)
```

**Subscriber Management**:
```
Subscribers list:
  | Name | Joined | Status |
  
Subscriber stats:
  - Total subscribers
  - Growth trend
  - Retention rate
  - [Send Newsletter] button
```

**Notifications**:
```
- New comments on my articles
- New subscribers
- Featured/trending article
- Milestone reached (e.g., 1K views)
- Moderation action on my content
```

---

## Admin Settings

### Workspace Settings (admin only)

**General**:
```
- Workspace name
- Logo upload
- Primary color (color picker)
- Footer content (rich editor)
- Support email address
```

**Content Policies**:
```
- Comment moderation toggle (auto, manual, disabled)
- Allowed content categories (checkboxes)
- Age ratings requirement (toggle)
- Auto-flag keywords (textarea)
```

**Subscription Tiers**:
```
Tier configurations:
  | Tier | Price | Features | Active |
  
[+ Add Tier] button
Edit modal:
  - Tier name
  - Monthly price
  - Features list (textarea)
  - Feature toggles (ads, premium articles, etc.)
  - Stripe product ID
```

**Integrations**:
```
[Connect] buttons for:
- Stripe (payment processor)
- Slack (notifications)
- Google Analytics
- Facebook Pixel
- Custom Webhooks

Show: connected/disconnected status, last sync time
```

### Team Management (admin only)

**Users List**:
```
| Email | Role | Status | Added Date | Last Login | Actions |
  
Filter: role, status (active/suspended)
[+ Add User] button
```

**Add User Modal**:
```
- Email (required)
- Role dropdown (admin, moderator, editor, creator)
- Status (active, pending, suspended)
[Send Invite] [Cancel]
```

**Audit Log**:
```
Log of all admin actions:
  | Date | User | Action | Details | Status |
  
Filter: date range, user, action type (login, publish, delete, etc.)
Export to CSV
```

---

## Real-Time Updates & Notifications

### WebSocket Connections

**Live Metrics Update**:
```javascript
// Dashboard subscribes to real-time metric events
ws.on('metrics:update', ({ views, comments, engagement_rate }) => {
  updateDashboard(metrics);
  // Triggers UI update with smooth animation
});
```

**Live Moderation Queue**:
```
- New flagged items appear at top of queue instantly
- Status updates animate (pending → approved)
- Count badges update in real-time
```

**Live Comment Notifications**:
```
- Toast notification: "New comment on 'Article Title'"
- [View] button links to comment thread
- Dismiss or auto-hide after 5 seconds
```

### Notification Center

**Notification Types**:
```
1. Content: Article published, flagged, featured
2. Engagement: New comment, new subscriber, milestone
3. Moderation: Flagged content needs review, action taken
4. System: API errors, maintenance, quota warnings
```

**Notification Preferences**:
```
☐ Email notifications
☐ Browser push notifications (requires permission)
☐ In-app notifications

Per notification type:
  [Email] [Push] [In-App] sliders
```

---

## Responsive Design & Mobile

### Mobile-First Breakpoints

```
- Phone (< 640px): Single column, collapsible nav, touch-friendly buttons
- Tablet (640px - 1024px): 2 columns, side nav, larger touch targets
- Desktop (> 1024px): 3+ columns, full sidebar, hover effects
```

### Mobile Optimizations

**Navigation**:
```
Desktop: Fixed sidebar with all links
Tablet: Collapsible sidebar (hamburger)
Mobile: Bottom tab bar + top app bar
```

**Tables**:
```
Desktop: Full table with all columns
Mobile: Card view (one row = one card, swipe to see more)
```

**Modals**:
```
Desktop: Modal dialog (centered)
Mobile: Full-screen bottom sheet (swipe to close)
```

**Forms**:
```
Desktop: Side-by-side fields
Mobile: Stacked fields, one per line
```

---

## Performance & UX Patterns

### Loading States

**Skeleton Screens** (not spinners):
```
Instead of spinner, show placeholder with same shape as content
Articles list → show 5 fake article rows (animated shimmer)
Analytics chart → show gray placeholder in chart area
```

**Pagination & Infinite Scroll**:
```
Tables: Use pagination (20, 50, 100 items per page)
Moderation queue: Infinite scroll with "Load More" button
```

**Debouncing**:
```
Search input: Debounce 300ms before API call
Filter changes: Debounce 500ms before refetch
```

### Caching Strategy

**React Query Configuration**:
```javascript
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5,  // 5 minutes
      gcTime: 1000 * 60 * 10,    // 10 minutes
      retry: 2,
    },
  },
});
```

**Cache Keys**:
```
articles: { articles, all }
articles: { articles, filters: { category: 'news', status: 'published' } }
moderation:queue: { moderation, queue, filters: { status: 'pending' } }
analytics:overview: { analytics, overview, period: 'month' }
```

### Error Handling

**Error UI**:
```
Toast notification (red background, dismiss button)
"Failed to load articles. [Retry] [Dismiss]"

Or inline error (if part of larger page):
"Error loading moderation queue. Please refresh."
```

**Graceful Degradation**:
```
If chart library fails → show data in table instead
If WebSocket fails → fall back to polling every 5s
If image fails to load → show placeholder
```

### Accessibility

**WCAG 2.1 Level AA**:
- Semantic HTML (header, nav, main, section, article)
- ARIA labels for icons and buttons
- Keyboard navigation (tab, enter, esc)
- Color contrast ratio ≥ 4.5:1
- Alt text for all images
- Focus indicators visible

**Screen Reader Testing**:
```
List page: "Articles list, 50 items, 1 of 5 pages"
Moderation row: "Article 'Title', pending review, spam reason, assigned to John"
Button: "Delete article, requires confirmation"
```

---

## Design System & Components

### Colors (TailwindCSS)

```
Primary: #10b981 (emerald)
Success: #10b981
Warning: #f59e0b (amber)
Error: #ef4444 (red)
Info: #3b82f6 (blue)
Muted: #6b7280 (gray)
```

### Typography

```
Heading 1 (h1): 2rem, bold, #111827
Heading 2 (h2): 1.5rem, bold, #111827
Body: 1rem, normal, #374151
Small: 0.875rem, normal, #6b7280
Monospace (code): 0.875rem, font-mono, #1f2937
```

### Spacing

```
Base unit: 0.25rem (4px)
Common: 4px, 8px, 12px, 16px, 24px, 32px
Padding: 12px, 16px, 24px
Margin: 16px, 24px, 32px, 48px
```

### Icons

```
Library: Heroicons (solid and outline)
Size: 16px (small), 20px (medium), 24px (large)
Color: Inherited from text color
```

### Buttons

```
Primary: emerald background, white text, hover: darker green
Secondary: gray background, dark gray text
Danger: red background, white text
Disabled: gray background, muted text, cursor: not-allowed
Size: sm (8px padding), md (12px padding), lg (16px padding)
```

---

## Common Workflows

### Publishing an Article

```
1. Editor clicks [Write Article]
2. Creates draft article with basic info
3. Edits title, content, metadata
4. Uploads featured image
5. Chooses category and tags
6. Selects publish status:
   - Draft: Save for later
   - Scheduled: Pick date/time
   - Published: Publish immediately
7. [Save and Publish]
8. Article appears in feed/category
9. Notifications sent to subscribers
```

### Moderating Flagged Content

```
1. Moderator views moderation queue
2. Clicks flagged item (e.g., comment)
3. Reads content, flag reason, context
4. Decision:
   a) Approve: Content was fine, restore visibility
   b) Remove: Content violates policy, hide from feed
   c) Escalate: Needs legal review, assigns to admin
5. Add optional notes (visible in audit log)
6. Notification sent to content creator
7. Item removed from moderator's queue
```

### Analyzing Content Performance

```
1. Analytics > Content Performance
2. Select date range (e.g., last 30 days)
3. Filter by category or sort by metric
4. Identify top performer
5. Click row to see detailed breakdown:
   - Geographic distribution of views
   - Device breakdown
   - Referrer breakdown (social, direct, search)
   - Comment growth over time
6. Export data to CSV for further analysis
```

---

## Integration Points

### With API

- All data fetched via REST API (`/v1/` or `/v2/` endpoints)
- Mutations via POST/PUT/DELETE
- Polling vs. subscription-based updates
- Error handling with proper status codes

### With Stripe

- Subscription management (upgrade/downgrade)
- Invoice history
- Payment method management
- Webhook integration for billing events

### With Email Service

- Transactional emails (password reset, notifications)
- Marketing emails (newsletter)
- Template management in dashboard

### With Analytics Service

- Google Analytics integration (if opted in)
- Custom event tracking
- Attribution modeling

---

## See Also

- **CLI Guide**: `grenadianbuzz-cli-guide.md` (command-line management)
- **API Patterns**: `grenadianbuzz-api-patterns.md` (REST endpoints)
- **Website Guide**: `grenadianbuzz-website-guide.md` (public site)
- **Domain Checklist**: `grenadianbuzz-domain-checklist.md` (design validation)
