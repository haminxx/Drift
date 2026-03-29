//
//  HomeDashboardView.swift
//  Drift
//
//  Summary + trigger hub: local flow/stress state, breathing visual, history chart, brick settings.
//  HealthKit + Family Controls + Time-Sensitive Notifications — see docs/ENTITLEMENTS.md.
//

import SwiftUI

struct HomeDashboardView: View {
    @ObservedObject private var flow = FlowStateManager.shared
    @ObservedObject private var session = DriftSessionState.shared
    @ObservedObject private var timer = ShieldTimerManager.shared
    @State private var showBrickSettings = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            GlassGradientBackground(intensity: false)
            VStack(spacing: 0) {
                upperSection
                lowerSection
            }
        }
        .ignoresSafeArea(edges: .top)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showBrickSettings = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.white)
                }
                .accessibilityLabel("Brick mode and break settings")
            }
        }
        .sheet(isPresented: $showBrickSettings) {
            BrickModeSettingsView()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private var upperSection: some View {
        VStack(spacing: 12) {
            Spacer()
            ZStack {
                let breathScale = (1.0 + 0.12 * flow.hrvRelativeToBaseline) * (pulse ? 1.06 : 1.0)
                Circle()
                    .fill(breathingFill)
                    .frame(width: 160, height: 160)
                    .scaleEffect(breathScale)
                    .opacity(0.45)
                    .blur(radius: 8)
                    .animation(.easeInOut(duration: 1.0), value: flow.hrvRelativeToBaseline)
                Circle()
                    .stroke(breathingStroke, lineWidth: 3)
                    .frame(width: 140, height: 140)
                    .scaleEffect(breathScale)
                    .opacity(0.25 + 0.35 * flow.hrvRelativeToBaseline)
                    .animation(.easeInOut(duration: 1.0), value: flow.hrvRelativeToBaseline)
                VStack(spacing: 6) {
                    Text(flow.dashboardStatus.rawValue)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    if let s = session.lastServerInFlow {
                        Text(s ? "Server: in flow" : "Server: drift")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 200)

            Text(statusSubtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack(spacing: 16) {
                Label("Flow score \(flow.flowScore)", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.95))
                if timer.isTimerActive {
                    Label(timerLabel, systemImage: "timer")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.95))
                }
                if flow.breakRemainingSeconds > 0 {
                    Label(breakLabel, systemImage: "cup.and.saucer.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.95))
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height * 2 / 3)
    }

    private var breathingFill: LinearGradient {
        let t = flow.hrvRelativeToBaseline
        return LinearGradient(
            colors: [
                DriftColorPalette.redMagenta.opacity(0.35 + 0.2 * (1 - t)),
                DriftColorPalette.cyan.opacity(0.35 + 0.25 * t),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var breathingStroke: LinearGradient {
        let t = flow.hrvRelativeToBaseline
        return LinearGradient(
            colors: [DriftColorPalette.orange.opacity(0.9 - 0.3 * t), DriftColorPalette.blue.opacity(0.5 + 0.4 * t)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var statusSubtitle: String {
        let h = flow.currentHRV.map { "\(Int($0)) ms" } ?? "—"
        let b = flow.baselineHRV.map { "\(Int($0)) ms" } ?? "—"
        return "Current HRV \(h) · 7d baseline \(b)"
    }

    private var timerLabel: String {
        let m = Int(timer.remainingSeconds) / 60
        let s = Int(timer.remainingSeconds) % 60
        return String(format: "Lock warning %d:%02d", m, s)
    }

    private var breakLabel: String {
        let m = Int(flow.breakRemainingSeconds) / 60
        let s = Int(flow.breakRemainingSeconds) % 60
        return String(format: "Break %d:%02d", m, s)
    }

    private var lowerSection: some View {
        ScrollView {
            VStack(spacing: 12) {
                WellnessTrendChartView()
                HStack(spacing: 12) {
                    DailyFlowSummaryCard()
                    PatternIdentificationCard()
                }
                BioDataAverageCard()
                InterventionStatusCard()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Color.white.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
