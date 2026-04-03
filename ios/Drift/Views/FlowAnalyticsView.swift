//
//  FlowAnalyticsView.swift
//  Drift
//
//  Ultrahuman-inspired dark analytics: Flow Index, 7-day bars, stage breakdown (mock), timeline chart.
//

import Charts
import SwiftUI

private enum FlowPalette {
    static let deep = Color(red: 0.08, green: 0.32, blue: 0.36)
    static let light = Color(red: 0.2, green: 0.55, blue: 0.58)
    static let working = Color(red: 0.35, green: 0.7, blue: 0.55)
    static let distracted = Color.white.opacity(0.55)
    static let bgTop = Color(red: 0.06, green: 0.18, blue: 0.22)
    static let bgBottom = Color.black
}

private struct FlowStageMock: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let duration: String
    let percent: Int
}

private struct FlowTimelineSegment: Identifiable {
    let id = UUID()
    let start: Date
    let end: Date
    let stage: String
    let color: Color
}

private struct DailyFlowScore: Identifiable {
    let id = UUID()
    let day: Date
    let score: Int
}

struct FlowAnalyticsView: View {
    @ObservedObject private var history = WellnessHistoryStore.shared
    @ObservedObject private var flow = FlowStateManager.shared
    @ObservedObject private var session = DriftSessionState.shared

    private var flowIndex: Int {
        let cal = Calendar.current
        let today = history.samples.filter { cal.isDateInToday($0.date) }
        let share: Double
        if today.isEmpty {
            share = 0.55
        } else {
            let ok = today.filter { $0.serverInFlow == true }.count
            share = Double(ok) / Double(today.count)
        }
        let hrvPart = flow.hrvRelativeToBaseline
        let serverBoost = (session.lastServerInFlow == true) ? 0.08 : 0.0
        let blended = (share * 0.5 + hrvPart * 0.42 + serverBoost) * 100
        return min(100, max(18, Int(blended.rounded())))
    }

    private var mockStages: [FlowStageMock] {
        [
            FlowStageMock(name: "Deep Focus", color: FlowPalette.deep, duration: "2h 15m", percent: 30),
            FlowStageMock(name: "Light Focus", color: FlowPalette.light, duration: "3h 02m", percent: 42),
            FlowStageMock(name: "Working", color: FlowPalette.working, duration: "1h 20m", percent: 18),
            FlowStageMock(name: "Distracted", color: FlowPalette.distracted, duration: "48m", percent: 10),
        ]
    }

    private var dailyScores: [DailyFlowScore] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0 ..< 7).compactMap { offset -> DailyFlowScore? in
            guard let day = cal.date(byAdding: .day, value: -6 + offset, to: today) else { return nil }
            let daySamples = history.samples.filter { cal.isDate($0.date, inSameDayAs: day) }
            let score: Int
            if daySamples.isEmpty {
                let fallbacks = [48, 55, 52, 61, 58, 67, flowIndex]
                score = fallbacks[offset]
            } else {
                let ok = daySamples.filter { $0.serverInFlow == true }.count
                score = Int(Double(ok) / Double(daySamples.count) * 100)
            }
            return DailyFlowScore(day: day, score: score)
        }
    }

    private var timelineSegments: [FlowTimelineSegment] {
        let cal = Calendar.current
        var start = cal.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        let endDay = cal.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()
        var segments: [FlowTimelineSegment] = []
        let stageCycle: [(String, Color)] = [
            ("Deep Focus", FlowPalette.deep),
            ("Light Focus", FlowPalette.light),
            ("Working", FlowPalette.working),
            ("Distracted", FlowPalette.distracted),
            ("Light Focus", FlowPalette.light),
            ("Deep Focus", FlowPalette.deep),
        ]
        var i = 0
        while start < endDay {
            let dur = Double([18, 25, 12, 8, 22, 15][i % 6]) * 60
            let next = min(start.addingTimeInterval(dur), endDay)
            let pair = stageCycle[i % stageCycle.count]
            segments.append(FlowTimelineSegment(start: start, end: next, stage: pair.0, color: pair.1))
            start = next
            i += 1
            if next >= endDay { break }
        }
        return segments
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                headerScores
                sevenDayChartWrapped
                stagesCard
                timelineCard
                statusFooter
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 120)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .background {
            LinearGradient(
                colors: [FlowPalette.bgTop, FlowPalette.bgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    private var headerScores: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Flow Index")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(flowIndex)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("/ 100")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.top, 8)
    }

    @available(iOS 16.0, *)
    private var sevenDayChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Last 7 days")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.55))
            Chart(dailyScores) { row in
                BarMark(
                    x: .value("Day", row.day, unit: .day),
                    y: .value("Flow", row.score)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [FlowPalette.light, FlowPalette.deep],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(6)
            }
            .chartYScale(domain: 0 ... 100)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { val in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.white.opacity(0.12))
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.white.opacity(0.1))
                    AxisValueLabel()
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
            .frame(height: 160)
        }
        .padding(16)
        .background(glassCardDark)
    }

    private var stagesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Flow stages today")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Illustrative split until on-device stage detection ships.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
            ForEach(mockStages) { s in
                HStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(s.color)
                        .frame(width: 10, height: 28)
                    Text(s.name)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                    Text("\(s.duration) · \(s.percent)%")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
        }
        .padding(16)
        .background(glassCardDark)
    }

    @available(iOS 16.0, *)
    private var timelineChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today's timeline")
                .font(.headline)
                .foregroundStyle(.white)
            Chart(timelineSegments) { seg in
                RectangleMark(
                    xStart: .value("Start", seg.start),
                    xEnd: .value("End", seg.end),
                    y: .value("Stage", seg.stage),
                    height: .fixed(22)
                )
                .foregroundStyle(seg.color)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                    AxisValueLabel(format: .dateTime.hour())
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            .frame(height: 200)
        }
        .padding(16)
        .background(glassCardDark)
    }

    @ViewBuilder
    private var timelineCard: some View {
        if #available(iOS 16.0, *) {
            timelineChart
        } else {
            Text("Timeline chart requires iOS 16+.")
                .foregroundStyle(.white.opacity(0.6))
                .padding()
        }
    }

    @ViewBuilder
    private var sevenDayChartWrapped: some View {
        if #available(iOS 16.0, *) {
            sevenDayChart
        } else {
            EmptyView()
        }
    }

    private var statusFooter: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Live status")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
            Text(flow.dashboardStatus.rawValue)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            if let h = flow.currentHRV {
                Text("HRV \(Int(h)) ms · baseline \(flow.baselineHRV.map { Int($0) } ?? 0) ms")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(glassCardDark)
    }

    private var glassCardDark: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.white.opacity(0.08))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
            }
    }
}
