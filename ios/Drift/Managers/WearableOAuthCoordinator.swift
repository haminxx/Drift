//
//  WearableOAuthCoordinator.swift
//  Drift
//
//  ASWebAuthenticationSession for Fitbit/Garmin OAuth; callback URL scheme "drift".
//  Independent from HealthKit (Apple Watch) pipeline.
//

import AuthenticationServices
import SwiftUI
import UIKit

enum WearableOAuthError: LocalizedError {
    case badAuthorizeURL
    case missingCallbackParameters
    case providerReturnedError(String)
    case sessionStartFailed
    case needsSignIn

    var errorDescription: String? {
        switch self {
        case .badAuthorizeURL: return "Invalid authorization URL from server."
        case .missingCallbackParameters: return "OAuth callback missing code or state."
        case .providerReturnedError(let s): return "Provider error: \(s)"
        case .sessionStartFailed: return "Could not start sign-in session."
        case .needsSignIn: return "Sign in with Firebase first to link cloud wearables."
        }
    }
}

@MainActor
final class WearableOAuthCoordinator: NSObject, ObservableObject {
    private var authSession: ASWebAuthenticationSession?

    func connectFitbit() async throws {
        let auth = try await APIClient.shared.fetchFitbitAuthorizeURL()
        try await runSession(urlString: auth.url, redirectUri: auth.redirectUri) { code, state in
            _ = try await APIClient.shared.exchangeFitbitOAuth(code: code, state: state, redirectUri: auth.redirectUri)
        }
    }

    func connectGarmin() async throws {
        let auth = try await APIClient.shared.fetchGarminAuthorizeURL()
        try await runSession(urlString: auth.url, redirectUri: auth.redirectUri) { code, state in
            _ = try await APIClient.shared.exchangeGarminOAuth(code: code, state: state, redirectUri: auth.redirectUri)
        }
    }

    private func runSession(
        urlString: String,
        redirectUri _: String,
        exchange: @escaping (String, String) async throws -> Void
    ) async throws {
        guard let url = URL(string: urlString) else { throw WearableOAuthError.badAuthorizeURL }

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "drift") { [weak self] callbackURL, error in
                self?.authSession = nil
                if let error = error {
                    let ns = error as NSError
                    // User dismissed the sheet (code 1 on AuthenticationServices domain).
                    if ns.domain == "com.apple.AuthenticationServices.WebAuthenticationSession", ns.code == 1 {
                        cont.resume(throwing: CancellationError())
                        return
                    }
                    cont.resume(throwing: error)
                    return
                }
                guard let callbackURL else {
                    cont.resume(throwing: WearableOAuthError.missingCallbackParameters)
                    return
                }
                let items = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems ?? []
                if let err = items.first(where: { $0.name == "error" })?.value {
                    cont.resume(throwing: WearableOAuthError.providerReturnedError(err))
                    return
                }
                guard let code = items.first(where: { $0.name == "code" })?.value,
                      let state = items.first(where: { $0.name == "state" })?.value else {
                    cont.resume(throwing: WearableOAuthError.missingCallbackParameters)
                    return
                }
                Task {
                    do {
                        try await exchange(code, state)
                        cont.resume()
                    } catch {
                        cont.resume(throwing: error)
                    }
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = true
            authSession = session
            if !session.start() {
                cont.resume(throwing: WearableOAuthError.sessionStartFailed)
            }
        }
    }
}

extension WearableOAuthCoordinator: ASWebAuthenticationSessionPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow } ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first
                ?? UIWindow()
        }
    }
}
