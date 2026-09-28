---
name: Autonomous IT Desk
colors:
  surface: '#faf8ff'
  surface-dim: '#d2d9f4'
  surface-bright: '#faf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f3ff'
  surface-container: '#eaedff'
  surface-container-high: '#e2e7ff'
  surface-container-highest: '#dae2fd'
  on-surface: '#131b2e'
  on-surface-variant: '#434655'
  inverse-surface: '#283044'
  inverse-on-surface: '#eef0ff'
  outline: '#737686'
  outline-variant: '#c3c6d7'
  surface-tint: '#0053db'
  primary: '#004ac6'
  on-primary: '#ffffff'
  primary-container: '#2563eb'
  on-primary-container: '#eeefff'
  inverse-primary: '#b4c5ff'
  secondary: '#712ae2'
  on-secondary: '#ffffff'
  secondary-container: '#8a4cfc'
  on-secondary-container: '#fffbff'
  tertiary: '#006243'
  on-tertiary: '#ffffff'
  tertiary-container: '#007d57'
  on-tertiary-container: '#bdffdc'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dbe1ff'
  primary-fixed-dim: '#b4c5ff'
  on-primary-fixed: '#00174b'
  on-primary-fixed-variant: '#003ea8'
  secondary-fixed: '#eaddff'
  secondary-fixed-dim: '#d2bbff'
  on-secondary-fixed: '#25005a'
  on-secondary-fixed-variant: '#5a00c6'
  tertiary-fixed: '#85f8c4'
  tertiary-fixed-dim: '#68dba9'
  on-tertiary-fixed: '#002114'
  on-tertiary-fixed-variant: '#005137'
  background: '#faf8ff'
  on-background: '#131b2e'
  surface-variant: '#dae2fd'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 30px
    fontWeight: '700'
    lineHeight: 38px
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-sm: 0.75rem
  margin: 1rem
  margin-sm: 0.75rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

The design system establishes a high-precision, utilitarian operational environment for enterprise IT operations. It balances corporate dependability with intelligent automation, projecting authority, responsiveness, and zero-defect clarity. The target users are corporate employees submitting mission-critical incidents and tier 1–3 IT support engineers handling rapid triage, diagnostics, and hardware provisioning.

The visual style blends **Corporate Modernism** with **Analytical High-Contrast**:
- **Cognitive Clarity:** Dense operational telemetry presented without clutter. Surfaces maintain neutral breathing room to keep incident escalations legible during high-stress outages.
- **Trust Architecture:** Explicit semantic visual segregation between automated machine intelligence (AI predictions, triage telemetry) and human-authored operational commands.
- **Tactile Precision:** Fine-line boundaries, calibrated micro-radii, and controlled tap targets optimized for rapid single-handed thumb interactions in mobile fleet deployments.

## Colors

The palette uses strict semantic roles to ensure instant comprehension of IT incident severity, automation provenance, and security boundaries.

### Core Foundation
- **Primary (`#2563EB`)**: Technical azure blue used for core interactive elements, active navigation states, primary triggers, and high-priority system affordances.
- **Secondary / AI Provenance (`#7C3AED`)**: Precision violet dedicated exclusively to machine-generated insights, root-cause recommendations, suggested KB remediations, and automated triage summaries. Never use this for standard human system states.
- **Tertiary / Success (`#059669`)**: Mint emerald green for resolved ticket SLAs, healthy infrastructure nodes, certified hardware checks, and verified credentials.
- **Neutral Dark / On-Canvas (`#0F172A`)**: Deep slate navy serving as primary text, dark chrome, and grounding surface containers.

### Functional Status & Incident Severity
- **Warning & SLA Risk (`#D97706`)**: High-visibility amber orange for pending vendor replies, breaches approaching within 30 minutes, and degraded internal services.
- **Critical & Blocker (`#DC2626`)**: Uncompromising crimson for P1 incidents, SLA expirations, unreachable gateways, and credential revocations.

### Surface Architecture & Security Contexts
- **Base Canvas (`#F8FAFC`)**: Ultra-clean cool grey-white that prevents screen glare during prolonged shifts.
- **Elevated Card Surface (`#FFFFFF`)**: Pure white containers with crisp structural borders (`#E2E8F0`).
- **Public Communications Stream**: Canvas remains neutral white with subtle primary borders to designate requester-facing visibility.
- **Internal Private Notes**: Warm amber/slate tinted surface (`#FFFBEB` with `#FDE68A` border) combined with an explicit security lock badge to prevent accidental public disclosure of root passwords or administrative diagnostic notes.

## Typography

Typography relies on **Inter** across all levels, configured to deliver programmatic precision and neutral legibility under varied mobile field conditions.

### Typesetting Principles
- **Tabular Figures for Identifiers:** All ticket IDs (e.g., `#INC-8921`), SLA countdown timers, IP addresses, and performance metrics must use `FontFeature.tabularFigures()` to prevent visual jitter when status feeds refresh.
- **Tight Micro-Headings:** Section labels and ticket metadata headers use `label-sm` with explicit uppercase tracking (`letter-spacing: 0.05em`) to structure dense operational modules cleanly.
- **High-Density Body Copy:** `body-md` is the primary workhorse for ticket conversations and technical logs, set at a 1.42 line-height ratio to maximize information density without sacrificing scanning speed.

## Layout & Spacing

The layout model is built around a predictable 4px/8px incremental grid tailored for standard enterprise handheld devices.

