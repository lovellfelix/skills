---
name: rfc
description: Draft and refine technical RFCs and design proposals.
version: 0.1.0
portable: true
tags: [rfc, design, proposal, architecture, technical-decision]
---

# RFC Skill

## What I Do

* Structure RFC (Request for Comments) documents with standard sections
* Refine design proposals for clarity and completeness
* Identify open questions and technical trade-offs
* Generate alternatives and pros/cons analysis
* Review RFCs for feasibility and alignment with goals

## When to Use Me

* When proposing a major technical change or feature
* To structure architectural decisions
* Before diving into implementation
* When seeking feedback on a design approach
* To document and track technical decisions over time

## How I Work

### 1. RFC Structure & Sections

I help organize RFCs with standard sections:

```
# RFC: [Title]

## Summary
Brief overview of the proposal (2-3 sentences)

## Problem Statement
Why this RFC is needed

## Proposed Solution
High-level approach

## Detailed Design
Technical specifics, APIs, algorithms, data structures

## Alternatives
Other approaches considered and why they were rejected

## Drawbacks & Trade-offs
What we're giving up or accepting with this approach

## Rationale & Benefits
Why this is the right choice

## Open Questions
Issues to resolve during implementation or review

## Implementation Plan
Steps to build this

## Rollout & Migration
How to deploy without breaking users

## Testing Strategy
How to validate the design works as intended
```

### 2. Problem Articulation

I help clarify what problem is being solved:

* **Current state**: How things work now
* **Limitation**: What's broken or insufficient
* **Desired outcome**: What success looks like
* **Impact**: Why this matters
* **Urgency**: Timeline and constraints

Example:
```
Current: Single-threaded request handler limits throughput to 100 req/s
Limitation: Peak traffic during events causes timeouts
Desired: Handle 10,000 req/s with <100ms latency
Impact: Revenue loss during high-traffic periods
Urgency: Event season is 3 months away
```

### 3. Design Articulation

I help explain the proposed solution:

* **High-level approach**: Conceptual overview
* **Architecture**: Components and interactions
* **API/Interface**: How users/systems interact with it
* **Data model**: Schema, storage, consistency
* **Performance characteristics**: Speed, memory, scalability
* **Failure modes**: What can go wrong

### 4. Trade-offs & Alternatives

I help surface design decisions:

```
## Alternative 1: Queue-based Processing
Pros: Decouples producer/consumer, easy to scale
Cons: Eventual consistency, higher latency, operational overhead

## Alternative 2: Stream Processing
Pros: Real-time, natural for event data
Cons: Complex state management, harder to debug

## Selected: Alternative 1 (Queue-based)
Reasoning: Simplicity wins; eventual consistency acceptable for this use case
```

### 5. Implementation Guidance

I help translate design into concrete steps:

* Phase 1: Core infrastructure (weeks 1-2)
* Phase 2: Feature implementation (weeks 3-4)
* Phase 3: Integration and testing (weeks 5-6)
* Phase 4: Gradual rollout with monitoring (weeks 7+)

## Usage Examples

### Structure a New RFC

```
Skill: rfc
Input: Problem description and rough ideas
Output: RFC template with key sections filled in
```

### Review RFC for Completeness

```
Skill: rfc
Input: Draft RFC
Output: Gaps identified, missing sections, clarifying questions
```

### Generate Alternatives

```
Skill: rfc
Input: Proposed solution
Output: 2-3 alternative approaches with pros/cons
```

### Create Migration Plan

```
Skill: rfc
Input: Architectural change details
Output: Phased rollout plan with rollback strategy
```

## Best Practices

* **Solve one problem per RFC**: Keep scope focused
* **Seek feedback early**: Share drafts before implementation
* **Document trade-offs**: Be explicit about what you're choosing
* **Consider operations**: Include monitoring, alerting, debugging
* **Think about failure**: How does this degrade gracefully?
* **Plan migration**: How do we not break existing users/systems?
* **Quantify when possible**: Performance numbers, scale limits
* **Link to context**: Reference issues, past RFCs, related work

## Practical Examples

### Async Task Processing Design
You're moving from synchronous to queue-based job processing:
```
Input: Current 30-second timeout limit, peak load hitting it, 
       need for retries and monitoring
Output: RFC with queue design, failure modes, rollout plan, 
        success metrics (e.g., "support 10x load")
```

### Database Schema Migration
You need to denormalize a frequently-joined table:
```
Input: Current schema, query patterns, performance bottleneck evidence
Output: RFC with migration strategy, rollback plan, zero-downtime approach
```

### API Rate Limiting Policy
You're adding per-customer rate limits:
```
Input: Abuse patterns, tier definitions, fairness goals
Output: RFC with tier matrix, request-quota algorithm, grace periods
```

### Deprecation Timeline for Legacy Feature
You want to sunset an old auth method:
```
Input: Current usage metrics, migration effort for customers, timeline constraints
Output: RFC with announcement, deprecation schedule, migration tooling plan
```

## Troubleshooting

**"My RFC feels incomplete; I don't know all the answers"**
That's fine. Use "Open Questions" section explicitly. List what you don't know,
what needs prototyping, and what you'll decide during implementation.
Mark those as "Resolved during Phase 2" or similar.

**"How much detail is too much?"**
If implementation decisions belong in code, not RFC. RFC covers "what and why",
not "every function signature". Aim for 2-3 pages; anything longer should link
to detailed design docs.

**"No one's reading my RFCs"**
Make the summary compelling (2-3 sentences). Add a visual diagram if possible.
Share in team meeting; don't just post. Highlight decisions that affect others.

**"We skipped RFC and now regret the design"**
Totally recoverable. Write a retrospective RFC explaining what you learned.
Use it to refine the approach for v2. Make it a learning exercise, not blame.

## Common Sections

* **Summary**: Elevator pitch
* **Motivation**: Why now?
* **Detailed Design**: How does it work?
* **Alternatives**: What else was considered?
* **Drawbacks**: What are we accepting?
* **Rationale**: Why is this the best approach?
* **Implementation**: How do we build it?
* **Rollout**: How do we deploy it?
* **Testing**: How do we validate it?
* **Success Metrics**: How do we know it worked?

## RFC Lifecycle

1. **Draft**: Initial proposal, seeking feedback
2. **Review**: Community/team discussion and refinement
3. **Final Comment Period**: Last chance for concerns
4. **Decision**: Approved, rejected, or deferred
5. **Implemented**: Changes deployed
6. **Closed**: RFC complete or superseded by new RFC

## Writing Tips

* Use clear, concise language
* Include diagrams or examples where helpful
* Anticipate questions and address them upfront
* Be humble about uncertainty; acknowledge unknowns
* Make it easy to skim: use headers and lists
* Reference related RFCs or decisions
* Update RFC as implementation learns new things
