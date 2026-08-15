# Fragment — EARS (acceptance test grammar)

> Reusable. Read by `/define` (Step 4.5) and by the bug-fix spec flow.
> EARS = Easy Approach to Requirements Syntax (Alistair Mavin, Rolls-Royce 2009).
> **Why:** each pattern maps mechanically onto a Verify Gate test type, and the *Unwanted*
> pattern forces you to enumerate the undesired behaviour BEFORE the build — the class of
> bug that escapes most often (a provider that is down, a missing row, a full queue).

## Rules

1. **Keywords in English** (When/While/If-Then/Where/shall — a greppable anchor).
2. Every test uses **exactly one** pattern from the table and states **one** observable behaviour.
3. **Bug fix ⇒ at least one "shall continue to" clause** (non-regression): what must NOT change,
   written as a requirement, becomes a regression entry in the gate.
4. An adjective without a number is not a criterion ("fast" → "under 2s").

## The five patterns + non-regression

| Pattern | Form | Example | Gate (`kind`) |
|---|---|---|---|
| **Ubiquitous** | The ⟨system⟩ **shall** ⟨response⟩ | The storefront shall render prices in the visitor's currency | `test`/`typecheck` |
| **Event-driven** | **When** ⟨trigger⟩, the ⟨system⟩ **shall** ⟨response⟩ | **When** a customer submits an order, the system **shall** write an `order_placed` event | `test` (fire the event, assert the state) |
| **State-driven** | **While** ⟨state⟩, the ⟨system⟩ **shall** ⟨response⟩ | **While** the cart is empty, the system **shall** hide the checkout button | `test` (state fixture) |
| **Unwanted behaviour** | **If** ⟨undesired trigger⟩, **then** the ⟨system⟩ **shall** ⟨response⟩ | **If** the payment provider is unreachable, **then** the system **shall** mark the order as pending and retry | `smoke`/`test`, **negative** (drive it through the real path) |
| **Optional feature** | **Where** ⟨feature present⟩, the ⟨system⟩ **shall** ⟨response⟩ | **Where** the kill switch is enabled, the system **shall** suppress outbound e-mail | `test` (flag matrix) |
| **Non-regression** (bug fix) | The ⟨system⟩ **shall continue to** ⟨existing behaviour⟩ | The system **shall continue to** deliver the weekly digest on Saturday mornings | `test` (explicit regression case) |

Complex combinations are allowed: `While ⟨state⟩, when ⟨trigger⟩, the system shall …`.

## Pattern → test mapping (how to derive the Verify Gate)

- **When** → the test fires the event and asserts the response.
- **If/Then** → a **negative** test: provoke the undesired trigger through the real path and
  assert the handling (never just the happy path).
- **While** → the test builds the state fixture and asserts the behaviour under it.
- **Where** → the test runs with the feature on AND off (matrix).
- **shall continue to** → becomes an explicit regression case in the fix's gate.

## Rejection checklist (applied by `/define` to any new or edited spec)

- [ ] Every test uses a pattern from the table (keyword present)
- [ ] At least one **Unwanted** test when the feature has a plausible undesired trigger
      (provider down, missing row, permission denied, full queue)
- [ ] Bug fix: at least one **shall continue to**
- [ ] Zero adjectives without numbers

> **Current limitation:** EARS conformance is prompt discipline plus this checklist — there is
> no mechanical linter for acceptance tests yet. A deterministic linter and test-ID → gate-assert
> traceability are planned.
