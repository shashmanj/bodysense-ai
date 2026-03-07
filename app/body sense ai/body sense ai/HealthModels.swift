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

// MARK: - Brand Colors

extension Color {
    static let brandPurple  = Color(hex: "#6C63FF")
    static let brandTeal    = Color(hex: "#4ECDC4")
    static let brandCoral   = Color(hex: "#FF6B6B")
    static let brandAmber   = Color(hex: "#FF9F43")
    static let brandGreen   = Color(hex: "#26de81")
    static let brandBg      = Color(hex: "#F5F6FA")
    static let cardBg       = Color.white

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
        case .poor: return "😴"; case .fair: return "😐"; case .good: return "😊"; case .excellent: return "🌟"
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
    var distance      : Double  // km
    var calories      : Int
    var activeMinutes : Int
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

let allSymptoms = [
    "Fatigue", "Headache", "Dizziness", "Nausea", "Blurred Vision",
    "Frequent Urination", "Excessive Thirst", "Tingling/Numbness",
    "Chest Pain", "Shortness of Breath", "Heart Palpitations",
    "Bloating", "Loss of Appetite", "Muscle Weakness", "Flushing",
    "Cold Sweats", "Dry Mouth", "Joint Pain", "Mood Swings", "Brain Fog"
]

// MARK: - Medication

struct Medication: Codable, Identifiable, Equatable {
    var id        = UUID()
    var name      : String
    var dosage    : String
    var unit      : String    = "mg"
    var frequency : MedFrequency
    var timeOfDay : [MedTime]
    var isActive  : Bool      = true
    var color     : String    = "#6C63FF"
    var logs      : [MedLog]  = []
    static func == (lhs: Medication, rhs: Medication) -> Bool { lhs.id == rhs.id }
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
    var verificationStatus   : String  = "Pending" // "Pending", "Under Review", "Verified", "Rejected"
    var stripeAccountId      : String  = ""    // Stripe Connect account for payouts

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
    var paymentIntentId : String? = nil     // Stripe PaymentIntent ID
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

    /// Localized price
    func priceString(currencyCode: String) -> String {
        CurrencyService.format(price, currencyCode: currencyCode)
    }
    /// Localized original price
    func originalPriceString(currencyCode: String) -> String {
        CurrencyService.format(originalPrice, currencyCode: currencyCode)
    }
    var isRing: Bool { category == .ring && !availableColors.isEmpty }
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
    var stripePaymentIntentId: String?
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

// MARK: - User Profile

struct UserProfile: Codable {
    var name             : String  = ""
    var age              : Int     = 30
    var gender           : String  = "Female"
    var diabetesType     : String  = "Type 2 Diabetes"
    var hasHypertension  : Bool    = true
    var targetGlucoseMin : Double  = 80
    var targetGlucoseMax : Double  = 140
    var targetSystolic   : Int     = 130
    var targetDiastolic  : Int     = 85
    var weight           : Double  = 70
    var height           : Double  = 165
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

    // ── Profile ───────────────────────────────────────────────────────────────
    var userProfile      : UserProfile       = UserProfile()

    // Convenience
    var isDoctor: Bool { userProfile.isDoctor }
    var doctorProfile: DoctorProfile? { userProfile.doctorProfile }

    // MARK: Computed convenience

