//
//  DoctorAppointmentsView.swift
//  body sense ai
//
//  Patient-facing: browse doctors, book appointments, reviews, postcode filter.
//

import SwiftUI
import PhotosUI

// MARK: - Doctors Tab Root

struct DoctorAppointmentsView: View {
    @Environment(HealthStore.self) var store
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            DoctorListView()
                .tabItem { Label("Find Doctors", systemImage: "stethoscope") }
                .tag(0)
            MyAppointmentsView()
                .tabItem { Label("My Appointments", systemImage: "calendar") }
                .tag(1)
        }
        .tint(.brandTeal)
    }
}

// MARK: - Doctor List

struct DoctorListView: View {
    @Environment(HealthStore.self) var store
    @State private var search           = ""
    @State private var selectedDoc      : Doctor? = nil
    @State private var showBook         = false
    @State private var showFilter       = false
    @State private var selectedSpec     = "All"
    @State private var useLocalSearch   = false
    @State private var showDocDetail    = false
    @State private var detailDoc        : Doctor? = nil

    var verifiedDoctors: [Doctor] {
        store.doctors.filter { $0.isVerified }
    }

    var allSpecialties: [String] {
        ["All"] + Array(Set(verifiedDoctors.map { $0.specialization })).sorted()
    }

    var filtered: [Doctor] {
        verifiedDoctors.filter { d in
            let matchSpec   = selectedSpec == "All" || d.specialization == selectedSpec
            let matchSearch = search.isEmpty || d.name.localizedCaseInsensitiveContains(search) ||
                              d.specialization.localizedCaseInsensitiveContains(search) ||
                              d.bio.localizedCaseInsensitiveContains(search)
            let matchLocal  : Bool
            if useLocalSearch && !store.userProfile.postcode.isEmpty {
                // Simple UK postcode area match (first 2–4 chars)
                let userArea = String(store.userProfile.postcode.prefix(4)).uppercased()
                let docArea  = String(d.postcode.prefix(4)).uppercased()
                matchLocal = docArea.isEmpty || docArea.hasPrefix(String(userArea.prefix(2)))
            } else {
                matchLocal = true
            }
            return matchSpec && matchSearch && matchLocal
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    // ── Hero banner ──
                    heroBanner

                    // ── Search & Filter Bar ──
                    HStack(spacing: 10) {
                        HStack {
                            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                            TextField("Search doctors, speciality…", text: $search)
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                        // Filter Button
                        Button { showFilter = true } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "line.3.horizontal.decrease.circle\(selectedSpec != "All" ? ".fill" : "")")
                                    .font(.title3)
                                if selectedSpec != "All" {
                                    Text(selectedSpec).font(.caption).lineLimit(1)
                                }
                            }
                            .foregroundColor(selectedSpec != "All" ? .white : .brandTeal)
                            .padding(.horizontal, 14).padding(.vertical, 12)
                            .background(selectedSpec != "All" ? Color.brandTeal : Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                    // ── Location Toggle ──
                    HStack {
                        Image(systemName: "location.fill")
                            .font(.caption).foregroundColor(.brandTeal)
                        Toggle(useLocalSearch ? "Local (\(store.userProfile.postcode.isEmpty ? "set postcode" : store.userProfile.postcode))" : "Worldwide", isOn: $useLocalSearch)
                            .font(.subheadline)
                            .tint(.brandTeal)
                    }
                    .padding(.horizontal).padding(.bottom, 10)

                    // ── Doctor cards ──
                    if filtered.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "person.slash")
                                .font(.system(size: 48)).foregroundColor(.secondary)
                            Text("No doctors found").font(.headline)
                            Text("Try adjusting your filter or search").font(.subheadline).foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(filtered) { doc in
                                BookDoctorCard(doctor: doc) {
                                    selectedDoc = doc
                                    showBook = true
                                } onViewProfile: {
                                    detailDoc = doc
                                    showDocDetail = true
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Find a Doctor")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showBook) {
            if let doc = selectedDoc {
                BookAppointmentView(doctor: doc)
            }
        }
        .sheet(isPresented: $showDocDetail) {
            if let doc = detailDoc {
                DoctorProfileDetailView(doctor: doc) {
                    selectedDoc = doc
                    showDocDetail = false
                    showBook = true
                }
            }
        }
        .sheet(isPresented: $showFilter) {
            SpecialtyFilterSheet(
                specialties: allSpecialties,
                selected: $selectedSpec
            )
        }
    }

    var heroBanner: some View {
        ZStack(alignment: .leading) {
            LinearGradient(colors: [Color(hex: "#4ECDC4"), Color(hex: "#26de81")],
                           startPoint: .leading, endPoint: .trailing)
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Talk to a Doctor")
                        .font(.title2).fontWeight(.bold).foregroundColor(.white)
                    Text("Video, phone & in-person consultations")
                        .font(.caption).foregroundColor(.white.opacity(0.85))
                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield.fill")
                        Text("Secure · Encrypted · Verified Doctors")
                    }
                    .font(.caption2).foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Image(systemName: "person.badge.clock.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding()
        }
        .frame(height: 120)
        .padding(.bottom, 14)
    }
}

// MARK: - Specialty Filter Sheet

struct SpecialtyFilterSheet: View {
    let specialties: [String]
    @Binding var selected: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(specialties, id: \.self) { spec in
                    Button {
                        selected = spec
                        dismiss()
                    } label: {
                        HStack {
                            Text(spec).foregroundColor(.primary)
                            Spacer()
                            if selected == spec {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.brandTeal)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter by Specialty")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Clear") { selected = "All"; dismiss() }
                        .foregroundColor(.brandCoral)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Doctor Profile Detail View

struct DoctorProfileDetailView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    let doctor: Doctor
    let onBook: () -> Void

    var reviews: [DoctorReview] {
        store.doctorReviews.filter { $0.doctorId == doctor.id }
            .sorted { $0.date > $1.date }
    }

    var avgRating: Double {
        reviews.isEmpty ? doctor.rating :
            reviews.map { $0.rating }.reduce(0, +) / Double(reviews.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // ── Header gradient ──
                    ZStack(alignment: .bottom) {
                        LinearGradient(colors: [Color(hex: doctor.avatarColor), Color(hex: doctor.avatarColor).opacity(0.7)],
                                       startPoint: .top, endPoint: .bottom)
                            .frame(height: 200)

                        HStack(alignment: .bottom, spacing: 16) {
                            if let photoData = doctor.profilePhotoData, let uiImg = UIImage(data: photoData) {
                                Image(uiImage: uiImg)
                                    .resizable().scaledToFill()
                                    .frame(width: 80, height: 80).clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                            } else {
                                Circle().fill(Color(hex: doctor.avatarColor))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Text(initials(doctor.name))
                                            .font(.title.bold())
                                            .foregroundColor(.white)
                                    )
                                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(doctor.name).font(.title2).fontWeight(.bold).foregroundColor(.white)
                                Text(doctor.specialization).font(.subheadline).foregroundColor(.white.opacity(0.9))
                                HStack(spacing: 6) {
                                    Image(systemName: "mappin.circle.fill").font(.caption)
                                    Text(doctor.city).font(.caption)
                                    if !doctor.postcode.isEmpty {
                                        Text("· \(doctor.postcode)").font(.caption)
                                    }
                                }.foregroundColor(.white.opacity(0.8))
                            }
                            Spacer()
                        }
                        .padding()
                        .padding(.bottom, 12)
                    }

                    VStack(spacing: 20) {
                        // ── Rating & stats row ──
                        HStack(spacing: 0) {
                            statCell(value: String(format: "%.1f", avgRating), label: "Rating", icon: "star.fill", color: .brandAmber)
                            Divider().frame(height: 40)
                            statCell(value: "\(reviews.count)", label: "Reviews", icon: "text.bubble.fill", color: .brandTeal)
                            Divider().frame(height: 40)
                            statCell(value: "\(doctor.experience)yr", label: "Experience", icon: "calendar.badge.checkmark", color: .brandPurple)
                            Divider().frame(height: 40)
                            statCell(value: doctor.available ? "Now" : "Busy", label: "Availability", icon: "clock.fill", color: doctor.available ? .brandGreen : .brandCoral)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.06), radius: 8)
                        .padding(.horizontal)
                        .padding(.top, 16)

                        // ── Consultation fees ──
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Consultation Fees").font(.headline).padding(.horizontal)
                            HStack(spacing: 12) {
                                feeCard("Video", fee: doctor.fee, icon: "video.fill", color: .brandTeal)
                                feeCard("Phone", fee: Int(Double(doctor.fee) * 0.7), icon: "phone.fill", color: .brandPurple)
                                feeCard("In Person", fee: Int(Double(doctor.fee) * 1.5), icon: "person.fill", color: .brandAmber)
                            }
                            .padding(.horizontal)
                        }

                        // ── About / Bio ──
                        if !doctor.bio.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("About").font(.headline)
                                Text(doctor.bio).font(.body).foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemBackground))
                            .cornerRadius(16).shadow(color: .black.opacity(0.05), radius: 6)
                            .padding(.horizontal)
                        }

                        // ── Qualifications & Credentials ──
                        credentialsSection

                        // ── Reviews ──
                        reviewsSection

                        // ── Book button ──
                        Button(action: onBook) {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                Text("Book Appointment")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity).padding()
                            .background(doctor.available ? Color.brandTeal : Color(.systemGray4))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                        .disabled(!doctor.available)
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    var credentialsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Qualifications & Credentials").font(.headline).padding(.horizontal)
            VStack(spacing: 0) {
                credRow("Qualifications", value: doctor.qualifications, icon: "graduationcap.fill")
                Divider().padding(.leading, 52)
                credRow("Hospital", value: doctor.hospital, icon: "building.columns.fill")
                Divider().padding(.leading, 52)
                credRow("Languages", value: doctor.languages.joined(separator: ", "), icon: "globe")
                if !doctor.licenseNumber.isEmpty {
                    Divider().padding(.leading, 52)
                    credRow("License No.", value: doctor.licenseNumber, icon: "number")
                }
                if doctor.isVerified {
                    Divider().padding(.leading, 52)
                    credRow("Status", value: "Verified by BodySense AI", icon: "checkmark.shield.fill")
                }
                if !doctor.certifications.isEmpty {
                    Divider().padding(.leading, 52)
                    credRow("Certifications", value: doctor.certifications.joined(separator: ", "), icon: "rosette")
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(16).shadow(color: .black.opacity(0.05), radius: 6)
            .padding(.horizontal)
        }
    }

    var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Patient Reviews (\(reviews.count))").font(.headline)
                Spacer()
                if !reviews.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill").foregroundColor(.brandAmber).font(.caption)
                        Text(String(format: "%.1f", avgRating)).font(.subheadline).fontWeight(.semibold)
                    }
                }
            }
            .padding(.horizontal)

            if reviews.isEmpty {
                HStack {
                    Image(systemName: "text.bubble")
                        .font(.title).foregroundColor(.secondary.opacity(0.5))
                    Text("No reviews yet. Book a consultation to be the first!")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(16).shadow(color: .black.opacity(0.05), radius: 6)
                .padding(.horizontal)
            } else {
                ForEach(reviews.prefix(5)) { rev in
                    ReviewCard(review: rev)
                        .padding(.horizontal)
                }
            }
        }
    }

    func statCell(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title3).foregroundColor(color)
            Text(value).font(.headline)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    func feeCard(_ type: String, fee: Int, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title3).foregroundColor(color)
            Text("£\(fee)").font(.title3).fontWeight(.bold)
            Text(type).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(color.opacity(0.08)).cornerRadius(14)
    }

    func credRow(_ label: String, value: String, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.body).foregroundColor(.brandTeal).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundColor(.secondary)
                Text(value.isEmpty ? "—" : value).font(.subheadline)
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    func initials(_ name: String) -> String {
        name.components(separatedBy: " ").compactMap { $0.first.map { String($0) } }.prefix(2).joined()
    }
}

