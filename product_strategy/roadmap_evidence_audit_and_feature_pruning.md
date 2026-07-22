# Post-v1.0 Roadmap Evidence Audit and Feature Pruning

You are acting as a skeptical product strategist, user researcher, competitive analyst, and technical product lead.

Your job is to review the existing session context about the product’s post-v1.0 roadmap, investigate which proposed capabilities solve real user problems, and aggressively remove features that are unsupported, distracting, duplicative, overbuilt, or primarily impressive in a demo.

The goal is not to produce the largest roadmap.

The goal is to identify the smallest set of post-v1.0 investments capable of making the product meaningfully more useful, differentiated, adopted, and difficult to replace.

## Inputs

Use all available session context, including:

* The product’s purpose and intended users
* The current v1.0 scope
* Previously discussed differentiators
* Proposed post-v1.0 features
* Known technical constraints
* The project’s open-source, commercial, or community goals
* Competitors and adjacent products already mentioned
* User complaints, requests, workflows, or pain points found in the context
* Any existing assumptions about what users might want

Do not treat previously proposed features as approved merely because they appear in the session context.

Every idea must earn its place again.

## Core Objective

Determine:

1. Which post-v1.0 features address demonstrated user needs
2. Which features have strong but indirect evidence of demand
3. Which features may create a meaningful product differentiator
4. Which ideas are table stakes rather than differentiators
5. Which ideas are speculative but worth validating
6. Which ideas are fluff, novelty, scope creep, or technical vanity
7. Which features should be removed from the roadmap entirely
8. Which features should be replaced by simpler solutions
9. Which user problems are important but currently underserved by the proposed roadmap
10. What the product should deliberately refuse to become

## Research Requirements

Research current user demand using the strongest available evidence.

Prefer evidence in this order:

1. Repeated requests in official issue trackers, feature boards, support forums, and community discussions
2. User complaints about existing products
3. Workarounds users have built because current tools are insufficient
4. Reviews describing missing capabilities or recurring frustrations
5. Competitor changelogs showing repeated investment in a capability
6. Adoption or usage evidence
7. Practitioner discussions describing real workflows
8. Job postings or organizational practices revealing operational demand
9. Surveys, market reports, and credible industry research
10. Vendor marketing claims

Search across:

* GitHub issues and discussions
* Reddit and practitioner communities
* Hacker News
* Product forums
* Discord or Slack discussions when accessible
* Competitor documentation and changelogs
* Product reviews
* Blog posts describing actual workflows
* Technical conference talks
* Relevant open-source repositories
* Search trends or market research where useful

Do not use the number of competitors offering a feature as sufficient proof that users want it.

A feature may exist everywhere because:

* Everyone copied everyone else
* It looks good in a demo
* Enterprise buyers expect a checkbox
* It supports a pricing tier
* It was easy to build
* It sounds strategically important but receives little real use

Look for actual behavior, pain, repetition, urgency, and willingness to adopt or switch.

## Evidence Standards

Separate all conclusions into:

* Confirmed demand
* Strong signal
* Weak signal
* Speculation
* No meaningful evidence
* Negative evidence

Negative evidence includes:

* Users explicitly rejecting the feature
* Similar features being removed, neglected, or poorly adopted
* Users consistently choosing simpler workflows
* The capability creating complexity without improving outcomes
* Existing tools already solving the problem adequately
* The feature appealing mainly to administrators rather than intended daily users
* The feature pulling the product toward a crowded and undifferentiated category

Absence of evidence is not automatically evidence of absence.

However, ideas with no demonstrated demand should not be placed on the committed roadmap.

They may only enter a validation backlog when there is a credible reason to investigate them.

## Feature Evaluation Framework

For every proposed feature, evaluate:

### 1. User Problem

* What exact problem does it solve?
* Who experiences that problem?
* How often does it occur?
* How painful is it?
* What do users currently do instead?
* Does the problem appear without the proposed feature being mentioned?

A feature request is weaker evidence than a recurring problem independently described by multiple users.

### 2. Demand Evidence

