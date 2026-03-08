//
//  PatternIdentificationCard.swift
//  Drift
//
//  Card B: Pattern Identification — bar chart (Morning, Afternoon, Evening) with placeholder heights.
//  Ready for future pattern data.
//

import SwiftUI

struct PatternIdentificationCard: View {
    /// Placeholder heights (0...1); later bind to flow-by-time-of-day data
    var morning: Double = 0.7
    var afternoon: Double = 0.4
    var evening: Double = 0.5

    var body: some View {
        SummaryCardView(title: "Pattern Identification", subtitle: "Typical flow by time of day") {
            HStack(alignment: .bottom, spacing: 16) {
                bar(label: "Morning", value: morning)
                bar(label: "Afternoon", value: afternoon)
                bar(label: "Evening", value: evening)
            }
            .frame(height: 56)
            .padding(.top, 8)
        }
    }

    private func bar(label: String, value: Double) -> some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4)
                .fill(DriftColorPalette.deepPurple.opacity(0.7))
                .frame(height: max(8, value * 48))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
