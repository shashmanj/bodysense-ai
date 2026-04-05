//
//  ProactiveInsightEngine.swift
//  body sense ai
//
//  Calls /ai/insights with patient context + triggering event.
//  Returns structured InsightCards for the home feed.
//

import Foundation

@MainActor
enum ProactiveInsightEngine {

    private static let backendURL = "https://body-sense-ai-production.up.railway.app"

    // MARK: - Public API

    /// Generate insight cards for a triggering event.
    static func generate(store: HealthStore, event: InsightEvent) async -> [InsightCard] {
        let context = buildPatientContext(store: store)
        let eventPayload = event.toDict()

        do {
            return try await callBackend(patientContext: context, currentEvent: eventPayload, email: store.userProfile.email)
        } catch {
            #if DEBUG
            print("⚠️ [InsightEngine] Backend call failed: \(error.localizedDescription)")
            #endif
            // Fallback: return local insights from PersonalisedInsightEngine
            return localFallback(store: store, event: event)
        }
    }

    /// Quick daily summary trigger.
    static func dailySummary(store: HealthStore) async -> [InsightCard] {
        await generate(store: store, event: .dailySummary)
    }

    /// Trigger after a meal is logged.
    static func mealLogged(store: HealthStore, meal: NutritionLog) async -> [InsightCard] {
        await generate(store: store, event: .mealLogged(meal))
    }

    /// Trigger after a vital reading.
    static func vitalLogged(store: HealthStore, type: String, value: Double) async -> [InsightCard] {
        await generate(store: store, event: .vitalLogged(type: type, value: value))
    }

    // MARK: - Backend Call

    private static func callBackend(patientContext: [String: Any], currentEvent: [String: Any], email: String) async throws -> [InsightCard] {
        guard let url = URL(string: "\(backendURL)/ai/insights") else {
            throw URLError(.badURL)
        }

        let body: [String: Any] = [
            "patientContext": patientContext,
            "currentEvent": currentEvent,
            "userEmail": email
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder.insightDecoder.decode(InsightResponse.self, from: data)
        return decoded.insightCards
    }

    // MARK: - Build Patient Context

    private static func buildPatientContext(store: HealthStore) -> [String: Any] {
        let p = store.userProfile
        let cal = Calendar.current

        // Identity
        var identity: [String: Any] = [
            "age": p.age,
            "gender": p.gender,
            "country": p.country
        ]
        if p.weight > 0 { identity["weight_kg"] = p.weight }
        if p.height > 0 { identity["height_cm"] = p.height }
        if p.weight > 0 && p.height > 0 {
            let heightM = p.height / 100
            identity["bmi"] = round(p.weight / (heightM * heightM) * 10) / 10
        }

        // Conditions
        var conditions: [String] = []
        if p.diabetesType.lowercased().contains("type 2") { conditions.append("Type 2 Diabetes") }
        if p.diabetesType.lowercased().contains("type 1") { conditions.append("Type 1 Diabetes") }
        if p.hasHypertension { conditions.append("Hypertension") }

        // Medications
        let activeMeds = store.medications.filter { $0.isActive }.map { med -> [String: Any] in
            ["name": med.name, "dosage": med.dosage, "frequency": med.frequency.rawValue]
        }

        // Today's intake
        let todayLogs = store.nutritionLogs.filter { cal.isDateInToday($0.date) }
        let todayIntake: [String: Any] = [
            "calories": todayLogs.map(\.calories).reduce(0, +),
            "protein_g": todayLogs.map(\.protein).reduce(0, +),
            "carbs_g": todayLogs.map(\.carbs).reduce(0, +),
            "fat_g": todayLogs.map(\.fat).reduce(0, +),
            "fiber_g": todayLogs.map(\.fiber).reduce(0, +),
            "sugar_g": todayLogs.map(\.sugar).reduce(0, +),
            "salt_g": todayLogs.map(\.salt).reduce(0, +),
            "meals_logged": todayLogs.count,
            "water_ml": store.todayWaterML
        ]

        // Recent vitals (last 7 days)
        let weekAgo = cal.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        var recentVitals: [String: Any] = [:]

        let recentGlucose = store.glucoseReadings.filter { $0.date >= weekAgo }
        if !recentGlucose.isEmpty {
            recentVitals["glucose"] = recentGlucose.suffix(10).map { [
                "value_mmol": round($0.value / 18.0 * 10) / 10,
                "context": $0.context.rawValue,
                "date": ISO8601DateFormatter().string(from: $0.date)
            ] as [String: Any] }
        }

        let recentBP = store.bpReadings.filter { $0.date >= weekAgo }
        if !recentBP.isEmpty {
            recentVitals["bp"] = recentBP.suffix(10).map { [
                "systolic": $0.systolic, "diastolic": $0.diastolic, "pulse": $0.pulse,
                "date": ISO8601DateFormatter().string(from: $0.date)
            ] as [String: Any] }
        }

        let recentSleep = store.sleepEntries.filter { $0.date >= weekAgo }
        if !recentSleep.isEmpty {
            recentVitals["sleep"] = recentSleep.suffix(7).map { [
                "hours": $0.duration, "quality": $0.quality.rawValue,
                "date": ISO8601DateFormatter().string(from: $0.date)
            ] as [String: Any] }
        }

        recentVitals["steps_today"] = store.todaySteps

        if let latestHR = store.latestHR {
            recentVitals["heart_rate_bpm"] = latestHR.value
        }
        if let latestHRV = store.latestHRV {
            recentVitals["hrv_ms"] = Int(latestHRV.value)
        }

        // Adherence
        let adherence: [String: Any] = [
            "logging_streak": store.userStreaks.first?.currentCount ?? 0,
            "daily_ai_messages": store.dailyAIMessagesUsed
        ]

        return [
            "identity": identity,
            "conditions": conditions,
            "medications": activeMeds,
            "todayIntake": todayIntake,
            "recentVitals": recentVitals,
            "adherence": adherence,
            "selectedGoals": p.selectedGoals
        ]
    }

    // MARK: - Local Fallback

    private static func localFallback(store: HealthStore, event: InsightEvent) -> [InsightCard] {
        let tips = PersonalisedInsightEngine.generate(from: store)
        let now = Date()
        return tips.prefix(3).enumerated().map { index, tip in
            InsightCard(
                id: "ins_local_\(Int(now.timeIntervalSince1970))_\(index)",
                type: .insight,
                severity: .info,
                title: "Health Insight",
                body: tip,
                evidence: nil,
                action: nil,
                expiresAt: Calendar.current.date(byAdding: .hour, value: 12, to: now),
                relatedMetrics: []
            )
        }
    }
}

// MARK: - Insight Event Types

enum InsightEvent {
    case mealLogged(NutritionLog)
    case vitalLogged(type: String, value: Double)
    case medicationEvent(name: String, taken: Bool)
    case healthKitPush
    case dailySummary
    case hourlySweep
    case streakChange(type: String, count: Int)

