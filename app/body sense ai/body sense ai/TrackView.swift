//
//  TrackView.swift
//  body sense ai
//
//  Comprehensive health logging hub:
//  Glucose · BP · Heart Rate · HRV · Sleep · Stress · Body Temp
//  Steps · Water · Nutrition · Symptoms · Medications · Cycle
//

import SwiftUI
import Charts

// MARK: - Track View

struct TrackView: View {
    @Environment(HealthStore.self) var store
    @State private var selectedCategory = 0

    let categories = ["Vitals", "Wellness", "Nutrition", "Meds", "Cycle"]
    let categoryIcons = ["waveform.path.ecg", "moon.stars.fill", "fork.knife.circle.fill", "pill.fill", "heart.circle.fill"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(0..<categories.count, id: \.self) { i in
                            Button {
                                withAnimation(.spring(response: 0.3)) { selectedCategory = i }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: categoryIcons[i])
                                    Text(categories[i])
                                        .fontWeight(.semibold)
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(selectedCategory == i ? Color.brandPurple : Color.white)
                                .foregroundColor(selectedCategory == i ? .white : .secondary)
                                .cornerRadius(20)
                                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .background(Color.brandBg)

                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedCategory {
                        case 0: VitalsSection()
                        case 1: WellnessSection()
                        case 2: NutritionSection()
                        case 3: MedicationsSection()
                        case 4: CycleSection()
                        default: EmptyView()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .padding(.bottom, 24)
                }
                .background(Color.brandBg)
            }
            .navigationTitle("Track")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Vitals Section

struct VitalsSection: View {
    @Environment(HealthStore.self) var store
    @State private var showAddGlucose   = false
    @State private var showAddBP        = false
    @State private var showAddHR        = false
    @State private var showAddHRV       = false
    @State private var showAddTemp      = false

    var body: some View {
        Group {
            // Glucose
            TrackCard(title: "Blood Glucose", icon: "drop.fill", color: .brandPurple, onAdd: { showAddGlucose = true }) {
                if let g = store.latestGlucose {
                    let s = store.glucoseStatus(g.value)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(Int(g.value)) mg/dL")
                                .font(.title2.bold())
                                .foregroundColor(s.color)
                            Text(g.context.rawValue)
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        StatusBadge(label: s.label, color: s.color)
                    }
                    .padding(.top, 4)
                    // Mini chart
                    if store.glucoseReadings.count > 3 {
                        Chart(store.glucoseReadings.sorted { $0.date < $1.date }.suffix(7)) { r in
                            LineMark(x: .value("Date", r.date, unit: .day), y: .value("mg/dL", r.value))
                                .foregroundStyle(Color.brandPurple)
                            AreaMark(x: .value("Date", r.date, unit: .day), y: .value("mg/dL", r.value))
                                .foregroundStyle(Color.brandPurple.opacity(0.15))
                        }
                        .frame(height: 55)
                        .chartXAxis(.hidden)
                        .chartYAxis(.hidden)
                        .padding(.top, 4)
                    }
                } else {
                    Text("No readings yet. Tap + to log.").foregroundColor(.secondary).font(.subheadline)
                }
            }
            .sheet(isPresented: $showAddGlucose) { AddGlucoseSheet() }

            // Blood Pressure
            TrackCard(title: "Blood Pressure", icon: "heart.fill", color: .brandCoral, onAdd: { showAddBP = true }) {
                if let b = store.latestBP {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(b.systolic)/\(b.diastolic)")
                                .font(.title2.bold())
                                .foregroundColor(b.category.color)
                            Text("Pulse: \(b.pulse) bpm").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        StatusBadge(label: b.category.rawValue, color: b.category.color)
                    }.padding(.top, 4)
                } else {
                    Text("No readings yet.").foregroundColor(.secondary).font(.subheadline)
                }
            }
            .sheet(isPresented: $showAddBP) { AddBPSheet() }

            // Heart Rate
            TrackCard(title: "Heart Rate", icon: "waveform.path.ecg", color: .brandCoral, onAdd: { showAddHR = true }) {
                if let hr = store.latestHR {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(hr.value) bpm").font(.title2.bold()).foregroundColor(.brandCoral)
                            Text(hr.context.rawValue).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        let zone = hr.value < 60 ? "Low" : hr.value < 100 ? "Normal" : "Elevated"
                        let zoneColor: Color = hr.value < 60 ? .brandTeal : hr.value < 100 ? .brandGreen : .brandCoral
                        StatusBadge(label: zone, color: zoneColor)
                    }.padding(.top, 4)
                    if store.heartRateReadings.count > 3 {
                        Chart(store.heartRateReadings.sorted { $0.date < $1.date }.suffix(7)) { r in
                            LineMark(x: .value("Date", r.date, unit: .day), y: .value("bpm", r.value))
                                .foregroundStyle(Color.brandCoral)
                        }
                        .frame(height: 50).chartXAxis(.hidden).chartYAxis(.hidden).padding(.top, 4)
                    }
                } else {
                    Text("No heart rate logged.").foregroundColor(.secondary).font(.subheadline)
                }
            }
            .sheet(isPresented: $showAddHR) { AddHRSheet() }

            // HRV
            TrackCard(title: "Heart Rate Variability", icon: "waveform.path", color: .brandGreen, onAdd: { showAddHRV = true }) {
                if let hrv = store.latestHRV {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(Int(hrv.value)) ms").font(.title2.bold()).foregroundColor(.brandGreen)
                            Text(hrv.date.shortTime).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        let status = hrv.value < 30 ? "Low" : hrv.value < 50 ? "Normal" : "Excellent"
                        let color: Color = hrv.value < 30 ? .brandCoral : hrv.value < 50 ? .brandAmber : .brandGreen
                        StatusBadge(label: status, color: color)
                    }.padding(.top, 4)
                } else {
                    Text("No HRV logged.").foregroundColor(.secondary).font(.subheadline)
                }
            }
            .sheet(isPresented: $showAddHRV) { AddHRVSheet() }

