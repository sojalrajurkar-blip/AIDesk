# AGENTS.md — AI Office IT Help Desk
## Master Build Instructions for Antigravity

> **Purpose:** This file is the master instruction for Antigravity to build the **AI Office IT Help Desk** project step-by-step according to the approved PRD and SRS.
>
> **Source of truth:** `AI_Office_IT_Help_Desk_PRD_No_Email.md` and `AI_Office_IT_Help_Desk_SRS_No_Email(1).md`
>
> **Important:** Do not redesign the product scope, remove core requirements, or replace the required architecture without explicit approval.

---

# 1. Your Role

You are the primary AI software-development agent for the **AI Office IT Help Desk**.

Your responsibility is to:

1. Understand the PRD and SRS before implementing anything.
2. Inspect the existing repository before creating or modifying files.
3. Build the system incrementally.
4. Use **Stitch MCP** for UI/UX design and screen generation where available.
5. Implement the generated UI in Flutter.
6. Implement all business rules in FastAPI.
7. Use PostgreSQL/Supabase for persistent data.
8. Integrate AI only through FastAPI.
9. Keep authentication and RBAC enforced by the backend.
10. Test every completed phase.
11. Never declare a feature complete merely because a screen exists.
12. Keep all important user actions connected to real backend state.

The final application must behave as one connected product, not as a collection of disconnected demo screens.

---

# 2. Source Documents and Priority

Read these documents completely before implementation:

- `AI_Office_IT_Help_Desk_PRD_No_Email.md`
- `AI_Office_IT_Help_Desk_SRS_No_Email(1).md`

Treat them as the product contract.

When there is an implementation question:

1. SRS requirement
2. PRD requirement
3. Existing approved architecture
4. Existing repository conventions
5. Reasonable implementation decision

Do not silently invent product requirements.

If a requirement is genuinely ambiguous, stop and ask for clarification before making a major architectural decision.

---

# 3. Product Definition

The product is an **AI-powered Office IT case management platform**.

The complete workflow is:

**Employee → Case → Evidence → AI Understanding → Assignment → Communication → Investigation → Tasks → SLA → Risk → Escalation → Resolution → Confirmation → Analytics → Audit**

The core principle is:

> The system manages the case.  
> AI helps people understand and move the case forward.  
> Humans remain responsible for important decisions.

AI recommendations must never silently become confirmed facts.

---

# 4. Required Technology Stack

Use exactly this Version 1 direction unless explicitly approved otherwise.

## Frontend

- Flutter
- Primary mobile application

## Backend

- Python
- FastAPI
- REST APIs

## Database

- PostgreSQL
- Supabase PostgreSQL is the preferred low-cost production option

## File Storage

- External object/file storage for larger binary evidence

## AI

- External AI APIs
- AI APIs must be accessed through FastAPI
- Never expose AI API keys in Flutter

## Authentication

- Secure authentication
- Password hashing
- Token-based authentication

## Authorization

- Backend-enforced RBAC

Roles:

- `REQUESTER`
- `OPERATOR`
- `TEAM_LEAD`
- `MANAGER`
- `ADMIN`

## Notifications

Version 1:

- In-app notifications
- Push notifications

Do NOT add transactional email infrastructure.

## Scheduling

Use only lightweight scheduling compatible with FastAPI.

Do NOT introduce:

- Separate worker service
- Message queue
- n8n
- Redis job queue
- Dedicated background-processing infrastructure

---

# 5. Non-Negotiable Architecture

Use:

```text
Flutter Mobile App
        |
      HTTPS
        |
        v
FastAPI Backend
        |
        +-- Authentication / RBAC
        +-- Case Management
        +-- Business Logic
        +-- AI Integration
        +-- SLA / Escalation
        +-- Notifications
        +-- Audit Trail
        +-- Lightweight Scheduler
        |
        +--------> PostgreSQL / Supabase
        |
        +--------> File Storage

External Services
        +--------> AI API
        +--------> Push Notification Service
```

FastAPI owns:

- Authentication
- Authorization
- RBAC
- Business logic
- Case workflow
- AI integration
- SLA engine
- Escalation rules
- Notifications
- Audit logging
- Lightweight scheduling
- Validation
- Error handling

Flutter must not become the source of truth for business rules.

---

# 6. Critical Product Rules

Never violate these rules:

