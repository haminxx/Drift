# Drift bundle IDs and Apple Developer checklist

Canonical identifiers for this repo:

| Target | Bundle ID |
|--------|-----------|
| **Drift** (iOS) | `com.flow.drift` |
| **Drift Watch App** | `com.flow.drift.watchkitapp` |

The Watch app’s **Info.plist** must set **`WKCompanionAppBundleIdentifier`** to **`com.flow.drift`** (the iPhone app’s ID).

OAuth URL type **name** in iOS **Info.plist**: `com.flow.drift.oauth`. The URL **scheme** remains **`drift`** so callbacks stay `drift://oauth/...` (Fitbit/Garmin redirect URIs unchanged).

---

## Apple Developer (Identifiers)

1. **Certificates, Identifiers & Profiles** → **Identifiers**.
2. **App ID** (iOS): explicit **`com.flow.drift`** — enable **HealthKit** (and other capabilities you use).
3. **App ID** (watchOS): explicit **`com.flow.drift.watchkitapp`** — enable **HealthKit**.
4. If you previously created **`com.drift.Drift.*`**, you can leave them unused or remove them after Xcode uses only the `com.flow.drift` pair.

---

## Xcode

1. Open **Drift** target → **Signing & Capabilities** → **Team** → enable **Automatically manage signing**.
2. Confirm **Bundle Identifier** is **`com.flow.drift`**.
3. Open **Drift Watch App** target → same **Team** → **Bundle Identifier** **`com.flow.drift.watchkitapp`**.
4. Add capabilities per [ENTITLEMENTS.md](ENTITLEMENTS.md): HealthKit (both), Watch **Background Modes → Workout**, iOS **Time-Sensitive Notifications** and **Family Controls** as needed.

---

## App Store Connect

Create the app record with bundle ID **`com.flow.drift`**. Privacy answers must match HealthKit read/write behavior.