            // Body Temperature
            TrackCard(title: "Body Temperature", icon: "thermometer.medium", color: .brandAmber, onAdd: { showAddTemp = true }) {
                if let t = store.latestTemp {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(format: "%.1f°C", t.value)).font(.title2.bold()).foregroundColor(.brandAmber)
                            Text(t.date.shortTime).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        let status = t.value < 36 ? "Low" : t.value < 37.5 ? "Normal" : "Fever"
                        let color: Color = t.value < 36 ? .brandTeal : t.value < 37.5 ? .brandGreen : .brandCoral
                        StatusBadge(label: status, color: color)
                    }.padding(.top, 4)
                } else {
                    Text("No temperature logged.").foregroundColor(.secondary).font(.subheadline)
                }
            }
            .sheet(isPresented: $showAddTemp) { AddTempSheet() }
        }
    }
}

// MARK: - Wellness Section

struct WellnessSection: View {
    @Environment(HealthStore.self) var store
    @State private var showAddSleep   = false
    @State private var showAddStress  = false
    @State private var showAddSteps   = false
    @State private var showAddWater   = false
    @State private var showSymptoms   = false

    var body: some View {
        Group {
            // Sleep
            TrackCard(title: "Sleep", icon: "bed.double.fill", color: .brandPurple, onAdd: { showAddSleep = true }) {
                if let s = store.lastSleep {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(format: "%.1f hrs", s.duration)).font(.title2.bold()).foregroundColor(.brandPurple)
                            Text(s.quality.rawValue + " quality").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(s.quality.icon).font(.title2)
                        StatusBadge(label: s.quality.rawValue, color: s.quality.color)
                    }.padding(.top, 4)
                    HStack(spacing: 12) {
                        SleepStagePill(label: "Deep", value: s.deepSleep, color: .brandPurple)
                        SleepStagePill(label: "REM",  value: s.remSleep,  color: .brandTeal)
                        SleepStagePill(label: "Light", value: s.lightSleep, color: Color(hex: "#a29bfe"))
                    }.padding(.top, 6)
                } else {
                    Text("Log your sleep duration and quality").foregroundColor(.secondary).font(.subheadline)
                }
            }
            .sheet(isPresented: $showAddSleep) { AddSleepSheet() }

