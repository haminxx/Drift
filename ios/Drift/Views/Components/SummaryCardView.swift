//
//  SummaryCardView.swift
//  Drift
//
//  Base card style inspired by image_2: white rounded rectangle, subtle shadow, padding.
//  Supports optional leading icon, title, subtitle, and trailing chevron.
//

import SwiftUI

struct SummaryCardView<Content: View>: View {
    var icon: (() -> View)?
    var title: String?
    var subtitle: String?
    var showChevron: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let icon = icon {
                icon()
            }
            VStack(alignment: .leading, spacing: 4) {
                if let title = title {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

extension SummaryCardView where Content == EmptyView {
    init(
        icon: (() -> View)? = nil,
        title: String? = nil,
        subtitle: String? = nil,
        showChevron: Bool = false
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.showChevron = showChevron
        self.content = { EmptyView() }
    }
}
