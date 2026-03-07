//
//  HealthKitManager.swift
//  Drift
//
//  iOS: Request HealthKit read permission for HR and HRV; observe new HRV (and optional HR)
//  samples so data from Garmin (via Garmin Connect → Apple Health) or any Health source
//  feeds the same pipeline as the Apple Watch. Entitlement: HealthKit read capability,
//  NSHealthShareUsageDescription (and NSHealthUpdateUsageDescription if you write).
//

import Foundation
#if canImport(HealthKit)
import HealthKit
#endif

#if canImport(HealthKit)
final class HealthKitManager {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()

    /// Called for each new HRV sample; set to forward payloads to APIClient (e.g. for Garmin/Health pipeline).
    var onHRVSample: ((HRVPayload) -> Void)?

    private var hrvQuery: HKAnchoredObjectQuery?
    private let queue = DispatchQueue(label: "com.drift.healthkit")

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
                    self?.startObservingHRV()
                    self?.enableBackgroundDeliveryIfSupported(for: hrv)
                }
            }
        }
    }

    /// Start observing new HRV samples (e.g. from Garmin Connect sync to Health).
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
            DispatchQueue.main.async { [weak self] in
                self?.onHRVSample?(payload)
            }
        }
    }

    /// Optional: enable background delivery for HRV so updates can be delivered when app is not in foreground.
    private func enableBackgroundDeliveryIfSupported(for type: HKQuantityType) {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        store.enableBackgroundDelivery(for: type, frequency: .immediate) { _, _ in }
    }
}
#else
final class HealthKitManager {
    static let shared = HealthKitManager()
    var onHRVSample: ((HRVPayload) -> Void)?
    func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        completion(false)
    }
    func startObservingHRV() {}
}
#endif
