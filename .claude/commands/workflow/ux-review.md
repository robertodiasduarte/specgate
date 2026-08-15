# UX Review Command

> Review UX/CX direction after DEFINE and before technical DESIGN

## Usage

```bash
/ux-review <define-file>
```

## Examples

```bash
/ux-review .claude/sdd/features/DEFINE_CUSTOMER_DASHBOARD.md
/ux-review DEFINE_CHECKOUT_FLOW.md
/ux-review .claude/sdd/features/DEFINE_ONBOARDING.md
```

---

## Overview

This command is the **UX/CX gate between Define and Design**:

```text
Phase 0: /brainstorm  -> .claude/sdd/features/BRAINSTORM_{FEATURE}.md (optional)
Phase 1: /define      -> .claude/sdd/features/DEFINE_{FEATURE}.md
UX Gate: /ux-review   -> .claude/sdd/reviews/UX_REVIEW_{FEATURE}.md (THIS COMMAND)
Phase 2: /design      -> .claude/sdd/features/DESIGN_{FEATURE}.md
Phase 3: /build       -> Code + .claude/sdd/reports/BUILD_REPORT_{FEATURE}.md
Phase 4: /release     -> production + ledger .claude/sdd/releases/
```

The `/ux-review` command translates requirements into user experience guidance before architecture and implementation decisions harden.

---

## North Star Principles (inviolable)

These 2 principles are the product's quality ceiling. Any MUST/SHOULD/COULD recommendation that violates one of them is automatically promoted to a blocking MUST.

### 1. Premium feel

The reference is the "inevitable, calm, confident" sensation of a best-in-class native app. It is not a visual style — it is a standard of perceived quality.

| Dimension | What premium means |
|-----------|--------------------|
| **Visual confidence** | Obvious hierarchy within 200ms; the eye knows where to land first |
| **Calibrated density** | Space breathes; nothing looks like a "pile of admin UI" |
| **Typography** | Weights and sizes with purpose; never 5 different sizes on the same surface |
| **Motion** | Short transitions (150-250ms), ease-out, ⛔ never decorative bounces |
| **Microinteractions** | Hover, focus, active, disabled — all deliberate, none forgotten |
| **Surfaces** | Canonical semantic surface buckets (hero/neutral/fallback), never a "generic white card with border-radius". A flat surface can be correct for a given theme; what you avoid is a generic surface with no semantic voice |
| **Empty states** | Empty states are an opportunity for delight, not an ugly placeholder |
| **Final polish** | The feature looks "shipped", not "an MVP we'll polish later" |

The current design-system baseline is the **floor**, not the ceiling.

### 2. If you have to explain it, it's wrong

Good UX does not need user support. Tooltips, helper text, an FAQ, a support message explaining "how it works" — all are a symptom, not a solution.

| Anti-pattern | What it reveals |
|--------------|-----------------|
| **Tooltip-as-crutch** | If an affordance needs a tooltip to be understood, redo the affordance |
| **Helper text stating the obvious** | "Click here to submit" under a "Submit" button = the button is wrong |
| **Ambiguous state** | The user looks at the screen and asks "was this saved?" / "was it sent?" / "is it still pending?" → the state must be unambiguous WITHOUT a caption |
| **Colors conflicting with semantics** | A draft shown in green + ✅ (success colors) → the user believes it was submitted (real incident: a user swapped a file, saw green, and messaged support asking whether it was a bug) |
| **Mandatory onboarding** | If the user needs a guided tour to use the feature, the feature is wrong |
| **Documentation as a UX contract** | "It's in the docs" does not count — documentation is a last resort, not a first line |

**The stranger test:** show the screen to someone who has never seen the feature, ask them to complete the task, and stay silent. If the person hesitates, asks, or does the wrong thing → the UX failed, not the person.

**The support-ticket test:** if you can imagine a user sending a screenshot to support asking "is this a bug?" or "how do I do X?" → that question is the bug. Fix it in the UI, not in support.

---

## Process

### Step 1: Load Context

```markdown
Read(.claude/sdd/features/DEFINE_{FEATURE}.md)
Read(.claude/sdd/templates/UX_REVIEW_TEMPLATE.md)
Read(.claude/CLAUDE.md)
Read(your design-system surface/bucket doc, if your project keeps one)  # optional — if the product ships more than one theme, validate contrast in the DEFAULT theme FIRST (it is what users actually see), then the opt-in theme.

# Optional, when available:
Read(existing design system docs)
Read(existing UI/page/component files)
Read(brand/color references)
Glob(.claude/sdd/reviews/UX_REVIEW_*.md)
```

### Step 2: Extract UX Inputs

From DEFINE, extract:

