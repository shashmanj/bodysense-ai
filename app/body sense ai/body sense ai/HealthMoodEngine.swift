//
//  HealthMoodEngine.swift
//  body sense ai
//
//  Computes a composite health mood score from all available data.
//  Weights vitals based on user conditions (diabetic → glucose 3x, etc.).
//  Drives the HealthMoodFace expression and HealthMoodCard display.
//

import Foundation

@MainActor
enum HealthMoodEngine {

    // MARK: - Main Computation

    /// Compute the overall health mood from current HealthStore data.
    static func computeMood(store: HealthStore) -> HealthMood {
        let profile = store.userProfile
        let isDiabetic = profile.diabetesType.lowercased().contains("diabetes")
        let isHypertensive = profile.hasHypertension
        let cal = Calendar.current

        // Collect individual scores (0-100 each, or nil if no data)
        var weightedScores: [(score: Double, weight: Double, indicator: MoodIndicator)] = []

        // ── Glucose ──
        let todayGlucose = store.glucoseReadings.filter { cal.isDateInToday($0.date) }
        if let latest = todayGlucose.sorted(by: { $0.date > $1.date }).first {
            let score = glucoseScore(mgdl: latest.value, isDiabetic: isDiabetic)
            let status = indicatorStatus(score: score)
            let weight: Double = isDiabetic ? 3.0 : 1.0
            weightedScores.append((
                score: score,
                weight: weight,
                indicator: MoodIndicator(name: "Glucose", status: status, icon: "drop.fill")
            ))
        } else if isDiabetic {
            weightedScores.append((
                score: 50, weight: 0.5,
                indicator: MoodIndicator(name: "Glucose", status: .noData, icon: "drop.fill")
            ))
        }

        // ── Blood Pressure ──
        let todayBP = store.bpReadings.filter { cal.isDateInToday($0.date) }
        if let latest = todayBP.sorted(by: { $0.date > $1.date }).first {
            let score = bpScore(systolic: latest.systolic, diastolic: latest.diastolic)
            let status = indicatorStatus(score: score)
            let weight: Double = isHypertensive ? 3.0 : 1.0
            weightedScores.append((
                score: score,
                weight: weight,
                indicator: MoodIndicator(name: "BP", status: status, icon: "heart.fill")
            ))
        } else if isHypertensive {
            weightedScores.append((
                score: 50, weight: 0.5,
                indicator: MoodIndicator(name: "BP", status: .noData, icon: "heart.fill")
            ))
        }

        // ── Sleep ──
        let recentSleep = store.sleepEntries
            .filter { cal.isDate($0.date, equalTo: cal.date(byAdding: .day, value: -1, to: Date())!, toGranularity: .day) }
        let totalSleepHours = recentSleep.map { $0.duration }.reduce(0, +)
        if totalSleepHours > 0 {
            let score = sleepScore(hours: totalSleepHours)
            let status = indicatorStatus(score: score)
            weightedScores.append((
                score: score,
                weight: 1.5,
                indicator: MoodIndicator(name: "Sleep", status: status, icon: "moon.fill")
            ))
        }

        // ── Steps ──
        let steps = store.todaySteps
        if steps > 0 {
            let target = profile.targetSteps > 0 ? profile.targetSteps : 10000
            let score = stepsScore(steps: steps, target: target)
            let status = indicatorStatus(score: score)
            weightedScores.append((
                score: score,
                weight: 1.0,
                indicator: MoodIndicator(name: "Steps", status: status, icon: "figure.walk")
            ))
        }

        // ── Heart Rate ──
        let todayHR = store.heartRateReadings.filter { cal.isDateInToday($0.date) }
        if let latest = todayHR.sorted(by: { $0.date > $1.date }).first {
            let score = heartRateScore(bpm: Double(latest.value), age: profile.age)
            let status = indicatorStatus(score: score)
            weightedScores.append((
                score: score,
                weight: 0.8,
                indicator: MoodIndicator(name: "Heart Rate", status: status, icon: "waveform.path.ecg")
            ))
        }

        // ── Water ──
        let waterML = store.todayWaterML
        if waterML > 0 {
            let targetML: Double = profile.targetWater > 0 ? profile.targetWater * 1000 : 2500
            let score = min(100, (waterML / targetML) * 100)
            let status = indicatorStatus(score: score)
            weightedScores.append((
                score: score,
                weight: 0.6,
                indicator: MoodIndicator(name: "Water", status: status, icon: "drop.triangle.fill")
            ))
        }

        // ── HRV (if CKD or cardiac) ──
        let todayHRV = store.hrvReadings.filter { cal.isDateInToday($0.date) }
        if let latest = todayHRV.sorted(by: { $0.date > $1.date }).first {
            let score = hrvScore(ms: latest.value)
            let status = indicatorStatus(score: score)
            let weight: Double = isHypertensive ? 2.0 : 0.7
            weightedScores.append((
                score: score,
                weight: weight,
                indicator: MoodIndicator(name: "HRV", status: status, icon: "waveform.path")
            ))
        }

        // ── Nutrition ──
        let todayMeals = store.nutritionLogs.filter { cal.isDateInToday($0.date) }
        if !todayMeals.isEmpty {
            let totalCal = Double(todayMeals.map { $0.calories }.reduce(0, +))
            let targetCal = profile.dailyCalorieGoal > 0 ? Double(profile.dailyCalorieGoal) : 2000.0
            let ratio = totalCal / targetCal
            let score: Double = ratio < 0.3 ? 40 : (ratio > 1.3 ? 50 : 85)
            let status = indicatorStatus(score: score)
            weightedScores.append((
                score: score,
                weight: 0.8,
                indicator: MoodIndicator(name: "Nutrition", status: status, icon: "leaf.fill")
            ))
        }

        // ── Compute Overall ──

        guard !weightedScores.isEmpty else {
            return .unknown
        }

        let totalWeight = weightedScores.map(\.weight).reduce(0, +)
        let weightedSum = weightedScores.map { $0.score * $0.weight }.reduce(0, +)
        let overallScore = Int(weightedSum / totalWeight)

        let level = moodLevel(for: overallScore)
        let summary = generateSummary(level: level, indicators: weightedScores.map(\.indicator), store: store)
        let indicators = weightedScores.map(\.indicator)

        return HealthMood(
            score: overallScore,
            level: level,
            summary: summary,
            indicators: indicators
        )
    }

