// BarcodeScannerView.swift
// body sense ai
//
// Production barcode scanner: AVFoundation camera capture + Open Food Facts API via BodySense backend.
// Scans EAN-8, EAN-13, UPC-A, UPC-E food product barcodes and logs nutrition to HealthStore.

import SwiftUI
import AVFoundation

// MARK: - API Food Item Model

struct APIFoodItem: Codable, Identifiable {
    var id = UUID()
    let name: String
    let brand: String
    let barcode: String
    let imageURL: String
    let servingSize: String
    let nutriScore: String?
    let novaGroup: Int?
    let categories: [String]
    let allergens: [String]
    let per100g: NutritionPer100g

    struct NutritionPer100g: Codable {
        let calories: Int
        let protein: Double
        let carbs: Double
        let fat: Double
        let fiber: Double
        let sugar: Double
        let salt: Double
        let saturatedFat: Double
    }

    enum CodingKeys: String, CodingKey {
        case name, brand, barcode, imageURL, servingSize, nutriScore, novaGroup, categories, allergens, per100g
    }
}

// MARK: - Food API Service

actor FoodAPIService {
    static let shared = FoodAPIService()
    private let baseURL = "https://body-sense-ai-production.up.railway.app"

    enum APIError: LocalizedError {
        case invalidURL
        case networkError(String)
        case decodingError(String)
        case notFound
        case serverError(Int)

        var errorDescription: String? {
            switch self {
            case .invalidURL:             return "Invalid request URL."
            case .networkError(let msg):  return "Network error: \(msg)"
            case .decodingError(let msg): return "Failed to parse response: \(msg)"
            case .notFound:               return "Product not found in our database."
            case .serverError(let code):  return "Server error (\(code)). Please try again."
            }
        }
    }

    func lookupBarcode(_ barcode: String) async throws -> APIFoodItem {
        guard let url = URL(string: "\(baseURL)/barcode-lookup") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        let body = ["barcode": barcode]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid response.")
        }
        if httpResponse.statusCode == 404 { throw APIError.notFound }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(APIFoodItem.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    func searchFood(query: String) async throws -> [APIFoodItem] {
        guard let url = URL(string: "\(baseURL)/food-search") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        let body = ["query": query]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid response.")
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode([APIFoodItem].self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }
}

// MARK: - Barcode Scanner Coordinator

final class BarcodeScannerCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    var onBarcodeDetected: ((String) -> Void)?
    private var lastDetectedBarcode: String?
    private var lastDetectionTime: Date = .distantPast
    private let debounceInterval: TimeInterval = 2.0

    let captureSession = AVCaptureSession()
    private let metadataOutput = AVCaptureMetadataOutput()
    private let sessionQueue = DispatchQueue(label: "com.bodysenseai.barcodescanner.session")

    var isSessionRunning: Bool { captureSession.isRunning }

    func setupSession() -> Bool {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoInput) else {
            captureSession.commitConfiguration()
            return false
        }
        captureSession.addInput(videoInput)

        guard captureSession.canAddOutput(metadataOutput) else {
            captureSession.commitConfiguration()
            return false
        }
        captureSession.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)

        let supportedTypes: [AVMetadataObject.ObjectType] = [.ean8, .ean13, .upce]
        let available = metadataOutput.availableMetadataObjectTypes
        metadataOutput.metadataObjectTypes = supportedTypes.filter { available.contains($0) }

        captureSession.commitConfiguration()
        return true
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
        }
    }

    func resetDetection() {
        lastDetectedBarcode = nil
        lastDetectionTime = .distantPast
    }

    // MARK: - AVCaptureMetadataOutputObjectsDelegate

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard let metadata = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let barcode = metadata.stringValue,
              !barcode.isEmpty else { return }

        let now = Date()
        if barcode == lastDetectedBarcode && now.timeIntervalSince(lastDetectionTime) < debounceInterval {
            return
        }

        lastDetectedBarcode = barcode
        lastDetectionTime = now

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        onBarcodeDetected?(barcode)
    }
}

// MARK: - Camera Preview (UIViewRepresentable)

struct BarcodeCameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

// MARK: - Scanning Overlay

private struct ScanningOverlayView: View {
    @State private var animateStroke = false

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height) * 0.65
            let rect = CGRect(
                x: (geo.size.width - size) / 2,
                y: (geo.size.height - size) / 2,
                width: size,
                height: size * 0.6
            )

            ZStack {
                // Dimmed background outside scan area
                Path { path in
                    path.addRect(CGRect(origin: .zero, size: geo.size))
                    path.addRoundedRect(in: rect, cornerSize: CGSize(width: 16, height: 16))
                }
                .fill(Color.black.opacity(0.45))
                .compositingGroup()
                .blendMode(.normal)

                // Scan frame border
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        animateStroke ? Color.accentColor : Color.white.opacity(0.7),
                        lineWidth: 3
                    )
                    .frame(width: rect.width, height: rect.height)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                // Instructional text
                VStack {
                    Spacer()
                    Text("Align barcode within the frame")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 40)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                animateStroke = true
            }
        }
    }
}

