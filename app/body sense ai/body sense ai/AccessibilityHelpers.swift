//
//  AccessibilityHelpers.swift
//  body sense ai
//
//  Accessibility helpers for VoiceOver and Dynamic Type support.
//

import SwiftUI

extension View {
    /// Convenience method for adding accessibility label and optional hint.
    func healthLabel(_ label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(Text(label))
            .accessibilityHint(hint.map { Text($0) } ?? Text(""))
    }
}
