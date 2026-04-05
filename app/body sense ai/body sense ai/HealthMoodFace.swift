//
//  HealthMoodFace.swift
//  body sense ai
//
//  Animated SwiftUI mascot face for BodySense AI.
//  Uses basic shapes (Circle, Path) — no custom artwork.
//  Expression changes based on HealthMoodLevel.
//  Eyes blink periodically. Subtle breathing animation.
//

import SwiftUI

struct HealthMoodFace: View {

    let mood: HealthMoodLevel
    var size: CGFloat = 80

    // MARK: - Animation State

    @State private var isBlinking = false
    @State private var breathScale: CGFloat = 1.0
    @State private var mouthProgress: CGFloat = 0

    // MARK: - Colors

    private let faceColor = Color(hex: "6C63FF") // Brand purple
    private let eyeColor = Color.white
    private let mouthColor = Color.white

    // MARK: - Body

    var body: some View {
        ZStack {
            // Face circle
            Circle()
                .fill(faceGradient)
                .frame(width: size, height: size)

            // Eyes
            HStack(spacing: size * 0.22) {
                eyeView(isLeft: true)
                eyeView(isLeft: false)
            }
            .offset(y: -size * 0.06)

            // Mouth
            mouthView
                .offset(y: size * 0.18)

            // Cheek blush (when thriving)
            if mood == .thriving {
                HStack(spacing: size * 0.42) {
                    Circle()
                        .fill(Color.pink.opacity(0.25))
                        .frame(width: size * 0.15, height: size * 0.1)
                    Circle()
                        .fill(Color.pink.opacity(0.25))
                        .frame(width: size * 0.15, height: size * 0.1)
                }
                .offset(y: size * 0.08)
            }
        }
        .scaleEffect(breathScale)
        .onAppear {
            startBreathingAnimation()
            startBlinkTimer()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                mouthProgress = 1
            }
        }
        .onChange(of: mood) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                mouthProgress = 1
            }
        }
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Face Gradient

    private var faceGradient: LinearGradient {
        let baseColor = faceColor
        return LinearGradient(
            colors: [baseColor.opacity(0.9), baseColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Eye

    @ViewBuilder
    private func eyeView(isLeft: Bool) -> some View {
        ZStack {
            // Eye white
            Ellipse()
                .fill(eyeColor)
                .frame(width: size * 0.16, height: size * 0.18)

            // Pupil
            Circle()
                .fill(Color(hex: "2D2B55"))
                .frame(width: size * 0.09, height: size * 0.09)
                .offset(y: mood == .unknown ? -size * 0.01 : 0)

            // Pupil highlight
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: size * 0.035, height: size * 0.035)
                .offset(x: size * 0.02, y: -size * 0.025)
        }
        .scaleEffect(y: isBlinking ? 0.1 : 1.0)
        .animation(.easeInOut(duration: 0.08), value: isBlinking)
    }

    // MARK: - Mouth

    @ViewBuilder
    private var mouthView: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            let midX = w / 2
            let midY = h / 2

            var path = Path()

            switch mood {
            case .thriving:
                // Big smile — wide arc up
                let smileWidth = w * 0.8
                let startX = midX - smileWidth / 2
                let endX = midX + smileWidth / 2
                path.move(to: CGPoint(x: startX, y: midY - h * 0.1))
                path.addQuadCurve(
                    to: CGPoint(x: endX, y: midY - h * 0.1),
                    control: CGPoint(x: midX, y: midY + h * 0.5)
                )

            case .good:
                // Gentle smile — medium arc
                let smileWidth = w * 0.6
                let startX = midX - smileWidth / 2
                let endX = midX + smileWidth / 2
                path.move(to: CGPoint(x: startX, y: midY))
                path.addQuadCurve(
                    to: CGPoint(x: endX, y: midY),
                    control: CGPoint(x: midX, y: midY + h * 0.35)
                )

            case .okay:
                // Neutral — straight line
                let lineWidth = w * 0.45
                path.move(to: CGPoint(x: midX - lineWidth / 2, y: midY))
                path.addLine(to: CGPoint(x: midX + lineWidth / 2, y: midY))

            case .needsAttention:
                // Slight frown — gentle down curve
                let frownWidth = w * 0.5
                let startX = midX - frownWidth / 2
                let endX = midX + frownWidth / 2
                path.move(to: CGPoint(x: startX, y: midY + h * 0.1))
                path.addQuadCurve(
                    to: CGPoint(x: endX, y: midY + h * 0.1),
                    control: CGPoint(x: midX, y: midY - h * 0.25)
                )

            case .unknown:
                // Curious — small "o" shape
                let ovalSize = w * 0.2
                path.addEllipse(in: CGRect(
                    x: midX - ovalSize / 2,
                    y: midY - ovalSize / 2,
                    width: ovalSize,
                    height: ovalSize * 1.2
                ))
            }

            context.stroke(
                path,
                with: .color(mouthColor),
                style: StrokeStyle(lineWidth: size * 0.03, lineCap: .round)
            )

            // Fill the "o" for unknown
            if mood == .unknown {
                context.fill(path, with: .color(mouthColor.opacity(0.3)))
            }
        }
        .frame(width: size * 0.5, height: size * 0.25)
    }

    // MARK: - Animations

    private func startBreathingAnimation() {
        withAnimation(
            .easeInOut(duration: 3.0)
            .repeatForever(autoreverses: true)
        ) {
            breathScale = 1.03
        }
    }

    private func startBlinkTimer() {
        Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: 3.0...5.0)))
                isBlinking = true
                try? await Task.sleep(for: .milliseconds(120))
                isBlinking = false
            }
        }
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        switch mood {
        case .thriving:       return "BodySense mascot with a big smile — your health is thriving"
        case .good:           return "BodySense mascot with a gentle smile — your health is good"
        case .okay:           return "BodySense mascot with a neutral expression — some things need attention"
        case .needsAttention: return "BodySense mascot with a concerned expression — your health needs attention"
        case .unknown:        return "BodySense mascot with a curious expression — waiting for health data"
        }
    }
}

