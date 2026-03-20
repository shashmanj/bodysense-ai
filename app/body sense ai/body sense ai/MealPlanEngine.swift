//
//  MealPlanEngine.swift
//  body sense ai
//
//  Intelligent Chef + Nutritionist Engine for HealthSense AI Agent.
//  Generates personalised meal plans, recipes, and food recommendations
//  based on the user's health conditions, goals, preferences, and data.
//
//  This engine combines Chef Kai's cooking expertise with Maya's nutrition science
//  to produce meals that are BOTH delicious AND medically optimal.
//

import Foundation

// MARK: - Meal Plan Models

struct MealSuggestion: Identifiable {
    let id = UUID()
    let name: String
    let mealType: MealType
    let description: String
    let ingredients: [String]
    let calories: Int
    let carbs: Int         // grams
    let protein: Int       // grams
    let fat: Int           // grams
    let fibre: Int         // grams
    let glycaemicIndex: GILevel
    let sodium: SodiumLevel
    let prepTime: Int      // minutes
    let cookTime: Int      // minutes
    let tags: [String]
    let healthBenefits: [String]
    let recipe: String?

    enum MealType: String {
        case breakfast = "Breakfast"
        case morningSnack = "Morning Snack"
        case lunch = "Lunch"
        case afternoonSnack = "Afternoon Snack"
        case dinner = "Dinner"
        case eveningSnack = "Evening Snack"
    }

    enum GILevel: String {
        case low = "Low GI"
        case medium = "Medium GI"
        case high = "High GI"
    }

    enum SodiumLevel: String {
        case low = "Low Sodium"
        case moderate = "Moderate Sodium"
        case high = "High Sodium"
    }
}

struct DayMealPlan: Identifiable {
    let id = UUID()
    let day: String
    let meals: [MealSuggestion]

    var totalCalories: Int { meals.map { $0.calories }.reduce(0, +) }
    var totalCarbs: Int { meals.map { $0.carbs }.reduce(0, +) }
    var totalProtein: Int { meals.map { $0.protein }.reduce(0, +) }
    var totalFat: Int { meals.map { $0.fat }.reduce(0, +) }
}

// MARK: - Meal Plan Engine

class MealPlanEngine {

    private let store: HealthStore
    private let memory: AgentMemoryStore

    init(store: HealthStore) {
        self.store = store
        self.memory = AgentMemoryStore.shared
    }

    // MARK: - Generate Meal Context for AI

