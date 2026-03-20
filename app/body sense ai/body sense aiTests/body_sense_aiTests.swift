//
//  body_sense_aiTests.swift
//  body sense aiTests
//
//  Comprehensive test suite for BodySense AI.
//  Covers: Health models, BP categories, glucose ranges, subscriptions,
//  payments, cart, orders, goals, GDPR, CEO access, Keychain, rate limiting,
//  currency conversion, doctor approval, and data persistence.
//

import Testing
import Foundation
import PassKit
@testable import BodySense_AI

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Blood Pressure Category Tests
// ═══════════════════════════════════════════════════════════════════════════

struct BPCategoryTests {

    @Test func normalBP() {
        let reading = BPReading(systolic: 115, diastolic: 75, pulse: 72, date: Date())
        #expect(reading.category == .normal)
        #expect(reading.category.rawValue == "Normal")
    }

    @Test func elevatedBP() {
        let reading = BPReading(systolic: 125, diastolic: 78, pulse: 75, date: Date())
        #expect(reading.category == .elevated)
    }

    @Test func highStage1BP() {
        let reading = BPReading(systolic: 135, diastolic: 85, pulse: 80, date: Date())
        #expect(reading.category == .high1)
        #expect(reading.category.rawValue == "High (Stage 1)")
    }

    @Test func highStage2BP() {
        let reading = BPReading(systolic: 145, diastolic: 95, pulse: 88, date: Date())
        #expect(reading.category == .high2)
        #expect(reading.category.rawValue == "High (Stage 2)")
    }

    @Test func borderlineNormalBP() {
        let reading = BPReading(systolic: 119, diastolic: 79, pulse: 70, date: Date())
        #expect(reading.category == .normal)
    }

    @Test func borderlineElevatedBP() {
        // Systolic 120, diastolic 79 → elevated (120 is NOT < 120)
        let reading = BPReading(systolic: 120, diastolic: 79, pulse: 70, date: Date())
        #expect(reading.category == .elevated)
    }

