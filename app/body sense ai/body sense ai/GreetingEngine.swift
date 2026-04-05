//
//  GreetingEngine.swift
//  body sense ai
//
//  Generates contextual, time-aware smart greetings.
//  Never says "no data" or "get started". Day 1 users get a warm welcome.
//  Checks: festivals → milestones → streaks → data observations → time-of-day.
//

import Foundation

@MainActor
enum GreetingEngine {

    // MARK: - Main Entry

    /// Generate a contextual greeting for the dashboard header.
    /// Returns (title, subtitle).
    static func generateGreeting(store: HealthStore, mood: HealthMood) -> (title: String, subtitle: String) {
        let profile = store.userProfile
        let firstName = extractFirstName(profile.name)
        let hour = Calendar.current.component(.hour, from: Date())

        // 1. Active cultural festival?
        if let festivalGreeting = festivalGreeting(store: store, name: firstName) {
            return festivalGreeting
        }

        // 2. Health milestone achieved today?
        if let milestone = milestoneGreeting(store: store, name: firstName) {
            return milestone
        }

        // 3. Streak celebration?
        if let streak = streakGreeting(store: store, name: firstName) {
            return streak
        }

        // 4. Data-driven observation?
        if let observation = dataObservation(store: store, mood: mood, name: firstName) {
            return observation
        }

        // 5. Time-of-day greeting (fallback — always has something warm)
        let title = timeGreeting(hour: hour, name: firstName)
        let subtitle = mood.level == .unknown
            ? "I'm here whenever you're ready"
            : mood.summary

        return (title, subtitle)
    }

    // MARK: - Festival Greeting

    private static func festivalGreeting(store: HealthStore, name: String) -> (title: String, subtitle: String)? {
        // Festival greetings require CulturalProfile — will be enabled once profile model is expanded
        return nil
    }

    // MARK: - Milestone Greeting

    private static func milestoneGreeting(store: HealthStore, name: String) -> (title: String, subtitle: String)? {
        // Steps milestone
        let steps = store.todaySteps
        if steps >= 10000 {
            return ("You hit \(steps.formatted()) steps today!", "Keep that momentum going, \(name)")
        }

        // Water target hit
        let waterML = store.todayWaterML
        let targetML = store.userProfile.targetWater * 1000
        if targetML > 0 && waterML >= targetML {
            return ("Hydration target smashed!", "Well done staying on top of your water, \(name)")
        }

        return nil
    }

    // MARK: - Streak Greeting

    private static func streakGreeting(store: HealthStore, name: String) -> (title: String, subtitle: String)? {
        // Check glucose logging streak
        let cal = Calendar.current
        var streak = 0
        var checkDate = Date()

        for _ in 0..<30 {
            let hasReading = store.glucoseReadings.contains { cal.isDate($0.date, inSameDayAs: checkDate) }
            if hasReading {
                streak += 1
                checkDate = cal.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }

        if streak >= 7 {
            return ("\(streak)-day glucose logging streak!", "Consistency is everything, \(name)")
        }

        // Check meal logging streak
        streak = 0
        checkDate = Date()
        for _ in 0..<30 {
            let hasMeal = store.nutritionLogs.contains { cal.isDate($0.date, inSameDayAs: checkDate) }
            if hasMeal {
                streak += 1
                checkDate = cal.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }

        if streak >= 5 {
            return ("\(streak)-day meal tracking streak!", "Your nutrition picture is getting clearer")
        }

        return nil
    }

    // MARK: - Data Observation

    private static func dataObservation(store: HealthStore, mood: HealthMood, name: String) -> (title: String, subtitle: String)? {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: Date())

        // Compare this week's sleep to last week
        let thisWeekSleep = averageSleep(store: store, daysAgo: 0...6)
        let lastWeekSleep = averageSleep(store: store, daysAgo: 7...13)

        if let thisWeek = thisWeekSleep, let lastWeek = lastWeekSleep, lastWeek > 0 {
            let change = ((thisWeek - lastWeek) / lastWeek) * 100
            if change >= 10 {
                let title = timeGreeting(hour: hour, name: name)
                return (title, "Your sleep improved \(Int(change))% this week")
            }
        }

        // If mood has a good summary, use it
        if mood.level != .unknown {
            let title = timeGreeting(hour: hour, name: name)
            return (title, mood.summary)
        }

        return nil
    }

    // MARK: - Time Greeting

    private static func timeGreeting(hour: Int, name: String) -> String {
        let displayName = name.isEmpty ? "" : ", \(name)"
        switch hour {
        case 5..<12:  return "Good morning\(displayName)"
        case 12..<17: return "Good afternoon\(displayName)"
        case 17..<21: return "Good evening\(displayName)"
        default:      return "Hey\(displayName)"
        }
    }

    // MARK: - Helpers

    private static func extractFirstName(_ fullName: String) -> String {
        let first = fullName.trimmingCharacters(in: .whitespaces).components(separatedBy: " ").first ?? ""
        return first.isEmpty ? "" : first
    }

    private static func averageSleep(store: HealthStore, daysAgo range: ClosedRange<Int>) -> Double? {
        let cal = Calendar.current
        var totalHours: Double = 0
        var daysWithData = 0

        for offset in range {
            guard let date = cal.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let daySleep = store.sleepEntries.filter { cal.isDate($0.date, inSameDayAs: date) }
            let hours = daySleep.map(\.duration).reduce(0, +)
            if hours > 0 {
                totalHours += hours
                daysWithData += 1
            }
        }

        guard daysWithData > 0 else { return nil }
        return totalHours / Double(daysWithData)
    }
}
