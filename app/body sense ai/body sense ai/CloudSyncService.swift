//
//  CloudSyncService.swift
//  body sense ai
//
//  Native CloudKit sync service for health data backup and cross-device sync.
//  Uses CKDatabase (private) — data is end-to-end encrypted by Apple.
//  No third-party dependencies — 100% Apple-native.
//

import Foundation
import CloudKit

/// Syncs HealthStore data to/from iCloud using CloudKit private database.
@MainActor
@Observable
final class CloudSyncService {

    static let shared = CloudSyncService()

    // MARK: - State

    var isSyncing: Bool = false
    var lastSyncDate: Date?
    var syncError: String?
    var syncProgress: String?

    // MARK: - CloudKit Configuration

    /// CloudKit container — uses the app's default iCloud container.
    /// Container ID must be configured in Xcode:
    ///   Signing & Capabilities → iCloud → CloudKit → Container: iCloud.com.bodysenseai
    private var container: CKContainer { CKContainer.default() }
    private var database: CKDatabase { container.privateCloudDatabase }

    /// Whether CloudKit is available (entitlement configured + iCloud signed in).
    var isCloudKitAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    /// Record types used in CloudKit.
    private enum RecordType {
        static let healthData     = "HealthData"
        static let userProfile    = "UserProfile"
        static let syncMetadata   = "SyncMetadata"
    }

    /// Zone for all health data.
    private let healthZone = CKRecordZone(zoneName: "HealthDataZone")

    private init() {
        loadLastSyncDate()
    }

    // MARK: - Zone Setup

    /// Create the custom zone if it doesn't exist. Call on first sync.
    private func ensureZoneExists() async throws {
        do {
            _ = try await database.save(healthZone)
        } catch let error as CKError where error.code == .serverRejectedRequest {
            // Zone already exists — that's fine
        } catch let error as CKError where error.code == .zoneNotFound {
            _ = try await database.save(healthZone)
        }
    }

    // MARK: - Sync to Cloud

