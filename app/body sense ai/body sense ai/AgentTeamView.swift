//
//  AgentTeamView.swift
//  body sense ai
//
//  CEO Command Centre — Shashikiran can talk to each specialist agent individually
//  or run a "Team Meeting" where all agents discuss a topic together.
//

import SwiftUI

// MARK: - Agent Team Root

struct AgentTeamView: View {
    @Environment(HealthStore.self) var store
    @State private var selectedAgent : AgentType?   = nil
    @State private var showMeeting   = false

    // Available agents (excluding Becky who's doctor-only)
    private let publicAgents: [AgentType] = [
        .healthCoach, .nutritionist, .fitnessCoach,
        .sleepCoach, .mindfulness, .shopAdvisor, .ceoAdvisor
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // ── CEO welcome banner ────────────────────────────────────
                    ceoBanner

                    // ── Team Meeting button ───────────────────────────────────
                    Button { showMeeting = true } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [Color(hex: "#FFD700"), Color(hex: "#FF9F43")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 52, height: 52)
                                Image(systemName: "person.3.sequence.fill")
                                    .font(.title3).foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Call a Team Meeting")
                                    .font(.headline)
                                Text("Ask all agents a question — they respond together")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary).font(.caption)
                        }
                        .padding(16)
                        .background(Color(hex: "#FFD700").opacity(0.10))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "#FFD700").opacity(0.4), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    // ── Agent roster ──────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Expert Team")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(publicAgents) { agent in
                            AgentRosterCard(agent: agent) {
                                selectedAgent = agent
                            }
                            .padding(.horizontal)
                        }
                    }

                    Spacer(minLength: 100)
                }
                .padding(.top, 8)
            }
            .background(Color.brandBg)
            .navigationTitle("AI Team")
            .navigationBarTitleDisplayMode(.large)
        }
        // Individual agent chat
        .sheet(item: $selectedAgent) { agent in
            AgentChatView(agent: agent)
                .environment(store)
        }
        // Team meeting
        .sheet(isPresented: $showMeeting) {
            TeamMeetingView()
                .environment(store)
        }
    }

    // MARK: CEO banner

    private var ceoBanner: some View {
        ZStack(alignment: .leading) {
            LinearGradient(
                colors: [Color(hex: "#1a1a2e"), Color(hex: "#16213e")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .cornerRadius(20)

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome, CEO 👋")
                        .font(.title2.bold()).foregroundColor(.white)
                    Text("Your AI team is ready.\nAsk any agent directly, or call a full team meeting.")
                        .font(.subheadline).foregroundColor(.white.opacity(0.75))
                        .lineSpacing(3)
                    HStack(spacing: 6) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8)).foregroundColor(.green)
                        Text("\(publicAgents.count) agents online")
                            .font(.caption).foregroundColor(.white.opacity(0.6))
                    }
                }
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 52))
                    .foregroundColor(.white.opacity(0.15))
            }
            .padding(20)
        }
        .padding(.horizontal)
    }
}

// MARK: - Agent Roster Card

struct AgentRosterCard: View {
    let agent: AgentType
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color(hex: agent.colorHex).opacity(0.18))
                        .frame(width: 52, height: 52)
                    Image(systemName: agent.icon)
                        .font(.title3)
                        .foregroundColor(Color(hex: agent.colorHex))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(agent.rawValue)
                        .font(.subheadline.bold())
                    Text(agent.tagline)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Circle().fill(Color.green).frame(width: 7, height: 7)
                    Text("Online").font(.caption2).foregroundColor(.secondary)
                }

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary).font(.caption)
            }
            .padding(14)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Individual Agent Chat View

