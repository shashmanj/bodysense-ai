//
//  ConnectView.swift
//  body sense ai
//
//  Telemedicine Hub: Doctor Directory · Appointments · Prescriptions
//

import SwiftUI

// MARK: - Connect View

struct ConnectView: View {
    @Environment(HealthStore.self) var store
    @State private var selectedTab = 0
    let tabs = ["Doctors", "Appointments", "Prescriptions"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    ForEach(0..<tabs.count, id: \.self) { i in Text(tabs[i]).tag(i) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.brandBg)

                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedTab {
                        case 0: DoctorDirectoryTab()
                        case 1: AppointmentsTab()
                        case 2: PrescriptionsTab()
                        default: EmptyView()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .padding(.bottom, 24)
                }
                .background(Color.brandBg)
            }
            .navigationTitle("Telemedicine")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Doctor Directory Tab

struct DoctorDirectoryTab: View {
    @Environment(HealthStore.self) var store
    @State private var searchText    = ""
    @State private var conditionText = ""
    @State private var postcodeText  = ""
    @State private var selectedSpec  : String? = nil
    @State private var selectedDoctor: Doctor? = nil
    @State private var searchScope   : SearchScope = .myArea

    enum SearchScope: String, CaseIterable {
        case myArea    = "My Area"
        case myCountry = "My Country"
        case worldwide = "Worldwide"
    }

    let specializations = ["All", "Endocrinologist", "Cardiologist", "Diabetologist",
                           "Internal Medicine", "Nephrologist", "Nutritionist"]

    var userCity: String { store.userProfile.city }
    var userCountry: String { store.userProfile.country }

    var filtered: [Doctor] {
        var docs = store.doctors.filter { $0.isVerified }

        // Scope filter
        switch searchScope {
        case .myArea:
            if !userCity.isEmpty {
                docs = docs.filter { $0.city == userCity }
            }
        case .myCountry:
            if !userCountry.isEmpty {
                docs = docs.filter { $0.country == userCountry }
            }
        case .worldwide:
            break // show all
        }

        // Postcode search
        if !postcodeText.isEmpty {
            let q = postcodeText.uppercased().replacingOccurrences(of: " ", with: "")
            docs = docs.filter {
                $0.postcode.uppercased().replacingOccurrences(of: " ", with: "").hasPrefix(q) ||
                $0.city.localizedCaseInsensitiveContains(postcodeText)
            }
        }

        // Condition-based search
        if !conditionText.isEmpty {
            let specs = ConditionMapper.specializations(for: conditionText)
            if !specs.isEmpty {
                docs = docs.filter { specs.contains($0.specialization) }
            }
        }

        // Specialization filter
        if let spec = selectedSpec, spec != "All" {
            docs = docs.filter { $0.specialization == spec }
        }

        // Name search
        if !searchText.isEmpty {
            docs = docs.filter { $0.name.localizedCaseInsensitiveContains(searchText) ||
                                 $0.specialization.localizedCaseInsensitiveContains(searchText) }
        }

        // Sort: verified first, user's city first, then rating
        docs.sort { a, b in
            if a.isVerified && !b.isVerified { return true }
            if !a.isVerified && b.isVerified { return false }
            if !userCity.isEmpty {
                if a.city == userCity && b.city != userCity { return true }
                if b.city == userCity && a.city != userCity { return false }
            }
            return a.rating > b.rating
        }
        return docs
    }

    var body: some View {
        Group {
            // Banner
            BSCard {
                HStack(spacing: 14) {
                    Image(systemName: "video.fill")
                        .font(.title2).foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.brandTeal).cornerRadius(12)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Video Consultation").font(.subheadline.bold())
                        Text("Connect with specialist doctors from home. Premium subscribers get monthly consultations included.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
            }

            // Search scope toggle (locality / country / worldwide)
            HStack(spacing: 0) {
                ForEach(SearchScope.allCases, id: \.self) { scope in
                    Button {
                        withAnimation { searchScope = scope }
                    } label: {
                        Text(scope.rawValue)
                            .font(.caption.bold())
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .frame(maxWidth: .infinity)
                            .background(searchScope == scope ? Color.brandPurple : Color.clear)
                            .foregroundColor(searchScope == scope ? .white : .brandPurple)
                    }
                }
            }
            .background(Color.brandPurple.opacity(0.1))
            .cornerRadius(10)

            // Postcode / locality search
            HStack {
                Image(systemName: "mappin.circle.fill").foregroundColor(.brandTeal)
                TextField("Search by postcode or city…", text: $postcodeText)
            }
            .padding(10)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .shadow(color: Color.primary.opacity(0.05), radius: 4, y: 2)

            // Search by name
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search doctors…", text: $searchText)
            }
            .padding(10)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .shadow(color: Color.primary.opacity(0.05), radius: 4, y: 2)

            // Search by condition
            HStack {
                Image(systemName: "stethoscope").foregroundColor(.secondary)
                TextField("Search by condition (e.g. diabetes, heart)…", text: $conditionText)
            }
            .padding(10)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .shadow(color: Color.primary.opacity(0.05), radius: 4, y: 2)

            // Specialization filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(specializations, id: \.self) { spec in
                        FilterChip(
                            label: spec,
                            isSelected: (spec == "All" && selectedSpec == nil) || selectedSpec == spec
                        ) {
                            selectedSpec = (spec == "All") ? nil : spec
                        }
                    }
                }
                .padding(.horizontal, 2)
            }

