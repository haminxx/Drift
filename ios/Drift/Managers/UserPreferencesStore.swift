//
//  UserPreferencesStore.swift
//  Drift
//
//  User-chosen break length (brick / stress break) and warning countdown before server-driven shield.
//  Backed by UserDefaults so values survive launches.
//

import Foundation
import SwiftUI

@MainActor
final class UserPreferencesStore: ObservableObject {
    static let shared = UserPreferencesStore()

    private static let kBreakBrick = "drift.breakBrickMinutes"
    private static let kWarning = "drift.warningBeforeShieldMinutes"

    /// Minutes for local stress / brick-mode break countdown (default 15).
    @Published private(set) var breakBrickMinutes: Int
    /// Minutes to wait after server says "drift" before applying shield (default 5).
    @Published private(set) var warningBeforeShieldMinutes: Int

    var breakBrickDuration: TimeInterval { TimeInterval(breakBrickMinutes * 60) }
    var warningBeforeShieldDuration: TimeInterval { TimeInterval(warningBeforeShieldMinutes * 60) }

    private init() {
        let d = UserDefaults.standard
        breakBrickMinutes = d.object(forKey: Self.kBreakBrick) as? Int ?? 15
        warningBeforeShieldMinutes = d.object(forKey: Self.kWarning) as? Int ?? 5
        breakBrickMinutes = min(120, max(1, breakBrickMinutes))
        warningBeforeShieldMinutes = min(60, max(1, warningBeforeShieldMinutes))
    }

    func setBreakBrickMinutes(_ value: Int) {
        let v = min(120, max(1, value))
        UserDefaults.standard.set(v, forKey: Self.kBreakBrick)
        breakBrickMinutes = v
    }

    func setWarningBeforeShieldMinutes(_ value: Int) {
        let v = min(60, max(1, value))
        UserDefaults.standard.set(v, forKey: Self.kWarning)
        warningBeforeShieldMinutes = v
    }
}
