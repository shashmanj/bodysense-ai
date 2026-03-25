//
//  HealthModels.swift
//  body sense ai
//
//  All data models and shared HealthStore for BodySense AI.
//  Comprehensive health companion — glucose, BP, HR, HRV, sleep, stress,
//  symptoms, nutrition, steps, goals, challenges, achievements, community,
//  telemedicine, shop, and subscription.
//

import SwiftUI
import Foundation
import UserNotifications

// MARK: - Appearance Mode

enum AppearanceMode: String, CaseIterable {
    case system  = "System"
    case light   = "Light"
    case dark    = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }
}

// MARK: - Brand Colors

extension Color {
    static let brandPurple  = Color(hex: "#6C63FF")
    static let brandTeal    = Color(hex: "#4ECDC4")
    static let brandCoral   = Color(hex: "#FF6B6B")
    static let brandAmber   = Color(hex: "#FF9F43")
    static let brandGreen   = Color(hex: "#26de81")
    static let brandBg      = Color(.systemGroupedBackground)
    static let cardBg       = Color(.secondarySystemGroupedBackground)

    /// Adaptive text color that works on both light and dark backgrounds
    static let adaptiveText = Color(.label)
    /// Subtle card border for dark mode visibility
    static let cardBorder   = Color(.separator)

    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch h.count {
        case 3: (a,r,g,b) = (255,(int>>8)*17,(int>>4 & 0xF)*17,(int & 0xF)*17)
        case 6: (a,r,g,b) = (255,int>>16,int>>8 & 0xFF,int & 0xFF)
        case 8: (a,r,g,b) = (int>>24,int>>16 & 0xFF,int>>8 & 0xFF,int & 0xFF)
        default:(a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Input Validation

enum InputValidator {
    static func isValidGMC(_ number: String) -> Bool {
        let trimmed = number.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count == 7 else { return false }
        guard let first = trimmed.first, first.isNumber, first != "0" else { return false }
        return trimmed.allSatisfy { $0.isNumber }
    }

    static func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    static func isValidGlucose(_ mgdl: Double) -> Bool { (20...600).contains(mgdl) }
    static func isValidBP(systolic: Int, diastolic: Int) -> Bool {
        (60...300).contains(systolic) && (30...200).contains(diastolic) && systolic > diastolic
    }
    static func isValidHeartRate(_ bpm: Int) -> Bool { (20...300).contains(bpm) }
    static func isValidHRV(_ ms: Double) -> Bool { (1...500).contains(ms) }
    static func isValidBodyTemp(_ celsius: Double) -> Bool { (30...45).contains(celsius) }
    static func isValidGroupName(_ name: String) -> Bool {
        let t = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.count >= 3 && t.count <= 50
    }
    static func isValidPostContent(_ content: String) -> Bool {
        let t = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.count >= 1 && t.count <= 2000
    }
}

// MARK: - Glucose

struct GlucoseReading: Codable, Identifiable, Equatable {
    var id      = UUID()
    var value   : Double
    var date    : Date
    var context : MealContext
    var notes   : String = ""
}

enum MealContext: String, Codable, CaseIterable {
    case fasting    = "Fasting"
    case beforeMeal = "Before Meal"
    case afterMeal  = "After Meal"
    case bedtime    = "Bedtime"
    case random     = "Random"
    var icon: String {
        switch self {
        case .fasting:    return "moon.stars"
        case .beforeMeal: return "fork.knife.circle"
        case .afterMeal:  return "fork.knife.circle.fill"
        case .bedtime:    return "bed.double"
        case .random:     return "clock"
        }
    }
}

// MARK: - Blood Pressure

struct BPReading: Codable, Identifiable, Equatable {
    var id        = UUID()
    var systolic  : Int
    var diastolic : Int
    var pulse     : Int
    var date      : Date
    var notes     : String = ""

    var category: BPCategory {
        if systolic < 120 && diastolic < 80 { return .normal }
        if systolic < 130 && diastolic < 80 { return .elevated }
        if systolic < 140 || diastolic < 90 { return .high1 }
        return .high2
    }
}

enum BPCategory: String {
    case normal   = "Normal"
    case elevated = "Elevated"
    case high1    = "High (Stage 1)"
    case high2    = "High (Stage 2)"
    var color: Color {
        switch self {
        case .normal:   return .brandGreen
        case .elevated: return .brandAmber
        case .high1:    return .orange
        case .high2:    return .brandCoral
        }
    }
}

// MARK: - Heart Rate

struct HeartRateReading: Codable, Identifiable, Equatable {
    var id      = UUID()
    var value   : Int       // bpm
    var date    : Date
    var context : HRContext = .rest
    var notes   : String = ""
}

enum HRContext: String, Codable, CaseIterable {
    case rest          = "Resting"
    case active        = "Active"
    case postExercise  = "Post-Exercise"
    case sleep         = "Sleep"
    var icon: String {
        switch self {
        case .rest:         return "heart.fill"
        case .active:       return "figure.run"
        case .postExercise: return "figure.highintensity.intervaltraining"
        case .sleep:        return "bed.double.fill"
        }
    }
}

// MARK: - HRV

struct HRVReading: Codable, Identifiable, Equatable {
    var id    = UUID()
    var value : Double  // ms
    var date  : Date
}

// MARK: - Sleep

struct SleepEntry: Codable, Identifiable, Equatable {
    var id         = UUID()
    var date       : Date
    var duration   : Double   // total hours
    var quality    : SleepQuality
    var deepSleep  : Double = 0
    var remSleep   : Double = 0
    var lightSleep : Double = 0
    var awakenings : Int    = 0
    var notes      : String = ""
}

enum SleepQuality: String, Codable, CaseIterable {
    case poor      = "Poor"
    case fair      = "Fair"
    case good      = "Good"
    case excellent = "Excellent"

    var color: Color {
        switch self {
        case .poor:      return .brandCoral
        case .fair:      return .brandAmber
        case .good:      return .brandTeal
        case .excellent: return .brandGreen
        }
    }
    var score: Int {
        switch self {
        case .poor: return 25; case .fair: return 50; case .good: return 75; case .excellent: return 100
        }
    }
    var icon: String {
        switch self {
        case .poor: return "moon.zzz"; case .fair: return "minus.circle"; case .good: return "checkmark.circle"; case .excellent: return "star.fill"
        }
    }
}

// MARK: - Stress

struct StressReading: Codable, Identifiable, Equatable {
    var id      = UUID()
    var level   : Int  // 1–10
    var date    : Date
    var trigger : StressTrigger = .other
    var notes   : String = ""
}

enum StressTrigger: String, Codable, CaseIterable {
    case work       = "Work"
    case personal   = "Personal"
    case health     = "Health"
    case financial  = "Financial"
    case sleep      = "Poor Sleep"
    case other      = "Other"
    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .personal: return "person.2.fill"
        case .health: return "cross.fill"
        case .financial: return "dollarsign.circle.fill"
        case .sleep: return "bed.double.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Body Temperature

struct BodyTempReading: Codable, Identifiable, Equatable {
    var id    = UUID()
    var value : Double  // Celsius
    var date  : Date
}

// MARK: - Steps

struct StepEntry: Codable, Identifiable, Equatable {
    var id            = UUID()
    var date          : Date
    var steps         : Int
    var distance      : Double  = 0     // km
    var calories      : Int     = 0
    var activeMinutes : Int     = 0
    var source        : String  = "manual"  // "manual" or "healthkit"
}

// MARK: - Water

struct WaterEntry: Codable, Identifiable, Equatable {
    var id     = UUID()
    var date   : Date
    var amount : Double  // ml
}

// MARK: - Nutrition

struct NutritionLog: Codable, Identifiable, Equatable {
    var id       = UUID()
    var date     : Date
    var mealType : MealType
    var calories : Int
    var carbs    : Double
    var protein  : Double
    var fat      : Double
    var fiber    : Double
    var sugar    : Double = 0
    var salt     : Double = 0
    var foodName : String = ""
    var notes    : String = ""
}

enum MealType: String, Codable, CaseIterable {
    case breakfast = "Breakfast"
    case lunch     = "Lunch"
    case dinner    = "Dinner"
    case snack     = "Snack"
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch:     return "sun.max.fill"
        case .dinner:    return "sunset.fill"
        case .snack:     return "apple.logo"
        }
    }
    var color: Color {
        switch self {
        case .breakfast: return .brandAmber
        case .lunch:     return .brandTeal
        case .dinner:    return .brandPurple
        case .snack:     return .brandGreen
        }
    }
}

// MARK: - Symptoms

struct SymptomLog: Codable, Identifiable, Equatable {
    var id       = UUID()
    var date     : Date
    var symptoms : [String]
    var severity : SymptomSeverity
    var notes    : String = ""
}

enum SymptomSeverity: String, Codable, CaseIterable {
    case mild     = "Mild"
    case moderate = "Moderate"
    case severe   = "Severe"
    var color: Color {
        switch self { case .mild: return .brandGreen; case .moderate: return .brandAmber; case .severe: return .brandCoral }
    }
}

/// Comprehensive symptom database organised by body system.
/// Covers general health, chronic conditions (diabetes, hypertension, CKD), women's health, and medication side effects.
let symptomCategories: [(category: String, icon: String, symptoms: [String])] = [
    ("General", "heart.text.square", [
        "Fatigue", "Fever", "Chills", "Night Sweats", "Weight Loss", "Weight Gain",
        "Malaise", "Loss of Appetite", "Excessive Thirst", "Dehydration",
        "Feeling Unwell", "Lethargy", "Weakness", "Fainting", "Cold Sweats",
        "Hot Flushes", "Swollen Glands", "Bruising Easily", "Excessive Hunger"
    ]),
    ("Head & Brain", "brain.head.profile", [
        "Headache", "Migraine", "Dizziness", "Vertigo", "Lightheadedness",
        "Brain Fog", "Confusion", "Memory Problems", "Difficulty Concentrating",
        "Pressure in Head", "Throbbing Head Pain", "Tension Headache",
        "Cluster Headache", "Head Heaviness"
    ]),
    ("Eyes", "eye", [
        "Blurred Vision", "Double Vision", "Eye Pain", "Dry Eyes", "Floaters",
        "Light Sensitivity", "Watery Eyes", "Red Eyes", "Itchy Eyes",
        "Eye Twitching", "Vision Loss", "Dark Spots in Vision",
        "Night Vision Problems", "Eye Swelling"
    ]),
    ("Ears, Nose & Throat", "ear", [
        "Sore Throat", "Ear Pain", "Tinnitus", "Hearing Loss", "Nasal Congestion",
        "Runny Nose", "Sneezing", "Nosebleeds", "Hoarse Voice", "Post-nasal Drip",
        "Difficulty Swallowing", "Dry Throat", "Blocked Ears", "Ear Discharge",
        "Loss of Smell", "Loss of Taste", "Mouth Ulcers", "Swollen Tonsils",
        "Jaw Pain", "Bad Breath"
    ]),
    ("Respiratory", "lungs", [
        "Cough", "Dry Cough", "Productive Cough", "Shortness of Breath",
        "Wheezing", "Chest Tightness", "Rapid Breathing", "Difficulty Breathing",
        "Coughing Blood", "Phlegm", "Night-time Cough", "Breathlessness on Exertion",
        "Shallow Breathing", "Stridor"
    ]),
    ("Heart & Circulation", "heart.fill", [
        "Chest Pain", "Heart Palpitations", "Rapid Heartbeat", "Slow Heartbeat",
        "Irregular Heartbeat", "Swollen Ankles", "Cold Hands/Feet",
        "Leg Pain when Walking", "Varicose Veins", "Chest Pressure",
        "Racing Heart at Rest", "Skipped Heartbeat", "Swollen Legs",
        "Blood Clot Symptoms", "Poor Circulation"
    ]),
    ("Digestive", "stomach", [
        "Nausea", "Vomiting", "Diarrhoea", "Constipation", "Bloating",
        "Abdominal Pain", "Heartburn", "Acid Reflux", "Gas", "Blood in Stool",
        "Indigestion", "Stomach Cramps", "Black/Tarry Stool", "Difficulty Swallowing",
        "Appetite Changes", "Feeling Full Quickly", "Rectal Bleeding",
        "Irritable Bowel", "Food Intolerance", "Nausea After Eating",
        "Abdominal Swelling", "Excessive Burping", "Vomiting Blood"
    ]),
    ("Urinary", "drop.fill", [
        "Frequent Urination", "Painful Urination", "Blood in Urine", "Urgency",
        "Incontinence", "Dark Urine", "Foamy Urine", "Reduced Urine Output",
        "Bedwetting", "Difficulty Urinating", "Cloudy Urine",
        "Strong-Smelling Urine", "Urinary Retention", "Kidney Pain",
        "Burning Sensation"
    ]),
    ("Muscles & Joints", "figure.walk", [
        "Joint Pain", "Muscle Pain", "Back Pain", "Neck Pain", "Muscle Weakness",
        "Stiffness", "Swelling", "Cramps", "Tingling/Numbness", "Shoulder Pain",
        "Knee Pain", "Hip Pain", "Elbow Pain", "Wrist Pain", "Ankle Pain",
        "Muscle Spasms", "Frozen Shoulder", "Sciatica", "Lower Back Pain",
        "Upper Back Pain", "Jaw Stiffness", "Morning Stiffness",
        "Joint Swelling", "Muscle Twitching", "Leg Cramps at Night",
        "Restless Legs", "Carpal Tunnel Symptoms", "Gout Pain"
    ]),
    ("Skin", "hand.raised", [
        "Rash", "Itching", "Hives", "Dry Skin", "Bruising",
        "Skin Discolouration", "Wound Not Healing", "Hair Loss",
        "Excessive Sweating", "Acne", "Eczema Flare", "Psoriasis Flare",
        "Skin Peeling", "Blisters", "Swelling/Oedema", "Skin Redness",
        "Lumps or Bumps", "Mole Changes", "Nail Changes", "Cold Sores",
        "Fungal Infection", "Skin Ulcer", "Stretch Marks", "Cellulitis Signs"
    ]),
    ("Neurological", "brain", [
        "Numbness", "Tremor", "Seizure", "Balance Problems",
        "Weakness on One Side", "Slurred Speech", "Pins and Needles",
        "Muscle Twitching", "Loss of Coordination", "Nerve Pain",
        "Facial Drooping", "Difficulty Walking", "Involuntary Movements",
        "Speech Problems", "Peripheral Neuropathy", "Burning Sensation in Feet"
    ]),
    ("Mental Health", "brain.head.profile.fill", [
        "Anxiety", "Depression", "Insomnia", "Mood Swings", "Irritability",
        "Panic Attacks", "Racing Thoughts", "Low Motivation", "Crying Spells",
        "Social Withdrawal", "Difficulty Sleeping", "Oversleeping",
        "Loss of Interest", "Feeling Hopeless", "Emotional Numbness",
        "Obsessive Thoughts", "Suicidal Thoughts", "Self-Harm Urges",
        "Paranoia", "Hallucinations", "Dissociation", "Burnout",
        "Emotional Eating", "Brain Fatigue", "Stress", "Anger Outbursts"
    ]),
    ("Diabetes-Specific", "drop.triangle", [
        "Hypoglycaemia Symptoms", "Hyperglycaemia Symptoms",
        "Excessive Thirst (Polydipsia)", "Frequent Urination (Polyuria)",
        "Slow Wound Healing", "Tingling in Feet", "Diabetic Foot Pain",
        "Dawn Phenomenon", "Blurred Vision (High Sugar)", "Fruity Breath",
        "Diabetic Neuropathy", "Sweating (Low Sugar)", "Shakiness",
        "Confusion (Low Sugar)", "Extreme Hunger (Low Sugar)",
        "Yeast Infections", "Skin Tags", "Dark Skin Patches (Acanthosis)"
    ]),
    ("Blood Pressure", "gauge.with.dots.needle.33percent", [
        "Flushing", "Headache with High BP", "Nosebleeds (BP Related)",
        "Visual Changes (BP)", "Dizziness on Standing", "Fainting (Low BP)",
        "Pounding in Ears", "Chest Tightness (BP)", "Shortness of Breath (BP)",
        "Anxiety with High BP", "Morning Headaches", "Facial Redness"
    ]),
    ("CKD-Specific", "kidneys", [
        "Swelling (Oedema)", "Foamy Urine", "Chronic Fatigue (CKD)",
        "Itching (Uraemia)", "Metallic Taste", "Reduced Urine Output",
        "Nausea (CKD)", "Loss of Appetite (CKD)", "Muscle Cramps (CKD)",
        "Difficulty Concentrating (CKD)", "Puffy Eyes", "Dry Skin (CKD)",
        "Bone Pain", "Restless Legs (CKD)", "Bad Breath (Uraemia)"
    ]),
    ("Medication Side Effects", "pills", [
        "Nausea from Medication", "Muscle Pain from Statins",
        "Dry Cough from ACE Inhibitors", "Dizziness from BP Meds",
        "Stomach Upset from Metformin", "Diarrhoea from Medication",
        "Drowsiness from Medication", "Weight Gain from Medication",
        "Swollen Ankles from Medication", "Headache from Medication",
        "Skin Reaction from Medication", "Liver Pain from Medication",
        "Constipation from Medication", "Mood Changes from Medication",
        "Sexual Dysfunction from Medication", "Bleeding/Bruising from Blood Thinners",
        "Photosensitivity from Medication"
    ]),
    ("Women's Health", "figure.dress.line.vertical.figure", [
        "Menstrual Cramps", "Irregular Periods", "Heavy Periods",
        "Missed Period", "Spotting Between Periods", "Breast Tenderness",
        "Pelvic Pain", "Mood Changes (Hormonal)", "Bloating (Hormonal)",
        "Premenstrual Syndrome (PMS)", "PMDD Symptoms", "Endometriosis Pain",
        "PCOS Symptoms", "Vaginal Discharge Changes", "Painful Intercourse",
        "Menopausal Symptoms", "Night Sweats (Hormonal)", "Vaginal Dryness",
        "Urinary Issues (Hormonal)", "Ovulation Pain", "Breast Lumps",
        "Pregnancy Symptoms", "Morning Sickness", "Gestational Diabetes Signs"
    ]),
    ("Emergency / Red Flags", "exclamationmark.triangle", [
        "Sudden Severe Headache", "Chest Pain at Rest", "Difficulty Speaking",
        "Sudden Vision Loss", "Severe Allergic Reaction", "Uncontrolled Bleeding",
        "Loss of Consciousness", "Severe Abdominal Pain", "Breathing Emergency",
        "Signs of Stroke (FAST)", "Severe Hypoglycaemia", "Anaphylaxis Signs"
    ])
]

/// Flat list of all symptoms for search.
let allSymptoms: [String] = symptomCategories.flatMap { $0.symptoms }

/// Expanded cycle-specific symptoms for women's health tracking.
let allCycleSymptoms = [
    "Cramps", "Bloating", "Fatigue", "Mood Swings", "Headache",
    "Back Pain", "Breast Tenderness", "Nausea", "Food Cravings", "Insomnia",
    "Irritability", "Acne", "Diarrhoea", "Constipation", "Joint Pain",
    "Anxiety", "Depression", "Crying Spells", "Water Retention", "Hot Flushes",
    "Dizziness", "Heavy Flow", "Light Flow", "Spotting", "Pelvic Pain",
    "Leg Pain", "Muscle Aches", "Brain Fog", "Low Energy", "Appetite Changes",
    "Abdominal Pain", "Skin Changes", "Hair Changes", "Ovulation Pain",
    "Vaginal Dryness", "Discharge Changes"
]

// MARK: - Medication

struct Medication: Codable, Identifiable, Equatable {
    var id           = UUID()
    var name         : String
    var dosage       : String
    var unit         : String    = "mg"
    var frequency    : MedFrequency
    var timeOfDay    : [MedTime]
    var isActive     : Bool      = true
    var color        : String    = "#6C63FF"
    var logs         : [MedLog]  = []

    // New fields — linked to MedicineDatabase (optional for backward-compat Codable)
    var genericName  : String?   = nil      // INN name — links to MedicineDatabase
    var form         : String?   = nil      // e.g. "Tablet"
    var notes        : String    = ""
    var prescriber   : String    = ""
    var instructions : String    = ""
    var startDate    : Date      = Date()

    static func == (lhs: Medication, rhs: Medication) -> Bool { lhs.id == rhs.id }

    /// Look up this medication's full database entry (warnings, interactions, etc.)
    var databaseEntry: MedicineItem? {
        guard let gn = genericName else { return nil }
        return MedicineDatabase.shared.item(byGenericName: gn)
    }

    /// Today's adherence: what % of scheduled doses were taken today
    var todayTakenCount: Int {
        logs.filter { Calendar.current.isDateInToday($0.date) && $0.taken }.count
    }
    var todayScheduledCount: Int { timeOfDay.count }
}

enum MedFrequency: String, Codable, CaseIterable {
    case daily    = "Once daily"
    case twice    = "Twice daily"
    case thrice   = "3× daily"
    case weekly   = "Weekly"
    case asNeeded = "As needed"
}

enum MedTime: String, Codable, CaseIterable {
    case morning   = "Morning"
    case afternoon = "Afternoon"
    case evening   = "Evening"
    case bedtime   = "Bedtime"
    var icon: String {
        switch self {
        case .morning:   return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening:   return "sunset.fill"
        case .bedtime:   return "moon.fill"
        }
    }
    var hour: Int {
        switch self { case .morning: return 8; case .afternoon: return 13; case .evening: return 18; case .bedtime: return 21 }
    }
}

struct MedLog: Codable, Identifiable, Equatable {
    var id   = UUID()
    var date : Date
    var taken: Bool
    var time : MedTime
}

// MARK: - Cycle

struct CycleEntry: Codable, Identifiable {
    var id        = UUID()
    var startDate : Date
    var endDate   : Date?
    var flow      : FlowLevel
    var symptoms  : [String]
    var notes     : String = ""
}

enum FlowLevel: String, Codable, CaseIterable {
    case light = "Light"; case medium = "Medium"; case heavy = "Heavy"
}

// MARK: - Health Alert

struct HealthAlert: Codable, Identifiable, Equatable {
    var id           = UUID()
    var date         : Date
    var type         : AlertType
    var title        : String
    var message      : String
    var isRead       : Bool = false
    var actionLabel  : String = ""
}

enum AlertType: String, Codable {
    case highGlucose    = "High Glucose"
    case lowGlucose     = "Low Glucose"
    case highBP         = "High BP"
    case missedMed      = "Missed Medication"
    case sleepAlert     = "Poor Sleep"
    case stressAlert    = "High Stress"
    case hrAlert        = "Abnormal Heart Rate"
    case achievement    = "Achievement"
    case challenge      = "Challenge Update"
    case reminder       = "Reminder"
    case goalReached    = "Goal Reached"

    var icon: String {
        switch self {
        case .highGlucose, .lowGlucose: return "drop.fill"
        case .highBP:       return "heart.fill"
        case .missedMed:    return "pill.fill"
        case .sleepAlert:   return "bed.double.fill"
        case .stressAlert:  return "brain.head.profile"
        case .hrAlert:      return "waveform.path.ecg"
        case .achievement:  return "star.fill"
        case .challenge:    return "flag.fill"
        case .reminder:     return "bell.fill"
        case .goalReached:  return "checkmark.seal.fill"
        }
    }

    var color: Color {
        switch self {
        case .highGlucose, .highBP, .hrAlert: return .brandCoral
        case .lowGlucose:   return Color(hex: "#4fc3f7")
        case .missedMed:    return .brandAmber
        case .sleepAlert, .stressAlert: return .brandAmber
        case .achievement, .goalReached: return .brandGreen
        case .challenge:    return .brandPurple
        case .reminder:     return .brandTeal
        }
    }
}

// MARK: - Health Goal

struct HealthGoal: Codable, Identifiable, Equatable {
    var id           = UUID()
    var type         : GoalType
    var title        : String
    var targetValue  : Double
    var currentValue : Double = 0
    var unit         : String
    var deadline     : Date
    var isCompleted  : Bool = false
    var createdAt    : Date = Date()
    var progress: Double { min(currentValue / max(targetValue, 1), 1.0) }
}

enum GoalType: String, Codable, CaseIterable {
    case steps   = "Steps"; case sleep   = "Sleep"; case weight  = "Weight"
    case glucose = "Glucose"; case bloodPressure = "Blood Pressure"
    case hrv     = "HRV"; case water   = "Water"; case exercise = "Exercise"
    case medication = "Medication"

    var icon: String {
        switch self {
        case .steps: return "figure.walk"; case .sleep: return "bed.double.fill"
        case .weight: return "scalemass.fill"; case .glucose: return "drop.fill"
        case .bloodPressure: return "heart.fill"; case .hrv: return "waveform.path.ecg"
        case .water: return "drop.circle.fill"; case .exercise: return "dumbbell.fill"
        case .medication: return "pill.fill"
        }
    }
    var color: Color {
        switch self {
        case .steps: return .brandTeal; case .sleep: return .brandPurple
        case .weight: return .brandAmber; case .glucose: return .brandCoral
        case .bloodPressure: return .red; case .hrv: return .brandGreen
        case .water: return Color(hex: "#4fc3f7"); case .exercise: return .orange
        case .medication: return .brandPurple
        }
    }
    var defaultUnit: String {
        switch self {
        case .steps: return "steps"; case .sleep: return "hrs"
        case .weight: return "kg"; case .glucose: return "mg/dL"
        case .bloodPressure: return "mmHg"; case .hrv: return "ms"
        case .water: return "L"; case .exercise: return "min"
        case .medication: return "%"
        }
    }
}

// MARK: - Health Challenge

struct HealthChallenge: Codable, Identifiable, Equatable {
    var id           = UUID()
    var title        : String
    var description  : String
    var type         : ChallengeType
    var targetValue  : Double
    var currentValue : Double = 0
    var reward       : Int
    var startDate    : Date
    var endDate      : Date
    var isJoined     : Bool = false
    var isCompleted  : Bool = false
    var participants : Int  = 0
    var progress: Double { min(currentValue / max(targetValue, 1), 1.0) }
    var isActive: Bool { Date() >= startDate && Date() <= endDate }
    var daysLeft: Int { max(0, Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0) }
}

enum ChallengeType: String, Codable, CaseIterable {
    case daily = "Daily"; case weekly = "Weekly"; case milestone = "Milestone"
    var icon: String {
        switch self { case .daily: return "sun.max.fill"; case .weekly: return "calendar.circle.fill"; case .milestone: return "star.fill" }
    }
    var color: Color {
        switch self { case .daily: return .brandAmber; case .weekly: return .brandTeal; case .milestone: return .brandPurple }
    }
}

// MARK: - Achievement

struct Achievement: Codable, Identifiable, Equatable {
    var id           = UUID()
    var title        : String
    var description  : String
    var icon         : String
    var color        : String
    var xp           : Int
    var earnedDate   : Date?
    var isEarned     : Bool = false
    var category     : AchievementCategory
}

enum AchievementCategory: String, Codable, CaseIterable {
    case tracking  = "Tracking"
    case vitals    = "Vitals"
    case medication = "Medication"
    case goals     = "Goals"
    case social    = "Community"
    case special   = "Special"
}

// MARK: - User Streak

struct UserStreak: Codable, Identifiable, Equatable {
    var id           = UUID()
    var type         : StreakType
    var currentCount : Int  = 0
    var longestCount : Int  = 0
    var lastUpdated  : Date = Date()
}

enum StreakType: String, Codable, CaseIterable {
    case dailyCheckIn  = "Daily Check-in"
    case glucose       = "Glucose Logging"
    case bloodPressure = "BP Logging"
    case medication    = "Medication"
    case sleep         = "Sleep Tracking"
    case steps         = "Step Goal"
    var icon: String {
        switch self {
        case .dailyCheckIn:  return "checkmark.circle.fill"
        case .glucose:       return "drop.fill"
        case .bloodPressure: return "heart.fill"
        case .medication:    return "pill.fill"
        case .sleep:         return "bed.double.fill"
        case .steps:         return "figure.walk"
        }
    }
}

// MARK: - Currency Service

struct CurrencyService {
    static let countryToCurrency: [String: String] = [
        "United Kingdom": "GBP", "United States": "USD", "India": "INR",
        "Germany": "EUR", "France": "EUR", "Spain": "EUR", "Italy": "EUR", "Netherlands": "EUR",
        "Canada": "CAD", "Australia": "AUD", "Japan": "JPY", "Brazil": "BRL",
        "Nigeria": "NGN", "South Africa": "ZAR", "Kenya": "KES",
        "UAE": "AED", "Saudi Arabia": "SAR", "Singapore": "SGD", "Malaysia": "MYR",
        "Pakistan": "PKR", "Bangladesh": "BDT", "Philippines": "PHP", "Mexico": "MXN",
        "China": "CNY", "South Korea": "KRW", "Indonesia": "IDR", "Thailand": "THB",
    ]

    static let currencySymbol: [String: String] = [
        "GBP": "£", "USD": "$", "EUR": "€", "INR": "₹",
        "CAD": "C$", "AUD": "A$", "JPY": "¥", "BRL": "R$",
        "NGN": "₦", "ZAR": "R", "AED": "AED ", "SAR": "SAR ",
        "SGD": "S$", "MYR": "RM ", "KES": "KSh ", "PKR": "Rs ",
        "BDT": "৳", "PHP": "₱", "MXN": "MX$",
        "CNY": "¥", "KRW": "₩", "IDR": "Rp ", "THB": "฿",
    ]

    static let rateFromGBP: [String: Double] = [
        "GBP": 1.0, "USD": 1.27, "EUR": 1.17, "INR": 105.0,
        "CAD": 1.72, "AUD": 1.94, "JPY": 190.0, "BRL": 6.2,
        "NGN": 1130.0, "ZAR": 23.5, "AED": 4.67, "SAR": 4.76,
        "SGD": 1.71, "MYR": 5.95, "KES": 195.0, "PKR": 354.0,
        "BDT": 140.0, "PHP": 71.0, "MXN": 21.8,
        "CNY": 9.1, "KRW": 1680.0, "IDR": 19800.0, "THB": 44.5,
    ]

    static let countryCities: [String: [String]] = [
        "United Kingdom": ["London", "Manchester", "Birmingham", "Edinburgh", "Glasgow", "Bristol", "Leeds", "Liverpool", "Cardiff"],
        "United States": ["New York", "Chicago", "San Francisco", "Miami", "Boston", "Los Angeles", "Houston", "Seattle"],
        "India": ["Mumbai", "Delhi", "Bangalore", "Hyderabad", "Chennai", "Kolkata", "Pune", "Ahmedabad"],
        "Canada": ["Toronto", "Vancouver", "Montreal", "Calgary", "Ottawa"],
        "Australia": ["Sydney", "Melbourne", "Brisbane", "Perth", "Adelaide"],
        "Germany": ["Berlin", "Munich", "Hamburg", "Frankfurt", "Cologne"],
        "France": ["Paris", "Lyon", "Marseille", "Toulouse", "Nice"],
        "Nigeria": ["Lagos", "Abuja", "Port Harcourt", "Ibadan", "Kano"],
        "South Africa": ["Cape Town", "Johannesburg", "Durban", "Pretoria"],
        "UAE": ["Dubai", "Abu Dhabi", "Sharjah"],
        "Saudi Arabia": ["Riyadh", "Jeddah", "Mecca", "Medina"],
        "Singapore": ["Singapore"],
        "Malaysia": ["Kuala Lumpur", "Penang", "Johor Bahru"],
        "Japan": ["Tokyo", "Osaka", "Kyoto", "Yokohama"],
        "Brazil": ["São Paulo", "Rio de Janeiro", "Brasília"],
        "Kenya": ["Nairobi", "Mombasa"],
        "Pakistan": ["Karachi", "Lahore", "Islamabad"],
        "Bangladesh": ["Dhaka", "Chittagong"],
        "Philippines": ["Manila", "Cebu", "Davao"],
        "Mexico": ["Mexico City", "Guadalajara", "Monterrey"],
        "China": ["Beijing", "Shanghai", "Shenzhen", "Guangzhou"],
        "South Korea": ["Seoul", "Busan", "Incheon"],
        "Indonesia": ["Jakarta", "Surabaya", "Bandung"],
        "Thailand": ["Bangkok", "Chiang Mai", "Phuket"],
    ]

    static var supportedCountries: [String] { countryToCurrency.keys.sorted() }

    static func convert(_ gbpPrice: Double, to currencyCode: String) -> Double {
        let rate = rateFromGBP[currencyCode] ?? 1.0
        return gbpPrice * rate
    }

    static func format(_ gbpPrice: Double, currencyCode: String) -> String {
        let local = convert(gbpPrice, to: currencyCode)
        let sym = currencySymbol[currencyCode] ?? currencyCode + " "
        if local >= 100 { return "\(sym)\(Int(local))" }
        return "\(sym)\(String(format: "%.2f", local))"
    }

    static func currency(for country: String) -> String {
        countryToCurrency[country] ?? "GBP"
    }
}

// MARK: - Condition Mapper

struct ConditionMapper {
    static let conditionToSpecializations: [String: [String]] = [
        "diabetes":       ["Diabetologist", "Endocrinologist", "Internal Medicine"],
        "blood sugar":    ["Diabetologist", "Endocrinologist"],
        "glucose":        ["Diabetologist", "Endocrinologist"],
        "blood pressure": ["Cardiologist", "Internal Medicine"],
        "hypertension":   ["Cardiologist", "Internal Medicine"],
        "heart":          ["Cardiologist"],
        "kidney":         ["Nephrologist", "Internal Medicine"],
        "weight":         ["Nutritionist", "Endocrinologist"],
        "diet":           ["Nutritionist"],
        "nutrition":      ["Nutritionist"],
        "cholesterol":    ["Cardiologist", "Internal Medicine"],
        "thyroid":        ["Endocrinologist"],
        "general":        ["Internal Medicine"],
    ]

    static func specializations(for problem: String) -> [String] {
        let lower = problem.lowercased()
        for (key, specs) in conditionToSpecializations {
            if lower.contains(key) { return specs }
        }
        return []
    }
}

// MARK: - Community Group

struct CommunityGroup: Codable, Identifiable, Equatable, Hashable {
    var id          = UUID()
    var name        : String
    var description : String
    var category    : GroupCategory
    var memberCount : Int
    var isJoined    : Bool = false
    var icon        : String
    var color       : String
    var posts       : [CommunityPost] = []
    var city        : String = ""
    var isUserCreated : Bool = false
    var creatorAlias  : String = ""
    var challenges    : [GroupChallenge] = []

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: CommunityGroup, rhs: CommunityGroup) -> Bool { lhs.id == rhs.id }
}

enum GroupCategory: String, Codable, CaseIterable {
    case diabetes    = "Diabetes"; case heartHealth = "Heart Health"
    case bloodPressure = "Blood Pressure"; case wellness = "Wellness"
    case weightLoss  = "Weight Loss"; case nutrition = "Nutrition"
    case exercise    = "Exercise"; case womensHealth = "Women's Health"
    case walking     = "Walking & Steps"
    case fasting     = "Fasting"
}

struct CommunityPost: Codable, Identifiable, Equatable {
    var id          = UUID()
    var author      : String
    var initials    : String
    var avatarColor : String
    var content     : String
    var date        : Date
    var likes       : Int
    var comments    : Int
    var isLiked     : Bool   = false
    var tag         : String = ""
    var activityData: SharedActivityData? = nil
    var isOwnPost   : Bool = false
    var reportCount : Int = 0
    var reportedBy  : [String] = []
    var isHidden    : Bool = false
}

struct SharedActivityData: Codable, Equatable {
    var steps        : Int
    var distance     : Double  // km
    var calories     : Int
    var activeMinutes: Int
    var date         : Date
}

struct GroupChallenge: Codable, Identifiable, Equatable {
    var id           = UUID()
    var title        : String
    var description  : String
    var targetValue  : Double
    var currentValue : Double = 0
    var unit         : String
    var startDate    : Date
    var endDate      : Date
    var participants : Int = 0
    var isJoined     : Bool = false
    var progress     : Double { min(currentValue / max(targetValue, 1), 1.0) }
}

// MARK: - Doctor

struct Doctor: Codable, Identifiable, Equatable {
    var id             = UUID()
    var name           : String
    var specialization : String
    var qualifications : String
    var experience     : Int
    var rating         : Double
    var reviews        : Int
    var hospital       : String
    var city           : String
    var fee            : Int        // base fee in GBP
    var available      : Bool     = true
    var avatarColor    : String   = "#6C63FF"
    var languages      : [String] = ["English"]
    var nextAvailable  : String   = "Today"
    var bio            : String   = ""
    var postcode       : String   = ""     // e.g. "SW1A 1AA" for locality search
    var country        : String   = "United Kingdom"

