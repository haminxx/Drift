# Drift iOS + watchOS

Swift source files are in place. Create the Xcode project as follows (or open an existing one and add these files).

## 1. Create a new Xcode project

1. File → New → Project.
2. Choose **App** (iOS); Product Name: **Drift**; Interface: SwiftUI; Language: Swift.
3. Save inside this `ios` folder (so the project is `ios/Drift.xcodeproj`).
4. Add a Watch App: File → New → Target → **Watch App** → name it **Drift Watch App**; finish.

## 2. Replace / add files

- Replace the default `DriftApp.swift` with the one in `Drift/DriftApp.swift` (or copy its contents).
- Add the `Drift/Managers`, `Drift/Models`, `Drift/Views`, and `Drift/Views/Components` folders to the **Drift** (iOS) target.
- Link the **Charts** framework (iOS 16+): select the Drift target → General → Frameworks → **+** → **Charts.framework** (or add via **Build Phases → Link Binary**). Set **Minimum Deployment** to iOS 16 if you use `WellnessTrendChartView`.
- Add the `Drift Watch App/` folder contents to the **Drift Watch App** target (Managers, Models, DriftWatchApp.swift, Info.plist).
- Use the provided `Info.plist` for both targets or merge keys into the targets’ Info tabs.

## 3. Capabilities (Signing & Capabilities)

- **Drift Watch App**: HealthKit, Background Modes → Workout.
- **Drift (iOS)**: HealthKit (for Garmin/Apple Health pipeline), Time-Sensitive Notifications, Family Controls.

See repo root `docs/ENTITLEMENTS.md` for Info.plist keys and steps.

## 4. Backend URL

Set `APIClient.shared.baseURL` from a config plist or build setting. For development: use `http://localhost:8000` (Simulator) or `http://<your-Mac-LAN-IP>:8000` (device on same Wi‑Fi). A Render (or other public) URL is only needed when the app cannot reach your machine (e.g. on cellular).

## 5. Family Controls

Open **Brick mode & breaks** from the home toolbar (slider icon). Request Screen Time access, then use **FamilyActivityPicker** for **apps to block** and **essentials** (always allowed). Saved tokens live on `ShieldManager` (`blockedApplicationTokens`, `essentialApplicationTokens`; effective shield = blocked − essential).

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
