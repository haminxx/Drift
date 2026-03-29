//
//  InterventionStatusCard.swift
//  Drift
//
//  Card D: Brick break, server-driven lock warning, enforced break state.
//

import SwiftUI

struct InterventionStatusCard: View {
    @ObservedObject private var flow = FlowStateManager.shared
    @ObservedObject private var timer = ShieldTimerManager.shared
    @ObservedObject private var prefs = UserPreferencesStore.shared

    var body: some View {
        SummaryCardView(
            icon: { Image(systemName: "shield.lefthalf.filled").foregroundStyle(DriftColorPalette.blue) },
            title: "Intervention Status",
            subtitle: nil
        ) {
            VStack(alignment: .leading, spacing: 6) {
                Text(flow.isInEnforcedBreak ? "Brick / stress break active" : "No enforced break")
                    .font(.subheadline)
                    .fontWeight(.medium)
                if flow.breakRemainingSeconds > 0 {
                    Text("Break ends in \(format(flow.breakRemainingSeconds))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if flow.dashboardStatus == .waitingForFlow {
                    Text("Restore calm HRV to unlock apps.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if timer.isTimerActive {
                    Text("Server drift lock in: \(format(timer.remainingSeconds))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("Break length: \(prefs.breakBrickMinutes) min · Warning: \(prefs.warningBeforeShieldMinutes) min")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 4)
        }
    }

    private func format(_ sec: TimeInterval) -> String {
        let m = Int(sec) / 60
        let s = Int(sec) % 60
        return String(format: "%d:%02d", m, s)
    }
}
