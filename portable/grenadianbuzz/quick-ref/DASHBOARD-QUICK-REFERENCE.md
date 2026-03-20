# GrenadianBuzz Dashboard Quick Reference

**One-page guide for common dashboard tasks and layouts**

---

## Navigation Shortcuts

| Section | Path | Role |
|---------|------|------|
| Content | `/dashboard/articles` | Editor, admin |
| Moderation Queue | `/dashboard/moderation/queue` | Moderator, admin |
| Analytics Overview | `/dashboard/analytics/overview` | Editor, admin, creator |
| My Creator Stats | `/dashboard/creators/stats` | Creator |
| Settings | `/dashboard/settings` | All |

---

## Content Management Dashboard

### Articles

**Common tasks**:
- **Create draft**: Click "New Article" → title, content, featured image → Save
- **Schedule publish**: Edit article → Set "Publish at" → Confirm
- **Bulk actions**: Select items (checkbox) → Choose action (publish, archive, delete) → Confirm
- **Filter/sort**: Use column headers (Published At, Status, Author) for sorting; sidebar for filters

**Key fields**:
| Field | Purpose | Required |
|-------|---------|----------|
| Title | Article headline | ✓ |
| Slug | URL-friendly name (auto-generated) | ✓ |
| Content | Markdown editor with preview | ✓ |
| Featured Image | Hero image (recommended 1200×600px) | Optional |
| Category | News, Culture, Events, etc. | ✓ |
| Status | Draft, Scheduled, Published, Archived | Auto |
| Tags | Comma-separated keywords | Optional |

### Obituaries

**Common tasks**:
- **Add obituary**: Click "New Obituary" → Full name, DOD, bio → Upload photo → Save
- **Update memorial info**: Edit → Add condolences count, related family links
- **Search**: Use search box to find by name; click to edit or view memorial

**Key sections**:
```
Obituary Detail Page
├── Name & Dates (header)
├── Biography section
├── Photos gallery
├── Condolence messages (read-only from website)
├── Related family links
└── Metadata (created, updated, view count)
```

### Events

**Common tasks**:
- **Create event**: Click "New Event" → Title, date, location, description
- **Set recurrence**: For weekly/monthly events (Carnival, religious observances)
- **Categorize**: Select category (Cultural, Religious, National Holiday, Sports)
- **Manage RSVP**: View count, export attendee list if enabled

**Calendar view**: Switch to calendar view; click date to see/add events

### Radio Stations

**Common tasks**:
- **Add station**: Click "New Station" → Name, stream URL, bitrate, location
- **Update metadata**: Edit station details (image, description, schedule)
- **Health check**: Dashboard auto-checks stream availability; shows status badge

---

## Moderation Dashboard

### Flagged Queue

**Layout**:
```
Filters (left sidebar):
├── Status: Pending, Approved, Removed
├── Severity: Low, Medium, High
├── Content Type: Article, Comment, User
└── Date range: Last 24h, 7 days, etc.

Queue (main):
├── Row per flagged item
├── Icon: Content type (📄 Article, 💬 Comment, 👤 User)
├── Title/preview
├── Reason flagged (auto or manual)
├── Time flagged
├── Actions: Review, Approve, Remove, Escalate
```

### Actions

**Approve**: Content is fine; remove flag. Notifies user if they flagged it.

**Remove**: Delete content; notify creator. Creates audit trail.

**Escalate**: Move to senior moderator/admin. Adds note for reviewer.

**Bulk actions**:
1. Check multiple items (left checkboxes)
2. Select action dropdown at top
3. Add reason/note
4. Confirm

### Audit Log

**View**: Click "Audit Log" tab in Moderation

**Shows**:
- Who acted (moderator name)
- When (timestamp)
- What (action taken)
- On what (item ID, type, title)
- Reason (if provided)

**Export**: Click "Export" → CSV or JSON for analysis

---

## Analytics Dashboard

### Overview Tab

