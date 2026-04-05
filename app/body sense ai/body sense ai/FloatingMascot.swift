//
//  FloatingMascot.swift
//  body sense ai
//
//  The living, breathing BodySense AI companion that peeps from the bottom
//  of the screen. Draggable, animated, always present. When tapped, voice
//  comes alive. Waves on idle. Knows the user personally.
//
//  Lives at MainTabView level — visible across ALL tabs.
//

import SwiftUI

// MARK: - Floating Mascot (Draggable Peep Character)

struct FloatingMascot: View {
    @Environment(HealthStore.self) var store
    @Binding var showChat: Bool

    // MARK: - State

    @State private var position: CGPoint = .zero
    @State private var dragOffset: CGSize = .zero
    @State private var isWaving = false
    @State private var isPeeping = true
    @State private var peepOffset: CGFloat = 30 // starts peeking from below
    @State private var hasGreeted = false
    @State private var showBubble = false
    @State private var bubbleText = ""
    @State private var mascotMood: HealthMoodLevel = .unknown

    // MARK: - Constants

    private let mascotSize: CGFloat = 64
    private let peepSize: CGFloat = 44  // When peeking, smaller
    private let brandPurple = Color(hex: "6C63FF")

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Speech bubble (above mascot)
                if showBubble {
                    speechBubble
                        .transition(.scale(scale: 0.5, anchor: .bottom).combined(with: .opacity))
                        .offset(x: currentX(in: geo) - geo.size.width / 2,
                                y: geo.size.height - 130 - peepOffset + dragOffset.height)
                }

                // Mascot character
                mascotBody
                    .offset(x: currentX(in: geo) - geo.size.width / 2,
                            y: geo.size.height / 2 - 50 + peepOffset + dragOffset.height)
                    .gesture(dragGesture(in: geo))
                    .onTapGesture {
                        mascotTapped()
                    }
                    .onLongPressGesture(minimumDuration: 0.5) {
                        // Long press = wave animation
                        triggerWave()
                    }
            }
            .onAppear {
                initializePosition(in: geo)
                startIdleAnimations()
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Mascot Body

    private var mascotBody: some View {
        ZStack {
            // Shadow / glow
            Circle()
                .fill(brandPurple.opacity(0.15))
                .frame(width: mascotSize + 12, height: mascotSize + 12)
                .blur(radius: 4)

            // The face
            HealthMoodFace(mood: mascotMood, size: mascotSize)

            // Waving hand (when waving)
            if isWaving {
                wavingHand
                    .offset(x: mascotSize * 0.4, y: -mascotSize * 0.15)
            }

            // Notification dot (if mascot has something to say)
            if hasPendingMessage {
                Circle()
                    .fill(Color.red)
                    .frame(width: 12, height: 12)
                    .offset(x: mascotSize * 0.35, y: -mascotSize * 0.35)
            }
        }
        .accessibilityLabel("BodySense AI companion")
        .accessibilityHint("Tap to start a conversation. Drag to move.")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Waving Hand

    private var wavingHand: some View {
        Text("\u{1F44B}") // 👋
            .font(.system(size: mascotSize * 0.3))
            .rotationEffect(.degrees(isWaving ? 20 : -20))
            .animation(
                .easeInOut(duration: 0.3).repeatCount(5, autoreverses: true),
                value: isWaving
            )
    }

    // MARK: - Speech Bubble

    private var speechBubble: some View {
        VStack(spacing: 0) {
            Text(bubbleText)
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                )
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 240)

            // Bubble tail
            Triangle()
                .fill(Color(.secondarySystemBackground))
                .frame(width: 16, height: 8)
                .offset(y: -1)
        }
    }

    // MARK: - Drag Gesture

    private func dragGesture(in geo: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
                // Dismiss bubble while dragging
                if showBubble {
                    withAnimation(.easeOut(duration: 0.2)) { showBubble = false }
                }
            }
            .onEnded { value in
                // Snap to new position
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    position.x += value.translation.width
                    position.y += value.translation.height

                    // Clamp to screen bounds
                    let halfSize = mascotSize / 2
                    position.x = max(halfSize, min(geo.size.width - halfSize, position.x))
                    position.y = max(-geo.size.height / 2 + halfSize + 60,
                                     min(geo.size.height / 2 - halfSize - 80, position.y))

                    dragOffset = .zero
                }
            }
    }

    private func currentX(in geo: GeometryProxy) -> CGFloat {
        position.x + dragOffset.width
    }

    // MARK: - Initialization

    private func initializePosition(in geo: GeometryProxy) {
        // Start at bottom-right, peeping up
        position = CGPoint(x: geo.size.width - mascotSize - 16, y: 0)

        // Compute mood
        mascotMood = HealthMoodEngine.computeMood(store: store).level

        // Peep-up animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.5)) {
            peepOffset = 0
        }

        // Auto-greet after peeping up
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            if !hasGreeted {
                greetUser()
                hasGreeted = true
            }
        }
    }

    // MARK: - Actions

    private func mascotTapped() {
        // Dismiss any existing bubble
        if showBubble {
            withAnimation(.easeOut(duration: 0.2)) { showBubble = false }
        }

        // Check if profile needs completion first
        if let missing = MascotBrain.nextMissingProfileField(store: store) {
            showBubbleMessage(missing.prompt)
            // After showing the prompt, open chat for the conversation
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2.0))
                showChat = true
            }
        } else {
            // Open chat directly — the voice of BodySense AI
            showChat = true
        }
    }

    private func greetUser() {
        let name = store.userProfile.name.components(separatedBy: " ").first ?? ""
        let greeting = MascotBrain.generateQuickGreeting(store: store, name: name)

        // Wave
        triggerWave()

        // Show bubble
        showBubbleMessage(greeting)
    }

    private func triggerWave() {
        withAnimation { isWaving = true }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation { isWaving = false }
        }
    }

    private func showBubbleMessage(_ text: String) {
        bubbleText = text
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showBubble = true
        }

        // Auto-dismiss after 4 seconds
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4.0))
            withAnimation(.easeOut(duration: 0.3)) {
                showBubble = false
            }
        }
    }

    // MARK: - Idle Animations

    private func startIdleAnimations() {
        // Periodically show tips or reminders
        Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: 45...90)))
                guard !showBubble && !showChat else { continue }

                // Check for pending insights or reminders
                if let nudge = MascotBrain.nextNudge(store: store) {
                    triggerWave()
                    try? await Task.sleep(for: .seconds(0.5))
                    showBubbleMessage(nudge)
                }
            }
        }
    }

    // MARK: - Computed

    private var hasPendingMessage: Bool {
        MascotBrain.hasPendingNudge(store: store)
    }
}

// MARK: - Triangle Shape (for speech bubble tail)

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