    // ── Certifications & Credentials ──
    var licenseNumber  : String   = ""     // Medical license number
    var regulatoryBody : String   = ""     // e.g. "GMC", "ECFMG", "AHPRA"
    var certifications : [String] = []     // e.g. ["ECFMG","WDOM Listed","Certificate of Good Standing"]
    var countryExam    : String   = ""     // e.g. "PLAB/UKMLA", "USMLE", "AMC"
    var isVerified     : Bool     = false  // Verified by BodySense AI team
    var profilePhotoData : Data?  = nil   // JPEG photo uploaded by doctor

    /// Fee in user's local currency
    func feeString(currencyCode: String) -> String {
        CurrencyService.format(Double(fee), currencyCode: currencyCode)
    }
}

// MARK: - Status Enums (Type-safe, replaces hardcoded strings)

enum VerificationStatus: String, Codable, CaseIterable {
    case pending     = "Pending"
    case underReview = "Under Review"
    case verified    = "Verified"
    case rejected    = "Rejected"

    var color: Color {
        switch self {
        case .pending:     return .brandAmber
        case .underReview: return .blue
        case .verified:    return .brandGreen
        case .rejected:    return .brandCoral
        }
    }

    // Safe decode — fallback to .pending if unknown value
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = VerificationStatus(rawValue: rawValue) ?? .pending
    }
}

