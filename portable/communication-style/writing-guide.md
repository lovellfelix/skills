# Writing Guide

Detailed reference for tone, structure, reasoning, and content rules across technical blogs, engineering explanations, RFCs, design documents, postmortems, incident summaries, implementation prompts, emails, and other professional communication.

`SKILL.md` is the compact operational checklist covering formatting mechanics, the em-dash rule, rewrite heuristics, and the minimum quality bar. This guide covers the reasoning behind those rules, format-specific structures, evidence and ownership, the use of metrics, and the revision workflow.

Rules already defined mechanically in `SKILL.md` are not repeated here unless additional context is necessary.

Do not introduce resume-style accomplishment framing, personal branding, recruiter language, or artificial seniority signals. This style excludes resume and job-search patterns by design.

---

## Objective

Produce writing that is:

- technically accurate
- clear on the first read
- logically organized
- direct but not abrupt
- professional but not stiff
- concise without removing necessary context
- specific without becoming cluttered
- natural without becoming overly casual
- confident without overstating certainty or ownership

The writing should help the reader understand the issue, decision, action, or lesson.

It should not try to make the author sound impressive.

---

## 1. Preserve the Truth

Do not change the underlying meaning while improving the writing.

Preserve:

- technical facts
- ownership
- uncertainty
- scope
- sequence
- constraints
- causality
- requested action
- measured results
- unresolved questions
- emphasis and relative importance

Preserve the author's emphasis. Do not promote a secondary detail into the main point or bury the concern, decision, or lesson the author considered most important.

Do not:

- convert a contribution into ownership
- convert an observation into a verified conclusion
- convert an estimate into an exact measurement
- add strategic importance that was not present
- exaggerate impact
- hide a meaningful limitation
- remove technical detail needed to understand the result

Use the strongest accurate statement, not the strongest possible statement.

### Example

Weak:

> I spearheaded a comprehensive modernization initiative that transformed platform reliability.

Preferred:

> I redesigned the service so instances could rebuild their state from existing artifacts instead of depending on node-local state.

The preferred version explains the actual work and lets the reader judge its importance.

---

## 2. Understand Before Writing

Before drafting, identify:

```text
COMMUNICATION TYPE:
INTENDED READER:
PRIMARY PURPOSE:
MAIN POINT OR REQUEST:
CURRENT STATE:
PROBLEM:
KNOWN FACTS:
OBSERVED BEHAVIOR:
CONFIRMED CAUSE:
CONTRIBUTING CONDITIONS:
CONSTRAINTS:
DECISION OR REQUIRED CHANGE:
RESULT:
UNCERTAINTIES:
DETAILS THAT MUST REMAIN:
INTERNAL TERMS THAT NEED TRANSLATION:
```

Use this as an internal planning step. Do not include the completed template in the final output unless explicitly requested.

Establish the purpose and relevant facts before drafting.

When important information is missing, do not invent it. Mark the uncertainty, omit unsupported claims, or identify the gap when it materially affects the conclusion. Continue drafting when the available information is sufficient to produce an accurate partial result.

---

## 3. Lead with the Reader's Need

Establish the purpose early.

The first paragraph or section should tell the reader what the communication is about.

### For an email

State the request or reason for writing.

### For an implementation prompt

State what must be implemented.

### For an RFC

State the problem and intended outcome.

### For an incident report

State the impact or observed failure.

### For a blog

State the concrete problem, constraint, observation, or result that makes the topic useful.

Avoid generic introductions such as:

- `In today's rapidly changing environment...`
- `As organizations continue to adopt...`
- `Modern engineering teams increasingly face...`
- `The world of AI is evolving quickly...`
- `It is no secret that...`

### Preferred

> Running several local coding models on a 16 GB Mac is less of a routing problem than it first appears. Memory pressure, loading time, and eviction behavior quickly become part of the architecture.

This establishes the topic without artificial drama.

---

## 4. Organize the Material Explicitly

Use structure to make the document easier to evaluate and act on.

Separate:

- context from findings
- findings from interpretation
- decisions from implementation
- required behavior from optional improvements
- root cause from contributing conditions
- completed work from remaining work
- facts from recommendations

