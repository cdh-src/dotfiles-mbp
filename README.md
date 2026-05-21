# dotfiles

Personal dotfiles for macOS, managed with GNU `stow`.

## Setup

On a fresh machine:

1. Clone this repo somewhere (e.g. `~/code/dotfiles-mbp`).
2. Read [`PREREQUISITES.md`](./PREREQUISITES.md) to see what gets installed.
3. Optionally run `./bootstrap.sh` to install everything via Homebrew. Idempotent.
4. Create `~/.zshsecrets` per PREREQUISITES.md §5.
5. Run `./update.sh` to symlink configs into `$HOME`.
6. Restart your shell.

## On a configured machine

`./update.sh` re-stows everything. Run it after adding files to the repo.

## Layout

Each top-level directory is a stow package using the `--dotfiles` convention (`dot-foo` → `~/.foo`). See [`CLAUDE.md`](./CLAUDE.md) for the full layout convention and key wiring notes.
