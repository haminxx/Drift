//
//  HomeDashboardView.swift
//  Drift
//
//  Upper 2/3: quiet glass gradient + current cognitive state (Locked In / Drift Detected).
//  Lower 1/3: grid of summary cards (image_2 style). Card D uses Screen Time / Family Controls
//  entitlement; Card C uses HealthKit — see docs/ENTITLEMENTS.md and Xcode Signing & Capabilities.
//

import SwiftUI

struct HomeDashboardView: View {
    /// Placeholder; later bind to APIClient / flow state
    private var isInFlow: Bool = true

    @State private var haloScale: CGFloat = 1.0
    @State private var haloOpacity: Double = 0.5

    var body: some View {
        ZStack {
            GlassGradientBackground(intensity: false)
            VStack(spacing: 0) {
                upperSection
                lowerSection
            }
        }
        .ignoresSafeArea(edges: .top)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                haloScale = 1.15
                haloOpacity = 0.25
            }
        }
    }

    private var upperSection: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(haloOpacity), lineWidth: 2)
                    .frame(width: 140, height: 140)
                    .scaleEffect(haloScale)
                Text(cognitiveStateTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .frame(height: 200)
            Text(cognitiveStateSubtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height * 2 / 3)
    }

    private var cognitiveStateTitle: String {
        isInFlow ? "Locked In\n(Flow State)" : "Drift Detected"
    }

    private var cognitiveStateSubtitle: String {
        isInFlow ? "You're in the zone." : "Consider a short break."
    }

    private var lowerSection: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    DailyFlowSummaryCard()
                    PatternIdentificationCard()
                }
                BioDataAverageCard()
                InterventionStatusCard()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Color.white.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
