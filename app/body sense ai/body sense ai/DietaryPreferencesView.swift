//
//  DietaryPreferencesView.swift
//  body sense ai
//
//  Complete dietary identity configuration — diet type, excluded meats,
//  meat schedule, allergens, intolerances, dislikes, transition goals,
//  and religious/cultural diet support.
//
//  100% private to each individual user. Stored locally via EncryptedStore.
//

import SwiftUI

struct DietaryPreferencesView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    @State private var diet: DietaryProfile = DietaryProfile()
    @State private var newIntolerance = ""
    @State private var newDislike = ""
    @State private var showSaved = false

    var body: some View {
        NavigationStack {
            Form {
                dietTypeSection
                religiousDietSection
                excludedMeatsSection
                meatScheduleSection
                allergensSection
                intolerancesSection
                dislikedFoodsSection
                transitionGoalSection
                additionalNotesSection
                summarySection
            }
            .navigationTitle("Diet & Nutrition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        save()
                    } label: {
                        Text(showSaved ? "Saved" : "Save")
                            .fontWeight(.semibold)
                    }
                    .disabled(showSaved)
                }
            }
            .onAppear {
                diet = store.userProfile.dietaryProfile
            }
        }
    }

    // MARK: - Diet Type

    private var dietTypeSection: some View {
        Section {
            Picker("Diet Type", selection: $diet.base) {
                ForEach(DietaryBase.allCases) { base in
                    VStack(alignment: .leading) {
                        Text(base.rawValue)
                    }
                    .tag(base)
                }
            }
            .pickerStyle(.navigationLink)

            if diet.base != .omnivore {
                Text(diet.base.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } header: {
            Label("What best describes your diet?", systemImage: "fork.knife")
        }
    }

    // MARK: - Religious / Cultural Diet

    @ViewBuilder
    private var religiousDietSection: some View {
        if diet.base != .vegan { // Vegans don't need religious diet section
            Section {
                Picker("Cultural/Religious Diet", selection: $diet.religiousDiet) {
                    ForEach(ReligiousDiet.allCases) { rd in
                        Text(rd.rawValue).tag(rd)
                    }
                }
                .pickerStyle(.navigationLink)
            } header: {
                Label("Cultural or Religious Diet", systemImage: "globe")
            }
        }
    }

    // MARK: - Excluded Meats

    @ViewBuilder
    private var excludedMeatsSection: some View {
        if diet.base == .omnivore || diet.base == .flexitarian || diet.base == .pescatarian {
            Section {
                ForEach(MeatType.allCases) { meat in
                    // Pescatarians already exclude all land meats
                    if diet.base == .pescatarian && meat != .fish && meat != .shellfish {
                        // Skip land meats for pescatarians — they're excluded by definition
                    } else {
                        Toggle(meat.rawValue, isOn: Binding(
                            get: { diet.excludedMeats.contains(meat) },
                            set: { isExcluded in
                                if isExcluded {
                                    diet.excludedMeats.insert(meat)
                                } else {
                                    diet.excludedMeats.remove(meat)
                                }
                            }
                        ))
                        .tint(.red)
                    }
                }
            } header: {
                Label("Excluded Meats", systemImage: "xmark.circle")
            } footer: {
                Text("Toggle ON to exclude. E.g. turn on Pork if you don't eat pork.")
            }
        }
    }

    // MARK: - Meat Schedule

    @ViewBuilder
    private var meatScheduleSection: some View {
        if diet.base == .flexitarian || (diet.base == .omnivore && diet.meatSchedule.allowedDays.count < 7) {
            Section {
                let days = [
                    (1, "Sunday"), (2, "Monday"), (3, "Tuesday"), (4, "Wednesday"),
                    (5, "Thursday"), (6, "Friday"), (7, "Saturday")
                ]
                ForEach(days, id: \.0) { dayNum, dayName in
                    Toggle(dayName, isOn: Binding(
                        get: { diet.meatSchedule.allowedDays.contains(dayNum) },
                        set: { allowed in
                            if allowed {
                                diet.meatSchedule.allowedDays.insert(dayNum)
                            } else {
                                diet.meatSchedule.allowedDays.remove(dayNum)
                            }
                        }
                    ))
                    .tint(.brandGreen)
                }

                if !diet.meatSchedule.allowedDays.isEmpty && diet.meatSchedule.allowedDays.count < 7 {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.brandPurple)
                        Text("Meat days: \(diet.meatSchedule.summaryText)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Label("Meat Schedule", systemImage: "calendar")
            } footer: {
                Text("Which days of the week do you eat meat? Turn off days you want to be meat-free.")
            }
        }
    }

    // MARK: - Allergens

    private var allergensSection: some View {
        Section {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(AllergenType.allCases) { allergen in
                    Button {
                        if diet.allergens.contains(allergen) {
                            diet.allergens.remove(allergen)
                        } else {
                            diet.allergens.insert(allergen)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: diet.allergens.contains(allergen) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(diet.allergens.contains(allergen) ? .red : .secondary)
                            Text(allergen.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(diet.allergens.contains(allergen) ? Color.red.opacity(0.1) : Color(.tertiarySystemBackground))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        } header: {
            Label("Allergies (UK 14 Major Allergens)", systemImage: "exclamationmark.triangle")
        } footer: {
            Text("Select all that apply. The AI will warn you if any food contains these allergens.")
        }
    }

    // MARK: - Intolerances

    private var intolerancesSection: some View {
        Section {
            ForEach(diet.intolerances, id: \.self) { item in
                HStack {
                    Text(item)
                    Spacer()
                    Button {
                        diet.intolerances.removeAll { $0 == item }
                    } label: {
                        Image(systemName: "minus.circle.fill").foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack {
                TextField("e.g. Lactose, Fructose", text: $newIntolerance)
                    .textInputAutocapitalization(.words)
                Button {
                    let trimmed = newIntolerance.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    diet.intolerances.append(trimmed)
                    newIntolerance = ""
                } label: {
                    Image(systemName: "plus.circle.fill").foregroundColor(.brandGreen)
                }
                .buttonStyle(.plain)
                .disabled(newIntolerance.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        } header: {
            Label("Intolerances", systemImage: "stomach")
        }
    }

    // MARK: - Disliked Foods

    private var dislikedFoodsSection: some View {
        Section {
            ForEach(diet.dislikedFoods, id: \.self) { item in
                HStack {
                    Text(item)
                    Spacer()
                    Button {
                        diet.dislikedFoods.removeAll { $0 == item }
                    } label: {
                        Image(systemName: "minus.circle.fill").foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack {
                TextField("e.g. Mushrooms, Coriander", text: $newDislike)
                    .textInputAutocapitalization(.words)
                Button {
                    let trimmed = newDislike.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    diet.dislikedFoods.append(trimmed)
                    newDislike = ""
                } label: {
                    Image(systemName: "plus.circle.fill").foregroundColor(.brandGreen)
                }
                .buttonStyle(.plain)
                .disabled(newDislike.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        } header: {
            Label("Foods You Dislike", systemImage: "hand.thumbsdown")
        }
    }

    // MARK: - Transition Goal

    private var transitionGoalSection: some View {
        Section {
            Picker("Your Goal", selection: $diet.transitionGoal) {
                ForEach(DietaryTransitionGoal.allCases) { goal in
                    Text(goal.rawValue).tag(goal)
                }
            }
            .pickerStyle(.navigationLink)
        } header: {
            Label("Dietary Goal", systemImage: "arrow.triangle.2.circlepath")
        } footer: {
            Text("Working towards a dietary change? The AI will gently guide you with alternatives.")
        }
    }

    // MARK: - Additional Notes

    private var additionalNotesSection: some View {
        Section {
            TextEditor(text: $diet.additionalNotes)
                .frame(minHeight: 60)
                .foregroundColor(.primary)
        } header: {
            Label("Additional Notes", systemImage: "note.text")
        } footer: {
            Text("Anything else the AI should know about your diet — e.g. 'I eat meat only when dining out' or 'I'm doing Ramadan fasting'.")
        }
    }

    // MARK: - Summary Preview

    @ViewBuilder
    private var summarySection: some View {
        if diet.isConfigured || diet.base != .omnivore || !diet.allergens.isEmpty {
            Section {
                Text(previewSummary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } header: {
                Label("AI Will See This", systemImage: "eye")
            }
        }
    }

    private var previewSummary: String {
        var temp = diet
        temp.isConfigured = true
        return temp.contextSummary
    }

    // MARK: - Save

    private func save() {
        diet.isConfigured = true
        store.userProfile.dietaryProfile = diet
        store.save()
        showSaved = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

#Preview {
    DietaryPreferencesView()
        .environment(HealthStore.shared)
}
