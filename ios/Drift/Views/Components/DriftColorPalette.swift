//
//  DriftColorPalette.swift
//  Drift
//
//  Exact palette from image_0: Yellow → Orange → Red-Magenta → Deep Purple → Blue → Cyan.
//  Used by GlassGradientBackground and any glass/glitch UI.
//

import SwiftUI

enum DriftColorPalette {
    /// Bright sunny yellow (top of gradient)
    static let yellow = Color(red: 1.0, green: 0.95, blue: 0.35)
    /// Warm orange
    static let orange = Color(red: 1.0, green: 0.55, blue: 0.2)
    /// Deep red-magenta / crimson
    static let redMagenta = Color(red: 0.85, green: 0.2, blue: 0.4)
    /// Deep saturated purple (center)
    static let deepPurple = Color(red: 0.35, green: 0.1, blue: 0.5)
    /// Vivid blue
    static let blue = Color(red: 0.25, green: 0.45, blue: 0.95)
    /// Bright neon cyan (bottom)
    static let cyan = Color(red: 0.2, green: 0.85, blue: 0.95)

    /// All stops in order for gradient (top to bottom)
    static var gradientStops: [Gradient.Stop] {
        [
            .init(color: yellow, location: 0),
            .init(color: orange, location: 0.2),
            .init(color: redMagenta, location: 0.4),
            .init(color: deepPurple, location: 0.5),
            .init(color: blue, location: 0.7),
            .init(color: cyan, location: 1.0),
        ]
    }

    /// Linear gradient (vertical) for fallback / non-shader use
    static var linearGradient: LinearGradient {
        LinearGradient(stops: gradientStops, startPoint: .top, endPoint: .bottom)
    }

    /// Angular gradient for weaving/organic motion
    static var angularGradient: AngularGradient {
        AngularGradient(
            colors: [yellow, orange, redMagenta, deepPurple, blue, cyan, yellow],
            center: .center
        )
    }
}
