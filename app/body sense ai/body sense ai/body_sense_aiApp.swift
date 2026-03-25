//
//  body_sense_aiApp.swift
//  body sense ai
//
//  BodySense AI — App entry point with notification support.
//  Bundle ID : com.base693c0fe8f0479560056f69f4.app
//  Team      : 9VS5N5PW5N
//

import SwiftUI
@preconcurrency import UserNotifications
import HealthKit

@main
struct body_sense_aiApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue
    @AppStorage("biometricLockEnabled") private var biometricLockEnabled = false
    @State private var isUnlocked = false
    @State private var showJailbreakWarning = false

    private var resolvedScheme: ColorScheme? {
        AppearanceMode(rawValue: appearanceMode)?.colorScheme
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if biometricLockEnabled && !isUnlocked {
                    BiometricLockScreen(isUnlocked: $isUnlocked)
                } else {
                    ContentView()
                        .task {
                            await AuthService.shared.checkCredentialState()
                        }
                        .task {
                            try? await Task.sleep(for: .seconds(2.0))
                            let store = HealthStore.shared
                            guard store.userProfile.healthKitEnabled else { return }
                            await HealthKitManager.shared.requestAuthorization()
                            await HealthKitManager.shared.syncAll(to: store)
                        }
                }
            }
            .preferredColorScheme(resolvedScheme)
            .onAppear {
                // Seed Keychain defaults on first launch
                KeychainManager.shared.seedDefaultsIfNeeded()

                // Exclude health data from iCloud backup
                BackupExclusion.excludeHealthDataFromBackup()

                // Enforce data retention policy (GDPR)
                DataRetentionPolicy.enforceRetention(store: HealthStore.shared)

                // Jailbreak detection
                if JailbreakDetector.isJailbroken {
                    showJailbreakWarning = true
                }

                // Schedule CEO daily summary (if CEO)
                if HealthStore.shared.userProfile.isCEO {
                    CEODailySummary.scheduleDailyNotification()
                }

                // Auto-unlock if biometric not enabled
                if !biometricLockEnabled {
                    isUnlocked = true
                }
            }
            .alert("Security Warning", isPresented: $showJailbreakWarning) {
                Button("I Understand") { showJailbreakWarning = false }
            } message: {
                Text(JailbreakDetector.warningMessage)
            }
        }
    }
}

// MARK: - Biometric Lock Screen

struct BiometricLockScreen: View {
    @Binding var isUnlocked: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: BiometricAuth.shared.iconName)
                .font(.system(size: 64))
                .foregroundColor(.brandPurple)

            Text("BodySense AI")
                .font(.title).fontWeight(.bold)

            Text("Your health data is protected")
                .font(.subheadline).foregroundColor(.secondary)

            Button {
                Task {
                    let success = await BiometricAuth.shared.authenticate()
                    if success { isUnlocked = true }
                }
            } label: {
                Label("Unlock with \(BiometricAuth.shared.typeName)", systemImage: BiometricAuth.shared.iconName)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.brandPurple)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .task {
            let success = await BiometricAuth.shared.authenticate()
            if success { isUnlocked = true }
        }
    }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        // ── Set notification delegate (permission is requested during onboarding) ──
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        // ── Daily morning health check-in — 8 AM ──
        scheduleDailyReminder(
            id: "morning",
            title: "BodySense AI 🌅",
            body: "Good morning! Check your overnight readings and log your morning health data.",
            hour: 8, minute: 0
        )

        // ── Evening wind-down reminder — 9 PM ──
        scheduleDailyReminder(
            id: "evening",
            title: "BodySense AI 🌙",
            body: "Evening check-in — how are you feeling today? Log any symptoms or notes.",
            hour: 21, minute: 0
        )

        // ── Schedule medication reminders for all active meds ──
        Task { @MainActor in
            NotificationService.shared.scheduleMedicationReminders(for: HealthStore.shared.medications)
        }

        return true
    }

    // ── Show notifications while app is in foreground ──
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge, .sound])
    }

    // ── Handle tap on a notification ──
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }

    // ── Remote push token ──
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        #if DEBUG
        print("APNs device token: \(token)")
        #endif
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        #if DEBUG
        print("Failed to register for remote notifications: \(error)")
        #endif
    }

    // MARK: - Daily Reminder Helper
    private func scheduleDailyReminder(id: String, title: String, body: String, hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let content      = UNMutableNotificationContent()
        content.title    = title
        content.body     = body
        content.sound    = .default
        content.badge    = 1

        var comps        = DateComponents()
        comps.hour       = hour
        comps.minute     = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }
}

