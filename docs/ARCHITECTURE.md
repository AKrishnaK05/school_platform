# Architecture overview

This is a brief architecture outline for the School Platform repository.

Components
- `backend/` — Django REST backend exposing `/api/*` endpoints used by the Flutter app.
- `parent_app/` — Flutter mobile app targeted at parents. Communicates with backend over HTTP and performs OAuth via WebView.

Integration points
- Backend provides login and OAuth start endpoints (e.g., `/api/login/`, `/api/auth/google/start/`).
- The app expects the backend to return `parent_id` and `token` after OAuth/login.

Notes
- For production, configure TLS, proper OAuth client IDs/redirect URIs, and environment-specific base URLs.