enum RequestStatus: String, Codable, CaseIterable {
    case pending  = "Pending"
    case approved = "Approved"
    case rejected = "Rejected"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = RequestStatus(rawValue: rawValue) ?? .pending
    }
}

// MARK: - Doctor Profile (for doctor accounts)

struct DoctorProfile: Codable {
    // ── Basic Info ──────────────────────────────────────────────────────────
    var licenseNumber        : String  = ""
    var specialty            : String  = "General Practice"
    var qualifications       : String  = ""
    var bio                  : String  = ""
    var introduction         : String  = ""    // Longer personal introduction
    var hospital             : String  = ""
    var postcode             : String  = ""
    var country              : String  = "United Kingdom"
    var profilePhotoData     : Data?   = nil   // JPEG photo data

    // ── UK GMC Credentials ─────────────────────────────────────────────────
    var gmcNumber            : String  = ""    // GMC Reference Number
    var gmcRegistrationStatus: String  = ""    // "Full", "Provisional", "Specialist Register", "GP Register"
    var gmcRegistrationDate  : String  = ""    // Date of first registration
    var certificateOfGoodStanding: Bool = false  // Certificate of Good Standing uploaded
    var pmqDegree            : String  = ""    // Primary Medical Qualification (e.g. "MBBS")
    var pmqCountry           : String  = ""    // Country where PMQ was awarded
    var pmqYear              : Int     = 0     // Year PMQ was awarded
    var plabPassed           : Bool    = false // PLAB/UKMLA exam passed (for international doctors)

    // ── International Credentials ──────────────────────────────────────────
    var ecfmgNumber          : String  = ""    // ECFMG Certificate Number
    var ecfmgCertified       : Bool    = false // ECFMG Certified (for US practice)
    var wdomListed           : Bool    = false // Listed in World Directory of Medical Schools
    var regulatoryBody       : String  = "GMC" // GMC / ECFMG / EPIC / AHPRA etc

    // ── Consultation Pricing (per type) ────────────────────────────────────
    var videoConsultationFee : Double  = 50.0
    var phoneConsultationFee : Double  = 35.0
    var inPersonFee          : Double  = 75.0
    var consultationFeeGBP   : Double  = 50.0  // Default / legacy fee
    var consultationDurationMin: Int   = 30

    // ── Financials ─────────────────────────────────────────────────────────
    var totalRevenue         : Double  = 0     // all paid appointments total
    var platformCommission   : Double  = 0     // 40% platform cut
    var doctorEarnings       : Double  = 0     // 60% to doctor

    // ── Availability ───────────────────────────────────────────────────────
    var availability         : [DayAvailability] = DayAvailability.defaultSchedule
    var timeZoneIdentifier   : String  = TimeZone.current.identifier

    // ── Status ─────────────────────────────────────────────────────────────
    var isVerified           : Bool    = false
    var verificationStatus   : VerificationStatus = .pending
    var payoutAccountId      : String  = ""    // Payment account for payouts

    /// Fee for a given appointment type
    func fee(for type: AppointmentType) -> Double {
        switch type {
        case .video:     return videoConsultationFee
        case .phone:     return phoneConsultationFee
        case .inPerson:  return inPersonFee
        }
    }
}

// MARK: - Doctor Review

struct DoctorReview: Codable, Identifiable, Equatable {
    var id           = UUID()
    var doctorId     : UUID
    var patientName  : String   = "Anonymous"
    var patientAlias : String   = ""
    var rating       : Double   = 5.0    // 1-5 stars
    var comment      : String   = ""
    var date         : Date     = Date()
    var appointmentId: UUID?    = nil
    var isVerified   : Bool     = false  // Verified that patient actually had appointment
    var consultType  : String   = "Video Call"
}

// MARK: - Medical Record

