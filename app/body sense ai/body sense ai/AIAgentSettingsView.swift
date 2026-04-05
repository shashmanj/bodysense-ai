//
//  AIAgentSettingsView.swift
//  body sense ai
//
//  Settings screen for the HealthSense AI Agent — on-device AI status,
//  agent memory management, and model info.
//

import SwiftUI
#if canImport(FoundationModels)
import FoundationModels
#endif

struct AIAgentSettingsView: View {
    @Environment(\.dismiss) var dismiss

    @State private var showClearConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // ── AI Status Card ──
                        aiStatusCard

                        // ── Agent Info ──
                        agentInfoSection

                        // ── Memory Management ──
                        memorySection
                    }
                    .padding()
                }
            }
            .navigationTitle("AI Agent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Clear Agent Memory?", isPresented: $showClearConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) {
                    AgentMemoryStore.shared.clearAllMemory()
                }
            } message: {
                Text("This will erase all learned insights, interaction history, and domain statistics. The agent will start fresh.")
            }
        }
    }

    // MARK: - AI Status Card

    var aiStatusCard: some View {
        VStack(spacing: 12) {
            let available = isModelAvailable

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(available ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: available ? "brain" : "brain.head.profile")
                        .font(.title3)
                        .foregroundColor(available ? .green : .orange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(available ? "AI Ready" : "AI Unavailable")
                        .font(.headline)
                    Text(available ? "On-device intelligence is active" : unavailableText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()

                Text(available ? "READY" : "SETUP")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(available ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                    .foregroundColor(available ? .green : .orange)
                    .clipShape(Capsule())
            }

            if available {
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("All AI processing happens privately on your device — no data leaves your iPhone")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6)
    }

    // MARK: - Agent Info

    var agentInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("BodySense Intelligence", systemImage: "cpu")
                .font(.headline)

            VStack(spacing: 8) {
                infoRow("Engine", value: "BodySense Intelligence\u{2122}", detail: "On-device neural engine")
                infoRow("Processing", value: "Private", detail: "Never leaves your device")
            }

            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundColor(.brandPurple)
                Text("8 specialist agents adapt automatically to your health questions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6)
    }

    // MARK: - Memory Management

    var memorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Agent Memory", systemImage: "brain")
                .font(.headline)

            let mem = AgentMemoryStore.shared
            VStack(spacing: 8) {
                infoRow("Learned Insights", value: "\(mem.totalInsights)", detail: nil)
                infoRow("Interactions", value: "\(mem.totalInteractions)", detail: nil)
                if let first = mem.firstInteractionDate {
                    infoRow("Active Since", value: first.formatted(.dateTime.day().month().year()), detail: nil)
                }
            }

            Button(role: .destructive) {
                showClearConfirm = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Clear Agent Memory")
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.08))
                .foregroundColor(.red)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6)
    }

    // MARK: - Helpers

    private var isModelAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if case .available = SystemLanguageModel.default.availability {
                return true
            }
        }
        #endif
        return false
    }

    private var unavailableText: String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return "Ready"
            case .unavailable(let reason):
                switch reason {
                case .deviceNotEligible:
                    return "iPhone 16 or newer required"
                case .modelNotReady:
                    return "AI model is downloading..."
                case .appleIntelligenceNotEnabled:
                    return "Enable Apple Intelligence in Settings"
                @unknown default:
                    return "Temporarily unavailable"
                }
            @unknown default:
                return "Temporarily unavailable"
            }
        }
        #endif
        return "On-device AI requires iOS 26 or later. Using cloud AI."
    }

    func infoRow(_ label: String, value: String, detail: String?) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            VStack(alignment: .trailing) {
                Text(value)
                    .font(.subheadline.weight(.medium))
                if let d = detail {
                    Text(d)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
