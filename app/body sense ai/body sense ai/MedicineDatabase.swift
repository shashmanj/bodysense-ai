//
//  MedicineDatabase.swift
//  body sense ai
//
//  Global medicine database — searchable offline database of 500+ medicines
//  from around the world. Uses INN (International Nonproprietary Names) for
//  universal coverage with regional brand names for local recognition.
//

import SwiftUI

// MARK: - Medicine Item Model

struct MedicineItem: Identifiable, Codable, Equatable {
    var id = UUID()
    let genericName: String              // INN universal name (e.g. "Paracetamol")
    let brandNames: [String]             // Regional brands (e.g. ["Tylenol", "Panadol", "Calpol"])
    let category: MedicineCategory
    let therapeuticClass: String         // e.g. "Biguanide", "ACE Inhibitor"
    let activeIngredient: String         // e.g. "Metformin Hydrochloride"
    let forms: [MedicineForm]            // tablet, capsule, liquid, etc.
    let typicalDosages: [String]         // e.g. ["250mg", "500mg", "850mg", "1000mg"]
    let defaultDosage: String            // e.g. "500mg"
    let defaultUnit: String              // e.g. "mg"
    let commonFrequency: MedFrequency    // Uses existing enum
    let warnings: [String]               // e.g. ["Take with food", "Monitor kidney function"]
    let sideEffects: [String]            // e.g. ["Nausea", "Diarrhea"]
    let interactions: [String]           // Drug-drug interactions
    let foodInteractions: [String]       // Drug-food interactions
    let description: String              // 1-2 sentence plain-language description
    let isOTC: Bool                      // Over-the-counter availability

    static func == (lhs: MedicineItem, rhs: MedicineItem) -> Bool {
        lhs.genericName == rhs.genericName
    }
}

// MARK: - Medicine Category

enum MedicineCategory: String, Codable, CaseIterable {
    case painRelief       = "Pain Relief"
    case antiInflammatory = "Anti-Inflammatory"
    case antibiotics      = "Antibiotics"
    case cardiovascular   = "Cardiovascular"
    case diabetes         = "Diabetes"
    case respiratory      = "Respiratory"
    case gastrointestinal = "Gastrointestinal"
    case mentalHealth     = "Mental Health"
    case hormones         = "Hormones & Endocrine"
    case bloodThinners    = "Blood Thinners"
    case cholesterol      = "Cholesterol"
    case thyroid          = "Thyroid"
    case allergy          = "Allergy & Antihistamines"
    case vitamins         = "Vitamins & Supplements"
    case skinCare         = "Dermatological"
    case eyeEar           = "Eye & Ear"
    case musculoskeletal  = "Musculoskeletal"
    case neurological     = "Neurological"
    case urological       = "Urological"
    case immunological    = "Immunological"

    var icon: String {
        switch self {
        case .painRelief:       return "cross.case.fill"
        case .antiInflammatory: return "flame.fill"
        case .antibiotics:      return "pills.fill"
        case .cardiovascular:   return "heart.fill"
        case .diabetes:         return "drop.fill"
        case .respiratory:      return "lungs.fill"
        case .gastrointestinal: return "stomach"
        case .mentalHealth:     return "brain.head.profile"
        case .hormones:         return "waveform.path.ecg"
        case .bloodThinners:    return "drop.triangle.fill"
        case .cholesterol:      return "chart.line.downtrend.xyaxis"
        case .thyroid:          return "allergens.fill"
        case .allergy:          return "aqi.medium"
        case .vitamins:         return "leaf.fill"
        case .skinCare:         return "hand.raised.fill"
        case .eyeEar:           return "eye.fill"
        case .musculoskeletal:  return "figure.walk"
        case .neurological:     return "brain"
        case .urological:       return "kidney.fill"
        case .immunological:    return "shield.fill"
        }
    }