struct MedicalRecord: Codable, Identifiable, Equatable {
    var id           = UUID()
    var title        : String
    var fileType     : MedicalRecordType
    var fileName     : String
    var fileData     : Data?     = nil   // Actual file data
    var thumbnailData: Data?     = nil   // Preview thumbnail for images
    var notes        : String    = ""
    var date         : Date      = Date()
    var addedBy      : String    = "Me"  // "Me" | "Dr. Smith"
    var doctorId     : UUID?     = nil   // If added by a doctor
    var tags         : [String]  = []    // e.g. ["Blood Test", "Diabetes", "2024"]
    var isShared     : Bool      = false
}

enum MedicalRecordType: String, Codable, CaseIterable {
    case image       = "Image"
    case pdf         = "PDF Document"
    case report      = "Medical Report"
    case prescription = "Prescription"
    case labResult   = "Lab Result"
    case xray        = "X-Ray / Scan"
    case other       = "Other"

    var icon: String {
        switch self {
        case .image:        return "photo"
        case .pdf:          return "doc.fill"
        case .report:       return "doc.text.fill"
        case .prescription: return "pills.fill"
        case .labResult:    return "testtube.2"
        case .xray:         return "lungs.fill"
        case .other:        return "doc.badge.plus"
        }
    }
    var color: Color {
        switch self {
        case .image:        return .brandTeal
        case .pdf:          return .brandCoral
        case .report:       return .brandPurple
        case .prescription: return .brandGreen
        case .labResult:    return .brandAmber
        case .xray:         return Color(.systemGray)
        case .other:        return .brandPurple
        }
    }
}

struct DayAvailability: Codable, Identifiable {
    var id = UUID()
    var dayOfWeek  : Int  // 0 = Sunday
    var startHour  : Int  // 9
    var endHour    : Int  // 17
    var isAvailable: Bool

    static var defaultSchedule: [DayAvailability] {
        (0...6).map { day in
            DayAvailability(dayOfWeek: day, startHour: 9, endHour: 17, isAvailable: day >= 1 && day <= 5)
        }
    }
    var dayName: String {
        ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"][dayOfWeek]
    }
}

// MARK: - Video Call Session

struct VideoCallSession: Identifiable {
    var id          = UUID()
    var doctor      : Doctor
    var appointment : Appointment
    var roomId      : String       // Agora / Daily.co room
    var startTime   : Date
}

// MARK: - Appointment Attachment

struct AppointmentAttachment: Codable, Identifiable, Equatable {
    var id            = UUID()
    var appointmentId : UUID
    var type          : AttachmentType
    var title         : String
    var data          : Data?   = nil
    var thumbnailData : Data?   = nil
    var notes         : String  = ""
    var date          : Date    = Date()
}

enum AttachmentType: String, Codable, CaseIterable {
    case healthReadings = "Health Readings"
    case medicalRecord  = "Medical Record"
    case uploadedScan   = "Uploaded Scan/Report"

    var icon: String {
        switch self {
        case .healthReadings: return "heart.text.clipboard"
        case .medicalRecord:  return "doc.text.fill"
        case .uploadedScan:   return "doc.richtext"
        }
    }

    var color: Color {
        switch self {
        case .healthReadings: return .brandTeal
        case .medicalRecord:  return .brandPurple
        case .uploadedScan:   return .brandAmber
        }
    }
}

// MARK: - Appointment

struct Appointment: Codable, Identifiable, Equatable {
    var id              = UUID()
    var doctorId        : UUID?
    var doctorName      : String
    var doctorSpec      : String
    var doctorColor     : String = "#6C63FF"
    var date            : Date
    var type            : AppointmentType
    var status          : AppointmentStatus
    var notes           : String  = ""
    var feeGBP          : Double  = 0       // Fee paid in GBP
    var isPaid          : Bool    = false
    var paymentIntentId : String? = nil     // Apple Pay transaction ID
    var videoRoomId     : String? = nil     // Video call room ID
    var durationMin     : Int     = 30
    var paymentMethod   : String  = ""      // "Apple Pay" | "Card"
    var attachments     : [AppointmentAttachment] = []
}

enum AppointmentType: String, Codable, CaseIterable {
    case video    = "Video Call"
    case inPerson = "In-Person"
    case phone    = "Phone Call"
    var icon: String {
        switch self { case .video: return "video.fill"; case .inPerson: return "person.fill"; case .phone: return "phone.fill" }
    }
}

enum AppointmentStatus: String, Codable {
    case upcoming  = "Upcoming"
    case completed = "Completed"
    case cancelled = "Cancelled"
    var color: Color {
        switch self { case .upcoming: return .brandTeal; case .completed: return .brandGreen; case .cancelled: return .brandCoral }
    }
}

// MARK: - Prescription

struct Prescription: Codable, Identifiable, Equatable {
    var id          = UUID()
    var doctorName  : String
    var date        : Date
    var medications : [String]
    var diagnosis   : String
    var notes       : String
    var validUntil  : Date
}

// MARK: - Subscription

enum SubscriptionPlan: String, Codable, CaseIterable {
    case free = "Free"; case pro = "Pro"; case premium = "Premium"

    /// Base price in GBP
    var basePriceGBP: Double {
        switch self { case .free: return 0; case .pro: return 3.99; case .premium: return 8.99 }
    }
    /// Legacy price string (GBP)
    var price: String {
        switch self { case .free: return "Free"; case .pro: return "£3.99/mo"; case .premium: return "£8.99/mo" }
    }
    /// Localized price string
    func priceString(currencyCode: String) -> String {
        if self == .free { return "Free" }
        return CurrencyService.format(basePriceGBP, currencyCode: currencyCode) + "/mo"
    }
    var features: [String] {
        switch self {
        case .free:    return ["Glucose & BP tracking","Medication reminders","1 health goal","Basic AI chat"]
        case .pro:     return ["All Free features","Sleep & HR tracking","5 health goals","Symptom logging","Reports export","Wearable sync","Community access","Challenges & achievements"]
        case .premium: return ["All Pro features","Full AI Coach","Unlimited goals","Unlimited doctor consultations","Family sharing (5 members)","Priority support","API access"]
        }
    }
    var color: Color {
        switch self { case .free: return Color(.systemGray); case .pro: return .brandTeal; case .premium: return .brandPurple }
    }
    var icon: String {
        switch self { case .free: return "star"; case .pro: return "star.fill"; case .premium: return "crown.fill" }
    }
    var badge: String {
        switch self { case .free: return "FREE"; case .pro: return "PRO"; case .premium: return "PREMIUM" }
    }
}

// MARK: - Shop Product

struct Product: Codable, Identifiable, Equatable {
    var id              = UUID()
    var name            : String
    var description     : String
    var price           : Double     // base price in GBP
    var originalPrice   : Double     // base original price in GBP
    var category        : ProductCategory
    var icon            : String
    var color           : String
    var inStock         : Bool        = true
    var rating          : Double      = 4.8
    var reviews         : Int         = 0
    var isNew           : Bool        = false
    var isBestSeller    : Bool        = false
    var availableColors : [RingColor] = []   // Non-empty only for rings
    var sizeName        : String      = ""   // e.g. "X3B (Med)" for the ring
    var imageFileName   : String?     = nil  // CEO-uploaded product photo filename

    /// Localized price
    func priceString(currencyCode: String) -> String {
        CurrencyService.format(price, currencyCode: currencyCode)
    }
    /// Localized original price
    func originalPriceString(currencyCode: String) -> String {
        CurrencyService.format(originalPrice, currencyCode: currencyCode)
    }
    var isRing: Bool { category == .ring && !availableColors.isEmpty }

    /// URL of the saved product image
    var imageURL: URL? {
        guard let fileName = imageFileName else { return nil }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first?.appendingPathComponent("product_images").appendingPathComponent(fileName)
    }

    /// Save image data to disk
    mutating func setImage(_ data: Data) {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("product_images")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fileName = "\(id.uuidString).jpg"
        try? data.write(to: dir.appendingPathComponent(fileName))
        imageFileName = fileName
    }

    /// Delete saved image
    mutating func removeImage() {
        if let url = imageURL { try? FileManager.default.removeItem(at: url) }
        imageFileName = nil
    }
}

// MARK: - Ring Colour

enum RingColor: String, Codable, CaseIterable {
    case silver  = "Silver"
    case black   = "Black"
    case gold    = "Gold"

    var hexColor: String {
        switch self {
        case .silver: return "#C8C8C8"
        case .black:  return "#1C1C1E"
        case .gold:   return "#C9A96E"
        }
    }
    var color: Color { Color(hex: hexColor) }
    var icon: String { "circle.fill" }
}

// MARK: - Ring Size

enum RingSize: String, Codable, CaseIterable {
    case size5  = "Size 5 (15.7mm)"
    case size6  = "Size 6 (16.5mm)"
    case size7  = "Size 7 (17.3mm)"
    case size8  = "Size 8 (18.1mm)"
    case size9  = "Size 9 (19.0mm)"
    case size10 = "Size 10 (19.8mm)"
    case size11 = "Size 11 (20.6mm)"
    case size12 = "Size 12 (21.4mm)"
    case size13 = "Size 13 (22.2mm)"

    var shortLabel: String {
        switch self {
        case .size5:  return "5"
        case .size6:  return "6"
        case .size7:  return "7"
        case .size8:  return "8"
        case .size9:  return "9"
        case .size10: return "10"
        case .size11: return "11"
        case .size12: return "12"
        case .size13: return "13"
        }
    }
}

// MARK: - Delivery Address

struct DeliveryAddress: Codable, Equatable {
    var fullName    : String = ""
    var addressLine1: String = ""
    var addressLine2: String = ""
    var city        : String = ""
    var postcode    : String = ""
    var country     : String = "United Kingdom"
    var phone       : String = ""

    var isComplete: Bool {
        !fullName.isEmpty && !addressLine1.isEmpty && !city.isEmpty && !postcode.isEmpty
    }
}

// MARK: - Gift Code (for subscriptions)

struct GiftCode: Codable, Identifiable, Equatable {
    var id          = UUID()
    var code        : String              // e.g. "BS-GIFT-A1B2C3"
    var plan        : SubscriptionPlan    // which plan it grants
    var durationMonths: Int = 12          // how long the gift lasts
    var createdAt   : Date = Date()
    var redeemedAt  : Date? = nil
    var redeemedBy  : String? = nil       // user alias who redeemed
    var isRedeemed  : Bool { redeemedAt != nil }

    static func generateCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        let random = (0..<6).map { _ in chars.randomElement()! }
        return "BS-GIFT-\(String(random))"
    }
}

// MARK: - Cart Item

struct CartItem: Codable, Identifiable, Equatable {
    var id            = UUID()
    var productID     : UUID
    var name          : String
    var price         : Double   // GBP
    var icon          : String
    var color         : String
    var quantity      : Int = 1
    var selectedColor : RingColor? = nil  // Ring colour selection
    var selectedSize  : RingSize? = nil   // Ring size selection
    var sku           : String = ""       // e.g. "RING-X3B-BLACK-S8"
    var isGift        : Bool = false      // Is this a gift for someone?
    var giftMessage   : String = ""
    var addSubscription: SubscriptionPlan? = nil  // Bundled subscription add-on
}

// MARK: - Order

struct Order: Codable, Identifiable, Equatable {
    var id                  = UUID()
    var orderNumber         : String   // "BS-2025-0001"
    var items               : [CartItem]
    var subtotal            : Double   // GBP
    var shippingCost        : Double   // GBP (0 if free)
    var total               : Double   // GBP
    var status              : OrderStatus
    var paymentMethod       : String   // "Apple Pay" | "Card"
    var transactionId: String?
    var createdAt           : Date
    var estimatedDelivery   : Date?
    var deliveryAddress     : DeliveryAddress? = nil
    var giftCodes           : [GiftCode] = []  // Generated gift codes for subscription add-ons

    static func == (lhs: Order, rhs: Order) -> Bool { lhs.id == rhs.id }
}

enum OrderStatus: String, Codable, CaseIterable {
    case pending   = "Pending"
    case confirmed = "Confirmed"
    case shipped   = "Shipped"
    case delivered = "Delivered"
    case cancelled = "Cancelled"