// MARK: - Notification Service (appointment reminders)
/// Call `NotificationService.shared.scheduleAppointmentReminder(...)` whenever a booking is confirmed.
@MainActor
final class NotificationService {

    static let shared = NotificationService()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    /// Schedule a reminder 15 minutes before a doctor appointment.
    /// - Parameters:
    ///   - appointmentId: Unique ID used to cancel/replace the notification.
    ///   - doctorName: Doctor's display name shown in the notification body.
    ///   - date: Exact appointment start time.
    func scheduleAppointmentReminder(appointmentId: UUID, doctorName: String, date: Date) {
        // Cancel any existing reminder for this appointment
        center.removePendingNotificationRequests(withIdentifiers: [appointmentId.uuidString])

        // Only schedule if the appointment is in the future
        guard date > Date() else { return }

        let reminderDate = date.addingTimeInterval(-15 * 60) // 15 min before
        guard reminderDate > Date() else { return }

        let content       = UNMutableNotificationContent()
        content.title     = "Upcoming Appointment 🩺"
        content.body      = "Your consultation with Dr. \(doctorName) starts in 15 minutes."
        content.sound     = .default
        content.badge     = 1
        content.userInfo  = ["appointmentId": appointmentId.uuidString, "type": "appointmentReminder"]

        let comps   = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: appointmentId.uuidString, content: content, trigger: trigger)

        center.add(request)
    }

    /// Schedule an "at-time" notification that fires exactly when the appointment starts.
    func scheduleAtTimeReminder(appointmentId: UUID, doctorName: String, date: Date) {
        let atTimeId = appointmentId.uuidString + "_start"
        center.removePendingNotificationRequests(withIdentifiers: [atTimeId])

        guard date > Date() else { return }

        let content       = UNMutableNotificationContent()
        content.title     = "Appointment Now 🩺"
        content.body      = "Your consultation with Dr. \(doctorName) is starting now. Join the call!"
        content.sound     = .defaultCritical
        content.badge     = 1
        content.userInfo  = ["appointmentId": appointmentId.uuidString, "type": "appointmentStart"]

        let comps   = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: atTimeId, content: content, trigger: trigger)

        center.add(request)
    }

    /// Cancel all reminders for a specific appointment (e.g. on cancellation).
    func cancelAppointmentReminders(appointmentId: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [
            appointmentId.uuidString,
            appointmentId.uuidString + "_start"
        ])
    }

    // MARK: - Medication Reminders

    /// Schedule daily repeating reminders for each active medication at each scheduled time.
    func scheduleMedicationReminders(for medications: [Medication]) {
        // First cancel all existing medication reminders
        let notificationCenter = self.center
        notificationCenter.getPendingNotificationRequests { requests in
            let medIds = requests.filter { $0.identifier.hasPrefix("med_") }.map { $0.identifier }
            notificationCenter.removePendingNotificationRequests(withIdentifiers: medIds)

            // Schedule new ones for active meds
            for med in medications where med.isActive {
                for time in med.timeOfDay {
                    let id = "med_\(med.id.uuidString)_\(time.rawValue)"

                    let content       = UNMutableNotificationContent()
                    content.title     = "Time for \(med.name)"
                    content.body      = "\(med.dosage) \(med.unit) — \(time.rawValue) dose"
                    content.sound     = .default
                    content.badge     = 1
                    content.userInfo  = ["medicationId": med.id.uuidString, "type": "medicationReminder"]

                    var comps         = DateComponents()
                    comps.hour        = time.hour
                    comps.minute      = 0

                    let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                    let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                    notificationCenter.add(request)
                }
            }
        }
    }

    /// Cancel all reminders for a specific medication.
    func cancelMedicationReminders(for medication: Medication) {
        let ids = medication.timeOfDay.map { "med_\(medication.id.uuidString)_\($0.rawValue)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
