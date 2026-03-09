//
//  ShopView.swift
//  body sense ai
//
//  Full shop: BodySense Ring with colour picker, Apple Pay + Stripe checkout,
//  accessories, subscriptions, order tracking.
//

import SwiftUI

// MARK: - Shop Root

struct ShopView: View {
    @Environment(HealthStore.self) var store
    @State private var tab         = 0
    @State private var showCart    = false

    var body: some View {
        NavigationView {
            TabView(selection: $tab) {
                ShopProductsTab()
                    .tabItem { Label("Shop", systemImage: "bag.fill") }
                    .tag(0)
                SubscriptionsTab()
                    .tabItem { Label("Subscriptions", systemImage: "crown.fill") }
                    .tag(1)
                OrdersTab()
                    .tabItem { Label("Orders", systemImage: "shippingbox.fill") }
                    .tag(2)
            }
            .tint(.brandPurple)
            .navigationTitle(tab == 0 ? "Shop" : tab == 1 ? "Subscriptions" : "My Orders")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showCart = true } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bag.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.brandPurple)
                            if store.cartCount > 0 {
                                Text("\(store.cartCount)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 18, height: 18)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showCart) {
            CartCheckoutView()
        }
    }
}

// MARK: - Shop Products Tab

struct ShopProductsTab: View {
    @Environment(HealthStore.self) var store
    @State private var selectedCategory: ProductCategory? = nil
    @State private var selectedProduct : Product? = nil

    var featured: Product? { store.products.first { $0.isRing } }

