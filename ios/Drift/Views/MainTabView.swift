//
//  MainTabView.swift
//  Drift
//
//  Four-tab shell with custom floating glass bottom bar (Home, Flow, Lock, Insight).
//

import SwiftUI
import UIKit

enum DriftMainTab: Int, CaseIterable {
    case home, flow, lock, insight

    var title: String {
        switch self {
        case .home: return String(localized: "tab.home")
        case .flow: return String(localized: "tab.flow")
        case .lock: return String(localized: "tab.lock")
        case .insight: return String(localized: "tab.insight")
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .flow: return "waveform.path.ecg"
        case .lock: return "lock.fill"
        case .insight: return "sparkles"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: DriftMainTab = .home
    @Namespace private var tabSelectionNS

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeSereneView()
                case .flow:
                    FlowAnalyticsView()
                case .lock:
                    LockHubView()
                case .insight:
                    InsightFeedView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 96)

            FloatingGlassTabBar(selectedTab: $selectedTab, tabSelectionNS: tabSelectionNS)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
        .ignoresSafeArea(.keyboard)
    }
}

private struct FloatingGlassTabBar: View {
    @Binding var selectedTab: DriftMainTab
    var tabSelectionNS: Namespace.ID

    var body: some View {
        HStack(spacing: 0) {
            ForEach(DriftMainTab.allCases, id: \.rawValue) { tab in
                tabButton(tab)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.25), radius: 16, y: 6)
        }
        .frame(maxWidth: 420)
    }

    private func tabButton(_ tab: DriftMainTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            if tab != selectedTab {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .scaleEffect(isSelected ? 1.08 : 1.0)
                Text(tab.title)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.55))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                        .padding(.horizontal, 2)
                        .matchedGeometryEffect(id: "tabPill", in: tabSelectionNS)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
