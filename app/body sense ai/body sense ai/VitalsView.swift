//
//  VitalsView.swift
//  body sense ai
//
//  Glucose + Blood Pressure log with add-reading sheets.
//

import SwiftUI
import UserNotifications

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
    @State private var saved     = false

    var isValid: Bool { Int(systolic) != nil && Int(diastolic) != nil && Int(pulse) != nil }

    /// Was the previous reading (before this one) also elevated?
    private var isFollowUp: Bool {
        let recent = store.bpReadings.sorted { $0.date > $1.date }
        guard recent.count >= 2 else { return false }
        let prev = recent[1] // the one before the latest
        return prev.systolic >= 140 || prev.diastolic >= 90
    }

    /// Previous elevated reading for comparison
    private var previousReading: BPReading? {
        let recent = store.bpReadings.sorted { $0.date > $1.date }
        guard recent.count >= 2 else { return nil }
        let prev = recent[1]
        return (prev.systolic >= 140 || prev.diastolic >= 90) ? prev : nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Input form
                    bpInputCard

                    // Escalation banner (appears after saving a high reading)
                    if let esc = escalation, saved {
                        bpEscalationCard(esc)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Log Blood Pressure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if saved {
                        Button("Done") { dismiss() }.fontWeight(.semibold)
                    } else {
                        Button("Save") { save() }
                            .disabled(!isValid)
                            .fontWeight(.semibold)
                    }
                }
            }
            .animation(.spring(duration: 0.4), value: saved)
        }
    }

    // MARK: - Input Card

    private var bpInputCard: some View {
        VStack(spacing: 0) {
            Group {
                row("Systolic",  $systolic,  "e.g. 120", "mmHg")
                Divider().padding(.leading)
                row("Diastolic", $diastolic, "e.g. 80",  "mmHg")
                Divider().padding(.leading)
                row("Pulse",     $pulse,     "e.g. 72",  "bpm")
                Divider().padding(.leading)
                DatePicker("Date & Time", selection: $date)
                    .padding(.horizontal).padding(.vertical, 8)
                Divider().padding(.leading)
                HStack {
                    Text("Notes").foregroundColor(.primary)
                    TextField("Optional notes…", text: $notes, axis: .vertical)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                }
                .padding(.horizontal).padding(.vertical, 8)
            }
            .disabled(saved)
            .opacity(saved ? 0.6 : 1)
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Escalation Card

    private func bpEscalationCard(_ esc: BPEscalationResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with tier badge
            HStack(spacing: 10) {
                Image(systemName: esc.tier == .critical ? "exclamationmark.triangle.fill" :
                        esc.tier == .red ? "heart.fill" : "heart.text.square.fill")
                    .font(.title2)
                    .foregroundColor(tierColor(esc.tier))

                VStack(alignment: .leading, spacing: 2) {
                    Text(esc.message)
                        .font(.subheadline).fontWeight(.semibold)
                    Text("Reading saved successfully")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }

            Divider()

            // Follow-up comparison (if this is a re-check)
            if isFollowUp, let prev = previousReading,
               let s = Int(systolic), let d = Int(diastolic) {
                followUpComparison(prev: prev, newSys: s, newDia: d, tier: esc.tier)
                Divider()
            }

            // Quick tips
            VStack(alignment: .leading, spacing: 8) {
                Text(isFollowUp ? "Still elevated? Here's what to do:" : "Try these before re-checking:")
                    .font(.caption).fontWeight(.semibold).foregroundColor(.secondary)

                tipRow(icon: "wind", color: .blue,
                       text: "4-7-8 breathing — inhale 4s, hold 7s, exhale 8s. Repeat 4 times.")
                tipRow(icon: "drop.fill", color: .cyan,
                       text: "Drink a glass of water. Dehydration can raise BP temporarily.")
                tipRow(icon: "figure.seated", color: .green,
                       text: "Sit quietly for 5 minutes with feet flat on the floor.")

                if esc.tier == .red || esc.tier == .critical {
                    tipRow(icon: "pills.fill", color: .orange,
                           text: "Check if you've taken your BP medication today.")
                    tipRow(icon: "cup.and.saucer.fill", color: .brown,
                           text: "Avoid caffeine and salty food for the rest of the day.")
                }
            }

            // GP / emergency section
            if esc.tier == .critical {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("This reading needs medical attention")
                        .font(.caption).fontWeight(.semibold).foregroundColor(.red)
                    Text("If you have chest pain, severe headache, or vision changes:")
                        .font(.caption).foregroundColor(.secondary)
                    HStack(spacing: 12) {
                        Button {
                            if let url = URL(string: "tel://999") { UIApplication.shared.open(url) }
                        } label: {
                            Label("Call 999", systemImage: "phone.fill")
                                .font(.subheadline).fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        Button {
                            if let url = URL(string: "tel://111") { UIApplication.shared.open(url) }
                        } label: {
                            Label("NHS 111", systemImage: "phone")
                                .font(.subheadline).fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }
            } else if esc.shouldSuggestGP {
                Divider()
                HStack {
                    Image(systemName: "stethoscope").foregroundColor(.brandPurple)
                    Text("Consider booking a GP appointment to review your blood pressure.")
                        .font(.caption).foregroundColor(.secondary)
                }
            }

            // Re-check reminder
            Divider()
            HStack(spacing: 8) {
                Image(systemName: "bell.badge.fill").foregroundColor(.brandPurple)
                VStack(alignment: .leading, spacing: 2) {
                    Text("We'll remind you in 1 hour to re-check")
                        .font(.caption).fontWeight(.medium)
                    Text("Rest, hydrate, and breathe — then take another reading to see if it's improved.")
                        .font(.caption2).foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(tierColor(esc.tier).opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(tierColor(esc.tier).opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Follow-Up Comparison

    private func followUpComparison(prev: BPReading, newSys: Int, newDia: Int, tier: BPEscalationTier) -> some View {
        let sysDiff = newSys - prev.systolic
        let diaDiff = newDia - prev.diastolic
        let improved = sysDiff < 0 && diaDiff <= 0

        return VStack(alignment: .leading, spacing: 6) {
            Text("Compared to your last reading:").font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("Before").font(.caption2).foregroundColor(.secondary)
                    Text("\(prev.systolic)/\(prev.diastolic)")
                        .font(.subheadline).fontWeight(.semibold).foregroundColor(.orange)
                }
                Image(systemName: "arrow.right").foregroundColor(.secondary)
                VStack(spacing: 2) {
                    Text("Now").font(.caption2).foregroundColor(.secondary)
                    Text("\(newSys)/\(newDia)")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(improved ? .green : tierColor(tier))
                }
                Spacer()
                Text(improved ? "Improving" : sysDiff == 0 ? "Unchanged" : "Still high")
                    .font(.caption).fontWeight(.medium)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(
                        Capsule().fill(improved ? Color.green.opacity(0.12) : Color.orange.opacity(0.12))
                    )
                    .foregroundColor(improved ? .green : .orange)
            }
            if improved && tier == .green {
                Text("Your BP has come down — well done! Keep up the good habits.")
                    .font(.caption).foregroundColor(.green)
            } else if !improved && tier != .green {
                Text("Still elevated after resting. Consider speaking with your GP this week.")
                    .font(.caption).foregroundColor(.orange)
            }
        }
    }

    // MARK: - Helpers

    private func tipRow(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }

    private func tierColor(_ tier: BPEscalationTier) -> Color {
        switch tier {
        case .green:    return .green
        case .amber:    return .yellow
        case .red:      return .orange
        case .critical: return .red
        }
    }

    func row(_ label: String, _ binding: Binding<String>, _ placeholder: String, _ unit: String) -> some View {
        HStack {
            Text(label).frame(width: 80, alignment: .leading)
            TextField(placeholder, text: binding).keyboardType(.numberPad)
            Spacer()
            Text(unit).foregroundColor(.secondary)
        }
        .padding(.horizontal).padding(.vertical, 8)
    }

    func save() {
        guard let s = Int(systolic), let d = Int(diastolic), let p = Int(pulse) else { return }
        let reading = BPReading(systolic: s, diastolic: d, pulse: p, date: date, notes: notes)
        store.bpReadings.append(reading)
        store.save()

        // BP Escalation — evaluate and show inline banner for amber/red/critical
        let response = BPEscalationEngine.evaluate(
            systolic: s, diastolic: d,
            recentReadings: store.bpReadings
        )
        store.lastBPEscalation = response

        if response.tier == .green {
            // Check if this was a follow-up that improved
            if isFollowUp {
                escalation = response
                saved = true
            } else {
                dismiss()
            }
        } else {
            escalation = response
            saved = true
            // Schedule 1-hour follow-up notification
            scheduleBPFollowUpReminder(systolic: s, diastolic: d)
        }
    }

    /// Schedule a local notification in 1 hour to re-check BP
    private func scheduleBPFollowUpReminder(systolic: Int, diastolic: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Time to re-check your BP"
        content.body = "Your last reading was \(systolic)/\(diastolic). After resting and hydrating, take another reading to see if it's improved."
        content.sound = .default
        content.userInfo = ["type": "bpFollowUp", "previousSystolic": systolic, "previousDiastolic": diastolic]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
        let request = UNNotificationRequest(identifier: "bp_followup_\(UUID().uuidString)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[BPFollowUp] Failed to schedule: \(error.localizedDescription)")
            }
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
