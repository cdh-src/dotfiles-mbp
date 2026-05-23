# copilot

GitHub Copilot CLI configuration, stowed to `~/.copilot/`.

Currently this package only provides **skills** for working with the personal Obsidian vault (`~/Documents/obsidian-notes` by default; override with `$OBSIDIAN_VAULT`).

## Stow layout
```
copilot/
└── dot-copilot/
    └── skills/
        ├── obsidian-new-project/SKILL.md
        ├── obsidian-session-start/SKILL.md
        └── obsidian-session-end/SKILL.md
```

After `./update.sh`, each `SKILL.md` is symlinked under `~/.copilot/skills/<skill>/SKILL.md`. `~/.copilot/` itself stays a real directory (managed by Copilot CLI) because `update.sh` uses `stow --no-folding`.

## Activating the skills
1. Run `./update.sh` from the dotfiles repo root.
2. Inside an active Copilot CLI session, run `/skills reload` (or restart the CLI).
3. Verify with `/skills list` — the three `obsidian-*` skills should appear under "personal-copilot".
4. Invoke as slash commands: `/obsidian-new-project`, `/obsidian-session-start`, `/obsidian-session-end`.

## Vault path
Each skill resolves the vault path via, in order:
1. `$OBSIDIAN_VAULT` if set
2. `~/Documents/obsidian-notes` (the default)

The vault must already have persistent write permission granted to Copilot CLI (one-time `/add-dir ~/Documents/obsidian-notes` plus an approved write action; it then persists in `~/.copilot/permissions-config.json`).

## Conventions live in the vault, not in the skills
The skills intentionally **read** `<vault>/00-Meta/conventions.md` and `<vault>/_templates/*.md` at invocation time rather than embedding those rules. When you refine vault conventions, the skills pick up the change immediately — no skill edits required.