            // Stress
            TrackCard(title: "Stress Level", icon: "brain.head.profile", color: .brandAmber, onAdd: { showAddStress = true }) {
                if let s = store.latestStress {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(s.level)/10").font(.title2.bold()).foregroundColor(stressColor(s.level))
                            Text("Trigger: \(s.trigger.rawValue)").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        StressBar(level: s.level)
                    }.padding(.top, 4)
                } else {
                    Text("How stressed are you today?").foregroundColor(.secondary).font(.subheadline)
                }
            }
            .sheet(isPresented: $showAddStress) { AddStressSheet() }

            // Steps
            TrackCard(title: "Steps Today", icon: "figure.walk", color: .brandTeal, onAdd: { showAddSteps = true }) {
                let steps = store.todaySteps
                let target = store.userProfile.targetSteps
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(steps)").font(.title2.bold()).foregroundColor(.brandTeal)
                        Text("Goal: \(target) steps").font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    ZStack {
                        Circle().stroke(Color.brandTeal.opacity(0.2), lineWidth: 6)
                        Circle().trim(from: 0, to: min(Double(steps) / Double(target), 1))
                            .stroke(Color.brandTeal, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(Int(min(Double(steps) / Double(target), 1) * 100))%")
                            .font(.caption2.bold()).foregroundColor(.brandTeal)
                    }
                    .frame(width: 52, height: 52)
                }.padding(.top, 4)
            }
            .sheet(isPresented: $showAddSteps) { AddStepsSheet() }

            // Water
            TrackCard(title: "Water Intake", icon: "drop.circle.fill", color: Color(hex: "#4fc3f7"), onAdd: { showAddWater = true }) {
                let ml = store.todayWaterML
                let target = store.userProfile.targetWater * 1000
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(format: "%.1f L", ml / 1000)).font(.title2.bold()).foregroundColor(Color(hex: "#4fc3f7"))
                        Text("Target: \(String(format: "%.1f L", target / 1000))").font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        ForEach(0..<8, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Double(i) * (target/8) < ml ? Color(hex: "#4fc3f7") : Color(hex: "#4fc3f7").opacity(0.2))
                                .frame(width: 14, height: 30)
                        }
                    }
                }.padding(.top, 4)
            }
            .sheet(isPresented: $showAddWater) { AddWaterSheet() }

            // Symptoms
            TrackCard(title: "Symptom Log", icon: "stethoscope", color: .brandCoral, onAdd: { showSymptoms = true }) {
                if let log = store.symptomLogs.sorted(by: { $0.date > $1.date }).first {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(log.symptoms.prefix(3).joined(separator: ", ")).font(.subheadline)
                            Text(log.severity.rawValue + " · " + log.date.shortTime).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        StatusBadge(label: log.severity.rawValue, color: log.severity.color)
                    }.padding(.top, 4)
                } else {
                    Text("Track symptoms like fatigue, headache, dizziness").foregroundColor(.secondary).font(.subheadline)
                }
            }
            .sheet(isPresented: $showSymptoms) { AddSymptomSheet() }
        }
    }

    func stressColor(_ level: Int) -> Color {
        level <= 3 ? .brandGreen : level <= 6 ? .brandAmber : .brandCoral
    }
}

// MARK: - Nutrition Section

struct NutritionSection: View {
    @Environment(HealthStore.self) var store
    @State private var showAdd        = false
    @State private var showFoodSearch = false

    var todayLogs: [NutritionLog] {
        let cal = Calendar.current
        return store.nutritionLogs.filter { cal.isDateInToday($0.date) }
    }

    var body: some View {
        Group {
            // ── Daily macro dashboard (rings) ──
            NutritionDashboardView()

            // ── Action buttons row ──
            HStack(spacing: 10) {
                Button {
                    showFoodSearch = true
                } label: {
                    Label("Search Food", systemImage: "magnifyingglass")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.brandPurple.opacity(0.1))
                        .foregroundColor(.brandPurple)
                        .cornerRadius(14)
                }

                Button {
                    showAdd = true
                } label: {
                    Label("Log Meal", systemImage: "plus")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.brandTeal.opacity(0.1))
                        .foregroundColor(.brandTeal)
                        .cornerRadius(14)
                }
            }
            .padding(.horizontal)