// MARK: - Review Card

struct ReviewCard: View {
    let review: DoctorReview

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle().fill(Color.brandPurple.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay(Text(String(review.patientName.prefix(1))).font(.headline).foregroundColor(.brandPurple))
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.patientName).font(.subheadline).fontWeight(.semibold)
                    Text(review.date.formatted(date: .abbreviated, time: .omitted)).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: i < Int(review.rating) ? "star.fill" : "star")
                            .font(.caption2).foregroundColor(.brandAmber)
                    }
                }
            }
            if !review.comment.isEmpty {
                Text(review.comment).font(.body).foregroundColor(.primary)
            }
            HStack(spacing: 6) {
                Text(review.consultType).font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color(.systemGray6)).cornerRadius(6)
                if review.isVerified {
                    Label("Verified Patient", systemImage: "checkmark.circle.fill")
                        .font(.caption2).foregroundColor(.brandGreen)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14).shadow(color: .black.opacity(0.05), radius: 6)
    }
}

// MARK: - Book Doctor Card

struct BookDoctorCard: View {
    let doctor     : Doctor
    let onBook     : () -> Void
    let onViewProfile: () -> Void

    var body: some View {
        Button(action: onViewProfile) {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    // Avatar with verified badge overlay
                    ZStack(alignment: .bottomTrailing) {
                        if let photoData = doctor.profilePhotoData, let uiImg = UIImage(data: photoData) {
                            Image(uiImage: uiImg).resizable().scaledToFill()
                                .frame(width: 56, height: 56).clipShape(Circle())
                        } else {
                            Circle().fill(Color(hex: doctor.avatarColor)).frame(width: 56, height: 56)
                                .overlay(Text(initials(doctor.name)).font(.title3.bold()).foregroundColor(.white))
                        }
                        if doctor.isVerified {
                            Image(systemName: "cross.circle.fill")
                                .font(.headline)
                                .foregroundColor(.red)
                                .background(Circle().fill(.white).padding(1))
                                .offset(x: 4, y: 4)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(doctor.name).font(.headline).foregroundColor(.primary)
                            if doctor.isVerified {
                                HStack(spacing: 3) {
                                    Image(systemName: "cross.circle.fill")
                                        .foregroundColor(.red)
                                    Text("Verified")
                                        .font(.caption2.bold())
                                        .foregroundColor(.red)
                                }
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.red.opacity(0.10))
                                .cornerRadius(8)
                            }
                        }
                        Text(doctor.specialization).font(.subheadline).foregroundColor(.secondary)
                        HStack(spacing: 8) {
                            Label(String(format: "%.1f", doctor.rating), systemImage: "star.fill")
                                .font(.caption).foregroundColor(.brandAmber)
                            Text("(\(doctor.reviews))").font(.caption).foregroundColor(.secondary)
                            Text("·").foregroundColor(.secondary)
                            Text(doctor.city).font(.caption).foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        Text("£\(doctor.fee)").font(.headline).foregroundColor(.brandPurple)
                        Text("per session").font(.caption2).foregroundColor(.secondary)
                        Text(doctor.available ? "Available" : "Busy").font(.caption2)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(doctor.available ? Color.brandGreen.opacity(0.15) : Color.brandCoral.opacity(0.15))
                            .foregroundColor(doctor.available ? .brandGreen : .brandCoral)
                            .cornerRadius(6)
                    }
                }
                .padding()

                Divider().padding(.horizontal)

                HStack {
                    Label(doctor.nextAvailable, systemImage: "clock")
                        .font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Button {
                        onViewProfile()
                    } label: {
                        Text("View Profile")
                            .font(.caption).fontWeight(.medium)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(Color(.systemGray6))
                            .foregroundColor(.primary).cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button {
                        onBook()
                    } label: {
                        Label("Book", systemImage: "calendar.badge.plus")
                            .font(.caption).fontWeight(.semibold)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Color.brandTeal).foregroundColor(.white).cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!doctor.available)
                }
                .padding(.horizontal).padding(.vertical, 10)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color(.systemBackground))
        .cornerRadius(16).shadow(color: .black.opacity(0.06), radius: 8)
    }

    func initials(_ name: String) -> String {
        name.components(separatedBy: " ").compactMap { $0.first.map { String($0) } }.prefix(2).joined()
    }
}

