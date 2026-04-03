//
//  InsightFeedView.swift
//  Drift
//
//  Mock AI-style insight cards (replace with backend later).
//

import SwiftUI

private struct InsightCard: Identifiable {
    let id = UUID()
    let kind: String
    let title: String
    let body: String
}

struct InsightFeedView: View {
    private let cards: [InsightCard] = [
        InsightCard(
            kind: "Quote",
            title: "Depth",
            body: "Your deepest work happens when you ignore the noise."
        ),
        InsightCard(
            kind: "Insight",
            title: "Afternoon dip",
            body: "You tend to get distracted around 2:30 PM. Try a preemptive 10-minute walk."
        ),
        InsightCard(
            kind: "Tip",
            title: "Yesterday",
            body: "You achieved 3 hours of Deep Focus yesterday. Great job!"
        ),
        InsightCard(
            kind: "Insight",
            title: "Recovery",
            body: "Shorter breaks under five minutes often help you return to flow faster after stress spikes."
        ),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                Text("Insights")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 4)

                ForEach(cards) { card in
                    insightCard(card)
                }
                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .background {
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.1, blue: 0.22),
                    Color.black,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    private func insightCard(_ card: InsightCard) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(card.kind.uppercased())
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.purple.opacity(0.9))
            Text(card.title)
                .font(.headline)
                .foregroundStyle(.white)
            Text(card.body)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.35), Color.purple.opacity(0.25)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
    }
}
