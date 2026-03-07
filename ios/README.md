# Drift iOS + watchOS

Swift source files are in place. Create the Xcode project as follows (or open an existing one and add these files).

## 1. Create a new Xcode project

1. File → New → Project.
2. Choose **App** (iOS); Product Name: **Drift**; Interface: SwiftUI; Language: Swift.
3. Save inside this `ios` folder (so the project is `ios/Drift.xcodeproj`).
4. Add a Watch App: File → New → Target → **Watch App** → name it **Drift Watch App**; finish.

## 2. Replace / add files

- Replace the default `DriftApp.swift` with the one in `Drift/DriftApp.swift` (or copy its contents).
- Add the `Drift/Managers` and `Drift/Models` folders to the **Drift** (iOS) target.
- Add the `Drift Watch App/` folder contents to the **Drift Watch App** target (Managers, Models, DriftWatchApp.swift, Info.plist).
- Use the provided `Info.plist` for both targets or merge keys into the targets’ Info tabs.

## 3. Capabilities (Signing & Capabilities)

- **Drift Watch App**: HealthKit, Background Modes → Workout.
- **Drift (iOS)**: HealthKit (for Garmin/Apple Health pipeline), Time-Sensitive Notifications, Family Controls.

See repo root `docs/ENTITLEMENTS.md` for Info.plist keys and steps.

## 4. Backend URL

Set `APIClient.shared.baseURL` from a config plist or build setting. For development: use `http://localhost:8000` (Simulator) or `http://<your-Mac-LAN-IP>:8000` (device on same Wi‑Fi). A Render (or other public) URL is only needed when the app cannot reach your machine (e.g. on cellular).

## 5. Family Controls

Call `ShieldManager.shared.requestAuthorization` from your UI once; then use the system picker to let the user select apps to manage. Store the chosen tokens in `ShieldManager.shared.applicationTokensToShield` (you’ll get these from the FamilyActivityPicker / authorization result in your UI).

## Folder layout (reference)

```
ios/
  Drift.xcodeproj
  Drift/
    DriftApp.swift
    Managers/
    Models/
    Info.plist
  Drift Watch App/
    DriftWatchApp.swift
    Managers/
    Models/
    Info.plist
```
