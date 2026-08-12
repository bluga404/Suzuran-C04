**Gemini API Integration**

- **Summary**: This document describes the current, official Google Gemini API pattern used by Suzuran and the safeguards required before shipping the report summary feature.

- **Official references**:
  - Google AI Studio / Gemini docs: https://ai.google.dev/
  - Gemini API documentation: https://ai.google.dev/gemini-api/docs
  - API key guidance: https://ai.google.dev/gemini-api/docs/api-key
  - Text generation guide: https://ai.google.dev/gemini-api/docs/text-generation
  - Google Cloud API key best practices: https://cloud.google.com/docs/authentication/api-keys#best_practices
  - Apple Keychain Services: https://developer.apple.com/documentation/security/keychain_services

- **High-level guidance**:
  - Never hard-code API keys in source code, plist files, or repository history.
  - Prefer Keychain for local development secrets, and a backend proxy/service for production mobile apps.
  - In local debug runs, the app may read standard Google environment variable names such as `GEMINI_API_KEY` or `GOOGLE_API_KEY`, but real values must remain local-only and must never be committed.
  - Restrict API keys in Google AI Studio / Cloud Console to the Gemini API only, and rotate them regularly.
  - Treat the client-side app as untrusted. A user can inspect any bundled secret in a production mobile app.
  - Never commit `.env`, `*.xcconfig`, Xcode scheme environment variables, or secret samples that contain real values.

- **Current implementation contract**:
  - Official Gemini REST requests use the `generateContent` endpoint under the `v1beta` base URL.
  - A standard API key is sent as a query parameter named `key`.
  - Request bodies follow the `contents` and optional `systemInstruction` structure shown in the official docs.
  - Response decoding must read `candidates[].content.parts[].text`, not a flat `content.text` field.

- **Where code belongs in this repo**:
  - Key management: Infrastructure/Security.
  - Network client: Features/Report/Services.
  - UI orchestration: Features/Report/ViewModels and ReportFactory.

- **Files involved**:
  - `Infrastructure/Security/APIKeyProvider.swift`: Keychain-backed provider and secure secret storage.
  - `Features/Report/Services/GeminiSummaryService.swift`: Gemini network client.
  - `Features/Report/Services/ReportDataService.swift`: Uses the summary service and fallback cache.
  - `Features/Report/ReportFactory.swift`: Injects the service into the feature.

- **Implementation notes**:
  - The service must stay on the official `https://generativelanguage.googleapis.com/v1beta` base URL and use `...:generateContent`.
  - The app should only log redacted URLs and not emit raw request bodies or API keys.
  - Keychain storage should use a device-scoped accessibility class so the secret is not exposed more broadly than necessary.
  - Production should use a backend proxy or a backend-issued token flow instead of pushing raw Gemini keys into the mobile app.

- **Safety checklist before release**:
  1. Create a dedicated Gemini key in Google AI Studio, restrict it to the Gemini API, and rotate it if it was ever exposed.
  2. Keep all real keys out of source control and remove historical leaks if found.
  3. Prefer a backend proxy to keep the mobile app from containing live credentials.
  4. Add quota, billing, and abuse monitoring in the Google Cloud project.
  5. Keep logging redaction in place and audit any error paths that might print URLs or payloads.
