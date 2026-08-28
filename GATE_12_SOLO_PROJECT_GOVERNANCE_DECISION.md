# Gate 12 Solo Project Governance Decision

## STATUS

GOVERNING — Effective immediately upon local commit

## EFFECTIVE_BASELINE

LOCAL_HEAD = a68a257802f1316f0a60e98eaec3345f0fa5de05
REMOTE_HEAD = a68a257802f1316f0a60e98eaec3345f0fa5de05
BRANCH = codex/i-tech-next-roadmap-freeze

## GOVERNANCE_PROBLEM

Gate 12 requires explicit written approval from TECH_LEAD and QA roles. The project is operated as a solo project with one accountable owner/operator. The question is whether existing governance requires these roles to be filled by distinct human individuals, or whether a single person may hold both roles with procedural separation.

## EVIDENCE_REVIEWED

### CURRENT (Locked, Governing)

1. **SUPABASE_GATE_12_DEFECT_REMEDIATION_PLAN.md** (planning tag: `supabase-gate-12-defect-remediation-planning-locked`, commit `eb87f1fbffcb1607ed0b2103a9f799019456a3e6`)
   - Section R.1: Lists "Tech Lead" as approval role for Architecture
   - Section Q: Lists "QA" as owner for running staging tests
   - Section R.3: Sign-off table includes "Tech Lead" row (blank)
   - No mention of QA as an approval/sign-off role; QA is a test execution role
   - No language requiring distinct human individuals

2. **SUPABASE_PRODUCTION_DEPLOYMENT_PLAN.md** (planning tag: `supabase-production-deployment-planning-baseline-locked`, commit `741b4236d4344e8fbd3f66c8c41af4595da15de7`)
   - Section 7.17 (Deployment Gates): GATE 11 requires "Written approval from PO + Tech Lead"
   - Section 7.17: GATE 12 (SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION) lists authorization: "Tech lead + QA"
   - Section 7.21 (Future Session Boundaries): `SUPABASE_STAGING_VERIFICATION` and `SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION` both list "Tech lead + QA" as authorization required
   - Section 7.15 (Responsibility Boundary): "Post-deployment verification: Deployment engineer + QA"
   - No language requiring distinct human individuals for Tech Lead and QA roles

3. **SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md** (Gate 12 already executed, commit `b9ef7a7f264f6119d051cd25e07f9b1854b463ec`)
   - Documents a completed Gate 12 verification session
   - Executed by a single operator without separate Tech Lead/QA attestations
   - GATE_12 = PASS recorded
   - Demonstrates precedent of solo execution

### LOCKED (Historical Planning)

4. **PROJECT_MASTER_PLAN.md** (master governing document)
   - Section 15: "Local commits only — no push/tag/deploy without explicit authorization"
   - No role definitions for Tech Lead or QA
   - No separation of duties requirements

### SUPERSEDED (Prior Roadmap)

5. **I-TECH-NEXT-ROADMAP-FREEZE.md**, **I-TECH-FINAL-DELIVERY-CLOSURE-REPORT.md**
   - No Tech Lead/QA role definitions
   - No independence requirements

### INFORMAL

6. **CODEX.md** and other technical reports
   - No governance role content

## EXISTING_ROLE_REQUIREMENTS

| Source | TECH_LEAD Required | QA Required | Role Separation Stated |
|--------|-------------------|-------------|------------------------|
| SUPABASE_GATE_12_DEFECT_REMEDIATION_PLAN.md §R.1 | Yes (Architecture approval) | No (test execution only) | No |
| SUPABASE_PRODUCTION_DEPLOYMENT_PLAN.md §7.17 | Yes (GATE 11, GATE 12) | Yes (GATE 12, staging verification) | No (lists as "Tech lead + QA" without "distinct") |
| SUPABASE_PRODUCTION_DEPLOYMENT_PLAN.md §7.21 | Yes (staging + prod verification sessions) | Yes (staging + prod verification sessions) | No |
| PROJECT_MASTER_PLAN.md | No | No | No |
| All other documents | No | No | No |

## DISTINCT_HUMAN_REQUIREMENT_FOUND

**NO** — No governing source explicitly requires Tech Lead and QA to be distinct human individuals.

The locked planning documents list "Tech lead + QA" as role *attestations* required for Gate 12 authorization, but:
- No document uses language such as "distinct individuals", "separate persons", "independent human reviewers", "four-eyes principle", "segregation of duties requiring different people", or equivalent.
- The SUPABASE_GATE_12_DEFECT_REMEDIATION_PLAN.md treats QA as a test execution role, not an approval role.
- The SUPABASE_PRODUCTION_DEPLOYMENT_PLAN.md lists "Tech lead + QA" for session authorization without independence qualifiers.
- The previously executed Gate 12 session (SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md) was completed by a single operator.

## SOLO_PROJECT_STATUS

**CONFIRMED** — This is a genuinely solo-operated project. All planning, implementation, testing, and governance sessions have been conducted by a single accountable owner/operator. No other developers, QA personnel, or independent reviewers have participated in any phase.

## DECISION

**OUTCOME_A_SOLO_MULTI_ROLE_GOVERNANCE_PERMITTED**

A single accountable project owner/operator MAY hold both TECH_LEAD and QA roles for this project.

The same person MAY provide both Gate 12 approvals provided:
- The approvals are separate written attestations
- Each explicitly names the role being exercised (TECH_LEAD or QA)
- Each explicitly authorizes GATE_12_REVERIFICATION
- All procedural separation controls in this governance decision are followed

