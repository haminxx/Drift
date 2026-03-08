//
//  FirebaseManager.swift
//  Drift
//
//  Configures Firebase and provides Auth + Firestore for login, user info, and summaries.
//  Add the Firebase iOS SDK via Xcode: File → Add Package Dependencies →
//  https://github.com/firebase/firebase-ios-sdk (select FirebaseAuth and FirebaseFirestore).
//  Add GoogleService-Info.plist from Firebase Console to the app target; do not commit it (see .gitignore).
//

import Foundation
import Combine

#if canImport(FirebaseCore)
import FirebaseCore
import FirebaseAuth
#endif
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

final class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()

    /// Current Firebase user ID; nil if not signed in.
    @Published private(set) var currentUserId: String?

    /// Callback to get the current Firebase ID token for the backend (Authorization header).
    var idTokenProvider: (() async -> String?)?

    #if canImport(FirebaseCore)
    private let auth = Auth.auth()
    #endif
    #if canImport(FirebaseFirestore)
    private let db = Firestore.firestore()
    #endif

    private init() {
        #if canImport(FirebaseCore)
        auth.addStateDidChangeListener { [weak self] _, user in
            self?.currentUserId = user?.uid
        }
        currentUserId = auth.currentUser?.uid
        #endif
    }

    /// Call once at app launch (e.g. in DriftApp.init). Requires GoogleService-Info.plist in the target.
    static func configure() {
        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        #endif
    }

    /// Sign in with email and password. Call from your login UI.
    func signIn(email: String, password: String) async throws {
        #if canImport(FirebaseCore)
        _ = try await auth.signIn(withEmail: email, password: password)
        #else
        throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firebase SDK not linked"])
        #endif
    }

    /// Sign out. Call from your settings or profile UI.
    func signOut() throws {
        #if canImport(FirebaseCore)
        try auth.signOut()
        currentUserId = nil
        #endif
    }

    /// Get the current user's ID token for the backend. Returns nil if not signed in or token unavailable.
    func getIdToken() async -> String? {
        #if canImport(FirebaseCore)
        guard let user = auth.currentUser else { return nil }
        return try? await user.getIDToken()
        #else
        return nil
        #endif
    }

    /// Create or update the current user's profile in Firestore (users/{uid}).
    func setUserProfile(displayName: String? = nil, email: String? = nil) async throws {
        #if canImport(FirebaseFirestore) && canImport(FirebaseCore)
        guard let uid = auth.currentUser?.uid else { return }
        var data: [String: Any] = ["updatedAt": FieldValue.serverTimestamp()]
        if let name = displayName { data["displayName"] = name }
        if let email = email { data["email"] = email }
        try await db.collection("users").document(uid).setData(data, merge: true)
        #endif
    }

    /// Fetch recent summaries for the current user (for charts). Returns empty array if not signed in or Firestore unavailable.
    func fetchSummaries(limit: Int = 30) async -> [[String: Any]] {
        #if canImport(FirebaseFirestore) && canImport(FirebaseCore)
        guard let uid = auth.currentUser?.uid else { return [] }
        let snapshot = try? await db.collection("users").document(uid).collection("summaries")
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        return snapshot?.documents.compactMap { doc in
            var dict = doc.data()
            dict["id"] = doc.documentID
            if let createdAt = dict["createdAt"] as? Timestamp {
                dict["createdAt"] = createdAt.dateValue().iso8601
            }
            return dict
        } ?? []
        #else
        return []
        #endif
    }
}

extension Date {
    var iso8601: String { ISO8601DateFormatter().string(from: self) }
}