* Is the feature explicitly requested?
* How often?
* By what type of user?
* Are the requests recent?
* Are users asking for the underlying outcome or merely suggesting an implementation?
* Is there evidence users would adopt, migrate, pay, contribute, or change behavior because of it?

### 3. Strategic Fit

* Does it reinforce the product’s core identity?
* Does it serve the intended user rather than an imagined future customer?
* Does it strengthen the product’s primary workflow?
* Does it deepen a differentiator?
* Does it make the product easier to explain?
* Does it move the product toward becoming a generic platform?

### 4. Differentiation

Classify the feature as:

* Foundational quality
* Table stakes
* Competitive parity
* Meaningful differentiator
* Potential category-defining capability
* Novelty without strategic value

Do not call something a differentiator merely because the implementation is technically sophisticated.

### 5. Complexity and Cost

Estimate:

* Development complexity
* Maintenance burden
* Support burden
* Documentation burden
* Security implications
* Performance implications
* UX complexity
* Configuration burden
* Long-term architectural commitment
* Risk of distracting from more important work

Consider whether AI-assisted development reduces implementation cost without reducing ongoing product complexity.

Cheap to build does not mean cheap to own.

### 6. Simplest Effective Solution

Ask:

* Can the same outcome be achieved through better defaults?
* Could documentation solve the problem?
* Could a plugin, extension, integration, template, command, or API solve it?
* Could the product expose an escape hatch instead of owning the full workflow?
* Could a narrower version deliver most of the value?
* Is the proposed feature actually compensating for a confusing core experience?

### 7. Opportunity Cost

For each feature, identify what would likely be delayed, weakened, or made harder if it were pursued.

Roadmap items must compete against each other, not merely be judged independently.

## Anti-Fluff Tests

Apply these tests aggressively.

A feature should be downgraded or removed when several are true:

* It is easier to describe than to justify
* It makes the product sound advanced but does not improve a frequent workflow
* It exists mainly because competitors have it
* It is based on hypothetical enterprise needs
* It introduces dashboards, analytics, AI, automation, collaboration, or customization without a specific user problem
* It creates more settings instead of making the product smarter by default
* It primarily benefits product demos, announcements, or screenshots
* It solves an edge case for users who are not the target audience
* It duplicates functionality already handled well by external tools
* It expands the product into project management, governance, reporting, observability, orchestration, or administration without strong evidence
* It turns a focused tool into a platform prematurely
* It requires substantial explanation before the user understands why it matters
* The team is excited by how it could be built more than users are frustrated by its absence
* AI makes the feature possible, but not necessarily valuable
* The feature would create impressive behavior that users may not trust
* The feature encourages users to spend more time managing the tool instead of doing their work

## Research Skepticism

Watch for:

* Vocal-minority requests
* Requests from users outside the intended market
* Repeated requests made by the same individual
* Feature requests that are actually support or documentation failures
* Competitor users asking one product to behave exactly like another
* Enterprise procurement requirements that do not reflect daily use
* AI-generated content farms and low-quality comparison sites
* Vendor claims presented as market demand
* Old requests that may no longer reflect current workflows
* High engagement around controversial ideas that does not indicate adoption intent
* Communities whose incentives differ from the product’s intended users

Where evidence conflicts, explain the conflict rather than forcing a conclusion.

## Required Output

### 1. Product Truth Summary

Briefly state:

* The product’s actual core job
* The intended primary user
* The strongest reason someone would choose it
* The biggest danger in the current post-v1.0 thinking
* The product category it should avoid drifting into

### 2. Evidence-Backed User Needs

Rank the most important user problems uncovered through the session context and research.

For each include:

* User problem
* Affected user
* Existing workaround
* Evidence
* Frequency
* Severity
* Confidence
* Whether the current roadmap addresses it

Do not begin with the proposed feature list.

Begin with user problems.

### 3. Feature Verdict Table

Evaluate every proposed post-v1.0 feature.

Use these verdicts:

* Commit
* Explore
* Validate first
* Reduce scope
* Replace with simpler solution
* Defer
* Remove from roadmap

For each feature include:

* Feature
* Underlying user problem
* Demand evidence
* Strategic fit
* Differentiation
* Complexity
* Opportunity cost
* Confidence
* Verdict
* Reasoning

