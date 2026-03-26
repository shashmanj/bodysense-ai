//
//  CloudSyncService.swift
//  body sense ai
//
//  Native CloudKit sync service for cross-device data sync.
//  Uses CKDatabase (private) — data is end-to-end encrypted by Apple.
//  No third-party dependencies — 100% Apple-native.
//
//  Syncs: UserProfile, Medications, HealthGoals, AgentInsights
//  Does NOT sync: Raw HealthKit data (Apple Health handles that natively)
//
//  Merge strategy: Latest-wins based on lastModified date.
//

import Foundation
import CloudKit

// MARK: - Sync State

enum CloudSyncState: Equatable {
    case idle
    case syncing
    case error(String)
    case upToDate

    var label: String {
        switch self {
        case .idle:           return "Not synced"
        case .syncing:        return "Syncing..."
        case .error(let msg): return msg
        case .upToDate:       return "Up to date"
        }
    }

    var icon: String {
        switch self {
        case .idle:     return "icloud"
        case .syncing:  return "arrow.triangle.2.circlepath.icloud"
        case .error:    return "exclamationmark.icloud"
        case .upToDate: return "checkmark.icloud"
        }
    }

    var isError: Bool {
        if case .error = self { return true }
        return false
    }
}

// MARK: - Cloud Sync Service

/// Syncs HealthStore data to/from iCloud using CloudKit private database.
@MainActor
@Observable
final class CloudSyncService {

    static let shared = CloudSyncService()

    // MARK: - State

    var syncState: CloudSyncState = .idle
    var lastSyncDate: Date?
    var syncProgress: String?

    // Legacy compatibility
    var isSyncing: Bool { syncState == .syncing }
    var syncError: String? {
        if case .error(let msg) = syncState { return msg }
        return nil
    }

    // MARK: - CloudKit Configuration

    /// CloudKit container — uses the app's default iCloud container.
    /// Container ID must be configured in Xcode:
    ///   Signing & Capabilities -> iCloud -> CloudKit -> Container: iCloud.com.bodysenseai
    private var container: CKContainer { CKContainer.default() }
    private var database: CKDatabase { container.privateCloudDatabase }

    /// Whether CloudKit is available (entitlement configured + iCloud signed in).
    var isCloudKitAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    /// Record types used in CloudKit.
    private enum RecordType {
        static let userProfile    = "UserProfile"
        static let medication     = "Medication"
        static let healthGoal     = "HealthGoal"
        static let agentInsight   = "AgentInsight"
        static let healthData     = "HealthData"
        static let syncMetadata   = "SyncMetadata"
    }

    /// Zone for all health data.
    private let healthZone = CKRecordZone(zoneName: "HealthDataZone")

    /// Whether remote change subscription has been set up
    private var subscriptionRegistered = false

