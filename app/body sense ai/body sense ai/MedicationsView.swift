//
//  MedicationsView.swift
//  body sense ai
//

import SwiftUI

struct MedicationsView: View {
    @Environment(HealthStore.self) var store
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    adherenceCard
                    todayScheduleSection
                    allMedsSection
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color.brandBg)
            .navigationTitle("Medications")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.brandPurple).font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showAdd) { AddMedicationSheet() }
        }
    }

    // ── Adherence Summary Card ──
    var adherenceCard: some View {
        let activeMeds = store.medications.filter { $0.isActive }
        let totalScheduled = activeMeds.reduce(0) { $0 + $1.todayScheduledCount }
        let totalTaken = activeMeds.reduce(0) { $0 + $1.todayTakenCount }
        let pct = totalScheduled > 0 ? Double(totalTaken) / Double(totalScheduled) : 0
        let streak = medicationStreak

        return Group {
            if !activeMeds.isEmpty {
                HStack(spacing: 16) {
                    // Circular progress
                    ZStack {
                        Circle()
                            .stroke(Color.brandPurple.opacity(0.15), lineWidth: 6)
                        Circle()
                            .trim(from: 0, to: pct)
                            .stroke(Color.brandPurple, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 0.5), value: pct)
                        Text("\(Int(pct * 100))%")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.brandPurple)
                    }
                    .frame(width: 52, height: 52)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Adherence")
                            .font(.subheadline).fontWeight(.semibold)
                        Text("\(totalTaken) of \(totalScheduled) doses taken")
                            .font(.caption).foregroundColor(.secondary)
                    }

                    Spacer()

                    // Streak badge
                    if streak > 0 {
                        VStack(spacing: 2) {
                            Text("\(streak)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.brandAmber)
                            Text("day streak")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.brandAmber.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color.cardBg)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
            }
        }
    }

    /// Calculate consecutive days where all scheduled doses were taken
    var medicationStreak: Int {
        let activeMeds = store.medications.filter { $0.isActive }
        guard !activeMeds.isEmpty else { return 0 }
        let cal = Calendar.current
        var streak = 0
        let _ = cal.startOfDay(for: Date())

        // Don't count today if not all taken yet
        let todayScheduled = activeMeds.reduce(0) { $0 + $1.todayScheduledCount }
        let todayTaken = activeMeds.reduce(0) { $0 + $1.todayTakenCount }
        if todayTaken >= todayScheduled && todayScheduled > 0 {
            streak += 1
        }

        // Check previous days
        for i in 1...365 {
            guard let checkDay = cal.date(byAdding: .day, value: -i, to: Date()) else { break }
            let dayStart = cal.startOfDay(for: checkDay)
            let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)!
            var allTaken = true
            for med in activeMeds {
                let dayLogs = med.logs.filter { $0.date >= dayStart && $0.date < dayEnd && $0.taken }
                if dayLogs.count < med.timeOfDay.count {
                    allTaken = false
                    break
                }
            }
            if allTaken { streak += 1 } else { break }
        }
        return streak
    }

    // ── Today's Schedule ──
    var todayScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Schedule")
                .font(.headline).padding(.top, 8)

            if store.medications.filter({ $0.isActive }).isEmpty {
                emptyState("No medications yet", "Tap + to add your first medication or search our database", "pill.fill")
                    .frame(height: 120)
            } else {
                ForEach(MedTime.allCases, id: \.self) { time in
                    let meds = store.medications.filter { $0.isActive && $0.timeOfDay.contains(time) }
                    if !meds.isEmpty {
                        timeSlotCard(time: time, meds: meds)
                    }
                }
            }
        }
    }

    func timeSlotCard(time: MedTime, meds: [Medication]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: time.icon)
                    .foregroundColor(.brandAmber)
                Text(time.rawValue).font(.subheadline).fontWeight(.semibold)
                Text("· \(timeString(time.hour))").font(.caption).foregroundColor(.secondary)
                Spacer()
            }
            Divider()
            ForEach(meds) { med in
                HStack(spacing: 12) {
                    // Pill icon with form-aware icon
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: med.color))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: medIcon(for: med))
                                .foregroundColor(.white).font(.system(size: 16))
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(med.name).font(.subheadline).fontWeight(.medium)
                        HStack(spacing: 4) {
                            Text("\(med.dosage) \(med.unit)")
                                .font(.caption).foregroundColor(.secondary)
                            if !med.instructions.isEmpty {
                                Text("· \(med.instructions)")
                                    .font(.caption).foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    Spacer()
                    // Improved checkmark — larger tap target, animated
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            logMed(med, time: time)
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(isTaken(med, time: time) ? Color.brandGreen : Color.clear)
                                .frame(width: 36, height: 36)
                            Circle()
                                .stroke(isTaken(med, time: time) ? Color.brandGreen : Color.secondary.opacity(0.4), lineWidth: 2)
                                .frame(width: 36, height: 36)
                            if isTaken(med, time: time) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(Color.cardBg)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    /// Choose icon based on medication form
    func medIcon(for med: Medication) -> String {
        if let form = med.form {
            switch form.lowercased() {
            case "tablet":      return "pill.fill"
            case "capsule":     return "capsule.fill"
            case "liquid":      return "drop.fill"
            case "injection":   return "syringe.fill"
            case "inhaler":     return "lungs.fill"
            case "topical":     return "hand.raised.fill"
            case "patch":       return "bandage.fill"
            case "drops":       return "drop.fill"
            default:            return "pill.fill"
            }
        }
        return "pill.fill"
    }

    func timeString(_ hour: Int) -> String {
        let c = Calendar.current
        let d = c.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        let f = DateFormatter(); f.timeStyle = .short
        return f.string(from: d)
    }

    func isTaken(_ med: Medication, time: MedTime) -> Bool {
        med.logs.contains { Calendar.current.isDateInToday($0.date) && $0.time == time && $0.taken }
    }

    func logMed(_ med: Medication, time: MedTime) {
        guard let idx = store.medications.firstIndex(where: { $0.id == med.id }) else { return }
        if isTaken(med, time: time) {
            store.medications[idx].logs.removeAll {
                Calendar.current.isDateInToday($0.date) && $0.time == time
            }
        } else {
            store.medications[idx].logs.append(MedLog(date: Date(), taken: true, time: time))
        }
        store.save()
    }

    // ── All Medications ──
    var allMedsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Medications").font(.headline)
            ForEach(store.medications) { med in
                medCard(med)
            }
        }
    }

    func medCard(_ med: Medication) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: med.color))
                .frame(width: 48, height: 48)
                .overlay(Image(systemName: medIcon(for: med)).foregroundColor(.white).font(.title3))
            VStack(alignment: .leading, spacing: 3) {
                Text(med.name).font(.subheadline).fontWeight(.semibold)
                Text("\(med.dosage) \(med.unit) · \(med.frequency.rawValue)")
                    .font(.caption).foregroundColor(.secondary)
                HStack(spacing: 4) {
                    ForEach(med.timeOfDay, id: \.self) { t in
                        Text(t.rawValue)
                            .font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color(hex: med.color).opacity(0.15))
                            .foregroundColor(Color(hex: med.color))
                            .cornerRadius(6)
                    }
                    if med.genericName != nil {
                        Image(systemName: "info.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.brandPurple.opacity(0.6))
                    }
                }
            }
            Spacer()
            // Improved toggle — larger, with active/paused label
            VStack(spacing: 2) {
                Toggle("", isOn: Binding(
                    get: { med.isActive },
                    set: { v in
                        if let idx = store.medications.firstIndex(where: { $0.id == med.id }) {
                            store.medications[idx].isActive = v
                            store.save()
                            NotificationService.shared.scheduleMedicationReminders(for: store.medications)
                        }
                    }
                ))
                .labelsHidden()
                .tint(.brandPurple)
                Text(med.isActive ? "Active" : "Paused")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(med.isActive ? .brandPurple : .secondary)
            }
        }
        .padding()
        .background(Color.cardBg)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

