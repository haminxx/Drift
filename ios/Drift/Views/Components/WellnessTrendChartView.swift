//
//  WellnessTrendChartView.swift
//  Drift
//
//  HRV over time from local history (filled after successful backend samples). Charts framework (iOS 16+).
//

import SwiftUI
import Charts

struct WellnessTrendChartView: View {
    @ObservedObject private var history = WellnessHistoryStore.shared

    private var window: [WellnessSample] {
        history.samples(inLastHours: 24)
    }

    var body: some View {
        SummaryCardView(
            icon: { Image(systemName: "chart.xyaxis.line").foregroundStyle(DriftColorPalette.cyan) },
            title: "HRV & flow (24h)",
            subtitle: "From saved samples"
        ) {
            if window.isEmpty {
                Text("Graph fills when HRV posts succeed against your backend.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            } else if #available(iOS 16.0, *) {
                chartContent
                    .frame(height: 180)
                    .padding(.top, 8)
            } else {
                Text("Charts need iOS 16 or later.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @available(iOS 16.0, *)
    private var chartContent: some View {
        Chart(window) { sample in
            LineMark(
                x: .value("Time", sample.date),
                y: .value("HRV ms", sample.hrvSDNN)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(DriftColorPalette.blue.gradient)

            PointMark(
                x: .value("Time", sample.date),
                y: .value("HRV ms", sample.hrvSDNN)
            )
            .foregroundStyle(pointColor(for: sample))
        }
        .chartXAxis(.automatic)
        .chartYAxisLabel("HRV (ms)")
    }

    private func pointColor(for sample: WellnessSample) -> Color {
        if sample.serverInFlow == true { return DriftColorPalette.cyan }
        if sample.serverInFlow == false { return DriftColorPalette.redMagenta }
        return Color.secondary.opacity(0.5)
    }
}
