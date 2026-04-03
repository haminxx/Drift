//
//  DriftColorPalette.swift
//  Drift
//
//  App-wide dark navy / purple mood (glassmorphism Flow reference). Flow “blob” accents
//  remain available for the timeline visualization.
//

import SwiftUI

enum DriftColorPalette {
    // MARK: - Shell / backgrounds

    static let navyDeep = Color(red: 0.04, green: 0.06, blue: 0.14)
    static let navyMid = Color(red: 0.07, green: 0.09, blue: 0.22)
    static let navyIndigo = Color(red: 0.1, green: 0.08, blue: 0.22)
    static let purpleNight = Color(red: 0.12, green: 0.1, blue: 0.26)

    /// Welcome / Flow line accents (muted electric blues & violets)
    static let waveLine1 = Color(red: 0.35, green: 0.45, blue: 0.85)
    static let waveLine2 = Color(red: 0.45, green: 0.35, blue: 0.75)
    static let waveLine3 = Color(red: 0.3, green: 0.55, blue: 0.82)
    static let waveLine4 = Color(red: 0.55, green: 0.4, blue: 0.9)

    // MARK: - Flow visualization (reference: purple → blue → teal → warm center)

    static let flowPurple = Color(red: 0.42, green: 0.22, blue: 0.62)
    static let flowBlue = Color(red: 0.2, green: 0.45, blue: 0.95)
    static let flowTeal = Color(red: 0.2, green: 0.72, blue: 0.78)
    static let flowAmber = Color(red: 1.0, green: 0.78, blue: 0.35)
    static let flowOrange = Color(red: 1.0, green: 0.55, blue: 0.28)

    /// Glass insight card fill (deep purple)
    static let insightCardFill = Color(red: 0.14, green: 0.1, blue: 0.28)

    // MARK: - Legacy chromatic stops (kept for angular accents if needed)

    static let yellow = Color(red: 1.0, green: 0.95, blue: 0.35)
    static let orange = Color(red: 1.0, green: 0.55, blue: 0.2)
    static let redMagenta = Color(red: 0.85, green: 0.2, blue: 0.4)
    static let deepPurple = Color(red: 0.35, green: 0.1, blue: 0.5)
    static let blue = Color(red: 0.25, green: 0.45, blue: 0.95)
    static let cyan = Color(red: 0.2, green: 0.85, blue: 0.95)

    static var gradientStops: [Gradient.Stop] {
        [
            .init(color: navyDeep, location: 0),
            .init(color: navyMid, location: 0.35),
            .init(color: navyIndigo, location: 0.65),
            .init(color: purpleNight, location: 1),
        ]
    }

    static var linearGradient: LinearGradient {
        LinearGradient(stops: gradientStops, startPoint: .top, endPoint: .bottom)
    }

    static var angularGradient: AngularGradient {
        AngularGradient(
            colors: [flowPurple, flowBlue, flowTeal, flowAmber, flowPurple],
            center: .center
        )
    }
}
