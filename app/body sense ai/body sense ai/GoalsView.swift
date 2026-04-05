//
//  GoalsView.swift
//  body sense ai
//
//  Goals · Challenges · Achievements · Streaks
//

import SwiftUI

// MARK: - Goals View

struct GoalsView: View {
    @Environment(HealthStore.self) var store
    @State private var selectedTab  = 0
    @State private var showAddGoal  = false

    let tabs = ["Goals", "Challenges", "Achievements", "Streaks"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // XP Banner
                xpBanner

                // Tab Selector
                Picker("", selection: $selectedTab) {
                    ForEach(0..<tabs.count, id: \.self) { i in Text(tabs[i]).tag(i) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.brandBg)

                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedTab {
                        case 0: GoalsTab(showAddGoal: $showAddGoal)
                        case 1: ChallengesTab()
                        case 2: AchievementsTab()
                        case 3: StreaksTab()
                        default: EmptyView()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .padding(.bottom, 24)
                }
                .background(Color.brandBg)
            }
            .navigationTitle("Goals & Rewards")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if selectedTab == 0 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showAddGoal = true } label: {
                            Image(systemName: "plus.circle.fill").foregroundColor(.brandPurple)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddGoal) { AddGoalSheet() }
    }

    var xpBanner: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.brandPurple, Color(hex: "#4834d4")], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 52, height: 52)
                VStack(spacing: 0) {
                    Text("⚡️").font(.title3)
                    Text("\(store.totalXP)").font(.caption.bold()).foregroundColor(.white)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Total XP: \(store.totalXP)").font(.headline)
                Text("\(store.earnedAchievements.count) achievements · \(store.activeGoals.count) active goals")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Level \(store.totalXP / 100 + 1)").font(.headline).foregroundColor(.brandPurple)
                Text("\(store.totalXP % 100)/100 XP").font(.caption).foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .shadow(color: Color.primary.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Goals Tab

struct GoalsTab: View {
    @Environment(HealthStore.self) var store
    @Binding var showAddGoal: Bool

    var activeGoals: [HealthGoal] { store.healthGoals.filter { !$0.isCompleted } }
    var completedGoals: [HealthGoal] { store.healthGoals.filter { $0.isCompleted } }

    var body: some View {
        Group {
            if activeGoals.isEmpty && completedGoals.isEmpty {
                emptyGoalsView
            } else {
                if !activeGoals.isEmpty {
                    SectionHeader("Active Goals", count: activeGoals.count)
                    ForEach(activeGoals) { goal in
                        GoalCard(goal: goal)
                    }
                }
                if !completedGoals.isEmpty {
                    SectionHeader("Completed", count: completedGoals.count)
                    ForEach(completedGoals) { goal in
                        GoalCard(goal: goal)
                    }
                }
            }
        }
    }

    var emptyGoalsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "target").font(.system(size: 60)).foregroundColor(.brandPurple.opacity(0.4))
            Text("Set Your First Goal").font(.title3.bold())
            Text("Track steps, sleep, weight, glucose, and more to stay on top of your health journey.")
                .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
                .padding(.horizontal)
            Button { showAddGoal = true } label: {
                Label("Add Goal", systemImage: "plus.circle.fill")
                    .font(.headline).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.brandPurple).cornerRadius(16)
            }
        }
        .padding()
    }
}

struct GoalCard: View {
    @Environment(HealthStore.self) var store
    var goal: HealthGoal

    var daysLeft: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: goal.deadline).day ?? 0)
    }

    var body: some View {
        BSCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        Circle().fill(goal.type.color.opacity(0.15)).frame(width: 38, height: 38)
                        Image(systemName: goal.type.icon).foregroundColor(goal.type.color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.title).font(.subheadline.bold())
                        Text("\(Int(goal.currentValue)) / \(Int(goal.targetValue)) \(goal.unit)")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    if goal.isCompleted {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.brandGreen).font(.title3)
                    } else {
                        Text("\(daysLeft)d left").font(.caption).foregroundColor(.secondary)
                    }
                }

                // Progress bar
                VStack(alignment: .trailing, spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(goal.type.color.opacity(0.15)).frame(height: 8)
                            RoundedRectangle(cornerRadius: 4).fill(goal.type.color)
                                .frame(width: geo.size.width * goal.progress, height: 8)
                        }
                    }
                    .frame(height: 8)
                    Text("\(Int(goal.progress * 100))%").font(.caption.bold()).foregroundColor(goal.type.color)
                }
            }
        }
    }
}

