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

    @State private var showReportShare = false
    @State private var reportURL: URL? = nil
    @State private var showPromptEditor = false
    @State private var selectedPromptAgent: AgentType? = nil

    // Available agents — Nova first for CEO, excluding Becky (doctor-only)
    private var publicAgents: [AgentType] {
        var agents: [AgentType] = [
            .nova, .healthCoach, .nutritionist, .fitnessCoach,
            .sleepCoach, .mindfulness, .shopAdvisor, .ceoAdvisor, .customerCare
        ]
        // Filter CEO-only agents for non-CEO users
        if !store.userProfile.isCEO {
            agents.removeAll { $0.isCEOOnly }
        }
        return agents
    }

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

                    // ── Escalated Tickets (CEO only) ────────────────────────
                    if store.userProfile.isCEO {
                        let escalated = store.supportTickets.filter { $0.isEscalated && !$0.isResolved }
                        if !escalated.isEmpty {
                            escalatedTicketsSection(tickets: escalated)
                        }
                    }

                    // ── Generate CEO Report button ──────────────────────────
                    if store.userProfile.isCEO {
                        Button {
                            generateReport()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.text.fill")
                                    .font(.title3).foregroundColor(.white)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Generate CEO Report")
                                        .font(.subheadline).fontWeight(.semibold)
                                    Text("PDF with agent performance, tickets & insights")
                                        .font(.caption2).foregroundColor(.white.opacity(0.7))
                                }
                                Spacer()
                                Image(systemName: "arrow.up.doc.fill")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(14)
                            .background(LinearGradient(
                                colors: [Color(hex: "#E040FB"), Color(hex: "#7C4DFF")],
                                startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(14)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }

                    // ── Prompt Performance (CEO only) ─────────────────────────
                    if store.userProfile.isCEO {
                        promptPerformanceSection
                    }

                    // ── Prompt Editor button (CEO only) ──────────────────────
                    if store.userProfile.isCEO {
                        Button { showPromptEditor = true } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "pencil.and.list.clipboard")
                                    .font(.title3).foregroundColor(.white)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Prompt Editor")
                                        .font(.subheadline).fontWeight(.semibold)
                                    Text("Customise AI agent instructions")
                                        .font(.caption2).foregroundColor(.white.opacity(0.7))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(14)
                            .background(LinearGradient(
                                colors: [Color(hex: "#6C63FF"), Color(hex: "#4834d4")],
                                startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(14)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }

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
        // Share report
        .sheet(isPresented: $showReportShare) {
            if let url = reportURL {
                ShareSheet(items: [url])
            }
        }
        // Prompt editor (CEO only)
        .sheet(isPresented: $showPromptEditor) {
            PromptEditorListView()
                .environment(store)
        }
    }

    // MARK: Prompt Performance Section

    private var promptPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .foregroundColor(.brandPurple)
                Text("Prompt Performance")
                    .font(.headline)
            }
            .padding(.horizontal)

            let report = AgentAnalyticsEngine.generateReport(from: AgentMemoryStore.shared, store: store)

            if report.agentStats.isEmpty {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("No interaction data yet. Performance metrics will appear after users interact with agents.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                VStack(spacing: 0) {
                    ForEach(report.agentStats) { stat in
                        let rating = stat.avgQuality * 5.0
                        let isUnderperforming = rating < 3.5 && stat.messageCount >= 5
                        HStack(spacing: 12) {
                            Image(systemName: stat.domain.icon)
                                .foregroundColor(Color(hex: stat.domain.colorHex))
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(stat.agentName)
                                        .font(.subheadline).fontWeight(.medium)
                                    if isUnderperforming {
                                        Text("Underperforming")
                                            .font(.caption2).fontWeight(.semibold)
                                            .foregroundColor(.brandCoral)
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(Color.brandCoral.opacity(0.12))
                                            .cornerRadius(100)
                                    }
                                }
                                Text("\(stat.messageCount) messages, \(String(format: "%.1f", rating))/5.0 avg rating")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            // Mini rating indicator
                            Text(String(format: "%.1f", rating))
                                .font(.subheadline).fontWeight(.bold)
                                .foregroundColor(rating >= 3.5 ? .brandGreen : .brandCoral)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        if stat.id != report.agentStats.last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.04), radius: 4)
                .padding(.horizontal)
            }
        }
    }

    // MARK: Escalated Tickets

    private func escalatedTicketsSection(tickets: [SupportTicketRecord]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.brandCoral)
                Text("Escalated Tickets (\(tickets.count))")
                    .font(.headline)
            }
            .padding(.horizontal)

            ForEach(tickets) { ticket in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(ticket.issue)
                            .font(.subheadline).fontWeight(.medium)
                        Spacer()
                        Text(ticket.createdAt.formatted(.dateTime.day().month().hour().minute()))
                            .font(.caption2).foregroundColor(.secondary)
                    }
                    Text("Category: \(ticket.category)")
                        .font(.caption).foregroundColor(.secondary)
                    if !ticket.detail.isEmpty {
                        Text(ticket.detail)
                            .font(.caption).foregroundColor(.secondary)
                    }
                    if let ai = ticket.aiResponse {
                        Text("AI response: \(ai)")
                            .font(.caption2).foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    // CEO reply button
                    HStack(spacing: 12) {
                        Button {
                            resolveTicket(ticket)
                        } label: {
                            Label("Mark Resolved", systemImage: "checkmark.circle.fill")
                                .font(.caption).fontWeight(.medium)
                                .foregroundColor(.brandGreen)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Color.brandGreen.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(14)
                .background(Color.brandCoral.opacity(0.06))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.brandCoral.opacity(0.2), lineWidth: 1))
                .padding(.horizontal)
            }
        }
    }

    private func resolveTicket(_ ticket: SupportTicketRecord) {
        if let idx = store.supportTickets.firstIndex(where: { $0.id == ticket.id }) {
            store.supportTickets[idx].status = "Resolved"
            store.supportTickets[idx].resolvedAt = Date()
            store.save()
        }
    }

    private func generateReport() {
        let report = AgentAnalyticsEngine.generateReport(from: AgentMemoryStore.shared, store: store)
        if let url = AgentReportExporter.createPDFFile(report: report, store: store) {
            reportURL = url
            showReportShare = true
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
                    Text("Welcome, CEO")
                        .font(.title2.bold()).foregroundColor(.white)
                    Text("Your AI team is ready.\nAsk any agent directly, or call a full team meeting.")
                        .font(.subheadline).foregroundColor(.white.opacity(0.75))
                        .lineSpacing(3)
                    HStack(spacing: 6) {
                        Image(systemName: "circle.fill")
                            .font(.caption2).foregroundColor(.green)
                        Text("\(publicAgents.count) agents online")
                            .font(.caption).foregroundColor(.white.opacity(0.6))
                    }
                }
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.largeTitle)
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
                let reply = try await AIClient.shared.sendWithHistory(
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
    @State private var showCopied = false

    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
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
                    .textSelection(.enabled)
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

            // Copy button for agent messages
            if !isUser {
                Button {
                    UIPasteboard.general.string = content
                    withAnimation { showCopied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { showCopied = false }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12))
                        Text(showCopied ? "Copied" : "Copy")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(showCopied ? .green : .secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
                .padding(.leading, 44)
            }
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
                                .font(.caption2).foregroundColor(.white)
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
                    .font(.largeTitle)
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
                    let reply = try await AIClient.shared.send(
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
                    .textSelection(.enabled)
                    .padding(.horizontal)
                    .padding(.bottom, 14)
                    .foregroundColor(.primary)
            }

            Divider()
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Prompt Editor List (CEO Layer 7)

struct PromptEditorListView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var selectedAgent: AgentType? = nil

    private let allAgents: [AgentType] = AgentType.allCases

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Customise the system prompts for each AI agent. Your additions are appended to the base prompt and take effect immediately.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .listRowBackground(Color.clear)
                }

                Section("Agents") {
                    ForEach(allAgents) { agent in
                        Button {
                            selectedAgent = agent
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: agent.colorHex).opacity(0.18))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: agent.icon)
                                        .font(.caption)
                                        .foregroundColor(Color(hex: agent.colorHex))
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(agent.rawValue)
                                        .font(.subheadline).fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    if let custom = store.agentCustomPrompts[agent.rawValue], !custom.isEmpty {
                                        Text("Custom prompt active")
                                            .font(.caption2)
                                            .foregroundColor(.brandGreen)
                                    } else {
                                        Text("Default prompt")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Prompt Editor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedAgent) { agent in
                PromptEditorDetailView(agent: agent)
                    .environment(store)
            }
        }
    }
}

