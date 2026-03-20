//
//  ImmersiveRingProductView.swift
//  body sense ai
//
//  Apple-style immersive product page for BodySense Ring X3B.
//  Scroll-driven 3D ring rotation, feature reveals, full specs & checkout.
//

import SwiftUI
import Combine

// MARK: - Entry Point

struct ImmersiveRingProductView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss)       var dismiss

    let product: Product
    var preselectedColor: RingColor? = nil

    // Ring animation
    @State private var ringRotation : Double  = 0.0
    @State private var floatPhase   : Double  = 0.0
    @State private var glowPulse    : Double  = 0.0

    // Selection
    @State private var selectedColor : RingColor = .silver
    @State private var selectedSize  : RingSize  = .size8
    @State private var quantity      = 1
    @State private var isGift        = false
    @State private var giftMessage   = ""
    @State private var addSubscription: SubscriptionPlan? = nil

    // Scroll & UI
    @State private var scrollY       : CGFloat = 0
    @State private var showPayment   = false
    @State private var buyNow        = false
    @State private var addedToCart   = false
    @State private var showSizeGuide = false
    @State private var showAddress   = false
    @State private var visibleSections: Set<Int> = []

    // Timers
    private let rotTimer   = Timer.publish(every: 0.018, on: .main, in: .common).autoconnect()
    private let floatTimer = Timer.publish(every: 0.022, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .top) {
            // ── Deep dark background ──
            Color(red: 0.04, green: 0.04, blue: 0.06)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                ZStack(alignment: .top) {
                    // Scroll-offset reader
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { scrollY = 0 }
                            .onChange(of: geo.frame(in: .global).minY) { _, newVal in
                                scrollY = -newVal
                            }
                    }
                    .frame(height: 0)

                    VStack(spacing: 0) {
                        heroSection
                        taglineSection
                        featuresSection
                        colorsSection
                        specsSection
                        orderSection
                        Spacer(minLength: 80)
                    }
                }
            }

            // ── Close button ──
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(.white.opacity(0.5), .white.opacity(0.1))
                }
                .padding(.trailing, 20)
                .padding(.top, 60)
            }
        }
        .ignoresSafeArea()
        .onReceive(rotTimer)   { _ in ringRotation += 0.008 }
        .onReceive(floatTimer) { _ in floatPhase    += 0.025; glowPulse += 0.018 }
        .onAppear {
            if let c = preselectedColor { selectedColor = c }
            else if let first = product.availableColors.first { selectedColor = first }
        }
        .sheet(isPresented: $showPayment) { paymentSheet }
        .sheet(isPresented: $showSizeGuide) { sizeGuideSheet }
    }

    // MARK: - Hero Section

    var heroSection: some View {
        ZStack {
            // Radial background glow
            RadialGradient(
                colors: [selectedColor.glowColor.opacity(0.25 + 0.08 * sin(glowPulse)), .clear],
                center: .center,
                startRadius: 10,
                endRadius: 260
            )
            .frame(height: 600)
            .offset(y: -scrollY * 0.3)

            VStack(spacing: 0) {
                Spacer().frame(height: 100)

                // ── Product Ring Photo (hero) ──
                ZStack {
                    // Glow bloom behind photo
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [selectedColor.glowColor.opacity(0.32 + 0.08 * sin(glowPulse)), .clear],
                                center: .center, startRadius: 0, endRadius: 110
                            )
                        )
                        .frame(width: 220, height: 220)
                        .blur(radius: 8)

                    Image(selectedColor.sidePhotoName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .shadow(color: selectedColor.glowColor.opacity(0.5), radius: 24, x: 0, y: 10)
                }
                .offset(y: CGFloat(sin(floatPhase) * 12) - scrollY * 0.18)
                .animation(.easeInOut(duration: 0.05), value: selectedColor)

                Spacer().frame(height: 40)

                // ── Title ──
                VStack(spacing: 10) {
                    Text("BodySense Ring")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    Text("X3B · Medical Grade")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .tracking(3)

                    Spacer().frame(height: 16)

                    // Price
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(product.priceString(currencyCode: store.userCurrency))
                            .font(.title.bold())
                            .foregroundStyle(.white)
                        if product.originalPrice > product.price {
                            Text(product.originalPriceString(currencyCode: store.userCurrency))
                                .font(.subheadline)
                                .strikethrough(color: .white.opacity(0.35))
                                .foregroundStyle(.white.opacity(0.35))
                        }
                    }

                    // Sale pill
                    let saving = Int(product.originalPrice - product.price)
                    Text("Save £\(saving) — Limited Sale")
                        .font(.caption).fontWeight(.semibold)
                        .padding(.horizontal, 14).padding(.vertical, 6)
                        .background(Color.orange.opacity(0.2))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.orange.opacity(0.4)))

                    Spacer().frame(height: 28)

                    // Rating
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { i in
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(Color(red:1, green:0.8, blue:0.2))
                        }
                        Text("4.9 · \(product.reviews) reviews")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    Spacer().frame(height: 32)

                    // Hero CTA row
                    HStack(spacing: 14) {
                        Button {
                            buyNow = false
                            showPayment = true
                        } label: {
                            Text("Order Now")
                                .font(.headline)
                                .frame(width: 150, height: 50)
                                .background(selectedColor.glowColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Button {
                            store.addToCart(product)
                            withAnimation { addedToCart = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { addedToCart = false }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: addedToCart ? "checkmark" : "bag.fill")
                                Text(addedToCart ? "Added!" : "Add to Bag")
                            }
                            .font(.headline)
                            .frame(width: 150, height: 50)
                            .background(.white.opacity(0.1))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.15)))
                        }
                    }
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

                Spacer().frame(height: 60)

                // Scroll hint
                VStack(spacing: 6) {
                    Image(systemName: "chevron.compact.down")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.25))
                    Text("Scroll to explore")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.2))
                        .tracking(2)
                }
                .opacity(scrollY < 50 ? 1 : 0)
                .animation(.easeOut, value: scrollY)
            }
        }
        .frame(minHeight: 750)
    }

    // MARK: - Tagline Section

    var taglineSection: some View {
        VStack(spacing: 24) {
            Divider().background(.white.opacity(0.08))

            VStack(spacing: 16) {
                Text("Worn differently.")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text("The X3B monitors 8 vital signs around the clock. No screen. No charging every night. Just intelligence, worn on your finger.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 28)
            }
            .padding(.vertical, 40)

            // 3 pillars
            HStack(spacing: 0) {
                ForEach(Array(pillars.enumerated()), id: \.offset) { idx, pillar in
                    VStack(spacing: 10) {
                        Image(systemName: pillar.icon)
                            .font(.title2)
                            .foregroundStyle(Color.brandPurple)
                        Text(pillar.title)
                            .font(.caption).fontWeight(.bold)
                            .foregroundStyle(.white)
                        Text(pillar.sub)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.45))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    if idx < pillars.count - 1 {
                        Divider().frame(height: 50).background(.white.opacity(0.1))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .background(Color(white: 0.06))
    }

    struct PillarItem { let icon: String; let title: String; let sub: String }
    var pillars: [PillarItem] {[
        PillarItem(icon: "drop.fill",   title: "IP68",       sub: "Waterproof\n50 m"),
        PillarItem(icon: "bolt.fill",   title: "7–10 Days",  sub: "Battery\nLife"),
        PillarItem(icon: "waveform",    title: "Medical",    sub: "Grade\nSensors"),
    ]}

    // MARK: - Features Section

    var featuresSection: some View {
        VStack(spacing: 0) {
            // Section header
            VStack(spacing: 12) {
                Text("Every reading.\nEvery moment.")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 56)

                Text("Eight health metrics. Continuous monitoring. No manual logging required.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Feature cards
            VStack(spacing: 16) {
                ForEach(Array(featureCards.enumerated()), id: \.offset) { i, card in
                    FeatureCard(
                        icon:     card.icon,
                        title:    card.title,
                        subtitle: card.subtitle,
                        metric:   card.metric,
                        unit:     card.unit,
                        color:    card.color,
                        scrollY:  scrollY,
                        index:    i
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 32)
        }
        .background(Color(white: 0.04))
    }

    var featureCards: [(icon: String, title: String, subtitle: String, metric: String, unit: String, color: Color)] {[
        ("heart.fill",             "Heart Rate & HRV",        "Continuous 24/7 monitoring with resting heart rate trends and recovery scores.", "72", "BPM", .pink),
        ("lungs.fill",             "Blood Oxygen (SpO₂)",     "Detect drops below 90% with alerts. Monitor overnight for sleep apnea risk.", "98", "%", .cyan),
        ("thermometer.medium",     "Skin Temperature",        "Track micro-variations that signal illness, ovulation, or stress before symptoms appear.", "36.5", "°C", .orange),
        ("moon.zzz.fill",          "Sleep Staging",           "Automatic REM, light, and deep sleep detection. HRV-based recovery scoring.", "7h 34m", "", .indigo),
        ("brain.head.profile",     "Stress Index",            "Photoplethysmography-derived HRV stress score updated every 5 minutes.", "Low", "", .green),
        ("drop.halffull",          "Glucose Risk Trend",      "Correlates HRV, sleep, and temperature to estimate metabolic health trends.", "Normal", "", .brandAmber),
        ("figure.walk",            "Activity & Steps",        "3-axis accelerometer for step counting, calorie burn, and workout detection.", "8,420", "steps", .brandTeal),
        ("chart.line.uptrend.xyaxis","Menstrual Cycle",       "BBT-based cycle prediction with fertile window and period forecasting.", "Day 14", "", .pink.opacity(0.8)),
    ]}

    // MARK: - Colors Section

    var colorsSection: some View {
        VStack(spacing: 32) {
            Divider().background(.white.opacity(0.08))

            VStack(spacing: 12) {
                Text("Three finishes.\nOne statement.")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("Aerospace-grade titanium. Hypoallergenic. Built to last.")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center).padding(.horizontal, 32)
            }
            .padding(.top, 48)

            // Large colour showcase — real product photo
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [selectedColor.glowColor.opacity(0.22), .clear],
                            center: .center, startRadius: 0, endRadius: 90
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 6)

                Image(selectedColor.frontPhotoName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .shadow(color: selectedColor.glowColor.opacity(0.4), radius: 18, x: 0, y: 8)
            }
            .offset(y: CGFloat(sin(floatPhase * 0.8) * 8))
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedColor)

            // Color name
            Text(selectedColor.rawValue)
                .font(.title2).fontWeight(.bold)
                .foregroundStyle(selectedColor.glowColor)
                .animation(.easeInOut(duration: 0.25), value: selectedColor)

            Text(selectedColor.finishDescription)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
                .animation(.easeInOut(duration: 0.25), value: selectedColor)

            // Color pills
            HStack(spacing: 24) {
                ForEach(RingColor.allCases, id: \.self) { col in
                    Button { withAnimation(.spring(response: 0.35)) { selectedColor = col } } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(col.swatch)
                                    .frame(width: 52, height: 52)
                                    .shadow(color: col.glowColor.opacity(0.5), radius: 12)
                                if selectedColor == col {
                                    Circle()
                                        .stroke(.white, lineWidth: 2.5)
                                        .frame(width: 46, height: 46)
                                    Image(systemName: "checkmark")
                                        .font(.caption).fontWeight(.bold)
                                        .foregroundStyle(.white)
                                }
                            }
                            Text(col.rawValue)
                                .font(.caption2)
                                .foregroundStyle(selectedColor == col ? .white : .white.opacity(0.4))
                        }
                    }
                }
            }
            .padding(.bottom, 48)
        }
        .background(Color(white: 0.05))
    }

    // MARK: - Specs Section

    var specsSection: some View {
        VStack(spacing: 0) {
            Divider().background(.white.opacity(0.08))

            VStack(alignment: .leading, spacing: 28) {
                Text("Technical Specs")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .padding(.top, 48)

                ForEach(Array(specGroups.enumerated()), id: \.offset) { _, group in
                    VStack(alignment: .leading, spacing: 0) {
                        Text(group.title)
                            .font(.caption).fontWeight(.bold)
                            .foregroundStyle(.white.opacity(0.3))
                            .tracking(2)
                            .padding(.bottom, 8)

                        VStack(spacing: 0) {
                            ForEach(Array(group.rows.enumerated()), id: \.offset) { i, row in
                                HStack {
                                    Text(row.label)
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.6))
                                    Spacer()
                                    Text(row.detail)
                                        .font(.subheadline).fontWeight(.medium)
                                        .foregroundStyle(.white)
                                        .multilineTextAlignment(.trailing)
                                }
                                .padding(.vertical, 13)
                                .padding(.horizontal, 16)
                                .background(i % 2 == 0 ? Color.white.opacity(0.04) : Color.clear)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.08)))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
        .background(Color(white: 0.04))
    }

    struct SpecRow: Identifiable { let id = UUID(); let label: String; let detail: String }
    struct SpecGroup: Identifiable { let id = UUID(); let title: String; let rows: [SpecRow] }

    var specGroups: [SpecGroup] {[
        SpecGroup(title: "DESIGN", rows: [
            SpecRow(label: "Material",          detail: "Aerospace-grade titanium"),
            SpecRow(label: "Finish",            detail: "Silver · Black · Gold PVD"),
            SpecRow(label: "Width",             detail: "8mm"),
            SpecRow(label: "Weight",            detail: "4g"),
            SpecRow(label: "Water Resistance",  detail: "IP68 (50 m, 1 hour)"),
        ]),
        SpecGroup(title: "SENSORS", rows: [
            SpecRow(label: "Heart Rate",        detail: "PPG optical (green + IR)"),
            SpecRow(label: "Blood Oxygen",      detail: "Red + IR LEDs, ±2% accuracy"),
            SpecRow(label: "Temperature",       detail: "Infrared + NTC, ±0.1°C"),
            SpecRow(label: "Accelerometer",     detail: "3-axis 50 Hz"),
            SpecRow(label: "Gyroscope",         detail: "Yes — tap gestures"),
        ]),
        SpecGroup(title: "PERFORMANCE", rows: [
            SpecRow(label: "Battery Life",      detail: "7–10 days typical"),
            SpecRow(label: "Charge Time",       detail: "Under 2 hours (magnetic)"),
            SpecRow(label: "Chip",              detail: "Nordic nRF52840"),
            SpecRow(label: "Bluetooth",         detail: "BLE 5.3 · 10m range"),
        ]),
        SpecGroup(title: "COMPATIBILITY", rows: [
            SpecRow(label: "iOS",               detail: "iOS 17.0 or later"),
            SpecRow(label: "HealthKit",         detail: "Full sync"),
            SpecRow(label: "App",               detail: "BodySense AI"),
            SpecRow(label: "Sizes Available",   detail: "5–13 (use sizer tool)"),
        ]),
    ]}

    // MARK: - Order Section

    var orderSection: some View {
        VStack(spacing: 0) {
            Divider().background(.white.opacity(0.08))

            VStack(alignment: .leading, spacing: 24) {

                Text("Configure your ring")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .padding(.top, 48)

                // ── Colour ──
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Colour").font(.headline).foregroundStyle(.white)
                        Spacer()
                        Text(selectedColor.rawValue).font(.subheadline)
                            .foregroundStyle(selectedColor.glowColor).fontWeight(.semibold)
                    }
                    HStack(spacing: 16) {
                        ForEach(product.availableColors, id: \.self) { col in
                            Button { withAnimation(.spring(response: 0.3)) { selectedColor = col } } label: {
                                ZStack {
                                    Circle().fill(col.swatch).frame(width: 44, height: 44)
                                        .shadow(color: col.glowColor.opacity(0.4), radius: 8)
                                    if selectedColor == col {
                                        Circle().stroke(Color.white, lineWidth: 2.5).frame(width: 38, height: 38)
                                        Image(systemName: "checkmark").font(.caption2).fontWeight(.bold).foregroundStyle(.white)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(18)
                .background(.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1)))

                // ── Size ──
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Ring Size").font(.headline).foregroundStyle(.white)
                        Spacer()
                        Button { showSizeGuide = true } label: {
                            Text("Size guide")
                                .font(.caption).foregroundStyle(.blue)
                        }
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(RingSize.allCases, id: \.self) { size in
                                Button { withAnimation(.spring(response: 0.3)) { selectedSize = size } } label: {
                                    VStack(spacing: 2) {
                                        Text(size.shortLabel)
                                            .font(.subheadline).fontWeight(.semibold)
                                            .frame(width: 46, height: 46)
                                            .background(selectedSize == size ? selectedColor.glowColor : Color.white.opacity(0.08))
                                            .foregroundStyle(.white)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(.white.opacity(selectedSize == size ? 0 : 0.12)))
                                    }
                                }
                            }
                        }
                    }
                    Text("Not sure? Order our free ring sizer at bodysenseai.co.uk/sizer")
                        .font(.caption2).foregroundStyle(.white.opacity(0.35))
                }
                .padding(18)
                .background(.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1)))

                // ── Quantity ──
                HStack {
                    Text("Quantity").font(.headline).foregroundStyle(.white)
                    Spacer()
                    HStack(spacing: 18) {
                        Button { if quantity > 1 { quantity -= 1 } } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(quantity > 1 ? .white : .white.opacity(0.3))
                        }
                        Text("\(quantity)").font(.title3).fontWeight(.bold).foregroundStyle(.white)
                            .frame(width: 28)
                        Button { quantity += 1 } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2).foregroundStyle(.white)
                        }
                    }
                }
                .padding(18)
                .background(.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1)))

                // ── Gift toggle ──
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $isGift.animation()) {
                        Label("This is a gift", systemImage: "gift.fill")
                            .font(.headline).foregroundStyle(.white)
                    }
                    .tint(selectedColor.glowColor)

                    if isGift {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gift Message (optional)").font(.caption).foregroundStyle(.white.opacity(0.4))
                            TextField("Write a message for the recipient…", text: $giftMessage, axis: .vertical)
                                .padding(12).background(.white.opacity(0.08))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .lineLimit(3...5)
                            Text("A premium printed gift card will be included.")
                                .font(.caption2).foregroundStyle(.white.opacity(0.35))
                        }
                    }
                }
                .padding(18)
                .background(.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1)))

                // ── Subscription bundle ──
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bundle a Subscription").font(.headline).foregroundStyle(.white)
                        Text("Unlock all AI features with your ring purchase")
                            .font(.caption).foregroundStyle(.white.opacity(0.4))
                    }
                    ForEach([SubscriptionPlan.pro, .premium], id: \.self) { plan in
                        Button { withAnimation { addSubscription = addSubscription == plan ? nil : plan } } label: {
                            HStack(spacing: 12) {
                                Image(systemName: plan.icon).font(.title3).foregroundStyle(plan.color).frame(width: 36)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(plan.rawValue) — 1 Year").font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
                                    Text("+\(CurrencyService.format(plan.basePriceGBP * 12, currencyCode: store.userCurrency))/year")
                                        .font(.caption).foregroundStyle(.white.opacity(0.5))
                                }
                                Spacer()
                                Image(systemName: addSubscription == plan ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(addSubscription == plan ? plan.color : .white.opacity(0.3))
                            }
                            .padding(14)
                            .background(addSubscription == plan ? plan.color.opacity(0.12) : Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(
                                addSubscription == plan ? plan.color.opacity(0.5) : Color.white.opacity(0.08)
                            ))
                        }
                    }
                }
                .padding(18)
                .background(.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1)))

                // ── Delivery ──
                VStack(alignment: .leading, spacing: 12) {
                    Button { withAnimation { showAddress.toggle() } } label: {
                        HStack {
                            Label("Delivery Address", systemImage: "shippingbox.fill")
                                .font(.headline).foregroundStyle(.white)
                            Spacer()
                            Image(systemName: showAddress ? "chevron.up" : "chevron.down")
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                    if showAddress {
                        VStack(spacing: 10) {
                            darkField("Full Name",            text: Binding(get: { store.deliveryAddress.fullName },     set: { store.deliveryAddress.fullName = $0 }))
                            darkField("Address Line 1",       text: Binding(get: { store.deliveryAddress.addressLine1 }, set: { store.deliveryAddress.addressLine1 = $0 }))
                            darkField("Address Line 2",       text: Binding(get: { store.deliveryAddress.addressLine2 }, set: { store.deliveryAddress.addressLine2 = $0 }))
                            HStack(spacing: 10) {
                                darkField("City",             text: Binding(get: { store.deliveryAddress.city },         set: { store.deliveryAddress.city = $0 }))
                                darkField("Postcode",         text: Binding(get: { store.deliveryAddress.postcode },     set: { store.deliveryAddress.postcode = $0 }))
                            }
                            darkField("Phone Number",         text: Binding(get: { store.deliveryAddress.phone },        set: { store.deliveryAddress.phone = $0 }))
                        }
                    } else if store.deliveryAddress.isComplete {
                        Label("\(store.deliveryAddress.fullName), \(store.deliveryAddress.postcode)", systemImage: "checkmark.circle.fill")
                            .font(.caption).foregroundStyle(.green)
                    } else {
                        Text("Required before checkout")
                            .font(.caption).foregroundStyle(.white.opacity(0.35))
                    }
                }
                .padding(18)
                .background(.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1)))

                // ── Order total ──
                let sub = addSubscription.map { $0.basePriceGBP * 12 } ?? 0
                let total = product.price * Double(quantity) + sub
                VStack(spacing: 10) {
                    HStack {
                        Text("Ring ×\(quantity)").foregroundStyle(.white.opacity(0.6)).font(.subheadline)
                        Spacer()
                        Text(CurrencyService.format(product.price * Double(quantity), currencyCode: store.userCurrency))
                            .foregroundStyle(.white).font(.subheadline)
                    }
                    if let plan = addSubscription {
                        HStack {
                            Text("\(plan.rawValue) 1 Year").foregroundStyle(.white.opacity(0.6)).font(.subheadline)
                            Spacer()
                            Text(CurrencyService.format(plan.basePriceGBP * 12, currencyCode: store.userCurrency))
                                .foregroundStyle(.white).font(.subheadline)
                        }
                    }
                    Divider().background(.white.opacity(0.15))
                    HStack {
                        Text("Total").font(.headline).foregroundStyle(.white)
                        Spacer()
                        Text(CurrencyService.format(total, currencyCode: store.userCurrency))
                            .font(.title3).fontWeight(.bold).foregroundStyle(selectedColor.glowColor)
                    }
                }
                .padding(18)
                .background(.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1)))

                // ── Buy button ──
                Button { buyNow = true; showPayment = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "bag.fill")
                        Text("Order — \(CurrencyService.format(total, currencyCode: store.userCurrency))")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [selectedColor.glowColor, selectedColor.glowColor.opacity(0.7)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: selectedColor.glowColor.opacity(0.4), radius: 16, y: 6)
                }

                // Badges
                HStack(spacing: 16) {
                    ForEach(["lock.shield.fill|Secure Checkout", "arrow.counterclockwise|30-Day Returns", "shippingbox.fill|Free UK Delivery"], id: \.self) { item in
                        let parts = item.split(separator: "|")
                        VStack(spacing: 4) {
                            Image(systemName: String(parts[0]))
                                .font(.caption).foregroundStyle(.white.opacity(0.4))
                            Text(String(parts[1]))
                                .font(.caption2).foregroundStyle(.white.opacity(0.35))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 20)
        }
        .background(Color(white: 0.06))
    }

    // MARK: - Helpers

    func darkField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .padding(12)
            .background(.white.opacity(0.07))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.12)))
    }

    // MARK: - Payment Sheet

    var paymentSheet: some View {
        let sub = addSubscription.map { $0.basePriceGBP * 12 } ?? 0
        let total = product.price * Double(quantity) + sub
        return ApplePayCheckoutView(
            title: product.name,
            subtitle: "\(selectedColor.rawValue) · Size \(selectedSize.shortLabel) · Qty \(quantity)",
            amountGBP: total,
            onSuccess: { transactionId, method in
                let item = CartItem(
                    productID: product.id, name: product.name,
                    price: product.price, icon: product.icon, color: product.color,
                    quantity: quantity,
                    selectedColor: selectedColor, selectedSize: selectedSize,
                    sku: "RING-X3B-\(selectedColor.rawValue.uppercased())-S\(selectedSize.shortLabel)",
                    isGift: isGift, giftMessage: giftMessage,
                    addSubscription: addSubscription
                )
                store.cartItems = [item]
                store.placeOrder(paymentMethod: method, paymentIntentId: transactionId)
                showPayment = false
                dismiss()
            }
        )
    }

    // MARK: - Size Guide Sheet

    var sizeGuideSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Find Your Ring Size")
                        .font(.title2).fontWeight(.bold)

                    Text("Wrap a strip of paper around your finger, mark where it overlaps, measure the length in mm, then match it below.")
                        .foregroundStyle(.secondary)

                    VStack(spacing: 0) {
                        HStack {
                            Text("Size").fontWeight(.bold).frame(width: 60, alignment: .leading)
                            Text("Circumference").fontWeight(.bold).frame(maxWidth: .infinity, alignment: .center)
                            Text("Diameter").fontWeight(.bold).frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(12).background(Color(.systemGray6))

                        ForEach(Array(RingSize.allCases.enumerated()), id: \.offset) { i, size in
                            HStack {
                                Text(size.shortLabel).frame(width: 60, alignment: .leading)
                                Text(size.circumference).frame(maxWidth: .infinity, alignment: .center).foregroundStyle(.secondary)
                                Text(size.diameter).frame(maxWidth: .infinity, alignment: .trailing).foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .background(i % 2 == 0 ? Color.clear : Color(.systemGray6).opacity(0.4))
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray5)))

                    Text("Tip: Fingers swell in heat — measure in the evening for the most accurate fit.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Ring Size Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { showSizeGuide = false } } }
        }
    }
}

