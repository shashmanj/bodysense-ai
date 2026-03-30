//
//  NutritionDashboardView.swift
//  body sense ai
//
//  CalTrack-style daily nutrition dashboard with circular progress rings,
//  today's meals timeline, and weekly analytics. Production-grade UI.
//

import SwiftUI

// MARK: - Circular Progress Ring

struct NutritionRing: View {
    let value: Double
    let goal: Double
    let color: Color
    let size: CGFloat
    let lineWidth: CGFloat

    var progress: Double { goal > 0 ? min(value / goal, 1.0) : 0 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Int(value)) of \(Int(goal))")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

// MARK: - Main Nutrition Dashboard

struct NutritionDashboardView: View {
    @Environment(HealthStore.self) var store
    @State private var selectedTab = 0  // 0 = Today, 1 = Analytics
    @State private var showFoodSearch = false

    // MARK: - Computed Data

    var todayLogs: [NutritionLog] {
        store.nutritionLogs.filter { Calendar.current.isDateInToday($0.date) }
    }

    var totalCalories: Int     { todayLogs.reduce(0) { $0 + $1.calories } }
    var totalProtein: Double   { todayLogs.reduce(0) { $0 + $1.protein } }
    var totalCarbs: Double     { todayLogs.reduce(0) { $0 + $1.carbs } }
    var totalFat: Double       { todayLogs.reduce(0) { $0 + $1.fat } }
    var totalFiber: Double     { todayLogs.reduce(0) { $0 + $1.fiber } }
    var totalSugar: Double     { todayLogs.reduce(0) { $0 + $1.sugar } }
    var totalSalt: Double      { todayLogs.reduce(0) { $0 + $1.salt } }

    var todayWater: Double {
        store.waterEntries.filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.amount } / 1000 // litres
    }