// MARK: - Book Appointment

struct BookAppointmentView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    let doctor: Doctor

    @State private var selectedDate  = Date()
    @State private var selectedTime  = "10:00 AM"
    @State private var selectedType  : AppointmentType = .video
    @State private var notes         = ""
    @State private var showPayment   = false
    @State private var booked        = false
    @State private var paymentMethod = ""

    // Document sharing
    @State private var attachReadings     = false
    @State private var selectedRecordIds  : Set<UUID> = []
    @State private var scanPickerItem     : PhotosPickerItem? = nil
    @State private var scanData           : Data? = nil
    @State private var scanThumbData      : Data? = nil

    let timeSlots = ["9:00 AM","9:30 AM","10:00 AM","10:30 AM","11:00 AM","11:30 AM",
                     "2:00 PM","2:30 PM","3:00 PM","3:30 PM","4:00 PM","4:30 PM","5:00 PM"]

    var currentFee: Int {
        switch selectedType {
        case .video:     return doctor.fee
        case .phone:     return Int(Double(doctor.fee) * 0.7)
        case .inPerson:  return Int(Double(doctor.fee) * 1.5)
        }
    }

    var body: some View {
        NavigationStack {
            if store.subscription < .premium {
                // Doctor consultations require Premium subscription
                ScrollView {
                    UpgradePromptView(
                        requiredPlan: .premium,
                        store: store,
                        isPresented: .init(get: { true }, set: { _ in dismiss() })
                    )
                    .padding(.top, 40)
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Book Appointment")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                }
            } else if booked {
                BookingConfirmationView(doctor: doctor, date: selectedDate,
                                        time: selectedTime, type: selectedType,
                                        paymentMethod: paymentMethod) { dismiss() }
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        doctorSummaryCard
                        appointmentTypeSection
                        dateSection
                        timeSection
                        notesSection
                        documentSharingSection
                        priceSummaryCard
                        bookButton
                    }
                    .padding(.bottom, 32)
                }
                .navigationTitle("Book Appointment")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
                .sheet(isPresented: $showPayment) {
                    ApplePayCheckoutView(
                        title: "Consultation with \(doctor.name)",
                        subtitle: "\(selectedType.rawValue) · \(selectedTime)",
                        amountGBP: Double(currentFee),
                        onSuccess: { transactionId, method in
                            paymentMethod = method
                            confirmBooking(intentId: transactionId, method: method)
                            showPayment = false
                        }
                    )
                }
            }
        }
    }

    var doctorSummaryCard: some View {
        HStack(spacing: 14) {
            Circle().fill(Color(hex: doctor.avatarColor)).frame(width: 52, height: 52)
                .overlay(Text(doctor.name.components(separatedBy: " ").compactMap { $0.first.map { String($0) } }.prefix(2).joined())
                    .font(.headline).foregroundColor(.white))
            VStack(alignment: .leading, spacing: 3) {
                Text(doctor.name).font(.headline)
                Text(doctor.specialization).font(.subheadline).foregroundColor(.secondary)
                Text(doctor.qualifications).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Label(String(format: "%.1f", doctor.rating), systemImage: "star.fill")
                .font(.caption).foregroundColor(.brandAmber)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16).shadow(color: .black.opacity(0.06), radius: 8)
        .padding(.horizontal)
    }

    var appointmentTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appointment Type").font(.headline).padding(.horizontal)
            HStack(spacing: 10) {
                ForEach(AppointmentType.allCases, id: \.self) { type in
                    Button { selectedType = type } label: {
                        VStack(spacing: 6) {
                            Image(systemName: type.icon).font(.title3)
                            Text(type.rawValue).font(.caption).multilineTextAlignment(.center)
                            Text("£\(Int(Double(doctor.fee) * (type == .video ? 1.0 : type == .phone ? 0.7 : 1.5)))")
                                .font(.caption2).fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(selectedType == type ? Color.brandTeal : Color(.systemGray6))
                        .foregroundColor(selectedType == type ? .white : .primary)
                        .cornerRadius(14)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Date").font(.headline).padding(.horizontal)
            DatePicker("", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                .datePickerStyle(.graphical).padding(.horizontal)
        }
    }

    var timeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Time").font(.headline).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(timeSlots, id: \.self) { t in
                        Button { selectedTime = t } label: {
                            Text(t).font(.subheadline)
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                .background(selectedTime == t ? Color.brandTeal : Color(.systemGray6))
                                .foregroundColor(selectedTime == t ? .white : .primary)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes for Doctor (optional)").font(.headline).padding(.horizontal)
            ZStack(alignment: .topLeading) {
                if notes.isEmpty {
                    Text("Describe your symptoms or reason for consultation…")
                        .font(.subheadline).foregroundColor(.secondary)
                        .padding(.top, 12).padding(.leading, 16)
                }
                TextEditor(text: $notes)
                    .frame(height: 100)
                    .padding(.horizontal, 8)
            }
            .background(Color(.systemGray6)).cornerRadius(12)
            .padding(.horizontal)
        }
    }

    // MARK: - Document Sharing Section

    var documentSharingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Share Documents with Doctor", systemImage: "doc.badge.arrow.up")
                .font(.headline).padding(.horizontal)

            Text("Help your doctor prepare by sharing your health data, medical records or scans.")
                .font(.caption).foregroundColor(.secondary).padding(.horizontal)

            // ── 1. Attach 30-day readings ──
            attachReadingsToggle

            // ── 2. Select existing medical records ──
            if !store.medicalRecords.isEmpty {
                existingRecordsSelector
            }

            // ── 3. Upload new scan/report ──
            uploadScanSection
        }
    }

    var attachReadingsToggle: some View {
        Button { attachReadings.toggle() } label: {
            HStack(spacing: 12) {
                Image(systemName: "heart.text.clipboard")
                    .font(.title3).foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.brandTeal).cornerRadius(10)
                VStack(alignment: .leading, spacing: 2) {
                    Text("30-Day Health Readings").font(.subheadline).fontWeight(.medium)
                    Text("Glucose, BP, HR, sleep, stress & more").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: attachReadings ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(attachReadings ? .brandGreen : .secondary)
            }
            .padding()
            .background(attachReadings ? Color.brandTeal.opacity(0.08) : Color(.systemGray6))
            .cornerRadius(14)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }

    var existingRecordsSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Medical Records").font(.subheadline).fontWeight(.medium).padding(.horizontal)
            ForEach(store.medicalRecords) { record in
                Button { toggleRecord(record.id) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: record.fileType.icon)
                            .font(.body).foregroundColor(.brandPurple)
                            .frame(width: 32, height: 32)
                            .background(Color.brandPurple.opacity(0.1)).cornerRadius(8)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.title).font(.caption).fontWeight(.medium).lineLimit(1)
                            Text(record.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2).foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: selectedRecordIds.contains(record.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedRecordIds.contains(record.id) ? .brandGreen : .secondary)
                    }
                    .padding(10)
                    .background(selectedRecordIds.contains(record.id) ? Color.brandPurple.opacity(0.06) : Color(.systemGray6))
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
            }
        }
    }

    var uploadScanSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Upload Scan / Report").font(.subheadline).fontWeight(.medium).padding(.horizontal)
            PhotosPicker(selection: $scanPickerItem, matching: .images) {
                HStack(spacing: 12) {
                    Image(systemName: scanData != nil ? "checkmark.circle.fill" : "arrow.up.doc.fill")
                        .font(.title3).foregroundColor(scanData != nil ? .brandGreen : .brandAmber)
                        .frame(width: 40, height: 40)
                        .background((scanData != nil ? Color.brandGreen : Color.brandAmber).opacity(0.12))
                        .cornerRadius(10)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(scanData != nil ? "Scan attached" : "Tap to upload a photo")
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundColor(scanData != nil ? .brandGreen : .primary)
                        Text("X-ray, MRI, blood test, or any report image")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    if scanData != nil {
                        Button {
                            scanData = nil
                            scanThumbData = nil
                            scanPickerItem = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6)).cornerRadius(14)
            }
            .padding(.horizontal)
            .onChange(of: scanPickerItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        scanData = data
                        if let uiImg = UIImage(data: data) {
                            let thumb = uiImg.preparingThumbnail(of: CGSize(width: 120, height: 120))
                            scanThumbData = thumb?.jpegData(compressionQuality: 0.7)
                        }
                    }
                }
            }
        }
    }

    func toggleRecord(_ id: UUID) {
        if selectedRecordIds.contains(id) { selectedRecordIds.remove(id) }
        else { selectedRecordIds.insert(id) }
    }

    var priceSummaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Consultation Fee").font(.subheadline)
                Spacer()
                Text("£\(currentFee)").font(.subheadline)
            }
            HStack {
                Text("Platform processing fee").font(.caption).foregroundColor(.secondary)
                Spacer()
                Text("£0.00").font(.caption).foregroundColor(.secondary)
            }
            Divider()
            HStack {
                Text("Total").font(.headline)
                Spacer()
                Text("£\(currentFee)").font(.headline).foregroundColor(.brandTeal)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16).shadow(color: .black.opacity(0.06), radius: 8)
        .padding(.horizontal)
    }

    var bookButton: some View {
        Button { showPayment = true } label: {
            HStack {
                Image(systemName: selectedType.icon)
                Text("Proceed to Pay · £\(currentFee)").fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity).padding()
            .background(Color.brandTeal).foregroundColor(.white).cornerRadius(16)
        }
        .padding(.horizontal)
    }

    func buildAttachments(for appointmentId: UUID) -> [AppointmentAttachment] {
        var attachments: [AppointmentAttachment] = []

        // 1. 30-day health readings
        if attachReadings {
            let summary = store.thirtyDayReadingsSummary()
            attachments.append(AppointmentAttachment(
                appointmentId: appointmentId,
                type: .healthReadings,
                title: "30-Day Health Readings",
                data: summary.data(using: .utf8),
                notes: "Auto-generated from patient health data"
            ))
        }

        // 2. Selected medical records
        for record in store.medicalRecords where selectedRecordIds.contains(record.id) {
            attachments.append(AppointmentAttachment(
                appointmentId: appointmentId,
                type: .medicalRecord,
                title: record.title,
                data: record.fileData,
                thumbnailData: record.thumbnailData,
                notes: record.notes
            ))
        }

        // 3. Uploaded scan
        if let data = scanData {
            attachments.append(AppointmentAttachment(
                appointmentId: appointmentId,
                type: .uploadedScan,
                title: "Uploaded Scan/Report",
                data: data,
                thumbnailData: scanThumbData,
                notes: ""
            ))
        }

        return attachments
    }

    func confirmBooking(intentId: String, method: String) {
        let cal = Calendar.current
        let comps = DateComponents(year: cal.component(.year, from: selectedDate),
                                   month: cal.component(.month, from: selectedDate),
                                   day: cal.component(.day, from: selectedDate))
        let date = cal.date(from: comps) ?? selectedDate

        let apptId = UUID()
        let attachments = buildAttachments(for: apptId)

        var appt = Appointment(
            doctorId: doctor.id,
            doctorName: doctor.name,
            doctorSpec: doctor.specialization,
            doctorColor: doctor.avatarColor,
            date: date,
            type: selectedType,
            status: .upcoming,
            notes: notes,
            feeGBP: Double(currentFee),
            isPaid: true,
            paymentIntentId: intentId,
            videoRoomId: "room_\(doctor.id.uuidString.prefix(8))",
            durationMin: 30,
            paymentMethod: method
        )
        appt.id = apptId
        appt.attachments = attachments
        store.appointments.append(appt)
        store.save()

        // ── Schedule appointment reminder notifications ──
        NotificationService.shared.scheduleAppointmentReminder(
            appointmentId: appt.id,
            doctorName: doctor.name,
            date: appt.date
        )
        NotificationService.shared.scheduleAtTimeReminder(
            appointmentId: appt.id,
            doctorName: doctor.name,
            date: appt.date
        )

        booked = true
    }
}

