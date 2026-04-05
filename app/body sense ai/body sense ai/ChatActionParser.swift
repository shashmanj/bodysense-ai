//
//  ChatActionParser.swift
//  body sense ai
//
//  Parses user chat messages for data logging intent.
//  When a user says "log my glucose 7.2" or "I had rice for lunch",
//  this parser extracts the data and logs it to HealthStore.
//
//  Returns a confirmation message so the AI knows data was logged
//  and can respond with context (e.g., "7.2 mmol/L is in normal range").
//

import Foundation

@MainActor
enum ChatActionParser {

    /// Result of parsing a chat message for logging intent.
    struct ParseResult {
        let didLog: Bool
        let loggedType: String        // "glucose", "blood pressure", "water", etc.
        let confirmationText: String  // Injected into AI context so it knows what was logged
        let userFacingMessage: String // Shown to user as a system message
    }

    /// Parse a user message and log data if it contains a logging request.
    /// Returns nil if no logging intent was detected.
    static func parseAndLog(message: String, store: HealthStore) -> ParseResult? {

        let lower = message.lowercased()

        // ── Glucose ──
        if let result = parseGlucose(lower, store: store) { return result }

        // ── Blood Pressure ──
        if let result = parseBP(lower, store: store) { return result }

        // ── Water ──
        if let result = parseWater(lower, store: store) { return result }

        // ── Weight ──
        if let result = parseWeight(lower, store: store) { return result }

        // ── Steps ──
        if let result = parseSteps(lower, store: store) { return result }

        // ── Food / Meal ──
        if let result = parseFood(lower, original: message, store: store) { return result }

        return nil
    }

    // MARK: - Glucose

    private static func parseGlucose(_ text: String, store: HealthStore) -> ParseResult? {
        // Patterns: "log glucose 7.2", "glucose is 7.2", "my sugar is 130", "blood glucose 5.8 mmol"
        let glucosePatterns = [
            "log.*(?:glucose|sugar|bg).*?(\\d+\\.?\\d*)",
            "(?:glucose|sugar|bg).*?(?:is|was|reading).*?(\\d+\\.?\\d*)",
            "(?:glucose|sugar|bg).*?(\\d+\\.?\\d*)",
            "(\\d+\\.?\\d*).*?(?:mmol|glucose|sugar|bg)"
        ]

        for pattern in glucosePatterns {
            if let match = text.range(of: pattern, options: .regularExpression) {
                let matchStr = String(text[match])
                // Extract the number
                if let value = extractNumber(from: matchStr) {
                    // Determine if mmol/L or mg/dL
                    let isMmol = text.contains("mmol") || value < 33 // mmol/L values are < 33
                    let mgdlValue: Double = isMmol ? value * 18.0 : value
                    let displayValue = isMmol ? value : value / 18.0

                    // Log it
                    let reading = GlucoseReading(
                        value: mgdlValue,
                        date: Date(),
                        context: detectMealContext(text)
                    )
                    store.glucoseReadings.append(reading)
                    store.save()

                    let displayStr = String(format: "%.1f mmol/L", displayValue)
                    return ParseResult(
                        didLog: true,
                        loggedType: "glucose",
                        confirmationText: "[SYSTEM: User's glucose reading of \(displayStr) (\(Int(mgdlValue)) mg/dL) has been logged successfully at \(Date().formatted(date: .omitted, time: .shortened)). Acknowledge the log and provide brief context about the reading.]",
                        userFacingMessage: "Logged glucose: \(displayStr)"
                    )
                }
            }
        }
        return nil
    }

    // MARK: - Blood Pressure

