# Apple Entitlements & Info.plist Checklist

Use this as a reference when configuring the Drift app in Xcode. Do not commit sensitive values.

---

## Capabilities (Xcode → Signing & Capabilities)

| Capability | Target | Purpose |
|------------|--------|---------|
| **HealthKit** | Drift Watch App | Read Heart Rate and Heart Rate Variability (HRV). |
| **HealthKit** | Drift (iOS) | Read HR/HRV from Apple Health (e.g. for **Garmin** pipeline: data synced from Garmin Connect to Health). |
| **Background Modes** | Drift Watch App | Enable "Workout" so HR/HRV can be collected during a mindfulness session in the background. |
| **Time-Sensitive Notifications** | Drift (iOS) | Allow the "Focus drifting. Entertainment apps will lock in 5 minutes." notification to break through Focus and appear prominently. |
| **Family Controls** | Drift (iOS) | Required for ManagedSettings and ApplicationToken (Screen Time–style app blocking). App Store review may require justification for usage. |
| **Sign in with Apple** | Drift (iOS) | Optional; required if you enable Apple as an auth provider in Firebase Authentication. |

---

## Info.plist keys

### Watch App

- **NSHealthShareUsageDescription** — Explain why the app needs to read heart rate and HRV (e.g. "Drift uses heart rate variability to help you stay in focus.").
- **NSHealthUpdateUsageDescription** — If you write workout data (e.g. mindfulness session), explain why (e.g. "Drift records mindfulness sessions to enable continuous HRV measurement.").

### iOS App

- **NSUserNotificationsUsageDescription** — Optional; system may prompt for notification permission.
- Time-Sensitive Notifications are controlled by the capability and user settings; no extra plist key is strictly required for the content.

### Family Controls

- When using `AuthorizationCenter.requestAuthorization(for: .individual)`, the system presents the built-in Screen Time permission UI. No custom plist key is required; the **Family Controls** capability must be enabled.

---

## Xcode steps (summary)

1. Select the **Drift Watch App** target → Signing & Capabilities → + Capability → **HealthKit** (check Background Delivery if you use background observers).
2. **Drift Watch App** → Signing & Capabilities → + Capability → **Background Modes** → enable **Workout**.
3. Select the **Drift** (iOS) target → Signing & Capabilities → + Capability → **Time-Sensitive Notifications** (if available in your Xcode version).
4. **Drift** (iOS) → Signing & Capabilities → + Capability → **Family Controls**.
5. In both targets' **Info** tabs, add the usage description keys above where applicable.

---

## Notes

- **HealthKit on Watch**: The Watch app uses HealthKit to read HR/HRV from the watch and send via WatchConnectivity.
- **HealthKit on iOS (Garmin pipeline)**: The iOS app can read HR/HRV from Apple Health. For **Garmin watch** users: install the Garmin Connect app, enable "Health" / "Apple Health" sharing in Garmin Connect so Heart Rate and HRV are written to Apple Health; then Drift will read that data from HealthKit when the app is running (and in background if background delivery is enabled).
- **Family Controls**: Storing `ApplicationToken` values requires the one-time authorization flow; tokens are opaque and app-specific. You cannot hardcode tokens for other users' devices.
- **Firebase**: For login and saved summaries, add the Firebase iOS SDK and `GoogleService-Info.plist` from the Firebase Console; do not commit the plist (keep it in `.gitignore`). See [SETUP.md](SETUP.md) for GitHub, Render, and Firebase setup.
- **Brick mode (Drift app)**: Use **BrickModeSettingsView** to request Screen Time authorization, pick **apps to block** and **essential apps** (always allowed during shields), and set **stress break** and **warning-before-lock** durations. Effective shield set is *blocked minus essential*. **Charts** (24h HRV graph) need **iOS 16+** and the **Charts** framework linked to the app target in Xcode.