    var color: String {
        switch self {
        case .painRelief:       return "#FF6B6B"
        case .antiInflammatory: return "#FF9F43"
        case .antibiotics:      return "#4ECDC4"
        case .cardiovascular:   return "#E74C3C"
        case .diabetes:         return "#6C63FF"
        case .respiratory:      return "#48dbfb"
        case .gastrointestinal: return "#26de81"
        case .mentalHealth:     return "#a29bfe"
        case .hormones:         return "#fd79a8"
        case .bloodThinners:    return "#d63031"
        case .cholesterol:      return "#e17055"
        case .thyroid:          return "#00b894"
        case .allergy:          return "#fdcb6e"
        case .vitamins:         return "#55efc4"
        case .skinCare:         return "#fab1a0"
        case .eyeEar:           return "#74b9ff"
        case .musculoskeletal:  return "#636e72"
        case .neurological:     return "#6c5ce7"
        case .urological:       return "#0984e3"
        case .immunological:    return "#00cec9"
        }
    }
}

// MARK: - Medicine Form

enum MedicineForm: String, Codable, CaseIterable {
    case tablet      = "Tablet"
    case capsule     = "Capsule"
    case liquid      = "Liquid"
    case injection   = "Injection"
    case inhaler     = "Inhaler"
    case topical     = "Topical"
    case patch       = "Patch"
    case drops       = "Drops"
    case suppository = "Suppository"
    case powder      = "Powder"

    var icon: String {
        switch self {
        case .tablet:      return "pill.fill"
        case .capsule:     return "capsule.fill"
        case .liquid:      return "drop.fill"
        case .injection:   return "syringe.fill"
        case .inhaler:     return "lungs.fill"
        case .topical:     return "hand.raised.fill"
        case .patch:       return "bandage.fill"
        case .drops:       return "drop.fill"
        case .suppository: return "pill.fill"
        case .powder:      return "burst.fill"
        }
    }
}

// MARK: - Medicine Database

struct MedicineDatabase {
    static let shared = MedicineDatabase()

    let items: [MedicineItem]

    init() {
        items = MedicineDatabase.buildDatabase()
    }

    /// Multi-word search across generic name, brand names, category, therapeutic class, and active ingredient.
    /// Results are sorted with prefix matches first.
    func search(_ query: String) -> [MedicineItem] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        let words = q.split(separator: " ").map(String.init)

        return items
            .filter { item in
                let generic     = item.genericName.lowercased()
                let brands      = item.brandNames.joined(separator: " ").lowercased()
                let cat         = item.category.rawValue.lowercased()
                let therapeutic = item.therapeuticClass.lowercased()
                let active      = item.activeIngredient.lowercased()
                return words.allSatisfy { word in
                    generic.contains(word) || brands.contains(word) ||
                    cat.contains(word) || therapeutic.contains(word) ||
                    active.contains(word)
                }
            }
            .sorted { a, b in
                let aStarts = a.genericName.lowercased().hasPrefix(q)
                let bStarts = b.genericName.lowercased().hasPrefix(q)
                if aStarts != bStarts { return aStarts }
                let aBrand = a.brandNames.contains { $0.lowercased().hasPrefix(q) }
                let bBrand = b.brandNames.contains { $0.lowercased().hasPrefix(q) }
                if aBrand != bBrand { return aBrand }
                return a.genericName < b.genericName
            }
    }

    /// Look up a medicine by its INN generic name.
    func item(byGenericName name: String) -> MedicineItem? {
        items.first { $0.genericName.lowercased() == name.lowercased() }
    }

    /// Find known interactions between two medicines.
    func interactionsBetween(_ name1: String, _ name2: String) -> [String] {
        let n1 = name1.lowercased()
        let n2 = name2.lowercased()
        var result: [String] = []

        if let item1 = items.first(where: { $0.genericName.lowercased() == n1 }) {
            for interaction in item1.interactions {
                if interaction.lowercased().contains(n2) {
                    result.append(interaction)
                }
            }
        }
        if let item2 = items.first(where: { $0.genericName.lowercased() == n2 }) {
            for interaction in item2.interactions {
                if interaction.lowercased().contains(n1) && !result.contains(where: { $0.lowercased() == interaction.lowercased() }) {
                    result.append(interaction)
                }
            }
        }
        return result
    }

    /// Browse all medicines in a given category.
    func medicines(in category: MedicineCategory) -> [MedicineItem] {
        items.filter { $0.category == category }.sorted { $0.genericName < $1.genericName }
    }
}
