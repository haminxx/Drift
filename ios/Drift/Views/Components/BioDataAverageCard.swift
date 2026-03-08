//
//  BioDataAverageCard.swift
//  Drift
//
//  Card C: Bio-Data Average — Avg. HRV Score, Restability Score. Placeholder values.
//  HealthKit read (and background delivery if needed) required; configure in Xcode
//  Signing & Capabilities and see docs/ENTITLEMENTS.md.
//

import SwiftUI

struct BioDataAverageCard: View {
    var body: some View {
        SummaryCardView(
            icon: { Image(systemName: "heart.fill").foregroundStyle(DriftColorPalette.redMagenta) },
            title: "Bio-Data Average",
            subtitle: "From Health / watch"
        ) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Avg. HRV Score")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("— ms")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                HStack {
                    Text("Restability Score")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("—")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .padding(.top, 4)
        }
    }
}