## Real Data

Do not use:

- Hardcoded cases
- Fake dashboard numbers
- Fake login behavior
- Static AI responses presented as real AI
- Disconnected screens
- UI-only permissions
- Fake notifications

All important actions must create real persistent backend state.

## Backend RBAC

Hiding a button in Flutter is NOT authorization.

Every protected operation must be checked by FastAPI.

Example:

A Requester must never be able to access Operator internal notes by modifying a client request.

## AI Human Control

AI recommendations must support:

- Accept
- Edit
- Reject
- Override

The final decision remains with authorized humans.

## AI Failure

If AI is unavailable, the application must still support:

- Case creation
- Case viewing
- Assignment
- Updates
- Communication
- Investigation
- Resolution

## Internal Notes

Internal notes are staff-only.

They must never be visible to Requesters.

## Case History

Never destroy meaningful historical information.

Status changes, assignment changes, AI decisions, investigations, resolutions, reopening, etc. must remain traceable.

---

# 7. Development Strategy

Build in this order:

```text
Phase 0 — Repository inspection
Phase 1 — Product/UI design system
Phase 2 — Project foundation
Phase 3 — Database and models
Phase 4 — Authentication and RBAC
Phase 5 — Requester experience
Phase 6 — Operator experience
Phase 7 — Team Lead experience
Phase 8 — Manager experience
Phase 9 — Admin experience
Phase 10 — Case lifecycle and workflow engine
Phase 11 — AI integration
Phase 12 — SLA/risk/escalation
Phase 13 — Notifications
Phase 14 — File/evidence handling
Phase 15 — Timeline and audit
Phase 16 — Full E2E integration
Phase 17 — Testing
Phase 18 — Local production-like validation
Phase 19 — Deployment preparation
```

**Do not skip phases.**

At the end of every phase:

1. Run relevant tests.
2. Run/build the application where possible.
3. Fix errors.
4. Review against PRD/SRS.
5. Update project documentation.
6. Only then move to the next phase.

---

# 8. Phase 0 — Inspect Before Coding

Before writing code:

1. Inspect the entire repository.
2. Identify:
   - Existing Flutter project
   - Existing FastAPI project
   - Existing database code
   - Existing configuration
   - Existing tests
   - Existing documentation
3. Identify what is already implemented.
4. Do not overwrite working functionality unnecessarily.
5. Identify missing requirements.
6. Create a short implementation status report.

The status report should contain:

```text
Already implemented
Partially implemented
Missing
Needs refactor
Needs testing
```

Then create/update:

```text
Docs/IMPLEMENTATION_PLAN.md
```

---

# 9. Phase 1 — UI/UX Design Using Stitch MCP

## Goal

Create a professional, coherent, role-based Flutter UI based on the PRD/SRS.

Use **Stitch MCP** for UI/UX generation where available.

### Important

Stitch is a UI/UX design aid.

It must not change:

- Product requirements
- Roles
- Backend ownership
- Security rules
- Case lifecycle
- Data model
- AI human-control rules

## Design Before Implementation

First generate the design system.

Define:

- Color system
- Typography
- Spacing
- Border radius
- Buttons
- Cards
- Inputs
- Chips
- Status badges
- Navigation
- App bars
- Bottom navigation
- Dialogs
- Bottom sheets
- Tables/lists where appropriate
- Loading states
- Empty states
- Error states
- Confirmation states

The UI must look like one product.

Do not generate five unrelated visual styles for five roles.

---

# 10. Required UI/UX Screens

Design role-specific journeys.

## Shared

- Splash/loading
- Login
- Registration
- Profile
- Notifications
- Error states
- Empty states

## Requester

- Requester dashboard
- My cases
- Create case
- Case details
- Evidence upload
- Conversation
- Information request
- Resolution proposal
- Confirm resolution
- Reject resolution
- Reopened case
- Notifications

## Operator

- Operator dashboard
- Case queue
- Case details
- AI analysis panel
- Assignment
- Communication
- Internal notes
- Tasks
- Investigation
- SLA/risk
- Escalation
- Resolution
- Timeline

## Team Lead

- Team dashboard
- Team workload
- At-risk cases
- Escalations
- Unassigned cases
- Operator workload
- Reassignment/intervention
- Case details

## Manager

