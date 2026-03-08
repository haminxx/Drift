//
//  SplashView.swift
//  Drift
//
//  Stage 1: Full-screen animated glass gradient (2.5 s). Stage 2: Vertical reveal.
//  Stage 3: Solid background (white/black) + "drift" + Continue. Auto or button to Home.
//  Notification/background capabilities (Time-Sensitive Notifications, HealthKit background
//  delivery) are configured in Xcode Signing & Capabilities and Info.plist; see docs/ENTITLEMENTS.md.
//

import SwiftUI

enum SplashPhase {
    case stage1
    case stage2
    case stage3
}

struct SplashView: View {
    var onContinue: () -> Void

    @State private var phase: SplashPhase = .stage1
    @Environment(\.colorScheme) private var colorScheme
    /// Set to true for dramatic dark reveal (solid black); false or system = white
    @AppStorage("splashUseDarkReveal") private var useDarkReveal: Bool = false

    private var revealBackground: Color {
        (useDarkReveal || colorScheme == .dark) ? .black : .white
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Bottom layer: revealed area (solid background + "drift" + button)
                VStack {
                    Spacer()
                    revealedContent
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(revealBackground)

                // Top layer: gradient slides up to reveal content beneath
                GlassGradientBackground(intensity: true)
                    .frame(height: geo.size.height * 1.2)
                    .offset(y: phase == .stage1 ? 0 : -geo.size.height * 1.1)
                    .animation(.easeInOut(duration: 1.2), value: phase)
                    .allowsHitTesting(phase == .stage1)
            }
        }
        .onAppear {
            startSequence()
        }
    }

    private var revealedContent: some View {
        VStack(spacing: 32) {
            Text("drift")
                .font(.system(size: 42, weight: .light, design: .rounded))
                .foregroundStyle(glassyTitleStyle)
                .scaleEffect(pulseScale)
            Button("Continue") {
                onContinue()
            }
            .font(.headline)
            .foregroundStyle(revealBackground == .black ? .white : .primary)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(Capsule().stroke(revealBackground == .black ? Color.white : Color.primary, lineWidth: 1.5))
            .padding(.top, 8)
        }
    }

    private var glassyTitleStyle: some ShapeStyle {
        let base = revealBackground == .black ? Color.white : Color.primary
        return LinearGradient(
            colors: [base.opacity(0.9), base],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @State private var pulseScale: CGFloat = 1.0
    private var pulseScaleAnimation: Animation {
        .easeInOut(duration: 2).repeatForever(autoreverses: true)
    }

    private func startSequence() {
        pulseScale = 1.02
        withAnimation(pulseScaleAnimation) {
            pulseScale = 0.98
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                phase = .stage2
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            withAnimation {
                phase = .stage3
            }
        }
        // Auto-continue after 1.5 s on stage 3 (optional; user can tap Continue earlier)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if phase == .stage3 {
                onContinue()
            }
        }
    }
}
