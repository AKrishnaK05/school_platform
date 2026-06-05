# School Platform (EduParent)

This repository contains a Django backend and a Flutter parent app (`parent_app`) that together form the EduParent / School Platform project.

Status
- Work in progress. The Flutter app contains a `snitch` prototype UI for matching a legacy design.
- This repository has been prepared for open-source consumption (LICENSE, README, .gitignore, contributing guide).

Quickstart

1. Backend (Django)

 - Create a Python virtual environment and install requirements.

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r backend/requirements.txt
```

 - Run migrations and start the development server:

```powershell
cd backend
python manage.py migrate
python manage.py runserver
```

2. Flutter app

 - From the `parent_app` folder, install dependencies and run the app.

```powershell
cd parent_app
flutter pub get
flutter run
```

Notes
- Local development may require the Django server to be reachable at `http://127.0.0.1:8000` (or `http://10.0.2.2:8000` for Android emulator). Update the API base URL in the Flutter code if needed.
- The repository includes prototype screenshots in `parent_app/assets/snitch/` used for pixel-matching.
- This README provides a minimal start — see `CONTRIBUTING.md` for development guidelines.

Notes about the Google icon
- Replace the placeholder `assets/branding/google_g.png` with a high-fidelity Google icon if desired.

Removing local DB from history
- I have **rewritten the local repository history** to remove `backend/db.sqlite3` and created a backup branch named `backup-before-history-rewrite-20260605_0001`.

Important: the rewrite was performed locally only. To update remote repositories you must force-push the rewritten branches. Example commands to push changes to `origin` (do this only when ready and ensure collaborators are informed):

```bash
# Push all branches (force) and tags after verifying history
git push --force --all origin
git push --force --tags origin
```

If you prefer not to force-push, you can keep the backup branch and consult collaborators before updating remotes.

Continuous Integration
- A GitHub Actions workflow has been added at `.github/workflows/ci.yml` that runs `flutter analyze` on push and pull requests against `parent_app`.

Security
- Do not commit secrets or local database files. Consider removing `backend/db.sqlite3` from Git history before publishing.

License
- This project is available under the MIT License. See `LICENSE`.

Project layout
- See [docs/PROJECT_STRUCTURE.md](docs/PROJECT_STRUCTURE.md) for recommended organization and commands to reorganize scripts, remove local DB from history, and add project docs.
