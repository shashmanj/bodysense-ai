//
//  DashboardView.swift
//  body sense ai
//
//  Home dashboard: Health Score · Daily Guidance · Alerts · Streaks · Quick Stats
//

import SwiftUI
import Charts

// MARK: - Dashboard

struct DashboardView: View {
    @Environment(HealthStore.self) var store
    @State private var showChat        = false
    @State private var showAlerts      = false
    @State private var showHealthScore = false
    @State private var showNutrition   = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    guidanceCard
                    if hasMinimumData {
                        healthScoreCard
                        TipsCardView()     // AI Health Insights — prominent position, user-swipeable + auto-rotates
                    } else {
                        gettingToKnowYouCard
                        healthScoreCardCollecting
                    }
                    // BP Escalation banner
                    if let bpEsc = store.lastBPEscalation, bpEsc.tier != .green {
                        bpEscalationBanner(bpEsc)
                    }
                    // GP Bridge suggestion
                    if let gpReport = store.gpBridgeReport {
                        gpBridgeCard(gpReport)
                    }
                    // Tomorrow's Food Plan
                    if let plan = store.tomorrowFoodPlan {
                        tomorrowFoodPlanCard(plan)
                    }
                    if !store.unreadAlerts.isEmpty { alertsCard }
                    quickStatsRow
                    calorieNutritionCard
                    glucoseCard
                    bpCard
                    hrvCard
                    streaksRow
                    todayMedsCard
                    challengesCard
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .background(Color.brandBg)
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackgroundVisibility(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAlerts = true } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill").font(.title3).foregroundColor(.brandPurple)
                            if !store.unreadAlerts.isEmpty {
                                Circle().fill(Color.brandCoral).frame(width: 9, height: 9).offset(x: 4, y: -3)
                            }
                        }
                    }
                    .accessibilityLabel(store.unreadAlerts.isEmpty ? "Notifications" : "Notifications, \(store.unreadAlerts.count) unread")
                    .accessibilityHint("View your health alerts")
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            FloatingChatButton(showChat: $showChat).padding(.trailing, 20).padding(.bottom, 20)
        }
        .sheet(isPresented: $showAlerts)      { AlertsView() }
        .sheet(isPresented: $showChat)        { ChatView() }
        .sheet(isPresented: $showHealthScore) { HealthScoreDetailView() }
        .sheet(isPresented: $showNutrition)   { NutritionDashboardView() }
        .task {
            // Compute lifestyle pillar scores
            store.lifestylePillarScores = LifestylePillarKnowledge.computeScores(store: store)

            // Generate tomorrow's food plan (if stale or missing)
            if store.tomorrowFoodPlan == nil ||
               store.tomorrowFoodPlan!.generatedAt.timeIntervalSinceNow < -12 * 3600 {
                store.tomorrowFoodPlan = TomorrowFoodPlanEngine.generate(store: store)
            }

            // Check GP Bridge
            store.gpBridgeReport = GPBridgeProtocol.shouldSuggestGP(store: store)

            store.save()
        }
    }

    // MARK: - BP Escalation Banner

    private func bpEscalationBanner(_ esc: BPEscalationResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: esc.tier == .critical ? "exclamationmark.triangle.fill" :
                        esc.tier == .red ? "heart.fill" : "heart.text.square")
                    .foregroundColor(esc.tier == .critical ? .red : esc.tier == .red ? .orange : .yellow)
                Text(esc.tier == .critical ? "Critical BP Alert" :
                        esc.tier == .red ? "High BP Alert" : "Elevated BP")
                    .font(.headline)
                Spacer()
            }
            Text(esc.message)
                .font(.subheadline).foregroundColor(.secondary)
            ForEach(esc.actions.prefix(3), id: \.self) { action in
                Label(action, systemImage: "arrow.right.circle")
                    .font(.caption).foregroundColor(.primary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(esc.tier == .critical ? Color.red.opacity(0.12) :
                        esc.tier == .red ? Color.orange.opacity(0.12) : Color.yellow.opacity(0.12))
        )
    }

    // MARK: - GP Bridge Card

    private func gpBridgeCard(_ report: GPBridgeReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "stethoscope").foregroundColor(.brandPurple)
                Text("Consider a GP Visit").font(.headline)
                Spacer()
                Text(report.urgency == .urgent ? "Urgent" : report.urgency == .soon ? "Soon" : "Routine")
                    .font(.caption).fontWeight(.medium)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(
                        Capsule().fill(report.urgency == .urgent ? Color.red.opacity(0.12) :
                                        report.urgency == .soon ? Color.orange.opacity(0.12) : Color.blue.opacity(0.12))
                    )
            }
            Text(report.reason)
                .font(.subheadline).foregroundColor(.secondary)
                .lineLimit(3)
            if !report.suggestedQuestions.isEmpty {
                Text("Ask your GP:").font(.caption).fontWeight(.medium).padding(.top, 2)
                ForEach(report.suggestedQuestions.prefix(2), id: \.self) { q in
                    Text("• \(q)").font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - Tomorrow's Food Plan Card

    private func tomorrowFoodPlanCard(_ plan: TomorrowFoodPlan) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "fork.knife").foregroundColor(.green)
                Text("Tomorrow's Meal Plan").font(.headline)
                Spacer()
                Text("\(plan.totalCalories) kcal").font(.caption).foregroundColor(.secondary)
            }
            ForEach(plan.meals, id: \.type) { meal in
                HStack(alignment: .top) {
                    Text(meal.type).font(.caption).fontWeight(.medium).frame(width: 70, alignment: .leading)
                    Text(meal.name).font(.caption).foregroundColor(.secondary)
                }
            }
            if !plan.drugFoodWarnings.isEmpty {
                Divider()
                ForEach(plan.drugFoodWarnings, id: \.self) { warning in
                    Label(warning, systemImage: "exclamationmark.circle")
                        .font(.caption2).foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default:      return "Good night"
        }
    }

    private var userName: String {
        let name = store.userProfile.name
        if name.isEmpty { return "" }
        return ", \(name.components(separatedBy: " ").first ?? name)"
    }

    // MARK: - Data-First Gate
    private var hasMinimumData: Bool {
        let cal = Calendar.current
        let threeDaysAgo = cal.date(byAdding: .day, value: -3, to: Date())!
        let hasGlucose = store.glucoseReadings.contains { $0.date >= threeDaysAgo }
        let hasBP = store.bpReadings.contains { $0.date >= threeDaysAgo }
        let hasSleep = store.sleepEntries.contains { $0.date >= threeDaysAgo }
        return [hasGlucose, hasBP, hasSleep].filter { $0 }.count >= 2
    }

    private var hasRecentGlucose: Bool {
        let cutoff = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        return store.glucoseReadings.contains { $0.date >= cutoff }
    }
    private var hasRecentBP: Bool {
        let cutoff = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        return store.bpReadings.contains { $0.date >= cutoff }
    }
    private var hasRecentSleep: Bool {
        let cutoff = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        return store.sleepEntries.contains { $0.date >= cutoff }
    }
    private var hasRecentSteps: Bool {
        let cutoff = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        return store.stepEntries.contains { $0.date >= cutoff }
    }

    // MARK: - Guidance Card
    var guidanceCard: some View {
        BSCard {
            VStack(alignment: .leading, spacing: 10) {
                // Always show a proper greeting
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(timeOfDayGreeting)\(userName)")
                            .font(.title3).fontWeight(.bold)
                        Text(hasMinimumData ? "Here's your health summary" : "Let's get started with your health journey")
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.title2).foregroundColor(.brandPurple)
                }

                if hasMinimumData, let g = store.dailyGuidance {
                    Text(g.insight).font(.subheadline).foregroundColor(.secondary)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Today's actions").font(.caption.bold()).foregroundColor(.brandPurple)
                        ForEach(g.actionItems.prefix(3), id: \.self) { action in
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle").font(.caption).foregroundColor(.brandGreen)
                                Text(action).font(.caption)
                            }
                        }
                    }
                    .padding(10).background(Color.brandPurple.opacity(0.06)).cornerRadius(10)
                    Text(g.quote).font(.caption.italic()).foregroundColor(.secondary)
                } else {
                    // No data yet — show a welcoming prompt
                    Text("Start by logging your first health reading below, or sync from Apple Health in Settings.")
                        .font(.subheadline).foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Getting to Know You (Data-First)
    private var gettingToKnowYouCard: some View {
        BSCard {
            VStack(spacing: 14) {
                Image(systemName: "chart.line.uptrend.xyaxis.circle")
                    .font(.system(size: 48))
                    .foregroundColor(.brandTeal)

                Text("Getting to Know You")
                    .font(.title3.bold())

                Text("Log your health data for 3+ days and I'll start finding patterns \u{2014} like how sleep affects your glucose, or how stress impacts your blood pressure.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 10) {
                    dataProgressRow(label: "Glucose", icon: "drop.fill", color: .brandTeal, done: hasRecentGlucose)
                    dataProgressRow(label: "Blood Pressure", icon: "heart.fill", color: .brandCoral, done: hasRecentBP)
                    dataProgressRow(label: "Sleep", icon: "moon.fill", color: .brandPurple, done: hasRecentSleep)
                    dataProgressRow(label: "Steps", icon: "figure.walk", color: .brandGreen, done: hasRecentSteps)
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 4)
        }
    }

    private func dataProgressRow(label: String, icon: String, color: Color, done: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(done ? color : Color(.tertiaryLabel))
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
                .foregroundColor(done ? .primary : .secondary)
            Spacer()
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .foregroundColor(done ? .brandGreen : Color(.tertiaryLabel))
        }
    }

    // MARK: - Health Score (Collecting State)
    private var healthScoreCardCollecting: some View {
        BSCard {
            HStack(spacing: 20) {
                ZStack {
                    Circle().stroke(Color.brandPurple.opacity(0.15), lineWidth: 10)
                    VStack(spacing: 0) {
                        Text("\u{2014}").font(.title.bold()).foregroundColor(.brandPurple)
                        Text("Health\nScore").font(.caption2).foregroundColor(.secondary).multilineTextAlignment(.center)
                    }
                }
                .frame(width: 90, height: 90)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Collecting data").font(.headline).foregroundColor(.secondary)
                    Text("Your health score will appear once you've logged enough data across glucose, blood pressure, and sleep.")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .accessibilityLabel("Health Score not yet available, collecting data")
    }

    // MARK: - Health Score
    var healthScoreCard: some View {
        Button { showHealthScore = true } label: {
            BSCard {
                HStack(spacing: 20) {
                    ZStack {
                        Circle().stroke(Color.brandPurple.opacity(0.15), lineWidth: 10)
                        Circle().trim(from: 0, to: Double(store.healthScore) / 100)
                            .stroke(AngularGradient(colors: [.brandTeal, .brandGreen, .brandPurple], center: .center),
                                    style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 0) {
                            Text("\(store.healthScore)").font(.title.bold()).foregroundColor(.brandPurple)
                            Text("Health\nScore").font(.caption2).foregroundColor(.secondary).multilineTextAlignment(.center)
                        }
                    }
                    .frame(width: 90, height: 90)

                    VStack(alignment: .leading, spacing: 8) {
                        let label : String = store.healthScore >= 80 ? "Excellent" : store.healthScore >= 65 ? "Good" : store.healthScore >= 50 ? "Fair" : "Needs Attention"
                        let color : Color  = store.healthScore >= 80 ? .brandGreen : store.healthScore >= 65 ? .brandTeal : store.healthScore >= 50 ? .brandAmber : .brandCoral
                        HStack {
                            Text(label).font(.headline).foregroundColor(color)
                            if let g = store.dailyGuidance, g.scoreChange != 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: g.scoreChange > 0 ? "arrow.up" : "arrow.down")
                                    Text("\(abs(g.scoreChange))")
                                }.font(.caption.bold()).foregroundColor(g.scoreChange > 0 ? .brandGreen : .brandCoral)
                            }
                        }
                        Text("Glucose · BP · Sleep · Stress · Medication adherence")
                            .font(.caption).foregroundColor(.secondary)
                        HStack(spacing: 8) {
                            ScoreDot(color: store.latestGlucose.map { store.glucoseStatus($0.value).color } ?? .gray, label: "Glucose")
                            ScoreDot(color: store.latestBP?.category.color ?? .gray, label: "BP")
                            ScoreDot(color: store.lastSleep?.quality.color ?? .gray, label: "Sleep")
                        }
                        HStack {
                            Spacer()
                            Label("View Details", systemImage: "chevron.right")
                                .font(.caption).foregroundColor(.brandPurple)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Health Score \(store.healthScore) out of 100")
        .accessibilityHint("View detailed health score breakdown")
    }

    // MARK: - Alerts Card
    var alertsCard: some View {
        Button { showAlerts = true } label: {
            BSCard {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title3).foregroundColor(.brandAmber)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(store.unreadAlerts.count) health alert\(store.unreadAlerts.count == 1 ? "" : "s") need attention")
                            .font(.subheadline.bold())
                        if let first = store.unreadAlerts.first {
                            Text(first.title).font(.caption).foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(store.unreadAlerts.count) health alert\(store.unreadAlerts.count == 1 ? "" : "s") need attention")
        .accessibilityHint("View all health alerts")
    }

    // MARK: - Quick Stats
    var todayCalories: Int {
        let cal = Calendar.current
        return store.nutritionLogs.filter { cal.isDateInToday($0.date) }
            .map { $0.calories }.reduce(0, +)
    }

    var quickStatsRow: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

        // Build stat items dynamically
        var statItems: [(icon: String, color: Color, value: String, unit: String, label: String)] = [
            ("figure.walk",      .brandTeal,              "\(store.todaySteps)", "",    "Steps"),
            ("bed.double.fill",  .brandPurple,            store.lastSleep.map { String(format: "%.1f", $0.duration) } ?? "--", "hr", "Sleep"),
            ("flame.fill",       .brandAmber,             "\(todayCalories)",    "kcal","Calories"),
            ("drop.circle.fill", Color(hex: "#4fc3f7"),   String(format: "%.1f", store.todayWaterML / 1000), "L", "Water"),
        ]

        // Conditionally add available vitals
        if let hrv = store.latestHRV {
            statItems.append(("waveform.path.ecg", .brandGreen, "\(Int(hrv.value))", "ms", "HRV"))
        }
        if let hr = store.latestHR {
            statItems.append(("heart.fill", .brandCoral, "\(hr.value)", "bpm", "Heart Rate"))
        }
        if let stress = store.latestStress {
            statItems.append(("brain.head.profile", Color(hex: "#a29bfe"), "\(stress.level)", "/10", "Stress"))
        }
        if let temp = store.latestTemp {
            statItems.append(("thermometer.medium", .brandCoral, String(format: "%.1f", temp.value), "\u{00B0}C", "Temp"))
        }

        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(statItems.enumerated()), id: \.offset) { _, item in
                QuickStatCard(icon: item.icon, color: item.color, value: item.value, unit: item.unit, label: item.label)
            }
        }
    }

    // MARK: - Calorie & Nutrition Card
    var calorieNutritionCard: some View {
        Button { showNutrition = true } label: {
            BSCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Nutrition Today", systemImage: "fork.knife.circle.fill")
                            .font(.subheadline.weight(.semibold)).foregroundColor(.brandAmber)
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
                    }

                    let todayLogs = store.nutritionLogs.filter { Calendar.current.isDateInToday($0.date) }
                    let totalCals  = todayLogs.map(\.calories).reduce(0, +)
                    let totalCarbs = todayLogs.map(\.carbs).reduce(0, +)
                    let totalProt  = todayLogs.map(\.protein).reduce(0, +)
                    let totalFat   = todayLogs.map(\.fat).reduce(0, +)
                    let calGoal = store.userProfile.dailyCalorieGoal
                    let left = max(calGoal - totalCals, 0)

                    if todayLogs.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "fork.knife")
                                .font(.title2).foregroundColor(Color(.tertiaryLabel))
                            Text("No meals logged today")
                                .font(.subheadline).foregroundColor(.secondary)
                            Text("Tap to log your nutrition")
                                .font(.caption).foregroundColor(Color(.tertiaryLabel))
                        }
                        .frame(maxWidth: .infinity, minHeight: 60)
                    } else {
                        HStack(spacing: 16) {
                            ZStack {
                                NutritionRing(value: Double(totalCals), goal: Double(calGoal),
                                              color: .brandAmber, size: 64, lineWidth: 7)
                                VStack(spacing: 1) {
                                    Text("\(left)")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                    Text("left")
                                        .font(.system(size: 8)).foregroundColor(.secondary)
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(totalCals) / \(calGoal) kcal")
                                    .font(.headline).fontWeight(.bold).foregroundColor(.brandAmber)
                                Text(left > 0 ? "\(left) kcal remaining" : "Goal reached!")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                        }

                        // Macro pills
                        HStack(spacing: 10) {
                            macroPill("Protein", value: "\(Int(totalProt))g", color: .brandTeal)
                            macroPill("Carbs", value: "\(Int(totalCarbs))g", color: .brandCoral)
                            macroPill("Fat", value: "\(Int(totalFat))g", color: .brandAmber)
                            macroPill("Meals", value: "\(todayLogs.count)", color: .brandGreen)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Nutrition today, \(todayCalories) calories consumed")
        .accessibilityHint("View detailed nutrition dashboard")
    }

    func macroPill(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.caption.bold()).foregroundColor(color)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 8)
        .background(color.opacity(0.1)).cornerRadius(10)
    }

    // MARK: - HRV Card
    var hrvCard: some View {
        Group {
            if let hrv = store.latestHRV {
                BSCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Heart Rate Variability", systemImage: "waveform.path.ecg")
                            .font(.subheadline.weight(.semibold)).foregroundColor(.brandGreen)
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(Int(hrv.value)) ms").font(.title2).fontWeight(.bold).foregroundColor(.brandGreen)
                                Text("RMSSD · \(hrv.date.formatted(date: .omitted, time: .shortened))")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            let status = hrv.value >= 50 ? ("Excellent", Color.brandGreen) :
                                         hrv.value >= 35 ? ("Good", Color.brandTeal) :
                                         hrv.value >= 20 ? ("Fair", Color.brandAmber) : ("Low", Color.brandCoral)
                            Text(status.0).font(.caption.bold())
                                .padding(.horizontal, 12).padding(.vertical, 5)
                                .background(status.1.opacity(0.15)).foregroundColor(status.1).cornerRadius(10)
                        }
                        if store.hrvReadings.count > 2 {
                            Chart(store.hrvReadings.sorted { $0.date < $1.date }.suffix(7)) { r in
                                LineMark(x: .value("D", r.date, unit: .day), y: .value("ms", r.value))
                                    .foregroundStyle(Color.brandGreen).interpolationMethod(.catmullRom)
                                AreaMark(x: .value("D", r.date, unit: .day), y: .value("ms", r.value))
                                    .foregroundStyle(Color.brandGreen.opacity(0.1))
                            }
                            .frame(height: 60).chartXAxis(.hidden).chartYAxis(.hidden)
                        }
                        Text("HRV above 50ms indicates good recovery. Low HRV may signal stress or illness.")
                            .font(.caption2).foregroundColor(.secondary)
                    }
                }
            } else {
                EmptyView()
            }
        }
    }

    // MARK: - Glucose Card
    var glucoseCard: some View {
        BSCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Blood Glucose", systemImage: "drop.fill")
                    .font(.subheadline.weight(.semibold)).foregroundColor(.brandPurple)
                if let g = store.latestGlucose {
                    let s = store.glucoseStatus(g.value)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(HealthStore.glucoseDisplayUK(g.value)).font(.title2.bold()).foregroundColor(s.color)
                            Text(g.context.rawValue + " · " + g.date.shortTime).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(s.label).font(.caption.bold())
                            .padding(.horizontal, 12).padding(.vertical, 5)
                            .background(s.color.opacity(0.15)).foregroundColor(s.color).cornerRadius(10)
                    }
                    if store.glucoseReadings.count > 2 {
                        Chart(store.glucoseReadings.sorted { $0.date < $1.date }.suffix(7)) { r in
                            LineMark(x: .value("D", r.date, unit: .day), y: .value("mmol/L", r.value / 18.0))
                                .foregroundStyle(Color.brandPurple).interpolationMethod(.catmullRom)
                            AreaMark(x: .value("D", r.date, unit: .day), y: .value("mmol/L", r.value / 18.0))
                                .foregroundStyle(Color.brandPurple.opacity(0.1))
                            RuleMark(y: .value("Min", store.userProfile.targetGlucoseMin / 18.0))
                                .foregroundStyle(Color.brandGreen.opacity(0.5)).lineStyle(StrokeStyle(dash: [4]))
                            RuleMark(y: .value("Max", store.userProfile.targetGlucoseMax / 18.0))
                                .foregroundStyle(Color.brandCoral.opacity(0.5)).lineStyle(StrokeStyle(dash: [4]))
                        }
                        .frame(height: 70).chartXAxis(.hidden).chartYAxis(.hidden)
                    }
                    HStack {
                        Text("Target: \(HealthStore.glucoseMmol(store.userProfile.targetGlucoseMin))–\(HealthStore.glucoseMmol(store.userProfile.targetGlucoseMax)) mmol/L")
                            .font(.caption).foregroundColor(.secondary)
                        Spacer()
                        let readings14 = store.glucoseReadings.prefix(14)
                        let inRange = readings14.filter {
                            $0.value >= store.userProfile.targetGlucoseMin && $0.value <= store.userProfile.targetGlucoseMax
                        }.count
                        if !readings14.isEmpty {
                            Text("In range: \(Int(Double(inRange)/Double(readings14.count)*100))%")
                                .font(.caption.bold()).foregroundColor(.brandGreen)
                        }
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "drop")
                            .font(.title2).foregroundColor(Color(.tertiaryLabel))
                        Text("No readings yet")
                            .font(.subheadline).foregroundColor(.secondary)
                        Text("Tap Track to log your glucose")
                            .font(.caption).foregroundColor(Color(.tertiaryLabel))
                    }
                    .frame(maxWidth: .infinity, minHeight: 60)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - BP Card
    var bpCard: some View {
        BSCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Blood Pressure", systemImage: "heart.fill")
                    .font(.subheadline.weight(.semibold)).foregroundColor(.brandCoral)
                if let b = store.latestBP {
                    HStack {
                        HStack(spacing: 16) {
                            BPPill(label: "SYS",   value: "\(b.systolic)",  color: b.category.color)
                            BPPill(label: "DIA",   value: "\(b.diastolic)", color: b.category.color)
                            BPPill(label: "Pulse", value: "\(b.pulse)",     color: .brandTeal)
                        }
                        Spacer()
                        Text(b.category.rawValue).font(.caption.bold())
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(b.category.color.opacity(0.15)).foregroundColor(b.category.color).cornerRadius(10)
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "heart")
                            .font(.title2).foregroundColor(Color(.tertiaryLabel))
                        Text("No readings yet")
                            .font(.subheadline).foregroundColor(.secondary)
                        Text("Tap Track to log your blood pressure")
                            .font(.caption).foregroundColor(Color(.tertiaryLabel))
                    }
                    .frame(maxWidth: .infinity, minHeight: 60)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Streaks Row
    var streaksRow: some View {
        BSCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Streaks", systemImage: "flame.fill")
                    .font(.subheadline.weight(.semibold)).foregroundColor(.brandCoral)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(store.userStreaks.prefix(4)) { streak in
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle().fill(streak.currentCount > 0 ? Color.brandCoral.opacity(0.15) : Color.gray.opacity(0.1))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: streak.type.icon)
                                        .foregroundColor(streak.currentCount > 0 ? .brandCoral : .gray)
                                }
                                Text("\(streak.currentCount)d").font(.caption.bold())
                                    .foregroundColor(streak.currentCount > 0 ? .brandCoral : .secondary)
                                Text(streak.type.rawValue.components(separatedBy: " ").first ?? "")
                                    .font(.caption2).foregroundColor(.secondary)
                            }.frame(width: 70)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Today's Meds Card
    var todayMedsCard: some View {
        let activeMeds = store.medications.filter { $0.isActive }
        return BSCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Today's Medications", systemImage: "pill.fill")
                    .font(.subheadline.weight(.semibold)).foregroundColor(.brandPurple)
                if activeMeds.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "pill")
                            .font(.title2).foregroundColor(Color(.tertiaryLabel))
                        Text("No active medications")
                            .font(.subheadline).foregroundColor(.secondary)
                        Text("Add them in Track")
                            .font(.caption).foregroundColor(Color(.tertiaryLabel))
                    }
                    .frame(maxWidth: .infinity, minHeight: 60)
                } else {
                    ForEach(activeMeds.prefix(3)) { med in
                        HStack {
                            Circle().fill(Color(hex: med.color)).frame(width: 10, height: 10)
                            Text("\(med.name) \(med.dosage)\(med.unit)").font(.subheadline)
                            Spacer()
                            Text(med.timeOfDay.map { $0.rawValue }.joined(separator: " · "))
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                    if activeMeds.count > 3 {
                        Text("+ \(activeMeds.count - 3) more").font(.caption).foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Challenges Teaser
    var challengesCard: some View {
        let active = store.healthChallenges.filter { $0.isJoined && !$0.isCompleted }
        guard !active.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(BSCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Active Challenges", systemImage: "flag.fill")
                    .font(.subheadline.weight(.semibold)).foregroundColor(.brandAmber)
                ForEach(active.prefix(2)) { ch in
                    HStack {
                        Image(systemName: ch.type.icon).foregroundColor(ch.type.color)
                        Text(ch.title).font(.subheadline).lineLimit(1)
                        Spacer()
                        Text("\(Int(ch.progress * 100))%").font(.caption.bold()).foregroundColor(ch.type.color)
                    }
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(ch.type.color.opacity(0.15)).frame(height: 6)
                            RoundedRectangle(cornerRadius: 3).fill(ch.type.color).frame(width: g.size.width * ch.progress, height: 6)
                        }
                    }.frame(height: 6)
                }
            }
        })
    }

}

