//
//  NutritionDashboardView.swift
//  body sense ai
//
//  Healthify-style daily nutrition dashboard with circular progress rings.
//  Shows personalised daily targets based on user's BMI, weight, height and goal.
//

import SwiftUI

// MARK: - Circular Progress Ring

struct NutritionRing: View {
    let value: Double       // current
    let goal: Double        // target
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

    var todayLogs: [NutritionLog] {
        store.nutritionLogs.filter { Calendar.current.isDateInToday($0.date) }
    }

    // Daily totals
    var totalCalories: Int     { todayLogs.reduce(0) { $0 + $1.calories } }
    var totalProtein: Double   { todayLogs.reduce(0) { $0 + $1.protein } }
    var totalCarbs: Double     { todayLogs.reduce(0) { $0 + $1.carbs } }
    var totalFat: Double       { todayLogs.reduce(0) { $0 + $1.fat } }
    var totalFiber: Double     { todayLogs.reduce(0) { $0 + $1.fiber } }
    var totalSugar: Double     { todayLogs.reduce(0) { $0 + $1.sugar } }
    var totalSalt: Double      { todayLogs.reduce(0) { $0 + $1.salt } }

    // Goals from UserProfile
    var calGoal: Int       { store.userProfile.dailyCalorieGoal }
    var proteinGoal: Double { store.userProfile.dailyProteinGoal }
    var carbGoal: Double   { store.userProfile.dailyCarbGoal }
    var fatGoal: Double    { store.userProfile.dailyFatGoal }
    var fiberGoal: Double  { store.userProfile.dailyFiberGoal }
    var sugarGoal: Double  { store.userProfile.dailySugarGoal }
    var saltGoal: Double   { store.userProfile.dailySaltGoal }

    // Check for multivitamins
    var takingMultivitamin: Bool {
        store.medications.contains { med in
            med.isActive && (med.name.lowercased().contains("vitamin") ||
                             med.name.lowercased().contains("multivitamin") ||
                             med.name.lowercased().contains("supplement") ||
                             med.name.lowercased().contains("omega") ||
                             med.name.lowercased().contains("zinc") ||
                             med.name.lowercased().contains("iron"))
        }
    }

    var goalLabel: String {
        switch store.userProfile.nutritionGoalType {
        case "lose":    return "🎯 Weight Loss Goal"
        case "gain":    return "💪 Weight Gain Goal"
        case "muscle":  return "🏋️ Build Muscle Goal"
        default:        return "⚖️ Maintenance Goal"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Nutrition")
                        .font(.headline)
                    Text(goalLabel)
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                if takingMultivitamin {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill").foregroundColor(.brandGreen)
                        Text("Vitamins ✓").font(.caption.bold()).foregroundColor(.brandGreen)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.brandGreen.opacity(0.1)).cornerRadius(10)
                }
            }
            .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 12)

            // Main calorie ring
            HStack(alignment: .center, spacing: 20) {
                ZStack {
                    NutritionRing(value: Double(totalCalories), goal: Double(calGoal),
                                  color: .brandAmber, size: 96, lineWidth: 9)
                    VStack(spacing: 2) {
                        Text("\(totalCalories)").font(.title3.bold()).foregroundColor(.brandAmber)
                        Text("/ \(calGoal)").font(.caption2).foregroundColor(.secondary)
                        Text("kcal").font(.caption2).foregroundColor(.secondary)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Calories consumed: \(totalCalories) of \(calGoal)")
                .accessibilityValue("\(calGoal > 0 ? Int(min(Double(totalCalories) / Double(calGoal), 1.0) * 100) : 0) percent")

                // Remaining calories context
                VStack(alignment: .leading, spacing: 6) {
                    let remaining = calGoal - totalCalories
                    if remaining > 0 {
                        Text("\(remaining) kcal remaining")
                            .font(.subheadline.bold()).foregroundColor(.primary)
                        Text("Keep it up!")
                            .font(.caption).foregroundColor(.secondary)
                    } else if remaining == 0 {
                        Text("Goal reached! 🎉")
                            .font(.subheadline.bold()).foregroundColor(.brandGreen)
                    } else {
                        Text("\(abs(remaining)) kcal over")
                            .font(.subheadline.bold()).foregroundColor(.brandCoral)
                        Text("Over your daily goal")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    // BMI context note
                    let bmi = store.userProfile.height > 0
                        ? store.userProfile.weight / pow(store.userProfile.height / 100, 2) : 0
                    if bmi > 0 {
                        Text("BMI \(String(format: "%.1f", bmi))")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(bmi < 18.5 ? Color.brandTeal :
                                        bmi < 25   ? Color.brandGreen :
                                        bmi < 30   ? Color.brandAmber : Color.brandCoral)
                            .cornerRadius(6)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.bottom, 16)

            Divider()

            // Macro rings row
            HStack(spacing: 0) {
                macroRingCell(label: "Protein", value: totalProtein, goal: proteinGoal,
                              unit: "g", color: .brandTeal)
                Divider().frame(height: 70)
                macroRingCell(label: "Carbs", value: totalCarbs, goal: carbGoal,
                              unit: "g", color: .brandCoral)
                Divider().frame(height: 70)
                macroRingCell(label: "Fat", value: totalFat, goal: fatGoal,
                              unit: "g", color: .brandAmber)
            }
            .padding(.vertical, 12)

            Divider()

            // Pills row — Fiber, Sugar, Salt
            HStack(spacing: 8) {
                nutriPill(label: "Fibre", value: totalFiber, goal: fiberGoal, unit: "g",
                          icon: "leaf.fill", color: .brandGreen, warning: false)
                nutriPill(label: "Sugar", value: totalSugar, goal: sugarGoal, unit: "g",
                          icon: "cube.fill", color: .brandAmber,
                          warning: totalSugar > sugarGoal)
                nutriPill(label: "Salt", value: totalSalt, goal: saltGoal, unit: "g",
                          icon: "drop.halffull", color: .brandCoral,
                          warning: totalSalt > saltGoal)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.06), radius: 8)
        .padding(.horizontal)
    }

    func macroRingCell(label: String, value: Double, goal: Double, unit: String, color: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                NutritionRing(value: value, goal: goal, color: color, size: 52, lineWidth: 5)
                Text("\(Int(value))").font(.caption.bold()).foregroundColor(color)
            }
            Text(label).font(.caption2).foregroundColor(.secondary)
            Text("/ \(Int(goal))\(unit)").font(.caption2).foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(Int(value)) of \(Int(goal)) \(unit)")
        .accessibilityValue("\(goal > 0 ? Int(min(value / goal, 1.0) * 100) : 0) percent")
    }

    func nutriPill(label: String, value: Double, goal: Double, unit: String,
                   icon: String, color: Color, warning: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: warning ? "exclamationmark.triangle.fill" : icon)
                .font(.caption)
                .foregroundColor(warning ? .brandCoral : color)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.caption2).foregroundColor(.secondary)
                Text("\(String(format: "%.1f", value))/\(String(format: "%.0f", goal))\(unit)")
                    .font(.caption.bold())
                    .foregroundColor(warning ? .brandCoral : color)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background((warning ? Color.brandCoral : color).opacity(0.08))
        .cornerRadius(10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(String(format: "%.1f", value)) of \(String(format: "%.0f", goal)) \(unit)\(warning ? ", over limit" : "")")
    }
}