**Displays**:
```
Top cards:
├── Active users (last 24h)
├── Total engagement (likes + comments + saves)
├── New subscribers
└── Content flagged (pending review)

Charts:
├── Engagement trend (last 30 days)
├── Top articles (by engagement)
├── Geographic distribution (map or bar chart)
└── Subscription metrics (growth, churn)
```

**Time range selector**: Top right; default 30 days

### Content Performance

**Shows per article**:
| Metric | Meaning |
|--------|---------|
| Views | Page loads |
| Engagement | Likes + saves + comments |
| Share rate | % of viewers who shared |
| Time spent | Avg seconds on page |
| Comments | Discussion count |

**Filter by**:
- Category
- Date range
- Author
- Content type (article, obituary, event)

### Engagement Tab

**Breakdown**:
- Reactions by type (👍, ❤️, 🕯️, etc.)
- Comments vs. engagement ratio
- Top commenters
- Sentiment distribution (if enabled)

---

## Creator Dashboard (Creator Role Only)

### My Stats

**Personal metrics**:
| Metric | Meaning |
|--------|---------|
| Followers | Total subscribers to your content |
| Engagement rate | % of followers who interacted |
| Top article | Highest-performing post |
| This month | Engagement in current month |

**Content list**:
- All your articles
- Draft status
- Publish date
- Engagement numbers
- Edit link

### Subscribers

**Table shows**:
- Email address
- Subscription date
- Last article read
- Engagement score
- Tier (free, premium, family)

**Export**: Click "Export" → CSV for email list

---

## Settings

### Profile

**Update**:
- Display name
- Email address
- Password
- Profile photo (optional)

### Notification Preferences

**Choose**:
- Email on new comments on your articles
- Email when someone follows you (creator)
- Email for moderation alerts (admin/moderator)
- Browser push notifications

### API Keys (Admin)

**Manage API keys for integrations**:
- Click "Generate new key"
- Copy token (shown once)
- Store securely in password manager
- Revoke old keys when done

### Workspace (Admin Only)

**Configure**:
- Logo/branding
- Email sender address
- Rate limits
- Feature flags

---

## Responsive Behavior

### Desktop (1200px+)

- Sidebar always visible (left)
- Full-width tables with horizontal scroll
- Charts rendered at full resolution

### Tablet (768px–1199px)

- Sidebar collapses to icons
- Tables scroll horizontally
- Charts resize for smaller viewport

### Mobile (< 768px)

- Hamburger menu (top left)
- Stacked layout (no sidebar)
- Cards for metrics instead of charts
- Actions move to dropdown menu
- Confirmation dialogs for destructive actions

**Tip**: Dashboard is fully mobile-responsive; access admin tasks from phone if needed.

---

## Keyboard Shortcuts (Coming Soon)

```
j/k         Next/previous item
e           Edit selected
d           Delete (with confirmation)
?           Show help
```

---

## Performance Tips

- **Avoid refreshing**: Data auto-updates via WebSocket (no manual refresh needed)
- **Bulk actions**: Faster than individual edits for 10+ items
- **Filters**: Use date range to reduce table size; easier to scroll
- **Export for reports**: Download data as CSV/JSON for analysis in spreadsheets

---

## Common Issues

### "Session expired" message
→ Log back in; tokens refresh automatically if you stay active

### "Permission denied" on moderation
→ Ask admin; you may need moderator role assigned

### Bulk action failed on some items
→ Check audit log; typically constraint violation (e.g., already published)

### Charts not loading
→ Try hard refresh (Cmd+Shift+R on Mac, Ctrl+Shift+R on Windows)

---

## See Also

- **Full Dashboard Guide**: `reference/grenadianbuzz-dashboard-guide.md` (5+ dashboards, RBAC, real-time patterns)
- **API Patterns**: `reference/grenadianbuzz-api-patterns.md` (endpoints used by dashboard)
- **Main Skill**: `SKILL.md` (cross-surface guidance)