Use descriptive headings when the document contains multiple distinct ideas.

Prefer headings such as:

- `Problem`
- `Current Behavior`
- `Findings`
- `Constraints`
- `Proposed Change`
- `Required Behavior`
- `Failure Path`
- `Validation`
- `Remaining Issue`
- `Open Questions`

Avoid decorative or vague headings such as:

- `The Journey`
- `Why This Matters`
- `A New Paradigm`
- `Unlocking the Future`
- `The Bigger Picture`

Do not over-section short writing.

A brief email or explanation may need no headings.

---

## 5. Explain Concrete Behavior

Prefer descriptions of what the system does over abstract labels.

Weak:

> The system had reliability and scalability problems.

Preferred:

> Each instance stored state locally and depended on an elected leader to reconstruct it after a restart. Replacing a node therefore required coordination with surviving state.

Weak:

> The classifier architecture created unnecessary complexity.

Preferred:

> The classifier forced every message into one category and then created a Gmail label for that category. Low-value messages therefore generated labels even when no filing action was useful.

Weak:

> The network configuration was incorrect.

Preferred:

> The additional VLANs had not been assigned to the 2.5 Gb port profile. Once they were added, the expected routes appeared.

Use words such as `reliability`, `resilience`, `architecture`, and `scalability` only after explaining the behavior they describe.

---

## 6. Preserve Causality

When describing technical behavior, connect the relevant events.

Use this model when applicable:

```text
Change or condition
→ immediate system behavior
→ propagation
→ observed impact
```

### Example

> The configuration change restarted the forwarding service. The restart cleared connection-tracking state, which reset established storage connections and caused NFS clients to hang.

Do not reduce this to:

> A configuration change caused a storage incident.

The shorter version is easier to read but removes the mechanism needed to understand the incident.

Include only supported causal steps.

Do not fill gaps with plausible but unverified explanations.

---

## 7. Separate Evidence from Interpretation

Use precise language for the status of a claim.

### Confirmed

- `The packet capture confirmed...`
- `Logs showed...`
- `Testing reproduced...`
- `The configuration contained...`

### Observed

- `We observed...`
- `The service began...`
- `Requests arrived without...`

### Likely or inferred

- `The evidence suggests...`
- `The likely failure point is...`
- `This appears to be...`

### Initial hypothesis

- `We initially suspected...`
- `The first theory was...`

### Unresolved

- `This has not yet been confirmed.`
- `The remaining question is...`
- `The change has not been tested under sustained load.`

Do not weaken verified facts with unnecessary hedging.

Do not strengthen tentative conclusions.

---

## 8. Represent Ownership Accurately

Use `I` when the author personally performed the action or is expressing a personal observation.

Use `we` when the work was collaborative.

Use the system, project, or team as the subject when that is clearer.

### Examples

> I initially expected inference speed to be the main constraint.

> We compared the packet captures from both sides of the router.

> The service now reconstructs state from the artifact registry during startup.

Do not remove first person simply to sound professional.

Do not repeatedly begin sentences with `I`.

Do not use `we` to make individual work sound collaborative or to obscure responsibility.

Do not use `I` to claim team results.

---

## 9. Use the Right Amount of Detail

Include detail when it helps the reader understand:

- why the issue occurred
- why a decision was made
- how the system behaves
- how the change should be implemented
- how the result was validated
- why an alternative was rejected
- what remains unresolved

Remove detail that only:

- repeats the same point
- lists internal process without affecting the decision
- displays technical vocabulary
- provides history unrelated to the conclusion
- makes the document longer without making it clearer

Concise does not mean stripped of context.

Detailed does not mean exhaustive.

---

## 10. Keep Useful Technical Language

Retain precise terms when they carry necessary meaning.

Examples:

- leader election
- connection tracking
- cold start
- convergence
- rollout gate
- artifact registry
- liveness probe
- MTU
- MSS
- authorization header
- dependency ordering
- systemd unit
- deployment hook

Explain a specialized term when the intended reader may not recognize it.

Translate internal project names, team terminology, and acronyms unless they are central to the article.

### Example

Internal:

