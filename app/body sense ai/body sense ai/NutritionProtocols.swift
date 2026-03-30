//
//  NutritionProtocols.swift
//  body sense ai
//
//  Condition-specific nutrition protocols distilled from research:
//  BNF, NICE, ADA, KDOQI, ESC/EAS, WHO guidelines.
//  Two-tier knowledge: compact (on-device) and extended (cloud).
//

import Foundation

// MARK: - Nutrition Protocols

enum NutritionProtocols {

    // MARK: - Public API

    /// Returns condition-specific nutrition guidance formatted for AI context injection.
    static func protocolForConditions(_ conditions: [String], tier: HealthKnowledgeBase.Tier) -> String {
        let normalised = conditions.map { $0.lowercased() }
        var sections: [String] = []

        for (key, value) in allProtocols {
            if normalised.contains(where: { key.contains($0) || $0.contains(key) }) {
                sections.append(tier == .compact ? value.compact : value.extended)
            }
        }

        guard !sections.isEmpty else { return "" }
        return "--- CONDITION-SPECIFIC NUTRITION PROTOCOLS ---\n" + sections.joined(separator: "\n\n")
    }

    /// Calculate personalised protein target based on weight and conditions.
    static func proteinTarget(weightKg: Double, conditions: [String]) -> (min: Double, max: Double, unit: String) {
        let normalised = conditions.map { $0.lowercased() }

        // CKD takes priority (restrictive)
        if normalised.contains(where: { $0.contains("ckd") || $0.contains("kidney") }) {
            if normalised.contains(where: { $0.contains("dialysis") }) {
                return (weightKg * 1.0, weightKg * 1.2, "g/day")
            }
            return (weightKg * 0.6, weightKg * 0.8, "g/day")
        }

        // Fitness / muscle building
        if normalised.contains(where: { $0.contains("fitness") || $0.contains("muscle") || $0.contains("athlete") }) {
            return (weightKg * 1.6, weightKg * 2.2, "g/day")
        }

        // Elderly / sarcopenia
        if normalised.contains(where: { $0.contains("elderly") || $0.contains("sarcopenia") || $0.contains("over 65") }) {
            return (weightKg * 1.0, weightKg * 1.2, "g/day")
        }

        // Type 2 Diabetes
        if normalised.contains(where: { $0.contains("type 2") || $0.contains("t2d") || $0.contains("diabetes") }) {
            return (weightKg * 1.0, weightKg * 1.2, "g/day")
        }

        // Hypertension (DASH)
        if normalised.contains(where: { $0.contains("hypertension") || $0.contains("high blood pressure") }) {
            return (weightKg * 0.8, weightKg * 1.0, "g/day")
        }

        // Pregnancy
        if normalised.contains(where: { $0.contains("pregnant") || $0.contains("pregnancy") }) {
            return (weightKg * 1.1, weightKg * 1.5, "g/day")
        }

        // General healthy adult
        return (weightKg * 0.8, weightKg * 1.0, "g/day")
    }

    /// Cooking method nutrient impact guidance.
    static let cookingMethodGuidance = """
    COOKING METHOD NUTRIENT IMPACTS:
    • Boiling: Loses 25-50% water-soluble vitamins (B, C) into cooking water. Use the liquid for soups/sauces.
    • Steaming: Retains 80-90% of nutrients. Best for vegetables.
    • Microwaving: Short cooking time preserves nutrients well. Minimal water loss.
    • Stir-frying: Quick high heat retains most nutrients. Use minimal oil.
    • Roasting/Baking: Good nutrient retention for most foods. Some vitamin C loss.
    • Grilling: Good retention but avoid charring (carcinogenic compounds). PAH formation at >300°C.
    • Slow cooking: Retains minerals but loses heat-sensitive vitamins. Liquid retains nutrients.
    • Raw: Maximum nutrient content but reduced bioavailability for some (e.g. lycopene, beta-carotene).
    • Soaking legumes: Reduces phytates/lectins, improving mineral absorption.
    • Fermentation: Increases bioavailability; creates probiotics; reduces antinutrients.
    """

