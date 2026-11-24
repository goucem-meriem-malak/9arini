# Documentation

## Architecture

- `lib/core`: theme tokens (one file), localization (one file), shared widgets, validators, error messages.
- `lib/data`: models, one `Repo` class for all Firestore, Storage and Functions access, Riverpod providers, push registration, discover query controller.
- `lib/features`: one folder per area (auth, discover, classes, class_space, tutor, notifications, profile, legal, splash, shell).
- `functions/`: counters, notifications, aggregates, account export and deletion. Clients never write counters.
- Permissions live in `firestore.rules` and `storage.rules`. Client checks only hide buttons.

## Data model (Firestore)

| Path | Main fields | Written by |
| --- | --- | --- |
| `users/{uid}` | name, role, locale, ageConfirmed, termsVersion, termsAcceptedAt | owner (role is immutable) |
| `users/{uid}/children/{id}` | name, level | owner |
| `users/{uid}/tokens/{token}` | platform | owner |
| `users/{uid}/blocks/{uid2}` | name | owner |
| `users/{uid}/notifications/{id}` | kind, classId, classTitle, name, postTitle, read | functions (owner may mark read) |
| `tutors/{uid}` | name, bio, subjects, wilaya, years, ratingAvg, ratingCount | owner (rating fields: functions only) |
| `tutors/{uid}/reviews/{reviewerUid}` | rating, text, classId, authorName | approved student of that tutor |
| `classes/{id}` | tutorId, title, subject, level, price, priceUnit, wilaya, commune, mode, schedule, capacity, status, memberCount, pendingCount | tutor (counters: functions) |
| `classes/{id}/private/info` | onlineLink | tutor; read by tutor and approved members |
| `classes/{id}/members/{uid}` | name, role, childName, status, classId, classTitle, tutorId | member creates `pending`; tutor sets `approved` or `rejected` |
| `classes/{id}/posts/{id}` | type, title, body, commentsEnabled, dueAt, file*, options, listItems, reactionCounts, pollCounts, commentCount | tutor (counts: functions) |
| `.../posts/{id}/reactions/{uid}`, `votes/{uid}` | emoji / options | the member |
| `.../posts/{id}/comments/{id}` | authorId, authorName, text | member or tutor, if comments are on |
| `reports/{id}` | reporterId, targetPath, reason | any verified user, write-only |

Personal data fields: email (Firebase Auth), name, role, language, child first name and level, push token, class activity. Stored in Firebase (Europe region). Users can export and delete everything in Settings.

## Permission matrix

| Action | Anonymous | Student / parent | Member (approved) | Tutor of the class | Other tutor |
| --- | --- | --- | --- | --- | --- |
| Read own profile | no | yes | yes | yes | yes |
| Read others' profile | no | no | no | no | no |
| Read tutor profile, classes, reviews | no | yes | yes | yes | yes |
| Request to join an open, non-full class | no | yes (verified email) | n/a | no | no |
| Approve or reject requests | no | no | no | yes | no |
| Read posts, online link, files | no | no | yes | yes | no |
| Create or delete posts | no | no | no | yes | no |
| React, vote | no | no | yes | yes | no |
| Comment | no | no | yes, if comments are on | yes | no |
| Review the tutor | no | no | yes (approved in that tutor's class) | no | no |
| Create a class | no | no | no | tutor role only | tutor role only |
| Change own role or ratings | no | no | no | no | no |

## Decisions

- Wilaya picker plus free-text commune instead of GPS: less personal data, no location permission.
- No private messages in v1: smaller moderation surface; discussion happens in class posts.
- Discover applies one server filter (wilaya, then level, then subject) and the rest on the client, to keep Firestore indexes few.
- Counters are maintained by Cloud Functions so clients cannot fake them.
- Document links use Storage download URLs, which contain a token. Anyone who gets the link can open that file. Accepted for v1.
- Class title and tutor name are copied into membership records for fast lists. A later rename does not update old records.
- No payments in v1. The subscription is not built (see the plan).
- App Check is activated in the app but must not be enforced for APKs outside Google Play.

## Known limits

- Capacity is checked by rules using `memberCount`, which a function updates a moment later. Two approvals at the same instant could pass the limit by one.
- A rejected request is final for that class (the user cannot ask again).
- A parent has one membership per class (one child name per class).
- Search is client-side over loaded pages, so very large catalogs need a search service later.
- The launch screen hands off with a fade, not a circular reveal, and there are no shared-element (hero) transitions between tabs and detail screens.
- Offline: Firestore cache shows saved data with an "offline" chip. Writes are not queued with conflict rules; no custom sync.
- Package versions were chosen from memory and may need `flutter pub upgrade`.