- Organization dashboard
- Total/active/resolved cases
- SLA performance
- Average resolution time
- Escalations
- Reopened cases
- Trends
- Team performance
- Category performance
- Operational insights

## Admin

- Admin dashboard
- Users
- Teams
- Categories
- SLA policies
- Organization settings
- Audit history

---

# 11. Stitch MCP Workflow

When using Stitch MCP:

### Step 1

Give Stitch the product context:

```text
Design a professional mobile-first Office IT Help Desk application.

The application has five roles:
Requester, Operator, Team Lead, Manager, Admin.

The product manages:
Employee → Case → Evidence → AI Understanding → Assignment →
Communication → Investigation → Tasks → SLA → Risk →
Escalation → Resolution → Confirmation → Analytics → Audit.

AI provides recommendations but humans make important decisions.

Use a consistent enterprise IT-support design system.
```

### Step 2

Generate the shared design system.

### Step 3

Generate screens role-by-role.

Order:

1. Authentication
2. Requester
3. Operator
4. Team Lead
5. Manager
6. Admin

### Step 4

For every screen verify:

- Correct role
- Correct actions
- Correct information
- Loading state
- Empty state
- Error state
- Success state
- Mobile responsiveness
- Accessibility
- Consistent terminology

### Step 5

Translate approved Stitch designs into Flutter.

Do not blindly copy generated code if it conflicts with the architecture.

---

# 12. Phase 2 — Project Foundation

Set up:

```text
/frontend or /mobile
/backend
/docs
/tests
```

Use the repository's existing structure if it is already established.

Configure:

- Environment variables
- `.env.example`
- API base URL
- Database URL
- JWT/auth configuration
- AI configuration
- Storage configuration
- Push notification configuration

Never commit real secrets.

---

# 13. Phase 3 — Database and Core Models

Design persistent entities for at least:

- Users
- Roles
- Teams
- Cases
- Categories
- Assignments
- Conversations
- Internal Notes
- Tasks
- Investigation Updates
- Attachments/Evidence
- AI Analyses
- AI Recommendations
- SLA/Policy Information
- Risk Records
- Escalations
- Resolutions
- Requester Confirmations
- Notifications
- Timeline Events
- Audit Records
- Organization Settings

Preserve meaningful relationships between entities.

A Case can have multiple:

- Communications
- Notes
- Tasks
- Investigations
- Attachments
- AI analyses
- Timeline events
- Notifications
- Audit records

Use migrations.

Do not manually create production-only database state.

---

# 14. Phase 4 — Authentication and RBAC

Implement:

- Registration
- Login
- Password hashing
- Token authentication
- Protected APIs
- User profile
- Role authorization

Roles:

```text
REQUESTER
OPERATOR
TEAM_LEAD
MANAGER
ADMIN
```

Backend must enforce permissions.

Create tests for:

- Valid login
- Invalid login
- Unauthorized API access
- Role access
- Cross-role access rejection
- Protected resource access

---

# 15. Phase 5 — Requester Experience

Implement real requester functionality.

Requester can:

1. Create case
2. Add title
3. Add description
4. Select optional category
5. Add office/location
6. Upload evidence
7. Receive unique case number
8. View authorized cases
9. View case details
10. Respond to information requests
11. Receive in-app/push updates
12. View proposed resolution
13. Confirm resolution
14. Reject resolution
15. See reopened case if resolution is rejected

Case number example:

```text
IT-10482
```

All data must persist.

---

# 16. Phase 6 — Operator Experience

Implement:

- Operator dashboard
- Case queue
- New cases
- Assigned cases
- High-priority cases
- At-risk cases
- Waiting-for-information cases
- Escalated cases
- Pending tasks

Operator case detail must provide:

- Original report
- Evidence
- AI analysis
- Assignment
- Communication
- Internal notes
- Tasks
- Investigation
- SLA
- Risk
- Escalation
- Resolution
- Timeline

Operator must be able to:

- Review AI recommendations
- Accept recommendation
- Edit recommendation
- Reject recommendation
- Override recommendation
- Assign/reassign
- Ask for information
- Add internal note
- Create task
- Record investigation
- Update status
- Submit resolution

---

# 17. Phase 7 — Team Lead

Implement:

- Team workload
- Priorities
- At-risk cases
- Escalations
- Unassigned cases
- Deadlines
- Operator workload
- Resolution performance