    @Test func highDiastolicAloneBP() {
        // Systolic normal but diastolic high → high1 because (systolic < 140 || diastolic < 90) is true
        let reading = BPReading(systolic: 118, diastolic: 92, pulse: 70, date: Date())
        #expect(reading.category == .high1)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Glucose Status Tests
// ═══════════════════════════════════════════════════════════════════════════

struct GlucoseStatusTests {

    @Test func lowGlucose() {
        let store = HealthStore.shared
        let status = store.glucoseStatus(55)
        #expect(status.label == "Low")
    }

    @Test func normalGlucose() {
        let store = HealthStore.shared
        let status = store.glucoseStatus(85)
        #expect(status.label == "Normal")
    }

    @Test func goodGlucose() {
        let store = HealthStore.shared
        let status = store.glucoseStatus(120)
        #expect(status.label == "Good")
    }

    @Test func highGlucose() {
        let store = HealthStore.shared
        let status = store.glucoseStatus(155)
        #expect(status.label == "High")
    }

    @Test func veryHighGlucose() {
        let store = HealthStore.shared
        let status = store.glucoseStatus(200)
        #expect(status.label == "Very High")
    }

    @Test func boundaryGlucose70() {
        let store = HealthStore.shared
        let status = store.glucoseStatus(70)
        #expect(status.label == "Normal")
    }

    @Test func boundaryGlucose140() {
        let store = HealthStore.shared
        let status = store.glucoseStatus(140)
        #expect(status.label == "High")
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Glucose Reading Model Tests
// ═══════════════════════════════════════════════════════════════════════════

struct GlucoseReadingTests {

    @Test func createGlucoseReading() {
        let reading = GlucoseReading(value: 95.0, date: Date(), context: .fasting)
        #expect(reading.value == 95.0)
        #expect(reading.context == .fasting)
        #expect(reading.notes == "")
    }

    @Test func mealContextIcons() {
        #expect(MealContext.fasting.icon == "moon.stars")
        #expect(MealContext.beforeMeal.icon == "fork.knife.circle")
        #expect(MealContext.afterMeal.icon == "fork.knife.circle.fill")
        #expect(MealContext.bedtime.icon == "bed.double")
        #expect(MealContext.random.icon == "clock")
    }

    @Test func allMealContexts() {
        #expect(MealContext.allCases.count == 5)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Sleep Quality Tests
// ═══════════════════════════════════════════════════════════════════════════

struct SleepQualityTests {

    @Test func sleepQualityScores() {
        #expect(SleepQuality.poor.score == 25)
        #expect(SleepQuality.fair.score == 50)
        #expect(SleepQuality.good.score == 75)
        #expect(SleepQuality.excellent.score == 100)
    }

    @Test func sleepQualityIcons() {
        #expect(SleepQuality.poor.icon == "😴")
        #expect(SleepQuality.fair.icon == "😐")
        #expect(SleepQuality.good.icon == "😊")
        #expect(SleepQuality.excellent.icon == "🌟")
    }

    @Test func sleepEntryCreation() {
        let entry = SleepEntry(date: Date(), duration: 7.5, quality: .good,
                               deepSleep: 1.5, remSleep: 2.0, lightSleep: 3.5, awakenings: 2)
        #expect(entry.duration == 7.5)
        #expect(entry.quality == .good)
        #expect(entry.awakenings == 2)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Subscription Plan Tests
// ═══════════════════════════════════════════════════════════════════════════

struct SubscriptionPlanTests {

    @Test func freePlanPrice() {
        #expect(SubscriptionPlan.free.basePriceGBP == 0)
        #expect(SubscriptionPlan.free.price == "Free")
    }

    @Test func proPlanPrice() {
        #expect(SubscriptionPlan.pro.basePriceGBP == 3.99)
        #expect(SubscriptionPlan.pro.price == "£3.99/mo")
    }

    @Test func premiumPlanPrice() {
        #expect(SubscriptionPlan.premium.basePriceGBP == 8.99)
        #expect(SubscriptionPlan.premium.price == "£8.99/mo")
    }

    @Test func planFeatures() {
        #expect(SubscriptionPlan.free.features.count == 4)
        #expect(SubscriptionPlan.pro.features.count == 8)
        #expect(SubscriptionPlan.premium.features.count == 7)
    }

    @Test func planBadges() {
        #expect(SubscriptionPlan.free.badge == "FREE")
        #expect(SubscriptionPlan.pro.badge == "PRO")
        #expect(SubscriptionPlan.premium.badge == "PREMIUM")
    }

    @Test func planIcons() {
        #expect(SubscriptionPlan.free.icon == "star")
        #expect(SubscriptionPlan.pro.icon == "star.fill")
        #expect(SubscriptionPlan.premium.icon == "crown.fill")
    }

    @Test func allPlansExist() {
        let all = SubscriptionPlan.allCases
        #expect(all.count == 3)
        #expect(all.contains(.free))
        #expect(all.contains(.pro))
        #expect(all.contains(.premium))
    }

    @Test func localizedPriceGBP() {
        let price = SubscriptionPlan.pro.priceString(currencyCode: "GBP")
        #expect(price == "£3.99/mo")
    }

    @Test func localizedPriceFree() {
        let price = SubscriptionPlan.free.priceString(currencyCode: "USD")
        #expect(price == "Free")
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Currency Conversion Tests
// ═══════════════════════════════════════════════════════════════════════════

struct CurrencyTests {

    @Test func gbpToGBP() {
        let converted = CurrencyService.convert(10.0, to: "GBP")
        #expect(converted == 10.0)
    }

    @Test func gbpToUSD() {
        let converted = CurrencyService.convert(10.0, to: "USD")
        #expect(converted == 12.7)
    }

    @Test func gbpToINR() {
        let converted = CurrencyService.convert(1.0, to: "INR")
        #expect(converted == 105.0)
    }

    @Test func formatGBP() {
        let formatted = CurrencyService.format(3.99, currencyCode: "GBP")
        #expect(formatted == "£3.99")
    }

    @Test func formatUSD() {
        let formatted = CurrencyService.format(3.99, currencyCode: "USD")
        #expect(formatted.hasPrefix("$"))
    }

    @Test func formatLargeAmount() {
        let formatted = CurrencyService.format(100.0, currencyCode: "INR")
        #expect(formatted.contains("₹"))
    }

    @Test func currencyForCountry() {
        #expect(CurrencyService.currency(for: "United Kingdom") == "GBP")
        #expect(CurrencyService.currency(for: "United States") == "USD")
        #expect(CurrencyService.currency(for: "India") == "INR")
        #expect(CurrencyService.currency(for: "Germany") == "EUR")
    }

    @Test func unknownCountryDefaultsGBP() {
        #expect(CurrencyService.currency(for: "Atlantis") == "GBP")
    }

    @Test func supportedCountriesNotEmpty() {
        #expect(CurrencyService.supportedCountries.count > 20)
    }

    @Test func allCurrenciesHaveSymbols() {
        for (_, currencyCode) in CurrencyService.countryToCurrency {
            #expect(CurrencyService.currencySymbol[currencyCode] != nil,
                    "Missing symbol for \(currencyCode)")
        }
    }

    @Test func allCurrenciesHaveRates() {
        for (_, currencyCode) in CurrencyService.countryToCurrency {
            #expect(CurrencyService.rateFromGBP[currencyCode] != nil,
                    "Missing rate for \(currencyCode)")
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Health Goal Tests
// ═══════════════════════════════════════════════════════════════════════════

struct HealthGoalTests {

    @Test func goalProgressCalculation() {
        let goal = HealthGoal(type: .steps, title: "Walk 10k",
                              targetValue: 10000, currentValue: 5000,
                              unit: "steps", deadline: Date())
        #expect(goal.progress == 0.5)
    }

    @Test func goalProgressAtZero() {
        let goal = HealthGoal(type: .water, title: "Drink water",
                              targetValue: 2000, currentValue: 0,
                              unit: "ml", deadline: Date())
        #expect(goal.progress == 0.0)
    }

    @Test func goalProgressCappedAt1() {
        let goal = HealthGoal(type: .steps, title: "Walk 5k",
                              targetValue: 5000, currentValue: 8000,
                              unit: "steps", deadline: Date())
        #expect(goal.progress == 1.0)
    }

    @Test func goalProgressExact() {
        let goal = HealthGoal(type: .sleep, title: "Sleep 8h",
                              targetValue: 8.0, currentValue: 8.0,
                              unit: "hrs", deadline: Date())
        #expect(goal.progress == 1.0)
    }

    @Test func goalZeroTargetSafe() {
        let goal = HealthGoal(type: .weight, title: "Weight",
                              targetValue: 0, currentValue: 50,
                              unit: "kg", deadline: Date())
        // min(50/max(0,1), 1.0) = min(50, 1.0) = 1.0
        #expect(goal.progress == 1.0)
    }

    @Test func allGoalTypes() {
        #expect(GoalType.allCases.count == 9)
    }

    @Test func goalTypeDefaultUnits() {
        #expect(GoalType.steps.defaultUnit == "steps")
        #expect(GoalType.sleep.defaultUnit == "hrs")
        #expect(GoalType.weight.defaultUnit == "kg")
        #expect(GoalType.glucose.defaultUnit == "mg/dL")
        #expect(GoalType.water.defaultUnit == "L")
        #expect(GoalType.exercise.defaultUnit == "min")
        #expect(GoalType.medication.defaultUnit == "%")
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Health Challenge Tests
// ═══════════════════════════════════════════════════════════════════════════

struct HealthChallengeTests {

    @Test func challengeProgress() {
        let challenge = HealthChallenge(
            title: "Walk 50k", description: "Weekly steps", type: .weekly,
            targetValue: 50000, currentValue: 25000, reward: 100,
            startDate: Date(), endDate: Date().addingTimeInterval(86400 * 7))
        #expect(challenge.progress == 0.5)
    }

    @Test func challengeIsActive() {
        let now = Date()
        let challenge = HealthChallenge(
            title: "Test", description: "Test", type: .daily,
            targetValue: 100, reward: 50,
            startDate: now.addingTimeInterval(-3600),
            endDate: now.addingTimeInterval(3600))
        #expect(challenge.isActive == true)
    }

    @Test func challengeIsInactive() {
        let now = Date()
        let challenge = HealthChallenge(
            title: "Past", description: "Past", type: .daily,
            targetValue: 100, reward: 50,
            startDate: now.addingTimeInterval(-86400 * 2),
            endDate: now.addingTimeInterval(-86400))
        #expect(challenge.isActive == false)
    }

    @Test func challengeTypes() {
        #expect(ChallengeType.allCases.count == 3)
        #expect(ChallengeType.daily.rawValue == "Daily")
        #expect(ChallengeType.weekly.rawValue == "Weekly")
        #expect(ChallengeType.milestone.rawValue == "Milestone")
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Stress & Symptom Tests
// ═══════════════════════════════════════════════════════════════════════════

struct StressSymptomTests {

    @Test func stressTriggers() {
        #expect(StressTrigger.allCases.count == 6)
    }

    @Test func stressReadingCreation() {
        let reading = StressReading(level: 7, date: Date(), trigger: .work)
        #expect(reading.level == 7)
        #expect(reading.trigger == .work)
    }

    @Test func symptomSeverities() {
        #expect(SymptomSeverity.allCases.count == 3)
        #expect(SymptomSeverity.mild.rawValue == "Mild")
        #expect(SymptomSeverity.moderate.rawValue == "Moderate")
        #expect(SymptomSeverity.severe.rawValue == "Severe")
    }

    @Test func predefinedSymptoms() {
        #expect(allSymptoms.count == 20)
        #expect(allSymptoms.contains("Fatigue"))
        #expect(allSymptoms.contains("Headache"))
        #expect(allSymptoms.contains("Brain Fog"))
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Medication Tests
// ═══════════════════════════════════════════════════════════════════════════

struct MedicationTests {

    @Test func medicationFrequencies() {
        #expect(MedFrequency.allCases.count == 5)
        #expect(MedFrequency.daily.rawValue == "Once daily")
        #expect(MedFrequency.twice.rawValue == "Twice daily")
    }

    @Test func medicationTimes() {
        #expect(MedTime.allCases.count == 4)
        #expect(MedTime.morning.hour == 8)
        #expect(MedTime.afternoon.hour == 13)
        #expect(MedTime.evening.hour == 18)
        #expect(MedTime.bedtime.hour == 21)
    }

    @Test func medicationCreation() {
        let med = Medication(name: "Metformin", dosage: "500", unit: "mg",
                             frequency: .twice, timeOfDay: [.morning, .evening])
        #expect(med.name == "Metformin")
        #expect(med.dosage == "500")
        #expect(med.unit == "mg")
        #expect(med.isActive == true)
        #expect(med.timeOfDay.count == 2)
    }

    @Test func medLogCreation() {
        let log = MedLog(date: Date(), taken: true, time: .morning)
        #expect(log.taken == true)
        #expect(log.time == .morning)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Nutrition Tests
// ═══════════════════════════════════════════════════════════════════════════

struct NutritionTests {

    @Test func mealTypes() {
        #expect(MealType.allCases.count == 4)
        #expect(MealType.breakfast.rawValue == "Breakfast")
        #expect(MealType.lunch.rawValue == "Lunch")
        #expect(MealType.dinner.rawValue == "Dinner")
        #expect(MealType.snack.rawValue == "Snack")
    }

    @Test func mealTypeIcons() {
        #expect(MealType.breakfast.icon == "sunrise.fill")
        #expect(MealType.lunch.icon == "sun.max.fill")
        #expect(MealType.dinner.icon == "sunset.fill")
    }

    @Test func nutritionLogCreation() {
        let log = NutritionLog(date: Date(), mealType: .lunch,
                               calories: 550, carbs: 60, protein: 30, fat: 18, fiber: 8,
                               sugar: 12, salt: 1.5, foodName: "Chicken Rice")
        #expect(log.calories == 550)
        #expect(log.carbs == 60)
        #expect(log.foodName == "Chicken Rice")
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Health Alert Tests
// ═══════════════════════════════════════════════════════════════════════════

struct HealthAlertTests {

    @Test func alertTypes() {
        let types: [AlertType] = [.highGlucose, .lowGlucose, .highBP, .missedMed,
                                   .sleepAlert, .stressAlert, .hrAlert,
                                   .achievement, .challenge, .reminder, .goalReached]
        for type in types {
            #expect(!type.icon.isEmpty, "Missing icon for \(type.rawValue)")
        }
    }

    @Test func alertDefaultUnread() {
        let alert = HealthAlert(date: Date(), type: .highGlucose,
                                title: "High Glucose", message: "Your glucose is 200 mg/dL")
        #expect(alert.isRead == false)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Cart & Order Tests
// ═══════════════════════════════════════════════════════════════════════════

struct CartOrderTests {

    @Test func addToCart() {
        let store = HealthStore.shared
        let initialCount = store.cartItems.count

        let product = Product(name: "Test Ring", description: "Test", price: 199.99,
                              originalPrice: 249.99, category: .ring, icon: "circle", color: "#000")
        store.addToCart(product)

        #expect(store.cartItems.count == initialCount + 1)

        // Clean up
        if let item = store.cartItems.last {
            store.removeFromCart(item)
        }
    }

    @Test func addDuplicateIncrementsQuantity() {
        let store = HealthStore.shared
        let product = Product(name: "Test Charger", description: "Test", price: 29.99,
                              originalPrice: 39.99, category: .accessories, icon: "bolt", color: "#FFF")

        store.addToCart(product)
        let countAfterFirst = store.cartItems.count
        store.addToCart(product)

        // Should not add a new item, just increment quantity
        #expect(store.cartItems.count == countAfterFirst)

        // Clean up
        if let item = store.cartItems.first(where: { $0.productID == product.id }) {
            store.removeFromCart(item)
        }
    }

    @Test func cartTotal() {
        let store = HealthStore.shared
        let savedCart = store.cartItems
        store.cartItems = []

        let product1 = Product(name: "Ring", description: "", price: 100.0,
                               originalPrice: 120.0, category: .ring, icon: "circle", color: "#000")
        let product2 = Product(name: "Band", description: "", price: 25.0,
                               originalPrice: 30.0, category: .accessories, icon: "circle", color: "#000")

        store.addToCart(product1)
        store.addToCart(product2)

        #expect(store.cartTotal == 125.0)
        #expect(store.cartCount == 2)

        store.cartItems = savedCart
    }

    @Test func removeFromCart() {
        let store = HealthStore.shared
        let product = Product(name: "Remove Test", description: "", price: 10.0,
                              originalPrice: 15.0, category: .accessories, icon: "circle", color: "#000")
        store.addToCart(product)

        let item = store.cartItems.first(where: { $0.productID == product.id })!
        store.removeFromCart(item)

        #expect(!store.isInCart(product))
    }

    @Test func decreaseCartItem() {
        let store = HealthStore.shared
        let product = Product(name: "Decrease Test", description: "", price: 15.0,
                              originalPrice: 20.0, category: .accessories, icon: "circle", color: "#000")
        store.addToCart(product)
        store.addToCart(product) // quantity = 2

        let item = store.cartItems.first(where: { $0.productID == product.id })!
        store.decreaseCartItem(item)

        let updatedItem = store.cartItems.first(where: { $0.productID == product.id })
        #expect(updatedItem?.quantity == 1)

        // Decrease again should remove
        if let u = updatedItem {
            store.decreaseCartItem(u)
        }
        #expect(!store.isInCart(product))
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Product Tests
// ═══════════════════════════════════════════════════════════════════════════

struct ProductTests {

    @Test func productIsRing() {
        let ring = Product(name: "BodySense Ring X3B", description: "Smart ring",
                           price: 199.99, originalPrice: 249.99, category: .ring,
                           icon: "circle", color: "#6C63FF",
                           availableColors: [.silver, .black, .gold])
        #expect(ring.isRing == true)
    }

    @Test func productIsNotRing() {
        let charger = Product(name: "Charging Dock", description: "Charger",
                              price: 29.99, originalPrice: 39.99, category: .accessories,
                              icon: "bolt", color: "#000")
        #expect(charger.isRing == false)
    }

    @Test func ringColors() {
        #expect(RingColor.allCases.count == 3)
        #expect(RingColor.silver.rawValue == "Silver")
        #expect(RingColor.black.rawValue == "Black")
        #expect(RingColor.gold.rawValue == "Gold")
    }

    @Test func productLocalizedPrice() {
        let product = Product(name: "Test", description: "", price: 10.0,
                              originalPrice: 15.0, category: .accessories, icon: "circle", color: "#000")
        let gbpPrice = product.priceString(currencyCode: "GBP")
        #expect(gbpPrice == "£10.00")
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Doctor Model Tests
// ═══════════════════════════════════════════════════════════════════════════

struct DoctorTests {

    @Test func doctorFeeString() {
        let doctor = Doctor(name: "Dr Smith", specialization: "Cardiologist",
                            qualifications: "MBBS", experience: 10,
                            rating: 4.8, reviews: 50, hospital: "NHS Trust",
                            city: "London", fee: 50)
        let feeGBP = doctor.feeString(currencyCode: "GBP")
        #expect(feeGBP == "£50.00")
    }

    @Test func doctorProfileFees() {
        let profile = DoctorProfile()
        #expect(profile.fee(for: .video) == 50.0)
        #expect(profile.fee(for: .phone) == 35.0)
        #expect(profile.fee(for: .inPerson) == 75.0)
    }

    @Test func defaultAvailability() {
        let schedule = DayAvailability.defaultSchedule
        #expect(schedule.count == 7)
        #expect(schedule[0].isAvailable == false)  // Sunday
        #expect(schedule[1].isAvailable == true)   // Monday
        #expect(schedule[5].isAvailable == true)   // Friday
        #expect(schedule[6].isAvailable == false)  // Saturday
    }

    @Test func dayNames() {
        let schedule = DayAvailability.defaultSchedule
        #expect(schedule[0].dayName == "Sunday")
        #expect(schedule[1].dayName == "Monday")
        #expect(schedule[6].dayName == "Saturday")
    }

    @Test func appointmentTypes() {
        #expect(AppointmentType.allCases.count == 3)
        #expect(AppointmentType.video.rawValue == "Video Call")
        #expect(AppointmentType.phone.rawValue == "Phone Call")
        #expect(AppointmentType.inPerson.rawValue == "In-Person")
    }

    @Test func appointmentStatus() {
        #expect(AppointmentStatus.upcoming.rawValue == "Upcoming")
        #expect(AppointmentStatus.completed.rawValue == "Completed")
        #expect(AppointmentStatus.cancelled.rawValue == "Cancelled")
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Doctor Approval Flow Tests
// ═══════════════════════════════════════════════════════════════════════════

struct DoctorApprovalTests {

    @Test func submitDoctorRequest() {
        let store = HealthStore.shared
        let initialCount = store.doctorRequests.count

        let request = DoctorRegistrationRequest(
            name: "Dr Test", email: "test@test.com", specialty: "Cardiologist",
            hospital: "Test Hospital", city: "London", country: "United Kingdom",
            postcode: "SW1A 1AA", gmcNumber: "1234567", gmcStatus: "Full",
            regulatoryBody: "GMC", pmqDegree: "MBBS", pmqCountry: "United Kingdom",
            pmqYear: 2015, plabPassed: false, ecfmgCertified: false, wdomListed: true,
            goodStanding: true, videoFee: 50, phoneFee: 35, inPersonFee: 75,
            introduction: "Test doctor")

        store.submitDoctorRequest(request)
        #expect(store.doctorRequests.count == initialCount + 1)
        #expect(store.doctorRequests.last?.status == "Pending")
    }

    @Test func approveDoctorRequest() {
        let store = HealthStore.shared
        let initialDoctorCount = store.doctors.count

        let request = DoctorRegistrationRequest(
            name: "Dr Approve", email: "approve@test.com", specialty: "Diabetologist",
            hospital: "Approve Hospital", city: "Manchester", country: "United Kingdom",
            postcode: "M1 1AA", gmcNumber: "9999999", gmcStatus: "Full",
            regulatoryBody: "GMC", pmqDegree: "MBBS", pmqCountry: "India",
            pmqYear: 2010, plabPassed: true, ecfmgCertified: false, wdomListed: true,
            goodStanding: true, videoFee: 45, phoneFee: 30, inPersonFee: 60,
            introduction: "Approve test")

        store.submitDoctorRequest(request)
        store.approveDoctor(request)

        #expect(store.doctors.count == initialDoctorCount + 1)
        #expect(store.doctors.last?.isVerified == true)

        if let idx = store.doctorRequests.firstIndex(where: { $0.id == request.id }) {
            #expect(store.doctorRequests[idx].status == "Approved")
        }
    }

    @Test func rejectDoctorRequest() {
        let store = HealthStore.shared

        let request = DoctorRegistrationRequest(
            name: "Dr Reject", email: "reject@test.com", specialty: "Nutritionist",
            hospital: "Reject Hospital", city: "Birmingham", country: "United Kingdom",
            postcode: "B1 1AA", gmcNumber: "0000000", gmcStatus: "Provisional",
            regulatoryBody: "GMC", pmqDegree: "MBBS", pmqCountry: "Pakistan",
            pmqYear: 2020, plabPassed: false, ecfmgCertified: false, wdomListed: false,
            goodStanding: false, videoFee: 40, phoneFee: 25, inPersonFee: 55,
            introduction: "Reject test")

        store.submitDoctorRequest(request)
        store.rejectDoctor(request)

        if let idx = store.doctorRequests.firstIndex(where: { $0.id == request.id }) {
            #expect(store.doctorRequests[idx].status == "Rejected")
        }
    }

    @Test func pendingDoctorRequests() {
        let store = HealthStore.shared
        let pending = store.pendingDoctorRequests
        for req in pending {
            #expect(req.status == "Pending")
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Condition Mapper Tests
// ═══════════════════════════════════════════════════════════════════════════

struct ConditionMapperTests {

    @Test func diabetesMapsToDiabetologist() {
        let specs = ConditionMapper.specializations(for: "diabetes")
        #expect(specs.contains("Diabetologist"))
        #expect(specs.contains("Endocrinologist"))
    }

    @Test func heartMapsToCardiologist() {
        let specs = ConditionMapper.specializations(for: "heart problems")
        #expect(specs.contains("Cardiologist"))
    }

    @Test func weightMapsToNutritionist() {
        let specs = ConditionMapper.specializations(for: "weight loss")
        #expect(specs.contains("Nutritionist"))
    }

    @Test func unknownConditionEmpty() {
        let specs = ConditionMapper.specializations(for: "alien abduction")
        #expect(specs.isEmpty)
    }

    @Test func caseInsensitive() {
        let specs = ConditionMapper.specializations(for: "DIABETES")
        #expect(specs.contains("Diabetologist"))
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Health Score Tests
// ═══════════════════════════════════════════════════════════════════════════

struct HealthScoreTests {

    @Test func scoreNeverExceeds100() {
        let store = HealthStore.shared
        #expect(store.healthScore <= 100)
    }

    @Test func scoreNeverBelow0() {
        let store = HealthStore.shared
        #expect(store.healthScore >= 0)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Keychain Manager Tests
// ═══════════════════════════════════════════════════════════════════════════

struct KeychainManagerTests {

    @Test func saveAndRetrieve() {
        let keychain = KeychainManager.shared
        let testValue = "test_key_\(UUID().uuidString.prefix(8))"

        let saved = keychain.save(testValue, for: .userSessionToken)
        #expect(saved == true)

        let retrieved = keychain.get(.userSessionToken)
        #expect(retrieved == testValue)

        keychain.delete(.userSessionToken)
    }

    @Test func deleteKey() {
        let keychain = KeychainManager.shared
        keychain.save("to_delete", for: .userSessionToken)
        let deleted = keychain.delete(.userSessionToken)
        #expect(deleted == true)
        #expect(keychain.get(.userSessionToken) == nil)
    }

    @Test func hasKey() {
        let keychain = KeychainManager.shared
        keychain.save("exists", for: .userSessionToken)
        #expect(keychain.has(.userSessionToken) == true)
        keychain.delete(.userSessionToken)
        #expect(keychain.has(.userSessionToken) == false)
    }

    @Test func overwriteExistingKey() {
        let keychain = KeychainManager.shared
        keychain.save("value1", for: .userSessionToken)
        keychain.save("value2", for: .userSessionToken)
        #expect(keychain.get(.userSessionToken) == "value2")
        keychain.delete(.userSessionToken)
    }

    @Test func deleteNonExistentKeySucceeds() {
        let keychain = KeychainManager.shared
        keychain.delete(.userSessionToken)
        let result = keychain.delete(.userSessionToken)
        #expect(result == true)
    }

    @Test func allKeysExist() {
        let allKeys = KeychainManager.Key.allCases
        #expect(allKeys.count == 6)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Biometric Auth Tests
// ═══════════════════════════════════════════════════════════════════════════

struct BiometricAuthTests {

    @Test func biometricTypeNames() {
        let auth = BiometricAuth.shared
        let typeName = auth.typeName
        #expect(["Face ID", "Touch ID", "Passcode"].contains(typeName))
    }

    @Test func biometricIconNames() {
        let auth = BiometricAuth.shared
        let icon = auth.iconName
        #expect(["faceid", "touchid", "lock.fill"].contains(icon))
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Rate Limiter Tests
// ═══════════════════════════════════════════════════════════════════════════

struct RateLimiterTests {

    @Test func firstRequestAllowed() async {
        let limiter = RateLimiter()
        let result = await limiter.checkLimit(config: .standard)
        #expect(result == nil)
    }

    @Test func cooldownEnforced() async {
        let limiter = RateLimiter()
        await limiter.recordRequest()
        let result = await limiter.checkLimit(config: .standard)
        #expect(result != nil)
        #expect(result?.contains("wait") == true)
    }

    @Test func ceoConfig() {
        let config = RateLimiter.Config.ceo
        #expect(config.cooldownSeconds == 1)
        #expect(config.maxPerMinute == 60)
        #expect(config.maxPerHour == 1000)
    }

    @Test func standardConfig() {
        let config = RateLimiter.Config.standard
        #expect(config.maxPerMinute == 10)
        #expect(config.maxPerHour == 100)
        #expect(config.cooldownSeconds == 6)
    }

    @Test func premiumConfig() {
        let config = RateLimiter.Config.premium
        #expect(config.maxPerMinute == 20)
        #expect(config.maxPerHour == 300)
        #expect(config.cooldownSeconds == 3)
    }

    @Test func statsTracking() async {
        let limiter = RateLimiter()
        await limiter.recordRequest()
        let stats = await limiter.stats()
        #expect(stats.minuteUsed >= 1)
        #expect(stats.hourUsed >= 1)
    }

    @Test @MainActor func configForCEO() {
        let store = HealthStore.shared
        let savedEmail = store.userProfile.email
        store.userProfile.email = "kiran.shashi47.sk@gmail.com"
        let config = RateLimiter.config(for: store)
        #expect(config.maxPerMinute == 60)
        store.userProfile.email = savedEmail
    }

    @Test @MainActor func configForFreeUser() {
        let store = HealthStore.shared
        let savedEmail = store.userProfile.email
        let savedSub = store.subscription
        store.userProfile.email = "user@example.com"
        store.subscription = .free
        let config = RateLimiter.config(for: store)
        #expect(config.maxPerMinute == 10)
        store.userProfile.email = savedEmail
        store.subscription = savedSub
    }

    @Test @MainActor func configForPremiumUser() {
        let store = HealthStore.shared
        let savedEmail = store.userProfile.email
        let savedSub = store.subscription
        store.userProfile.email = "premium@example.com"
        store.subscription = .premium
        let config = RateLimiter.config(for: store)
        #expect(config.maxPerMinute == 20)
        store.userProfile.email = savedEmail
        store.subscription = savedSub
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Network Monitor Tests
// ═══════════════════════════════════════════════════════════════════════════

struct NetworkMonitorTests {

    @Test func connectionTypes() {
        #expect(NetworkMonitor.ConnectionType.wifi.rawValue == "Wi-Fi")
        #expect(NetworkMonitor.ConnectionType.cellular.rawValue == "Cellular")
        #expect(NetworkMonitor.ConnectionType.ethernet.rawValue == "Ethernet")
        #expect(NetworkMonitor.ConnectionType.unknown.rawValue == "Unknown")
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Payment Result Tests
// ═══════════════════════════════════════════════════════════════════════════

struct PaymentResultTests {

    @Test func successResult() {
        let result = PaymentResult.success(paymentIntentId: "pi_test_123", method: "Apple Pay")
        if case .success(let id, let method) = result {
            #expect(id == "pi_test_123")
            #expect(method == "Apple Pay")
        } else {
            Issue.record("Expected success result")
        }
    }

    @Test func failedResult() {
        let result = PaymentResult.failed(error: "Card declined")
        if case .failed(let error) = result {
            #expect(error == "Card declined")
        } else {
            Issue.record("Expected failed result")
        }
    }

    @Test func cancelledResult() {
        let result = PaymentResult.cancelled
        if case .cancelled = result {
            // pass
        } else {
            Issue.record("Expected cancelled result")
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Stripe Manager Tests
// ═══════════════════════════════════════════════════════════════════════════

struct StripeManagerTests {

    @Test func backendURL() {
        let stripe = StripeManager.shared
        #expect(stripe.backendURL == "https://api.bodysenseai.co.uk")
    }

    @Test func applePayRequestConfig() {
        let stripe = StripeManager.shared
        let request = stripe.applePayRequest(for: 199.99, label: "BodySense Ring X3B")

        #expect(request.merchantIdentifier == "merchant.co.uk.bodysenseai")
        #expect(request.countryCode == "GB")
        #expect(request.currencyCode == "GBP")
        #expect(request.paymentSummaryItems.count == 1)
        #expect(request.paymentSummaryItems.first?.label == "BodySense Ring X3B")
    }

    @Test func paymentAmountConversion() {
        let amountGBP = 3.99
        let pence = Int(amountGBP * 100)
        #expect(pence == 399)
    }

    @Test func simulatePaymentReturnsSuccess() async {
        let stripe = StripeManager.shared
        let result = await stripe.simulatePayment(amountGBP: 10.0, method: "Card")
        if case .success(let id, let method) = result {
            #expect(id.hasPrefix("pi_sandbox_"))
            #expect(method == "Card")
        } else {
            Issue.record("Simulated payment should always succeed")
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - GDPR / User Profile Tests
// ═══════════════════════════════════════════════════════════════════════════

struct GDPRProfileTests {

    @Test func defaultGDPRConsentsAreFalse() {
        let profile = UserProfile()
        #expect(profile.privacyPolicyAccepted == false)
        #expect(profile.termsAccepted == false)
        #expect(profile.consentHealthDataProcessing == false)
        #expect(profile.consentAnalytics == false)
        #expect(profile.consentMarketing == false)
        #expect(profile.consentDataSharing == false)
        #expect(profile.consentAIProcessing == false)
    }

    @Test func gdprTimestampsInitiallyNil() {
        let profile = UserProfile()
        #expect(profile.privacyPolicyAcceptedAt == nil)
        #expect(profile.dataExportRequestedAt == nil)
        #expect(profile.accountDeletionRequestedAt == nil)
    }

    @Test func userProfileDefaults() {
        let profile = UserProfile()
        #expect(profile.name == "")
        #expect(profile.age == 30)
        #expect(profile.isDoctor == false)
        #expect(profile.country == "United Kingdom")
        #expect(profile.currencyCode == "GBP")
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Community Tests
// ═══════════════════════════════════════════════════════════════════════════

struct CommunityTests {

    @Test func groupCategories() {
        let cats = GroupCategory.allCases
        #expect(cats.count == 10)
        #expect(cats.contains(.diabetes))
        #expect(cats.contains(.heartHealth))
        #expect(cats.contains(.bloodPressure))
        #expect(cats.contains(.wellness))
        #expect(cats.contains(.weightLoss))
    }

    @Test func communityGroupCreation() {
        let group = CommunityGroup(name: "Test Group", description: "A test",
                                    category: .diabetes, memberCount: 50,
                                    icon: "drop.fill", color: "#FF6B6B")
        #expect(group.name == "Test Group")
        #expect(group.category == .diabetes)
        #expect(group.memberCount == 50)
        #expect(group.isJoined == false)
        #expect(group.posts.isEmpty)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Launch Checklist Tests
// ═══════════════════════════════════════════════════════════════════════════

struct LaunchChecklistTests {

    @Test func defaultItemsExist() {
        let items = LaunchChecklistView.defaultItems
        #expect(items.count > 40)
    }

    @Test func hasCriticalItems() {
        let items = LaunchChecklistView.defaultItems
        let critical = items.filter { $0.priority == .critical }
        #expect(critical.count > 15)
    }

    @Test func hasAllCategories() {
        let items = LaunchChecklistView.defaultItems
        let categories = Set(items.map { $0.category })
        #expect(categories.contains("Apple Developer Account"))
        #expect(categories.contains("Stripe Setup"))
        #expect(categories.contains("Backend Server"))
        #expect(categories.contains("Security & Privacy"))
        #expect(categories.contains("App Store Connect"))
        #expect(categories.contains("Testing & QA"))
        #expect(categories.contains("Business & Legal"))
        #expect(categories.contains("Final Submission"))
    }

    @Test func allItemsStartUnchecked() {
        let items = LaunchChecklistView.defaultItems
        for item in items {
            #expect(item.isComplete == false, "\(item.title) should start unchecked")
        }
    }

    @Test func priorityValues() {
        #expect(LaunchItem.Priority.critical.rawValue == "Critical")
        #expect(LaunchItem.Priority.important.rawValue == "Important")
        #expect(LaunchItem.Priority.recommended.rawValue == "Recommended")
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - HealthStore Computed Properties Tests
// ═══════════════════════════════════════════════════════════════════════════

struct HealthStoreComputedTests {

    @Test func latestReadings() {
        let store = HealthStore.shared
        let savedGlucose = store.glucoseReadings

        let old = GlucoseReading(value: 100, date: Date().addingTimeInterval(-3600), context: .fasting)
        let recent = GlucoseReading(value: 120, date: Date(), context: .afterMeal)
        store.glucoseReadings = [old, recent]

        #expect(store.latestGlucose?.value == 120)

        store.glucoseReadings = savedGlucose
    }

    @Test func todaySteps() {
        let store = HealthStore.shared
        let saved = store.stepEntries

        store.stepEntries = [
            StepEntry(date: Date(), steps: 3000),
            StepEntry(date: Date(), steps: 2000),
            StepEntry(date: Date().addingTimeInterval(-86400 * 2), steps: 5000),
        ]

        #expect(store.todaySteps == 5000)

        store.stepEntries = saved
    }

    @Test func todayWater() {
        let store = HealthStore.shared
        let saved = store.waterEntries

        store.waterEntries = [
            WaterEntry(date: Date(), amount: 500),
            WaterEntry(date: Date(), amount: 300),
        ]

        #expect(store.todayWaterML == 800)

        store.waterEntries = saved
    }

    @Test func activeGoals() {
        let store = HealthStore.shared
        let saved = store.healthGoals

        store.healthGoals = [
            HealthGoal(type: .steps, title: "Walk", targetValue: 10000,
                       unit: "steps", deadline: Date(), isCompleted: false),
            HealthGoal(type: .water, title: "Drink", targetValue: 2000,
                       unit: "ml", deadline: Date(), isCompleted: true),
        ]

        #expect(store.activeGoals.count == 1)
        #expect(store.activeGoals.first?.title == "Walk")

        store.healthGoals = saved
    }

    @Test func unreadAlerts() {
        let store = HealthStore.shared
        let saved = store.healthAlerts

        store.healthAlerts = [
            HealthAlert(date: Date(), type: .highGlucose, title: "High", message: "Test", isRead: false),
            HealthAlert(date: Date(), type: .reminder, title: "Reminder", message: "Test", isRead: true),
        ]

        #expect(store.unreadAlerts.count == 1)

        store.healthAlerts = saved
    }

    @Test func isDoctor() {
        let store = HealthStore.shared
        let saved = store.userProfile.isDoctor
        store.userProfile.isDoctor = true
        #expect(store.isDoctor == true)
        store.userProfile.isDoctor = false
        #expect(store.isDoctor == false)
        store.userProfile.isDoctor = saved
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Medical Record Tests
// ═══════════════════════════════════════════════════════════════════════════

struct MedicalRecordTests {

    @Test func recordTypes() {
        #expect(MedicalRecordType.allCases.count == 7)
    }

    @Test func recordTypeIcons() {
        #expect(MedicalRecordType.image.icon == "photo")
        #expect(MedicalRecordType.pdf.icon == "doc.fill")
        #expect(MedicalRecordType.prescription.icon == "pills.fill")
        #expect(MedicalRecordType.labResult.icon == "testtube.2")
    }

    @Test func recordCreation() {
        let record = MedicalRecord(title: "Blood Test", fileType: .labResult, fileName: "blood_test.pdf")
        #expect(record.title == "Blood Test")
        #expect(record.fileType == .labResult)
        #expect(record.addedBy == "Me")
        #expect(record.isShared == false)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Streak Tests
// ═══════════════════════════════════════════════════════════════════════════

struct StreakTests {

    @Test func streakTypes() {
        #expect(StreakType.allCases.count == 6)
        #expect(StreakType.dailyCheckIn.rawValue == "Daily Check-in")
        #expect(StreakType.glucose.rawValue == "Glucose Logging")
    }

    @Test func streakCreation() {
        var streak = UserStreak(type: .dailyCheckIn)
        #expect(streak.currentCount == 0)
        #expect(streak.longestCount == 0)
        streak.currentCount = 7
        streak.longestCount = 14
        #expect(streak.currentCount == 7)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Achievement Tests
// ═══════════════════════════════════════════════════════════════════════════

struct AchievementTests {

    @Test func achievementCategories() {
        #expect(AchievementCategory.allCases.count == 6)
    }

    @Test func achievementCreation() {
        let achievement = Achievement(title: "First Steps",
                                       description: "Logged your first glucose reading",
                                       icon: "star.fill", color: "#FFD700", xp: 100,
                                       category: .tracking)
        #expect(achievement.xp == 100)
        #expect(achievement.isEarned == false)
        #expect(achievement.earnedDate == nil)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Cycle Tracking Tests
// ═══════════════════════════════════════════════════════════════════════════

struct CycleTests {

    @Test func flowLevels() {
        #expect(FlowLevel.allCases.count == 3)
        #expect(FlowLevel.light.rawValue == "Light")
        #expect(FlowLevel.medium.rawValue == "Medium")
        #expect(FlowLevel.heavy.rawValue == "Heavy")
    }

    @Test func cycleEntryCreation() {
        let entry = CycleEntry(startDate: Date(), flow: .medium, symptoms: ["Cramps", "Fatigue"])
        #expect(entry.flow == .medium)
        #expect(entry.symptoms.count == 2)
        #expect(entry.endDate == nil)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Agent Type Tests
// ═══════════════════════════════════════════════════════════════════════════

struct AgentTypeTests {

    @Test func agentCount() {
        let agents = AgentType.allCases
        #expect(agents.count == 8)
    }

    @Test func ceoOnlyAgents() {
        #expect(AgentType.shopAdvisor.isCEOOnly == true)
        #expect(AgentType.ceoAdvisor.isCEOOnly == true)
    }

    @Test func nonCEOAgents() {
        #expect(AgentType.healthCoach.isCEOOnly == false)
        #expect(AgentType.nutritionist.isCEOOnly == false)
        #expect(AgentType.fitnessCoach.isCEOOnly == false)
        #expect(AgentType.sleepCoach.isCEOOnly == false)
        #expect(AgentType.mindfulness.isCEOOnly == false)
        #expect(AgentType.becky.isCEOOnly == false)
    }

    @Test func agentRawValues() {
        #expect(AgentType.healthCoach.rawValue == "Health Coach")
        #expect(AgentType.nutritionist.rawValue == "Nutritionist")
        #expect(AgentType.shopAdvisor.rawValue == "Shop Advisor")
        #expect(AgentType.ceoAdvisor.rawValue == "Business Advisor")
        #expect(AgentType.becky.rawValue == "Becky (Doctor AI)")
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Thirty Day Summary Tests
// ═══════════════════════════════════════════════════════════════════════════

struct ThirtyDaySummaryTests {

    @Test func summaryContainsHeader() {
        let store = HealthStore.shared
        let summary = store.thirtyDayReadingsSummary()
        #expect(summary.contains("30-DAY HEALTH READINGS SUMMARY"))
    }

    @Test func summaryWithGlucoseData() {
        let store = HealthStore.shared
        let saved = store.glucoseReadings

        store.glucoseReadings = [
            GlucoseReading(value: 90, date: Date(), context: .fasting),
            GlucoseReading(value: 110, date: Date().addingTimeInterval(-3600), context: .afterMeal),
        ]

        let summary = store.thirtyDayReadingsSummary()
        #expect(summary.contains("GLUCOSE"))
        #expect(summary.contains("2 readings"))

        store.glucoseReadings = saved
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - 3-Day Summary Tests
// ═══════════════════════════════════════════════════════════════════════════

struct ThreeDaySummaryTests {

    @Test func threeDayHeader() {
        let store = HealthStore.shared
        let summary = store.threeDayReadingsSummary()
        #expect(summary.contains("3-DAY HEALTH READINGS SUMMARY"))
    }

    @Test func threeDayIncludesHealthScore() {
        let store = HealthStore.shared
        let summary = store.threeDayReadingsSummary()
        #expect(summary.contains("Health Score:"))
    }

    @Test func threeDayFiltersOldData() {
        let store = HealthStore.shared
        let saved = store.glucoseReadings

        store.glucoseReadings = [
            GlucoseReading(value: 100, date: Date(), context: .fasting),
            GlucoseReading(value: 200, date: Date().addingTimeInterval(-86400 * 10), context: .fasting),
        ]

        let summary = store.threeDayReadingsSummary()
        // Should only include 1 reading (the recent one, not 10 days old)
        #expect(summary.contains("1 readings"))

        store.glucoseReadings = saved
    }

    @Test func threeDayShowsHighEpisodes() {
        let store = HealthStore.shared
        let saved = store.glucoseReadings

        store.glucoseReadings = [
            GlucoseReading(value: 200, date: Date(), context: .afterMeal),
            GlucoseReading(value: 190, date: Date().addingTimeInterval(-3600), context: .afterMeal),
        ]

        let summary = store.threeDayReadingsSummary()
        #expect(summary.contains("High episodes"))

        store.glucoseReadings = saved
    }

    @Test func threeDayShowsLowEpisodes() {
        let store = HealthStore.shared
        let saved = store.glucoseReadings

        store.glucoseReadings = [
            GlucoseReading(value: 55, date: Date(), context: .fasting),
        ]

        let summary = store.threeDayReadingsSummary()
        #expect(summary.contains("Low episodes"))

        store.glucoseReadings = saved
    }

    @Test func threeDayShowsFever() {
        let store = HealthStore.shared
        let saved = store.bodyTempReadings

        store.bodyTempReadings = [
            BodyTempReading(value: 38.5, date: Date()),
        ]

        let summary = store.threeDayReadingsSummary()
        #expect(summary.contains("Fever detected"))

        store.bodyTempReadings = saved
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Doctor 30-Day Clinical Summary Tests
// ═══════════════════════════════════════════════════════════════════════════

struct DoctorThirtyDaySummaryTests {

    @Test func doctorSummaryHeader() {
        let store = HealthStore.shared
        let summary = store.doctorThirtyDaySummary()
        #expect(summary.contains("30-DAY CLINICAL SUMMARY FOR DOCTOR REVIEW"))
        #expect(summary.contains("CONFIDENTIAL"))
    }

    @Test func doctorSummaryPatientDemographics() {
        let store = HealthStore.shared
        let summary = store.doctorThirtyDaySummary()
        #expect(summary.contains("PATIENT DEMOGRAPHICS"))
        #expect(summary.contains("BMI:"))
        #expect(summary.contains("Primary Condition:"))
    }

    @Test func doctorSummaryRiskFlags() {
        let store = HealthStore.shared
        let saved = store.glucoseReadings

        // Add multiple hyperglycaemia episodes to trigger risk flag
        store.glucoseReadings = [
            GlucoseReading(value: 250, date: Date(), context: .afterMeal),
            GlucoseReading(value: 220, date: Date().addingTimeInterval(-3600), context: .afterMeal),
            GlucoseReading(value: 195, date: Date().addingTimeInterval(-7200), context: .random),
        ]

        let summary = store.doctorThirtyDaySummary()
        #expect(summary.contains("CLINICAL RISK FLAGS"))
        #expect(summary.contains("hyperglycaemia"))

        store.glucoseReadings = saved
    }

    @Test func doctorSummaryNoRiskFlags() {
        let store = HealthStore.shared
        let saved = (store.glucoseReadings, store.bpReadings, store.heartRateReadings,
                     store.sleepEntries, store.stressReadings, store.medications)

        store.glucoseReadings = []
        store.bpReadings = []
        store.heartRateReadings = []
        store.sleepEntries = []
        store.stressReadings = []
        store.medications = []

        let summary = store.doctorThirtyDaySummary()
        #expect(summary.contains("NO CLINICAL RISK FLAGS"))

        store.glucoseReadings = saved.0
        store.bpReadings = saved.1
        store.heartRateReadings = saved.2
        store.sleepEntries = saved.3
        store.stressReadings = saved.4
        store.medications = saved.5
    }

    @Test func doctorSummaryGlycaemicControl() {
        let store = HealthStore.shared
        let saved = store.glucoseReadings

        store.glucoseReadings = [
            GlucoseReading(value: 90, date: Date(), context: .fasting),
            GlucoseReading(value: 130, date: Date().addingTimeInterval(-3600), context: .afterMeal),
            GlucoseReading(value: 110, date: Date().addingTimeInterval(-7200), context: .random),
        ]

        let summary = store.doctorThirtyDaySummary()
        #expect(summary.contains("GLYCAEMIC CONTROL"))
        #expect(summary.contains("Mean Glucose:"))
        #expect(summary.contains("Time in Range"))
        #expect(summary.contains("Fasting Average:"))
        #expect(summary.contains("Post-Meal Average:"))

        store.glucoseReadings = saved
    }

    @Test func doctorSummaryBPDistribution() {
        let store = HealthStore.shared
        let saved = store.bpReadings

        store.bpReadings = [
            BPReading(systolic: 115, diastolic: 75, pulse: 70, date: Date()),
            BPReading(systolic: 145, diastolic: 95, pulse: 85, date: Date().addingTimeInterval(-3600)),
        ]

        let summary = store.doctorThirtyDaySummary()
        #expect(summary.contains("CARDIOVASCULAR"))
        #expect(summary.contains("Distribution:"))
        #expect(summary.contains("Normal 1"))
        #expect(summary.contains("Stage 2 1"))

        store.bpReadings = saved
    }

    @Test func doctorSummarySleepAnalysis() {
        let store = HealthStore.shared
        let saved = store.sleepEntries

        store.sleepEntries = [
            SleepEntry(date: Date(), duration: 7.5, quality: .good,
                       deepSleep: 1.5, remSleep: 2.0, lightSleep: 3.5, awakenings: 1),
            SleepEntry(date: Date().addingTimeInterval(-86400), duration: 5.0, quality: .poor,
                       deepSleep: 0.5, remSleep: 1.0, lightSleep: 3.0, awakenings: 4),
        ]

        let summary = store.doctorThirtyDaySummary()
        #expect(summary.contains("SLEEP ANALYSIS"))
        #expect(summary.contains("Deep Sleep:"))
        #expect(summary.contains("REM:"))
        #expect(summary.contains("Avg Awakenings:"))

        store.sleepEntries = saved
    }

    @Test func doctorSummaryMedicationAdherence() {
        let store = HealthStore.shared
        let saved = store.medications

        var med = Medication(name: "Metformin", dosage: "500", unit: "mg",
                             frequency: .twice, timeOfDay: [.morning, .evening])
        med.logs = [
            MedLog(date: Date(), taken: true, time: .morning),
            MedLog(date: Date(), taken: false, time: .evening),
            MedLog(date: Date().addingTimeInterval(-86400), taken: true, time: .morning),
            MedLog(date: Date().addingTimeInterval(-86400), taken: true, time: .evening),
        ]
        store.medications = [med]

        let summary = store.doctorThirtyDaySummary()
        #expect(summary.contains("CURRENT MEDICATIONS"))
        #expect(summary.contains("Metformin"))
        #expect(summary.contains("Adherence:"))

        store.medications = saved
    }

    @Test func doctorSummaryFooter() {
        let store = HealthStore.shared
        let summary = store.doctorThirtyDaySummary()
        #expect(summary.contains("auto-generated"))
        #expect(summary.contains("professional medical judgement"))
    }

    @Test func doctorSummaryBMICategories() {
        let store = HealthStore.shared
        let saved = (store.userProfile.weight, store.userProfile.height)

        // Normal BMI
        store.userProfile.weight = 70
        store.userProfile.height = 175
        var summary = store.doctorThirtyDaySummary()
        #expect(summary.contains("Normal"))

        // Obese BMI
        store.userProfile.weight = 110
        store.userProfile.height = 170
        summary = store.doctorThirtyDaySummary()
        #expect(summary.contains("Obese"))

        store.userProfile.weight = saved.0
        store.userProfile.height = saved.1
    }

    @Test func doctorSummaryStressTriggers() {
        let store = HealthStore.shared
        let saved = store.stressReadings

        store.stressReadings = [
            StressReading(level: 8, date: Date(), trigger: .work),
            StressReading(level: 6, date: Date().addingTimeInterval(-3600), trigger: .work),
            StressReading(level: 5, date: Date().addingTimeInterval(-7200), trigger: .sleep),
        ]

        let summary = store.doctorThirtyDaySummary()
        #expect(summary.contains("STRESS & MENTAL HEALTH"))
        #expect(summary.contains("Top Triggers:"))
        #expect(summary.contains("Work"))

        store.stressReadings = saved
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Doctor 3-Day Clinical Summary Tests
// ═══════════════════════════════════════════════════════════════════════════

struct DoctorThreeDaySummaryTests {

    @Test func doctorThreeDayHeader() {
        let store = HealthStore.shared
        let summary = store.doctorThreeDaySummary()
        #expect(summary.contains("3-DAY CLINICAL SUMMARY FOR DOCTOR REVIEW"))
        #expect(summary.contains("CONFIDENTIAL"))
    }

    @Test func doctorThreeDayFiltersOldData() {
        let store = HealthStore.shared
        let saved = store.bpReadings

        store.bpReadings = [
            BPReading(systolic: 130, diastolic: 85, pulse: 75, date: Date()),
            BPReading(systolic: 150, diastolic: 95, pulse: 85, date: Date().addingTimeInterval(-86400 * 15)),
        ]

        let summary = store.doctorThreeDaySummary()
        // Should contain only 1 reading (the recent one)
        #expect(summary.contains("1 readings"))

        store.bpReadings = saved
    }

    @Test func doctorThreeDayHypoglycaemiaRiskFlag() {
        let store = HealthStore.shared
        let saved = store.glucoseReadings

        store.glucoseReadings = [
            GlucoseReading(value: 55, date: Date(), context: .fasting),
        ]

        let summary = store.doctorThreeDaySummary()
        #expect(summary.contains("Hypoglycaemia"))

        store.glucoseReadings = saved
    }

    @Test func doctorThreeDayShowsReportPeriod() {
        let store = HealthStore.shared
        let summary = store.doctorThreeDaySummary()
        #expect(summary.contains("Report Period: Last 3 days"))
    }

    @Test func doctorThreeDayHypertensionFlag() {
        let store = HealthStore.shared
        let saved = store.bpReadings

        store.bpReadings = [
            BPReading(systolic: 160, diastolic: 100, pulse: 90, date: Date()),
            BPReading(systolic: 155, diastolic: 98, pulse: 88, date: Date().addingTimeInterval(-3600)),
        ]

        let summary = store.doctorThreeDaySummary()
        #expect(summary.contains("Stage 2 hypertension"))

        store.bpReadings = saved
    }

    @Test func doctorThreeDaySymptomsSevere() {
        let store = HealthStore.shared
        let saved = store.symptomLogs

        store.symptomLogs = [
            SymptomLog(date: Date(), symptoms: ["Chest Pain", "Dizziness"], severity: .severe),
        ]

        let summary = store.doctorThreeDaySummary()
        #expect(summary.contains("REPORTED SYMPTOMS"))
        #expect(summary.contains("Severe episodes: 1"))

        store.symptomLogs = saved
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Generic Health Summary Tests
// ═══════════════════════════════════════════════════════════════════════════

struct GenericHealthSummaryTests {

    @Test func customDaySummary() {
        let store = HealthStore.shared
        let summary = store.healthSummary(days: 7, title: "WEEKLY SUMMARY")
        #expect(summary.contains("WEEKLY SUMMARY"))
        #expect(summary.contains("Health Score:"))
    }

    @Test func emptyDataMessage() {
        let store = HealthStore.shared
        let saved = (store.glucoseReadings, store.bpReadings, store.heartRateReadings,
                     store.hrvReadings, store.sleepEntries, store.stressReadings,
                     store.symptomLogs, store.medications, store.stepEntries,
                     store.waterEntries, store.bodyTempReadings, store.nutritionLogs)

        store.glucoseReadings = []
        store.bpReadings = []
        store.heartRateReadings = []
        store.hrvReadings = []
        store.sleepEntries = []
        store.stressReadings = []
        store.symptomLogs = []
        store.medications = []
        store.stepEntries = []
        store.waterEntries = []
        store.bodyTempReadings = []
        store.nutritionLogs = []

        let summary = store.healthSummary(days: 7, title: "TEST")
        #expect(summary.contains("No health data recorded"))

        store.glucoseReadings = saved.0
        store.bpReadings = saved.1
        store.heartRateReadings = saved.2
        store.hrvReadings = saved.3
        store.sleepEntries = saved.4
        store.stressReadings = saved.5
        store.symptomLogs = saved.6
        store.medications = saved.7
        store.stepEntries = saved.8
        store.waterEntries = saved.9
        store.bodyTempReadings = saved.10
        store.nutritionLogs = saved.11
    }

    @Test func nutritionInSummary() {
        let store = HealthStore.shared
        let saved = store.nutritionLogs

        store.nutritionLogs = [
            NutritionLog(date: Date(), mealType: .lunch, calories: 600,
                         carbs: 70, protein: 35, fat: 20, fiber: 8),
        ]

        let summary = store.healthSummary(days: 3, title: "TEST")
        #expect(summary.contains("NUTRITION"))
        #expect(summary.contains("1 meals logged"))

        store.nutritionLogs = saved
    }

    @Test func poorSleepWarning() {
        let store = HealthStore.shared
        let saved = store.sleepEntries

        store.sleepEntries = [
            SleepEntry(date: Date(), duration: 4.0, quality: .poor),
            SleepEntry(date: Date().addingTimeInterval(-86400), duration: 4.5, quality: .poor),
        ]

        let summary = store.healthSummary(days: 7, title: "TEST")
        #expect(summary.contains("Poor sleep nights: 2"))

        store.sleepEntries = saved
    }

    @Test func highStressWarning() {
        let store = HealthStore.shared
        let saved = store.stressReadings

        store.stressReadings = [
            StressReading(level: 9, date: Date(), trigger: .work),
            StressReading(level: 8, date: Date().addingTimeInterval(-3600), trigger: .financial),
            StressReading(level: 7, date: Date().addingTimeInterval(-7200), trigger: .personal),
        ]

        let summary = store.healthSummary(days: 3, title: "TEST")
        #expect(summary.contains("High stress episodes"))

        store.stressReadings = saved
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Haptic Manager Tests
// ═══════════════════════════════════════════════════════════════════════════

struct HapticManagerTests {

    @Test func sharedInstanceExists() {
        let haptic = HapticManager.shared
        #expect(haptic === HapticManager.shared) // Same instance
    }

    @Test func impactStyles() {
        // Verify all impact styles are callable without crash
        let haptic = HapticManager.shared
        haptic.impact(.light)
        haptic.impact(.medium)
        haptic.impact(.heavy)
        haptic.impact(.soft)
        haptic.impact(.rigid)
    }

    @Test func notificationFeedback() {
        let haptic = HapticManager.shared
        haptic.success()
        haptic.warning()
        haptic.error()
    }

    @Test func convenienceMethods() {
        let haptic = HapticManager.shared
        haptic.tap()
        haptic.confirm()
        haptic.heavy()
        haptic.selection()
    }

    @Test func celebrateFeedback() {
        let haptic = HapticManager.shared
        haptic.celebrate()
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Jailbreak Detection Tests
// ═══════════════════════════════════════════════════════════════════════════

struct JailbreakDetectorTests {

    @Test func simulatorIsNotJailbroken() {
        // On simulator, should always return false
        #expect(JailbreakDetector.isJailbroken == false)
    }

    @Test func warningMessageNotEmpty() {
        #expect(!JailbreakDetector.warningMessage.isEmpty)
        #expect(JailbreakDetector.warningMessage.contains("jailbroken"))
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Screenshot Protection Tests
// ═══════════════════════════════════════════════════════════════════════════

struct ScreenshotProtectionTests {

    @Test func sharedInstance() {
        let protection = ScreenshotProtection.shared
        #expect(protection === ScreenshotProtection.shared)
    }

    @Test func initiallyNotProtecting() {
        let protection = ScreenshotProtection.shared
        #expect(protection.isProtecting == false)
    }

    @Test func startAndStopProtection() {
        let protection = ScreenshotProtection.shared
        protection.startProtecting()
        #expect(protection.isProtecting == true)
        protection.stopProtecting()
        #expect(protection.isProtecting == false)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - iCloud Backup Exclusion Tests
// ═══════════════════════════════════════════════════════════════════════════

struct BackupExclusionTests {

    @Test func sensitiveKeysNotEmpty() {
        #expect(BackupExclusion.sensitiveKeys.count > 10)
    }

    @Test func sensitiveKeysContainHealthData() {
        #expect(BackupExclusion.sensitiveKeys.contains("glucoseReadings"))
        #expect(BackupExclusion.sensitiveKeys.contains("bpReadings"))
        #expect(BackupExclusion.sensitiveKeys.contains("medications"))
        #expect(BackupExclusion.sensitiveKeys.contains("medicalRecords"))
        #expect(BackupExclusion.sensitiveKeys.contains("userProfile"))
    }

    @Test func excludeFromBackupFunction() {
        // Create a temp file and test exclusion
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("backup_test_\(UUID().uuidString).txt")
        try? "test".write(to: testFile, atomically: true, encoding: .utf8)

        let result = BackupExclusion.excludeFromBackup(url: testFile)
        #expect(result == true)

        try? FileManager.default.removeItem(at: testFile)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Data Retention Policy Tests
// ═══════════════════════════════════════════════════════════════════════════

struct DataRetentionPolicyTests {

    @Test func retentionPeriods() {
        #expect(DataRetentionPolicy.retentionYears == 7)
        #expect(DataRetentionPolicy.transientRetentionYears == 2)
    }

    @Test func retentionSummaryNotEmpty() {
        let summary = DataRetentionPolicy.retentionSummary
        #expect(!summary.isEmpty)
        #expect(summary.contains("7 years"))
        #expect(summary.contains("2 years"))
        #expect(summary.contains("GDPR"))
        #expect(summary.contains("Storage Limitation"))
    }

    @Test func enforceRetentionDoesNotDeleteRecentData() {
        let store = HealthStore.shared
        let saved = store.glucoseReadings

        // Add a recent reading
        let recent = GlucoseReading(value: 100, date: Date(), context: .fasting)
        store.glucoseReadings = [recent]

        DataRetentionPolicy.enforceRetention(store: store)

        // Recent data should survive
        #expect(store.glucoseReadings.count == 1)
        #expect(store.glucoseReadings.first?.value == 100)

        store.glucoseReadings = saved
    }

    @Test func enforceRetentionDeletesOldData() {
        let store = HealthStore.shared
        let saved = store.stressReadings

        let old = StressReading(level: 5,
                                date: Date().addingTimeInterval(-86400 * 365 * 3), // 3 years ago
                                trigger: .work)
        let recent = StressReading(level: 3, date: Date(), trigger: .personal)
        store.stressReadings = [old, recent]

        DataRetentionPolicy.enforceRetention(store: store)

        // Old transient data (>2 years) should be purged
        #expect(store.stressReadings.count == 1)
        #expect(store.stressReadings.first?.trigger == .personal)

        store.stressReadings = saved
    }

    @Test func enforceRetentionDeletesOldAlerts() {
        let store = HealthStore.shared
        let saved = store.healthAlerts

        let oldAlert = HealthAlert(
            date: Date().addingTimeInterval(-86400 * 400), // 400 days ago
            type: .reminder, title: "Old", message: "Old alert")
        let recentAlert = HealthAlert(
            date: Date(), type: .highGlucose, title: "New", message: "New alert")
        store.healthAlerts = [oldAlert, recentAlert]

        DataRetentionPolicy.enforceRetention(store: store)

        #expect(store.healthAlerts.count == 1)
        #expect(store.healthAlerts.first?.title == "New")

        store.healthAlerts = saved
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Referral System Tests
// ═══════════════════════════════════════════════════════════════════════════

struct ReferralSystemTests {

    @Test func generateReferralCode() {
        let code = ReferralCode.generate(for: "test@test.com", alias: "HealthHero_42")
        #expect(code.code.hasPrefix("BSA-"))
        #expect(code.code.count == 10) // "BSA-" + 6 chars
        #expect(code.referrerEmail == "test@test.com")
        #expect(code.referrerAlias == "HealthHero_42")
        #expect(code.isActive == true)
        #expect(code.redemptionCount == 0)
    }

    @Test func uniqueReferralCodes() {
        let code1 = ReferralCode.generate(for: "a@a.com", alias: "A")
        let code2 = ReferralCode.generate(for: "b@b.com", alias: "B")
        #expect(code1.code != code2.code)
    }

    @Test func referralRewardTiers() {
        #expect(ReferralReward.reward(for: 0) == nil)
        #expect(ReferralReward.reward(for: 1) == ReferralReward.tier1)
        #expect(ReferralReward.reward(for: 3) == ReferralReward.tier1)
        #expect(ReferralReward.reward(for: 5) == ReferralReward.tier5)
        #expect(ReferralReward.reward(for: 8) == ReferralReward.tier5)
        #expect(ReferralReward.reward(for: 10) == ReferralReward.tier10)
        #expect(ReferralReward.reward(for: 50) == ReferralReward.tier10)
    }

    @Test func referralCodeRedemptionCount() {
        var code = ReferralCode.generate(for: "test@test.com", alias: "Test")
        #expect(code.redemptionCount == 0)
        code.redeemedBy.append("user1@test.com")
        code.redeemedBy.append("user2@test.com")
        #expect(code.redemptionCount == 2)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - CEO Daily Summary Tests
// ═══════════════════════════════════════════════════════════════════════════

struct CEODailySummaryTests {

    @Test func summaryNotEmpty() {
        let store = HealthStore.shared
        let summary = CEODailySummary.buildSummary(store: store)
        #expect(!summary.isEmpty)
        #expect(summary.contains("Daily Business Summary"))
    }

    @Test func summaryContainsMetrics() {
        let store = HealthStore.shared
        let summary = CEODailySummary.buildSummary(store: store)
        #expect(summary.contains("Users:"))
        #expect(summary.contains("Doctors:"))
        #expect(summary.contains("revenue:"))
    }

    @Test func summaryShowsPendingDoctors() {
        let store = HealthStore.shared
        let saved = store.doctorRequests

        let request = DoctorRegistrationRequest(
            name: "Dr Summary", email: "sum@test.com", specialty: "Cardiologist",
            hospital: "Test", city: "London", country: "United Kingdom",
            postcode: "SW1A", gmcNumber: "111", gmcStatus: "Full",
            regulatoryBody: "GMC", pmqDegree: "MBBS", pmqCountry: "UK",
            pmqYear: 2015, plabPassed: false, ecfmgCertified: false, wdomListed: false,
            goodStanding: true, videoFee: 50, phoneFee: 35, inPersonFee: 75,
            introduction: "Test")
        store.doctorRequests = [request]

        let summary = CEODailySummary.buildSummary(store: store)
        #expect(summary.contains("1 doctor approvals pending"))

        store.doctorRequests = saved
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - BMI Category Tests (from doctorClinicalSummary)
// ═══════════════════════════════════════════════════════════════════════════

struct BMICategoryTests {

    @Test func underweightBMI() {
        let store = HealthStore.shared
        let saved = (store.userProfile.weight, store.userProfile.height)
        store.userProfile.weight = 45
        store.userProfile.height = 175
        let summary = store.doctorThirtyDaySummary()
        #expect(summary.contains("Underweight"))
        store.userProfile.weight = saved.0
        store.userProfile.height = saved.1
    }

    @Test func normalBMI() {
        let store = HealthStore.shared
        let saved = (store.userProfile.weight, store.userProfile.height)
        store.userProfile.weight = 70
        store.userProfile.height = 175
        let summary = store.doctorThirtyDaySummary()
        #expect(summary.contains("Normal"))
        store.userProfile.weight = saved.0
        store.userProfile.height = saved.1
    }

    @Test func overweightBMI() {
        let store = HealthStore.shared
        let saved = (store.userProfile.weight, store.userProfile.height)
        store.userProfile.weight = 85
        store.userProfile.height = 175
        let summary = store.doctorThirtyDaySummary()
        #expect(summary.contains("Overweight"))
        store.userProfile.weight = saved.0
        store.userProfile.height = saved.1
    }

    @Test func obeseBMI() {
        let store = HealthStore.shared
        let saved = (store.userProfile.weight, store.userProfile.height)
        store.userProfile.weight = 110
        store.userProfile.height = 170
        let summary = store.doctorThirtyDaySummary()
        #expect(summary.contains("Obese"))
        store.userProfile.weight = saved.0
        store.userProfile.height = saved.1
    }
}