### Layout Mechanics
- **Mobile Handheld (Screen width < 600dp):** Fluid single-column architecture bounded by `margin` (16px) side paddings. Primary action bars and SLA countdown rails stick to the bottom viewport with an intrinsic safe-area inset.
- **Tablet Split-Pane (Screen width >= 600dp):** The layout transitions to a permanent master-detail 40/60 split-pane. Left pane hosts the incident queue; right pane displays the active thread, telemetry timeline, and AI diagnostic panel.
- **Vertical Rhythm:** Components stack with uniform `space-md` gaps. Sub-items inside cards and diagnostic rows use `space-xs` and `space-sm` for immediate grouping proximity.
- **Touch Ergonomics:** All interactive buttons, chips, and list selections enforce a minimum 48x48dp tappable hitbox, regardless of physical visual glyph size.

## Elevation & Depth

Visual hierarchy relies on structural borders and subtle ambient diffusion rather than deep physical drops, creating a sharp, low-latency enterprise feel.

### Elevation Hierarchy
- **Level 0 (Base Canvas):** Flat `#F8FAFC`. Zero elevation.
- **Level 1 (Default Cards & Tiles):** Surface `#FFFFFF` encased in a crisp 1px solid stroke of `#E2E8F0`. Shadow is purely ambient: `0px 1px 3px rgba(15, 23, 42, 0.06)`.
- **Level 2 (Active Modals & Drawers):** Floating triage filter sheets, resolution prompt dialogs, and bottom sheets. Encased in a 1px stroke of `#CBD5E1` with a diffuse shadow: `0px 8px 24px -4px rgba(15, 23, 42, 0.12)`.
- **Level 3 (AI Insight Containers):** Distinctive 1px layered border tinted in `#DDD6FE` (violet-200) paired with a high-register glow shadow: `0px 2px 10px rgba(124, 58, 237, 0.08)`.
- **Internal Note Elevation:** Embedded within conversation trees using a 1px dashed perimeter (`#FCD34D`) and a flat, non-elevated `#FFFBEB` fill to signal a distinct internal-only security state.

## Shapes

The geometric signature uses modern, controlled radii (`roundedness: 2` / 8px standard) that balance clean technical architecture with tactile mobile comfort.

### Corner Archetypes
- **Standard Controls & Cards (`0.5rem` / 8px):** Form fields, standard cards, contextual chips, and buttons use an 8px radius to keep density high.
- **Dialogs & Bottom Sheets (`rounded-lg` / 1rem / 16px):** Sheet corners and modal surfaces use 16px top-radii for deliberate sheet anchoring.
- **Pill Indicators (`9999px`):** Status indicator tags, priority badges, and count markers use fully pill-shaped radii to separate metadata tags from tappable rectangular targets.

## Components

### Buttons
- **Primary Command:** Solid `#2563EB` fill, `#FFFFFF` text, 48px height, 8px radius. Active tap state triggers a subtle scale compression (0.98x) and deepens to `#1D4ED8`.
- **AI Action Triggers:** Solid `#7C3AED` fill with an embedded sparkle icon or translucent violet wash (`#7C3AED` at 10% opacity with `#7C3AED` solid text and border) for secondary assistive prompts ("Auto-triage with AI", "Draft Resolution").
- **Destructive/Revoke:** Outlined or solid `#DC2626` strictly for closing tickets without resolution, remote-wiping enterprise devices, or rolling back configurations.

### Segmented Chips & Status Pills
- **Incident Status Pills:** Compact 24px height with pill radius. Composed of a 6px solid status dot and semantic text:
  - *Resolved:* `#ECFDF5` background, `#059669` label, `#059669` dot.
  - *SLA Risk / Pending:* `#FFFBEB` background, `#D97706` label, `#D97706` dot.
  - *Critical / Escalated:* `#FEF2F2` background, `#DC2626` label, `#DC2626` dot.
- **Segmented Filter Bar:** Full-width container with `#F1F5F9` track fill; selected segment transitions to `#FFFFFF` with a crisp 1px `#CBD5E1` border and 0 1px 2px drop.

### Cards & Ticket Modules
- **Queue Item Card:** High-contrast 8px-radius white container. Top bar aligns ticket ID, SLA countdown timer, and requester avatar. Middle row renders incident title (`label-lg`) truncated to two lines. Bottom row stacks priority badges and device tags.
- **AI Recommendation Module:** Enclosed in a pale violet gradient fill (`#FAF5FF` to `#FFFFFF`) with a 1px solid `#DDD6FE` border. Includes a 12px pill header ("AI Diagnosis") in `#7C3AED` and accepts binary feedback actions (thumbs up/down) to refine automated triage models.

### Communications Thread
- **Requester Bubble:** Left-aligned `#F1F5F9` neutral surface with dark slate body text.
- **Technician Response:** Right-aligned `#EFF6FF` soft azure surface with a 1px solid `#BFDBFE` outline.
- **Internal Note:** Full-width container featuring a `#FFFBEB` amber-tinted background, 1px dashed `#FCD34D` boundary, and a persistent lock icon header reading `INTERNAL ONLY - RESTRICTED FROM REQUESTER`.

### Input Fields
- **Search & Diagnostic Prompt:** 44px height, 8px radius, background `#F8FAFC`, border 1px solid `#CBD5E1`. On focus, transitions to `#FFFFFF` with a 2px `#2563EB` active ring. Includes trailing mic/barcode scanner icons for physical asset inventory lookups.
- **Ticket Reply Dock:** Persistent bottom bar with seamless switching between "Public Reply" and "Internal Note" via an explicit safety toggle switch.