    /// Builds a rich food/nutrition context string for the AI agent
    func buildMealContext() -> String {
        let p = store.userProfile
        var ctx = "\n--- MEAL PLANNING CONTEXT ---\n"

        // Calorie target estimation
        let bmr = calculateBMR()
        let tdee = Int(bmr * activityMultiplier())
        let targetCal: Int
        if p.selectedGoals.contains("Lose weight") {
            targetCal = tdee - 500  // 500 cal deficit
        } else if p.selectedGoals.contains("Build muscle") {
            targetCal = tdee + 300  // 300 cal surplus
        } else {
            targetCal = tdee
        }
        ctx += "Estimated daily calories: \(targetCal) kcal (TDEE: \(tdee))\n"

        // Macro targets
        let proteinTarget: Int
        let carbTarget: Int
        let fatTarget: Int

        if !p.diabetesType.isEmpty {
            // Lower carb for diabetes
            proteinTarget = Int(Double(targetCal) * 0.25 / 4)  // 25% protein
            carbTarget = Int(Double(targetCal) * 0.35 / 4)     // 35% carbs (controlled)
            fatTarget = Int(Double(targetCal) * 0.40 / 9)      // 40% healthy fats
            ctx += "Macro split (diabetic): Protein \(proteinTarget)g, Carbs \(carbTarget)g (controlled), Fat \(fatTarget)g\n"
        } else if p.hasHypertension {
            // DASH diet macros
            proteinTarget = Int(Double(targetCal) * 0.20 / 4)
            carbTarget = Int(Double(targetCal) * 0.50 / 4)
            fatTarget = Int(Double(targetCal) * 0.30 / 9)
            ctx += "Macro split (DASH): Protein \(proteinTarget)g, Carbs \(carbTarget)g, Fat \(fatTarget)g\n"
            ctx += "Sodium target: <1500mg/day (DASH recommendation)\n"
        } else {
            proteinTarget = Int(Double(targetCal) * 0.25 / 4)
            carbTarget = Int(Double(targetCal) * 0.45 / 4)
            fatTarget = Int(Double(targetCal) * 0.30 / 9)
            ctx += "Macro split: Protein \(proteinTarget)g, Carbs \(carbTarget)g, Fat \(fatTarget)g\n"
        }

        // Glucose-specific food guidance
        if !p.diabetesType.isEmpty {
            let recentGlucose = store.glucoseReadings.sorted(by: { $0.date > $1.date }).prefix(7)
            if !recentGlucose.isEmpty {
                let avg = recentGlucose.map { $0.value }.reduce(0, +) / Double(recentGlucose.count)
                if avg > 180 {
                    ctx += "GLUCOSE ALERT: Avg glucose HIGH (\(Int(avg)) mg/dL). Prioritise very low-GI meals. Avoid: white rice, white bread, potatoes, sugary foods.\n"
                } else if avg > 140 {
                    ctx += "Glucose slightly above target (\(Int(avg)) mg/dL). Prefer low-GI foods, pair carbs with protein/fat.\n"
                } else {
                    ctx += "Glucose well-controlled (\(Int(avg)) mg/dL). Maintain current eating patterns.\n"
                }
            }
        }

        // Learned food preferences from memory
        let foodInsights = memory.allInsights.filter {
            ($0.category == .preference || $0.category == .dislike || $0.category == .allergy) &&
            ($0.domain == .chef || $0.domain == .nutrition)
        }
        if !foodInsights.isEmpty {
            ctx += "\nLEARNED FOOD PREFERENCES:\n"
            for insight in foodInsights {
                ctx += "• [\(insight.category.rawValue)] \(insight.content)\n"
            }
        }

        // Medications that affect food choices
        let meds = store.medications.filter { $0.isActive }
        if !meds.isEmpty {
            ctx += "\nMEDICATION-FOOD CONSIDERATIONS:\n"
            for med in meds {
                let medName = med.name.lowercased()
                if medName.contains("metformin") {
                    ctx += "• Metformin: Take with food to reduce GI side effects. High-fibre meals help.\n"
                }
                if medName.contains("warfarin") {
                    ctx += "• Warfarin: AVOID sudden changes in vitamin K intake (green leafy veg). Keep consistent.\n"
                }
                if medName.contains("statin") || medName.contains("atorvastatin") || medName.contains("simvastatin") {
                    ctx += "• Statin: Avoid grapefruit. Take simvastatin at night, atorvastatin any time.\n"
                }
                if medName.contains("lisinopril") || medName.contains("ramipril") {
                    ctx += "• ACE inhibitor: Avoid high-potassium salt substitutes.\n"
                }
            }
        }

        return ctx
    }

    // MARK: - Quick Meal Suggestions (No AI needed)

    func quickMealIdeas(for mealType: MealSuggestion.MealType) -> [MealSuggestion] {
        let p = store.userProfile
        let isDiabetic = !p.diabetesType.isEmpty
        let isHypertensive = p.hasHypertension
        let wantsWeightLoss = p.selectedGoals.contains("Lose weight")

        switch mealType {
        case .breakfast:
            return breakfastSuggestions(diabetic: isDiabetic, hypertensive: isHypertensive, weightLoss: wantsWeightLoss)
        case .lunch:
            return lunchSuggestions(diabetic: isDiabetic, hypertensive: isHypertensive, weightLoss: wantsWeightLoss)
        case .dinner:
            return dinnerSuggestions(diabetic: isDiabetic, hypertensive: isHypertensive, weightLoss: wantsWeightLoss)
        case .morningSnack, .afternoonSnack:
            return snackSuggestions(diabetic: isDiabetic, hypertensive: isHypertensive, weightLoss: wantsWeightLoss)
        case .eveningSnack:
            return eveningSnackSuggestions(diabetic: isDiabetic)
        }
    }

    // MARK: - Breakfast Suggestions

