# GrenadianBuzz Skill: Complete Surface Guides

**Comprehensive reference for all GrenadianBuzz surfaces: API, CLI, Dashboard, and Website**

This skill provides deep, production-grounded guides for every major surface of the GrenadianBuzz platform.

---

## Quick Navigation

### Start Here Based on Your Task

**Need a quick cheat sheet for CLI commands?**
→ See **CLI Quick Reference** (`quick-ref/CLI-QUICK-REFERENCE.md`) — 1-page command cheat sheet

**Need to navigate the dashboard quickly?**
→ See **Dashboard Quick Reference** (`quick-ref/DASHBOARD-QUICK-REFERENCE.md`) — 1-page task guide

**Need to understand website navigation?**
→ See **Website Quick Reference** (`quick-ref/WEBSITE-QUICK-REFERENCE.md`) — 1-page user flow guide

---

**Designing a new API or endpoint?**
→ See **API Patterns** (`reference/grenadianbuzz-api-patterns.md`)

**Building CLI tools or scripts?** (Deep dive)
→ See **CLI Guide** (`reference/grenadianbuzz-cli-guide.md`)

**Working on admin/creator dashboards?** (Deep dive)
→ See **Dashboard Guide** (`reference/grenadianbuzz-dashboard-guide.md`)

**Building public website pages?** (Deep dive)
→ See **Website Guide** (`reference/grenadianbuzz-website-guide.md`)

**Validating design against domain patterns?**
→ See **Domain Checklist** (`reference/grenadianbuzz-domain-checklist.md`)

---

## Complete Guide Map

### Quick References (One-Page Cheat Sheets)

**Fastest way to find what you need — perfect for busy admins and developers**

| Reference | Coverage | Best For |
|-----------|----------|----------|
| **CLI Quick Ref** | 150 lines, 40+ common commands | Admin scripts, bulk ops, quick lookup |
| **Dashboard Quick Ref** | 200 lines, all major sections | Content mgmt, moderation, analytics tasks |
| **Website Quick Ref** | 250 lines, navigation & user flows | Navigation, engagement, mobile behavior |

### Reference Guides (Production-Grounded)

**Comprehensive guides with real examples and patterns — for deep design work**

| Guide | Coverage | Best For |
|-------|----------|----------|
| **API Patterns** | 823 lines, 39+ services, FeathersJS | Endpoint design, versioning, error handling, real examples |
| **CLI Guide** | 700+ lines, 70+ commands | Admin workflows, bulk operations, automation, scripts |
| **Dashboard Guide** | 900+ lines, React/TailwindCSS | Content mgmt, moderation, analytics, creator tools |
| **Website Guide** | 1000+ lines, Next.js/React | Public pages, SEO, mobile UX, engagement patterns |
| **Domain Checklist** | 150+ lines, validation rules | Design review, domain-specific patterns, safety checks |

### Templates (Reusable for Any Project)

| Template | Lines | Reusable |
|----------|-------|----------|
| **Quick Reference** | 487 | Checklist, endpoint templates, error examples |
| **API PRD Template** | 350+ | 14-section comprehensive PRD structure |
| **Newsletter Pack** | 6,500+ | Diaspora-focused email templates (4 templates) |

---

## Surface Overview

### 1. **API** (REST Backend)

**Coverage**: Versioning, response formats, pagination, engagement endpoints, moderation workflows, authentication, analytics aggregation

**Key Files**:
- `reference/grenadianbuzz-api-patterns.md` (823 lines)
- `templates/api-prd-template.md` (350+ lines)
- `templates/quick-reference.md` (487 lines)

**Use When**:
- Designing new endpoints
- Planning API deprecation
- Implementing error handling
- Building integrations

**Real Examples Included**:
- Create + publish article workflow
- Engagement interactions (likes, comments, saves)
- Moderation queue processing
- Feed personalization

---

### 2. **CLI** (Command-Line Tools)

**Coverage**: 70+ commands, command patterns, safe operations, bulk actions, analytics export, configuration management, scripting

**Key File**:
- `reference/grenadianbuzz-cli-guide.md` (700+ lines)

**Use When**:
- Building admin scripts
- Automating content workflows
- Setting up bulk operations
- Designing monitoring tools

