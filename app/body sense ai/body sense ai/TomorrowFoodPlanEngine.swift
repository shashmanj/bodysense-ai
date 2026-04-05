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

        // Day seed ensures different meals on different days
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let daySeed = daySeedFromDate(tomorrow)

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
            medTimingAdvice: timingAdvice(for: activeMeds, mealTime: "morning"),
            daySeed: daySeed
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
            medTimingAdvice: timingAdvice(for: activeMeds, mealTime: "midday"),
            daySeed: daySeed
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
            medTimingAdvice: timingAdvice(for: activeMeds, mealTime: "evening"),
            daySeed: daySeed
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
            medTimingAdvice: "",
            daySeed: daySeed
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

        return TomorrowFoodPlan(
            date: tomorrow,
            meals: meals,
            totalCalories: totalCalories,
            totalProtein: totalProtein,
            reasoning: reasoning,
            drugFoodWarnings: Array(Set(drugFoodWarnings)),
            generatedAt: Date()
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
        medTimingAdvice: String,
        daySeed: Int
    ) -> PlannedMeal {

        let isVegan = dietary.base == .vegan
        let isVegetarian = dietary.base == .vegetarian || isVegan
        let hasDiabetes = conditions.contains(where: { $0.contains("diabetes") })
        let hasCKD = conditions.contains { $0.contains("ckd") }
        let hasHTN = conditions.contains { $0.contains("hypertension") }
        let needsB12 = depletedNutrients.contains { $0.nutrient.contains("B12") }
        let needsMg = depletedNutrients.contains { $0.nutrient.contains("Magnesium") }
        let needsK = depletedNutrients.contains { $0.nutrient.contains("Potassium") }

        // Extract primary cuisine preference
        let cuisine: CuisineType = dietary.cuisinePreference

        // Select meal from condition-aware pool
        let (name, description, ingredients, calories, protein, carbs, fat, fiber, reasoning) = selectMeal(
            type: type,
            cuisine: cuisine,
            isVegan: isVegan,
            isVegetarian: isVegetarian,
            hasDiabetes: hasDiabetes,
            hasCKD: hasCKD,
            hasHTN: hasHTN,
            needsB12: needsB12,
            needsMg: needsMg,
            needsK: needsK && !hasCKD, // Don't push potassium if CKD
            targetCalories: targetCalories,
            targetProtein: targetProtein,
            daySeed: daySeed
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
            fiber: fiber,
            reasoning: reasoning,
            drugFoodWarnings: mealWarnings,
            ingredients: ingredients
        )
    }

    // MARK: - Meal Selection

    // swiftlint:disable:next function_body_length
    private static func selectMeal(
        type: String,
        cuisine: CuisineType,
        isVegan: Bool,
        isVegetarian: Bool,
        hasDiabetes: Bool,
        hasCKD: Bool,
        hasHTN: Bool,
        needsB12: Bool,
        needsMg: Bool,
        needsK: Bool,
        targetCalories: Int,
        targetProtein: Double,
        daySeed: Int
    ) -> (name: String, description: String, ingredients: [String], calories: Int, protein: Double, carbs: Double, fat: Double, fiber: Double, reasoning: String) {

        // Helper: pick from an array of meal options using the day seed
        typealias MealOption = (name: String, description: String, ingredients: [String], calories: Int, protein: Double, carbs: Double, fat: Double, fiber: Double, reasoning: String)
        func pick(_ options: [MealOption]) -> MealOption {
            guard options.count > 1 else { return options[0] }
            return options[daySeed % options.count]
        }

        switch type {
        case "Breakfast":
            // ── South Indian cuisine ──
            if cuisine == .southIndian {
                if isVegan {
                    if hasDiabetes {
                        return pick([
                            ("Ragi Dosa with Coconut Chutney", "Low-GI finger millet crepe with fresh coconut chutney. Vegan and diabetes-friendly.",
                             ["ragi flour 60g", "rice flour 20g", "coconut chutney 2 tbsp", "mustard seeds", "curry leaves"],
                             280, 8.0, 38.0, 8.0, 6.0, "Ragi is low-GI and rich in calcium. Coconut chutney adds healthy fats."),
                            ("Pesarattu with Ginger Chutney", "Moong dal crepe served with spicy ginger chutney. High protein, low GI.",
                             ["green moong dal 80g", "ginger chutney 2 tbsp", "green chilli", "cumin seeds", "coriander"],
                             290, 14.0, 34.0, 6.0, 8.0, "Moong dal is low-GI with excellent plant protein. Ginger aids digestion.")
                        ])
                    }
                    return pick([
                        ("Upma with Vegetables", "Semolina porridge with mustard seeds, curry leaves, and mixed vegetables.",
                         ["semolina 50g", "mixed vegetables 80g", "mustard seeds", "curry leaves", "cashews 10g", "coconut oil 1 tsp"],
                         340, 9.0, 48.0, 12.0, 4.0, "Semolina provides energy. Vegetables add fibre and vitamins. Cashews add healthy fats."),
                        ("Poha with Peanuts & Curry Leaves", "Flattened rice with peanuts, turmeric, and curry leaves.",
                         ["flattened rice 60g", "peanuts 20g", "turmeric", "curry leaves", "mustard seeds", "lime juice"],
                         330, 9.0, 44.0, 12.0, 3.0, "Light yet filling. Peanuts add protein. Turmeric is anti-inflammatory."),
                        ("Ragi Porridge with Jaggery", "Finger millet porridge sweetened with jaggery and cardamom.",
                         ["ragi flour 40g", "coconut milk 200ml", "jaggery 1 tsp", "cardamom", "cashews 5g"],
                         310, 8.0, 44.0, 10.0, 5.0, "Ragi is rich in calcium and iron. Jaggery provides minerals. Cardamom aids digestion.")
                    ])
                }
                if hasDiabetes {
                    return pick([
                        ("Ragi Dosa with Coconut Chutney", "Low-GI finger millet crepe with fresh coconut chutney.",
                         ["ragi flour 60g", "rice flour 20g", "coconut chutney 2 tbsp", "mustard seeds", "curry leaves"],
                         290, 9.0, 38.0, 10.0, 6.0, "Ragi is low-GI and rich in calcium. Excellent for blood sugar control."),
                        ("Pesarattu with Ginger Chutney", "Moong dal crepe served with spicy ginger chutney. High protein, low GI.",
                         ["green moong dal 80g", "ginger chutney 2 tbsp", "green chilli", "cumin seeds", "coriander"],
                         300, 15.0, 34.0, 8.0, 8.0, "Moong dal is low-GI with excellent plant protein. Ginger aids digestion."),
                        ("Oats Idli with Sambar", "Steamed oat cakes with lentil-vegetable stew. Low-GI and high fibre.",
                         ["oats 50g", "semolina 20g", "sambar 150ml", "curd 30g", "mustard seeds", "curry leaves"],
                         310, 12.0, 40.0, 8.0, 7.0, "Oats replace rice for lower GI. Sambar adds lentil protein. Fermented batter aids digestion."),
                        ("Vegetable Uttapam", "Thick rice-lentil pancake topped with onions, tomatoes, and green chillies.",
                         ["uttapam batter 100g", "onion 30g", "tomato 30g", "green chilli", "coconut chutney 2 tbsp"],
                         320, 10.0, 42.0, 10.0, 5.0, "Fermented batter aids gut health. Topped vegetables add fibre. Lower GI than dosa.")
                    ])
                }
                if hasCKD {
                    return pick([
                        ("Idli with Coconut Chutney", "Steamed rice-lentil cakes with fresh coconut chutney. Light on kidneys.",
                         ["idli 3 pieces", "coconut chutney 2 tbsp", "ginger"],
                         300, 8.0, 48.0, 8.0, 3.0, "Low potassium, controlled protein. Coconut chutney avoids high-potassium accompaniments."),
                        ("Upma with Coconut", "Semolina porridge with grated coconut and mild spices.",
                         ["semolina 50g", "grated coconut 15g", "mustard seeds", "curry leaves", "ghee 1 tsp"],
                         320, 8.0, 46.0, 10.0, 3.0, "Low potassium. Semolina is kidney-friendly. Coconut adds healthy fats.")
                    ])
                }
                // Default South Indian breakfast
                return pick([
                    ("Idli with Sambar & Coconut Chutney", "Steamed rice-lentil cakes with lentil-vegetable stew and fresh coconut chutney.",
                     ["idli 3 pieces", "sambar 150ml", "coconut chutney 2 tbsp", "drumstick", "carrot"],
                     360, 12.0, 56.0, 8.0, 4.0, "Fermented batter aids digestion. Sambar provides lentil protein and vegetable nutrition."),
                    ("Masala Dosa with Sambar", "Crispy fermented crepe filled with spiced potato, served with sambar.",
                     ["dosa batter 100g", "potato 80g", "mustard seeds", "curry leaves", "sambar 100ml"],
                     400, 10.0, 54.0, 14.0, 4.0, "Fermented batter for gut health. Potato provides energy. Sambar adds protein."),
                    ("Upma with Vegetables", "Semolina porridge with mustard seeds, curry leaves, and mixed vegetables.",
                     ["semolina 50g", "mixed vegetables 80g", "mustard seeds", "curry leaves", "cashews 10g", "ghee 1 tsp"],
                     360, 10.0, 50.0, 12.0, 4.0, "Semolina provides energy. Vegetables add fibre and vitamins."),
                    ("Pongal with Coconut Chutney", "Creamy rice-lentil porridge tempered with cumin, pepper, and ghee.",
                     ["rice 40g", "moong dal 30g", "ghee 1 tsp", "black pepper", "cumin seeds", "curry leaves", "coconut chutney 2 tbsp"],
                     370, 12.0, 52.0, 10.0, 5.0, "Comforting and nutritious. Moong dal adds protein. Cumin and pepper aid digestion."),
                    ("Appam with Vegetable Stew", "Lacy rice-coconut pancake with a mild coconut vegetable stew.",
                     ["rice batter 80g", "coconut milk 100ml", "mixed vegetables 100g", "cinnamon", "cardamom", "curry leaves"],
                     380, 10.0, 50.0, 14.0, 4.0, "Fermented batter for probiotics. Coconut milk adds healthy fats. Vegetables add vitamins.")
                ])
            }
            // ── North Indian cuisine ──
            if cuisine == .northIndian {
                if hasDiabetes {
                    return pick([
                        ("Moong Dal Cheela with Curd", "Savoury lentil pancake served with spiced yoghurt and fresh coriander.",
                         ["moong dal batter 80g", "onion 30g", "coriander", "natural yoghurt 100g", "cumin"],
                         320, 18.0, 30.0, 10.0, 6.0, "Lentil base for low-GI protein. Yoghurt adds probiotics and calcium."),
                        ("Besan Chilla with Mint Chutney", "Gram flour pancake with vegetables and fresh mint chutney.",
                         ["besan 60g", "onion 30g", "tomato 30g", "green chilli", "mint chutney 2 tbsp"],
                         300, 14.0, 32.0, 10.0, 6.0, "Besan is low-GI and protein-rich. Mint chutney aids digestion.")
                    ])
                }
                return pick([
                    ("Aloo Paratha with Curd", "Stuffed potato flatbread served with fresh yoghurt and pickle.",
                     ["wholemeal flour 60g", "potato 60g", "butter 1 tsp", "natural yoghurt 80g", "cumin"],
                     420, 12.0, 52.0, 16.0, 5.0, "Wholemeal flour for fibre. Yoghurt adds probiotics and calcium. Potato provides energy."),
                    ("Poha with Peanuts", "Flattened rice with peanuts, turmeric, and fresh coriander.",
                     ["flattened rice 60g", "peanuts 20g", "turmeric", "mustard seeds", "curry leaves", "lime juice"],
                     350, 10.0, 46.0, 14.0, 3.0, "Light and nutritious. Peanuts add protein. Turmeric is anti-inflammatory."),
                    ("Chole Bhature Light", "Chickpea curry with baked wholemeal bhatura.",
                     ["chickpeas 80g cooked", "wholemeal flour bhatura 1", "onion 30g", "tomato 50g", "garam masala"],
                     440, 16.0, 56.0, 14.0, 8.0, "Chickpeas for protein and fibre. Baked bhatura reduces oil.")
                ])
            }
            // ── Default / Western / Mixed cuisine ──
            if isVegan {
                if hasDiabetes {
                    return pick([
                        ("Chia Seed Pudding with Berries", "Low-GI breakfast rich in fibre and omega-3. Topped with mixed berries for antioxidants.",
                         ["chia seeds 30g", "oat milk 200ml", "mixed berries 80g", "flaxseeds 10g", "cinnamon"],
                         320, 10.0, 28.0, 18.0, 10.0, "Low-GI for blood sugar control. Chia provides omega-3 and fibre."),
                        ("Moong Dal Chilla with Chutney", "High-protein savoury crepe made from green gram, served with mint chutney.",
                         ["moong dal batter 80g", "onion 30g", "tomato 30g", "green chilli", "coriander", "mint chutney 2 tbsp"],
                         290, 14.0, 32.0, 8.0, 8.0, "Low-GI legume base for steady blood sugar. High protein from moong dal."),
                        ("Oat & Flax Smoothie Bowl", "Blended oats with flaxseeds, topped with nuts and seeds for sustained energy.",
                         ["rolled oats 40g", "flaxseeds 15g", "almond milk 200ml", "walnuts 10g", "pumpkin seeds 10g"],
                         310, 11.0, 30.0, 16.0, 8.0, "Slow-release carbs from oats. Omega-3 from flax and walnuts.")
                    ])
                }
                return pick([
                    ("Avocado Toast with Seeds", "Wholegrain sourdough with mashed avocado, pumpkin seeds, and cherry tomatoes.",
                     ["wholegrain sourdough 2 slices", "avocado ½", "pumpkin seeds 15g", "cherry tomatoes 6", "lemon juice"],
                     380, 12.0, 35.0, 22.0, 8.0, "Plant-based with healthy fats and fibre. Seeds add minerals."),
                    ("Ragi Porridge with Dates", "Finger millet porridge sweetened with dates, rich in calcium and iron.",
                     ["ragi flour 40g", "almond milk 200ml", "dates 2 chopped", "cardamom", "almonds 10g"],
                     340, 10.0, 48.0, 10.0, 6.0, "Ragi is rich in calcium and iron. Dates provide natural sweetness and fibre."),
                    ("Poha with Peanuts & Lime", "Flattened rice with peanuts, turmeric, curry leaves, and fresh lime.",
                     ["flattened rice 60g", "peanuts 20g", "turmeric", "curry leaves", "mustard seeds", "lime juice"],
                     350, 9.0, 46.0, 14.0, 3.0, "Light yet filling. Peanuts add protein. Turmeric is anti-inflammatory.")
                ])
            }
            if isVegetarian {
                return pick([
                    ("Greek Yoghurt Power Bowl", "High-protein Greek yoghurt with berries, granola, and a drizzle of honey.",
                     ["Greek yoghurt 200g", "mixed berries 80g", "granola 30g", "honey 1 tsp", "chia seeds 10g"],
                     380, 22.0, 42.0, 14.0, 5.0, "High protein for sustained energy. Berries for antioxidants."),
                    ("South Indian Idli Sambar", "Steamed rice-lentil cakes with vegetable sambar and coconut chutney.",
                     ["idli 3 pieces", "sambar 150ml", "coconut chutney 2 tbsp", "drumstick", "carrot"],
                     360, 12.0, 56.0, 8.0, 4.0, "Fermented batter aids digestion. Sambar provides lentil protein and vegetable nutrition."),
                    ("Masala Dosa with Chutney", "Crispy fermented crepe filled with spiced potato, served with coconut chutney.",
                     ["dosa batter 100g", "potato 80g", "mustard seeds", "curry leaves", "coconut chutney 2 tbsp"],
                     390, 10.0, 52.0, 14.0, 3.0, "Fermented batter for gut health. Potato provides potassium and energy.")
                ])
            }
            if hasDiabetes {
                return pick([
                    ("Scrambled Eggs with Spinach on Rye", "Low-GI breakfast with protein-rich eggs and iron-rich spinach.",
                     ["eggs 2", "spinach 50g", "rye bread 1 slice", "olive oil 1 tsp", "cherry tomatoes 4"],
                     350, 22.0, 18.0, 20.0, 3.0, "High protein, low-GI. Eggs provide B12 and choline. Spinach adds iron and folate."),
                    ("Vegetable Omelette with Multigrain Toast", "Fluffy omelette with peppers, mushrooms, and a slice of multigrain bread.",
                     ["eggs 2", "red pepper 40g", "mushrooms 40g", "multigrain bread 1 slice", "olive oil 1 tsp"],
                     340, 21.0, 20.0, 18.0, 4.0, "Low-GI multigrain bread. Eggs for sustained protein. Vegetables add fibre."),
                    ("Moong Dal Cheela with Curd", "Savoury lentil pancake served with spiced yoghurt and fresh coriander.",
                     ["moong dal batter 80g", "onion 30g", "coriander", "natural yoghurt 100g", "cumin"],
                     320, 18.0, 30.0, 10.0, 6.0, "Lentil base for low-GI protein. Yoghurt adds probiotics and calcium.")
                ])
            }
            return pick([
                ("Porridge with Banana and Almonds", "Slow-release oats with potassium-rich banana and magnesium-rich almonds.",
                 ["rolled oats 50g", "semi-skimmed milk 200ml", "banana ½", "almonds 15g", "cinnamon"],
                 380, 14.0, 52.0, 14.0, 7.0, "Oats for sustained energy and cholesterol reduction. Almonds add magnesium."),
                ("Upma with Vegetables", "Semolina savoury porridge with mustard seeds, curry leaves, and mixed vegetables.",
                 ["semolina 50g", "mixed vegetables 80g", "mustard seeds", "curry leaves", "cashews 10g", "ghee 1 tsp"],
                 360, 10.0, 50.0, 12.0, 4.0, "Semolina provides energy. Vegetables add fibre and vitamins. Cashews add healthy fats."),
                ("Egg & Avocado on Sourdough", "Poached egg on sourdough with sliced avocado and cherry tomatoes.",
                 ["egg 1", "sourdough 1 slice", "avocado ¼", "cherry tomatoes 4", "black pepper"],
                 370, 16.0, 32.0, 20.0, 4.0, "Balanced macros. Avocado for healthy fats. Egg for complete protein.")
            ])

        case "Lunch":
            // ── South Indian cuisine ──
            if cuisine == .southIndian {
                if isVegan {
                    return pick([
                        ("Sambar Rice with Poriyal", "Lentil-vegetable stew over rice with dry vegetable stir-fry.",
                         ["toor dal 60g dry", "basmati rice 60g dry", "mixed vegetables 120g", "tamarind", "sambar powder", "coconut oil 1 tsp"],
                         480, 16.0, 72.0, 10.0, 10.0, "Lentils + rice = complete protein. Vegetables add fibre. Tamarind aids iron absorption."),
                        ("Lemon Rice with Papad", "Tangy rice with peanuts, turmeric, and curry leaves, served with a crispy papad.",
                         ["basmati rice 60g dry", "lemon juice", "peanuts 15g", "turmeric", "curry leaves", "mustard seeds", "papad 1"],
                         420, 10.0, 64.0, 12.0, 4.0, "Light and easy to digest. Peanuts add protein. Lemon provides vitamin C."),
                        ("Bisi Bele Bath", "One-pot Karnataka rice-lentil dish with vegetables and tamarind.",
                         ["basmati rice 50g dry", "toor dal 40g dry", "mixed vegetables 100g", "tamarind", "bisi bele bath powder", "ghee 1 tsp"],
                         470, 14.0, 68.0, 12.0, 8.0, "Balanced one-pot meal. Dal and rice provide complete protein. Rich in vegetables.")
                    ])
                }
                if hasDiabetes {
                    return pick([
                        ("Millets Rice with Rasam & Poriyal", "Low-GI millet replacing white rice, with tangy rasam and vegetable stir-fry.",
                         ["foxtail millet 60g dry", "rasam 150ml", "mixed vegetables 100g", "coconut oil 1 tsp", "curry leaves"],
                         420, 14.0, 56.0, 12.0, 9.0, "Millets are low-GI for blood sugar control. Rasam aids digestion. Vegetables add fibre."),
                        ("Sambar Rice with Vegetables", "Lentil-vegetable stew with controlled rice portions and extra vegetables.",
                         ["toor dal 60g dry", "brown rice 40g dry", "drumstick 1", "beans 50g", "carrot 40g", "sambar powder"],
                         400, 16.0, 54.0, 10.0, 10.0, "Brown rice for lower GI. Extra vegetables increase fibre. Dal provides plant protein."),
                        ("Ragi Mudde with Sambar", "Finger millet ball with lentil-vegetable stew. Traditional Karnataka diabetes-friendly meal.",
                         ["ragi flour 60g", "sambar 200ml", "drumstick 1", "brinjal 40g"],
                         380, 14.0, 52.0, 8.0, 8.0, "Ragi is low-GI and calcium-rich. Sambar provides protein. Traditional and satisfying.")
                    ])
                }
                if hasCKD {
                    return pick([
                        ("Curd Rice with Cucumber Raita", "Cooling yoghurt rice with cucumber. Low potassium, easy on kidneys.",
                         ["basmati rice 60g dry", "yoghurt 100g", "cucumber 60g", "mustard seeds", "curry leaves", "ginger"],
                         380, 12.0, 54.0, 10.0, 2.0, "Low potassium. Yoghurt adds protein and probiotics. Cucumber is kidney-friendly."),
                        ("Vegetable Kootu with Rice", "Mild vegetable-lentil stew with controlled rice portions.",
                         ["basmati rice 50g dry", "moong dal 30g dry", "snake gourd 60g", "chayote 60g", "coconut 10g"],
                         360, 12.0, 50.0, 10.0, 5.0, "Low-potassium vegetables. Controlled protein from dal. Light and easy to digest."),
                        ("Lemon Rice with Papad", "Tangy lemon rice with peanuts and a crispy papad.",
                         ["basmati rice 60g dry", "lemon juice", "peanuts 10g", "turmeric", "curry leaves", "papad 1"],
                         380, 10.0, 56.0, 10.0, 3.0, "Low potassium. Lemon provides vitamin C. Light and kidney-friendly.")
                    ])
                }
                // Default South Indian lunch
                return pick([
                    ("Sambar Rice with Poriyal & Papad", "Classic South Indian meal with lentil stew, dry vegetable, and crispy papad.",
                     ["toor dal 60g dry", "basmati rice 60g dry", "drumstick 1", "beans 50g", "sambar powder", "papad 1"],
                     480, 16.0, 68.0, 12.0, 9.0, "Lentils for plant protein. Vegetables add fibre. Tamarind aids iron absorption."),
                    ("Rasam Rice with Vegetable Kootu", "Tangy pepper-tamarind broth with rice and a mild vegetable-lentil stew.",
                     ["basmati rice 60g dry", "rasam 150ml", "moong dal 30g dry", "mixed vegetables 100g", "coconut 10g"],
                     450, 14.0, 64.0, 12.0, 8.0, "Rasam aids digestion with pepper and cumin. Kootu adds vegetable and dal nutrition."),
                    ("Curd Rice with Pickle & Papad", "Cooling yoghurt rice with South Indian pickle and a crispy papad.",
                     ["basmati rice 60g dry", "yoghurt 120g", "pickle 1 tsp", "mustard seeds", "curry leaves", "papad 1"],
                     420, 14.0, 58.0, 12.0, 2.0, "Yoghurt for probiotics and protein. Comforting and easy to digest."),
                    ("Bisi Bele Bath", "One-pot Karnataka rice-lentil dish with vegetables and tamarind.",
                     ["basmati rice 50g dry", "toor dal 40g dry", "mixed vegetables 100g", "tamarind", "bisi bele bath powder", "ghee 1 tsp"],
                     470, 14.0, 68.0, 12.0, 8.0, "Balanced one-pot meal. Dal and rice provide complete protein. Rich in vegetables."),
                    ("Lemon Rice with Raita", "Tangy lemon rice with peanuts, served with cooling cucumber raita.",
                     ["basmati rice 60g dry", "lemon juice", "peanuts 15g", "turmeric", "curry leaves", "yoghurt 60g", "cucumber 30g"],
                     440, 12.0, 62.0, 14.0, 4.0, "Light and easy to digest. Peanuts add protein. Raita adds probiotics.")
                ])
            }
            // ── North Indian cuisine ──
            if cuisine == .northIndian {
                if hasDiabetes {
                    return pick([
                        ("Moong Dal Khichdi with Raita", "Comforting lentil-rice porridge with cooling yoghurt raita.",
                         ["moong dal 50g dry", "brown rice 50g dry", "ghee 1 tsp", "cumin seeds", "turmeric", "yoghurt 80g", "cucumber 30g"],
                         420, 18.0, 56.0, 12.0, 8.0, "Low-GI dal + rice combo. Moong is the easiest-digesting lentil. Raita aids digestion."),
                        ("Rajma with Brown Rice", "Kidney bean curry with brown rice for low-GI lunch.",
                         ["kidney beans 100g cooked", "brown rice 50g dry", "tomatoes 80g", "onion 40g", "cumin seeds", "garam masala"],
                         460, 18.0, 66.0, 10.0, 12.0, "Brown rice for lower GI. Kidney beans are high in protein and fibre.")
                    ])
                }
                return pick([
                    ("Rajma Chawal", "Kidney bean curry with steamed basmati rice.",
                     ["kidney beans 100g cooked", "basmati rice 60g dry", "tomatoes 80g", "onion 40g", "cumin seeds", "garam masala"],
                     500, 18.0, 72.0, 12.0, 10.0, "Kidney beans are high in protein and fibre. Classic comfort food."),
                    ("Dal Tadka with Roti & Salad", "Yellow lentil curry with wholemeal roti and fresh salad.",
                     ["yellow dal 60g dry", "wholemeal roti 2", "ghee 1 tsp", "cumin seeds", "garlic", "mixed salad 40g"],
                     470, 18.0, 60.0, 14.0, 10.0, "Lentils for plant protein. Wholemeal roti for fibre. Balanced and comforting."),
                    ("Chole with Rice", "Chickpea curry with steamed rice and fresh coriander.",
                     ["chickpeas 100g cooked", "basmati rice 60g dry", "tomatoes 80g", "onion 40g", "garam masala", "coriander"],
                     490, 18.0, 70.0, 12.0, 10.0, "Chickpeas for protein and fibre. Aromatic spices aid digestion.")
                ])
            }
            // ── Default / Western / Mixed cuisine ──
            if isVegan {
                return pick([
                    ("Lentil & Vegetable Curry with Brown Rice", "Protein-rich red lentil curry with mixed vegetables and wholegrain rice.",
                     ["red lentils 80g dry", "brown rice 60g dry", "mixed vegetables 150g", "coconut milk 50ml", "turmeric", "cumin"],
                     520, 22.0, 72.0, 14.0, 12.0, "Lentils + rice = complete protein. Turmeric is anti-inflammatory."),
                    ("Chickpea & Spinach Stew with Millet", "Iron-rich chickpea stew with wilted spinach, served over fluffy millet.",
                     ["chickpeas 100g cooked", "spinach 80g", "tomatoes 100g", "millet 60g dry", "cumin", "coriander"],
                     490, 20.0, 68.0, 12.0, 11.0, "Chickpeas for protein and fibre. Spinach for iron. Millet is gluten-free and mineral-rich."),
                    ("Rajma Masala with Jeera Rice", "Kidney bean curry in tomato gravy with cumin-tempered basmati rice.",
                     ["kidney beans 100g cooked", "basmati rice 60g dry", "tomatoes 100g", "onion 50g", "cumin seeds", "garam masala"],
                     510, 18.0, 76.0, 10.0, 10.0, "Kidney beans are high in protein and fibre. Cumin aids digestion.")
                ])
            }
            if hasCKD {
                return pick([
                    ("Herb-Grilled Chicken Salad", "Lower-potassium salad with grilled chicken, cucumber, and mixed leaves.",
                     ["chicken breast 120g", "mixed salad leaves 60g", "cucumber 80g", "red pepper 50g", "olive oil 1 tbsp", "lemon"],
                     380, 35.0, 12.0, 22.0, 3.0, "Controlled potassium. High protein from chicken. Low phosphorus."),
                    ("Egg Fried Rice with Green Beans", "Light egg fried rice with green beans and a hint of ginger.",
                     ["basmati rice 60g dry", "eggs 2", "green beans 60g", "ginger", "sesame oil 1 tsp", "spring onion"],
                     400, 18.0, 50.0, 14.0, 4.0, "Controlled potassium. Eggs for protein. Green beans are lower-potassium vegetables.")
                ])
            }
            if hasHTN {
                return pick([
                    ("Mediterranean Tuna Salad", "DASH-friendly lunch with omega-3-rich tuna and plenty of vegetables.",
                     ["tuna in spring water 1 can", "mixed leaves 60g", "cherry tomatoes 6", "cucumber 80g", "red onion", "olive oil 1 tbsp", "wholemeal pitta 1"],
                     420, 32.0, 30.0, 18.0, 6.0, "DASH diet compliant. Low sodium, high potassium. Omega-3 from tuna."),
                    ("Grilled Chicken & Beetroot Salad", "DASH-friendly salad with lean chicken, beetroot, and walnuts.",
                     ["chicken breast 120g", "beetroot cooked 80g", "rocket leaves 50g", "walnuts 15g", "olive oil 1 tbsp", "balsamic vinegar"],
                     410, 34.0, 22.0, 20.0, 5.0, "DASH compliant. Beetroot supports blood pressure. Walnuts provide omega-3.")
                ])
            }
            return pick([
                ("Grilled Salmon with Quinoa & Greens", "Omega-3-rich salmon with complete-protein quinoa and steamed broccoli.",
                 ["salmon fillet 120g", "quinoa 60g dry", "broccoli 100g", "lemon", "olive oil 1 tsp"],
                 480, 38.0, 36.0, 20.0, 6.0, "Salmon for omega-3 and vitamin D. Quinoa for complete plant protein. Broccoli steamed to retain nutrients."),
                ("South Indian Sambar Rice with Papad", "Hearty lentil-vegetable stew served over rice with a crispy papad.",
                 ["toor dal 60g dry", "basmati rice 60g dry", "drumstick 1", "brinjal 50g", "tamarind", "sambar powder", "papad 1"],
                 470, 16.0, 68.0, 12.0, 9.0, "Lentils for plant protein. Vegetables add fibre. Tamarind aids iron absorption."),
                ("Paneer Tikka Wrap with Raita", "Spiced paneer pieces in a wholemeal wrap with cucumber raita.",
                 ["paneer 100g", "wholemeal wrap 1", "yoghurt 50g", "cucumber 40g", "tikka spices", "onion 30g", "lemon"],
                 490, 28.0, 38.0, 24.0, 5.0, "Paneer for complete protein and calcium. Yoghurt for probiotics. Spices aid digestion.")
            ])

        case "Dinner":
            // ── South Indian cuisine ──
            if cuisine == .southIndian {
                if isVegan {
                    return pick([
                        ("Idiyappam with Vegetable Kurma", "Rice noodle nests with a mild coconut vegetable curry.",
                         ["idiyappam 3 pieces", "mixed vegetables 120g", "coconut milk 80ml", "cinnamon", "cardamom", "curry leaves"],
                         400, 10.0, 56.0, 14.0, 5.0, "Light rice noodles for easy digestion. Coconut milk adds healthy fats. Vegetables provide vitamins."),
                        ("Dosa with Coconut Chutney & Sambar", "Crispy fermented crepe with coconut chutney and lentil-vegetable stew.",
                         ["dosa batter 100g", "coconut chutney 2 tbsp", "sambar 150ml", "drumstick", "curry leaves"],
                         380, 12.0, 52.0, 12.0, 5.0, "Fermented batter for gut health. Sambar adds lentil protein. Light dinner option."),
                        ("Vegetable Stew with Appam", "Mild coconut vegetable stew with lacy rice-coconut pancake.",
                         ["rice batter 80g", "coconut milk 100ml", "potato 40g", "carrot 40g", "beans 30g", "cinnamon", "cardamom"],
                         390, 8.0, 52.0, 14.0, 4.0, "Kerala classic. Coconut milk provides healthy fats. Vegetables add nutrition.")
                    ])
                }
                if hasDiabetes {
                    return pick([
                        ("Ragi Roti with Mixed Vegetable Curry", "Finger millet flatbread with a mild mixed vegetable curry. Low GI.",
                         ["ragi flour 60g", "mixed vegetables 150g", "coconut milk 50ml", "cumin", "coriander"],
                         370, 12.0, 48.0, 12.0, 8.0, "Ragi is low-GI and calcium-rich. Mixed vegetables add fibre. Light dinner for blood sugar control."),
                        ("Pongal with Coconut Chutney", "Creamy rice-lentil porridge tempered with cumin and pepper. Light dinner.",
                         ["rice 30g", "moong dal 40g", "ghee 1 tsp", "black pepper", "cumin seeds", "curry leaves", "coconut chutney 2 tbsp"],
                         350, 14.0, 46.0, 10.0, 6.0, "Moong dal provides protein. Pepper and cumin aid digestion. Light on the stomach.")
                    ])
                }
                if hasCKD {
                    return pick([
                        ("Idiyappam with Coconut Milk", "Rice noodle nests with sweetened coconut milk. Low potassium dinner.",
                         ["idiyappam 3 pieces", "coconut milk 100ml", "cardamom"],
                         340, 6.0, 48.0, 14.0, 2.0, "Low potassium. Rice noodles are kidney-friendly. Coconut milk adds healthy fats."),
                        ("Dosa with Coconut Chutney", "Plain crispy dosa with fresh coconut chutney. Light on kidneys.",
                         ["dosa batter 100g", "coconut chutney 2 tbsp", "ginger"],
                         320, 8.0, 46.0, 10.0, 2.0, "Low potassium. Fermented batter aids digestion. Light dinner for CKD.")
                    ])
                }
                // Default South Indian dinner
                return pick([
                    ("Idiyappam with Vegetable Kurma", "Rice noodle nests with a mild coconut vegetable curry.",
                     ["idiyappam 3 pieces", "mixed vegetables 120g", "coconut milk 80ml", "cinnamon", "cardamom", "curry leaves"],
                     420, 12.0, 56.0, 14.0, 5.0, "Light rice noodles for easy digestion. Coconut milk adds healthy fats. Vegetables provide vitamins."),
                    ("Dosa with Coconut Chutney & Sambar", "Crispy fermented crepe with coconut chutney and lentil-vegetable stew.",
                     ["dosa batter 100g", "coconut chutney 2 tbsp", "sambar 150ml", "drumstick", "curry leaves"],
                     400, 14.0, 52.0, 12.0, 5.0, "Fermented batter for gut health. Sambar adds lentil protein. Light dinner option."),
                    ("Ragi Roti with Mixed Vegetable Curry", "Finger millet flatbread with a mild mixed vegetable curry.",
                     ["ragi flour 60g", "mixed vegetables 150g", "coconut milk 50ml", "cumin", "coriander"],
                     390, 12.0, 48.0, 14.0, 8.0, "Ragi is calcium-rich. Mixed vegetables add fibre and vitamins."),
                    ("Vegetable Stew with Appam", "Mild coconut vegetable stew with lacy rice-coconut pancake.",
                     ["rice batter 80g", "coconut milk 100ml", "potato 40g", "carrot 40g", "beans 30g", "cinnamon", "cardamom"],
                     410, 10.0, 52.0, 16.0, 4.0, "Kerala classic. Coconut milk provides healthy fats. Vegetables add nutrition."),
                    ("Pongal with Coconut Chutney", "Creamy rice-lentil porridge tempered with cumin, pepper, and ghee.",
                     ["rice 40g", "moong dal 30g", "ghee 1 tsp", "black pepper", "cumin seeds", "curry leaves", "coconut chutney 2 tbsp"],
                     380, 12.0, 50.0, 12.0, 5.0, "Comforting and nutritious. Moong dal adds protein. Light dinner.")
                ])
            }
            // ── North Indian cuisine ──
            if cuisine == .northIndian {
                if hasDiabetes {
                    return pick([
                        ("Palak Paneer with Multigrain Roti", "Spinach and cottage cheese curry with multigrain flatbread.",
                         ["paneer 100g", "spinach 150g", "multigrain roti 1", "onion 30g", "garlic", "ginger", "cumin"],
                         390, 24.0, 28.0, 20.0, 6.0, "Paneer for protein. Spinach is low-GI and iron-rich. Multigrain roti for slow-release carbs."),
                        ("Moong Dal with Roti", "Yellow lentil curry with wholemeal flatbread.",
                         ["moong dal 60g dry", "wholemeal roti 1", "ghee 1 tsp", "cumin seeds", "turmeric", "tomato 40g"],
                         380, 18.0, 48.0, 10.0, 8.0, "Moong dal is low-GI and easy to digest. Wholemeal roti for fibre.")
                    ])
                }
                return pick([
                    ("Dal Makhani with Jeera Rice & Raita", "Creamy black lentil curry with cumin rice and cooling yoghurt.",
                     ["black urad dal 60g dry", "basmati rice 60g dry", "cream 1 tbsp", "butter 1 tsp", "cumin seeds", "yoghurt 50g", "cucumber 20g"],
                     490, 20.0, 62.0, 16.0, 8.0, "Dal makhani is rich in plant protein. Jeera rice aids digestion. Raita for probiotics."),
                    ("Aloo Gobi with Roti & Salad", "Spiced cauliflower-potato curry with wholemeal roti and fresh salad.",
                     ["cauliflower 150g", "potato 80g", "wholemeal roti 2", "turmeric", "cumin", "mixed salad 40g"],
                     440, 12.0, 60.0, 14.0, 7.0, "Cauliflower is rich in vitamin C. Potato provides potassium. Turmeric is anti-inflammatory."),
                    ("Paneer Tikka with Naan & Salad", "Tandoori-style paneer with garlic naan and fresh salad.",
                     ["paneer 100g", "garlic naan 1", "tikka spices", "yoghurt marinade 30g", "mixed salad 50g", "lemon"],
                     460, 24.0, 38.0, 20.0, 4.0, "Paneer for complete protein and calcium. Naan for energy. Spices aid digestion.")
                ])
            }
            // ── Default / Western / Mixed cuisine ──
            if isVegan {
                return pick([
                    ("Tofu Stir-Fry with Vegetables & Noodles", "High-protein tofu with colourful vegetables and wholegrain noodles.",
                     ["firm tofu 150g", "wholegrain noodles 60g dry", "mixed stir-fry vegetables 200g", "soy sauce low-sodium 1 tbsp", "ginger", "garlic", "sesame oil 1 tsp"],
                     450, 24.0, 48.0, 18.0, 7.0, "Tofu provides complete plant protein. Variety of vegetables for micronutrients. Low-sodium soy sauce for HTN awareness."),
                    ("Baingan Bharta with Roti", "Smoky roasted aubergine mash with wholemeal roti and a side salad.",
                     ["aubergine 200g", "wholemeal roti 2", "onion 50g", "tomato 60g", "green chilli", "coriander", "mustard oil 1 tsp"],
                     420, 12.0, 58.0, 14.0, 8.0, "Aubergine is rich in fibre and antioxidants. Wholemeal roti for complex carbs."),
                    ("Chana Masala with Jeera Rice", "Spiced chickpea curry with cumin rice and fresh coriander.",
                     ["chickpeas 100g cooked", "basmati rice 50g dry", "tomatoes 80g", "onion 40g", "cumin seeds", "garam masala", "coriander"],
                     460, 16.0, 64.0, 12.0, 10.0, "Chickpeas provide protein and fibre. Cumin aids digestion. Balanced plant-based dinner.")
                ])
            }
            if hasDiabetes {
                return pick([
                    ("Baked Cod with Cauliflower Mash & Green Beans", "Low-GI dinner with lean protein and non-starchy vegetables.",
                     ["cod fillet 150g", "cauliflower 200g", "green beans 100g", "olive oil 1 tbsp", "garlic", "lemon"],
                     380, 35.0, 18.0, 16.0, 6.0, "Cauliflower mash replaces potato for lower GI. Cod is lean protein. Green beans for fibre."),
                    ("Palak Paneer with Multigrain Roti", "Spinach and cottage cheese curry with multigrain flatbread.",
                     ["paneer 100g", "spinach 150g", "multigrain roti 1", "onion 30g", "garlic", "ginger", "cumin"],
                     390, 24.0, 28.0, 20.0, 6.0, "Paneer for protein. Spinach is low-GI and iron-rich. Multigrain roti for slow-release carbs."),
                    ("Grilled Fish with Stir-Fried Vegetables", "Light grilled white fish with a medley of non-starchy vegetables.",
                     ["white fish fillet 150g", "courgette 80g", "red pepper 60g", "mushrooms 60g", "olive oil 1 tbsp", "herbs"],
                     360, 34.0, 14.0, 16.0, 5.0, "Lean protein from fish. Non-starchy vegetables for minimal blood sugar impact.")
                ])
            }
            return pick([
                ("Lean Chicken with Sweet Potato & Roasted Vegetables", "Balanced dinner with lean protein, complex carbs, and mixed vegetables.",
                 ["chicken breast 130g", "sweet potato 150g", "courgette 80g", "red pepper 80g", "olive oil 1 tbsp", "herbs"],
                 480, 38.0, 42.0, 16.0, 7.0, "Sweet potato for sustained energy and beta-carotene. Chicken for lean protein. Roasted veg for variety."),
                ("Vegetable Biryani with Raita", "Fragrant spiced rice with mixed vegetables and cooling yoghurt raita.",
                 ["basmati rice 60g dry", "mixed vegetables 150g", "yoghurt 50g", "cucumber 30g", "biryani spices", "saffron", "ghee 1 tsp", "mint"],
                 460, 14.0, 62.0, 14.0, 6.0, "Aromatic spices aid digestion. Mixed vegetables provide fibre and vitamins. Raita for probiotics."),
                ("Dal Tadka with Rice & Salad", "Yellow lentil curry with tempered spices, served with rice and fresh salad.",
                 ["yellow dal 60g dry", "basmati rice 60g dry", "ghee 1 tsp", "cumin seeds", "garlic", "tomato 50g", "mixed salad 40g"],
                 470, 18.0, 66.0, 12.0, 10.0, "Lentils for plant protein. Tempered spices improve nutrient absorption. Balanced and comforting.")
            ])

        case "Snack":
            // ── South Indian cuisine ──
            if cuisine == .southIndian {
                if isVegan {
                    return pick([
                        ("Sundal", "Spiced chickpea salad with coconut, curry leaves, and mustard seeds.",
                         ["chickpeas 80g cooked", "grated coconut 10g", "mustard seeds", "curry leaves", "green chilli"],
                         160, 8.0, 20.0, 4.0, 6.0, "Chickpeas for plant protein and fibre. Coconut adds healthy fats. Traditional temple snack."),
                        ("Roasted Makhana with Spices", "Crunchy fox nuts roasted with turmeric and black pepper.",
                         ["makhana 30g", "turmeric", "black pepper", "coconut oil 1 tsp"],
                         160, 5.0, 20.0, 6.0, 2.0, "Makhana is low-GI and rich in calcium. Turmeric is anti-inflammatory. Light and satisfying."),
                        ("Banana with Jaggery", "Ripe banana with a small piece of jaggery. Traditional energy snack.",
                         ["banana 1 small", "jaggery 10g"],
                         150, 2.0, 34.0, 0.5, 3.0, "Natural sugars for quick energy. Banana provides potassium. Jaggery adds iron.")
                    ])
                }
                if hasDiabetes {
                    return pick([
                        ("Sundal", "Spiced chickpea salad with coconut. Low-GI, high-fibre snack.",
                         ["chickpeas 80g cooked", "grated coconut 10g", "mustard seeds", "curry leaves", "green chilli"],
                         160, 8.0, 20.0, 4.0, 6.0, "Low-GI chickpeas for steady blood sugar. High fibre. Traditional and satisfying."),
                        ("Roasted Makhana with Spices", "Crunchy fox nuts roasted with turmeric and black pepper.",
                         ["makhana 30g", "turmeric", "black pepper", "coconut oil 1 tsp"],
                         160, 5.0, 20.0, 6.0, 2.0, "Makhana is low-GI and rich in calcium. Turmeric is anti-inflammatory."),
                        ("Filter Coffee with Ragi Biscuits", "Strong South Indian filter coffee with finger millet biscuits.",
                         ["filter coffee 150ml", "milk 30ml", "ragi biscuits 2"],
                         140, 4.0, 20.0, 4.0, 3.0, "Ragi biscuits are low-GI. Coffee in moderation can improve insulin sensitivity.")
                    ])
                }
                // Default South Indian snacks
                return pick([
                    ("Murukku with Tea", "Crunchy rice-lentil spiral snack with a cup of tea.",
                     ["murukku 2 pieces", "tea 200ml", "milk 20ml"],
                     180, 3.0, 24.0, 8.0, 1.0, "Traditional teatime snack. Rice and lentil flour provide energy."),
                    ("Sundal", "Spiced chickpea salad with coconut, curry leaves, and mustard seeds.",
                     ["chickpeas 80g cooked", "grated coconut 10g", "mustard seeds", "curry leaves", "green chilli"],
                     160, 8.0, 20.0, 4.0, 6.0, "Chickpeas for plant protein and fibre. Coconut adds healthy fats. Traditional temple snack."),
                    ("Banana with Jaggery", "Ripe banana with a small piece of jaggery. Traditional energy snack.",
                     ["banana 1 small", "jaggery 10g"],
                     150, 2.0, 34.0, 0.5, 3.0, "Natural sugars for quick energy. Banana provides potassium. Jaggery adds iron."),
                    ("Roasted Makhana", "Crunchy fox nuts roasted with turmeric and black pepper.",
                     ["makhana 30g", "turmeric", "black pepper", "coconut oil 1 tsp"],
                     160, 5.0, 20.0, 6.0, 2.0, "Makhana is low-GI and rich in calcium. Turmeric is anti-inflammatory."),
                    ("Filter Coffee with Ragi Biscuits", "Strong South Indian filter coffee with finger millet biscuits.",
                     ["filter coffee 150ml", "milk 30ml", "ragi biscuits 2"],
                     140, 4.0, 20.0, 4.0, 3.0, "Ragi biscuits add calcium and fibre. Filter coffee is a South Indian tradition."),
                    ("Medu Vada", "Crispy fried lentil doughnuts. A classic South Indian snack.",
                     ["urad dal 60g", "ginger", "curry leaves", "green chilli", "coconut oil for frying"],
                     200, 8.0, 22.0, 8.0, 4.0, "Urad dal provides protein. Best enjoyed fresh. A satisfying teatime treat.")
                ])
            }
            // ── North Indian cuisine ──
            if cuisine == .northIndian {
                return pick([
                    ("Masala Chai with Digestive Biscuits", "Spiced tea with 2 wholemeal digestive biscuits.",
                     ["tea 200ml", "milk 30ml", "cardamom", "ginger", "wholemeal digestive biscuits 2"],
                     160, 3.0, 22.0, 6.0, 2.0, "Chai spices aid digestion. Wholemeal biscuits for fibre. A comforting afternoon snack."),
                    ("Roasted Chana", "Spiced roasted chickpeas with chaat masala.",
                     ["roasted chana 40g", "chaat masala", "lime juice"],
                     150, 8.0, 20.0, 4.0, 6.0, "High protein and fibre. Low-GI snack. Chaat masala aids digestion."),
                    ("Samosa (Baked)", "Baked wholemeal samosa with potato-pea filling.",
                     ["wholemeal flour pastry 1", "potato 40g", "peas 20g", "cumin seeds", "green chilli"],
                     180, 4.0, 26.0, 6.0, 3.0, "Baked not fried. Wholemeal pastry for fibre. A lighter version of the classic.")
                ])
            }
            // ── Default / Western / Mixed cuisine ──
            if isVegan {
                return pick([
                    ("Apple Slices with Almond Butter", "Simple plant-based snack with healthy fats and fibre.",
                     ["apple 1 medium", "almond butter 1 tbsp"],
                     200, 5.0, 22.0, 10.0, 4.0, "Apple for fibre and vitamin C. Almond butter for healthy fats and magnesium."),
                    ("Roasted Makhana with Spices", "Crunchy fox nuts roasted with turmeric and black pepper.",
                     ["makhana 30g", "turmeric", "black pepper", "coconut oil 1 tsp"],
                     160, 5.0, 20.0, 6.0, 2.0, "Makhana is low-GI and rich in calcium. Turmeric is anti-inflammatory. Light and satisfying."),
                    ("Trail Mix with Dried Fruit", "A mix of nuts, seeds, and unsweetened dried fruit.",
                     ["almonds 10g", "pumpkin seeds 10g", "dried cranberries unsweetened 15g", "sunflower seeds 10g"],
                     190, 6.0, 16.0, 12.0, 3.0, "Nuts and seeds provide omega-3 and minerals. Dried fruit adds natural energy.")
                ])
            }
            if needsMg {
                return pick([
                    ("Dark Chocolate & Mixed Nuts", "Magnesium-rich snack with antioxidant dark chocolate.",
                     ["dark chocolate 70%+ 20g", "mixed nuts 20g"],
                     210, 4.0, 14.0, 16.0, 3.0, "Dark chocolate and nuts are excellent magnesium sources. Anti-inflammatory."),
                    ("Banana with Pumpkin Seeds", "Potassium and magnesium-rich snack for mineral replenishment.",
                     ["banana 1 small", "pumpkin seeds 15g"],
                     180, 5.0, 24.0, 8.0, 3.0, "Banana for potassium. Pumpkin seeds are one of the best magnesium sources.")
                ])
            }
            return pick([
                ("Hummus with Carrot Sticks", "Fibre-rich snack with plant protein from chickpeas.",
                 ["hummus 50g", "carrot sticks 80g", "cucumber sticks 50g"],
                 150, 5.0, 16.0, 8.0, 5.0, "Chickpeas for plant protein and fibre. Low GI. Vegetables for micronutrients."),
                ("Yoghurt with Walnuts & Honey", "Creamy yoghurt topped with omega-3-rich walnuts and a touch of honey.",
                 ["natural yoghurt 120g", "walnuts 15g", "honey ½ tsp"],
                 180, 8.0, 14.0, 10.0, 2.0, "Yoghurt for probiotics and calcium. Walnuts for omega-3. Light and satisfying."),
                ("Masala Chai with Digestive Biscuits", "Spiced tea with 2 wholemeal digestive biscuits.",
                 ["tea 200ml", "milk 30ml", "cardamom", "ginger", "wholemeal digestive biscuits 2"],
                 160, 3.0, 22.0, 6.0, 2.0, "Chai spices aid digestion. Wholemeal biscuits for fibre. A comforting afternoon snack.")
            ])

        default:
            return ("Mixed Fruit & Yoghurt", "Simple balanced snack.", ["Greek yoghurt 100g", "mixed fruit 80g"], 150, 8.0, 18.0, 4.0, 3.0, "Protein from yoghurt, vitamins from fruit.")
        }
    }

    // MARK: - Helpers

    /// Produces a stable integer seed from a date (based on year + day-of-year).
    /// Consecutive days always produce different seeds.
    private static func daySeedFromDate(_ date: Date) -> Int {
        let cal = Calendar.current
        let day = cal.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = cal.component(.year, from: date)
        return abs(year &* 367 &+ day)
    }

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
