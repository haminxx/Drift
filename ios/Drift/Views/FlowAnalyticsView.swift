//
//  FlowAnalyticsView.swift
//  Drift
//
//  Flow “today” view: felt-time header, vertical timeline with soft glow blob, activity pills,
//  and insight cards (glassmorphism, dark navy / purple mood).
//

import SwiftUI

private struct FlowActivityPin: Identifiable {
    let id: String
    let label: String
    let yFraction: CGFloat
}

struct FlowAnalyticsView: View {
    @ObservedObject private var history = WellnessHistoryStore.shared
    @ObservedObject private var flow = FlowStateManager.shared

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
        let blended = (share * 0.5 + hrvPart * 0.42) * 100
        return min(100, max(18, Int(blended.rounded())))
    }

    /// Subjective “felt” hours (derived from flow index).
    private var feltLikeHours: Double {
        2.0 + Double(flowIndex) / 100.0 * 6.5
    }

    /// Wall time since 7:00 today (for “It’s been … hours”).
    private var elapsedHours: Double {
        let cal = Calendar.current
        guard let start = cal.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) else { return 8 }
        let end = Date()
        return max(0.5, end.timeIntervalSince(start) / 3600.0)
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: Date())
    }

    private var activityPins: [FlowActivityPin] {
        [
            FlowActivityPin(id: "working", label: String(localized: "flow.activity.working"), yFraction: 0.2),
            FlowActivityPin(id: "meeting", label: String(localized: "flow.activity.meeting"), yFraction: 0.48),
            FlowActivityPin(id: "walking", label: String(localized: "flow.activity.walking"), yFraction: 0.82),
        ]
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                headerBlock

                flowRhythmBlock
                    .frame(height: 420)

                insightsBlock

                statusFooter
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 100)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .background {
            DriftColorPalette.linearGradient
                .ignoresSafeArea()
        }
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(formattedDate)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.55))

            Text(String(localized: "flow.header.felt_prefix"))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(String(format: "%.1f", feltLikeHours))
                    .font(.system(size: 56, weight: .thin, design: .rounded))
                    .foregroundStyle(.white)
                Text(String(localized: "flow.header.hours_unit"))
                    .font(.title3.weight(.light))
                    .foregroundStyle(.white.opacity(0.45))
            }

            Text(
                String(
                    format: String(localized: "flow.header.elapsed_format"),
                    locale: .current,
                    arguments: [elapsedHours]
                )
            )
            .font(.footnote)
            .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.top, 4)
    }

    private var flowRhythmBlock: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .leading) {
                timeAxisLabels(totalHeight: h)
                    .frame(width: 44)

                flowGlowBlob
                    .frame(width: w * 0.42, height: h * 0.92)
                    .position(x: w * 0.45, y: h * 0.5)

                activityConnectors(size: CGSize(width: w, height: h))
            }
        }
    }

    private func timeAxisLabels(totalHeight: CGFloat) -> some View {
        let labels = ["7 AM", "9 AM", "12 PM", "3 PM", "6 PM"]
        return VStack(spacing: 0) {
            ForEach(0 ..< labels.count, id: \.self) { i in
                Text(labels[i])
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.38))
                if i < labels.count - 1 {
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var flowGlowBlob: some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            DriftColorPalette.flowPurple.opacity(0.85),
                            DriftColorPalette.flowBlue.opacity(0.75),
                            DriftColorPalette.flowTeal.opacity(0.65),
                            DriftColorPalette.flowAmber.opacity(0.55),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blur(radius: 28)
                .scaleEffect(x: 1.1, y: 1.05)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            DriftColorPalette.flowBlue.opacity(0.4),
                            DriftColorPalette.flowOrange.opacity(0.35),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blur(radius: 40)
                .scaleEffect(0.85)
        }
        .opacity(0.95)
    }

    private func activityConnectors(size: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(activityPins) { pin in
                let y = size.height * pin.yFraction
                HStack(spacing: 0) {
                    Spacer()
                        .frame(width: size.width * 0.52)
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: size.width * 0.12, height: 1)
                    Text(pin.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background {
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .overlay {
                                    Capsule()
                                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                                }
                        }
                }
                .position(x: size.width * 0.74, y: y)
            }
        }
        .allowsHitTesting(false)
    }

    private var insightsBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(String(localized: "flow.insights.title"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.45))
                .textCase(.uppercase)
                .tracking(1.2)

            insightCard(
                title: String(localized: "flow.insight.card1.title"),
                subtitle: String(localized: "flow.insight.card1.subtitle")
            )
            insightCard(
                title: String(localized: "flow.insight.card2.title"),
                subtitle: String(localized: "flow.insight.card2.subtitle")
            )
        }
    }

    private func insightCard(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white.opacity(0.95))
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.45))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(DriftColorPalette.insightCardFill.opacity(0.92))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.06),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: DriftColorPalette.flowPurple.opacity(0.15), radius: 20, y: 8)
        }
    }

    private var statusFooter: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "flow.status.live"))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.4))
                .textCase(.uppercase)
            Text(flow.dashboardStatus.rawValue)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
            if let h = flow.currentHRV {
                Text(
                    String(
                        format: String(localized: "flow.status.hrv_format"),
                        locale: .current,
                        arguments: [Int(h), flow.baselineHRV.map { Int($0) } ?? 0]
                    )
                )
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.07))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                }
        }
    }
}