**Command Categories**:
- Content management (articles, obituaries, events, radio)
- User & moderation (flags, approvals, escalations)
- Analytics & reporting (exports, metrics, trends)
- Configuration (auth, profiles, secrets)

**Example Workflows**:
- Daily editorial workflow (check queue, approve, publish, report)
- Bulk content migration (export, validate, import)
- Moderation escalation with decision logic

---

### 3. **Dashboard** (Admin/Creator Tools)

**Coverage**: 5+ dashboards, RBAC, content management, moderation, analytics, real-time updates, mobile-responsive

**Key File**:
- `reference/grenadianbuzz-dashboard-guide.md` (900+ lines)

**Dashboards Covered**:
- Content management (articles, obituaries, events, radio)
- Moderation queue and audit log
- Analytics overview, engagement, content performance
- Creator personal dashboard with stats

**Use When**:
- Designing content management interfaces
- Building moderation workflows
- Creating analytics dashboards
- Implementing real-time features

**UI Patterns**:
- Data grids with filtering and sorting
- Bulk actions on multiple items
- Draft recovery and version history
- Real-time WebSocket updates
- Mobile-friendly responsive design

---

### 4. **Website** (Public Facing)

**Coverage**: 10+ page types, information architecture, responsive design, SEO, accessibility, engagement patterns

**Key File**:
- `reference/grenadianbuzz-website-guide.md` (1000+ lines)

**Pages Covered**:
- Homepage (hero, featured content, previews)
- Article list & detail (with comments)
- Obituaries (search, cards, detail with condolences)
- Events (calendar, list, detail)
- Radio (station list, player, detail)
- Search & discovery
- User accounts (login, profile, saved items)

**Use When**:
- Building public website components
- Designing information architecture
- Implementing SEO
- Planning mobile experience

**Design Patterns**:
- Responsive grid layouts
- Real-time engagement (likes, comments, saves)
- Infinite scroll vs. pagination
- Personalization for logged-in users
- Accessibility (WCAG 2.1 AA)

---

### 5. **Newsletters** (Email Engagement)

**Coverage**: 4 production-ready templates for diaspora-focused emails: weekly digest, breaking news, events & culture, community spotlight

**Key Files**:
- `templates/newsletter/README.md` (navigation & strategy)
- `templates/newsletter/weekly-roundup.md` (1,465 words)
- `templates/newsletter/breaking-news-alert.md` (300-400 words)
- `templates/newsletter/events-culture-digest.md` (2,500+ words)
- `templates/newsletter/community-spotlight.md` (1,800+ words)

**Templates Covered**:
- **Weekly Roundup**: Digest-style (stories + culture + events), Sunday mornings, 5-7 min read
- **Breaking News Alert**: Real-time urgent notifications (hurricanes, political events, emergencies), 2-3 min read
- **Events & Culture Digest**: Festival celebrations + diaspora gatherings, bi-weekly, 8-10 min read
- **Community Spotlight**: Diaspora changemakers + grassroots initiatives, bi-weekly, 6-8 min read

**Use When**:
- Engaging diaspora audiences via email
- Planning newsletter strategy
- Needing templates for cultural/community engagement
- Building engagement across time zones (USA, Canada, UK, Caribbean)

**Design Patterns**:
- Warm, personal tone (like talking to family)
- Diaspora-aware content (always include home connection)
- Timezone support (multiple event times listed)
- Subscription tier personalization (free, premium, family)
- Actionable CTAs (3-5 per issue, focused)
- Mobile-first responsive design
- Clear unsubscribe & preference management

**Personalization Options**:
- Geographic segments (USA, Canada, UK, Caribbean)
- Subscription tiers (free, premium, family)
- Topic preferences (news, culture, events, community)

---

## Domain Context

All guides are grounded in real GrenadianBuzz architecture:

**Content Model**:
- Articles & news (from feeds, sources, submissions)
- Obituary listings (searchable, biographical metadata)
- Cultural events (Carnival, religious observances, national holidays)
- Radio stations (streaming, geolocation, metadata)
- User-generated content (comments, reactions, subscriptions)

