//
//  HealthKitManager.swift
//  Drift Watch App
//
//  Request HealthKit permissions for Heart Rate and HRV; start a mindfulness workout so the watch
//  collects HR/HRV in the background; subscribe to new HRV samples and send each via WatchConnectivity.
//  Entitlement: HealthKit capability, NSHealthShareUsageDescription / NSHealthUpdateUsageDescription,
//  Background Modes → Workout.
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

    /// Start a mindfulness workout so the watch continues to sample HR/HRV in the background.
    private func startMindfulnessSession(completion: @escaping (Bool) -> Void) {
        let config = HKWorkoutConfiguration()
        config.activityType = .mindfulness
        config.locationType = .unknown

        do {
            workoutSession = try HKWorkoutSession(healthStore: store, configuration: config)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)
            workoutSession?.startActivity(with: Date())
            workoutBuilder?.beginCollection(at: Date()) { [weak self] success, error in
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
        ) { [weak self] _, samples, _, _, error in
            guard let samples = samples as? [HKQuantitySample] else { return }
            for sample in samples {
                self?.emitHRVPayload(sample: sample)
            }
        }
        hrvQuery?.updateHandler = { [weak self] _, samples, _, _, _ in
            guard let samples = samples else { return }
            for sample in samples {
                self?.emitHRVPayload(sample: sample)
            }
        }
        store.execute(hrvQuery!)
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
        workoutBuilder?.endCollection(at: Date()) { [weak self] _, _ in
            self?.workoutSession?.end(at: Date())
            self?.workoutSession = nil
            self?.workoutBuilder = nil
        }
    }
}