// MARK: - Challenges Tab

struct ChallengesTab: View {
    @Environment(HealthStore.self) var store

    var joinedChallenges: [HealthChallenge] { store.healthChallenges.filter { $0.isJoined } }
    var availableChallenges: [HealthChallenge] { store.healthChallenges.filter { !$0.isJoined && $0.isActive } }

    var body: some View {
        Group {
            if !joinedChallenges.isEmpty {
                SectionHeader("My Challenges", count: joinedChallenges.count)
                ForEach(joinedChallenges) { challenge in
                    ChallengeCard(challenge: challenge)
                }
            }
            if !availableChallenges.isEmpty {
                SectionHeader("Available Challenges")
                ForEach(availableChallenges) { challenge in
                    ChallengeCard(challenge: challenge)
                }
            }
        }
    }
}

struct ChallengeCard: View {
    @Environment(HealthStore.self) var store
    var challenge: HealthChallenge

    var idx: Int? { store.healthChallenges.firstIndex(where: { $0.id == challenge.id }) }

    var body: some View {
        BSCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(challenge.type.color.opacity(0.15)).frame(width: 38, height: 38)
                        Image(systemName: challenge.type.icon).foregroundColor(challenge.type.color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(challenge.title).font(.subheadline.bold())
                            Text(challenge.type.rawValue).font(.caption)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(challenge.type.color.opacity(0.15))
                                .foregroundColor(challenge.type.color).cornerRadius(6)
                        }
                        Text(challenge.description).font(.caption).foregroundColor(.secondary)
                    }
                }

                HStack {
                    Image(systemName: "person.2.fill").foregroundColor(.secondary).font(.caption)
                    Text("\(challenge.participants) participants").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text("\(challenge.daysLeft)d left").font(.caption).foregroundColor(.secondary)
                    Text("⚡️ \(challenge.reward) XP").font(.caption.bold()).foregroundColor(.brandPurple)
                }

                if challenge.isJoined {
                    VStack(alignment: .trailing, spacing: 4) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4).fill(challenge.type.color.opacity(0.15)).frame(height: 8)
                                RoundedRectangle(cornerRadius: 4).fill(challenge.type.color)
                                    .frame(width: geo.size.width * challenge.progress, height: 8)
                            }
                        }.frame(height: 8)
                        Text("\(Int(challenge.currentValue)) / \(Int(challenge.targetValue)) · \(Int(challenge.progress * 100))%")
                            .font(.caption).foregroundColor(.secondary)
                    }
                } else {
                    Button {
                        if let i = idx {
                            store.healthChallenges[i].isJoined = true
                            store.save()
                        }
                    } label: {
                        Text("Join Challenge")
                            .font(.subheadline.bold()).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(challenge.type.color).cornerRadius(12)
                    }
                }
            }
        }
    }
}

// MARK: - Achievements Tab

struct AchievementsTab: View {
    @Environment(HealthStore.self) var store
    @State private var selectedCategory: AchievementCategory? = nil

    var filtered: [Achievement] {
        guard let cat = selectedCategory else { return store.achievements }
        return store.achievements.filter { $0.category == cat }
    }

    var body: some View {
        Group {
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(label: "All", isSelected: selectedCategory == nil) { selectedCategory = nil }
                    ForEach(AchievementCategory.allCases, id: \.self) { cat in
                        FilterChip(label: cat.rawValue, isSelected: selectedCategory == cat) { selectedCategory = cat }
                    }
                }
                .padding(.horizontal, 2)
            }

            // Earned count
            BSCard {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(store.earnedAchievements.count) / \(store.achievements.count)").font(.title2.bold()).foregroundColor(.brandPurple)
                        Text("Achievements earned").font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    let pct = store.achievements.isEmpty ? 0 : Double(store.earnedAchievements.count) / Double(store.achievements.count)
                    ZStack {
                        Circle().stroke(Color.brandPurple.opacity(0.2), lineWidth: 5)
                        Circle().trim(from: 0, to: pct)
                            .stroke(Color.brandPurple, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(Int(pct * 100))%").font(.caption2.bold()).foregroundColor(.brandPurple)
                    }.frame(width: 52, height: 52)
                }
            }

            // Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(filtered) { ach in
                    AchievementCard(achievement: ach)
                }
            }
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement

    var body: some View {
        BSCard {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(achievement.isEarned ? Color(hex: achievement.color) : Color.gray.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: achievement.icon)
                        .font(.title3)
                        .foregroundColor(achievement.isEarned ? .white : .gray.opacity(0.4))
                }
                Text(achievement.title).font(.caption.bold()).multilineTextAlignment(.center)
                Text(achievement.description).font(.caption2).foregroundColor(.secondary).multilineTextAlignment(.center)
                HStack(spacing: 4) {
                    Text("⚡️").font(.caption2)
                    Text("\(achievement.xp) XP").font(.caption2.bold()).foregroundColor(.brandPurple)
                }
                if achievement.isEarned, let d = achievement.earnedDate {
                    Text("Earned \(d, style: .date)").font(.caption2).foregroundColor(.brandGreen)
                } else {
                    Text("Locked").font(.caption2).foregroundColor(.secondary)
                }
            }
            .opacity(achievement.isEarned ? 1 : 0.55)
        }
    }
}

// MARK: - Streaks Tab

struct StreaksTab: View {
    @Environment(HealthStore.self) var store

    var body: some View {
        Group {
            BSCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Your Streaks 🔥", systemImage: "flame.fill").font(.headline).foregroundColor(.brandCoral)
                    Text("Stay consistent every day to build longer streaks and earn bonus XP!").font(.caption).foregroundColor(.secondary)
                }
            }

            ForEach(store.userStreaks) { streak in
                StreakCard(streak: streak)
            }
        }
    }
}

struct StreakCard: View {
    let streak: UserStreak

    var body: some View {
        BSCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(streak.currentCount > 0 ? Color.brandCoral.opacity(0.15) : Color.gray.opacity(0.1))
                        .frame(width: 46, height: 46)
                    Image(systemName: streak.type.icon)
                        .foregroundColor(streak.currentCount > 0 ? .brandCoral : .gray)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(streak.type.rawValue).font(.subheadline.bold())
                    Text("Best: \(streak.longestCount) days").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 2) {
                        Text(streak.currentCount > 0 ? "🔥" : "❄️").font(.title3)
                        Text("\(streak.currentCount)").font(.title3.bold())
                            .foregroundColor(streak.currentCount > 0 ? .brandCoral : .secondary)
                    }
                    Text("days").font(.caption).foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Add Goal Sheet

struct AddGoalSheet: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var goalType: GoalType  = .steps
    @State private var title               = ""
    @State private var targetValue         = ""
    @State private var deadline            = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Type") {
                    Picker("Type", selection: $goalType) {
                        ForEach(GoalType.allCases, id: \.self) { t in
                            Label(t.rawValue, systemImage: t.icon).tag(t)
                        }
                    }
                    .onChange(of: goalType) { _, new in
                        title = "Reach my \(new.rawValue) goal"
                        targetValue = ""
                    }
                }
                Section("Goal Details") {
                    TextField("Title", text: $title)
                    HStack {
                        TextField("Target", text: $targetValue).keyboardType(.decimalPad)
                        Text(goalType.defaultUnit).foregroundColor(.secondary)
                    }
                    DatePicker("Deadline", selection: $deadline, in: Date()..., displayedComponents: .date)
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let v = Double(targetValue), !title.isEmpty {
                            let g = HealthGoal(type: goalType, title: title, targetValue: v, unit: goalType.defaultUnit, deadline: deadline)
                            store.healthGoals.append(g)
                            store.save(); dismiss()
                        }
                    }.disabled(Double(targetValue) == nil || title.isEmpty)
                }
            }
        }
    }
}

// MARK: - Helpers

struct SectionHeader: View {
    let title: String
    let count: Int?
    init(_ title: String, count: Int? = nil) { self.title = title; self.count = count }

    var body: some View {
        HStack {
            Text(title).font(.headline)
            if let c = count {
                Text("\(c)").font(.caption.bold())
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(Color.brandPurple.opacity(0.15))
                    .foregroundColor(.brandPurple).cornerRadius(8)
            }
            Spacer()
        }
        .padding(.top, 4)
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(isSelected ? Color.brandPurple : Color(.secondarySystemGroupedBackground))
                .foregroundColor(isSelected ? .white : .secondary)
                .cornerRadius(14)
                .shadow(color: Color.primary.opacity(0.05), radius: 3, y: 1)
        }
    }
}