    /// Protein source quality data.
    static let proteinQuality = """
    PROTEIN QUALITY SCORES (DIAAS/PDCAAS):
    • Whey protein: DIAAS 1.09 (excellent) — fast absorption, high leucine
    • Eggs: DIAAS 1.13 (excellent) — complete amino acid profile
    • Milk: DIAAS 1.14 (excellent) — casein + whey blend
    • Chicken breast: DIAAS 1.08 (excellent) — lean, high bioavailability
    • Beef: DIAAS 1.12 (excellent) — complete aminos, high iron
    • Fish: DIAAS 1.0+ (excellent) — omega-3 bonus
    • Soy: DIAAS 0.90 (good) — best plant source, complete aminos
    • Chickpeas: DIAAS 0.83 (good) — combine with grains for complete profile
    • Lentils: DIAAS 0.58 (moderate) — low in methionine, combine with rice
    • Rice: DIAAS 0.60 (moderate) — low in lysine, combine with legumes
    • Wheat: DIAAS 0.40 (low) — low in lysine
    • Peanuts: DIAAS 0.43 (low) — combine with wholegrains

    LEUCINE THRESHOLD: 2.5g per meal triggers maximum muscle protein synthesis.
    • Chicken breast 100g = 2.5g leucine
    • Eggs × 3 = 1.6g leucine (need 4-5 for threshold)
    • Tofu 200g = 1.4g leucine (combine with other sources)
    • Lentils 200g cooked = 1.3g leucine
    """

    // MARK: - Protocol Database

    private struct ProtocolPair {
        let compact: String
        let extended: String
    }