// MARK: - AI Health Insights Card (Isolated Sub-View)
// Generates personalised tips from the user's actual health data — glucose, BP, sleep, nutrition,
// exercise, medications, symptoms, conditions, water intake, HRV, stress, body temp, and goals.
// Timer lives here — updates only re-render this card, not the entire dashboard.

struct TipsCardView: View {
    @Environment(HealthStore.self) var store
    @State private var tipIndex = 0
    @State private var tipTimer: Timer?
    @State private var insights: [String] = []
    @State private var dragOffset: CGFloat = 0
    @State private var swipeDirection: Edge = .trailing

    var body: some View {
        let count = max(insights.count, 1)
        let safeIdx = insights.isEmpty ? 0 : tipIndex % count

        BSCard {
            VStack(alignment: .leading, spacing: 8) {
                // Header row with icon + title + page counter
                HStack {
                    Label("AI Health Insights", systemImage: "brain.head.profile")
                        .font(.headline).foregroundColor(.brandPurple)
                    Spacer()
                    if !insights.isEmpty {
                        Text("\(safeIdx + 1)/\(count)")
                            .font(.caption2).fontWeight(.medium)
                            .foregroundColor(.brandPurple.opacity(0.6))
                    }
                }

                if insights.isEmpty {
                    Text("Log your health data to get personalised insights powered by BodySense AI.")
                        .font(.subheadline).foregroundColor(.secondary)
                } else {
                    // Insight text with swipe animation
                    Text(insights[safeIdx])
                        .font(.subheadline).foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .id(tipIndex)
                        .transition(.asymmetric(
                            insertion: .move(edge: swipeDirection).combined(with: .opacity),
                            removal: .move(edge: swipeDirection == .trailing ? .leading : .trailing).combined(with: .opacity)
                        ))
                        .offset(x: dragOffset)

                    // Dot indicator row + swipe hint
                    HStack(spacing: 4) {
                        ForEach(0..<count, id: \.self) { i in
                            Circle()
                                .fill(i == safeIdx ? Color.brandPurple : Color.brandPurple.opacity(0.25))
                                .frame(width: i == safeIdx ? 8 : 5, height: i == safeIdx ? 8 : 5)
                                .animation(.easeInOut(duration: 0.2), value: safeIdx)
                        }
                        Spacer()
                        if count > 1 {
                            Text("Swipe for more")
                                .font(.caption2).foregroundColor(.secondary.opacity(0.6))
                        }
                    }
                    .padding(.top, 2)
                }
            }
        }
        .contentShape(Rectangle()) // Makes entire card area respond to gestures
        .gesture(
            DragGesture(minimumDistance: 30, coordinateSpace: .local)
                .onChanged { value in
                    dragOffset = value.translation.width * 0.3 // subtle drag feedback
                }
                .onEnded { value in
                    dragOffset = 0
                    guard !insights.isEmpty else { return }
                    let threshold: CGFloat = 40
                    if value.translation.width < -threshold {
                        // Swiped left → next insight
                        swipeDirection = .trailing
                        withAnimation(.easeInOut(duration: 0.35)) {
                            tipIndex = (tipIndex + 1) % count
                        }
                        resetAutoRotateTimer()
                    } else if value.translation.width > threshold {
                        // Swiped right → previous insight
                        swipeDirection = .leading
                        withAnimation(.easeInOut(duration: 0.35)) {
                            tipIndex = (tipIndex - 1 + count) % count
                        }
                        resetAutoRotateTimer()
                    }
                }
        )
        .onAppear {
            insights = PersonalisedInsightEngine.generate(from: store)
            guard !insights.isEmpty else { return }
            tipIndex = Calendar.current.component(.hour, from: Date()) % insights.count
            startAutoRotateTimer()
        }
        .onDisappear { tipTimer?.invalidate(); tipTimer = nil }
    }

