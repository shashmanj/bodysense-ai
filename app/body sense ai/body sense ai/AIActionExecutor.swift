//
//  AIActionExecutor.swift
//  body sense ai
//
//  Executes structured actions from Claude's brain.
//  Claude returns JSON actions (log_meal, log_glucose, log_bp, etc.)
//  and this executor writes them into HealthStore.
//
//  This is the bridge between Claude's intelligence and the app's data layer.
//

import Foundation

// MARK: - Structured AI Response

/// The complete response from the structured AI endpoint.
/// Contains both executable actions and conversational text.
struct StructuredAIResponse: Codable {
    let actions: [AIAction]
    let response: String
    let model: String?
    let usage: AIUsage?
}

struct AIUsage: Codable {
    let used: Int
    let limit: Int
    let remaining: Int
}

// MARK: - AI Action (What Claude wants the app to do)

struct AIAction: Codable {
    let type: String

    // Meal fields
    var food_name: String?
    var meal_type: String?
    var calories: Int?
    var carbs: Double?
    var protein: Double?
    var fat: Double?
    var fiber: Double?
    var sugar: Double?
    var salt: Double?
    var serving_grams: Int?

    // Glucose fields
    var value_mmol: Double?
    var context: String?

    // BP fields
    var systolic: Int?
    var diastolic: Int?
    var pulse: Int?

    // Water fields
    var ml: Int?

    // Weight fields
    var kg: Double?

    // Steps fields
    var steps: Int?

    // Symptom fields
    var symptom: String?
    var severity: String?

    // Reminder fields
    var message: String?
    var minutes_from_now: Int?

    // Profile update fields
    var field: String?
    var value: String?
}

// MARK: - Action Execution Result

struct ActionExecutionResult {
    let summaries: [String]    // User-facing confirmation messages
    let totalActions: Int
}

// MARK: - AI Action Executor

@MainActor
enum AIActionExecutor {

    /// Execute all actions from a structured AI response and write to HealthStore.
    /// Returns user-facing confirmation summaries.
    static func execute(actions: [AIAction], store: HealthStore) -> ActionExecutionResult {
        var summaries: [String] = []

        for action in actions {
            switch action.type {

            case "log_meal":
                if let summary = executeMealLog(action, store: store) {
                    summaries.append(summary)
                }

            case "log_glucose":
                if let summary = executeGlucoseLog(action, store: store) {
                    summaries.append(summary)
                }

            case "log_bp":
                if let summary = executeBPLog(action, store: store) {
                    summaries.append(summary)
                }

            case "log_water":
                if let summary = executeWaterLog(action, store: store) {
                    summaries.append(summary)
                }

            case "log_weight":
                if let summary = executeWeightLog(action, store: store) {
                    summaries.append(summary)
                }

            case "log_steps":
                if let summary = executeStepsLog(action, store: store) {
                    summaries.append(summary)
                }

            case "log_symptom":
                if let summary = executeSymptomLog(action, store: store) {
                    summaries.append(summary)
                }

            case "update_profile":
                if let summary = executeProfileUpdate(action, store: store) {
                    summaries.append(summary)
                }

            default:
                break
            }
        }

        if !summaries.isEmpty {
            store.save()
        }

        return ActionExecutionResult(summaries: summaries, totalActions: summaries.count)
    }

    // MARK: - Individual Executors