    /// Upload all health data from HealthStore to CloudKit.
    /// Uses a single CKRecord per data category for simplicity.
    func syncToCloud(store: HealthStore) async {
        guard !isSyncing else { return }
        guard isCloudKitAvailable else {
            syncError = "iCloud is not available. Please sign in to iCloud in Settings."
            return
        }

        isSyncing = true
        syncError = nil
        syncProgress = "Preparing data..."

        do {
            try await ensureZoneExists()

            let zoneID = healthZone.zoneID
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601

            // Build records for each data category
            var records: [CKRecord] = []

            // ── User Profile ──
            let profileRecord = CKRecord(recordType: RecordType.userProfile,
                                         recordID: CKRecord.ID(recordName: "userProfile", zoneID: zoneID))
            if let data = try? encoder.encode(store.userProfile) {
                profileRecord["data"] = data as CKRecordValue
                profileRecord["lastModified"] = Date() as CKRecordValue
                records.append(profileRecord)
            }

            // ── Health Data Categories ──
            let categories: [(String, () throws -> Data?)] = [
                ("glucoseReadings",    { try encoder.encode(store.glucoseReadings) }),
                ("bpReadings",         { try encoder.encode(store.bpReadings) }),
                ("heartRateReadings",  { try encoder.encode(store.heartRateReadings) }),
                ("hrvReadings",        { try encoder.encode(store.hrvReadings) }),
                ("sleepEntries",       { try encoder.encode(store.sleepEntries) }),
                ("stressReadings",     { try encoder.encode(store.stressReadings) }),
                ("bodyTempReadings",   { try encoder.encode(store.bodyTempReadings) }),
                ("stepEntries",        { try encoder.encode(store.stepEntries) }),
                ("waterEntries",       { try encoder.encode(store.waterEntries) }),
                ("nutritionLogs",      { try encoder.encode(store.nutritionLogs) }),
                ("symptomLogs",        { try encoder.encode(store.symptomLogs) }),
                ("medications",        { try encoder.encode(store.medications) }),
                ("cycles",             { try encoder.encode(store.cycles) }),
                ("healthAlerts",       { try encoder.encode(store.healthAlerts) }),
                ("healthGoals",        { try encoder.encode(store.healthGoals) }),
                ("healthChallenges",   { try encoder.encode(store.healthChallenges) }),
                ("achievements",       { try encoder.encode(store.achievements) }),
                ("userStreaks",         { try encoder.encode(store.userStreaks) }),
                ("communityGroups",    { try encoder.encode(store.communityGroups) }),
                ("appointments",       { try encoder.encode(store.appointments) }),
                ("prescriptions",      { try encoder.encode(store.prescriptions) }),
                ("orders",             { try encoder.encode(store.orders) }),
                ("medicalRecords",     { try encoder.encode(store.medicalRecords) }),
            ]

            for (name, encode) in categories {
                if let data = try? encode() {
                    let record = CKRecord(recordType: RecordType.healthData,
                                          recordID: CKRecord.ID(recordName: name, zoneID: zoneID))
                    record["category"] = name as CKRecordValue
                    record["data"] = data as CKRecordValue
                    record["lastModified"] = Date() as CKRecordValue
                    records.append(record)
                }
            }

            syncProgress = "Uploading \(records.count) categories..."

            // Use modifyRecords to upsert all records in one batch
            let (saveResults, _) = try await database.modifyRecords(
                saving: records,
                deleting: [],
                savePolicy: .allKeys
            )

            // Check for per-record errors
            var failedCount = 0
            for (_, result) in saveResults {
                if case .failure = result { failedCount += 1 }
            }

            let now = Date()
            lastSyncDate = now
            isSyncing = false
            syncProgress = nil
            if failedCount > 0 {
                syncError = "\(failedCount) categories failed to sync"
            }

            saveLastSyncDate(now)

        } catch {
            isSyncing = false
            syncError = error.localizedDescription
            syncProgress = nil
            print("❌ CloudSync: Upload failed: \(error)")
        }
    }

    // MARK: - Sync from Cloud

    /// Download all health data from CloudKit and merge into HealthStore.
    /// Used on sign-in to restore data from iCloud.
    func syncFromCloud(store: HealthStore) async {
        guard !isSyncing else { return }
        guard isCloudKitAvailable else {
            syncError = "iCloud is not available. Please sign in to iCloud in Settings."
            return
        }

        isSyncing = true
        syncError = nil
        syncProgress = "Downloading from iCloud..."

        do {
            try await ensureZoneExists()

            let zoneID = healthZone.zoneID
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            // Query all health data records
            let healthQuery = CKQuery(recordType: RecordType.healthData, predicate: NSPredicate(value: true))
            let (healthResults, _) = try await database.records(matching: healthQuery, inZoneWith: zoneID)

            var restoredCategories = 0

            for (_, result) in healthResults {
                guard case .success(let record) = result,
                      let category = record["category"] as? String,
                      let data = record["data"] as? Data else { continue }

                restoreCategory(category, data: data, to: store, decoder: decoder)
                restoredCategories += 1
                syncProgress = "Restored \(restoredCategories) categories..."
            }

            // Query user profile
            let profileID = CKRecord.ID(recordName: "userProfile", zoneID: zoneID)
            if let profileRecord = try? await database.record(for: profileID),
               let data = profileRecord["data"] as? Data,
               let profile = try? decoder.decode(UserProfile.self, from: data) {
                store.userProfile = profile
            }

            let now = Date()
            lastSyncDate = now
            isSyncing = false
            syncProgress = nil

            saveLastSyncDate(now)

            // Save restored data locally
            store.save()

        } catch {
            isSyncing = false
            syncError = error.localizedDescription
            syncProgress = nil
            print("❌ CloudSync: Download failed: \(error)")
        }
    }

    // MARK: - Delete All Cloud Data (GDPR)

