---
name: communication-style
description: Rewrite communication for clarity, tone, and audience across Slack, email, docs, and more.
version: 0.1.0
portable: true
tags: [communication, writing, clarity, tone, style, docs]
---

# Communication Style Skill

## What I Do

* Rewrite messages for clarity and conciseness
* Adapt tone to audience (technical, executive, end-user, friendly, formal)
* Improve email subject lines and structure for readability
* Refine documentation for different skill levels
* Suggest rhetorical improvements while preserving intent

## When to Use Me

* Writing Slack messages that feel unclear or verbose
* Crafting emails for different audiences
* Refining documentation or blog posts
* Adjusting tone for escalations or sensitive topics
* Making technical content accessible to non-technical readers
* Ensuring consistency in team communication style

## How I Work

### 1. Clarity Improvements

I identify and fix common clarity issues:

* **Jargon elimination**: Replace specialized terms with simple language (or explain them)
* **Sentence structure**: Break up long, complex sentences
* **Passive → Active**: Prefer active voice ("we fixed" vs "the issue was fixed")
* **Wordiness**: Remove redundancy and filler
* **Specificity**: Replace vague terms with concrete details

Example:
```
Before: "It seems like there might be some performance issues that could 
potentially affect the user experience in certain scenarios."

After: "Users may experience 10-30 second delays when uploading large files."
```

### 2. Audience & Tone Adaptation

I adjust communication for different contexts:

* **Technical Audience**: Precise terminology, implementation details
* **Executive/Business**: Impact metrics, risk, ROI focus
* **End-Users**: Benefits, not mechanics; friendly, supportive
* **Peer Team**: Casual, collaborative, assumes context
* **Public/Marketing**: Aspirational, benefit-focused, polished

Example (same news, different audiences):
```
Technical: "Upgraded database connection pooling from pgbouncer v1.15 to v1.16 
to resolve connection timeout errors under load."

Executive: "Fixed infrastructure issue causing service timeouts, reducing 
customer complaints by 40%."

End-User: "We've made the app faster and more reliable. You may notice fewer 
loading delays."
```

### 3. Email Structure Optimization

I help organize emails for readability:

```
Subject: [ACTION] Need approval for Q2 infrastructure upgrade by Friday

Body structure:
1. What you need: "Approval needed for Q2 infrastructure upgrade"
2. Why it matters: "Increases reliability during peak load"
3. Key detail: "Requires 2-hour maintenance window"
4. Timeline: "Decision needed by Friday for Monday deployment"
5. Next step: "Reply with yes/no and contact <person> with questions"

TL;DR: Can go at top or bottom depending on audience
```

### 4. Documentation Refinement

I help tailor docs for different readers:

* **Beginner**: Step-by-step, lots of examples, minimal jargon
* **Experienced**: Direct, advanced options, reference material
* **API Docs**: Clear signatures, usage examples, common errors
* **Troubleshooting**: Problem → Solution flow, diagnostic steps

Example structure for different levels:
```
Getting Started (beginners)
- What is this?
- Quick example
- Common questions

Usage (intermediate)
- Detailed reference
- Configuration options
- Examples

Advanced (experts)
- Performance tuning
- Internal architecture
- Edge cases
```

### 5. Tone & Sentiment Control

I help calibrate emotional tone:

* **Formal/Professional**: "We regret to inform you..."
* **Friendly/Casual**: "Whoops! We totally messed that up..."
* **Urgent/Critical**: "Action required immediately"
* **Celebratory**: "We're thrilled to announce..."
* **Empathetic**: "We understand this is frustrating..."

## Usage Examples

### Clarify a Slack Message

```
Skill: communication-style
Input: "yo can anyone help w/ the thingy that's not working"
Output: "Can someone help debug why the authentication service keeps timing out?"
```

### Adapt Email for Executive

```
Skill: communication-style
Input: Technical incident report
Output: Executive summary focusing on business impact and resolution
```

### Simplify API Documentation

```
Skill: communication-style
Input: Technical API spec with complex parameter descriptions
Output: Beginner-friendly guide with usage examples
```

### Refine Announcement

```
Skill: communication-style
Input: Draft feature announcement
Output: Polished announcement emphasizing user benefits
```