    var color: Color {
        switch self {
        case .pending:   return .brandAmber
        case .confirmed: return .brandTeal
        case .shipped:   return .brandPurple
        case .delivered: return .brandGreen
        case .cancelled: return .brandCoral
        }
    }
    var icon: String {
        switch self {
        case .pending:   return "clock.fill"
        case .confirmed: return "checkmark.circle.fill"
        case .shipped:   return "shippingbox.fill"
        case .delivered: return "house.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
}

enum ProductCategory: String, Codable, CaseIterable {
    case ring        = "Smart Ring"
    case accessories = "Accessories"
    case nutrition   = "Nutrition"
    case devices     = "Devices"
}

// MARK: - Wearable Device

struct WearableDevice: Codable, Identifiable, Equatable {
    var id          = UUID()
    var type        : WearableType
    var isConnected : Bool   = false
    var batteryLevel: Int    = 100
    var lastSync    : Date?
    var color       : String = "#6C63FF"
    var ringColor   : RingColor? = nil   // Set when device is BodySense Ring
}

/// What a device can measure
enum HealthMetric: String, Codable, CaseIterable {
    case heartRate      = "Heart Rate"
    case hrv            = "HRV"
    case spo2           = "SpO2"
    case ecg            = "ECG"
    case bloodPressure  = "Blood Pressure"
    case bloodGlucose   = "Blood Glucose"
    case sleep          = "Sleep"
    case steps          = "Steps"
    case calories       = "Calories"
    case skinTemp       = "Skin Temperature"
    case stress         = "Stress"
    case bodyComp       = "Body Composition"

    var icon: String {
        switch self {
        case .heartRate:     return "heart.fill"
        case .hrv:           return "waveform.path.ecg"
        case .spo2:          return "lungs.fill"
        case .ecg:           return "waveform.path.ecg.rectangle"
        case .bloodPressure: return "stethoscope"
        case .bloodGlucose:  return "drop.fill"
        case .sleep:         return "bed.double.fill"
        case .steps:         return "figure.walk"
        case .calories:      return "flame.fill"
        case .skinTemp:      return "thermometer.medium"
        case .stress:        return "brain.head.profile"
        case .bodyComp:      return "figure.stand"
        }
    }
    var color: Color {
        switch self {
        case .heartRate:     return .brandCoral
        case .hrv:           return .brandPurple
        case .spo2:          return .brandTeal
        case .ecg:           return .brandCoral
        case .bloodPressure: return .brandTeal
        case .bloodGlucose:  return .brandAmber
        case .sleep:         return .brandPurple
        case .steps:         return .brandGreen
        case .calories:      return .brandCoral
        case .skinTemp:      return .brandAmber
        case .stress:        return .orange
        case .bodyComp:      return .brandTeal
        }
    }
}

enum DeviceCategory: String, Codable, CaseIterable {
    case smartwatch  = "Smartwatches"
    case ring        = "Smart Rings"
    case glucometer  = "Glucometers"
    case bpMonitor   = "BP Monitors"
    case pulseOx     = "Pulse Oximeters"
    case cgm         = "CGM"
    case scale       = "Smart Scales"
}

enum WearableType: String, Codable, CaseIterable {
    // ── Smartwatches ──
    case appleWatch    = "Apple Watch"
    case samsungWatch  = "Samsung Galaxy Watch"
    case fitbit        = "Fitbit"
    case garmin        = "Garmin"
    // ── Smart rings ──
    case ouraRing      = "Oura Ring"
    case bodySenseRing = "BodySense Ring"
    // ── Bluetooth Glucometers ──
    case accu_chek     = "Accu-Chek Guide"
    case oneTouch      = "OneTouch Verio"
    case contourNext   = "Contour Next One"
    case dexcomCGM     = "Dexcom G7 (CGM)"
    case libreCGM      = "FreeStyle Libre 3 (CGM)"
    // ── Bluetooth BP Monitors ──
    case omronBP       = "Omron Evolv"
    case withingsBP    = "Withings BPM Connect"
    case qardio        = "QardioArm"
    // ── Pulse Oximeters ──
    case masimoPulseOx = "Masimo MightySat"
    case beurer        = "Beurer PO 60"
    // ── Smart Scales ──
    case withingsScale = "Withings Body+"
    case eufy          = "eufy Smart Scale"

    var category: DeviceCategory {
        switch self {
        case .appleWatch, .samsungWatch, .fitbit, .garmin:        return .smartwatch
        case .ouraRing, .bodySenseRing:                           return .ring
        case .accu_chek, .oneTouch, .contourNext:                 return .glucometer
        case .dexcomCGM, .libreCGM:                               return .cgm
        case .omronBP, .withingsBP, .qardio:                      return .bpMonitor
        case .masimoPulseOx, .beurer:                              return .pulseOx
        case .withingsScale, .eufy:                                return .scale
        }
    }

    /// What this device can measure
    var metrics: [HealthMetric] {
        switch self {
        // Apple Watch: HR, HRV, ECG, SpO2, sleep, steps, calories (NO blood pressure)
        case .appleWatch:    return [.heartRate, .hrv, .ecg, .spo2, .sleep, .steps, .calories]
        case .samsungWatch:  return [.heartRate, .hrv, .ecg, .spo2, .sleep, .steps, .calories, .bodyComp, .bloodPressure]
        case .fitbit:        return [.heartRate, .hrv, .spo2, .sleep, .steps, .calories, .stress, .skinTemp]
        case .garmin:        return [.heartRate, .hrv, .spo2, .sleep, .steps, .calories, .stress]
        // Rings
        case .ouraRing:      return [.heartRate, .hrv, .spo2, .sleep, .skinTemp, .steps, .stress]
        case .bodySenseRing: return [.heartRate, .hrv, .spo2, .sleep, .skinTemp, .steps, .stress, .calories]
        // Glucometers & CGMs
        case .accu_chek:     return [.bloodGlucose]
        case .oneTouch:      return [.bloodGlucose]
        case .contourNext:   return [.bloodGlucose]
        case .dexcomCGM:     return [.bloodGlucose]
        case .libreCGM:      return [.bloodGlucose]
        // BP Monitors
        case .omronBP:       return [.bloodPressure, .heartRate]
        case .withingsBP:    return [.bloodPressure, .heartRate]
        case .qardio:        return [.bloodPressure, .heartRate]
        // Pulse Oximeters
        case .masimoPulseOx: return [.spo2, .heartRate]
        case .beurer:        return [.spo2, .heartRate]
        // Smart Scales
        case .withingsScale: return [.bodyComp]
        case .eufy:          return [.bodyComp]
        }
    }

    var icon: String {
        switch self {
        case .appleWatch:    return "applewatch"
        case .samsungWatch:  return "applewatch.radiowaves.left.and.right"
        case .fitbit:        return "figure.run"
        case .garmin:        return "figure.outdoor.cycle"
        case .ouraRing:      return "circle.hexagonpath.fill"
        case .bodySenseRing: return "circle.fill"
        case .accu_chek, .oneTouch, .contourNext: return "drop.fill"
        case .dexcomCGM, .libreCGM:               return "sensor.fill"
        case .omronBP, .withingsBP, .qardio:      return "stethoscope"
        case .masimoPulseOx, .beurer:              return "lungs.fill"
        case .withingsScale, .eufy:                return "scalemass.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .appleWatch:    return "#1C1C1E"
        case .samsungWatch:  return "#1428A0"
        case .fitbit:        return "#00B0B9"
        case .garmin:        return "#007CC3"
        case .ouraRing:      return "#2D2D2D"
        case .bodySenseRing: return "#6C63FF"
        case .accu_chek:     return "#E30613"
        case .oneTouch:      return "#0072CE"
        case .contourNext:   return "#00A3E0"
        case .dexcomCGM:     return "#62B445"
        case .libreCGM:      return "#FDB913"
        case .omronBP:       return "#003B5C"
        case .withingsBP:    return "#00BCD4"
        case .qardio:        return "#E91E63"
        case .masimoPulseOx: return "#FF6F00"
        case .beurer:        return "#0097A7"
        case .withingsScale: return "#00BCD4"
        case .eufy:          return "#1A73E8"
        }
    }
    var color: Color { Color(hex: colorHex) }
}

// MARK: - Daily Guidance

struct DailyGuidance: Codable, Equatable {
    var date         : Date
    var greeting     : String
    var insight      : String
    var actionItems  : [String]
    var quote        : String
    var healthScore  : Int  // 0–100
    var scoreChange  : Int  // delta vs yesterday
}

// MARK: - Body Metric Units

enum WeightUnit: String, Codable, CaseIterable {
    case kg     = "kg"
    case lbs    = "lbs"
    case stones = "stones"

    var label: String { rawValue }

    /// Convert FROM this unit TO kg
    func toKg(_ value: Double) -> Double {
        switch self {
        case .kg:     return value
        case .lbs:    return value * 0.453592
        case .stones: return value * 6.35029
        }
    }

    /// Convert FROM kg TO this unit
    func fromKg(_ kg: Double) -> Double {
        switch self {
        case .kg:     return kg
        case .lbs:    return kg / 0.453592
        case .stones: return kg / 6.35029
        }
    }
}

enum HeightUnit: String, Codable, CaseIterable {
    case cm     = "cm"
    case inches = "inches"
    case feet   = "ft/in"

    var label: String { rawValue }

    /// Convert FROM this unit TO cm
    func toCm(_ value: Double) -> Double {
        switch self {
        case .cm:     return value
        case .inches: return value * 2.54
        case .feet:   return value * 2.54  // stored as total inches internally
        }
    }

    /// Convert FROM cm TO this unit
    func fromCm(_ cm: Double) -> Double {
        switch self {
        case .cm:     return cm
        case .inches: return cm / 2.54
        case .feet:   return cm / 2.54  // returns total inches; UI shows ft'in"
        }
    }

    /// Format a cm value in the user's chosen unit
    func format(_ cm: Double) -> String {
        switch self {
        case .cm:     return "\(Int(cm)) cm"
        case .inches: return String(format: "%.1f in", cm / 2.54)
        case .feet:
            let totalIn = cm / 2.54
            let ft = Int(totalIn) / 12
            let inches = Int(totalIn) % 12
            return "\(ft)'\(inches)\""
        }
    }
}

// MARK: - Notification Preferences

struct NotificationPreferences: Codable, Equatable {
    var medicationReminders  : Bool = true
    var glucoseAlerts        : Bool = true
    var bpAlerts             : Bool = true
    var waterReminders       : Bool = true
    var sleepReminders       : Bool = true
    var exerciseReminders    : Bool = true
    var aiInsights           : Bool = true
    var communityUpdates     : Bool = false

    // Timing
    var morningReminderHour  : Int  = 8
    var eveningReminderHour  : Int  = 21
    var waterReminderInterval: Int  = 120  // minutes
}

// MARK: - User Profile

struct UserProfile: Codable {
    var name             : String  = ""
    var email            : String  = ""
    var age              : Int     = 30
    var gender           : String  = "Female"
    var diabetesType     : String  = "Type 2 Diabetes"
    var hasHypertension  : Bool    = true
    var targetGlucoseMin : Double  = 80
    var targetGlucoseMax : Double  = 140
    var targetSystolic   : Int     = 130
    var targetDiastolic  : Int     = 85
    var weight           : Double  = 70     // always stored in kg internally
    var height           : Double  = 165    // always stored in cm internally
    var weightUnit       : WeightUnit = .kg
    var heightUnit       : HeightUnit = .cm
    var emergencyName    : String  = ""
    var emergencyPhone   : String  = ""
    var targetSteps      : Int     = 8000
    var targetSleep      : Double  = 7.5
    var targetWater      : Double  = 2.5   // litres

    // ── Location & currency ──
    var city             : String  = ""
    var country          : String  = "United Kingdom"
    var currencyCode     : String  = "GBP"
    var postcode         : String  = ""    // e.g. "SW1A 1AA"

    // ── Profile photo ──
    var profilePhotoData : Data?   = nil   // JPEG compressed photo

    // ── Doctor search preferences ──
    var preferLocalSearch : Bool   = false // true = search by postcode, false = worldwide
    var searchRadiusMiles : Int    = 25    // radius for local search

    // ── Anonymous identity ──
    var anonymousAlias   : String  = ""
    var anonymousColor   : String  = ""

    // ── Account type ──
    var isDoctor         : Bool    = false
    var doctorProfile    : DoctorProfile? = nil

    // ── Onboarding: user-selected health goals ──
    var selectedGoals: [String] = []

    // ── Notification preferences ──
    var notificationPreferences: NotificationPreferences = NotificationPreferences()

    // ── HealthKit sync ──
    var healthKitEnabled : Bool = false

    // ── Nutrition goals (calculated from BMR/weight/goal) ──
    var dailyCalorieGoal : Int    = 2000
    var dailyProteinGoal : Double = 50    // grams
    var dailyCarbGoal    : Double = 250
    var dailyFatGoal     : Double = 65
    var dailyFiberGoal   : Double = 25
    var dailySugarGoal   : Double = 30    // NHS max
    var dailySaltGoal    : Double = 6     // NHS max
    var nutritionGoalType: String = "maintain" // "lose", "gain", "muscle", "maintain"

    // ── Fitness / Activity level ──
    var activityLevel    : String = "moderate" // "sedentary", "light", "moderate", "active", "veryActive"

    // ── GDPR consent (UK GDPR compliance) ──
    var privacyPolicyAccepted      : Bool   = false
    var privacyPolicyAcceptedAt    : Date?  = nil
    var termsAccepted              : Bool   = false
    var termsAcceptedAt            : Date?  = nil
    var consentHealthDataProcessing: Bool   = false   // Required — Article 9 special category
    var consentAnalytics           : Bool   = false   // Optional
    var consentMarketing           : Bool   = false   // Optional — promotional emails
    var consentDataSharing         : Bool   = false   // Optional — anonymised research
    var consentAIProcessing        : Bool   = false   // Optional — on-device AI
    var dataExportRequestedAt      : Date?  = nil
    var accountDeletionRequestedAt : Date?  = nil

    // ── CEO check (Keychain-based, no email) ──
    /// CEO access is granted via a secret activation code stored in Keychain.
    /// NOT based on email — cannot be spoofed by editing profile.
    var isCEO: Bool {
        CEOAccessManager.isActivated
    }
}

// MARK: - Nutrition Goal Type
// Defines the user's body composition objective — drives calorie, protein, carb, and fat targets.

enum NutritionGoalType: String, CaseIterable, Identifiable {
    case lose     = "lose"
    case maintain = "maintain"
    case gain     = "gain"
    case muscle   = "muscle"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .lose:     return "Lose Weight"
        case .maintain: return "Maintain"
        case .gain:     return "Gain Weight"
        case .muscle:   return "Build Muscle"
        }
    }

    var icon: String {
        switch self {
        case .lose:     return "arrow.down.circle.fill"
        case .maintain: return "equal.circle.fill"
        case .gain:     return "arrow.up.circle.fill"
        case .muscle:   return "dumbbell.fill"
        }
    }

    var color: Color {
        switch self {
        case .lose:     return .brandCoral
        case .maintain: return .brandTeal
        case .gain:     return .brandAmber
        case .muscle:   return .brandPurple
        }
    }

    var description: String {
        switch self {
        case .lose:     return "500 kcal deficit · high protein to preserve muscle"
        case .maintain: return "Balanced macros at maintenance calories"
        case .gain:     return "300 kcal surplus · moderate protein"
        case .muscle:   return "400 kcal surplus · 2.2g protein/kg · high carb for training"
        }
    }
}

// MARK: - Activity Level
// Determines the TDEE multiplier for calorie calculations.