    private func breakfastSuggestions(diabetic: Bool, hypertensive: Bool, weightLoss: Bool) -> [MealSuggestion] {
        var meals: [MealSuggestion] = []

        meals.append(MealSuggestion(
            name: diabetic ? "Greek Yogurt Power Bowl" : "Overnight Oats with Berries",
            mealType: .breakfast,
            description: diabetic
                ? "High-protein Greek yogurt with cinnamon, walnuts, and blueberries. Low GI, keeps blood sugar stable."
                : "Rolled oats soaked overnight with chia seeds, mixed berries, and a drizzle of honey.",
            ingredients: diabetic
                ? ["150g Greek yogurt (0% fat)", "1 tsp cinnamon", "30g walnuts", "50g blueberries", "1 tbsp flaxseed"]
                : ["50g rolled oats", "150ml milk", "1 tbsp chia seeds", "80g mixed berries", "1 tsp honey"],
            calories: diabetic ? 280 : 350,
            carbs: diabetic ? 18 : 48,
            protein: diabetic ? 22 : 14,
            fat: diabetic ? 16 : 12,
            fibre: diabetic ? 4 : 8,
            glycaemicIndex: .low,
            sodium: .low,
            prepTime: diabetic ? 5 : 5,
            cookTime: 0,
            tags: diabetic ? ["diabetic-friendly", "high-protein", "low-GI"] : ["meal-prep", "high-fibre"],
            healthBenefits: diabetic
                ? ["Stable blood sugar", "Omega-3 from walnuts", "Cinnamon may improve insulin sensitivity"]
                : ["Sustained energy", "Heart-healthy fibre", "Antioxidants from berries"],
            recipe: nil
        ))

        meals.append(MealSuggestion(
            name: "Veggie Egg Scramble",
            mealType: .breakfast,
            description: "Protein-rich scrambled eggs with spinach, tomatoes, and mushrooms. Perfect for blood sugar control.",
            ingredients: ["2 eggs", "Handful spinach", "4 cherry tomatoes", "3 mushrooms", "1 tsp olive oil", hypertensive ? "Herbs (no salt)" : "Pinch of salt"],
            calories: 220,
            carbs: 6,
            protein: 16,
            fat: 15,
            fibre: 2,
            glycaemicIndex: .low,
            sodium: hypertensive ? .low : .moderate,
            prepTime: 5,
            cookTime: 5,
            tags: ["high-protein", "low-carb", "quick"],
            healthBenefits: ["High protein for satiety", "Iron from spinach", "B12 from eggs", "Low glycaemic impact"],
            recipe: nil
        ))

        return meals
    }

    // MARK: - Lunch Suggestions

    private func lunchSuggestions(diabetic: Bool, hypertensive: Bool, weightLoss: Bool) -> [MealSuggestion] {
        var meals: [MealSuggestion] = []

        meals.append(MealSuggestion(
            name: "Mediterranean Chicken Salad",
            mealType: .lunch,
            description: "Grilled chicken breast with mixed leaves, cucumber, tomato, olives, and extra virgin olive oil dressing.",
            ingredients: ["120g chicken breast", "Mixed salad leaves", "½ cucumber", "6 cherry tomatoes", "8 olives", "1 tbsp extra virgin olive oil", "Juice of ½ lemon"],
            calories: weightLoss ? 350 : 420,
            carbs: 12,
            protein: 38,
            fat: 20,
            fibre: 4,
            glycaemicIndex: .low,
            sodium: hypertensive ? .low : .moderate,
            prepTime: 10,
            cookTime: 12,
            tags: ["mediterranean", "high-protein", "heart-healthy"],
            healthBenefits: ["Monounsaturated fats from olive oil", "Lean protein", "Antioxidants", "Anti-inflammatory"],
            recipe: nil
        ))

        meals.append(MealSuggestion(
            name: diabetic ? "Lentil & Vegetable Soup" : "Quinoa Buddha Bowl",
            mealType: .lunch,
            description: diabetic
                ? "Hearty red lentil soup with carrots, celery, and cumin. Very low GI and high in fibre."
                : "Quinoa base with roasted sweet potato, chickpeas, avocado, and tahini dressing.",
            ingredients: diabetic
                ? ["100g red lentils", "1 carrot", "2 celery sticks", "1 onion", "1 tsp cumin", "500ml low-salt stock"]
                : ["80g quinoa", "100g sweet potato", "80g chickpeas", "½ avocado", "1 tbsp tahini"],
            calories: diabetic ? 320 : 480,
            carbs: diabetic ? 42 : 58,
            protein: diabetic ? 20 : 18,
            fat: diabetic ? 4 : 22,
            fibre: diabetic ? 12 : 10,
            glycaemicIndex: .low,
            sodium: .low,
            prepTime: 10,
            cookTime: diabetic ? 25 : 30,
            tags: diabetic ? ["diabetic-friendly", "high-fibre", "batch-cook"] : ["plant-based", "nutrient-dense"],
            healthBenefits: diabetic
                ? ["Very slow glucose release", "Plant protein", "Soluble fibre lowers cholesterol"]
                : ["Complete protein from quinoa", "Healthy fats from avocado", "Iron from chickpeas"],
            recipe: nil
        ))

        return meals
    }

