//
//  APIClient.swift
//  Drift
//
//  Posts HRV data to the Python backend and parses flow state response.
//  On is_in_flow == false, triggers ShieldTimerManager and notification.
//

import Foundation

final class APIClient: ObservableObject {
    static let shared = APIClient()

    /// Base URL for the backend (Render). Override in Xcode scheme or plist if needed.
    var baseURL: URL = URL(string: "https://drift-hrv-backend.onrender.com")!

    /// When set, the backend request will include Authorization: Bearer <token>. Set from FirebaseManager.getIdToken.
    var authTokenProvider: (() async -> String?)?

    private let session: URLSession = .shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    /// When flow state is false, this is called so ShieldTimerManager can start the 5-min timer and post notification.
    var onFlowStateLost: (() -> Void)?
    /// When flow state is true again, call so ShieldManager can remove shield and timer can cancel.
    var onFlowStateRestored: (() -> Void)?

    private init() {}

    /// Builds `baseURL/api/v1/...` with correct path segments (avoids encoding slashes as one component).
    private func apiURL(path: String) -> URL {
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var url = baseURL
        for part in trimmed.split(separator: "/") {
            url = url.appendingPathComponent(String(part))
        }
        return url
    }

    private static func extractHrvMs(from body: [String: Any]) -> Double? {
        guard let readings = body["readings"] as? [[String: Any]],
              let first = readings.first,
              let hrv = first["hrv_sdnn"] as? Double else { return nil }
        return hrv
    }

    /// POST a single HRV payload (or batch) to /api/v1/hrv_stream and handle response.
    func postHRVStream(_ payload: HRVPayload, completion: ((Result<FlowStateResponse, Error>) -> Void)? = nil) {
        var reading: [String: Any] = [
            "timestamp": payload.timestamp,
            "hrv_sdnn": payload.hrvSDNN,
        ]
        if let hr = payload.heartRate { reading["heart_rate"] = hr }
        var body: [String: Any] = ["readings": [reading]]
        if let did = payload.deviceId { body["device_id"] = did }
        if let sid = payload.sessionId { body["session_id"] = sid }
        postHRVStream(body: body, completion: completion)
    }

    /// POST request body (readings + optional device_id, session_id) to /api/v1/hrv_stream.
    func postHRVStream(body: [String: Any], completion: ((Result<FlowStateResponse, Error>) -> Void)? = nil) {
        let url = apiURL(path: "api/v1/hrv_stream")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        Task { @MainActor in
            if let provider = authTokenProvider, let token = await provider() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            let task = session.dataTask(with: request) { [decoder] data, _, error in
                if let error = error {
                    DispatchQueue.main.async { completion?(.failure(error)) }
                    return
                }
                guard let data = data else {
                    DispatchQueue.main.async { completion?(.failure(APIClientError.noData)) }
                    return
                }
                do {
                    let response = try decoder.decode(FlowStateResponse.self, from: data)
                    DispatchQueue.main.async {
                        DriftSessionState.shared.lastServerInFlow = response.isInFlow
                        if let hrv = Self.extractHrvMs(from: body) {
                            WellnessHistoryStore.shared.append(
                                hrvSDNN: hrv,
                                serverInFlow: response.isInFlow,
                                localStressScore: HealthKitManager.shared.lastLocalStressScore,
                                source: (body["device_id"] as? String) ?? "api"
                            )
                        }
                        completion?(.success(response))
                        if response.isInFlow {
                            self.onFlowStateRestored?()
                        } else {
                            self.onFlowStateLost?()
                        }
                    }
                } catch {
                    DispatchQueue.main.async { completion?(.failure(error)) }
                }
            }
            task.resume()
        }
    }

    // MARK: - Wearable OAuth (Fitbit / Garmin; server-stored tokens)

    func fetchWearableProviders() async throws -> [WearableProviderInfo] {
        let url = apiURL(path: "api/v1/wearables/providers")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)
        try throwIfHTTPError(data: data, response: response)
        return try decoder.decode([WearableProviderInfo].self, from: data)
    }

    func fetchFitbitAuthorizeURL() async throws -> WearableAuthorizeResponse {
        try await authorizedGET(path: "api/v1/wearables/oauth/fitbit/authorize-url", as: WearableAuthorizeResponse.self)
    }

    func fetchGarminAuthorizeURL() async throws -> WearableAuthorizeResponse {
        try await authorizedGET(path: "api/v1/wearables/oauth/garmin/authorize-url", as: WearableAuthorizeResponse.self)
    }

    func exchangeFitbitOAuth(code: String, state: String, redirectUri: String) async throws -> WearableExchangeResponse {
        try await authorizedPOST(
            path: "api/v1/wearables/oauth/fitbit/exchange",
            body: OAuthExchangeBody(code: code, state: state, redirectUri: redirectUri),
            as: WearableExchangeResponse.self
        )
    }

    func exchangeGarminOAuth(code: String, state: String, redirectUri: String) async throws -> WearableExchangeResponse {
        try await authorizedPOST(
            path: "api/v1/wearables/oauth/garmin/exchange",
            body: OAuthExchangeBody(code: code, state: state, redirectUri: redirectUri),
            as: WearableExchangeResponse.self
        )
    }

    private func authorizedGET<T: Decodable>(path: String, as type: T.Type) async throws -> T {
        let url = apiURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        guard let provider = authTokenProvider, let token = await provider() else {
            throw APIClientError.unauthorized
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        try throwIfHTTPError(data: data, response: response)
        return try decoder.decode(T.self, from: data)
    }

    private func authorizedPOST<T: Decodable, B: Encodable>(path: String, body: B, as type: T.Type) async throws -> T {
        let url = apiURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        guard let provider = authTokenProvider, let token = await provider() else {
            throw APIClientError.unauthorized
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        try throwIfHTTPError(data: data, response: response)
        return try decoder.decode(T.self, from: data)
    }

    private func throwIfHTTPError(data: Data, response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200 ... 299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw APIClientError.httpStatus(http.statusCode, msg)
        }
    }
}

private struct OAuthExchangeBody: Encodable {
    let code: String
    let state: String
    let redirectUri: String
}

enum APIClientError: Error {
    case noData
    case unauthorized
    case httpStatus(Int, String)
}
