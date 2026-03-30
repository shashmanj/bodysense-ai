//
//  HealthKitManager.swift
//  body sense ai
//
//  Comprehensive HealthKit integration — syncs 40+ health data types
//  from Apple Health / Apple Watch / connected devices.
//  100% Apple-native using HealthKit framework.
//

import Foundation
import HealthKit

@Observable
class HealthKitManager {
    static let shared = HealthKitManager()
    private init() {}

    private let hkStore = HKHealthStore()
    var isAuthorized = false
    var lastSyncTime: Date?
    var latestSpO2: Double?

    /// Active observer queries — stored to prevent deallocation.
    private var observerQueries: [HKObserverQuery] = []
    private var isObserving = false

    /// Weak reference to HealthStore for observer callbacks.
    private weak var observerHealthStore: HealthStore?

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // MARK: - Read Types (40+ Health Data Types)

    /// All quantity types we request READ access for.
    private var quantityTypes: Set<HKQuantityType> {
        var types = Set<HKQuantityType>()
        let identifiers: [HKQuantityTypeIdentifier] = [
            // ── Vitals ──
            .heartRate,
            .restingHeartRate,
            .walkingHeartRateAverage,
            .heartRateVariabilitySDNN,
            .oxygenSaturation,
            .bloodPressureSystolic,
            .bloodPressureDiastolic,
            .bodyTemperature,
            .respiratoryRate,
            .bloodGlucose,
            .vo2Max,

            // ── Body Measurements ──
            .bodyMass,
            .bodyMassIndex,
            .bodyFatPercentage,
            .leanBodyMass,
            .waistCircumference,
            .height,

            // ── Activity & Fitness ──
            .stepCount,
            .distanceWalkingRunning,
            .distanceCycling,
            .activeEnergyBurned,
            .basalEnergyBurned,
            .appleExerciseTime,
            .appleStandTime,
            .flightsClimbed,

            // ── Nutrition ──
            .dietaryWater,
            .dietaryEnergyConsumed,
            .dietaryCarbohydrates,
            .dietaryProtein,
            .dietaryFatTotal,
            .dietaryFiber,
            .dietarySugar,
            .dietarySodium,
            .dietaryCaffeine,
            .dietaryIron,
            .dietaryVitaminD,

            // ── Reproductive ──
            .basalBodyTemperature,

            // ── Other Clinical ──
            .bloodAlcoholContent,
            .electrodermalActivity,
            .insulinDelivery,
            .numberOfTimesFallen,
            .peripheralPerfusionIndex
        ]
        for id in identifiers {
            if let t = HKQuantityType.quantityType(forIdentifier: id) { types.insert(t) }
        }
        return types
    }

    /// Category types we request READ access for.
    private var categoryTypes: Set<HKCategoryType> {
        var types = Set<HKCategoryType>()
        let identifiers: [HKCategoryTypeIdentifier] = [
            .sleepAnalysis,
            .menstrualFlow,
            .cervicalMucusQuality,
            .ovulationTestResult,
            .intermenstrualBleeding,
            .lowHeartRateEvent,
            .highHeartRateEvent,
            .irregularHeartRhythmEvent,
            .mindfulSession
        ]
        for id in identifiers {
            if let t = HKCategoryType.categoryType(forIdentifier: id) { types.insert(t) }
        }
        return types
    }

    /// Correlation types (Blood Pressure).
    private var correlationTypes: Set<HKCorrelationType> {
        var types = Set<HKCorrelationType>()
        if let bp = HKCorrelationType.correlationType(forIdentifier: .bloodPressure) {
            types.insert(bp)
        }
        return types
    }

    /// Combined set of all read types for authorization.
    /// NOTE: Correlation types (e.g. BloodPressure) must NOT be included here —
    /// HealthKit throws an NSException if you request auth for correlation types.
    /// Authorization is granted via the individual quantity types
    /// (bloodPressureSystolic / bloodPressureDiastolic) which are already included.
    private var readTypes: Set<HKObjectType> {
        var all = Set<HKObjectType>()
        for t in quantityTypes { all.insert(t) }
        for t in categoryTypes { all.insert(t) }
        // correlationTypes intentionally excluded — auth via component quantity types
        return all
    }

    // MARK: - Request Authorization