// MARK: - Booking Confirmation

struct BookingConfirmationView: View {
    let doctor: Doctor
    let date: Date
    let time: String
    let type: AppointmentType
    let paymentMethod: String
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.brandGreen)
                .shadow(color: .brandGreen.opacity(0.3), radius: 20)

            Text("Appointment Booked!").font(.title.bold())
            Text("Your \(type.rawValue.lowercased()) consultation with \(doctor.name) is confirmed for \(date.formatted(date: .long, time: .omitted)) at \(time).")
                .font(.body).multilineTextAlignment(.center).foregroundColor(.secondary)
                .padding(.horizontal, 32)

            VStack(spacing: 12) {
                confirmRow("Doctor", value: doctor.name, icon: "stethoscope")
                confirmRow("Date & Time", value: "\(date.formatted(date: .abbreviated, time: .omitted)) · \(time)", icon: "calendar")
                confirmRow("Type", value: type.rawValue, icon: type.icon)
                confirmRow("Paid via", value: paymentMethod, icon: "creditcard.fill")
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(20).shadow(color: .black.opacity(0.06), radius: 10)
            .padding(.horizontal)

            Text("A notification reminder will be sent before your appointment.")
                .font(.caption).foregroundColor(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)

            Spacer()
            Button("Done", action: onDone)
                .font(.headline).frame(maxWidth: .infinity).padding()
                .background(Color.brandTeal).foregroundColor(.white).cornerRadius(16)
                .padding(.horizontal, 28).padding(.bottom, 40)
        }
    }

    func confirmRow(_ label: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(.brandTeal).frame(width: 24)
            Text(label).font(.subheadline).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.subheadline).fontWeight(.medium)
        }
    }
}