    func toDict() -> [String: Any] {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        switch self {
        case .mealLogged(let meal):
            return [
                "type": "meal_logged",
                "timestamp": timestamp,
                "data": [
                    "mealType": meal.mealType.rawValue,
                    "foodName": meal.foodName,
                    "calories": meal.calories,
                    "protein": meal.protein,
                    "carbs": meal.carbs,
                    "fat": meal.fat,
                    "fiber": meal.fiber,
                    "sugar": meal.sugar,
                    "salt": meal.salt
                ] as [String: Any]
            ]
        case .vitalLogged(let type, let value):
            return [
                "type": "vital_logged",
                "timestamp": timestamp,
                "data": ["metric": type, "value": value] as [String: Any]
            ]
        case .medicationEvent(let name, let taken):
            return [
                "type": "medication_event",
                "timestamp": timestamp,
                "data": ["medication": name, "taken": taken] as [String: Any]
            ]
        case .healthKitPush:
            return ["type": "healthkit_push", "timestamp": timestamp, "data": [:] as [String: Any]]
        case .dailySummary:
            return ["type": "daily_summary", "timestamp": timestamp, "data": [:] as [String: Any]]
        case .hourlySweep:
            return ["type": "hourly_sweep", "timestamp": timestamp, "data": [:] as [String: Any]]
        case .streakChange(let type, let count):
            return [
                "type": "streak_change",
                "timestamp": timestamp,
                "data": ["streakType": type, "count": count] as [String: Any]
            ]
        }
    }
}

// MARK: - Response Model

private struct InsightResponse: Codable {
    let insightCards: [InsightCard]
    let updatedTargets: [String: Double]?
    let emergencyFlag: Bool?
}

// MARK: - Custom JSON Decoder

extension JSONDecoder {
    static let insightDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