    private static let allProtocols: [String: ProtocolPair] = [

        "ckd": ProtocolPair(
            compact: """
            CKD NUTRITION: Protein 0.6-0.8g/kg stages 3-5 (1.0-1.2g/kg on dialysis). \
            Limit potassium <2000mg/day if hyperkalaemic. Phosphorus <800mg/day. \
            Sodium <2000mg/day. Fluid restriction per nephrologist. \
            Avoid: star fruit (neurotoxic in CKD), excess dairy (phosphorus), \
            processed meats (sodium + phosphorus additives).
            """,
            extended: """
            CKD NUTRITION PROTOCOL (KDOQI/NICE):

            PROTEIN TARGETS BY STAGE:
            • CKD Stage 1-2: Normal protein (0.8-1.0g/kg)
            • CKD Stage 3a-3b: 0.6-0.8g/kg/day — slow progression
            • CKD Stage 4-5 (pre-dialysis): 0.6-0.8g/kg/day — strict
            • Haemodialysis: 1.0-1.2g/kg/day — compensate for dialysis losses
            • Peritoneal dialysis: 1.2-1.3g/kg/day — higher due to protein loss in dialysate
            • Favour high biological value sources: eggs, fish, poultry (50% of protein)

            POTASSIUM MANAGEMENT:
            • Target: <2000-2500mg/day if K+ elevated
            • Boil vegetables to leach potassium (30-50% reduction)
            • Avoid: bananas, oranges, tomatoes, potatoes (unless leached), dried fruit, chocolate
            • Safe fruits: apples, berries, grapes, pineapple
            • Double-boiling technique: peel, chop, soak 2hrs, boil in fresh water

            PHOSPHORUS MANAGEMENT:
            • Target: <800-1000mg/day
            • Avoid phosphorus ADDITIVES (E338-E343, E450-E452) — absorbed 90-100% vs 40-60% natural
            • Limit: processed cheese, cola drinks, processed meats, canned fish (with bones)
            • Take phosphate binders WITH meals (not between meals)

            SODIUM: <2000mg/day. Use herbs/spices instead. Avoid processed foods.
            FLUID: Per nephrologist; typically previous day urine output + 500ml
            """
        ),

        "diabetes": ProtocolPair(
            compact: """
            DIABETES NUTRITION: Protein 1.0-1.2g/kg. GI-based carb selection. \
            Distribute carbs evenly across meals. Fibre >30g/day (NICE NG28). \
            Post-meal walk 15min reduces glucose 30-50%. \
            Mediterranean diet: HbA1c reduction 0.3-0.5%. \
            Avoid: sugary drinks, refined carbs, large carb loads. \
            Carb counting for T1D insulin dosing.
            """,
            extended: """
            DIABETES NUTRITION PROTOCOL (NICE NG28 / ADA Standards):

            TYPE 2 DIABETES:
            • Protein: 1.0-1.2g/kg — supports satiety and muscle maintenance
            • Carbohydrates: 40-50% of energy, focus on low-GI sources
            • Fat: <35% energy; favour unsaturated (olive oil, nuts, oily fish)
            • Fibre: >30g/day — reduces post-meal glucose spikes
            • Sodium: <2300mg/day (<1500mg if hypertensive)

            GLYCAEMIC INDEX GUIDANCE:
            • Low GI (<55): porridge, sweet potato, lentils, chickpeas, most fruits, basmati rice
            • Medium GI (56-69): brown rice, wholemeal bread, pitta bread
            • High GI (>70): white bread, white rice, potatoes, cornflakes, watermelon
            • Pairing high-GI foods with protein/fat/fibre lowers overall glycaemic response

            MEAL TIMING:
            • Eat within 1 hour of waking (reduces cortisol-driven glucose rise)
            • 3 main meals + 1-2 snacks to prevent glucose swings
            • Last meal 3+ hours before bed
            • 15-minute post-meal walk reduces glucose by 30-50% (most effective intervention)

            TYPE 1 DIABETES CARB COUNTING:
            • 1 unit rapid insulin per 10-15g carbs (individual ratio)
            • Count total carbs, not just sugar
            • Factor in protein: >25g protein in a meal may need additional insulin (fat-protein units)
            • Pre-exercise: may need 15-30g extra carbs or insulin reduction

            SOUTH ASIAN ADAPTATIONS:
            • Brown rice or 50:50 mix instead of white basmati
            • Whole wheat atta (not maida) for roti
            • Measured oil: 1 tsp per person per dish
            • Dal with vegetables — high fibre, moderate GI
            • Avoid: mithai, fried snacks, sugary chai
            """
        ),

        "type 1": ProtocolPair(
            compact: """
            T1D NUTRITION: Carb counting essential. 1 unit insulin per 10-15g carbs (individual). \
            Factor protein >25g for fat-protein units. Pre-exercise carbs 15-30g. \
            Hypo treatment: 15g fast-acting carbs, wait 15 min, recheck. \
            CGM with meal tagging improves time-in-range.
            """,
            extended: """
            TYPE 1 DIABETES NUTRITION:

            CARB COUNTING:
            • Insulin-to-carb ratio (ICR): typically 1 unit per 10-15g carbs
            • Individualise with endo/DSN — varies by time of day
            • Count total carbohydrates, not just sugar
            • Weigh/measure portions for accuracy (especially early on)

            FAT-PROTEIN UNITS (FPU):
            • High-fat meals (pizza, curry) cause delayed glucose rise (4-8 hours)
            • If >25g protein or >15g fat beyond carbs: consider extended bolus
            • Rule of thumb: 100 kcal from fat+protein = 1 FPU = ~10g equivalent carbs

            HYPO TREATMENT (15-15 RULE):
            • Blood glucose <4.0 mmol/L: take 15g fast-acting carbs
            • Examples: 3-4 glucose tablets, 150ml fruit juice, 5 jelly babies
            • Recheck after 15 minutes; repeat if still <4.0
            • Follow with slow-acting carb (toast, biscuit) if next meal >1 hour away

            EXERCISE:
            • Aerobic: reduce bolus by 25-75% OR take 15-30g extra carbs per 30 min
            • Resistance: may cause initial glucose rise (adrenaline); monitor after
            • Check glucose before, during (every 30 min), and after
            • Avoid exercise if glucose >14 mmol/L with ketones
            """
        ),

        "hypertension": ProtocolPair(
            compact: """
            HTN NUTRITION (DASH): Sodium <1500mg/day. Potassium 4700mg/day. \
            Calcium 1000mg, Magnesium 500mg. 4-5 fruit, 4-5 veg, 2-3 low-fat dairy, \
            <2 lean meat servings daily. BP reduction: 5.5-11.4 mmHg with DASH. \
            Limit alcohol, caffeine. Beetroot juice: 4-10 mmHg reduction.
            """,
            extended: """
            HYPERTENSION NUTRITION (NICE CG127 / DASH DIET):

            DASH DIET DAILY TARGETS:
            • Grains: 6-8 servings (wholegrain)
            • Vegetables: 4-5 servings
            • Fruits: 4-5 servings
            • Low-fat dairy: 2-3 servings
            • Lean meat/fish: ≤2 servings (180g)
            • Nuts/seeds/legumes: 4-5 servings per week
            • Fats/oils: 2-3 servings (olive/rapeseed)
            • Sweets: ≤5 per week

            KEY NUTRIENTS:
            • Sodium: <1500mg/day (6g salt = 2300mg Na; 1 tsp salt = ~2300mg Na)
            • Potassium: 4700mg/day — bananas, sweet potato, spinach, avocado, beans
            • Calcium: 1000-1200mg — low-fat dairy, fortified plant milk, sardines
            • Magnesium: 400-500mg — nuts, seeds, dark chocolate, leafy greens
            • Fibre: 30g+ — wholegrains, legumes, vegetables

            EVIDENCE:
            • DASH diet alone: reduces BP 5.5-11.4 mmHg systolic
            • DASH + sodium restriction: up to 11.4 mmHg reduction
            • Weight loss: every 1kg lost = ~1 mmHg reduction
            • Beetroot juice (250ml): acute 4-10 mmHg reduction (dietary nitrate → NO)
            • Dark chocolate (70%+ cocoa, 30g): modest BP reduction via flavanols
            • Hibiscus tea: 2-3 cups/day — mild antihypertensive effect

            FOODS TO LIMIT:
            • Processed meats (salami, bacon, ham)
            • Canned soups/sauces (high sodium)
            • Cheese (especially hard cheeses)
            • Bread (hidden sodium — UK bread contributes ~1/4 of salt intake)
            • Soy sauce, stock cubes, ready meals
            """
        ),

        "cvd": ProtocolPair(
            compact: """
            CVD NUTRITION: Mediterranean diet (PREDIMED). Oily fish 2× weekly (omega-3). \
            Plant sterols 2g/day reduce LDL 10%. Nuts 30g/day. Extra virgin olive oil 40ml/day. \
            Fibre 30g+. Limit saturated fat <10% energy. Avoid trans fats completely.
            """,
            extended: """
            CVD NUTRITION PROTOCOL (ESC/EAS / NICE CG181):

            MEDITERRANEAN DIET (PREDIMED Evidence):
            • Extra virgin olive oil: 40ml/day (4 tbsp) — polyphenols + oleic acid
            • Nuts: 30g/day mixed (walnuts, almonds, hazelnuts) — 30% CVD reduction
            • Oily fish: 2+ portions/week (salmon, mackerel, sardines) — EPA/DHA 250-500mg
            • Fruits: 3+ servings/day
            • Vegetables: 2+ servings/day (including legumes 3+/week)
            • Wholegrains: prefer over refined
            • Wine: optional, max 1 glass/day with meals (do NOT start drinking for health)

            SPECIFIC CVD TARGETS:
            • Saturated fat: <10% of energy (7% if high LDL)
            • Trans fats: ZERO (avoid partially hydrogenated oils)
            • Plant sterols/stanols: 2g/day reduces LDL by 10% (fortified spreads, yoghurt drinks)
            • Soluble fibre: 7-13g/day from oats, barley, psyllium — lowers LDL 5-10%
            • Soy protein: 25g/day may reduce LDL 3-5%

            OMEGA-3 SOURCES:
            • Salmon: 1.5-2.5g EPA+DHA per 100g
            • Mackerel: 1.8-2.6g per 100g
            • Sardines: 1.4g per 100g
            • Plant: ALA from flaxseed (2.3g/tbsp), chia (1.7g/tbsp), walnuts (2.5g/30g)
            • Note: ALA conversion to EPA/DHA is low (5-10%) — oily fish preferred
            """
        ),

        "fitness": ProtocolPair(
            compact: """
            FITNESS NUTRITION: Protein 1.6-2.2g/kg/day. Leucine 2.5g/meal for MPS. \
            Carbs 3-7g/kg (moderate) to 8-12g/kg (endurance). Pre-workout: carbs 1-4g/kg 1-4hrs before. \
            Post-workout: 20-40g protein within 2hrs. Creatine 3-5g/day (most researched). \
            Caffeine 3-6mg/kg 30-60min pre-exercise.
            """,
            extended: """
            FITNESS NUTRITION PROTOCOL (ISSN / ACSM):

            PROTEIN:
            • Target: 1.6-2.2g/kg/day for muscle building
            • Distribution: 0.3-0.5g/kg per meal, 4-5 meals/day
            • Leucine threshold: 2.5g per meal triggers maximum MPS
            • Post-workout: 20-40g protein within 2 hours
            • Before sleep: 30-40g casein protein (sustained release)
            • Plant-based athletes: increase total by 10-20% (lower DIAAS)

            CARBOHYDRATES:
            • Light training: 3-5g/kg/day
            • Moderate training (1hr/day): 5-7g/kg/day
            • High-volume (1-3hrs/day): 6-10g/kg/day
            • Extreme (4-5hrs/day): 8-12g/kg/day
            • Pre-workout: 1-4g/kg, 1-4 hours before
            • During exercise >60min: 30-60g/hr carbs
            • Post-workout: 1.0-1.2g/kg within 30 min if training again same day

            EVIDENCE-BASED SUPPLEMENTS:
            • Creatine monohydrate: 3-5g/day — increases strength, power, lean mass (most researched)
            • Caffeine: 3-6mg/kg, 30-60 min pre-exercise — improves endurance and power
            • Beta-alanine: 3-6g/day — improves high-intensity performance >60s
            • Citrulline malate: 6-8g pre-workout — may improve endurance
            • Vitamin D: maintain >75 nmol/L — affects muscle function and recovery
            • Omega-3: 2-3g EPA+DHA — may reduce DOMS and inflammation

            HYDRATION:
            • Pre-exercise: 5-10ml/kg, 2-4 hours before
            • During: 150-300ml every 15-20 minutes
            • Post: 1.5L per kg body weight lost
            • Electrolytes: needed if >60 min or heavy sweating (sodium 500-700mg/L)
            """
        ),

        "pregnancy": ProtocolPair(
            compact: """
            PREGNANCY NUTRITION: Folate 400mcg pre-conception to 12 weeks (5mg if high risk). \
            Iron 30mg/day if deficient. Iodine 150-200mcg. Vitamin D 10mcg/day. \
            Calcium 1000mg. DHA 200mg. Extra 200kcal/day in third trimester only. \
            Avoid: raw fish, unpasteurised cheese, liver (vitamin A excess), alcohol.
            """,
            extended: """
            PREGNANCY NUTRITION (NICE CG62 / RCOG):

            KEY SUPPLEMENTS:
            • Folic acid: 400mcg daily from pre-conception to 12 weeks (5mg if diabetes, epilepsy, BMI >30, or previous NTD)
            • Vitamin D: 10mcg (400 IU) daily throughout pregnancy and breastfeeding
            • Iron: only if deficient (Hb <110 g/L first trimester, <105 second/third)
            • Iodine: 150-200mcg (from diet or supplement)
            • DHA: 200mg/day (oily fish 1-2 portions/week, NOT shark/swordfish/marlin)

            CALORIE NEEDS:
            • First trimester: NO extra calories needed
            • Second trimester: NO extra calories (some guidelines suggest +340 kcal)
            • Third trimester: +200 kcal/day (NICE)

            FOODS TO AVOID:
            • Raw/undercooked meat, poultry, eggs (salmonella)
            • Raw shellfish
            • Unpasteurised milk/cheese, mould-ripened soft cheese (listeria)
            • Liver and liver products (excess vitamin A — teratogenic)
            • Pâté (listeria risk)
            • Shark, swordfish, marlin (mercury) — limit tuna to 2 cans/week
            • Alcohol: ZERO safe level (NICE)
            • Caffeine: limit to 200mg/day (1 mug filter coffee)
            """
        ),

        "elderly": ProtocolPair(
            compact: """
            ELDERLY NUTRITION: Protein 1.0-1.2g/kg (sarcopenia prevention). \
            Vitamin D 20mcg/day (800 IU). Calcium 1200mg. B12 monitor (absorption declines). \
            Hydration 1.5-2L/day (thirst perception reduced). Fibre 30g for bowel health. \
            Small frequent meals if appetite poor. Fortify with energy-dense foods.
            """,
            extended: """
            ELDERLY NUTRITION (NICE / BAPEN / ESPEN):

            PROTEIN & SARCOPENIA:
            • Target: 1.0-1.2g/kg/day (higher than young adults)
            • Distribution: 25-30g per meal × 3 meals (even distribution critical)
            • Leucine: 2.5-3g per meal (may need higher threshold in elderly)
            • Combine with resistance exercise for maximum benefit
            • Signs of sarcopenia: grip strength, walking speed, muscle mass

            MICRONUTRIENTS:
            • Vitamin D: 20mcg (800 IU) daily — NICE recommends for ALL over-65s
            • Calcium: 1200mg/day (diet + supplement if needed)
            • Vitamin B12: absorption declines with age (atrophic gastritis); check levels
            • Iron: monitor especially if on PPIs or poor appetite
            • Zinc: supports immune function and wound healing
            • Omega-3: anti-inflammatory, cognitive support

            HYDRATION:
            • Minimum 1.5-2L/day (6-8 glasses)
            • Thirst perception declines with age — schedule drinks
            • Include soups, juicy fruits, herbal teas
            • Monitor urine colour (pale straw = adequate)
            • UTI risk increases with dehydration

            MALNUTRITION SCREENING:
            • Use MUST (Malnutrition Universal Screening Tool)
            • BMI <18.5 = underweight
            • Unintentional weight loss >5% in 3-6 months = concern
            • Fortify foods: add cheese, cream, butter, milk powder to meals
            • Small, frequent, energy-dense meals if appetite poor
            • Consider ONS (oral nutritional supplements) if unable to meet needs
            """
        ),
    ]
}