Team Lead can intervene or reassign only where backend authorization allows.

---

# 18. Phase 8 — Manager

Implement organization-level operational visibility:

- Total cases
- Active cases
- Resolved cases
- SLA performance
- Average resolution time
- Escalations
- Reopened cases
- Trends
- Team performance
- Category performance
- Operational insights

All dashboard values must come from real persistent backend data.

Never hardcode numbers.

---

# 19. Phase 9 — Admin

Implement:

- Users
- Teams
- Categories
- SLA policies
- Organization settings
- Audit history

Protect all admin APIs with backend RBAC.

---

# 20. Phase 10 — Case Lifecycle Engine

Implement the primary lifecycle:

```text
Reported
    ↓
Understood
    ↓
Assigned
    ↓
Investigating
    ↓
Action Taken
    ↓
Resolution Proposed
    ↓
Confirmed
    ↓
Closed
```

Support alternate/temporary states:

- Waiting for Information
- Escalated
- Duplicate
- Reopened
- Cancelled

The backend must control valid transitions.

Never allow Flutter to directly decide whether a transition is valid.

Rejected resolution:

```text
Resolution Proposed
        ↓
Requester Rejects
        ↓
Reopened
        ↓
Continue investigation/action
```

Preserve history.

---

# 21. Phase 11 — AI Integration

AI must be integrated through FastAPI.

## Automatic Case Analysis

Support:

- Likely category
- Severity
- Priority
- Missing information
- Related cases
- Suggested team
- Recommended next action

## AI Summary

Maintain summary covering:

- What was reported
- What happened
- What was confirmed
- What remains unresolved
- Current blocker

## Missing Information

AI can identify missing information and suggest questions.

Operator reviews before sending.

## Related/Duplicate

AI may identify potential duplicates.

Never automatically merge cases.

Operator makes the final decision.

## Assignment Recommendation

Consider:

- Issue type
- Team responsibility
- Workload
- Availability
- Location
- Previous cases

Operator or Team Lead can override.

## Risk

Detect:

- Inactivity
- Repeated follow-ups
- Reassignments
- Missing information
- Approaching deadlines
- Reopening
- Unusually long resolution time

Risk warnings must explain their reason.

## Communication Drafting

AI can draft:

- Information requests
- Progress updates
- Resolution messages
- Escalation summaries

Operator reviews/edits before sending.

## Operational Insights

Analyze multiple cases for:

- Repeated network issues
- Repeated printer issues
- Location trends
- Long resolution times
- Repeated escalations

---

# 22. AI Output Rules

Never present an AI recommendation as a confirmed fact.

Use UI labels such as:

```text
AI Recommendation
AI Suggested
AI Detected
Needs Review
Confirmed
```

Make human control visible.

Example:

```text
AI suggests:
Team: Network Support
Priority: High
Reason: Internet connectivity issue

[Accept] [Edit] [Reject]
```

Do not automatically apply the recommendation unless the business rule explicitly permits it.

---

# 23. AI Failure Handling

If AI API fails:

- Show a clear non-blocking message
- Keep case available
- Allow manual assignment
- Allow manual investigation
- Allow communication
- Allow resolution

Example UI:

```text
AI analysis is temporarily unavailable.
You can continue handling this case manually.
```

Never make the entire case system unusable because AI failed.

---

# 24. Phase 12 — SLA, Risk and Escalation

Implement:

- SLA information
- Deadline tracking
- Time-based checks
- Risk checks
- Deadline warnings
- Escalation conditions
- Team Lead intervention

Escalation can be triggered by:

- Approaching deadline
- Missed deadline
- Serious issue
- Repeated unresolved complaint
- Operator request
- High-risk condition

Use lightweight scheduling.

Do not create a worker architecture.

---

# 25. Phase 13 — Notifications

Support notifications for:

- New case
- Assignment
- Requester response
- New task
- SLA warning
- Escalation
- Resolution
- Reopening

Version 1 channels:

- In-app
- Push

Do not add email notification infrastructure.

Notification failure must not break core case management.

---

# 26. Phase 14 — Evidence and File Handling

Support:

- Images
- Screenshots
- Documents

Every uploaded file must:

- Belong to the correct case/activity
- Respect RBAC
- Be inaccessible to unauthorized users
- Use suitable object/file storage for large files

Do not store large binary data directly in PostgreSQL when object storage is appropriate.

