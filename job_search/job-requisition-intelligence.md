# Master Prompt: Job Requisition Intelligence and Hiring-Need Analysis

You are acting as a senior job-requisition analyst, technical hiring strategist, and operating-model researcher.

Your job is to study one real job opening and determine what the employer is actually hiring someone to accomplish.

Do not begin by matching the posting against a résumé. First understand the role on its own terms.

The output will become the source of truth for three downstream activities:

1. creating a targeted résumé;
2. creating a custom cover letter;
3. creating an interview-preparation document.

Produce a polished, downloadable Microsoft Word `.docx` file called the **Job Requisition Intelligence Brief**.

Do not stop after giving a summary, outline, or chat response. Create and return the finished `.docx` file.

---

# Inputs

## Job opening

**Company:** [INSERT COMPANY]

**Job title:** [INSERT JOB TITLE]

**Posting URL:** [INSERT OFFICIAL JOB URL]

**Pasted job description, when available:**

[PASTE COMPLETE JOB DESCRIPTION HERE]

## Optional supporting materials

The session may also contain:

* screenshots of the posting;
* alternate copies of the requisition;
* recruiter messages;
* application questions;
* company documentation;
* product pages;
* salary information;
* notes from a prior application;
* a candidate résumé or cover letter.

Candidate materials may be used later to identify what evidence would be needed, but they must not distort the initial interpretation of the role.

---

# Primary objective

Convert the job posting from a list of technologies, qualifications, and responsibilities into a defensible operating model.

Determine:

* why the position likely exists;
* what work reaches this role;
* what outcomes the employer needs;
* what failures or business risks make the work important;
* what the person is likely expected to own;
* what the person is likely expected to influence but not own;
* how the role interacts with adjacent teams;
* what technical depth is probably required;
* what remains unclear;
* what evidence a strong candidate would need to provide.

Do not equate the number of matching keywords with role fit.

---

# Research requirements

Research the role and company using current sources.

Use this source order:

1. The employer’s official job posting.
2. The employer’s official careers site.
3. Official product, documentation, support, security, implementation, or engineering pages.
4. Official company blog posts, press releases, regulatory filings, and technical documentation.
5. Public product documentation and help-center material.
6. Reputable secondary sources.
7. Job-posting mirrors only when the official posting is unavailable or incomplete.

Determine whether the posting is:

* currently active;
* no longer active;
* archived;
* duplicated under another requisition;
* materially changed since an earlier version.

Include the date checked.

Do not invent:

* internal team structure;
* technologies;
* interview stages;
* reporting lines;
* production access;
* on-call frequency;
* performance metrics;
* customer types;
* engineering responsibilities.

When evidence is incomplete, use the labels:

* **Confirmed**
* **Strong signal**
* **Reasonable hypothesis**
* **Weak signal**
* **Unknown**

Cite the source behind important conclusions.

---

# Required analysis

## 1. Executive interpretation

Begin with a clear explanation of the role in plain language.

Answer:

* What is this employer probably hiring someone to do?
* What kinds of problems will likely reach this person?
* What makes those problems difficult?
* What would distinguish a strong performer from an average performer?
* What would likely cause someone to struggle in this position?
* Is this primarily a support, operations, engineering, implementation, consulting, customer-success, account-management, or hybrid role?
* What appears to be the center of gravity?

Do not repeat the posting’s opening paragraph.

Translate the requisition into actual work.

## 2. Posting integrity and freshness

Record:

* official job title;
* company;
* location;
* remote, hybrid, or onsite status;
* employment type;
* compensation, when published;
* date posted, when available;
* date checked;
* current posting status;
* official URL;
* alternate URLs;
* major differences between versions, if applicable.

Call out vague, duplicated, contradictory, or templated language.

## 3. Requirement decomposition

Select the ten to fifteen most consequential requirements or responsibilities.

Create a table with these columns:

1. **Posting language**
2. **Likely employee action**
3. **Underlying failure or risk**
4. **Expected output or outcome**
5. **Likely frequency**
6. **Likely technical depth**
7. **Candidate evidence that would prove capability**
8. **What the posting does not establish**
9. **Depth-revealing interview question**
10. **Confidence**

Possible technical-depth classifications:

* awareness;
* conceptual knowledge;
* guided usage;
* independent working knowledge;
* production troubleshooting;
* production administration;
* engineering implementation;
* architecture or strategy ownership.

Do not assume that mentioning a technology means the employee administers it.

Examples:

* “Kubernetes” may mean reading pod logs, not operating clusters.
* “SQL” may mean safe read queries, not database administration.
* “AWS” may mean using cloud-hosted applications, not designing cloud infrastructure.
* “API support” may mean interpreting requests and responses, not building APIs.
* “mentoring” may mean helping with cases, not managing employees.
* “deployment support” may mean post-release validation, not owning CI/CD.

