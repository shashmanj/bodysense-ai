//
//  DoctorApprovalView.swift
//  body sense ai
//
//  CEO-only view for reviewing and approving/rejecting doctor registrations.
//

import SwiftUI

// MARK: - Doctor Document Response Model

/// JSON shape returned by GET /doctor-documents/:userId
private struct DoctorDocumentsResponse: Codable {
    var photoId: String?
    var dbsCertificate: String?
    var indemnityInsurance: String?
    var qualification: String?
}

// MARK: - Doctor Approval List

struct DoctorApprovalView: View {
    @Environment(HealthStore.self) var store

    var pending: [DoctorRegistrationRequest] {
        store.doctorRequests.filter { $0.status == .pending }
    }

    var reviewed: [DoctorRegistrationRequest] {
        store.doctorRequests.filter { $0.status != .pending }
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
        case .approved: return .brandGreen
        case .rejected: return .brandCoral
        case .pending:  return .brandAmber
        }
    }

    var statusIcon: String {
        switch request.status {
        case .approved: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .pending:  return "clock.fill"
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
    @State private var showDocumentViewer = false

    var isPending: Bool { request.status == .pending }

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

            // Uploaded Documents
            Section("Uploaded Documents") {
                if request.userId.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.secondary)
                        Text("No user ID linked — documents unavailable")
                            .font(.caption).foregroundColor(.secondary)
                    }
                } else {
                    Button {
                        showDocumentViewer = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 18))
                                .foregroundColor(.brandTeal)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("View Documents")
                                    .font(.subheadline).fontWeight(.medium)
                                    .foregroundColor(.primary)
                                Text("Photo ID, DBS, Insurance, Qualification")
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
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
                    Text(request.status.rawValue)
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(request.status == .approved ? .brandGreen : request.status == .rejected ? .brandCoral : .brandAmber)
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
        .sheet(isPresented: $showDocumentViewer) {
            NavigationStack {
                DoctorDocumentViewerView(userId: request.userId, doctorName: request.name)
            }
        }
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

// MARK: - Doctor Document Viewer (CEO Only)

/// Fetches and displays uploaded doctor documents from the backend.
/// Gated by CEOAccessManager — only the CEO can view these sensitive documents.
private struct DoctorDocumentViewerView: View {
    let userId: String
    let doctorName: String

    @Environment(\.dismiss) var dismiss
    @State private var documents: [(label: String, url: URL)] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedImageURL: URL?

    private let baseURL = "https://body-sense-ai-production.up.railway.app"

    var body: some View {
        Group {
            if !CEOAccessManager.isActivated {
                // Double-gate — should never happen, but defence in depth
                VStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 48)).foregroundColor(.secondary)
                    Text("CEO Access Required")
                        .font(.headline).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Loading documents...")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.brandAmber)
                    Text("Failed to Load Documents")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.caption).foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button {
                        Task { await fetchDocuments() }
                    } label: {
                        Text("Retry")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color(.systemFill))
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if documents.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.3))
                    Text("No Documents Uploaded")
                        .font(.headline).foregroundColor(.secondary)
                    Text("This doctor has not uploaded any verification documents yet.")
                        .font(.caption).foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(documents, id: \.url) { doc in
                            documentCard(label: doc.label, url: doc.url)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("\(doctorName) — Documents")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
        .fullScreenCover(item: $selectedImageURL) { url in
            NavigationStack {
                DoctorDocumentFullScreenView(url: url)
            }
        }
        .task {
            await fetchDocuments()
        }
    }

    // MARK: - Document Card

    private func documentCard(label: String, url: URL) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: iconForDocumentType(label))
                    .foregroundColor(.brandTeal)
                Text(label)
                    .font(.subheadline).fontWeight(.semibold)
                Spacer()
                Button {
                    selectedImageURL = url
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.tertiarySystemBackground))
                        .frame(height: 200)
                        .overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 280)
                        .cornerRadius(10)
                        .onTapGesture {
                            selectedImageURL = url
                        }
                case .failure:
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.tertiarySystemBackground))
                        .frame(height: 120)
                        .overlay(
                            VStack(spacing: 6) {
                                Image(systemName: "photo.badge.exclamationmark")
                                    .font(.title3).foregroundColor(.secondary)
                                Text("Failed to load image")
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                        )
                @unknown default:
                    EmptyView()
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - Fetch Documents

    private func fetchDocuments() async {
        guard CEOAccessManager.isActivated else {
            errorMessage = "CEO access is required to view documents."
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil
        documents = []

        guard let url = URL(string: "\(baseURL)/doctor-documents/\(userId)") else {
            errorMessage = "Invalid request URL."
            isLoading = false
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Unexpected response from server."
                isLoading = false
                return
            }

            guard httpResponse.statusCode == 200 else {
                errorMessage = "Server returned status \(httpResponse.statusCode)."
                isLoading = false
                return
            }

            let decoded = try JSONDecoder().decode(DoctorDocumentsResponse.self, from: data)

            var result: [(label: String, url: URL)] = []
            if let urlString = decoded.photoId, let docURL = URL(string: urlString) {
                result.append((label: "Photo ID", url: docURL))
            }
            if let urlString = decoded.dbsCertificate, let docURL = URL(string: urlString) {
                result.append((label: "DBS Certificate", url: docURL))
            }
            if let urlString = decoded.indemnityInsurance, let docURL = URL(string: urlString) {
                result.append((label: "Indemnity Insurance", url: docURL))
            }
            if let urlString = decoded.qualification, let docURL = URL(string: urlString) {
                result.append((label: "Qualification Certificate", url: docURL))
            }

            documents = result
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Helpers

    private func iconForDocumentType(_ label: String) -> String {
        switch label {
        case "Photo ID":                return "person.text.rectangle"
        case "DBS Certificate":         return "checkmark.shield.fill"
        case "Indemnity Insurance":     return "building.columns.fill"
        case "Qualification Certificate": return "scroll.fill"
        default:                        return "doc.fill"
        }
    }
}

// MARK: - Full-Screen Document Image Viewer

/// Makes URL Identifiable so it can be used with .fullScreenCover(item:)
extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

private struct DoctorDocumentFullScreenView: View {
    let url: URL
    @Environment(\.dismiss) var dismiss
    @State private var currentZoom: CGFloat = 1.0

    var body: some View {
        GeometryReader { geo in
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: geo.size.width, height: geo.size.height)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(minWidth: geo.size.width, minHeight: geo.size.height)
                            .scaleEffect(currentZoom)
                            .gesture(
                                MagnifyGesture()
                                    .onChanged { value in
                                        currentZoom = max(1.0, min(value.magnification, 5.0))
                                    }
                                    .onEnded { value in
                                        withAnimation(.spring()) {
                                            currentZoom = max(1.0, min(value.magnification, 5.0))
                                        }
                                    }
                            )
                            .onTapGesture(count: 2) {
                                withAnimation(.spring()) {
                                    currentZoom = currentZoom > 1.0 ? 1.0 : 2.5
                                }
                            }
                    case .failure:
                        VStack(spacing: 12) {
                            Image(systemName: "photo.badge.exclamationmark")
                                .font(.system(size: 48)).foregroundColor(.secondary)
                            Text("Failed to load image")
                                .font(.subheadline).foregroundColor(.secondary)
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle("Document")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }
}
