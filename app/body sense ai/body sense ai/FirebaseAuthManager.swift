//
//  FirebaseAuthManager.swift
//  body sense ai
//
//  Firebase Authentication manager supporting:
//  - Sign in with Apple (via Firebase)
//  - Sign in with Google
//  - Phone number OTP (200+ countries)
//  - Email + Password
//
//  All methods produce a Firebase User → unified user ID across all providers.
//

import Foundation
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit

/// Unified Firebase authentication manager — single source of truth for auth state.
@MainActor
@Observable
final class FirebaseAuthManager {

    static let shared = FirebaseAuthManager()

    // MARK: - State

    /// The Firebase user — nil when signed out.
    var firebaseUser: FirebaseAuth.User? { Auth.auth().currentUser }

    /// Stable user ID from Firebase (used as primary key everywhere).
    var userId: String? { firebaseUser?.uid }

    /// Display name (from any provider).
    var displayName: String? { firebaseUser?.displayName }

    /// Email (from any provider).
    var email: String? { firebaseUser?.email }

    /// Phone number (if signed in with phone).
    var phoneNumber: String? { firebaseUser?.phoneNumber }

    /// Whether the user is authenticated.
    var isAuthenticated: Bool { firebaseUser != nil }

    /// Loading state for UI.
    var isLoading: Bool = false

    /// Error message for display.
    var errorMessage: String?

    /// Which provider the user signed in with.
    var authProvider: AuthProvider? {
        guard let providerID = firebaseUser?.providerData.first?.providerID else { return nil }
        switch providerID {
        case "apple.com": return .apple
        case "google.com": return .google
        case "phone": return .phone
        case "password": return .email
        default: return nil
        }
    }

    enum AuthProvider: String {
        case apple, google, phone, email
    }

    // MARK: - Phone OTP State

    /// The Firebase verification ID returned after sending OTP.
    var phoneVerificationID: String?

    /// Whether we're waiting for the user to enter the OTP code.
    var isAwaitingOTP: Bool = false

    // MARK: - Apple Sign-In State

    /// Current nonce for Sign in with Apple (replay protection).
    private var currentNonce: String?

    // MARK: - Init

    private init() {}

    // MARK: - Configure (call from AppDelegate)

    /// Call this once in didFinishLaunchingWithOptions.
    static func configure() {
        FirebaseApp.configure()
    }

    // MARK: - Sign in with Apple

    /// Generate a nonce and return the SHA256 hash for the Apple sign-in request.
    func prepareAppleSignIn() -> (nonce: String, sha256Hash: String) {
        let nonce = randomNonceString()
        currentNonce = nonce
        return (nonce, sha256(nonce))
    }

    /// Handle the ASAuthorization result and sign in with Firebase.
    func handleAppleAuthorization(_ authorization: ASAuthorization) async throws {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.invalidCredential
        }

        guard let nonce = currentNonce else {
            throw AuthError.missingNonce
        }

        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.missingToken
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let firebaseCredential = OAuthProvider.credential(
            providerID: .apple,
            idToken: tokenString,
            rawNonce: nonce
        )

        let result = try await Auth.auth().signIn(with: firebaseCredential)

        // Apple only provides name on FIRST sign-in — update Firebase profile if available
        if let fullName = credential.fullName {
            let components = [fullName.givenName, fullName.familyName].compactMap { $0 }
            if !components.isEmpty {
                let name = components.joined(separator: " ")
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = name
                try? await changeRequest.commitChanges()
            }
        }

        currentNonce = nil
        syncToLegacyAuthService()
    }

    // MARK: - Sign in with Google

    /// Trigger Google Sign-In flow and sign in with Firebase.
    func signInWithGoogle() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.missingClientID
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            throw AuthError.noRootViewController
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)

        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.missingToken
        }

        let firebaseCredential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        try await Auth.auth().signIn(with: firebaseCredential)
        syncToLegacyAuthService()
    }

    // MARK: - Phone Number OTP

    /// Send OTP to the given phone number (e.g. "+44 7700 900000").
    func sendOTP(to phoneNumber: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let verificationID = try await PhoneAuthProvider.provider().verifyPhoneNumber(
            phoneNumber,
            uiDelegate: nil
        )
        self.phoneVerificationID = verificationID
        self.isAwaitingOTP = true
    }

    /// Verify the OTP code entered by the user.
    func verifyOTP(_ code: String) async throws {
        guard let verificationID = phoneVerificationID else {
            throw AuthError.missingVerificationID
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )

        try await Auth.auth().signIn(with: credential)
        self.isAwaitingOTP = false
        self.phoneVerificationID = nil
        syncToLegacyAuthService()
    }

    // MARK: - Email + Password

    /// Create a new account with email and password.
    func signUpWithEmail(_ email: String, password: String, name: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let result = try await Auth.auth().createUser(withEmail: email, password: password)

        // Set display name
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = name
        try await changeRequest.commitChanges()

        // Send verification email
        try? await result.user.sendEmailVerification()

        syncToLegacyAuthService()
    }

    /// Sign in with existing email and password.
    func signInWithEmail(_ email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        try await Auth.auth().signIn(withEmail: email, password: password)
        syncToLegacyAuthService()
    }

    /// Send password reset email.
    func sendPasswordReset(to email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            syncToLegacyAuthService()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Delete Account (GDPR)

    func deleteAccount() async throws {
        guard let user = firebaseUser else { return }
        try await user.delete()
        GIDSignIn.sharedInstance.signOut()
        syncToLegacyAuthService()
    }

    // MARK: - Sync to Legacy AuthService

    /// Keep the existing AuthService in sync so the rest of the app works without changes.
    private func syncToLegacyAuthService() {
        let auth = AuthService.shared
        if let user = firebaseUser {
            auth.userIdentifier = user.uid
            auth.userName = user.displayName
            auth.userEmail = user.email ?? user.phoneNumber

            // Persist to Keychain for offline access
            try? KeychainService.saveString(user.uid, forKey: "com.bodysenseai.auth.userIdentifier")
            if let name = user.displayName {
                try? KeychainService.saveString(name, forKey: "com.bodysenseai.auth.userName")
            }
            if let email = user.email {
                try? KeychainService.saveString(email, forKey: "com.bodysenseai.auth.userEmail")
            }

            // Scope agent memory to this user
            AgentMemoryStore.shared.setUser(user.uid)
        } else {
            auth.userIdentifier = nil
            auth.userName = nil
            auth.userEmail = nil

            try? KeychainService.delete(key: "com.bodysenseai.auth.userIdentifier")
            try? KeychainService.delete(key: "com.bodysenseai.auth.userName")
            try? KeychainService.delete(key: "com.bodysenseai.auth.userEmail")

            AgentMemoryStore.shared.setUser(nil)
        }
    }

    // MARK: - Crypto Helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Error Types

    enum AuthError: LocalizedError {
        case invalidCredential
        case missingNonce
        case missingToken
        case missingClientID
        case noRootViewController
        case missingVerificationID

        var errorDescription: String? {
            switch self {
            case .invalidCredential: return "Invalid sign-in credential."
            case .missingNonce: return "Authentication security error. Please try again."
            case .missingToken: return "Could not retrieve authentication token."
            case .missingClientID: return "Firebase configuration error."
            case .noRootViewController: return "Cannot present sign-in screen."
            case .missingVerificationID: return "Phone verification expired. Please request a new code."
            }
        }
    }
}
