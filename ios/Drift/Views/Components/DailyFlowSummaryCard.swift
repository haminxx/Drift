//
//  DailyFlowSummaryCard.swift
//  Drift
//
//  Card A: Daily Flow Summary — circular chart (Flow vs Drift % today) + text.
//  Structurally ready for FlowStateResponse or aggregated stats.
//

import SwiftUI

struct DailyFlowSummaryCard: View {
    /// Placeholder; later bind to aggregated flow vs drift percentage (e.g. 0.6 = 60% flow)
    var flowPercent: Double = 0.6

    var body: some View {
        SummaryCardView(title: "Daily Flow Summary", subtitle: "Today") {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                        .frame(width: 72, height: 72)
                    Circle()
                        .trim(from: 0, to: flowPercent)
                        .stroke(DriftColorPalette.cyan, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 72, height: 72)
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(flowPercent * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(flowPercent * 100))% Flow")
                        .font(.subheadline)
                        .foregroundStyle(DriftColorPalette.cyan)
                    Text("\(Int((1 - flowPercent) * 100))% Drift")
                        .font(.subheadline)
                        .foregroundStyle(DriftColorPalette.redMagenta)
                }
                Spacer(minLength: 0)
            }
            .padding(.top, 8)
        }
    }
}
