//
//  MedicineDetailView.swift
//  body sense ai
//
//  Medicine detail view and pre-populated add medication sheet
//  powered by the MedicineDatabase.
//

import SwiftUI

// MARK: - Medicine Detail View

struct MedicineDetailView: View {
    let medicine: MedicineItem
    @Binding var selectedMedicine: MedicineItem?
    @Environment(\.dismiss) var dismiss
    @State private var showAddSheet = false
    @State private var showSideEffects = false

    private var categoryColor: Color {
        Color(hex: medicine.category.color)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    quickFactsCard
                    descriptionCard

                    if !medicine.warnings.isEmpty {
                        warningsCard
                    }

                    if !medicine.sideEffects.isEmpty {
                        sideEffectsCard
                    }

                    if !medicine.interactions.isEmpty {
                        interactionsCard
                    }

                    if !medicine.foodInteractions.isEmpty {
                        foodInteractionsCard
                    }

                    addButton
                }
                .padding()
            }
            .background(Color.brandBg)
            .navigationTitle("Medicine Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddMedicationFromDBSheet(medicine: medicine)
            }
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(spacing: 14) {
            // Category icon circle
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 80, height: 80)
                Circle()
                    .fill(categoryColor.opacity(0.3))
                    .frame(width: 64, height: 64)
                Image(systemName: medicine.category.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(categoryColor)
            }

            // Generic name
            Text(medicine.genericName)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Therapeutic class
            Text(medicine.therapeuticClass)
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Category badge
            Text(medicine.category.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(categoryColor.opacity(0.15))
                .foregroundColor(categoryColor)
                .clipShape(Capsule())

            // Brand names
            if !medicine.brandNames.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Brand Names")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(medicine.brandNames, id: \.self) { brand in
                                Text(brand)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.brandPurple.opacity(0.1))
                                    )
                                    .foregroundColor(.brandPurple)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(Color.brandPurple.opacity(0.25), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.cardBg)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }

    // MARK: - Quick Facts Card

    private var quickFactsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Quick Facts", systemImage: "info.circle.fill")
                .font(.headline)
                .foregroundColor(.brandTeal)

            Divider()

            // Forms
            HStack(spacing: 6) {
                Image(systemName: "pill.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                Text("Forms:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(medicine.forms, id: \.self) { form in
                            HStack(spacing: 4) {
                                Image(systemName: form.icon)
                                    .font(.caption2)
                                Text(form.rawValue)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.brandTeal.opacity(0.1))
                            .foregroundColor(.brandTeal)
                            .cornerRadius(8)
                        }
                    }
                }
            }

            // OTC status
            HStack(spacing: 6) {
                Image(systemName: medicine.isOTC ? "checkmark.seal.fill" : "lock.fill")
                    .foregroundColor(medicine.isOTC ? .brandGreen : .brandAmber)
                    .frame(width: 24)
                Text(medicine.isOTC ? "Available Over-the-Counter" : "Prescription Required")
                    .font(.subheadline)
                    .foregroundColor(medicine.isOTC ? .brandGreen : .brandAmber)
                    .fontWeight(.medium)
            }

            // Typical dosages
            if !medicine.typicalDosages.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "scalemass.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    Text("Typical Dosages:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(medicine.typicalDosages.joined(separator: ", "))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            // Active ingredient
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "atom")
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                Text("Active Ingredient:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(medicine.activeIngredient)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            // Common frequency
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                Text("Usual Frequency:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(medicine.commonFrequency.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBg)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }

    // MARK: - Description Card

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("About", systemImage: "text.book.closed.fill")
                .font(.headline)
                .foregroundColor(.brandPurple)

            Divider()

            Text(medicine.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBg)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }

    // MARK: - Warnings Card

    private var warningsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Warnings", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundColor(.brandAmber)

            Divider()

            ForEach(medicine.warnings, id: \.self) { warning in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.brandAmber)
                        .font(.caption)
                        .padding(.top, 2)
                    Text(warning)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.brandAmber.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.brandAmber.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Side Effects Card

    private var sideEffectsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            DisclosureGroup(isExpanded: $showSideEffects) {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .padding(.top, 4)
                    ForEach(medicine.sideEffects, id: \.self) { effect in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(Color.brandCoral.opacity(0.6))
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            Text(effect)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } label: {
                Label("Side Effects (\(medicine.sideEffects.count))", systemImage: "list.bullet.clipboard.fill")
                    .font(.headline)
                    .foregroundColor(.brandCoral)
            }
            .tint(.brandCoral)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBg)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }

    // MARK: - Drug Interactions Card

    private var interactionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Drug Interactions", systemImage: "exclamationmark.2")
                .font(.headline)
                .foregroundColor(.brandCoral)

            Divider()

            ForEach(medicine.interactions, id: \.self) { interaction in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundColor(.brandCoral)
                        .font(.caption)
                        .padding(.top, 2)
                    Text(interaction)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.brandCoral.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.brandCoral.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Food Interactions Card

    private var foodInteractionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Food Interactions", systemImage: "fork.knife")
                .font(.headline)
                .foregroundColor(.brandAmber)

            Divider()

            ForEach(medicine.foodInteractions, id: \.self) { interaction in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "fork.knife")
                        .foregroundColor(.brandAmber)
                        .font(.caption)
                        .padding(.top, 2)
                    Text(interaction)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBg)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            showAddSheet = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("Add to My Medications")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.brandPurple, Color.brandPurple.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: Color.brandPurple.opacity(0.3), radius: 8, y: 4)
        }
        .padding(.top, 8)
        .padding(.bottom, 24)
    }
}