## ALLOWED_ROLE_CONSOLIDATION

| Role | May Be Held By Same Person | Condition |
|------|---------------------------|-----------|
| PROJECT_OWNER | Yes | Sole accountable operator |
| TECH_LEAD | Yes | With distinct attestation |
| QA | Yes | With distinct attestation |
| SECURITY_REVIEWER | Yes | With distinct attestation (per remediation plan) |
| DBA | Yes | With distinct attestation (per remediation plan) |
| BACKEND_LEAD | Yes | With distinct attestation (per remediation plan) |
| RELEASE_MANAGER | Yes | With distinct attestation (per remediation plan) |

Consolidation applies ONLY because this is a solo-operated project. Must be revisited if additional accountable team members are introduced.

## TECH_LEAD_RESPONSIBILITIES

Under the solo-project model, TECH_LEAD approval means the approver, acting specifically in the TECH_LEAD role, has reviewed:

- Repository baseline and governing locks
- Remediation deployment status
- Technical scope and production safety boundaries
- Prohibited deployment actions
- Gate 12 technical verification procedure
- Rollback/stop rules
- Evidence requirements

The Tech Lead attestation must explicitly authorize **GATE_12_REVERIFICATION** from the technical-governance perspective.

## QA_RESPONSIBILITIES

Under the solo-project model, QA approval means the same person, acting specifically in the QA role, has independently reviewed:

- Mandatory Gate 12 verification matrix
- Expected results and negative-path requirements
- Production test-data safety
- Side-effect verification
- Tenant-isolation checks
- Cleanup requirements
- Pass/fail criteria
- Defect stop conditions

The QA attestation must explicitly authorize **GATE_12_REVERIFICATION** from the quality-verification perspective.

## CONFLICT_OF_INTEREST_CONTROLS

The following mandatory controls compensate for lack of human independence with procedural separation:

**CONTROL_1** — Role-separated written attestations. The same individual must issue distinct written statements for TECH_LEAD and QA roles.

**CONTROL_2** — Gate 12 executed in an independent new session. The governance decision session does not itself issue role approvals.

**CONTROL_3** — No remediation/repair allowed inside Gate 12. Gate 12 is verification only.

**CONTROL_4** — Any mandatory test failure causes BLOCKED/STOP. No discretionary pass.

**CONTROL_5** — Evidence is recorded before PASS classification. No post-hoc justification.

**CONTROL_6** — No test criterion may be changed after seeing a failure merely to produce a PASS.

**CONTROL_7** — No deployment is permitted inside Gate 12.

**CONTROL_8** — No Git mutation is permitted inside Gate 12 unless separately governed.

**CONTROL_9** — Production test artifacts, if authorized, must be explicitly ledgered and reconciled.

**CONTROL_10** — The final Gate 12 result must be evidence-driven rather than owner-discretion driven.

**CONTROL_11** — The same individual must explicitly state which role is being exercised in each approval (e.g., "Acting as TECH_LEAD: I authorize..." / "Acting as QA: I authorize...").

**CONTROL_12** — Role consolidation applies only because this is a solo-operated project and must be revisited if additional accountable team members are introduced.

## ROLE_SEPARATED_APPROVAL_REQUIREMENT

For any future Gate 12 session, the following separate approvals are required:

1. **TECH_LEAD Attestation** — Explicit statement: "Acting as TECH_LEAD, I authorize GATE_12_REVERIFICATION based on technical governance review of [specific items]."

2. **QA Attestation** — Explicit statement: "Acting as QA, I authorize GATE_12_REVERIFICATION based on quality verification review of [specific items]."

A single generic statement such as "I approve everything" is NOT sufficient. Each role attestation must evaluate its own responsibility independently.

## PRODUCTION_TEST_DATA_AUTHORIZATION_RULE

This governance session does NOT automatically authorize production test-data mutation.

For future Gate 12:
- TECH_LEAD approval and QA approval must explicitly state whether controlled ephemeral production test-data mutation is approved.
- If those later approval statements do not explicitly authorize it: **PRODUCTION_TEST_DATA_MUTATION_AUTHORIZATION = NOT_GRANTED**
- Gate 12 may then execute only non-mutating tests until further approval.

## NO_RETROACTIVE_APPROVAL

**RETROACTIVE_APPROVAL = NOT_GRANTED**

This governance decision does NOT constitute retrospective approval of:
- Previous Gate 11 activity
- Previous Gate 12 activity (the session documented in SUPABASE_PRODUCTION_POST_DEPLOYMENT_VERIFICATION_REPORT.md)
- Previous deployment
- Previous remediation sessions

The governance rule applies prospectively. The future Gate 12 session still requires explicit role-separated approval statements issued after this governance decision becomes governing.

## TRIGGER_FOR_REVIEW

**SOLO_ROLE_MODEL_REVIEW_TRIGGER = TEAM_OR_EXTERNAL_GOVERNANCE_CHANGE**

The solo governance model must cease to be assumed automatically if:
- Another developer joins with decision authority
- A dedicated QA person is introduced
- An external customer requires independent acceptance
- Regulatory/compliance requirements appear
- Financing/audit/governance obligations require segregation of duties
- The project becomes organizational rather than solo-operated

## NEXT_AUTHORIZED_SESSION

**GATE_12_SOLO_PROJECT_GOVERNANCE_REMOTE_LOCK**

This session establishes local governance only. Remote locking of this governance decision is a separate session. No Gate 12 reverification is authorized in this session.