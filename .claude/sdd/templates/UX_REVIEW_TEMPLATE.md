# UX REVIEW: {Feature Name}

> UX/CX review for `{FEATURE_NAME}` after DEFINE and before DESIGN

## Metadata

| Attribute | Value |
|-----------|-------|
| **Feature** | {FEATURE_NAME} |
| **Date** | {YYYY-MM-DD} |
| **Author** | ux-review-command |
| **DEFINE** | [DEFINE_{FEATURE}.md](../features/DEFINE_{FEATURE}.md) |
| **Status** | Draft / Ready for Design / Needs Requirement Iteration |

---

## UX Summary

{2-4 sentences summarizing the experience goal, main user risk, and strongest recommendation.}

---

## User and Context

| Field | Value |
|-------|-------|
| **Primary User** | {Persona or role} |
| **User Goal** | {What they need to accomplish} |
| **Primary Pain** | {What currently frustrates or blocks them} |
| **Business/CX Goal** | {Trust, conversion, retention, support reduction, speed, clarity} |
| **Device/Context** | {Desktop/mobile/tablet, internal/external, urgent/calm, repeated/one-time} |

---

## Journey Map

| Step | User Intent | Emotion/Risk | Interface Need |
|------|-------------|--------------|----------------|
| Before | {What happens before feature use} | {Emotion or risk} | {Expectation setting} |
| Entry | {How user enters} | {Emotion or risk} | {Navigation, CTA, context} |
| Core Action | {Primary task} | {Emotion or risk} | {Form, flow, controls} |
| Feedback | {What user needs to know} | {Emotion or risk} | {Status, validation, confirmation} |
| Recovery | {What happens when something fails} | {Emotion or risk} | {Error, retry, support, undo} |
| Completion | {How success is understood} | {Emotion or risk} | {Success message, next step} |
| Follow-up | {What happens after} | {Emotion or risk} | {Notification, history, support path} |

---

## UX/CX Findings

| Priority | Area | Finding | Recommendation |
|----------|------|---------|----------------|
| MUST | {Clarity/Efficiency/Confidence/Premium/Self-Evident/etc.} | {Issue or risk} | {What to change} |
| SHOULD | {Area} | {Issue or opportunity} | {What to change} |
| COULD | {Area} | {Nice-to-have} | {What to change} |
| WONT | {Area} | {Good idea excluded from this feature} | {Why excluded} |

---

## North Star Checks (Premium + Self-Evident)

Explicit verification of the 2 inviolable principles. Any violation = automatic MUST.

### Premium / iPhone-style

| Dimension | Status | Evidence / Risk |
|-----------|--------|-----------------|
| Visual hierarchy within 200ms | ✅ / ⚠️ / ❌ | {Does the eye know where to land first?} |
| Calibrated density (it breathes) | ✅ / ⚠️ / ❌ | {Does it avoid looking like a cramped admin screen?} |
| Typography with purpose (≤3 sizes/surface) | ✅ / ⚠️ / ❌ | {Are weights and sizes justified?} |
| Short motion (150-250ms ease-out) | ✅ / ⚠️ / ❌ | {Zero decorative bounces?} |
| Complete micro-interactions (hover/focus/active/disabled) | ✅ / ⚠️ / ❌ | {No forgotten state?} |
| Canonical surfaces (hero/neutral/fallback) | ✅ / ⚠️ / ❌ | {Zero generic flat or "white card"?} |
| Empty states as delight, not placeholder | ✅ / ⚠️ / ❌ | {Is empty an opportunity, not an embarrassment?} |
| "Shipped" finish, not "MVP to polish" | ✅ / ⚠️ / ❌ | {Does it feel like a finished product?} |

### Self-Evident / Zero-Explanation

| Anti-pattern | Present? | Where / how to remove |
|--------------|----------|-----------------------|
| Tooltip crutch (affordance only works with a tooltip) | ❌ Yes / ✅ No | {Surface and plan to rebuild the affordance} |
| Helper text explaining the obvious | ❌ Yes / ✅ No | {Text and plan to remove it} |
| Ambiguous state (was it saved/sent/pending?) | ❌ Yes / ✅ No | {Surface and plan to make it unambiguous} |
| Color conflicting with semantics (draft shown in green, etc.) | ❌ Yes / ✅ No | {Where, and what the correct color is} |
| Mandatory onboarding/tour | ❌ Yes / ✅ No | {Why it is removable} |
| Documentation used as a UX contract | ❌ Yes / ✅ No | {Move the rule into the UI} |

**Stranger test:** {Mental result — does a first-time user complete the task in silence? Where would they hesitate?}

**Support-inbox test:** {Does any state trigger a "is this a bug?" or "how do I do X?" message to support? If so, list them and mark as MUST.}

---

## Gamification Strategy

Use gamification whenever it can improve motivation, progress clarity, learning, completion, or confidence without manipulation.

| Opportunity | Recommended Mechanic | User Value | Guardrail | Priority |
|-------------|----------------------|------------|-----------|----------|
| {Where gamification could help} | {Progress/Milestone/Badge/Streak/Level/Challenge/Feedback/None} | {Why it helps the user} | {How to avoid pressure, shame, clutter, or dark patterns} | MUST/SHOULD/COULD/WONT |

If gamification is not appropriate, state why:

```text
Gamification decision: Not recommended because {reason}.
```

---

## 60/30/10 Visual Strategy

> Buckets are theme-agnostic; the token's value changes per theme. **Name your default theme and think about it first.** The "Token / Role" column lists the bucket; consult your design system's canonical file for the exact HEX of each theme.