enum ActivityLevel: String, CaseIterable, Identifiable {
    case sedentary  = "sedentary"
    case light      = "light"
    case moderate   = "moderate"
    case active     = "active"
    case veryActive = "veryActive"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .sedentary:  return "Sedentary"
        case .light:      return "Lightly Active"
        case .moderate:   return "Moderately Active"
        case .active:     return "Active"
        case .veryActive: return "Very Active"
        }
    }

    var description: String {
        switch self {
        case .sedentary:  return "Desk job, little exercise"
        case .light:      return "Light exercise 1–3 days/week"
        case .moderate:   return "Moderate exercise 3–5 days/week"
        case .active:     return "Hard exercise 6–7 days/week"
        case .veryActive: return "Athlete or physical job + gym"
        }
    }

    var multiplier: Double {
        switch self {
        case .sedentary:  return 1.2
        case .light:      return 1.375
        case .moderate:   return 1.55
        case .active:     return 1.725
        case .veryActive: return 1.9
        }
    }
}

/// MARK: - Doctor Registration Request

struct DoctorRegistrationRequest: Codable, Identifiable, Equatable {
    var id              = UUID()
    var name            : String
    var email           : String
    var specialty       : String
    var hospital        : String
    var city            : String
    var country         : String
    var postcode        : String
    var gmcNumber       : String
    var gmcStatus       : String
    var regulatoryBody  : String
    var pmqDegree       : String
    var pmqCountry      : String
    var pmqYear         : Int
    var plabPassed      : Bool
    var ecfmgCertified  : Bool
    var wdomListed      : Bool
    var goodStanding    : Bool
    var videoFee        : Double
    var phoneFee        : Double
    var inPersonFee     : Double
    var introduction    : String
    var submittedAt     : Date   = Date()
    var status          : RequestStatus = .pending
    var reviewedAt      : Date?  = nil
    var reviewNotes     : String = ""
}

// MARK: - Support Ticket Record (persistent)

struct SupportTicketRecord: Codable, Identifiable, Equatable {
    var id              = UUID()
    var category        : String              // SupportCategory.rawValue
    var issue           : String
    var detail          : String = ""
    var userEmail       : String = ""
    var createdAt       : Date = Date()
    var updatedAt       : Date = Date()
    var status          : String = "Open"     // "Open", "In Progress", "Resolved", "Escalated"
    var aiResponse      : String? = nil
    var ceoReply        : String? = nil       // CEO's reply to escalated ticket
    var isEscalated     : Bool = false
    var escalatedAt     : Date? = nil
    var resolvedAt      : Date? = nil

    var isResolved: Bool { status == "Resolved" }
}

// MARK: - Chat History Record (persistent)

struct ChatHistoryRecord: Codable, Identifiable {
    var id              = UUID()
    var messages        : [ChatMessageRecord] = []
    var agentType       : String? = nil       // nil = main chat, else AgentType.rawValue
    var createdAt       : Date = Date()
    var lastMessageAt   : Date = Date()
    var title           : String = "Chat"     // Auto-generated from first query
}

struct ChatMessageRecord: Codable, Identifiable {
    var id              = UUID()
    var content         : String
    var isUser          : Bool
    var timestamp       : Date = Date()
    var chips           : [String] = []
}

// MARK: - HealthStore (shared observable state)

@Observable
class HealthStore {
    static let shared = HealthStore()

    // ── Core health data ──────────────────────────────────────────────────────
    var glucoseReadings  : [GlucoseReading]  = []
    var bpReadings       : [BPReading]       = []
    var heartRateReadings: [HeartRateReading] = []
    var hrvReadings      : [HRVReading]      = []
    var sleepEntries     : [SleepEntry]      = []
    var stressReadings   : [StressReading]   = []
    var bodyTempReadings : [BodyTempReading] = []
    var stepEntries      : [StepEntry]       = []
    var waterEntries     : [WaterEntry]      = []
    var nutritionLogs    : [NutritionLog]    = []
    var symptomLogs      : [SymptomLog]      = []
    var medications      : [Medication]      = []
    var cycles           : [CycleEntry]      = []

    // ── AI coaching & goals ───────────────────────────────────────────────────
    var healthAlerts     : [HealthAlert]     = []
    var healthGoals      : [HealthGoal]      = []
    var healthChallenges : [HealthChallenge] = []
    var achievements     : [Achievement]     = []
    var userStreaks       : [UserStreak]      = []
    var dailyGuidance    : DailyGuidance?    = nil
    var totalXP          : Int               = 0

    // ── Community & telemedicine ──────────────────────────────────────────────
    var communityGroups  : [CommunityGroup]  = []
    var doctors          : [Doctor]          = []
    var appointments     : [Appointment]     = []
    var prescriptions    : [Prescription]    = []

    // ── Shop & subscription ───────────────────────────────────────────────────
    var subscription     : SubscriptionPlan  = .free
    var products         : [Product]         = []
    var cartItems        : [CartItem]        = []
    var orders           : [Order]           = []
    var wearableDevices  : [WearableDevice]  = []
    var giftCodes        : [GiftCode]        = []    // Purchased/redeemed gift codes
    var deliveryAddress  : DeliveryAddress   = DeliveryAddress()  // Saved address

    // ── Medical records & reviews ─────────────────────────────────────────────
    var medicalRecords   : [MedicalRecord]   = []   // User uploaded medical records
    var doctorReviews    : [DoctorReview]    = []   // Patient reviews for doctors

    // ── Doctor registration requests (CEO approval queue) ────────────────────
    var doctorRequests   : [DoctorRegistrationRequest] = []

    // ── Support tickets (customer care) ─────────────────────────────────────
    var supportTickets   : [SupportTicketRecord] = []

    // ── Chat history (persistent conversations) ─────────────────────────────
    var chatHistories    : [ChatHistoryRecord] = []

    // ── Profile ───────────────────────────────────────────────────────────────
    var userProfile      : UserProfile       = UserProfile()

    // Convenience
    var isDoctor: Bool { userProfile.isDoctor }
    var doctorProfile: DoctorProfile? { userProfile.doctorProfile }

    /// True ONLY when the doctor has been verified/approved by the CEO.
    /// This gates access to Becky AI, patient data, and the doctor dashboard.
    var isDoctorApproved: Bool {
        guard isDoctor, let dp = doctorProfile else { return false }
        return dp.isVerified && dp.verificationStatus == .verified
    }

    /// The doctor's current application status for display purposes.
    var doctorApplicationStatus: String {
        doctorProfile?.verificationStatus.rawValue ?? "None"
    }

    /// Sync the doctor's profile to the public doctors list so patients can find and book them.
    /// Called after saving DoctorProfile changes.
    func syncDoctorToPublicList() {
        guard let dp = userProfile.doctorProfile, dp.isVerified else { return }
        let name = userProfile.name
        guard !name.isEmpty else { return }

        if let idx = doctors.firstIndex(where: { $0.name == name }) {
            // Update existing
            doctors[idx].specialization     = dp.specialty
            doctors[idx].qualifications     = dp.qualifications
            doctors[idx].hospital           = dp.hospital
            doctors[idx].fee                = Int(dp.videoConsultationFee)
            doctors[idx].bio                = dp.introduction
            doctors[idx].postcode           = dp.postcode
            doctors[idx].country            = dp.country
            doctors[idx].licenseNumber      = dp.licenseNumber
            doctors[idx].regulatoryBody     = dp.regulatoryBody
            doctors[idx].isVerified         = true
            doctors[idx].profilePhotoData   = dp.profilePhotoData
            doctors[idx].available          = true
        } else {
            // Create new public listing
            let doc = Doctor(
                name: name,
                specialization: dp.specialty,
                qualifications: dp.qualifications,
                experience: max(1, Calendar.current.component(.year, from: Date()) - dp.pmqYear),
                rating: 5.0,
                reviews: 0,
                hospital: dp.hospital,
                city: dp.postcode.isEmpty ? "UK" : String(dp.postcode.prefix(4)),
                fee: Int(dp.videoConsultationFee),
                available: true,
                bio: dp.introduction,
                postcode: dp.postcode,
                country: dp.country,
                licenseNumber: dp.licenseNumber,
                regulatoryBody: dp.regulatoryBody,
                isVerified: true,
                profilePhotoData: dp.profilePhotoData
            )
            doctors.append(doc)
        }
        save()
    }

    // MARK: Computed convenience

    // Use .max(by:) — O(n) instead of .sorted().first — O(n log n)
    var latestGlucose : GlucoseReading?   { glucoseReadings.max(by:  { $0.date < $1.date }) }
    var latestBP      : BPReading?        { bpReadings.max(by:       { $0.date < $1.date }) }
    var latestHR      : HeartRateReading? { heartRateReadings.max(by: { $0.date < $1.date }) }
    var latestHRV     : HRVReading?       { hrvReadings.max(by:      { $0.date < $1.date }) }
    var lastSleep     : SleepEntry?       { sleepEntries.max(by:     { $0.date < $1.date }) }
    var latestStress  : StressReading?    { stressReadings.max(by:   { $0.date < $1.date }) }
    var latestTemp    : BodyTempReading?  { bodyTempReadings.max(by: { $0.date < $1.date }) }

    var todaySteps: Int {
        let cal = Calendar.current
        return stepEntries.filter { cal.isDateInToday($0.date) }.map { $0.steps }.reduce(0, +)
    }
    var todayWaterML: Double {
        let cal = Calendar.current
        return waterEntries.filter { cal.isDateInToday($0.date) }.map { $0.amount }.reduce(0, +)
    }
    var activeGoals: [HealthGoal]       { healthGoals.filter { !$0.isCompleted } }
    var unreadAlerts: [HealthAlert]     { healthAlerts.filter { !$0.isRead } }
    var joinedGroups: [CommunityGroup]  { communityGroups.filter { $0.isJoined } }
    var earnedAchievements: [Achievement] { achievements.filter { $0.isEarned } }

    // ── Doctor Registration Request methods ─────────────────────────────────

    /// Pending doctor requests awaiting CEO review
    var pendingDoctorRequests: [DoctorRegistrationRequest] {
        doctorRequests.filter { $0.status == .pending }
    }

    /// Submit a new doctor registration request for CEO approval
    func submitDoctorRequest(_ request: DoctorRegistrationRequest) {
        doctorRequests.append(request)
        save()
    }

    /// CEO approves a doctor → adds to verified doctors list + updates their profile
    func approveDoctor(_ request: DoctorRegistrationRequest) {
        guard let idx = doctorRequests.firstIndex(where: { $0.id == request.id }) else { return }
        doctorRequests[idx].status = .approved
        doctorRequests[idx].reviewedAt = Date()

        // ── Update the doctor's own profile so they see "Verified" ──
        // On a single-device app the doctor IS the current user (or was when they registered).
        // Match by email to update their DoctorProfile when they next open the app.
        if userProfile.email.lowercased() == request.email.lowercased(),
           userProfile.doctorProfile != nil {
            userProfile.doctorProfile?.isVerified = true
            userProfile.doctorProfile?.verificationStatus = .verified
        }

        // ── Create / update a Doctor entry visible to patients ──
        let yearsExp = max(1, Calendar.current.component(.year, from: Date()) - request.pmqYear)

        // Check if doctor already exists (from syncDoctorToPublicList or previous approval)
        if let existingIdx = doctors.firstIndex(where: { $0.name == request.name && $0.licenseNumber == request.gmcNumber }) {
            doctors[existingIdx].isVerified = true
            doctors[existingIdx].specialization = request.specialty
            doctors[existingIdx].hospital = request.hospital
            doctors[existingIdx].fee = Int(request.videoFee)
            doctors[existingIdx].bio = request.introduction
        } else {
            let newDoctor = Doctor(
                name: request.name,
                specialization: request.specialty,
                qualifications: request.pmqDegree,
                experience: yearsExp,
                rating: 0,
                reviews: 0,
                hospital: request.hospital,
                city: request.city,
                fee: Int(request.videoFee),
                languages: ["English"],
                bio: request.introduction,
                postcode: request.postcode,
                country: request.country,
                licenseNumber: request.gmcNumber,
                regulatoryBody: request.regulatoryBody,
                certifications: buildCertifications(request),
                isVerified: true
            )
            doctors.append(newDoctor)
        }
        save()
    }

    /// CEO rejects a doctor registration
    func rejectDoctor(_ request: DoctorRegistrationRequest) {
        guard let idx = doctorRequests.firstIndex(where: { $0.id == request.id }) else { return }
        doctorRequests[idx].status = .rejected
        doctorRequests[idx].reviewedAt = Date()

        // Update the doctor's own profile if they're the current user
        if userProfile.email.lowercased() == request.email.lowercased(),
           userProfile.doctorProfile != nil {
            userProfile.doctorProfile?.verificationStatus = .rejected
        }
        save()
    }

    /// Build certifications array from registration request booleans
    private func buildCertifications(_ request: DoctorRegistrationRequest) -> [String] {
        var certs: [String] = []
        if request.goodStanding { certs.append("Certificate of Good Standing") }
        if request.plabPassed   { certs.append("PLAB/UKMLA Passed") }
        if request.ecfmgCertified { certs.append("ECFMG Certified") }
        if request.wdomListed   { certs.append("WDOM Listed") }
        return certs
    }

    // Ring colour from last purchase or cart
    var lastPurchasedRingColor: RingColor? {
        // Check order items for ring with a selected colour
        for order in orders.reversed() {
            if let ringItem = order.items.first(where: { $0.name.lowercased().contains("ring") }) {
                return ringItem.selectedColor ?? .silver
            }
        }
        // Fallback: check cart items
        if let cartRing = cartItems.first(where: { $0.name.lowercased().contains("ring") }) {
            return cartRing.selectedColor ?? .silver
        }
        return nil
    }

    // Cart helpers
    var cartCount: Int { cartItems.reduce(0) { $0 + $1.quantity } }
    var cartTotal: Double { cartItems.reduce(0) { $0 + $1.price * Double($1.quantity) } }

    func addToCart(_ product: Product) {
        if let idx = cartItems.firstIndex(where: { $0.productID == product.id }) {
            cartItems[idx].quantity += 1
        } else {
            cartItems.append(CartItem(productID: product.id, name: product.name,
                                      price: product.price, icon: product.icon, color: product.color))
        }
        save()
    }

