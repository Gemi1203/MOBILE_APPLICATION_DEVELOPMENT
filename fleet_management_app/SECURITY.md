Security & API key guidance

- Do NOT commit API keys or service account files to the repository.
- Store Google Maps / Directions API keys and Firebase service accounts in CI secrets (GitHub Actions) and environment variables.
- For Android: put restricted Maps API keys in `android/app/src/main/AndroidManifest.xml` as a resource or use Gradle to inject from environment.
- For iOS: configure keys via Xcode build settings and `.xcconfig` files, not checked-in plaintext.
- Firebase Rules: enforce role-based access in `firestore.rules` and `database.rules.json`. Example defensive rules:
  - Only allow users to write their own `driver_locations/{driverId}` when `request.auth.uid == driverId`.
  - Only managers/admins may read `locations_buffered` or `anomalies` collection for management dashboards.

CI guidance

- Create repository secrets: `GOOGLE_MAPS_API_KEY`, `FIREBASE_SERVICE_ACCOUNT` (or use Firebase CLI with project login), and mark them in GitHub Actions secrets.
- In workflows, inject secrets into the build via env vars and do not print them.

If you want, I can:
- Add example Firestore rules to `firebase.rules`.
- Scaffold GitHub Action steps to inject secrets and run a deploy step.