    // MARK: - Timer Helpers

    private func startAutoRotateTimer() {
        tipTimer?.invalidate()
        tipTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { _ in
            swipeDirection = .trailing
            withAnimation(.easeInOut(duration: 0.4)) {
                tipIndex = (tipIndex + 1) % max(insights.count, 1)
            }
        }
    }

    private func resetAutoRotateTimer() {
        // User swiped manually — restart the 8-sec countdown from now
        startAutoRotateTimer()
    }
}

// MARK: - Personalised Insight Engine
// Analyses the user's HealthStore data and generates contextual, actionable health tips.
// 100% local computation — no API call needed, instant on every dashboard load.

enum PersonalisedInsightEngine {

    static func generate(from store: HealthStore) -> [String] {
        let cal = Calendar.current
        var tips: [String] = []
        let p = store.userProfile

        // ── Glucose Insights ──
        if let g = store.glucoseReadings.max(by: { $0.date < $1.date }) {
            let val = Int(g.value)
            if val > Int(store.userProfile.targetGlucoseMax) {
                tips.append("Your latest glucose is \(HealthStore.glucoseDisplayUK(g.value)) — above your \(HealthStore.glucoseMmol(p.targetGlucoseMax)) mmol/L target. A 15-min walk after meals can lower post-meal spikes by 1.1–1.7 mmol/L.")
            } else if val < Int(store.userProfile.targetGlucoseMin) {
                tips.append("Glucose at \(HealthStore.glucoseDisplayUK(g.value)) is below your \(HealthStore.glucoseMmol(p.targetGlucoseMin)) mmol/L target. Consider a small snack with protein and complex carbs to stabilise.")
            } else {
                tips.append("Glucose at \(HealthStore.glucoseDisplayUK(g.value)) — nicely within your \(HealthStore.glucoseMmol(p.targetGlucoseMin))–\(HealthStore.glucoseMmol(p.targetGlucoseMax)) mmol/L target range. Keep up the great work!")
            }
            // Trend analysis
            let recent7 = store.glucoseReadings.filter { $0.date > cal.date(byAdding: .day, value: -7, to: Date())! }
            if recent7.count >= 3 {
                let avg = recent7.map { $0.value }.reduce(0, +) / Double(recent7.count)
                tips.append("Your 7-day glucose average is \(HealthStore.glucoseMmol(avg)) mmol/L across \(recent7.count) readings. \(avg > p.targetGlucoseMax ? "Consider reducing refined carbs and increasing fibre." : "Excellent metabolic control!")")
            }
        }

        // ── Blood Pressure Insights ──
        if let bp = store.bpReadings.max(by: { $0.date < $1.date }) {
            if bp.systolic >= 140 || bp.diastolic >= 90 {
                tips.append("🔴 BP \(bp.systolic)/\(bp.diastolic) mmHg is in the hypertension range. Reducing sodium to <2g/day and regular exercise can lower systolic by 5–10 mmHg.")
            } else if bp.systolic >= 130 || bp.diastolic >= 80 {
                tips.append("🟡 BP \(bp.systolic)/\(bp.diastolic) mmHg is elevated. Try the DASH diet — rich in fruits, vegetables, and whole grains — to help bring it down.")
            } else {
                tips.append("💚 BP \(bp.systolic)/\(bp.diastolic) mmHg — excellent reading! Keep it up with balanced nutrition and regular activity.")
            }
        }

        // ── Sleep Insights ──
        if let sleep = store.sleepEntries.max(by: { $0.date < $1.date }) {
            let hrs = sleep.duration
            if hrs < 6 {
                tips.append("😴 Only \(String(format: "%.1f", hrs)) hours of sleep last night. Adults need 7–9 hours for optimal glucose regulation and heart health. Try setting a consistent bedtime.")
            } else if hrs >= 6 && hrs < 7 {
                tips.append("🌙 \(String(format: "%.1f", hrs)) hours of sleep — close to the recommended 7–9 hours. Even 30 extra minutes can improve insulin sensitivity.")
            } else {
                tips.append("🌟 Great sleep — \(String(format: "%.1f", hrs)) hours! Consistent good sleep improves glucose control by up to 20%.")
            }
        }

        // ── Nutrition Insights (use actual user goals) ──
        let calGoal = p.dailyCalorieGoal
        let protGoal = p.dailyProteinGoal
        let goalType = NutritionGoalType(rawValue: p.nutritionGoalType) ?? .maintain

        let todayLogs = store.nutritionLogs.filter { cal.isDateInToday($0.date) }
        if !todayLogs.isEmpty {
            let totalCals = todayLogs.map { $0.calories }.reduce(0, +)
            let totalCarbs = todayLogs.map { $0.carbs }.reduce(0, +)
            let totalProt = todayLogs.map { $0.protein }.reduce(0, +)

            if totalCals > calGoal + 200 {
                tips.append("🍽️ \(totalCals) kcal consumed — above your \(calGoal) kcal \(goalType.label.lowercased()) target. Consider lighter portions for remaining meals.")
            } else if totalCals > 0 && totalCals < calGoal / 2 {
                tips.append("🍽️ Only \(totalCals) kcal so far — you need \(calGoal - totalCals) more to hit your \(calGoal) kcal \(goalType.label.lowercased()) target.")
            }

            if totalCarbs > Double(p.dailyCarbGoal) * 1.1 {
                tips.append("🍞 Carbs at \(Int(totalCarbs))g vs \(Int(p.dailyCarbGoal))g target. Choose complex carbs like oats and quinoa over refined options.")
            }

            // Protein insight — critical for muscle building
            if totalProt < protGoal * 0.5 && totalCals > 500 {
                let remaining = Int(protGoal - totalProt)
                if goalType == .muscle {
                    tips.append("Only \(Int(totalProt))g of \(Int(protGoal))g protein target! You need \(remaining)g more for muscle growth. Add chicken breast (31g/100g), eggs (13g/2), or whey shake (25g).")
                } else {
                    tips.append("Only \(Int(totalProt))g of \(Int(protGoal))g protein target. Add lean protein to your next meal — it stabilises blood sugar and preserves muscle.")
                }
            } else if totalProt >= protGoal {
                tips.append("Protein target hit — \(Int(totalProt))g of \(Int(protGoal))g! Great for \(goalType == .muscle ? "muscle protein synthesis" : "maintaining lean mass").")
            }
        } else {
            tips.append("No meals logged today. Tracking nutrition helps \(goalType == .muscle ? "ensure you hit your protein target for muscle growth" : "identify patterns between food and glucose") — log your next meal!")
        }

        // ── Exercise & Steps Insights ──
        let todaySteps = store.todaySteps
        if todaySteps > 10000 {
            tips.append("Amazing — \(todaySteps.formatted()) steps today! Regular walking at this level reduces cardiovascular risk by up to 30%.")
        } else if todaySteps > 5000 {
            tips.append("\(todaySteps.formatted()) steps so far — solid progress! Another \(max(0, 10000 - todaySteps).formatted()) steps to hit the 10K goal.")
        } else if todaySteps > 0 {
            tips.append("\(todaySteps.formatted()) steps today. Even a short 10-min walk now would help lower glucose and boost your mood.")
        }

        // ── Water Intake ──
        let waterML = store.todayWaterML
        let targetML = p.targetWater > 0 ? p.targetWater * 1000 : 2500.0
        if waterML > 0 {
            let pct = Int(waterML / targetML * 100)
            if pct >= 100 {
                tips.append("Hydration goal reached — \(String(format: "%.1f", waterML / 1000))L! Good hydration supports kidney function and blood pressure.")
            } else {
                tips.append("\(String(format: "%.1f", waterML / 1000))L of \(String(format: "%.1f", targetML / 1000))L target (\(pct)%). Drink \(String(format: "%.1f", (targetML - waterML) / 1000))L more for optimal hydration.")
            }
        }

        // ── HRV & Stress Insights ──
        if let hrv = store.hrvReadings.max(by: { $0.date < $1.date }) {
            if hrv.value < 20 {
                tips.append("HRV at \(Int(hrv.value))ms is low — your body may be under stress. Try 5 minutes of deep breathing or a guided meditation.")
            } else if hrv.value >= 50 {
                tips.append("HRV at \(Int(hrv.value))ms shows excellent recovery and resilience. Your nervous system is well-balanced!")
            }
        }

        if let stress = store.stressReadings.max(by: { $0.date < $1.date }) {
            if stress.level >= 7 {
                tips.append("Stress level \(stress.level)/10 — elevated. Try box breathing (4s in, 4s hold, 4s out, 4s hold) to activate your parasympathetic nervous system.")
            }
        }

        // ── Medication Adherence ──
        let activeMeds = store.medications.filter { $0.isActive }
        if !activeMeds.isEmpty {
            tips.append("You have \(activeMeds.count) active medication\(activeMeds.count == 1 ? "" : "s"). Consistent timing maximises effectiveness — set reminders for each dose.")
        }

        // ── Body Temperature ──
        if let temp = store.bodyTempReadings.max(by: { $0.date < $1.date }) {
            if temp.value > 37.5 {
                tips.append("Body temp \(String(format: "%.1f", temp.value))°C — slightly elevated. Stay hydrated and monitor for any developing symptoms.")
            }
        }

        // ── Conditions-Specific Tips (from user profile) ──
        let diabetesType = p.diabetesType.lowercased()
        if diabetesType.contains("type 1") {
            tips.append("Type 1 Diabetes: Consistent carb counting and insulin timing are key. Pair carbs with protein/fat to slow absorption.")
        } else if diabetesType.contains("type 2") {
            tips.append("Type 2 Diabetes: Aim for <7% HbA1c. Pairing carbs with protein/fat slows absorption and reduces glucose spikes.")
        } else if diabetesType.contains("gestational") {
            tips.append("Gestational Diabetes: Monitor glucose closely. Frequent small meals with complex carbs help maintain stable levels.")
        }

        if p.hasHypertension {
            tips.append("With hypertension, the DASH diet (fruits, vegetables, low-fat dairy, whole grains) can lower systolic BP by 8–14 mmHg.")
        }

        // Check medications for statin-related tips
        let medNames = store.medications.map { $0.name.lowercased() }
        if medNames.contains(where: { $0.contains("statin") || $0.contains("atorvastatin") || $0.contains("rosuvastatin") || $0.contains("simvastatin") }) {
            tips.append("On statins: take them at the same time daily. Grapefruit can interact — check with your doctor.")
        }

        // ── Health Goals ──
        let active = store.healthGoals.filter { !$0.isCompleted }
        if let goal = active.first {
            tips.append("Active goal: \"\(goal.title)\" — \(Int(goal.progress * 100))% complete. Small daily actions compound into big health improvements!")
        }

        // ── Recent Symptoms ──
        let recentSymptoms = store.symptomLogs.filter { $0.date > cal.date(byAdding: .day, value: -3, to: Date())! }
        if !recentSymptoms.isEmpty {
            let allSymptoms = recentSymptoms.flatMap { $0.symptoms }
            let uniqueSymptoms = Array(Set(allSymptoms)).prefix(3).joined(separator: ", ")
            tips.append("📋 Recent symptoms: \(uniqueSymptoms). Track patterns between symptoms, meals, and sleep to share with your doctor.")
        }

        // ── Fitness & Muscle-Building Insights ──
        if goalType == .muscle {
            let protPerKg = p.weight > 0 ? protGoal / p.weight : 2.2
            tips.append("🏋️ Build Muscle mode: targeting \(Int(protGoal))g protein/day (\(String(format: "%.1f", protPerKg))g/kg). Spread protein across 4–5 meals for optimal muscle protein synthesis.")

            if let sleep = store.sleepEntries.max(by: { $0.date < $1.date }), sleep.duration < 7 {
                tips.append("💤 Muscle recovery happens during deep sleep. At \(String(format: "%.1f", sleep.duration))h, aim for 7–9h — growth hormone peaks during slow-wave sleep.")
            }

            let todayExerciseCal = store.stepEntries.filter { cal.isDateInToday($0.date) }.map { $0.calories }.reduce(0, +)
            if todayExerciseCal > 300 {
                tips.append("🔥 \(todayExerciseCal) kcal burned today! Post-workout: consume 20–40g protein within 2 hours to maximise muscle repair.")
            }
        } else if goalType == .lose {
            tips.append("⚡ Weight loss tip: prioritise protein (\(Int(protGoal))g/day) to preserve lean muscle mass during your calorie deficit.")
        }

        // ── Activity Level Awareness ──
        let level = ActivityLevel(rawValue: p.activityLevel) ?? .moderate
        if level == .sedentary || level == .light {
            tips.append("🚶 Your activity level is set to \"\(level.label)\". Even adding a daily 20-min walk can improve insulin sensitivity and cardiovascular health.")
        } else if level == .veryActive {
            tips.append("🏅 Very active lifestyle! Make sure you're eating enough — your TDEE is \(Int(p.tdee)) kcal. Under-fuelling can impair recovery and immune function.")
        }

        // ── Fallback if no data yet ──
        if tips.isEmpty {
            tips = [
                "💡 Start logging your glucose, meals, and sleep to unlock personalised AI health insights.",
                "💡 BodySense AI analyses your health patterns to give you actionable, personalised tips.",
                "💡 The more data you log, the smarter your insights become. Let's build your health picture!",
            ]
        }

        return tips
    }
}

