//
//  ChatView.swift
//  body sense ai
//
//  Floating AI chatbox — full conversation interface with BodySense AI.
//

import SwiftUI

// MARK: - Floating Chat Button (added as overlay on Dashboard)

struct FloatingChatButton: View {
    @Binding var showChat: Bool
    @State private var pulse = false

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button { showChat = true } label: {
                    ZStack {
                        // Pulse ring
                        Circle()
                            .fill(Color.brandPurple.opacity(0.2))
                            .frame(width: 72, height: 72)
                            .scaleEffect(pulse ? 1.3 : 1.0)
                            .opacity(pulse ? 0 : 0.5)
                            .animation(.easeOut(duration: 1.6).repeatForever(autoreverses: false), value: pulse)

                        // Main button
                        Circle()
                            .fill(
                                LinearGradient(colors: [.brandPurple, Color(hex: "#4834d4")],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 58, height: 58)
                            .shadow(color: .brandPurple.opacity(0.45), radius: 10, y: 4)

                        // Icon — friendly heart pulse
                        Image(systemName: "heart.text.clipboard.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 16)
            }
        }
        .onAppear { pulse = true }
        .sheet(isPresented: $showChat) { ChatView() }
    }
}

// MARK: - Chat View

struct ChatView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var ai: HealthAIEngine?
    @State private var messages: [ChatMessage] = []
    @State private var input      = ""
    @State private var scrollID   = UUID()
    @State private var showAgentStats = false
    @State private var showHistory = false
    @State private var showUpgradeSheet = false
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBg.ignoresSafeArea()
                VStack(spacing: 0) {
                    chatHeader
                    agentDomainBadge
                    AIMessageLimitBanner(store: store)
                    messagesScrollView
                    if ai?.isTyping == true { typingIndicator }
                    inputBar
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAgentStats) {
                if let agent = ai?.agent {
                    AgentStatsView(agent: agent)
                }
            }
            .sheet(isPresented: $showHistory) {
                ChatHistoryListView { history in
                    loadHistory(history)
                }
                .environment(store)
            }
            .sheet(isPresented: $showUpgradeSheet) {
                let nextPlan: SubscriptionPlan = store.subscription == .free ? .pro : .premium
                UpgradePromptSheet(
                    requiredPlan: nextPlan,
                    store: store,
                    reason: "You have reached your daily limit of \(store.subscription.dailyAIMessageLimit) AI messages. Upgrade to \(nextPlan.badge) for \(nextPlan.dailyAIMessageLimit) messages per day."
                )
                .environment(store)
            }
        }
        .onAppear { setupAI() }
        .onDisappear { saveCurrentChat() }
    }

    // ── Header with Agent Identity ──
    var chatHeader: some View {
        HStack(spacing: 12) {
            // Agent avatar — changes based on active domain
            Button { showAgentStats = true } label: {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(hex: ai?.currentDomain.colorHex ?? "#6C63FF"),
                                     Color(hex: ai?.currentDomain.colorHex ?? "#4834d4").opacity(0.7)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)
                    Image(systemName: ai?.currentDomain.icon ?? "heart.text.clipboard.fill")
                        .foregroundColor(.white).font(.system(size: 20))
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(ai?.agentPersona ?? "HealthSense AI")
                        .font(.headline)
                    // Learning indicator
                    if let count = ai?.agentLearningCount, count > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "brain.fill")
                                .font(.system(size: 9))
                            Text("\(count)")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(hex: "#6C63FF")))
                    }
                }
                HStack(spacing: 4) {
                    Circle().fill(ConnectivityMonitor.shared.isConnected ? Color.brandGreen : Color.orange)
                        .frame(width: 7, height: 7)
                    Text(ConnectivityMonitor.shared.isConnected
                         ? "Online · Learning from every conversation"
                         : "Offline · Using local intelligence")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
            Button { showHistory = true } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.secondary).font(.title3)
            }
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary).font(.title2)
            }
        }
        .padding(.horizontal).padding(.vertical, 12)
        .background(Color.cardBg)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    // ── Domain Badge (shows current expert persona) ──
    var agentDomainBadge: some View {
        Group {
            if let domain = ai?.currentDomain, domain != .general, messages.count > 1 {
                HStack(spacing: 6) {
                    Image(systemName: domain.icon)
                        .font(.system(size: 11))
                    Text("\(domain.persona) · \(domain.rawValue) Expert")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(Color(hex: domain.colorHex))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color(hex: domain.colorHex).opacity(0.1))
                        .overlay(Capsule().stroke(Color(hex: domain.colorHex).opacity(0.3), lineWidth: 1))
                )
                .padding(.top, 6)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.4), value: domain)
            }
        }
    }

    // ── Messages ──
    var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(messages) { msg in
                        ChatBubble(message: msg, onChip: { chip in
                            send(chip)
                        }, onFeedback: { feedback in
                            if let idx = messages.firstIndex(where: { $0.id == msg.id }) {
                                messages[idx].feedback = feedback
                                // Feed back to agent for learning
                                if idx > 0 {
                                    let query = messages[idx - 1].isUser ? messages[idx - 1].content : ""
                                    ai?.reportFeedback(feedback, forQuery: query)
                                }
                            }
                        })
                        .id(msg.id)
                    }
                    Color.clear.frame(height: 8).id("bottom")
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
            }
            .onChange(of: messages.count) {
                withAnimation { proxy.scrollTo("bottom") }
            }
            .onChange(of: ai?.isTyping) {
                withAnimation { proxy.scrollTo("bottom") }
            }
        }
    }

    // ── Typing Indicator ──
    var typingIndicator: some View {
        HStack(alignment: .bottom, spacing: 8) {
            aiAvatar
            TypingBubble()
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    var aiAvatar: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [.brandPurple, Color(hex: "#4834d4")],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 30, height: 30)
            Image(systemName: "heart.text.clipboard.fill")
                .foregroundColor(.white).font(.system(size: 14))
        }
    }

    // ── Input Bar ──
    var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                TextField("Ask your health coach…", text: $input, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(22)
                    .focused($focused)
                    .onSubmit { sendTapped() }

                Button { sendTapped() } label: {
                    Image(systemName: input.trimmingCharacters(in: .whitespaces).isEmpty
                          ? "mic.fill" : "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.brandPurple)
                }
                .disabled(ai?.isTyping == true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.cardBg)
        }
    }

    // ── Logic ──
    private func setupAI() {
        ai = HealthAIEngine(store: store)
        let name = store.userProfile.name.split(separator: " ").first.map(String.init) ?? "there"
        let learnCount = ai?.agentLearningCount ?? 0
        let learnNote = learnCount > 0 ? " I've already learned **\(learnCount) things** about you." : ""
        var greetText = "Hi \(name)! I'm your **HealthSense AI Agent** — a learning health intelligence that grows smarter with every conversation.\n\n"
        greetText += "I have **8 expert personas** — Medical, Nutrition, Fitness, Chef, Sleep, Mental Wellness, Personal Care — and I'll automatically switch to the right expert for each question.\(learnNote)\n\n"

        greetText += "**Powered by on-device AI** — private, fast, and always available.\n\n"
        greetText += "What would you like to know today?"

        let chips = ["My glucose", "My BP", "Meal plan for me", "Workout plan", "Health summary"]

        let greeting = ChatMessage(content: greetText, isUser: false, chips: chips)
        messages = [greeting]
    }

    private func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Enforce AI message limit
        if store.isAIMessageLimitReached {
            showUpgradeSheet = true
            return
        }

        focused = false
        input = ""
        messages.append(ChatMessage(content: trimmed, isUser: true))
        store.recordAIMessage()
        Task {
            let reply = await ai?.respond(to: trimmed)
            if let r = reply {
                await MainActor.run { messages.append(r) }
            }
        }
    }

    private func sendTapped() {
        let t = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty { send(t) }
    }

    private func saveCurrentChat() {
        // Only save if there are user messages (not just the greeting)
        let userMessages = messages.filter { $0.isUser }
        guard !userMessages.isEmpty else { return }

        let records = messages.map { msg in
            ChatMessageRecord(content: msg.content, isUser: msg.isUser, chips: msg.chips)
        }

        // Generate title from first user query
        let title = userMessages.first?.content.prefix(50).description ?? "Chat"

        let history = ChatHistoryRecord(
            messages: records,
            agentType: nil,
            lastMessageAt: Date(),
            title: String(title)
        )
        // Avoid duplicating if re-opening same chat
        store.chatHistories.append(history)
        // Keep max 50 histories
        if store.chatHistories.count > 50 {
            store.chatHistories.removeFirst(store.chatHistories.count - 50)
        }
        store.save()
    }

    private func loadHistory(_ history: ChatHistoryRecord) {
        messages = history.messages.map { record in
            ChatMessage(content: record.content, isUser: record.isUser, chips: record.chips)
        }
        showHistory = false
    }
}

