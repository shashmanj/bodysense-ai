//
//  GPBridgeProtocol.swift
//  body sense ai
//
//  GP Bridge Protocol: determines when to suggest a GP visit, what data to
//  prepare, and generates a shareable health summary. Cross-cutting concern
//  used by HealthSenseAgent, Dashboard, and SmartNotificationEngine.
//

import Foundation

// MARK: - GP Bridge Protocol

enum GPBridgeProtocol {

    // MARK: - Public API

    /// Evaluate whether the user should be advised to see their GP.
    /// Returns nil if no GP visit is needed.
    static func shouldSuggestGP(store: HealthStore) -> GPBridgeReport? {
        var triggers: [(reason: String, urgency: GPBridgeUrgency)] = []

        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!

        // 1. BP consistently above amber threshold (3+ readings in 7 days)
        let recentBP = store.bpReadings.filter { $0.date >= sevenDaysAgo }
        let elevatedBP = recentBP.filter { $0.systolic >= 140 || $0.diastolic >= 90 }
        if elevatedBP.count >= 3 {
            let avgSys = elevatedBP.map(\.systolic).reduce(0, +) / elevatedBP.count
            let avgDia = elevatedBP.map(\.diastolic).reduce(0, +) / elevatedBP.count
            let urgency: GPBridgeUrgency = elevatedBP.contains(where: { $0.systolic >= 180 || $0.diastolic >= 110 }) ? .urgent : .soon
            triggers.append((
                "Blood pressure has been elevated (\(elevatedBP.count) of \(recentBP.count) readings above 140/90, avg \(avgSys)/\(avgDia)) over the past 7 days.",
                urgency
            ))
        }

        // 2. Glucose trending out of range (>30% out-of-range in 7 days)
        let recentGlucose = store.glucoseReadings.filter { $0.date >= sevenDaysAgo }
        if recentGlucose.count >= 5 {
            let targetMin = store.userProfile.targetGlucoseMin
            let targetMax = store.userProfile.targetGlucoseMax
            let outOfRange = recentGlucose.filter { $0.value < targetMin || $0.value > targetMax }
            let outPercent = Double(outOfRange.count) / Double(recentGlucose.count)
            if outPercent > 0.3 {
                triggers.append((
                    "Glucose has been out of target range in \(Int(outPercent * 100))% of readings this week (\(outOfRange.count) of \(recentGlucose.count)).",
                    outPercent > 0.5 ? .soon : .routine
                ))
            }
        }

        // 3. Symptoms logged with concerning patterns
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!
        let recentSymptoms = store.symptomLogs.filter { $0.date >= thirtyDaysAgo }
        let symptomCounts: [String: Int] = recentSymptoms.reduce(into: [:]) { dict, log in
            for symptom in log.symptoms {
                dict[symptom, default: 0] += 1
            }
        }
        let frequentSymptoms = symptomCounts.filter { $0.value >= 5 }
        if !frequentSymptoms.isEmpty {
            let symptomList = frequentSymptoms.map { "\($0.key) (\($0.value)×)" }.joined(separator: ", ")
            triggers.append((
                "Recurring symptoms in the past 30 days: \(symptomList). Your GP may want to investigate.",
                .routine
            ))
        }

        // 4. No glucose monitoring despite diabetes
        let dt = store.userProfile.diabetesType.lowercased()
        if (dt.contains("type 1") || dt.contains("type 2")) && recentGlucose.isEmpty {
            triggers.append((
                "No glucose readings logged in the past 7 days despite diabetes diagnosis. Regular monitoring is important.",
                .routine
            ))
        }

        guard !triggers.isEmpty else { return nil }

        // Pick highest urgency
        let maxUrgency = triggers.map(\.urgency).max(by: { urgencyRank($0) < urgencyRank($1) }) ?? .routine

        // Build combined report
        let reasons = triggers.map(\.reason)
        let dataToShare = buildDataToShare(store: store)
        let suggestedQuestions = buildSuggestedQuestions(triggers: triggers, store: store)

        return GPBridgeReport(
            reason: reasons.joined(separator: " "),
            urgency: maxUrgency,
            dataToShare: dataToShare,
            suggestedQuestions: suggestedQuestions
        )
    }

    /// Generate a detailed report for a specific reason.
    static func generateReport(store: HealthStore, reason: String) -> GPBridgeReport {
        return GPBridgeReport(
            reason: reason,
            urgency: .routine,
            dataToShare: buildDataToShare(store: store),
            suggestedQuestions: [
                "Based on my recent health data, are there any concerns?",
                "Should we adjust my current medications?",
                "Are there any additional tests you'd recommend?",
                "What lifestyle changes would have the most impact?"
            ]
        )
    }

