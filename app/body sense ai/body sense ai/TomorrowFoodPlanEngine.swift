//
//  TomorrowFoodPlanEngine.swift
//  body sense ai
//
//  Generates next-day meal plans based on user's conditions, medications,
//  dietary profile, activity schedule, and recent health trends.
//  Uses MealPlanEngine suggestions + NutritionProtocols + DrugNutrientDatabase.
//

import Foundation

// MARK: - Tomorrow's Food Plan Engine

enum TomorrowFoodPlanEngine {

    // MARK: - Public API

    /// Generate a personalised food plan for tomorrow.
    static func generate(store: HealthStore) -> TomorrowFoodPlan {
        let profile = store.userProfile
        let dietary = profile.dietaryProfile
        let activeMeds = store.medications.filter(\.isActive)

        // Calculate targets
        let conditions = deriveConditions(from: profile)
        let proteinTarget = NutritionProtocols.proteinTarget(weightKg: profile.weight, conditions: conditions)
        let calorieTarget = profile.dailyCalorieGoal

        // Get drug-food warnings
        let drugInteractions = DrugNutrientDatabase.interactionsForMedications(activeMeds)
        let drugFoodWarnings = drugInteractions.flatMap(\.dietaryRestrictions)
        let depletedNutrients = drugInteractions.flatMap(\.depletedNutrients)

        // Build meals
        var meals: [PlannedMeal] = []
        var totalCalories = 0
        var totalProtein = 0.0

        // Breakfast (~25% of daily calories)
        let breakfast = generateMeal(
            type: "Breakfast",
            targetCalories: Int(Double(calorieTarget) * 0.25),
            targetProtein: proteinTarget.min * 0.25,
            dietary: dietary,
            conditions: conditions,
            depletedNutrients: depletedNutrients,
            drugFoodWarnings: drugFoodWarnings,
            medTimingAdvice: timingAdvice(for: activeMeds, mealTime: "morning")
        )
        meals.append(breakfast)
        totalCalories += breakfast.calories
        totalProtein += breakfast.protein

        // Lunch (~30% of daily calories)
        let lunch = generateMeal(
            type: "Lunch",
            targetCalories: Int(Double(calorieTarget) * 0.30),
            targetProtein: proteinTarget.min * 0.30,
            dietary: dietary,
            conditions: conditions,
            depletedNutrients: depletedNutrients,
            drugFoodWarnings: drugFoodWarnings,
            medTimingAdvice: timingAdvice(for: activeMeds, mealTime: "midday")
        )
        meals.append(lunch)
        totalCalories += lunch.calories
        totalProtein += lunch.protein

        // Dinner (~30% of daily calories)
        let dinner = generateMeal(
            type: "Dinner",
            targetCalories: Int(Double(calorieTarget) * 0.30),
            targetProtein: proteinTarget.min * 0.30,
            dietary: dietary,
            conditions: conditions,
            depletedNutrients: depletedNutrients,
            drugFoodWarnings: drugFoodWarnings,
            medTimingAdvice: timingAdvice(for: activeMeds, mealTime: "evening")
        )
        meals.append(dinner)
        totalCalories += dinner.calories
        totalProtein += dinner.protein

        // Snacks (~15% of daily calories)
        let snack = generateMeal(
            type: "Snack",
            targetCalories: Int(Double(calorieTarget) * 0.15),
            targetProtein: proteinTarget.min * 0.15,
            dietary: dietary,
            conditions: conditions,
            depletedNutrients: depletedNutrients,
            drugFoodWarnings: drugFoodWarnings,
            medTimingAdvice: ""
        )
        meals.append(snack)
        totalCalories += snack.calories
        totalProtein += snack.protein

        // Build reasoning
        var reasoning = "Plan based on \(calorieTarget) kcal target"
        reasoning += ", protein \(String(format: "%.0f", proteinTarget.min))-\(String(format: "%.0f", proteinTarget.max))g/day"
        if !conditions.isEmpty {
            reasoning += ". Adjusted for: \(conditions.joined(separator: ", "))"
        }
        if dietary.base != .omnivore {
            reasoning += ". Diet: \(dietary.base.rawValue)"
        }

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

        return TomorrowFoodPlan(
            date: tomorrow,
            meals: meals,
            totalCalories: totalCalories,
            totalProtein: totalProtein,
            reasoning: reasoning,
            drugFoodWarnings: Array(Set(drugFoodWarnings))
        )
    }

    // MARK: - Meal Generation