    var calGoal: Int       { store.userProfile.dailyCalorieGoal }
    var proteinGoal: Double { store.userProfile.dailyProteinGoal }
    var carbGoal: Double   { store.userProfile.dailyCarbGoal }
    var fatGoal: Double    { store.userProfile.dailyFatGoal }
    var caloriesLeft: Int  { max(calGoal - totalCalories, 0) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Tab switcher
                    Picker("", selection: $selectedTab) {
                        Text("Today").tag(0)
                        Text("Analytics").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if selectedTab == 0 {
                        todayView
                    } else {
                        analyticsView
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .background(Color.brandBg)
            .navigationTitle("Nutrition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showFoodSearch = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.brandPurple).font(.title2)
                    }
                    .accessibilityLabel("Add meal")
                }
            }
            .sheet(isPresented: $showFoodSearch) {
                NavigationStack { FoodSearchView() }
            }
        }
    }

    // MARK: - Today View

    private var todayView: some View {
        VStack(spacing: 16) {
            // Hero calorie card
            calorieHeroCard

            // Macro + Water pills
            macroRow

            // Today's Meals
            todayMealsList

            // Add Meal button
            Button { showFoodSearch = true } label: {
                Label("Add Meal", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.brandPurple)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Hero Calorie Card

    private var calorieHeroCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 24) {
                // Big ring
                ZStack {
                    NutritionRing(value: Double(totalCalories), goal: Double(calGoal),
                                  color: .brandAmber, size: 120, lineWidth: 12)
                    VStack(spacing: 2) {
                        Text("\(caloriesLeft)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("left")
                            .font(.caption2).foregroundColor(.secondary)
                    }
                }

                // Stats column
                VStack(alignment: .leading, spacing: 12) {
                    calorieStat(label: "Goal", value: "\(calGoal)", color: .primary)
                    calorieStat(label: "Consumed", value: "\(totalCalories)", color: .brandAmber)
                    calorieStat(label: "Remaining", value: "\(caloriesLeft)", color: .brandGreen)
                }
                Spacer()
            }
            .padding(.horizontal)

            // Percentage bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.brandAmber.opacity(0.15))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [.brandAmber, totalCalories > calGoal ? .brandCoral : .brandGreen],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * min(Double(totalCalories) / Double(max(calGoal, 1)), 1.0))
                        .animation(.spring(response: 0.5), value: totalCalories)
                }
            }
            .frame(height: 8)
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .padding(.horizontal)
    }

    private func calorieStat(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.subheadline).fontWeight(.semibold).foregroundColor(color)
        }
    }

    // MARK: - Macro Row (Protein, Carbs, Fat, Water)

    private var macroRow: some View {
        HStack(spacing: 10) {
            macroPillCard(icon: "flame.fill", label: "Protein",
                          value: "\(Int(totalProtein))g",
                          percent: proteinGoal > 0 ? Int(totalProtein / proteinGoal * 100) : 0,
                          color: .brandTeal)
            macroPillCard(icon: "leaf.fill", label: "Carbs",
                          value: "\(Int(totalCarbs))g",
                          percent: carbGoal > 0 ? Int(totalCarbs / carbGoal * 100) : 0,
                          color: .brandCoral)
            macroPillCard(icon: "drop.fill", label: "Fat",
                          value: "\(Int(totalFat))g",
                          percent: fatGoal > 0 ? Int(totalFat / fatGoal * 100) : 0,
                          color: .brandAmber)
            macroPillCard(icon: "drop.halffull", label: "Water",
                          value: String(format: "%.1fL", todayWater),
                          percent: Int(todayWater / 2.0 * 100), // 2L goal
                          color: .blue)
        }
        .padding(.horizontal)
    }

    private func macroPillCard(icon: String, label: String, value: String, percent: Int, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(value)
                .font(.caption.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            // Mini progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.15))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * min(Double(percent) / 100.0, 1.0))
                }
            }
            .frame(height: 3)

            Text("\(min(percent, 100))%")
                .font(.system(size: 9)).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Today's Meals List

    private var todayMealsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Meals")
                    .font(.headline)
                Spacer()
                Text("\(todayLogs.count) items")
                    .font(.caption).foregroundColor(.secondary)
            }
            .padding(.horizontal)

            if todayLogs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 40)).foregroundColor(.secondary.opacity(0.4))
                    Text("No meals logged yet")
                        .font(.subheadline).foregroundColor(.secondary)
                    Text("Tap + to search and log your food")
                        .font(.caption).foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                // Group by meal type
                let grouped = Dictionary(grouping: todayLogs.sorted { $0.date < $1.date }) { $0.mealType }
                let mealOrder: [MealType] = [.breakfast, .lunch, .dinner, .snack]

                ForEach(mealOrder, id: \.self) { mealType in
                    if let meals = grouped[mealType], !meals.isEmpty {
                        mealGroup(type: mealType, meals: meals)
                    }
                }
            }
        }
    }

    private func mealGroup(type: MealType, meals: [NutritionLog]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Meal type header
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.caption).foregroundColor(type.color)
                Text(type.rawValue)
                    .font(.caption).fontWeight(.semibold).foregroundColor(type.color)
                Spacer()
                let mealCals = meals.reduce(0) { $0 + $1.calories }
                Text("\(mealCals) kcal")
                    .font(.caption).foregroundColor(.secondary)
            }
            .padding(.horizontal)

            ForEach(meals) { log in
                mealRow(log)
            }
        }
    }

    private func mealRow(_ log: NutritionLog) -> some View {
        HStack(spacing: 12) {
            // Food icon
            RoundedRectangle(cornerRadius: 10)
                .fill(log.mealType.color.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: foodIcon(for: log.foodName))
                        .font(.title3)
                        .foregroundColor(log.mealType.color)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(log.foodName.isEmpty ? log.mealType.rawValue : log.foodName)
                    .font(.subheadline).fontWeight(.medium)
                    .lineLimit(1)
                Text(log.date.formatted(date: .omitted, time: .shortened))
                    .font(.caption2).foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(log.calories) kcal")
                    .font(.subheadline).fontWeight(.semibold).foregroundColor(.brandAmber)
                Text("\(Int(log.protein))p \(Int(log.carbs))c \(Int(log.fat))f")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func foodIcon(for name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("egg") || lower.contains("omelette") { return "circle.grid.cross" }
        if lower.contains("chicken") || lower.contains("meat") || lower.contains("beef") { return "flame" }
        if lower.contains("fish") || lower.contains("salmon") || lower.contains("tuna") { return "fish" }
        if lower.contains("salad") || lower.contains("veg") { return "leaf" }
        if lower.contains("rice") || lower.contains("pasta") || lower.contains("bread") { return "takeoutbag.and.cup.and.straw" }
        if lower.contains("yogurt") || lower.contains("yoghurt") || lower.contains("milk") { return "cup.and.saucer" }
        if lower.contains("fruit") || lower.contains("apple") || lower.contains("banana") { return "apple.logo" }
        if lower.contains("coffee") || lower.contains("tea") { return "cup.and.saucer.fill" }
        if lower.contains("water") { return "drop.fill" }
        return "fork.knife"
    }

    // MARK: - Analytics View

    private var analyticsView: some View {
        VStack(spacing: 20) {
            // Weekly calorie chart
            weeklyCalorieChart

            // Macronutrient progress bars
            macroProgressSection

            // Daily/Weekly goal circles
            goalCircles

            // Nutrient details
            nutrientDetails
        }
    }

    // MARK: - Weekly Calorie Chart

    private var weeklyCalorieChart: some View {
        let weekData = last7DaysCalories()

        return VStack(alignment: .leading, spacing: 12) {
            Text("Calorie Intake")
                .font(.headline)

            // Week day labels + bars
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(weekData, id: \.day) { day in
                    VStack(spacing: 4) {
                        // Bar
                        let maxVal = Double(max(weekData.map(\.calories).max() ?? 1, calGoal))
                        let height = maxVal > 0 ? CGFloat(Double(day.calories) / maxVal) * 120 : 0

                        RoundedRectangle(cornerRadius: 4)
                            .fill(day.isToday ? Color.brandPurple :
                                    day.calories > calGoal ? Color.brandCoral.opacity(0.7) :
                                    Color.brandPurple.opacity(0.4))
                            .frame(width: 32, height: max(height, 4))

                        // Value
                        Text("\(day.calories)")
                            .font(.system(size: 8)).foregroundColor(.secondary)

                        // Day label
                        Text(day.day)
                            .font(.caption2)
                            .fontWeight(day.isToday ? .bold : .regular)
                            .foregroundColor(day.isToday ? .brandPurple : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 160)

            // Goal line label
            HStack(spacing: 4) {
                Rectangle().fill(Color.brandAmber.opacity(0.5)).frame(height: 1)
                Text("Goal: \(calGoal)").font(.caption2).foregroundColor(.secondary)
                Rectangle().fill(Color.brandAmber.opacity(0.5)).frame(height: 1)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .padding(.horizontal)
    }

    // MARK: - Macro Progress Section

    private var macroProgressSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Macronutrients")
                .font(.headline)

            macroBar(label: "Protein", value: totalProtein, goal: proteinGoal,
                     color: .brandTeal, unit: "g")
            macroBar(label: "Carbs", value: totalCarbs, goal: carbGoal,
                     color: .brandCoral, unit: "g")
            macroBar(label: "Fat", value: totalFat, goal: fatGoal,
                     color: .brandAmber, unit: "g")
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .padding(.horizontal)
    }

    private func macroBar(label: String, value: Double, goal: Double, color: Color, unit: String) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(label).font(.subheadline).fontWeight(.medium)
                Spacer()
                Text("\(Int(value))\(unit)")
                    .font(.subheadline).fontWeight(.bold).foregroundColor(color)
                Text("/ \(Int(goal))\(unit)")
                    .font(.caption).foregroundColor(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.15))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * min(goal > 0 ? value / goal : 0, 1.0))
                        .animation(.spring(response: 0.5), value: value)
                }
            }
            .frame(height: 10)
        }
    }

    // MARK: - Goal Circles

    private var goalCircles: some View {
        HStack(spacing: 20) {
            goalCircle(label: "Daily Goal",
                       percent: calGoal > 0 ? Double(totalCalories) / Double(calGoal) : 0,
                       color: .brandPurple)
            goalCircle(label: "Weekly Avg",
                       percent: weeklyAveragePercent(),
                       color: .brandTeal)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .padding(.horizontal)
    }

    private func goalCircle(label: String, percent: Double, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                NutritionRing(value: percent * 100, goal: 100,
                              color: color, size: 72, lineWidth: 7)
                Text("\(Int(min(percent, 1.0) * 100))%")
                    .font(.subheadline.bold()).foregroundColor(color)
            }
            Text(label)
                .font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Nutrient Details

    private var nutrientDetails: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Nutrient Details")
                .font(.headline)

            nutrientRow(label: "Fibre", value: totalFiber, goal: store.userProfile.dailyFiberGoal,
                        icon: "leaf.fill", color: .green)
            nutrientRow(label: "Sugar", value: totalSugar, goal: store.userProfile.dailySugarGoal,
                        icon: "cube.fill", color: .orange,
                        warning: totalSugar > store.userProfile.dailySugarGoal)
            nutrientRow(label: "Salt", value: totalSalt, goal: store.userProfile.dailySaltGoal,
                        icon: "drop.halffull", color: .red,
                        warning: totalSalt > store.userProfile.dailySaltGoal)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .padding(.horizontal)
    }

    private func nutrientRow(label: String, value: Double, goal: Double,
                             icon: String, color: Color, warning: Bool = false) -> some View {
        HStack {
            Image(systemName: warning ? "exclamationmark.triangle.fill" : icon)
                .foregroundColor(warning ? .red : color)
                .frame(width: 20)
            Text(label).font(.subheadline)
            Spacer()
            Text(String(format: "%.1fg", value))
                .font(.subheadline).fontWeight(.semibold)
                .foregroundColor(warning ? .red : .primary)
            Text("/ \(String(format: "%.0fg", goal))")
                .font(.caption).foregroundColor(.secondary)
        }
    }

    // MARK: - Data Helpers

    private struct DayCalories {
        let day: String
        let calories: Int
        let isToday: Bool
    }

    private func last7DaysCalories() -> [DayCalories] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let logs = store.nutritionLogs.filter { calendar.isDate($0.date, inSameDayAs: date) }
            let cals = logs.reduce(0) { $0 + $1.calories }
            let weekday = calendar.component(.weekday, from: date)
            // weekday: 1=Sun, 2=Mon, ..., 7=Sat
            let dayIndex = weekday == 1 ? 6 : weekday - 2
            return DayCalories(
                day: dayNames[dayIndex],
                calories: cals,
                isToday: daysAgo == 0
            )
        }
    }

    private func weeklyAveragePercent() -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var totalPercent = 0.0
        var daysWithData = 0

        for daysAgo in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let logs = store.nutritionLogs.filter { calendar.isDate($0.date, inSameDayAs: date) }
            if !logs.isEmpty {
                let cals = logs.reduce(0) { $0 + $1.calories }
                totalPercent += Double(cals) / Double(max(calGoal, 1))
                daysWithData += 1
            }
        }
        return daysWithData > 0 ? totalPercent / Double(daysWithData) : 0
    }
}

