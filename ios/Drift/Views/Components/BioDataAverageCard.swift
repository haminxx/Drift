//
//  BioDataAverageCard.swift
//  Drift
//
//  Card C: Current HRV + 7-day baseline from HealthKit pipeline.
//

import SwiftUI

struct BioDataAverageCard: View {
    @ObservedObject private var flow = FlowStateManager.shared

    var body: some View {
        SummaryCardView(
            icon: { Image(systemName: "heart.fill").foregroundStyle(DriftColorPalette.redMagenta) },
            title: "Bio-Data Average",
            subtitle: "From Health / watch"
        ) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Current HRV")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(flow.currentHRV.map { "\(Int($0)) ms" } ?? "—")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                HStack {
                    Text("7-day baseline")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(flow.baselineHRV.map { "\(Int($0)) ms" } ?? "—")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                HStack {
                    Text("vs baseline")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(flow.hrvRelativeToBaseline * 100))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .padding(.top, 4)
        }
    }
}