**Engagement Types**:
- Reactions: 👍 like, ❤️ love, 🕯️ remember, 💖 compassion, 🌹 tribute, 🙏 respect
- Comments with nested replies
- Saves/bookmarks
- Shares

**Audience**:
- 90,000+ diaspora readers
- USA (45%), Canada (20%), UK (15%), Caribbean (8%), other (12%)
- Subscription tiers: Free, Premium ($4.99/mo), Family ($9.99/mo)

**Moderation**:
- 5-status lifecycle: pending → review → approved/removed
- Auto-flagging for keywords, spam patterns
- Audit trails for all actions
- 24-hour SLA on reviews

**Authentication**:
- JWT (1-day expiry)
- OAuth (Google, Facebook)
- API keys
- Email/password (local)

---

## How to Use These Guides

### For Design Review

1. Read relevant guide(s) based on surface (CLI, Dashboard, Website, API)
2. Cross-check against **Domain Checklist**
3. Validate against **Design Patterns** sections
4. Use examples as reference implementations

### For Building New Features

1. **Start**: Quick-reference checklist
2. **Design**: Use appropriate template (PRD, CLI command structure, etc.)
3. **Validate**: Domain checklist and patterns
4. **Reference**: Real examples in guides
5. **Implement**: Following established patterns

### For Creating Standards

1. Review patterns across all surfaces for consistency
2. Extract common behaviors (e.g., pagination, error handling, moderation)
3. Document team-specific variations
4. Reference these guides as baseline

---

## File Structure

```
skills/portable/grenadianbuzz/
├── SKILL.md                              # Main skill entry point
├── INDEX.md                              # This file — start here
│
├── quick-ref/                            # ⭐ One-page quick references (NEW)
│   ├── CLI-QUICK-REFERENCE.md            # 150 lines: 40+ common commands cheat sheet
│   ├── DASHBOARD-QUICK-REFERENCE.md      # 200 lines: All sections & common tasks
│   └── WEBSITE-QUICK-REFERENCE.md        # 250 lines: Navigation, flows, features
│
├── reference/                            # Deep reference guides
│   ├── grenadianbuzz-api-patterns.md     # 823 lines: API versioning, responses, real examples
│   ├── grenadianbuzz-cli-guide.md        # 700+ lines: 70+ commands, workflows, scripts
│   ├── grenadianbuzz-dashboard-guide.md  # 900+ lines: Content, moderation, analytics dashboards
│   ├── grenadianbuzz-website-guide.md    # 1000+ lines: Pages, SEO, responsive design, engagement
│   └── grenadianbuzz-domain-checklist.md # 150+ lines: Validation rules, patterns, safety
│
└── templates/                            # Reusable templates
    ├── quick-reference.md                # 487 lines: Fast checklist and endpoint templates
    ├── api-prd-template.md               # 350+ lines: 14-section PRD structure
    │
    └── newsletter/                       # 📧 Newsletter template pack (NEW)
        ├── README.md                     # Navigation & content strategy
        ├── weekly-roundup.md             # 1,465 words: Digest-style weekly newsletter
        ├── breaking-news-alert.md        # 300-400 words: Real-time urgent alerts
        ├── events-culture-digest.md      # 2,500+ words: Festival & cultural celebrations
        └── community-spotlight.md        # 1,800+ words: Diaspora changemakers & initiatives
```

**Total**: ~12,400+ lines of production-grounded guides, quick references, and newsletter templates across all surfaces

---

## Key Patterns Across All Surfaces

### Authentication & Authorization

**API**: JWT tokens, OAuth, API keys, scopes
**CLI**: Token-based, config profiles, secret storage
**Dashboard**: Session tokens, RBAC (admin, moderator, editor, creator)
**Website**: JWT/OAuth, user accounts with preferences

### Error Handling

**API**: Structured error schema, HTTP status codes, rate limit headers
**CLI**: Exit codes (0=success, 1=error, etc.), verbose output
**Dashboard**: Toast notifications, inline error messages, retry options
**Website**: User-friendly messages, graceful degradation

### Pagination & Cursors

**API**: Cursor-based for stability across updates
**CLI**: Limit/cursor options, bulk operations
**Dashboard**: Pagination for tables, infinite scroll for queues
**Website**: Pagination or infinite scroll based on use case

