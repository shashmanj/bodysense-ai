//
//  SmartNotificationEngine.swift
//  body sense ai
//
//  Pattern-triggered intelligent notifications via UNNotificationCenter.
//  Scheduled on each app-foreground event. No dumb reminders — every
//  notification is driven by real health data patterns.
//

import Foundation
import UserNotifications

// MARK: - Smart Notification Engine

enum SmartNotificationEngine {

    /// Category identifiers for notification actions
    private static let categoryID = "bodysense.smart"

    // MARK: - Public API

    /// Schedule smart notifications based on user's current health data.
    /// Call this on each app-foreground (ScenePhase.active).
    static func scheduleSmartNotifications(store: HealthStore) {
        let prefs = store.userProfile.notificationPreferences

        // Clear previously scheduled smart notifications
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers:
            store.smartNotifications.map(\.id.uuidString)
        )

        var notifications: [SmartHealthNotification] = []

        // 1. Drug-nutrient reminders
        if prefs.aiInsights {
            notifications.append(contentsOf: drugNutrientReminders(store: store))
        }

        // 2. BP pattern alerts
        if prefs.bpAlerts {
            notifications.append(contentsOf: bpPatternAlerts(store: store))
        }

        // 3. Glucose trend warnings
        if prefs.glucoseAlerts {
            notifications.append(contentsOf: glucoseTrendWarnings(store: store))
        }

        // 4. Meal timing reminders
        if prefs.medicationReminders {
            notifications.append(contentsOf: mealTimingReminders(store: store))
        }

        // 5. Achievement celebrations
        if prefs.aiInsights {
            notifications.append(contentsOf: achievementNotifications(store: store))
        }

        // 6. GP suggestion
        if let gpReport = GPBridgeProtocol.shouldSuggestGP(store: store) {
            notifications.append(SmartHealthNotification(
                type: .gpSuggestion,
                title: "Consider a GP Visit",
                message: gpReport.reason.prefix(150) + (gpReport.reason.count > 150 ? "..." : ""),
                scheduledFor: Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date(),
                priority: gpReport.urgency == .urgent ? 5 : gpReport.urgency == .soon ? 4 : 3
            ))
        }

        // Schedule all via UNNotificationCenter
        for notification in notifications {
            scheduleLocal(notification)
        }

