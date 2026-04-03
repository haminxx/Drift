//
//  UserPreferencesStore.swift
//  Drift
//
//  Break length, warning countdown, focus schedule (local), unlock-required sustained flow minutes.
//

import Foundation
import SwiftUI

@MainActor
final class UserPreferencesStore: ObservableObject {
    static let shared = UserPreferencesStore()

    private static let kBreakBrick = "drift.breakBrickMinutes"
    private static let kWarning = "drift.warningBeforeShieldMinutes"
    private static let kFocusStart = "drift.focusScheduleStartMinutes"
    private static let kFocusEnd = "drift.focusScheduleEndMinutes"
    private static let kUnlockFlow = "drift.unlockRequiredFlowMinutes"

    @Published private(set) var breakBrickMinutes: Int
    @Published private(set) var warningBeforeShieldMinutes: Int
    /// Minutes from midnight (0–1439) when focus hours start (default 9:00).
    @Published private(set) var focusScheduleStartMinutes: Int
    /// Minutes from midnight when focus hours end (default 17:00).
    @Published private(set) var focusScheduleEndMinutes: Int
    /// Minutes of sustained local "flow" HRV before shields unlock after break (default 1).
    @Published private(set) var unlockRequiredFlowMinutes: Int

    var breakBrickDuration: TimeInterval { TimeInterval(breakBrickMinutes * 60) }
    var warningBeforeShieldDuration: TimeInterval { TimeInterval(warningBeforeShieldMinutes * 60) }
    var unlockRequiredFlowDuration: TimeInterval { TimeInterval(unlockRequiredFlowMinutes * 60) }

    private init() {
        let d = UserDefaults.standard
        breakBrickMinutes = d.object(forKey: Self.kBreakBrick) as? Int ?? 15
        warningBeforeShieldMinutes = d.object(forKey: Self.kWarning) as? Int ?? 5
        focusScheduleStartMinutes = d.object(forKey: Self.kFocusStart) as? Int ?? (9 * 60)
        focusScheduleEndMinutes = d.object(forKey: Self.kFocusEnd) as? Int ?? (17 * 60)
        unlockRequiredFlowMinutes = d.object(forKey: Self.kUnlockFlow) as? Int ?? 1
        breakBrickMinutes = min(120, max(1, breakBrickMinutes))
        warningBeforeShieldMinutes = min(60, max(1, warningBeforeShieldMinutes))
        focusScheduleStartMinutes = min(24 * 60 - 1, max(0, focusScheduleStartMinutes))
        focusScheduleEndMinutes = min(24 * 60, max(1, focusScheduleEndMinutes))
        unlockRequiredFlowMinutes = min(120, max(1, unlockRequiredFlowMinutes))
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

    func setFocusScheduleStartMinutes(_ value: Int) {
        let v = min(24 * 60 - 1, max(0, value))
        UserDefaults.standard.set(v, forKey: Self.kFocusStart)
        focusScheduleStartMinutes = v
    }

    func setFocusScheduleEndMinutes(_ value: Int) {
        let v = min(24 * 60, max(1, value))
        UserDefaults.standard.set(v, forKey: Self.kFocusEnd)
        focusScheduleEndMinutes = v
    }

    func setUnlockRequiredFlowMinutes(_ value: Int) {
        let v = min(120, max(1, value))
        UserDefaults.standard.set(v, forKey: Self.kUnlockFlow)
        unlockRequiredFlowMinutes = v
    }
}