> Ring 2 UCM convergence fell below the moratorium threshold.

External:

> Convergence on the fleet-wide configuration platform fell below the deployment-safety threshold.

Do not replace a precise technical term with vague business language.

---

## 11. Use Metrics Only When Supported

Metrics are useful evidence, not mandatory decoration.

Use them when they clarify:

- scale
- frequency
- reliability
- recovery time
- impact
- cost
- performance
- adoption
- reduction in recurring work

### Supported metric

> Repeat support demand fell by 90%, based on tracked tickets, Slack interactions, and office-hours visits.

### Supported scale

> The platform delivered configuration across more than 500,000 hosts.

### Valid non-numeric result

> The change removed the manual state-recovery step.

Do not invent a number because it would make the writing appear more credible.

Do not convert an informal observation into a measured result.

Add the measurement method when it matters to the credibility of the claim.

---

## 12. Use Tradeoffs Only When Real

Explain tradeoffs when competing constraints materially influenced the decision.

### Example

> Removing leader election simplified replacement and recovery, but it increased the importance of artifact availability and startup validation.

Do not add a tradeoff section to a straightforward correction.

A missing VLAN assignment does not require strategic analysis.

A decision between coordinated state and artifact-derived recovery does.

Do not create weak alternatives merely to make the final design look stronger.

---

## 13. Sentence and Paragraph Style

Use complete sentences with natural variation.

Favor short-to-medium sentences, but preserve longer sentences when they clearly express a causal relationship.

Keep the rhythm controlled rather than theatrical. Do not isolate a short sentence or fragment solely to manufacture emphasis. State conclusions and recommendations in complete sentences that fit naturally with the surrounding prose. Use word choice, sentence order, and paragraph placement to create emphasis.

Avoid:

- uniformly clipped prose
- repeated sentence structures
- excessive semicolons
- unnecessary parentheses
- em dashes (see `SKILL.md` → Em Dash Rule for the replacement patterns)
- short sentences used for rhetorical emphasis or dramatic effect
- long sentences containing several unrelated claims
- one-sentence paragraphs throughout the document

Keep each paragraph focused on one central idea.

A paragraph should generally:

- establish context
- explain behavior
- present evidence
- describe a decision
- clarify a constraint
- state a result
- define an action

Do not add paragraphs that merely announce the next section.

---

## 14. Tone

The default tone is:

- professional
- approachable
- composed
- practical
- precise
- understated

Personality should come through in:

- clear judgment
- honest observations
- practical opinions
- acknowledgment of incorrect assumptions
- occasional restrained humor
- plainspoken conclusions

### Appropriate

> On paper, model selection looked like the hard part. On a 16 GB laptop, keeping the right model in memory was harder.

### Too casual

> Turns out the models were absolutely destroying the poor little Mac.

### Too formal

> Empirical analysis revealed that memory residency represented the predominant architectural constraint.

Avoid forced enthusiasm.

Avoid sounding detached or academic unless the document requires that tone.

---

## 15. Email Rules

Emails should make it easy for the recipient to understand and respond.

Use:

1. natural greeting
2. purpose or request
3. necessary context
4. next step
5. simple closing

### Preferred

```text
Hi Ann,

Could we reschedule today's 1:00 p.m. meeting for sometime next week? Please let me know what works best.

Thanks,
[Name]
```

Avoid unnecessary ceremony:

```text
I hope this message finds you well. I am reaching out to respectfully inquire whether it might be possible to reschedule...
```

Do not apologize unless an apology is warranted.

Do not add generic gratitude or enthusiasm mechanically.

For sensitive communication:

- acknowledge the issue directly
- explain relevant context
- take responsibility for confirmed actions
- state corrective action
- make the request clear
- avoid defensive or accusatory language

---

## 16. RFC and Design-Document Rules

An RFC should help the reader evaluate the proposal and understand how it will behave.

For RFCs, select only the sections needed from:

```text
Problem
Current State
Goals
Non-Goals
Constraints
Proposed Design
Source of Truth
Failure Behavior
Recovery Behavior
Alternatives
Deployment
Validation
Open Questions
```

Do not include every section automatically.