    var latestGlucose : GlucoseReading?   { glucoseReadings.sorted  { $0.date > $1.date }.first }
    var latestBP      : BPReading?        { bpReadings.sorted       { $0.date > $1.date }.first }
    var latestHR      : HeartRateReading? { heartRateReadings.sorted{ $0.date > $1.date }.first }
    var latestHRV     : HRVReading?       { hrvReadings.sorted      { $0.date > $1.date }.first }
    var lastSleep     : SleepEntry?       { sleepEntries.sorted     { $0.date > $1.date }.first }
    var latestStress  : StressReading?    { stressReadings.sorted   { $0.date > $1.date }.first }
    var latestTemp    : BodyTempReading?  { bodyTempReadings.sorted { $0.date > $1.date }.first }

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
            stripePaymentIntentId: paymentIntentId,
            createdAt: Date(),
            estimatedDelivery: deliveryDate,
            deliveryAddress: deliveryAddress.isComplete ? deliveryAddress : nil,
            giftCodes: generatedCodes
        )
        orders.insert(order, at: 0)
        cartItems.removeAll()
        save()
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
        var score = 60
        if let g = latestGlucose {
            let s = glucoseStatus(g.value)
            if s.label == "Good" || s.label == "Normal" { score += 10 }
            else if s.label == "High" || s.label == "Low" { score -= 5 }
        }
        if let b = latestBP, b.category == .normal { score += 10 }
        if let s = lastSleep, s.quality == .good || s.quality == .excellent { score += 8 }
        if let st = latestStress, st.level <= 4 { score += 7 }
        let medCount = medications.filter { $0.isActive }.count
        if medCount > 0 { score += 5 }
        return min(100, max(0, score))
    }