### Real-Time Updates

**API**: WebSocket subscriptions, polling fallbacks
**CLI**: Not applicable (batch operations)
**Dashboard**: WebSocket for metrics, comment threads, moderation queue
**Website**: WebSocket for live comment counts, engagement, radio listeners

### Moderation & Safety

**API**: Separate /moderation endpoints, audit trails, status tracking
**CLI**: Flag, approve, remove, escalate commands
**Dashboard**: Queue view, bulk actions, audit log
**Website**: Flagged content hidden, appeals process, no mod UI

---

## Validation Checklist

When using these guides, verify:

- ✅ Pattern applies to your GrenadianBuzz context
- ✅ Implementation follows structure (not just examples)
- ✅ Error handling matches API schema
- ✅ UI matches domain defaults (colors, typography, spacing)
- ✅ Moderation is first-class, not an afterthought
- ✅ Mobile responsiveness considered
- ✅ Accessibility (WCAG 2.1 AA) addressed
- ✅ No hardcoded secrets or internal paths

---

## Common Questions

**Q: Which guide should I start with?**
A: Depends on your task. See "Start Here" section above.

**Q: Can I use these templates for other projects?**
A: Yes! Templates in `templates/` are fully reusable. Reference guides have GrenadianBuzz-specific patterns but principles apply broadly.

**Q: How often are these guides updated?**
A: Updated when GrenadianBuzz architecture changes. Check UPDATE_SUMMARY.md for latest changes.

**Q: What if I need something not covered?**
A: Check the domain checklist for validation patterns. If still missing, file a feature request with your use case.

**Q: Are these guides only for GrenadianBuzz?**
A: Mostly. API, CLI, and website patterns are broadly applicable. Dashboard guide is specific to GrenadianBuzz admin tool.

---

## External References

**Project Documentation** (verified sources):
- `~/projects/grenadianbuzz/docs/PROJECT_OVERVIEW.md` - Platform overview
- `~/projects/grenadianbuzz/docs/prd/PROJECT_PRD.md` - Master PRD and roadmap
- `~/projects/grenadianbuzz/docs/API_ENDPOINT_REVIEW.md` - Endpoint inventory
- `~/projects/grenadianbuzz/docs/architecture/DATA_MODELS.md` - Data schemas
- `~/projects/grenadianbuzz/cli/` - CLI source code
- `~/projects/grenadianbuzz/web/dashboard.grenadianbuzz.com/` - Dashboard source
- `~/projects/grenadianbuzz/web/grenadianbuzz.com/` - Website source

---

## Summary

This expanded GrenadianBuzz skill now covers **all major surfaces** with:
- ✅ **Quick references** (1-page cheat sheets for CLI, Dashboard, Website)
- ✅ **Deep reference guides** (production-grounded, 4,500+ lines)
- ✅ **Reusable templates** (PRD, quick-ref checklist, newsletter pack)
- ✅ **Domain checklist** (design validation)
- ✅ **Newsletter template pack** — NEW! (4 templates for diaspora engagement)

| Surface | Quick Ref | Deep Guide | Templates | Status |
|---------|-----------|-----------|---|--------|
| CLI | ✅ | 700+ lines | — | Complete |
| Dashboard | ✅ | 900+ lines | — | Complete |
| Website | ✅ | 1000+ lines | — | Complete |
| API | — | 823 lines | API PRD | Complete |
| Domain | — | 150+ lines | — | Validation rules |
| Newsletter | — | — | 6,500+ words (4 templates) | ✨ NEW |
| **TOTAL** | **600 lines** | **5,300 lines** | **7,500+ words** | **Complete** |

All guides maintain:
- ✅ Portability (templates & patterns work for other projects and diaspora communities)
- ✅ Safety (no secrets or internal details)
- ✅ Consistency (shared patterns, cross-references)
- ✅ Practicality (real examples, workflows)
- ✅ Scannability (quick refs + deep dives available)

---

## See Also

- **SKILL.md**: Main skill entry point with workflow and examples
- **UPDATE_SUMMARY.md**: Recent changes and additions
- **Domain Checklist**: Design validation and rules
