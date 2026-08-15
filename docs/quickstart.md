<!-- Language: **English** · [Português](pt-BR/quickstart.md) -->

# Quickstart

From zero to a blocking gate in about ten minutes.

## 0. Should you use the full workflow at all?

Be honest about the change in front of you:

| The change is… | Do this |
|---|---|
| Describable in one sentence, small blast radius | Skip the phases. Talk to the model, run your tests. |
| A bug fix with a known cause | `/define` (a bug-fix spec needs at least one `shall continue to`) then `/build`. |
| New behaviour, several files, or expensive to get wrong | The full workflow below. |

A framework that claims to be the only path is lying to you. Use the phases where being wrong
is expensive.

## 1. Install

```bash
git clone https://github.com/<owner>/specgate.git /tmp/specgate
cp -r /tmp/specgate/.claude your-project/
cp -r /tmp/specgate/scripts your-project/
cp /tmp/specgate/sdd.config.example.yaml your-project/sdd.config.yaml
```

Nothing is registered, compiled or installed — these are markdown instructions and bash scripts.
One requirement: run the scripts **from inside a git repository** (the gate resolves paths from
the repo root; outside one it exits `64`).

## 2. Point the slots at your project

Edit `sdd.config.yaml`:

```yaml
project:
  name: your-project
  test_cmd: "npm test"
  typecheck_cmd: "tsc --noEmit"
deploy:
  cmd: "./deploy.sh production"
release:
  landmines_cmd: "bash scripts/release-landmines.sh"
```

The commands reference these slots rather than hardcoding anything, which is what makes the
framework portable across stacks.

## 3. Verify the install

```bash
scripts/verify-gate.sh .claude/sdd/fixtures/DEFINE_FIXTURE_CONTROL.md;              echo "exit=$?"  # 0
scripts/verify-gate.sh .claude/sdd/fixtures/DEFINE_FIXTURE_NEEDS_CLARIFICATION.md;  echo "exit=$?"  # 5
```

Getting `0` and `5` means the gate runner and the exit contract work. If the second one returns
`0`, the ambiguity detection is broken — do not proceed, because silent assumptions are exactly
what it exists to catch.

## 4. Write your first spec

```
/define Add a discount code field to the checkout form
```

The command will push back in three ways, all deliberate:

**It writes acceptance tests in EARS.** Not "the discount should work" but:

> **When** a customer submits a valid discount code, the system **shall** recalculate the order
> total and display the discounted amount before payment.
>
> **If** the discount code is expired, **then** the system **shall** keep the original total and
> show the reason inline.

The second one is the *unwanted behaviour* pattern, and `/define` will refuse a spec that has a
plausible failure mode without one. That is the class of bug that escapes review most often.

**It marks ambiguity instead of guessing.** If it cannot tell whether codes stack, it plants a
marker and asks you — at most five multiple-choice questions per round. Until you answer, the
gate returns exit `5` and the pipeline is stopped.

**It demands an executable gate.** The spec is not saved without one:

```yaml
verify_gate:
  kind: test
  cmd: "npm test -- src/checkout/discount.test.ts"
  pass_when: "exit 0"
```

## 5. Design, build, release

```
/design .claude/sdd/features/DEFINE_DISCOUNT_CODES.md   # architecture, decisions, file manifest
/build  .claude/sdd/features/DESIGN_DISCOUNT_CODES.md   # code, then the gate — blocking
/release "discount codes at checkout"                    # graded verdict, one human approval
```

`/build` will not declare success with the gate at `2` (red) or unresolved `3` (inconclusive).
`/release` ends in PASS, CONCERNS, FAIL or WAIVED — and a waiver requires a written reason from
a human, never from the agent.

## The exit contract, once

| exit | Meaning | What the caller does |
|---|---|---|
| `0` | green | proceed |
| `2` | red | abort |
| `3` | inconclusive (missing tool, infra noise) | resolve explicitly; never counts as red |
| `4` | manual-ux: needs a human signature | show the checklist, wait for the receipt |
| `5` | an ambiguity marker is still active | stop, go back to `/define` — never iterate the design |
| `64` | the gate block is missing or malformed | the spec is invalid |

The distinction between `2` and `5` is the one people miss: a red gate means the code is wrong,
while `5` means the *question* is wrong. Loops that treat them alike will happily iterate a design
built on an unresolved assumption.

## Next

- [Adaptation guide](adaptation-guide.md) — fitting this to your stack, CI and team
- [Verify Gate contract](verify-gate-contract.md) — the full reference
- [Comparison](comparison.md) — how this differs from other frameworks