    var displayed: [Product] {
        if let cat = selectedCategory {
            return store.products.filter { $0.category == cat }
        }
        return store.products
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // ── Hero: BodySense Ring ──
                if let ring = featured {
                    RingHeroBanner(product: ring)
                        .onTapGesture { selectedProduct = ring }
                }

                // ── Category filter ──
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        filterChip("All", selected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach(ProductCategory.allCases, id: \.self) { cat in
                            filterChip(cat.rawValue, selected: selectedCategory == cat) {
                                selectedCategory = cat
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // ── Product grid ──
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(displayed) { product in
                        ProductCard2(product: product) {
                            selectedProduct = product
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .padding(.top, 8)
        }
        .sheet(item: $selectedProduct) { product in
            if product.isRing {
                ImmersiveRingProductView(product: product)
                    .environment(store)
            } else {
                ProductDetailView2(product: product)
            }
        }
    }

    func filterChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption).fontWeight(.medium)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(selected ? Color.brandPurple : Color(.systemGray6))
                .foregroundColor(selected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// MARK: - Ring Hero Banner

struct RingHeroBanner: View {
    @Environment(HealthStore.self) var store
    let product: Product
    @State private var selectedColor: RingColor = .silver
    @State private var showDetail   = false
    @State private var floatUp      = false

    var body: some View {
        ZStack(alignment: .leading) {
            // ── Glassmorphism background ──
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.brandPurple.opacity(0.08),
                                    Color.brandTeal.opacity(0.06),
                                    Color.white.opacity(0.35)
                                ],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.55), lineWidth: 1.2)
                )
                .shadow(color: Color.brandPurple.opacity(0.12), radius: 20, x: 0, y: 8)

            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 11) {

                    // Sale badge
                    HStack(spacing: 5) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundColor(.brandCoral)
                        Text("LIMITED SALE")
                            .font(.caption2).fontWeight(.bold)
                            .foregroundColor(.brandCoral)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.brandCoral.opacity(0.1))
                    .cornerRadius(20)

                    Text("BodySense Ring")
                        .font(.title2).fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("X3B · Medical Grade")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Price
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(product.priceString(currencyCode: store.userCurrency))
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(colors: [.brandPurple, .brandTeal],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                        if product.originalPrice > product.price {
                            Text(product.originalPriceString(currencyCode: store.userCurrency))
                                .font(.subheadline)
                                .strikethrough()
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                    }

                    let savings = CurrencyService.format(product.originalPrice - product.price, currencyCode: store.userCurrency)
                    Text("Save \(savings) · IP68 · 7–10 day battery")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    // Colour picker
                    HStack(spacing: 10) {
                        Text("Colour:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ForEach(product.availableColors, id: \.self) { col in
                            Circle()
                                .fill(col.color)
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            selectedColor == col
                                                ? Color.brandPurple
                                                : Color.gray.opacity(0.3),
                                            lineWidth: 2.5
                                        )
                                        .padding(-3)
                                )
                                .shadow(color: selectedColor == col ? col.glowColor.opacity(0.5) : .clear, radius: 5)
                                .onTapGesture { withAnimation(.spring()) { selectedColor = col } }
                        }
                        Text(selectedColor.rawValue)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // Shop Now button — brandPurple fill
                    Button { showDetail = true } label: {
                        HStack(spacing: 6) {
                            Text("Shop Now")
                                .font(.subheadline).fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(
                            LinearGradient(colors: [.brandPurple, .brandTeal],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(14)
                        .shadow(color: Color.brandPurple.opacity(0.35), radius: 8, y: 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 8)

                // ── Floating ring photo ──
                ZStack {
                    // Ambient glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [selectedColor.glowColor.opacity(0.45), .clear],
                                center: .center, startRadius: 0, endRadius: 70
                            )
                        )
                        .frame(width: 150, height: 150)
                        .blur(radius: 12)

                    Image(selectedColor.frontPhotoName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .shadow(color: selectedColor.glowColor.opacity(0.5), radius: 20, x: 0, y: 10)
                        .offset(y: floatUp ? -6 : 6)
                        .animation(
                            .easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                            value: floatUp
                        )
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedColor)
                .onAppear { floatUp = true }
            }
            .padding(.horizontal, 20).padding(.vertical, 22)
        }
        .frame(height: 265)
        .padding(.horizontal)
        .sheet(isPresented: $showDetail) {
            ImmersiveRingProductView(product: product, preselectedColor: selectedColor)
                .environment(store)
        }
    }
}

// MARK: - Product Card

struct ProductCard2: View {
    @Environment(HealthStore.self) var store
    let product: Product
    let onTap  : () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                // Icon / image area
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: product.color).opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: product.color).opacity(0.05),
                                            Color(hex: product.color).opacity(0.18)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .frame(height: 140)
                        .overlay(
                            Group {
                                if product.isRing, let firstColor = product.availableColors.first {
                                    Image(firstColor.frontPhotoName)
                                        .resizable()
                                        .scaledToFit()
                                        .padding(12)
                                } else {
                                    VStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: product.color).opacity(0.15))
                                                .frame(width: 72, height: 72)
                                            Image(systemName: product.icon)
                                                .font(.system(size: 32, weight: .medium))
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        colors: [Color(hex: product.color), Color(hex: product.color).opacity(0.7)],
                                                        startPoint: .top, endPoint: .bottom
                                                    )
                                                )
                                                .shadow(color: Color(hex: product.color).opacity(0.3), radius: 4, y: 2)
                                        }
                                        // Star rating
                                        HStack(spacing: 2) {
                                            ForEach(0..<5) { i in
                                                Image(systemName: Double(i) < product.rating ? "star.fill" : "star")
                                                    .font(.system(size: 8))
                                                    .foregroundColor(.brandAmber)
                                            }
                                            Text("(\(product.reviews))")
                                                .font(.system(size: 8))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        )
                    // Badge
                    if product.isBestSeller {
                        Text("⭐ Best")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Color.brandAmber)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                            .padding(6)
                    } else if product.isNew {
                        Text("NEW")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Color.brandTeal)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                            .padding(6)
                    }
                    // In-cart indicator
                    if store.isInCart(product) {
                        Circle()
                            .fill(Color.brandGreen)
                            .frame(width: 16, height: 16)
                            .overlay(Image(systemName: "checkmark").font(.system(size: 8)).foregroundColor(.white))
                            .offset(x: -6, y: 6)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }
                }

                Text(product.name)
                    .font(.subheadline).fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundColor(.primary)

                // Price row
                HStack {
                    Text(product.priceString(currencyCode: store.userCurrency))
                        .font(.headline).foregroundColor(.brandPurple)
                    if product.originalPrice > product.price {
                        Text(product.originalPriceString(currencyCode: store.userCurrency))
                            .font(.caption).strikethrough().foregroundColor(.secondary)
                    }
                    Spacer()
                }

                // Colour dots for ring
                if !product.availableColors.isEmpty {
                    HStack(spacing: 5) {
                        ForEach(product.availableColors, id: \.self) { c in
                            Circle().fill(c.color).frame(width: 10, height: 10)
                        }
                    }
                }
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
            )
            .cornerRadius(18)
            .shadow(color: Color(hex: product.color).opacity(0.12), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Product Detail Sheet

struct ProductDetailView2: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    let product: Product
    var preselectedColor: RingColor? = nil

    @State private var selectedColor : RingColor = .black
    @State private var selectedSize  : RingSize  = .size8
    @State private var quantity      = 1
    @State private var isGift        = false
    @State private var giftMessage   = ""
    @State private var addSubscription: SubscriptionPlan? = nil
    @State private var showPayment   = false
    @State private var addedToCart   = false
    @State private var showAddress   = false

    var subscriptionAddOnPrice: Double {
        guard let plan = addSubscription else { return 0 }
        return plan.basePriceGBP * 12 // yearly price
    }
    var totalPrice: Double { (product.price * Double(quantity)) + subscriptionAddOnPrice }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {

                    // ── Product hero image ──
                    productHeroImage

                    VStack(alignment: .leading, spacing: 16) {

                        // Name + price
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(product.name)
                                    .font(.title2).fontWeight(.bold)
                                if !product.sizeName.isEmpty {
                                    Text("Size: \(product.sizeName)")
                                        .font(.caption).foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(product.priceString(currencyCode: store.userCurrency))
                                    .font(.title).fontWeight(.bold).foregroundColor(.brandPurple)
                                if product.originalPrice > product.price {
                                    Text(product.originalPriceString(currencyCode: store.userCurrency))
                                        .font(.caption).strikethrough().foregroundColor(.secondary)
                                }
                            }
                        }

                        // Rating
                        HStack(spacing: 4) {
                            ForEach(0..<5, id: \.self) { i in
                                Image(systemName: i < Int(product.rating) ? "star.fill" : "star")
                                    .font(.caption).foregroundColor(.brandAmber)
                            }
                            Text("\(product.rating, specifier: "%.1f") (\(product.reviews) reviews)")
                                .font(.caption).foregroundColor(.secondary)
                        }

                        Divider()

                        // Colour picker (only for ring)
                        if !product.availableColors.isEmpty {
                            colourPicker
                        }

                        // Ring size picker
                        if product.isRing {
                            sizePicker
                        }

                        // Quantity
                        quantitySection

                        Divider()

                        // Gift option
                        giftSection

                        // Subscription add-on
                        if product.isRing {
                            subscriptionAddOnSection
                        }

                        Divider()

                        // Delivery address
                        deliveryAddressSection

                        Divider()

                        // Description
                        Text("About this product")
                            .font(.headline)
                        Text(product.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)

                        // Ring features
                        if product.isRing {
                            ringFeaturesGrid
                        }

                        Divider()

                        // Action buttons
                        actionButtons
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(product.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showPayment) {
            PaymentSheetView(
                title: product.name,
                subtitle: product.isRing ? "\(selectedColor.rawValue) · Size \(selectedSize.shortLabel)" : "Qty: \(quantity)",
                amountGBP: totalPrice
            ) { intentId, method in
                // Immediate Buy — bypass cart
                let item = CartItem(productID: product.id, name: product.name,
                                    price: product.price, icon: product.icon, color: product.color,
                                    quantity: quantity,
                                    selectedColor: product.isRing ? selectedColor : nil,
                                    selectedSize: product.isRing ? selectedSize : nil,
                                    sku: product.isRing ? "RING-X3B-\(selectedColor.rawValue.uppercased())-S\(selectedSize.shortLabel)" : "",
                                    isGift: isGift,
                                    giftMessage: giftMessage,
                                    addSubscription: addSubscription)
                store.cartItems = [item]
                store.placeOrder(paymentMethod: method, paymentIntentId: intentId)
                showPayment = false
                dismiss()
            } onCancel: {
                showPayment = false
            }
        }
        .onAppear {
            if let c = preselectedColor { selectedColor = c }
            else if let first = product.availableColors.first { selectedColor = first }
        }
    }

    // MARK: Hero Image
    var productHeroImage: some View {
        ZStack {
            Rectangle()
                .fill(LinearGradient(
                    colors: [Color(hex: product.color).opacity(0.15), Color(hex: product.color).opacity(0.05)],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(height: 220)

            if product.isRing {
                ZStack {
                    // Glow behind photo
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [selectedColor.glowColor.opacity(0.28), .clear],
                                center: .center, startRadius: 0, endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .blur(radius: 8)

                    Image(selectedColor.frontPhotoName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                        .shadow(color: selectedColor.glowColor.opacity(0.4), radius: 18, x: 0, y: 8)
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: selectedColor)
            } else {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: product.color).opacity(0.2), .clear],
                                center: .center, startRadius: 0, endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .blur(radius: 8)
                    Circle()
                        .fill(Color(hex: product.color).opacity(0.12))
                        .frame(width: 120, height: 120)
                    Image(systemName: product.icon)
                        .font(.system(size: 52, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: product.color), Color(hex: product.color).opacity(0.6)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .shadow(color: Color(hex: product.color).opacity(0.3), radius: 8, y: 4)
                }
            }
        }
    }

    // MARK: Colour Picker
    var colourPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Colour").font(.headline)
                Spacer()
                Text(selectedColor.rawValue)
                    .font(.subheadline)
                    .foregroundColor(selectedColor.color)
                    .fontWeight(.semibold)
            }
            HStack(spacing: 16) {
                ForEach(product.availableColors, id: \.self) { col in
                    Button {
                        withAnimation(.spring(response: 0.3)) { selectedColor = col }
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(col.color)
                                    .frame(width: 44, height: 44)
                                    .shadow(color: col.color.opacity(0.4), radius: 6)
                                if selectedColor == col {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                        .frame(width: 38, height: 38)
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                            }
                            Text(col.rawValue)
                                .font(.caption2)
                                .foregroundColor(selectedColor == col ? .primary : .secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: Size Picker
    var sizePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ring Size").font(.headline)
                Spacer()
                Text(selectedSize.rawValue)
                    .font(.subheadline).foregroundColor(.brandPurple)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(RingSize.allCases, id: \.self) { size in
                        Button {
                            withAnimation(.spring(response: 0.3)) { selectedSize = size }
                        } label: {
                            Text(size.shortLabel)
                                .font(.subheadline).fontWeight(.semibold)
                                .frame(width: 44, height: 44)
                                .background(selectedSize == size ? Color.brandPurple : Color(.systemGray6))
                                .foregroundColor(selectedSize == size ? .white : .primary)
                                .clipShape(Circle())
                        }
                    }
                }
            }
            Text("Not sure? Order our free ring sizer at bodysenseai.co.uk/sizer")
                .font(.caption2).foregroundColor(.secondary)
        }
    }

    // MARK: Gift Section
    var giftSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $isGift) {
                Label("This is a gift", systemImage: "gift.fill")
                    .font(.subheadline).fontWeight(.medium)
            }
            .tint(.brandPurple)

            if isGift {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gift Message (optional)")
                        .font(.caption).foregroundColor(.secondary)
                    TextField("Happy birthday! Enjoy your new BodySense Ring…", text: $giftMessage, axis: .vertical)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .lineLimit(3)
                    Text("A printed gift card with your message will be included.")
                        .font(.caption2).foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: Subscription Add-On
    var subscriptionAddOnSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Subscription").font(.headline)
            Text("Bundle a yearly subscription with your ring purchase")
                .font(.caption).foregroundColor(.secondary)

            ForEach([SubscriptionPlan.pro, .premium], id: \.self) { plan in
                Button {
                    withAnimation {
                        addSubscription = addSubscription == plan ? nil : plan
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: plan.icon)
                            .font(.title3).foregroundColor(plan.color)
                            .frame(width: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(plan.rawValue) — 1 Year")
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Text("\(CurrencyService.format(plan.basePriceGBP * 12, currencyCode: store.userCurrency))/year")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: addSubscription == plan ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(addSubscription == plan ? plan.color : .secondary)
                    }
                    .padding(12)
                    .background(
                        addSubscription == plan ?
                            AnyView(RoundedRectangle(cornerRadius: 12).fill(plan.color.opacity(0.08))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(plan.color, lineWidth: 1.5))) :
                            AnyView(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                    )
                }
            }

            if isGift && addSubscription != nil {
                HStack(spacing: 6) {
                    Image(systemName: "key.fill").foregroundColor(.brandAmber)
                    Text("A gift code will be generated for the recipient to redeem")
                        .font(.caption2).foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: Delivery Address
    var deliveryAddressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation { showAddress.toggle() }
            } label: {
                HStack {
                    Label("Delivery Address", systemImage: "shippingbox.fill")
                        .font(.headline)
                    Spacer()
                    Image(systemName: showAddress ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.primary)

            if showAddress {
                VStack(spacing: 12) {
                    addressField("Full Name", text: Binding(
                        get: { store.deliveryAddress.fullName },
                        set: { store.deliveryAddress.fullName = $0 }
                    ))
                    addressField("Address Line 1", text: Binding(
                        get: { store.deliveryAddress.addressLine1 },
                        set: { store.deliveryAddress.addressLine1 = $0 }
                    ))
                    addressField("Address Line 2 (optional)", text: Binding(
                        get: { store.deliveryAddress.addressLine2 },
                        set: { store.deliveryAddress.addressLine2 = $0 }
                    ))
                    HStack(spacing: 12) {
                        addressField("City", text: Binding(
                            get: { store.deliveryAddress.city },
                            set: { store.deliveryAddress.city = $0 }
                        ))
                        addressField("Postcode", text: Binding(
                            get: { store.deliveryAddress.postcode },
                            set: { store.deliveryAddress.postcode = $0 }
                        ))
                    }
                    addressField("Phone Number", text: Binding(
                        get: { store.deliveryAddress.phone },
                        set: { store.deliveryAddress.phone = $0 }
                    ))
                }
            } else if store.deliveryAddress.isComplete {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.brandGreen)
                    Text("\(store.deliveryAddress.fullName), \(store.deliveryAddress.postcode)")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
        }
    }

    func addressField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .font(.subheadline)
    }

    // MARK: Quantity
    var quantitySection: some View {
        HStack {
            Text("Quantity").font(.headline)
            Spacer()
            HStack(spacing: 16) {
                Button {
                    if quantity > 1 { quantity -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2).foregroundColor(quantity > 1 ? .brandPurple : .gray)
                }
                Text("\(quantity)")
                    .font(.headline)
                    .frame(width: 32)
                Button {
                    quantity += 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2).foregroundColor(.brandPurple)
                }
            }
        }
    }

    // MARK: Ring Features
    var ringFeaturesGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Features").font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                featureTag("SpO2 Monitoring", icon: "lungs.fill")
                featureTag("Sleep Apnea Detection", icon: "bed.double.fill")
                featureTag("HRV & Heart Rate", icon: "waveform.path.ecg")
                featureTag("Skin Temperature", icon: "thermometer.medium")
                featureTag("Stress Tracking", icon: "brain.head.profile")
                featureTag("Menstrual Tracking", icon: "calendar.circle.fill")
                featureTag("IP68 Waterproof", icon: "drop.fill")
                featureTag("7–10 Day Battery", icon: "battery.100percent")
            }
        }
    }

    func featureTag(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.brandTeal)
            Text(title)
                .font(.caption)
                .lineLimit(2)
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.brandTeal.opacity(0.08))
        .cornerRadius(10)
    }

    // MARK: Action Buttons
    var actionButtons: some View {
        VStack(spacing: 12) {
            // Buy Now (Apple Pay or Card)
            Button { showPayment = true } label: {
                HStack {
                    Image(systemName: "lock.fill")
                    Text("Buy Now — \(CurrencyService.format(totalPrice, currencyCode: store.userCurrency))")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.brandPurple)
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: .brandPurple.opacity(0.3), radius: 8, y: 4)
            }

            // Price breakdown if subscription add-on
            if addSubscription != nil {
                VStack(spacing: 4) {
                    HStack {
                        Text("\(product.name) × \(quantity)")
                        Spacer()
                        Text(CurrencyService.format(product.price * Double(quantity), currencyCode: store.userCurrency))
                    }
                    .font(.caption).foregroundColor(.secondary)
                    if let plan = addSubscription {
                        HStack {
                            Text("\(plan.rawValue) — 1 Year")
                            Spacer()
                            Text(CurrencyService.format(plan.basePriceGBP * 12, currencyCode: store.userCurrency))
                        }
                        .font(.caption).foregroundColor(.secondary)
                    }
                }
            }

            // Add to Cart
            Button {
                let item = CartItem(productID: product.id, name: product.name,
                                    price: product.price, icon: product.icon, color: product.color,
                                    quantity: quantity,
                                    selectedColor: product.isRing ? selectedColor : nil,
                                    selectedSize: product.isRing ? selectedSize : nil,
                                    sku: product.isRing ? "RING-X3B-\(selectedColor.rawValue.uppercased())-S\(selectedSize.shortLabel)" : "",
                                    isGift: isGift,
                                    giftMessage: giftMessage,
                                    addSubscription: addSubscription)
                if let idx = store.cartItems.firstIndex(where: { $0.productID == product.id }) {
                    store.cartItems[idx].quantity += quantity
                } else {
                    store.cartItems.append(item)
                }
                store.save()
                withAnimation { addedToCart = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { addedToCart = false }
            } label: {
                Label(addedToCart ? "Added to Bag ✓" : "Add to Bag",
                      systemImage: addedToCart ? "checkmark.circle.fill" : "bag.badge.plus")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(addedToCart ? Color.brandGreen : Color.brandTeal.opacity(0.12))
                    .foregroundColor(addedToCart ? .white : .brandTeal)
                    .cornerRadius(16)
            }

            // Security note
            HStack(spacing: 16) {
                Label("Secure", systemImage: "lock.shield.fill")
                Label("Apple Pay", systemImage: "apple.logo")
                Label("1yr Warranty", systemImage: "checkmark.seal.fill")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
    }
}

// MARK: - Cart & Checkout

struct CartCheckoutView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var showPayment = false

    var freeShipping: Bool { store.cartTotal >= 100 }
    var shippingCost: Double { freeShipping ? 0 : 4.99 }
    var grandTotal: Double { store.cartTotal + shippingCost }

    var body: some View {
        NavigationView {
            Group {
            if store.cartItems.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "bag").font(.system(size: 64)).foregroundColor(.secondary.opacity(0.3))
                    Text("Your bag is empty").font(.title3).fontWeight(.semibold)
                    Text("Browse the shop to add products.").foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List {
                    Section("Items (\(store.cartCount))") {
                        ForEach(store.cartItems) { item in
                            CartItemRow2(item: item)
                        }
                        .onDelete { idx in
                            store.cartItems.remove(atOffsets: idx)
                            store.save()
                        }
                    }

                    Section("Order Summary") {
                        HStack { Text("Subtotal"); Spacer(); Text(CurrencyService.format(store.cartTotal, currencyCode: store.userCurrency)) }
                        HStack {
                            Text("Shipping")
                            Spacer()
                            if freeShipping {
                                Text("FREE").foregroundColor(.brandGreen).fontWeight(.semibold)
                            } else {
                                Text(CurrencyService.format(shippingCost, currencyCode: store.userCurrency))
                            }
                        }
                        if !freeShipping {
                            Text("Add \(CurrencyService.format(100 - store.cartTotal, currencyCode: store.userCurrency)) more for free shipping")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }

                    Section {
                        HStack {
                            Text("Total").fontWeight(.bold)
                            Spacer()
                            Text(CurrencyService.format(grandTotal, currencyCode: store.userCurrency))
                                .fontWeight(.bold).foregroundColor(.brandPurple)
                        }
                    }

                    Section {
                        // Apple Pay
                        if StripeManager.shared.canMakeApplePayPayments {
                            ApplePayButton {
                                Task {
                                    let result = await StripeManager.shared.simulatePayment(
                                        amountGBP: grandTotal, method: "Apple Pay"
                                    )
                                    if case .success(let id, let method) = result {
                                        store.placeOrder(paymentMethod: method, paymentIntentId: id)
                                        dismiss()
                                    }
                                }
                            }
                            .frame(height: 50)
                            .cornerRadius(12)
                        }

                        // Card / other
                        Button { showPayment = true } label: {
                            Label("Pay with Card or Other", systemImage: "creditcard.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.brandPurple)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .listStyle(.insetGrouped)
            }
            }
            .navigationTitle("My Bag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showPayment) {
            PaymentSheetView(
                title: "BodySense Order",
                subtitle: "\(store.cartCount) item(s)",
                amountGBP: grandTotal
            ) { intentId, method in
                store.placeOrder(paymentMethod: method, paymentIntentId: intentId)
                showPayment = false
                dismiss()
            } onCancel: {
                showPayment = false
            }
        }
    }
}

// MARK: - Cart Item Row

struct CartItemRow2: View {
    @Environment(HealthStore.self) var store
    let item: CartItem

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: item.color).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: item.icon)
                    .foregroundColor(Color(hex: item.color))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name).font(.subheadline).fontWeight(.medium)
                HStack(spacing: 6) {
                    if let col = item.selectedColor {
                        Text(col.rawValue).font(.caption).foregroundColor(.secondary)
                    }
                    if let size = item.selectedSize {
                        Text("Size \(size.shortLabel)").font(.caption).foregroundColor(.secondary)
                    }
                }
                if item.isGift {
                    HStack(spacing: 4) {
                        Image(systemName: "gift.fill").font(.caption2).foregroundColor(.brandPurple)
                        Text("Gift").font(.caption2).foregroundColor(.brandPurple)
                    }
                }
                if let plan = item.addSubscription {
                    Text("+ \(plan.rawValue) 1yr").font(.caption2).foregroundColor(.brandTeal)
                }
                Text("\(CurrencyService.format(item.price, currencyCode: store.userCurrency)) each")
                    .font(.caption).foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                Button {
                    store.decreaseCartItem(item)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.secondary)
                }
                Text("\(item.quantity)")
                    .font(.headline).frame(width: 24)
                Button {
                    if let idx = store.cartItems.firstIndex(where: { $0.id == item.id }) {
                        store.cartItems[idx].quantity += 1
                        store.save()
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.brandPurple)
                }
            }
        }
    }
}