// MARK: - Personalised Calorie & Macro Goal Calculator
// Uses Mifflin-St Jeor BMR × activity level multiplier.
// Protein scales by body weight and goal type (build muscle = highest).

extension UserProfile {

    /// Resolved activity multiplier
    private var activityMultiplier: Double {
        ActivityLevel(rawValue: activityLevel)?.multiplier ?? 1.55
    }

    /// Mifflin-St Jeor BMR (basal metabolic rate)
    var bmr: Double {
        guard weight > 0, height > 0, age > 0 else { return 1600 }
        if gender.lowercased().contains("male") || gender.lowercased().contains("man") {
            return 10 * weight + 6.25 * height - 5 * Double(age) + 5
        } else {
            return 10 * weight + 6.25 * height - 5 * Double(age) - 161
        }
    }

    /// TDEE (Total Daily Energy Expenditure) = BMR × activity multiplier
    var tdee: Double { bmr * activityMultiplier }

    /// Calculate personalised daily calorie goal
    var calculatedCalorieGoal: Int {
        switch nutritionGoalType {
        case "lose":   return Int(tdee - 500)    // ~0.5 kg/week loss
        case "gain":   return Int(tdee + 300)    // moderate surplus
        case "muscle": return Int(tdee + 400)    // higher surplus for muscle synthesis
        default:       return Int(tdee)           // maintenance
        }
    }

    /// Personalised protein goal (grams/day) — calculated from body weight in kg.
    ///
    /// Evidence-based targets:
    ///  - Sedentary/maintain:  0.8–1.0 g/kg (RDA minimum)
    ///  - Active/maintain:     1.2–1.6 g/kg
    ///  - Weight loss:         1.6–2.0 g/kg (preserve lean mass during deficit)
    ///  - Weight gain:         1.6–1.8 g/kg
    ///  - **Build muscle:**    1.8–2.2 g/kg (maximise muscle protein synthesis)
    var calculatedProteinGoal: Double {
        guard weight > 0 else { return 50 }
        switch nutritionGoalType {
        case "lose":   return weight * 2.0   // high protein preserves muscle in deficit
        case "gain":   return weight * 1.8   // moderate surplus — protein not as critical
        case "muscle": return weight * 2.2   // peak muscle protein synthesis range
        default:
            // Scale by activity level even at maintenance
            let level = ActivityLevel(rawValue: activityLevel) ?? .moderate
            switch level {
            case .sedentary, .light: return weight * 1.2
            case .moderate:          return weight * 1.6
            case .active:            return weight * 1.8
            case .veryActive:        return weight * 2.0
            }
        }
    }

    /// Calculate carb goal from calorie goal
    ///
    /// Muscle-building uses 45% carbs — fuel for resistance training and glycogen replenishment.
    var calculatedCarbGoal: Double {
        let calGoal = Double(calculatedCalorieGoal)
        switch nutritionGoalType {
        case "lose":   return (calGoal * 0.35) / 4   // 35% carbs — lower to aid fat loss
        case "gain":   return (calGoal * 0.50) / 4   // 50% carbs — fuel growth
        case "muscle": return (calGoal * 0.45) / 4   // 45% carbs — glycogen for lifting
        default:       return (calGoal * 0.45) / 4   // 45% maintenance
        }
    }

    /// Calculate fat goal from calorie goal
    var calculatedFatGoal: Double {
        let calGoal = Double(calculatedCalorieGoal)
        switch nutritionGoalType {
        case "lose":   return (calGoal * 0.30) / 9   // 30% fat
        case "muscle": return (calGoal * 0.25) / 9   // 25% fat — more room for protein + carbs
        default:       return (calGoal * 0.30) / 9   // 30% fat
        }
    }

    /// Update all nutrition goals based on current profile (call after any profile change)
    mutating func recalculateNutritionGoals() {
        dailyCalorieGoal = calculatedCalorieGoal
        dailyProteinGoal = calculatedProteinGoal
        dailyCarbGoal    = calculatedCarbGoal
        dailyFatGoal     = calculatedFatGoal
        // fiber, sugar, salt stay as NHS defaults
    }
}
