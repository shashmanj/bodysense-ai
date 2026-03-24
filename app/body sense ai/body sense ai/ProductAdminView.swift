//
//  ProductAdminView.swift
//  body sense ai
//
//  Product management admin panel — add, edit, delete products.
//

import SwiftUI
import PhotosUI

// MARK: - Admin Product List

struct ProductAdminView: View {
    @Environment(HealthStore.self) var store
    @State private var showAddForm = false
    @State private var editingProduct: Product? = nil
    @State private var showDeleteConfirm = false
    @State private var productToDelete: Product? = nil

    var body: some View {
        List {
            ForEach(store.products) { product in
                ProductAdminRow(product: product) {
                    editingProduct = product
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        productToDelete = product
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Manage Products")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAddForm = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.brandPurple)
                }
            }
        }
        .sheet(isPresented: $showAddForm) {
            NavigationStack {
                ProductFormView(mode: .add)
                    .environment(store)
            }
        }
        .sheet(item: $editingProduct) { product in
            NavigationStack {
                ProductFormView(mode: .edit(product))
                    .environment(store)
            }
        }
        .alert("Delete Product?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let product = productToDelete {
                    store.deleteProduct(product)
                }
            }
        } message: {
            if let product = productToDelete {
                Text("Are you sure you want to delete \"\(product.name)\"? This cannot be undone.")
            }
        }
    }
}

// MARK: - Admin Row

struct ProductAdminRow: View {
    let product: Product
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 12) {
                // Product image or fallback icon
                if let url = product.imageURL,
                   let data = try? Data(contentsOf: url),
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Circle()
                        .fill(Color(hex: product.color).opacity(0.15))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: product.icon)
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: product.color))
                        )
                }

                // Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(product.name)
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Text(product.category.rawValue)
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text("£\(String(format: "%.2f", product.price))")
                            .font(.caption2).fontWeight(.semibold)
                            .foregroundColor(.brandPurple)
                    }
                }

                Spacer()

                // Stock indicator
                Circle()
                    .fill(product.inStock ? Color.brandGreen : Color.brandCoral)
                    .frame(width: 8, height: 8)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Product Form (Add / Edit)

enum ProductFormMode: Identifiable {
    case add
    case edit(Product)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let p): return p.id.uuidString
        }
    }
}

