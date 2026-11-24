# Security checklist

Verified = checked by reading or scanning the files. Not verified = written but never executed.

| Item | Status |
| --- | --- |
| No secrets, keys or private files in the project files (grep scan of the ZIP contents) | Verified (static scan) |
| `.gitignore` covers env files, Firebase config, signing files, build output | Verified (static read) |
| Support email is not hard-coded (comes from `config.json` at build time) | Verified (static scan) |
| Permissions enforced in Firestore and Storage rules, not in the app | Verified (by design, static read) |
| Rules tests (user A cannot read B, no self role change, no self approval, no review without membership, no rating writes, no posts by students, full-class join refused) | Not verified (written, not run) |
| Server-side validation of lengths, types and enums in rules | Not verified (not run) |
| Roles cannot be changed by the user; no admin role exists in the app | Not verified (rules test written, not run) |
| Auth through Firebase Auth (email, Google); no custom crypto | Not verified (not run) |
| Email verification required for writes beyond the profile | Not verified (not run) |
| Password reset does not reveal whether an email exists | Not verified (not run) |
| Rate limiting and abuse protection beyond Firebase defaults | Not applicable for v1 (App Check not enforced for GitHub APKs) |
| Sensitive tokens in secure storage | Not applicable (Firebase Auth manages sessions; no custom tokens stored) |
| HTTPS only | Not verified (Firebase default, not run) |
| Release build shrinking and obfuscation | Not verified (steps in SETUP, not run) |
| No test accounts or backdoors in code | Verified (static read) |
| Account deletion and data export | Not verified (functions written, not run) |
| Terms and Privacy accepted at sign-up, version and time stored, re-asked on change | Not verified (not run) |
| Dependency audit and pinned versions | Not verified (`npm audit`, `flutter pub outdated` not run; commit `pubspec.lock` after the first `flutter pub get`) |
| Backups and restore | Not applicable (not set up; exports are not backups) |
| Legal texts reviewed by a lawyer | Outstanding |
