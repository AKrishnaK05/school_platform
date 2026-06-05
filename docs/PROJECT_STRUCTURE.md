# Project structure and recommended organization

This file documents the current repository layout and recommended organization for contributors.

Top-level layout

- `backend/` — Django backend (models, views, migrations, requirements). Keep as-is.
- `parent_app/` — Flutter parent app (Dart/Flutter). Contains `lib/`, `assets/`, `pubspec.yaml`.
- `.github/` — CI workflows and GitHub configuration.
- `tools/` (recommended) — utility scripts, cleanup helpers, history-rewrite helpers. Currently the repository includes `scripts/`; consider moving them here.
- `assets/` — optional global assets (not present). App-specific assets live under `parent_app/assets/`.
- `docs/` — documentation (this file). Add architecture diagrams and design notes here.
- `LICENSE`, `README.md`, `CONTRIBUTING.md` — project metadata at repo root.

Recommendations

- Keep runtime artifacts and local databases out of the repo (`backend/db.sqlite3` is currently present). Use `scripts/remove_db_history.*` to safely remove it from history.
- Keep developer scripts in a single folder (`tools/` or `scripts/`). If you move files, update README references.
- Keep app-specific assets inside their app folders (e.g., `parent_app/assets/`). Avoid committing very large prototype images unless required.
- Add `docs/ARCHITECTURE.md` for high-level architecture diagrams and API contracts.

Example suggested reorganization (manual steps you can run):

1. Move scripts into `tools/`:

```powershell
git mv scripts tools
git commit -m "Move maintenance scripts to tools/"
```

2. Remove `backend/db.sqlite3` from Git history (review `scripts/remove_db_history.*` first):

```bash
# Install git-filter-repo (recommended):
pip install --user git-filter-repo
git filter-repo --path backend/db.sqlite3 --invert-paths
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push --force --all
git push --force --tags
```

3. Add CODEOWNERS and ISSUE_TEMPLATE files to `.github/` as needed.

If you want, I can perform the reorganization steps for you (move scripts into `tools/`, update references, and prepare the history-rewrite commands). Confirm and I'll proceed.