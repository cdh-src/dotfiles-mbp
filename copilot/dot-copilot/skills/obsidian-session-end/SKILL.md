---
name: obsidian-session-end
description: >-
  Run the end-of-session ritual for the user's Obsidian PKM vault: completes
  the active session log, updates the project's Current focus, refreshes the
  agent primer if needed, fleshes out seed learning notes, then drafts a
  commit message and — after explicit user approval — commits and pushes the
  vault changes. Use when the user says they're wrapping up a tracked
  session, or runs the /obsidian-session-end slash command.
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

Then transition to step 7 below.

### 7. Stage, commit, and push (after review)

This step replaces the prior "stop and hand off" behavior. The review gate moves one step earlier: the user approves the proposed commit, then the skill performs the git operations. See [[30-Decisions/ADR-0007-session-end-skill-commits-and-pushes]] for the rationale.

All git commands run via `git -C "<vault>" …` so this works from any cwd. **Never `cd`.** The agent stays in the user's project working directory.

**7a. Pre-flight safety checks (bail and report if any fail):**
- `git -C "<vault>" symbolic-ref --short HEAD` returns `main`. Bail with the actual branch if not.
- `git -C "<vault>" rev-parse --abbrev-ref --symbolic-full-name @{u}` succeeds (upstream is set). Bail otherwise.
- `git -C "<vault>" status --porcelain` lists **only files this skill invocation touched**. If anything else is dirty (a half-finished prior session, manual edits, etc.), enumerate the surprises and ask the user how to handle before proceeding.
- `git -C "<vault>" fetch --quiet` then `git -C "<vault>" rev-list --count HEAD..@{u}` returns `0`. If the local branch is behind upstream, bail — do not auto-pull.

**7b. Draft the commit message** as free-form prose (not a fill-in template), following this style:

- **Subject:** `<project-or-area>: <imperative summary>`, ≤72 chars, no trailing period. Examples:
  - `ha-onebusaway: log phase-1 smoke test and freshness finding`
  - `dotfiles-mbp: fix stow 2.3.1 silent failure on Debian devcontainers`
  - `vault: bootstrap structure, templates, conventions, and skills workflow`

  Use `vault` as the area prefix when the commit is about the vault itself (meta-work, primer drift fixes, ADRs about the vault), otherwise use the project name (matching the kebab-case MOC filename).

- **Body:** prose paragraphs explaining *what changed and why*, grouped by concern. Wrap ~72 chars. Bullets only for genuinely list-shaped content (multiple new artifacts, multiple decisions). The body should explain **decisions**, not just enumerate changes — if it reads like a checklist, rewrite it.

- **Mandatory tail block**, separated from the body by a blank line:
  - `Session: 20-Sessions/YYYY/MM/<file>.md` — the log this session produced.
  - One line per new ADR / learning note: `Adds: 30-Decisions/ADR-NNNN-<slug>.md (one-line summary)` or `Adds: 40-Learning/<slug>.md (one-line summary)`. Omit if none.
  - `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>`

**7c. Tooling — heredoc trap.** Write the drafted message to a tempfile (`mktemp -t vault-commit.XXXXXX`) and use `git -C "<vault>" commit -F <tempfile>`. **Do NOT** use heredoc-as-command-substitution (`git commit -m "$(cat <<'EOF' … EOF)"`) — it hangs indefinitely in this CLI's bash tool. See [[40-Learning/heredoc-command-substitution-hangs-in-cli-bash]].

**7d. Review gate.** Show the user:

```
Proposed commit:
---
<full message text>
---

git -C <vault> diff --cached --stat:
<output>

Will commit on `main` and push to `origin/main`. Approve?
```

Offer four choices: `commit + push` (default), `commit only`, `edit message first`, `skip`. Honor any in-session signal the user gave earlier (e.g. "don't push tonight").

**7e. On approval:**
1. `git -C "<vault>" add -A`
2. `git -C "<vault>" commit -F <tempfile>`
3. If `commit + push`: `git -C "<vault>" push`
4. Delete the tempfile
5. Report the new SHA (`git -C "<vault>" rev-parse --short HEAD`) and, if pushed, confirm the upstream update

**7f. Failure handling:**
- Commit failure: leave the staging area as-is (do not unstage). Report the error and stop.
- Push failure: the commit stands locally. Report the error, suggest the user run `git -C <vault> push` after fixing, and stop.

**Do not amend prior commits**, even if the skill is invoked twice in a row. If the user spots a problem after commit, draft a follow-up commit.

## Hard rules
- Do not skip **section 7 of the session log** (Next steps) — it is the load-bearing output of this entire workflow.
- Do not skip the MOC **Current focus** update (skill step 3) — it is the first thing the next session reads.
- Do not modify the primer without explicit reason (cite the change). Drift is the failure mode.
- This skill **only commits the vault**. Never touch any code-project repo's git state, regardless of where the agent is running from.
- Only operate on the vault's `main` branch. Bail if HEAD is elsewhere or upstream is missing.
- Do not bypass the step-7d review gate. Do not amend previous commits.
- Use `git -C "<vault>"` for every git invocation; never `cd`.
- Use `git commit -F <tempfile>` for the commit message; never heredoc-as-arg.
- If you cannot identify the active session log unambiguously, ask the user rather than guessing.