// MARK: - Nutri-Score Badge

private struct NutriScoreBadge: View {
    let score: String

    private var colour: Color {
        switch score.uppercased() {
        case "A": return .green
        case "B": return Color(red: 0.55, green: 0.78, blue: 0.25)
        case "C": return .yellow
        case "D": return .orange
        case "E": return .red
        default:  return .secondary
        }
    }

    var body: some View {
        Text("Nutri-Score \(score.uppercased())")
            .font(.caption.weight(.bold))
            .foregroundStyle(colour)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(colour.opacity(0.12))
            .clipShape(Capsule())
    }
}

// MARK: - Scanned Product View

struct ScannedProductView: View {
    let food: APIFoodItem
    let onLog: (MealType, Double) -> Void
    let onDismiss: () -> Void
    let onSearchByName: () -> Void

    @Environment(HealthStore.self) private var store
    @State private var selectedMealType: MealType = .lunch
    @State private var grams: Double = 100
    @State private var showLogConfirmation = false

    /// Check user allergens against product allergens
    private var allergenWarnings: [String] {
        // Surface all allergens from the product so the user is informed
        food.allergens.filter { !$0.isEmpty }
    }

    /// Dietary conflict check against user's health conditions
    private var dietaryConflicts: [String] {
        var conflicts: [String] = []
        let profile = store.userProfile

        // High sugar warning for diabetic users
        let sugarPer100 = food.per100g.sugar
        if (profile.diabetesType.lowercased().contains("type 1") ||
            profile.diabetesType.lowercased().contains("type 2")) && sugarPer100 > 10 {
            conflicts.append("High sugar content (\(String(format: "%.1f", sugarPer100))g/100g) — monitor glucose after eating.")
        }

        // High salt warning for hypertensive users
        let saltPer100 = food.per100g.salt
        if profile.hasHypertension && saltPer100 > 1.5 {
            conflicts.append("High salt content (\(String(format: "%.1f", saltPer100))g/100g) — may affect blood pressure.")
        }

        // High saturated fat
        if food.per100g.saturatedFat > 5 {
            conflicts.append("High saturated fat (\(String(format: "%.1f", food.per100g.saturatedFat))g/100g).")
        }

        return conflicts
    }