// MARK: - Subscriptions Tab

struct SubscriptionsTab: View {
    @Environment(HealthStore.self) var store
    @State private var showPayment   = false
    @State private var selectedPlan  : SubscriptionPlan = .pro
    @State private var isYearly      = false
    @State private var showGiftPurchase = false
    @State private var showRedeemCode   = false
    @State private var redeemInput      = ""
    @State private var redeemResult     : Bool? = nil
    @State private var giftPlan         : SubscriptionPlan = .pro
    @State private var giftQuantity     = 1
    @State private var showGiftPayment  = false
    @State private var generatedCodes   : [String] = []
    @State private var copiedCode       : String? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Header
                VStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.brandAmber)
                    Text("Unlock Premium Features")
                        .font(.title2).fontWeight(.bold)
                    Text("Everyone gets the free tier. Upgrade for advanced health insights.")
                        .font(.subheadline).foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 8)

                // Monthly / Yearly toggle
                HStack(spacing: 0) {
                    Button {
                        withAnimation { isYearly = false }
                    } label: {
                        Text("Monthly")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(isYearly ? Color.clear : Color.brandPurple)
                            .foregroundColor(isYearly ? .brandPurple : .white)
                    }
                    Button {
                        withAnimation { isYearly = true }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Yearly")
                            Text("Save 17%").font(.caption2).fontWeight(.bold)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.brandGreen)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(isYearly ? Color.brandPurple : Color.clear)
                        .foregroundColor(isYearly ? .white : .brandPurple)
                    }
                }
                .background(Color.brandPurple.opacity(0.1))
                .cornerRadius(12)

                // Plan cards
                ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                    SubscriptionCard(plan: plan, isCurrent: store.subscription == plan, isYearly: isYearly) {
                        if plan != .free {
                            selectedPlan = plan
                            showPayment = true
                        }
                    }
                }

                Divider().padding(.horizontal)

                // Gift a subscription
                VStack(alignment: .leading, spacing: 12) {
                    Label("Gift a Subscription", systemImage: "gift.fill")
                        .font(.headline)
                    Text("Buy a yearly subscription as a gift. A unique code is generated that anyone can redeem.")
                        .font(.caption).foregroundColor(.secondary)

                    Button { showGiftPurchase = true } label: {
                        Label("Buy Gift Subscription", systemImage: "gift.circle.fill")
                            .font(.subheadline).fontWeight(.semibold)
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.brandAmber.opacity(0.12))
                            .foregroundColor(.brandAmber)
                            .cornerRadius(14)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.06), radius: 8)

                // Redeem a code
                VStack(alignment: .leading, spacing: 12) {
                    Label("Redeem a Code", systemImage: "key.fill")
                        .font(.headline)
                    Text("Have a gift code? Enter it below to activate your subscription.")
                        .font(.caption).foregroundColor(.secondary)

                    HStack {
                        TextField("BS-GIFT-XXXXXX", text: $redeemInput)
                            .textInputAutocapitalization(.characters)
                            .font(.system(.body, design: .monospaced))
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        Button {
                            let success = store.redeemGiftCode(redeemInput.trimmingCharacters(in: .whitespaces))
                            withAnimation { redeemResult = success }
                        } label: {
                            Text("Redeem")
                                .font(.subheadline).fontWeight(.bold)
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                .background(Color.brandPurple)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(redeemInput.count < 6)
                    }

                    if let result = redeemResult {
                        HStack(spacing: 6) {
                            Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                            Text(result ? "Code redeemed! Your subscription is now active." : "Invalid or already used code.")
                        }
                        .font(.caption).fontWeight(.medium)
                        .foregroundColor(result ? .brandGreen : .brandCoral)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.06), radius: 8)

                // My gift codes
                if !store.giftCodes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("My Gift Codes").font(.headline)
                        ForEach(store.giftCodes) { gc in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(gc.code)
                                        .font(.system(.caption, design: .monospaced)).fontWeight(.bold)
                                    Text("\(gc.plan.rawValue) · \(gc.durationMonths) months")
                                        .font(.caption2).foregroundColor(.secondary)
                                }
                                Spacer()
                                if gc.isRedeemed {
                                    Label("Redeemed", systemImage: "checkmark.circle.fill")
                                        .font(.caption2).foregroundColor(.brandGreen)
                                } else {
                                    Text("Active")
                                        .font(.caption2).fontWeight(.semibold)
                                        .padding(.horizontal, 8).padding(.vertical, 3)
                                        .background(Color.brandAmber.opacity(0.15))
                                        .foregroundColor(.brandAmber)
                                        .cornerRadius(6)
                                }
                            }
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.06), radius: 8)
                }

                // Comparison
                subscriptionComparisonTable

                Spacer(minLength: 32)
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showPayment) {
            PaymentSheetView(
                title: "\(selectedPlan.rawValue) Subscription",
                subtitle: isYearly ? "Yearly — save 17%" : "Monthly — cancel anytime",
                amountGBP: isYearly ? selectedPlan.basePriceGBP * 10 : selectedPlan.basePriceGBP
            ) { intentId, method in
                store.subscription = selectedPlan
                store.save()
                showPayment = false
            } onCancel: {
                showPayment = false
            }
        }
        .sheet(isPresented: $showGiftPurchase) {
            giftPurchaseSheet
        }
    }

    var giftPurchaseSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 50)).foregroundColor(.brandAmber)
                Text("Gift a Subscription")
                    .font(.title2).fontWeight(.bold)
                Text("Choose a plan and how many gift codes to generate.")
                    .font(.subheadline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                // Plan selection
                VStack(spacing: 12) {
                    ForEach([SubscriptionPlan.pro, .premium], id: \.self) { plan in
                        Button {
                            giftPlan = plan
                        } label: {
                            HStack {
                                Image(systemName: plan.icon).foregroundColor(plan.color)
                                Text(plan.rawValue).fontWeight(.semibold)
                                Spacer()
                                Text("\(CurrencyService.format(plan.basePriceGBP * 12, currencyCode: store.userCurrency))/year")
                                    .foregroundColor(.secondary)
                                if giftPlan == plan {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(plan.color)
                                }
                            }
                            .padding()
                            .background(giftPlan == plan ? plan.color.opacity(0.08) : Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                giftPlan == plan ?
                                RoundedRectangle(cornerRadius: 12).stroke(plan.color, lineWidth: 1.5) :
                                RoundedRectangle(cornerRadius: 12).stroke(Color.clear)
                            )
                        }
                        .foregroundColor(.primary)
                    }
                }

                // Quantity
                HStack {
                    Text("Quantity").font(.headline)
                    Spacer()
                    HStack(spacing: 16) {
                        Button { if giftQuantity > 1 { giftQuantity -= 1 } } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2).foregroundColor(giftQuantity > 1 ? .brandPurple : .gray)
                        }
                        Text("\(giftQuantity)").font(.headline).frame(width: 32)
                        Button { giftQuantity += 1 } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2).foregroundColor(.brandPurple)
                        }
                    }
                }

                // Total
                HStack {
                    Text("Total").font(.headline)
                    Spacer()
                    Text(CurrencyService.format(giftPlan.basePriceGBP * 12 * Double(giftQuantity), currencyCode: store.userCurrency))
                        .font(.title2).fontWeight(.bold).foregroundColor(.brandPurple)
                }

                // Buy button
                Button {
                    showGiftPayment = true
                } label: {
                    Label("Purchase Gift Code\(giftQuantity > 1 ? "s" : "")", systemImage: "gift.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.brandAmber)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }

                // Show generated codes
                if !generatedCodes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Gift Codes:").font(.subheadline).fontWeight(.bold)
                        ForEach(generatedCodes, id: \.self) { code in
                            HStack {
                                Text(code)
                                    .font(.system(.body, design: .monospaced)).fontWeight(.bold)
                                Spacer()
                                Button {
                                    UIPasteboard.general.string = code
                                    withAnimation { copiedCode = code }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        if copiedCode == code { withAnimation { copiedCode = nil } }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: copiedCode == code ? "checkmark" : "doc.on.doc")
                                        if copiedCode == code {
                                            Text("Copied").font(.caption2)
                                        }
                                    }
                                    .foregroundColor(copiedCode == code ? .brandGreen : .brandTeal)
                                }
                            }
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        Text("Share these codes with your recipients. They can enter them in the Redeem section.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Gift Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showGiftPurchase = false }
                }
            }
            .sheet(isPresented: $showGiftPayment) {
                PaymentSheetView(
                    title: "Gift \(giftPlan.rawValue) ×\(giftQuantity)",
                    subtitle: "1-year gift subscription\(giftQuantity > 1 ? "s" : "")",
                    amountGBP: giftPlan.basePriceGBP * 12 * Double(giftQuantity)
                ) { intentId, method in
                    // Generate codes
                    var codes: [String] = []
                    for _ in 0..<giftQuantity {
                        let code = GiftCode.generateCode()
                        let gc = GiftCode(code: code, plan: giftPlan, durationMonths: 12)
                        store.giftCodes.append(gc)
                        codes.append(code)
                    }
                    store.save()
                    generatedCodes = codes
                    showGiftPayment = false
                } onCancel: {
                    showGiftPayment = false
                }
            }
        }
    }

    var subscriptionComparisonTable: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Feature Comparison").font(.headline)
            let features: [(String, String, String, String)] = [
                ("Basic health tracking",     "✓", "✓", "✓"),
                ("AI Health Coach",           "Limited", "✓", "✓"),
                ("Goals",                     "1",  "5",  "Unlimited"),
                ("Reports & Export",          "✗",  "✓",  "✓"),
                ("Doctor consultations",      "Pay-per", "Pay-per", "Unlimited"),
                ("Wearable sync",             "✗",  "✓",  "✓"),
                ("Family sharing (5 members)","✗",  "✗",  "✓"),
            ]
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Feature").font(.caption).fontWeight(.bold).frame(maxWidth: .infinity, alignment: .leading)
                    Text("Free").font(.caption).fontWeight(.bold).frame(width: 60, alignment: .center)
                    Text("Pro").font(.caption).fontWeight(.bold).foregroundColor(.brandTeal).frame(width: 60, alignment: .center)
                    Text("Premium").font(.caption).fontWeight(.bold).foregroundColor(.brandPurple).frame(width: 70, alignment: .center)
                }
                .padding(.vertical, 8).padding(.horizontal, 12)
                .background(Color(.systemGray6))

                ForEach(Array(features.enumerated()), id: \.offset) { idx, row in
                    HStack {
                        Text(row.0).font(.caption).frame(maxWidth: .infinity, alignment: .leading)
                        Text(row.1).font(.caption).frame(width: 60, alignment: .center).foregroundColor(.secondary)
                        Text(row.2).font(.caption).frame(width: 60, alignment: .center).foregroundColor(.brandTeal)
                        Text(row.3).font(.caption).frame(width: 70, alignment: .center).foregroundColor(.brandPurple)
                    }
                    .padding(.vertical, 8).padding(.horizontal, 12)
                    .background(idx % 2 == 0 ? Color(.systemBackground) : Color(.systemGray6).opacity(0.4))
                }
            }
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray5)))
        }
    }
}

