# Addis Delight Restaurant app (v1 scaffold)

Flutter + Bloc + GoRouter + Firebase (Auth, Firestore, FCM, Cloud Functions). Android first.
The full design (strategy, journeys, data model, screens, testing, risks) is in the blueprint document.

> This scaffold was written without running Flutter, so it is not compiled yet.
> Run `flutter pub get` then `flutter analyze` and fix any small version-related issues.

## 1. Create the Flutter project and copy these files in

    flutter create --org com.addisdelight --platforms=android addis_delight_app
    # copy from this folder into addis_delight_app/:
    #   lib/  test/  pubspec.yaml  analysis_options.yaml
    #   firebase.json  firestore.rules  firestore.indexes.json  functions/  tools/

## 2. Firebase

1. Create a Firebase project. Enable Authentication > Email/Password and Phone.
2. Create Firestore (pick the region closest to Addis Ababa that is available to you).
3. `dart pub global activate flutterfire_cli` then `flutterfire configure` (creates `lib/firebase_options.dart`).
4. Add your debug and release SHA-1 and SHA-256 fingerprints to the Android app in Firebase
   (`cd android && ./gradlew signingReport`). Phone OTP does not work on Android without them.
5. Android 13+: make sure `android/app/src/main/AndroidManifest.xml` contains
   `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>`.
6. Deploy (Cloud Functions needs the Blaze plan):

       cd functions && npm install && cd ..
       firebase deploy --only firestore:rules,firestore:indexes,functions

   In `functions/index.js` set the region to match your Firestore location.

## 3. Seed data and roles

    export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
    cd functions && npm install && cd ..
    node tools/seed.js                      # sample menu (placeholder prices) and settings
    node tools/set_role.js <uid> staff      # or manager. Find the uid in Authentication > Users

Roles are custom claims. After changing a role, the user signs out and in again.

## 4. Run and test

    flutter pub get
    flutter analyze
    flutter test
    flutter run

## Where things live

| Folder | Purpose |
|---|---|
| lib/core | theme, router (role-based redirects), notifications, formatters |
| lib/features/auth | AuthBloc (session and role), LoginCubit (email and phone OTP) |
| lib/features/menu | live menu, search and filters |
| lib/features/cart | CartBloc, CheckoutCubit, cart and checkout page |
| lib/features/orders | order models, repository, history with reorder, live tracking |
| lib/features/reservations | table booking form, list, ReservationCubit |
| lib/features/profile | loyalty points, favorites, user repository |
| lib/features/staff | order queue and reservation queue |
| lib/features/manager | daily dashboard |
| functions/index.js | re-pricing, push notifications, loyalty points, daily stats |
| firestore.rules | role-based security rules |