    private var scaledCalories: Int { Int(Double(food.per100g.calories) * grams / 100) }
    private var scaledProtein: Double { food.per100g.protein * grams / 100 }
    private var scaledCarbs: Double { food.per100g.carbs * grams / 100 }
    private var scaledFat: Double { food.per100g.fat * grams / 100 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Product header
                productHeader

                // Nutrition per serving
                nutritionCard

                // Allergen warnings
                if !allergenWarnings.isEmpty {
                    allergenSection
                }

                // Dietary conflict warnings
                if !dietaryConflicts.isEmpty {
                    conflictSection
                }

                // Portion & meal picker
                portionPicker

                // Log button
                logButton

                // Scan another
                Button {
                    onDismiss()
                } label: {
                    Label("Scan Another Product", systemImage: "barcode.viewfinder")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemBackground))
        .alert("Logged", isPresented: $showLogConfirmation) {
            Button("OK") { onDismiss() }
        } message: {
            Text("\(food.name) (\(Int(grams))g) added to \(selectedMealType.rawValue).")
        }
    }

    // MARK: - Subviews

    private var productHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                // Product image
                if let url = URL(string: food.imageURL), !food.imageURL.isEmpty {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        default:
                            productImagePlaceholder
                        }
                    }
                } else {
                    productImagePlaceholder
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(food.name)
                        .font(.headline)
                        .foregroundStyle(Color(.label))

                    if !food.brand.isEmpty {
                        Text(food.brand)
                            .font(.subheadline)
                            .foregroundStyle(Color(.secondaryLabel))
                    }

                    if !food.servingSize.isEmpty {
                        Text("Serving: \(food.servingSize)")
                            .font(.caption)
                            .foregroundStyle(Color(.tertiaryLabel))
                    }

                    HStack(spacing: 8) {
                        if let score = food.nutriScore, !score.isEmpty {
                            NutriScoreBadge(score: score)
                        }
                        if let nova = food.novaGroup {
                            Text("NOVA \(nova)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(nova <= 2 ? Color.green : (nova == 3 ? Color.orange : Color.red))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background((nova <= 2 ? Color.green : (nova == 3 ? Color.orange : Color.red)).opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .padding(.horizontal)
    }

    private var productImagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.tertiarySystemBackground))
            .frame(width: 80, height: 80)
            .overlay {
                Image(systemName: "takeoutbag.and.cup.and.straw")
                    .font(.title2)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
    }

    private var nutritionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition per \(Int(grams))g")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(.label))

            LazyVGrid(columns: [
                GridItem(.flexible()), GridItem(.flexible()),
                GridItem(.flexible()), GridItem(.flexible())
            ], spacing: 12) {
                nutrientCell(label: "Calories", value: "\(scaledCalories)", unit: "kcal", colour: .orange)
                nutrientCell(label: "Protein", value: String(format: "%.1f", scaledProtein), unit: "g", colour: .blue)
                nutrientCell(label: "Carbs", value: String(format: "%.1f", scaledCarbs), unit: "g", colour: .purple)
                nutrientCell(label: "Fat", value: String(format: "%.1f", scaledFat), unit: "g", colour: .yellow)
            }

            Divider()

            HStack(spacing: 16) {
                detailNutrient(label: "Fibre", value: food.per100g.fiber * grams / 100)
                detailNutrient(label: "Sugar", value: food.per100g.sugar * grams / 100)
                detailNutrient(label: "Salt", value: food.per100g.salt * grams / 100)
                detailNutrient(label: "Sat. Fat", value: food.per100g.saturatedFat * grams / 100)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .padding(.horizontal)
    }

    private func nutrientCell(label: String, value: String, unit: String, colour: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(colour)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(Color(.tertiaryLabel))
            Text(label)
                .font(.caption)
                .foregroundStyle(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
    }

    private func detailNutrient(label: String, value: Double) -> some View {
        VStack(spacing: 2) {
            Text(String(format: "%.1f", value))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(.label))
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
    }

    private var allergenSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Allergens", systemImage: "exclamationmark.triangle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)

            BarcodeFlowLayout(spacing: 6) {
                ForEach(allergenWarnings, id: \.self) { allergen in
                    Text(allergen.capitalized)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .padding(.horizontal)
    }

    private var conflictSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Health Considerations", systemImage: "heart.text.square")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.red)

            ForEach(dietaryConflicts, id: \.self) { conflict in
                Text(conflict)
                    .font(.caption)
                    .foregroundStyle(Color(.label))
            }
        }
        .padding()
        .background(Color.red.opacity(0.06))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .padding(.horizontal)
    }

    private var portionPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Log This Food")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(.label))

            // Meal type
            HStack {
                Text("Meal")
                    .font(.subheadline)
                    .foregroundStyle(Color(.secondaryLabel))
                Spacer()
                Picker("Meal", selection: $selectedMealType) {
                    ForEach(MealType.allCases, id: \.self) { meal in
                        Text(meal.rawValue).tag(meal)
                    }
                }
                .pickerStyle(.menu)
            }

            // Portion size
            HStack {
                Text("Portion")
                    .font(.subheadline)
                    .foregroundStyle(Color(.secondaryLabel))
                Spacer()
                Text("\(Int(grams))g")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color(.label))
                    .frame(width: 60, alignment: .trailing)
            }
            Slider(value: $grams, in: 10...500, step: 5)
                .tint(.accentColor)

            // Quick portion buttons
            HStack(spacing: 8) {
                ForEach([25, 50, 100, 150, 200], id: \.self) { amount in
                    Button("\(amount)g") {
                        withAnimation { grams = Double(amount) }
                    }
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Int(grams) == amount ? Color.accentColor.opacity(0.15) : Color(.tertiarySystemBackground))
                    .foregroundStyle(Int(grams) == amount ? Color.accentColor : Color(.secondaryLabel))
                    .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .padding(.horizontal)
    }

    private var logButton: some View {
        Button {
            onLog(selectedMealType, grams)
            showLogConfirmation = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Log \(scaledCalories) kcal to \(selectedMealType.rawValue)")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .cornerRadius(14)
        }
        .padding(.horizontal)
    }
}

// MARK: - Flow Layout (for allergen tags)

private struct BarcodeFlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                                  proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}

// MARK: - Barcode Scanner View

