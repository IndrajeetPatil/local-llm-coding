# AGENTS.md

Guidance for AI coding agents working in this repository.

## Overview

`local-llm-coding` runs GitHub Copilot CLI against a Qwen3.5 model that Ollama
serves locally on an Apple Silicon Mac. A Makefile installs the tools,
configures the model's context window, and verifies inference and a real
Copilot file-tool call. See [README.md](README.md) for an overview and
[docs/detailed-setup.md](docs/detailed-setup.md) for details.

## Layout

| Path | Purpose |
| --- | --- |
| `Makefile` | The whole workflow: setup, start, stop, status, state checks, and verification (`make help`) |
| `Brewfile` | Command-line tools that `make setup` installs with `brew bundle` |
| `docs/` | User documentation, built into a Zensical site; `docs/index.md` includes `README.md` |
| `docs/images/` | Generated figures; `README.md` and `response-workflow-prompts.md` hold their provenance and prompts |
| `mkdocs.yml` | Documentation site configuration, navigation, and `llms.txt` sections |
| `overrides/` | Site template overrides |
| `pyproject.toml`, `uv.lock` | Docs-only uv project that installs Zensical |
| `lychee.toml` | Link-check settings for the CI link check |
| `hextools/` | Artwork and R scripts that render the hex sticker and the social preview card |
| `.github/workflows/` | CI workflows: checks on pull requests, docs deployment from `main` |
| `.github/zizmor.yml` | zizmor policy for the workflow audit |
| `.github/dependabot.yml` | Dependabot updates for GitHub Actions |
| `prek.toml` | Git hooks |

## Commands

```sh
make help          # list all targets and overridable variables
make -n <target>   # dry-run a target to check the dependency graph
make docs          # build the documentation site strictly
make docs-serve    # preview the site at http://localhost:8000
prek run --all-files  # every hook; must pass before committing
```

`make setup`, `make start`, `make stop`, `make verify`, and the targets they
depend on install Homebrew packages, start or stop the Ollama login service,
download multi-gigabyte models, or run Copilot CLI. Do not run them unless
explicitly asked; they only work on an Apple Silicon Mac. `make status` and
`make check-state` only read state.

## Conventions

- Keep the Makefile idempotent: every install, start, and configure step
  checks the current state first and prints `[SKIP]` when nothing is needed.
  Use the existing `INFO`, `OK`, `SKIP`, `WARN`, and `FAIL` prefixes, and
  send failures to stderr with a non-zero exit.

- Install command-line tools through the `Brewfile`, not ad hoc
  `brew install` calls.

- Keep the offline guarantees intact: Copilot talks only to the loopback
  Ollama endpoint, runs with an isolated `COPILOT_LOCAL_HOME` (mode 0700),
  and has tokens, proxies, telemetry, and auto-update stripped or disabled in
  `COPILOT_LOCAL`. Do not loosen these without an explicit request.

- Keep `PROMPT_TOKENS` plus `OUTPUT_TOKENS` within `CONTEXT_TOKENS`, and keep
  defaults in the Makefile's overridable variables rather than hard-coding
  them in recipes.

- Keep the documentation site building with `make docs`: register new pages
  in `nav` and the `llmstxt` sections of `mkdocs.yml`, and link outside
  `docs/` with full GitHub URLs.

- The site's home page includes `README.md` verbatim, so give README images
  and links absolute URLs.

- Use GitHub callouts (`> [!NOTE]`) for asides; the site renders them as
  admonitions.

- Keep the README short: requirements, the quick start, commands, and links.
  Put details in `docs/detailed-setup.md`, and update it when targets,
  defaults, or files outside the repository change.

- Keep `docs/validation.md` to results that were actually measured; never
  invent or extrapolate benchmark numbers.

- When regenerating a figure, update its prompt and accuracy checklist in
  `docs/images/` and keep the alt text beside it accurate.

- Use American English in prose, matching the existing docs.

## Workflows

- Trigger checks on pull requests to `main` only; only `docs.yml` also runs
  on `main` and by hand, to deploy the site.

- Pin every action to a full commit SHA with its most specific release in an
  inline comment (`# v7.0.1`), never a sliding tag such as `v7`. First-party
  reusable workflows from `IndrajeetPatil/workflows` are the exception: they
  are called at `@main` by design, and `.github/zizmor.yml` allows that.

- Default `GITHUB_TOKEN` to `contents: read` at the workflow level, and grant
  write scopes only to the job that needs them, with a comment saying why.

- Set `persist-credentials: false` on every checkout, a finite
  `timeout-minutes` on every job, and a `concurrency` group on every
  workflow.

- Pass event data and inputs to scripts through `env:`, never by
  interpolating `${{ }}` into `run:`.

- Prefer runner-provided tools over additional actions. Install a standalone
  binary only at a pinned version with a pinned SHA-256 checksum of the
  archive, verified before extraction, and update both together.

- Keep the security gate fail-closed: Gitleaks scans the complete history,
  and zizmor audits every workflow in pedantic mode. Fix findings rather than
  suppressing them.

- Keep tool versions that CI and prek share in step: zizmor in `security.yml`
  and `prek.toml`, and conventional-pre-commit and its commit types in
  `conventional-commits.yml` and `prek.toml`.

## Learn from mistakes

When a check fails, a reviewer raises a finding, or you notice a mistake in
your own work, fix it, then ask what led you to it. If `AGENTS.md`, a skill,
its scripts or templates, a prompt, or a doc gave missing, ambiguous, or
wrong guidance, correct that guidance in the same pull request, stating the
general rule rather than the incident. Never weaken a quality gate instead.

## Pull requests

Follow these rules without relying on any instructions outside this
repository:

- Write every commit message and PR title as a Conventional Commit,
  `type(scope): description`, lowercase and imperative, with an allowed type
  (`build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`,
  `revert`, `style`, `test`). Keep the PR title and body in sync with the
  net diff.

- Open every PR ready for review with `gh pr create`, never as a draft.

- Never add agent or tool attribution to commits, PRs, or comments.

- When a PR needs visual evidence (such as slide layout or styling changes),
  use the shared `pr-screenshot` skill to post verified screenshots. Verify the
  uploaded images render in the comment.

- After opening or pushing, wait for hosted CI to finish. Inspect failed jobs,
  fix the cause, run the local checks, push, and repeat. Skipped, queued, or
  failing required checks are not success.

- If an automatic AI review (Codex, for the owner) runs on the PR, wait for
  its result instead of requesting one. Fix merited findings, reply to and
  resolve addressed threads, and continue until the review approves the
  current head with no unresolved findings. Never write `@codex` anywhere in
  a PR, even in backticks: it cancels the automatic review. Say "a Codex
  review request" instead.

- If Codex reports exhausted usage, take no workaround action: leave the PR
  open, do not merge, and report the review limit. CI work can still finish.
  Once usage refreshes, comment `@codex review` once; this is the only case
  that needs the comment.

- Once CI is green and the review gate is met, squash-merge with the owner's
  authenticated `gh` credentials, then verify the merged state. Recheck the
  head, threads, and checks immediately before merging, and never bypass
  branch protections.

- Update a PR branch from `main` only to resolve conflicts or pick up a change
  the PR depends on, never just to bring it up to date.

- Report local validation, hosted CI, review, and merge state separately. If
  an external blocker stops completion, leave the PR open and say so.
