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

    // ── Today's Schedule ──
    var todayScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Schedule")
                .font(.headline).padding(.top, 8)

            if store.medications.filter({ $0.isActive }).isEmpty {
                emptyState("No medications yet", "Add your first medication below", "pill.fill")
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
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: med.color))
                        .frame(width: 36, height: 36)
                        .overlay(Image(systemName: "pill.fill").foregroundColor(.white).font(.caption))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(med.name).font(.subheadline).fontWeight(.medium)
                        Text("\(med.dosage) \(med.unit)").font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Button {
                        logMed(med, time: time)
                    } label: {
                        Image(systemName: isTaken(med, time: time) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isTaken(med, time: time) ? .brandGreen : .secondary)
                            .font(.title2)
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBg)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
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
                .overlay(Image(systemName: "pill.fill").foregroundColor(.white).font(.title3))
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
                }
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { med.isActive },
                set: { v in
                    if let idx = store.medications.firstIndex(where: { $0.id == med.id }) {
                        store.medications[idx].isActive = v
                        store.save()
                    }
                }
            ))
            .labelsHidden()
            .tint(.brandPurple)
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

    let units   = ["mg", "mcg", "g", "mL", "IU", "tablet", "capsule"]
    let colors  = ["#6C63FF","#FF6B6B","#4ECDC4","#FF9F43","#26de81","#48dbfb","#fd79a8"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication Details") {
                    TextField("Name (e.g. Metformin)", text: $name)
                    HStack {
                        TextField("Dosage (e.g. 500)", text: $dosage).keyboardType(.decimalPad)
                        Picker("Unit", selection: $unit) {
                            ForEach(units, id: \.self) { Text($0).tag($0) }
                        }.pickerStyle(.menu)
                    }
                }
                Section("Frequency") {
                    Picker("How often", selection: $frequency) {
                        ForEach(MedFrequency.allCases, id: \.self) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }.pickerStyle(.wheel).frame(height: 120)
                }
                Section("Time of Day") {
                    ForEach(MedTime.allCases, id: \.self) { t in
                        Button {
                            if times.contains(t) { times.remove(t) } else { times.insert(t) }
                        } label: {
                            HStack {
                                Image(systemName: t.icon).foregroundColor(.brandAmber).frame(width: 24)
                                Text(t.rawValue).foregroundColor(.primary)
                                Spacer()
                                if times.contains(t) {
                                    Image(systemName: "checkmark").foregroundColor(.brandPurple)
                                }
                            }
                        }
                    }
                }
                Section("Colour") {
                    HStack(spacing: 12) {
                        ForEach(colors, id: \.self) { c in
                            Circle()
                                .fill(Color(hex: c))
                                .frame(width: 30, height: 30)
                                .overlay(Circle().stroke(Color.white, lineWidth: color == c ? 3 : 0))
                                .overlay(Circle().stroke(Color(hex: c), lineWidth: color == c ? 2 : 0).padding(1))
                                .onTapGesture { color = c }
                        }
                    }
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.isEmpty || dosage.isEmpty || times.isEmpty)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    func save() {
        let med = Medication(name: name, dosage: dosage, unit: unit,
                             frequency: frequency, timeOfDay: Array(times), color: color)
        store.medications.append(med)
        store.save()
        dismiss()
    }
}