struct ProductFormView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    let mode: ProductFormMode

    @State private var name = ""
    @State private var description = ""
    @State private var price = ""
    @State private var originalPrice = ""
    @State private var category: ProductCategory = .accessories
    @State private var icon = "shippingbox.fill"
    @State private var colorHex = "#6C63FF"
    @State private var inStock = true
    @State private var isNew = false
    @State private var isBestSeller = false
    @State private var rating = 4.8
    @State private var reviews = 0
    @State private var pickerItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var hasExistingImage = false

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var isValid: Bool {
        !name.isEmpty && !description.isEmpty &&
        Double(price) != nil && Double(originalPrice) != nil
    }

    var body: some View {
        Form {
            // Product Image
            Section("Product Image") {
                VStack(spacing: 12) {
                    // Image preview
                    if let img = selectedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: colorHex).opacity(0.1))
                            .frame(height: 200)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 40))
                                        .foregroundColor(Color(hex: colorHex).opacity(0.5))
                                    Text("Tap to add product photo")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            )
                    }

                    HStack(spacing: 12) {
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            Label(selectedImage != nil ? "Change Photo" : "Choose Photo",
                                  systemImage: "photo.on.rectangle.angled")
                                .font(.subheadline).fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.brandPurple.opacity(0.1))
                                .foregroundColor(.brandPurple)
                                .cornerRadius(10)
                        }

                        if selectedImage != nil {
                            Button {
                                selectedImage = nil
                                hasExistingImage = false
                                HapticManager.shared.tap()
                            } label: {
                                Label("Remove", systemImage: "trash")
                                    .font(.subheadline).fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.red.opacity(0.1))
                                    .foregroundColor(.red)
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            }
            .onChange(of: pickerItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                        HapticManager.shared.success()
                    }
                }
            }

            // Basic info
            Section("Product Details") {
                TextField("Product Name", text: $name)
                TextField("Description", text: $description, axis: .vertical)
                    .lineLimit(2...4)
            }

            // Pricing
            Section("Pricing (GBP)") {
                HStack {
                    Text("£")
                        .foregroundColor(.secondary)
                    TextField("Sale Price", text: $price)
                        .keyboardType(.decimalPad)
                }
                HStack {
                    Text("£")
                        .foregroundColor(.secondary)
                    TextField("Original Price", text: $originalPrice)
                        .keyboardType(.decimalPad)
                }
            }

            // Category & appearance
            Section("Category & Appearance") {
                Picker("Category", selection: $category) {
                    ForEach(ProductCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }

                HStack {
                    Text("SF Symbol")
                        .foregroundColor(.secondary)
                    Spacer()
                    TextField("Icon name", text: $icon)
                        .multilineTextAlignment(.trailing)
                    Image(systemName: icon)
                        .foregroundColor(Color(hex: colorHex))
                        .frame(width: 24)
                }

                HStack {
                    Text("Accent Colour")
                        .foregroundColor(.secondary)
                    Spacer()
                    TextField("#Hex", text: $colorHex)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                    Circle()
                        .fill(Color(hex: colorHex))
                        .frame(width: 24, height: 24)
                }
            }

            // Flags
            Section("Status") {
                Toggle("In Stock", isOn: $inStock)
                Toggle("Mark as New", isOn: $isNew)
                Toggle("Best Seller", isOn: $isBestSeller)
            }

            // Rating
            Section("Rating") {
                HStack {
                    Text("Rating")
                    Spacer()
                    Text(String(format: "%.1f", rating))
                        .foregroundColor(.secondary)
                }
                Slider(value: $rating, in: 1...5, step: 0.1)

                Stepper("Reviews: \(reviews)", value: $reviews, in: 0...99999)
            }
        }
        .navigationTitle(isEditing ? "Edit Product" : "Add Product")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Add") {
                    saveProduct()
                    dismiss()
                }
                .fontWeight(.semibold)
                .foregroundColor(.brandPurple)
                .disabled(!isValid)
            }
        }
        .onAppear { loadExisting() }
    }

    private func loadExisting() {
        guard case .edit(let product) = mode else { return }
        name = product.name
        description = product.description
        price = String(format: "%.2f", product.price)
        originalPrice = String(format: "%.2f", product.originalPrice)
        category = product.category
        icon = product.icon
        colorHex = product.color
        inStock = product.inStock
        isNew = product.isNew
        isBestSeller = product.isBestSeller
        rating = product.rating
        reviews = product.reviews

        // Load existing product image
        if let url = product.imageURL,
           let data = try? Data(contentsOf: url),
           let uiImage = UIImage(data: data) {
            selectedImage = uiImage
            hasExistingImage = true
        }
    }

    private func saveProduct() {
        let priceVal = Double(price) ?? 0
        let origPriceVal = Double(originalPrice) ?? priceVal

        switch mode {
        case .add:
            var product = Product(
                name: name,
                description: description,
                price: priceVal,
                originalPrice: origPriceVal,
                category: category,
                icon: icon,
                color: colorHex,
                inStock: inStock,
                rating: rating,
                reviews: reviews,
                isNew: isNew,
                isBestSeller: isBestSeller
            )
            // Save product image if selected
            if let img = selectedImage, let data = img.jpegData(compressionQuality: 0.8) {
                product.setImage(data)
            }
            store.addProduct(product)
            HapticManager.shared.success()

        case .edit(var product):
            product.name = name
            product.description = description
            product.price = priceVal
            product.originalPrice = origPriceVal
            product.category = category
            product.icon = icon
            product.color = colorHex
            product.inStock = inStock
            product.rating = rating
            product.reviews = reviews
            product.isNew = isNew
            product.isBestSeller = isBestSeller

            // Handle image changes
            if let img = selectedImage, let data = img.jpegData(compressionQuality: 0.8) {
                product.setImage(data)
            } else if selectedImage == nil && hasExistingImage {
                // CEO removed the image
                product.removeImage()
            }
            store.updateProduct(product)
            HapticManager.shared.success()
        }
    }
}
