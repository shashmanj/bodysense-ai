//
//  IntroSlidesView.swift
//  body sense ai
//
//  Swipeable intro carousel shown to new users before the Welcome screen.
//  7 slides — one per major health goal — with a Skip button and a
//  "Get Started" button on the final slide.
//

import SwiftUI

// MARK: - Slide data model

private struct IntroSlide {
    let icon      : String   // SF Symbol name
    let iconColor : Color
    let title     : String
    let subtitle  : String
}

// MARK: - IntroSlidesView

struct IntroSlidesView: View {

    /// Called when "Get Started" or "Skip" is tapped
    let onFinish: () -> Void

    @State private var currentPage = 0

    private let slides: [IntroSlide] = [
        IntroSlide(
            icon:      "heart.text.clipboard.fill",
            iconColor: Color(hex: "#4ECDC4"),
            title:     "Your Health, All in One Place",
            subtitle:  "Track vitals, goals, and progress daily — your intelligent health companion."
        ),
        IntroSlide(
            icon:      "drop.fill",
            iconColor: Color(hex: "#FF9F43"),
            title:     "Manage Diabetes & Glucose",
            subtitle:  "Log readings, spot patterns, and get AI-powered insights for better control."
        ),
        IntroSlide(
            icon:      "heart.fill",
            iconColor: Color(hex: "#FF6B6B"),
            title:     "Control Blood Pressure",
            subtitle:  "Monitor hypertension and stay ahead of your heart health every day."
        ),
        IntroSlide(
            icon:      "pill.fill",
            iconColor: Color(hex: "#A29BFE"),
            title:     "Never Miss a Medication",
            subtitle:  "Smart reminders keep your adherence on track, morning to bedtime."
        ),
        IntroSlide(
            icon:      "bed.double.fill",
            iconColor: Color(hex: "#C084FC"),
            title:     "Sleep & Recovery",
            subtitle:  "Understand your sleep quality and HRV trends for better recovery."
        ),
        IntroSlide(
            icon:      "figure.run",
            iconColor: Color(hex: "#6BCB77"),
            title:     "Fitness & Weight Goals",
            subtitle:  "Track steps, calories, hydration, and body metrics in one dashboard."
        ),
        IntroSlide(
            icon:      "stethoscope",
            iconColor: Color(hex: "#4ECDC4"),
            title:     "Connect with Doctors",
            subtitle:  "Book appointments, video consults, and get prescriptions — all in-app."
        ),
    ]

    var body: some View {
        ZStack(alignment: .top) {
            // Carousel
            TabView(selection: $currentPage) {
                ForEach(slides.indices, id: \.self) { index in
                    slideView(for: slides[index], isLast: index == slides.count - 1)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .onAppear {
                UIPageControl.appearance().currentPageIndicatorTintColor  = .white
                UIPageControl.appearance().pageIndicatorTintColor         = UIColor.white.withAlphaComponent(0.35)
            }

            // Skip button — floats above the carousel, hidden on last slide
            if currentPage < slides.count - 1 {
                HStack {
                    Spacer()
                    Button("Skip", action: onFinish)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Capsule())
                        .padding(.trailing, 20)
                        .padding(.top, 58)
                }
            }
        }
    }

    // MARK: - Single slide layout

    @ViewBuilder
    private func slideView(for slide: IntroSlide, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            Spacer()

            // Large coloured SF Symbol
            Image(systemName: slide.icon)
                .font(.system(size: 90, weight: .regular))
                .foregroundColor(slide.iconColor)
                .shadow(color: slide.iconColor.opacity(0.45), radius: 22, x: 0, y: 10)
                .padding(.bottom, 36)

            Text(slide.title)
                .font(.system(size: 27, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text(slide.subtitle)
                .font(.body)
                .foregroundColor(.white.opacity(0.80))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 36)
                .padding(.top, 16)

            Spacer()

            // "Get Started" on last slide; invisible placeholder on others
            // so icon/text stay vertically centred across all slides.
            if isLast {
                Button(action: onFinish) {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(Color(hex: "#6C63FF"))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 88)
            } else {
                Color.clear
                    .frame(height: 56)        // matches button height
                    .padding(.bottom, 88)
            }
        }
        .padding(.top, 100)   // clear status bar + Skip button
    }
}