// MARK: - Subscription Card

struct SubscriptionCard: View {
    let plan      : SubscriptionPlan
    let isCurrent : Bool
    var isYearly  : Bool = false
    let onSelect  : () -> Void

    @Environment(HealthStore.self) var store

    var displayPrice: String {
        if plan == .free { return plan.price }
        if isYearly {
            let yearly = plan.basePriceGBP * 10 // 2 months free
            return "\(CurrencyService.format(yearly, currencyCode: store.userCurrency))/year"
        }
        return plan.priceString(currencyCode: store.userCurrency)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: plan.icon)
                    .font(.title2)
                    .foregroundColor(plan.color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.rawValue).font(.headline)
                    Text(displayPrice).font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
                if plan == .pro {
                    Text("POPULAR").font(.caption2).fontWeight(.bold)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.brandTeal)
                        .foregroundColor(.white).cornerRadius(6)
                }
                if isCurrent {
                    Text("Current").font(.caption2).fontWeight(.bold)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.brandGreen.opacity(0.15))
                        .foregroundColor(.brandGreen).cornerRadius(6)
                }
            }

            ForEach(plan.features, id: \.self) { feature in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption).foregroundColor(plan.color)
                    Text(feature).font(.caption)
                }
            }

            if plan != .free && !isCurrent {
                Button(action: onSelect) {
                    Text("Subscribe — \(displayPrice)")
                        .font(.subheadline).fontWeight(.semibold)
                        .frame(maxWidth: .infinity).padding()
                        .background(plan.color)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(
            isCurrent ?
                AnyView(RoundedRectangle(cornerRadius: 16).fill(plan.color.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(plan.color, lineWidth: 2))) :
                AnyView(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.07), radius: 8))
        )
    }
}

