//
//  HealthDataExporter.swift
//  body sense ai
//
//  Export health data as CSV or professional PDF medical report.
//  100% Apple-native — uses Foundation + UIKit PDF rendering only.
//

import Foundation
import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Export Format

enum ExportFormat: String, CaseIterable {
    case csv = "CSV"
    case pdf = "PDF Medical Report"

    var icon: String {
        switch self {
        case .csv: return "tablecells"
        case .pdf: return "doc.richtext"
        }
    }

    var description: String {
        switch self {
        case .csv: return "Raw data for spreadsheets"
        case .pdf: return "Professional report for doctors"
        }
    }
}

/// Exports HealthStore data as CSV files or professional PDF medical reports.
enum HealthDataExporter {

    // MARK: - Export All Data as CSV

    /// Generate a CSV string containing all health data categories.
    static func exportAllAsCSV(store: HealthStore) -> String {
        var csv = ""

        // ── User Profile ──
        csv += "=== USER PROFILE ===\n"
        csv += "Name,Age,Gender,Diabetes Type,Has Hypertension,Weight (kg),Height (cm)\n"
        let p = store.userProfile
        csv += "\"\(p.name)\",\(p.age),\"\(p.gender)\",\"\(p.diabetesType)\",\(p.hasHypertension),\(p.weight),\(p.height)\n\n"

        // ── Glucose Readings ──
        if !store.glucoseReadings.isEmpty {
            csv += "=== GLUCOSE READINGS ===\n"
            csv += "Date,Value (mg/dL),Context,Notes\n"
            for r in store.glucoseReadings.sorted(by: { $0.date > $1.date }) {
                csv += "\"\(formatDate(r.date))\",\(r.value),\"\(r.context.rawValue)\",\"\(escape(r.notes))\"\n"
            }
            csv += "\n"
        }

        // ── Blood Pressure ──
        if !store.bpReadings.isEmpty {
            csv += "=== BLOOD PRESSURE ===\n"
            csv += "Date,Systolic,Diastolic,Pulse,Category\n"
            for r in store.bpReadings.sorted(by: { $0.date > $1.date }) {
                csv += "\"\(formatDate(r.date))\",\(r.systolic),\(r.diastolic),\(r.pulse),\"\(r.category.rawValue)\"\n"
            }
            csv += "\n"
        }

        // ── Heart Rate ──
        if !store.heartRateReadings.isEmpty {
            csv += "=== HEART RATE ===\n"
            csv += "Date,Value (bpm),Context\n"
            for r in store.heartRateReadings.sorted(by: { $0.date > $1.date }) {
                csv += "\"\(formatDate(r.date))\",\(r.value),\"\(r.context.rawValue)\"\n"
            }
            csv += "\n"
        }

        // ── HRV ──
        if !store.hrvReadings.isEmpty {
            csv += "=== HEART RATE VARIABILITY ===\n"
            csv += "Date,Value (ms)\n"
            for r in store.hrvReadings.sorted(by: { $0.date > $1.date }) {
                csv += "\"\(formatDate(r.date))\",\(r.value)\n"
            }
            csv += "\n"
        }

        // ── Sleep ──
        if !store.sleepEntries.isEmpty {
            csv += "=== SLEEP ===\n"
            csv += "Date,Duration (hrs),Quality,Deep (hrs),REM (hrs),Light (hrs),Awakenings,Notes\n"
            for r in store.sleepEntries.sorted(by: { $0.date > $1.date }) {
                csv += "\"\(formatDate(r.date))\",\(r.duration),\"\(r.quality.rawValue)\",\(r.deepSleep),\(r.remSleep),\(r.lightSleep),\(r.awakenings),\"\(escape(r.notes))\"\n"
            }
            csv += "\n"
        }

        // ── Stress ──
        if !store.stressReadings.isEmpty {
            csv += "=== STRESS ===\n"
            csv += "Date,Level (1-10),Trigger\n"
            for r in store.stressReadings.sorted(by: { $0.date > $1.date }) {
                csv += "\"\(formatDate(r.date))\",\(r.level),\"\(r.trigger.rawValue)\"\n"
            }
            csv += "\n"
        }

        // ── Body Temperature ──
        if !store.bodyTempReadings.isEmpty {
            csv += "=== BODY TEMPERATURE ===\n"
            csv += "Date,Value (°C)\n"
            for r in store.bodyTempReadings.sorted(by: { $0.date > $1.date }) {
                csv += "\"\(formatDate(r.date))\",\(r.value)\n"
            }
            csv += "\n"
        }

        // ── Steps ──
        if !store.stepEntries.isEmpty {
            csv += "=== STEPS ===\n"
            csv += "Date,Steps,Distance (km),Calories,Active Minutes,Source\n"
            for r in store.stepEntries.sorted(by: { $0.date > $1.date }) {
                csv += "\"\(formatDate(r.date))\",\(r.steps),\(String(format: "%.2f", r.distance)),\(r.calories),\(r.activeMinutes),\"\(r.source)\"\n"
            }
            csv += "\n"
        }

        // ── Water ──
        if !store.waterEntries.isEmpty {
            csv += "=== WATER INTAKE ===\n"
            csv += "Date,Amount (ml)\n"
            for r in store.waterEntries.sorted(by: { $0.date > $1.date }) {
                csv += "\"\(formatDate(r.date))\",\(r.amount)\n"
            }
            csv += "\n"
        }

        // ── Nutrition ──
        if !store.nutritionLogs.isEmpty {
            csv += "=== NUTRITION ===\n"
            csv += "Date,Meal,Food,Calories,Carbs (g),Protein (g),Fat (g),Fiber (g),Sugar (g),Salt (g)\n"
            for r in store.nutritionLogs.sorted(by: { $0.date > $1.date }) {
                csv += "\"\(formatDate(r.date))\",\"\(r.mealType.rawValue)\",\"\(escape(r.foodName))\",\(r.calories),\(r.carbs),\(r.protein),\(r.fat),\(r.fiber),\(r.sugar),\(r.salt)\n"
            }
            csv += "\n"
        }

        // ── Symptoms ──
        if !store.symptomLogs.isEmpty {
            csv += "=== SYMPTOMS ===\n"
            csv += "Date,Symptoms,Severity,Notes\n"
            for r in store.symptomLogs.sorted(by: { $0.date > $1.date }) {
                csv += "\"\(formatDate(r.date))\",\"\(r.symptoms.joined(separator: "; "))\",\"\(r.severity.rawValue)\",\"\(escape(r.notes))\"\n"
            }
            csv += "\n"
        }

        // ── Medications ──
        if !store.medications.isEmpty {
            csv += "=== MEDICATIONS ===\n"
            csv += "Name,Dosage,Unit,Frequency,Times,Active\n"
            for m in store.medications {
                csv += "\"\(m.name)\",\"\(m.dosage)\",\"\(m.unit)\",\"\(m.frequency.rawValue)\",\"\(m.timeOfDay.map(\.rawValue).joined(separator: "; "))\",\(m.isActive)\n"
            }
            csv += "\n"
        }

        // ── Menstrual Cycles ──
        if !store.cycles.isEmpty {
            csv += "=== MENSTRUAL CYCLE ===\n"
            csv += "Start Date,End Date,Flow,Symptoms,Notes\n"
            for c in store.cycles.sorted(by: { $0.startDate > $1.startDate }) {
                csv += "\"\(formatDate(c.startDate))\",\"\(c.endDate.map { formatDate($0) } ?? "")\",\"\(c.flow.rawValue)\",\"\(c.symptoms.joined(separator: "; "))\",\"\(escape(c.notes))\"\n"
            }
            csv += "\n"
        }

        // ── Prescriptions ──
        if !store.prescriptions.isEmpty {
            csv += "=== PRESCRIPTIONS ===\n"
            csv += "Date,Doctor,Diagnosis,Medications,Valid Until,Notes\n"
            for rx in store.prescriptions.sorted(by: { $0.date > $1.date }) {
                csv += "\"\(formatDate(rx.date))\",\"\(escape(rx.doctorName))\",\"\(escape(rx.diagnosis))\",\"\(rx.medications.joined(separator: "; "))\",\"\(formatDate(rx.validUntil))\",\"\(escape(rx.notes))\"\n"
            }
            csv += "\n"
        }

        // ── Health Goals ──
        if !store.healthGoals.isEmpty {
            csv += "=== HEALTH GOALS ===\n"
            csv += "Title,Type,Target,Current,Unit,Deadline,Completed\n"
            for g in store.healthGoals {
                csv += "\"\(escape(g.title))\",\"\(g.type.rawValue)\",\(g.targetValue),\(g.currentValue),\"\(g.unit)\",\"\(formatDate(g.deadline))\",\(g.isCompleted)\n"
            }
            csv += "\n"
        }

        return csv
    }