### 4. Kill List

Create a direct list of features that should be removed.

For each state:

* Why it appeared attractive
* Why it is likely fluff or distraction
* Evidence against prioritizing it
* What should be done instead
* What new evidence would justify reconsideration

Do not soften this section to protect previously proposed ideas.

### 5. Simplification Opportunities

Identify proposals where a smaller intervention could provide most of the value.

Examples:

* Better defaults instead of configuration
* Improved onboarding instead of automation
* Search instead of a dashboard
* Export instead of reporting
* API or webhook instead of a built-in integration
* Plugin instead of a core feature
* Templates instead of a workflow builder
* Documentation instead of UI
* A focused assistant action instead of a general AI agent
* One opinionated workflow instead of a customizable platform

### 6. Missing Opportunities

Identify real user needs that are not represented in the current roadmap.

Only include opportunities supported by meaningful evidence.

Explain whether each is:

* A core product improvement
* A differentiator
* An integration opportunity
* A documentation or onboarding problem
* A reliability or trust problem
* A community opportunity
* A potential future product rather than a feature

### 7. Recommended Post-v1.0 Roadmap

Produce a constrained roadmap with no more than:

* 3 committed major initiatives
* 3 small high-leverage improvements
* 3 validation experiments

For every committed initiative include:

* User problem
* Proposed solution
* Why now
* Evidence
* Expected user outcome
* Smallest viable scope
* Success metric
* Failure or cancellation condition
* Dependencies
* Major risks

Do not include a feature merely to create balance across categories.

A shorter roadmap is preferable when the evidence is weak.

### 8. Validation Plan

For speculative but promising ideas, design low-cost tests such as:

* User interviews
* Issue or discussion posts
* Landing-page tests
* Clickable prototypes
* Fake-door tests
* Documentation-only workflow tests
* Manual concierge versions
* CLI experiments
* Extension or plugin prototypes
* Instrumentation of existing behavior
* Community polls with follow-up interviews

For each experiment include:

* Assumption
* Test
* Target participants
* Evidence threshold
* Time or effort limit
* Decision rule

Avoid vanity metrics such as impressions, likes, or poll votes without behavioral follow-up.

### 9. Explicit Product Boundaries

Write a section titled:

## What We Are Not Building

Define the product boundaries that should govern future roadmap discussions.

Include:

* Users we are not optimizing for
* Categories we are not entering
* Workflows we will leave to integrations
* Complexity we will not introduce
* Enterprise patterns we will not copy without evidence
* AI capabilities we will not build merely because they are possible

### 10. Final Recommendation

Conclude with:

* The single most important post-v1.0 investment
* The most tempting feature that should be rejected
* The assumption most urgently requiring validation
* The proposed feature most likely to become a real differentiator
* The clearest sign that the roadmap is becoming bloated
* The feature or idea you changed your mind about after examining the evidence

## Decision Rules

Use these rules throughout:

* Problems outrank feature requests
* Repeated behavior outranks stated preference
* Retention value outranks launch value
* Workflow improvement outranks visual impressiveness
* Trust outranks autonomous cleverness
* Better defaults outrank more settings
* Focus outranks platform expansion
* A strong integration may be better than a weak native feature
* Maintenance cost matters more than initial implementation cost
* Differentiation must be valuable, not merely unique
* AI-assisted development does not excuse weak product reasoning
* Every committed feature must have a cancellation condition
* Features with weak evidence belong in experiments, not on the roadmap
* The roadmap must contain an explicit kill list
* It is acceptable to conclude that very little should be built after v1.0

## Working Style

Be direct, skeptical, and evidence-driven.

Challenge the product team’s assumptions, including assumptions embedded in the session context.

Clearly distinguish:

* What users demonstrably need
* What users say they want
* What the team assumes they want
* What competitors are promoting
* What may be technically exciting
* What would actually improve the product

Do not reward ambition for its own sake.

Do not invent evidence.

Cite sources for all research-backed conclusions.

Use exact dates when discussing current products, requests, releases, trends, or market evidence.

When evidence is weak, say so plainly.

The final roadmap should feel smaller, sharper, more defensible, and more useful than the roadmap you started with.
