//
//  GlassGradientBackground.swift
//  Drift
//
//  Reusable animated pixelated glass-gradient (image_0 palette) with optional noise and
//  chromatic-style glitch. intensity: true = Splash (hypnotic); false = Home (quiet).
//  Note: GPU-heavy; on Watch or low-power devices consider a static gradient or reduced animation.
//  iOS 17+ could use a .metal shader with colorEffect for stronger chromatic aberration.
//

import SwiftUI

struct GlassGradientBackground: View {
    /// true = full intensity (Splash), false = subdued (Home)
    var intensity: Bool = true

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack {
                // Base: vertical gradient with time-based shift for weaving
                baseGradient(t: t)
                    .drawingGroup()

                // Noise overlay (granular / pixelated feel)
                noiseOverlay(t: t)
                    .opacity(intensity ? 0.25 : 0.12)
                    .blendMode(.overlay)
                    .drawingGroup()

                // Chromatic-style glitch: slight RGB offset simulation via overlay
                if intensity {
                    chromaticOverlay(t: t)
                        .blendMode(.screen)
                        .opacity(0.15)
                        .drawingGroup()
                }
            }
            .opacity(intensity ? 1.0 : 0.5)
        }
        .ignoresSafeArea()
    }

    private func baseGradient(t: TimeInterval) -> some View {
        let phase = t * 0.15
        return LinearGradient(
            stops: DriftColorPalette.gradientStops,
            startPoint: UnitPoint(x: 0.5 + sin(phase) * 0.2, y: 0),
            endPoint: UnitPoint(x: 0.5 + cos(phase * 1.1) * 0.2, y: 1)
        )
        .overlay(
            AngularGradient(
                colors: [
                    DriftColorPalette.yellow.opacity(0.4),
                    DriftColorPalette.deepPurple.opacity(0.5),
                    DriftColorPalette.cyan.opacity(0.4),
                ],
                center: .center
            )
            .opacity(0.5)
        )
    }

    private func noiseOverlay(t: TimeInterval) -> some View {
        Canvas { context, size in
            let seed = Int(t * 100) % 10000
            for x in stride(from: 0, to: size.width, by: 4) {
                for y in stride(from: 0, to: size.height, by: 4) {
                    let v = pseudoRandom(x: Int(x), y: Int(y), seed: seed)
                    let gray = Color.white.opacity(v * 0.3)
                    context.fill(
                        Path(CGRect(x: x, y: y, width: 4, height: 4)),
                        with: .color(gray)
                    )
                }
            }
        }
    }

    private func chromaticOverlay(t: TimeInterval) -> some View {
        let offset = 2.0 + sin(t * 3) * 1.5
        return HStack(spacing: 0) {
            DriftColorPalette.redMagenta.opacity(0.3)
                .frame(width: offset)
            DriftColorPalette.cyan.opacity(0.2)
                .frame(width: offset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .blur(radius: 8)
    }

    private func pseudoRandom(x: Int, y: Int, seed: Int) -> Double {
        let n = x &* 73856093 &+ y &* 19349663 &+ seed &* 83492791
        return Double(abs(n % 1000)) / 1000.0
    }
}