    // MARK: - Export as CSV File

    /// Create a temporary CSV file and return its URL for sharing.
    static func createCSVFile(store: HealthStore) -> URL? {
        let csv = exportAllAsCSV(store: store)
        let dateStr = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let fileName = "BodySenseAI_HealthData_\(dateStr).csv"

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("HealthDataExporter: Failed to write CSV: \(error)")
            return nil
        }
    }

    // MARK: - Professional PDF Medical Report

    /// Generate a professional A4 medical report PDF.
    static func exportAsPDF(store: HealthStore) -> Data? {
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4
        let margin: CGFloat = 40
        let contentWidth = pageRect.width - margin * 2
        let reportID = UUID().uuidString.prefix(8).uppercased()
        let cal = Calendar.current
        let cutoff = cal.date(byAdding: .day, value: -30, to: Date())!
        let p = store.userProfile

        // Fonts
        let headerFont  = UIFont.systemFont(ofSize: 16, weight: .bold)
        let bodyFont    = UIFont.systemFont(ofSize: 10, weight: .regular)
        let smallFont   = UIFont.systemFont(ofSize: 8, weight: .regular)
        let boldBody    = UIFont.systemFont(ofSize: 10, weight: .bold)

        // Colors
        let brandPurple = UIColor(red: 0.424, green: 0.388, blue: 1.0, alpha: 1.0) // #6C63FF
        let darkText    = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0)
        let grayText    = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        let warningRed  = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        let lightBg     = UIColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1.0)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { ctx in
            var yPos: CGFloat = 0

            // Helper: start new page if needed
            func ensureSpace(_ needed: CGFloat) {
                if yPos + needed > pageRect.height - 60 {
                    drawFooter(ctx: ctx, pageRect: pageRect, smallFont: smallFont, grayText: grayText, reportID: String(reportID))
                    ctx.beginPage()
                    yPos = margin
                }
            }

            // Helper: draw text
            @discardableResult
            func drawText(_ text: String, x: CGFloat, font: UIFont, color: UIColor, maxWidth: CGFloat? = nil) -> CGFloat {
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                let w = maxWidth ?? contentWidth
                let size = (text as NSString).boundingRect(with: CGSize(width: w, height: .greatestFiniteMagnitude),
                                                           options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
                (text as NSString).draw(in: CGRect(x: x, y: yPos, width: w, height: size.height), withAttributes: attrs)
                return size.height
            }

            // Helper: draw a section header with colored bar
            func drawSectionHeader(_ title: String) {
                ensureSpace(35)
                let barRect = CGRect(x: margin, y: yPos, width: 4, height: 18)
                brandPurple.setFill()
                UIBezierPath(roundedRect: barRect, cornerRadius: 2).fill()
                let attrs: [NSAttributedString.Key: Any] = [.font: headerFont, .foregroundColor: darkText]
                (title as NSString).draw(at: CGPoint(x: margin + 10, y: yPos), withAttributes: attrs)
                yPos += 24
                // Thin line
                grayText.withAlphaComponent(0.3).setStroke()
                let line = UIBezierPath()
                line.move(to: CGPoint(x: margin, y: yPos))
                line.addLine(to: CGPoint(x: pageRect.width - margin, y: yPos))
                line.lineWidth = 0.5
                line.stroke()
                yPos += 8
            }

            // Helper: draw key-value row
            func drawKVRow(_ key: String, _ value: String) {
                ensureSpace(16)
                drawText(key, x: margin + 8, font: boldBody, color: grayText, maxWidth: 160)
                let savedY = yPos
                let h = drawText(value, x: margin + 170, font: bodyFont, color: darkText, maxWidth: contentWidth - 170)
                yPos = savedY + max(h, 14)
            }

            // Helper: draw bullet point
            func drawBullet(_ text: String, indent: CGFloat = 8) {
                ensureSpace(16)
                let h = drawText("  \u{2022}  \(text)", x: margin + indent, font: bodyFont, color: darkText)
                yPos += max(h, 14) + 1
            }

            // ═══════════════════════════════════════════
            // PAGE 1: Header, Patient Info, Conditions
            // ═══════════════════════════════════════════
            ctx.beginPage()
            yPos = margin

            // ── Branded Header Bar ──
            let headerRect = CGRect(x: 0, y: 0, width: pageRect.width, height: 80)
            brandPurple.setFill()
            UIRectFill(headerRect)

            let logoAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 24, weight: .bold), .foregroundColor: UIColor.white]
            ("BODYSENSE AI" as NSString).draw(at: CGPoint(x: margin, y: 20), withAttributes: logoAttrs)

            let subtitleAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12, weight: .medium), .foregroundColor: UIColor.white.withAlphaComponent(0.85)]
            ("HEALTH DATA REPORT" as NSString).draw(at: CGPoint(x: margin, y: 50), withAttributes: subtitleAttrs)

            // Report ID on right
            let idAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 9, weight: .medium), .foregroundColor: UIColor.white.withAlphaComponent(0.7)]
            let idText = "Report ID: \(reportID)"
            let idSize = (idText as NSString).size(withAttributes: idAttrs)
            (idText as NSString).draw(at: CGPoint(x: pageRect.width - margin - idSize.width, y: 52), withAttributes: idAttrs)

            let dateAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 9, weight: .medium), .foregroundColor: UIColor.white.withAlphaComponent(0.7)]
            let genDate = "Generated: \(Date().formatted(date: .long, time: .shortened))"
            let genSize = (genDate as NSString).size(withAttributes: dateAttrs)
            (genDate as NSString).draw(at: CGPoint(x: pageRect.width - margin - genSize.width, y: 28), withAttributes: dateAttrs)

            yPos = 100

            // ── Patient Information Box ──
            let infoBoxRect = CGRect(x: margin, y: yPos, width: contentWidth, height: 90)
            lightBg.setFill()
            UIBezierPath(roundedRect: infoBoxRect, cornerRadius: 8).fill()

            yPos += 10

            // Row 1
            let nameAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14, weight: .bold), .foregroundColor: darkText]
            (p.name as NSString).draw(at: CGPoint(x: margin + 12, y: yPos), withAttributes: nameAttrs)

            let bmi = p.height > 0 ? p.weight / pow(p.height / 100, 2) : 0
            let bmiStr = String(format: "BMI: %.1f", bmi)
            let ageStr = "Age: \(p.age)  |  Gender: \(p.gender)  |  \(bmiStr)"
            let ageAttrs: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: grayText]
            (ageStr as NSString).draw(at: CGPoint(x: margin + 12, y: yPos + 20), withAttributes: ageAttrs)

            let weightStr = "Weight: \(String(format: "%.1f", p.weight)) kg  |  Height: \(String(format: "%.0f", p.height)) cm"
            (weightStr as NSString).draw(at: CGPoint(x: margin + 12, y: yPos + 35), withAttributes: ageAttrs)

            let condStr = "Conditions: \(p.diabetesType)\(p.hasHypertension ? ", Hypertension" : "")"
            let condAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: brandPurple]
            (condStr as NSString).draw(at: CGPoint(x: margin + 12, y: yPos + 55), withAttributes: condAttrs)

            yPos += 100

            // ── Active Medications ──
            let activeMeds = store.medications.filter { $0.isActive }
            if !activeMeds.isEmpty {
                drawSectionHeader("ACTIVE MEDICATIONS")
                for med in activeMeds {
                    let recentLogs = med.logs.filter { $0.date >= cutoff }
                    let taken = recentLogs.filter { $0.taken }.count
                    let total = recentLogs.count
                    let adherence = total > 0 ? Int(Double(taken) / Double(total) * 100) : 0
                    let adherenceColor = adherence >= 90 ? "+" : (adherence >= 70 ? "~" : "!")
                    drawBullet("\(med.name) \(med.dosage)\(med.unit) — \(med.frequency.rawValue) — Adherence: \(adherence)% \(adherenceColor)")
                }
                yPos += 8
            }

            // ── Prescriptions ──
            if !store.prescriptions.isEmpty {
                drawSectionHeader("PRESCRIPTIONS")
                for rx in store.prescriptions.sorted(by: { $0.date > $1.date }).prefix(5) {
                    let expired = rx.validUntil < Date()
                    let status = expired ? " [EXPIRED]" : ""
                    drawBullet("\(rx.diagnosis)\(status) — Dr. \(rx.doctorName)")
                    ensureSpace(14)
                    drawText("      Medications: \(rx.medications.joined(separator: ", "))", x: margin + 16, font: smallFont, color: grayText)
                    yPos += 12
                }
                yPos += 8
            }

            // ── Glucose Summary ──
            let glu = store.glucoseReadings.filter { $0.date >= cutoff }
            if !glu.isEmpty {
                drawSectionHeader("GLUCOSE SUMMARY (30 Days)")
                let avg = glu.map { $0.value }.reduce(0, +) / Double(glu.count)
                let minG = glu.map { $0.value }.min() ?? 0
                let maxG = glu.map { $0.value }.max() ?? 0
                let inTarget = glu.filter { $0.value >= 70 && $0.value <= 180 }
                let targetPct = Int(Double(inTarget.count) / Double(glu.count) * 100)
                drawKVRow("Readings:", "\(glu.count)")
                drawKVRow("Average:", "\(Int(avg)) mg/dL")
                drawKVRow("Range:", "\(Int(minG)) – \(Int(maxG)) mg/dL")
                drawKVRow("Time in Target:", "\(targetPct)% (70-180 mg/dL)")

                // Trend: compare first vs second half
                let midDate = cal.date(byAdding: .day, value: -15, to: Date())!
                let firstHalf = glu.filter { $0.date < midDate }
                let secondHalf = glu.filter { $0.date >= midDate }
                if !firstHalf.isEmpty && !secondHalf.isEmpty {
                    let firstAvg = firstHalf.map { $0.value }.reduce(0, +) / Double(firstHalf.count)
                    let secondAvg = secondHalf.map { $0.value }.reduce(0, +) / Double(secondHalf.count)
                    let trend = secondAvg < firstAvg ? "Improving" : (secondAvg > firstAvg + 10 ? "Worsening" : "Stable")
                    drawKVRow("Trend:", "\(trend) (\(Int(firstAvg)) → \(Int(secondAvg)) mg/dL)")
                }
                yPos += 8
            }

            // ── Blood Pressure Summary ──
            let bp = store.bpReadings.filter { $0.date >= cutoff }
            if !bp.isEmpty {
                drawSectionHeader("BLOOD PRESSURE SUMMARY (30 Days)")
                let avgSys = bp.map { $0.systolic }.reduce(0, +) / bp.count
                let avgDia = bp.map { $0.diastolic }.reduce(0, +) / bp.count
                drawKVRow("Readings:", "\(bp.count)")
                drawKVRow("Average:", "\(avgSys)/\(avgDia) mmHg")

                let categories = Dictionary(grouping: bp, by: { $0.category.rawValue }).mapValues { $0.count }
                let catStr = categories.sorted(by: { $0.value > $1.value }).map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                drawKVRow("Categories:", catStr)
                yPos += 8
            }

            // ── Heart Rate + HRV ──
            let hr = store.heartRateReadings.filter { $0.date >= cutoff }
            let hrv = store.hrvReadings.filter { $0.date >= cutoff }
            if !hr.isEmpty || !hrv.isEmpty {
                drawSectionHeader("HEART RATE & HRV (30 Days)")
                if !hr.isEmpty {
                    let avgHR = hr.map { $0.value }.reduce(0, +) / hr.count
                    let minHR = hr.map { $0.value }.min() ?? 0
                    let maxHR = hr.map { $0.value }.max() ?? 0
                    drawKVRow("Heart Rate:", "Avg \(avgHR) bpm (range: \(minHR)–\(maxHR))")
                }
                if !hrv.isEmpty {
                    let avgHRV = hrv.map { $0.value }.reduce(0, +) / Double(hrv.count)
                    drawKVRow("HRV:", "Avg \(Int(avgHRV)) ms (\(hrv.count) readings)")
                }
                yPos += 8
            }

            // ── Sleep Summary ──
            let sl = store.sleepEntries.filter { $0.date >= cutoff }
            if !sl.isEmpty {
                drawSectionHeader("SLEEP SUMMARY (30 Days)")
                let avgDur = sl.map { $0.duration }.reduce(0, +) / Double(sl.count)
                let avgDeep = sl.map { $0.deepSleep }.reduce(0, +) / Double(sl.count)
                let avgREM = sl.map { $0.remSleep }.reduce(0, +) / Double(sl.count)
                let avgAwake = sl.map { Double($0.awakenings) }.reduce(0, +) / Double(sl.count)
                let qualities = Dictionary(grouping: sl, by: { $0.quality.rawValue }).mapValues { $0.count }
                drawKVRow("Average Duration:", "\(String(format: "%.1f", avgDur)) hrs")
                drawKVRow("Deep Sleep:", "\(String(format: "%.1f", avgDeep)) hrs avg")
                drawKVRow("REM Sleep:", "\(String(format: "%.1f", avgREM)) hrs avg")
                drawKVRow("Awakenings:", "\(String(format: "%.1f", avgAwake)) per night avg")
                let qualStr = qualities.sorted(by: { $0.value > $1.value }).map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                drawKVRow("Quality:", qualStr)
                yPos += 8
            }

            // ── Stress Summary ──
            let st = store.stressReadings.filter { $0.date >= cutoff }
            if !st.isEmpty {
                drawSectionHeader("STRESS SUMMARY (30 Days)")
                let avgStress = st.map { $0.level }.reduce(0, +) / st.count
                let triggers = Dictionary(grouping: st, by: { $0.trigger.rawValue }).mapValues { $0.count }
                    .sorted(by: { $0.value > $1.value })
                drawKVRow("Average Level:", "\(avgStress)/10 (\(st.count) readings)")
                let trigStr = triggers.prefix(5).map { "\($0.key): \($0.value)x" }.joined(separator: ", ")
                drawKVRow("Top Triggers:", trigStr)
                yPos += 8
            }

            // ── Body Temperature ──
            let temps = store.bodyTempReadings.filter { $0.date >= cutoff }
            if !temps.isEmpty {
                drawSectionHeader("BODY TEMPERATURE (30 Days)")
                let avg = temps.map { $0.value }.reduce(0, +) / Double(temps.count)
                let feverCount = temps.filter { $0.value > 37.5 }.count
                drawKVRow("Average:", "\(String(format: "%.1f", avg))°C (\(temps.count) readings)")
                if feverCount > 0 {
                    drawKVRow("Fever Episodes:", "\(feverCount) readings above 37.5°C")
                }
                yPos += 8
            }

            // ── Steps & Activity ──
            let steps = store.stepEntries.filter { $0.date >= cutoff }
            if !steps.isEmpty {
                drawSectionHeader("PHYSICAL ACTIVITY (30 Days)")
                let avgSteps = steps.map { $0.steps }.reduce(0, +) / steps.count
                let totalDist = steps.map { $0.distance }.reduce(0, +)
                let totalCal = steps.map { $0.calories }.reduce(0, +)
                let avgActive = steps.map { $0.activeMinutes }.reduce(0, +) / steps.count
                drawKVRow("Daily Steps Avg:", "\(avgSteps) (target: \(p.targetSteps))")
                drawKVRow("Total Distance:", "\(String(format: "%.1f", totalDist)) km")
                drawKVRow("Total Calories:", "\(totalCal) kcal")
                drawKVRow("Active Minutes:", "\(avgActive) min/day avg")
                yPos += 8
            }

            // ── Water Intake ──
            let water = store.waterEntries.filter { $0.date >= cutoff }
            if !water.isEmpty {
                drawSectionHeader("HYDRATION (30 Days)")
                let waterDays = Set(water.map { cal.startOfDay(for: $0.date) }).count
                let dailyAvg = waterDays > 0 ? water.map { $0.amount }.reduce(0, +) / Double(waterDays) : 0
                let target = p.targetWater * 1000
                let pct = target > 0 ? Int(dailyAvg / target * 100) : 0
                drawKVRow("Daily Average:", "\(Int(dailyAvg)) ml (\(pct)% of \(Int(target)) ml target)")
                yPos += 8
            }

            // ── Nutrition Summary ──
            let nutr = store.nutritionLogs.filter { $0.date >= cutoff }
            if !nutr.isEmpty {
                drawSectionHeader("NUTRITION SUMMARY (30 Days)")
                let avgCal = nutr.map { $0.calories }.reduce(0, +) / nutr.count
                let avgCarbs = nutr.map { Double($0.carbs) }.reduce(0, +) / Double(nutr.count)
                let avgProtein = nutr.map { Double($0.protein) }.reduce(0, +) / Double(nutr.count)
                let avgFat = nutr.map { Double($0.fat) }.reduce(0, +) / Double(nutr.count)
                let avgSugar = nutr.map { Double($0.sugar) }.reduce(0, +) / Double(nutr.count)
                let avgSalt = nutr.map { $0.salt }.reduce(0, +) / Double(nutr.count)
                drawKVRow("Avg Calories:", "\(avgCal) kcal/meal (\(nutr.count) meals logged)")
                drawKVRow("Macros Avg:", "\(Int(avgCarbs))g carbs, \(Int(avgProtein))g protein, \(Int(avgFat))g fat")
                drawKVRow("Sugar:", "\(Int(avgSugar))g avg (NHS daily limit: 30g)")
                drawKVRow("Salt:", "\(String(format: "%.1f", avgSalt))g avg (NHS daily limit: 6g)")
                yPos += 8
            }

            // ── Symptom Analysis ──
            let sym = store.symptomLogs.filter { $0.date >= cutoff }
            if !sym.isEmpty {
                drawSectionHeader("SYMPTOM ANALYSIS (30 Days)")
                let allSyms = sym.flatMap { $0.symptoms }
                let freq = Dictionary(grouping: allSyms, by: { $0 }).mapValues { $0.count }
                    .sorted { $0.value > $1.value }
                let sevCounts = Dictionary(grouping: sym, by: { $0.severity.rawValue }).mapValues { $0.count }
                drawKVRow("Total Logs:", "\(sym.count)")
                let sevStr = sevCounts.sorted(by: { $0.value > $1.value }).map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                drawKVRow("Severity:", sevStr)
                ensureSpace(16)
                drawText("Most Frequent Symptoms:", x: margin + 8, font: boldBody, color: grayText)
                yPos += 14
                for (name, count) in freq.prefix(8) {
                    drawBullet("\(name): \(count)x", indent: 16)
                }
                yPos += 8
            }

            // ── Cycle Tracking ──
            let cyc = store.cycles.filter { $0.startDate >= cutoff }
            if !cyc.isEmpty {
                drawSectionHeader("MENSTRUAL CYCLE TRACKING (30 Days)")
                drawKVRow("Entries:", "\(cyc.count)")
                for c in cyc.sorted(by: { $0.startDate > $1.startDate }).prefix(3) {
                    let endStr = c.endDate.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "Ongoing"
                    drawBullet("\(c.startDate.formatted(date: .abbreviated, time: .omitted)) – \(endStr), Flow: \(c.flow.rawValue)")
                    if !c.symptoms.isEmpty {
                        ensureSpace(14)
                        drawText("        Symptoms: \(c.symptoms.prefix(4).joined(separator: ", "))", x: margin + 16, font: smallFont, color: grayText)
                        yPos += 12
                    }
                }
                yPos += 8
            }

            // ── Health Goals ──
            let activeGoals = store.healthGoals.filter { !$0.isCompleted }
            let completedGoals = store.healthGoals.filter { $0.isCompleted }
            if !store.healthGoals.isEmpty {
                drawSectionHeader("HEALTH GOALS")
                if !activeGoals.isEmpty {
                    ensureSpace(16)
                    drawText("Active Goals:", x: margin + 8, font: boldBody, color: grayText)
                    yPos += 14
                    for g in activeGoals.prefix(5) {
                        let pctVal = Int(g.progress * 100)
                        drawBullet("\(g.title): \(pctVal)% — \(String(format: "%.0f", g.currentValue))/\(String(format: "%.0f", g.targetValue)) \(g.unit)", indent: 16)
                    }
                }
                if !completedGoals.isEmpty {
                    ensureSpace(16)
                    drawKVRow("Completed:", "\(completedGoals.count) goals achieved")
                }
                yPos += 8
            }

            // ═══════════════════════════════════════════
            // DISCLAIMER PAGE
            // ═══════════════════════════════════════════
            ensureSpace(120)

            // Separator
            brandPurple.setFill()
            UIRectFill(CGRect(x: margin, y: yPos, width: contentWidth, height: 2))
            yPos += 16

            // Disclaimer box
            let disclaimerRect = CGRect(x: margin, y: yPos, width: contentWidth, height: 80)
            UIColor(red: 1.0, green: 0.95, blue: 0.95, alpha: 1.0).setFill()
            UIBezierPath(roundedRect: disclaimerRect, cornerRadius: 8).fill()

            let disclaimerTitle: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10, weight: .bold), .foregroundColor: warningRed]
            ("IMPORTANT DISCLAIMER" as NSString).draw(at: CGPoint(x: margin + 12, y: yPos + 8), withAttributes: disclaimerTitle)

            let disclaimerBody: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 8, weight: .regular), .foregroundColor: darkText]
            let dText = "This report was generated by BodySense AI and is based on self-reported and device-synced health data. It is NOT a clinical diagnosis and should not be used as a substitute for professional medical advice. Please share this report with your healthcare provider for proper interpretation and clinical decision-making."
            (dText as NSString).draw(in: CGRect(x: margin + 12, y: yPos + 24, width: contentWidth - 24, height: 50), withAttributes: disclaimerBody)

            yPos += 90

            // Encryption note
            let encAttrs: [NSAttributedString.Key: Any] = [.font: smallFont, .foregroundColor: grayText]
            let encText = "Data encrypted with AES-256-GCM on device  |  Transmitted via HTTPS/TLS  |  GDPR compliant"
            let encSize = (encText as NSString).size(withAttributes: encAttrs)
            (encText as NSString).draw(at: CGPoint(x: (pageRect.width - encSize.width) / 2, y: yPos), withAttributes: encAttrs)

            yPos += 20

            let appAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 8, weight: .medium), .foregroundColor: brandPurple]
            let appText = "BodySense AI — Your Health, Your Data, Your Future"
            let appSize = (appText as NSString).size(withAttributes: appAttrs)
            (appText as NSString).draw(at: CGPoint(x: (pageRect.width - appSize.width) / 2, y: yPos), withAttributes: appAttrs)

            // Footer on last page
            drawFooter(ctx: ctx, pageRect: pageRect, smallFont: smallFont, grayText: grayText, reportID: String(reportID))
        }

        return data
    }

    /// Draw page footer with page number and report ID
    private static func drawFooter(ctx: UIGraphicsPDFRendererContext, pageRect: CGRect, smallFont: UIFont, grayText: UIColor, reportID: String) {
        let footerAttrs: [NSAttributedString.Key: Any] = [.font: smallFont, .foregroundColor: grayText]
        let footerText = "BodySense AI Medical Report  |  Report ID: \(reportID)  |  Confidential"
        let footerSize = (footerText as NSString).size(withAttributes: footerAttrs)
        (footerText as NSString).draw(at: CGPoint(x: (pageRect.width - footerSize.width) / 2, y: pageRect.height - 30), withAttributes: footerAttrs)
    }

    // MARK: - Export as PDF File

    /// Create a temporary PDF file and return its URL for sharing.
    static func createPDFFile(store: HealthStore) -> URL? {
        guard let data = exportAsPDF(store: store) else { return nil }
        let dateStr = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let fileName = "BodySenseAI_MedicalReport_\(dateStr).pdf"

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("HealthDataExporter: Failed to write PDF: \(error)")
            return nil
        }
    }

    // MARK: - Helpers

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }

    private static func escape(_ string: String) -> String {
        string.replacingOccurrences(of: "\"", with: "\"\"")
    }
}