| Element | What To Look For |
|---------|------------------|
| **User** | Persona, role, context, level of expertise |
| **User Goal** | What the user is trying to accomplish |
| **Pain Point** | What feels slow, confusing, risky, or expensive |
| **Success Criteria** | Measurable outcomes and acceptance tests |
| **Constraints** | Technical, business, legal, brand, content, or platform limits |
| **Out of Scope** | UX ideas that must not be pulled into this feature |

### Step 3: Map the Journey

Create a simple journey map:

```text
Before -> Entry Point -> Core Action -> Feedback -> Recovery -> Completion -> Follow-up
```

For each step, identify:

| Dimension | Questions |
|-----------|-----------|
| **User Intent** | What is the user trying to do here? |
| **User Emotion** | Confident, uncertain, rushed, worried, blocked? |
| **Friction** | What can slow down or confuse the user? |
| **System Feedback** | What does the interface need to confirm? |
| **Recovery** | What happens when input, network, permission, or data fails? |

### Step 4: Review UX/CX Quality

Evaluate these areas:

| Area | Review Focus |
|------|--------------|
| **Clarity** | Labels, hierarchy, next action, language |
| **Efficiency** | Number of steps, repeated work, defaults, shortcuts |
| **Confidence** | Feedback, confirmation, trust, proof, reversibility |
| **Accessibility** | Keyboard flow, focus, contrast, readable copy, non-color cues |
| **Responsiveness** | Mobile, tablet, desktop, dense screens, long text |
| **States** | Loading, empty, error, success, partial data, permission denied |
| **CX Continuity** | Email/notification/support handoff, expectation setting, follow-up |
| **Premium Feel** | Obvious hierarchy, calibrated density, short motion, deliberate microinteractions, canonical surfaces (see North Star #1) |
| **Self-Evident** | Zero-explanation: the task completes without a tooltip crutch, without obvious helper text, without the user having to ask support (see North Star #2) |
| **Gamification** | Progress, milestones, rewards, feedback loops, motivation without manipulation |

### Step 5: Apply 60/30/10 calibrated to the design system

Load your design-system surface doc (read in Step 1, if present) and assign every surface proposed in the feature to one of the 3 canonical semantic buckets:

> **The bucket is semantic and theme-agnostic** — the SAME surface=hero renders differently in each theme. You assign the bucket; the theme decides the token's value. **Think first about how the surface looks in the default theme.**

| Bucket | Token | When to use | Default theme | Opt-in theme |
|--------|-------|-------------|---------------|--------------|
| **Hero** | `--surface-hero` | 1-2 surfaces/screen: aspirational/identity (status, progress, next action, large CTAs) | flat card + dark ink | gradient + white text |
| **Neutral** | `--surface-neutral` | Long lists, tables, records, admin screens — operational/dense | flat card + dark ink | gradient + white text |
| **Fallback** | `--bg-card` | Modals, popovers, tooltips, overlay banners — no voice of their own | base card color | base card color |

**Canonical rules UX-Review MUST validate** (see the "Canonical rules" sections for each theme in the canonical doc):

- Canonical accents are untouchable in every theme: the status colors and the brand accent. Each theme has its own hex values.
- **The primary CTA differs per theme** — follow the canonical doc; ⛔ never repurpose an accent that is reserved for links/active/focus as a CTA background.
- Admin/operational screens are always surface=neutral, ⛔ never hero (true in every theme).
- Identity colors driven by data (status pills, category colors) are identity — untouched in every theme.
- Long lists: gradient/color only on the container; items stay flat and semi-transparent (same rule in every theme, with the theme's own rgba values).
- Status colors as badges (colored background + white text): each theme carries its own darkened/canonical hex values.

Document recommendations citing the bucket assigned per surface (not just generic hex values):

```markdown
Surface "Dashboard hero": bucket=hero — first impression after login
Surface "Order list": bucket=neutral — operational/dense
Surface "Confirmation modal": bucket=fallback — overlay with no voice of its own
```

### Step 6: Evaluate Gamification Opportunities

Use gamification whenever it helps the user understand progress, stay motivated, build mastery, or complete a valuable behavior.

Good gamification candidates:

| Mechanic | Use When | UX Purpose |
|----------|----------|------------|
| **Progress Indicator** | The task has clear steps or completion percentage | Reduces uncertainty and encourages completion |
| **Milestones** | The user advances through meaningful stages | Creates momentum and celebrates progress |
| **Badges/Achievements** | The user completes valuable behaviors | Reinforces learning or contribution |
| **Streaks** | Repetition genuinely matters and missing a day is not punished harshly | Encourages habit formation |
| **Levels/Status** | Skill, maturity, or completeness can be represented honestly | Shows growth and next challenge |
| **Challenges** | The user benefits from a focused goal | Makes action concrete and time-bound |
| **Positive Feedback** | The system can confirm effort, quality, or progress | Builds confidence and trust |

Guardrails:

```text
[ ] Gamification supports the user's goal, not only business engagement
[ ] Rewards are meaningful, honest, and tied to useful behavior
[ ] The mechanic does not shame, pressure, or manipulate the user
[ ] Competition is avoided unless it clearly improves the experience
[ ] Accessibility and non-color cues are preserved
[ ] If gamification is not appropriate, document why
```

### Step 7: Prioritize Recommendations

Classify every recommendation:

| Priority | Meaning |
|----------|---------|
| **MUST** | UX/CX risk that can break user success |
| **SHOULD** | Important improvement with clear user value |
| **COULD** | Useful polish if effort is low |
| **WONT** | Valid idea intentionally excluded from this feature |

### Step 8: Produce Design Handoff

Write concrete guidance for `/design`:

| Handoff Item | Content |
|--------------|---------|
| **UX Requirements** | Behaviors and interface expectations |
| **Component Needs** | Forms, tables, cards, empty states, modals, navigation |
| **State Requirements** | Loading, empty, error, success, disabled, permission |
| **Copy Guidance** | Labels, helper text, error copy, confirmation copy |
| **Visual Guidance** | 60/30/10 roles, hierarchy, spacing, contrast |
| **Gamification Guidance** | Progress, milestones, rewards, feedback, or explicit reason not to use them |
| **Acceptance Notes** | UX checks that must survive implementation |

### Step 9: Save

```markdown
Write(.claude/sdd/reviews/UX_REVIEW_{FEATURE_NAME}.md)
```

---

## Output

| Artifact | Location |
|----------|----------|
| **UX Review** | `.claude/sdd/reviews/UX_REVIEW_{FEATURE_NAME}.md` |

**Next Step:** `/design .claude/sdd/features/DEFINE_{FEATURE_NAME}.md`

---

## Quality Gate

Before saving, verify:

```text
[ ] User journey is mapped
[ ] Main UX/CX risks are explicit
[ ] Loading, empty, error, success, and permission states are considered
[ ] Accessibility and responsive behavior are addressed
[ ] 60/30/10 visual rule is applied with clear roles
[ ] Every proposed surface has an assigned bucket (hero/neutral/fallback) with a rationale — buckets hold across every theme
[ ] Admin/operational screens (if the feature touches them) do NOT get surface=hero (neutral only)
[ ] **Primary CTA validated in every theme**, following the canonical doc — never an accent reserved for links/active/focus
[ ] Canonical accents preserved: zero proposals for a new accent hue or a replacement of the accent/status tokens (each theme has its own hex values — do not invent new colors)
[ ] **Numeric contrast targets measured in the DEFAULT theme FIRST**, opt-in theme after. ⚠️ Where the canonical doc only estimates a ratio, **measure the real pair before shipping**.
[ ] Gamification is considered and either recommended or explicitly skipped
[ ] **Premium feel (North Star #1)**: hierarchy, density, typography, motion and microinteractions handled at "shipped feature" level, not "MVP to polish later"
[ ] **Self-evident / zero-explanation (North Star #2)**: no state depends on a tooltip crutch, obvious helper text, or external context to be understood
[ ] Colors never conflict with expected semantics (a draft is ⛔ never green+✅, an error is ⛔ never green, success is ⛔ never red/yellow)
[ ] Stranger test applied mentally: a user who has never seen the feature completes the task without hesitation
[ ] Support-ticket test applied: no screen state provokes "is this a bug?" or "how do I do X?" — if it does, it was promoted to a blocking MUST
[ ] Recommendations are prioritized as MUST/SHOULD/COULD/WONT (a North Star violation = automatic MUST)
[ ] Design handoff has concrete requirements for /design
[ ] No decorative choice is recommended without a user purpose
```

---

## Tips

1. **Do not design the whole UI** - Review enough to guide Design and Build
2. **Tie every recommendation to user success** - Avoid taste-only feedback
3. **Use color to guide attention** - The 10% accent should point to the next meaningful action
4. **Design for failure states early** - Error and empty states are part of the product
5. **Use gamification with purpose** - Progress and rewards should help the user, not distract them
6. **Protect scope** - Put good but non-essential ideas in WONT or future work
7. **Premium is the floor, not the ceiling** - If the feature looks like "an MVP to polish later", it is below standard. Treat every state (loading/empty/error/success/disabled) as a showcase, not a detail
8. **If you are writing helper text, stop** - Ask first: can the affordance be redone so this sentence is unnecessary? 9 times out of 10 it can. Helper text is a last resort, not a first one
9. **The "stranger" and the "support ticket" are your judges** - Before approving, simulate: does a stranger complete the task in silence? Can you imagine a user screenshotting this to support? If no/yes respectively, back to the drawing board

---

## References

- Template: `.claude/sdd/templates/UX_REVIEW_TEMPLATE.md`
- Previous Phase: `.claude/commands/workflow/define.md`
- Next Phase: `.claude/commands/workflow/design.md`