// MARK: - 3D Ring Canvas View

struct Ring3DView: View {
    let color     : RingColor
    let rotation  : Double   // continuous, drives cos
    let floatY    : CGFloat

    private var cosR: CGFloat { CGFloat(abs(cos(rotation))) }

    var body: some View {
        ZStack {
            // Shadow on "floor"
            Ellipse()
                .fill(Color.black.opacity(0.35))
                .frame(width: 140 * cosR + 20, height: 18)
                .blur(radius: 14)
                .offset(y: 88 + floatY * 0.4)

            // Glow bloom
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.glowColor.opacity(0.28), .clear],
                        center: .center, startRadius: 0, endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .offset(y: floatY)

            // Ring outer glow
            Ellipse()
                .stroke(color.glowColor.opacity(0.2), lineWidth: 30)
                .frame(width: 130 * cosR, height: 130)
                .blur(radius: 10)
                .offset(y: floatY)

            // Main ring body
            Ellipse()
                .stroke(
                    LinearGradient(
                        colors: [
                            color.highlight,
                            color.base,
                            color.shadow,
                            color.base,
                            color.highlight,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 22
                )
                .frame(width: 116 * cosR, height: 116)
                .offset(y: floatY)

            // Specular streak
            Ellipse()
                .trim(from: 0.08, to: 0.28)
                .stroke(Color.white.opacity(0.55), lineWidth: 7)
                .frame(width: 116 * cosR, height: 116)
                .blur(radius: 1.5)
                .offset(y: floatY)

            // Sensor dot (bottom of ring)
            Circle()
                .fill(Color.black)
                .frame(width: 10, height: 10)
                .offset(y: 58 + floatY)
                .opacity(cosR > 0.15 ? 1 : 0)

            // PPG LED dots (red + green)
            Circle().fill(Color.red.opacity(0.9)).frame(width: 5, height: 5)
                .offset(x: -7, y: 58 + floatY).opacity(cosR > 0.2 ? 1 : 0)
            Circle().fill(Color.green.opacity(0.9)).frame(width: 5, height: 5)
                .offset(x: 7, y: 58 + floatY).opacity(cosR > 0.2 ? 1 : 0)
        }
    }
}

// MARK: - Feature Card

struct FeatureCard: View {
    let icon    : String
    let title   : String
    let subtitle: String
    let metric  : String
    let unit    : String
    let color   : Color
    let scrollY : CGFloat
    let index   : Int