| Share | Token / Role | Theme A (default) | Theme B (opt-in) | UX Rationale |
|-------|--------------|-------------------|------------------|--------------|
| **60% Dominant** | `--app-bg` | {light base} | {dark base} | Viewport background — reduces cognitive load |
| **30% Secondary HERO** | `--app-surface-hero` ({aspirational surfaces — list which}) | {hero surface, theme A} | {hero surface, theme B} | "Highlight / identity" — first impression |
| **30% Secondary NEUTRAL** | `--app-surface-neutral` ({operational surfaces — list which}) | {neutral surface, theme A} | {neutral surface, theme B} | "Dense / sober" — long lists, admin work |
| **30% Fallback** | `--app-bg-card` | {card, theme A} | {card, theme B} | Modals/popovers/tooltips — no voice of their own |
| **10% Canonical accent** | `--app-accent`, status colors | {accent + status, theme A} | {accent + status, theme B} | Semantic signals preserved — ⛔ do NOT propose a new hue |

**Color Guardrails:**

```text
[ ] Every proposed surface has a bucket assigned (filled in under "Surface Buckets Assignment" below) — the bucket holds in BOTH themes
[ ] Primary CTA validated per theme (the CTA token differs by theme — never assume the accent is the CTA)
[ ] Dense/operational areas use surface=neutral, NEVER surface=hero (holds in both themes)
[ ] Theme-specific variants used where a canonical color fails on the other theme's background
[ ] Canonical accents preserved (zero proposals for a new accent hue)
[ ] Numeric contrast targets specified for the DEFAULT theme FIRST, the opt-in theme second
[ ] Meaning does not depend on color alone (chips use icon + text + color — 3 signals)
```

---

## Surface Buckets Assignment

Every UI surface proposed in this feature must be assigned to a canonical bucket of the design system.
Consult your design system's surface/bucket doc (if your project keeps one) for precedents.

| Surface (functional) | Bucket | Rationale | Add to canonical matrix? |
|----------------------|--------|-----------|--------------------------|
| {Surface name, e.g. "Dashboard hero"} | hero / neutral / fallback | {Why this bucket? Aspirational? Operational? Overlapping?} | Yes (new surface) / No (already in the matrix) |
| ... | ... | ... | ... |

**Canonical rules to respect:**

- ✅ CTAs on surfaces=hero use the on-hero CTA token, NEVER the raw accent
- ✅ Operational/review screens are always surface=neutral
- ✅ Modals/popovers/tooltips use surface=fallback
- ✅ Long lists: gradient only on the container; items stay flat and semi-transparent
- ✅ Untouchable accents: the canonical accent and the status colors

---

## Interaction Requirements

| Requirement | Why It Matters | Priority |
|-------------|----------------|----------|
| {Interaction requirement} | {User/CX reason} | MUST/SHOULD/COULD |
| {Gamification requirement or explicit skip} | {Motivation/progress reason or why not applicable} | MUST/SHOULD/COULD/WONT |

---

## Required States

| State | Required UX |
|-------|-------------|
| Loading | {Skeleton, spinner, progress, expected wait copy} |
| Empty | {What user sees before data exists} |
| Error | {Readable error, recovery path, retry/support} |
| Success | {Confirmation and next step} |
| Partial Data | {How incomplete data is shown} |
| Permission Denied | {Access explanation and next action} |
| Disabled | {Why unavailable and how to enable} |

---

## Content and Copy Guidance

| Surface | Guidance |
|---------|----------|
| Primary CTA | {Verb-first, user outcome, concise} |
| Helper Text | {What uncertainty to resolve} |
| Error Copy | {Specific, human, actionable} |
| Confirmation | {What happened and what user can do next} |
| Empty State | {Explain value and first action} |

---

## Accessibility and Responsiveness

| Concern | Requirement |
|---------|-------------|
| Keyboard | {Focus order, shortcuts, escape behavior} |
| Contrast (calibrated to the design system — **measure the default theme first**) | **Default theme:** body text on background ≥7:1 AAA where possible; accent on background ≥4.5:1 AA (measured, not estimated); status colors on background ≥4.5:1. **Opt-in theme:** same targets re-measured — a color that passes on one theme's background often fails on the other, so use the theme-specific variant. Status badges: ≥3:1 non-text in both themes. ⚠️ Measure via DevTools/contrast calculator — list the values for BOTH themes in the response; never carry over an estimated ratio. |
| Screen Reader | {Labels, roles, announcements} |
| Mobile | {Layout, touch target, truncation, long content} |
| Non-color Cues | {Icons, text, shape, position} |

---

## Design Handoff

Concrete requirements for `/design`:

- {Requirement 1}
- {Requirement 2}
- {Requirement 3}
- {Gamification requirement or explicit reason not to include gamification}

Components likely needed:

- {Component 1}
- {Component 2}
- {Component 3}

Acceptance notes:

- [ ] {UX acceptance note}
- [ ] {CX acceptance note}
- [ ] {60/30/10 visual hierarchy note}
- [ ] {Gamification acceptance note or explicit skip rationale}
- [ ] **Premium**: every state (loading/empty/error/success/disabled) has a "shipped" finish, not "MVP to polish"
- [ ] **Self-Evident**: zero tooltip crutches, zero obvious helper text, zero color conflicting with semantics — stranger test and support-inbox test passed

---

## Open UX Questions

- {Question 1}
- {Question 2}

If none, state: `None - ready for Design.`

**Special trigger:** if you CANNOT determine the bucket of a proposed surface, list it here — that question MUST block the move to /design until it is resolved (never push the decision down into /design):

- "Surface X: hero (aspirational) or neutral (operational)? Awaiting the design owner's decision."

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | {YYYY-MM-DD} | ux-review-command | Initial UX review |

---

## Next Step

**Ready for:** `/design .claude/sdd/features/DEFINE_{FEATURE_NAME}.md`
