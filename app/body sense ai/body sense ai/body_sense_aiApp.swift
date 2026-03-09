//
//  body_sense_aiApp.swift
//  body sense ai
//
//  BodySense AI — App entry point with notification support.
//  Bundle ID : com.base693c0fe8f0479560056f69f4.app
//  Team      : 9VS5N5PW5N
//

import SwiftUI
import UserNotifications
#if canImport(StripeCore)
import StripeCore
#endif
import HealthKit

@main
struct body_sense_aiApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                .task {
                    // Auto-sync HealthKit data on launch if enabled
                    let store = HealthStore.shared
                    if store.userProfile.healthKitEnabled {
                        await HealthKitManager.shared.requestAuthorization()
                        await HealthKitManager.shared.syncAll(to: store)
                    }
                }
        }
    }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        // ── Stripe SDK init (requires StripeCore via SPM) ──
        #if canImport(StripeCore)
        StripeAPI.defaultPublishableKey = StripeManager.shared.publishableKey
        #endif

        // ── Request notification permissions ──
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }

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
        print("APNs device token: \(token)")
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error)")
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
final class NotificationService: @unchecked Sendable {

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
}