    @State private var appeared = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline).foregroundStyle(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .lineSpacing(3)
                    .lineLimit(3)
            }

            Spacer()

            // Live metric badge
            if !metric.isEmpty {
                VStack(spacing: 2) {
                    Text(metric)
                        .font(.headline)
                        .foregroundStyle(color)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption2)
                            .foregroundStyle(color.opacity(0.6))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.07)))
        .offset(x: appeared ? 0 : 40, y: 0)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(Double(index) * 0.07)) {
                appeared = true
            }
        }
    }
}

// MARK: - RingColor Extensions

extension RingColor {
    /// Asset name for the front-face product photo (transparent/white bg)
    var frontPhotoName: String {
        switch self {
        case .silver: return "ring_silver_front"
        case .black:  return "ring_black_front"
        case .gold:   return "ring_gold_front"
        }
    }

    /// Asset name for the angled side product photo (dark bg)
    var sidePhotoName: String {
        switch self {
        case .silver: return "ring_silver_side"
        case .black:  return "ring_black_side"
        case .gold:   return "ring_gold_side"
        }
    }

    var glowColor: Color {
        switch self {
        case .silver: return Color(white: 0.75)
        case .black:  return Color(white: 0.5)
        case .gold:   return Color(red: 0.85, green: 0.65, blue: 0.25)
        }
    }