// MARK: - Leave Review View

struct LeaveReviewView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    let appointment: Appointment

    @State private var rating  : Double = 5
    @State private var comment = ""
    @State private var saved   = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Rate your consultation") {
                    HStack {
                        ForEach(1...5, id: \.self) { i in
                            Button {
                                withAnimation { rating = Double(i) }
                            } label: {
                                Image(systemName: Double(i) <= rating ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundColor(.brandAmber)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                Section("Your review") {
                    TextEditor(text: $comment)
                        .frame(height: 120)
                }
                Section {
                    Button("Submit Review") { submitReview() }
                        .foregroundColor(.brandTeal)
                }
            }
            .navigationTitle("Leave a Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Review Submitted!", isPresented: $saved) {
                Button("OK") { dismiss() }
            }
        }
    }

    func submitReview() {
        guard let docId = appointment.doctorId else { return }
        let review = DoctorReview(
            doctorId: docId,
            patientName: store.userProfile.anonymousAlias.isEmpty ? "Anonymous" : store.userProfile.anonymousAlias,
            patientAlias: store.userProfile.anonymousAlias,
            rating: rating,
            comment: comment,
            date: Date(),
            appointmentId: appointment.id,
            isVerified: appointment.isPaid,
            consultType: appointment.type.rawValue
        )
        store.doctorReviews.append(review)
        store.save()
        saved = true
    }
}