            // Meal cards
            ForEach(MealType.allCases, id: \.self) { type in
                let meals = todayLogs.filter { $0.mealType == type }
                BSCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: type.icon).foregroundColor(type.color)
                            Text(type.rawValue).font(.headline)
                            Spacer()
                            if meals.isEmpty {
                                Button { showAdd = true } label: {
                                    Text("+ Log").font(.caption).foregroundColor(.brandPurple)
                                }
                            }
                        }
                        if meals.isEmpty {
                            Text("Not logged yet").font(.caption).foregroundColor(.secondary)
                        } else {
                            ForEach(meals) { m in
                                HStack {
                                    Text(m.foodName.isEmpty ? "Meal" : m.foodName).font(.subheadline)
                                    Spacer()
                                    Text("\(m.calories) kcal").font(.caption).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddNutritionSheet() }
        .sheet(isPresented: $showFoodSearch) { FoodSearchView() }
    }
}

// MARK: - Medications Section (re-export)

struct MedicationsSection: View {
    var body: some View { MedicationsView() }
}

// MARK: - Cycle Section

struct CycleSection: View {
    @Environment(HealthStore.self) var store
    @State private var showAdd = false

    var body: some View {
        Group {
            BSCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Cycle Tracker", systemImage: "heart.circle.fill")
                            .font(.headline).foregroundColor(Color(hex: "#fd79a8"))
                        Spacer()
                        Button { showAdd = true } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3).foregroundColor(Color(hex: "#fd79a8"))
                        }
                    }

                    if let latest = store.cycles.sorted(by: { $0.startDate > $1.startDate }).first {
                        let days = Calendar.current.dateComponents([.day], from: latest.startDate, to: Date()).day ?? 0
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Day \(days + 1) of cycle").font(.title2.bold()).foregroundColor(Color(hex: "#fd79a8"))
                                Text("Flow: \(latest.flow.rawValue)").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Started").font(.caption2).foregroundColor(.secondary)
                                Text(latest.startDate, style: .date).font(.caption.bold())
                            }
                        }
                        if !latest.symptoms.isEmpty {
                            HStack {
                                ForEach(latest.symptoms.prefix(3), id: \.self) { sym in
                                    Text(sym).font(.caption)
                                        .padding(.horizontal, 10).padding(.vertical, 4)
                                        .background(Color(hex: "#fd79a8").opacity(0.15))
                                        .foregroundColor(Color(hex: "#fd79a8"))
                                        .cornerRadius(10)
                                }
                            }
                        }
                    } else {
                        Text("Track your menstrual cycle to understand how it affects your glucose and energy levels.")
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                }
            }

            // Phase information card
            BSCard {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Cycle & Glucose Insights", systemImage: "lightbulb.fill").font(.headline).foregroundColor(.brandAmber)
                    CyclePhaseRow(phase: "Week 1–2 (Follicular)", effect: "↓ Insulin resistance · Glucose tends lower", color: .brandGreen)
                    CyclePhaseRow(phase: "Week 3–4 (Luteal)", effect: "↑ Progesterone · Glucose may run higher", color: .brandAmber)
                    CyclePhaseRow(phase: "During period", effect: "Pain & stress can spike glucose", color: .brandCoral)
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddCycleSheet() }
    }
}

// MARK: - Add Sheets

struct AddHRSheet: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var bpm = "72"
    @State private var context: HRContext = .rest
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Heart Rate") {
                    HStack {
                        TextField("BPM", text: $bpm).keyboardType(.numberPad)
                        Text("bpm").foregroundColor(.secondary)
                    }
                    Picker("Context", selection: $context) {
                        ForEach(HRContext.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    DatePicker("When", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("Log Heart Rate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let v = Int(bpm) {
                            store.heartRateReadings.append(HeartRateReading(value: v, date: date, context: context))
                            store.save(); dismiss()
                        }
                    }.disabled(Int(bpm) == nil)
                }
            }
        }
    }
}

struct AddHRVSheet: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var ms = "42"
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("HRV Reading") {
                    HStack {
                        TextField("ms", text: $ms).keyboardType(.decimalPad)
                        Text("ms").foregroundColor(.secondary)
                    }
                    DatePicker("When", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                Section("What is HRV?") {
                    Text("Heart Rate Variability measures the variation in time between heartbeats. Higher HRV generally indicates better recovery and stress resilience.")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .navigationTitle("Log HRV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let v = Double(ms) {
                            store.hrvReadings.append(HRVReading(value: v, date: date))
                            store.save(); dismiss()
                        }
                    }
                }
            }
        }
    }
}