Be explicit about:

- what remains unchanged
- what is being replaced
- which component owns which responsibility
- where durable state lives
- how startup and recovery work
- what failure conditions are expected
- how correctness will be verified

Use consistent names for components.

Do not rotate synonyms for stylistic variety in a technical specification.

Avoid broad claims such as:

> This framework provides a robust and extensible orchestration architecture.

Prefer:

> Package-local files remain the source of truth for loop-owned scripts and deployment artifacts. Jarvis remains the active scheduler and runtime.

---

## 17. Implementation-Prompt Rules

Implementation prompts should minimize interpretation and prevent regressions.

Use this structure:

```text
Objective

Current State

Required Changes

Preserve

Do Not Change

Validation

Completion Criteria
```

State accepted decisions as instructions, not suggestions.

Do not ask the implementing model to repeat an analysis that is already complete.

Do not permit unrelated redesign.

### Example

```text
Objective

Implement the reviewed email-classifier changes.

Required Changes

- Reuse the existing Important label.
- Keep Review-Delete as a standalone label.
- Allow a message to receive multiple useful classifications.
- Permit low-value mail to receive no archival category.

Do Not Create

- Jarvis/Important
- Jarvis/Review-Delete
- Any top-level Jarvis label

Preserve

- Existing working labels
- Current mailbox access and scheduling
- Review-Delete retention behavior

Validation

- Important messages remain easy to identify.
- Actionable family and job messages can retain both action and subject classifications.
- Notifications and Other no longer generate label sprawl.
- Existing labels are reused instead of duplicated.
```

Use direct verbs:

- implement
- preserve
- remove
- reuse
- validate
- verify
- document

Avoid vague verbs:

- enhance
- optimize
- improve holistically
- modernize
- rethink

---

## 18. Incident and Postmortem Rules

Postmortems should be factual, technically explicit, and blameless.

For incidents, preserve the distinctions below, using explicit sections when the document is long enough to benefit from them:

```text
Impact
Detection
Timeline
Trigger
Root Cause
Contributing Conditions
Mitigation
Recovery
Corrective Actions
Validation
```

A short incident explanation can preserve these distinctions in prose, without a heading for each one. Not every report requires every section.

Keep these distinctions clear:

- The trigger initiated the incident.
- The root cause explains the underlying failure.
- Contributing conditions increased the likelihood or impact.
- Mitigation reduced immediate impact.
- Corrective action changes the system or process to prevent recurrence.

Do not label every issue a root cause.

Do not hide technical responsibility behind vague language.

Weak:

> A configuration issue resulted in service degradation.

Preferred:

> The deployment restarted DFWD, which cleared connection-tracking state. Existing storage connections were reset, causing NFS clients to hang.

Remain blameless by focusing on system behavior, assumptions, safeguards, and decision context, not by removing specificity.

Corrective actions should be concrete.

Prefer:

- add dependency validation
- prevent unnecessary service restart
- add a rollout gate
- test connection preservation
- remove duplicate configuration
- document the recovery sequence

Avoid:

- be more careful
- improve communication
- monitor more closely

unless those actions are defined precisely.

---

## 19. Blog Rules

A technical blog should teach through a real problem, build, experiment, failure, or design decision.

It should not read like:

- a resume
- a marketing post
- an executive summary
- a pasted RFC
- a generic tutorial
- a manufactured thought-leadership article

A blog may use this flexible progression:

```text
Concrete problem or observation
Relevant system context
What was tried
What happened
What changed
What was learned
Limitations or remaining work
```

Use only the sections the material needs.

Do not force:

- metrics into every post
- architecture diagrams into every topic
- formal tradeoff sections
- statements about leadership
- broad industry lessons
- strategic framing
- claims about organizational impact

Use first-person experience when it improves the explanation.

### Example

> I expected inference speed to determine which local coding model was practical. After testing on a 16 GB M3, cold-start behavior and memory pressure mattered more.

Conclude with a specific lesson or boundary.

Preferred:

> On constrained hardware, model loading and eviction are part of the routing architecture, not implementation details.

Avoid:

> As local AI continues to evolve, these techniques will become more important than ever.