// MARK: - Chat History List

struct ChatHistoryListView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    var onSelect: (ChatHistoryRecord) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if store.chatHistories.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.largeTitle).foregroundColor(.secondary)
                        Text("No chat history yet")
                            .font(.headline).foregroundColor(.secondary)
                        Text("Your conversations will appear here after you chat.")
                            .font(.caption).foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(store.chatHistories.reversed()) { history in
                            Button {
                                onSelect(history)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(history.title)
                                        .font(.subheadline).fontWeight(.medium)
                                        .lineLimit(1)
                                    HStack {
                                        Text(history.lastMessageAt.formatted(.dateTime.day().month().hour().minute()))
                                            .font(.caption2).foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(history.messages.count) messages")
                                            .font(.caption2).foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete { offsets in
                            let reversed = store.chatHistories.reversed().map { $0 }
                            for index in offsets {
                                if let idx = store.chatHistories.firstIndex(where: { $0.id == reversed[index].id }) {
                                    store.chatHistories.remove(at: idx)
                                }
                            }
                            store.save()
                        }
                    }
                }
            }
            .navigationTitle("Chat History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Agent Stats View (shows learning progress)

struct AgentStatsView: View {
    let agent: HealthSenseAgent
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Agent brain visual
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color(hex: "#6C63FF"), Color(hex: "#4834d4")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 100, height: 100)
                                .shadow(color: Color(hex: "#6C63FF").opacity(0.4), radius: 20)
                            Image(systemName: agent.stats.experienceIcon)
                                .font(.system(size: 44))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)

                        Text("HealthSense AI Agent")
                            .font(.title2.bold())
                        Text(agent.stats.experienceLevel)
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "#6C63FF"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color(hex: "#6C63FF").opacity(0.1)))

                        // Stats grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            statCard(icon: "brain.fill", title: "Insights Learned", value: "\(agent.stats.totalInsights)", color: "#6C63FF")
                            statCard(icon: "bubble.left.and.bubble.right.fill", title: "Conversations", value: "\(agent.stats.totalInteractions)", color: "#26de81")
                            statCard(icon: "chart.bar.fill", title: "Confidence", value: "\(Int(agent.stats.confidenceLevel * 100))%", color: "#FF9F43")
                            statCard(icon: "calendar", title: "Active Since", value: agent.stats.activeSince?.formatted(.dateTime.day().month()) ?? "Today", color: "#4ECDC4")
                        }
                        .padding(.horizontal)

                        // Top domains
                        if !agent.stats.topDomains.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Top Expertise Areas")
                                    .font(.headline)
                                    .padding(.horizontal)

                                ForEach(agent.stats.topDomains, id: \.0) { domain, count in
                                    HStack(spacing: 12) {
                                        Image(systemName: domain.icon)
                                            .foregroundColor(Color(hex: domain.colorHex))
                                            .frame(width: 30)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(domain.rawValue).font(.subheadline.bold())
                                            Text("\(count) interactions").font(.caption).foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Text(domain.persona)
                                            .font(.caption)
                                            .foregroundColor(Color(hex: domain.colorHex))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Capsule().fill(Color(hex: domain.colorHex).opacity(0.1)))
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color.cardBg)
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                }
                            }
                        }

                        // All domains
                        VStack(alignment: .leading, spacing: 12) {
                            Text("All Expert Personas")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(HealthDomain.allCases, id: \.self) { domain in
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: domain.colorHex).opacity(0.2))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: domain.icon)
                                            .foregroundColor(Color(hex: domain.colorHex))
                                            .font(.system(size: 16))
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(domain.persona).font(.subheadline.bold())
                                        Text(domain.rawValue).font(.caption).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if agent.activeDomains.contains(domain) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.brandGreen)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Agent Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func statCard(icon: String, title: String, value: String, color: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(hex: color))
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.cardBg)
        .cornerRadius(16)
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message    : ChatMessage
    let onChip     : (String) -> Void
    var onFeedback : ((MessageFeedback) -> Void)? = nil

    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
            HStack(alignment: .bottom, spacing: 8) {
                if !message.isUser {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.brandPurple, Color(hex: "#4834d4")],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 30, height: 30)
                        Image(systemName: "heart.text.clipboard.fill")
                            .foregroundColor(.white).font(.system(size: 14))
                    }
                }
                VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                    bubbleBody
                    // Feedback row for AI messages
                    if !message.isUser {
                        feedbackRow
                    }
                }
                if message.isUser { Spacer(minLength: 44) }
            }
            if !message.chips.isEmpty && !message.isUser {
                chipRow
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
    }

    @State private var showCopied = false

    var feedbackRow: some View {
        HStack(spacing: 12) {
            // Copy button — easy one-tap copy
            Button {
                UIPasteboard.general.string = message.content
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
                .foregroundColor(showCopied ? .brandGreen : .secondary.opacity(0.6))
            }
            .buttonStyle(.plain)

            Button {
                onFeedback?(message.feedback == .thumbsUp ? .none : .thumbsUp)
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: message.feedback == .thumbsUp ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .font(.system(size: 12))
                    if message.feedback == .thumbsUp {
                        Text("Helpful").font(.system(size: 10))
                    }
                }
                .foregroundColor(message.feedback == .thumbsUp ? .brandGreen : .secondary.opacity(0.6))
            }
            .buttonStyle(.plain)

            Button {
                onFeedback?(message.feedback == .thumbsDown ? .none : .thumbsDown)
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: message.feedback == .thumbsDown ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                        .font(.system(size: 12))
                    if message.feedback == .thumbsDown {
                        Text("Not helpful").font(.system(size: 10))
                    }
                }
                .foregroundColor(message.feedback == .thumbsDown ? .brandCoral : .secondary.opacity(0.6))
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.leading, 4)
        .padding(.top, 2)
    }

    var bubbleBody: some View {
        Text(LocalizedStringKey(markdownify(message.content)))
            .font(.subheadline)
            .foregroundColor(message.isUser ? .white : .primary)
            .textSelection(.enabled)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(message.isUser
                ? LinearGradient(colors: [.brandPurple, Color(hex: "#4834d4")],
                                 startPoint: .topLeading, endPoint: .bottomTrailing)
                    .cornerRadius(18, corners: [.topLeft, .topRight, .bottomLeft])
                : LinearGradient(colors: [Color.cardBg, Color.cardBg],
                                 startPoint: .top, endPoint: .bottom)
                    .cornerRadius(18, corners: [.topLeft, .topRight, .bottomRight])
            )
            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            .frame(maxWidth: (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.width ?? 390 * 0.78, alignment: message.isUser ? .trailing : .leading)
    }

    var chipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(message.chips, id: \.self) { chip in
                    Button { onChip(chip) } label: {
                        Text(chip)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.brandPurple.opacity(0.1))
                            .foregroundColor(.brandPurple)
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.brandPurple.opacity(0.3), lineWidth: 1))
                    }
                }
            }
            .padding(.leading, 40)
        }
    }

    // Convert simple **bold** markdown to attributed string key
    private func markdownify(_ text: String) -> String { text }
}

// MARK: - Typing Bubble Animation

struct TypingBubble: View {
    @State private var show = [false, false, false]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.secondary.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .scaleEffect(show[i] ? 1.3 : 0.7)
                    .animation(.easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.2),
                               value: show[i])
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(Color.cardBg)
        .cornerRadius(18, corners: [.topLeft, .topRight, .bottomRight])
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        .onAppear { show = [true, true, true] }
    }
}

// MARK: - Corner Radius Helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius  : CGFloat = .infinity
    var corners : UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(roundedRect: rect, byRoundingCorners: corners,
                          cornerRadii: CGSize(width: radius, height: radius)).cgPath)
    }
}
