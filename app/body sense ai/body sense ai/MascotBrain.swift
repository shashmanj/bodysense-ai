//
//  MascotBrain.swift
//  body sense ai
//
//  The intelligence behind the floating mascot. Knows the user deeply.
//  Detects missing profile fields, generates warm nudges, surfaces insights
//  from other agents, and decides what to say and when.
//
//  This is the "brain behind the mouth" — the mascot speaks on behalf
//  of ALL agents (Sage, Maya, Alex, Chef Kai, Luna, Zen, Cara).
//

import Foundation

@MainActor
enum MascotBrain {

    // MARK: - Profile Completion Detection

    /// Represents a missing profile field the mascot should ask about.
    struct MissingField {
        let field: String
        let prompt: String
        let priority: Int  // Lower = ask first
    }

    /// Returns the next missing profile field that the mascot should ask about,
    /// or nil if the profile is complete enough.
    static func nextMissingProfileField(store: HealthStore) -> MissingField? {
        let profile = store.userProfile

        // Priority order: name → DOB → conditions → goals → dietary → cultural
        var missing: [MissingField] = []

        if profile.name.trimmingCharacters(in: .whitespaces).isEmpty {
            missing.append(MissingField(
                field: "name",
                prompt: "Hey there! I'd love to know your name so I can greet you properly",
                priority: 1
            ))
        }

        if profile.age == 30 {
            // Age is still at default — likely not set
            missing.append(MissingField(
                field: "age",
                prompt: "By the way, how old are you? It helps me give you more accurate health insights",
                priority: 2
            ))
        }

        if profile.gender.isEmpty {
            missing.append(MissingField(
                field: "gender",
                prompt: "Quick question — what's your gender? Some health ranges differ and I want to get yours right",
                priority: 3
            ))
        }

        if profile.diabetesType == "General Wellness" || profile.diabetesType.isEmpty {
            missing.append(MissingField(
                field: "healthConditions",
                prompt: "Do you have any health conditions I should know about? I'll personalise everything for you",
                priority: 4
            ))
        }

        if profile.selectedGoals.isEmpty {
            missing.append(MissingField(
                field: "goals",
                prompt: "What are you hoping to achieve? Weight loss, better sleep, managing diabetes? Let me know and I'll focus on that",
                priority: 5
            ))
        }

        if profile.weight == 70 && profile.height == 165 {
            // Both at defaults — likely not set
            missing.append(MissingField(
                field: "measurements",
                prompt: "I'd love to know your height and weight — it helps with nutrition and fitness advice",
                priority: 6
            ))
        }

        if profile.emergencyName.isEmpty {
            missing.append(MissingField(
                field: "emergency",
                prompt: "One more thing — do you have an emergency contact? It's good to have just in case",
                priority: 8
            ))
        }

        return missing.sorted(by: { $0.priority < $1.priority }).first
    }

    // MARK: - Smart Greeting

    /// Generate a quick greeting for the mascot bubble (max 2 lines).
    static func generateQuickGreeting(store: HealthStore, name: String) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let displayName = name.isEmpty ? "" : " \(name)"

        // Check for things to mention
        let mood = HealthMoodEngine.computeMood(store: store)

        // Profile incomplete?
        if let missing = nextMissingProfileField(store: store), missing.priority <= 3 {
            return "Hey\(displayName)! Tap me — I'd love to get to know you better"
        }

        // Medication reminder?
        if hasMedicationDue(store: store) {
            return "Hey\(displayName)! Have you taken your medication today?"
        }