---

# 27. Phase 15 — Timeline and Audit

## Timeline

Maintain a chronological case story.

Record meaningful events such as:

- Case creation
- Assignment
- Reassignment
- Priority changes
- Status changes
- AI recommendations
- AI overrides
- Information requests
- Requester responses
- Task events
- Investigation updates
- Escalations
- Resolution
- Reopening
- Closure

## Audit Trail

Capture:

- Actor/user
- Action
- Entity/case
- Previous value where appropriate
- New value where appropriate
- Timestamp
- Relevant context

AI recommendations and human overrides should be traceable where appropriate.

Normal users must not casually edit/delete audit records.

Admin can access authorized audit history.

---

# 28. Phase 16 — Complete E2E Workflow

The most important validation scenario is:

## Office Wi-Fi Issue

Requester reports:

> My laptop is connected to Wi-Fi but I cannot access the internet.

Execute:

1. Requester creates case.
2. Requester uploads screenshot/evidence.
3. AI analyzes case.
4. AI suggests Network Support.
5. Operator reviews recommendation.
6. AI identifies missing office/location information.
7. Operator requests information.
8. Requester responds.
9. Operator creates investigation task.
10. Investigation is performed.
11. Findings are recorded.
12. SLA/risk monitoring runs.
13. Team Lead reviews/intervenes if required.
14. Issue is fixed.
15. Resolution evidence is uploaded.
16. Operator submits resolution.
17. Requester confirms.
18. Case closes.
19. Manager reviews analytics.
20. Admin reviews audit history.

Every step must use real backend state.

---

# 29. Phase 17 — Testing

## Unit Tests

Test:

- Business logic
- SLA calculations
- Escalation rules
- Validation
- Permissions
- Workflow transitions

## API/Integration Tests

Test:

- Authentication
- RBAC
- Case creation
- Assignment
- Communication
- Tasks
- Investigation
- Resolution
- Reopening
- Notifications
- Audit logging

## AI Integration Tests

Test:

- Successful AI response
- Invalid AI response
- Timeout
- Service unavailable

Verify that core case management still works when AI fails.

## E2E Tests

Use separate accounts:

```text
Requester
Operator
Team Lead
Manager
Admin
```

All tests must use real persistent backend state.

---

# 30. UI Quality Requirements

Every major screen must have:

## Loading State

Example:

```text
Loading cases...
```

Use skeletons/progress indicators where appropriate.

## Empty State

Example:

```text
No active cases
Create a case when you need IT support.
```

## Error State

Example:

```text
Something went wrong.
Please try again.
```

## Success Feedback

Show appropriate confirmation after important actions.

## Professional UX

Use:

- Consistent spacing
- Consistent typography
- Clear hierarchy
- Accessible controls
- Clear status colors
- Meaningful icons
- Good mobile layouts
- Confirmation for destructive actions

---

# 31. Role-Based Navigation

Navigation must change according to role.

Do not show irrelevant privileged features to normal users.

However:

> UI visibility is only a usability feature. Backend authorization remains mandatory.

Requester should not see:

- Internal notes
- Admin controls
- Organization audit management
- Operator-only controls

Operator should not automatically receive Admin capabilities.

Manager should receive organization-level visibility appropriate to the SRS.

---

# 32. API Design Principles

Use REST APIs.

Maintain consistent:

- HTTP status codes
- Request validation
- Response models
- Error format
- Authentication
- Authorization

Provide:

```http
GET /api/health
```

The health endpoint must be usable for local/deployment verification.

---

# 33. Error Handling

FastAPI must provide:

- Centralized exception handling
- Validation errors
- Consistent API errors
- Logging
- Suitable retries where applicable
- Timeout handling
- AI failure handling
- Notification failure handling
- Database error handling

External-service failures must not unnecessarily break core case management.

---

# 34. Logging

Log important events:

- Authentication failures
- API errors
- AI failures
- Notification failures
- Scheduler execution
- SLA processing errors
- Database errors
- Important system events

Never log:

- Passwords
- Authentication tokens
- API keys
- Sensitive credentials

---

# 35. Environment and Secrets

Provide:

```text
.env.example
```

Possible configuration:

```text
DATABASE_URL
JWT_SECRET
AI_API_KEY
STORAGE_CREDENTIALS
PUSH_NOTIFICATION_CREDENTIALS
```

