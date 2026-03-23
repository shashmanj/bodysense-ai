//
//  AuthService.swift
//  body sense ai
//
//  Native Sign in with Apple authentication service.
//  Uses AuthenticationServices framework + Keychain for secure credential storage.
//  No third-party dependencies — 100% Apple-native.
//

import Foundation
import AuthenticationServices
import CryptoKit

/// Manages Sign in with Apple authentication and credential persistence.
@MainActor
@Observable
final class AuthService {

    static let shared = AuthService()

    // MARK: - Published State

    /// The Apple-provided stable user identifier (persisted in Keychain).
    var userIdentifier: String?

    /// User's full name (only provided on FIRST sign-in — must be persisted).
    var userName: String?

    /// User's email (only provided on FIRST sign-in if user allows it).
    var userEmail: String?

    /// Whether the user is fully authenticated.
    var isAuthenticated: Bool { userIdentifier != nil }

    /// Loading state for auth operations.
    var isLoading: Bool = false

    /// Error message for display.
    var errorMessage: String?

    /// Whether onboarding has been completed for this user.
    var onboardingCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: "onboardingCompleted_\(userIdentifier ?? "none")") }
        set { UserDefaults.standard.set(newValue, forKey: "onboardingCompleted_\(userIdentifier ?? "none")") }
    }

    // MARK: - Keychain Keys

    private enum Keys {
        static let userID    = "com.bodysenseai.auth.userIdentifier"
        static let userName  = "com.bodysenseai.auth.userName"
        static let userEmail = "com.bodysenseai.auth.userEmail"
    }

    // MARK: - Init

    private init() {
        loadStoredCredentials()
    }

    // MARK: - Sign in with Apple

    /// Generate a random nonce for Sign in with Apple (replay protection).
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    /// SHA256 hash of the nonce (sent to Apple for verification).
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Process the ASAuthorization result from Sign in with Apple.
    func handleAuthorization(_ authorization: ASAuthorization) {
        isLoading = true
        errorMessage = nil

        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            errorMessage = "Invalid credential type"
            isLoading = false
            return
        }

        let uid = credential.user

        // Apple only provides name and email on the FIRST sign-in.
        // We MUST persist them immediately.
        var name: String? = nil
        if let fullName = credential.fullName {
            let components = [fullName.givenName, fullName.familyName].compactMap { $0 }
            if !components.isEmpty {
                name = components.joined(separator: " ")
            }
        }

        let email = credential.email

        // Persist to Keychain
        do {
            try KeychainService.saveString(uid, forKey: Keys.userID)

            if let name = name {
                try KeychainService.saveString(name, forKey: Keys.userName)
            }

            if let email = email {
                try KeychainService.saveString(email, forKey: Keys.userEmail)
            }
        } catch {
            print("⚠️ AuthService: Failed to save credentials to Keychain: \(error)")
        }

        // Update state
        self.userIdentifier = uid
        if let name = name { self.userName = name }
        if let email = email { self.userEmail = email }

        // Scope agent memory to this user
        AgentMemoryStore.shared.setUser(uid)

        isLoading = false
    }

    /// Handle Sign in with Apple error.
    func handleAuthError(_ error: Error) {
        isLoading = false

        // User cancelled — not a real error
        if let authError = error as? ASAuthorizationError,
           authError.code == .canceled {
            return
        }

        errorMessage = error.localizedDescription
        print("❌ AuthService: Sign in with Apple failed: \(error)")
    }

    // MARK: - Sign Out

    /// Sign out the current user. Clears Keychain credentials but preserves local data.
    func signOut() {
        // Clear Keychain
        try? KeychainService.delete(key: Keys.userID)
        try? KeychainService.delete(key: Keys.userName)
        try? KeychainService.delete(key: Keys.userEmail)

        // Reset state
        userIdentifier = nil
        userName = nil
        userEmail = nil
        errorMessage = nil

        // Clear agent memory scope
        AgentMemoryStore.shared.setUser(nil)
    }

    // MARK: - Delete Account (GDPR / App Store Requirement)

    /// Permanently delete the user's account, all local data, and all cloud data.
    func deleteAccount(store: HealthStore) async {
        isLoading = true
        errorMessage = nil

        // 1. Delete cloud data
        await CloudSyncService.shared.deleteAllCloudData()

        // 2. Clear all local UserDefaults data
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }

        // 3. Clear Keychain
        KeychainService.deleteAll()

        // 4. Reset HealthStore in-memory
        store.resetAllData()

        // 5. Reset auth state
        userIdentifier = nil
        userName = nil
        userEmail = nil

        isLoading = false
    }

    // MARK: - Credential Validation

    /// Check whether the Apple ID credential is still valid.
    /// Call this on app launch to detect revoked credentials.
    func checkCredentialState() async {
        guard let uid = userIdentifier else { return }

        let provider = ASAuthorizationAppleIDProvider()

        do {
            let state = try await provider.credentialState(forUserID: uid)

            switch state {
            case .authorized:
                break // All good
            case .revoked, .notFound:
                // User revoked access or credential not found — sign out
                signOut()
            case .transferred:
                // App transferred to a different team — re-auth needed
                signOut()
            @unknown default:
                break
            }
        } catch {
            print("⚠️ AuthService: Credential state check failed: \(error)")
        }
    }

    // MARK: - Private

    /// Load stored credentials from Keychain on init.
    private func loadStoredCredentials() {
        do {
            userIdentifier = try KeychainService.loadString(forKey: Keys.userID)
            userName = try KeychainService.loadString(forKey: Keys.userName)
            userEmail = try KeychainService.loadString(forKey: Keys.userEmail)

            // Restore per-user agent memory scope
            AgentMemoryStore.shared.setUser(userIdentifier)
        } catch {
            print("⚠️ AuthService: Failed to load stored credentials: \(error)")
        }
    }
}