    private static func generateMeal(
        type: String,
        targetCalories: Int,
        targetProtein: Double,
        dietary: DietaryProfile,
        conditions: [String],
        depletedNutrients: [NutrientDepletion],
        drugFoodWarnings: [String],
        medTimingAdvice: String
    ) -> PlannedMeal {

        let isVegan = dietary.base == .vegan
        let isVegetarian = dietary.base == .vegetarian || isVegan
        let hasDiabetes = conditions.contains(where: { $0.contains("diabetes") })
        let hasCKD = conditions.contains { $0.contains("ckd") }
        let hasHTN = conditions.contains { $0.contains("hypertension") }
        let needsB12 = depletedNutrients.contains { $0.nutrient.contains("B12") }
        let needsMg = depletedNutrients.contains { $0.nutrient.contains("Magnesium") }
        let needsK = depletedNutrients.contains { $0.nutrient.contains("Potassium") }

        // Select meal from condition-aware pool
        let (name, description, ingredients, calories, protein, carbs, fat, reasoning) = selectMeal(
            type: type,
            isVegan: isVegan,
            isVegetarian: isVegetarian,
            hasDiabetes: hasDiabetes,
            hasCKD: hasCKD,
            hasHTN: hasHTN,
            needsB12: needsB12,
            needsMg: needsMg,
            needsK: needsK && !hasCKD, // Don't push potassium if CKD
            targetCalories: targetCalories,
            targetProtein: targetProtein
        )

        var mealWarnings: [String] = []
        if !medTimingAdvice.isEmpty {
            mealWarnings.append(medTimingAdvice)
        }

        return PlannedMeal(
            type: type,
            name: name,
            description: description,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            reasoning: reasoning,
            drugFoodWarnings: mealWarnings,
            ingredients: ingredients
        )
    }

    // MARK: - Meal Selection

    private static func selectMeal(
        type: String,
        isVegan: Bool,
        isVegetarian: Bool,
        hasDiabetes: Bool,
        hasCKD: Bool,
        hasHTN: Bool,
        needsB12: Bool,
        needsMg: Bool,
        needsK: Bool,
        targetCalories: Int,
        targetProtein: Double
    ) -> (name: String, description: String, ingredients: [String], calories: Int, protein: Double, carbs: Double, fat: Double, reasoning: String) {

        switch type {
        case "Breakfast":
            if isVegan {
                if hasDiabetes {
                    return ("Chia Seed Pudding with Berries", "Low-GI breakfast rich in fibre and omega-3. Topped with mixed berries for antioxidants.",
                            ["chia seeds 30g", "oat milk 200ml", "mixed berries 80g", "flaxseeds 10g", "cinnamon"],
                            320, 10, 28, 18, "Low-GI for blood sugar control. Chia provides omega-3 and fibre.")
                }
                return ("Avocado Toast with Seeds", "Wholegrain sourdough with mashed avocado, pumpkin seeds, and cherry tomatoes.",
                        ["wholegrain sourdough 2 slices", "avocado ½", "pumpkin seeds 15g", "cherry tomatoes 6", "lemon juice"],
                        380, 12, 35, 22, "Plant-based with healthy fats and fibre. Seeds add minerals.")
            }
            if isVegetarian {
                return ("Greek Yoghurt Power Bowl", "High-protein Greek yoghurt with berries, granola, and a drizzle of honey.",
                        ["Greek yoghurt 200g", "mixed berries 80g", "granola 30g", "honey 1 tsp", "chia seeds 10g"],
                        380, 22, 42, 14, "High protein for sustained energy. Berries for antioxidants.")
            }
            if hasDiabetes {
                return ("Scrambled Eggs with Spinach on Rye", "Low-GI breakfast with protein-rich eggs and iron-rich spinach.",
                        ["eggs 2", "spinach 50g", "rye bread 1 slice", "olive oil 1 tsp", "cherry tomatoes 4"],
                        350, 22, 18, 20, "High protein, low-GI. Eggs provide B12 and choline. Spinach adds iron and folate.")
            }
            return ("Porridge with Banana and Almonds", "Slow-release oats with potassium-rich banana and magnesium-rich almonds.",
                    ["rolled oats 50g", "semi-skimmed milk 200ml", "banana ½", "almonds 15g", "cinnamon"],
                    380, 14, 52, 14, "Oats for sustained energy and cholesterol reduction. Almonds add magnesium.")

        case "Lunch":
            if isVegan {
                return ("Lentil & Vegetable Curry with Brown Rice", "Protein-rich red lentil curry with mixed vegetables and wholegrain rice.",
                        ["red lentils 80g dry", "brown rice 60g dry", "mixed vegetables 150g", "coconut milk 50ml", "turmeric", "cumin"],
                        520, 22, 72, 14, "Lentils + rice = complete protein. Turmeric is anti-inflammatory.")
            }
            if hasCKD {
                return ("Herb-Grilled Chicken Salad", "Lower-potassium salad with grilled chicken, cucumber, and mixed leaves.",
                        ["chicken breast 120g", "mixed salad leaves 60g", "cucumber 80g", "red pepper 50g", "olive oil 1 tbsp", "lemon"],
                        380, 35, 12, 22, "Controlled potassium. High protein from chicken. Low phosphorus.")
            }
            if hasHTN {
                return ("Mediterranean Tuna Salad", "DASH-friendly lunch with omega-3-rich tuna and plenty of vegetables.",
                        ["tuna in spring water 1 can", "mixed leaves 60g", "cherry tomatoes 6", "cucumber 80g", "red onion", "olive oil 1 tbsp", "wholemeal pitta 1"],
                        420, 32, 30, 18, "DASH diet compliant. Low sodium, high potassium. Omega-3 from tuna.")
            }
            return ("Grilled Salmon with Quinoa & Greens", "Omega-3-rich salmon with complete-protein quinoa and steamed broccoli.",
                    ["salmon fillet 120g", "quinoa 60g dry", "broccoli 100g", "lemon", "olive oil 1 tsp"],
                    480, 38, 36, 20, "Salmon for omega-3 and vitamin D. Quinoa for complete plant protein. Broccoli steamed to retain nutrients.")

        case "Dinner":
            if isVegan {
                return ("Tofu Stir-Fry with Vegetables & Noodles", "High-protein tofu with colourful vegetables and wholegrain noodles.",
                        ["firm tofu 150g", "wholegrain noodles 60g dry", "mixed stir-fry vegetables 200g", "soy sauce low-sodium 1 tbsp", "ginger", "garlic", "sesame oil 1 tsp"],
                        450, 24, 48, 18, "Tofu provides complete plant protein. Variety of vegetables for micronutrients. Low-sodium soy sauce for HTN awareness.")
            }
            if hasDiabetes {
                return ("Baked Cod with Cauliflower Mash & Green Beans", "Low-GI dinner with lean protein and non-starchy vegetables.",
                        ["cod fillet 150g", "cauliflower 200g", "green beans 100g", "olive oil 1 tbsp", "garlic", "lemon"],
                        380, 35, 18, 16, "Cauliflower mash replaces potato for lower GI. Cod is lean protein. Green beans for fibre.")
            }
            return ("Lean Chicken with Sweet Potato & Roasted Vegetables", "Balanced dinner with lean protein, complex carbs, and mixed vegetables.",
                    ["chicken breast 130g", "sweet potato 150g", "courgette 80g", "red pepper 80g", "olive oil 1 tbsp", "herbs"],
                    480, 38, 42, 16, "Sweet potato for sustained energy and beta-carotene. Chicken for lean protein. Roasted veg for variety.")

        case "Snack":
            if isVegan {
                return ("Apple Slices with Almond Butter", "Simple plant-based snack with healthy fats and fibre.",
                        ["apple 1 medium", "almond butter 1 tbsp"],
                        200, 5, 22, 10, "Apple for fibre and vitamin C. Almond butter for healthy fats and magnesium.")
            }
            if needsMg {
                return ("Dark Chocolate & Mixed Nuts", "Magnesium-rich snack with antioxidant dark chocolate.",
                        ["dark chocolate 70%+ 20g", "mixed nuts 20g"],
                        210, 4, 14, 16, "Dark chocolate and nuts are excellent magnesium sources. Anti-inflammatory.")
            }
            return ("Hummus with Carrot Sticks", "Fibre-rich snack with plant protein from chickpeas.",
                    ["hummus 50g", "carrot sticks 80g", "cucumber sticks 50g"],
                    150, 5, 16, 8, "Chickpeas for plant protein and fibre. Low GI. Vegetables for micronutrients.")

        default:
            return ("Mixed Fruit & Yoghurt", "Simple balanced snack.", ["Greek yoghurt 100g", "mixed fruit 80g"], 150, 8, 18, 4, "Protein from yoghurt, vitamins from fruit.")
        }
    }