    // MARK: - Individual Scorers

    /// Glucose score: in-range = high, spikes/lows = low
    private static func glucoseScore(mgdl: Double, isDiabetic: Bool) -> Double {
        // Ranges: diabetic 70-180 ideal, non-diabetic 70-140
        let upper: Double = isDiabetic ? 180 : 140
        let lower: Double = 70

        if mgdl >= lower && mgdl <= upper { return 90 }
        if mgdl < lower {
            let deficit = lower - mgdl
            return max(10, 90 - deficit * 2)
        }
        // High
        let excess = mgdl - upper
        return max(10, 90 - excess * 0.8)
    }

    /// BP score: optimal 120/80 centre, penalise deviations
    private static func bpScore(systolic: Int, diastolic: Int) -> Double {
        // Optimal: 90-120 / 60-80
        var score: Double = 90

        if systolic > 140 { score -= Double(systolic - 140) * 1.5 }
        else if systolic > 130 { score -= Double(systolic - 130) * 1.0 }
        else if systolic < 90 { score -= Double(90 - systolic) * 1.5 }

        if diastolic > 90 { score -= Double(diastolic - 90) * 1.5 }
        else if diastolic > 85 { score -= Double(diastolic - 85) * 1.0 }
        else if diastolic < 60 { score -= Double(60 - diastolic) * 1.5 }

        return max(10, min(100, score))
    }

    /// Sleep score: 7-9h optimal
    private static func sleepScore(hours: Double) -> Double {
        if hours >= 7 && hours <= 9 { return 90 }
        if hours >= 6 && hours < 7 { return 70 }
        if hours > 9 && hours <= 10 { return 75 }
        if hours >= 5 && hours < 6 { return 50 }
        if hours > 10 { return 50 }
        return max(20, hours / 7 * 70)
    }

    /// Steps score: percentage of target
    private static func stepsScore(steps: Int, target: Int) -> Double {
        let ratio = Double(steps) / Double(target)
        if ratio >= 1.0 { return 95 }
        if ratio >= 0.75 { return 80 }
        if ratio >= 0.5 { return 60 }
        if ratio >= 0.25 { return 40 }
        return 25
    }

    /// Heart rate: resting 60-100 normal, lower is generally better
    private static func heartRateScore(bpm: Double, age: Int) -> Double {
        // Simplified — resting HR 50-80 is excellent for most ages
        if bpm >= 50 && bpm <= 80 { return 90 }
        if bpm > 80 && bpm <= 100 { return 70 }
        if bpm > 100 { return max(20, 70 - (bpm - 100) * 1.5) }
        if bpm < 50 && bpm >= 40 { return 70 }
        return 40
    }

    /// HRV score: higher is generally better (age-adjusted)
    private static func hrvScore(ms: Double) -> Double {
        if ms >= 50 { return 90 }
        if ms >= 30 { return 70 }
        if ms >= 20 { return 50 }
        return 30
    }

    // MARK: - Helpers

    private static func indicatorStatus(score: Double) -> IndicatorStatus {
        switch score {
        case 80...100: return .good
        case 60..<80:  return .trending
        case 40..<60:  return .warning
        default:       return .concern
        }
    }

    private static func moodLevel(for score: Int) -> HealthMoodLevel {
        switch score {
        case 80...100: return .thriving
        case 60..<80:  return .good
        case 40..<60:  return .okay
        case 20..<40:  return .needsAttention
        default:       return .unknown
        }
    }

    private static func generateSummary(level: HealthMoodLevel, indicators: [MoodIndicator], store: HealthStore) -> String {
        let goodNames = indicators.filter { $0.status == .good || $0.status == .trending }.map(\.name)

        switch level {
        case .thriving:
            if goodNames.count >= 3 {
                let top3 = goodNames.prefix(3).joined(separator: ", ")
                return "\(top3) all looking brilliant today"
            }
            return "Your body is doing brilliantly today"

        case .good:
            if let first = goodNames.first {
                return "\(first) is on track — steady day so far"
            }
            return "Steady day — things are looking good"

        case .okay:
            let warningNames = indicators.filter { $0.status == .warning }.map(\.name)
            if let first = warningNames.first {
                return "\(first) needs a bit of attention today"
            }
            return "A few things need a bit of attention"

        case .needsAttention:
            let concernNames = indicators.filter { $0.status == .concern }.map(\.name)
            if let first = concernNames.first {
                return "Let's focus on getting \(first) back on track"
            }
            return "Let's focus on getting back on track"

        case .unknown:
            return "I'm getting to know you — log some data and I'll tell you how you're doing"
        }
    }
}
