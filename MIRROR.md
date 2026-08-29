# About this mirror

`astack` is a git mirror of [**pstack**](https://github.com/cursor/plugins/tree/main/pstack)
by [Lauren Tan](https://x.com/poteto), which lives as a subdirectory of the
[`cursor/plugins`](https://github.com/cursor/plugins) monorepo.

Everything outside of this file and `scripts/sync-upstream.sh` is upstream content,
carried over verbatim. pstack is MIT licensed; `LICENSE` is preserved unchanged.

## How the mirror was made

The `pstack/` subdirectory was extracted from `cursor/plugins` with
`git subtree split`, which rewrites only the commits that touched that path and
re-roots them at the repository root. Authorship, dates and commit messages are
the original ones — this is real upstream history, not a snapshot commit.

| | |
| --- | --- |
| Upstream repo | `https://github.com/cursor/plugins` |
| Upstream path | `pstack/` |
| Mirrored at | `cursor/plugins@68836dd` |
| Subtree split tip | `25e2e7a` |
| pstack version | 0.14.5 |
| Commits carried | 75 |

## Staying current

```bash
./scripts/sync-upstream.sh          # fetch upstream, merge new pstack commits
./scripts/sync-upstream.sh --check  # report what's new, change nothing
```

The script clones `cursor/plugins` into a temporary directory, re-runs the
subtree split, and merges the result. `git subtree split` is deterministic — the
same upstream commits always produce the same split commits — so re-running it
replays your existing history and appends only what is genuinely new. The
temporary clone is discarded afterwards, which keeps unrelated `cursor/plugins`
history out of this repository's object store.

If you have local commits of your own, the sync produces an ordinary merge and
any conflicts are resolved the usual way.

## Making it yours

Upstream's own README says to fork it and make it yours, so local divergence is
expected rather than a problem. Two things worth knowing before you start editing:

- `.cursor-plugin/plugin.json` still identifies the plugin as `pstack`, points
  `homepage` at the upstream tree, and carries upstream's version number. Change
  those if you publish this as a distinct plugin.
- The further your edits drift from upstream files, the more conflicts a sync
  will surface. Adding new skills alongside the existing ones stays conflict-free;
  rewriting upstream skills in place will not.