    /// Format a plain-text health summary suitable for sharing with a GP.
    static func formatGPSummary(store: HealthStore) -> String {
        let profile = store.userProfile
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

        var summary = "BodySense AI — Health Summary for GP\n"
        summary += "Generated: \(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .short))\n"
        summary += String(repeating: "─", count: 50) + "\n\n"

        // Patient info
        summary += "PATIENT: \(profile.name.isEmpty ? "Not provided" : profile.name)\n"
        summary += "Age: \(profile.age) | Gender: \(profile.gender)\n"
        summary += "Weight: \(String(format: "%.1f", profile.weight)) kg | Height: \(String(format: "%.0f", profile.height)) cm\n"
        let bmi = profile.weight / pow(profile.height / 100, 2)
        summary += "BMI: \(String(format: "%.1f", bmi))\n"
        summary += "Diabetes: \(profile.diabetesType)\n"
        summary += "Hypertension: \(profile.hasHypertension ? "Yes" : "No")\n\n"

        // Medications
        let activeMeds = store.medications.filter(\.isActive)
        if !activeMeds.isEmpty {
            summary += "CURRENT MEDICATIONS:\n"
            for med in activeMeds {
                summary += "• \(med.name) \(med.dosage)\(med.unit) — \(med.frequency.rawValue)\n"
            }
            summary += "\n"
        }

        // BP readings (7 days)
        let recentBP = store.bpReadings.filter { $0.date >= sevenDaysAgo }.sorted(by: { $0.date > $1.date })
        if !recentBP.isEmpty {
            let avgSys = recentBP.map(\.systolic).reduce(0, +) / recentBP.count
            let avgDia = recentBP.map(\.diastolic).reduce(0, +) / recentBP.count
            summary += "BLOOD PRESSURE (Last 7 days, \(recentBP.count) readings):\n"
            summary += "Average: \(avgSys)/\(avgDia) mmHg\n"
            for reading in recentBP.prefix(7) {
                let dateStr = DateFormatter.localizedString(from: reading.date, dateStyle: .short, timeStyle: .short)
                summary += "  \(dateStr): \(reading.systolic)/\(reading.diastolic) mmHg (pulse \(reading.pulse))\n"
            }
            summary += "\n"
        }

        // Glucose readings (7 days)
        let recentGlucose = store.glucoseReadings.filter { $0.date >= sevenDaysAgo }
        if !recentGlucose.isEmpty {
            let avg = recentGlucose.map(\.value).reduce(0, +) / Double(recentGlucose.count)
            let inRange = recentGlucose.filter { $0.value >= profile.targetGlucoseMin && $0.value <= profile.targetGlucoseMax }
            let tir = Double(inRange.count) / Double(recentGlucose.count) * 100
            summary += "GLUCOSE (Last 7 days, \(recentGlucose.count) readings):\n"
            summary += "Average: \(String(format: "%.1f", avg)) mmol/L | Time in range: \(String(format: "%.0f", tir))%\n"
            summary += "Target: \(String(format: "%.0f", profile.targetGlucoseMin))-\(String(format: "%.0f", profile.targetGlucoseMax)) mmol/L\n\n"
        }

        // Symptoms (30 days)
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        let symptoms = store.symptomLogs.filter { $0.date >= thirtyDaysAgo }
        if !symptoms.isEmpty {
            let grouped: [String: Int] = symptoms.reduce(into: [:]) { dict, log in
                for s in log.symptoms { dict[s, default: 0] += 1 }
            }
            summary += "SYMPTOMS (Last 30 days):\n"
            for (symptom, count) in grouped.sorted(by: { $0.value > $1.value }) {
                summary += "• \(symptom): \(count) occurrence(s)\n"
            }
            summary += "\n"
        }

        summary += String(repeating: "─", count: 50) + "\n"
        summary += "This summary was generated by BodySense AI for informational purposes.\n"
        summary += "It is not a medical diagnosis. Please discuss with your healthcare provider.\n"

        return summary
    }

    // MARK: - Private Helpers

    private static func urgencyRank(_ urgency: GPBridgeUrgency) -> Int {
        switch urgency {
        case .routine: return 0
        case .soon:    return 1
        case .urgent:  return 2
        }
    }

    private static func buildDataToShare(store: HealthStore) -> [String] {
        var data: [String] = []
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

        let recentBP = store.bpReadings.filter { $0.date >= sevenDaysAgo }
        if !recentBP.isEmpty {
            let avg = recentBP.map(\.systolic).reduce(0, +) / recentBP.count
            data.append("Last 7 days BP: \(recentBP.count) readings, avg systolic \(avg) mmHg")
        }

        let recentGlucose = store.glucoseReadings.filter { $0.date >= sevenDaysAgo }
        if !recentGlucose.isEmpty {
            let avg = recentGlucose.map(\.value).reduce(0, +) / Double(recentGlucose.count)
            data.append("Last 7 days glucose: \(recentGlucose.count) readings, avg \(String(format: "%.1f", avg)) mmol/L")
        }

        let activeMeds = store.medications.filter(\.isActive)
        if !activeMeds.isEmpty {
            data.append("Current medications: \(activeMeds.map(\.name).joined(separator: ", "))")
        }

        let symptoms = store.symptomLogs.suffix(10)
        if !symptoms.isEmpty {
            let names = Set(symptoms.flatMap(\.symptoms))
            data.append("Recent symptoms: \(names.joined(separator: ", "))")
        }

        return data
    }

    private static func buildSuggestedQuestions(triggers: [(reason: String, urgency: GPBridgeUrgency)], store: HealthStore) -> [String] {
        var questions: [String] = []

        for trigger in triggers {
            if trigger.reason.contains("Blood pressure") {
                questions.append("My BP has been running high — should we review my medication?")
                questions.append("Would you recommend ambulatory blood pressure monitoring (ABPM)?")
            }
            if trigger.reason.contains("Glucose") || trigger.reason.contains("glucose") {
                questions.append("My glucose has been out of range — should we adjust my treatment?")
                questions.append("Would you recommend an HbA1c test?")
            }
            if trigger.reason.contains("symptoms") || trigger.reason.contains("Symptoms") {
                questions.append("I've been experiencing recurring symptoms — could these be related to my medication or condition?")
            }
        }

        if questions.isEmpty {
            questions = [
                "Based on my recent health data, are there any concerns?",
                "What lifestyle changes would have the most impact?"
            ]
        }

        return Array(Set(questions)) // deduplicate
    }
}