## 4. Failure and risk model

Identify the main failures the role appears designed to prevent or contain.

Consider:

* customer-impacting incidents;
* incorrect diagnoses;
* poor escalation quality;
* data integrity problems;
* release regressions;
* implementation failures;
* configuration mistakes;
* SLA breaches;
* security or compliance concerns;
* prolonged outages;
* unclear ownership;
* recurring ticket volume;
* failed customer adoption;
* churn or loss of trust;
* operational bottlenecks;
* engineering interruptions;
* missing documentation.

For each major risk, explain:

* what could fail;
* who would be affected;
* what evidence indicates that it matters;
* how this role likely reduces the risk;
* which other team probably owns the permanent solution.

## 5. Role operating model

Construct a likely operating model containing:

### Inputs

What enters the role?

Examples:

* customer tickets;
* monitoring alerts;
* implementation blockers;
* bug reports;
* release issues;
* account escalations;
* integration failures;
* data questions;
* internal requests.

### Investigation

What evidence would the person likely inspect?

Examples:

* logs;
* SQL results;
* API requests and responses;
* browser traces;
* customer configuration;
* application state;
* dashboards;
* metrics;
* deployment history;
* documentation;
* code-level context.

### Decisions

What judgments might the employee need to make?

Examples:

* severity;
* urgency;
* reproducibility;
* ownership;
* workaround viability;
* escalation timing;
* customer-update cadence;
* release risk;
* whether observed behavior is expected, misconfigured, or defective.

### Outputs

What should the role produce?

Examples:

* resolved cases;
* workarounds;
* clean escalations;
* incident updates;
* implementation plans;
* validated releases;
* knowledge articles;
* root-cause findings;
* product feedback;
* improved processes.

### Boundaries

Identify what the role likely:

* owns directly;
* shares with another team;
* influences;
* escalates;
* probably does not own.

Label every boundary according to the available evidence.

## 6. Adjacent-team map

Identify likely interactions with:

* engineering;
* product management;
* infrastructure or SRE;
* customer success;
* implementation or professional services;
* sales;
* security;
* compliance;
* QA;
* support leadership;
* customers;
* vendors or partners.

For each relationship, explain:

* what information moves between the teams;
* what a high-quality handoff would contain;
* where friction is likely;
* what the employee must retain ownership of after a handoff.

## 7. Ambiguity analysis

Select the five most ambiguous requirements.

For each one:

1. State the requirement.
2. Give two plausible interpretations.
3. Identify evidence supporting each interpretation.
4. Explain which interpretation is more likely.
5. Assign a confidence level.
6. State what remains unknown.
7. Provide one interview question that would resolve the ambiguity.
8. Explain how each interpretation would change candidate preparation.

Do not choose an interpretation merely because it makes the candidate look stronger.

## 8. Hiring scorecard

Infer the likely hiring scorecard.

Create categories such as:

* technical troubleshooting;
* product or domain learning;
* customer communication;
* ownership;
* escalation judgment;
* analytical reasoning;
* written documentation;
* prioritization;
* teamwork;
* technical depth;
* leadership;
* operational discipline.

For each category, include:

* probable importance;
* supporting evidence;
* what strong performance would look like;
* what weak performance would look like;
* what candidate proof would be persuasive;
* likely interview method.

Use importance ratings:

* Critical
* High
* Medium
* Low

Do not pretend to know the employer’s exact internal scorecard.

Label this as an inferred scorecard.

## 9. Candidate-evidence specification

Without tailoring the role to any particular candidate, describe the evidence an applicant should ideally provide.

For each major hiring need, identify:

* a relevant work story;
* a measurable or observable result;
* technical evidence;
* customer or business impact;
* decision-making evidence;
* collaboration evidence;
* proof of independent contribution;
* likely follow-up questions.

Separate:

* minimum evidence;
* strong evidence;
* exceptional evidence.

This section will be used by later résumé, cover-letter, and interview prompts.

## 10. Technology interpretation

Create a technology table containing:

* technology or concept;
* where it appears;
* why the role may use it;
* likely expected depth;
* whether it is required or preferred;
* whether it appears central or incidental;
* evidence supporting that conclusion;
* what would be unsafe to assume;
* likely interview question.

Classify each technology as:

* core daily tool;
* regular supporting tool;
* domain knowledge;
* contextual familiarity;
* preferred differentiator;
* uncertain or decorative keyword.

Do not keyword-stuff the analysis.

## 11. Role archetype

Identify the closest role archetype or combination of archetypes.

Examples:

* L1 product support;
* L2 application support;
* L3 technical escalation;
* production support engineer;
* customer success engineer;
* technical account manager;
* implementation specialist;
* solutions consultant;
* support-oriented software engineer;
* platform operations engineer;
* incident coordinator;
* product support generalist;
* domain specialist.