// MARK: - Export Button View

/// A reusable "Export Health Data" button with format picker (CSV or PDF Medical Report).
struct ExportHealthDataButton: View {
    let store: HealthStore
    @State private var showFormatPicker = false
    @State private var showShareSheet = false
    @State private var exportURL: URL?
    @State private var isExporting = false
    @State private var selectedFormat: ExportFormat = .pdf

    var body: some View {
        VStack(spacing: 10) {
            Button {
                showFormatPicker = true
            } label: {
                HStack {
                    if isExporting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Text(isExporting ? "Generating Report..." : "Export Health Data")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.brandTeal)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isExporting)
        }
        .confirmationDialog("Export Format", isPresented: $showFormatPicker, titleVisibility: .visible) {
            Button("PDF Medical Report (for doctors)") {
                exportData(format: .pdf)
            }
            Button("CSV Spreadsheet (raw data)") {
                exportData(format: .csv)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose how to export your health data")
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
    }

    private func exportData(format: ExportFormat) {
        selectedFormat = format
        isExporting = true
        DispatchQueue.global(qos: .userInitiated).async {
            let url: URL?
            switch format {
            case .csv:
                url = HealthDataExporter.createCSVFile(store: store)
            case .pdf:
                url = HealthDataExporter.createPDFFile(store: store)
            }
            DispatchQueue.main.async {
                exportURL = url
                isExporting = false
                if url != nil {
                    showShareSheet = true
                }
            }
        }
    }
}

// MARK: - Share Sheet (UIKit Wrapper)

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
