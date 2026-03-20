# GrenadianBuzz Website Reference Guide

**Deep reference for public website design, layouts, and content patterns for GrenadianBuzz**

Based on actual website surface: `~/projects/grenadianbuzz/web/grenadianbuzz.com`

---

## Table of Contents

1. [Website Architecture](#website-architecture)
2. [Navigation & Information Architecture](#navigation--information-architecture)
3. [Homepage](#homepage)
4. [Article & Content Pages](#article--content-pages)
5. [Obituaries Section](#obituaries-section)
6. [Events Section](#events-section)
7. [Radio Section](#radio-section)
8. [Search & Discovery](#search--discovery)
9. [Engagement & Interaction](#engagement--interaction)
10. [Personalization & Recommendations](#personalization--recommendations)
11. [Authentication & User Accounts](#authentication--user-accounts)
12. [Mobile & Responsive Design](#mobile--responsive-design)
13. [Performance & SEO](#performance--seo)
14. [Accessibility](#accessibility)

---

## Website Architecture

### Tech Stack

- **Frontend Framework**: Next.js 14+ with React 18, TypeScript
- **Styling**: TailwindCSS with custom theme
- **State Management**: Zustand for client state, React Query for API caching
- **CMS Integration**: Headless API (GrenadianBuzz backend)
- **Search**: Elasticsearch or hosted search service
- **Authentication**: OAuth (Google, Facebook) + email/password
- **Analytics**: Google Analytics 4, custom event tracking
- **Performance**: Next.js Image optimization, ISR (Incremental Static Regeneration)
- **CDN**: Cloudflare with edge caching

### Core Pages

```
grenadianbuzz.com/
├── /                          (Homepage)
├── /articles                  (Articles list/feed)
├── /articles/:slug            (Article detail)
├── /news                      (News category)
├── /obituaries                (Obituaries section)
├── /obituaries/:slug          (Obituary detail)
├── /events                    (Events calendar)
├── /events/:slug              (Event detail)
├── /radio                     (Radio stations)
├── /radio/:id                 (Station detail + stream)
├── /search                    (Search results)
├── /profile                   (User profile, if logged in)
├── /saved                     (Saved articles, if logged in)
├── /login                     (Authentication)
├── /about                     (About GrenadianBuzz)
├── /contact                   (Contact form)
├── /privacy                   (Privacy policy)
├── /terms                     (Terms of service)
└── /subscribe                 (Subscription page)
```

---

## Navigation & Information Architecture

### Main Navigation (Header)

```
[Logo] [GrenadianBuzz]

Links (desktop):
  [Home] [News] [Obituaries] [Events] [Radio] [About]
  Search icon → search modal
  (if logged in) Profile dropdown
  (if not) [Login] [Subscribe]

Mobile/Tablet (hamburger):
  ≡ button → slides in drawer from left
    Links: Home, News, Obituaries, Events, Radio, About
    Account section: Login / [Profile] [Logout]
    Search box at top of drawer
```

### Breadcrumb Navigation

```
Where appropriate:
  Home > News > Article Category > Article Title
  Home > Obituaries > [Search filters] > [John Doe]
```

### Footer

```
[Logo] GrenadianBuzz

Links organized in columns:
  Content:        Account:         Company:        Legal:
  [News]          [Login]          [About]         [Privacy]
  [Obituaries]    [Subscribe]      [Contact]       [Terms]
  [Events]        [Saved Articles] [Careers]       [Cookies]
  [Radio]         [Profile]        [Ad Info]       [Contact]

Newsletter signup:
  "Get news in your inbox"
  [Email input] [Subscribe button]

Social media icons: Facebook, Twitter, Instagram

Copyright: © 2026 GrenadianBuzz. All rights reserved.
```

---

## Homepage

### Hero Section

```
Full-width background image (featured article or event)
Overlay: dark gradient (top: transparent, bottom: dark)

Content (centered, bottom half):
  Headline: Large, bold, white text (h1)
    "Grenadian Stories, Global Reach"
  
  Subheadline: Smaller, lighter text
    "News, obituaries, events, and radio from Grenada"
  
  CTA buttons:
    [Explore Latest News] (primary button)
    [Subscribe Free] (secondary button)
```

### Featured Content Section

```
"Latest & Trending" section

Layout (desktop): 3-column grid
  [Featured Article 1] [Featured Article 2] [Featured Article 3]
  (larger, aspect ratio 3:2)

Layout (mobile): Single column, scrollable horizontally

Card content per article:
  - Featured image (responsive)
  - Category badge (colored: news, obituaries, events, etc.)
  - Headline (2-3 lines, truncated with ellipsis)
  - Excerpt (1-2 lines, truncated)
  - Author name (small text, gray)
  - Time ago (e.g., "2 hours ago")
  - Engagement metrics (comment icon + count, like icon + count)
```

### Content Grid Section

```
"News & Stories" 

Layout (desktop): 
  Left: Main article (large, 2x size)
  Right: 6 article cards in 2x3 grid

Each card:
  - Smaller image
  - Category badge
  - Headline
  - Time ago
  - Hover effect: slight shadow, text color change
```

### Obituaries Preview

```
"Recent Obituaries" section

Grid of 4-6 obituary cards (mobile: 1-2 columns, desktop: 3-4):
  Card content:
    - Photo (headshot, circular crop)
    - Name (bold)
    - Birth year - Death year (e.g., "1945 - 2026")
    - Brief excerpt (location, profession)
    - [Read More] link
  
  Hover: Slight zoom, shadow increase
```

### Events Preview

```
"Upcoming Events" section

Layout: 
  Desktop: 3 event cards (horizontal layout)
  Mobile: Single column, scrollable

Card content:
  - Event date (large, bold, accent color)
  - Month name (smaller)
  - Event title (bold, 2 lines max)
  - Location (small text, gray)
  - Category badge (e.g., Carnival, Religious, etc.)
  - [Learn More] link
```

### Radio Preview

```
"Tune In" section

Layout: Carousel of 4-6 radio station cards (desktop scrolls horizontally)

Card content:
  - Station logo (if available, else colored placeholder)
  - Station name (bold)
  - Genre (music, news, talk, etc.)
  - Language (English, French Creole, etc.)
  - [Listen] button (opens player modal)
  - Listener count (if real-time available)
```

### Newsletter Signup

```
Background: Accent color (emerald)
Heading: "Never miss a story"
Subheading: "Subscribe to GrenadianBuzz for news in your inbox"

Form:
  [Email input] [Subscribe button]
  Small text: "No spam. Unsubscribe anytime."
```

### Social Proof Section (Optional)

```
"Trusted by 90,000+ readers"

Stats row:
  [90K+ Readers] [5K+ Daily Stories] [24/7 Radio]
```

---

## Article & Content Pages

### Article List/Feed View

**Filter Bar** (sticky on scroll):
```
[Search box: placeholder "Search articles..."]

Filters (left side):
  Category:
    ☐ All Categories
    ☐ News
    ☐ Features
    ☐ Opinion
    
  Time Period:
    ○ Last 24 hours
    ○ Last 7 days
    ○ Last 30 days
    ○ Any time
  
  Sort By:
    ○ Newest first
    ○ Most popular
    ○ Trending

[Clear Filters] link (if filters applied)
```

**Article Cards** (full width, mobile-friendly):

```
Layout (desktop): Two-column layout
  Left (60%): Featured + main article card list
  Right (40%): Sidebar (trending, ads, newsletter signup)

Layout (mobile): Single column, stacked

Card format (list):
  [Image (16:9)] [Title, 2-3 lines]
  [Category badge] [Author] [Time ago]
  [Excerpt, 2 lines, truncated]
  [Comments icon: X] [Likes icon: X] [Share icon]
  Hover: Background color change, shadow
```

### Article Detail Page

**Header Section**:
```
[Breadcrumb: Home > News > Article Title]

Article Metadata (below breadcrumb):
  [Category badge] | By [Author Name] | [Time published]

Headline (h1):
  "Grenada Prepares for Carnival Season Celebrations"
  (Large, bold, line-height 1.3)

Subheadline (h2):
  "Record crowds expected as festivities kick off this weekend"
  (Slightly smaller, gray text)

Meta info row:
  [Avatar] Author Name | [Calendar] Mar 20, 2026 | [Clock] 3 min read
  
Featured image:
  Full-width (max-width: 900px, responsive)
  Aspect ratio: 16:9
  Caption below (small, gray, italic)

Share buttons (sticky on scroll):
  [Share on Facebook] [Share on Twitter] [Copy Link]
```

**Article Body**:
```
Content container (max-width: 700px, centered)
Typography:
  - Paragraph spacing: 1.5rem
  - Line height: 1.75
  - Font size: 1.125rem
  - Color: #1f2937 (dark gray)

Inline elements:
  Links: Color: emerald, underline on hover
  Bold: #111827 (darker)
  Italic: Slightly lighter, serif font
  Blockquote: Left border (emerald), light gray background, italic

Images within content:
  Max-width: 100%, responsive
  Margin: 2rem top/bottom
  Caption: Centered, small, gray, italic

Code blocks (if technical):
  Gray background, monospace font, syntax highlighting

Lists:
  Bullet points: Indented, spacing
  Numbered lists: 1. 2. 3. format
```

**Related Content** (below article):
```
"Related Articles" section

Grid of 3-4 related article cards:
  Smaller images, headline, excerpt
  Link to each article
  Hover effect
```

**Comment Section** (if enabled):
```
"Comments" heading

If user is logged in:
  [User avatar] Textarea: "Share your thoughts..."
  [Post Comment] button

If user not logged in:
  "Sign in to comment"
  [Login with Google] [Login with Facebook] [Email login link]

Existing comments:
  [Author avatar] Author Name | Time ago
  Comment text
  [Reply] [Like] [More menu]
  
  Nested replies (indented):
    [Reply author avatar] Author | Time ago
    Reply text
    [Reply] [Like] [More]

Sorting:
  Dropdown: [Newest first] [Most liked] [Most replies]
```

**Engagement Widgets** (right sidebar, sticky on scroll):

```
[Article Actions]
[❤️ Like] [💬 Comment] [📌 Save] [📤 Share]
  Views: 1,234 | Comments: 45

[Newsletter Signup]
"Get stories like this"
[Email input] [Subscribe]

[Ads]
(if applicable, with "Advertisement" label)

[Trending Now]
Trending article list (top 5, with numbers)
  1. Article title | 2.1K views
  2. Article title | 1.8K views
  ...

[More From Author]
Author bio card:
  [Avatar] 
  Author Name
  "Author bio excerpt..."
  [Follow] button
  
  List of 3 recent articles from author
```

---

## Obituaries Section

### Obituaries List

**Search & Filter** (prominent):
```
[Name search input: "Search by name..."]

Filters:
  Date: [Date picker from] - [to]
  Sort: [Recently added] [A-Z] [Z-A]
  Location: [Location search]

[Browse A-Z] alphabet buttons (A B C D ... Z)
```

**Obituary Cards** (grid or list):

Grid (desktop: 3-4 columns, mobile: 1-2):
```
[Photo: circular crop, headshot]
Name (bold)
Birth - Death (gray text)
Location/profession (small, gray)
[View Obituary] button
Hover: Shadow, slight zoom
```

### Obituary Detail Page

**Header**:
```
[Breadcrumb: Home > Obituaries > [Name]]

[Full name, large bold]
[Birth date] - [Death date] (Age: calculated)
Location: [City, Country]
```

**Main Content**:
```
Left column (70%, desktop; 100%, mobile):
  
  Photo gallery:
    Main image (large, responsive)
    Thumbnails below (scrollable on mobile)
    Image counter: "1 of 5"
  
  Biography:
    "A Tribute to [Name]"
    Rich text, multiple sections
    Photos interspersed
  
  Survived by:
    Family members list
    Relationships noted (child, spouse, etc.)
  
  Service information:
    Date & time of funeral/memorial
    Location & directions
    Funeral home contact
    [Directions] button (Google Maps integration)

Right sidebar (30%, desktop; below on mobile):
  
  Share buttons:
    [Share on Facebook] [Email] [Copy Link]
  
  Save obituary:
    ☐ Save this obituary (if logged in)
    "Save to your remembrances"
  
  Condolences:
    [Leave a message] button
    Recent condolences (list of 3-5 messages)
    [View all] link if more
```

**Condolences Section**:
```
"Remembrances & Condolences"

If logged in:
  Textarea: "Share a memory or condolence..."
  [Post] button

Existing messages:
  [User avatar] User name | Time ago
  Message text (max 500 chars)
  [Like] [Reply]

Nested replies (indented, same format)
```

**Related Obituaries**:
```
"Others We've Remembered"

Grid of 3 related obituaries (same time period, similar location, etc.)
Same card format as list view
```

---

## Events Section

### Events Calendar View

**Calendar Widget** (prominent):
```
Navigation:
  < [March 2026] >
  [Today] button

Mini calendar:
  Su Mo Tu We Th Fr Sa
  dates with events highlighted (dot or color)
  Click date to filter

List view (right side):
  Events for selected date(s)
  Card format (date, title, location)
```

**Events List View**:

```
Filter bar:
  Category:
    [All] [Carnival] [Religious] [Sports] [Cultural] [Other]
  
  Location:
    [Search location]
  
  Sort:
    [Upcoming] [Date] [Popular]

[Advanced filters] collapsible:
  Date range picker
  Free/Paid filter
  Featured filter

Layout: List or calendar grid toggle [List view] [Calendar]
```

**Event Cards**:

List format:
```
[Date: Large, bold]   [Title, 2 lines max]
[Month]               [Location, gray text]
[Time: if applicable] [Category badge]
                      [Description excerpt, 1 line]
                      [Attending: X people] [Learn More button]
```

Grid format (calendar):
```
Date in corner
Title (truncated)
Location (small, truncated)
Category color (background tint)
```

### Event Detail Page

**Header**:
```
[Breadcrumb: Home > Events > [Event title]]

Event title (h1, large)
Category badge (colored)

Metadata row:
  [Calendar] Date range (e.g., "Mar 21 - 24, 2026")
  [Clock] Time(s)
  [Location] Location / [Online] if virtual
  [Cost] Free or price

Featured image:
  Full-width, responsive, aspect ratio 16:9
```

**Event Details**:

Left column (65%, desktop):
```
Description:
  Rich text, markdown support
  Sections: Overview, Schedule, Participants, Highlights

Schedule (if multi-day/event with schedule):
  Day 1: Mar 21
    09:00 AM - Opening ceremony
    10:30 AM - Main event
    06:00 PM - Evening program
  
  Day 2: Mar 22
    ...

Location details:
  [Venue name]
  [Address]
  [Google Maps embed]
  [Directions] button (opens Google Maps)

Ticket info (if applicable):
  Ticket types (if available for sale)
  Price
  [Purchase] or [Learn More] link
```

Right sidebar (35%, desktop; below on mobile):
```
[Attending]
"X people planning to attend"
[I'm Going] button (if logged in)

Share buttons:
  [Share on Facebook] [Share on Twitter] [Copy Link]

Save event:
  ☐ Save to my calendar
  (if logged in, adds to saved events)

Related events:
  3-4 other upcoming events
  Similar category or time period
  Card format
```

**Comments/Discussion**:
```
"Event Comments"

Similar to article comments:
  Add comment (if logged in)
  Existing comments list
  Sort options
```

---

## Radio Section

### Radio Station List

**Filter Bar**:
```
Genre:
  [All] [Music] [News] [Sports] [Talk] [Variety]

Language:
  [All] [English] [French Creole] [French]

Status:
  ○ Online
  ○ All
```

**Station Cards**:

Grid (desktop: 3-4 columns, mobile: 1-2):
```
[Logo or colored placeholder]
Station name (bold)
Genre (small, colored badge)
Language (small text)
Listener count (if real-time): "234 listening now"
[Listen] button
Hover: Shadow, slight zoom
```

### Station Detail Page

**Header**:
```
[Breadcrumb: Home > Radio > [Station name]]

[Logo or placeholder]
Station name (large)
Genre | Language
"[X] people listening now" (if available)
```

**Main Content**:

Left column (65%, desktop):
```
Player:
  [Play/Pause button]
  Station name
  Current program (if available): "Now playing: [Program name]"
  Signal quality indicator (bars)
  Volume control

Description:
  Station bio / About this station
  Contact info if available
  
Schedule (if available):
  Current time and program
  Next 3 programs
  Link to full schedule

Related content:
  Recent articles about this station
  Trending from this genre
```

Right sidebar (35%, desktop; below on mobile):
```
Share:
  [Share on Facebook] [Copy Link]

Save:
  ☐ Save to my stations

More stations in this genre:
  3-4 related station cards
```

---

## Search & Discovery

### Search Page

**Search Bar** (top, sticky):
```
[Search input: "Search news, obituaries, events..."]
[Search button or enter to submit]

Filters (left sidebar, collapsible on mobile):
  Content type:
    ☐ Articles
    ☐ Obituaries
    ☐ Events
    ☐ Radio stations
  
  Date range:
    [Picker from] - [to]
  
  Category:
    (checkboxes based on selected content type)
```

**Search Results**:

```
"Search Results for '[query]'" (X results)

Results organized by type (if multi-type search):
  
  Articles (5 results)
    Result card format (title, excerpt, date, relevance score)
    [View all X article results]
  
  Obituaries (2 results)
    Similar card format
  
  Events (1 result)
    Similar card format

If single type selected:
  Paginated list of results
  [Previous] [1 2 3 4 5] [Next]

No results:
  "No results found for '[query]'"
  Suggestions: Check spelling, try different keywords
  [Browse categories] link
```

### Trending & Popular

**Trending Sidebar Widget** (on multiple pages):
```
"Trending Now" (updated real-time)

1. Article title | 1.2K views
2. Article title | 1.1K views
3. Article title | 980 views
4. Article title | 856 views
5. Article title | 745 views

[See all trending]
```

**Recommendation Algorithm**:
```
Based on:
  - Content user is viewing (if logged in)
  - Content user has saved
  - Category preferences
  - Engagement patterns
  
Shown as:
  - "Recommended for you" section
  - Related content cards
  - Homepage personalization (logged-in only)
```

---

## Engagement & Interaction

### Reactions/Likes

```
Like button:
  [❤️] [234] (click to like/unlike)
  
If user is logged in:
  Click adds heart, increments count
  Hover shows "You like this"
  
If user not logged in:
  Click opens login modal

Additional reactions (article level):
  ❤️ Love | 🙏 Respect | 💪 Powerful
  (hover shows counts)
```

### Comments

**Comment composition**:
```
If logged in:
  [User avatar] 
  Textarea: "Share your thoughts..."
  [Cancel] [Post] buttons
  Mentions: Type @ to mention users
  
If not logged in:
  "Sign in to comment"
  [Login with Google] [Login with Facebook] [Email]
```

**Comment display**:
```
[User avatar] User name | gray timestamp
Comment text (rendered markdown if supported)
[Like] [Reply] [More menu]

If flagged/removed:
  "[Content removed - violated community standards]"
  [View context] link (admin/moderator only)
```

### Save/Bookmarks

```
Save button:
  [📌] [Save] or just [📌] icon
  
If not logged in:
  Click opens login modal
  
If logged in:
  Click toggles save state
  Saved articles appear in /saved page
  Tooltip: "Saved" when active
```

### Share

```
Share button:
  [📤] [Share]
  
Share modal:
  [Share on Facebook] [Share on Twitter] [Copy Link]
  
  Copy link shows:
    Article URL [Copy to clipboard]
    "Copied!" notification
```

---

## Personalization & Recommendations

### User Preferences (Logged In Only)

**Preference Center** (/profile/preferences):
```
Content interests:
  ☐ News
  ☐ Obituaries
  ☐ Events
  ☐ Radio

Email frequency:
  [Daily digest] [Weekly] [None]

Newsletter signup:
  ☐ Latest news
  ☐ Weekly roundup
  ☐ Event announcements
  [Save preferences]
```

### Personalized Feed

**Logged-in user homepage** (customizable):
```
"For You" section
  Articles based on saved content, reading history
  [Customize feed preferences] link
  
"Latest in [Category]" sections
  Based on user's content preferences
  (e.g., "Latest Obituaries", "Upcoming Events")
  
"Recommended for You"
  ML-based recommendations
  Similar to articles user has engaged with
```

### Reading History

```
[Profile] > [Reading History]

List of articles recently viewed:
  | Article title | Category | Date | [Remove from history]

Clear all history option
```

---

## Authentication & User Accounts

### Login Page (/login)

```
Heading: "Welcome back to GrenadianBuzz"

Social login (primary):
  [Continue with Google] [Continue with Facebook]
  
Divider: "or"

Email/password (secondary):
  Email: [input]
  Password: [input, masked]
  ☐ Remember me
  [Forgot password?] link
  
  [Login] button

Bottom:
  "Don't have an account?" [Create one]
```

### Sign Up Page

```
Heading: "Join GrenadianBuzz"

Social signup (primary):
  [Sign up with Google] [Sign up with Facebook]
  
Divider: "or"

Email signup:
  Name: [input]
  Email: [input]
  Password: [input, masked]
  Confirm password: [input, masked]
  ☐ I agree to [Terms] and [Privacy Policy]
  
  [Create Account] button

Bottom:
  "Already have an account?" [Login]
```

### User Profile (/profile)

```
[User avatar, large]
User name (editable)
Email (read-only)

Sections:

Saved articles:
  "X saved articles"
  [View all saved]

Reading history:
  [View history]

Preferences:
  [Edit preferences]

Subscription:
  "Current plan: Free"
  [Upgrade to Premium] button

Account settings:
  [Password reset] [Logout]

Delete account:
  [Delete my account]
```

### Logout

```
Confirmation modal:
  "You'll be logged out."
  [Logout] [Cancel]

After logout:
  Redirect to homepage
  Show notification: "You've been logged out"
```

---

## Mobile & Responsive Design

### Breakpoints

```
Mobile (< 640px):
  - Single column layout
  - Hamburger menu (drawer from left)
  - Bottom tab navigation
  - Touch-friendly buttons (min 44x44px)
  - Full-width images

Tablet (640px - 1024px):
  - 2-column layout where applicable
  - Collapsible sidebar
  - Larger touch targets

Desktop (> 1024px):
  - Full navigation
  - 3+ column layouts
  - Hover effects enabled
  - Sidebar visible
```

### Mobile Navigation

```
Bottom navigation bar (sticky):
  [Home] [News] [Search] [Saved] [Profile]
  
Top app bar:
  [Hamburger menu] [Logo] [Search icon]
  
Drawer (hamburger menu):
  Links:
    [Home]
    [News]
    [Obituaries]
    [Events]
    [Radio]
    [About]
  
  User section (bottom of drawer):
    If logged in:
      [Profile] [Logout]
    If not:
      [Login] [Subscribe]
```

### Mobile Optimizations

**Images**:
```
Responsive: srcset for different sizes
Aspect ratio: Consistent 16:9 or 4:3
Lazy loading: Load as user scrolls
```

**Navigation**:
```
No hovers (no mouse)
Large tap targets
Swipe gestures where useful (card carousel)
```

**Forms**:
```
Full-width inputs
Auto-capitalization for name fields
Appropriate keyboard types (email, tel, etc.)
Clear error messages inline
```

---

## Performance & SEO

### Performance Optimization

**Next.js ISR** (Incremental Static Regeneration):
```
Homepage: Revalidate every 60 seconds
Article pages: Revalidate every 300 seconds (5 min)
List pages: Revalidate every 3600 seconds (1 hour)
Detail pages: Revalidate on-demand when content updated
```

**Image Optimization**:
```
Next.js Image component
Automatic format selection (WEBP, etc.)
Responsive sizes: srcset for mobile, tablet, desktop
Lazy loading with placeholder blur
Max width: 900px (article), 1200px (header)
```

**Caching Strategy**:
```
API responses: 5 min client-side cache
Static assets: 1 year (fingerprinted)
HTML: No cache (always fresh)
```

### SEO

**Meta Tags**:
```
Homepage:
  title: "GrenadianBuzz - News, Obituaries & Events from Grenada"
  description: "Stay informed with news, obituaries, cultural events, and radio from Grenada and the Caribbean diaspora."
  og:image: Featured image
  
Article:
  title: "[Article title] - GrenadianBuzz"
  description: "[Article excerpt or meta description, 155 chars]"
  og:image: Featured image
  canonical: Article URL
  article:published_time: Publish timestamp
  article:author: Author name
  article:tag: Categories/tags
```

**Structured Data** (JSON-LD):
```
Homepage:
  Organization schema

Article pages:
  Article schema (headline, image, author, date, body)
  BreadcrumbList schema

Event pages:
  Event schema (name, date, location, image)

Obituary pages:
  Person schema (name, birth/death dates)
```

**Sitemap**:
```
/sitemap.xml (auto-generated)
Includes:
  - Homepage
  - Article list pages
  - Individual articles
  - Obituaries
  - Events
  - Radio stations
```

**Robots.txt**:
```
Allow crawling of public pages
Disallow: /admin, /dashboard, /user-profile
Sitemap: https://grenadianbuzz.com/sitemap.xml
```

---

## Accessibility

**WCAG 2.1 AA Compliance**:

**Keyboard Navigation**:
```
Tab order logical
Focus indicators visible (outline or highlight)
All interactive elements keyboard accessible
Escape closes modals
Enter submits forms
```

**Screen Readers**:
```
Semantic HTML (nav, main, article, section)
ARIA labels for icons (e.g., aria-label="Close dialog")
Form labels associated with inputs
Alt text for images
Skip to main content link
```

**Color & Contrast**:
```
Text contrast: ≥ 4.5:1 (normal text), ≥ 3:1 (large text)
Color not sole means of conveying information
Icons paired with text labels
```

**Motion**:
```
Respect prefers-reduced-motion
Animations optional, not required
No auto-playing videos without controls
```

**Language**:
```
lang="en" attribute on html element
Identify changes in language (e.g., <span lang="fr">Patois</span>)
```

---

## Common Workflows

### Reading an Article

```
1. User navigates to /articles or /news
2. Sees list of articles
3. Clicks article title or [Read More]
4. Article detail page loads
5. Reads content (may contain images, videos)
6. Scrolls to comments, reads others' thoughts
7. If logged in: leaves comment or like
8. Clicks related article or [Back to list]
```

### Finding an Obituary

```
1. User navigates to /obituaries
2. Uses search box: types deceased person's name
3. Results appear
4. Clicks on correct person
5. Views full obituary (bio, photos, services)
6. Leaves condolence message (if logged in)
7. Sees related obituaries
```

### Discovering Events

```
1. User navigates to /events
2. Sees calendar or list view
3. Filters by category (e.g., Carnival)
4. Clicks event to see details
5. Views schedule, location, venue info
6. Marks [I'm Going] (if logged in)
7. Sees related events
```

---

## Analytics & Tracking

**Google Analytics 4 Events**:
```
page_view: Every page load
scroll: User scrolls 50%, 75%, 100% of page
engagement_time: Time on page
view_search_results: Search performed
select_content: Article/event clicked
share: Content shared
like_post: Article liked
save_post: Article saved
```

**Custom Events**:
```
comment_posted
obituary_viewed
event_attended_marked
radio_played
subscription_initiated
subscription_completed
```

---

## Design System & Components

### Colors

```
Primary: #10b981 (emerald)
Secondary: #3b82f6 (blue)
Accent: #f59e0b (amber, for warnings)
Error: #ef4444 (red)
Success: #10b981 (green)
Muted: #6b7280 (gray)
Dark: #111827 (nearly black)
Light: #f3f4f6 (light gray)
```

### Typography

```
Font: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif

Sizes:
  h1: 2.5rem (40px), bold
  h2: 2rem (32px), bold
  h3: 1.5rem (24px), bold
  Body: 1.125rem (18px), normal
  Small: 0.875rem (14px), normal
```

### Buttons

```
Primary: emerald background, white text, rounded corners
Secondary: gray background, dark text
Ghost: transparent, colored text, border
Disabled: gray background, muted text, cursor: not-allowed
Size: sm (8px), md (12px), lg (16px)
```

---

## See Also

- **CLI Guide**: `grenadianbuzz-cli-guide.md` (command-line administration)
- **Dashboard Guide**: `grenadianbuzz-dashboard-guide.md` (admin/creator tools)
- **API Patterns**: `grenadianbuzz-api-patterns.md` (REST endpoints, versioning)
- **Domain Checklist**: `grenadianbuzz-domain-checklist.md` (design validation)
