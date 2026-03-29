//
//  ShieldManager.swift
//  Drift
//
//  FamilyControls + ManagedSettings. Pick apps to block in brick mode and essentials that stay open.
//  Effective shield = blocked minus essential. Entitlement: Family Controls in Xcode.
//

import Foundation
import FamilyControls
import ManagedSettings

final class ShieldManager: ObservableObject {
    static let shared = ShieldManager()

    private let store = ManagedSettingsStore()

    /// Apps to restrict when brick / shield is active.
    var blockedApplicationTokens: Set<ApplicationToken> = []

    /// Apps that remain accessible even when blocked list would cover them (always-allow).
    var essentialApplicationTokens: Set<ApplicationToken> = []

    /// Legacy: same as blocked list.
    var applicationTokensToShield: Set<ApplicationToken> {
        get { blockedApplicationTokens }
        set { blockedApplicationTokens = newValue }
    }

    private var effectiveShieldTokens: Set<ApplicationToken> {
        blockedApplicationTokens.subtracting(essentialApplicationTokens)
    }

    private init() {}

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

    func updateBlockedTokens(from selection: FamilyActivitySelection) {
        blockedApplicationTokens = selection.applicationTokens
    }

    func updateEssentialTokens(from selection: FamilyActivitySelection) {
        essentialApplicationTokens = selection.applicationTokens
    }

    func applyShields() {
        guard !effectiveShieldTokens.isEmpty else { return }
        store.shield.applications = effectiveShieldTokens
    }

    func removeShields() {
        store.shield.applications = nil
    }

    func applyShield() { applyShields() }
    func removeShield() { removeShields() }
}

struct AuthorizationResult {}
