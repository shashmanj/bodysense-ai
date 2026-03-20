//
//  MedicineSearchView.swift
//  body sense ai
//
//  Smart Medicine Search — browse and search 500+ medicines with category
//  filtering, popular quick-picks, and detailed medicine information sheets.
//

import SwiftUI

// MARK: - Medicine Search View

struct MedicineSearchView: View {
    @Binding var selectedMedicine: MedicineItem?
    @Environment(\.dismiss) var dismiss

    @State private var searchText = ""
    @State private var selectedCategory: MedicineCategory? = nil
    @State private var showDetail: MedicineItem? = nil
    @FocusState private var searchFocused: Bool

    private let db = MedicineDatabase.shared

    // Popular medicines for quick access chips
    private let popularMedicines = [
        "Paracetamol", "Ibuprofen", "Metformin", "Omeprazole",
        "Amoxicillin", "Atorvastatin", "Amlodipine", "Salbutamol"
    ]

    var results: [MedicineItem] {
        if let cat = selectedCategory {
            let catMeds = db.medicines(in: cat)
            if searchText.isEmpty { return catMeds }
            let q = searchText.lowercased()
            return catMeds.filter {
                $0.genericName.lowercased().contains(q) ||
                $0.brandNames.contains(where: { $0.lowercased().contains(q) }) ||
                $0.therapeuticClass.lowercased().contains(q)
            }
        }
        return db.search(searchText)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar

                ScrollView {
                    VStack(spacing: 0) {
                        // Category filter strip
                        if selectedCategory != nil {
                            categoryFilterBanner
                        }

                        if searchText.isEmpty && selectedCategory == nil {
                            // Empty state with popular picks and categories
                            emptyState
                        } else if results.isEmpty {
                            noResultsView
                        } else {
                            resultsList
                        }
                    }
                }
            }
            .background(Color.brandBg.ignoresSafeArea())
            .navigationTitle("Search Medicines")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.brandPurple)
                }
            }
            .sheet(item: $showDetail) { medicine in
                MedicineDetailView(medicine: medicine, selectedMedicine: $selectedMedicine)
            }
            .onAppear { searchFocused = true }
        }
    }

    // MARK: - Search Bar

    var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.body)
            TextField("Search medicines, brands, or conditions...", text: $searchText)
                .focused($searchFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityLabel("Search medicines")
                .accessibilityHint("Type a medicine name to find it")
            if !searchText.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        searchText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .transition(.scale.combined(with: .opacity))
                .accessibilityLabel("Clear search")
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Category Filter Banner

    var categoryFilterBanner: some View {
        HStack(spacing: 8) {
            if let cat = selectedCategory {
                Image(systemName: cat.icon)
                    .foregroundColor(Color(hex: cat.color))
                Text(cat.rawValue)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
            }
            Spacer()
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedCategory = nil
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "xmark")
                        .font(.caption2.bold())
                    Text("Clear")
                        .font(.caption.bold())
                }
                .foregroundColor(.brandCoral)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.brandCoral.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemBackground).opacity(0.6))
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Empty State

    var emptyState: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 30)

            // Hero illustration
            VStack(spacing: 10) {
                Image(systemName: "pills.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.brandPurple, .brandTeal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(0.4)
                Text("Find Your Medicine")
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                Text("Search by generic name, brand name,\nor therapeutic class.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Popular medicines section
            VStack(alignment: .leading, spacing: 12) {
                Text("Popular Medicines")
                    .font(.headline)
                    .padding(.horizontal, 16)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(popularMedicines, id: \.self) { name in
                        popularChip(name)
                    }
                }
                .padding(.horizontal, 16)
            }

            // Browse by category section
            VStack(alignment: .leading, spacing: 12) {
                Text("Browse by Category")
                    .font(.headline)
                    .padding(.horizontal, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(MedicineCategory.allCases, id: \.self) { category in
                            categoryPill(category)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }

            Spacer(minLength: 40)
        }
    }

    func popularChip(_ name: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                searchText = name
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "pill.fill")
                    .font(.caption)
                    .foregroundColor(.brandPurple.opacity(0.6))
                Text(name)
                    .font(.subheadline)
                    .foregroundColor(.brandPurple)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.brandPurple.opacity(0.08))
            .cornerRadius(10)
        }
        .accessibilityLabel("Search for \(name)")
    }

    func categoryPill(_ category: MedicineCategory) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedCategory = category
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            .foregroundColor(Color(hex: category.color))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Color(hex: category.color).opacity(0.12))
            .cornerRadius(20)
        }
        .accessibilityLabel("Browse \(category.rawValue) medicines")
    }

    // MARK: - No Results

    var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 60)
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.4))
            Text("No results for \"\(searchText)\"")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Try a different spelling, brand name, or generic name")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    // MARK: - Results List

    var resultsList: some View {
        LazyVStack(spacing: 10) {
            ForEach(results.prefix(30)) { medicine in
                medicineCard(medicine)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 20)
        .animation(.easeInOut(duration: 0.25), value: results.map(\.genericName))
    }

    func medicineCard(_ medicine: MedicineItem) -> some View {
        Button {
            showDetail = medicine
        } label: {
            HStack(spacing: 12) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(Color(hex: medicine.category.color).opacity(0.15))
                        .frame(width: 42, height: 42)
                    Image(systemName: medicine.category.icon)
                        .font(.body)
                        .foregroundColor(Color(hex: medicine.category.color))
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(medicine.genericName)
                        .font(.body.bold())
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(medicine.therapeuticClass)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    // Brand badges + OTC badge
                    HStack(spacing: 4) {
                        ForEach(medicine.brandNames.prefix(3), id: \.self) { brand in
                            Text(brand)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.brandTeal)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.brandTeal.opacity(0.1))
                                .cornerRadius(4)
                        }
                        if medicine.brandNames.count > 3 {
                            Text("+\(medicine.brandNames.count - 3)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.08))
                                .cornerRadius(4)
                        }
                        if medicine.isOTC {
                            Text("OTC")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.brandGreen)
                                .cornerRadius(4)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(medicine.genericName), \(medicine.therapeuticClass)\(medicine.isOTC ? ", over the counter" : "")")
        .accessibilityHint("View medicine details")
    }
}

// MARK: - Preview

#Preview {
    MedicineSearchView(selectedMedicine: .constant(nil))
}