// MARK: - Add Medication Sheet

struct AddMedicationSheet: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    @State private var name      = ""
    @State private var dosage    = ""
    @State private var unit      = "mg"
    @State private var frequency = MedFrequency.daily
    @State private var times     = Set<MedTime>()
    @State private var color     = "#6C63FF"

    // Database search
    @State private var matchedMedicine: MedicineItem? = nil
    @State private var showSuggestions = false
    @State private var showMedicineInfo = false
    @FocusState private var nameFieldFocused: Bool

    let units   = ["mg", "mcg", "g", "mL", "IU", "tablet", "capsule"]
    let colors  = ["#6C63FF","#FF6B6B","#4ECDC4","#FF9F43","#26de81","#48dbfb","#fd79a8"]

    private let db = MedicineDatabase.shared

    /// Live search results as user types
    var suggestions: [MedicineItem] {
        guard name.count >= 2 else { return [] }
        return db.search(name).prefix(6).map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // ── Name field with inline search ──
                    VStack(alignment: .leading, spacing: 0) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("MEDICATION NAME")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.top, 16)

                            HStack(spacing: 10) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                    .font(.body)
                                TextField("Search medicines, brands...", text: $name)
                                    .focused($nameFieldFocused)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                                    .onChange(of: name) { _, newVal in
                                        showSuggestions = newVal.count >= 2
                                        // Clear matched medicine if name changed manually
                                        if let matched = matchedMedicine, matched.genericName.lowercased() != newVal.lowercased() {
                                            matchedMedicine = nil
                                        }
                                    }
                                if !name.isEmpty {
                                    Button {
                                        name = ""
                                        matchedMedicine = nil
                                        dosage = ""
                                        unit = "mg"
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }

                        // ── Inline suggestions dropdown ──
                        if showSuggestions && !suggestions.isEmpty && matchedMedicine == nil {
                            Divider().padding(.horizontal, 16)
                            VStack(spacing: 0) {
                                ForEach(suggestions) { med in
                                    Button {
                                        selectMedicine(med)
                                    } label: {
                                        HStack(spacing: 10) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color(hex: med.category.color).opacity(0.15))
                                                    .frame(width: 34, height: 34)
                                                Image(systemName: med.category.icon)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(Color(hex: med.category.color))
                                            }
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(med.genericName)
                                                    .font(.subheadline).fontWeight(.medium)
                                                    .foregroundColor(.primary)
                                                HStack(spacing: 4) {
                                                    Text(med.therapeuticClass)
                                                        .font(.caption2).foregroundColor(.secondary)
                                                    if !med.brandNames.isEmpty {
                                                        Text("·")
                                                            .font(.caption2).foregroundColor(.secondary)
                                                        Text(med.brandNames.prefix(2).joined(separator: ", "))
                                                            .font(.caption2).foregroundColor(.brandTeal)
                                                    }
                                                }
                                            }
                                            Spacer()
                                            if med.isOTC {
                                                Text("OTC")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 5).padding(.vertical, 2)
                                                    .background(Color.brandGreen)
                                                    .cornerRadius(4)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                    }
                                    if med.id != suggestions.last?.id {
                                        Divider().padding(.leading, 60)
                                    }
                                }
                            }
                        }

                        // ── Matched medicine info card ──
                        if let med = matchedMedicine {
                            Divider().padding(.horizontal, 16)
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(Color(hex: med.category.color).opacity(0.15))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: med.category.icon)
                                            .font(.system(size: 15))
                                            .foregroundColor(Color(hex: med.category.color))
                                    }
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(med.therapeuticClass)
                                            .font(.caption).foregroundColor(.secondary)
                                        HStack(spacing: 4) {
                                            ForEach(med.brandNames.prefix(3), id: \.self) { brand in
                                                Text(brand)
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundColor(.brandTeal)
                                                    .padding(.horizontal, 5).padding(.vertical, 2)
                                                    .background(Color.brandTeal.opacity(0.1))
                                                    .cornerRadius(4)
                                            }
                                        }
                                    }
                                    Spacer()
                                    Button {
                                        showMedicineInfo = true
                                    } label: {
                                        HStack(spacing: 3) {
                                            Image(systemName: "info.circle.fill")
                                            Text("Details")
                                        }
                                        .font(.caption).fontWeight(.medium)
                                        .foregroundColor(.brandPurple)
                                        .padding(.horizontal, 10).padding(.vertical, 6)
                                        .background(Color.brandPurple.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                }

                                // Warnings preview
                                if !med.warnings.isEmpty {
                                    HStack(spacing: 5) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.brandAmber)
                                        Text(med.warnings.first ?? "")
                                            .font(.caption2).foregroundColor(.brandAmber)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(hex: med.category.color).opacity(0.04))
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    // ── Dosage & Unit ──
                    VStack(alignment: .leading, spacing: 6) {
                        Text("DOSAGE")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)

                        HStack(spacing: 12) {
                            // Dosage field
                            HStack {
                                TextField("e.g. 500", text: $dosage)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 17, weight: .medium))
                            }
                            .padding(12)
                            .background(Color(.systemBackground))
                            .cornerRadius(10)

                            // Unit picker
                            Menu {
                                ForEach(units, id: \.self) { u in
                                    Button(u) { unit = u }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(unit)
                                        .font(.subheadline).fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 14).padding(.vertical, 12)
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                            }
                        }

                        // Quick dosage chips from database
                        if let med = matchedMedicine, med.typicalDosages.count > 1 {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(med.typicalDosages, id: \.self) { dose in
                                        Button {
                                            dosage = dose.replacingOccurrences(of: med.defaultUnit, with: "")
                                                        .replacingOccurrences(of: "mg", with: "")
                                                        .replacingOccurrences(of: "mcg", with: "")
                                                        .trimmingCharacters(in: .whitespaces)
                                        } label: {
                                            Text(dose)
                                                .font(.caption).fontWeight(.medium)
                                                .foregroundColor(dosage == dose.replacingOccurrences(of: med.defaultUnit, with: "").trimmingCharacters(in: .whitespaces) ? .white : .brandPurple)
                                                .padding(.horizontal, 12).padding(.vertical, 6)
                                                .background(dosage == dose.replacingOccurrences(of: med.defaultUnit, with: "").trimmingCharacters(in: .whitespaces) ? Color.brandPurple : Color.brandPurple.opacity(0.1))
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                    // ── Frequency ──
                    VStack(alignment: .leading, spacing: 6) {
                        Text("FREQUENCY")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(MedFrequency.allCases, id: \.self) { f in
                                    Button {
                                        frequency = f
                                    } label: {
                                        Text(f.rawValue)
                                            .font(.subheadline).fontWeight(.medium)
                                            .foregroundColor(frequency == f ? .white : .primary)
                                            .padding(.horizontal, 16).padding(.vertical, 10)
                                            .background(frequency == f ? Color.brandPurple : Color(.systemBackground))
                                            .cornerRadius(10)
                                            .shadow(color: .black.opacity(frequency == f ? 0 : 0.04), radius: 2, y: 1)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                    // ── Time of Day ──
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TIME OF DAY")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(MedTime.allCases, id: \.self) { t in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        if times.contains(t) { times.remove(t) } else { times.insert(t) }
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: t.icon)
                                            .font(.system(size: 16))
                                            .foregroundColor(times.contains(t) ? .white : .brandAmber)
                                        Text(t.rawValue)
                                            .font(.subheadline).fontWeight(.medium)
                                            .foregroundColor(times.contains(t) ? .white : .primary)
                                        Spacer()
                                        if times.contains(t) {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                                .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                    .padding(.horizontal, 14).padding(.vertical, 12)
                                    .background(times.contains(t) ? Color.brandPurple : Color(.systemBackground))
                                    .cornerRadius(10)
                                    .shadow(color: .black.opacity(times.contains(t) ? 0 : 0.04), radius: 2, y: 1)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                    // ── Colour ──
                    VStack(alignment: .leading, spacing: 6) {
                        Text("COLOUR")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)

                        HStack(spacing: 14) {
                            ForEach(colors, id: \.self) { c in
                                Circle()
                                    .fill(Color(hex: c))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: color == c ? 3 : 0)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color(hex: c).opacity(0.6), lineWidth: color == c ? 2 : 0)
                                            .padding(1)
                                    )
                                    .scaleEffect(color == c ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: color)
                                    .onTapGesture { color = c }
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                    Spacer(minLength: 30)
                }
            }
            .background(Color.brandBg)
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.isEmpty || dosage.isEmpty || times.isEmpty)
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showMedicineInfo) {
                if let med = matchedMedicine {
                    MedicineDetailView(medicine: med, selectedMedicine: .constant(nil))
                }
            }
            .onAppear { nameFieldFocused = true }
        }
    }

    func selectMedicine(_ med: MedicineItem) {
        withAnimation(.easeInOut(duration: 0.2)) {
            name = med.genericName
            matchedMedicine = med
            showSuggestions = false
            nameFieldFocused = false

            // Auto-fill dosage, unit, frequency from database
            dosage = med.defaultDosage
            unit = med.defaultUnit
            frequency = med.commonFrequency

            // Set color from category
            color = med.category.color
        }
    }

    func save() {
        let med = Medication(
            name: name,
            dosage: dosage,
            unit: unit,
            frequency: frequency,
            timeOfDay: Array(times),
            color: color,
            genericName: matchedMedicine?.genericName,
            form: matchedMedicine?.forms.first?.rawValue,
            instructions: matchedMedicine?.warnings.first ?? ""
        )
        store.medications.append(med)
        store.save()
        NotificationService.shared.scheduleMedicationReminders(for: store.medications)
        dismiss()
    }
}
