//
//  LockHubView.swift
//  Drift
//
//  Distraction lock hub: sliders, focus schedule, unlock threshold, mock essentials, Screen Time sheet.
//

import SwiftUI

struct LockHubView: View {
    @ObservedObject private var prefs = UserPreferencesStore.shared
    @StateObject private var wearableOAuth = WearableOAuthCoordinator()
    @State private var showBrickSheet = false
    @State private var mailOn = true
    @State private var calendarOn = true
    @State private var canvasOn = false
    @State private var slackOn = true
    @State private var wearableBanner: String?
    @State private var wearableError: String?
    @State private var wearableConfigured: [String: Bool] = [:]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Distraction Lock")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Text("Timers apply to stress breaks and server drift warnings. Real bypass uses Screen Time essentials.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.55))

                glassSection(title: "Cloud wearables") {
                    Text("Apple Watch uses on-device HealthKit (no OAuth). Fitbit and Garmin can link to your Drift account on the server via OAuth. Register the same redirect URI in the vendor portal (e.g. drift://oauth/callback).")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                    if let banner = wearableBanner {
                        Text(banner)
                            .font(.caption)
                            .foregroundStyle(.green.opacity(0.9))
                    }
                    if let err = wearableError {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.orange.opacity(0.95))
                    }
                    HStack(spacing: 12) {
                        Button {
                            Task { await connectFitbit() }
                        } label: {
                            Label("Connect Fitbit", systemImage: "figure.walk")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.white)

                        Button {
                            Task { await connectGarmin() }
                        } label: {
                            Label("Connect Garmin", systemImage: "location.north.circle")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.white)
                    }
                    if (wearableConfigured["fitbit"] ?? false) == false || (wearableConfigured["garmin"] ?? false) == false {
                        Text("If a button fails, set FITBIT_* / GARMIN_* env vars on the backend and sign in with Firebase.")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .task {
                    await refreshWearableProviders()
                }

                glassSection(title: "Break & warning") {
                    sliderRow(
                        title: "Stress / brick break",
                        binding: Binding(
                            get: { Double(prefs.breakBrickMinutes) },
                            set: { prefs.setBreakBrickMinutes(Int($0)) }
                        ),
                        range: 1 ... 120,
                        unit: "min"
                    )
                    sliderRow(
                        title: "Warning before app lock",
                        binding: Binding(
                            get: { Double(prefs.warningBeforeShieldMinutes) },
                            set: { prefs.setWarningBeforeShieldMinutes(Int($0)) }
                        ),
                        range: 1 ... 60,
                        unit: "min"
                    )
                }

                glassSection(title: "Focus schedule") {
                    Text("Planned focus window (used for future reminders; not enforced server-side yet).")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                    HStack {
                        Text("Start")
                            .foregroundStyle(.white.opacity(0.8))
                        Spacer()
                        Stepper(
                            clockLabel(minutes: prefs.focusScheduleStartMinutes),
                            value: Binding(
                                get: { prefs.focusScheduleStartMinutes / 60 },
                                set: { prefs.setFocusScheduleStartMinutes(min($0 * 60, 23 * 60 + 59)) }
                            ),
                            in: 0 ... 23
                        )
                    }
                    HStack {
                        Text("End")
                            .foregroundStyle(.white.opacity(0.8))
                        Spacer()
                        Stepper(
                            clockLabel(minutes: prefs.focusScheduleEndMinutes),
                            value: Binding(
                                get: { min(prefs.focusScheduleEndMinutes / 60, 23) },
                                set: { prefs.setFocusScheduleEndMinutes(min(max($0 * 60, 60), 24 * 60 - 1)) }
                            ),
                            in: 1 ... 23
                        )
                    }
                }

                glassSection(title: "Unlock goal") {
                    Text("Minutes of sustained calm HRV (local flow) required to remove shields after a break.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                    sliderRow(
                        title: "Deep flow to unlock",
                        binding: Binding(
                            get: { Double(prefs.unlockRequiredFlowMinutes) },
                            set: { prefs.setUnlockRequiredFlowMinutes(Int($0)) }
                        ),
                        range: 1 ... 120,
                        unit: "min"
                    )
                }

                glassSection(title: "Allowed essentials (mock)") {
                    Text("Illustrative toggles. Real always-allowed apps are set with Screen Time below.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.45))
                    mockToggle("Mail", isOn: $mailOn)
                    mockToggle("Calendar", isOn: $calendarOn)
                    mockToggle("Canvas", isOn: $canvasOn)
                    mockToggle("Slack", isOn: $slackOn)
                }

                Button {
                    showBrickSheet = true
                } label: {
                    Label("Screen Time & app lists", systemImage: "hand.raised.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.16))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                                }
                        }
                        .foregroundStyle(.white)
                }
                .padding(.top, 8)

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .background {
            DriftColorPalette.linearGradient
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showBrickSheet) {
            BrickModeSettingsView()
        }
    }

    private func refreshWearableProviders() async {
        do {
            let list = try await APIClient.shared.fetchWearableProviders()
            var map: [String: Bool] = [:]
            for p in list {
                map[p.id] = p.configured
            }
            wearableConfigured = map
        } catch {
            wearableConfigured = [:]
        }
    }

    private func connectFitbit() async {
        wearableBanner = nil
        wearableError = nil
        do {
            try await wearableOAuth.connectFitbit()
            wearableBanner = "Fitbit linked to your account."
        } catch is CancellationError {
            wearableBanner = nil
        } catch {
            wearableError = "Fitbit: \(error.localizedDescription)"
        }
    }

    private func connectGarmin() async {
        wearableBanner = nil
        wearableError = nil
        do {
            try await wearableOAuth.connectGarmin()
            wearableBanner = "Garmin linked to your account."
        } catch is CancellationError {
            wearableBanner = nil
        } catch {
            wearableError = "Garmin: \(error.localizedDescription)"
        }
    }

    private func glassSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 14) {
                content()
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                    }
            }
        }
    }

    private func sliderRow(title: String, binding: Binding<Double>, range: ClosedRange<Double>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Text("\(Int(binding.wrappedValue.rounded())) \(unit)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.55))
            }
            Slider(value: binding, in: range, step: 1)
                .tint(.cyan)
        }
    }

    private func mockToggle(_ name: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(name)
                .foregroundStyle(.white.opacity(0.9))
        }
        .tint(.green)
    }

    private func clockLabel(minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        let p = h >= 12 ? "PM" : "AM"
        let hh = h % 12 == 0 ? 12 : h % 12
        return String(format: "%d:%02d %@", hh, m, p)
    }
}
