//
//  FamilySharingView.swift
//  body sense ai
//
//  Family Health Hub — coming soon feature for sharing health with up to 5 family members.
//

import SwiftUI

struct FamilySharingView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    Spacer(minLength: 30)

                    // Hero icon
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.brandPurple.opacity(0.12), .brandTeal.opacity(0.08)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 120, height: 120)
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(LinearGradient(colors: [.brandPurple, .brandTeal],
                                                            startPoint: .topLeading, endPoint: .bottomTrailing))
                    }

                    VStack(spacing: 8) {
                        Text("Family Health Hub").font(.title2.bold())
                        Text("Coming Soon")
                            .font(.headline).foregroundColor(.white)
                            .padding(.horizontal, 20).padding(.vertical, 6)
                            .background(
                                LinearGradient(colors: [.brandPurple, .brandTeal],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(20)
                    }

                    Text("Share health goals, track family wellness together, and get group insights for up to 5 family members. Designed for families managing diabetes, hypertension, and other health conditions together.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 32)

                    // Features preview
                    VStack(spacing: 12) {
                        featureRow("person.badge.plus", "Invite up to 5 family members", .brandPurple)
                        featureRow("chart.line.uptrend.xyaxis", "View each other's health scores", .brandTeal)
                        featureRow("bell.badge.fill", "Get alerts when family needs support", .brandCoral)
                        featureRow("trophy.fill", "Shared challenges and achievements", .brandAmber)
                        featureRow("lock.shield.fill", "100% private — data stays secure", .brandGreen)
                    }
                    .padding(.horizontal)

                    // Invite button (disabled — coming soon)
                    Button { } label: {
                        Label("Invite Family Member", systemImage: "person.badge.plus")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.brandPurple.opacity(0.15))
                            .foregroundColor(.brandPurple)
                            .cornerRadius(16)
                    }
                    .disabled(true)
                    .padding(.horizontal)

                    Text("Be the first to know when Family Sharing launches. We'll notify you automatically.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Spacer(minLength: 40)
                }
            }
            .background(Color.brandBg)
            .navigationTitle("Family Sharing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }

    func featureRow(_ icon: String, _ text: String, _ color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body).foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(color).cornerRadius(8)
            Text(text).font(.subheadline)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color.white.opacity(0.6))
        .cornerRadius(12)
    }
}