// MARK: - Health Score Detail Sheet

struct HealthScoreDetailView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    // Today's vitals from step entries (HealthKit synced or manual)
    var todayEntry: StepEntry? {
        store.stepEntries.first(where: { Calendar.current.isDateInToday($0.date) })
    }
    var todayDistance: Double { (todayEntry?.distance ?? 0) / 1000.0 } // metres -> km
    var todayCaloriesBurned: Int { todayEntry?.calories ?? 0 }
    var todayStandMinutes: Int { todayEntry?.activeMinutes ?? 0 }

    // Latest SpO2 from HealthKit manager cache
    var latestSpO2: Double { HealthKitManager.shared.latestSpO2 ?? 0 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Big score circle
                    ZStack {
                        Circle().stroke(Color.brandPurple.opacity(0.12), lineWidth: 18)
                        Circle().trim(from: 0, to: Double(store.healthScore) / 100)
                            .stroke(AngularGradient(colors: [.brandTeal, .brandGreen, .brandPurple], center: .center),
                                    style: StrokeStyle(lineWidth: 18, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 4) {
                            Text("\(store.healthScore)").font(.system(size: 52, weight: .bold)).foregroundColor(.brandPurple)
                            Text("Health Score").font(.subheadline).foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 180, height: 180)
                    .padding(.top, 20)

                    let label: String = store.healthScore >= 80 ? "Excellent" : store.healthScore >= 65 ? "Good" : store.healthScore >= 50 ? "Fair" : "Needs Attention"
                    let color: Color  = store.healthScore >= 80 ? .brandGreen : store.healthScore >= 65 ? .brandTeal : store.healthScore >= 50 ? .brandAmber : .brandCoral

                    Text(label).font(.title2.bold()).foregroundColor(color)

                    // Score breakdown
                    VStack(spacing: 0) {
                        scoreRow("Blood Glucose", value: store.latestGlucose.map { store.glucoseStatus($0.value).label } ?? "No data", color: store.latestGlucose.map { store.glucoseStatus($0.value).color } ?? .gray, icon: "drop.fill")
                        Divider().padding(.leading, 52)
                        scoreRow("Blood Pressure", value: store.latestBP?.category.rawValue ?? "No data", color: store.latestBP?.category.color ?? .gray, icon: "heart.fill")
                        Divider().padding(.leading, 52)
                        scoreRow("Sleep Quality", value: store.lastSleep?.quality.rawValue ?? "No data", color: store.lastSleep?.quality.color ?? .gray, icon: "bed.double.fill")
                        Divider().padding(.leading, 52)
                        scoreRow("Medications", value: store.medications.filter { $0.isActive }.isEmpty ? "None active" : "\(store.medications.filter { $0.isActive }.count) active", color: .brandPurple, icon: "pill.fill")
                        Divider().padding(.leading, 52)
                        scoreRow("Steps Today", value: "\(store.todaySteps) steps", color: .brandTeal, icon: "figure.walk")
                        Divider().padding(.leading, 52)
                        scoreRow("Distance", value: String(format: "%.1f km", todayDistance), color: .brandGreen, icon: "location.fill")
                        Divider().padding(.leading, 52)
                        scoreRow("Calories Burned", value: "\(todayCaloriesBurned) kcal", color: .brandAmber, icon: "flame.fill")
                        Divider().padding(.leading, 52)
                        scoreRow("Standing Time", value: "\(todayStandMinutes) min", color: .brandCoral, icon: "figure.stand")
                        Divider().padding(.leading, 52)
                        scoreRow("SpO₂", value: latestSpO2 > 0 ? String(format: "%.0f%%", latestSpO2) : "No data", color: latestSpO2 >= 95 ? .brandGreen : .brandCoral, icon: "lungs.fill")
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.primary.opacity(0.05), radius: 6)
                    .padding(.horizontal)

                    // How score is calculated
                    BSCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("How is this calculated?", systemImage: "info.circle.fill")
                                .font(.subheadline.bold()).foregroundColor(.brandPurple)
                            Text("Your health score is calculated daily from your glucose readings, blood pressure, sleep quality, medication adherence, and physical activity. Log data regularly to keep your score accurate.")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color.brandBg)
            .navigationTitle("Health Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    func scoreRow(_ label: String, value: String, color: Color, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.body).foregroundColor(.white)
                .frame(width: 32, height: 32).background(color).cornerRadius(8)
            Text(label).font(.subheadline)
            Spacer()
            Text(value).font(.caption.bold()).foregroundColor(color)
        }
        .padding()
    }
}