    func requestAuthorization() async {
        guard isAvailable, !isAuthorized else { return }
        do {
            try await hkStore.requestAuthorization(toShare: [], read: readTypes)
            await MainActor.run { isAuthorized = true }
        } catch {
            #if DEBUG
            print("⚕️ HealthKit auth error: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Live Observer Queries

    /// Sets up HKObserverQuery for critical real-time health types so CGM data,
    /// heart rate, steps, BP, and SpO2 from external devices are detected immediately
    /// without waiting for the next app launch.
    /// Call once after authorization succeeds.
    func startObserving(store: HealthStore) {
        guard isAuthorized, !isObserving else { return }
        isObserving = true
        observerHealthStore = store

        // Critical types to observe in real time
        let observedTypes: [(HKQuantityTypeIdentifier, HKUpdateFrequency)] = [
            (.bloodGlucose,          .immediate),  // CGM — Dexcom, Libre
            (.heartRate,             .hourly),      // Apple Watch
            (.stepCount,             .hourly),      // Live step counting
            (.bloodPressureSystolic, .hourly),      // BP monitors
            (.oxygenSaturation,      .hourly)       // SpO2
        ]

        for (identifier, frequency) in observedTypes {
            guard let sampleType = HKQuantityType.quantityType(forIdentifier: identifier) else { continue }

            // Enable background delivery so iOS wakes the app for new samples
            hkStore.enableBackgroundDelivery(for: sampleType, frequency: frequency) { success, error in
                #if DEBUG
                if let error = error {
                    print("⚕️ Background delivery error for \(identifier.rawValue): \(error.localizedDescription)")
                } else if success {
                    print("⚕️ Background delivery enabled for \(identifier.rawValue)")
                }
                #endif
            }

            // Create observer query that fires when new samples arrive
            let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { [weak self] _, completionHandler, error in
                guard let self = self, error == nil else {
                    completionHandler()
                    return
                }

                #if DEBUG
                print("⚕️ Observer fired for \(identifier.rawValue)")
                #endif

                // Re-fetch the specific data type and update the store
                Task { @MainActor [weak self] in
                    guard let self = self, let store = self.observerHealthStore else {
                        completionHandler()
                        return
                    }
                    await self.handleObserverUpdate(for: identifier, store: store)
                    completionHandler()
                }
            }

            hkStore.execute(query)
            observerQueries.append(query)
        }

        #if DEBUG
        print("⚕️ Live observer queries started for \(observedTypes.count) critical types")
        #endif
    }

    /// Handles a single observer callback — re-fetches only the changed type and updates HealthStore.
    @MainActor
    private func handleObserverUpdate(for identifier: HKQuantityTypeIdentifier, store: HealthStore) async {
        let cal = Calendar.current
        let now = Date()

        switch identifier {
        case .bloodGlucose:
            if let glu = await fetchLatestBloodGlucose(), glu > 0 {
                let alreadyRecent = store.glucoseReadings.first.map {
                    abs($0.date.timeIntervalSince(now)) < 300  // skip if last reading < 5 min ago
                } ?? false
                if !alreadyRecent {
                    store.glucoseReadings.insert(GlucoseReading(value: glu, date: now, context: .random), at: 0)
                    store.save()
                }
            }

        case .heartRate:
            if let hr = await fetchLatestHeartRate() {
                let alreadyToday = store.heartRateReadings.contains { cal.isDateInToday($0.date) && $0.context == .rest }
                if !alreadyToday {
                    store.heartRateReadings.insert(HeartRateReading(value: hr, date: now, context: .rest), at: 0)
                    store.save()
                }
            }

        case .stepCount:
            let steps = await fetchTodaySteps()
            let distance = await fetchTodayDistance()
            let calories = await fetchTodayCaloriesBurned()
            let exercise = await fetchTodayExerciseMinutes()
            if let idx = store.stepEntries.firstIndex(where: { cal.isDateInToday($0.date) && $0.source == "healthkit" }) {
                store.stepEntries[idx].steps = steps
                store.stepEntries[idx].distance = distance
                store.stepEntries[idx].calories = calories
                store.stepEntries[idx].activeMinutes = exercise
                store.save()
            } else if steps > 0 || distance > 0 || calories > 0 {
                store.stepEntries.append(StepEntry(
                    date: now, steps: steps, distance: distance,
                    calories: calories, activeMinutes: exercise, source: "healthkit"
                ))
                store.save()
            }

        case .bloodPressureSystolic:
            if let bp = await fetchLatestBloodPressure(), bp.systolic > 0 {
                let alreadyToday = store.bpReadings.contains { cal.isDateInToday($0.date) }
                if !alreadyToday {
                    let hr = await fetchLatestHeartRate()
                    store.bpReadings.insert(BPReading(
                        systolic: bp.systolic, diastolic: bp.diastolic,
                        pulse: hr ?? 72, date: now
                    ), at: 0)
                    store.save()
                }
            }

        case .oxygenSaturation:
            if let spo2 = await fetchLatestSpO2(), spo2 > 0 {
                let alreadyToday = store.spo2Readings.contains { cal.isDateInToday($0.date) }
                if !alreadyToday {
                    store.spo2Readings.insert(SpO2Reading(value: spo2, date: now), at: 0)
                    latestSpO2 = spo2
                    store.save()
                }
            }

        default:
            break
        }

        lastSyncTime = Date()
    }

    // MARK: - Date Helpers

    private var todayPredicate: NSPredicate {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        return HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
    }

    private func predicate(days: Int) -> NSPredicate {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -days, to: Date())!
        return HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
    }

    // MARK: - Activity Fetchers

    func fetchTodaySteps() async -> Int {
        await fetchCumulativeSum(.stepCount, unit: .count())
    }

    func fetchTodayDistance() async -> Double {
        await fetchCumulativeSumDouble(.distanceWalkingRunning, unit: HKUnit.meterUnit(with: .kilo))
    }

    func fetchTodayCaloriesBurned() async -> Int {
        await fetchCumulativeSum(.activeEnergyBurned, unit: .kilocalorie())
    }

    func fetchTodayStandMinutes() async -> Int {
        await fetchCumulativeSum(.appleStandTime, unit: .minute())
    }

    func fetchTodayFlightsClimbed() async -> Int {
        await fetchCumulativeSum(.flightsClimbed, unit: .count())
    }

    func fetchTodayExerciseMinutes() async -> Int {
        await fetchCumulativeSum(.appleExerciseTime, unit: .minute())
    }

    func fetchTodayBasalCalories() async -> Int {
        await fetchCumulativeSum(.basalEnergyBurned, unit: .kilocalorie())
    }

    func fetchTodayCyclingDistance() async -> Double {
        await fetchCumulativeSumDouble(.distanceCycling, unit: HKUnit.meterUnit(with: .kilo))
    }

    // MARK: - Vitals Fetchers

    func fetchLatestHeartRate() async -> Int? {
        await fetchLatestInt(.heartRate, unit: HKUnit.count().unitDivided(by: .minute()))
    }

    func fetchLatestRestingHeartRate() async -> Int? {
        await fetchLatestInt(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()))
    }

    func fetchLatestWalkingHeartRate() async -> Int? {
        await fetchLatestInt(.walkingHeartRateAverage, unit: HKUnit.count().unitDivided(by: .minute()))
    }

    func fetchLatestSpO2() async -> Double? {
        guard let val = await fetchLatestDouble(.oxygenSaturation, unit: .percent()) else { return nil }
        return val > 1 ? val : val * 100 // Normalize to percentage
    }

    func fetchLatestHRV() async -> Double? {
        await fetchLatestDouble(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli))
    }