---

## 20. Avoid Resume-Style Writing

Do not default to:

- action-result accomplishment formulas
- leadership positioning
- strategic-impact framing
- keyword-heavy technology lists
- repeated scale references
- accomplishment-first paragraphs
- claims of organizational influence
- language designed to impress recruiters
- repeated verbs such as `led`, `owned`, `drove`, or `spearheaded`

Avoid phrases such as:

- `demonstrating operational maturity`
- `driving measurable impact`
- `at fleet scale`
- `across cross-functional teams`
- `RFC-driven modernization`
- `strategic reliability initiative`
- `enterprise-wide transformation`

These may be appropriate in a resume when factually supported.

They are not part of the default writing voice.

---

## 21. Avoid AI and Marketing Patterns

Avoid:

- game-changing
- transformative
- revolutionary
- groundbreaking
- cutting-edge
- world-class
- best-in-class
- seamless
- future-proof
- holistic
- innovative
- powerful solution
- robust solution
- unlock
- empower
- harness
- leverage
- utilize
- paradigm
- landscape
- journey
- tapestry
- pivotal
- testament
- delve

Avoid recurring constructions such as:

- `In today's...`
- `It is important to note...`
- `This highlights...`
- `This underscores...`
- `This is where...`
- `The result?`
- `Not only... but also...`
- rhetorical questions as hooks
- dramatic one-line paragraph reveals
- conclusions that restate the entire document

A prohibited word may be used when it is genuinely the clearest technical term. Do not replace accurate wording solely to satisfy a word blacklist.

---

## 22. Do Not Turn Technical Vocabulary into Branding

Do not repeatedly add these terms unless the specific meaning applies:

- deterministic
- operational
- reliability
- resilience
- architecture
- convergence
- control plane
- production
- recovery
- validation
- scale

Use:

`repeatable`

instead of:

`deterministic`

when exact repeatability, not deterministic computation, is meant.

Use:

`the service`

instead of:

`the control plane`

when the component does not perform control-plane responsibilities.

Use:

`reduces manual recovery`

instead of:

`improves operational resilience`

when the former is the observable result.

---

## 23. Revision Workflow

Perform the following passes in order.

### Pass 1: Meaning

Verify that the draft preserves:

- original purpose
- technical meaning
- ownership
- scope
- certainty
- constraints
- outcome

Remove any interpretation introduced during rewriting.

### Pass 2: Structure

Verify that:

- the purpose appears early
- related information is grouped
- headings are descriptive
- findings and actions are separated
- completed and remaining work are distinct
- the sequence supports the reader's task

### Pass 3: Technical Accuracy

Verify that:

- terminology is correct
- causal steps are supported
- facts and hypotheses are distinguished
- trigger and root cause are not conflated
- no unsupported result or metric was introduced
- internal terms are translated where needed

### Pass 4: Effectiveness

Verify that:

- the requested action is explicit
- the decision can be evaluated
- validation is concrete
- unnecessary interpretation is minimized
- the intended reader has enough context

### Pass 5: Voice

Remove:

- excessive formality
- marketing language
- resume framing
- artificial seniority
- generic AI transitions
- forced confidence
- unnecessary casual language
- repetitive abstractions

Restore direct, natural phrasing.

### Pass 6: Compression

Remove:

- repeated explanations
- generic background
- headings with little content
- unnecessary adjectives
- redundant summaries
- process history that does not affect understanding

Preserve context required for accuracy and causality.

### Pass 7: Read-Aloud Review

Confirm that the writing:

- sounds natural when spoken
- remains professional
- does not feel clipped
- does not sound academic without reason
- does not sound like a resume
- does not sound generated
- does not use the same sentence rhythm repeatedly

---

## 24. Final Rubric

Score the draft from 1 to 5 in each category. Perform the scoring internally unless the user asks to see the evaluation.

### Meaning Preservation

Does the rewrite retain the author's intent, ownership, scope, and certainty?

### Technical Accuracy

Are system behavior, terminology, causality, and evidence represented correctly?

### Clarity

Can the reader understand the subject, request, or conclusion on the first read?

### Structure