// MARK: - Nutrition Log Sheet (from dashboard tap)

struct NutritionLogSheet: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    var todayLogs: [NutritionLog] {
        store.nutritionLogs.filter { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if todayLogs.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "fork.knife.circle")
                                .font(.system(size: 56)).foregroundColor(.brandAmber.opacity(0.4))
                                .padding(.top, 40)
                            Text("No meals logged today")
                                .font(.headline)
                            Text("Open the Track tab and tap Nutrition to log your meals.")
                                .font(.subheadline).foregroundColor(.secondary)
                                .multilineTextAlignment(.center).padding(.horizontal, 32)
                        }
                    } else {
                        // Summary
                        let totalCals  = todayLogs.map { $0.calories }.reduce(0, +)
                        let totalCarbs = todayLogs.map { $0.carbs }.reduce(0, +)
                        let totalProt  = todayLogs.map { $0.protein }.reduce(0, +)
                        let totalFat   = todayLogs.map { $0.fat }.reduce(0, +)

                        BSCard {
                            VStack(spacing: 12) {
                                Text("\(totalCals) kcal today").font(.title2.bold()).foregroundColor(.brandAmber)
                                HStack(spacing: 12) {
                                    macroBadge("Carbs", "\(Int(totalCarbs))g", .brandTeal)
                                    macroBadge("Protein", "\(Int(totalProt))g", .brandPurple)
                                    macroBadge("Fat", "\(Int(totalFat))g", .brandAmber)
                                }
                            }
                        }

                        ForEach(todayLogs.sorted { $0.date > $1.date }) { log in
                            BSCard {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(log.mealType.rawValue).font(.caption.bold()).foregroundColor(.brandAmber)
                                        Text(log.foodName).font(.subheadline.bold())
                                        Text("\(Int(log.carbs))g carbs · \(Int(log.protein))g protein · \(Int(log.fat))g fat")
                                            .font(.caption).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("\(log.calories) kcal").font(.headline).foregroundColor(.brandAmber)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal).padding(.top, 8).padding(.bottom, 40)
            }
            .background(Color.brandBg)
            .navigationTitle("Today's Nutrition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    func macroBadge(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline.bold()).foregroundColor(color)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 8)
        .background(color.opacity(0.1)).cornerRadius(10)
    }
}

