//
//  FoodSearchView.swift
//  body sense ai
//
//  Smart Food Search — Google-like autocomplete with nutritional data.
//  Users can search any food item, pick a serving size (grams), and see
//  full nutritional breakdown (calories, protein, carbs, fat, fiber).
//

import SwiftUI

// MARK: - Food Item Model

struct FoodItem: Identifiable, Codable, Equatable {
    var id = UUID()
    let name: String
    let category: FoodCategory
    let brand: String           // e.g. "Tesco", "Sainsbury's", "" for generic
    let defaultServingGrams: Int // typical pack / serving size

    // Nutritional values per 100g
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    let fiberPer100g: Double
    let sugarPer100g: Double
    let saltPer100g: Double      // g

    // Calculated values for any gram amount
    func nutritionFor(grams: Double) -> NutritionValues {
        let factor = grams / 100.0
        return NutritionValues(
            grams: grams,
            calories: caloriesPer100g * factor,
            protein: proteinPer100g * factor,
            carbs: carbsPer100g * factor,
            fat: fatPer100g * factor,
            fiber: fiberPer100g * factor,
            sugar: sugarPer100g * factor,
            salt: saltPer100g * factor
        )
    }
}

struct NutritionValues {
    let grams: Double
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let salt: Double
}

enum FoodCategory: String, Codable, CaseIterable {
    case grain       = "Grains & Cereals"
    case protein     = "Protein"
    case dairy       = "Dairy"
    case fruit       = "Fruits"
    case vegetable   = "Vegetables"
    case nuts        = "Nuts & Seeds"
    case oils        = "Oils & Fats"
    case snacks      = "Snacks"
    case drinks      = "Drinks"
    case prepared    = "Prepared Foods"
    case bakery      = "Bakery"
    case condiments  = "Condiments"
    case superfoods  = "Superfoods"
    case shop        = "Shop Products"

    var icon: String {
        switch self {
        case .grain:      return "🌾"
        case .protein:    return "🥩"
        case .dairy:      return "🥛"
        case .fruit:      return "🍎"
        case .vegetable:  return "🥦"
        case .nuts:       return "🥜"
        case .oils:       return "🫒"
        case .snacks:     return "🍪"
        case .drinks:     return "☕"
        case .prepared:   return "🍱"
        case .bakery:     return "🍞"
        case .condiments: return "🧂"
        case .superfoods: return "✨"
        case .shop:       return "🛒"
        }
    }
}

// MARK: - Food Database

struct FoodDatabase {
    static let shared = FoodDatabase()

    let items: [FoodItem]

    init() {
        items = FoodDatabase.buildDatabase()
    }

    func search(_ query: String) -> [FoodItem] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        let words = q.split(separator: " ").map(String.init)