struct AgentChatView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    let agent: AgentType

    @State private var messages: [(role: String, content: String, isUser: Bool)] = []
    @State private var input    = ""
    @State private var isTyping = false
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Agent header
                    agentHeader

                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(messages.enumerated()), id: \.offset) { idx, msg in
                                    AgentChatBubble(content: msg.content,
                                                    isUser: msg.isUser,
                                                    agent: agent)
                                    .id(idx)
                                }
                                if isTyping {
                                    agentTypingBubble
                                }
                                Color.clear.frame(height: 1).id("bottom")
                            }
                            .padding(.horizontal)
                            .padding(.top, 12)
                        }
                        .onChange(of: messages.count) { _, _ in
                            withAnimation { proxy.scrollTo("bottom") }
                        }
                        .onChange(of: isTyping) { _, _ in
                            withAnimation { proxy.scrollTo("bottom") }
                        }
                    }

                    // Input bar
                    inputBar
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear { sendGreeting() }
    }

    // MARK: Agent header

    private var agentHeader: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }

            ZStack {
                Circle()
                    .fill(Color(hex: agent.colorHex).opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: agent.icon)
                    .font(.body)
                    .foregroundColor(Color(hex: agent.colorHex))
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(agent.rawValue).font(.headline)
                HStack(spacing: 4) {
                    Circle().fill(Color.green).frame(width: 6, height: 6)
                    Text("Online").font(.caption2).foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    // MARK: Input bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Message \(agent.rawValue)…", text: $input, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(14)
                .lineLimit(1...4)
                .focused($focused)

            Button { sendMessage() } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(input.isEmpty ? .secondary : Color(hex: agent.colorHex))
            }
            .disabled(input.isEmpty || isTyping)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }

    // MARK: Typing indicator

    private var agentTypingBubble: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle().fill(Color(hex: agent.colorHex).opacity(0.2)).frame(width: 28, height: 28)
                Image(systemName: agent.icon).font(.caption2)
                    .foregroundColor(Color(hex: agent.colorHex))
            }
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color(hex: agent.colorHex).opacity(0.5))
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color(.systemBackground))
            .cornerRadius(16, corners: [.topLeft, .topRight, .bottomRight])
            Spacer()
        }
    }

    // MARK: Logic

    private func sendGreeting() {
        let userName = store.userProfile.name.isEmpty ? "CEO" : store.userProfile.name
        let greeting: String
        switch agent {
        case .ceoAdvisor:
            greeting = "Hello \(userName)! I'm Aria, your Business Advisor. As BodySense AI's founder, what strategic topic can I help you with today? Growth strategy, competitor analysis, investor pitch, NHS partnerships — I'm here to help you build something extraordinary."
        default:
            greeting = "Hi \(userName)! I'm your \(agent.rawValue). \(agent.tagline.capitalized). What would you like to explore today?"
        }
        messages.append((role: "assistant", content: greeting, isUser: false))
    }

    private func sendMessage() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        messages.append((role: "user", content: trimmed, isUser: true))
        input = ""
        isTyping = true
        focused = false

        Task {
            let history = messages.dropLast().map { (role: $0.isUser ? "user" : "assistant", content: $0.content) }

            do {
                let reply = try await AnthropicClient.shared.sendWithHistory(
                    system: agent.systemPrompt,
                    history: history,
                    userMessage: trimmed
                )
                await MainActor.run {
                    isTyping = false
                    messages.append((role: "assistant", content: reply, isUser: false))
                }
            } catch {
                await MainActor.run {
                    isTyping = false
                    messages.append((role: "assistant", content: "I'm having trouble connecting right now. Please try again in a moment.", isUser: false))
                }
            }
        }
    }
}

// MARK: - Agent Chat Bubble

struct AgentChatBubble: View {
    let content: String
    let isUser: Bool
    let agent: AgentType

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !isUser {
                ZStack {
                    Circle().fill(Color(hex: agent.colorHex).opacity(0.2)).frame(width: 28, height: 28)
                    Image(systemName: agent.icon).font(.caption2)
                        .foregroundColor(Color(hex: agent.colorHex))
                }
            }

            Text(content)
                .font(.body)
                .foregroundColor(isUser ? .white : .primary)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(isUser
                    ? Color(hex: agent.colorHex)
                    : Color(.systemBackground))
                .cornerRadius(16, corners: isUser
                    ? [.topLeft, .topRight, .bottomLeft]
                    : [.topLeft, .topRight, .bottomRight])
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                .frame(maxWidth: 280, alignment: isUser ? .trailing : .leading)

            if isUser { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }
}

// MARK: - Team Meeting View