    func addToCart(_ product: Product, color: RingColor, size: RingSize, quantity: Int) {
        let sku = "RING-X3B-\(color.rawValue.uppercased())-S\(size.shortLabel)"
        if let idx = cartItems.firstIndex(where: { $0.sku == sku }) {
            cartItems[idx].quantity += quantity
        } else {
            var item = CartItem(productID: product.id, name: product.name,
                                price: product.price, icon: product.icon, color: product.color)
            item.selectedColor = color
            item.selectedSize  = size
            item.quantity      = quantity
            item.sku           = sku
            cartItems.append(item)
        }
        save()
    }

    func removeFromCart(_ item: CartItem) {
        cartItems.removeAll { $0.id == item.id }
        save()
    }

    func decreaseCartItem(_ item: CartItem) {
        if let idx = cartItems.firstIndex(where: { $0.id == item.id }) {
            if cartItems[idx].quantity > 1 { cartItems[idx].quantity -= 1 }
            else { cartItems.remove(at: idx) }
        }
        save()
    }

    func isInCart(_ product: Product) -> Bool {
        cartItems.contains(where: { $0.productID == product.id })
    }

    // MARK: Order Helpers

    func placeOrder(paymentMethod: String, paymentIntentId: String? = nil) {
        let subtotal = cartTotal
        let shipping = subtotal >= 100 ? 0.0 : 4.99
        let num = "BS-\(Calendar.current.component(.year, from: Date()))-\(String(format: "%04d", orders.count + 1))"
        let deliveryDate = Calendar.current.date(byAdding: .day, value: Int.random(in: 3...7), to: Date())

        // Generate gift codes for any subscription add-ons
        var generatedCodes: [GiftCode] = []
        for item in cartItems {
            if let plan = item.addSubscription, plan != .free {
                for _ in 0..<item.quantity {
                    let code = GiftCode(code: GiftCode.generateCode(), plan: plan, durationMonths: 12)
                    generatedCodes.append(code)
                    giftCodes.append(code)
                }
            }
        }

        let order = Order(
            orderNumber: num,
            items: cartItems,
            subtotal: subtotal,
            shippingCost: shipping,
            total: subtotal + shipping,
            status: .confirmed,
            paymentMethod: paymentMethod,
            transactionId: paymentIntentId,
            createdAt: Date(),
            estimatedDelivery: deliveryDate,
            deliveryAddress: deliveryAddress.isComplete ? deliveryAddress : nil,
            giftCodes: generatedCodes
        )
        orders.insert(order, at: 0)
        cartItems.removeAll()
        save()

        // Schedule receipt email notification
        scheduleReceiptNotification(order: order)
    }

    /// Schedule a local notification as a "receipt email" placeholder.
    /// In production this would trigger a backend email via Stripe receipt or SendGrid.
    private func scheduleReceiptNotification(order: Order) {
        let content = UNMutableNotificationContent()
        content.title = "Order Confirmed — \(order.orderNumber)"
        content.body = "Total: \(CurrencyService.format(order.total, currencyCode: userCurrency)). " +
            "Estimated delivery: \(order.estimatedDelivery?.formatted(.dateTime.day().month()) ?? "3-7 days"). " +
            "Receipt sent to \(userProfile.email.isEmpty ? "your email" : userProfile.email)."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "receipt-\(order.orderNumber)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: Gift Code Helpers

    func redeemGiftCode(_ codeString: String) -> Bool {
        if let idx = giftCodes.firstIndex(where: { $0.code == codeString && !$0.isRedeemed }) {
            giftCodes[idx].redeemedAt = Date()
            giftCodes[idx].redeemedBy = userProfile.anonymousAlias
            subscription = giftCodes[idx].plan
            save()
            return true
        }
        return false
    }

    func cancelOrder(_ order: Order) {
        if let idx = orders.firstIndex(where: { $0.id == order.id }) {
            orders[idx].status = .cancelled
            save()
        }
    }

    var healthScore: Int {
        var score = 40  // lower base for more dynamic range
        // Glucose
        if let g = latestGlucose {
            let s = glucoseStatus(g.value)
            if s.label == "Good" || s.label == "Normal" { score += 12 }
            else if s.label == "High" || s.label == "Low" { score -= 5 }
        }
        // Blood pressure
        if let b = latestBP, b.category == .normal { score += 10 }
        // Sleep
        if let s = lastSleep, s.quality == .good || s.quality == .excellent { score += 10 }
        // Stress
        if let st = latestStress, st.level <= 4 { score += 7 }
        // Medications adherence
        let medCount = medications.filter { $0.isActive }.count
        if medCount > 0 { score += 5 }
        // Water intake
        if todayWaterML >= 2000 { score += 5 }
        // Steps
        if todaySteps >= userProfile.targetSteps { score += 8 }
        else if todaySteps >= userProfile.targetSteps / 2 { score += 4 }
        // Nutrition logged today
        let todayCals = nutritionLogs.filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.calories }
        let goal = userProfile.dailyCalorieGoal
        if todayCals > 0 && todayCals >= Int(Double(goal) * 0.8) && todayCals <= Int(Double(goal) * 1.2) {
            score += 5
        }
        // ── Critical safety override ──
        // Cap score if ANY vital is in danger zone — prevents misleading "Good" with dangerous readings
        if let g = latestGlucose, g.value > 250 || g.value < 54 { score = min(score, 40) }  // >13.9 or <3.0 mmol/L
        if let bp = latestBP, bp.systolic > 180 || bp.diastolic > 120 { score = min(score, 40) }  // Hypertensive crisis
        if let hr = latestHR, hr.value < 40 || hr.value > 150 { score = min(score, 40) }  // Dangerous HR

        return min(100, max(0, score))
    }

    // MARK: UK Glucose Display (mmol/L)

    /// Convert mg/dL (stored via HealthKit) to mmol/L (UK display standard per NHS/NICE)
    static func glucoseMmol(_ mgdl: Double) -> String {
        String(format: "%.1f", mgdl / 18.0)
    }

    /// Format glucose for UK display: "5.5 mmol/L"
    static func glucoseDisplayUK(_ mgdl: Double) -> String {
        "\(String(format: "%.1f", mgdl / 18.0)) mmol/L"
    }

    func glucoseStatus(_ v: Double) -> (label: String, color: Color) {
        // v is in mg/dL internally. Thresholds per NHS/NICE:
        // <3.9 mmol/L = Low, 3.9-5.5 = Normal, 5.6-7.8 = Good, 7.8-10.0 = High, >10.0 = Very High
        switch v {
        case ..<70:    return ("Low",      .brandCoral)    // <3.9 mmol/L
        case 70..<100: return ("Normal",   .brandGreen)    // 3.9-5.5 mmol/L
        case 100..<140:return ("Good",     .brandTeal)     // 5.6-7.8 mmol/L
        case 140..<180:return ("High",     .brandAmber)    // 7.8-10.0 mmol/L
        default:       return ("Very High",.brandCoral)    // >10.0 mmol/L
        }
    }

    // MARK: 30-Day Readings Summary