            // Doctor cards
            ForEach(filtered) { doctor in
                DoctorCard(doctor: doctor) { selectedDoctor = doctor }
            }
        }
        .sheet(item: $selectedDoctor) { doc in DoctorDetailView(doctor: doc) }
    }
}

// MARK: - Doctor Card

struct DoctorCard: View {
    @Environment(HealthStore.self) var store
    let doctor: Doctor
    let onBook: () -> Void

    var body: some View {
        BSCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(Color(hex: doctor.avatarColor)).frame(width: 54, height: 54)
                        Text(doctor.name.components(separatedBy: " ").compactMap { $0.first.map(String.init) }.prefix(2).joined())
                            .font(.headline.bold()).foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(doctor.name).font(.subheadline.bold())
                        Text(doctor.specialization).font(.caption).foregroundColor(.brandPurple)
                        Text(doctor.qualifications + " · " + doctor.hospital).font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill").font(.caption2).foregroundColor(.brandAmber)
                            Text(String(format: "%.1f", doctor.rating)).font(.caption.bold())
                        }
                        Text("(\(doctor.reviews))").font(.caption2).foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 12) {
                    InfoPill(icon: "briefcase.fill",    text: "\(doctor.experience)y exp", color: .brandPurple)
                    InfoPill(icon: "mappin.circle.fill", text: doctor.city,                color: .brandTeal)
                    InfoPill(icon: "clock.fill",         text: doctor.nextAvailable,        color: .brandGreen)
                }

                // Certification badges
                if doctor.isVerified || !doctor.certifications.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            if doctor.isVerified {
                                HStack(spacing: 3) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.caption2).foregroundColor(.brandGreen)
                                    Text("Verified").font(.caption2).fontWeight(.semibold)
                                        .foregroundColor(.brandGreen)
                                }
                                .padding(.horizontal, 7).padding(.vertical, 3)
                                .background(Color.brandGreen.opacity(0.1))
                                .cornerRadius(6)
                            }
                            if !doctor.regulatoryBody.isEmpty {
                                Text(doctor.regulatoryBody)
                                    .font(.caption2).fontWeight(.medium)
                                    .padding(.horizontal, 7).padding(.vertical, 3)
                                    .background(Color.brandPurple.opacity(0.1))
                                    .foregroundColor(.brandPurple)
                                    .cornerRadius(6)
                            }
                            ForEach(doctor.certifications.prefix(2), id: \.self) { cert in
                                Text(cert)
                                    .font(.caption2)
                                    .padding(.horizontal, 7).padding(.vertical, 3)
                                    .background(Color.brandTeal.opacity(0.1))
                                    .foregroundColor(.brandTeal)
                                    .cornerRadius(6)
                            }
                        }
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Consultation fee").font(.caption2).foregroundColor(.secondary)
                        Text(doctor.feeString(currencyCode: store.userCurrency))
                            .font(.subheadline.bold()).foregroundColor(.brandPurple)
                    }
                    Spacer()
                    Button(action: onBook) {
                        Label("Book Now", systemImage: "calendar.badge.plus")
                            .font(.subheadline.bold()).foregroundColor(.white)
                            .padding(.horizontal, 18).padding(.vertical, 10)
                            .background(Color.brandPurple).cornerRadius(12)
                    }
                }
            }
        }
    }
}

// MARK: - Doctor Detail View

