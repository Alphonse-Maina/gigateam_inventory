# ShopGuard — Multi-Store Inventory

A Flutter + Firebase app for a CCTV / security / networking shop running
4+ store locations. Tracks what's in stock where, who manages each store,
lets staff request stock from another location, and gives Admins a full
cross-store audit log. Runs on Android, iOS, Web, Windows, macOS, and Linux
from one codebase.

## Roles

| Role    | Can do |
|---------|--------|
| **Admin**   | Everything: manage stores, manage team accounts, edit any store's inventory, approve/reject any request, view the full activity **Logs** tab. |
| **Manager** | Full CRUD on their **own** store's inventory only. Can search/view every other store read-only. Approves/rejects requests aimed at their store. |
| **Staff**   | Read-only search across every store ("who has what"). Can create stock requests. Cannot edit any inventory. |

Nobody outside Admin/that store's Manager can edit a store's items — this is
enforced both in the UI and, more importantly, in `firestore.rules`, so it
holds even if someone calls the API directly.

Every add / edit / remove / request action writes an entry to `logs`, which
only Admin accounts can read (Store screen → bottom nav → **Logs**).

## Project structure

```
lib/
  models/        Plain Dart data classes (Store, InventoryItem, StockRequest, ActivityLog, AppUser, AppNotification)
  services/      Firebase access (AuthService, FirestoreService) — the only files that talk to Firebase directly
  providers/     Riverpod providers wiring services into streams the UI watches
  routes/        go_router config, including the auth redirect
  screens/       One folder per feature (auth, dashboard, stores, inventory, search, requests, notifications, logs, profile)
  widgets/       Shared UI pieces (RoleBadge, CategoryTag, StockPill, StatCard, EmptyState)
  theme/         Centralized colors/spacing/typography ("Night Ops" dark theme + light variant)
firestore.rules  Security rules — the real enforcement of the role table above
```

## First-time setup

This project contains the Dart source (`lib/`), `pubspec.yaml`, security
rules, and this README — it does **not** include the generated native
platform folders (`android/`, `ios/`, `web/`, `windows/`, `macos/`,
`linux/`), since those are machine-generated and shouldn't be hand-written.
Create them once, from the project root, before anything else:

```bash
flutter create . --org com.yourshop --project-name security_inventory
```

Answer "no" if it asks to overwrite `lib/main.dart` — you want to keep the
one included here. This generates real platform projects that already know
the app is called `security_inventory`.

## Firebase setup

1. **Create a Firebase project** at https://console.firebase.google.com.
2. **Enable services**: Authentication (Email/Password provider), Cloud
   Firestore (start in production mode), Cloud Messaging, and Storage (for
   item photos, if you add that later).
3. **Install the CLI tools** (one-time):
   ```bash
   dart pub global activate flutterfire_cli
   npm install -g firebase-tools   # if you don't already have it
   firebase login
   ```
4. **Wire the Flutter app to your project** from the project root:
   ```bash
   flutterfire configure
   ```
   This replaces the placeholder `lib/firebase_options.dart` with your
   project's real keys for every platform you select, and registers the
   Android/iOS/etc. apps in Firebase automatically.
5. **Deploy the security rules**:
   ```bash
   firebase init firestore   # point it at this project, keep the existing firestore.rules
   firebase deploy --only firestore:rules
   ```
6. **Create your first Admin account.** There's no public sign-up screen on
   purpose (accounts are provisioned, not self-served). Easiest path for
   the very first user:
   - In the Firebase console, Authentication → Add user (email + password).
   - In Firestore, create a `users/{that uid}` document:
     ```json
     {
       "name": "Your Name",
       "email": "you@shop.com",
       "role": "admin",
       "storeId": null,
       "active": true
     }
     ```
   - From then on, sign in as that Admin and use the in-app **Team**
     management (see "Next steps" below) to create Manager/Staff accounts
     the normal way.

## Running the app

```bash
flutter pub get
flutter run                 # picks whatever device/simulator is connected
flutter run -d chrome        # web
flutter run -d windows        # Windows desktop
flutter run -d macos           # macOS desktop
```

## Notifications

In-app notifications (the bell icon, with unread badge) work out of the box
via Firestore — no extra setup needed. For **push** notifications when the
app is closed, wire up `firebase_messaging` (already in `pubspec.yaml`):
add `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) from
the Firebase console, request notification permission on launch, and save
each device's FCM token to `users/{uid}/fcmTokens`. A Cloud Function can
then push a notification whenever a `requests` doc or `logs` doc is created.

"Calls" are handled simply and reliably via `url_launcher`'s `tel:` links —
tap a store's phone icon or a teammate's number on their profile to dial
out through the phone's native dialer. True in-app VoIP/video calling is a
much larger build (needs a signaling service like Agora/Twilio) — happy to
scope that separately if you want it.

## What's built vs. what's next

**Built:** auth + role-aware routing, dashboard with live KPIs, store list
+ detail, per-store inventory CRUD (permission-gated), global cross-store
search with filters, inter-store stock requests with approve/reject +
notifications, full activity log (Admin-only), profile + sign out,
responsive layout (bottom nav on phones, nav rail on tablet/desktop),
Firestore security rules matching the role table above.

**Natural next steps**, roughly in priority order:
1. **Team management screen** (Admin): list/create/deactivate Manager &
   Staff accounts from inside the app instead of the Firebase console.
2. **Barcode/QR scanning** (`mobile_scanner` is already in `pubspec.yaml`)
   to look up or add an item by scanning it.
3. **Item photos** via `image_picker` + Firebase Storage.
4. **Push notifications** (see above).
5. **Reports tab**: stock value per store, movement over time, using the
   `fl_chart` package already included.
6. App icons / splash screen branding, and store listing on the App
   Store / Play Store when you're ready to ship.

## Design

Dark-first "Night Ops" theme — deep navy/graphite surfaces with a single
electric-cyan accent, amber for low-stock warnings, green/red for
approved/rejected. Category tags (CCTV, Networking, Security Systems,
Accessories) each get their own accent color so a scrolled list stays
scannable. A light theme is included too (`ThemeMode` currently pinned to
dark in `main.dart` — flip to `ThemeMode.system` if you want it to follow
the OS).
