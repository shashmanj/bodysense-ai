//
//  SplashScreenView.swift
//  body sense ai
//
//  Animated splash screen — plays once per launch, then transitions to main content.
//  Orange heart cradled by curved hands, BodySense AI branding.
//

import SwiftUI

struct SplashScreenView: View {

    var onFinished: () -> Void

    // MARK: - Animation State

    @State private var heartScale: CGFloat = 0.5
    @State private var heartOpacity: Double = 0
    @State private var leftHandOffset: CGFloat = -120
    @State private var rightHandOffset: CGFloat = 120
    @State private var handOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 20
    @State private var taglineOpacity: Double = 0
    @State private var taglineOffset: CGFloat = 12
    @State private var glowOpacity: Double = 0
    @State private var dismissOpacity: Double = 1

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.brandPurple, Color(hex: "#4834d4")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Heart + hands cluster
                ZStack {
                    // Glow behind heart
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.orange.opacity(0.4), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .opacity(glowOpacity)

                    // Left hand (curved arc)
                    HandShape(isLeft: true)
                        .stroke(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                        .frame(width: 100, height: 80)
                        .offset(x: leftHandOffset, y: 18)
                        .opacity(handOpacity)

                    // Right hand (curved arc)
                    HandShape(isLeft: false)
                        .stroke(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                        .frame(width: 100, height: 80)
                        .offset(x: rightHandOffset, y: 18)
                        .opacity(handOpacity)

                    // Heart icon
                    Image(systemName: "heart.fill")
                        .font(.system(size: 72, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#FF8C42"), Color(hex: "#FF6B35")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(heartScale)
                        .opacity(heartOpacity)
                }
                .frame(height: 140)

                Spacer().frame(height: 40)

                // Title
                Text("BodySense AI")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)

                Spacer().frame(height: 10)

                // Tagline
                Text("Your Health, Understood")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))
                    .opacity(taglineOpacity)
                    .offset(y: taglineOffset)

                Spacer()
            }
        }
        .opacity(dismissOpacity)
        .onAppear(perform: runAnimationSequence)
    }

    // MARK: - Animation Sequence

    private func runAnimationSequence() {
        // Phase 1: Heart fades in and scales up (0 – 0.8s)
        withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.1)) {
            heartScale = 1.0
            heartOpacity = 1.0
        }

        // Phase 2: Hands animate inward (0.3 – 1.2s)
        withAnimation(.easeOut(duration: 0.9).delay(0.3)) {
            leftHandOffset = -48
            rightHandOffset = 48
            handOpacity = 1.0
        }

        // Phase 3: Title fades in and slides up (0.8 – 1.5s)
        withAnimation(.easeOut(duration: 0.7).delay(0.8)) {
            titleOpacity = 1.0
            titleOffset = 0
        }

        // Phase 4: Tagline fades in (1.2 – 1.8s)
        withAnimation(.easeOut(duration: 0.6).delay(1.2)) {
            taglineOpacity = 1.0
            taglineOffset = 0
        }

        // Phase 5: Gentle glow pulse on heart (1.5 – 2.5s)
        withAnimation(.easeInOut(duration: 0.8).delay(1.5).repeatCount(2, autoreverses: true)) {
            glowOpacity = 1.0
        }

        // Phase 6: Whole view fades out (2.5 – 3.0s)
        withAnimation(.easeIn(duration: 0.5).delay(2.5)) {
            dismissOpacity = 0
        }

        // Completion callback
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            onFinished()
        }
    }
}

// MARK: - Hand Shape (curved cradling arc)

/// A curved arc that resembles an open, cupped hand — mirrored for left/right.
private struct HandShape: Shape {
    let isLeft: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()

        if isLeft {
            // Left hand: curves from top-left down and inward
            path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.15))
            path.addCurve(
                to: CGPoint(x: rect.maxX, y: rect.maxY),
                control1: CGPoint(x: rect.minX, y: rect.maxY * 0.85),
                control2: CGPoint(x: rect.midX, y: rect.maxY)
            )
        } else {
            // Right hand: mirror
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.15))
            path.addCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY),
                control1: CGPoint(x: rect.maxX, y: rect.maxY * 0.85),
                control2: CGPoint(x: rect.midX, y: rect.maxY)
            )
        }

        return path
    }
}

// MARK: - Preview

#Preview {
    SplashScreenView(onFinished: {})
}