struct DoctorDetailView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    let doctor: Doctor
    @State private var selectedDate    = Date()
    @State private var selectedType    : AppointmentType = .video
    @State private var notes           = ""
    @State private var bookingConfirmed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Doctor header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color(hex: doctor.avatarColor)).frame(width: 80, height: 80)
                            Text(doctor.name.components(separatedBy: " ").compactMap { $0.first.map(String.init) }.prefix(2).joined())
                                .font(.title2.bold()).foregroundColor(.white)
                        }
                        Text(doctor.name).font(.title3.bold())
                        Text(doctor.specialization).font(.subheadline).foregroundColor(.brandPurple)
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill").foregroundColor(.brandAmber)
                            Text(String(format: "%.1f", doctor.rating)).font(.subheadline.bold())
                            Text("· \(doctor.reviews) reviews").font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(20)
                    .shadow(color: Color.primary.opacity(0.06), radius: 6, y: 2)
                    .padding(.horizontal)

                    // Stats
                    HStack(spacing: 0) {
                        DoctorStat(label: "Experience",    value: "\(doctor.experience) yrs")
                        DoctorStat(label: "Hospital",      value: doctor.hospital.components(separatedBy: " ").prefix(2).joined(separator: " "))
                        DoctorStat(label: "Fee",           value: doctor.feeString(currencyCode: store.userCurrency))
                    }
                    .background(Color(.secondarySystemGroupedBackground)).cornerRadius(16)
                    .shadow(color: Color.primary.opacity(0.05), radius: 4, y: 2)
                    .padding(.horizontal)

                    // Credentials & Certifications
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Credentials & Certifications", systemImage: "checkmark.seal.fill")
                            .font(.subheadline.bold()).foregroundColor(.brandPurple)

                        if doctor.isVerified {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundColor(.brandGreen)
                                Text("Verified by BodySense AI")
                                    .font(.caption).foregroundColor(.brandGreen).fontWeight(.semibold)
                            }
                        }

                        if !doctor.regulatoryBody.isEmpty || !doctor.licenseNumber.isEmpty {
                            HStack {
                                Text("License: \(doctor.regulatoryBody) \(doctor.licenseNumber)")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }

                        if !doctor.countryExam.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "graduationcap.fill").font(.caption).foregroundColor(.brandTeal)
                                Text("Country exam: \(doctor.countryExam)")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }

                        if !doctor.certifications.isEmpty {
                            FlowLayout(spacing: 6) {
                                ForEach(doctor.certifications, id: \.self) { cert in
                                    Text(cert)
                                        .font(.caption2).fontWeight(.medium)
                                        .padding(.horizontal, 10).padding(.vertical, 5)
                                        .background(Color.brandTeal.opacity(0.1))
                                        .foregroundColor(.brandTeal)
                                        .cornerRadius(8)
                                }
                            }
                        }

                        if !doctor.postcode.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.and.ellipse").font(.caption).foregroundColor(.brandAmber)
                                Text("\(doctor.city), \(doctor.postcode) · \(doctor.country)")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.primary.opacity(0.05), radius: 4, y: 2)
                    .padding(.horizontal)

                    // Book appointment
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Book Appointment").font(.headline).padding(.horizontal)

                        BSCard {
                            VStack(spacing: 12) {
                                Picker("Type", selection: $selectedType) {
                                    ForEach(AppointmentType.allCases, id: \.self) { t in
                                        Label(t.rawValue, systemImage: t.icon).tag(t)
                                    }
                                }.pickerStyle(.segmented)

                                DatePicker("Date & Time", selection: $selectedDate, in: Date()...,
                                           displayedComponents: [.date, .hourAndMinute])

                                TextField("Notes for doctor (optional)", text: $notes, axis: .vertical)
                                    .padding(10).background(Color.brandBg).cornerRadius(10)

                                Button {
                                    store.appointments.append(Appointment(
                                        doctorName: doctor.name, doctorSpec: doctor.specialization,
                                        doctorColor: doctor.avatarColor,
                                        date: selectedDate, type: selectedType, status: .upcoming, notes: notes))
                                    store.save()
                                    bookingConfirmed = true
                                } label: {
                                    Text("Confirm Booking — \(doctor.feeString(currencyCode: store.userCurrency))")
                                        .font(.headline).foregroundColor(.white)
                                        .frame(maxWidth: .infinity).padding()
                                        .background(Color.brandPurple).cornerRadius(14)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color.brandBg)
            .navigationTitle("Book Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Close") { dismiss() } }
            }
            .alert("Booking Confirmed", isPresented: $bookingConfirmed) {
                Button("Done") { dismiss() }
            } message: {
                Text("Your appointment with \(doctor.name) on \(selectedDate.formatted(date: .abbreviated, time: .shortened)) has been booked. You'll receive a confirmation email shortly.")
            }
        }
    }
}

// MARK: - Appointments Tab

struct AppointmentsTab: View {
    @Environment(HealthStore.self) var store

    var upcoming  : [Appointment] { store.appointments.filter { $0.status == .upcoming  }.sorted { $0.date < $1.date } }
    var completed : [Appointment] { store.appointments.filter { $0.status == .completed }.sorted { $0.date > $1.date } }