    func thirtyDayReadingsSummary() -> String {
        let cal = Calendar.current
        let cutoff = cal.date(byAdding: .day, value: -30, to: Date())!

        var lines: [String] = []
        lines.append("═══ 30-DAY HEALTH READINGS SUMMARY ═══")
        lines.append("Patient: \(userProfile.name)")
        lines.append("Condition: \(userProfile.diabetesType)")
        lines.append("Generated: \(Date().formatted(date: .long, time: .shortened))")
        lines.append("")

        // Glucose
        let glu = glucoseReadings.filter { $0.date >= cutoff }
        if !glu.isEmpty {
            let avg = glu.map { $0.value }.reduce(0, +) / Double(glu.count)
            let minG = glu.map { $0.value }.min() ?? 0
            let maxG = glu.map { $0.value }.max() ?? 0
            lines.append("── GLUCOSE (\(glu.count) readings) ──")
            lines.append("  Average: \(Int(avg)) mg/dL")
            lines.append("  Range: \(Int(minG)) – \(Int(maxG)) mg/dL")
            for r in glu.sorted(by: { $0.date > $1.date }).prefix(10) {
                lines.append("  • \(r.date.formatted(date: .abbreviated, time: .shortened)): \(Int(r.value)) mg/dL (\(r.context.rawValue))")
            }
            lines.append("")
        }

        // Blood Pressure
        let bp = bpReadings.filter { $0.date >= cutoff }
        if !bp.isEmpty {
            let avgSys = bp.map { $0.systolic }.reduce(0, +) / bp.count
            let avgDia = bp.map { $0.diastolic }.reduce(0, +) / bp.count
            lines.append("── BLOOD PRESSURE (\(bp.count) readings) ──")
            lines.append("  Average: \(avgSys)/\(avgDia) mmHg")
            for r in bp.sorted(by: { $0.date > $1.date }).prefix(10) {
                lines.append("  • \(r.date.formatted(date: .abbreviated, time: .shortened)): \(r.systolic)/\(r.diastolic) mmHg, pulse \(r.pulse) — \(r.category.rawValue)")
            }
            lines.append("")
        }

        // Heart Rate
        let hr = heartRateReadings.filter { $0.date >= cutoff }
        if !hr.isEmpty {
            let avg = hr.map { $0.value }.reduce(0, +) / hr.count
            lines.append("── HEART RATE (\(hr.count) readings) ──")
            lines.append("  Average: \(avg) bpm")
            for r in hr.sorted(by: { $0.date > $1.date }).prefix(5) {
                lines.append("  • \(r.date.formatted(date: .abbreviated, time: .shortened)): \(r.value) bpm (\(r.context.rawValue))")
            }
            lines.append("")
        }

        // HRV
        let hrv = hrvReadings.filter { $0.date >= cutoff }
        if !hrv.isEmpty {
            let avg = hrv.map { $0.value }.reduce(0, +) / Double(hrv.count)
            lines.append("── HRV (\(hrv.count) readings) ──")
            lines.append("  Average: \(Int(avg)) ms")
            lines.append("")
        }

        // Sleep
        let sl = sleepEntries.filter { $0.date >= cutoff }
        if !sl.isEmpty {
            let avgDur = sl.map { $0.duration }.reduce(0, +) / Double(sl.count)
            lines.append("── SLEEP (\(sl.count) entries) ──")
            lines.append("  Average duration: \(String(format: "%.1f", avgDur)) hrs")
            for r in sl.sorted(by: { $0.date > $1.date }).prefix(5) {
                lines.append("  • \(r.date.formatted(date: .abbreviated, time: .omitted)): \(String(format: "%.1f", r.duration))h — \(r.quality.rawValue)")
            }
            lines.append("")
        }

        // Stress
        let st = stressReadings.filter { $0.date >= cutoff }
        if !st.isEmpty {
            let avg = st.map { $0.level }.reduce(0, +) / st.count
            lines.append("── STRESS (\(st.count) readings) ──")
            lines.append("  Average level: \(avg)/10")
            lines.append("")
        }

        // Symptoms
        let sym = symptomLogs.filter { $0.date >= cutoff }
        if !sym.isEmpty {
            let allSyms = sym.flatMap { $0.symptoms }
            let freq = Dictionary(grouping: allSyms, by: { $0 }).mapValues { $0.count }.sorted { $0.value > $1.value }
            lines.append("── SYMPTOMS (\(sym.count) logs) ──")
            for (name, count) in freq.prefix(8) {
                lines.append("  • \(name): \(count)×")
            }
            lines.append("")
        }

        // Medications
        let activeMeds = medications.filter { $0.isActive }
        if !activeMeds.isEmpty {
            lines.append("── ACTIVE MEDICATIONS ──")
            for med in activeMeds {
                let recentLogs = med.logs.filter { $0.date >= cutoff }
                let taken = recentLogs.filter { $0.taken }.count
                let total = recentLogs.count
                let adherence = total > 0 ? Int(Double(taken) / Double(total) * 100) : 0
                lines.append("  • \(med.name) \(med.dosage)\(med.unit) — \(med.frequency.rawValue) — \(adherence)% adherence")
            }
            lines.append("")
        }

        // Steps
        let steps = stepEntries.filter { $0.date >= cutoff }
        if !steps.isEmpty {
            let avgSteps = steps.map { $0.steps }.reduce(0, +) / steps.count
            lines.append("── STEPS (\(steps.count) days) ──")
            lines.append("  Daily average: \(avgSteps) steps")
            lines.append("")
        }

        // Water
        let water = waterEntries.filter { $0.date >= cutoff }
        if !water.isEmpty {
            let totalL = water.map { $0.amount }.reduce(0, +) / 1000
            let waterDays = Set(water.map { cal.startOfDay(for: $0.date) }).count
            let dailyAvg = waterDays > 0 ? water.map { $0.amount }.reduce(0, +) / Double(waterDays) : 0
            lines.append("── WATER (\(water.count) entries) ──")
            lines.append("  Total 30-day intake: \(String(format: "%.1f", totalL)) L")
            lines.append("  Daily average: \(Int(dailyAvg)) ml (target: \(Int(userProfile.targetWater * 1000)) ml)")
            lines.append("")
        }

        // Body Temperature
        let temps = bodyTempReadings.filter { $0.date >= cutoff }
        if !temps.isEmpty {
            let avg = temps.map { $0.value }.reduce(0, +) / Double(temps.count)
            let feverEpisodes = temps.filter { $0.value > 37.5 }
            lines.append("── BODY TEMPERATURE (\(temps.count) readings) ──")
            lines.append("  Average: \(String(format: "%.1f", avg))°C")
            if !feverEpisodes.isEmpty {
                lines.append("  ⚠️ Fever episodes (>37.5°C): \(feverEpisodes.count)")
                for f in feverEpisodes.sorted(by: { $0.date > $1.date }).prefix(3) {
                    lines.append("    • \(f.date.formatted(date: .abbreviated, time: .shortened)): \(String(format: "%.1f", f.value))°C")
                }
            }
            lines.append("")
        }

        // Nutrition Details
        let nutr = nutritionLogs.filter { $0.date >= cutoff }
        if !nutr.isEmpty {
            let avgCal = nutr.map { $0.calories }.reduce(0, +) / nutr.count
            let avgCarbs = nutr.map { Double($0.carbs) }.reduce(0, +) / Double(nutr.count)
            let avgProtein = nutr.map { Double($0.protein) }.reduce(0, +) / Double(nutr.count)
            let avgFat = nutr.map { Double($0.fat) }.reduce(0, +) / Double(nutr.count)
            let avgSugar = nutr.map { Double($0.sugar) }.reduce(0, +) / Double(nutr.count)
            let avgSalt = nutr.map { $0.salt }.reduce(0, +) / Double(nutr.count)
            lines.append("── NUTRITION (\(nutr.count) meals logged) ──")
            lines.append("  Average per meal: \(avgCal) kcal")
            lines.append("  Macros avg: \(Int(avgCarbs))g carbs, \(Int(avgProtein))g protein, \(Int(avgFat))g fat")
            lines.append("  Sugar: \(Int(avgSugar))g (NHS limit: 30g/day), Salt: \(String(format: "%.1f", avgSalt))g (NHS limit: 6g/day)")
            lines.append("")
        }

        // Cycle Tracking
        let cyc = cycles.filter { $0.startDate >= cutoff }
        if !cyc.isEmpty {
            lines.append("── MENSTRUAL CYCLE (\(cyc.count) entries) ──")
            for c in cyc.sorted(by: { $0.startDate > $1.startDate }).prefix(5) {
                let endStr = c.endDate.map { " to \($0.formatted(date: .abbreviated, time: .omitted))" } ?? " (ongoing)"
                lines.append("  • \(c.startDate.formatted(date: .abbreviated, time: .omitted))\(endStr) — Flow: \(c.flow.rawValue)")
                if !c.symptoms.isEmpty {
                    lines.append("    Symptoms: \(c.symptoms.prefix(5).joined(separator: ", "))")
                }
            }
            lines.append("")
        }

        // Prescriptions
        if !prescriptions.isEmpty {
            lines.append("── PRESCRIPTIONS (\(prescriptions.count)) ──")
            for rx in prescriptions.sorted(by: { $0.date > $1.date }).prefix(5) {
                lines.append("  • \(rx.date.formatted(date: .abbreviated, time: .omitted)): \(rx.diagnosis)")
                lines.append("    Doctor: \(rx.doctorName)")
                lines.append("    Medications: \(rx.medications.joined(separator: ", "))")
                if rx.validUntil > Date() {
                    lines.append("    Valid until: \(rx.validUntil.formatted(date: .abbreviated, time: .omitted))")
                } else {
                    lines.append("    ⚠️ Expired: \(rx.validUntil.formatted(date: .abbreviated, time: .omitted))")
                }
            }
            lines.append("")
        }

        // Health Goals
        let activeGoals = healthGoals.filter { !$0.isCompleted }
        if !activeGoals.isEmpty {
            lines.append("── ACTIVE HEALTH GOALS ──")
            for g in activeGoals.prefix(5) {
                let pct = Int(g.progress * 100)
                lines.append("  • \(g.title): \(pct)% (\(String(format: "%.0f", g.currentValue))/\(String(format: "%.0f", g.targetValue)) \(g.unit))")
            }
            let completedCount = healthGoals.filter { $0.isCompleted }.count
            if completedCount > 0 {
                lines.append("  ✅ Completed goals: \(completedCount)")
            }
            lines.append("")
        }

        if lines.count <= 5 {
            lines.append("No health data recorded in the last 30 days.")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: Currency & Identity

    /// User's currency code based on profile country
    var userCurrency: String { userProfile.currencyCode }

    /// Generate anonymous alias once, persist it
    func ensureAnonymousAlias() {
        guard userProfile.anonymousAlias.isEmpty else { return }
        let adjectives = ["Healthy", "Active", "Brave", "Calm", "Bright", "Strong", "Mindful", "Steady", "Vibrant", "Gentle"]
        let nouns = ["Hero", "Walker", "Star", "Phoenix", "Warrior", "Runner", "Champion", "Spirit", "Tiger", "Eagle"]
        let adj = adjectives.randomElement()!
        let noun = nouns.randomElement()!
        let num = Int.random(in: 10...99)
        userProfile.anonymousAlias = "\(adj)\(noun)_\(num)"

        let colors = ["#6C63FF", "#FF6B6B", "#4ECDC4", "#FF9F43", "#26de81", "#4834d4", "#e056fd", "#22a6b3", "#f9ca24", "#eb4d4b"]
        userProfile.anonymousColor = colors.randomElement()!
        save()
    }

    // MARK: Persistence
    private let defaults = UserDefaults.standard
    private init() {
        load()
        migrateToEncryptedIfNeeded()
    }

    func save() {
        func enc<T: Encodable>(_ v: T, key: String) {
            guard let jsonData = try? JSONEncoder().encode(v) else { return }
            if let encrypted = try? EncryptedStore.encrypt(jsonData) {
                defaults.set(encrypted, forKey: key)
            } else {
                print("⚠️ SECURITY: Encryption failed for \(key) — data NOT saved")
            }
        }
        enc(glucoseReadings,   key: "glucoseReadings")
        enc(bpReadings,        key: "bpReadings")
        enc(heartRateReadings, key: "heartRateReadings")
        enc(hrvReadings,       key: "hrvReadings")
        enc(sleepEntries,      key: "sleepEntries")
        enc(stressReadings,    key: "stressReadings")
        enc(bodyTempReadings,  key: "bodyTempReadings")
        enc(stepEntries,       key: "stepEntries")
        enc(waterEntries,      key: "waterEntries")
        enc(nutritionLogs,     key: "nutritionLogs")
        enc(symptomLogs,       key: "symptomLogs")
        enc(medications,       key: "medications")
        enc(cycles,            key: "cycles")
        enc(healthAlerts,      key: "healthAlerts")
        enc(healthGoals,       key: "healthGoals")
        enc(healthChallenges,  key: "healthChallenges")
        enc(achievements,      key: "achievements")
        enc(userStreaks,        key: "userStreaks")
        enc(communityGroups,   key: "communityGroups")
        enc(doctors,           key: "doctors")
        enc(appointments,      key: "appointments")
        enc(prescriptions,     key: "prescriptions")
        enc(subscription,      key: "subscription")
        enc(medicalRecords,  key: "medicalRecords")
        enc(doctorReviews,   key: "doctorReviews")
        enc(doctorRequests,  key: "doctorRequests")
        enc(products,          key: "products")
        enc(cartItems,         key: "cartItems")
        enc(orders,            key: "orders")
        enc(wearableDevices,   key: "wearableDevices")
        enc(userProfile,       key: "userProfile")
        enc(supportTickets,    key: "supportTickets")
        enc(chatHistories,     key: "chatHistories")
        defaults.set(totalXP,  forKey: "totalXP")
    }

    // MARK: - Reset (Account Deletion)

    /// Clear all in-memory data and persisted storage. Used during account deletion.
    func resetAllData() {
        // Core health data
        glucoseReadings = []
        bpReadings = []
        heartRateReadings = []
        hrvReadings = []
        sleepEntries = []
        stressReadings = []
        bodyTempReadings = []
        stepEntries = []
        waterEntries = []
        nutritionLogs = []
        symptomLogs = []
        medications = []
        cycles = []

        // AI coaching & goals
        healthAlerts = []
        healthGoals = []
        healthChallenges = []
        achievements = []
        userStreaks = []
        dailyGuidance = nil
        totalXP = 0

        // Community & telemedicine
        communityGroups = []
        doctors = []
        appointments = []
        prescriptions = []

        // Shop & subscription
        subscription = .free
        products = []
        cartItems = []
        orders = []
        wearableDevices = []
        giftCodes = []
        deliveryAddress = DeliveryAddress()

        // Medical records & reviews
        medicalRecords = []
        doctorReviews = []

        // Support & chat history
        supportTickets = []
        chatHistories = []

        // Profile
        userProfile = UserProfile()

        // Persist the empty state
        save()
    }

    private func load() {
        func dec<T: Decodable>(_ type: T.Type, key: String) -> T? {
            guard let stored = defaults.data(forKey: key) else { return nil }
            // Try decrypting first (new encrypted format)
            if EncryptedStore.isEncrypted(stored),
               let decrypted = try? EncryptedStore.decrypt(stored),
               let decoded = try? JSONDecoder().decode(type, from: decrypted) {
                return decoded
            }
            // Fallback: try reading as plain JSON (legacy unencrypted data)
            return try? JSONDecoder().decode(type, from: stored)
        }
        glucoseReadings   = dec([GlucoseReading].self,   key: "glucoseReadings")   ?? []
        bpReadings        = dec([BPReading].self,         key: "bpReadings")        ?? []
        heartRateReadings = dec([HeartRateReading].self,  key: "heartRateReadings") ?? []
        hrvReadings       = dec([HRVReading].self,        key: "hrvReadings")       ?? []
        sleepEntries      = dec([SleepEntry].self,        key: "sleepEntries")      ?? []
        stressReadings    = dec([StressReading].self,     key: "stressReadings")    ?? []
        bodyTempReadings  = dec([BodyTempReading].self,   key: "bodyTempReadings")  ?? []
        stepEntries       = dec([StepEntry].self,         key: "stepEntries")       ?? []
        waterEntries      = dec([WaterEntry].self,        key: "waterEntries")      ?? []
        nutritionLogs     = dec([NutritionLog].self,      key: "nutritionLogs")     ?? []
        symptomLogs       = dec([SymptomLog].self,        key: "symptomLogs")       ?? []
        medications       = dec([Medication].self,        key: "medications")       ?? []
        cycles            = dec([CycleEntry].self,        key: "cycles")            ?? []
        healthAlerts      = dec([HealthAlert].self,       key: "healthAlerts")      ?? []
        healthGoals       = dec([HealthGoal].self,        key: "healthGoals")       ?? []
        healthChallenges  = dec([HealthChallenge].self,   key: "healthChallenges")  ?? []
        achievements      = dec([Achievement].self,       key: "achievements")      ?? []
        userStreaks        = dec([UserStreak].self,        key: "userStreaks")        ?? []
        communityGroups   = dec([CommunityGroup].self,    key: "communityGroups")   ?? []
        doctors           = dec([Doctor].self,            key: "doctors")           ?? []
        appointments      = dec([Appointment].self,       key: "appointments")      ?? []
        prescriptions     = dec([Prescription].self,      key: "prescriptions")     ?? []
        subscription      = dec(SubscriptionPlan.self,    key: "subscription")      ?? .free
        medicalRecords   = dec([MedicalRecord].self,   key: "medicalRecords")   ?? []
        doctorReviews    = dec([DoctorReview].self,    key: "doctorReviews")    ?? []
        doctorRequests   = dec([DoctorRegistrationRequest].self, key: "doctorRequests") ?? []
        products          = dec([Product].self,           key: "products")          ?? []
        cartItems         = dec([CartItem].self,          key: "cartItems")         ?? []
        orders            = dec([Order].self,             key: "orders")            ?? []
        wearableDevices   = dec([WearableDevice].self,    key: "wearableDevices")   ?? []
        userProfile       = dec(UserProfile.self,         key: "userProfile")       ?? UserProfile()
        supportTickets    = dec([SupportTicketRecord].self, key: "supportTickets")  ?? []
        chatHistories     = dec([ChatHistoryRecord].self,   key: "chatHistories")   ?? []
        totalXP           = defaults.integer(forKey: "totalXP")

        if products.isEmpty       { seedProducts() }     // always ensure products are present
    }

    /// One-time migration: re-save all data encrypted.
    /// Runs once after update from unencrypted version.
    private func migrateToEncryptedIfNeeded() {
        let migrationKey = "encryptionMigrationV1Done"
        guard !defaults.bool(forKey: migrationKey) else { return }
        // Re-save triggers the encrypted enc() helper
        save()
        defaults.set(true, forKey: migrationKey)
    }

    // MARK: - Product CRUD (CEO)

    func addProduct(_ product: Product) {
        products.append(product)
        save()
    }

    func updateProduct(_ product: Product) {
        if let idx = products.firstIndex(where: { $0.id == product.id }) {
            products[idx] = product
            save()
        }
    }

    func deleteProduct(_ product: Product) {
        products.removeAll { $0.id == product.id }
        save()
    }

    // MARK: - Seed Products (always run if missing)
    private func seedProducts() {
        products = [
            Product(name: "BodySense Ring",
                    description: "Medical-grade X3B smart ring — SpO2, sleep apnea detection, HRV, heart rate, skin temperature, stress & menstrual tracking. IP68 waterproof. 7–10 day battery. Available in Silver, Black, Gold.",
                    price: 129, originalPrice: 399, category: .ring, icon: "circle.fill", color: "#6C63FF",
                    reviews: 1240, isNew: false, isBestSeller: true,
                    availableColors: [.silver, .black, .gold], sizeName: "X3B (Med)"),
            Product(name: "Premium Charging Dock",
                    description: "Wireless magnetic charging dock for BodySense Ring. LED status indicator. USB-C powered. Charges to 100% in under 2 hours.",
                    price: 29, originalPrice: 45, category: .accessories, icon: "bolt.circle.fill", color: "#FF9F43",
                    reviews: 320, isNew: false, isBestSeller: false),
            Product(name: "BodySense Ring Case",
                    description: "Premium protective travel case for BodySense Ring. Shock-resistant, compact, includes charging cable holder.",
                    price: 15, originalPrice: 22, category: .accessories, icon: "case.fill", color: "#4ECDC4",
                    reviews: 156, isNew: true, isBestSeller: false),
            Product(name: "Glucose Test Strips (100pk)",
                    description: "Precision glucose test strips — compatible with all major meters. 18-month shelf life. Sterile, individually wrapped.",
                    price: 29, originalPrice: 35, category: .devices, icon: "drop.fill", color: "#FF6B6B",
                    reviews: 890, isNew: false, isBestSeller: false),
            Product(name: "BodySense Nutrition Kit",
                    description: "30-day metabolic health supplement pack: omega-3, vitamin D3, magnesium glycinate, chromium picolinate. Clinically formulated.",
                    price: 49, originalPrice: 65, category: .nutrition, icon: "pill.fill", color: "#26de81",
                    reviews: 423, isNew: true, isBestSeller: false),
        ]
        save()
    }

}
