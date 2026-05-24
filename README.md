# SolRank
IOS App. You create a user character based on yourself, compete in real life stats vs friends

## Firebase setup

The real `GoogleService-Info.plist` is **not** included in this repository — it
contains API keys and is gitignored. To build the app locally:

1. Open the [Firebase Console](https://console.firebase.google.com/) and select
   the SolRank project (or your own Firebase project if you're forking).
2. Add an iOS app with bundle ID `com.VincentAndreozzi.SolRank` (or your own).
3. Download the generated `GoogleService-Info.plist`.
4. Drop it into `SolRank/SolRank/` next to `GoogleService-Info.template.plist`.

The committed `GoogleService-Info.template.plist` shows the expected keys —
copy it and replace the placeholder values if you'd rather edit by hand.
