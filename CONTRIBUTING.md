# Contributing

Read this before opening a pull request — the model here is unusual and you deserve to know it
before spending your time.

## How this repository is maintained

SpecGate is a **curated snapshot** of a framework in daily production use in a private codebase.
Changes flow one way: they are made and proven in that private repository, then exported here
through a scripted, gated publication. This repository is never the source.

The practical consequences:

- **Pull requests cannot be merged directly.** A merge here would be overwritten by the next
  export. A PR that is accepted gets reimplemented upstream and arrives in the following release,
  with attribution in the commit and the release notes.
- **Releases are periodic, not continuous.** There is no promise of cadence.
- **The private layer never appears here.** Concrete landmine rules, domain skills and internal
  conventions are excluded by an allowlist, not by a filter.

If that model does not suit you, forking is genuinely a reasonable choice — this is roughly two
hundred lines of bash and a set of markdown instructions. The MIT license is there for that.

## What is most useful

**Issues, above all.** Especially:

- The exit contract behaving differently than documented on your platform (bash version, macOS
  vs Linux, CI runner).
- A false positive in the ambiguity detection — a spec that should pass returning exit `5`.
- Documentation that is wrong about another framework in [comparison.md](docs/comparison.md).
  That page tries to be fair and will sometimes fail; corrections from maintainers of those
  projects are especially welcome.
- Adaptation friction: a stack where the slots in `sdd.config.yaml` do not stretch far enough.

**Discussion before code.** If you want to change the gate mechanism or the exit contract, open
an issue first. Those two are the framework's spine — a change there ripples through every
command, and the four fixtures exist to make breaking them loud.

## If you do send a PR

- Run the fixtures: `scripts/verify-gate.sh` against all four in `.claude/sdd/fixtures/`,
  expecting `5 / 0 / 0 / 0`. A PR that changes those expectations changes the contract, which is
  an issue-first discussion.
- Keep examples in a neutral domain (e-commerce, SaaS, blog). No real personal data, no real
  hostnames, no credentials — not even fake-looking ones.
- English for everything in `.claude/` and `scripts/`. Documentation exists in English and
  Portuguese; English is canonical and the Portuguese files are translations.
- Small and focused beats broad. The same rule the framework applies to agents applies here:
  surgical changes, nothing unrequested.

## Translations

`README.pt-BR.md` and `docs/pt-BR/` are translations of the English originals. If you change an
English document, the translation may lag; that is expected and preferable to a stale
translation presented as authoritative. Translations into other languages are welcome as issues
first, so we can agree on maintenance before the files exist.

## Code of conduct

Be decent. Assume the other person is competent and busy. Technical disagreement is welcome;
contempt is not.
