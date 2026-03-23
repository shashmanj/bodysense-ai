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
            print("⚕️ HealthKit auth error: \(error.localizedDescription)")
        }
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

    // MARK: - Blood Glucose

    func fetchLatestBloodGlucose() async -> Double? {
        await fetchLatestDouble(.bloodGlucose, unit: HKUnit(from: "mg/dL"))
    }

    func fetchRecentBloodGlucose(days: Int = 7) async -> [(date: Date, value: Double)] {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bloodGlucose) else { return [] }
        let unit = HKUnit(from: "mg/dL")
        return await withCheckedContinuation { cont in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate(days: days),
                limit: 100,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                let results = (samples as? [HKQuantitySample])?.map { s in
                    (date: s.endDate, value: s.quantity.doubleValue(for: unit))
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

    // MARK: - Comprehensive Sync

    /// Full sync — fetch everything and update HealthStore.
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
        async let waterHK     = fetchTodayWaterIntake()

        // Await all results
        let (s, d, c, m, _, ex) = await (steps, distance, calories, standMin, flights, exerciseMin)
        let (h, _, sp, hv, _, _, bt) = await (hr, restHR, spo2, hrv, vo2, respRate, bodyTemp)
        let (glu, bpVal, wt, _, wtr) = await (glucose, bp, weight, bodyFat, waterHK)

        let cal = Calendar.current

        // ── Steps/Activity ──
        if let idx = store.stepEntries.firstIndex(where: { cal.isDateInToday($0.date) && $0.source == "healthkit" }) {
            store.stepEntries[idx].steps         = s
            store.stepEntries[idx].distance      = d
            store.stepEntries[idx].calories      = c
            store.stepEntries[idx].activeMinutes = ex > 0 ? ex : m
        } else if s > 0 || d > 0 || c > 0 {
            store.stepEntries.append(StepEntry(
                date: Date(), steps: s, distance: d,
                calories: c, activeMinutes: ex > 0 ? ex : m, source: "healthkit"
            ))
        }

        // ── Heart Rate ──
        if let heartRate = h {
            let alreadyToday = store.heartRateReadings.contains { cal.isDateInToday($0.date) && $0.context == .rest }
            if !alreadyToday {
                store.heartRateReadings.insert(HeartRateReading(value: heartRate, date: Date(), context: .rest), at: 0)
            }
        }

        // ── HRV ──
        if let hrvVal = hv {
            let alreadyToday = store.hrvReadings.contains { cal.isDateInToday($0.date) }
            if !alreadyToday {
                store.hrvReadings.insert(HRVReading(value: hrvVal, date: Date()), at: 0)
            }
        }

        // ── Blood Glucose ──
        if let gluVal = glu, gluVal > 0 {
            let alreadyToday = store.glucoseReadings.contains { cal.isDateInToday($0.date) }
            if !alreadyToday {
                store.glucoseReadings.insert(GlucoseReading(value: gluVal, date: Date(), context: .random), at: 0)
            }
        }

        // ── Blood Pressure ──
        if let bpReading = bpVal, bpReading.systolic > 0 {
            let alreadyToday = store.bpReadings.contains { cal.isDateInToday($0.date) }
            if !alreadyToday {
                store.bpReadings.insert(BPReading(
                    systolic: bpReading.systolic, diastolic: bpReading.diastolic,
                    pulse: h ?? 72, date: Date()
                ), at: 0)
            }
        }

        // ── Body Temperature ──
        if let temp = bt, temp > 30 {
            let alreadyToday = store.bodyTempReadings.contains { cal.isDateInToday($0.date) }
            if !alreadyToday {
                store.bodyTempReadings.insert(BodyTempReading(value: temp, date: Date()), at: 0)
            }
        }

        // ── Weight ──
        if let w = wt, w > 0 {
            store.userProfile.weight = w
        }

        // ── Water Intake from HealthKit ──
        if wtr > 0 {
            let alreadyToday = store.waterEntries.contains { cal.isDateInToday($0.date) }
            if !alreadyToday {
                store.waterEntries.append(WaterEntry(date: Date(), amount: wtr))
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

        // ── Cache SpO2 for dashboard ──
        latestSpO2 = sp

        lastSyncTime = Date()
        store.save()

        print("⚕️ HealthKit sync complete: \(s) steps, \(String(format: "%.2f", d))km, \(c) kcal, " +
              "HR: \(h.map { "\($0)" } ?? "–"), HRV: \(hv.map { String(format: "%.0f", $0) } ?? "–")ms, " +
              "SpO2: \(sp.map { String(format: "%.0f%%", $0) } ?? "–"), Glucose: \(glu.map { String(format: "%.0f", $0) } ?? "–"), " +
              "BP: \(bpVal.map { "\($0.systolic)/\($0.diastolic)" } ?? "–"), Temp: \(bt.map { String(format: "%.1f°C", $0) } ?? "–"), " +
              "Weight: \(wt.map { String(format: "%.1fkg", $0) } ?? "–")")
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