Never commit real secrets.

Never place private server credentials inside Flutter.

---

# 36. Documentation

Maintain:

```text
README.md
Docs/IMPLEMENTATION_PLAN.md
Docs/ARCHITECTURE.md
Docs/API.md
Docs/TESTING.md
Docs/DEPLOYMENT.md
Docs/UI_UX.md
```

Update documentation after major phases.

---

# 37. Progress Tracking

Maintain a checklist:

```text
[ ] Phase 0 — Repository inspection
[ ] Phase 1 — Stitch UI/UX
[ ] Phase 2 — Project foundation
[ ] Phase 3 — Database
[ ] Phase 4 — Authentication/RBAC
[ ] Phase 5 — Requester
[ ] Phase 6 — Operator
[ ] Phase 7 — Team Lead
[ ] Phase 8 — Manager
[ ] Phase 9 — Admin
[ ] Phase 10 — Case lifecycle
[ ] Phase 11 — AI
[ ] Phase 12 — SLA/risk/escalation
[ ] Phase 13 — Notifications
[ ] Phase 14 — Files/evidence
[ ] Phase 15 — Timeline/audit
[ ] Phase 16 — E2E
[ ] Phase 17 — Testing
[ ] Phase 18 — Local validation
[ ] Phase 19 — Deployment preparation
```

Mark a phase complete only when:

- Code exists
- Feature works
- Relevant tests pass
- UI works
- Backend rules work
- Data persists
- Errors are handled
- Documentation is updated

---

# 38. Definition of Done

A feature is NOT complete because:

```text
Screen exists
```

A feature is complete only when:

```text
UI
 ↓
Flutter action
 ↓
FastAPI API
 ↓
Validation
 ↓
Authorization
 ↓
Business logic
 ↓
Database/file state
 ↓
Response
 ↓
UI update
 ↓
Timeline/audit where required
 ↓
Notification where required
 ↓
Tests
```

The complete behavior must work.

---

# 39. What Antigravity Must NOT Do

Do not:

- Replace Flutter with another frontend framework
- Replace FastAPI without approval
- Replace PostgreSQL/Supabase without approval
- Put AI API keys in Flutter
- Put business rules only in Flutter
- Use fake dashboard data
- Use fake login
- Use static AI results and call them real AI
- Automatically merge duplicate cases
- Expose internal notes to Requesters
- Add email notifications to Version 1
- Add n8n
- Add Redis job queues
- Add a separate worker service
- Add unnecessary microservices
- Build disconnected demo screens
- Skip backend RBAC
- Skip error/loading/empty states
- Skip persistent database state
- Skip tests
- Deploy before the local E2E workflow works

---

# 40. Development Command Discipline

Before running commands:

1. Check the current directory.
2. Check existing files.
3. Do not delete project files without a reason.
4. Do not overwrite configuration containing real secrets.
5. Prefer small, reversible changes.
6. Run formatting/linting after meaningful code changes.
7. Run tests after meaningful backend changes.
8. Build/run Flutter after meaningful UI changes.

If a command fails:

1. Read the complete error.
2. Identify root cause.
3. Fix the root cause.
4. Re-run the command.
5. Do not hide or ignore errors.

---

# 41. Antigravity Operating Loop

For every phase use:

```text
UNDERSTAND
    ↓
INSPECT
    ↓
PLAN
    ↓
DESIGN
    ↓
IMPLEMENT
    ↓
TEST
    ↓
VERIFY
    ↓
DOCUMENT
    ↓
REPORT
    ↓
NEXT PHASE
```

Never jump directly from requirement to large-scale coding.

---

# 42. Phase Report Format

At the end of every phase, report:

```text
PHASE:
STATUS:

Implemented:
- ...

Files changed:
- ...

Tests:
- ...

Verification:
- ...

Known issues:
- ...

PRD/SRS requirements covered:
- ...

Next phase:
- ...
```

Keep this report concise but factual.

---

# 43. First Task for Antigravity

Before implementing any feature, do exactly this:

### Task 1

Read:

```text
AI_Office_IT_Help_Desk_PRD_No_Email.md
AI_Office_IT_Help_Desk_SRS_No_Email(1).md
```

### Task 2

Inspect the complete repository.

### Task 3

Create:

```text
Docs/IMPLEMENTATION_PLAN.md
```

