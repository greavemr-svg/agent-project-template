# Security and data protection standards

Security by design (principles, MASVS/ASVS profile, threat modelling and the
NIST SSDF mapping) is in `security-by-design.md`. This page holds the
concrete coding rules.

## Secrets
- No secrets in the repository: API keys, tokens, passwords, signing keys, keystores, `google-services.json` with live keys.
- Secrets live in the platform's secret store (GitHub Actions secrets, local `.env` excluded by `.gitignore`).
- A secret that ever reached a commit is treated as compromised: rotate it, then clean history (owner action).

## Input and output
- Validate all external input (user input, files, network responses, intents) for type, length, range and format.
- Parameterised queries only; never build SQL, shell commands or file paths from unchecked input.
- Encode output for its context (HTML, URLs). Never render untrusted HTML.

## Authentication and access
- Least privilege everywhere. No debug back doors or hard-coded accounts.
- Sessions and tokens expire; tokens are stored in secure platform storage (Android Keystore / EncryptedSharedPreferences).

## Personal data (UK GDPR)
- Collect only what the feature needs; the spec states what and why.
- Health-related or employment data (e.g. rotas, pay, sickness) is treated as sensitive: encrypted at rest, never logged, never sent to third parties without explicit consent.
- No real personal data in tests, fixtures, screenshots or seed data.
- Users can delete their data; retention is stated in the spec when data is stored.

## Transport
- HTTPS only. No cleartext traffic; certificate validation never disabled.

## Dependencies
- No dependency with a known High or Critical vulnerability without an ADR accepting the risk.
- Dependabot alerts and CodeQL (or equivalent) findings are triaged before release.

## Android specifics
- Components are not exported unless required, and exported ones are protected.
- `android:allowBackup` reviewed for sensitive data; `usesCleartextTraffic="false"`.
- WebViews: JavaScript off unless needed; no `addJavascriptInterface` with untrusted content.
- Release builds are minified and signed; signing keys never in the repo.

## Severity
| Severity | Meaning | Release |
|---|---|---|
| Critical | Exploitable now, data exposure or takeover | Blocks |
| High | Likely exploitable or serious data risk | Blocks |
| Medium | Needs specific conditions | Fix or accept in audit |
| Low | Hardening | Backlog |
