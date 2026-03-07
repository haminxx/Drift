//
//  ShieldManager.swift
//  Drift
//
//  FamilyControls + ManagedSettings: apply shield to distracting apps when timer expires and
//  is_in_flow is still false; remove shield when flow state is restored.
//  Entitlement: Family Controls (Screen Time) capability in Xcode. App Store may require justification.
//

import Foundation
import FamilyControls
import ManagedSettings

final class ShieldManager: ObservableObject {
    static let shared = ShieldManager()

    private let store = ManagedSettingsStore()

    /// Application tokens to shield (from user's one-time Family Controls authorization).
    /// You will build a UI for the user to select apps; this holds the result.
    /// Set this after AuthorizationCenter.shared.requestAuthorization(for: .individual) and
    /// the user selecting which apps to manage.
    var applicationTokensToShield: Set<ApplicationToken> = []

    private init() {}

    /// One-time: request Screen Time authorization and let user select apps to manage.
    /// Call from your UI; then persist the chosen tokens into applicationTokensToShield.
    func requestAuthorization(completion: @escaping (Result<AuthorizationResult, Error>) -> Void) {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                await MainActor.run {
                    completion(.success(AuthorizationResult()))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }

    /// Call when 5-minute timer has expired and backend still returns is_in_flow == false.
    func applyShield() {
        guard !applicationTokensToShield.isEmpty else { return }
        store.shield.applications = applicationTokensToShield
    }

    /// Call when backend returns is_in_flow == true so user can access apps again.
    func removeShield() {
        store.shield.applications = nil
    }
}

/// Placeholder for authorization result (e.g. you might store that auth was granted).
struct AuthorizationResult {}