struct AddSleepSheet: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var hours = 7.0
    @State private var quality: SleepQuality = .good
    @State private var deep = 1.5
    @State private var rem  = 1.8
    @State private var awakenings = 1
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Sleep Duration") {
                    VStack(alignment: .leading) {
                        Text(String(format: "%.1f hours", hours)).font(.headline)
                        Slider(value: $hours, in: 2...12, step: 0.5)
                            .tint(.brandPurple)
                    }
                    Picker("Quality", selection: $quality) {
                        ForEach(SleepQuality.allCases, id: \.self) { q in
                            Text("\(q.icon) \(q.rawValue)").tag(q)
                        }
                    }
                    DatePicker("Night of", selection: $date, displayedComponents: .date)
                }
                Section("Sleep Stages (optional)") {
                    VStack(alignment: .leading) {
                        Text("Deep sleep: \(String(format: "%.1f", deep)) hrs")
                        Slider(value: $deep, in: 0...4, step: 0.1).tint(.brandPurple)
                    }
                    VStack(alignment: .leading) {
                        Text("REM sleep: \(String(format: "%.1f", rem)) hrs")
                        Slider(value: $rem, in: 0...4, step: 0.1).tint(.brandTeal)
                    }
                    Stepper("Awakenings: \(awakenings)", value: $awakenings, in: 0...20)
                }
            }
            .navigationTitle("Log Sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.sleepEntries.append(SleepEntry(date: date, duration: hours, quality: quality, deepSleep: deep, remSleep: rem, lightSleep: max(0, hours - deep - rem), awakenings: awakenings))
                        store.save(); dismiss()
                    }
                }
            }
        }
    }
}

struct AddStressSheet: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var level: Double = 5
    @State private var trigger: StressTrigger = .other
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Stress Level") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Level: \(Int(level))/10").font(.headline)
                            Spacer()
                            Text(Int(level) <= 3 ? "😌 Low" : Int(level) <= 6 ? "😐 Moderate" : "😰 High")
                        }
                        Slider(value: $level, in: 1...10, step: 1)
                            .tint(Int(level) <= 3 ? .brandGreen : Int(level) <= 6 ? .brandAmber : .brandCoral)
                    }
                    Picker("Main Trigger", selection: $trigger) {
                        ForEach(StressTrigger.allCases, id: \.self) { t in
                            Label(t.rawValue, systemImage: t.icon).tag(t)
                        }
                    }
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle("Log Stress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.stressReadings.append(StressReading(level: Int(level), date: Date(), trigger: trigger, notes: notes))
                        store.save(); dismiss()
                    }
                }
            }
        }
    }
}

struct AddTempSheet: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var temp = "36.6"
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Body Temperature") {
                    HStack {
                        TextField("°C", text: $temp).keyboardType(.decimalPad)
                        Text("°C").foregroundColor(.secondary)
                    }
                    DatePicker("When", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("Log Temperature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let v = Double(temp) {
                            store.bodyTempReadings.append(BodyTempReading(value: v, date: date))
                            store.save(); dismiss()
                        }
                    }
                }
            }
        }
    }
}

struct AddStepsSheet: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var steps = "7500"
    @State private var distance = "5.8"
    @State private var calories = "280"

    var body: some View {
        NavigationStack {
            Form {
                Section("Today's Activity") {
                    HStack { TextField("Steps", text: $steps).keyboardType(.numberPad); Text("steps").foregroundColor(.secondary) }
                    HStack { TextField("Distance", text: $distance).keyboardType(.decimalPad); Text("km").foregroundColor(.secondary) }
                    HStack { TextField("Calories", text: $calories).keyboardType(.numberPad); Text("kcal").foregroundColor(.secondary) }
                }
            }
            .navigationTitle("Log Steps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let s = Int(steps) {
                            store.stepEntries.append(StepEntry(date: Date(), steps: s, distance: Double(distance) ?? 0, calories: Int(calories) ?? 0, activeMinutes: s / 100))
                            store.save(); dismiss()
                        }
                    }
                }
            }
        }
    }
}