        return items
            .filter { item in
                let name = item.name.lowercased()
                let brand = item.brand.lowercased()
                let cat = item.category.rawValue.lowercased()
                // All query words must appear in name, brand, or category
                return words.allSatisfy { word in
                    name.contains(word) || brand.contains(word) || cat.contains(word)
                }
            }
            .sorted { a, b in
                // Prioritize items that start with the query
                let aStarts = a.name.lowercased().hasPrefix(q)
                let bStarts = b.name.lowercased().hasPrefix(q)
                if aStarts != bStarts { return aStarts }
                return a.name < b.name
            }
    }

    // MARK: - Build comprehensive food database
    private static func buildDatabase() -> [FoodItem] {
        var db: [FoodItem] = []

        // Helper to add items
        func add(_ name: String, _ cat: FoodCategory, _ brand: String = "", serving: Int = 100,
                 cal: Double, pro: Double, carb: Double, fat: Double, fib: Double, sug: Double = 0, salt: Double = 0) {
            db.append(FoodItem(name: name, category: cat, brand: brand, defaultServingGrams: serving,
                               caloriesPer100g: cal, proteinPer100g: pro, carbsPer100g: carb,
                               fatPer100g: fat, fiberPer100g: fib, sugarPer100g: sug, saltPer100g: salt))
        }

        // ── GRAINS & CEREALS ──
        add("White Rice (cooked)", .grain, serving: 200, cal: 130, pro: 2.7, carb: 28, fat: 0.3, fib: 0.4, sug: 0.1)
        add("Brown Rice (cooked)", .grain, serving: 200, cal: 112, pro: 2.6, carb: 23, fat: 0.9, fib: 1.8, sug: 0.4)
        add("Basmati Rice (cooked)", .grain, serving: 200, cal: 121, pro: 3.5, carb: 25, fat: 0.4, fib: 0.4, sug: 0)
        add("Pasta (cooked)", .grain, serving: 200, cal: 131, pro: 5.0, carb: 25, fat: 1.1, fib: 1.8, sug: 0.6)
        add("Wholemeal Pasta (cooked)", .grain, serving: 200, cal: 124, pro: 5.3, carb: 23, fat: 1.1, fib: 3.2, sug: 0.8)
        add("Noodles (egg, cooked)", .grain, serving: 200, cal: 138, pro: 4.5, carb: 25, fat: 2.0, fib: 1.2, sug: 0.4)
        add("Quinoa (cooked)", .grain, serving: 185, cal: 120, pro: 4.4, carb: 21, fat: 1.9, fib: 2.8, sug: 0.9)
        add("Oats (porridge, cooked)", .grain, serving: 250, cal: 68, pro: 2.5, carb: 12, fat: 1.4, fib: 1.7, sug: 0.3)
        add("Oats (raw)", .grain, serving: 40, cal: 379, pro: 13.2, carb: 67, fat: 6.5, fib: 10.1, sug: 1.0)
        add("Couscous (cooked)", .grain, serving: 200, cal: 112, pro: 3.8, carb: 23, fat: 0.2, fib: 1.4, sug: 0.1)
        add("Bread (white, sliced)", .bakery, serving: 36, cal: 265, pro: 8.9, carb: 49, fat: 3.2, fib: 2.7, sug: 5.0, salt: 1.0)
        add("Bread (wholemeal)", .bakery, serving: 36, cal: 247, pro: 13, carb: 41, fat: 3.4, fib: 7.0, sug: 4.4, salt: 0.98)
        add("Bread (sourdough)", .bakery, serving: 50, cal: 274, pro: 9.0, carb: 51, fat: 3.0, fib: 3.0, sug: 2.5, salt: 1.1)
        add("Pitta Bread", .bakery, serving: 60, cal: 275, pro: 9.1, carb: 55, fat: 1.2, fib: 2.2, sug: 1.8, salt: 0.75)
        add("Corn Flakes", .grain, serving: 30, cal: 376, pro: 7.0, carb: 84, fat: 0.6, fib: 3.0, sug: 8.0, salt: 1.13)
        add("Weetabix", .grain, "Weetabix", serving: 38, cal: 362, pro: 11.5, carb: 67, fat: 2.0, fib: 10.0, sug: 4.4, salt: 0.28)
        add("Granola", .grain, serving: 45, cal: 471, pro: 10, carb: 56, fat: 22, fib: 6.5, sug: 21, salt: 0.1)

        // ── PROTEIN ──
        add("Chicken Breast (grilled)", .protein, serving: 150, cal: 165, pro: 31, carb: 0, fat: 3.6, fib: 0)
        add("Chicken Thigh (skin on)", .protein, serving: 150, cal: 229, pro: 24, carb: 0, fat: 15, fib: 0)
        add("Turkey Breast", .protein, serving: 150, cal: 135, pro: 30, carb: 0, fat: 1.0, fib: 0)
        add("Salmon Fillet (baked)", .protein, serving: 150, cal: 208, pro: 20, carb: 0, fat: 13, fib: 0)
        add("Tuna (canned in water)", .protein, serving: 100, cal: 116, pro: 26, carb: 0, fat: 0.8, fib: 0, salt: 0.4)
        add("Tuna (canned in oil)", .protein, serving: 100, cal: 198, pro: 29, carb: 0, fat: 8.2, fib: 0, salt: 0.5)
        add("Cod Fillet (baked)", .protein, serving: 150, cal: 105, pro: 23, carb: 0, fat: 0.9, fib: 0)
        add("Prawns (cooked)", .protein, serving: 100, cal: 99, pro: 24, carb: 0.2, fat: 0.3, fib: 0, salt: 1.0)
        add("Beef Mince (lean, cooked)", .protein, serving: 150, cal: 176, pro: 24, carb: 0, fat: 9, fib: 0)
        add("Beef Steak (sirloin, grilled)", .protein, serving: 200, cal: 218, pro: 26, carb: 0, fat: 13, fib: 0)
        add("Lamb Chop (grilled)", .protein, serving: 120, cal: 294, pro: 25, carb: 0, fat: 21, fib: 0)
        add("Pork Chop (grilled)", .protein, serving: 150, cal: 231, pro: 28, carb: 0, fat: 13, fib: 0)
        add("Bacon (back, grilled)", .protein, serving: 25, cal: 215, pro: 25, carb: 0, fat: 13, fib: 0, salt: 2.7)
        add("Sausage (pork)", .protein, serving: 57, cal: 301, pro: 14, carb: 8, fat: 24, fib: 0.5, salt: 1.5)
        add("Egg (boiled)", .protein, serving: 60, cal: 155, pro: 13, carb: 1.1, fat: 11, fib: 0)
        add("Egg (scrambled)", .protein, serving: 100, cal: 166, pro: 11, carb: 1.6, fat: 12, fib: 0, salt: 0.6)
        add("Tofu (firm)", .protein, serving: 100, cal: 144, pro: 17, carb: 3.0, fat: 8.7, fib: 2.3)
        add("Chickpeas (cooked)", .protein, serving: 150, cal: 164, pro: 8.9, carb: 27, fat: 2.6, fib: 7.6)
        add("Lentils (cooked)", .protein, serving: 150, cal: 116, pro: 9.0, carb: 20, fat: 0.4, fib: 7.9)
        add("Red Kidney Beans (cooked)", .protein, serving: 150, cal: 127, pro: 8.7, carb: 22, fat: 0.5, fib: 6.4)
        add("Baked Beans", .protein, "Heinz", serving: 200, cal: 81, pro: 4.7, carb: 13, fat: 0.6, fib: 3.7, sug: 5.0, salt: 0.6)

        // ── DAIRY ──
        add("Whole Milk", .dairy, serving: 250, cal: 64, pro: 3.3, carb: 4.7, fat: 3.6, fib: 0, sug: 4.7)
        add("Semi-Skimmed Milk", .dairy, serving: 250, cal: 46, pro: 3.4, carb: 4.7, fat: 1.7, fib: 0, sug: 4.7)
        add("Skimmed Milk", .dairy, serving: 250, cal: 34, pro: 3.4, carb: 5.0, fat: 0.1, fib: 0, sug: 5.0)
        add("Almond Milk (unsweetened)", .dairy, serving: 250, cal: 13, pro: 0.4, carb: 0.3, fat: 1.1, fib: 0.2)
        add("Oat Milk", .dairy, serving: 250, cal: 46, pro: 1.0, carb: 7.0, fat: 1.5, fib: 0.8, sug: 4.0)
        add("Greek Yoghurt (full fat)", .dairy, serving: 150, cal: 97, pro: 9.0, carb: 3.6, fat: 5.0, fib: 0, sug: 3.6)
        add("Greek Yoghurt (0% fat)", .dairy, serving: 150, cal: 57, pro: 10, carb: 4.0, fat: 0.7, fib: 0, sug: 4.0)
        add("Natural Yoghurt", .dairy, serving: 150, cal: 61, pro: 3.5, carb: 7.0, fat: 1.5, fib: 0, sug: 7.0)
        add("Cheddar Cheese", .dairy, serving: 30, cal: 416, pro: 25, carb: 0.1, fat: 35, fib: 0, salt: 1.8)
        add("Mozzarella", .dairy, serving: 30, cal: 280, pro: 28, carb: 3.1, fat: 17, fib: 0, salt: 0.7)
        add("Cottage Cheese", .dairy, serving: 100, cal: 98, pro: 11, carb: 3.4, fat: 4.3, fib: 0, salt: 0.5)
        add("Butter", .dairy, serving: 10, cal: 717, pro: 0.9, carb: 0.1, fat: 81, fib: 0, salt: 0.6)

        // ── FRUITS ──
        add("Apple", .fruit, serving: 150, cal: 52, pro: 0.3, carb: 14, fat: 0.2, fib: 2.4, sug: 10)
        add("Banana", .fruit, serving: 120, cal: 89, pro: 1.1, carb: 23, fat: 0.3, fib: 2.6, sug: 12)
        add("Orange", .fruit, serving: 130, cal: 47, pro: 0.9, carb: 12, fat: 0.1, fib: 2.4, sug: 9.4)
        add("Blueberries", .fruit, serving: 80, cal: 57, pro: 0.7, carb: 14, fat: 0.3, fib: 2.4, sug: 10)
        add("Strawberries", .fruit, serving: 100, cal: 33, pro: 0.7, carb: 8, fat: 0.3, fib: 2.0, sug: 4.9)
        add("Grapes", .fruit, serving: 80, cal: 67, pro: 0.7, carb: 17, fat: 0.4, fib: 0.9, sug: 16)
        add("Mango", .fruit, serving: 100, cal: 60, pro: 0.8, carb: 15, fat: 0.4, fib: 1.6, sug: 14)
        add("Pineapple", .fruit, serving: 100, cal: 50, pro: 0.5, carb: 13, fat: 0.1, fib: 1.4, sug: 10)
        add("Avocado", .fruit, serving: 80, cal: 160, pro: 2.0, carb: 8.5, fat: 15, fib: 6.7, sug: 0.7)
        add("Watermelon", .fruit, serving: 150, cal: 30, pro: 0.6, carb: 7.6, fat: 0.2, fib: 0.4, sug: 6.2)
        add("Pear", .fruit, serving: 150, cal: 57, pro: 0.4, carb: 15, fat: 0.1, fib: 3.1, sug: 10)
        add("Kiwi", .fruit, serving: 70, cal: 61, pro: 1.1, carb: 15, fat: 0.5, fib: 3.0, sug: 9.0)
        add("Lemon", .fruit, serving: 50, cal: 29, pro: 1.1, carb: 9.3, fat: 0.3, fib: 2.8, sug: 2.5)
        add("Dates (dried)", .fruit, serving: 30, cal: 282, pro: 2.5, carb: 75, fat: 0.4, fib: 8.0, sug: 64)

        // ── VEGETABLES ──
        add("Broccoli (steamed)", .vegetable, serving: 80, cal: 35, pro: 2.4, carb: 7.2, fat: 0.4, fib: 3.3)
        add("Spinach (raw)", .vegetable, serving: 50, cal: 23, pro: 2.9, carb: 3.6, fat: 0.4, fib: 2.2)
        add("Kale (raw)", .vegetable, serving: 50, cal: 35, pro: 2.9, carb: 4.4, fat: 1.5, fib: 4.1)
        add("Carrots (raw)", .vegetable, serving: 80, cal: 41, pro: 0.9, carb: 10, fat: 0.2, fib: 2.8, sug: 4.7)
        add("Sweet Potato (baked)", .vegetable, serving: 150, cal: 90, pro: 2.0, carb: 21, fat: 0.1, fib: 3.3, sug: 6.5)
        add("Potato (baked, no skin)", .vegetable, serving: 200, cal: 93, pro: 2.5, carb: 21, fat: 0.1, fib: 2.2, sug: 1.2)
        add("Potato (boiled)", .vegetable, serving: 200, cal: 87, pro: 1.9, carb: 20, fat: 0.1, fib: 1.8, sug: 0.8)
        add("Chips / French Fries", .vegetable, serving: 150, cal: 312, pro: 3.4, carb: 41, fat: 15, fib: 3.8, sug: 0.3, salt: 0.6)
        add("Cucumber", .vegetable, serving: 100, cal: 15, pro: 0.7, carb: 3.6, fat: 0.1, fib: 0.5, sug: 1.7)
        add("Tomato", .vegetable, serving: 100, cal: 18, pro: 0.9, carb: 3.9, fat: 0.2, fib: 1.2, sug: 2.6)
        add("Onion", .vegetable, serving: 100, cal: 40, pro: 1.1, carb: 9.3, fat: 0.1, fib: 1.7, sug: 4.2)
        add("Pepper (bell, red)", .vegetable, serving: 100, cal: 26, pro: 1.0, carb: 6.0, fat: 0.3, fib: 2.1, sug: 4.2)
        add("Mushrooms", .vegetable, serving: 80, cal: 22, pro: 3.1, carb: 3.3, fat: 0.3, fib: 1.0)
        add("Cauliflower (steamed)", .vegetable, serving: 100, cal: 25, pro: 1.9, carb: 5.0, fat: 0.3, fib: 2.0, sug: 1.9)
        add("Green Beans (steamed)", .vegetable, serving: 80, cal: 31, pro: 1.8, carb: 7.0, fat: 0.1, fib: 3.4, sug: 1.4)
        add("Corn on the Cob", .vegetable, serving: 150, cal: 86, pro: 3.3, carb: 19, fat: 1.4, fib: 2.7, sug: 3.2)

        // ── NUTS & SEEDS ──
        add("Almonds", .nuts, serving: 30, cal: 579, pro: 21, carb: 22, fat: 50, fib: 12, sug: 3.9)
        add("Walnuts", .nuts, serving: 30, cal: 654, pro: 15, carb: 14, fat: 65, fib: 6.7, sug: 2.6)
        add("Cashews", .nuts, serving: 30, cal: 553, pro: 18, carb: 30, fat: 44, fib: 3.3, sug: 5.9)
        add("Peanuts (roasted)", .nuts, serving: 30, cal: 567, pro: 26, carb: 16, fat: 49, fib: 8.5, sug: 4.0)
        add("Peanut Butter", .nuts, serving: 15, cal: 588, pro: 25, carb: 20, fat: 50, fib: 6.0, sug: 9.0, salt: 0.5)
        add("Chia Seeds", .nuts, serving: 15, cal: 486, pro: 17, carb: 42, fat: 31, fib: 34, sug: 0)
        add("Flaxseeds", .nuts, serving: 15, cal: 534, pro: 18, carb: 29, fat: 42, fib: 27, sug: 1.6)
        add("Hemp Seeds", .nuts, serving: 15, cal: 553, pro: 32, carb: 8.7, fat: 49, fib: 4.0, sug: 1.5)
        add("Pumpkin Seeds", .nuts, serving: 30, cal: 559, pro: 30, carb: 11, fat: 49, fib: 6.0, sug: 1.4)
        add("Sunflower Seeds", .nuts, serving: 30, cal: 584, pro: 21, carb: 20, fat: 51, fib: 8.6, sug: 2.6)

        // ── OILS & FATS ──
        add("Coconut Oil", .oils, serving: 15, cal: 862, pro: 0, carb: 0, fat: 100, fib: 0)
        add("Olive Oil (extra virgin)", .oils, serving: 15, cal: 884, pro: 0, carb: 0, fat: 100, fib: 0)
        add("Sunflower Oil", .oils, serving: 15, cal: 884, pro: 0, carb: 0, fat: 100, fib: 0)
        add("Vegetable Oil", .oils, serving: 15, cal: 884, pro: 0, carb: 0, fat: 100, fib: 0)
        add("Ghee (clarified butter)", .oils, serving: 10, cal: 900, pro: 0, carb: 0, fat: 100, fib: 0)

        // ── SUPERFOODS / HEALTH FOODS ──
        add("Turmeric (ground)", .superfoods, serving: 5, cal: 312, pro: 9.7, carb: 67, fat: 3.3, fib: 22, sug: 3.2)
        add("Ginger (fresh)", .superfoods, serving: 10, cal: 80, pro: 1.8, carb: 18, fat: 0.8, fib: 2.0, sug: 1.7)
        add("Cinnamon (ground)", .superfoods, serving: 3, cal: 247, pro: 4.0, carb: 81, fat: 1.2, fib: 53, sug: 2.2)
        add("Garlic (fresh)", .superfoods, serving: 5, cal: 149, pro: 6.4, carb: 33, fat: 0.5, fib: 2.1, sug: 1.0)
        add("Honey", .superfoods, serving: 20, cal: 304, pro: 0.3, carb: 82, fat: 0, fib: 0, sug: 82)
        add("Apple Cider Vinegar", .superfoods, serving: 15, cal: 22, pro: 0, carb: 0.9, fat: 0, fib: 0, sug: 0.4)
        add("Spirulina (dried)", .superfoods, serving: 5, cal: 290, pro: 57, carb: 24, fat: 8, fib: 3.6, sug: 3.1)
        add("Matcha Powder", .superfoods, serving: 3, cal: 324, pro: 29, carb: 39, fat: 5.0, fib: 39, sug: 0)
        add("Acai Powder", .superfoods, serving: 5, cal: 534, pro: 8.6, carb: 52, fat: 33, fib: 33, sug: 0)
        add("Coconut (desiccated)", .superfoods, serving: 15, cal: 660, pro: 6.9, carb: 24, fat: 65, fib: 16, sug: 7.4)
        add("Dark Chocolate (85%)", .superfoods, serving: 25, cal: 580, pro: 8.0, carb: 36, fat: 46, fib: 11, sug: 14)
        add("Shea Butter (food grade)", .superfoods, serving: 10, cal: 884, pro: 0, carb: 0, fat: 100, fib: 0)

        // ── DRINKS ──
        add("Tea (black, no sugar)", .drinks, serving: 250, cal: 1, pro: 0, carb: 0.3, fat: 0, fib: 0)
        add("Coffee (black, no sugar)", .drinks, serving: 250, cal: 2, pro: 0.3, carb: 0, fat: 0, fib: 0)
        add("Coffee (latte)", .drinks, serving: 350, cal: 60, pro: 3.0, carb: 5.0, fat: 3.0, fib: 0, sug: 5.0)
        add("Orange Juice", .drinks, serving: 200, cal: 45, pro: 0.7, carb: 10, fat: 0.2, fib: 0.2, sug: 8.4)
        add("Coca-Cola", .drinks, "Coca-Cola", serving: 330, cal: 42, pro: 0, carb: 11, fat: 0, fib: 0, sug: 11)
        add("Coca-Cola Zero", .drinks, "Coca-Cola", serving: 330, cal: 0, pro: 0, carb: 0, fat: 0, fib: 0, sug: 0)

        // ── CONDIMENTS ──
        add("Ketchup", .condiments, "Heinz", serving: 15, cal: 112, pro: 1.2, carb: 26, fat: 0.1, fib: 0.3, sug: 23, salt: 1.8)
        add("Mayonnaise", .condiments, serving: 15, cal: 680, pro: 1.0, carb: 0.6, fat: 75, fib: 0, sug: 0.6, salt: 1.2)
        add("Hummus", .condiments, serving: 30, cal: 166, pro: 8.0, carb: 14, fat: 10, fib: 6.0, sug: 0.3, salt: 0.8)
        add("Soy Sauce", .condiments, serving: 15, cal: 53, pro: 8.1, carb: 4.9, fat: 0, fib: 0.8, sug: 0.4, salt: 14.4)

        // ── SHOP PRODUCTS (Tesco / Supermarket) ──
        add("Tesco Chicken Breast Fillets", .shop, "Tesco", serving: 150, cal: 106, pro: 24, carb: 0, fat: 1.1, fib: 0, salt: 0.2)
        add("Tesco Whole Milk", .shop, "Tesco", serving: 250, cal: 66, pro: 3.3, carb: 4.7, fat: 3.7, fib: 0, sug: 4.7)
        add("Tesco Houmous", .shop, "Tesco", serving: 200, cal: 280, pro: 7.1, carb: 11, fat: 23, fib: 4.1, sug: 0.9, salt: 0.93)
        add("Tesco Finest Granola", .shop, "Tesco", serving: 350, cal: 445, pro: 9.2, carb: 55, fat: 20, fib: 6.5, sug: 19, salt: 0.1)
        add("Tesco Basmati Rice", .shop, "Tesco", serving: 500, cal: 349, pro: 8.3, carb: 77, fat: 0.6, fib: 1.3, sug: 0.3)
        add("Tesco Cheddar Cheese (mature)", .shop, "Tesco", serving: 200, cal: 416, pro: 25, carb: 0.1, fat: 35, fib: 0, sug: 0.1, salt: 1.8)
        add("Tesco Free Range Eggs (6 pack)", .shop, "Tesco", serving: 60, cal: 131, pro: 13, carb: 0.6, fat: 9.0, fib: 0, salt: 0.4)
        add("Tesco Sliced White Bread (800g)", .shop, "Tesco", serving: 800, cal: 240, pro: 8.4, carb: 46, fat: 1.7, fib: 3.2, sug: 3.4, salt: 1.0)
        add("Tesco Greek Style Yoghurt", .shop, "Tesco", serving: 500, cal: 115, pro: 4.3, carb: 5.3, fat: 8.4, fib: 0, sug: 5.3)
        add("Tesco Digestive Biscuits", .shop, "Tesco", serving: 400, cal: 487, pro: 7.0, carb: 64, fat: 22, fib: 3.0, sug: 22, salt: 1.0)
        add("Tesco Semi Skimmed Milk", .shop, "Tesco", serving: 568, cal: 46, pro: 3.6, carb: 4.6, fat: 1.8, fib: 0, sug: 4.6)
        add("Tesco Chicken Tikka Masala", .shop, "Tesco", serving: 400, cal: 140, pro: 9.0, carb: 11, fat: 6.3, fib: 1.0, sug: 4.5, salt: 0.7)
        add("Tesco Penne Pasta", .shop, "Tesco", serving: 500, cal: 355, pro: 12, carb: 72, fat: 1.5, fib: 3.5, sug: 3.2)
        add("Tesco Baked Beans", .shop, "Tesco", serving: 400, cal: 82, pro: 4.5, carb: 13, fat: 0.6, fib: 3.8, sug: 5.4, salt: 0.6)
        add("Sainsbury's Chicken Breast", .shop, "Sainsbury's", serving: 320, cal: 108, pro: 24, carb: 0, fat: 1.3, fib: 0, salt: 0.2)
        add("Warburtons Toastie White Bread", .shop, "Warburtons", serving: 800, cal: 243, pro: 8.8, carb: 46, fat: 2.0, fib: 3.0, sug: 3.5, salt: 1.0)

        // ── PREPARED / MEALS ──
        add("Chicken Curry (home-cooked)", .prepared, serving: 350, cal: 143, pro: 12, carb: 10, fat: 6.5, fib: 2.0, sug: 3.5, salt: 0.8)
        add("Spaghetti Bolognese", .prepared, serving: 400, cal: 120, pro: 6.0, carb: 13, fat: 5.0, fib: 1.5, sug: 3.0, salt: 0.6)
        add("Fish and Chips", .prepared, serving: 400, cal: 200, pro: 10, carb: 22, fat: 8.0, fib: 2.0, sug: 1.0, salt: 0.9)
        add("Pizza (Margherita)", .prepared, serving: 300, cal: 266, pro: 11, carb: 33, fat: 10, fib: 2.3, sug: 3.6, salt: 1.4)
        add("Burger (beef, plain)", .prepared, serving: 200, cal: 255, pro: 17, carb: 24, fat: 10, fib: 1.0, sug: 5.0, salt: 1.2)
        add("Stir Fry (chicken & veg)", .prepared, serving: 300, cal: 90, pro: 9.0, carb: 7.0, fat: 3.5, fib: 2.5, sug: 3.0, salt: 1.0)
        add("Omelette (2 egg, plain)", .prepared, serving: 120, cal: 154, pro: 11, carb: 0.7, fat: 12, fib: 0)
        add("Porridge with Milk", .prepared, serving: 300, cal: 71, pro: 2.8, carb: 12, fat: 1.5, fib: 1.4, sug: 3.2)
        add("Beans on Toast", .prepared, serving: 300, cal: 130, pro: 6.5, carb: 21, fat: 2.0, fib: 4.0, sug: 4.5, salt: 0.8)
        add("Soup (tomato)", .prepared, serving: 300, cal: 36, pro: 0.8, carb: 7.0, fat: 0.5, fib: 0.8, sug: 5.0, salt: 0.6)
        add("Soup (chicken)", .prepared, serving: 300, cal: 31, pro: 2.5, carb: 3.0, fat: 1.2, fib: 0.5, sug: 1.0, salt: 0.7)

        // ── SNACKS ──
        add("Crisps (ready salted)", .snacks, serving: 25, cal: 526, pro: 6.0, carb: 53, fat: 32, fib: 4.5, sug: 0.5, salt: 1.4)
        add("Crisps (salt & vinegar)", .snacks, serving: 25, cal: 520, pro: 5.5, carb: 54, fat: 31, fib: 4.2, sug: 1.0, salt: 1.8)
        add("Chocolate Bar (milk)", .snacks, serving: 45, cal: 535, pro: 8.0, carb: 56, fat: 30, fib: 2.4, sug: 52)
        add("Digestive Biscuit", .snacks, serving: 15, cal: 487, pro: 7.0, carb: 64, fat: 22, fib: 3.0, sug: 22, salt: 1.0)
        add("Rice Cake", .snacks, serving: 9, cal: 387, pro: 8.0, carb: 81, fat: 2.8, fib: 3.5, sug: 0.4)
        add("Popcorn (plain, air-popped)", .snacks, serving: 30, cal: 375, pro: 11, carb: 74, fat: 4.3, fib: 15, sug: 0.9)
        add("Trail Mix", .snacks, serving: 30, cal: 462, pro: 14, carb: 45, fat: 29, fib: 5.0, sug: 28)
        add("Protein Bar", .snacks, serving: 60, cal: 350, pro: 33, carb: 35, fat: 10, fib: 5.0, sug: 3.0, salt: 0.5)

        // ═══════════════════════════════════════════
        // SOUTH ASIAN FOODS
        // ═══════════════════════════════════════════
        add("Biryani (chicken)", .prepared, serving: 350, cal: 178, pro: 11, carb: 22, fat: 5.5, fib: 1.0, sug: 1.5, salt: 0.9)
        add("Biryani (veg)", .prepared, serving: 350, cal: 152, pro: 4.0, carb: 25, fat: 4.0, fib: 2.0, sug: 2.0, salt: 0.7)
        add("Dal (toor dal)", .prepared, serving: 250, cal: 116, pro: 7.5, carb: 17, fat: 2.0, fib: 5.0, sug: 2.0, salt: 0.6)
        add("Dal Makhani", .prepared, serving: 250, cal: 140, pro: 6.5, carb: 14, fat: 6.5, fib: 4.0, sug: 2.5, salt: 0.7)
        add("Chana Masala", .prepared, serving: 250, cal: 150, pro: 8.0, carb: 22, fat: 4.0, fib: 6.0, sug: 3.0, salt: 0.8)
        add("Palak Paneer", .prepared, serving: 250, cal: 148, pro: 9.0, carb: 6.0, fat: 10, fib: 2.5, sug: 2.0, salt: 0.7)
        add("Butter Chicken", .prepared, serving: 250, cal: 175, pro: 14, carb: 8.0, fat: 10, fib: 1.0, sug: 3.5, salt: 1.0)
        add("Tandoori Chicken", .protein, serving: 200, cal: 148, pro: 25, carb: 3.0, fat: 4.5, fib: 0.5, sug: 1.0, salt: 1.2)
        add("Samosa (vegetable)", .snacks, serving: 80, cal: 262, pro: 5.0, carb: 32, fat: 13, fib: 2.5, sug: 2.0, salt: 0.6)
        add("Samosa (chicken)", .snacks, serving: 80, cal: 245, pro: 9.0, carb: 28, fat: 11, fib: 1.5, sug: 1.5, salt: 0.7)
        add("Naan Bread (plain)", .bakery, serving: 90, cal: 262, pro: 9.0, carb: 45, fat: 5.0, fib: 2.0, sug: 3.5, salt: 0.9)
        add("Roti / Chapati", .bakery, serving: 40, cal: 297, pro: 10, carb: 50, fat: 6.0, fib: 4.0, sug: 1.5, salt: 0.5)
        add("Paratha", .bakery, serving: 70, cal: 326, pro: 8.0, carb: 45, fat: 13, fib: 3.0, sug: 1.5, salt: 0.6)
        add("Dosa (plain)", .bakery, serving: 100, cal: 168, pro: 4.0, carb: 28, fat: 4.5, fib: 1.0, sug: 1.0, salt: 0.3)
        add("Idli", .grain, serving: 80, cal: 130, pro: 3.5, carb: 24, fat: 1.5, fib: 1.5, sug: 0.5, salt: 0.2)
        add("Upma", .grain, serving: 200, cal: 120, pro: 3.5, carb: 18, fat: 3.5, fib: 1.5, sug: 1.0, salt: 0.5)
        add("Pongal (ven)", .grain, serving: 200, cal: 135, pro: 4.0, carb: 21, fat: 3.5, fib: 1.0, sug: 0.5, salt: 0.3)
        add("Raita", .dairy, serving: 100, cal: 52, pro: 3.0, carb: 5.0, fat: 2.0, fib: 0.5, sug: 3.5, salt: 0.3)
        add("Paneer (raw)", .dairy, serving: 100, cal: 265, pro: 18, carb: 1.2, fat: 21, fib: 0, sug: 0.5)
        add("Ghee", .oils, serving: 14, cal: 900, pro: 0, carb: 0, fat: 99.5, fib: 0)
        add("Lassi (sweet)", .drinks, serving: 250, cal: 72, pro: 3.0, carb: 12, fat: 1.5, fib: 0, sug: 11)
        add("Masala Chai", .drinks, serving: 200, cal: 42, pro: 1.5, carb: 7.0, fat: 1.0, fib: 0, sug: 6.0)
        add("Gulab Jamun", .snacks, serving: 50, cal: 350, pro: 4.0, carb: 52, fat: 14, fib: 0.5, sug: 40)
        add("Jalebi", .snacks, serving: 50, cal: 365, pro: 2.5, carb: 60, fat: 13, fib: 0.2, sug: 50)
        add("Aloo Gobi", .prepared, serving: 200, cal: 95, pro: 3.0, carb: 12, fat: 4.0, fib: 3.0, sug: 2.5, salt: 0.6)
        add("Rajma (kidney bean curry)", .prepared, serving: 250, cal: 130, pro: 8.0, carb: 20, fat: 2.5, fib: 7.0, sug: 2.0, salt: 0.7)
        add("Poha (flattened rice)", .grain, serving: 200, cal: 130, pro: 2.5, carb: 25, fat: 2.5, fib: 1.0, sug: 1.5, salt: 0.4)
        add("Pav Bhaji", .prepared, serving: 300, cal: 160, pro: 5.0, carb: 22, fat: 6.0, fib: 3.0, sug: 3.0, salt: 0.8)
        add("Chole Bhature", .prepared, serving: 300, cal: 290, pro: 9.0, carb: 38, fat: 12, fib: 5.0, sug: 3.5, salt: 1.0)
        add("Fish Curry (Indian)", .prepared, serving: 250, cal: 120, pro: 14, carb: 6.0, fat: 5.0, fib: 1.5, sug: 2.0, salt: 0.9)
        add("Coconut Chutney", .condiments, serving: 30, cal: 115, pro: 2.0, carb: 6.0, fat: 9.0, fib: 2.5, sug: 2.0, salt: 0.4)
        add("Pickle (Indian mango)", .condiments, serving: 15, cal: 185, pro: 1.5, carb: 10, fat: 15, fib: 2.0, sug: 6.0, salt: 4.0)

        // ═══════════════════════════════════════════
        // EAST ASIAN FOODS
        // ═══════════════════════════════════════════
        add("Sushi (salmon nigiri)", .prepared, serving: 40, cal: 146, pro: 8.5, carb: 20, fat: 3.5, fib: 0.5, sug: 2.5, salt: 1.0)
        add("Sushi (California roll)", .prepared, serving: 150, cal: 140, pro: 5.0, carb: 22, fat: 3.5, fib: 1.0, sug: 2.0, salt: 0.8)
        add("Ramen (pork)", .prepared, serving: 500, cal: 90, pro: 5.0, carb: 10, fat: 3.5, fib: 0.5, sug: 1.5, salt: 1.8)
        add("Miso Soup", .prepared, serving: 200, cal: 40, pro: 3.0, carb: 5.0, fat: 1.0, fib: 0.5, sug: 1.5, salt: 2.0)
        add("Fried Rice (egg)", .prepared, serving: 300, cal: 163, pro: 5.5, carb: 24, fat: 5.0, fib: 1.0, sug: 1.0, salt: 1.2)
        add("Kung Pao Chicken", .prepared, serving: 250, cal: 148, pro: 14, carb: 10, fat: 6.5, fib: 2.0, sug: 4.0, salt: 1.5)
        add("Sweet & Sour Chicken", .prepared, serving: 250, cal: 165, pro: 10, carb: 22, fat: 4.5, fib: 1.0, sug: 14, salt: 1.0)
        add("Dim Sum (har gow)", .prepared, serving: 120, cal: 120, pro: 6.0, carb: 16, fat: 3.0, fib: 0.5, sug: 1.0, salt: 0.7)
        add("Spring Roll (vegetable)", .snacks, serving: 60, cal: 218, pro: 4.0, carb: 28, fat: 10, fib: 2.0, sug: 2.5, salt: 0.5)
        add("Tofu (firm)", .protein, serving: 150, cal: 144, pro: 17, carb: 3.0, fat: 8.0, fib: 2.0, sug: 0.7)
        add("Edamame", .protein, serving: 100, cal: 121, pro: 12, carb: 9.0, fat: 5.0, fib: 5.0, sug: 2.0, salt: 0.01)
        add("Pad Thai", .prepared, serving: 300, cal: 145, pro: 7.0, carb: 20, fat: 4.5, fib: 1.5, sug: 5.0, salt: 1.4)
        add("Tom Yum Soup", .prepared, serving: 300, cal: 35, pro: 3.0, carb: 4.0, fat: 1.0, fib: 0.5, sug: 2.0, salt: 1.5)
        add("Green Curry (Thai)", .prepared, serving: 250, cal: 125, pro: 9.0, carb: 6.0, fat: 8.0, fib: 1.5, sug: 3.0, salt: 1.2)
        add("Kimchi", .vegetable, serving: 100, cal: 15, pro: 1.1, carb: 2.4, fat: 0.5, fib: 1.6, sug: 1.1, salt: 2.7)
        add("Japchae (Korean glass noodles)", .prepared, serving: 200, cal: 140, pro: 3.5, carb: 26, fat: 3.0, fib: 1.5, sug: 6.0, salt: 0.9)
        add("Bibimbap", .prepared, serving: 400, cal: 122, pro: 7.0, carb: 16, fat: 3.5, fib: 2.0, sug: 2.5, salt: 1.0)
        add("Pho (Vietnamese)", .prepared, serving: 500, cal: 60, pro: 5.0, carb: 7.0, fat: 1.5, fib: 0.5, sug: 1.0, salt: 1.6)
        add("Banh Mi (Vietnamese)", .prepared, serving: 250, cal: 210, pro: 12, carb: 30, fat: 5.0, fib: 2.0, sug: 4.0, salt: 1.3)
        add("Soy Sauce", .condiments, serving: 15, cal: 53, pro: 5.0, carb: 8.0, fat: 0.04, fib: 0.4, sug: 1.0, salt: 14.0)
        add("Teriyaki Sauce", .condiments, serving: 15, cal: 89, pro: 3.0, carb: 16, fat: 0, fib: 0, sug: 14, salt: 3.5)

        // ═══════════════════════════════════════════
        // MIDDLE EASTERN FOODS
        // ═══════════════════════════════════════════
        add("Hummus", .prepared, serving: 100, cal: 177, pro: 8.0, carb: 14, fat: 10, fib: 6.0, sug: 0.5, salt: 0.6)
        add("Falafel", .prepared, serving: 50, cal: 333, pro: 13, carb: 32, fat: 18, fib: 5.0, sug: 3.0, salt: 0.8)
        add("Shawarma (chicken)", .prepared, serving: 200, cal: 155, pro: 18, carb: 5.0, fat: 7.0, fib: 1.0, sug: 2.0, salt: 1.1)
        add("Tabbouleh", .prepared, serving: 150, cal: 90, pro: 2.5, carb: 13, fat: 3.5, fib: 2.5, sug: 2.0, salt: 0.4)
        add("Baba Ganoush", .prepared, serving: 100, cal: 95, pro: 2.0, carb: 8.0, fat: 6.0, fib: 3.0, sug: 3.5, salt: 0.5)
        add("Kebab (lamb kofte)", .protein, serving: 150, cal: 225, pro: 18, carb: 5.0, fat: 15, fib: 0.5, sug: 1.5, salt: 1.0)
        add("Fattoush", .prepared, serving: 150, cal: 70, pro: 2.0, carb: 10, fat: 3.0, fib: 2.5, sug: 3.0, salt: 0.5)
        add("Baklava", .snacks, serving: 50, cal: 428, pro: 7.0, carb: 46, fat: 25, fib: 2.0, sug: 33)

        // ═══════════════════════════════════════════
        // AFRICAN FOODS
        // ═══════════════════════════════════════════
        add("Jollof Rice", .prepared, serving: 300, cal: 150, pro: 3.5, carb: 25, fat: 4.0, fib: 1.5, sug: 3.0, salt: 0.7)
        add("Fufu (cassava)", .grain, serving: 200, cal: 160, pro: 1.5, carb: 38, fat: 0.3, fib: 1.8, sug: 1.7)
        add("Egusi Soup", .prepared, serving: 300, cal: 150, pro: 9.0, carb: 5.0, fat: 11, fib: 2.5, sug: 2.0, salt: 0.8)
        add("Suya (spiced beef skewer)", .protein, serving: 100, cal: 218, pro: 26, carb: 4.0, fat: 11, fib: 1.0, sug: 1.0, salt: 1.0)
        add("Injera (Ethiopian bread)", .bakery, serving: 100, cal: 145, pro: 5.0, carb: 28, fat: 1.5, fib: 2.0, sug: 1.5, salt: 0.3)
        add("Wat (Ethiopian stew)", .prepared, serving: 250, cal: 120, pro: 8.0, carb: 10, fat: 6.0, fib: 3.0, sug: 3.0, salt: 0.9)
        add("Plantain (fried)", .vegetable, serving: 100, cal: 200, pro: 1.0, carb: 38, fat: 5.5, fib: 2.0, sug: 14)
        add("Ugali (maize meal)", .grain, serving: 200, cal: 125, pro: 2.5, carb: 28, fat: 0.5, fib: 1.5, sug: 0.5)
        add("Bobotie (South African)", .prepared, serving: 250, cal: 155, pro: 11, carb: 10, fat: 8.0, fib: 1.5, sug: 4.0, salt: 0.8)

        // ═══════════════════════════════════════════
        // EUROPEAN FOODS
        // ═══════════════════════════════════════════
        add("Croissant", .bakery, serving: 60, cal: 406, pro: 8.2, carb: 46, fat: 21, fib: 2.0, sug: 7.0, salt: 0.8)
        add("Baguette", .bakery, serving: 100, cal: 274, pro: 9.0, carb: 54, fat: 1.5, fib: 2.5, sug: 3.0, salt: 1.2)
        add("Paella (seafood)", .prepared, serving: 350, cal: 135, pro: 8.5, carb: 17, fat: 4.0, fib: 1.0, sug: 1.5, salt: 0.8)
        add("Moussaka", .prepared, serving: 300, cal: 145, pro: 8.0, carb: 11, fat: 8.0, fib: 2.5, sug: 3.5, salt: 0.7)
        add("Gyros (lamb)", .prepared, serving: 200, cal: 210, pro: 16, carb: 18, fat: 8.5, fib: 1.5, sug: 2.5, salt: 1.2)
        add("Pierogi (potato, cheese)", .prepared, serving: 200, cal: 195, pro: 6.5, carb: 30, fat: 5.5, fib: 1.5, sug: 1.5, salt: 0.5)
        add("Borscht", .prepared, serving: 300, cal: 45, pro: 2.0, carb: 8.0, fat: 1.0, fib: 2.0, sug: 5.0, salt: 0.7)
        add("Pelmeni (Russian dumplings)", .prepared, serving: 200, cal: 186, pro: 9.0, carb: 24, fat: 6.0, fib: 1.0, sug: 1.0, salt: 0.8)
        add("Blini (Russian pancake)", .bakery, serving: 80, cal: 233, pro: 6.5, carb: 34, fat: 8.0, fib: 1.0, sug: 2.5, salt: 0.5)
        add("Schnitzel (chicken)", .protein, serving: 150, cal: 215, pro: 22, carb: 12, fat: 9.0, fib: 0.5, sug: 0.5, salt: 0.8)
        add("Bratwurst", .protein, serving: 100, cal: 296, pro: 14, carb: 3.0, fat: 25, fib: 0, sug: 1.0, salt: 1.8)
        add("Risotto (mushroom)", .prepared, serving: 300, cal: 140, pro: 4.0, carb: 20, fat: 5.0, fib: 1.0, sug: 1.0, salt: 0.6)

        // ═══════════════════════════════════════════
        // AMERICAN FOODS
        // ═══════════════════════════════════════════
        add("Burrito (chicken)", .prepared, serving: 350, cal: 175, pro: 10, carb: 22, fat: 5.5, fib: 3.0, sug: 2.0, salt: 1.0)
        add("Tacos (beef)", .prepared, serving: 150, cal: 210, pro: 12, carb: 18, fat: 10, fib: 2.0, sug: 2.5, salt: 0.9)
        add("Nachos with Cheese", .snacks, serving: 100, cal: 346, pro: 7.0, carb: 35, fat: 20, fib: 2.0, sug: 1.0, salt: 1.5)
        add("Mac and Cheese", .prepared, serving: 250, cal: 164, pro: 7.0, carb: 18, fat: 7.5, fib: 1.0, sug: 2.5, salt: 0.8)
        add("Pancakes (buttermilk)", .bakery, serving: 100, cal: 227, pro: 6.0, carb: 34, fat: 8.0, fib: 1.0, sug: 10, salt: 1.0)
        add("Hot Dog", .prepared, serving: 150, cal: 245, pro: 10, carb: 22, fat: 13, fib: 1.0, sug: 4.0, salt: 1.4)
        add("Jambalaya", .prepared, serving: 300, cal: 115, pro: 8.0, carb: 14, fat: 3.5, fib: 1.5, sug: 2.0, salt: 0.9)
        add("Clam Chowder", .prepared, serving: 250, cal: 95, pro: 4.5, carb: 10, fat: 4.0, fib: 1.0, sug: 2.0, salt: 1.0)
        add("Peanut Butter & Jelly Sandwich", .prepared, serving: 150, cal: 310, pro: 10, carb: 42, fat: 13, fib: 3.0, sug: 20, salt: 0.8)

        // ═══════════════════════════════════════════
        // DRINKS (Soft, Branded, Juices)
        // ═══════════════════════════════════════════
        add("Coca-Cola", .drinks, "Coca-Cola", serving: 330, cal: 42, pro: 0, carb: 10.6, fat: 0, fib: 0, sug: 10.6, salt: 0.01)
        add("Coca-Cola Zero", .drinks, "Coca-Cola", serving: 330, cal: 0.3, pro: 0, carb: 0, fat: 0, fib: 0, sug: 0, salt: 0.02)
        add("Diet Coke", .drinks, "Coca-Cola", serving: 330, cal: 1.0, pro: 0, carb: 0, fat: 0, fib: 0, sug: 0, salt: 0.03)
        add("Pepsi", .drinks, "Pepsi", serving: 330, cal: 44, pro: 0, carb: 11, fat: 0, fib: 0, sug: 11, salt: 0.02)
        add("Pepsi Max", .drinks, "Pepsi", serving: 330, cal: 0.4, pro: 0, carb: 0, fat: 0, fib: 0, sug: 0, salt: 0.03)
        add("Sprite", .drinks, "Coca-Cola", serving: 330, cal: 36, pro: 0, carb: 9.0, fat: 0, fib: 0, sug: 9.0, salt: 0.01)
        add("Fanta Orange", .drinks, "Coca-Cola", serving: 330, cal: 42, pro: 0, carb: 10, fat: 0, fib: 0, sug: 10, salt: 0.02)
        add("Red Bull", .drinks, "Red Bull", serving: 250, cal: 46, pro: 0, carb: 11, fat: 0, fib: 0, sug: 11, salt: 0.1)
        add("Monster Energy", .drinks, "Monster", serving: 500, cal: 47, pro: 0, carb: 12, fat: 0, fib: 0, sug: 11.5, salt: 0.18)
        add("Lucozade Original", .drinks, "Lucozade", serving: 380, cal: 66, pro: 0, carb: 17, fat: 0, fib: 0, sug: 13, salt: 0.01)
        add("Ribena", .drinks, "Ribena", serving: 250, cal: 41, pro: 0, carb: 10, fat: 0, fib: 0, sug: 9.9)
        add("Orange Juice (fresh)", .drinks, serving: 250, cal: 45, pro: 0.7, carb: 10, fat: 0.2, fib: 0.2, sug: 8.4)
        add("Apple Juice", .drinks, serving: 250, cal: 46, pro: 0.1, carb: 11, fat: 0.1, fib: 0.1, sug: 10)
        add("Mango Juice", .drinks, serving: 250, cal: 54, pro: 0.3, carb: 14, fat: 0.1, fib: 0.3, sug: 13)
        add("Coconut Water", .drinks, serving: 330, cal: 19, pro: 0.7, carb: 3.7, fat: 0.2, fib: 1.1, sug: 2.6, salt: 0.1)
        add("Lemonade", .drinks, serving: 330, cal: 44, pro: 0.1, carb: 11, fat: 0, fib: 0, sug: 10)
        add("Iced Tea", .drinks, serving: 330, cal: 30, pro: 0, carb: 7.5, fat: 0, fib: 0, sug: 7.0, salt: 0.01)
        add("Tonic Water", .drinks, serving: 200, cal: 34, pro: 0, carb: 8.8, fat: 0, fib: 0, sug: 8.0)
        add("Smoothie (berry)", .drinks, serving: 250, cal: 52, pro: 1.0, carb: 12, fat: 0.3, fib: 1.5, sug: 9.0)
        add("Protein Shake (whey, milk)", .drinks, serving: 400, cal: 80, pro: 16, carb: 6.0, fat: 1.5, fib: 0.5, sug: 4.0, salt: 0.3)
        add("Coffee (black)", .drinks, serving: 240, cal: 2, pro: 0.3, carb: 0, fat: 0, fib: 0, sug: 0)
        add("Coffee (latte, whole milk)", .drinks, serving: 350, cal: 55, pro: 3.0, carb: 5.0, fat: 2.5, fib: 0, sug: 4.5)
        add("Cappuccino (whole milk)", .drinks, serving: 300, cal: 52, pro: 3.5, carb: 5.0, fat: 2.0, fib: 0, sug: 4.5)
        add("Matcha Latte", .drinks, serving: 350, cal: 60, pro: 3.0, carb: 8.0, fat: 2.0, fib: 0, sug: 7.0)
        add("Hot Chocolate", .drinks, serving: 300, cal: 80, pro: 3.5, carb: 13, fat: 2.5, fib: 1.0, sug: 11)
        add("Beer (lager, pint)", .drinks, serving: 568, cal: 43, pro: 0.3, carb: 3.6, fat: 0, fib: 0, sug: 0.3)
        add("Wine (red, glass)", .drinks, serving: 175, cal: 85, pro: 0.1, carb: 2.6, fat: 0, fib: 0, sug: 0.6)
        add("Wine (white, glass)", .drinks, serving: 175, cal: 82, pro: 0.1, carb: 2.6, fat: 0, fib: 0, sug: 1.0)

        // ═══════════════════════════════════════════
        // SUPERFOODS & HEALTH FOODS
        // ═══════════════════════════════════════════
        add("Chia Seeds", .superfoods, serving: 15, cal: 486, pro: 17, carb: 42, fat: 31, fib: 34, sug: 0.8)
        add("Flaxseeds", .superfoods, serving: 15, cal: 534, pro: 18, carb: 29, fat: 42, fib: 27, sug: 1.6)
        add("Spirulina (powder)", .superfoods, serving: 5, cal: 290, pro: 57, carb: 24, fat: 8.0, fib: 3.6, sug: 3.1, salt: 1.05)
        add("Moringa (powder)", .superfoods, serving: 5, cal: 205, pro: 9.4, carb: 38, fat: 2.0, fib: 19, sug: 3.0)
        add("Açaí Bowl", .prepared, serving: 300, cal: 110, pro: 2.0, carb: 18, fat: 4.0, fib: 3.5, sug: 12)
        add("Tempeh", .protein, serving: 100, cal: 192, pro: 20, carb: 8.0, fat: 11, fib: 5.5, sug: 0.5)
        add("Seitan", .protein, serving: 100, cal: 120, pro: 21, carb: 4.0, fat: 1.5, fib: 0.5, sug: 0.5)

        return db
    }
}

