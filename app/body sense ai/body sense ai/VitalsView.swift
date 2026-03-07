//
//  VitalsView.swift
//  body sense ai
//
//  Glucose + Blood Pressure log with add-reading sheets.
//

import SwiftUI

struct VitalsView: View {
    @Environment(HealthStore.self) var store
    @State private var segment  = 0          // 0 = Glucose, 1 = BP
    @State private var showAdd  = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segment bar
                Picker("", selection: $segment) {
                    Text("🩸 Glucose").tag(0)
                    Text("❤️ Blood Pressure").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                if segment == 0 {
                    GlucoseListView()
                } else {
                    BPListView()
                }
            }
            .background(Color.brandBg)
            .navigationTitle("Vitals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.brandPurple).font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                if segment == 0 { AddGlucoseSheet() }
                else            { AddBPSheet() }
            }
        }
    }
}

// MARK: - Glucose List

struct GlucoseListView: View {
    @Environment(HealthStore.self) var store

    var sorted: [GlucoseReading] {
        store.glucoseReadings.sorted { $0.date > $1.date }
    }

    var body: some View {
        if sorted.isEmpty {
            emptyState("No glucose readings yet", "Tap + to log your first reading", "drop.fill")
        } else {
            List {
                ForEach(sorted) { r in
                    glucoseRow(r)
                        .listRowBackground(Color.cardBg)
                        .listRowSeparator(.hidden)
                        .listRowInsets(.init(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
                .onDelete { idx in
                    let ids = idx.map { sorted[$0].id }
                    store.glucoseReadings.removeAll { ids.contains($0.id) }
                    store.save()
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.brandBg)
        }
    }

    func glucoseRow(_ r: GlucoseReading) -> some View {
        let status = store.glucoseStatus(r.value)
        return HStack(spacing: 14) {
            Circle()
                .fill(status.color.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: r.context.icon).foregroundColor(status.color))
            VStack(alignment: .leading, spacing: 2) {
                Text(r.context.rawValue).font(.subheadline).fontWeight(.semibold)
                Text(r.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(r.value))").font(.system(size: 22, weight: .bold)).foregroundColor(status.color)
                Text("mg/dL").font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.cardBg)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

// MARK: - BP List

struct BPListView: View {
    @Environment(HealthStore.self) var store

    var sorted: [BPReading] {
        store.bpReadings.sorted { $0.date > $1.date }
    }

    var body: some View {
        if sorted.isEmpty {
            emptyState("No BP readings yet", "Tap + to log your first reading", "heart.fill")
        } else {
            List {
                ForEach(sorted) { r in
                    bpRow(r)
                        .listRowBackground(Color.cardBg)
                        .listRowSeparator(.hidden)
                        .listRowInsets(.init(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
                .onDelete { idx in
                    let ids = idx.map { sorted[$0].id }
                    store.bpReadings.removeAll { ids.contains($0.id) }
                    store.save()
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.brandBg)
        }
    }

    func bpRow(_ r: BPReading) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(r.category.color.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: "heart.fill").foregroundColor(r.category.color))
            VStack(alignment: .leading, spacing: 2) {
                Text(r.category.rawValue).font(.subheadline).fontWeight(.semibold)
                Text(r.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(r.systolic)/\(r.diastolic)")
                    .font(.system(size: 20, weight: .bold)).foregroundColor(r.category.color)
                Text("❤︎ \(r.pulse) bpm").font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.cardBg)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

// MARK: - Add Glucose Sheet

struct AddGlucoseSheet: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    @State private var valueText = ""
    @State private var context   = MealContext.random
    @State private var notes     = ""
    @State private var date      = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Reading") {
                    HStack {
                        TextField("e.g. 120", text: $valueText).keyboardType(.decimalPad)
                        Text("mg/dL").foregroundColor(.secondary)
                    }
                    DatePicker("Date & Time", selection: $date)
                }
                Section("Context") {
                    Picker("When", selection: $context) {
                        ForEach(MealContext.allCases, id: \.self) { c in
                            Label(c.rawValue, systemImage: c.icon).tag(c)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }
                Section("Notes (optional)") {
                    TextField("Any notes…", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Log Glucose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(Double(valueText) == nil)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    func save() {
        guard let v = Double(valueText) else { return }
        store.glucoseReadings.append(GlucoseReading(value: v, date: date, context: context, notes: notes))
        store.save()
        dismiss()
    }
}

// MARK: - Add BP Sheet

struct AddBPSheet: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    @State private var systolic  = ""
    @State private var diastolic = ""
    @State private var pulse     = ""
    @State private var notes     = ""
    @State private var date      = Date()

    var isValid: Bool { Int(systolic) != nil && Int(diastolic) != nil && Int(pulse) != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Blood Pressure") {
                    row("Systolic",  $systolic,  "e.g. 120", "mmHg")
                    row("Diastolic", $diastolic, "e.g. 80",  "mmHg")
                    row("Pulse",     $pulse,     "e.g. 72",  "bpm")
                    DatePicker("Date & Time", selection: $date)
                }
                Section("Notes (optional)") {
                    TextField("Any notes…", text: $notes, axis: .vertical).lineLimit(3)
                }
            }
            .navigationTitle("Log Blood Pressure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    func row(_ label: String, _ binding: Binding<String>, _ placeholder: String, _ unit: String) -> some View {
        HStack {
            Text(label).frame(width: 80, alignment: .leading)
            TextField(placeholder, text: binding).keyboardType(.numberPad)
            Spacer()
            Text(unit).foregroundColor(.secondary)
        }
    }

    func save() {
        guard let s = Int(systolic), let d = Int(diastolic), let p = Int(pulse) else { return }
        store.bpReadings.append(BPReading(systolic: s, diastolic: d, pulse: p, date: date, notes: notes))
        store.save()
        dismiss()
    }
}

// MARK: - Shared empty state

func emptyState(_ title: String, _ subtitle: String, _ icon: String) -> some View {
    VStack(spacing: 16) {
        Spacer()
        Image(systemName: icon).font(.system(size: 60)).foregroundColor(.brandPurple.opacity(0.3))
        Text(title).font(.headline)
        Text(subtitle).font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
        Spacer()
    }
    .padding()
}