// MARK: - My Appointments

struct MyAppointmentsView: View {
    @Environment(HealthStore.self) var store
    @State private var showReview: Appointment? = nil

    var upcoming: [Appointment] { store.appointments.filter { $0.status == .upcoming }.sorted { $0.date < $1.date } }
    var past: [Appointment]     { store.appointments.filter { $0.status != .upcoming }.sorted { $0.date > $1.date } }

    var body: some View {
        NavigationStack {
            Group {
                if store.appointments.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 56)).foregroundColor(.brandTeal.opacity(0.4))
                        Text("No appointments yet").font(.title3).fontWeight(.semibold)
                        Text("Find a doctor and book your first consultation.")
                            .font(.subheadline).foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding()
                } else {
                    List {
                        if !upcoming.isEmpty {
                            Section("Upcoming") {
                                ForEach(upcoming) { appt in
                                    PatientApptRow(appointment: appt, showReview: $showReview)
                                }
                            }
                        }
                        if !past.isEmpty {
                            Section("Past") {
                                ForEach(past) { appt in
                                    PatientApptRow(appointment: appt, showReview: $showReview)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Appointments")
        }
        .sheet(item: $showReview) { appt in
            LeaveReviewView(appointment: appt)
        }
    }
}

// MARK: - Patient Appointment Row

struct PatientApptRow: View {
    @Environment(HealthStore.self) var store
    let appointment: Appointment
    @Binding var showReview: Appointment?
    @State private var showCall = false

    var alreadyReviewed: Bool {
        guard let docId = appointment.doctorId else { return false }
        return store.doctorReviews.contains { $0.doctorId == docId && $0.appointmentId == appointment.id }
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 14) {
                Circle().fill(Color(hex: appointment.doctorColor)).frame(width: 44, height: 44)
                    .overlay(Text(String(appointment.doctorName.prefix(1))).font(.headline).foregroundColor(.white))

                VStack(alignment: .leading, spacing: 3) {
                    Text(appointment.doctorName).font(.subheadline).fontWeight(.semibold)
                    Text(appointment.doctorSpec).font(.caption).foregroundColor(.secondary)
                    Text("\(appointment.date.formatted(date: .abbreviated, time: .omitted)) · \(appointment.date.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2).foregroundColor(.secondary)
                }

                Spacer()

                Text(appointment.status.rawValue).font(.caption2)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(appointment.status.color.opacity(0.15))
                    .foregroundColor(appointment.status.color).cornerRadius(6)
            }

            if appointment.status == .upcoming {
                HStack(spacing: 10) {
                    if appointment.type == .video {
                        Button {
                            showCall = true
                        } label: {
                            Label("Join Call", systemImage: "video.fill")
                                .font(.caption).fontWeight(.semibold)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(Color.brandTeal).foregroundColor(.white).cornerRadius(10)
                        }
                    }
                    Spacer()
                    Text("£\(Int(appointment.feeGBP)) · \(appointment.paymentMethod)")
                        .font(.caption2).foregroundColor(.secondary)
                }
            } else if appointment.status == .completed && !alreadyReviewed {
                Button { showReview = appointment } label: {
                    Label("Leave a Review", systemImage: "star.fill")
                        .font(.caption).fontWeight(.medium)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Color.brandAmber.opacity(0.15))
                        .foregroundColor(.brandAmber).cornerRadius(10)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .fullScreenCover(isPresented: $showCall) {
            if let doc = store.doctors.first(where: { $0.id == appointment.doctorId }) {
                VideoCallView(
                    session: VideoCallSession(doctor: doc, appointment: appointment,
                                             roomId: appointment.videoRoomId ?? "room",
                                             startTime: Date())
                ) { showCall = false }
            }
        }
    }
}