struct BarcodeScannerView: View {
    @Environment(HealthStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var coordinator = BarcodeScannerCoordinator()
    @State private var cameraPermission: AVAuthorizationStatus = .notDetermined
    @State private var isLoading = false
    @State private var scannedFood: APIFoodItem?
    @State private var errorMessage: String?
    @State private var lastScannedBarcode: String?
    @State private var isTorchOn = false

    var onSwitchToTextSearch: (() -> Void)?

    var body: some View {
        NavigationStack {
            ZStack {
                switch cameraPermission {
                case .authorized:
                    if let food = scannedFood {
                        ScannedProductView(
                            food: food,
                            onLog: { mealType, grams in logFood(food: food, mealType: mealType, grams: grams) },
                            onDismiss: { resetScanner() },
                            onSearchByName: { switchToTextSearch() }
                        )
                    } else {
                        scannerView
                    }

                case .denied, .restricted:
                    cameraPermissionDeniedView

                case .notDetermined:
                    requestingPermissionView

                @unknown default:
                    requestingPermissionView
                }
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                if cameraPermission == .authorized && scannedFood == nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            toggleTorch()
                        } label: {
                            Image(systemName: isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                        }
                    }
                }
            }
        }
        .onAppear { checkCameraPermission() }
        .onDisappear {
            coordinator.stopSession()
            if isTorchOn { setTorch(on: false) }
        }
    }

    // MARK: - Scanner View

    private var scannerView: some View {
        ZStack {
            BarcodeCameraPreviewView(session: coordinator.captureSession)
                .ignoresSafeArea()

            ScanningOverlayView()

            // Loading overlay
            if isLoading {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Looking up product...")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                    if let barcode = lastScannedBarcode {
                        Text(barcode)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(24)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }

            // Error overlay
            if let error = errorMessage {
                VStack {
                    Spacer()
                    errorBanner(message: error)
                }
            }

            // Bottom actions
            if !isLoading && errorMessage == nil {
                VStack {
                    Spacer()
                    searchByNameButton
                        .padding(.bottom, 20)
                }
            }
        }
    }

    private func errorBanner(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass.circle")
                .font(.largeTitle)
                .foregroundStyle(.white)

            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button("Try Again") {
                    withAnimation { errorMessage = nil }
                    coordinator.resetDetection()
                }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.white)
                .foregroundStyle(Color.accentColor)
                .clipShape(Capsule())

                Button("Search by Name") {
                    switchToTextSearch()
                }
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.white.opacity(0.25))
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding()
    }

    private var searchByNameButton: some View {
        Button {
            switchToTextSearch()
        } label: {
            Label("Search by name instead", systemImage: "text.magnifyingglass")
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: Capsule())
                .foregroundStyle(.white)
        }
    }

    // MARK: - Permission Views

    private var cameraPermissionDeniedView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "camera.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color(.tertiaryLabel))

            Text("Camera Access Required")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color(.label))

            Text("BodySense AI needs camera access to scan food product barcodes. Please enable camera access in Settings.")
                .font(.subheadline)
                .foregroundStyle(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 40)

            searchByNameLink
            Spacer()
        }
    }

    private var requestingPermissionView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Requesting camera access...")
                .font(.subheadline)
                .foregroundStyle(Color(.secondaryLabel))
        }
    }

    private var searchByNameLink: some View {
        Button {
            switchToTextSearch()
        } label: {
            Text("Search by name instead")
                .font(.subheadline)
                .foregroundStyle(Color.accentColor)
        }
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        cameraPermission = status

        switch status {
        case .authorized:
            startCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraPermission = granted ? .authorized : .denied
                    if granted { startCamera() }
                }
            }
        default:
            break
        }
    }

    private func startCamera() {
        coordinator.onBarcodeDetected = { barcode in
            guard !isLoading else { return }
            lastScannedBarcode = barcode
            lookupBarcode(barcode)
        }

        if coordinator.setupSession() {
            coordinator.startSession()
        }
    }

    private func lookupBarcode(_ barcode: String) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let food = try await FoodAPIService.shared.lookupBarcode(barcode)
                await MainActor.run {
                    coordinator.stopSession()
                    scannedFood = food
                    isLoading = false
                }
            } catch let error as FoodAPIService.APIError {
                await MainActor.run {
                    errorMessage = error.errorDescription
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Could not look up product. Check your connection and try again."
                    isLoading = false
                }
            }
        }
    }

    private func logFood(food: APIFoodItem, mealType: MealType, grams: Double) {
        let log = NutritionLog(
            date: Date(),
            mealType: mealType,
            calories: Int(Double(food.per100g.calories) * grams / 100),
            carbs: food.per100g.carbs * grams / 100,
            protein: food.per100g.protein * grams / 100,
            fat: food.per100g.fat * grams / 100,
            fiber: food.per100g.fiber * grams / 100,
            sugar: food.per100g.sugar * grams / 100,
            salt: food.per100g.salt * grams / 100,
            foodName: food.name,
            notes: "Scanned: \(food.barcode)"
        )
        store.nutritionLogs.append(log)
        store.save()

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func resetScanner() {
        scannedFood = nil
        errorMessage = nil
        lastScannedBarcode = nil
        coordinator.resetDetection()
        coordinator.startSession()
    }

    private func switchToTextSearch() {
        coordinator.stopSession()
        if let action = onSwitchToTextSearch {
            action()
        }
        dismiss()
    }

    private func toggleTorch() {
        isTorchOn.toggle()
        setTorch(on: isTorchOn)
    }

    private func setTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }
}

// MARK: - Preview

#Preview {
    BarcodeScannerView()
        .environment(HealthStore.shared)
}