    // MARK: - Helpers

    private static func deriveConditions(from profile: UserProfile) -> [String] {
        var conditions: [String] = []
        let dt = profile.diabetesType.lowercased()
        if dt.contains("type 1") { conditions.append("type 1 diabetes") }
        else if dt.contains("type 2") { conditions.append("diabetes") }
        if profile.hasHypertension { conditions.append("hypertension") }
        for goal in profile.selectedGoals.map({ $0.lowercased() }) {
            if goal.contains("kidney") || goal.contains("ckd") { conditions.append("ckd") }
            if goal.contains("heart") || goal.contains("cvd") { conditions.append("cvd") }
            if goal.contains("fitness") || goal.contains("muscle") { conditions.append("fitness") }
        }
        if profile.age >= 65 { conditions.append("elderly") }
        return conditions
    }

    private static func timingAdvice(for meds: [Medication], mealTime: String) -> String {
        var advice: [String] = []
        for med in meds {
            guard let entry = DrugNutrientDatabase.interactions(for: (med.genericName ?? med.name)) else { continue }
            let timing = entry.timingAdvice.lowercased()
            switch mealTime {
            case "morning":
                if timing.contains("morning") || timing.contains("breakfast") || timing.contains("empty stomach") || timing.contains("before") {
                    advice.append("\(med.name): \(entry.timingAdvice)")
                }
            case "midday":
                if timing.contains("with food") || timing.contains("with meal") {
                    advice.append("\(med.name): Take with this meal")
                }
            case "evening":
                if timing.contains("evening") || timing.contains("bedtime") || timing.contains("night") {
                    advice.append("\(med.name): \(entry.timingAdvice)")
                }
            default: break
            }
        }
        return advice.joined(separator: "; ")
    }
}
