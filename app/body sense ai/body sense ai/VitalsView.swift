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
    @State private var segment: Int          // 0 = Glucose, 1 = BP
    @State private var showAdd  = false

    init(initialSegment: Int = 0) {
        _segment = State(initialValue: initialSegment)
    }

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

    @State private var showRetakePrompt = false  // For ≥160: "Take another reading after resting"
    @State private var retakeCountdown  = 0      // For ≥180: 2-min rest timer
    @State private var retakeTimer: Timer?
    @State private var isSecondReading  = false   // True when user is taking the confirmation reading
    @State private var firstReading: BPReading?   // Store the first high reading for comparison

    /// Was the previous reading (within the last 10 minutes) also elevated?
    private var isFollowUp: Bool {
        let recent = store.bpReadings.sorted { $0.date > $1.date }
        guard recent.count >= 2 else { return false }
        let prev = recent[1]
        return prev.systolic >= 130 || prev.diastolic > 80
    }

    /// Previous elevated reading for comparison
    private var previousReading: BPReading? {
        let recent = store.bpReadings.sorted { $0.date > $1.date }
        guard recent.count >= 2 else { return nil }
        let prev = recent[1]
        return (prev.systolic >= 130 || prev.diastolic > 80) ? prev : nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Input form
                    bpInputCard

                    // Crisis retake countdown (≥180: rest 2 mins, then retake)
                    if retakeCountdown > 0 {
                        crisisRestCard
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Stage 2 retake prompt (≥160: soft prompt to retake after resting)
                    if showRetakePrompt && retakeCountdown == 0 {
                        stage2RetakeCard
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Escalation banner (appears after saving a high reading)
                    if let esc = escalation, saved, !showRetakePrompt, retakeCountdown == 0 {
                        bpEscalationCard(esc)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(isSecondReading ? "Re-check Reading" : "Log Blood Pressure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { retakeTimer?.invalidate(); dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if saved && !showRetakePrompt && retakeCountdown == 0 {
                        Button("Done") { dismiss() }.fontWeight(.semibold)
                    } else if retakeCountdown == 0 && !showRetakePrompt {
                        Button("Save") { save() }
                            .disabled(!isValid)
                            .fontWeight(.semibold)
                    }
                }
            }
            .animation(.spring(duration: 0.4), value: saved)
            .animation(.spring(duration: 0.4), value: showRetakePrompt)
            .animation(.spring(duration: 0.4), value: retakeCountdown)
            .onDisappear { retakeTimer?.invalidate() }
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

    // MARK: - Stage 2 Retake Card (≥160 — soft, encouraging)

    private var stage2RetakeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "heart.text.square.fill")
                    .font(.title2).foregroundColor(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your reading is a bit high — let's double-check")
                        .font(.subheadline).fontWeight(.semibold)
                    Text("This happens sometimes, and it doesn't always mean something is wrong.")
                        .font(.caption).foregroundColor(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Before you retake, try these:")
                    .font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
                tipRow(icon: "wind", color: .blue,
                       text: "Take 5 slow, deep breaths — inhale 4s, hold 4s, exhale 6s.")
                tipRow(icon: "drop.fill", color: .cyan,
                       text: "Drink a glass of water. Dehydration can raise your BP.")
                tipRow(icon: "figure.seated", color: .green,
                       text: "Sit comfortably for a few minutes with your feet flat.")
                tipRow(icon: "cup.and.saucer.fill", color: .brown,
                       text: "Avoid caffeine or salty food for now.")
            }

            Divider()

            HStack(spacing: 8) {
                Image(systemName: "bell.badge.fill").foregroundColor(.brandPurple)
                Text("We've set reminders at 1hr, 3hr, and 5hr to check in with you.")
                    .font(.caption).foregroundColor(.secondary)
            }

            Button {
                prepareForRetake()
            } label: {
                Label("I'm ready to retake", systemImage: "arrow.counterclockwise")
                    .font(.subheadline).fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.brandPurple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.orange.opacity(0.25), lineWidth: 1)
                )
        )
    }

    // MARK: - Crisis Rest Card (≥180 — 2-minute countdown)

    private var crisisRestCard: some View {
        let minutes = retakeCountdown / 60
        let seconds = retakeCountdown % 60

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "hand.raised.fill")
                    .font(.title2).foregroundColor(.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Let's take a moment")
                        .font(.subheadline).fontWeight(.semibold)
                    Text("Your reading is quite high. This can happen after stress, exercise, or caffeine. Let's rest and check again.")
                        .font(.caption).foregroundColor(.secondary)
                }
            }

            Divider()

            // Countdown timer
            VStack(spacing: 8) {
                Text(String(format: "%d:%02d", minutes, seconds))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(.brandPurple)
                    .monospacedDigit()
                Text("Rest quietly — we'll let you know when to retake")
                    .font(.caption).foregroundColor(.secondary)

                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.brandPurple.opacity(0.15), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: CGFloat(retakeCountdown) / 120.0)
                        .stroke(Color.brandPurple, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: retakeCountdown)
                }
                .frame(width: 60, height: 60)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("While you rest:")
                    .font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
                tipRow(icon: "figure.seated", color: .green,
                       text: "Sit comfortably — uncross your legs, feet flat on the floor.")
                tipRow(icon: "wind", color: .blue,
                       text: "Breathe slowly and deeply. In through your nose, out through your mouth.")
                tipRow(icon: "hand.raised.slash.fill", color: .purple,
                       text: "Try not to talk or move around. Just relax.")
            }

            if retakeCountdown == 0 {
                Button {
                    prepareForRetake()
                } label: {
                    Label("Take second reading now", systemImage: "arrow.counterclockwise")
                        .font(.subheadline).fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.brandPurple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.red.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.red.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Escalation Card (shown after save for amber, or after second reading)

    private func bpEscalationCard(_ esc: BPEscalationResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: escalationIcon(esc.tier))
                    .font(.title2)
                    .foregroundColor(tierColor(esc.tier))
                VStack(alignment: .leading, spacing: 2) {
                    Text(isSecondReading ? secondReadingMessage(esc) : esc.message)
                        .font(.subheadline).fontWeight(.semibold)
                    Text("Reading saved")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }

            // Follow-up comparison (if this is a re-check after ≥160 or ≥180)
            if isSecondReading, let first = firstReading,
               let s = Int(systolic), let d = Int(diastolic) {
                Divider()
                followUpComparison(prev: first, newSys: s, newDia: d, tier: esc.tier)
            } else if isFollowUp, let prev = previousReading,
                      let s = Int(systolic), let d = Int(diastolic) {
                Divider()
                followUpComparison(prev: prev, newSys: s, newDia: d, tier: esc.tier)
            }

            // Tips section
            if esc.tier != .green {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Things that can help:")
                        .font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
                    tipRow(icon: "wind", color: .blue,
                           text: "Deep breathing — inhale 4s, hold 4s, exhale 6s. Repeat 4 times.")
                    tipRow(icon: "drop.fill", color: .cyan,
                           text: "Stay hydrated — water helps regulate blood pressure.")
                    tipRow(icon: "figure.walk", color: .green,
                           text: "A gentle 10-minute walk can help lower BP naturally.")
                    if esc.tier == .red || esc.tier == .critical {
                        tipRow(icon: "pills.fill", color: .orange,
                               text: "Check if you've taken your BP medication today.")
                    }
                }
            }

            // Second reading outcome advice
            if isSecondReading, let first = firstReading {
                let wasFromCrisis = first.systolic >= 180 || first.diastolic >= 110
                let stillCritical = esc.tier == .critical
                let stillDangerous = esc.tier == .red || esc.tier == .critical  // ≥160
                let cameDown = esc.tier == .green || esc.tier == .amber         // <130

                Divider()

                if cameDown && wasFromCrisis {
                    // Crisis → Normal/Elevated: great improvement, but close monitoring
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            Text("Good news — it's come down!").font(.subheadline).fontWeight(.semibold).foregroundColor(.green)
                        }
                        Text("Your BP dropped from \(first.systolic)/\(first.diastolic) to \(Int(systolic) ?? 0)/\(Int(diastolic) ?? 0). That's a real improvement. Because it was quite high earlier, we've set closer check-ins (30min, 1hr, 2hr, 4hr, 8hr) to make sure it stays down.")
                            .font(.caption).foregroundColor(.secondary)
                        Text("If it goes above 160 again, please call your GP or NHS 111 for advice.")
                            .font(.caption).foregroundColor(.orange)
                    }
                } else if cameDown {
                    // High → Normal: simple positive
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            Text("That's much better!").font(.subheadline).fontWeight(.semibold).foregroundColor(.green)
                        }
                        Text("Your BP has come down nicely. We've scheduled check-ins at 1hr, 3hr, and 5hr to keep an eye on things.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                } else if stillCritical {
                    // Still ≥180 on second reading → professional help
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your second reading is still very high")
                            .font(.subheadline).fontWeight(.semibold).foregroundColor(.red)
                        Text("Two high readings in a row means it's a good idea to speak with someone today — not to panic, just to be safe and get proper guidance.")
                            .font(.caption).foregroundColor(.secondary)

                        // NHS 111 primary (advice line), 999 secondary (emergency)
                        Button {
                            if let url = URL(string: "tel://111") { UIApplication.shared.open(url) }
                        } label: {
                            Label("Call NHS 111 for advice", systemImage: "phone.fill")
                                .font(.subheadline).fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.brandPurple)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        Text("If you have chest pain, severe headache, blurred vision, or feel faint — call 999.")
                            .font(.caption2).foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            Image(systemName: "bell.badge.fill").foregroundColor(.orange)
                            Text("We've set close check-ins at 30min, 1hr, 2hr, 4hr, and 8hr. We won't stop checking on you.")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                } else if stillDangerous && wasFromCrisis {
                    // 180 → 170 (or 160–179): dropped from crisis but STILL very high
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.heart.fill").foregroundColor(.orange)
                            Text("It's come down a bit, but still needs attention")
                                .font(.subheadline).fontWeight(.semibold)
                        }
                        Text("Your BP dropped from \(first.systolic)/\(first.diastolic) to \(Int(systolic) ?? 0)/\(Int(diastolic) ?? 0) — that's movement in the right direction. But it's still higher than we'd like, so let's keep a close eye on it.")
                            .font(.caption).foregroundColor(.secondary)

                        // GP call — stronger than "worth mentioning"
                        VStack(alignment: .leading, spacing: 4) {
                            Text("We'd recommend calling your GP today")
                                .font(.caption).fontWeight(.semibold).foregroundColor(.orange)
                            Text("Not to worry you — but because your BP was \(first.systolic)/\(first.diastolic) and is still above 160, a quick phone call to your GP practice can give you peace of mind and proper guidance.")
                                .font(.caption).foregroundColor(.secondary)
                        }

                        Button {
                            if let url = URL(string: "tel://111") { UIApplication.shared.open(url) }
                        } label: {
                            Label("Call NHS 111 for advice", systemImage: "phone.fill")
                                .font(.caption).fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.orange.opacity(0.12))
                                .foregroundColor(.orange)
                                .cornerRadius(12)
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "bell.badge.fill").foregroundColor(.orange)
                            Text("We've set close check-ins at 30min, 1hr, 2hr, 4hr, and 8hr. Please take the readings when we remind you — it really helps.")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                } else if stillDangerous {
                    // Generic stage 2 retake still high (not from crisis)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "stethoscope").foregroundColor(.orange)
                            Text("Still elevated — let's keep watching").font(.subheadline).fontWeight(.semibold)
                        }
                        Text("Your reading is still above 160 after resting. It would be a good idea to call your GP practice today for a phone consultation — they can advise you properly.")
                            .font(.caption).foregroundColor(.secondary)
                        Text("We've set check-ins at 30min, 1hr, 2hr, and 4hr.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                } else {
                    // Improved to stage 1 range (130-159) — positive but still monitoring
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.heart.fill").foregroundColor(.brandTeal)
                            Text("Improving — well done").font(.subheadline).fontWeight(.semibold).foregroundColor(.brandTeal)
                        }
                        Text("Your BP has come down from \(first.systolic)/\(first.diastolic). Still a touch elevated, so we'll keep checking in to make sure it continues settling.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
            } else if esc.shouldSuggestGP && !isSecondReading {
                Divider()
                HStack(spacing: 8) {
                    Image(systemName: "stethoscope").foregroundColor(.brandPurple)
                    Text("If readings stay high, consider chatting with your GP at your next visit.")
                        .font(.caption).foregroundColor(.secondary)
                }
            }

            // Notification reminder (only show for non-second-reading amber tier, since
            // second reading cards already include their own notification info above)
            if esc.tier != .green && !isSecondReading {
                Divider()
                HStack(spacing: 8) {
                    Image(systemName: "bell.badge.fill").foregroundColor(.brandPurple)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("We'll check in with you")
                            .font(.caption).fontWeight(.medium)
                        Text("We'll remind you to re-check — rest and hydrate in the meantime.")
                            .font(.caption2).foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(tierColor(esc.tier).opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(tierColor(esc.tier).opacity(0.25), lineWidth: 1)
                )
        )
    }

    private func escalationIcon(_ tier: BPEscalationTier) -> String {
        switch tier {
        case .green:    return "checkmark.heart.fill"
        case .amber:    return "heart.text.square.fill"
        case .red:      return "heart.fill"
        case .critical: return "exclamationmark.heart.fill"
        }
    }

    private func secondReadingMessage(_ esc: BPEscalationResponse) -> String {
        switch esc.tier {
        case .green:    return "Your BP is back to a healthy range"
        case .amber:    return "Your BP has improved — looking better"
        case .red:      return "Still a bit high, but you're doing the right thing"
        case .critical: return "Still high — let's get you some support"
        }
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

        // BP Escalation — evaluate
        let response = BPEscalationEngine.evaluate(
            systolic: s, diastolic: d,
            recentReadings: store.bpReadings
        )
        store.lastBPEscalation = response

        // ── Tiered response flow ──────────────────────────────────────────

        if isSecondReading {
            // This is the confirmation reading (after a ≥160 or ≥180 first reading)
            handleSecondReading(s: s, d: d, response: response)
            return
        }

        switch response.tier {
        case .green:
            // Normal or improved — dismiss quietly
            if isFollowUp {
                escalation = response
                saved = true
            } else {
                dismiss()
            }

        case .amber:
            // Stage 1 (130–159 / 80–89) — gentle banner + 1hr check-in
            escalation = response
            saved = true
            scheduleBPFollowUp(systolic: s, diastolic: d, intervals: [3600]) // 1hr

        case .red:
            // Stage 2 (≥160 / ≥100) — soft prompt: "Rest a few minutes, retake when ready"
            firstReading = reading
            escalation = response
            saved = true
            showRetakePrompt = true
            // Also schedule follow-up notifications at 1hr, 3hr, 5hr
            scheduleBPFollowUp(systolic: s, diastolic: d, intervals: [3600, 10800, 18000])

        case .critical:
            // Crisis (≥180 / ≥110) — rest 2 minutes, automatic countdown, then retake
            firstReading = reading
            escalation = response
            saved = true
            startCrisisRestTimer()
        }
    }

    // MARK: - Handle Second Reading (after ≥160 or ≥180 first reading)

    private func handleSecondReading(s: Int, d: Int, response: BPEscalationResponse) {
        escalation = response
        saved = true
        showRetakePrompt = false
        retakeCountdown = 0

        guard let first = firstReading else { return }

        let wasFromCrisis = first.systolic >= 180 || first.diastolic >= 110
        let backToNormal = response.tier == .green
        let stillDangerous = response.tier == .red || response.tier == .critical // ≥160 or ≥180

        if backToNormal && wasFromCrisis {
            // Crisis → Normal: great, but still needs close watch (BP can spike again)
            scheduleBPFollowUp(systolic: s, diastolic: d, intervals: [1800, 3600, 7200, 14400, 28800],
                               wasFromCrisis: true)
        } else if backToNormal {
            // High → Normal: encouraging, moderate monitoring
            scheduleBPFollowUp(systolic: s, diastolic: d, intervals: [3600, 10800, 18000])
        } else if stillDangerous && wasFromCrisis {
            // Crisis → Still ≥160: this is the "doesn't care" scenario — aggressive monitoring
            // 30min, 1hr, 2hr, 4hr, 8hr — with escalating tone
            scheduleBPFollowUp(systolic: s, diastolic: d, intervals: [1800, 3600, 7200, 14400, 28800],
                               wasFromCrisis: true)
        } else if stillDangerous {
            // Stage 2 retake still high — close monitoring
            scheduleBPFollowUp(systolic: s, diastolic: d, intervals: [1800, 3600, 7200, 14400])
        } else {
            // Improved to amber range (130-159) — standard monitoring
            scheduleBPFollowUp(systolic: s, diastolic: d, intervals: [3600, 10800, 18000])
        }
    }

    // MARK: - Crisis Rest Timer (2 minutes)

    private func startCrisisRestTimer() {
        retakeCountdown = 120 // 2 minutes in seconds
        retakeTimer?.invalidate()
        retakeTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            Task { @MainActor in
                if retakeCountdown > 0 {
                    retakeCountdown -= 1
                } else {
                    timer.invalidate()
                    prepareForRetake()
                }
            }
        }
    }

    // MARK: - Prepare for Retake

    private func prepareForRetake() {
        isSecondReading = true
        saved = false
        showRetakePrompt = false
        systolic = ""
        diastolic = ""
        pulse = ""
        notes = ""
        date = Date()
    }

    // MARK: - Schedule Follow-Up Notifications (Escalating Tone)

    private func scheduleBPFollowUp(systolic: Int, diastolic: Int,
                                     intervals: [TimeInterval],
                                     wasFromCrisis: Bool = false) {
        let center = UNUserNotificationCenter.current()

        // Clear all existing BP follow-ups so they don't stack
        center.removePendingNotificationRequests(withIdentifiers:
            (0..<10).map { "bp_followup_\($0)" })

        let totalChecks = intervals.count

        for (index, interval) in intervals.enumerated() {
            let content = UNMutableNotificationContent()
            let minutes = Int(interval / 60)
            let timeLabel = minutes < 60 ? "\(minutes) minutes" :
                            minutes == 60 ? "1 hour" : "\(minutes / 60) hours"

            // Escalating tone — gentle first, firmer later, never scary
            if index == 0 {
                // First check-in: warm and gentle
                content.title = "How are you feeling?"
                content.body = "It's been \(timeLabel) since your reading of \(systolic)/\(diastolic). Whenever you're ready, take a quick check — you're doing great by looking after yourself."
            } else if index == 1 {
                // Second: still warm, slightly more direct
                content.title = "Time for a quick BP check"
                content.body = "Taking another reading helps you see how your body is doing. Find a quiet spot, sit for a minute, then check."
            } else if index == 2 && wasFromCrisis {
                // Third (from crisis): more direct, mentions GP
                content.title = "Your BP matters — let's check in"
                content.body = "Your reading was quite high earlier. If you haven't re-checked yet, now would be a good time. If it's still above 160, it's worth calling your GP today."
            } else if index == 3 && wasFromCrisis {
                // Fourth (from crisis): firmer, clear action
                content.title = "Please check your blood pressure"
                content.body = "It's been \(timeLabel) since your high reading. If you haven't spoken to your GP or taken another reading, please do so today. Your health matters."
            } else if index >= 4 && wasFromCrisis {
                // Fifth+ (from crisis): strongest nudge without being scary
                content.title = "One more reminder about your BP"
                content.body = "We've been checking in because your reading was \(systolic)/\(diastolic) — that's higher than ideal. If it's still above 140, please speak to your GP or call NHS 111. We're here to help."
            } else {
                // Standard check-ins for non-crisis
                content.title = "Gentle BP check-in"
                content.body = "It's been \(timeLabel) since your last reading. A quick check helps you see patterns over time."
            }

            content.sound = index >= 3 && wasFromCrisis ? .defaultCritical : .default
            content.userInfo = [
                "type": "bpFollowUp",
                "previousSystolic": systolic,
                "previousDiastolic": diastolic,
                "checkNumber": index + 1,
                "totalChecks": totalChecks,
                "wasFromCrisis": wasFromCrisis
            ]

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let request = UNNotificationRequest(
                identifier: "bp_followup_\(index)",
                content: content,
                trigger: trigger
            )

            center.add(request) { error in
                if let error {
                    print("[BPFollowUp] Failed to schedule \(timeLabel): \(error.localizedDescription)")
                }
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
