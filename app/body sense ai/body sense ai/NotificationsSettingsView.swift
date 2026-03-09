//
//  NotificationsSettingsView.swift
//  body sense ai
//
//  Notification preferences screen — toggle health alerts, reminders, AI insights.
//

import SwiftUI

struct NotificationsSettingsView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.badge.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(colors: [.brandPurple, .brandTeal],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Notification Settings").font(.headline)
                            Text("Personalise your health alerts and reminders").font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("🏥 Health Alerts") {
                    notifToggle("Medication Reminders", icon: "pill.fill", color: .brandPurple,
                                get: { store.userProfile.notificationPreferences.medicationReminders },
                                set: { store.userProfile.notificationPreferences.medicationReminders = $0 })
                    notifToggle("Glucose Alerts", icon: "drop.fill", color: .brandCoral,
                                get: { store.userProfile.notificationPreferences.glucoseAlerts },
                                set: { store.userProfile.notificationPreferences.glucoseAlerts = $0 })
                    notifToggle("Blood Pressure Alerts", icon: "heart.fill", color: .brandTeal,
                                get: { store.userProfile.notificationPreferences.bpAlerts },
                                set: { store.userProfile.notificationPreferences.bpAlerts = $0 })
                }

                Section("💧 Daily Reminders") {
                    notifToggle("Water Reminders", icon: "drop.circle.fill", color: Color(hex: "#4fc3f7"),
                                get: { store.userProfile.notificationPreferences.waterReminders },
                                set: { store.userProfile.notificationPreferences.waterReminders = $0 })
                    notifToggle("Sleep Reminders", icon: "bed.double.fill", color: .brandPurple,
                                get: { store.userProfile.notificationPreferences.sleepReminders },
                                set: { store.userProfile.notificationPreferences.sleepReminders = $0 })
                    notifToggle("Exercise Reminders", icon: "figure.run", color: .brandAmber,
                                get: { store.userProfile.notificationPreferences.exerciseReminders },
                                set: { store.userProfile.notificationPreferences.exerciseReminders = $0 })
                }

                Section("🤖 AI & Social") {
                    notifToggle("AI Health Insights", icon: "brain.head.profile", color: .brandGreen,
                                get: { store.userProfile.notificationPreferences.aiInsights },
                                set: { store.userProfile.notificationPreferences.aiInsights = $0 })
                    notifToggle("Community Updates", icon: "person.3.fill", color: .brandTeal,
                                get: { store.userProfile.notificationPreferences.communityUpdates },
                                set: { store.userProfile.notificationPreferences.communityUpdates = $0 })
                }

                Section("⏰ Timing") {
                    HStack {
                        Image(systemName: "sunrise.fill").foregroundColor(.brandAmber)
                        Text("Morning Reminder")
                        Spacer()
                        Text("\(store.userProfile.notificationPreferences.morningReminderHour):00")
                            .foregroundColor(.brandPurple).fontWeight(.semibold)
                    }
                    Stepper("", value: Binding(
                        get: { store.userProfile.notificationPreferences.morningReminderHour },
                        set: { store.userProfile.notificationPreferences.morningReminderHour = $0; store.save() }
                    ), in: 5...11).labelsHidden()

                    HStack {
                        Image(systemName: "moon.fill").foregroundColor(.brandPurple)
                        Text("Evening Reminder")
                        Spacer()
                        Text("\(store.userProfile.notificationPreferences.eveningReminderHour):00")
                            .foregroundColor(.brandPurple).fontWeight(.semibold)
                    }
                    Stepper("", value: Binding(
                        get: { store.userProfile.notificationPreferences.eveningReminderHour },
                        set: { store.userProfile.notificationPreferences.eveningReminderHour = $0; store.save() }
                    ), in: 17...23).labelsHidden()

                    HStack {
                        Image(systemName: "drop.circle.fill").foregroundColor(Color(hex: "#4fc3f7"))
                        Text("Water Reminder Every")
                        Spacer()
                        Text("\(store.userProfile.notificationPreferences.waterReminderInterval) min")
                            .foregroundColor(.brandPurple).fontWeight(.semibold)
                    }
                    Picker("Interval", selection: Binding(
                        get: { store.userProfile.notificationPreferences.waterReminderInterval },
                        set: { store.userProfile.notificationPreferences.waterReminderInterval = $0; store.save() }
                    )) {
                        Text("30 min").tag(30)
                        Text("60 min").tag(60)
                        Text("90 min").tag(90)
                        Text("2 hours").tag(120)
                        Text("3 hours").tag(180)
                    }
                    .pickerStyle(.menu)
                }

                Section {
                    HStack {
                        Image(systemName: "info.circle.fill").foregroundColor(.secondary)
                        Text("Notifications require permission in iOS Settings > BodySense AI.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }

    func notifToggle(_ label: String, icon: String, color: Color,
                     get: @escaping () -> Bool,
                     set: @escaping (Bool) -> Void) -> some View {
        Toggle(isOn: Binding(get: get, set: { val in set(val); store.save() })) {
            Label(label, systemImage: icon).foregroundColor(color)
        }
        .tint(color)
    }
}