    private static func parseBP(_ text: String, store: HealthStore) -> ParseResult? {
        // Patterns: "log bp 120/80", "blood pressure 130 over 85", "bp is 140/90"
        let bpPatterns = [
            "(\\d{2,3})\\s*/\\s*(\\d{2,3})",
            "(\\d{2,3})\\s+over\\s+(\\d{2,3})"
        ]

        let hasBPKeyword = text.contains("bp") || text.contains("blood pressure") ||
                           text.contains("pressure")

        guard hasBPKeyword else { return nil }

        for pattern in bpPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let nsText = text as NSString
            if let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: nsText.length)),
               match.numberOfRanges >= 3 {
                let sysStr = nsText.substring(with: match.range(at: 1))
                let diaStr = nsText.substring(with: match.range(at: 2))
                guard let sys = Int(sysStr), let dia = Int(diaStr),
                      sys >= 70 && sys <= 250, dia >= 40 && dia <= 150 else { continue }

                let reading = BPReading(systolic: sys, diastolic: dia, pulse: 0, date: Date())
                store.bpReadings.append(reading)
                store.save()

                return ParseResult(
                    didLog: true,
                    loggedType: "blood pressure",
                    confirmationText: "[SYSTEM: User's blood pressure reading of \(sys)/\(dia) mmHg has been logged successfully. Acknowledge the log and provide brief context about whether this is normal, elevated, or high.]",
                    userFacingMessage: "Logged BP: \(sys)/\(dia) mmHg"
                )
            }
        }
        return nil
    }

    // MARK: - Water

    private static func parseWater(_ text: String, store: HealthStore) -> ParseResult? {
        let hasWaterKeyword = text.contains("water") || text.contains("drank") ||
                              text.contains("hydrat")

        guard hasWaterKeyword else { return nil }

        // Patterns: "drank 500ml water", "log water 2 glasses", "had a glass of water"
        if let value = extractNumber(from: text) {
            var ml: Double

            if text.contains("glass") {
                ml = value * 250 // 1 glass = 250ml
            } else if text.contains("litre") || text.contains("liter") || text.contains("l ") {
                ml = value * 1000
            } else if value > 50 {
                ml = value // Assume ml if > 50
            } else {
                ml = value * 250 // Assume glasses if small number
            }

            let entry = WaterEntry(date: Date(), amount: ml)
            store.waterEntries.append(entry)
            store.save()

            return ParseResult(
                didLog: true,
                loggedType: "water",
                confirmationText: "[SYSTEM: User logged \(Int(ml))ml of water. Today's total is now \(Int(store.todayWaterML))ml. Acknowledge and encourage hydration.]",
                userFacingMessage: "Logged water: \(Int(ml))ml"
            )
        }

        // "had a glass of water" — no number
        if text.contains("glass") || text.contains("cup") {
            let ml: Double = 250
            let entry = WaterEntry(date: Date(), amount: ml)
            store.waterEntries.append(entry)
            store.save()

            return ParseResult(
                didLog: true,
                loggedType: "water",
                confirmationText: "[SYSTEM: User logged 250ml of water (1 glass). Today's total is now \(Int(store.todayWaterML))ml. Acknowledge.]",
                userFacingMessage: "Logged water: 250ml"
            )
        }

        return nil
    }

    // MARK: - Weight

    private static func parseWeight(_ text: String, store: HealthStore) -> ParseResult? {
        let hasWeightKeyword = text.contains("weight") || text.contains("weigh")
        guard hasWeightKeyword else { return nil }

        if let value = extractNumber(from: text) {
            // Reasonable weight range
            guard value >= 30 && value <= 300 else { return nil }

            store.userProfile.weight = value
            store.save()

            return ParseResult(
                didLog: true,
                loggedType: "weight",
                confirmationText: "[SYSTEM: User's weight updated to \(String(format: "%.1f", value)) kg. Acknowledge the update.]",
                userFacingMessage: "Updated weight: \(String(format: "%.1f", value)) kg"
            )
        }
        return nil
    }

    // MARK: - Steps

    private static func parseSteps(_ text: String, store: HealthStore) -> ParseResult? {
        let hasStepsKeyword = text.contains("steps") || text.contains("walked")
        guard hasStepsKeyword else { return nil }

        if let value = extractNumber(from: text) {
            let steps = Int(value)
            guard steps >= 100 && steps <= 100000 else { return nil }

            let entry = StepEntry(date: Date(), steps: steps)
            store.stepEntries.append(entry)
            store.save()

            return ParseResult(
                didLog: true,
                loggedType: "steps",
                confirmationText: "[SYSTEM: User logged \(steps.formatted()) steps. Today's total is now \(store.todaySteps.formatted()) steps (target: \(store.userProfile.targetSteps.formatted())). Acknowledge and encourage.]",
                userFacingMessage: "Logged steps: \(steps.formatted())"
            )
        }
        return nil
    }

    // MARK: - Food / Meal

    private static func parseFood(_ text: String, original: String, store: HealthStore) -> ParseResult? {
        // Detect food logging intent
        let hasFoodKeyword = text.contains("ate") || text.contains("eaten") || text.contains("had ") ||
                             text.contains("i ate") || text.contains("i had") ||
                             text.contains("log food") || text.contains("log meal") ||
                             text.contains("for breakfast") || text.contains("for lunch") ||
                             text.contains("for dinner") || text.contains("for snack") ||
                             text.contains("breakfast was") || text.contains("lunch was") ||
                             text.contains("dinner was") || text.contains("snack was") ||
                             text.contains("just had") || text.contains("just ate") ||
                             text.contains("i eat") || text.contains("eating")

        guard hasFoodKeyword else { return nil }

        // Detect meal type from context
        let mealType = detectMealType(text)

        // Extract food description — strip common prefixes
        let foodDescription = extractFoodDescription(text, original: original)
        guard !foodDescription.isEmpty else { return nil }

        // Search local food database for matches
        let db = FoodDatabase.shared
        let words = foodDescription.lowercased().split(separator: " ").map(String.init)
            .filter { !["and", "with", "some", "a", "the", "of", "for"].contains($0) }

        var loggedFoods: [(name: String, cal: Int, carbs: Double, protein: Double, fat: Double, fiber: Double, sugar: Double, salt: Double)] = []

        // Try to match each food word/phrase against the database
        var matchedAny = false
        for word in words {
            let results = db.search(word)
            if let best = results.first {
                let serving = Double(best.defaultServingGrams)
                let nutrition = best.nutritionFor(grams: serving)
                loggedFoods.append((
                    name: best.name,
                    cal: Int(nutrition.calories),
                    carbs: nutrition.carbs,
                    protein: nutrition.protein,
                    fat: nutrition.fat,
                    fiber: nutrition.fiber,
                    sugar: nutrition.sugar,
                    salt: nutrition.salt
                ))
                matchedAny = true
            }
        }

        // Also try multi-word searches (e.g., "chicken curry", "brown rice")
        if !matchedAny {
            let results = db.search(foodDescription)
            if let best = results.first {
                let serving = Double(best.defaultServingGrams)
                let nutrition = best.nutritionFor(grams: serving)
                loggedFoods.append((
                    name: best.name,
                    cal: Int(nutrition.calories),
                    carbs: nutrition.carbs,
                    protein: nutrition.protein,
                    fat: nutrition.fat,
                    fiber: nutrition.fiber,
                    sugar: nutrition.sugar,
                    salt: nutrition.salt
                ))
                matchedAny = true
            }
        }

        if matchedAny {
            // Log each matched food
            let totalCal = loggedFoods.map(\.cal).reduce(0, +)
            let totalCarbs = loggedFoods.map(\.carbs).reduce(0, +)
            let totalProtein = loggedFoods.map(\.protein).reduce(0, +)
            let totalFat = loggedFoods.map(\.fat).reduce(0, +)
            let totalFiber = loggedFoods.map(\.fiber).reduce(0, +)
            let totalSugar = loggedFoods.map(\.sugar).reduce(0, +)
            let totalSalt = loggedFoods.map(\.salt).reduce(0, +)
            let foodNames = loggedFoods.map(\.name).joined(separator: ", ")

            let entry = NutritionLog(
                date: Date(),
                mealType: mealType,
                calories: totalCal,
                carbs: totalCarbs,
                protein: totalProtein,
                fat: totalFat,
                fiber: totalFiber,
                sugar: totalSugar,
                salt: totalSalt,
                foodName: foodNames
            )
            store.nutritionLogs.append(entry)
            store.save()

            return ParseResult(
                didLog: true,
                loggedType: "meal",
                confirmationText: "[SYSTEM: User's \(mealType.rawValue.lowercased()) has been logged: \(foodNames) — \(totalCal) kcal, \(String(format: "%.0f", totalCarbs))g carbs, \(String(format: "%.0f", totalProtein))g protein, \(String(format: "%.0f", totalFat))g fat. Acknowledge the log. Comment on the nutritional balance. If the user is diabetic, mention the carb content and potential glucose impact.]",
                userFacingMessage: "Logged \(mealType.rawValue.lowercased()): \(foodNames) — \(totalCal) kcal"
            )
        } else {
            // No match in local DB — log with food name, zero nutrition (AI will estimate)
            let entry = NutritionLog(
                date: Date(),
                mealType: mealType,
                calories: 0,
                carbs: 0,
                protein: 0,
                fat: 0,
                fiber: 0,
                foodName: foodDescription
            )
            store.nutritionLogs.append(entry)
            store.save()

            return ParseResult(
                didLog: true,
                loggedType: "meal",
                confirmationText: "[SYSTEM: User logged \(mealType.rawValue.lowercased()): \"\(foodDescription)\" but exact nutrition data wasn't found in the local database. Acknowledge the log, provide your best estimate of calories and macros for this meal, and suggest the user can edit the entry if needed.]",
                userFacingMessage: "Logged \(mealType.rawValue.lowercased()): \(foodDescription)"
            )
        }
    }

    private static func detectMealType(_ text: String) -> MealType {
        if text.contains("breakfast") || text.contains("morning") { return .breakfast }
        if text.contains("lunch") || text.contains("afternoon") { return .lunch }
        if text.contains("dinner") || text.contains("supper") || text.contains("evening") { return .dinner }
        if text.contains("snack") { return .snack }

        // Guess by time of day
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11:  return .breakfast
        case 11..<15: return .lunch
        case 15..<17: return .snack
        default:      return .dinner
        }
    }

    private static func extractFoodDescription(_ text: String, original: String) -> String {
        // Remove common prefixes to isolate food names
        var cleaned = original

        let prefixes = [
            "i just had ", "i just ate ", "i had ", "i ate ", "i eat ",
            "just had ", "just ate ", "had ", "ate ",
            "log food ", "log meal ", "log breakfast ", "log lunch ", "log dinner ", "log snack ",
            "for breakfast i had ", "for lunch i had ", "for dinner i had ",
            "for breakfast i ate ", "for lunch i ate ", "for dinner i ate ",
            "breakfast was ", "lunch was ", "dinner was ", "snack was ",
            "for breakfast ", "for lunch ", "for dinner ", "for snack ",
            "eating ", "i'm eating ", "im eating "
        ]

        let lowerCleaned = cleaned.lowercased()
        for prefix in prefixes {
            if lowerCleaned.hasPrefix(prefix) {
                cleaned = String(cleaned.dropFirst(prefix.count))
                break
            }
        }

        // Trim trailing context like "for lunch", "today", "this morning"
        let suffixes = [" for breakfast", " for lunch", " for dinner", " for snack",
                        " today", " this morning", " this afternoon", " this evening",
                        " just now", " right now"]
        var result = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        for suffix in suffixes {
            if result.lowercased().hasSuffix(suffix) {
                result = String(result.dropLast(suffix.count))
            }
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Helpers

    private static func extractNumber(from text: String) -> Double? {
        let pattern = "\\d+\\.?\\d*"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsText = text as NSString
        if let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: nsText.length)) {
            let numStr = nsText.substring(with: match.range)
            return Double(numStr)
        }
        return nil
    }

    private static func detectMealContext(_ text: String) -> MealContext {
        if text.contains("fasting") || text.contains("morning") {
            return .fasting
        }
        if text.contains("after") || text.contains("post") {
            return .afterMeal
        }
        if text.contains("before meal") || text.contains("pre") {
            return .beforeMeal
        }
        if text.contains("bedtime") || text.contains("night") || text.contains("sleep") {
            return .bedtime
        }
        return .random
    }
}
