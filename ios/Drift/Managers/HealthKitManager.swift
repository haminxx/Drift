//
//  HealthKitManager.swift
//  Drift
//
//  iOS: HealthKit HRV/HR, 7-day baseline, local stress vs flow, observer + anchored query.
//  Garmin path: Connect → Apple Health → same pipeline.
//

import Foundation
#if canImport(HealthKit)
import HealthKit
#endif

#if canImport(HealthKit)
final class HealthKitManager {
    static let shared = HealthKitManager()

    enum BiometricStressLevel {
        case flow
        case stressed
        case unknown
    }

    var onHRVSample: ((HRVPayload) -> Void)?
    /// Local HRV vs baseline (Prompt 2 / FlowStateManager).
    var onBiometricEvaluation: ((Double, Double?, BiometricStressLevel) -> Void)?

    /// Last 0...1 stress score for wellness history (1 = stressed).
    private(set) var lastLocalStressScore: Double = 0

    private let store = HKHealthStore()
    private var hrvQuery: HKAnchoredObjectQuery?
    private var hrvObserver: HKObserverQuery?
    private(set) var rollingBaselineHRV: Double?

    func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        guard let hr = HKQuantityType.quantityType(forIdentifier: .heartRate),
              let hrv = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            completion(false)
            return
        }
        store.requestAuthorization(toShare: [], read: [hr, hrv]) { [weak self] success, _ in
            DispatchQueue.main.async {
                completion(success)
                if success {
                    self?.refreshBaseline { _ in }
                    self?.startObservingHRV()
                    self?.startHRVObserverQuery()
                    self?.enableBackgroundDeliveryIfSupported(for: hrv)
                }
            }
        }
    }

    /// Recompute 7-day average HRV (SDNN, ms).
    func refreshBaseline(completion: ((Double?) -> Void)? = nil) {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            completion?(nil)
            return
        }
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -7, to: end) ?? end.addingTimeInterval(-7 * 86400)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let query = HKStatisticsQuery(
            quantityType: hrvType,
            quantitySamplePredicate: predicate,
            options: .discreteAverage
        ) { [weak self] _, result, _ in
            let ms = result?.averageQuantity()?.doubleValue(for: HKUnit.secondUnit(with: .milli))
            DispatchQueue.main.async {
                self?.rollingBaselineHRV = ms
                completion?(ms)
            }
        }
        store.execute(query)
    }

    func startObservingHRV() {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)
        hrvQuery = HKAnchoredObjectQuery(
            type: hrvType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            self?.processHRVSamples(samples ?? [])
        }
        hrvQuery?.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.processHRVSamples(samples ?? [])
        }
        store.execute(hrvQuery!)
    }

    private func startHRVObserverQuery() {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        hrvObserver = HKObserverQuery(sampleType: hrvType, predicate: nil) { [weak self] _, completionHandler, _ in
            self?.refreshBaseline { _ in }
            completionHandler()
        }
        if let hrvObserver {
            store.execute(hrvObserver)
        }
    }

    private func processHRVSamples(_ samples: [HKSample]) {
        guard let quantitySamples = samples as? [HKQuantitySample] else { return }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        for sample in quantitySamples {
            let valueMs = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
            let payload = HRVPayload(
                timestamp: formatter.string(from: sample.startDate),
                hrvSDNN: valueMs,
                heartRate: nil,
                deviceId: "health",
                sessionId: nil
            )
            let level = evaluate(hrvMs: valueMs)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.onHRVSample?(payload)
                self.onBiometricEvaluation?(valueMs, self.rollingBaselineHRV, level)
                let stress: Double = level == .stressed ? 1.0 : (level == .flow ? 0.0 : 0.4)
                self.lastLocalStressScore = stress
            }
        }
    }

    private func evaluate(hrvMs: Double) -> BiometricStressLevel {
        guard let baseline = rollingBaselineHRV, baseline > 0 else {
            print("HRV evaluation: baseline not ready")
            return .unknown
        }
        let ratio = hrvMs / baseline
        let level: BiometricStressLevel
        if ratio < 0.75 {
            level = .stressed
            print("Stressed (HRV ratio \(String(format: "%.2f", ratio)))")
        } else if ratio >= 0.9 {
            level = .flow
            print("Flow State (HRV ratio \(String(format: "%.2f", ratio)))")
        } else {
            level = .unknown
        }
        return level
    }

    private func enableBackgroundDeliveryIfSupported(for type: HKQuantityType) {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        store.enableBackgroundDelivery(for: type, frequency: .immediate) { _, _ in }
    }
}
#else
final class HealthKitManager {
    static let shared = HealthKitManager()
    enum BiometricStressLevel { case flow, stressed, unknown }
    var onHRVSample: ((HRVPayload) -> Void)?
    var onBiometricEvaluation: ((Double, Double?, BiometricStressLevel) -> Void)?
    var lastLocalStressScore: Double = 0
    var rollingBaselineHRV: Double?
    func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) { completion(false) }
    func startObservingHRV() {}
    func refreshBaseline(completion: ((Double?) -> Void)? = nil) { completion?(nil) }
}
#endif