struct AddWaterSheet: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var amount: Double = 250

    struct WaterPreset: Identifiable {
        let id = UUID()
        let label: String
        let ml: Double
    }
    let presets: [WaterPreset] = [
        WaterPreset(label: "Glass\n250ml",   ml: 250),
        WaterPreset(label: "Bottle\n500ml",  ml: 500),
        WaterPreset(label: "1 Litre",        ml: 1000),
        WaterPreset(label: "1.5 Litres",     ml: 1500),
        WaterPreset(label: "2 Litres",       ml: 2000),
    ]

    // Total water logged today (including this new entry)
    var todayTotal: Double {
        store.waterEntries
            .filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.amount }
        + amount
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Quick Add") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()),
                                        GridItem(.flexible())], spacing: 10) {
                        ForEach(presets) { preset in
                            Button {
                                amount = preset.ml
                            } label: {
                                Text(preset.label)
                                    .font(.caption).multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(amount == preset.ml ? Color(hex: "#4fc3f7") : Color(hex: "#4fc3f7").opacity(0.12))
                                    .foregroundColor(amount == preset.ml ? .white : Color(hex: "#4fc3f7"))
                                    .cornerRadius(10)
                            }
                        }
                    }
                }

                Section("Custom Amount") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Amount:")
                            Spacer()
                            Text("\(Int(amount)) ml  (\(String(format: "%.2f", amount / 1000)) L)")
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "#4fc3f7"))
                        }
                        Slider(value: $amount, in: 50...4000, step: 50)
                            .tint(Color(hex: "#4fc3f7"))
                        HStack {
                            Text("50 ml").font(.caption2).foregroundColor(.secondary)
                            Spacer()
                            Text("4 L max").font(.caption2).foregroundColor(.secondary)
                        }
                    }
                }

                // Electrolyte warning when > 3L
                if todayTotal > 3000 {
                    Section {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.brandAmber)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Electrolyte Warning")
                                    .font(.caption.bold())
                                    .foregroundColor(.brandAmber)
                                Text("Drinking excessive water can flush out important electrolytes like sodium and potassium. Make sure you're getting adequate minerals from food or electrolyte drinks.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Log Water")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.waterEntries.append(WaterEntry(date: Date(), amount: amount))
                        store.save(); dismiss()
                    }
                }
            }
        }
    }
}

struct AddSymptomSheet: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var selected: Set<String> = []
    @State private var severity: SymptomSeverity = .mild
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Symptoms") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(allSymptoms, id: \.self) { sym in
                            Button {
                                if selected.contains(sym) { selected.remove(sym) } else { selected.insert(sym) }
                            } label: {
                                Text(sym).font(.caption).multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity).padding(8)
                                    .background(selected.contains(sym) ? Color.brandCoral : Color.brandCoral.opacity(0.1))
                                    .foregroundColor(selected.contains(sym) ? .white : .brandCoral)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                Section("Severity") {
                    Picker("Severity", selection: $severity) {
                        ForEach(SymptomSeverity.allCases, id: \.self) { s in Text(s.rawValue).tag(s) }
                    }.pickerStyle(.segmented)
                }
                Section {
                    TextField("Notes", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle("Log Symptoms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !selected.isEmpty else { return }
                        store.symptomLogs.append(SymptomLog(date: Date(), symptoms: Array(selected), severity: severity, notes: notes))
                        store.save(); dismiss()
                    }.disabled(selected.isEmpty)
                }
            }
        }
    }
}

struct AddNutritionSheet: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var mealType: MealType = .breakfast
    @State private var foodName = ""
    @State private var calories = ""
    @State private var carbs    = ""
    @State private var protein  = ""
    @State private var fat      = ""
    @State private var fiber    = ""
    @State private var sugar    = ""
    @State private var salt     = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Meal", selection: $mealType) {
                        ForEach(MealType.allCases, id: \.self) { t in
                            Label(t.rawValue, systemImage: t.icon).tag(t)
                        }
                    }
                    TextField("Food name (optional)", text: $foodName)
                }
                Section("Macros") {
                    HStack { TextField("Calories", text: $calories).keyboardType(.numberPad); Text("kcal").foregroundColor(.secondary) }
                    HStack { TextField("Carbohydrates", text: $carbs).keyboardType(.decimalPad); Text("g").foregroundColor(.secondary) }
                    HStack { TextField("Protein", text: $protein).keyboardType(.decimalPad); Text("g").foregroundColor(.secondary) }
                    HStack { TextField("Fat", text: $fat).keyboardType(.decimalPad); Text("g").foregroundColor(.secondary) }
                }
                Section("More Nutrients (Optional)") {
                    HStack { TextField("Fibre", text: $fiber).keyboardType(.decimalPad); Text("g").foregroundColor(.secondary) }
                    HStack { TextField("Sugar", text: $sugar).keyboardType(.decimalPad); Text("g").foregroundColor(.secondary) }
                    HStack { TextField("Salt / Sodium", text: $salt).keyboardType(.decimalPad); Text("g").foregroundColor(.secondary) }
                }
            }
            .navigationTitle("Log Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.nutritionLogs.append(NutritionLog(
                            date: Date(), mealType: mealType,
                            calories: Int(calories) ?? 0,
                            carbs:    Double(carbs) ?? 0,
                            protein:  Double(protein) ?? 0,
                            fat:      Double(fat) ?? 0,
                            fiber:    Double(fiber) ?? 0,
                            sugar:    Double(sugar) ?? 0,
                            salt:     Double(salt) ?? 0,
                            foodName: foodName))
                        store.save(); dismiss()
                    }
                }
            }
        }
    }
}