    var swatch: Color {
        switch self {
        case .silver: return Color(white: 0.78)
        case .black:  return Color(white: 0.15)
        case .gold:   return Color(red: 0.85, green: 0.7, blue: 0.35)
        }
    }

    var base: Color {
        switch self {
        case .silver: return Color(white: 0.78)
        case .black:  return Color(white: 0.18)
        case .gold:   return Color(red: 0.82, green: 0.63, blue: 0.25)
        }
    }

    var highlight: Color {
        switch self {
        case .silver: return Color(white: 0.96)
        case .black:  return Color(white: 0.38)
        case .gold:   return Color(red: 1.0, green: 0.9, blue: 0.55)
        }
    }

    var shadow: Color {
        switch self {
        case .silver: return Color(white: 0.45)
        case .black:  return Color(white: 0.06)
        case .gold:   return Color(red: 0.5, green: 0.38, blue: 0.05)
        }
    }

    var finishDescription: String {
        switch self {
        case .silver: return "Brushed silver titanium. Timeless, minimal, pairs with anything."
        case .black:  return "PVD black titanium. Bold, scratch-resistant, ultra-modern."
        case .gold:   return "18K gold PVD. Warm, elegant, and uniquely refined."
        }
    }
}

// MARK: - RingSize Extensions

extension RingSize {
    var circumference: String {
        switch self {
        case .size5:  return "49.3 mm"
        case .size6:  return "51.8 mm"
        case .size7:  return "54.4 mm"
        case .size8:  return "56.9 mm"
        case .size9:  return "59.5 mm"
        case .size10: return "62.1 mm"
        case .size11: return "64.6 mm"
        case .size12: return "67.2 mm"
        case .size13: return "69.7 mm"
        }
    }

    var diameter: String {
        switch self {
        case .size5:  return "15.7 mm"
        case .size6:  return "16.5 mm"
        case .size7:  return "17.3 mm"
        case .size8:  return "18.2 mm"
        case .size9:  return "18.9 mm"
        case .size10: return "19.8 mm"
        case .size11: return "20.6 mm"
        case .size12: return "21.4 mm"
        case .size13: return "22.2 mm"
        }
    }
}
