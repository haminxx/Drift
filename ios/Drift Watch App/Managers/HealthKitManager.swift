//
//  HealthKitManager.swift
//  Drift Watch App
//
//  Request HealthKit permissions for Heart Rate and HRV; start a workout session so the watch
//  samples HR/HRV in the background; subscribe to new HRV samples and send each via WatchConnectivity.
//  Uses .mindAndBody for broad SDK compatibility (mindfulness type varies by OS version).
//

import Foundation
import HealthKit

final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var hrvQuery: HKAnchoredObjectQuery?

    /// Called with each new HRV payload to send to iPhone via WatchConnectivity.
    var onHRVSample: ((HRVPayload) -> Void)?

    private init() {}

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard let hr = HKQuantityType.quantityType(forIdentifier: .heartRate),
              let hrv = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            completion(false)
            return
        }
        store.requestAuthorization(toShare: [hr, hrv], read: [hr, hrv]) { [weak self] success, _ in
            guard success else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            self?.startMindfulnessSession(completion: completion)
        }
    }

    /// Start a workout session so the watch continues to sample HR/HRV in the background.
    private func startMindfulnessSession(completion: @escaping (Bool) -> Void) {
        let config = HKWorkoutConfiguration()
        // `.mindfulness` is not available on all watchOS SDKs; `.mindAndBody` is widely supported.
        config.activityType = .mindAndBody
        config.locationType = .unknown

        do {
            workoutSession = try HKWorkoutSession(healthStore: store, configuration: config)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)

            let start = Date()
            workoutSession?.startActivity(with: start)
            workoutBuilder?.beginCollection(withStart: start) { [weak self] success, _ in
                DispatchQueue.main.async {
                    completion(success)
                    if success {
                        self?.subscribeToHRV()
                    }
                }
            }
        } catch {
            DispatchQueue.main.async { completion(false) }
        }
    }

    private func subscribeToHRV() {
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
        for sample in quantitySamples {
            emitHRVPayload(sample: sample)
        }
    }

    private func emitHRVPayload(sample: HKQuantitySample) {
        let value = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let payload = HRVPayload(
            timestamp: formatter.string(from: sample.startDate),
            hrvSDNN: value,
            heartRate: nil,
            deviceId: nil,
            sessionId: nil
        )
        DispatchQueue.main.async { [weak self] in
            self?.onHRVSample?(payload)
        }
    }

    func stopSession() {
        let end = Date()
        workoutBuilder?.endCollection(withEnd: end) { [weak self] _, _ in
            self?.workoutSession?.end()
            self?.workoutSession = nil
            self?.workoutBuilder = nil
        }
    }
}
