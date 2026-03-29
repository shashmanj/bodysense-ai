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
                    Text("Glucose").tag(0)
                    Text("Blood Pressure").tag(1)
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
                Text(HealthStore.glucoseMmol(r.value)).font(.title2.bold()).foregroundColor(status.color)
                Text("mmol/L").font(.caption2).foregroundColor(.secondary)
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
                    .font(.title3.bold()).foregroundColor(r.category.color)
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
                        TextField("e.g. 6.7", text: $valueText).keyboardType(.decimalPad)
                        Text("mmol/L").foregroundColor(.secondary)
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
        let mgdl = v * 18.0 // Convert mmol/L input to mg/dL for internal storage
        store.glucoseReadings.append(GlucoseReading(value: mgdl, date: date, context: context, notes: notes))
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
    @State private var escalation: BPEscalationResponse?
    @State private var showEscalation = false

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
            .alert(
                escalation?.tier == .critical ? "Critically High BP" :
                escalation?.tier == .red ? "High Blood Pressure" :
                escalation?.tier == .amber ? "Elevated Blood Pressure" : "Blood Pressure Logged",
                isPresented: $showEscalation
            ) {
                if escalation?.tier == .critical {
                    Button("Call 999", role: .destructive) {
                        if let url = URL(string: "tel://999") { UIApplication.shared.open(url) }
                    }
                    Button("Call NHS 111") {
                        if let url = URL(string: "tel://111") { UIApplication.shared.open(url) }
                    }
                    Button("I Understand") { dismiss() }
                } else {
                    Button("OK") { dismiss() }
                }
            } message: {
                if let esc = escalation {
                    Text(esc.message + "\n\n" + esc.actions.map { "• \($0)" }.joined(separator: "\n"))
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
        let reading = BPReading(systolic: s, diastolic: d, pulse: p, date: date, notes: notes)
        store.bpReadings.append(reading)
        store.save()

        // BP Escalation — evaluate and show alert for amber/red/critical
        let response = BPEscalationEngine.evaluate(
            systolic: s, diastolic: d,
            recentReadings: store.bpReadings
        )
        store.lastBPEscalation = response

        if response.tier == .green {
            dismiss()
        } else {
            escalation = response
            showEscalation = true
        }
    }
}

// MARK: - Shared empty state

func emptyState(_ title: String, _ subtitle: String, _ icon: String) -> some View {
    VStack(spacing: 16) {
        Spacer()
        Image(systemName: icon).font(.largeTitle).foregroundColor(.brandPurple.opacity(0.3))
        Text(title).font(.headline)
        Text(subtitle).font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
        Spacer()
    }
    .padding()
}
