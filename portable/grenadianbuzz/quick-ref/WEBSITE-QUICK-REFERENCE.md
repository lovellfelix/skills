# GrenadianBuzz Website Quick Reference

**One-page guide for common website navigation, features, and user flows**

---

## Navigation Shortcuts

| Page | Path | Purpose |
|------|------|---------|
| Home | `/` | Featured content, hero |
| Articles | `/articles` | All news, filterable feed |
| Obituaries | `/obituaries` | Search, browse, add condolences |
| Events | `/events` | Calendar, upcoming cultural events |
| Radio | `/radio` | Station list, stream player |
| Search | `/search` | Full-text search across all content |
| Profile (logged in) | `/profile` | Your saved articles, settings |

---

## Homepage

**Hero section**: Featured article with image, headline, snippet

**Below fold**:
```
Featured Section
├── Large card: Latest trending article
├── Smaller cards: Latest in each category
│   ├── News (3-4 articles)
│   ├── Obituaries (2-3 recent)
│   ├── Events (3 upcoming)
│   └── Radio (3 top stations)
└── Newsletter signup CTA

Trending
├── "Today's trending" - Top 5 articles by engagement
└── "Top creators" - Most-followed authors

Community
├── Recent comments
└── Latest saved items
```

**Footer**:
- About GrenadianBuzz
- Subscribe link
- Contact form
- Social links (Twitter, Facebook)
- Privacy, Terms

---

## Articles (News Feed)

### Browse

**Layout**:
```
Filters (left sidebar on desktop; dropdown on mobile):
├── Category: News, Culture, Events, Radio, Opinion
├── Time: Last 24h, Week, Month
├── Source: Manual, RSS feeds, User-submitted
└── Sort: Latest, Trending, Most commented

Feed (main):
├── Article card per item
│   ├── Featured image (thumbnail)
│   ├── Headline
│   ├── Snippet (first 140 chars)
│   ├── Author name & date
│   ├── Engagement: ❤️ likes, 💬 comments, 📌 saves
│   └── Category badge (color-coded)
└── Infinite scroll or "Load more" button
```

**Infinite scroll**: Automatically loads next page as you scroll to bottom (mobile-optimized)

### Read Article

**Article detail page**:
```
Header:
├── Large featured image
├── Headline
├── Author name (clickable → author profile)
├── Publication date
└── Reading time estimate

Body:
├── Markdown rendered HTML
├── Embedded images with captions
├── Links (open in same tab or new window)
└── Pull quotes (highlighted)

Sidebar (desktop):
├── Related articles (3-5)
├── Author bio (with follow button)
├── Trending today
└── Newsletter signup CTA

Engagement (below article):
├── Reaction buttons: 👍 like, ❤️ love, 🕯️ remember, 💖 compassion, 🌹 tribute, 🙏 respect
├── Comment thread (sorted by date, newest first)
├── "Add comment" input (requires login)
├── Share buttons (Twitter, Facebook, WhatsApp, Email)
└── Save button (heart icon; toggles)
```

**Comments**:
- Threaded replies (click "Reply" on comment)
- Edit/delete your own (30-min window)
- Flag inappropriate comments
- Newest comments collapsed; expand to view

---

## Obituaries

### Search & Browse

**Search box**: Prominent on section header

**Results**:
```
Card per obituary:
├── Name (large, bold)
├── Birth–Death dates
├── Location (if available)
├── Photo (thumbnail or placeholder)
├── Snippet of bio (first 100 words)
└── "View full memorial" link
```

**Browse by**:
- Recent deaths (last 30 days)
- Alphabetical (A-Z)
- Geographic location (if enabled)

### Obituary Detail Page

**Layout**:
```
Header:
├── Name & dates (prominent)
├── Location & age
└── Photo gallery (multiple photos if available)

Bio section:
├── Full biography (as entered)
├── Notable accomplishments
└── Family mentions (links to related memorials)

Condolences:
├── "Add condolence" input (anonymous or logged-in)
├── Condolence count & list
├── Condolences sorted by date (newest first)
└── Share memorial (email to family)

Related:
├── Family members (if linked)
├── Similar obituaries (same location, age range)
└── Community remembrances
```

**Actions**:
- Print memorial (PDF download)
- Email to family
- Share on social media
- Bookmark memorial (if logged in)

---

## Events

### Calendar View (Desktop)

**Month calendar**:
```
Sun  Mon  Tue  Wed  Thu  Fri  Sat
                         1    2    3
4    5    6    7    [8]  9    10
     ↑ Today (blue circle)

Date 8 (selected):
├── Carnival parade (9:00 AM, Grenada)
├── Independence ceremony (3:00 PM, national)
└── Community gathering (7:00 PM, St. George's)

Filters (left):
├── Category: Cultural, Religious, National, Sports
├── Location: All, St. George's, Carriacou, etc.
└── This week / This month
```

**List view** (mobile):
- Vertical list of events
- Today's events at top
- Upcoming highlighted in next 7 days
- Expandable detail (tap to see full info)

### Event Detail Page

