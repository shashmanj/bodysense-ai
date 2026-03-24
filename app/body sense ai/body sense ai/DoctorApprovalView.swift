//
//  DoctorApprovalView.swift
//  body sense ai
//
//  CEO-only view for reviewing and approving/rejecting doctor registrations.
//

import SwiftUI

// MARK: - Doctor Approval List

struct DoctorApprovalView: View {
    @Environment(HealthStore.self) var store

    var pending: [DoctorRegistrationRequest] {
        store.doctorRequests.filter { $0.status == "Pending" }
    }

    var reviewed: [DoctorRegistrationRequest] {
        store.doctorRequests.filter { $0.status != "Pending" }
    }

    var body: some View {
        Group {
        if !CEOAccessManager.isActivated {
            // Hard gate — CEO access required even if view is navigated to directly
            VStack(spacing: 16) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 64)).foregroundColor(.secondary)
                Text("CEO Access Required")
                    .font(.title3).fontWeight(.semibold)
                Text("Only the CEO can review and approve doctor applications.")
                    .font(.subheadline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
        List {
            if pending.isEmpty && reviewed.isEmpty {
                emptyState
            }

            if !pending.isEmpty {
                Section {
                    ForEach(pending) { request in
                        NavigationLink {
                            DoctorRequestDetailView(request: request)
                                .environment(store)
                        } label: {
                            DoctorRequestRow(request: request)
                        }
                    }
                } header: {
                    HStack {
                        Text("Pending Approval")
                        Spacer()
                        Text("\(pending.count)")
                            .font(.caption2).fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(Color.brandCoral)
                            .cornerRadius(10)
                    }
                }
            }

            if !reviewed.isEmpty {
                Section("Previously Reviewed") {
                    ForEach(reviewed) { request in
                        NavigationLink {
                            DoctorRequestDetailView(request: request)
                                .environment(store)
                        } label: {
                            DoctorRequestRow(request: request)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Doctor Approvals")
        } // end else (CEO gate)
        } // end Group
    }

    var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "stethoscope.circle")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.3))
            Text("No Registration Requests")
                .font(.headline).foregroundColor(.secondary)
            Text("Doctor registration requests will appear here for your review.")
                .font(.caption).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .listRowBackground(Color.clear)
    }
}

// MARK: - Request Row

struct DoctorRequestRow: View {
    let request: DoctorRegistrationRequest

    var statusColor: Color {
        switch request.status {
        case "Approved": return .brandGreen
        case "Rejected": return .brandCoral
        default:         return .brandAmber
        }
    }

    var statusIcon: String {
        switch request.status {
        case "Approved": return "checkmark.circle.fill"
        case "Rejected": return "xmark.circle.fill"
        default:         return "clock.fill"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Doctor avatar
            Circle()
                .fill(Color.brandTeal.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "stethoscope")
                        .font(.system(size: 18))
                        .foregroundColor(.brandTeal)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(request.name)
                    .font(.subheadline).fontWeight(.medium)

                HStack(spacing: 6) {
                    Text(request.specialty)
                        .font(.caption2).foregroundColor(.secondary)
                    Text("·")
                        .font(.caption2).foregroundColor(.secondary)
                    Text(request.regulatoryBody)
                        .font(.caption2).fontWeight(.medium)
                        .foregroundColor(.brandPurple)
                }

                Text(request.submittedAt, style: .date)
                    .font(.caption2).foregroundColor(.secondary)
            }

            Spacer()

            // Status badge
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.title3)
        }
    }
}

// MARK: - Request Detail (Review & Approve/Reject)

struct DoctorRequestDetailView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    let request: DoctorRegistrationRequest

    @State private var showApproveConfirm = false
    @State private var showRejectConfirm = false

    var isPending: Bool { request.status == "Pending" }

    var body: some View {
        List {
            // Personal info
            Section("Doctor Information") {
                infoRow("Name", value: request.name)
                infoRow("Email", value: request.email)
                infoRow("Specialty", value: request.specialty)
                infoRow("Hospital", value: request.hospital)
                infoRow("Location", value: "\(request.city), \(request.country)")
                infoRow("Postcode", value: request.postcode)
            }

            // Credentials
            Section("Credentials") {
                infoRow("Regulatory Body", value: request.regulatoryBody)
                infoRow("GMC Number", value: request.gmcNumber)
                infoRow("GMC Status", value: request.gmcStatus)
                infoRow("PMQ", value: "\(request.pmqDegree) — \(request.pmqCountry), \(request.pmqYear)")
                credentialCheck("Certificate of Good Standing", passed: request.goodStanding)
                credentialCheck("PLAB/UKMLA Passed", passed: request.plabPassed)
                credentialCheck("ECFMG Certified", passed: request.ecfmgCertified)
                credentialCheck("WDOM Listed", passed: request.wdomListed)
            }

            // Fees
            Section("Consultation Fees") {
                infoRow("Video", value: "£\(String(format: "%.0f", request.videoFee))")
                infoRow("Phone", value: "£\(String(format: "%.0f", request.phoneFee))")
                infoRow("In-Person", value: "£\(String(format: "%.0f", request.inPersonFee))")
            }

            // Introduction
            if !request.introduction.isEmpty {
                Section("Introduction") {
                    Text(request.introduction)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Status
            Section("Status") {
                HStack {
                    Text("Current Status")
                    Spacer()
                    Text(request.status)
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(request.status == "Approved" ? .brandGreen : request.status == "Rejected" ? .brandCoral : .brandAmber)
                }
                HStack {
                    Text("Submitted")
                    Spacer()
                    Text(request.submittedAt, style: .date)
                        .foregroundColor(.secondary)
                }
            }

            // Action buttons (only for pending)
            if isPending {
                Section {
                    Button {
                        showApproveConfirm = true
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                            Text("Approve Doctor")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .background(Color.brandGreen)
                        .cornerRadius(12)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                    Button {
                        showRejectConfirm = true
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "xmark.circle.fill")
                            Text("Reject")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .foregroundColor(.brandCoral)
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Review Doctor")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Approve Doctor?", isPresented: $showApproveConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Approve") {
                store.approveDoctor(request)
                dismiss()
            }
        } message: {
            Text("\(request.name) will be added to the verified doctor directory and can start receiving patient bookings.")
        }
        .alert("Reject Doctor?", isPresented: $showRejectConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Reject", role: .destructive) {
                store.rejectDoctor(request)
                dismiss()
            }
        } message: {
            Text("\(request.name) will not be added to the doctor directory.")
        }
    }

    func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value.isEmpty ? "—" : value)
                .font(.subheadline)
                .multilineTextAlignment(.trailing)
        }
    }

    func credentialCheck(_ label: String, passed: Bool) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Image(systemName: passed ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundColor(passed ? .brandGreen : .secondary.opacity(0.4))
        }
    }
}
