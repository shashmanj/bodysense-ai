//
//  HealthKitManager.swift
//  body sense ai
//
//  Auto-syncs steps, distance, calories burned, standing minutes and SpO2
//  from Apple Health / Apple Watch / BodySense Ring.
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

    // ── Types we want to READ ──────────────────────────────────────────────────
    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        let identifiers: [HKQuantityTypeIdentifier] = [
            .stepCount,
            .distanceWalkingRunning,
            .activeEnergyBurned,
            .appleStandTime,
            .oxygenSaturation,
            .heartRate,
            .restingHeartRate
        ]
        for id in identifiers {
            if let t = HKQuantityType.quantityType(forIdentifier: id) { types.insert(t) }
        }
        return types
    }

    // ── Request authorization ────────────────────────────────────────────────
    func requestAuthorization() async {
        guard isAvailable else { return }
        do {
            try await hkStore.requestAuthorization(toShare: [], read: readTypes)
            await MainActor.run { isAuthorized = true }
        } catch {
            print("⚕️ HealthKit auth error: \(error.localizedDescription)")
        }
    }

    // ── Today's date range ────────────────────────────────────────────────────
    private var todayPredicate: NSPredicate {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = Date()
        return HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
    }

    // ── Fetch TODAY'S step count ─────────────────────────────────────────────
    func fetchTodaySteps() async -> Int {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }
        return await withCheckedContinuation { cont in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: todayPredicate,
                options: .cumulativeSum
            ) { _, stats, _ in
                let val = stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                cont.resume(returning: Int(val))
            }
            hkStore.execute(query)
        }
    }

    // ── Fetch TODAY'S walking/running distance (km) ──────────────────────────
    func fetchTodayDistance() async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return 0 }
        return await withCheckedContinuation { cont in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: todayPredicate,
                options: .cumulativeSum
            ) { _, stats, _ in
                let val = stats?.sumQuantity()?.doubleValue(for: HKUnit.meterUnit(with: .kilo)) ?? 0
                cont.resume(returning: val)
            }
            hkStore.execute(query)
        }
    }

    // ── Fetch TODAY'S active calories burned ────────────────────────────────
    func fetchTodayCaloriesBurned() async -> Int {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0 }
        return await withCheckedContinuation { cont in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: todayPredicate,
                options: .cumulativeSum
            ) { _, stats, _ in
                let val = stats?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                cont.resume(returning: Int(val))
            }
            hkStore.execute(query)
        }
    }

    // ── Fetch TODAY'S standing minutes ──────────────────────────────────────
    func fetchTodayStandMinutes() async -> Int {
        guard let type = HKQuantityType.quantityType(forIdentifier: .appleStandTime) else { return 0 }
        return await withCheckedContinuation { cont in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: todayPredicate,
                options: .cumulativeSum
            ) { _, stats, _ in
                let val = stats?.sumQuantity()?.doubleValue(for: .minute()) ?? 0
                cont.resume(returning: Int(val))
            }
            hkStore.execute(query)
        }
    }

    // ── Fetch LATEST SpO2 reading ────────────────────────────────────────────
    func fetchLatestSpO2() async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else { return nil }
        return await withCheckedContinuation { cont in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                let val = (samples?.first as? HKQuantitySample)?
                    .quantity.doubleValue(for: HKUnit.percent()) ?? 0
                cont.resume(returning: val > 0 ? val * 100 : nil)  // convert 0.97 → 97%
            }
            hkStore.execute(query)
        }
    }

    // ── Fetch LATEST heart rate ───────────────────────────────────────────────
    func fetchLatestHeartRate() async -> Int? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return nil }
        return await withCheckedContinuation { cont in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: type,
                predicate: todayPredicate,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                let bpm = (samples?.first as? HKQuantitySample)?
                    .quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                cont.resume(returning: bpm != nil ? Int(bpm!) : nil)
            }
            hkStore.execute(query)
        }
    }

    // ── Full sync — fetch everything and update HealthStore ─────────────────
    @MainActor
    func syncAll(to store: HealthStore) async {
        guard isAuthorized else { return }

        async let steps     = fetchTodaySteps()
        async let distance  = fetchTodayDistance()
        async let calories  = fetchTodayCaloriesBurned()
        async let standMin  = fetchTodayStandMinutes()
        async let hr        = fetchLatestHeartRate()
        async let spo2      = fetchLatestSpO2()

        let (s, d, c, m, h, sp) = await (steps, distance, calories, standMin, hr, spo2)

        let cal = Calendar.current
        // Update or create today's HealthKit step entry
        if let idx = store.stepEntries.firstIndex(where: { cal.isDateInToday($0.date) && $0.source == "healthkit" }) {
            store.stepEntries[idx].steps         = s
            store.stepEntries[idx].distance      = d
            store.stepEntries[idx].calories      = c
            store.stepEntries[idx].activeMinutes = m
        } else if s > 0 || d > 0 || c > 0 {
            store.stepEntries.append(StepEntry(
                date: Date(), steps: s, distance: d,
                calories: c, activeMinutes: m, source: "healthkit"
            ))
        }

        // Sync heart rate
        if let heartRate = h {
            let alreadyToday = store.heartRateReadings.contains { cal.isDateInToday($0.date) }
            if !alreadyToday {
                store.heartRateReadings.insert(HeartRateReading(value: heartRate, date: Date()), at: 0)
            }
        }

        // Cache SpO2 for dashboard display
        latestSpO2 = sp

        lastSyncTime = Date()
        store.save()
        print("⚕️ HealthKit sync complete: \(s) steps, \(String(format: "%.2f", d))km, \(c) kcal, \(m) stand min, SpO2: \(sp.map { String(format: "%.0f%%", $0) } ?? "N/A")")
    }
}
