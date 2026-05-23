---
name: obsidian-session-start
description: >-
  Load the context needed to start a working session on a project tracked in the
  user's Obsidian PKM vault: reads the agent primer and most recent session log,
  summarizes them back, then creates today's session log skeleton. Use when the
  user says they're starting a session on a tracked project, or runs the
  /obsidian-session-start slash command.
user-invocable: true
---

# Start a working session on an Obsidian-tracked project

You are loading the minimum-viable context an agent needs to be productive on this project, and creating today's session log so capture-as-you-go is possible.

## Inputs
- **Project name** (required, kebab-case matching the MOC filename). Ask if not provided.

## Vault path resolution
1. If `$OBSIDIAN_VAULT` is set, use it.
2. Otherwise use `~/Documents/obsidian-notes`.

If the project's MOC (`<vault>/10-Projects/<name>.md`) does not exist, stop and tell the user to run `/obsidian-new-project <name>` first.

## Steps

### 1. Load the primer
Read `<vault>/50-Agent-Context/<name>-primer.md` carefully. This is your single most important context source for the session.

### 2. Load the latest session log
Find the most recent file under `<vault>/20-Sessions/` whose `project:` frontmatter is `[[10-Projects/<name>]]`. "Most recent" = highest `date:` in frontmatter, tiebreak by filename.

- If at least one exists: read the most recent one in full.
- If none exists: this is the project's first session — note that.

### 3. Load active constraints
From the primer's "Active constraints" section, read any linked ADRs in `<vault>/30-Decisions/`. Skip if none.

### 4. Recap to the user (mandatory; do not skip)
Output **3–5 bullets** covering:
- What state the project is in right now (1 line, from primer's "Current focus" and last session)
- What the last session accomplished (1 line; "first session" if none)
- What the last session's "Next steps" said to do next (verbatim or near-verbatim — this is what the user is most likely picking up)
- Any active constraints/ADRs in force (1 line; "none" if none)
- Any open questions or blockers carried over (1 line; "none" if none)

Then ask the user to confirm what they want to work on this session, and **wait for their answer** before continuing.

### 5. Create today's session log
Once the user confirms direction, create `<vault>/20-Sessions/YYYY/MM/YYYY-MM-DD-<slug>.md` from `<vault>/_templates/session.md` where:
- `YYYY`, `MM`, `YYYY-MM-DD` are today's date
- `<slug>` is a short kebab-case description of this session's goal (e.g. `webhook-retries`, `auth-refactor`)

If a session log with the same slug already exists for today, append `-2`, `-3`, etc.

Fill these sections immediately:
- Frontmatter: `date`, `time`, `project: "[[10-Projects/<name>]]"`, `agent` (set to what you can identify about yourself — model name and CLI), `status: in-progress`.
- **Section 1: Goal** — one or two sentences based on what the user confirmed.
- **Section 2: Context loaded** — link to the primer, the last session log (if any), and any ADRs you read in step 3.

Leave sections 3–8 empty for now; they get filled during the work (or by `/obsidian-session-end`).

### 6. Hand off
Confirm to the user:
- Session log created at `<path>`
- You're ready to start work
- Reminder: capture decisions and learnings into the session log as they happen (or paste them and ask the agent to log them), and run `/obsidian-session-end` when wrapping up.

## Hard rules
- Never modify the primer or MOC in this skill — those are updated by `/obsidian-session-end`.
- Never proceed past step 4 without explicit user confirmation of session direction. The recap-and-confirm step is the user's check that you actually loaded the right context.
- If the user's confirmed direction contradicts the last session's "Next steps," note the divergence briefly in the new session log's section 2 ("Context loaded") so it's traceable later.
