//
//  DailyFlowSummaryCard.swift
//  Drift
//
//  Card A: Flow vs drift share from today's saved backend samples (WellnessHistoryStore).
//

import SwiftUI

struct DailyFlowSummaryCard: View {
    @ObservedObject private var history = WellnessHistoryStore.shared

    private var flowPercent: Double {
        let cal = Calendar.current
        let today = history.samples.filter { cal.isDateInToday($0.date) }
        guard !today.isEmpty else { return 0.55 }
        let inFlow = today.filter { $0.serverInFlow == true }.count
        return Double(inFlow) / Double(today.count)
    }

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