    func fetchLatestVO2Max() async -> Double? {
        await fetchLatestDouble(.vo2Max, unit: HKUnit(from: "ml/kg*min"))
    }

    func fetchLatestRespiratoryRate() async -> Double? {
        await fetchLatestDouble(.respiratoryRate, unit: HKUnit.count().unitDivided(by: .minute()))
    }

    func fetchLatestBodyTemp() async -> Double? {
        await fetchLatestDouble(.bodyTemperature, unit: .degreeCelsius())
    }

    // MARK: - Blood Glucose (read in mmol/L, convert to mg/dL for internal storage)

    /// Fetches latest blood glucose from HealthKit in mmol/L, returns mg/dL for internal consistency.
    func fetchLatestBloodGlucose() async -> Double? {
        guard let mmol = await fetchLatestDouble(.bloodGlucose, unit: HKUnit.moleUnit(with: .milli, molarMass: HKUnitMolarMassBloodGlucose).unitDivided(by: .liter())) else { return nil }
        return mmol * 18.0  // mmol/L → mg/dL for internal storage
    }

    func fetchRecentBloodGlucose(days: Int = 7) async -> [(date: Date, value: Double)] {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bloodGlucose) else { return [] }
        let unit = HKUnit.moleUnit(with: .milli, molarMass: HKUnitMolarMassBloodGlucose).unitDivided(by: .liter())
        return await withCheckedContinuation { cont in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate(days: days),
                limit: 100,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                let results = (samples as? [HKQuantitySample])?.map { s in
                    (date: s.endDate, value: s.quantity.doubleValue(for: unit) * 18.0)  // mmol/L → mg/dL
                } ?? []
                cont.resume(returning: results)
            }
            hkStore.execute(query)
        }
    }

    // MARK: - Blood Pressure

    func fetchLatestBloodPressure() async -> (systolic: Int, diastolic: Int)? {
        guard let bpType = HKCorrelationType.correlationType(forIdentifier: .bloodPressure) else { return nil }
        return await withCheckedContinuation { cont in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: bpType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                guard let correlation = samples?.first as? HKCorrelation else {
                    cont.resume(returning: nil)
                    return
                }
                let sysType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!
                let diaType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!
                let mmHg = HKUnit.millimeterOfMercury()
                let sys = (correlation.objects(for: sysType).first as? HKQuantitySample)?
                    .quantity.doubleValue(for: mmHg) ?? 0
                let dia = (correlation.objects(for: diaType).first as? HKQuantitySample)?
                    .quantity.doubleValue(for: mmHg) ?? 0
                cont.resume(returning: (systolic: Int(sys), diastolic: Int(dia)))
            }
            hkStore.execute(query)
        }
    }

    // MARK: - Body Measurements

    func fetchLatestWeight() async -> Double? {
        await fetchLatestDouble(.bodyMass, unit: .gramUnit(with: .kilo))
    }

    func fetchLatestBodyFat() async -> Double? {
        guard let val = await fetchLatestDouble(.bodyFatPercentage, unit: .percent()) else { return nil }
        return val > 1 ? val : val * 100
    }

    func fetchLatestBMI() async -> Double? {
        await fetchLatestDouble(.bodyMassIndex, unit: .count())
    }

    func fetchLatestHeight() async -> Double? {
        await fetchLatestDouble(.height, unit: .meterUnit(with: .centi))
    }

    func fetchLatestWaistCircumference() async -> Double? {
        await fetchLatestDouble(.waistCircumference, unit: .meterUnit(with: .centi))
    }

    func fetchLatestLeanBodyMass() async -> Double? {
        await fetchLatestDouble(.leanBodyMass, unit: .gramUnit(with: .kilo))
    }

    // MARK: - Basal Body Temperature

    func fetchLatestBasalBodyTemp() async -> Double? {
        await fetchLatestDouble(.basalBodyTemperature, unit: .degreeCelsius())
    }

    // MARK: - Insulin Delivery

    func fetchTodayInsulinDelivery() async -> Double {
        await fetchCumulativeSumDouble(.insulinDelivery, unit: .internationalUnit())
    }

    // MARK: - Nutrition (extended)

    func fetchTodayProtein() async -> Double {
        await fetchCumulativeSumDouble(.dietaryProtein, unit: .gram())
    }

    func fetchTodayCarbs() async -> Double {
        await fetchCumulativeSumDouble(.dietaryCarbohydrates, unit: .gram())
    }

    func fetchTodayFat() async -> Double {
        await fetchCumulativeSumDouble(.dietaryFatTotal, unit: .gram())
    }

    func fetchTodayFiber() async -> Double {
        await fetchCumulativeSumDouble(.dietaryFiber, unit: .gram())
    }

    func fetchTodaySugar() async -> Double {
        await fetchCumulativeSumDouble(.dietarySugar, unit: .gram())
    }

    func fetchTodaySodium() async -> Double {
        await fetchCumulativeSumDouble(.dietarySodium, unit: .gram())
    }

    func fetchTodayCaffeine() async -> Double {
        await fetchCumulativeSumDouble(.dietaryCaffeine, unit: .gram())
    }

    // MARK: - Mindful Sessions

    func fetchTodayMindfulMinutes() async -> Double {
        guard let type = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else { return 0 }
        return await withCheckedContinuation { cont in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: type,
                predicate: todayPredicate,
                limit: 100,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                let totalSeconds = (samples as? [HKCategorySample])?.reduce(0.0) { sum, s in
                    sum + s.endDate.timeIntervalSince(s.startDate)
                } ?? 0
                cont.resume(returning: totalSeconds / 60.0)
            }
            hkStore.execute(query)
        }
    }

    // MARK: - Sleep Analysis

    func fetchSleepAnalysis(days: Int = 7) async -> [(date: Date, duration: TimeInterval, inBed: TimeInterval)] {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return [] }
        return await withCheckedContinuation { cont in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate(days: days),
                limit: 200,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                guard let categorySamples = samples as? [HKCategorySample] else {
                    cont.resume(returning: [])
                    return
                }
                // Group by night (calendar day of end date)
                let cal = Calendar.current
                var nightSummaries: [Date: (asleep: TimeInterval, inBed: TimeInterval)] = [:]
                for sample in categorySamples {
                    let nightDate = cal.startOfDay(for: sample.endDate)
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    let existing = nightSummaries[nightDate, default: (asleep: 0, inBed: 0)]
                    if sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue {
                        nightSummaries[nightDate] = (asleep: existing.asleep, inBed: existing.inBed + duration)
                    } else if sample.value != HKCategoryValueSleepAnalysis.awake.rawValue {
                        // asleepCore, asleepDeep, asleepREM, asleepUnspecified
                        nightSummaries[nightDate] = (asleep: existing.asleep + duration, inBed: existing.inBed + duration)
                    }
                }
                let results = nightSummaries.map { (date: $0.key, duration: $0.value.asleep, inBed: $0.value.inBed) }
                    .sorted { $0.date > $1.date }
                cont.resume(returning: results)
            }
            hkStore.execute(query)
        }
    }

    // MARK: - Menstrual Cycle

    func fetchMenstrualFlow(days: Int = 90) async -> [(date: Date, flow: Int)] {
        guard let type = HKCategoryType.categoryType(forIdentifier: .menstrualFlow) else { return [] }
        return await withCheckedContinuation { cont in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate(days: days),
                limit: 100,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                let results = (samples as? [HKCategorySample])?.map { s in
                    (date: s.startDate, flow: s.value)
                } ?? []
                cont.resume(returning: results)
            }
            hkStore.execute(query)
        }
    }

    // MARK: - Nutrition from HealthKit

    func fetchTodayWaterIntake() async -> Double {
        await fetchCumulativeSumDouble(.dietaryWater, unit: .literUnit(with: .milli))
    }

    func fetchTodayDietaryCalories() async -> Int {
        await fetchCumulativeSum(.dietaryEnergyConsumed, unit: .kilocalorie())
    }

    // MARK: - Heart Events

    func fetchHeartEvents(days: Int = 30) async -> [(date: Date, type: String)] {
        var events: [(date: Date, type: String)] = []
        let eventTypes: [(HKCategoryTypeIdentifier, String)] = [
            (.lowHeartRateEvent, "Low Heart Rate"),
            (.highHeartRateEvent, "High Heart Rate"),
            (.irregularHeartRhythmEvent, "Irregular Rhythm")
        ]
        for (identifier, label) in eventTypes {
            guard let type = HKCategoryType.categoryType(forIdentifier: identifier) else { continue }
            let results: [(date: Date, type: String)] = await withCheckedContinuation { cont in
                let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
                let query = HKSampleQuery(
                    sampleType: type,
                    predicate: predicate(days: days),
                    limit: 10,
                    sortDescriptors: [sort]
                ) { _, samples, _ in
                    let r = (samples as? [HKCategorySample])?.map { s in
                        (date: s.startDate, type: label)
                    } ?? []
                    cont.resume(returning: r)
                }
                hkStore.execute(query)
            }
            events.append(contentsOf: results)
        }
        return events.sorted { $0.date > $1.date }
    }

    // MARK: - Comprehensive Sync (40+ Health Data Types)

    /// Full sync — fetch everything from HealthKit and update HealthStore.
    @MainActor
    func syncAll(to store: HealthStore) async {
        guard isAuthorized else { return }

        // ── Activity (parallel) ──
        async let steps       = fetchTodaySteps()
        async let distance    = fetchTodayDistance()
        async let calories    = fetchTodayCaloriesBurned()
        async let standMin    = fetchTodayStandMinutes()
        async let flights     = fetchTodayFlightsClimbed()
        async let exerciseMin = fetchTodayExerciseMinutes()
        async let basalCal    = fetchTodayBasalCalories()
        async let cyclingDist = fetchTodayCyclingDistance()

        // ── Vitals (parallel) ──
        async let hr          = fetchLatestHeartRate()
        async let restHR      = fetchLatestRestingHeartRate()
        async let spo2        = fetchLatestSpO2()
        async let hrv         = fetchLatestHRV()
        async let vo2         = fetchLatestVO2Max()
        async let respRate    = fetchLatestRespiratoryRate()
        async let bodyTemp    = fetchLatestBodyTemp()

        // ── Blood & Body (parallel) ──
        async let glucose     = fetchLatestBloodGlucose()
        async let bp          = fetchLatestBloodPressure()
        async let weight      = fetchLatestWeight()
        async let bodyFat     = fetchLatestBodyFat()
        async let bmi         = fetchLatestBMI()
        async let heightVal   = fetchLatestHeight()
        async let waist       = fetchLatestWaistCircumference()
        async let lean        = fetchLatestLeanBodyMass()
        async let waterHK     = fetchTodayWaterIntake()

        // ── Nutrition (parallel) ──
        async let dietCal     = fetchTodayDietaryCalories()
        async let protein     = fetchTodayProtein()
        async let carbs       = fetchTodayCarbs()
        async let fat         = fetchTodayFat()
        async let fiber       = fetchTodayFiber()
        async let sugar       = fetchTodaySugar()
        async let sodium      = fetchTodaySodium()
        async let caffeine    = fetchTodayCaffeine()

        // ── Clinical & Reproductive (parallel) ──
        async let insulin     = fetchTodayInsulinDelivery()
        async let basalTemp   = fetchLatestBasalBodyTemp()
        async let mindful     = fetchTodayMindfulMinutes()

        // Await all activity results
        let (s, d, c, m, fl, ex) = await (steps, distance, calories, standMin, flights, exerciseMin)
        let (bCal, cyc) = await (basalCal, cyclingDist)

        // Await all vitals
        let (h, rhr, sp, hv, v2, rr, bt) = await (hr, restHR, spo2, hrv, vo2, respRate, bodyTemp)

        // Await blood & body
        let (glu, bpVal, wt, bf, bmiVal) = await (glucose, bp, weight, bodyFat, bmi)
        let (ht, wc, lbm, wtr) = await (heightVal, waist, lean, waterHK)

        // Await nutrition
        let (dCal, prot, crb, ft, fib) = await (dietCal, protein, carbs, fat, fiber)
        let (sug, sod, caf) = await (sugar, sodium, caffeine)

        // Await clinical & reproductive
        let (ins, bbt, mf) = await (insulin, basalTemp, mindful)

        let cal = Calendar.current
        let now = Date()

        // ── Steps/Activity ──
        if let idx = store.stepEntries.firstIndex(where: { cal.isDateInToday($0.date) && $0.source == "healthkit" }) {
            store.stepEntries[idx].steps         = s
            store.stepEntries[idx].distance      = d
            store.stepEntries[idx].calories      = c
            store.stepEntries[idx].activeMinutes = ex > 0 ? ex : m
        } else if s > 0 || d > 0 || c > 0 {
            store.stepEntries.append(StepEntry(
                date: now, steps: s, distance: d,
                calories: c, activeMinutes: ex > 0 ? ex : m, source: "healthkit"
            ))
        }

        // ── Heart Rate ──
        if let heartRate = h {
            let alreadyToday = store.heartRateReadings.contains { cal.isDateInToday($0.date) && $0.context == .rest }
            if !alreadyToday {
                store.heartRateReadings.insert(HeartRateReading(value: heartRate, date: now, context: .rest), at: 0)
            }
        }

        // ── HRV ──
        if let hrvVal = hv {
            let alreadyToday = store.hrvReadings.contains { cal.isDateInToday($0.date) }
            if !alreadyToday {
                store.hrvReadings.insert(HRVReading(value: hrvVal, date: now), at: 0)
            }
        }

        // ── SpO2 (Blood Oxygen) ──
        if let spo2Val = sp, spo2Val > 0 {
            let alreadyToday = store.spo2Readings.contains { cal.isDateInToday($0.date) }
            if !alreadyToday {
                store.spo2Readings.insert(SpO2Reading(value: spo2Val, date: now), at: 0)
            }
        }

        // ── Respiratory Rate ──
        if let rrVal = rr, rrVal > 0 {
            let alreadyToday = store.respiratoryRateReadings.contains { cal.isDateInToday($0.date) }
            if !alreadyToday {
                store.respiratoryRateReadings.insert(RespiratoryRateReading(value: rrVal, date: now), at: 0)
            }
        }

        // ── VO2 Max ──
        if let vo2Val = v2, vo2Val > 0 {
            let alreadyToday = store.vo2MaxReadings.contains { cal.isDateInToday($0.date) }
            if !alreadyToday {
                store.vo2MaxReadings.insert(VO2MaxReading(value: vo2Val, date: now), at: 0)
            }
        }

        // ── Blood Glucose ──
        if let gluVal = glu, gluVal > 0 {
            let alreadyToday = store.glucoseReadings.contains { cal.isDateInToday($0.date) }
            if !alreadyToday {
                store.glucoseReadings.insert(GlucoseReading(value: gluVal, date: now, context: .random), at: 0)
            }
        }

        // ── Blood Pressure ──
        if let bpReading = bpVal, bpReading.systolic > 0 {
            let alreadyToday = store.bpReadings.contains { cal.isDateInToday($0.date) }
            if !alreadyToday {
                store.bpReadings.insert(BPReading(
                    systolic: bpReading.systolic, diastolic: bpReading.diastolic,
                    pulse: h ?? 72, date: now
                ), at: 0)
            }
        }

        // ── Body Temperature ──
        if let temp = bt, temp > 30 {
            let alreadyToday = store.bodyTempReadings.contains { cal.isDateInToday($0.date) }
            if !alreadyToday {
                store.bodyTempReadings.insert(BodyTempReading(value: temp, date: now), at: 0)
            }
        }

        // ── Weight & Height → UserProfile ──
        if let w = wt, w > 0 {
            store.userProfile.weight = w
        }
        if let h = ht, h > 0 {
            store.userProfile.height = h
        }

        // ── Body Measurements (BMI, body fat, waist, lean body mass) ──
        let hasMeasurement = (bmiVal != nil || bf != nil || wc != nil || lbm != nil)
        if hasMeasurement {
            let alreadyToday = store.bodyMeasurements.contains { cal.isDateInToday($0.date) }
            if !alreadyToday {
                let normalizedBF: Double? = {
                    guard let v = bf else { return nil }
                    return v > 1 ? v : v * 100  // normalize percentage
                }()
                store.bodyMeasurements.insert(BodyMeasurement(
                    date: now,
                    bmi: bmiVal,
                    bodyFat: normalizedBF,
                    height: ht,
                    waistCirc: wc,
                    leanBodyMass: lbm
                ), at: 0)
            }
        }

        // ── Water Intake from HealthKit ──
        if wtr > 0 {
            let alreadyToday = store.waterEntries.contains { cal.isDateInToday($0.date) }
            if !alreadyToday {
                store.waterEntries.append(WaterEntry(date: now, amount: wtr))
            }
        }

        // ── Nutrition from HealthKit (aggregate into a NutritionLog if any data) ──
        if dCal > 0 || prot > 0 || crb > 0 || ft > 0 {
            let alreadyToday = store.nutritionLogs.contains {
                cal.isDateInToday($0.date) && $0.notes == "Synced from Apple Health"
            }
            if !alreadyToday {
                store.nutritionLogs.append(NutritionLog(
                    date: now,
                    mealType: .snack,
                    calories: dCal,
                    carbs: crb,
                    protein: prot,
                    fat: ft,
                    fiber: fib,
                    sugar: sug,
                    salt: sod * 1000,  // grams → mg, then stored as grams (sodium→salt conversion)
                    foodName: "HealthKit Daily Total",
                    notes: "Synced from Apple Health"
                ))
            }
        }

        // ── Insulin Delivery ──
        if ins > 0 {
            let alreadyToday = store.insulinDeliveries.contains { cal.isDateInToday($0.date) }
            if !alreadyToday {
                store.insulinDeliveries.insert(InsulinDeliveryReading(value: ins, date: now), at: 0)
            }
        }

        // ── Basal Body Temperature ──
        if let bbtVal = bbt, bbtVal > 30 {
            let alreadyToday = store.basalBodyTempReadings.contains { cal.isDateInToday($0.date) }
            if !alreadyToday {
                store.basalBodyTempReadings.insert(BasalBodyTempReading(value: bbtVal, date: now), at: 0)
            }
        }

        // ── Mindful Minutes ──
        if mf > 0 {
            let alreadyToday = store.mindfulSessions.contains { cal.isDateInToday($0.date) }
            if !alreadyToday {
                store.mindfulSessions.insert(MindfulSessionEntry(date: now, duration: mf), at: 0)
            }
        }

        // ── Sleep from HealthKit ──
        let sleepData = await fetchSleepAnalysis(days: 3)
        for night in sleepData {
            let hours = night.duration / 3600
            guard hours > 0.5 else { continue } // ignore very short naps
            let alreadyExists = store.sleepEntries.contains {
                cal.isDate($0.date, inSameDayAs: night.date)
            }
            if !alreadyExists {
                let quality: SleepQuality = hours >= 8 ? .excellent : hours >= 7 ? .good : hours >= 5.5 ? .fair : .poor
                store.sleepEntries.insert(SleepEntry(
                    date: night.date,
                    duration: hours,
                    quality: quality,
                    deepSleep: hours * 0.2,
                    remSleep: hours * 0.25,
                    lightSleep: hours * 0.55,
                    awakenings: 0,
                    notes: "Synced from Apple Health"
                ), at: 0)
            }
        }

        // ── Cache SpO2 for dashboard (backward compat) ──
        latestSpO2 = sp

        lastSyncTime = Date()
        store.save()

        #if DEBUG
        let syncedTypes = [
            s > 0 ? "steps:\(s)" : nil,
            d > 0 ? String(format: "dist:%.2fkm", d) : nil,
            c > 0 ? "cal:\(c)" : nil,
            bCal > 0 ? "basal:\(bCal)" : nil,
            fl > 0 ? "flights:\(fl)" : nil,
            ex > 0 ? "exercise:\(ex)min" : nil,
            m > 0 ? "stand:\(m)min" : nil,
            cyc > 0 ? String(format: "cycling:%.2fkm", cyc) : nil,
            h.map { "HR:\($0)" },
            rhr.map { "restHR:\($0)" },
            sp.map { String(format: "SpO2:%.0f%%", $0) },
            hv.map { String(format: "HRV:%.0fms", $0) },
            v2.map { String(format: "VO2:%.1f", $0) },
            rr.map { String(format: "resp:%.1f", $0) },
            bt.map { String(format: "temp:%.1f°C", $0) },
            glu.map { String(format: "glu:%.0fmg/dL", $0) },
            bpVal.map { "BP:\($0.systolic)/\($0.diastolic)" },
            wt.map { String(format: "wt:%.1fkg", $0) },
            ht.map { String(format: "ht:%.1fcm", $0) },
            bf.map { String(format: "bf:%.1f%%", $0) },
            bmiVal.map { String(format: "BMI:%.1f", $0) },
            wc.map { String(format: "waist:%.1fcm", $0) },
            lbm.map { String(format: "lean:%.1fkg", $0) },
            wtr > 0 ? String(format: "water:%.0fml", wtr) : nil,
            dCal > 0 ? "dietCal:\(dCal)" : nil,
            prot > 0 ? String(format: "protein:%.1fg", prot) : nil,
            crb > 0 ? String(format: "carbs:%.1fg", crb) : nil,
            ft > 0 ? String(format: "fat:%.1fg", ft) : nil,
            fib > 0 ? String(format: "fiber:%.1fg", fib) : nil,
            sug > 0 ? String(format: "sugar:%.1fg", sug) : nil,
            sod > 0 ? String(format: "sodium:%.2fg", sod) : nil,
            caf > 0 ? String(format: "caffeine:%.1fmg", caf * 1000) : nil,
            ins > 0 ? String(format: "insulin:%.1fIU", ins) : nil,
            bbt.map { String(format: "basalTemp:%.1f°C", $0) },
            mf > 0 ? String(format: "mindful:%.0fmin", mf) : nil
        ].compactMap { $0 }.joined(separator: ", ")
        print("⚕️ HealthKit sync complete: \(syncedTypes)")
        #endif
    }

    // MARK: - Generic Fetch Helpers

    /// Fetch cumulative sum for today as Int.
    private func fetchCumulativeSum(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Int {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return 0 }
        return await withCheckedContinuation { cont in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: todayPredicate,
                options: .cumulativeSum
            ) { _, stats, _ in
                let val = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                cont.resume(returning: Int(val))
            }
            hkStore.execute(query)
        }
    }

    /// Fetch cumulative sum for today as Double.
    private func fetchCumulativeSumDouble(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return 0 }
        return await withCheckedContinuation { cont in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: todayPredicate,
                options: .cumulativeSum
            ) { _, stats, _ in
                let val = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                cont.resume(returning: val)
            }
            hkStore.execute(query)
        }
    }

    /// Fetch latest sample as Int.
    private func fetchLatestInt(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Int? {
        guard let val = await fetchLatestDouble(identifier, unit: unit) else { return nil }
        return Int(val)
    }

    /// Fetch latest sample as Double.
    private func fetchLatestDouble(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        return await withCheckedContinuation { cont in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                let val = (samples?.first as? HKQuantitySample)?
                    .quantity.doubleValue(for: unit)
                cont.resume(returning: val)
            }
            hkStore.execute(query)
        }
    }
}
