---
name: obsidian-new-project
description: >-
  Onboard a new project into the user's Obsidian PKM vault. Surveys the project's
  code repo, then drafts the project MOC and agent primer from vault templates.
  Use when the user says they want to start tracking a new project in their Obsidian
  vault, or runs the /obsidian-new-project slash command.
user-invocable: true
---

# Onboard a new project into the Obsidian vault

You are creating two new notes in the user's Obsidian vault so future sessions can be tracked against this project:
- `10-Projects/<name>.md` — the project MOC
- `50-Agent-Context/<name>-primer.md` — the agent primer (the most important file in the workflow)

## Inputs
- **Project name** (required, kebab-case, e.g. `payments-api`). Ask if not provided.
- **Code repo path** (optional, defaults to the current working directory). Ask only if cwd is clearly not a code repo (no README/manifest at the root).

## Vault path resolution
1. If `$OBSIDIAN_VAULT` is set, use it.
2. Otherwise use `~/Documents/obsidian-notes`.

Verify the vault exists and is writable. If you cannot write, tell the user to run `/add-dir <vault>` once (permission is then persistent in `~/.copilot/permissions-config.json`) and stop.

## Steps

### 1. Load vault context
Read these files before doing anything else (they are the source of truth — do not rely on memory):
- `<vault>/00-Meta/conventions.md` — folder layout, file naming, frontmatter rules
- `<vault>/_templates/project.md`
- `<vault>/_templates/agent-context.md`

### 2. Survey the code repo
Spend a few minutes — no more than ~5 tool calls — getting an accurate picture. Focus on:
- README (purpose, status)
- Package manifest (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, etc.) → language, framework, test runner
- Top-level source layout (1–2 levels)
- Test setup (how to run them)
- Lint/format setup
- CI config (one file is usually enough)
- Any existing `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`

Take notes mentally; don't dump the survey into a file.

### 3. Draft the project MOC
Create `<vault>/10-Projects/<name>.md` from `_templates/project.md`:
- Fill frontmatter: `name`, `repo` (full path or `owner/repo`), `status: active`, `created: <today>`.
- Set "Primer for agents" to `[[50-Agent-Context/<name>-primer]]`.
- Leave "Current focus" as: `Project just onboarded — focus TBD.`
- Fill "Resources" with the repo path and any docs URLs you found.
- Leave Dataview blocks intact.

### 4. Draft the agent primer
Create `<vault>/50-Agent-Context/<name>-primer.md` from `_templates/agent-context.md`. **This is the highest-leverage file in the whole vault — be terse, concrete, and only state things you actually verified from the repo.** Fill:
- Frontmatter `project: [[10-Projects/<name>]]`, `updated: <today>`.
- **What this project is** — 2–4 sentences, based on README.
- **Stack & conventions** — language, framework, test runner, lint/format, branching/commit conventions if visible, "things to never do" if any are explicit (e.g. "never commit to main").
- **Architecture in one screen** — smallest map that lets a fresh agent navigate. Component names + how they talk. If you cannot determine this from a 5-tool-call survey, write `TBD — fill on first session` rather than guessing.
- **Current focus** — `Just onboarded; first session TBD.`
- **Active constraints** — `(none yet)` for both bullets.
- **How to work in this repo** — actual setup/test/run commands from the repo, not guessed.

### 5. Hand off to the user
- Print the full primer to the conversation so the user can review.
- Explicitly say: *"Please review the primer carefully — a wrong primer makes future sessions confidently wrong. Edit anything that's incorrect before we move on."*
- Tell the user the next step: when they start working on this project, run `/obsidian-session-start <name>`.
- **Do not commit anything.** The user reviews and commits manually.

## Hard rules
- Never modify `<vault>/_templates/*` — those propagate to every future note.
- Never invent stack details. If unsure, write `TBD` and flag it for the user.
- Never create files outside `10-Projects/` and `50-Agent-Context/` in this skill.
- If the project name already exists in either folder, stop and ask the user whether to overwrite or pick a different name.