struct AddCycleSheet: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var startDate = Date()
    @State private var flow: FlowLevel = .medium
    @State private var selectedSymptoms: Set<String> = []

    let cycleSymptoms = ["Cramps", "Bloating", "Fatigue", "Mood Swings", "Headache", "Back Pain", "Breast Tenderness", "Nausea", "Food Cravings", "Insomnia"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    Picker("Flow", selection: $flow) {
                        ForEach(FlowLevel.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)
                }
                Section("Symptoms") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(cycleSymptoms, id: \.self) { sym in
                            Button {
                                if selectedSymptoms.contains(sym) { selectedSymptoms.remove(sym) } else { selectedSymptoms.insert(sym) }
                            } label: {
                                Text(sym).font(.caption).frame(maxWidth: .infinity).padding(8)
                                    .background(selectedSymptoms.contains(sym) ? Color(hex: "#fd79a8") : Color(hex: "#fd79a8").opacity(0.1))
                                    .foregroundColor(selectedSymptoms.contains(sym) ? .white : Color(hex: "#fd79a8"))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Log Cycle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.cycles.append(CycleEntry(startDate: startDate, flow: flow, symptoms: Array(selectedSymptoms)))
                        store.save(); dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Reusable Components

struct TrackCard<Content: View>: View {
    let title  : String
    let icon   : String
    let color  : Color
    let onAdd  : () -> Void
    let content: Content

    init(title: String, icon: String, color: Color, onAdd: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.title = title; self.icon = icon; self.color = color; self.onAdd = onAdd; self.content = content()
    }

    var body: some View {
        BSCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(title, systemImage: icon).font(.headline).foregroundColor(color)
                    Spacer()
                    Button(action: onAdd) {
                        Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(color)
                    }
                }
                content
            }
        }
    }
}

struct StatusBadge: View {
    let label: String
    let color: Color
    var body: some View {
        Text(label).font(.caption.bold()).padding(.horizontal, 10).padding(.vertical, 4)
            .background(color.opacity(0.15)).foregroundColor(color).cornerRadius(10)
    }
}

struct SleepStagePill: View {
    let label: String; let value: Double; let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text(String(format: "%.1fh", value)).font(.caption.bold()).foregroundColor(color)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct StressBar: View {
    let level: Int
    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...10, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i <= level ? stressColor(level) : Color.gray.opacity(0.2))
                    .frame(width: 8, height: i <= level ? 20 : 12)
            }
        }
    }
    func stressColor(_ l: Int) -> Color { l <= 3 ? .brandGreen : l <= 6 ? .brandAmber : .brandCoral }
}

struct NutrientPill: View {
    let label: String; let value: String; let unit: String; let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline.bold()).foregroundColor(color)
            Text(unit).font(.caption2).foregroundColor(.secondary)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct CyclePhaseRow: View {
    let phase: String; let effect: String; let color: Color
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle().fill(color).frame(width: 8, height: 8).padding(.top, 5)
            VStack(alignment: .leading, spacing: 2) {
                Text(phase).font(.caption.bold())
                Text(effect).font(.caption).foregroundColor(.secondary)
            }
        }
    }
}

struct BSCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}

// Re-export AddGlucoseSheet and AddBPSheet from VitalsView
extension Date {
    var shortTime: String {
        let f = DateFormatter()
        f.timeStyle = .short; f.dateStyle = .none
        return f.string(from: self)
    }
}
