//
//  OnDeviceAIManager.swift
//  body sense ai
//
//  On-device AI manager using Apple Foundation Models with cloud fallback.
//  Primary: Apple Intelligence on-device (zero cost, complete privacy)
//  Fallback: Claude API via Railway backend (when device doesn't support on-device AI)
//
//  Architecture:
//  1. Check device capability for Foundation Models
//  2. Try on-device generation first (instant, private, free)
//  3. If unavailable or fails → fall back to Claude API via Railway
//  4. User can toggle on-device AI preference in settings
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - On-Device AI Manager

@MainActor @Observable
final class OnDeviceAIManager {

    static let shared = OnDeviceAIManager()

    // MARK: - State

    /// Whether the device supports Apple Foundation Models
    var isAvailable: Bool {
        checkAvailability()
    }

    /// Whether an AI request is currently processing
    var isProcessing: Bool = false

    /// Last error message (cleared on next successful request)
    var lastError: String?

    /// Whether the user prefers on-device AI (default: on when available)
    var preferOnDevice: Bool {
        get { UserDefaults.standard.object(forKey: "preferOnDeviceAI") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "preferOnDeviceAI") }
    }

    /// Tracks whether the last response came from on-device or cloud
    var lastResponseSource: ResponseSource = .none

    enum ResponseSource: String {
        case onDevice = "On-Device"
        case cloud    = "Cloud"
        case none     = "None"
    }

    // MARK: - Cloud Fallback Configuration

    private let backendURL = "https://body-sense-ai-production.up.railway.app"

    private init() {}

    // MARK: - Device Capability Check

    /// Check if the device supports Apple Foundation Models (Apple Intelligence)
    func checkAvailability() -> Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if case .available = SystemLanguageModel.default.availability {
                return true
            }
        }
        #endif
        return false
    }

    /// Human-readable reason if on-device AI is unavailable
    var unavailableReason: String? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if case .unavailable(let reason) = SystemLanguageModel.default.availability {
                switch reason {
                case .deviceNotEligible:
                    return "This device does not support Apple Intelligence. Cloud AI will be used."
                case .appleIntelligenceNotEnabled:
                    return "Enable Apple Intelligence in Settings to use on-device AI."
                case .modelNotReady:
                    return "The on-device AI model is still downloading. Cloud AI will be used meanwhile."
                @unknown default:
                    return "On-device AI is temporarily unavailable. Cloud AI will be used."
                }
            }
        }
        #endif
        return nil
    }

    // MARK: - Generate (Primary Entry Point)

    /// Generate a response using the best available AI engine.
    /// Tries on-device first (if available and preferred), then falls back to cloud.
    func generate(systemPrompt: String, userMessage: String, context: [String] = []) async throws -> String {
        isProcessing = true
        lastError = nil

        defer { isProcessing = false }

        // Build context string from array
        let contextString = context.isEmpty ? "" : "\n\nAdditional context:\n" + context.joined(separator: "\n")
        let fullSystem = systemPrompt + contextString

        // Strategy: Try on-device first if available and preferred
        if preferOnDevice && isAvailable {
            do {
                let result = try await generateOnDevice(system: fullSystem, userMessage: userMessage)
                lastResponseSource = .onDevice
                return result
            } catch {
                #if DEBUG
                print("On-device AI failed, falling back to cloud: \(error.localizedDescription)")
                #endif
                // Fall through to cloud
            }
        }

        // Cloud fallback
        do {
            let result = try await generateViaCloud(system: fullSystem, userMessage: userMessage)
            lastResponseSource = .cloud
            return result
        } catch {
            lastError = error.localizedDescription
            throw error
        }
    }

    /// Generate with conversation history support
    func generateWithHistory(
        systemPrompt: String,
        history: [(role: String, content: String)],
        userMessage: String,
        context: [String] = []
    ) async throws -> String {
        isProcessing = true
        lastError = nil

        defer { isProcessing = false }

        let contextString = context.isEmpty ? "" : "\n\nAdditional context:\n" + context.joined(separator: "\n")
        let fullSystem = systemPrompt + contextString

        // Strategy: Try on-device first if available and preferred
        if preferOnDevice && isAvailable {
            do {
                let result = try await generateOnDeviceWithHistory(
                    system: fullSystem, history: history, userMessage: userMessage
                )
                lastResponseSource = .onDevice
                return result
            } catch {
                #if DEBUG
                print("On-device AI failed with history, falling back to cloud: \(error.localizedDescription)")
                #endif
            }
        }

        // Cloud fallback
        do {
            let result = try await generateViaCloudWithHistory(
                system: fullSystem, history: history, userMessage: userMessage
            )
            lastResponseSource = .cloud
            return result
        } catch {
            lastError = error.localizedDescription
            throw error
        }
    }

    // MARK: - On-Device Generation (Apple Foundation Models)

    private func generateOnDevice(system: String, userMessage: String) async throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard case .available = SystemLanguageModel.default.availability else {
                throw OnDeviceAIError.modelUnavailable
            }

            let session = LanguageModelSession(instructions: system)
            let response = try await session.respond(to: userMessage)
            return response.content
        }
        #endif
        throw OnDeviceAIError.modelUnavailable
    }

    private func generateOnDeviceWithHistory(
        system: String,
        history: [(role: String, content: String)],
        userMessage: String
    ) async throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard case .available = SystemLanguageModel.default.availability else {
                throw OnDeviceAIError.modelUnavailable
            }

            let session = LanguageModelSession(instructions: system)

            if !history.isEmpty {
                let contextStr = history.map { msg in
                    let role = msg.role == "user" ? "User" : "Assistant"
                    return "\(role): \(msg.content)"
                }.joined(separator: "\n\n")

                let fullPrompt = """
                Previous conversation for context:
                \(contextStr)

                Now respond to the user's latest message:
                \(userMessage)
                """

                let response = try await session.respond(to: fullPrompt)
                return response.content
            } else {
                let response = try await session.respond(to: userMessage)
                return response.content
            }
        }
        #endif
        throw OnDeviceAIError.modelUnavailable
    }

    // MARK: - Cloud Generation (Claude API via Railway Backend)

    private func generateViaCloud(system: String, userMessage: String) async throws -> String {
        try await generateViaCloudWithHistory(system: system, history: [], userMessage: userMessage)
    }

    private func generateViaCloudWithHistory(
        system: String,
        history: [(role: String, content: String)],
        userMessage: String
    ) async throws -> String {
        guard let url = URL(string: "\(backendURL)/ai-chat") else {
            throw OnDeviceAIError.invalidURL
        }

        // Build messages array for the API
        var messages: [[String: String]] = []
        for msg in history {
            messages.append(["role": msg.role, "content": msg.content])
        }
        messages.append(["role": "user", "content": userMessage])

        let body: [String: Any] = [
            "system": system,
            "messages": messages
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OnDeviceAIError.networkError("Invalid response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OnDeviceAIError.networkError("Server error \(httpResponse.statusCode): \(errorBody)")
        }

        // Parse response — expecting { "response": "..." } or { "content": "..." }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OnDeviceAIError.parseError
        }

        if let content = json["response"] as? String {
            return content
        }
        if let content = json["content"] as? String {
            return content
        }
        // Try extracting from messages array format
        if let choices = json["choices"] as? [[String: Any]],
           let first = choices.first,
           let message = first["message"] as? [String: String],
           let content = message["content"] {
            return content
        }

        throw OnDeviceAIError.parseError
    }
}

// MARK: - Errors

enum OnDeviceAIError: LocalizedError {
    case modelUnavailable
    case invalidURL
    case networkError(String)
    case parseError

    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "On-device AI model is not available on this device."
        case .invalidURL:
            return "Invalid backend URL configuration."
        case .networkError(let detail):
            return "Cloud AI error: \(detail)"
        case .parseError:
            return "Failed to parse AI response from cloud."
        }
    }
}