        // Time-based greeting with health context
        switch hour {
        case 5..<9:
            if mood.level == .thriving || mood.level == .good {
                return "Good morning\(displayName)! Your body's looking good today"
            }
            return "Good morning\(displayName)! Let's have a great day"

        case 9..<12:
            if store.todaySteps > 5000 {
                return "Nice\(displayName)! Already \(store.todaySteps.formatted()) steps today"
            }
            return "Morning\(displayName)! How are you feeling?"

        case 12..<14:
            let meals = store.nutritionLogs.filter { Calendar.current.isDateInToday($0.date) }
            if meals.isEmpty {
                return "Hey\(displayName)! Had lunch yet? I can help log it"
            }
            return "Hey\(displayName)! Hope lunch was good"

        case 14..<17:
            return "Afternoon\(displayName)! Need anything?"

        case 17..<20:
            return "Good evening\(displayName)! How was your day?"

        case 20..<23:
            return "Hey\(displayName)! Time to wind down soon"

        default:
            return "Hey\(displayName)! You're up late — everything okay?"
        }
    }

    // MARK: - Nudges (Periodic Reminders)

    /// Returns a contextual nudge message, or nil if nothing needs attention right now.
    static func nextNudge(store: HealthStore) -> String? {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: Date())

        // Don't nudge during quiet hours
        guard hour >= 7 && hour <= 22 else { return nil }

        // 1. Medication due
        if hasMedicationDue(store: store) {
            let dueMeds = medicationsDue(store: store)
            if let first = dueMeds.first {
                return "Friendly reminder — have you taken your \(first.name) today?"
            }
        }

        // 2. Water check (afternoon)
        if hour >= 14 && hour <= 17 {
            let waterML = store.todayWaterML
            let targetML = store.userProfile.targetWater * 1000
            if targetML > 0 && waterML < targetML * 0.5 {
                let remaining = Int((targetML - waterML) / 1000 * 10) / 10
                return "You're a bit behind on water — \(remaining) glasses to go"
            }
        }

        // 3. Steps encouragement (evening)
        if hour >= 17 && hour <= 20 {
            let steps = store.todaySteps
            let target = store.userProfile.targetSteps
            if steps < target && steps > 0 {
                let remaining = target - steps
                return "You're \(remaining.formatted()) steps from your goal — a short walk?"
            }
        }

        // 4. Glucose logging reminder (for diabetics)
        let isDiabetic = store.userProfile.diabetesType.lowercased().contains("diabetes")
        if isDiabetic {
            let todayGlucose = store.glucoseReadings.filter { cal.isDateInToday($0.date) }
            if todayGlucose.isEmpty && hour >= 10 {
                return "No glucose reading today — would you like to log one?"
            }
        }

        // 5. Celebrate a streak
        let streaks = store.userStreaks
        if let best = streaks.max(by: { $0.currentCount < $1.currentCount }), best.currentCount >= 7 {
            return "\(best.currentCount)-day \(best.type.rawValue) streak! You're doing amazing"
        }

        return nil
    }

    /// Whether the mascot has something pending to say (shows notification dot).
    static func hasPendingNudge(store: HealthStore) -> Bool {
        // Has missing critical profile fields
        if let field = nextMissingProfileField(store: store), field.priority <= 4 { return true }

        // Has medication due
        if hasMedicationDue(store: store) { return true }

        return false
    }

    // MARK: - Verification Prompts

    /// Check if pre-selected defaults might be wrong and need user verification.
    /// Called when mascot first interacts after profile setup.
    static func verificationPrompts(store: HealthStore) -> [String] {
        var prompts: [String] = []
        let profile = store.userProfile

        // If conditions are empty but user selected "General Wellness" — might have real conditions
        if profile.diabetesType == "General Wellness" || profile.diabetesType.isEmpty {
            prompts.append("I see you're set to General Wellness — do you have any specific health conditions? Even things like high BP or pre-diabetes are important for me to know.")
        }

        // If default glucose range is set but user might be diabetic
        if profile.targetGlucoseMax == 140 && profile.diabetesType.lowercased().contains("type 2") {
            prompts.append("Your glucose target is set to 140 mg/dL — is that what your doctor recommended? Some doctors suggest different ranges.")
        }

        // If age is default (30)
        if profile.age == 30 {
            prompts.append("Your age is showing as 30 — is that right? Age affects a lot of health calculations.")
        }

        return prompts
    }

    // MARK: - Subscription Upsell (Gentle)

    /// Returns a gentle upsell prompt if the user hits a premium feature, or nil.
    static func subscriptionNudge(for feature: String) -> String? {
        switch feature {
        case "advancedCorrelations":
            return "I can find deeper patterns between your meals and glucose — that's part of the Pro plan. Want to hear more?"
        case "aiMealPlan":
            return "I'd love to build you a personalised meal plan — that's a Pro feature. Shall I show you what's included?"
        case "doctorReport":
            return "I can generate a GP-ready health report — that's available on Pro. Want to check it out?"
        default:
            return nil
        }
    }

    // MARK: - Private Helpers

    private static func hasMedicationDue(store: HealthStore) -> Bool {
        !medicationsDue(store: store).isEmpty
    }

    private static func medicationsDue(store: HealthStore) -> [Medication] {
        let cal = Calendar.current
        let now = Date()

        return store.medications.filter { med in
            guard med.isActive else { return false }

            // Check if already taken today
            let takenToday = med.logs.contains { cal.isDateInToday($0.date) }
            if takenToday { return false }

            // Check if it's time (simple: after 8am for morning meds)
            let hour = cal.component(.hour, from: now)
            return hour >= 8
        }
    }
}