// MARK: - Sign in with Apple Button (SwiftUI Wrapper)

/// A reusable Sign in with Apple button that handles the full auth flow.
struct SignInWithAppleButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let onSuccess: () -> Void
    let onError: ((Error) -> Void)?

    init(onSuccess: @escaping () -> Void, onError: ((Error) -> Void)? = nil) {
        self.onSuccess = onSuccess
        self.onError = onError
    }

    var body: some View {
        SignInWithAppleButtonRepresentable(
            type: .signIn,
            style: colorScheme == .dark ? .white : .black,
            onRequest: { request in
                let nonce = AuthService.shared.randomNonceString()
                request.requestedScopes = [.fullName, .email]
                request.nonce = AuthService.shared.sha256(nonce)
            },
            onCompletion: { result in
                switch result {
                case .success(let authorization):
                    AuthService.shared.handleAuthorization(authorization)
                    onSuccess()
                case .failure(let error):
                    AuthService.shared.handleAuthError(error)
                    onError?(error)
                }
            }
        )
        .frame(height: 54)
        .cornerRadius(14)
    }
}

/// UIViewRepresentable wrapper for ASAuthorizationAppleIDButton.
struct SignInWithAppleButtonRepresentable: UIViewRepresentable {
    let type: ASAuthorizationAppleIDButton.ButtonType
    let style: ASAuthorizationAppleIDButton.Style
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: type, style: style)
        button.addTarget(context.coordinator, action: #selector(Coordinator.handleTap), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onRequest: onRequest, onCompletion: onCompletion)
    }

    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let onRequest: (ASAuthorizationAppleIDRequest) -> Void
        let onCompletion: (Result<ASAuthorization, Error>) -> Void

        init(onRequest: @escaping (ASAuthorizationAppleIDRequest) -> Void,
             onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void) {
            self.onRequest = onRequest
            self.onCompletion = onCompletion
        }

        @objc func handleTap() {
            let request = ASAuthorizationAppleIDProvider().createRequest()
            onRequest(request)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }

        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            onCompletion(.success(authorization))
        }

        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            onCompletion(.failure(error))
        }

        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            let scene = UIApplication.shared.connectedScenes.first as! UIWindowScene
            return scene.windows.first ?? UIWindow(windowScene: scene)
        }
    }
}

import SwiftUI
