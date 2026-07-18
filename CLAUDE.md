# Always use a worktree in this repo

`pc` (the machine this repo normally lives on) runs impermanence: `/` and
`$HOME` are wiped on every reboot. Only paths under `home.persistence."/persist"`
survive — that includes `~/mynix` itself (it's a bind mount from `/persist`),
but **not** arbitrary directories like `/tmp` or a stray `~/some-dir`.

**Before making any code changes, always create/enter a git worktree first**
(the `EnterWorktree` tool, or `git worktree add`) rather than editing the
checkout directly. Keep worktrees inside the repo, at
`~/mynix/.claude/worktrees/<name>` — anything created outside a
persisted path is silently lost on the next reboot, along with any
uncommitted work in it.

A few gotchas specific to this setup:

- `git worktree move` out of `~/mynix` fails with "Invalid cross-device
  link" (crossing the bind-mount boundary). Use `cp -a` to the new location
  plus `git -C ~/mynix worktree repair <new-path>` instead.
- The shell's cwd has occasionally been observed to silently drift back to
  the main repo root between otherwise-consecutive tool calls while working
  inside a worktree, with no `cd` issued and no error. Run `pwd` (or use
  `git -C <path>` explicitly) immediately before any git write operation
  (`add`/`commit`/`reset`) rather than trusting cwd to have persisted.
- Stale/orphaned worktree directories (present on disk but not in
  `git worktree list`) can linger after a reboot or an interrupted session —
  check `git worktree list` and `git status` before reusing an existing
  worktree directory rather than assuming it's in the state you left it.
