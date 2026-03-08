//
//  InterventionStatusCard.swift
//  Drift
//
//  Card D: Intervention Status — Last Shield Reset, Next Break Prompt. Placeholder copy.
//  Screen Time / Family Controls entitlement required for shield; see docs/ENTITLEMENTS.md.
//

import SwiftUI

struct InterventionStatusCard: View {
    var body: some View {
        SummaryCardView(
            icon: { Image(systemName: "shield.lefthalf.filled").foregroundStyle(DriftColorPalette.blue) },
            title: "Intervention Status",
            subtitle: nil
        ) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Last Shield Reset: —")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Next Break Prompt: —")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
    }
}