    // MARK: - Dinner Suggestions

    private func dinnerSuggestions(diabetic: Bool, hypertensive: Bool, weightLoss: Bool) -> [MealSuggestion] {
        var meals: [MealSuggestion] = []

        meals.append(MealSuggestion(
            name: "Baked Salmon with Roasted Vegetables",
            mealType: .dinner,
            description: "Omega-3 rich salmon fillet with roasted broccoli, courgette, and bell peppers. Drizzled with lemon and herbs.",
            ingredients: ["150g salmon fillet", "100g broccoli", "1 courgette", "1 bell pepper", "1 tbsp olive oil", "Lemon juice", "Fresh dill"],
            calories: weightLoss ? 380 : 450,
            carbs: 14,
            protein: 36,
            fat: 24,
            fibre: 6,
            glycaemicIndex: .low,
            sodium: .low,
            prepTime: 10,
            cookTime: 20,
            tags: ["omega-3", "heart-healthy", "anti-inflammatory"],
            healthBenefits: [
                "Omega-3 reduces triglycerides and inflammation",
                "Vitamin D from salmon",
                "Potassium from vegetables (helps lower BP)",
                diabetic ? "Minimal glucose impact" : "Brain-healthy DHA"
            ],
            recipe: """
            1. Preheat oven to 200°C (400°F)
            2. Place salmon on a lined baking tray, season with lemon, dill, and pepper
            3. Toss vegetables in olive oil, spread around salmon
            4. Bake for 18-20 minutes until salmon flakes easily
            5. Serve with a squeeze of fresh lemon
            """
        ))

        meals.append(MealSuggestion(
            name: diabetic ? "Cauliflower Rice Stir-Fry" : "Chicken & Vegetable Stir-Fry",
            mealType: .dinner,
            description: diabetic
                ? "Low-carb cauliflower rice with mixed vegetables, tofu or chicken, and ginger-soy sauce."
                : "Lean chicken with colourful vegetables in a light soy-ginger sauce over brown rice.",
            ingredients: diabetic
                ? ["200g cauliflower rice", "120g chicken or tofu", "Mixed stir-fry veg", "1 tbsp soy sauce (low salt)", "1 tsp ginger", "1 tsp sesame oil"]
                : ["120g chicken breast", "Mixed stir-fry veg", "80g brown rice", "1 tbsp soy sauce", "1 tsp ginger", "1 clove garlic"],
            calories: diabetic ? 280 : 420,
            carbs: diabetic ? 12 : 48,
            protein: diabetic ? 30 : 34,
            fat: diabetic ? 12 : 10,
            fibre: diabetic ? 6 : 5,
            glycaemicIndex: diabetic ? .low : .medium,
            sodium: hypertensive ? .low : .moderate,
            prepTime: 10,
            cookTime: 12,
            tags: diabetic ? ["low-carb", "diabetic-friendly", "quick"] : ["balanced", "quick", "family-friendly"],
            healthBenefits: diabetic
                ? ["Very low carb — minimal glucose spike", "High protein", "Cauliflower rich in vitamin C"]
                : ["Lean protein", "Colourful veg = diverse antioxidants", "Whole grain brown rice"],
            recipe: nil
        ))

        return meals
    }

    // MARK: - Snack Suggestions