    private static func executeMealLog(_ action: AIAction, store: HealthStore) -> String? {
        guard let foodName = action.food_name, !foodName.isEmpty else { return nil }

        let mealType: MealType = {
            switch action.meal_type?.lowercased() {
            case "breakfast": return .breakfast
            case "lunch":     return .lunch
            case "dinner":    return .dinner
            case "snack":     return .snack
            default:
                // Infer from time of day
                let hour = Calendar.current.component(.hour, from: Date())
                switch hour {
                case 5..<11:  return .breakfast
                case 11..<15: return .lunch
                case 15..<17: return .snack
                default:      return .dinner
                }
            }
        }()

        let entry = NutritionLog(
            date: Date(),
            mealType: mealType,
            calories: action.calories ?? 0,
            carbs: action.carbs ?? 0,
            protein: action.protein ?? 0,
            fat: action.fat ?? 0,
            fiber: action.fiber ?? 0,
            sugar: action.sugar ?? 0,
            salt: action.salt ?? 0,
            foodName: foodName
        )

        store.nutritionLogs.append(entry)
        let cal = action.calories ?? 0
        return "Logged \(mealType.rawValue.lowercased()): \(foodName)\(cal > 0 ? " — \(cal) kcal" : "")"
    }

    private static func executeGlucoseLog(_ action: AIAction, store: HealthStore) -> String? {
        guard let mmol = action.value_mmol, mmol > 0 else { return nil }

        let mgdl = mmol * 18.0

        let mealContext: MealContext = {
            switch action.context?.lowercased() {
            case "fasting":     return .fasting
            case "before_meal": return .beforeMeal
            case "after_meal":  return .afterMeal
            case "bedtime":     return .bedtime
            default:            return .random
            }
        }()

        let reading = GlucoseReading(
            value: mgdl,
            date: Date(),
            context: mealContext
        )
        store.glucoseReadings.append(reading)

        return "Logged glucose: \(String(format: "%.1f", mmol)) mmol/L"
    }

    private static func executeBPLog(_ action: AIAction, store: HealthStore) -> String? {
        guard let sys = action.systolic, let dia = action.diastolic,
              sys >= 70, sys <= 250, dia >= 40, dia <= 150 else { return nil }

        let reading = BPReading(
            systolic: sys,
            diastolic: dia,
            pulse: action.pulse ?? 0,
            date: Date()
        )
        store.bpReadings.append(reading)

        return "Logged BP: \(sys)/\(dia) mmHg"
    }

    private static func executeWaterLog(_ action: AIAction, store: HealthStore) -> String? {
        guard let ml = action.ml, ml > 0 else { return nil }

        let entry = WaterEntry(date: Date(), amount: Double(ml))
        store.waterEntries.append(entry)

        return "Logged water: \(ml)ml"
    }

    private static func executeWeightLog(_ action: AIAction, store: HealthStore) -> String? {
        guard let kg = action.kg, kg >= 20, kg <= 300 else { return nil }

        store.userProfile.weight = kg
        return "Updated weight: \(String(format: "%.1f", kg)) kg"
    }

    private static func executeStepsLog(_ action: AIAction, store: HealthStore) -> String? {
        guard let steps = action.steps, steps >= 100, steps <= 100000 else { return nil }

        let entry = StepEntry(date: Date(), steps: steps)
        store.stepEntries.append(entry)

        return "Logged steps: \(steps.formatted())"
    }

    private static func executeSymptomLog(_ action: AIAction, store: HealthStore) -> String? {
        guard let symptom = action.symptom, !symptom.isEmpty else { return nil }

        let severity: SymptomSeverity = {
            switch action.severity?.lowercased() {
            case "moderate": return .moderate
            case "severe":   return .severe
            default:         return .mild
            }
        }()

        let log = SymptomLog(
            date: Date(),
            symptoms: [symptom],
            severity: severity
        )
        store.symptomLogs.append(log)

        return "Logged symptom: \(symptom) (\(severity.rawValue.lowercased()))"
    }

    private static func executeProfileUpdate(_ action: AIAction, store: HealthStore) -> String? {
        guard let field = action.field, let value = action.value else { return nil }

        switch field.lowercased() {
        case "name":
            store.userProfile.name = value
            return "Updated name: \(value)"
        case "age":
            if let age = Int(value), age >= 1, age <= 120 {
                store.userProfile.age = age
                return "Updated age: \(age)"
            }
        case "gender":
            store.userProfile.gender = value
            return "Updated gender: \(value)"
        default:
            break
        }
        return nil
    }
}
