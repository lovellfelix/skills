---
name: incident-review
description: Incident review and postmortem analysis with timeline, impact, root cause, and follow-ups.
version: 0.1.0
portable: true
tags: [incident, postmortem, root-cause-analysis, follow-up, retrospective]
---

# Incident Review Skill

## What I Do

* Extract and document incident timeline with key events and timestamps
* Analyze impact metrics (users affected, duration, data loss, service degradation)
* Identify root causes through systematic investigation
* Generate action items and follow-up tasks with ownership
* Create structured postmortem summaries with lessons learned

## When to Use Me

* After a production incident or service outage
* During postmortem meetings to structure analysis
* When documenting incident details for knowledge base
* To ensure follow-ups don't fall through the cracks
* When creating incident reports for stakeholders

## How I Work

### 1. Timeline Construction

I help organize incident events chronologically:

```
Start: 2024-03-20 14:32 UTC - Database connection spike detected
2024-03-20 14:35 UTC - Alerts fired, on-call page triggered
2024-03-20 14:37 UTC - Services begin returning 503s
2024-03-20 14:45 UTC - Root cause hypothesis (connection pool exhaustion)
2024-03-20 15:02 UTC - Mitigation deployed, traffic recovered
2024-03-20 15:15 UTC - All services nominal, incident closed
```

### 2. Impact Assessment

I capture and quantify the incident's scope:

* **User Impact**: How many users were affected, what was their experience
* **Service Downtime**: Duration and which services/regions
* **Data Impact**: Any data loss, corruption, or inconsistency
* **Revenue Impact**: Estimated business cost (optional)
* **Dependencies**: What external systems or customers were impacted

### 3. Root Cause Analysis

Structured investigation to identify why the incident happened:

* Immediate cause: The direct technical trigger
* Contributing factors: System design, monitoring gaps, process issues
* Root cause: The underlying condition that made the incident possible
* Why-why analysis: Asking "why" repeatedly to uncover deeper issues

### 4. Action Items & Follow-Ups

I help generate SMART follow-up tasks:

* **Preventive**: Stop this class of incident from happening again
* **Detective**: Improve monitoring/alerting for early detection
* **Responsive**: Reduce time to mitigate similar incidents
* **Process**: Documentation, runbook, on-call guide updates

Each action should have:
- Clear description and acceptance criteria
- Owner (who is responsible)
- Priority and deadline
- Link to incident for traceability

### 5. Lessons Learned

I capture knowledge for future reference:

* What worked well in the response
* What could be improved
* How to reduce detection/resolution time
* Training or process changes needed

## Usage Examples

### Incident Timeline Meeting

```
Skill: incident-review
Input: List of events with timestamps, chat transcripts, log snippets
Output: Structured timeline with context and decisions
```

### Impact Calculation

```
Skill: incident-review
Input: Number of affected users, service downtime minutes, error logs
Output: Impact summary with business metrics
```

### Root Cause Documentation

```
Skill: incident-review
Input: What happened, system behavior, logs and metrics
Output: Structured root cause analysis with why-why chain
```

### Postmortem Generation

```
Skill: incident-review
Input: Timeline, root cause, impact, response events
Output: Complete postmortem document with action items
```

## Best Practices

* Conduct postmortem within 24-48 hours while memory is fresh
* Avoid blame; focus on systems and processes, not individuals
* Document findings immediately; don't rely on memory
* Ensure follow-ups are tracked and actioned by actual teams
* Review previous incident reports to identify patterns
* Use postmortems as learning, not compliance exercises

## Practical Examples

### Quick Timeline Recovery
You have chat transcripts and three log files from a database outage:
```
Input: "We got paged at 2:15pm, started looking at logs, 
noticed connection errors at 2:17pm, restarted service at 2:35pm"
Output: Structured timeline with key decision points and response metrics
```

### Impact for Stakeholders
Your incident affected payment processing for 90 minutes:
```
Input: Number of transactions blocked, revenue impact estimate, 
affected customer count, SLA breach details
Output: Executive summary with business metrics and customer comms
```

### Root Cause Deep Dive
You suspect connection pool exhaustion but want the full chain:
```
Input: System behavior, metrics showing connection count over time,
config changes from the week before
Output: Multi-layer root cause with contributing factors and prevention steps
```

### Postmortem Follow-up Tracking
You held the meeting; now you need to actionize findings:
```
Input: Timeline, root cause, and lessons from team discussion
Output: Numbered action items with owners, priority, and deadline
```

## Troubleshooting

**"I have too many events—where do I start?"**
Focus on decisions that changed the incident trajectory: page alert, mitigation attempt, recovery. Less important: every log line or Slack message.

**"Root cause keeps changing as I dig deeper"**
That's normal. Use the why-why framework: keep asking "why" until you reach a systemic issue, not just the technical trigger. Record contributing factors separately.

**"Teams aren't actually doing the follow-ups"**
Assign owners explicitly, link to the postmortem, set deadlines. Review quarterly to spot recurring issues. Make follow-ups part of sprint planning, not a to-do list.

**"This feels blame-y; my team is defensive"**
Remove names. Focus on "the request burst" not "John's code". Emphasize "we were missing monitoring" not "we didn't check".
Frame as team learning: "What can we improve together?"

## Common Sections in Output

* **Incident Summary**: One-paragraph overview
* **Timeline**: Chronological event log
* **Impact**: User, service, and business metrics
* **Root Cause**: Why the incident happened
* **Contributing Factors**: System design or process gaps
* **Resolution**: What stopped the incident
* **Action Items**: Numbered follow-ups with owners
* **Lessons Learned**: Key insights