// MARK: - Personalised Calorie & Macro Goal Calculator

extension UserProfile {

    private var activityMultiplier: Double {
        ActivityLevel(rawValue: activityLevel)?.multiplier ?? 1.55
    }

    var bmr: Double {
        guard weight > 0, height > 0, age > 0 else { return 1600 }
        if gender.lowercased().contains("male") || gender.lowercased().contains("man") {
            return 10 * weight + 6.25 * height - 5 * Double(age) + 5
        } else {
            return 10 * weight + 6.25 * height - 5 * Double(age) - 161
        }
    }

    var tdee: Double { bmr * activityMultiplier }

    var calculatedCalorieGoal: Int {
        switch nutritionGoalType {
        case "lose":   return Int(tdee - 500)
        case "gain":   return Int(tdee + 300)
        case "muscle": return Int(tdee + 400)
        default:       return Int(tdee)
        }
    }

    var calculatedProteinGoal: Double {
        guard weight > 0 else { return 50 }
        switch nutritionGoalType {
        case "lose":   return weight * 2.0
        case "gain":   return weight * 1.8
        case "muscle": return weight * 2.2
        default:
            let level = ActivityLevel(rawValue: activityLevel) ?? .moderate
            switch level {
            case .sedentary, .light: return weight * 1.2
            case .moderate:          return weight * 1.6
            case .active:            return weight * 1.8
            case .veryActive:        return weight * 2.0
            }
        }
    }

    var calculatedCarbGoal: Double {
        let calGoal = Double(calculatedCalorieGoal)
        switch nutritionGoalType {
        case "lose":   return (calGoal * 0.35) / 4
        case "gain":   return (calGoal * 0.50) / 4
        case "muscle": return (calGoal * 0.45) / 4
        default:       return (calGoal * 0.45) / 4
        }
    }

    var calculatedFatGoal: Double {
        let calGoal = Double(calculatedCalorieGoal)
        switch nutritionGoalType {
        case "lose":   return (calGoal * 0.30) / 9
        case "muscle": return (calGoal * 0.25) / 9
        default:       return (calGoal * 0.30) / 9
        }
    }

    mutating func recalculateNutritionGoals() {
        dailyCalorieGoal = calculatedCalorieGoal
        dailyProteinGoal = calculatedProteinGoal
        dailyCarbGoal    = calculatedCarbGoal
        dailyFatGoal     = calculatedFatGoal
    }
}