// MARK: - Serving Size Presets

struct ServingPreset: Identifiable {
    let id = UUID()
    let label: String
    let grams: Double
}

let defaultServingPresets: [ServingPreset] = [
    ServingPreset(label: "25g", grams: 25),
    ServingPreset(label: "50g", grams: 50),
    ServingPreset(label: "75g", grams: 75),
    ServingPreset(label: "100g", grams: 100),
    ServingPreset(label: "150g", grams: 150),
    ServingPreset(label: "200g", grams: 200),
    ServingPreset(label: "250g", grams: 250),
    ServingPreset(label: "300g", grams: 300),
    ServingPreset(label: "500g", grams: 500),
]

// MARK: - Food Search View (Main entry point)

struct FoodSearchView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    @State private var searchText = ""
    @State private var selectedFood: FoodItem? = nil
    @State private var showNutritionDetail = false
    @FocusState private var searchFocused: Bool

    private let db = FoodDatabase.shared

    var searchResults: [FoodItem] {
        db.search(searchText)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                    // Results
                    if searchText.isEmpty {
                        emptyState
                    } else if searchResults.isEmpty {
                        noResultsView
                    } else {
                        resultsList
                    }
                }
            }
            .navigationTitle("Food Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showNutritionDetail) {
                if let food = selectedFood {
                    FoodNutritionDetailView(food: food)
                }
            }
            .onAppear { searchFocused = true }
        }
    }

    var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search any food or product...", text: $searchText)
                .focused($searchFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
        .padding(.horizontal).padding(.top, 8)
    }

    var emptyState: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 40)
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 50))
                    .foregroundColor(.brandPurple.opacity(0.3))
                Text("Search Foods & Products")
                    .font(.title3.bold())
                Text("Type any food, recipe, or product name.\nWe'll show you the full nutritional breakdown.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                // Popular categories
                VStack(alignment: .leading, spacing: 12) {
                    Text("Popular Searches").font(.headline).padding(.horizontal)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        popularChip("Chicken Breast")
                        popularChip("Rice")
                        popularChip("Banana")
                        popularChip("Eggs")
                        popularChip("Oats")
                        popularChip("Salmon")
                        popularChip("Avocado")
                        popularChip("Greek Yoghurt")
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 20)
            }
        }
    }

    func popularChip(_ name: String) -> some View {
        Button { searchText = name } label: {
            Text(name)
                .font(.subheadline)
                .foregroundColor(.brandPurple)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.brandPurple.opacity(0.08))
                .cornerRadius(10)
        }
    }

    var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No results for \"\(searchText)\"")
                .font(.headline).foregroundColor(.secondary)
            Text("Try a different spelling or search term")
                .font(.subheadline).foregroundColor(.secondary.opacity(0.7))
            Spacer()
        }
    }

    var resultsList: some View {
        List(searchResults.prefix(20)) { food in
            Button {
                selectedFood = food
                showNutritionDetail = true
            } label: {
                HStack(spacing: 12) {
                    Text(food.category.icon)
                        .font(.title2)
                        .frame(width: 36)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(food.name)
                            .font(.body).fontWeight(.medium)
                            .foregroundColor(.primary)
                        HStack(spacing: 8) {
                            Text("\(Int(food.caloriesPer100g)) kcal/100g")
                                .font(.caption)
                                .foregroundColor(.brandAmber)
                            if !food.brand.isEmpty {
                                Text(food.brand)
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.brandTeal)
                                    .cornerRadius(4)
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption).foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Nutrition Detail View (for a selected food)

struct FoodNutritionDetailView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss

    let food: FoodItem

    @State private var selectedGrams: Double
    @State private var customGrams: String = ""
    @State private var mealType: MealType = .snack
    @State private var showSaved = false

    init(food: FoodItem) {
        self.food = food
        _selectedGrams = State(initialValue: Double(food.defaultServingGrams))
    }

    var nutrition: NutritionValues {
        food.nutritionFor(grams: selectedGrams)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text(food.category.icon).font(.system(size: 50))
                        Text(food.name).font(.title2.bold())
                        if !food.brand.isEmpty {
                            Text(food.brand)
                                .font(.caption).foregroundColor(.white)
                                .padding(.horizontal, 12).padding(.vertical, 4)
                                .background(Color.brandTeal).cornerRadius(8)
                        }
                    }
                    .padding(.top, 10)

                    // Gram size selector
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Serving Size").font(.headline)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                // Default serving
                                gramButton(label: "Default (\(food.defaultServingGrams)g)", grams: Double(food.defaultServingGrams))

                                ForEach(defaultServingPresets) { preset in
                                    if Int(preset.grams) != food.defaultServingGrams {
                                        gramButton(label: preset.label, grams: preset.grams)
                                    }
                                }
                            }
                        }

                        // Custom gram input
                        HStack {
                            TextField("Custom grams", text: $customGrams)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 120)
                            Text("g")
                                .foregroundColor(.secondary)
                            Button("Apply") {
                                if let g = Double(customGrams), g > 0 {
                                    selectedGrams = g
                                }
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(.brandPurple)
                        }
                    }
                    .padding(.horizontal)

                    // Big calorie card
                    VStack(spacing: 6) {
                        Text("\(Int(nutrition.calories))")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.brandAmber)
                        Text("calories for \(Int(selectedGrams))g")
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                    .padding().frame(maxWidth: .infinity)
                    .background(Color.brandAmber.opacity(0.08))
                    .cornerRadius(16).padding(.horizontal)

                    // Macronutrient bars
                    VStack(spacing: 12) {
                        Text("Nutritional Breakdown").font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        nutrientRow("Protein", value: nutrition.protein, color: .brandTeal, unit: "g")
                        nutrientRow("Carbohydrates", value: nutrition.carbs, color: .brandCoral, unit: "g")
                        nutrientRow("  of which sugars", value: nutrition.sugar, color: .brandCoral.opacity(0.7), unit: "g")
                        nutrientRow("Fat", value: nutrition.fat, color: .brandAmber, unit: "g")
                        nutrientRow("Fibre", value: nutrition.fiber, color: .brandGreen, unit: "g")
                        nutrientRow("Salt", value: nutrition.salt, color: .secondary, unit: "g")
                    }
                    .padding(.horizontal)

                    // Per-100g reference
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Per 100g Reference").font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        HStack(spacing: 16) {
                            miniStat("Cal", "\(Int(food.caloriesPer100g))")
                            miniStat("Pro", "\(String(format: "%.1f", food.proteinPer100g))g")
                            miniStat("Carb", "\(String(format: "%.1f", food.carbsPer100g))g")
                            miniStat("Fat", "\(String(format: "%.1f", food.fatPer100g))g")
                            miniStat("Fib", "\(String(format: "%.1f", food.fiberPer100g))g")
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12).padding(.horizontal)

                    // Log to nutrition section
                    VStack(spacing: 12) {
                        Text("Log This Food").font(.headline)
                        Picker("Meal", selection: $mealType) {
                            ForEach(MealType.allCases, id: \.self) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)

                        Button {
                            logFood()
                        } label: {
                            HStack {
                                Image(systemName: showSaved ? "checkmark.circle.fill" : "plus.circle.fill")
                                Text(showSaved ? "Saved!" : "Add to \(mealType.rawValue)")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(showSaved ? Color.brandGreen : Color.brandPurple)
                            .cornerRadius(14)
                        }
                        .disabled(showSaved)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .background(Color.brandBg)
            .navigationTitle("Nutrition Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    func gramButton(label: String, grams: Double) -> some View {
        Button {
            selectedGrams = grams
            customGrams = ""
        } label: {
            Text(label)
                .font(.caption.bold())
                .foregroundColor(selectedGrams == grams ? .white : .brandPurple)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(selectedGrams == grams ? Color.brandPurple : Color.brandPurple.opacity(0.1))
                .cornerRadius(20)
        }
    }

    func nutrientRow(_ label: String, value: Double, color: Color, unit: String) -> some View {
        HStack {
            Text(label).font(.subheadline)
            Spacer()
            Text("\(String(format: value >= 10 ? "%.0f" : "%.1f", value))\(unit)")
                .font(.subheadline.bold())
                .foregroundColor(color)
        }
        .padding(.vertical, 2)
    }

    func miniStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.caption.bold())
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
    }

    func logFood() {
        let n = nutrition
        let log = NutritionLog(
            date: Date(),
            mealType: mealType,
            calories: Int(n.calories),
            carbs: n.carbs,
            protein: n.protein,
            fat: n.fat,
            fiber: n.fiber,
            sugar: n.sugar,
            salt: n.salt,
            foodName: "\(food.name) (\(Int(selectedGrams))g)"
        )
        store.nutritionLogs.append(log)
        store.save()
        showSaved = true

        // Reset after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showSaved = false
        }
    }
}
