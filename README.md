<p align="center">
  <img src="docs/images/logo.png" alt="9arini logo" width="120" />
</p>

<h1 align="center">9arini</h1>
<p align="center"><b>Find the right tutor. Learn anything.</b></p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-Dart-02569B" />
  <img alt="Firebase" src="https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20Functions-FFCA28" />
  <img alt="Languages" src="https://img.shields.io/badge/languages-AR%20%7C%20FR%20%7C%20EN-1A6BEA" />
  <img alt="License" src="https://img.shields.io/badge/license-proprietary-lightgrey" />
</p>

9arini connects Algerian students and parents with tutors. Tutors publish classes, students request a seat, and every class becomes a private space for announcements, homework, files, polls and lists.

## Screenshots

Add your screenshots with these exact names.

| Discover | Class | Class space | Sign in |
| --- | --- | --- | --- |
| `docs/images/discover.png` | `docs/images/class.png` | `docs/images/space.png` | `docs/images/signin.png` |

## Features

- Three roles: student, parent (with child profiles) and tutor
- Discover classes by subject, level, wilaya, format and price
- Join requests approved by the tutor, with push notifications
- Class space: announcements, assignments, documents, polls, lists, comments and reactions
- Reviews, only from approved students of the tutor
- Report and block tools, data export and account deletion
- Arabic, French and English with full right-to-left layout, light and dark themes
- Glass design system built from the logo colors

## Tech stack

| Part | Choice |
| --- | --- |
| App | Flutter, Riverpod, go_router |
| Backend | Firebase Auth, Firestore, Storage, Cloud Functions (TypeScript), Cloud Messaging |
| Security | Firestore and Storage rules, App Check (optional), Firestore rules tests |

## Structure

```
lib/        app code (core, data, features)
functions/  Cloud Functions
rules_test/ security rules tests
assets/     logo, fonts, legal texts
docs/       documentation, checklist, legal drafts
```

## Status

The code was written without running it. Nothing has been built, executed or tested yet. See [docs/SECURITY_CHECKLIST.md](docs/SECURITY_CHECKLIST.md) for what is verified and what is not.

## Setup

All steps are in [SETUP.md](SETUP.md).

## License

Proprietary, all rights reserved. See [LICENSE](LICENSE).

## Credits

Built for 9arini. The logo is the project's own asset.