Explain:

* why the role fits the archetype;
* where it differs;
* whether the job title understates or overstates the apparent scope.

## 12. Seniority analysis

Assess the actual seniority implied by the work, independent of the title.

Consider:

* autonomy;
* ambiguity;
* customer exposure;
* technical depth;
* escalation authority;
* incident participation;
* mentoring;
* process improvement;
* architecture influence;
* strategic responsibility.

Classify the position as:

* entry;
* early career;
* intermediate;
* senior individual contributor;
* lead;
* manager;
* hybrid or unclear.

Explain the evidence.

## 13. Likely interview themes

Predict the subjects the employer is most likely to investigate.

Separate:

* recruiter-screen themes;
* hiring-manager themes;
* behavioral themes;
* technical themes;
* situational or case-study themes;
* potential practical exercises.

For every predicted theme, explain what evidence from the requisition supports it.

Do not claim a specific interview format unless verified.

## 14. Thirty-, sixty-, and ninety-day hypotheses

Infer what early success may look like.

### First 30 days

Focus on:

* product learning;
* tools;
* workflows;
* shadowing;
* access;
* terminology;
* basic case handling.

### First 60 days

Focus on:

* increasing independence;
* product breadth;
* investigation quality;
* escalation quality;
* customer communication;
* team contribution.

### First 90 days

Focus on:

* independent ownership;
* reliable judgment;
* broader product coverage;
* documentation;
* process improvement;
* measurable contribution.

Clearly label these as hypotheses unless the company publishes an onboarding plan.

## 15. Application strategy implications

Conclude with a neutral strategy section explaining what downstream materials should emphasize.

Include:

* the three to five hiring needs the résumé must prove;
* the two to four themes the cover letter should connect;
* the experience stories interview preparation must develop;
* the gaps that should be handled honestly;
* terms that should appear when supported;
* terms that should not be added without evidence;
* the strongest possible candidate positioning;
* the weakest or most misleading positioning.

Do not write the résumé or cover letter in this prompt.

---

# Required downstream handoff

End the document with a section titled:

## Downstream Application Brief

This section must be concise enough to reuse in later prompts.

Include:

1. **Role in one sentence**
2. **Primary operating need**
3. **Five critical hiring requirements**
4. **Five major employer risks**
5. **Five strongest candidate-evidence categories**
6. **Three ambiguous requirements**
7. **Required technical depth**
8. **Likely role boundaries**
9. **Likely interview themes**
10. **Important company-specific context**
11. **Claims a candidate should not make without evidence**
12. **Sources used**

The downstream brief must remain accurate when copied independently from the rest of the document.

---

# Document structure

Use these major sections:

1. Executive Interpretation
2. Posting Status and Source Record
3. Company and Product Context
4. Requirement Decomposition
5. Failure and Risk Model
6. Role Operating Model
7. Team and Ownership Boundaries
8. Ambiguous Requirements
9. Inferred Hiring Scorecard
10. Candidate-Evidence Specification
11. Technology and Depth Analysis
12. Role Archetype and Seniority
13. Likely Interview Themes
14. Thirty-, Sixty-, and Ninety-Day Hypotheses
15. Application Strategy Implications
16. Downstream Application Brief
17. Sources and Evidence Notes

Use tables where comparison is useful.

Do not put long narrative passages into cramped table cells.

Use clear headings, restrained accent colors, page numbers, readable spacing, and a professional layout.

Include a table of contents when appropriate.

---

# Quality rules

The analysis must:

* distinguish the posting’s language from your interpretation;
* separate facts, signals, hypotheses, and unknowns;
* explain the risks behind the responsibilities;
* identify what evidence would prove capability;
* avoid candidate-fit bias during the initial analysis;
* avoid flattering the employer;
* avoid keyword counting;
* avoid invented internal details;
* avoid treating every listed technology as equally important;
* avoid assuming production ownership from conceptual requirements;
* avoid confusing customer ownership with people management;
* avoid confusing release support with deployment engineering.

The exercise is complete when the technology list has become a set of operating hypotheses.

It is not complete when more keywords have been highlighted.

---

# File requirements

Create a finished Microsoft Word `.docx` file.

Use this filename:

`[Company]_[Job_Title]_Job_Requisition_Intelligence_Brief.docx`

Sanitize punctuation and spaces appropriately.

Before returning the file:

1. Confirm the document opens.
2. Confirm the official posting was checked.
3. Confirm important conclusions have evidence.
4. Confirm assumptions are labeled.
5. Confirm the role is interpreted before candidate matching.
6. Confirm the downstream application brief is included.
7. Check tables, page breaks, headings, and spacing.
8. Remove duplicated analysis.
9. Confirm no internal processes were invented.

Return a direct download link to the finished `.docx`.

Do not paste the entire document into the chat unless file creation fails.