    /// Permanently delete all user data from CloudKit. Called during account deletion.
    func deleteAllCloudData() async {
        guard isCloudKitAvailable else { return }
        do {
            try await database.deleteRecordZone(withID: healthZone.zoneID)
        } catch {
            print("❌ CloudSync: Failed to delete cloud data: \(error)")
        }
    }

    // MARK: - iCloud Availability

    /// Check if iCloud is available for the current user.
    func checkiCloudStatus() async -> Bool {
        do {
            let status = try await container.accountStatus()
            return status == .available
        } catch {
            return false
        }
    }

    // MARK: - Private Helpers

    /// Restore a single data category from CloudKit data into HealthStore.
    private func restoreCategory(_ category: String, data: Data, to store: HealthStore, decoder: JSONDecoder) {
        switch category {
        case "glucoseReadings":
            if let v = try? decoder.decode([GlucoseReading].self, from: data) { store.glucoseReadings = v }
        case "bpReadings":
            if let v = try? decoder.decode([BPReading].self, from: data) { store.bpReadings = v }
        case "heartRateReadings":
            if let v = try? decoder.decode([HeartRateReading].self, from: data) { store.heartRateReadings = v }
        case "hrvReadings":
            if let v = try? decoder.decode([HRVReading].self, from: data) { store.hrvReadings = v }
        case "sleepEntries":
            if let v = try? decoder.decode([SleepEntry].self, from: data) { store.sleepEntries = v }
        case "stressReadings":
            if let v = try? decoder.decode([StressReading].self, from: data) { store.stressReadings = v }
        case "bodyTempReadings":
            if let v = try? decoder.decode([BodyTempReading].self, from: data) { store.bodyTempReadings = v }
        case "stepEntries":
            if let v = try? decoder.decode([StepEntry].self, from: data) { store.stepEntries = v }
        case "waterEntries":
            if let v = try? decoder.decode([WaterEntry].self, from: data) { store.waterEntries = v }
        case "nutritionLogs":
            if let v = try? decoder.decode([NutritionLog].self, from: data) { store.nutritionLogs = v }
        case "symptomLogs":
            if let v = try? decoder.decode([SymptomLog].self, from: data) { store.symptomLogs = v }
        case "medications":
            if let v = try? decoder.decode([Medication].self, from: data) { store.medications = v }
        case "cycles":
            if let v = try? decoder.decode([CycleEntry].self, from: data) { store.cycles = v }
        case "healthAlerts":
            if let v = try? decoder.decode([HealthAlert].self, from: data) { store.healthAlerts = v }
        case "healthGoals":
            if let v = try? decoder.decode([HealthGoal].self, from: data) { store.healthGoals = v }
        case "healthChallenges":
            if let v = try? decoder.decode([HealthChallenge].self, from: data) { store.healthChallenges = v }
        case "achievements":
            if let v = try? decoder.decode([Achievement].self, from: data) { store.achievements = v }
        case "userStreaks":
            if let v = try? decoder.decode([UserStreak].self, from: data) { store.userStreaks = v }
        case "communityGroups":
            if let v = try? decoder.decode([CommunityGroup].self, from: data) { store.communityGroups = v }
        case "appointments":
            if let v = try? decoder.decode([Appointment].self, from: data) { store.appointments = v }
        case "prescriptions":
            if let v = try? decoder.decode([Prescription].self, from: data) { store.prescriptions = v }
        case "orders":
            if let v = try? decoder.decode([Order].self, from: data) { store.orders = v }
        case "medicalRecords":
            if let v = try? decoder.decode([MedicalRecord].self, from: data) { store.medicalRecords = v }
        default:
            print("⚠️ CloudSync: Unknown category '\(category)'")
        }
    }

    /// Persist last sync date to UserDefaults.
    private func saveLastSyncDate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: "cloudSync.lastSyncDate")
    }

    /// Load last sync date from UserDefaults.
    private func loadLastSyncDate() {
        lastSyncDate = UserDefaults.standard.object(forKey: "cloudSync.lastSyncDate") as? Date
    }
}