    var body: some View {
        Group {
            if upcoming.isEmpty && completed.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.plus").font(.system(size: 50)).foregroundColor(.brandPurple.opacity(0.3))
                    Text("No appointments").font(.title3.bold())
                    Text("Book a consultation with a specialist doctor from the Doctors tab.")
                        .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
                }.padding()
            } else {
                if !upcoming.isEmpty {
                    SectionHeader("Upcoming", count: upcoming.count)
                    ForEach(upcoming) { appt in AppointmentCard(appointment: appt) }
                }
                if !completed.isEmpty {
                    SectionHeader("Past Appointments", count: completed.count)
                    ForEach(completed) { appt in AppointmentCard(appointment: appt) }
                }
            }
        }
    }
}

struct AppointmentCard: View {
    let appointment: Appointment

    var body: some View {
        BSCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(Color(hex: appointment.doctorColor).opacity(0.15)).frame(width: 52, height: 52)
                    Image(systemName: appointment.type.icon)
                        .font(.title3).foregroundColor(Color(hex: appointment.doctorColor))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(appointment.doctorName).font(.subheadline.bold())
                    Text(appointment.doctorSpec).font(.caption).foregroundColor(.brandPurple)
                    Text(appointment.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption).foregroundColor(.secondary)
                    if !appointment.notes.isEmpty {
                        Text(appointment.notes).font(.caption).foregroundColor(.secondary).lineLimit(1)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text(appointment.status.rawValue)
                        .font(.caption.bold())
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(appointment.status.color.opacity(0.15))
                        .foregroundColor(appointment.status.color).cornerRadius(8)
                    if appointment.status == .upcoming {
                        Button {
                            // Join call action
                        } label: {
                            Text("Join Call")
                                .font(.caption.bold()).foregroundColor(.white)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Color.brandTeal).cornerRadius(8)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Prescriptions Tab

struct PrescriptionsTab: View {
    @Environment(HealthStore.self) var store

    var valid   : [Prescription] { store.prescriptions.filter { $0.validUntil >= Date() } }
    var expired : [Prescription] { store.prescriptions.filter { $0.validUntil < Date() } }

    var body: some View {
        Group {
            if store.prescriptions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.fill").font(.system(size: 50)).foregroundColor(.brandPurple.opacity(0.3))
                    Text("No prescriptions yet").font(.title3.bold())
                    Text("Prescriptions issued during your consultations will appear here.")
                        .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
                }.padding()
            } else {
                if !valid.isEmpty {
                    SectionHeader("Active Prescriptions", count: valid.count)
                    ForEach(valid) { rx in PrescriptionCard(prescription: rx) }
                }
                if !expired.isEmpty {
                    SectionHeader("Expired")
                    ForEach(expired) { rx in PrescriptionCard(prescription: rx) }
                }
            }
        }
    }
}

struct PrescriptionCard: View {
    let prescription: Prescription
    @State private var expanded = false

    var isValid: Bool { prescription.validUntil >= Date() }

    var body: some View {
        BSCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(prescription.doctorName).font(.subheadline.bold())
                        Text(prescription.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(isValid ? "Active" : "Expired")
                        .font(.caption.bold())
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(isValid ? Color.brandGreen.opacity(0.15) : Color.gray.opacity(0.15))
                        .foregroundColor(isValid ? .brandGreen : .secondary)
                        .cornerRadius(8)
                }

                Text("Diagnosis: \(prescription.diagnosis)").font(.caption).foregroundColor(.secondary)

                Button { withAnimation { expanded.toggle() } } label: {
                    Label(expanded ? "Hide medications" : "Show \(prescription.medications.count) medications",
                          systemImage: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption).foregroundColor(.brandPurple)
                }

                if expanded {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(prescription.medications, id: \.self) { med in
                            HStack(spacing: 6) {
                                Circle().fill(Color.brandPurple).frame(width: 5, height: 5)
                                Text(med).font(.caption)
                            }
                        }
                        if !prescription.notes.isEmpty {
                            Text("Note: \(prescription.notes)").font(.caption).foregroundColor(.secondary).padding(.top, 4)
                        }
                        Text("Valid until: \(prescription.validUntil.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2).foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
}

// MARK: - Helper Views

struct InfoPill: View {
    let icon: String; let text: String; let color: Color
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2).foregroundColor(color)
            Text(text).font(.caption).foregroundColor(.secondary)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(color.opacity(0.1)).cornerRadius(8)
    }
}

struct DoctorStat: View {
    let label: String; let value: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.caption.bold()).multilineTextAlignment(.center)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
    }
}

// MARK: - Flow Layout (for certification badges)

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(in: proposal.width ?? 300, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (idx, pos) in result.positions.enumerated() {
            subviews[idx].place(at: CGPoint(x: bounds.minX + pos.x, y: bounds.minY + pos.y),
                                proposal: .unspecified)
        }
    }

    private func layout(in width: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxWidth = max(maxWidth, x)
        }
        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
