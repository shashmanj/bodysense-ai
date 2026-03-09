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
    @State private var tipIndex        = 0
    @State private var tipTimer        : Timer? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    guidanceCard
                    healthScoreCard
                    if !store.unreadAlerts.isEmpty { alertsCard }
                    quickStatsRow
                    calorieNutritionCard
                    glucoseCard
                    bpCard
                    hrvCard
                    streaksRow
                    todayMedsCard
                    challengesCard
                    tipsCard
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .background(Color.brandBg)
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
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
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            FloatingChatButton(showChat: $showChat).padding(.trailing, 20).padding(.bottom, 20)
        }
        .sheet(isPresented: $showAlerts)      { AlertsView() }
        .sheet(isPresented: $showChat)        { ChatView() }
        .sheet(isPresented: $showHealthScore) { HealthScoreDetailView() }
        .sheet(isPresented: $showNutrition)   { NutritionLogSheet() }
        .onAppear {
            // Seed tip index from current time so each launch shows a different tip
            tipIndex = Calendar.current.component(.hour, from: Date()) % tips.count
            // Rotate tips every 8 seconds for a lively feel
            tipTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.4)) {
                    tipIndex = (tipIndex + 1) % tips.count
                }
            }
        }
        .onDisappear { tipTimer?.invalidate(); tipTimer = nil }
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

    // MARK: - Guidance Card
    var guidanceCard: some View {
        BSCard {
            VStack(alignment: .leading, spacing: 10) {
                if let g = store.dailyGuidance {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(timeOfDayGreeting)\(userName)").font(.headline)
                            Text("Your daily health brief").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "brain.head.profile")
                            .font(.title2).foregroundColor(.brandPurple)
                    }
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
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(timeOfDayGreeting)\(userName)").font(.headline)
                            Text("Let's check on your health today").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "sparkles").font(.title2).foregroundColor(.brandPurple)
                    }
                }
            }
        }
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
    }

    // MARK: - Quick Stats
    var todayCalories: Int {
        let cal = Calendar.current
        return store.nutritionLogs.filter { cal.isDateInToday($0.date) }
            .map { $0.calories }.reduce(0, +)
    }

    var quickStatsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                QuickStatCard(icon: "figure.walk",      color: .brandTeal,   value: "\(store.todaySteps)",   label: "Steps")
                QuickStatCard(icon: "bed.double.fill",  color: .brandPurple, value: store.lastSleep.map { String(format: "%.1fh", $0.duration) } ?? "--", label: "Sleep")
                QuickStatCard(icon: "flame.fill",       color: .brandAmber,  value: "\(todayCalories) kcal",  label: "Calories")
                QuickStatCard(icon: "drop.circle.fill", color: Color(hex: "#4fc3f7"), value: String(format: "%.1fL", store.todayWaterML / 1000), label: "Water")
                if let hr = store.latestHR {
                    QuickStatCard(icon: "heart.fill",   color: .brandCoral,  value: "\(hr.value) bpm",       label: "Heart Rate")
                }
                if let hrv = store.latestHRV {
                    QuickStatCard(icon: "waveform.path.ecg", color: .brandGreen, value: "\(Int(hrv.value)) ms", label: "HRV")
                }
                if let stress = store.latestStress {
                    QuickStatCard(icon: "brain.head.profile", color: .brandPurple, value: "\(stress.level)/10", label: "Stress")
                }
                if let temp = store.latestTemp {
                    QuickStatCard(icon: "thermometer.medium", color: .brandCoral, value: String(format: "%.1f°C", temp.value), label: "Temp")
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Calorie & Nutrition Card
    var calorieNutritionCard: some View {
        Button { showNutrition = true } label: {
        BSCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                Label("Nutrition Today", systemImage: "fork.knife.circle.fill")
                    .font(.headline).foregroundColor(.brandAmber)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
                }

                let todayLogs = store.nutritionLogs.filter { Calendar.current.isDateInToday($0.date) }
                let totalCals  = todayLogs.map { $0.calories }.reduce(0, +)
                let totalCarbs = todayLogs.map { $0.carbs }.reduce(0, +)
                let totalProt  = todayLogs.map { $0.protein }.reduce(0, +)
                let totalFat   = todayLogs.map { $0.fat }.reduce(0, +)
                let calorieGoal = 2000

                if todayLogs.isEmpty {
                    Text("No meals logged today. Tap to log your nutrition.")
                        .font(.caption).foregroundColor(.secondary)
                } else {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(totalCals) / \(calorieGoal) kcal")
                                .font(.title2).fontWeight(.bold).foregroundColor(.brandAmber)
                            Text("\(calorieGoal - totalCals > 0 ? "\(calorieGoal - totalCals) kcal remaining" : "Goal reached! 🎉")")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        ZStack {
                            Circle().stroke(Color.brandAmber.opacity(0.2), lineWidth: 8)
                            Circle().trim(from: 0, to: min(Double(totalCals) / Double(calorieGoal), 1.0))
                                .stroke(Color.brandAmber, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            Text("\(min(Int(Double(totalCals) / Double(calorieGoal) * 100), 100))%")
                                .font(.caption.bold()).foregroundColor(.brandAmber)
                        }
                        .frame(width: 56, height: 56)
                    }

                    // Macro pills
                    HStack(spacing: 10) {
                        macroPill("Carbs", value: "\(Int(totalCarbs))g", color: .brandTeal)
                        macroPill("Protein", value: "\(Int(totalProt))g", color: .brandPurple)
                        macroPill("Fat", value: "\(Int(totalFat))g", color: .brandAmber)
                        macroPill("Meals", value: "\(todayLogs.count)", color: .brandGreen)
                    }
                }
            }
        }
        }
        .buttonStyle(.plain)
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
                            .font(.headline).foregroundColor(.brandGreen)
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
                Label("Blood Glucose", systemImage: "drop.fill").font(.headline).foregroundColor(.brandPurple)
                if let g = store.latestGlucose {
                    let s = store.glucoseStatus(g.value)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(Int(g.value)) mg/dL").font(.title2.bold()).foregroundColor(s.color)
                            Text(g.context.rawValue + " · " + g.date.shortTime).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(s.label).font(.caption.bold())
                            .padding(.horizontal, 12).padding(.vertical, 5)
                            .background(s.color.opacity(0.15)).foregroundColor(s.color).cornerRadius(10)
                    }
                    if store.glucoseReadings.count > 2 {
                        Chart(store.glucoseReadings.sorted { $0.date < $1.date }.suffix(7)) { r in
                            LineMark(x: .value("D", r.date, unit: .day), y: .value("mg/dL", r.value))
                                .foregroundStyle(Color.brandPurple).interpolationMethod(.catmullRom)
                            AreaMark(x: .value("D", r.date, unit: .day), y: .value("mg/dL", r.value))
                                .foregroundStyle(Color.brandPurple.opacity(0.1))
                            RuleMark(y: .value("Min", store.userProfile.targetGlucoseMin))
                                .foregroundStyle(Color.brandGreen.opacity(0.5)).lineStyle(StrokeStyle(dash: [4]))
                            RuleMark(y: .value("Max", store.userProfile.targetGlucoseMax))
                                .foregroundStyle(Color.brandCoral.opacity(0.5)).lineStyle(StrokeStyle(dash: [4]))
                        }
                        .frame(height: 70).chartXAxis(.hidden).chartYAxis(.hidden)
                    }
                    HStack {
                        Text("Target: \(Int(store.userProfile.targetGlucoseMin))–\(Int(store.userProfile.targetGlucoseMax)) mg/dL")
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
                    Text("No readings yet. Tap Track → Vitals to log.").font(.caption).foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - BP Card
    var bpCard: some View {
        BSCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Blood Pressure", systemImage: "heart.fill").font(.headline).foregroundColor(.brandCoral)
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
                    Text("No readings yet.").font(.caption).foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Streaks Row
    var streaksRow: some View {
        BSCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Streaks 🔥", systemImage: "flame.fill").font(.headline).foregroundColor(.brandCoral)
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
                Label("Today's Medications", systemImage: "pill.fill").font(.headline).foregroundColor(.brandPurple)
                if activeMeds.isEmpty {
                    Text("No active medications. Add them in Track → Meds.").font(.caption).foregroundColor(.secondary)
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
                Label("Active Challenges", systemImage: "flag.fill").font(.headline).foregroundColor(.brandAmber)
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

    // MARK: - Tips
    let tips = [
        "💡 Walk 10 minutes after meals to lower post-meal glucose by 15–30 mg/dL.",
        "💡 Consistent sleep times improve insulin sensitivity significantly.",
        "💡 Cutting 500mg sodium daily can lower systolic BP by 2–5 mmHg.",
        "💡 HRV above 50ms generally indicates good recovery and low stress.",
        "💡 Drinking water before meals reduces appetite and helps glucose control.",
        "💡 Logging consistently is the #1 predictor of good metabolic control.",
        "💡 Stress hormones directly raise blood glucose — practice box breathing.",
        "💡 Dark leafy greens have minimal glycaemic impact and are rich in magnesium.",
    ]
    var tipsCard: some View {
        BSCard {
            VStack(alignment: .leading, spacing: 6) {
                Label("Daily Health Tips", systemImage: "lightbulb.fill").font(.headline).foregroundColor(.brandAmber)
                Text(tips[tipIndex])
                    .font(.subheadline).foregroundColor(.secondary)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    .animation(.easeInOut, value: tipIndex)
                // Dot indicator
                HStack(spacing: 4) {
                    ForEach(0..<tips.count, id: \.self) { i in
                        Circle()
                            .fill(i == tipIndex ? Color.brandAmber : Color.brandAmber.opacity(0.25))
                            .frame(width: i == tipIndex ? 8 : 5, height: i == tipIndex ? 8 : 5)
                    }
                }
                .padding(.top, 2)
            }
        }
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
                    .shadow(color: .black.opacity(0.05), radius: 6)
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
                    .listRowBackground(alert.isRead ? Color.white : Color.brandPurple.opacity(0.04))
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
    let icon: String; let color: Color; let value: String; let label: String
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.body).foregroundColor(color)
            Text(value).font(.subheadline.bold())
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
        .background(Color.white).cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
    }
}

struct BPPill: View {
    let label: String; let value: String; let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.bold()).foregroundColor(color)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
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
