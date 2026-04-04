//
//  NavyShaderLinesBackground.swift
//  Drift
//
//  Full-screen navy gradient with four animated “plasma” wave strokes (Canvas), inspired by
//  the WebGL shader reference—implemented natively for SwiftUI.
//

import SwiftUI

struct NavyShaderLinesBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 45.0)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let top = DriftColorPalette.navyDeep
                let mid = DriftColorPalette.navyMid
                let bottom = DriftColorPalette.navyIndigo
                let rect = Path(CGRect(origin: .zero, size: size))
                // GraphicsContext shading uses CGPoint in canvas coordinates (not UnitPoint).
                context.fill(
                    rect,
                    with: .linearGradient(
                        Gradient(colors: [top, mid, bottom]),
                        startPoint: CGPoint(x: size.width * 0.15, y: 0),
                        endPoint: CGPoint(x: size.width * 0.85, y: size.height)
                    )
                )

                let lineColors: [Color] = [
                    DriftColorPalette.waveLine1,
                    DriftColorPalette.waveLine2,
                    DriftColorPalette.waveLine3,
                    DriftColorPalette.waveLine4,
                ]

                for i in 0 ..< 4 {
                    var path = Path()
                    let verticalSpread = size.height * 0.18
                    let baseY = size.height * (0.22 + CGFloat(i) * 0.14)
                    let freq = Double(i + 1) * 0.35 + 1.2
                    let speed = 0.25 + Double(i) * 0.06
                    path.move(to: CGPoint(x: 0, y: baseY))

                    var x: CGFloat = 0
                    while x <= size.width {
                        let nx = Double(x / max(size.width, 1))
                        let wobble =
                            sin(t * speed + nx * .pi * 2 * freq + Double(i) * 0.7) * 0.5
                            + cos(t * speed * 1.3 + nx * .pi * 3 + Double(i)) * 0.35
                        let y = baseY + CGFloat(wobble) * verticalSpread
                            + sin(nx * .pi * 4 + t * 0.4 + Double(i)) * verticalSpread * 0.25
                        path.addLine(to: CGPoint(x: x, y: y))
                        x += 3
                    }

                    context.stroke(
                        path,
                        with: .color(lineColors[i].opacity(0.42 + Double(i) * 0.06)),
                        style: StrokeStyle(lineWidth: CGFloat(1.2 + Double(i) * 0.35), lineCap: .round, lineJoin: .round)
                    )
                }
            }
            .blur(radius: 0.8)
        }
        .ignoresSafeArea()
    }
}
