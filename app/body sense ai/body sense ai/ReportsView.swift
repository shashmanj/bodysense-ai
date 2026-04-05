//
//  ReportsView.swift
//  body sense ai
//

import SwiftUI
import Charts

struct ReportsView: View {
    @Environment(HealthStore.self) var store
    @State private var segment  = 0   // 0=Glucose 1=BP
    @State private var range    = 7   // days

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Range picker
                    Picker("Range", selection: $range) {
                        Text("7 Days").tag(7)
                        Text("14 Days").tag(14)
                        Text("30 Days").tag(30)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Tab
                    Picker("", selection: $segment) {
                        Text("Glucose").tag(0)
                        Text("Blood Pressure").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if segment == 0 {
                        if filteredGlucose.isEmpty {
                            emptyReportState(
                                icon: "drop.fill",
                                title: "No Glucose Data Yet",
                                message: "Log your glucose readings in Track to see trends, averages, and time-in-range reports here."
                            )
                        } else {
                            glucoseSummaryCard
                            glucoseChartCard
                            glucoseDistributionCard
                        }
                    } else {
                        if filteredBP.isEmpty {
                            emptyReportState(
                                icon: "heart.fill",
                                title: "No Blood Pressure Data Yet",
                                message: "Log your blood pressure readings in Track to see trends and averages here."
                            )
                        } else {
                            bpSummaryCard
                            bpChartCard
                        }
                    }

                    medicationAdherenceCard
                }
                .padding(.bottom, 24)
            }
            .background(Color.brandBg)
            .navigationTitle("Reports")
        }
    }

    // ── Filtered Data ──
    var filteredGlucose: [GlucoseReading] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -range, to: Date()) ?? Date()
        return store.glucoseReadings.filter { $0.date >= cutoff }.sorted { $0.date < $1.date }
    }

    var filteredBP: [BPReading] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -range, to: Date()) ?? Date()
        return store.bpReadings.filter { $0.date >= cutoff }.sorted { $0.date < $1.date }
    }

    // ── Glucose Summary ──
    var glucoseSummaryCard: some View {
        let vals = filteredGlucose.map { $0.value }
        let avg  = vals.isEmpty ? 0 : vals.reduce(0,+) / Double(vals.count)
        let high = vals.max() ?? 0
        let low  = vals.min() ?? 0
        let inRange = vals.filter {
            $0 >= store.userProfile.targetGlucoseMin && $0 <= store.userProfile.targetGlucoseMax
        }.count
        let pct = vals.isEmpty ? 0 : Int(Double(inRange) / Double(vals.count) * 100)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Glucose Summary · Last \(range) days")
                .font(.headline).padding(.bottom, 2)
            HStack(spacing: 0) {
                summaryCol("Avg", HealthStore.glucoseMmol(avg), "mmol/L", .brandPurple)
                Divider().frame(height: 50)
                summaryCol("High", HealthStore.glucoseMmol(high), "mmol/L", .brandCoral)
                Divider().frame(height: 50)
                summaryCol("Low",  HealthStore.glucoseMmol(low),  "mmol/L", .brandTeal)
                Divider().frame(height: 50)
                summaryCol("In Range", "\(pct)%", "\(inRange)/\(vals.count)", .brandGreen)
            }
            // HbA1c estimate
            if avg > 0 {
                let hba1c = (avg + 46.7) / 28.7
                HStack {
                    Image(systemName: "chart.bar.fill").foregroundColor(.brandAmber)
                    Text("Estimated HbA1c:").font(.subheadline)
                    Text(String(format: "%.1f%%", hba1c))
                        .font(.subheadline).fontWeight(.bold).foregroundColor(.brandAmber)
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.cardBg)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .padding(.horizontal)
    }

    // ── Glucose Chart ──
    var glucoseChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Glucose Trend").font(.headline)
            if filteredGlucose.isEmpty {
                Text("No data for this period").foregroundColor(.secondary).frame(maxWidth: .infinity)
            } else {
                Chart {
                    RuleMark(y: .value("Min", store.userProfile.targetGlucoseMin / 18.0))
                        .foregroundStyle(Color.brandGreen.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    RuleMark(y: .value("Max", store.userProfile.targetGlucoseMax / 18.0))
                        .foregroundStyle(Color.brandCoral.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    ForEach(filteredGlucose) { r in
                        LineMark(
                            x: .value("Date", r.date),
                            y: .value("mmol/L", r.value / 18.0)
                        )
                        .foregroundStyle(Color.brandPurple)
                        .interpolationMethod(.catmullRom)
                        AreaMark(
                            x: .value("Date", r.date),
                            y: .value("mmol/L", r.value / 18.0)
                        )
                        .foregroundStyle(Color.brandPurple.opacity(0.1))
                        .interpolationMethod(.catmullRom)
                        PointMark(
                            x: .value("Date", r.date),
                            y: .value("mmol/L", r.value / 18.0)
                        )
                        .foregroundStyle(store.glucoseStatus(r.value).color)
                        .symbolSize(30)
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: 2.8...16.7)
            }
        }
        .padding()
        .background(Color.cardBg)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .padding(.horizontal)
    }

    // ── Glucose Distribution ──
    var glucoseDistributionCard: some View {
        let vals = filteredGlucose.map { $0.value }
        let low    = vals.filter { $0 < 70 }.count
        let normal = vals.filter { $0 >= 70 && $0 < store.userProfile.targetGlucoseMax }.count
        let high   = vals.filter { $0 >= store.userProfile.targetGlucoseMax }.count
        let total  = Double(vals.count)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Time in Range").font(.headline)
            if vals.isEmpty {
                Text("No data for this period").foregroundColor(.secondary)
            } else {
                Chart {
                    BarMark(x: .value("n", low),    y: .value("Zone", "Low"))
                        .foregroundStyle(Color.brandCoral)
                    BarMark(x: .value("n", normal), y: .value("Zone", "In Range"))
                        .foregroundStyle(Color.brandGreen)
                    BarMark(x: .value("n", high),   y: .value("Zone", "High"))
                        .foregroundStyle(Color.brandAmber)
                }
                .frame(height: 100)
                HStack(spacing: 16) {
                    legend("Low",      pct(low, total),    .brandCoral)
                    legend("In Range", pct(normal, total), .brandGreen)
                    legend("High",     pct(high, total),   .brandAmber)
                }
            }
        }
        .padding()
        .background(Color.cardBg)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .padding(.horizontal)
    }

    // ── BP Summary ──
    var bpSummaryCard: some View {
        let sys = filteredBP.map { Double($0.systolic) }
        let dia = filteredBP.map { Double($0.diastolic) }
        let pul = filteredBP.map { Double($0.pulse) }
        return VStack(alignment: .leading, spacing: 12) {
            Text("BP Summary · Last \(range) days").font(.headline).padding(.bottom, 2)
            HStack(spacing: 0) {
                summaryCol("Avg Sys",  sys.isEmpty ? "—" : "\(Int(sys.reduce(0,+)/Double(sys.count)))", "mmHg", .brandTeal)
                Divider().frame(height: 50)
                summaryCol("Avg Dia",  dia.isEmpty ? "—" : "\(Int(dia.reduce(0,+)/Double(dia.count)))", "mmHg", .brandPurple)
                Divider().frame(height: 50)
                summaryCol("Avg Pulse",pul.isEmpty ? "—" : "\(Int(pul.reduce(0,+)/Double(pul.count)))", "bpm", .brandAmber)
            }
        }
        .padding()
        .background(Color.cardBg)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .padding(.horizontal)
    }

    // ── BP Chart ──
    var bpChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BP Trend").font(.headline)
            if filteredBP.isEmpty {
                Text("No data for this period").foregroundColor(.secondary)
            } else {
                Chart {
                    RuleMark(y: .value("Target Sys", store.userProfile.targetSystolic))
                        .foregroundStyle(Color.brandTeal.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    ForEach(filteredBP) { r in
                        LineMark(x: .value("Date", r.date), y: .value("Systolic", r.systolic))
                            .foregroundStyle(Color.brandCoral).interpolationMethod(.catmullRom)
                            .symbol(.circle)
                        LineMark(x: .value("Date", r.date), y: .value("Diastolic", r.diastolic))
                            .foregroundStyle(Color.brandTeal).interpolationMethod(.catmullRom)
                            .symbol(.square)
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: 50...200)
                HStack(spacing: 20) {
                    legend("Systolic",  "", .brandCoral)
                    legend("Diastolic", "", .brandTeal)
                }
            }
        }
        .padding()
        .background(Color.cardBg)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .padding(.horizontal)
    }

    // ── Med Adherence ──
    var medicationAdherenceCard: some View {
        let activeMeds = store.medications.filter { $0.isActive }
        return VStack(alignment: .leading, spacing: 12) {
            Text("Medication Adherence").font(.headline)
            if activeMeds.isEmpty {
                Text("No active medications").foregroundColor(.secondary)
            } else {
                ForEach(activeMeds) { med in
                    let takenCount = med.logs.filter {
                        let cutoff = Calendar.current.date(byAdding: .day, value: -range, to: Date()) ?? Date()
                        return $0.date >= cutoff && $0.taken
                    }.count
                    let expectedCount = range * med.timeOfDay.count
                    let pct = expectedCount == 0 ? 0 : Double(takenCount) / Double(expectedCount)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Circle().fill(Color(hex: med.color)).frame(width: 10, height: 10)
                            Text(med.name).font(.subheadline)
                            Spacer()
                            Text("\(Int(pct*100))%").font(.subheadline).foregroundColor(Color(hex: med.color))
                        }
                        ProgressView(value: pct)
                            .tint(Color(hex: med.color))
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBg)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .padding(.horizontal)
    }

    // ── Empty State ──
    func emptyReportState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity)
    }

    // ── Helpers ──
    func summaryCol(_ title: String, _ val: String, _ sub: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title).font(.caption2).foregroundColor(.secondary)
            Text(val).font(.title3.bold()).foregroundColor(color)
            Text(sub).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    func legend(_ label: String, _ pctStr: String, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(label) \(pctStr)").font(.caption).foregroundColor(.secondary)
        }
    }

    func pct(_ n: Int, _ total: Double) -> String {
        total == 0 ? "0%" : "\(Int(Double(n)/total*100))%"
    }
}