## Best Practices

* **Know your audience**: Tailor depth and terminology accordingly
* **Be specific**: Replace vague terms with concrete details and examples
* **Use active voice**: "We improved" not "Improvements were made"
* **Lead with action**: Tell people what to do first, then explain why
* **One idea per paragraph**: Easier to follow
* **Use examples**: Show, don't just tell
* **Front-load urgency**: If it's urgent, say so in the first line
* **Provide context**: Don't assume everyone knows the background
* **Test readability**: Read aloud, or check Flesch Reading Ease score

## Practical Examples

### Debug a Confusing Slack Message
Your message is getting replies asking for clarification:
```
Input: "yo can anyone help w/ the thingy that's not working"
Output: "Can someone help debug why the authentication service 
         keeps timing out on password reset?"
```

### Rewrite Incident Update for Three Audiences
Same incident, three versions:
```
Input: Database replication lag caused 15-minute delay in reports
Customers: "Reports are running 15 minutes slower. We're investigating 
           and will update you in 30 minutes."
Technical: "Replication lag between primary/replica exceeds 5 min. 
           Temporarily increasing query timeout and monitoring catchup."
Executives: "Operational issue resolved in 20 minutes. No revenue impact. 
            Improving monitoring."
```

### Simplify Dense API Documentation
Your endpoint doc has 5 nested parameter descriptions:
```
Input: Parameter names like "offset_timestamp_unix_ms_utc", 
       "include_deleted_soft_entries"
Output: Clear names, one-line summaries, usage example, common mistakes
```

### Craft Bad-News Email
You need to tell a client their request is delayed:
```
Input: "request is deprioritized"
Output: "We're focusing on critical fixes first. 
         Your request is scheduled for March 15. 
         Contact us if that timing doesn't work."
```

## Troubleshooting

**"I rewrote it shorter, but it lost important detail"**
Add a layered structure: headline, summary (1 paragraph), details (for those
who need them). Let people drill down instead of front-loading everything.

**"My tone sounds corporate/sterile; I wanted friendly"**
Use contractions, shorter sentences, and specific examples. 
Replace "assistance" with "help". Imagine explaining to a colleague over coffee.

**"Different audiences have conflicting needs"**
Use a brief executive summary at the top, detailed explanation below.
Or send two versions. The key is making it easy for each reader to find their info.

**"I sound too casual now; how do I know the right tone?"**
Look at existing communication from your team/company. Match that baseline.
When uncertain, slightly formal beats too casual in writing (easier to relax tone
in follow-ups if needed).

## Tone Spectrum

```
Casual ----------- Professional ----------- Formal
  😄                    👔                      🎩
"hey there"      "thanks for your help"   "we appreciate your assistance"
Friendly         Neutral                  Corporate
```

## Common Scenarios

### Incident Communication

```
Avoid: "There is a potential issue affecting systems"
Better: "We're investigating why some users can't log in. We'll update you 
in 15 minutes."
```

### Escalation/Bad News

```
Avoid: "You didn't follow the process"
Better: "Let's discuss the process to prevent this next time"
```

### Feature Announcement

```
Avoid: "We implemented a new API endpoint"
Better: "You can now bulk export 10,000 records at once, saving hours of manual work"
```

### Rejection/Deferral

```
Avoid: "We're not doing that"
Better: "Great idea. We're focusing on X first, but this is on our radar for Q3"
```

## Formatting Tips

* **Subject lines**: Specific, benefit-focused or action-oriented
* **Lists**: Parallelstructure, consistent formatting
* **Bold/italics**: Use sparingly; emphasize key points only
* **Paragraphs**: 3-4 sentences max; break up long content
* **Code snippets**: Include in technical communication
* **Links**: Provide context before the link; don't use "click here"

## Checklist for Refined Communication

- [ ] Clear, specific language (no jargon or explain it)
- [ ] Active voice where possible
- [ ] Audience appropriate (depth, tone, terminology)
- [ ] Actionable (people know what to do next)
- [ ] Scannable (headers, lists, white space)
- [ ] Concise (removed filler and redundancy)
- [ ] Empathetic (considers reader's perspective)
- [ ] Correct (no typos, accurate information)
