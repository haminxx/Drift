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

    /// Base URL for the backend (e.g. https://your-app.onrender.com). Set from config/plist.
    var baseURL: URL = URL(string: "https://your-app.onrender.com")!

    private let session: URLSession = .shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    /// When flow state is false, this is called so ShieldTimerManager can start the 5-min timer and post notification.
    var onFlowStateLost: (() -> Void)?
    /// When flow state is true again, call so ShieldManager can remove shield and timer can cancel.
    var onFlowStateRestored: (() -> Void)?

    private init() {}

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
        let url = baseURL.appendingPathComponent("api/v1/hrv_stream")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

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

enum APIClientError: Error {
    case noData
}
