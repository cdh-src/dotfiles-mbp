---
name: obsidian-session-end
description: >-
  Run the end-of-session ritual for the user's Obsidian PKM vault: completes
  the active session log, updates the project's Current focus, refreshes the
  agent primer if needed, fleshes out seed learning notes, and shows a diff
  for review. Use when the user says they're wrapping up a tracked session,
  or runs the /obsidian-session-end slash command.
user-invocable: true
---

# End-of-session ritual for an Obsidian-tracked project

This is the **most important skill in the workflow**. Without this ritual, session logs become write-only and the whole context-handoff system silently rots. Do every step. Do not skip section 7 (Next steps) or step 2 (Current focus) — those are the two things the next session actually reads.

## Inputs
- **Project name** (optional). If not provided, infer it from the most recently modified session log in the vault and confirm with the user before proceeding.

## Vault path resolution
1. If `$OBSIDIAN_VAULT` is set, use it.
2. Otherwise use `~/Documents/obsidian-notes`.

## Steps

### 1. Identify the active session log
Find the session log to close out:
- If the user named a project: the most recent file under `<vault>/20-Sessions/` whose `project:` frontmatter matches `[[10-Projects/<name>]]` and whose `status:` is `in-progress`.
- If no project named: the most recently modified file under `<vault>/20-Sessions/` whose `status:` is `in-progress`. Confirm with the user: *"Closing out `<filename>` (project: `<name>`). Correct?"*

If none is `in-progress`, ask the user which session to close (they may have forgotten to start one formally).

### 2. Complete the session log
Open the identified log and fill in any sections still empty or thin. Use the conversation history of this session as your source material. **Bullets, not prose.**

- **Section 3: What happened** — tight narrative of what was actually done. **Include dead ends and pivots** — those are some of the most valuable signal for the next session. Don't sanitize the log into a success story.
- **Section 4: Decisions made** — bullet list. If any decision is load-bearing (constrains future work or someone will later wonder "why did we do it this way?"), also draft a new ADR in `<vault>/30-Decisions/` using the next sequential ADR-NNNN number, and link to it from this section.
- **Section 5: Learnings** — bullet list of durable knowledge. For each, create or update a corresponding file in `<vault>/40-Learning/` (see step 4 for fleshing-out rules). Link from this section.
- **Section 6: Open questions / blockers** — what's still unresolved.
- **Section 7: Next steps** — **this is the single most-read section by the next session/agent. Spend real effort here.** Each bullet should be:
  - Concrete and action-shaped (starts with a verb)
  - Specific enough that a fresh agent with zero context could pick it up cold
  - Not aspirational ("improve performance" ← bad; "profile webhook handler under 100 RPS load, target p99 < 50ms" ← good)
- **Section 8: Artifacts** — commit SHAs, PR URLs, branch names, files touched. Use `git log` / `git status` to verify.
- **Frontmatter** — set `status: complete`.

### 3. Update the project MOC
Open `<vault>/10-Projects/<name>.md`. Rewrite the **"Current focus"** paragraph to reflect where the project actually is now. One short paragraph, present-tense. Do not touch any other section.

If "Current focus" still says something like "Project just onboarded — focus TBD," replace it entirely.

### 4. Check the agent primer
Open `<vault>/50-Agent-Context/<name>-primer.md`. Ask yourself: **did anything this session change** the stack, conventions, "things to never do," architecture, or commands in "How to work in this repo"?

- **If yes**: update the relevant section(s) in the primer and bump the `updated:` frontmatter to today. Tell the user explicitly which sections changed and why.
- **If no**: explicitly say *"Primer unchanged — no changes to stack, conventions, or architecture this session."* Do not touch the file.

A stale primer is worse than no primer because future sessions will confidently act on wrong info. This check is non-negotiable.

### 5. Flesh out seed learning notes
For each new `40-Learning/` note created this session (including any `maturity: seed` stubs):
- If the note has fewer than ~3 sentences of actual content, expand it now while context is fresh. The "Why it matters", "The thing itself", and "Evidence" sections should each have real content.
- If the user explicitly said it's just a placeholder, leave it as a seed stub — but confirm with the user before doing so.

### 6. Show the diff
Output a summary of every file touched in this skill invocation:
```
Touched files:
  - <vault>/20-Sessions/YYYY/MM/<file>.md            (session log completed)
  - <vault>/10-Projects/<name>.md                    (Current focus updated)
  - <vault>/50-Agent-Context/<name>-primer.md        (unchanged | sections updated: <list>)
  - <vault>/30-Decisions/ADR-NNNN-<slug>.md          (new ADR for: <one-line summary>)
  - <vault>/40-Learning/<slug>.md                    (new seed | expanded)
```

Then **stop. Do not commit.** The user reviews the diff and commits manually. The human-review gate is part of the design.

## Hard rules
- Do not skip step 7 (Next steps) — it is the load-bearing output of this entire workflow.
- Do not skip step 2 (Current focus) — it is the first thing the next session reads.
- Do not modify the primer without explicit reason (cite the change). Drift is the failure mode.
- Do not commit. Do not push. Show diff, stop, hand off.
- If you cannot identify the active session log unambiguously, ask the user rather than guessing.