// MARK: - Orders Tab

struct OrdersTab: View {
    @Environment(HealthStore.self) var store

    var body: some View {
        Group {
            if store.orders.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "shippingbox")
                        .font(.system(size: 60)).foregroundColor(.secondary.opacity(0.3))
                    Text("No Orders Yet").font(.title3).fontWeight(.semibold)
                    Text("Your orders will appear here after checkout.")
                        .font(.subheadline).foregroundColor(.secondary)
                        .multilineTextAlignment(.center).padding(.horizontal, 32)
                    Spacer()
                }
            } else {
                List(store.orders) { order in
                    OrderRowView(order: order)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
                .listStyle(.plain)
            }
        }
    }
}

// MARK: - Order Row

struct OrderRowView: View {
    @Environment(HealthStore.self) var store
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: order.status.icon)
                    .foregroundColor(order.status.color)
                Text(order.orderNumber).font(.subheadline).fontWeight(.semibold)
                Spacer()
                Text(CurrencyService.format(order.total, currencyCode: store.userCurrency))
                    .font(.headline).foregroundColor(.brandPurple)
            }

            HStack {
                Text(order.status.rawValue)
                    .font(.caption).fontWeight(.medium)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(order.status.color.opacity(0.15))
                    .foregroundColor(order.status.color)
                    .cornerRadius(6)
                Spacer()
                Text(order.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption).foregroundColor(.secondary)
            }

            ForEach(order.items) { item in
                HStack(spacing: 8) {
                    Image(systemName: item.icon)
                        .font(.caption)
                        .foregroundColor(Color(hex: item.color))
                    Text(item.name).font(.caption)
                    if let col = item.selectedColor {
                        Text("· \(col.rawValue)").font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("×\(item.quantity)").font(.caption).foregroundColor(.secondary)
                }
            }

            if let delivery = order.estimatedDelivery, order.status != .cancelled {
                HStack(spacing: 4) {
                    Image(systemName: "shippingbox.fill").font(.caption).foregroundColor(.brandTeal)
                    Text("Estimated delivery: \(delivery.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption).foregroundColor(.secondary)
                }
            }

            HStack {
                Text("via \(order.paymentMethod)").font(.caption2).foregroundColor(.secondary)
                Spacer()
                if order.status == .confirmed {
                    Button {
                        store.cancelOrder(order)
                    } label: {
                        Text("Cancel Order")
                            .font(.caption2).foregroundColor(.brandCoral)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6)
    }
}