// MARK: - Add Medication From Database Sheet

struct AddMedicationFromDBSheet: View {
    let medicine: MedicineItem
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    // Pre-populated from medicine database
    @State private var name: String
    @State private var dosage: String
    @State private var unit: String
    @State private var frequency: MedFrequency
    @State private var times = Set<MedTime>()
    @State private var color = "#6C63FF"
    @State private var notes = ""
    @State private var prescriber = ""
    @State private var instructions = ""

    let units = ["mg", "mcg", "g", "mL", "IU", "tablet", "capsule"]
    let colors = ["#6C63FF", "#FF6B6B", "#4ECDC4", "#FF9F43", "#26de81", "#48dbfb", "#fd79a8"]

    init(medicine: MedicineItem) {
        self.medicine = medicine
        _name = State(initialValue: medicine.genericName)
        _dosage = State(initialValue: medicine.defaultDosage)
        _unit = State(initialValue: medicine.defaultUnit)
        _frequency = State(initialValue: medicine.commonFrequency)
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Medicine Info
                Section("Medicine Details") {
                    TextField("Name", text: $name)

                    // Dosage picker from typical dosages
                    if !medicine.typicalDosages.isEmpty {
                        Picker("Dosage", selection: $dosage) {
                            ForEach(medicine.typicalDosages, id: \.self) { d in
                                Text(d).tag(d)
                            }
                        }
                        .pickerStyle(.menu)
                    } else {
                        TextField("Dosage (e.g. 500)", text: $dosage)
                            .keyboardType(.decimalPad)
                    }

                    Picker("Unit", selection: $unit) {
                        ForEach(units, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                }

                // MARK: Frequency
                Section("Frequency") {
                    Picker("How often", selection: $frequency) {
                        ForEach(MedFrequency.allCases, id: \.self) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }

                // MARK: Time of Day
                Section("Time of Day") {
                    ForEach(MedTime.allCases, id: \.self) { t in
                        Button {
                            if times.contains(t) { times.remove(t) } else { times.insert(t) }
                        } label: {
                            HStack {
                                Image(systemName: t.icon)
                                    .foregroundColor(.brandAmber)
                                    .frame(width: 24)
                                Text(t.rawValue)
                                    .foregroundColor(.primary)
                                Spacer()
                                if times.contains(t) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.brandPurple)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                }

                // MARK: Additional Info
                Section("Additional Information") {
                    TextField("Prescriber / Doctor", text: $prescriber)
                    TextField("Instructions", text: $instructions)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                // MARK: Colour
                Section("Colour") {
                    HStack(spacing: 12) {
                        ForEach(colors, id: \.self) { c in
                            Circle()
                                .fill(Color(hex: c))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: color == c ? 3 : 0)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color(hex: c), lineWidth: color == c ? 2 : 0)
                                        .padding(1)
                                )
                                .onTapGesture { color = c }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // MARK: Warnings Preview
                if !medicine.warnings.isEmpty {
                    Section {
                        ForEach(medicine.warnings, id: \.self) { warning in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.brandAmber)
                                    .font(.caption)
                                    .padding(.top, 2)
                                Text(warning)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } header: {
                        Text("Warnings")
                    }
                }
            }
            .navigationTitle("Add \(medicine.genericName)")
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
        }
    }

    private func save() {
        let med = Medication(
            name: name,
            dosage: dosage,
            unit: unit,
            frequency: frequency,
            timeOfDay: Array(times),
            color: color,
            genericName: medicine.genericName,
            form: medicine.forms.first?.rawValue,
            notes: notes,
            prescriber: prescriber,
            instructions: instructions
        )
        store.medications.append(med)
        store.save()
        dismiss()
    }
}
