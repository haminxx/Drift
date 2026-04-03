# Drift iOS + watchOS

## Open in Xcode (macOS required)

The repo includes **`Drift.xcodeproj`** so you can **double-click or File → Open** and press **Run** on an iPhone simulator.

1. Use a **Mac** with Xcode 15+ (iOS Simulator does not run on Windows).
2. Open **`ios/Drift.xcodeproj`**.
3. Select the **Drift** scheme and an **iPhone** simulator (e.g. iPhone 16).
4. **Product → Run** (⌘R).

You should see **Welcome → Start →** main tabs (**Flow**, **Lock**, **Insight**).

If install fails with **missing or invalid CFBundleExecutable**, clean and rebuild (**Product → Clean Build Folder**, then Run). The bundled `Info.plist` includes `CFBundleExecutable` and `INFOPLIST_PREPROCESS` so Xcode expands `$(EXECUTABLE_NAME)`.

### Exact paths (after you clone the repo)

If the repo lives at `~/Projects/Drift` on your Mac:

| What | Path |
|------|------|
| **Open in Xcode** | `~/Projects/Drift/ios/Drift.xcodeproj` |
| **iPhone app source (SwiftUI UI)** | `~/Projects/Drift/ios/Drift/` (e.g. `ContentView.swift`, `Views/`) |
| **Watch app source** | `~/Projects/Drift/ios/Drift Watch App/` |

**To test the main UI:** use scheme **Drift** and destination **iPhone 16** (or any **iPhone** simulator)—not the Watch. Primary screens (`WelcomeView`, `MainTabView`, `FlowAnalyticsView`, `LockHubView`, `InsightFeedView`, etc.) live under `ios/Drift/`.

**To test the Watch app:** scheme **Drift Watch App** and a **watchOS** simulator. The Watch target is companion code (HRV → iPhone); the full tab UI runs on **iOS**.

### Regenerating the Xcode project

If you add or remove Swift files and Xcode shows missing files, regenerate `project.pbxproj`:

```bash
cd ios
python3 tools/generate_pbxproj.py
```

Alternatively, on a Mac with [XcodeGen](https://github.com/yonaskolb/XcodeGen) installed:

```bash
brew install xcodegen
cd ios
xcodegen generate
```

The committed **`project.yml`** is the source of truth for XcodeGen; **`tools/generate_pbxproj.py`** produces an equivalent project without Homebrew.

**Note:** `Drift.xcscheme` references target IDs from the generated `project.pbxproj`. If you regenerate the project and Xcode loses the scheme, pick **Drift** as the run target again or re-run the Python generator (IDs are deterministic).

## Capabilities (Signing & Capabilities)

After the project opens, enable capabilities per target (see repo **`docs/ENTITLEMENTS.md`**):

- **Drift (iOS):** HealthKit, Time-Sensitive Notifications, Family Controls (for shields / app picker).
- **Drift Watch App:** HealthKit, Background Modes → Workout.

## Backend URL

Set `APIClient.shared.baseURL` (or a build setting / plist) for your FastAPI server. Simulator can use `http://localhost:8000`; a physical iPhone on Wi‑Fi needs your Mac’s LAN IP.

## Family Controls (Lock tab)

Use **Apps & Screen Time** in the Lock tab to authorize Screen Time and choose apps to block; tokens are stored on `ShieldManager`.

## Folder layout

```
ios/
  Drift.xcodeproj/          ← open this
  project.yml               ← XcodeGen spec
  tools/generate_pbxproj.py ← regenerate project.pbxproj
  Drift/                    ← iOS app sources, Info.plist, Assets, Localizable.xcstrings
  Drift Watch App/          ← watchOS app
```