        // Store references for cleanup
        store.smartNotifications = notifications
    }

    /// Cancel all pending smart notifications.
    static func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Drug-Nutrient Reminders

    private static func drugNutrientReminders(store: HealthStore) -> [SmartHealthNotification] {
        var notifications: [SmartHealthNotification] = []
        let activeMeds = store.medications.filter(\.isActive)
        let interactions = DrugNutrientDatabase.interactionsForMedications(activeMeds)

        for interaction in interactions {
            let highSeverity = interaction.depletedNutrients.filter { $0.severity == .high || $0.severity == .moderate }
            guard !highSeverity.isEmpty else { continue }

            let nutrients = highSeverity.map(\.nutrient).joined(separator: ", ")
            let mitigations = highSeverity.map(\.mitigation).first ?? ""

            // Schedule for tomorrow morning at 9 AM
            let tomorrow9AM = nextOccurrence(hour: 9, minute: 0)

            notifications.append(SmartHealthNotification(
                type: .drugNutrient,
                title: "\(interaction.genericName.capitalized) & Nutrition",
                message: "Your \(interaction.genericName) may affect \(nutrients) levels. \(mitigations)",
                scheduledFor: tomorrow9AM,
                priority: 3
            ))
        }

        return notifications
    }

    // MARK: - BP Pattern Alerts

    private static func bpPatternAlerts(store: HealthStore) -> [SmartHealthNotification] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentBP = store.bpReadings.filter { $0.date >= sevenDaysAgo }

        guard recentBP.count >= 3 else { return [] }

        if let trend = BPEscalationEngine.trendAnalysis(readings: recentBP) {
            let notification = SmartHealthNotification(
                type: .bpPattern,
                title: "Blood Pressure Trend",
                message: trend,
                scheduledFor: nextOccurrence(hour: 10, minute: 0),
                priority: 4
            )
            return [notification]
        }

        return []
    }

    // MARK: - Glucose Trend Warnings

    private static func glucoseTrendWarnings(store: HealthStore) -> [SmartHealthNotification] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentGlucose = store.glucoseReadings.filter { $0.date >= sevenDaysAgo }

        guard recentGlucose.count >= 5 else { return [] }

        let targetMin = store.userProfile.targetGlucoseMin
        let targetMax = store.userProfile.targetGlucoseMax
        let outOfRange = recentGlucose.filter { $0.value < targetMin || $0.value > targetMax }
        let outPercent = Double(outOfRange.count) / Double(recentGlucose.count)

        guard outPercent > 0.3 else { return [] }

        // Check if mostly high or low
        let highCount = recentGlucose.filter { $0.value > targetMax }.count
        let lowCount = recentGlucose.filter { $0.value < targetMin }.count

        let message: String
        if highCount > lowCount {
            message = "Your glucose has been above target in \(Int(outPercent * 100))% of readings this week. A 15-minute walk after meals can help reduce post-meal spikes."
        } else {
            message = "Your glucose has been below target in some readings. Check your meal timing and medication doses with your healthcare team."
        }

        return [SmartHealthNotification(
            type: .glucoseTrend,
            title: "Glucose Trend Alert",
            message: message,
            scheduledFor: nextOccurrence(hour: 8, minute: 30),
            priority: highCount > lowCount ? 3 : 4
        )]
    }

    // MARK: - Meal Timing Reminders

    private static func mealTimingReminders(store: HealthStore) -> [SmartHealthNotification] {
        var notifications: [SmartHealthNotification] = []
        let activeMeds = store.medications.filter(\.isActive)

        for med in activeMeds {
            guard let interaction = DrugNutrientDatabase.interactions(for: (med.genericName ?? med.name)) else { continue }
            let timing = interaction.timingAdvice.lowercased()

            if timing.contains("empty stomach") || timing.contains("before breakfast") || timing.contains("30 min") {
                notifications.append(SmartHealthNotification(
                    type: .mealTiming,
                    title: "\(med.name) — Take Before Breakfast",
                    message: interaction.timingAdvice,
                    scheduledFor: nextOccurrence(hour: 7, minute: 0),
                    priority: 4
                ))
            }
        }

        return notifications
    }

    // MARK: - Achievement Notifications

    private static func achievementNotifications(store: HealthStore) -> [SmartHealthNotification] {
        var notifications: [SmartHealthNotification] = []
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        // Check glucose streak
        let recentGlucose = store.glucoseReadings.filter { $0.date >= sevenDaysAgo }
        if recentGlucose.count >= 10 {
            let inRange = recentGlucose.filter {
                $0.value >= store.userProfile.targetGlucoseMin && $0.value <= store.userProfile.targetGlucoseMax
            }
            let tir = Double(inRange.count) / Double(recentGlucose.count)
            if tir >= 0.7 {
                notifications.append(SmartHealthNotification(
                    type: .achievement,
                    title: "Great Glucose Control!",
                    message: "\(Int(tir * 100))% of your readings were in range this week. Keep it up!",
                    scheduledFor: nextOccurrence(hour: 19, minute: 0),
                    priority: 2
                ))
            }
        }

        // Check step streak
        let recentSteps = store.stepEntries.filter { $0.date >= sevenDaysAgo }
        let daysWithGoal = recentSteps.filter { $0.steps >= store.userProfile.targetSteps }.count
        if daysWithGoal >= 5 {
            notifications.append(SmartHealthNotification(
                type: .achievement,
                title: "Step Goal Streak!",
                message: "You hit your step goal on \(daysWithGoal) out of 7 days this week. Brilliant!",
                scheduledFor: nextOccurrence(hour: 19, minute: 30),
                priority: 2
            ))
        }

        return notifications
    }

    // MARK: - Scheduling

    private static func scheduleLocal(_ notification: SmartHealthNotification) {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.message
        content.sound = notification.priority >= 4 ? .default : .default
        content.categoryIdentifier = categoryID

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notification.scheduledFor)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: notification.id.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[SmartNotifications] Failed to schedule: \(error.localizedDescription)")
            }
        }
    }

    private static func nextOccurrence(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute

        if let date = calendar.date(from: components), date > Date() {
            return date
        }
        // Tomorrow at the specified time
        components.day = (components.day ?? 0) + 1
        return calendar.date(from: components) ?? Date()
    }
}