    func glucoseStatus(_ v: Double) -> (label: String, color: Color) {
        switch v {
        case ..<70:    return ("Low",      .brandCoral)
        case 70..<100: return ("Normal",   .brandGreen)
        case 100..<140:return ("Good",     .brandTeal)
        case 140..<180:return ("High",     .brandAmber)
        default:       return ("Very High",.brandCoral)
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
            lines.append("── WATER ──")
            lines.append("  Total 30-day intake: \(String(format: "%.1f", totalL)) L")
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
    private init() { load() }

    func save() {
        func enc<T: Encodable>(_ v: T, key: String) {
            if let d = try? JSONEncoder().encode(v) { defaults.set(d, forKey: key) }
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
        enc(products,          key: "products")
        enc(cartItems,         key: "cartItems")
        enc(orders,            key: "orders")
        enc(wearableDevices,   key: "wearableDevices")
        enc(userProfile,       key: "userProfile")
        defaults.set(totalXP,  forKey: "totalXP")
    }

    private func load() {
        func dec<T: Decodable>(_ type: T.Type, key: String) -> T? {
            guard let d = defaults.data(forKey: key) else { return nil }
            return try? JSONDecoder().decode(type, from: d)
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
        products          = dec([Product].self,           key: "products")          ?? []
        cartItems         = dec([CartItem].self,          key: "cartItems")         ?? []
        orders            = dec([Order].self,             key: "orders")            ?? []
        wearableDevices   = dec([WearableDevice].self,    key: "wearableDevices")   ?? []
        userProfile       = dec(UserProfile.self,         key: "userProfile")       ?? UserProfile()
        totalXP           = defaults.integer(forKey: "totalXP")

        if glucoseReadings.isEmpty { seedSampleData() }
        if products.isEmpty       { seedProducts() }     // always ensure products are present
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

    // MARK: Seed Data
    private func seedSampleData() {
        let now = Date()
        let cal = Calendar.current

        // ── Glucose & BP (14 days) ───────────────────────────────────────────
        for i in 0..<14 {
            let d = cal.date(byAdding: .day, value: -i, to: now)!
            glucoseReadings.append(GlucoseReading(value: Double.random(in: 95...155), date: d, context: .random))
            bpReadings.append(BPReading(systolic: Int.random(in: 118...142), diastolic: Int.random(in: 76...92), pulse: Int.random(in: 62...82), date: d))
        }

        // ── Heart Rate & HRV (14 days) ───────────────────────────────────────
        for i in 0..<14 {
            let d = cal.date(byAdding: .day, value: -i, to: now)!
            heartRateReadings.append(HeartRateReading(value: Int.random(in: 58...82), date: d, context: .rest))
            hrvReadings.append(HRVReading(value: Double.random(in: 28...65), date: d))
        }

        // ── Sleep (14 days) ──────────────────────────────────────────────────
        let qualities: [SleepQuality] = [.good, .fair, .excellent, .good, .poor, .good, .good, .fair, .excellent, .good, .fair, .good, .good, .excellent]
        for i in 0..<14 {
            let d = cal.date(byAdding: .day, value: -i, to: now)!
            let dur = Double.random(in: 5.5...8.5)
            sleepEntries.append(SleepEntry(date: d, duration: dur, quality: qualities[i], deepSleep: dur * 0.2, remSleep: dur * 0.25, lightSleep: dur * 0.55, awakenings: Int.random(in: 0...3)))
        }

        // ── Stress (7 days) ──────────────────────────────────────────────────
        for i in 0..<7 {
            let d = cal.date(byAdding: .day, value: -i, to: now)!
            stressReadings.append(StressReading(level: Int.random(in: 2...8), date: d, trigger: StressTrigger.allCases.randomElement()!))
        }

        // ── Body Temperature ─────────────────────────────────────────────────
        for i in 0..<7 {
            let d = cal.date(byAdding: .day, value: -i, to: now)!
            bodyTempReadings.append(BodyTempReading(value: Double.random(in: 36.4...37.2), date: d))
        }

        // ── Steps (14 days) ──────────────────────────────────────────────────
        for i in 0..<14 {
            let d = cal.date(byAdding: .day, value: -i, to: now)!
            let s = Int.random(in: 4500...11000)
            stepEntries.append(StepEntry(date: d, steps: s, distance: Double(s) * 0.00078, calories: s / 20, activeMinutes: Int.random(in: 20...60)))
        }

        // ── Water today ──────────────────────────────────────────────────────
        waterEntries.append(WaterEntry(date: cal.date(byAdding: .hour, value: -2, to: now)!, amount: 500))
        waterEntries.append(WaterEntry(date: cal.date(byAdding: .hour, value: -4, to: now)!, amount: 300))

        // ── Medications ──────────────────────────────────────────────────────
        medications = [
            Medication(name: "Metformin",   dosage: "500", unit: "mg", frequency: .twice,  timeOfDay: [.morning, .evening]),
            Medication(name: "Amlodipine",  dosage: "5",   unit: "mg", frequency: .daily,  timeOfDay: [.morning], color: "#4ECDC4"),
            Medication(name: "Losartan",    dosage: "50",  unit: "mg", frequency: .daily,  timeOfDay: [.morning], color: "#FF9F43")
        ]

        // ── Health Alerts ────────────────────────────────────────────────────
        healthAlerts = [
            HealthAlert(date: cal.date(byAdding: .hour, value: -1, to: now)!, type: .highGlucose, title: "Glucose above target", message: "Your last reading was 162 mg/dL. Consider a short walk to bring it down.", isRead: false, actionLabel: "View tips"),
            HealthAlert(date: cal.date(byAdding: .hour, value: -3, to: now)!, type: .missedMed, title: "Metformin reminder", message: "You haven't logged your evening Metformin dose yet.", isRead: false, actionLabel: "Log now"),
            HealthAlert(date: cal.date(byAdding: .day, value: -1, to: now)!, type: .achievement, title: "7-Day Streak! 🔥", message: "You've logged glucose for 7 consecutive days. +50 XP earned!", isRead: true, actionLabel: "View achievements"),
        ]

        // ── Goals ────────────────────────────────────────────────────────────
        healthGoals = [
            HealthGoal(type: .steps,   title: "Walk 8,000 steps daily",       targetValue: 8000,  currentValue: Double(todaySteps), unit: "steps",  deadline: cal.date(byAdding: .day, value: 30, to: now)!),
            HealthGoal(type: .sleep,   title: "Sleep 7+ hours nightly",        targetValue: 7,     currentValue: lastSleep?.duration ?? 0, unit: "hrs", deadline: cal.date(byAdding: .day, value: 30, to: now)!),
            HealthGoal(type: .weight,  title: "Reach 68kg target weight",      targetValue: 68,    currentValue: userProfile.weight, unit: "kg",     deadline: cal.date(byAdding: .day, value: 90, to: now)!),
            HealthGoal(type: .glucose, title: "Keep glucose in range 80%",     targetValue: 80,    currentValue: 65, unit: "%",   deadline: cal.date(byAdding: .day, value: 30, to: now)!),
            HealthGoal(type: .water,   title: "Drink 2.5L water daily",        targetValue: 2500,  currentValue: todayWaterML, unit: "ml", deadline: cal.date(byAdding: .day, value: 7, to: now)!),
        ]

        // ── Challenges ───────────────────────────────────────────────────────
        healthChallenges = [
            HealthChallenge(title: "7-Day Step Challenge",     description: "Walk 7,000+ steps every day for a week",   type: .weekly,    targetValue: 49000, currentValue: 32000, reward: 200, startDate: cal.date(byAdding: .day, value: -3, to: now)!, endDate: cal.date(byAdding: .day, value: 4,  to: now)!, isJoined: true,  participants: 1248),
            HealthChallenge(title: "Glucose Log Streak",       description: "Log glucose every day for 14 days",          type: .milestone, targetValue: 14,    currentValue: 7,     reward: 150, startDate: cal.date(byAdding: .day, value: -7, to: now)!, endDate: cal.date(byAdding: .day, value: 7,  to: now)!, isJoined: true,  participants: 892),
            HealthChallenge(title: "Hydration Hero",           description: "Drink 2.5L of water daily for 5 days",      type: .daily,     targetValue: 5,     currentValue: 2,     reward: 100, startDate: cal.date(byAdding: .day, value: -1, to: now)!, endDate: cal.date(byAdding: .day, value: 4,  to: now)!, isJoined: false, participants: 3410),
            HealthChallenge(title: "Mindful Medication Month", description: "Take all medications on time for 30 days",   type: .milestone, targetValue: 30,    currentValue: 12,    reward: 300, startDate: cal.date(byAdding: .day, value: -12,to: now)!, endDate: cal.date(byAdding: .day, value: 18, to: now)!, isJoined: true,  participants: 567),
            HealthChallenge(title: "Sleep Champion",           description: "Log 7+ hours of sleep for 7 days",           type: .weekly,    targetValue: 7,     currentValue: 4,     reward: 175, startDate: now, endDate: cal.date(byAdding: .day, value: 7, to: now)!, isJoined: false, participants: 2100),
        ]

        // ── Achievements ─────────────────────────────────────────────────────
        achievements = [
            Achievement(title: "First Reading",   description: "Logged your first glucose reading",  icon: "drop.fill",         color: "#6C63FF", xp: 10,  earnedDate: cal.date(byAdding: .day, value: -14, to: now), isEarned: true,  category: .tracking),
            Achievement(title: "7-Day Streak",    description: "Logged readings 7 days in a row",    icon: "flame.fill",         color: "#FF6B6B", xp: 50,  earnedDate: cal.date(byAdding: .day, value: -7,  to: now), isEarned: true,  category: .tracking),
            Achievement(title: "Glucose Guru",    description: "Kept glucose in range for 5 days",   icon: "star.fill",          color: "#26de81", xp: 75,  earnedDate: cal.date(byAdding: .day, value: -3,  to: now), isEarned: true,  category: .vitals),
            Achievement(title: "Pill Perfect",    description: "Never missed a dose for 7 days",     icon: "pill.fill",          color: "#4ECDC4", xp: 60,  earnedDate: nil, isEarned: false, category: .medication),
            Achievement(title: "Community Star",  description: "Joined 3 community groups",          icon: "person.3.fill",      color: "#FF9F43", xp: 40,  earnedDate: nil, isEarned: false, category: .social),
            Achievement(title: "Goal Crusher",    description: "Completed your first health goal",   icon: "checkmark.seal.fill",color: "#6C63FF", xp: 100, earnedDate: nil, isEarned: false, category: .goals),
            Achievement(title: "Sleep Champ",     description: "Logged 7+ hours for 5 nights",       icon: "bed.double.fill",    color: "#4834d4", xp: 50,  earnedDate: nil, isEarned: false, category: .tracking),
            Achievement(title: "10K Steps",       description: "Walked 10,000+ steps in a day",      icon: "figure.walk",        color: "#26de81", xp: 80,  earnedDate: nil, isEarned: false, category: .goals),
            Achievement(title: "Early Bird",      description: "Logged readings before 8 AM 5 times",icon: "sunrise.fill",       color: "#FF9F43", xp: 30,  earnedDate: nil, isEarned: false, category: .special),
            Achievement(title: "30-Day Champion", description: "Used the app every day for 30 days", icon: "crown.fill",         color: "#FF6B6B", xp: 200, earnedDate: nil, isEarned: false, category: .special),
        ]
        totalXP = achievements.filter { $0.isEarned }.reduce(0) { $0 + $1.xp }

        // ── Streaks ──────────────────────────────────────────────────────────
        userStreaks = StreakType.allCases.map {
            UserStreak(type: $0, currentCount: Int.random(in: 1...14), longestCount: Int.random(in: 7...21))
        }

        // ── Community Groups ─────────────────────────────────────────────────
        communityGroups = [
            CommunityGroup(name: "Type 2 Diabetes Warriors", description: "Support and tips for managing Type 2 Diabetes day-to-day", category: .diabetes, memberCount: 12450, isJoined: true, icon: "drop.fill", color: "#6C63FF",
                posts: [
                    CommunityPost(author: "HealthyHero_42", initials: "HH", avatarColor: "#FF6B6B", content: "Just got my HbA1c down to 6.8% from 8.2% in 3 months! Consistency with meals and walking made all the difference.", date: cal.date(byAdding: .hour, value: -2, to: now)!, likes: 142, comments: 28, tag: "Success Story",
                        activityData: SharedActivityData(steps: 8420, distance: 6.5, calories: 340, activeMinutes: 45, date: cal.date(byAdding: .hour, value: -2, to: now)!)),
                    CommunityPost(author: "ActiveWalker_17", initials: "AW", avatarColor: "#4ECDC4", content: "Tip: A 15-min walk right after dinner drops my glucose by about 25-30 mg/dL every time. Try it!", date: cal.date(byAdding: .hour, value: -5, to: now)!, likes: 89, comments: 15, tag: "Tip"),
                    CommunityPost(author: "BrightStar_53", initials: "BS", avatarColor: "#FF9F43", content: "Anyone else find that stress at work shoots their glucose up even without eating anything? How do you manage it?", date: cal.date(byAdding: .hour, value: -8, to: now)!, likes: 67, comments: 34, tag: "Question"),
                ],
                city: "London",
                challenges: [
                    GroupChallenge(title: "Walk 50K Steps Together", description: "Community goal: 50,000 combined steps this week", targetValue: 50000, currentValue: 32400, unit: "steps", startDate: cal.date(byAdding: .day, value: -3, to: now)!, endDate: cal.date(byAdding: .day, value: 4, to: now)!, participants: 48, isJoined: true),
                ]),
            CommunityGroup(name: "Heart Health Heroes", description: "Managing blood pressure and cardiovascular wellness together", category: .heartHealth, memberCount: 8920, isJoined: true, icon: "heart.fill", color: "#FF6B6B",
                posts: [
                    CommunityPost(author: "CalmSpirit_88", initials: "CS", avatarColor: "#26de81", content: "DASH diet changed my BP from 158/96 to 128/82 in 8 weeks. Cut sodium, added potassium-rich foods.", date: cal.date(byAdding: .hour, value: -3, to: now)!, likes: 203, comments: 41, tag: "Diet"),
                    CommunityPost(author: "StrongRunner_31", initials: "SR", avatarColor: "#6C63FF", content: "Daily 30-min morning walks + magnesium supplement. BP consistently normal for 2 months now!", date: cal.date(byAdding: .hour, value: -6, to: now)!, likes: 156, comments: 22, tag: "Exercise",
                        activityData: SharedActivityData(steps: 6200, distance: 4.8, calories: 280, activeMinutes: 35, date: cal.date(byAdding: .hour, value: -6, to: now)!)),
                ],
                city: "London",
                challenges: [
                    GroupChallenge(title: "7-Day BP Log Streak", description: "Log your blood pressure every day for a week", targetValue: 7, currentValue: 4, unit: "days", startDate: cal.date(byAdding: .day, value: -4, to: now)!, endDate: cal.date(byAdding: .day, value: 3, to: now)!, participants: 112, isJoined: true),
                ]),
            CommunityGroup(name: "Healthy Weight Journey", description: "Sustainable weight loss for better diabetes and BP control", category: .weightLoss, memberCount: 15200, isJoined: false, icon: "scalemass.fill", color: "#FF9F43", posts: [], city: ""),
            CommunityGroup(name: "Diabetic Nutrition Hub", description: "Recipes, meal plans, and food tips for diabetics", category: .nutrition, memberCount: 9800, isJoined: false, icon: "fork.knife.circle.fill", color: "#26de81", posts: [], city: "Mumbai"),
            CommunityGroup(name: "Women's Wellness Circle", description: "Navigating diabetes and hormones — cycle, pregnancy, menopause", category: .womensHealth, memberCount: 6750, isJoined: false, icon: "figure.wave", color: "#FF6B6B", posts: [], city: ""),
            CommunityGroup(name: "Move More, Feel Better", description: "Exercise routines and activity tips for metabolic health", category: .exercise, memberCount: 11300, isJoined: false, icon: "figure.run", color: "#4ECDC4", posts: [], city: "Sydney"),
            CommunityGroup(name: "Morning Walkers Club", description: "Early birds who walk together — share routes, steps, and motivation", category: .walking, memberCount: 4200, isJoined: false, icon: "figure.walk", color: "#26de81", posts: [
                    CommunityPost(author: "VibrantEagle_66", initials: "VE", avatarColor: "#22a6b3", content: "Hit 12,000 steps before 9am today! The sunrise was incredible.", date: cal.date(byAdding: .hour, value: -4, to: now)!, likes: 45, comments: 8, tag: "Activity",
                        activityData: SharedActivityData(steps: 12000, distance: 9.2, calories: 480, activeMinutes: 75, date: cal.date(byAdding: .hour, value: -4, to: now)!)),
                ], city: "London"),
            CommunityGroup(name: "Fat Loss Warriors", description: "Sustainable fat loss through nutrition, exercise, and accountability", category: .weightLoss, memberCount: 18500, isJoined: false, icon: "flame.fill", color: "#FF9F43", posts: [], city: ""),
            CommunityGroup(name: "Sugar Warriors", description: "Tackling high blood sugar together — share tips, wins, and support", category: .diabetes, memberCount: 14200, isJoined: false, icon: "drop.triangle.fill", color: "#6C63FF", posts: [], city: ""),
            CommunityGroup(name: "Hypertension Warriors", description: "Lower your BP naturally — lifestyle changes, stress management, and more", category: .bloodPressure, memberCount: 9600, isJoined: false, icon: "heart.circle.fill", color: "#FF6B6B", posts: [], city: ""),
            CommunityGroup(name: "Fasting Community", description: "Intermittent fasting, extended fasting, and metabolic health — all levels welcome", category: .fasting, memberCount: 21300, isJoined: false, icon: "clock.fill", color: "#4ECDC4", posts: [], city: ""),
        ]

        // ── Doctors ──────────────────────────────────────────────────────────
        // Fee values are in GBP base — use doctor.feeString(currencyCode:) for display
        doctors = [
            Doctor(name: "Dr. Amara Patel",    specialization: "Endocrinologist",  qualifications: "MD, FRCP", experience: 14, rating: 4.9, reviews: 312, hospital: "City Medical Center",       city: "London",       fee: 120, avatarColor: "#6C63FF", nextAvailable: "Today 3 PM",
                   postcode: "W1G 8YN", country: "United Kingdom", licenseNumber: "GMC-7234561", regulatoryBody: "GMC", certifications: ["PLAB/UKMLA Passed","Certificate of Good Standing","EPIC Certified"], countryExam: "PLAB/UKMLA", isVerified: true),
            Doctor(name: "Dr. James Osei",     specialization: "Cardiologist",     qualifications: "MD, PhD",  experience: 18, rating: 4.8, reviews: 489, hospital: "Heart & Vascular Inst.",    city: "London",       fee: 150, avatarColor: "#FF6B6B", nextAvailable: "Tomorrow 10 AM",
                   postcode: "EC2R 8AH", country: "United Kingdom", licenseNumber: "GMC-6189032", regulatoryBody: "GMC", certifications: ["PLAB/UKMLA Passed","Certificate of Good Standing","WDOM Listed"], countryExam: "PLAB/UKMLA", isVerified: true),
            Doctor(name: "Dr. Priya Sharma",   specialization: "Diabetologist",    qualifications: "MD, CDE",  experience: 11, rating: 4.9, reviews: 227, hospital: "Apollo Clinic",             city: "Mumbai",       fee: 40,  avatarColor: "#4ECDC4", languages: ["English", "Hindi"], nextAvailable: "Today 5 PM",
                   postcode: "400001", country: "India", licenseNumber: "MCI-58723", regulatoryBody: "MCI", certifications: ["ECFMG Certified","WDOM Listed"], countryExam: "NEET-PG", isVerified: true),
            Doctor(name: "Dr. Carlos Rivera",  specialization: "Internal Medicine", qualifications: "MD, MPH", experience: 9,  rating: 4.7, reviews: 184, hospital: "General Hospital",          city: "New York",     fee: 90,  avatarColor: "#FF9F43", nextAvailable: "In 2 days",
                   postcode: "10001", country: "United States", licenseNumber: "NY-267834", regulatoryBody: "NYSED", certifications: ["USMLE Passed","ECFMG Certified","Board Certified"], countryExam: "USMLE", isVerified: true),
            Doctor(name: "Dr. Sarah Mitchell", specialization: "Nephrologist",     qualifications: "MD, FASN", experience: 16, rating: 4.8, reviews: 261, hospital: "Kidney Care Centre",        city: "Manchester",   fee: 140, avatarColor: "#26de81", nextAvailable: "Tomorrow 2 PM",
                   postcode: "M1 3BN", country: "United Kingdom", licenseNumber: "GMC-6543210", regulatoryBody: "GMC", certifications: ["PLAB/UKMLA Passed","Certificate of Good Standing","EPIC Certified"], countryExam: "PLAB/UKMLA", isVerified: true),
            Doctor(name: "Dr. Ravi Krishnan",  specialization: "Endocrinologist",  qualifications: "MBBS, DM", experience: 12, rating: 4.8, reviews: 198, hospital: "Fortis Hospital",            city: "Delhi",        fee: 35,  avatarColor: "#4834d4", languages: ["English", "Hindi"], nextAvailable: "Today 6 PM",
                   postcode: "110001", country: "India", licenseNumber: "DMC-43218", regulatoryBody: "DMC", certifications: ["ECFMG Certified","WDOM Listed"], countryExam: "NEET-PG", isVerified: true),
            Doctor(name: "Dr. Emily Wong",     specialization: "Cardiologist",     qualifications: "MD, FRACP",experience: 15, rating: 4.9, reviews: 340, hospital: "Sydney Heart Clinic",        city: "Sydney",       fee: 110, avatarColor: "#e056fd", nextAvailable: "Tomorrow 9 AM",
                   postcode: "2000", country: "Australia", licenseNumber: "AHPRA-MED0012345", regulatoryBody: "AHPRA", certifications: ["AMC Passed","WDOM Listed","Certificate of Good Standing"], countryExam: "AMC", isVerified: true),
            Doctor(name: "Dr. Michael Brown",  specialization: "Diabetologist",    qualifications: "MD, FRCPC",experience: 10, rating: 4.7, reviews: 156, hospital: "Toronto Diabetes Centre",    city: "Toronto",      fee: 95,  avatarColor: "#22a6b3", nextAvailable: "In 3 days",
                   postcode: "M5V 2T6", country: "Canada", licenseNumber: "CPSO-98765", regulatoryBody: "CPSO", certifications: ["LMCC Passed","WDOM Listed"], countryExam: "LMCC", isVerified: true),
            Doctor(name: "Dr. Fatima Al-Hassan",specialization: "Nutritionist",   qualifications: "MD, RDN",  experience: 8,  rating: 4.6, reviews: 127, hospital: "Wellness Medical Hub",       city: "Dubai",        fee: 80,  avatarColor: "#f9ca24", languages: ["English", "Arabic"], nextAvailable: "Today 4 PM",
                   postcode: "00000", country: "United Arab Emirates", licenseNumber: "DHA-45678", regulatoryBody: "DHA", certifications: ["ECFMG Certified","HAAD Licensed"], countryExam: "HAAD/DHA", isVerified: true),
            // Future: Doctor signup app will allow more practitioners to register
        ]

        // ── Appointments ─────────────────────────────────────────────────────
        appointments = [
            Appointment(doctorName: "Dr. Amara Patel", doctorSpec: "Endocrinologist", doctorColor: "#6C63FF",
                        date: cal.date(byAdding: .day, value: 3, to: now)!, type: .video, status: .upcoming, notes: "Quarterly HbA1c review"),
            Appointment(doctorName: "Dr. James Osei",  doctorSpec: "Cardiologist",     doctorColor: "#FF6B6B",
                        date: cal.date(byAdding: .day, value: -14, to: now)!, type: .inPerson, status: .completed, notes: "BP medication review — increased Amlodipine to 5mg"),
        ]

        // ── Prescriptions ────────────────────────────────────────────────────
        prescriptions = [
            Prescription(doctorName: "Dr. Amara Patel", date: cal.date(byAdding: .day, value: -30, to: now)!, medications: ["Metformin 500mg twice daily", "Linagliptin 5mg once daily"], diagnosis: "Type 2 Diabetes — HbA1c 7.2%", notes: "Review in 3 months. Lifestyle modifications continue.", validUntil: cal.date(byAdding: .day, value: 60, to: now)!),
        ]

        // ── Wearable Devices ─────────────────────────────────────────────────
        let seedDeviceTypes: [WearableType] = [
            .appleWatch, .samsungWatch, .fitbit, .garmin,
            .ouraRing, .bodySenseRing,
            .accu_chek, .oneTouch, .contourNext,
            .dexcomCGM, .libreCGM,
            .omronBP, .withingsBP, .qardio,
            .masimoPulseOx, .beurer,
            .withingsScale, .eufy
        ]
        wearableDevices = seedDeviceTypes.map {
            WearableDevice(type: $0, isConnected: $0 == .bodySenseRing || $0 == .appleWatch, batteryLevel: $0 == .bodySenseRing ? 82 : ($0 == .appleWatch ? 67 : 0), lastSync: ($0 == .bodySenseRing || $0 == .appleWatch) ? cal.date(byAdding: .hour, value: -1, to: now) : nil, color: $0.colorHex)
        }

        // ── Shop Products (delegated to seedProducts so they always stay current) ──
        seedProducts()

        // ── Daily Guidance ───────────────────────────────────────────────────
        dailyGuidance = DailyGuidance(
            date: now,
            greeting: "Good \(greetingTime()), \(userProfile.name.isEmpty ? "Friend" : userProfile.name.components(separatedBy: " ").first ?? "Friend")! 👋",
            insight: "Your glucose averaged 118 mg/dL yesterday — that's 4% better than last week. Sleep quality also improved. Keep it up!",
            actionItems: ["Log your morning glucose reading", "Take Metformin with breakfast", "Aim for a 20-min walk after lunch", "Drink 2.5L of water today"],
            quote: "\"The secret of getting ahead is getting started.\" — Mark Twain",
            healthScore: healthScore,
            scoreChange: 3
        )

        // Generate anonymous alias for community
        ensureAnonymousAlias()

        save()
    }

    private func greetingTime() -> String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "morning" }
        if h < 17 { return "afternoon" }
        return "evening"
    }
}