// MARK: - Prompt Editor Detail (Single Agent)

struct PromptEditorDetailView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    let agent: AgentType
    @State private var customPrompt: String = ""
    @State private var showSaved = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Agent header
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: agent.colorHex).opacity(0.18))
                                .frame(width: 48, height: 48)
                            Image(systemName: agent.icon)
                                .font(.title3)
                                .foregroundColor(Color(hex: agent.colorHex))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(agent.rawValue)
                                .font(.headline)
                            Text(agent.tagline)
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    // Base prompt (read-only)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Base System Prompt")
                            .font(.subheadline).fontWeight(.semibold)
                        Text("Read-only. This is the built-in prompt for this agent.")
                            .font(.caption2).foregroundColor(.secondary)
                        Text(agent.baseSystemPrompt)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // Custom addition (editable)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Custom Instructions")
                            .font(.subheadline).fontWeight(.semibold)
                        Text("These are appended to the base prompt. Use this to fine-tune the agent's behaviour without modifying code.")
                            .font(.caption2).foregroundColor(.secondary)

                        TextEditor(text: $customPrompt)
                            .font(.body)
                            .frame(minHeight: 150)
                            .padding(8)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)

                    // Actions
                    HStack(spacing: 12) {
                        Button {
                            store.agentCustomPrompts[agent.rawValue] = customPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
                            store.save()
                            withAnimation { showSaved = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { showSaved = false }
                            }
                        } label: {
                            HStack {
                                Image(systemName: showSaved ? "checkmark.circle.fill" : "square.and.arrow.down")
                                Text(showSaved ? "Saved" : "Save")
                            }
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 54)
                            .background(showSaved ? Color.brandGreen : Color.brandPurple)
                            .cornerRadius(14)
                        }

                        Button {
                            customPrompt = ""
                            store.agentCustomPrompts.removeValue(forKey: agent.rawValue)
                            store.save()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.uturn.backward")
                                Text("Reset")
                            }
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(.brandCoral)
                            .frame(maxWidth: .infinity).frame(height: 54)
                            .background(Color.brandCoral.opacity(0.1))
                            .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
                .padding(.top, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                customPrompt = store.agentCustomPrompts[agent.rawValue] ?? ""
            }
        }
    }
}
