//
//  HapticManager.swift
//  body sense ai
//
//  Centralised haptic feedback for tactile UI responses.
//  Call HapticManager.shared.impact(.medium) on button taps,
//  .success() on completions, .warning() on alerts, .error() on failures.
//

import UIKit

final class HapticManager: @unchecked Sendable {
    static let shared = HapticManager()
    private init() {}

    // MARK: - Impact Feedback (taps, toggles, selections)

    private let lightGen   = UIImpactFeedbackGenerator(style: .light)
    private let mediumGen  = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGen   = UIImpactFeedbackGenerator(style: .heavy)
    private let softGen    = UIImpactFeedbackGenerator(style: .soft)
    private let rigidGen   = UIImpactFeedbackGenerator(style: .rigid)

    enum ImpactStyle {
        case light, medium, heavy, soft, rigid
    }

    func impact(_ style: ImpactStyle = .medium) {
        switch style {
        case .light:  lightGen.impactOccurred()
        case .medium: mediumGen.impactOccurred()
        case .heavy:  heavyGen.impactOccurred()
        case .soft:   softGen.impactOccurred()
        case .rigid:  rigidGen.impactOccurred()
        }
    }

    // MARK: - Notification Feedback (results)

    private let notifGen = UINotificationFeedbackGenerator()

    /// Call on successful actions: payment complete, goal reached, achievement earned
    func success() {
        notifGen.notificationOccurred(.success)
    }

    /// Call on warnings: high glucose, high BP, approaching limit
    func warning() {
        notifGen.notificationOccurred(.warning)
    }

    /// Call on errors: payment failed, network error, validation failure
    func error() {
        notifGen.notificationOccurred(.error)
    }

    // MARK: - Selection Feedback (pickers, sliders, segments)

    private let selectionGen = UISelectionFeedbackGenerator()

    /// Call when user scrolls through picker items or changes selection
    func selection() {
        selectionGen.selectionChanged()
    }

    // MARK: - Convenience Methods

    /// Tap feedback for general button presses
    func tap() { impact(.light) }

    /// Confirm feedback for important actions (add to cart, save, submit)
    func confirm() { impact(.medium) }

    /// Heavy feedback for destructive/irreversible actions (delete, cancel order)
    func heavy() { impact(.heavy) }

    /// Streak/achievement celebration — triple haptic burst
    func celebrate() {
        impact(.rigid)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            impact(.rigid)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
            success()
        }
    }
}