// MARK: - Alerts Sheet

struct AlertsView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    var sorted: [HealthAlert] { store.healthAlerts.sorted { $0.date > $1.date } }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sorted) { alert in
                    HStack(alignment: .top, spacing: 14) {
                        ZStack {
                            Circle().fill(alert.type.color.opacity(0.15)).frame(width: 42, height: 42)
                            Image(systemName: alert.type.icon).foregroundColor(alert.type.color)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(alert.title).font(.subheadline.bold())
                                if !alert.isRead {
                                    Circle().fill(Color.brandPurple).frame(width: 7, height: 7)
                                }
                            }
                            Text(alert.message).font(.caption).foregroundColor(.secondary)
                            Text(alert.date.timeAgo).font(.caption2).foregroundColor(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let idx = store.healthAlerts.firstIndex(where: { $0.id == alert.id }) {
                            store.healthAlerts[idx].isRead = true
                            store.save()
                        }
                    }
                    .listRowBackground(alert.isRead ? Color(.secondarySystemGroupedBackground) : Color.brandPurple.opacity(0.04))
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Health Alerts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Mark all read") {
                        for i in store.healthAlerts.indices { store.healthAlerts[i].isRead = true }
                        store.save()
                    }
                }
                ToolbarItem(placement: .topBarLeading) { Button("Done") { dismiss() } }
            }
        }
    }
}

// MARK: - Subviews

struct QuickStatCard: View {
    let icon: String; let color: Color; let value: String; var unit: String = ""; let label: String
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                // Label row with icon — Apple Health style
                HStack(spacing: 5) {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(color)
                    Text(label.uppercased())
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(color)
                }

                // Value row — large number + small unit
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color.opacity(0.08))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value) \(unit)")
    }
}

struct BPPill: View {
    let label: String; let value: String; let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.bold()).foregroundColor(color)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

struct ScoreDot: View {
    let color: Color; let label: String
    var body: some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
    }
}
