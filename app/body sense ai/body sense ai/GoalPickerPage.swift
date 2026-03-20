//
//  GoalPickerPage.swift
//  body sense ai
//
//  Goal-picker onboarding step — Page 1 of PatientOnboardingView.
//  Users tap cards for the health goals they care about; selections
//  are stored in UserProfile.selectedGoals for personalisation.
//

import SwiftUI

// MARK: - Goal option model (file-private)

private struct GoalOption: Identifiable {
    let id    = UUID()
    let emoji : String
    let label : String
}

// MARK: - GoalPickerPage

struct GoalPickerPage: View {

    /// Two-way binding to PatientOnboardingView's @State array
    @Binding var selectedGoals: [String]
    /// Advances to the next onboarding page
    let onNext: () -> Void

    private let goals: [GoalOption] = [
        GoalOption(emoji: "🩸", label: "Manage Diabetes"),
        GoalOption(emoji: "❤️", label: "Control Blood Pressure"),
        GoalOption(emoji: "💊", label: "Medication Adherence"),
        GoalOption(emoji: "😴", label: "Better Sleep"),
        GoalOption(emoji: "🏃", label: "Weight & Fitness"),
        GoalOption(emoji: "💧", label: "Hydration"),
        GoalOption(emoji: "🫀", label: "Heart Health"),
        GoalOption(emoji: "🧘", label: "Stress Management"),
        GoalOption(emoji: "🌡️", label: "General Wellness"),
        GoalOption(emoji: "👨‍⚕️", label: "Connect with Doctors"),
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Header
            Image(systemName: "checklist")
                .font(.largeTitle)
                .foregroundColor(.white)
                .shadow(radius: 10)
                .padding(.bottom, 16)

            Text("Your Health Goals")
                .font(.title.bold())
                .foregroundColor(.white)
                .padding(.bottom, 8)

            Text("Select all that apply — we'll personalise your experience.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.80))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.bottom, 24)

            // 2-column goal grid
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(goals) { goal in
                    goalCard(goal)
                }
            }
            .padding(.horizontal, 28)

            Spacer()

            // Continue button — matches nextBtn style in PatientOnboardingView
            Button(action: onNext) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(Color(hex: "#6C63FF"))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
        .padding(.top, 8)
    }

    // MARK: - Goal card

    @ViewBuilder
    private func goalCard(_ goal: GoalOption) -> some View {
        let isSelected = selectedGoals.contains(goal.label)

        Button {
            if isSelected {
                selectedGoals.removeAll { $0 == goal.label }
            } else {
                selectedGoals.append(goal.label)
            }
        } label: {
            VStack(spacing: 8) {
                Text(goal.emoji)
                    .font(.largeTitle)
                Text(goal.label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(Color.white.opacity(isSelected ? 0.30 : 0.12))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? Color.white : Color.white.opacity(0.25),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isSelected)
        }
    }
}