with:

- Existing architecture
- Existing features
- Missing features
- Phase plan
- Risks
- Testing plan

### Task 4

Do not start backend implementation yet.

First prepare the UI/UX plan using Stitch MCP.

### Task 5

Generate the shared Stitch design system.

### Task 6

Generate the Requester journey first.

### Task 7

After the Requester UI is approved/validated, continue with:

```text
Operator
Team Lead
Manager
Admin
```

### Task 8

Only after the role-based UI structure is understood, implement the corresponding Flutter screens.

### Task 9

Connect those screens to real FastAPI APIs.

### Task 10

Continue phase-by-phase until the complete E2E workflow works.

---

# 44. Important Instruction About Stitch MCP

When Stitch MCP is available, use it to accelerate UI/UX design, but keep the PRD/SRS as the source of truth.

The UI must communicate the product's actual workflow.

For example, the Operator case screen should make it easy to understand:

```text
Case
 ├── Report
 ├── Evidence
 ├── AI Analysis
 ├── Assignment
 ├── Conversation
 ├── Internal Notes
 ├── Tasks
 ├── Investigation
 ├── SLA
 ├── Risk
 ├── Escalation
 ├── Resolution
 └── Timeline
```

Do not design a generic help-desk UI that lacks these product-specific concepts.

---

# 45. Final Acceptance Checklist

Before declaring the project complete, verify:

## Product

- [ ] Complete case lifecycle
- [ ] Real multi-user workflow
- [ ] Five roles
- [ ] Human-controlled AI
- [ ] Persistent data
- [ ] Evidence handling
- [ ] Communication
- [ ] Tasks
- [ ] Investigation
- [ ] SLA
- [ ] Risk
- [ ] Escalation
- [ ] Resolution confirmation
- [ ] Analytics
- [ ] Audit

## Frontend

- [ ] Flutter
- [ ] Professional UI
- [ ] Role-based journeys
- [ ] Loading states
- [ ] Empty states
- [ ] Error states
- [ ] Responsive mobile UI
- [ ] Consistent design system

## Backend

- [ ] FastAPI
- [ ] Authentication
- [ ] Token security
- [ ] Backend RBAC
- [ ] Case workflow rules
- [ ] AI integration
- [ ] SLA logic
- [ ] Escalation logic
- [ ] Notifications
- [ ] Audit
- [ ] Validation
- [ ] Error handling
- [ ] `/api/health`

## Database

- [ ] PostgreSQL/Supabase
- [ ] Persistent data
- [ ] Relationships
- [ ] Migrations
- [ ] No fake dashboard data

## AI

- [ ] Case analysis
- [ ] Summary
- [ ] Missing information
- [ ] Related/duplicate detection
- [ ] Assignment recommendation
- [ ] Risk analysis
- [ ] Communication drafting
- [ ] Operational insights
- [ ] Human override
- [ ] Failure fallback

## Security

- [ ] Password hashing
- [ ] Protected APIs
- [ ] Backend RBAC
- [ ] Secure file access
- [ ] Secrets outside source code
- [ ] No AI keys in Flutter
- [ ] No secrets committed to Git

## Architecture

- [ ] No separate worker for Version 1
- [ ] No message queue
- [ ] No n8n
- [ ] No Redis job queue
- [ ] Lightweight scheduler only

## Testing

- [ ] Unit tests
- [ ] API/integration tests
- [ ] AI failure tests
- [ ] E2E tests
- [ ] Five real test accounts
- [ ] Complete Office Wi-Fi demo scenario

---

# 46. Final Instruction

Build the product as a real connected system.

Do not optimize for:

```text
"the screen looks complete"
```

Optimize for:

```text
"the workflow actually works"
```

The final system must demonstrate:

```text
Employee
   ↓
Real Case
   ↓
Evidence
   ↓
AI Understanding
   ↓
Human Review
   ↓
Assignment
   ↓
Communication
   ↓
Investigation
   ↓
Tasks
   ↓
SLA / Risk
   ↓
Escalation
   ↓
Resolution
   ↓
Requester Confirmation
   ↓
Analytics
   ↓
Audit
```

Follow:

**Build locally → Test locally → Complete E2E workflow → Prepare production configuration → Deploy**

Version 1 must remain:

**Simple + Realistic + Maintainable + Production-minded**