struct TeamMeetingView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    @State private var topic      = ""
    @State private var responses  : [(agent: AgentType, text: String)] = []
    @State private var isRunning  = false
    @State private var currentAgent: AgentType? = nil
    @State private var started    = false
    @FocusState private var focused: Bool

    private let meetingAgents: [AgentType] = [
        .healthCoach, .nutritionist, .fitnessCoach,
        .sleepCoach, .mindfulness, .ceoAdvisor
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                meetingHeader

                if !started {
                    topicEntry
                } else {
                    meetingFeed
                }
            }
            .background(Color.brandBg)
            .navigationBarHidden(true)
        }
    }

    // MARK: Header

    private var meetingHeader: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2).foregroundColor(.secondary)
            }
            Spacer()
            VStack(spacing: 2) {
                Text("Team Meeting").font(.headline)
                Text("\(meetingAgents.count) agents").font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            // Agent avatars
            HStack(spacing: -8) {
                ForEach(meetingAgents.prefix(4)) { agent in
                    Circle()
                        .fill(Color(hex: agent.colorHex))
                        .frame(width: 22, height: 22)
                        .overlay(
                            Image(systemName: agent.icon)
                                .font(.system(size: 9)).foregroundColor(.white)
                        )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    // MARK: Topic entry

    private var topicEntry: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "person.3.sequence.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "#FFD700"))

                Text("What's the agenda?")
                    .font(.title2.bold())

                Text("Type a topic and your whole AI team will discuss it — each from their own expertise.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            TextField("e.g. How do we help diabetic patients lose weight?", text: $topic, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(14)
                .background(Color(.systemGray6))
                .cornerRadius(14)
                .lineLimit(3...6)
                .focused($focused)
                .padding(.horizontal, 28)

            Button {
                guard !topic.isEmpty else { return }
                started = true
                focused = false
                runTeamMeeting()
            } label: {
                Text("Start Meeting")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(hex: "#FFD700"))
                    .cornerRadius(14)
            }
            .disabled(topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.horizontal, 28)

            Spacer()
        }
    }

    // MARK: Meeting feed

    private var meetingFeed: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // CEO message (topic)
                    ceoTopicCard

                    // Agent responses
                    ForEach(Array(responses.enumerated()), id: \.offset) { _, resp in
                        MeetingAgentCard(agent: resp.agent, text: resp.text)
                            .id(resp.agent.rawValue)
                    }

                    // Currently processing indicator
                    if let current = currentAgent {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color(hex: current.colorHex).opacity(0.2))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: current.icon)
                                        .font(.caption).foregroundColor(Color(hex: current.colorHex))
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(current.rawValue).font(.caption.bold())
                                HStack(spacing: 4) {
                                    ForEach(0..<3, id: \.self) { _ in
                                        Circle().fill(Color(hex: current.colorHex).opacity(0.5))
                                            .frame(width: 6, height: 6)
                                    }
                                }
                            }
                        }
                        .padding()
                        .id("typing")
                    }

                    Color.clear.frame(height: 80).id("bottom")
                }
            }
            .onChange(of: responses.count) { _, _ in
                withAnimation { proxy.scrollTo("bottom") }
            }
            .onChange(of: currentAgent) { _, _ in
                withAnimation { proxy.scrollTo("bottom") }
            }
        }
    }

    private var ceoTopicCard: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(Color(hex: "#FFD700").opacity(0.2)).frame(width: 40, height: 40)
                Image(systemName: "crown.fill").font(.body).foregroundColor(Color(hex: "#FFD700"))
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("CEO").font(.caption.bold())
                    Text("· Agenda Item").font(.caption2).foregroundColor(.secondary)
                }
                Text(topic)
                    .font(.body)
                    .padding(12)
                    .background(Color(hex: "#FFD700").opacity(0.12))
                    .cornerRadius(12)
            }
        }
        .padding()
    }

    // MARK: Logic

    private func runTeamMeeting() {
        isRunning = true
        responses = []

        Task {
            var previousResponses = ""

            for agent in meetingAgents {
                await MainActor.run { currentAgent = agent }

                let meetingPrompt = AISystemPrompts.teamMeeting(
                    agentName: agent.rawValue,
                    topic: topic,
                    previousAgentResponses: previousResponses
                )

                do {
                    let reply = try await AnthropicClient.shared.send(
                        system: meetingPrompt,
                        userMessage: "Please share your expert perspective on: \(topic)"
                    )
                    await MainActor.run {
                        responses.append((agent: agent, text: reply))
                    }
                    previousResponses += "\n\n[\(agent.rawValue)]: \(reply)"
                } catch {
                    await MainActor.run {
                        responses.append((agent: agent, text: "Unavailable right now."))
                    }
                }
            }

            await MainActor.run {
                currentAgent = nil
                isRunning = false
            }
        }
    }
}

// MARK: - Meeting Agent Card

struct MeetingAgentCard: View {
    let agent: AgentType
    let text: String
    @State private var expanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Agent header row
            Button { withAnimation(.spring(response: 0.3)) { expanded.toggle() } } label: {
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(Color(hex: agent.colorHex).opacity(0.18)).frame(width: 36, height: 36)
                        Image(systemName: agent.icon).font(.caption)
                            .foregroundColor(Color(hex: agent.colorHex))
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(agent.rawValue).font(.caption.bold())
                        Text(agent.tagline).font(.caption2).foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption2).foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            if expanded {
                Text(text)
                    .font(.subheadline)
                    .padding(.horizontal)
                    .padding(.bottom, 14)
                    .foregroundColor(.primary)
            }

            Divider()
        }
        .background(Color(.systemBackground))
    }
}


