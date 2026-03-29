//
//  BPEscalationEngine.swift
//  body sense ai
//
//  Tiered BP response system based on NICE CG127/NG136 thresholds.
//  Evaluates each BP reading and returns an appropriate escalation response.
//

import Foundation

// MARK: - BP Escalation Engine

enum BPEscalationEngine {

    // MARK: - Public API

    /// Evaluate a BP reading against NICE thresholds and recent history.
    static func evaluate(
        systolic: Int,
        diastolic: Int,
        recentReadings: [BPReading]
    ) -> BPEscalationResponse {

        let tier = classifyTier(systolic: systolic, diastolic: diastolic)

        switch tier {
        case .green:
            return BPEscalationResponse(
                tier: .green,
                message: "Your blood pressure is in a healthy range.",
                actions: [
                    "Keep up the good work with your current lifestyle",
                    "Continue monitoring regularly"
                ],
                shouldNotify: false,
                shouldSuggestGP: false
            )

        case .amber:
            let consecutiveElevated = countConsecutiveElevated(recentReadings)
            let shouldSuggestGP = consecutiveElevated >= 3

            return BPEscalationResponse(
                tier: .amber,
                message: "Your blood pressure is slightly elevated (\(systolic)/\(diastolic) mmHg).",
                actions: [
                    "Rest for 5 minutes and remeasure to confirm",
                    "Reduce salt intake today — aim for <1500mg sodium",
                    "Try a 15-minute brisk walk",
                    "Practice 4-7-8 breathing: inhale 4s, hold 7s, exhale 8s",
                    consecutiveElevated >= 2
                        ? "This is \(consecutiveElevated + 1) elevated readings in a row — monitor closely"
                        : "Continue monitoring over the next few days"
                ],
                shouldNotify: true,
                shouldSuggestGP: shouldSuggestGP
            )

        case .red:
            return BPEscalationResponse(
                tier: .red,
                message: "Your blood pressure is high (\(systolic)/\(diastolic) mmHg). This needs attention.",
                actions: [
                    "Sit quietly for 5 minutes and remeasure",
                    "If it remains high, consider contacting your GP today",
                    "Avoid caffeine and salt for the rest of the day",
                    "Check if you've missed any blood pressure medication",
                    "Try deep breathing exercises to help reduce it"
                ],
                shouldNotify: true,
                shouldSuggestGP: true
            )

        case .critical:
            return BPEscalationResponse(
                tier: .critical,
                message: "Your blood pressure is critically high (\(systolic)/\(diastolic) mmHg). Seek medical attention.",
                actions: [
                    "If you have chest pain, severe headache, or vision changes — call 999 NOW",
                    "Otherwise, contact NHS 111 or your GP urgently today",
                    "Do not drive yourself to hospital",
                    "Sit down, stay calm, and wait for help",
                    "Take any prescribed emergency medication if advised by your doctor"
                ],
                shouldNotify: true,
                shouldSuggestGP: true
            )
        }
    }

    /// Quick classification without full response (for UI badges).
    static func classifyTier(systolic: Int, diastolic: Int) -> BPEscalationTier {
        // NICE CG127 / NG136 thresholds
        if systolic >= 180 || diastolic >= 110 {
            return .critical
        } else if systolic >= 160 || diastolic >= 100 {
            return .red
        } else if systolic >= 140 || diastolic >= 90 {
            return .amber
        } else {
            return .green
        }
    }

    /// Check if recent readings show a concerning trend.
    static func trendAnalysis(readings: [BPReading], days: Int = 7) -> String? {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -days, to: Date())!
        let recent = readings.filter { $0.date >= cutoff }

        guard recent.count >= 3 else { return nil }

        let avgSystolic = recent.map(\.systolic).reduce(0, +) / recent.count
        let avgDiastolic = recent.map(\.diastolic).reduce(0, +) / recent.count

        // Check for consistently elevated
        let elevatedCount = recent.filter { $0.systolic >= 140 || $0.diastolic >= 90 }.count
        let elevatedPercent = Double(elevatedCount) / Double(recent.count)

        if elevatedPercent > 0.7 {
            return "Your BP has been elevated in \(elevatedCount) of \(recent.count) readings this week (avg \(avgSystolic)/\(avgDiastolic)). Consider speaking with your GP about your blood pressure management."
        }

        // Check for improving trend
        if recent.count >= 4 {
            let firstHalf = Array(recent.prefix(recent.count / 2))
            let secondHalf = Array(recent.suffix(recent.count / 2))
            let firstAvg = firstHalf.map(\.systolic).reduce(0, +) / firstHalf.count
            let secondAvg = secondHalf.map(\.systolic).reduce(0, +) / secondHalf.count

            if secondAvg < firstAvg - 5 {
                return "Your BP trend is improving — average systolic dropped from \(firstAvg) to \(secondAvg) this week."
            }
        }

        return nil
    }

    // MARK: - Private Helpers

    private static func countConsecutiveElevated(_ readings: [BPReading]) -> Int {
        let sorted = readings.sorted { $0.date > $1.date }
        var count = 0
        for reading in sorted {
            if reading.systolic >= 140 || reading.diastolic >= 90 {
                count += 1
            } else {
                break
            }
        }
        return count
    }
}