// MARK: - Listening Expression (for Voice Mode)

struct HealthMoodFaceListening: View {

    var size: CGFloat = 80

    @State private var pulseScale: CGFloat = 1.0
    @State private var mouthOpen: CGFloat = 0.5

    private let faceColor = Color(hex: "6C63FF")

    var body: some View {
        ZStack {
            // Pulse ring
            Circle()
                .stroke(faceColor.opacity(0.3), lineWidth: 2)
                .frame(width: size * 1.3, height: size * 1.3)
                .scaleEffect(pulseScale)

            // Face
            Circle()
                .fill(LinearGradient(
                    colors: [faceColor.opacity(0.9), faceColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: size, height: size)

            // Wide eyes (listening)
            HStack(spacing: size * 0.22) {
                listeningEye
                listeningEye
            }
            .offset(y: -size * 0.06)

            // Open mouth (listening)
            Ellipse()
                .fill(Color.white.opacity(0.9))
                .frame(width: size * 0.18, height: size * 0.12 * mouthOpen)
                .offset(y: size * 0.18)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                mouthOpen = 1.0
            }
        }
        .accessibilityLabel("BodySense mascot listening to you")
    }

    private var listeningEye: some View {
        ZStack {
            Ellipse()
                .fill(Color.white)
                .frame(width: size * 0.18, height: size * 0.22) // Wider eyes

            Circle()
                .fill(Color(hex: "2D2B55"))
                .frame(width: size * 0.10, height: size * 0.10)

            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: size * 0.04, height: size * 0.04)
                .offset(x: size * 0.02, y: -size * 0.03)
        }
    }
}

// Color(hex:) is defined in HealthModels.swift