**Layout**:
```
Header:
├── Event name (large)
├── Date & time (in user's timezone if logged in)
├── Location map (Google Maps embed)
└── Category badge

Details:
├── Full description
├── Organizer name (if available)
├── RSVP count (if RSVP enabled)
├── Related articles (if any)
└── Map embed (location, directions link)

Actions:
├── "Save event" button (bookmark)
├── "Share" button (social, email, link)
└── "Get directions" link (Google Maps)
```

---

## Radio

### Station Browsing

**Grid view**:
```
Station card (per station):
├── Station logo/image
├── Name (e.g., "Grenada FM")
├── Genre (Music, Talk, News, etc.)
├── Listener count badge ("🎧 2.3K listening now")
├── "Play" button (blue)
└── "Favorite" button (heart)
```

**List view** (mobile):
- Vertical list with stream status (🟢 Online, 🔴 Offline)

### Station Detail & Streaming

**Player**:
```
[Album art / station logo]
        ▶ Play / ⏸ Pause
[═══●───────────────]
   Now playing     Duration
  "Last Calypsian"  2:34

Station info:
├── Name & description
├── Genres/categories
├── Schedule (if available)
├── Listen count (all-time)
└── Related articles
```

**Features**:
- Fullscreen player (mobile)
- Favorite/bookmark station
- Share stream link
- Quality selector (if available: 128kbps, 192kbps, etc.)

---

## Search

### Search Box

**Appears in**: Header on all pages (magnifying glass icon)

**Suggestions** (as you type):
- Recent articles matching query
- Popular search terms
- Top creators/authors

### Results Page

**Results show**:
```
Tabs:
├── All (default)
├── Articles
├── Obituaries
├── Events
├── Radio
└── People (creators/authors)

Per result:
├── Title/name
├── Type badge (Article, Obituary, etc.)
├── Snippet (100 words with query highlighted)
├── Author (if article)
├── Date (if available)
├── Engagement metric (likes, listeners)
└── Click to open detail
```

**Refine search**:
- Date range slider
- Category filter
- Sort: Relevance, Latest, Most popular

---

## User Authentication & Profile

### Login

**Methods**:
- Email + password
- Google OAuth
- Facebook OAuth

**Post-login**:
- Saves location in localStorage
- Redirects to previous page or homepage
- Header updates (shows user avatar, "Profile" link)

### User Profile (Logged In)

**Your profile** (`/profile`):
```
Header:
├── Your avatar/initials
├── Display name
├── Email
└── Member since date

Tabs:
├── Saved articles (bookmarks)
├── My comments (if creator)
└── Subscription tier (Free, Premium, Family)

Actions:
├── Edit profile
├── Manage subscription
├── API keys (if creator/admin)
├── Logout
└── Delete account
```

### Saved Articles

**Collection** of bookmarked articles:
- Remove from saved (X button)
- Sort by: Date saved, Date published
- Filter by: Category, Author
- Archive for later reading

---

## Engagement Patterns

### Reactions

**Available reactions** (context-dependent):
- Articles & comments: 👍 ❤️ 🕯️ 💖 🌹 🙏
- Obituaries: 🙏 ❤️ 🕯️ 💖 (compassion focus)
- Events: 👍 ❤️

**Click to react**; click again to remove. Shows count of each reaction.

### Comments

**Leave comment**:
1. Click "Add comment" or reply box
2. Log in (if not already)
3. Type message (up to 500 chars)
4. Click "Post"

**Edit/delete**: Hover over your comment → Click ... menu → Edit/Delete (30-min window)

**Flag**: Click ... menu → Report as inappropriate (moderation review)

### Sharing

**Share article/obituary/event**:
- Twitter: Pre-populated tweet + link
- Facebook: Share to timeline with preview
- WhatsApp: Send link directly to contacts
- Email: Open mail client with subject + link
- Copy link: Puts URL in clipboard

---

## Personalization (Logged In)

### Feed Recommendations

**Homepage feed**:
- Shows articles based on past reads
- Highlights creators you follow (if any)
- Filters by your timezone (for events)

### Saved Subscriptions

**Subscribe to category**: Click "Subscribe to {Category}" → Receive email summaries

**Unsubscribe**: Settings → Email preferences

---

## Mobile Optimization

### Responsive Breakpoints

| Size | Behavior |
|------|----------|
| Desktop (1200px+) | Full sidebar, multi-column layout |
| Tablet (768–1199px) | Sidebar collapses, two-column articles |
| Mobile (< 768px) | Single column, hamburger menu, bottom nav |

### Bottom Navigation (Mobile)

```
[🏠]  [📰]  [⚰️]  [📅]  [📻]  [🔍]
Home  News  Obits Events Radio Search
```

---

## Performance & Loading

- **Images**: Lazy-loaded (load as you scroll)
- **Infinite scroll**: Loads next 20 articles automatically
- **Streaming**: Geolocation bypass for radio (diaspora-friendly)
- **Caching**: Saves read articles locally (offline reading coming soon)

---

## See Also

- **Full Website Guide**: `reference/grenadianbuzz-website-guide.md` (10+ pages, SEO, accessibility, engagement patterns)
- **API Patterns**: `reference/grenadianbuzz-api-patterns.md` (endpoints used by website)
- **Main Skill**: `SKILL.md` (cross-surface guidance)
