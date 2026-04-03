//
//  FlowStateManager.swift
//  Drift
//
//  Local stress / brick break state from HRV vs baseline. Break length comes from UserPreferencesStore.
//

import Foundation
import SwiftUI
import UserNotifications

@MainActor
final class FlowStateManager: ObservableObject {
    static let shared = FlowStateManager()

    enum DashboardStatus: String {
        case inFlow = "In Flow"
        case stressed = "Stressed"
        case breakTime = "Break Time"
        case waitingForFlow = "Restore focus"
    }

    @Published private(set) var dashboardStatus: DashboardStatus = .inFlow
    @Published var flowScore: Int = 0
    @Published var hrvRelativeToBaseline: Double = 0.5
    @Published var baselineHRV: Double?
    @Published var currentHRV: Double?
    @Published var breakRemainingSeconds: TimeInterval = 0

    var isInEnforcedBreak: Bool {
        dashboardStatus == .breakTime || dashboardStatus == .waitingForFlow
    }

    private var breakTimerTask: Task<Void, Never>?
    private var lastStressTriggerAt: Date?
    /// First time HRV looked like "flow" while waiting to unlock; used with unlockRequiredFlowMinutes.
    private var sustainedFlowStartedAt: Date?

    private init() {}

    func connectHealthKit(_ health: HealthKitManager) {
        health.onBiometricEvaluation = { [weak self] hrv, baseline, level in
            Task { @MainActor in
                self?.handleEvaluation(hrv: hrv, baseline: baseline, level: level)
            }
        }
    }

    private var breakDuration: TimeInterval {
        UserPreferencesStore.shared.breakBrickDuration
    }

    private func handleEvaluation(hrv: Double, baseline: Double?, level: HealthKitManager.BiometricStressLevel) {
        currentHRV = hrv
        baselineHRV = baseline
        if let b = baseline, b > 0 {
            hrvRelativeToBaseline = min(1, max(0, hrv / b))
        } else {
            hrvRelativeToBaseline = 0.5
        }

        switch level {
        case .stressed:
            if dashboardStatus == .waitingForFlow {
                sustainedFlowStartedAt = nil
            }
            if dashboardStatus != .breakTime, dashboardStatus != .waitingForFlow {
                enterStressedPath()
            }
        case .flow:
            if dashboardStatus == .waitingForFlow {
                considerSustainedFlowUnlock()
            } else if dashboardStatus != .breakTime {
                dashboardStatus = .inFlow
                sustainedFlowStartedAt = nil
            }
        case .unknown:
            break
        }
    }

    private func considerSustainedFlowUnlock() {
        let required = UserPreferencesStore.shared.unlockRequiredFlowDuration
        let now = Date()
        if sustainedFlowStartedAt == nil {
            sustainedFlowStartedAt = now
        }
        guard let start = sustainedFlowStartedAt else { return }
        if now.timeIntervalSince(start) >= required {
            completeRecoveryUnlock()
        }
    }

    private func enterStressedPath() {
        if let last = lastStressTriggerAt, Date().timeIntervalSince(last) < 30 { return }
        lastStressTriggerAt = Date()
        sustainedFlowStartedAt = nil
        dashboardStatus = .stressed
        postStressBreakNotification()
        ShieldManager.shared.applyShields()
        dashboardStatus = .breakTime
        startBreakCountdown()
    }

    private func startBreakCountdown() {
        breakTimerTask?.cancel()
        let duration = breakDuration
        breakRemainingSeconds = duration
        let start = Date()
        breakTimerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self else { return }
                let elapsed = Date().timeIntervalSince(start)
                let remaining = max(0, duration - elapsed)
                await MainActor.run {
                    self.breakRemainingSeconds = remaining
                    if remaining <= 0 {
                        self.dashboardStatus = .waitingForFlow
                        self.sustainedFlowStartedAt = nil
                        self.breakTimerTask?.cancel()
                        self.breakTimerTask = nil
                    }
                }
                if remaining <= 0 { break }
            }
        }
    }

    private func completeRecoveryUnlock() {
        breakTimerTask?.cancel()
        breakTimerTask = nil
        breakRemainingSeconds = 0
        sustainedFlowStartedAt = nil
        ShieldManager.shared.removeShields()
        flowScore += 1
        dashboardStatus = .inFlow
    }

    private func postStressBreakNotification() {
        let mins = UserPreferencesStore.shared.breakBrickMinutes
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        let content = UNMutableNotificationContent()
        content.title = "Stress detected"
        content.body = "Taking a \(mins)-minute break."
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "drift.stress.break", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