    private func snackSuggestions(diabetic: Bool, hypertensive: Bool, weightLoss: Bool) -> [MealSuggestion] {
        [
            MealSuggestion(
                name: diabetic ? "Apple & Almond Butter" : "Mixed Nuts & Fruit",
                mealType: .afternoonSnack,
                description: diabetic
                    ? "Sliced apple with 1 tbsp almond butter. The fat and protein slow glucose absorption."
                    : "A handful of mixed nuts with a few dried apricots.",
                ingredients: diabetic ? ["1 small apple", "1 tbsp almond butter"] : ["30g mixed nuts", "2 dried apricots"],
                calories: diabetic ? 180 : 200,
                carbs: diabetic ? 20 : 18,
                protein: diabetic ? 5 : 6,
                fat: diabetic ? 10 : 14,
                fibre: diabetic ? 4 : 3,
                glycaemicIndex: .low,
                sodium: .low,
                prepTime: 2,
                cookTime: 0,
                tags: ["quick", "portable", "no-cook"],
                healthBenefits: diabetic
                    ? ["Slow glucose release when paired with fat", "Healthy monounsaturated fats"]
                    : ["Heart-healthy fats", "Iron from apricots", "Magnesium from nuts"],
                recipe: nil
            ),
            MealSuggestion(
                name: "Hummus & Veggie Sticks",
                mealType: .afternoonSnack,
                description: "Crunchy carrot, cucumber, and celery sticks with 2 tbsp hummus.",
                ingredients: ["1 carrot", "½ cucumber", "2 celery sticks", "2 tbsp hummus"],
                calories: 120,
                carbs: 14,
                protein: 5,
                fat: 6,
                fibre: 4,
                glycaemicIndex: .low,
                sodium: .low,
                prepTime: 3,
                cookTime: 0,
                tags: ["plant-based", "low-calorie", "high-fibre"],
                healthBenefits: ["Fibre for gut health", "Chickpeas lower cholesterol", "Hydrating vegetables"],
                recipe: nil
            )
        ]
    }

    // MARK: - Evening Snack

    private func eveningSnackSuggestions(diabetic: Bool) -> [MealSuggestion] {
        [
            MealSuggestion(
                name: diabetic ? "Small Handful of Walnuts" : "Herbal Tea & Dark Chocolate",
                mealType: .eveningSnack,
                description: diabetic
                    ? "10 walnut halves — omega-3 rich, won't spike glucose overnight."
                    : "Chamomile tea with 2 squares of 85% dark chocolate.",
                ingredients: diabetic ? ["10 walnut halves (15g)"] : ["Chamomile tea bag", "2 squares dark chocolate (85%)"],
                calories: diabetic ? 100 : 80,
                carbs: diabetic ? 2 : 8,
                protein: diabetic ? 3 : 1,
                fat: diabetic ? 9 : 5,
                fibre: diabetic ? 1 : 2,
                glycaemicIndex: .low,
                sodium: .low,
                prepTime: 1,
                cookTime: 0,
                tags: ["evening", "sleep-friendly", "low-calorie"],
                healthBenefits: diabetic
                    ? ["Won't raise fasting glucose", "Omega-3 for heart and brain", "Melatonin precursors in walnuts"]
                    : ["Chamomile promotes sleep", "Dark chocolate has flavonoids", "Magnesium relaxes muscles"],
                recipe: nil
            )
        ]
    }

    // MARK: - BMR Calculation (Mifflin-St Jeor)

    private func calculateBMR() -> Double {
        let p = store.userProfile
        let weightKg = p.weight
        let heightCm = p.height
        let age = Double(p.age)

        if p.gender.lowercased() == "male" {
            return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5
        } else {
            return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161
        }
    }

    private func activityMultiplier() -> Double {
        let weekSteps = store.stepEntries.suffix(7)
        guard !weekSteps.isEmpty else { return 1.3 } // sedentary default

        let avgSteps = weekSteps.map { $0.steps }.reduce(0, +) / weekSteps.count

        switch avgSteps {
        case 0..<4000:   return 1.2   // Sedentary
        case 4000..<7000: return 1.375 // Lightly active
        case 7000..<10000: return 1.55 // Moderately active
        case 10000..<15000: return 1.725 // Very active
        default:          return 1.9   // Extra active
        }
    }
}