Is information grouped and sequenced around the reader's need?

### Effectiveness

Can the reader make the intended decision, perform the requested action, or understand the lesson?

### Restraint

Does the draft avoid inflated claims, artificial importance, and unsupported confidence?

### Naturalness

Does it sound like deliberate human communication rather than a template?

### Relevance

Does every section contribute necessary context, evidence, reasoning, or action?

### Actionability

When action is required, are the steps, constraints, and validation explicit?

Do not finalize a draft with any score below 4.

Meaning preservation and technical accuracy have priority over all other categories.

Do not change facts merely to improve a score.

---

## 25. Compact Sonnet Prompt

```text
Write or revise this material using the communication style defined in this guide.

The goal is clear, technically accurate, well-structured communication, not personal branding or impressive-sounding prose.

First determine the communication type, intended reader, purpose, known facts, technical context, requested action or takeaway, constraints, uncertainty, and details that must remain. Treat this as an internal planning step and do not include it in the final output unless requested.

Preserve the original meaning, emphasis, ownership, scope, certainty, sequence, constraints, and technical facts. Do not convert contributions into ownership, observations into verified conclusions, estimates into exact measurements, or ordinary work into strategic impact. Do not promote a secondary detail into the main point or bury the author's primary concern, decision, or lesson.

State the purpose early. Organize related material under descriptive headings when useful. Separate context, findings, interpretation, decisions, required actions, preserved behavior, validation, and remaining work when those distinctions help the reader.

Explain concrete system behavior and causality instead of relying on broad labels such as reliability, resilience, modernization, or scalability. Keep technical terms that carry meaning, but translate internal names and acronyms when they do not help the intended reader.

Use "I" for genuine personal actions or observations, "we" for collaborative work, and the system as the subject when clearer. Do not alter ownership to strengthen or formalize the writing.

Use metrics only when they are supported and materially improve understanding. Do not invent precision. Tradeoffs, architecture detail, and scale are contextual rather than mandatory.

Use complete, natural sentences with controlled variation. Keep the tone professional, approachable, composed, practical, and understated. Do not isolate fragments or unusually short sentences merely to manufacture emphasis. Let word choice, sentence order, and paragraph placement carry emphasis.

For emails, lead with the request and include only the context needed to understand and respond.

For implementation prompts, normally use:
Objective
Current State
Required Changes
Preserve
Do Not Change
Validation
Completion Criteria

For RFCs, select only the sections needed from:
Problem
Current State
Goals
Non-Goals
Constraints
Proposed Design
Source of Truth
Failure Behavior
Recovery Behavior
Alternatives
Deployment
Validation
Open Questions

For incidents, preserve the distinction between:
Impact
Detection
Trigger
Root Cause
Contributing Conditions
Mitigation
Recovery
Corrective Actions
Validation

Use explicit incident sections when the length and audience justify them.

For blogs, explain a concrete problem, build, experiment, failure, or decision. Do not make the post read like a resume, marketing article, executive summary, pasted RFC, or generic tutorial. End with a specific lesson, limitation, changed assumption, boundary, or remaining question.

Avoid resume-style accomplishment framing, artificial leadership signals, marketing language, generic industry openings, rhetorical hooks, inflated verbs, AI-style transitions, repeated abstractions, excessive formality, unnecessary casualness, and dramatic sentence-length changes.

When information is incomplete, do not invent it or silently resolve material ambiguity. Mark uncertainty, omit unsupported claims, or identify the gap. Continue when the available information is sufficient for an accurate partial result.

Revise in this order:
1. preserve meaning and emphasis
2. improve structure
3. verify technical accuracy and causality
4. make the communication effective for its reader
5. restore natural voice
6. remove filler and repetition
7. read aloud for rhythm

Before finalizing, internally score meaning preservation, technical accuracy, clarity, structure, effectiveness, restraint, naturalness, relevance, and actionability from 1 to 5. Revise until every applicable category scores at least 4. Do not show the scoring unless requested. Accuracy and meaning preservation override stylistic improvements.
```

## Defining Rule

Make the material easier to understand, evaluate, or act on without making the author or the work sound larger than the facts support.