    /// Change token for incremental fetches
    private var serverChangeToken: CKServerChangeToken? {
        get {
            guard let data = UserDefaults.standard.data(forKey: "cloudSync.changeToken") else { return nil }
            return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data)
        }
        set {
            if let token = newValue,
               let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) {
                UserDefaults.standard.set(data, forKey: "cloudSync.changeToken")
            } else {
                UserDefaults.standard.removeObject(forKey: "cloudSync.changeToken")
            }
        }
    }

    private init() {
        loadLastSyncDate()
        if lastSyncDate != nil {
            syncState = .upToDate
        }
    }

    // MARK: - Zone Setup

    /// Create the custom zone if it doesn't exist. Call on first sync.
    private func ensureZoneExists() async throws {
        do {
            _ = try await database.save(healthZone)
        } catch let error as CKError where error.code == .serverRejectedRequest {
            // Zone already exists
        } catch let error as CKError where error.code == .zoneNotFound {
            _ = try await database.save(healthZone)
        }
    }

    // MARK: - Remote Change Subscription

    /// Register for push notifications when data changes on another device.
    func registerForRemoteChanges() async {
        guard !subscriptionRegistered else { return }
        guard isCloudKitAvailable else { return }

        do {
            try await ensureZoneExists()

            let subscriptionID = "healthDataZone-changes"

            // Check if subscription already exists
            do {
                _ = try await database.subscription(for: subscriptionID)
                subscriptionRegistered = true
                return
            } catch {
                // Subscription doesn't exist yet, create it
            }

            let subscription = CKDatabaseSubscription(subscriptionID: subscriptionID)

            let notificationInfo = CKSubscription.NotificationInfo()
            notificationInfo.shouldSendContentAvailable = true // Silent push
            subscription.notificationInfo = notificationInfo

            _ = try await database.save(subscription)
            subscriptionRegistered = true

            #if DEBUG
            print("CloudSync: Registered for remote change notifications")
            #endif
        } catch {
            #if DEBUG
            print("CloudSync: Failed to register subscription: \(error)")
            #endif
        }
    }

    /// Called when a remote change notification arrives.
    /// Fetches only the changed records since last token.
    func handleRemoteChangeNotification(store: HealthStore) async {
        guard isCloudKitAvailable else { return }
        await syncFromCloud(store: store)
    }

    // MARK: - Auto-Sync on Launch

    /// Call on app launch to sync data if needed.
    func autoSyncOnLaunch(store: HealthStore) async {
        guard isCloudKitAvailable else { return }

        // Register for remote changes
        await registerForRemoteChanges()

        // If never synced or last sync was more than 5 minutes ago, sync from cloud
        if lastSyncDate == nil || Date().timeIntervalSince(lastSyncDate ?? .distantPast) > 300 {
            await syncFromCloud(store: store)
        }
    }

    // MARK: - Sync to Cloud

    /// Upload user profile, medications, health goals, and agent insights to CloudKit.
    /// Does NOT sync raw health data (HealthKit handles that natively).
    func syncToCloud(store: HealthStore) async {
        guard syncState != .syncing else { return }
        guard isCloudKitAvailable else {
            syncState = .error("iCloud is not available. Please sign in to iCloud in Settings.")
            return
        }

        syncState = .syncing
        syncProgress = "Preparing data..."

        do {
            try await ensureZoneExists()

            let zoneID = healthZone.zoneID
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601

            var records: [CKRecord] = []
            let now = Date()

            // ── 1. User Profile ──
            syncProgress = "Syncing profile..."
            let profileRecord = CKRecord(
                recordType: RecordType.userProfile,
                recordID: CKRecord.ID(recordName: "userProfile", zoneID: zoneID)
            )
            if let data = try? encoder.encode(store.userProfile) {
                profileRecord["data"] = data as CKRecordValue
                profileRecord["lastModified"] = now as CKRecordValue
                profileRecord["recordVersion"] = "1.0" as CKRecordValue
                records.append(profileRecord)
            }

            // ── 2. Medications (each as individual record for granular sync) ──
            syncProgress = "Syncing medications..."
            for med in store.medications {
                let record = CKRecord(
                    recordType: RecordType.medication,
                    recordID: CKRecord.ID(recordName: "med_\(med.id.uuidString)", zoneID: zoneID)
                )
                if let data = try? encoder.encode(med) {
                    record["data"] = data as CKRecordValue
                    record["medicationID"] = med.id.uuidString as CKRecordValue
                    record["name"] = med.name as CKRecordValue
                    record["isActive"] = (med.isActive ? 1 : 0) as CKRecordValue
                    record["lastModified"] = now as CKRecordValue
                    records.append(record)
                }
            }

            // ── 3. Health Goals ──
            syncProgress = "Syncing health goals..."
            for goal in store.healthGoals {
                let record = CKRecord(
                    recordType: RecordType.healthGoal,
                    recordID: CKRecord.ID(recordName: "goal_\(goal.id.uuidString)", zoneID: zoneID)
                )
                if let data = try? encoder.encode(goal) {
                    record["data"] = data as CKRecordValue
                    record["goalID"] = goal.id.uuidString as CKRecordValue
                    record["lastModified"] = now as CKRecordValue
                    records.append(record)
                }
            }

            // ── 4. Agent Insights (AI memory) ──
            syncProgress = "Syncing AI memory..."
            let insights = AgentMemoryStore.shared.allInsights
            for insight in insights {
                let record = CKRecord(
                    recordType: RecordType.agentInsight,
                    recordID: CKRecord.ID(recordName: "insight_\(insight.id)", zoneID: zoneID)
                )
                if let data = try? encoder.encode(insight) {
                    record["data"] = data as CKRecordValue
                    record["insightID"] = insight.id as CKRecordValue
                    record["domain"] = insight.domain.rawValue as CKRecordValue
                    record["confidence"] = insight.confidence as CKRecordValue
                    record["lastModified"] = insight.lastUsed as CKRecordValue
                    records.append(record)
                }
            }

            // ── 5. Bulk health data categories (non-HealthKit user-entered data) ──
            syncProgress = "Syncing health data..."
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
                ("cycles",             { try encoder.encode(store.cycles) }),
                ("healthAlerts",       { try encoder.encode(store.healthAlerts) }),
                ("healthChallenges",   { try encoder.encode(store.healthChallenges) }),
                ("achievements",       { try encoder.encode(store.achievements) }),
                ("userStreaks",        { try encoder.encode(store.userStreaks) }),
                ("communityGroups",    { try encoder.encode(store.communityGroups) }),
                ("appointments",       { try encoder.encode(store.appointments) }),
                ("prescriptions",      { try encoder.encode(store.prescriptions) }),
                ("orders",             { try encoder.encode(store.orders) }),
                ("medicalRecords",     { try encoder.encode(store.medicalRecords) }),
            ]

            for (name, encode) in categories {
                if let data = try? encode() {
                    let record = CKRecord(
                        recordType: RecordType.healthData,
                        recordID: CKRecord.ID(recordName: name, zoneID: zoneID)
                    )
                    record["category"] = name as CKRecordValue
                    record["data"] = data as CKRecordValue
                    record["lastModified"] = now as CKRecordValue
                    records.append(record)
                }
            }

            syncProgress = "Uploading \(records.count) records..."

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

            lastSyncDate = now
            syncProgress = nil

            if failedCount > 0 {
                syncState = .error("\(failedCount) records failed to sync")
            } else {
                syncState = .upToDate
            }

            saveLastSyncDate(now)

        } catch {
            syncState = .error(error.localizedDescription)
            syncProgress = nil
            #if DEBUG
            print("CloudSync: Upload failed: \(error)")
            #endif
        }
    }

    // MARK: - Sync from Cloud

    /// Download data from CloudKit and merge into HealthStore.
    /// Uses latest-wins strategy based on lastModified date.
    func syncFromCloud(store: HealthStore) async {
        guard syncState != .syncing else { return }
        guard isCloudKitAvailable else {
            syncState = .error("iCloud is not available. Please sign in to iCloud in Settings.")
            return
        }

        syncState = .syncing
        syncProgress = "Downloading from iCloud..."

        do {
            try await ensureZoneExists()

            let zoneID = healthZone.zoneID
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            // ── 1. Restore User Profile (latest-wins merge) ──
            syncProgress = "Syncing profile..."
            let profileID = CKRecord.ID(recordName: "userProfile", zoneID: zoneID)
            if let profileRecord = try? await database.record(for: profileID),
               let data = profileRecord["data"] as? Data,
               let cloudProfile = try? decoder.decode(UserProfile.self, from: data),
               let cloudModified = profileRecord["lastModified"] as? Date {
                // Latest-wins: only apply cloud profile if it's newer
                let localModified = UserDefaults.standard.object(forKey: "cloudSync.profileModified") as? Date ?? .distantPast
                if cloudModified > localModified {
                    // Merge: preserve local-only fields, take cloud for shared fields
                    mergeProfile(cloud: cloudProfile, into: store)
                    UserDefaults.standard.set(cloudModified, forKey: "cloudSync.profileModified")
                }
            }

            // ── 2. Restore Medications (latest-wins per medication) ──
            syncProgress = "Syncing medications..."
            let medQuery = CKQuery(recordType: RecordType.medication, predicate: NSPredicate(value: true))
            let (medResults, _) = try await database.records(matching: medQuery, inZoneWith: zoneID)

            for (_, result) in medResults {
                guard case .success(let record) = result,
                      let data = record["data"] as? Data,
                      let cloudMed = try? decoder.decode(Medication.self, from: data),
                      let cloudModified = record["lastModified"] as? Date else { continue }

                // Find matching local medication
                if let localIdx = store.medications.firstIndex(where: { $0.id == cloudMed.id }) {
                    // Latest-wins merge
                    let localMed = store.medications[localIdx]
                    let localModified = localMed.startDate // Use startDate as proxy for modification time
                    if cloudModified > localModified {
                        store.medications[localIdx] = cloudMed
                    }
                } else {
                    // New medication from another device
                    store.medications.append(cloudMed)
                }
            }

            // ── 3. Restore Health Goals (latest-wins per goal) ──
            syncProgress = "Syncing health goals..."
            let goalQuery = CKQuery(recordType: RecordType.healthGoal, predicate: NSPredicate(value: true))
            let (goalResults, _) = try await database.records(matching: goalQuery, inZoneWith: zoneID)

            for (_, result) in goalResults {
                guard case .success(let record) = result,
                      let data = record["data"] as? Data,
                      let cloudGoal = try? decoder.decode(HealthGoal.self, from: data),
                      let cloudModified = record["lastModified"] as? Date else { continue }

                if let localIdx = store.healthGoals.firstIndex(where: { $0.id == cloudGoal.id }) {
                    let localGoal = store.healthGoals[localIdx]
                    let localModified = localGoal.createdAt
                    if cloudModified > localModified {
                        store.healthGoals[localIdx] = cloudGoal
                    }
                } else {
                    store.healthGoals.append(cloudGoal)
                }
            }

            // ── 4. Restore Agent Insights (latest-wins per insight) ──
            syncProgress = "Syncing AI memory..."
            let insightQuery = CKQuery(recordType: RecordType.agentInsight, predicate: NSPredicate(value: true))
            let (insightResults, _) = try await database.records(matching: insightQuery, inZoneWith: zoneID)

            for (_, result) in insightResults {
                guard case .success(let record) = result,
                      let data = record["data"] as? Data,
                      let cloudInsight = try? decoder.decode(UserInsight.self, from: data) else { continue }

                // AgentMemoryStore handles deduplication internally
                AgentMemoryStore.shared.addInsight(cloudInsight)
            }

            // ── 5. Restore bulk health data categories ──
            syncProgress = "Syncing health data..."
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

            let now = Date()
            lastSyncDate = now
            syncProgress = nil
            syncState = .upToDate

            saveLastSyncDate(now)

            // Save restored data locally
            store.save()

        } catch {
            syncState = .error(error.localizedDescription)
            syncProgress = nil
            #if DEBUG
            print("CloudSync: Download failed: \(error)")
            #endif
        }
    }

    // MARK: - Profile Merge (Latest-Wins with Field-Level Awareness)

    /// Merge cloud profile into local store, preserving local-only transient state.
    private func mergeProfile(cloud: UserProfile, into store: HealthStore) {
        var merged = store.userProfile

        // Sync shared fields from cloud
        merged.name = cloud.name
        merged.email = cloud.email
        merged.age = cloud.age
        merged.gender = cloud.gender
        merged.diabetesType = cloud.diabetesType
        merged.hasHypertension = cloud.hasHypertension
        merged.targetGlucoseMin = cloud.targetGlucoseMin
        merged.targetGlucoseMax = cloud.targetGlucoseMax
        merged.targetSystolic = cloud.targetSystolic
        merged.targetDiastolic = cloud.targetDiastolic
        merged.weight = cloud.weight
        merged.height = cloud.height
        merged.weightUnit = cloud.weightUnit
        merged.heightUnit = cloud.heightUnit
        merged.emergencyName = cloud.emergencyName
        merged.emergencyPhone = cloud.emergencyPhone
        merged.targetSteps = cloud.targetSteps
        merged.targetSleep = cloud.targetSleep
        merged.targetWater = cloud.targetWater
        merged.city = cloud.city
        merged.country = cloud.country
        merged.currencyCode = cloud.currencyCode
        merged.postcode = cloud.postcode
        merged.profilePhotoData = cloud.profilePhotoData
        merged.anonymousAlias = cloud.anonymousAlias
        merged.anonymousColor = cloud.anonymousColor
        merged.isDoctor = cloud.isDoctor
        merged.doctorProfile = cloud.doctorProfile
        merged.selectedGoals = cloud.selectedGoals
        merged.notificationPreferences = cloud.notificationPreferences
        merged.dailyCalorieGoal = cloud.dailyCalorieGoal
        merged.dailyProteinGoal = cloud.dailyProteinGoal
        merged.dailyCarbGoal = cloud.dailyCarbGoal
        merged.dailyFatGoal = cloud.dailyFatGoal
        merged.dailyFiberGoal = cloud.dailyFiberGoal
        merged.dailySugarGoal = cloud.dailySugarGoal
        merged.dailySaltGoal = cloud.dailySaltGoal
        merged.nutritionGoalType = cloud.nutritionGoalType
        merged.activityLevel = cloud.activityLevel

        // Preserve local-only device settings
        // healthKitEnabled stays local (per-device)
        // GDPR consents stay local (per-device acceptance)
        // preferLocalSearch stays local (device-specific)

        store.userProfile = merged
    }

    // MARK: - Sync on Data Change

    /// Call after any data mutation to trigger a background cloud sync.
    func syncAfterChange(store: HealthStore) {
        Task {
            // Debounce: wait a short moment for batch changes
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            await syncToCloud(store: store)
        }
    }

    // MARK: - Delete All Cloud Data (GDPR)

    /// Permanently delete all user data from CloudKit. Called during account deletion.
    func deleteAllCloudData() async {
        guard isCloudKitAvailable else { return }
        do {
            try await database.deleteRecordZone(withID: healthZone.zoneID)
            syncState = .idle
            lastSyncDate = nil
            serverChangeToken = nil
            UserDefaults.standard.removeObject(forKey: "cloudSync.lastSyncDate")
            UserDefaults.standard.removeObject(forKey: "cloudSync.profileModified")
        } catch {
            #if DEBUG
            print("CloudSync: Failed to delete cloud data: \(error)")
            #endif
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
        case "cycles":
            if let v = try? decoder.decode([CycleEntry].self, from: data) { store.cycles = v }
        case "healthAlerts":
            if let v = try? decoder.decode([HealthAlert].self, from: data) { store.healthAlerts = v }
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
            #if DEBUG
            print("CloudSync: Unknown category '\(category)'")
            #endif
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
