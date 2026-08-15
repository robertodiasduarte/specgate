<!-- Language: **English** · [Português](pt-BR/adaptation-guide.md) -->

# Adaptation guide

SpecGate was extracted from one production codebase. This document marks the seams — what is
generic, what you must configure, and what was deliberately left out because it was specific to
where it came from.

## What you must configure

Everything project-specific lives in `sdd.config.yaml`. The commands reference slots; they never
hardcode a command.

```yaml
project:
  name: your-project
  test_cmd: "npm test"              # {{TEST_CMD}}
  typecheck_cmd: "tsc --noEmit"     # {{TYPECHECK_CMD}}

deploy:
  cmd: "./deploy.sh production"     # {{DEPLOY_CMD}}
  drift_check_cmd: ""               # {{DRIFT_CHECK_CMD}} — see "drift" below

release:
  landmines_cmd: "bash scripts/release-landmines.sh"   # {{LANDMINES_CMD}}
  changelog_hook: ""                # {{CHANGELOG_HOOK}}

prompts:
  builder_skill: ""                 # your prompt-engineering skill, if you have one
```

## The extension point that matters most: landmines

[`scripts/release-landmines.sh`](../scripts/release-landmines.sh) ships as a **mechanism with
three generic rules** — a secret literal in a tracked file, an out-of-band migration without a
matching commit, a dirty working tree at release time.

That emptiness is deliberate. In the codebase this came from, that script carries dozens of
rules, and every one of them is a scar: a specific outage, a specific silent failure, a specific
2 a.m. discovery. Those rules are worthless to you — they name tables, vendors and internal
functions you do not have — and publishing them would have been an inventory of a private
system's weak points.

**What transfers is the habit:** after each incident, encode the detection as a grep and add it
to your copy. The script's structure supports this directly:

```bash
crit "secret literal in tracked file" \
  "$(diff_added | grep -nE '(sk-[A-Za-z0-9]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY)')"

warn "migration applied out of band has no matching commit" \
  "$(your_check_here)"
```

`crit` blocks the release, `warn` surfaces it in the verdict, `info` records it. A framework
cannot ship your post-mortems; it can ship the place to put them.

## Drift: things deployed outside git

If your project can deploy without a commit — a serverless function pushed from a console, a
migration applied through a dashboard, a config changed in a UI — then your repository can
silently stop describing what runs. This is the failure mode `{{DRIFT_CHECK_CMD}}` exists for.

If everything you deploy goes through git, leave it empty. If not, write a check that compares
what is deployed against what is committed, and wire it in. The release flow will run it in the
pre-flight phase.

## Parallel work: worktrees

The workflow assumes a feature is developed on a branch off the default branch, and it works
well with `git worktree` when several features run at once. The framework does not require
worktrees — it requires that you not develop on the branch you deploy from.

One caveat worth internalizing if you adopt heavy parallelism: with many worktrees alive at
once, the specs in each of them describe divergent futures, and the canonical truth blurs. That
is a real limitation of this framework today (see [comparison.md](comparison.md) — OpenSpec's
specs-as-diffs is a better answer, and it is on the roadmap).

## Agents and models

The framework is model-agnostic in principle, with two practical caveats:

- **`/build --mode briefs` assumes a cheap model exists** for parallel workers, and hard-excludes
  security surface and prompt-engineering items from it. If you do not have a tiering strategy,
  ignore this mode; the default in-context loop is the recommended path.
- **The adversarial review assumes a second vendor.** Its value comes from an uncorrelated error
  profile — a different model family reviewing the first one's work. Reviewing with the same
  model that wrote the code gets you agreement, not review.

Model names are deliberately absent from the shipped files: they age badly. Put yours in
`sdd.config.yaml`.

## What was left out, and why

| Left out | Why |
|---|---|
| Concrete landmine rules | Each documents a specific private incident; useless elsewhere, unwise to publish |
| Domain skills (data import, record lookup, publishing flows) | Business logic of one product, not framework |
| Memory/knowledge layer conventions | A private layer of accumulated project facts; the framework does not depend on it |
| Deploy pipeline, CI wiring, host configuration | Yours will differ in every particular |
| Prompt-engineering skills | Referenced as a configurable slot; the commands call whatever you plug in |

## Fitting it into CI

The minimum useful integration is running the gate of the spec a pull request implements:

```yaml
- run: scripts/verify-gate.sh .claude/sdd/features/DEFINE_${{ env.FEATURE }}.md
```

Treat exit `3` and `4` deliberately: `3` means the CI runner lacks something (often correct to
ignore in CI and resolve locally), `4` means a human must sign — which a CI job cannot do for
you. Mapping either to green defeats the mechanism.
