//
//  DriftSessionState.swift
//  Drift
//
//  Latest server flow verdict for correlating with local HRV history rows.
//

import Foundation

@MainActor
final class DriftSessionState: ObservableObject {
    static let shared = DriftSessionState()
    @Published var lastServerInFlow: Bool?
    private init() {}
}
