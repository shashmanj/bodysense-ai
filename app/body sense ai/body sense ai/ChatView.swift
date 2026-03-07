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
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBg.ignoresSafeArea()
                VStack(spacing: 0) {
                    chatHeader
                    messagesScrollView
                    if ai?.isTyping == true { typingIndicator }
                    inputBar
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear { setupAI() }
    }

    // ── Header ──
    var chatHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.brandPurple, Color(hex: "#4834d4")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                Image(systemName: "heart.text.clipboard.fill")
                    .foregroundColor(.white).font(.system(size: 20))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("BodySense Health Coach").font(.headline)
                HStack(spacing: 4) {
                    Circle().fill(Color.brandGreen).frame(width: 7, height: 7)
                    Text("Online · Ask me anything about your health").font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary).font(.title2)
            }
        }
        .padding(.horizontal).padding(.vertical, 12)
        .background(Color.cardBg)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
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
        let greeting = ChatMessage(
            content: "Hi \(name)! 👋 I'm your BodySense Health Coach.\n\nI have access to your health readings and profile, so I can give you **personalised** guidance on your glucose, blood pressure, medications, meal plans, and more.\n\nWhat would you like to know today?",
            isUser: false,
            chips: ["📊 My glucose", "❤️ My BP", "🍽️ Give me a meal plan", "💊 My medications", "📋 Full summary"]
        )
        messages = [greeting]
    }

    private func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        focused = false
        input = ""
        messages.append(ChatMessage(content: trimmed, isUser: true))
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

    var feedbackRow: some View {
        HStack(spacing: 12) {
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
