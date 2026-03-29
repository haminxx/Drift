//
//  ShieldTimerManager.swift
//  Drift
//
//  When "focus drifting" is detected (backend returns is_in_flow == false), starts a 5-minute
//  countdown and fires a Time-Sensitive local notification. On expiry, calls ShieldManager to apply shield.
//  If backend returns is_in_flow == true before expiry, cancels timer and does not shield.
//  Entitlement: Time-Sensitive Notifications (capability + user Settings).
//

import Foundation
import UserNotifications

@MainActor
final class ShieldTimerManager: ObservableObject {
    static let shared = ShieldTimerManager()

    /// Configurable warning duration in seconds (default 5 minutes).
    var warningDuration: TimeInterval = 5 * 60

    /// Remaining seconds on the countdown; 0 when idle or expired. Bind UI to this.
    @Published private(set) var remainingSeconds: TimeInterval = 0

    /// Whether the warning timer is currently active.
    var isTimerActive: Bool { remainingSeconds > 0 }

    private var timerTask: Task<Void, Never>?
    private var timerStartDate: Date?

    /// Called when timer expires so ShieldManager can apply the shield.
    var onTimerExpired: (() -> Void)?

    private init() {}

    /// Call when backend returns is_in_flow == false: start countdown and post notification.
    func startWarning() {
        cancelWarning()
        requestNotificationPermissionIfNeeded()
        let duration = UserPreferencesStore.shared.warningBeforeShieldDuration
        warningDuration = duration
        scheduleTimeSensitiveNotification(minutes: UserPreferencesStore.shared.warningBeforeShieldMinutes)
        remainingSeconds = duration
        timerStartDate = Date()
        timerTask = Task { [weak self] in
            await self?.runTimer()
        }
    }

    /// Call when backend returns is_in_flow == true before expiry: cancel countdown, do not shield.
    func cancelWarning() {
        timerTask?.cancel()
        timerTask = nil
        remainingSeconds = 0
        timerStartDate = nil
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["drift.focus.drifting"])
    }

    private func runTimer() async {
        let step: TimeInterval = 1
        while remainingSeconds > 0 {
            try? await Task.sleep(nanoseconds: UInt64(step * 1_000_000_000))
            guard !Task.isCancelled else { return }
            let elapsed = Date().timeIntervalSince(timerStartDate ?? Date())
            let remaining = max(0, warningDuration - elapsed)
            remainingSeconds = remaining
            if remaining <= 0 {
                onTimerExpired?()
                break
            }
        }
    }

    private func requestNotificationPermissionIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func scheduleTimeSensitiveNotification(minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Focus drifting"
        content.body = "Entertainment apps will lock in \(minutes) minute\(minutes == 1 ? "" : "s")."
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "drift.focus.drifting", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
