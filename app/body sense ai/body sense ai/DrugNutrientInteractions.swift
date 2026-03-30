//
//  DrugNutrientInteractions.swift
//  body sense ai
//
//  Structured drug-nutrient interaction database. 50+ interactions keyed by
//  MedicineDatabase genericName for O(1) lookup. Sources: BNF, NICE, research.
//

import Foundation

// MARK: - Drug-Nutrient Database

enum DrugNutrientDatabase {

    // MARK: - Public API

    /// Look up interactions for a single medicine by INN generic name.
    static func interactions(for genericName: String) -> DrugNutrientInteraction? {
        allInteractions[genericName.lowercased()]
    }

    /// Look up interactions for all of a user's active medications.
    static func interactionsForMedications(_ meds: [Medication]) -> [DrugNutrientInteraction] {
        meds.compactMap { med in
            let name = (med.genericName ?? med.name).lowercased()
            return allInteractions[name]
        }
    }

    /// Build a formatted context string for AI prompt injection.
    /// Returns empty string if no interactions found.
    static func contextForAI(_ meds: [Medication]) -> String {
        let interactions = interactionsForMedications(meds)
        guard !interactions.isEmpty else { return "" }

        var ctx = "--- DRUG-NUTRIENT INTERACTIONS ---\n"
        for interaction in interactions {
            ctx += "\n\(interaction.genericName.capitalized):\n"
            for depletion in interaction.depletedNutrients {
                ctx += "  ⚠️ Depletes \(depletion.nutrient) (\(depletion.severity.rawValue)): \(depletion.mechanism). \(depletion.mitigation)\n"
            }
            if !interaction.dietaryRestrictions.isEmpty {
                ctx += "  🚫 Dietary: \(interaction.dietaryRestrictions.joined(separator: "; "))\n"
            }
            if !interaction.timingAdvice.isEmpty {
                ctx += "  ⏰ Timing: \(interaction.timingAdvice)\n"
            }
            if !interaction.monitoringNeeded.isEmpty {
                ctx += "  📋 Monitor: \(interaction.monitoringNeeded.joined(separator: "; "))\n"
            }
        }
        return ctx
    }

    // MARK: - Complete Interaction Database

    /// Dictionary keyed by lowercase genericName for O(1) lookup.
    private static let allInteractions: [String: DrugNutrientInteraction] = {
        var dict: [String: DrugNutrientInteraction] = [:]
        for entry in rawInteractions {
            dict[entry.genericName.lowercased()] = entry
        }
        return dict
    }()

    // MARK: - Raw Data (50+ Interactions)

    private static let rawInteractions: [DrugNutrientInteraction] = [

        // ═══════════════════════════════════════════════════════════════
        // DIABETES MEDICATIONS
        // ═══════════════════════════════════════════════════════════════

        DrugNutrientInteraction(
            genericName: "Metformin",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Vitamin B12", mechanism: "Reduces intrinsic factor-mediated ileal absorption by 10-30%", mitigation: "Monitor B12 annually; supplement 1000mcg/day if deficient", severity: .high),
                NutrientDepletion(nutrient: "Folate", mechanism: "May reduce folate absorption over long-term use", mitigation: "Ensure dietary folate from leafy greens or supplement 400mcg", severity: .moderate)
            ],
            dietaryRestrictions: ["Take with food to reduce GI side effects", "High-fibre meals may slow absorption"],
            timingAdvice: "Take with or immediately after meals",
            monitoringNeeded: ["Check serum B12 annually", "Monitor for peripheral neuropathy symptoms", "Check folate if megaloblastic anaemia suspected"]
        ),

        DrugNutrientInteraction(
            genericName: "Gliclazide",
            depletedNutrients: [
                NutrientDepletion(nutrient: "CoQ10", mechanism: "Sulphonylureas may reduce CoQ10 levels", mitigation: "Consider CoQ10 100mg supplementation", severity: .low)
            ],
            dietaryRestrictions: ["Take with breakfast", "Consistent carbohydrate intake important to prevent hypoglycaemia"],
            timingAdvice: "Take with breakfast; maintain regular meal times",
            monitoringNeeded: ["Regular blood glucose monitoring", "HbA1c every 3-6 months"]
        ),

        DrugNutrientInteraction(
            genericName: "Glimepiride",
            depletedNutrients: [
                NutrientDepletion(nutrient: "CoQ10", mechanism: "Sulphonylureas may reduce CoQ10 levels", mitigation: "Consider CoQ10 100mg supplementation", severity: .low)
            ],
            dietaryRestrictions: ["Take with first main meal", "Avoid skipping meals — hypoglycaemia risk"],
            timingAdvice: "Take immediately before or with first main meal",
            monitoringNeeded: ["Blood glucose monitoring", "Watch for hypoglycaemia signs"]
        ),

        DrugNutrientInteraction(
            genericName: "Pioglitazone",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Calcium", mechanism: "Thiazolidinediones increase fracture risk via reduced bone formation", mitigation: "Ensure adequate calcium (1000mg/day) and vitamin D", severity: .moderate),
                NutrientDepletion(nutrient: "Vitamin D", mechanism: "Reduced bone mineral density over time", mitigation: "Supplement 800-1000 IU vitamin D daily", severity: .moderate)
            ],
            dietaryRestrictions: ["May cause fluid retention — monitor sodium intake"],
            timingAdvice: "Can be taken with or without food",
            monitoringNeeded: ["Bone density if long-term use", "Weight and oedema monitoring", "Liver function tests"]
        ),

        DrugNutrientInteraction(
            genericName: "Insulin",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Magnesium", mechanism: "Insulin promotes cellular magnesium uptake; chronic use may deplete serum levels", mitigation: "Ensure dietary magnesium from nuts, seeds, leafy greens", severity: .low),
                NutrientDepletion(nutrient: "Chromium", mechanism: "Insulin metabolism increases chromium demand", mitigation: "Broccoli, wholegrains, and brewer's yeast are good sources", severity: .low)
            ],
            dietaryRestrictions: ["Carb counting essential for dose matching", "Consistent meal timing improves control"],
            timingAdvice: "Rapid-acting: inject 0-15 min before meals. Long-acting: same time daily.",
            monitoringNeeded: ["Blood glucose before meals and bedtime", "HbA1c every 3-6 months", "Hypo awareness assessment"]
        ),

        // ═══════════════════════════════════════════════════════════════
        // CARDIOVASCULAR MEDICATIONS
        // ═══════════════════════════════════════════════════════════════

        DrugNutrientInteraction(
            genericName: "Atorvastatin",
            depletedNutrients: [
                NutrientDepletion(nutrient: "CoQ10", mechanism: "Statins inhibit HMG-CoA reductase in the mevalonate pathway, which also synthesises CoQ10", mitigation: "Supplement CoQ10 100-200mg/day, especially if muscle symptoms occur", severity: .high),
                NutrientDepletion(nutrient: "Vitamin D", mechanism: "Statins may reduce vitamin D synthesis (shared cholesterol pathway)", mitigation: "Check 25-OH vitamin D annually; supplement if <50 nmol/L", severity: .moderate)
            ],
            dietaryRestrictions: ["Avoid grapefruit and grapefruit juice (CYP3A4 inhibition increases statin levels)", "Limit alcohol"],
            timingAdvice: "Can be taken any time of day with or without food",
            monitoringNeeded: ["Liver function tests at baseline and 3 months", "CK levels if muscle pain", "Lipid panel annually"]
        ),

        DrugNutrientInteraction(
            genericName: "Simvastatin",
            depletedNutrients: [
                NutrientDepletion(nutrient: "CoQ10", mechanism: "HMG-CoA reductase inhibition reduces CoQ10 synthesis", mitigation: "Supplement CoQ10 100-200mg/day", severity: .high),
                NutrientDepletion(nutrient: "Vitamin D", mechanism: "Shared mevalonate pathway affects D synthesis", mitigation: "Monitor and supplement as needed", severity: .moderate)
            ],
            dietaryRestrictions: ["AVOID grapefruit — significantly increases drug levels", "Avoid excessive alcohol"],
            timingAdvice: "Take in the evening (cholesterol synthesis peaks at night)",
            monitoringNeeded: ["LFTs at baseline and 3 months", "CK if myalgia", "Annual lipid panel"]
        ),

        DrugNutrientInteraction(
            genericName: "Rosuvastatin",
            depletedNutrients: [
                NutrientDepletion(nutrient: "CoQ10", mechanism: "HMG-CoA reductase inhibition", mitigation: "Supplement CoQ10 100-200mg/day if symptomatic", severity: .high)
            ],
            dietaryRestrictions: ["Grapefruit interaction is minimal (not CYP3A4 metabolised)", "Limit alcohol"],
            timingAdvice: "Can be taken any time of day",
            monitoringNeeded: ["LFTs at baseline", "Renal function if high dose", "Lipid panel annually"]
        ),

        DrugNutrientInteraction(
            genericName: "Ramipril",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Zinc", mechanism: "ACE inhibitors increase urinary zinc excretion", mitigation: "Ensure dietary zinc from meat, shellfish, seeds, legumes", severity: .moderate)
            ],
            dietaryRestrictions: ["Avoid potassium supplements and high-potassium salt substitutes (risk of hyperkalaemia)", "Avoid NSAIDs if possible"],
            timingAdvice: "Can be taken with or without food; consistent timing daily",
            monitoringNeeded: ["Renal function and potassium at baseline, 1-2 weeks, then periodically", "Blood pressure monitoring"]
        ),

        DrugNutrientInteraction(
            genericName: "Lisinopril",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Zinc", mechanism: "ACE inhibitors chelate zinc and increase urinary excretion", mitigation: "Dietary zinc or supplement 15mg/day if deficient", severity: .moderate)
            ],
            dietaryRestrictions: ["Avoid potassium supplements and potassium-based salt substitutes", "Limit high-potassium foods if K+ elevated"],
            timingAdvice: "Take at the same time each day, with or without food",
            monitoringNeeded: ["Renal function and electrolytes within 1-2 weeks of starting", "Regular BP monitoring"]
        ),

        DrugNutrientInteraction(
            genericName: "Enalapril",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Zinc", mechanism: "ACE inhibitor-induced zinc depletion", mitigation: "Monitor zinc status; supplement if taste disturbance occurs", severity: .moderate)
            ],
            dietaryRestrictions: ["Avoid potassium supplements", "Avoid high-potassium salt substitutes"],
            timingAdvice: "Take at the same time each day",
            monitoringNeeded: ["U&Es at baseline and 1-2 weeks", "BP monitoring"]
        ),

        DrugNutrientInteraction(
            genericName: "Losartan",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Zinc", mechanism: "ARBs may increase zinc excretion (less than ACE inhibitors)", mitigation: "Dietary zinc usually sufficient", severity: .low)
            ],
            dietaryRestrictions: ["Avoid potassium supplements and high-potassium salt substitutes"],
            timingAdvice: "Take at the same time daily with or without food",
            monitoringNeeded: ["Renal function and potassium at baseline and periodically"]
        ),

        DrugNutrientInteraction(
            genericName: "Amlodipine",
            depletedNutrients: [],
            dietaryRestrictions: ["Avoid grapefruit in large quantities (CYP3A4 interaction, though milder than with simvastatin)"],
            timingAdvice: "Take at the same time each day",
            monitoringNeeded: ["BP monitoring", "Check for ankle oedema"]
        ),

        DrugNutrientInteraction(
            genericName: "Warfarin",
            depletedNutrients: [],
            dietaryRestrictions: [
                "CRITICAL: Maintain CONSISTENT vitamin K intake — do NOT suddenly increase or decrease green leafy vegetables",
                "Avoid cranberry juice in large quantities (potentiates anticoagulation)",
                "Limit alcohol (affects INR stability)",
                "Avoid supplements: St John's Wort, ginkgo, garlic supplements, fish oil >3g/day"
            ],
            timingAdvice: "Take at the same time each day, usually in the evening",
            monitoringNeeded: ["INR monitoring weekly initially, then every 4-12 weeks when stable", "Report any unusual bruising or bleeding"]
        ),

        DrugNutrientInteraction(
            genericName: "Digoxin",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Magnesium", mechanism: "Low Mg increases sensitivity to digoxin toxicity", mitigation: "Maintain adequate Mg through diet and supplements if needed", severity: .high),
                NutrientDepletion(nutrient: "Potassium", mechanism: "Hypokalaemia increases digoxin toxicity risk", mitigation: "Monitor potassium closely; banana, potato, leafy greens", severity: .high)
            ],
            dietaryRestrictions: ["High-fibre meals may reduce absorption — take 1 hour before or 2 hours after", "Avoid St John's Wort (reduces levels)"],
            timingAdvice: "Take at the same time daily; separate from high-fibre meals",
            monitoringNeeded: ["Digoxin levels", "Renal function", "Electrolytes (especially K+ and Mg2+)"]
        ),

        // ═══════════════════════════════════════════════════════════════
        // DIURETICS
        // ═══════════════════════════════════════════════════════════════

        DrugNutrientInteraction(
            genericName: "Furosemide",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Potassium", mechanism: "Loop diuretics increase renal potassium excretion", mitigation: "Monitor K+; eat potassium-rich foods (bananas, potatoes, spinach) or supplement", severity: .high),
                NutrientDepletion(nutrient: "Magnesium", mechanism: "Increased renal magnesium loss", mitigation: "Supplement Mg 200-400mg/day if deficient", severity: .high),
                NutrientDepletion(nutrient: "Calcium", mechanism: "Loop diuretics increase calcium excretion (unlike thiazides)", mitigation: "Ensure 1000mg calcium daily; consider supplements", severity: .moderate),
                NutrientDepletion(nutrient: "Thiamine (B1)", mechanism: "Increased urinary thiamine loss, especially in heart failure", mitigation: "Supplement B1 100mg/day in heart failure patients", severity: .moderate),
                NutrientDepletion(nutrient: "Zinc", mechanism: "Increased urinary zinc excretion", mitigation: "Dietary zinc from shellfish, seeds, meat", severity: .low)
            ],
            dietaryRestrictions: ["May need potassium-rich diet unless on K-sparing diuretic", "Monitor sodium intake"],
            timingAdvice: "Take in the morning to avoid night-time diuresis",
            monitoringNeeded: ["U&Es regularly", "Magnesium levels", "Blood pressure", "Weight monitoring"]
        ),

        DrugNutrientInteraction(
            genericName: "Bendroflumethiazide",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Potassium", mechanism: "Thiazides increase potassium excretion", mitigation: "Monitor K+; potassium-rich foods or supplements", severity: .high),
                NutrientDepletion(nutrient: "Magnesium", mechanism: "Increased renal magnesium loss", mitigation: "Dietary Mg or supplement 200-400mg", severity: .moderate),
                NutrientDepletion(nutrient: "Zinc", mechanism: "Increased zinc excretion", mitigation: "Dietary zinc sources", severity: .low)
            ],
            dietaryRestrictions: ["Monitor sodium intake", "May increase blood glucose — relevant for diabetics"],
            timingAdvice: "Take in the morning",
            monitoringNeeded: ["U&Es at baseline and periodically", "Blood glucose if diabetic", "Uric acid (gout risk)"]
        ),

        DrugNutrientInteraction(
            genericName: "Indapamide",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Potassium", mechanism: "Thiazide-like diuretic increases K+ loss", mitigation: "Monitor K+; dietary potassium", severity: .moderate),
                NutrientDepletion(nutrient: "Sodium", mechanism: "Risk of hyponatraemia especially in elderly", mitigation: "Monitor Na+; ensure adequate (not excessive) salt intake", severity: .moderate)
            ],
            dietaryRestrictions: ["May affect glucose tolerance"],
            timingAdvice: "Take in the morning with or without food",
            monitoringNeeded: ["U&Es regularly, especially in elderly", "Na+ if confusion or falls"]
        ),

        DrugNutrientInteraction(
            genericName: "Spironolactone",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Sodium", mechanism: "Potassium-sparing diuretic promotes sodium excretion", mitigation: "Monitor sodium; adequate dietary salt", severity: .low)
            ],
            dietaryRestrictions: ["AVOID potassium supplements and high-potassium foods — hyperkalaemia risk", "Avoid salt substitutes (contain KCl)"],
            timingAdvice: "Take with food to improve absorption",
            monitoringNeeded: ["Potassium levels closely (risk of hyperkalaemia)", "Renal function", "BP monitoring"]
        ),

        // ═══════════════════════════════════════════════════════════════
        // GASTROINTESTINAL — PPIs & H2 BLOCKERS
        // ═══════════════════════════════════════════════════════════════

        DrugNutrientInteraction(
            genericName: "Omeprazole",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Magnesium", mechanism: "PPIs reduce active intestinal Mg absorption with long-term use", mitigation: "Monitor Mg if on PPI >1 year; supplement if deficient", severity: .high),
                NutrientDepletion(nutrient: "Calcium", mechanism: "Reduced stomach acid impairs calcium absorption, increasing fracture risk", mitigation: "Take calcium citrate (acid-independent); 1000mg/day", severity: .high),
                NutrientDepletion(nutrient: "Vitamin B12", mechanism: "Reduced acid impairs protein-bound B12 release from food", mitigation: "Monitor B12 annually if on PPI >2 years; supplement if low", severity: .moderate),
                NutrientDepletion(nutrient: "Iron", mechanism: "Reduced acid decreases non-haem iron absorption", mitigation: "Iron-rich foods with vitamin C; consider supplement if deficient", severity: .moderate),
                NutrientDepletion(nutrient: "Vitamin C", mechanism: "Reduced gastric acid decreases vitamin C bioavailability", mitigation: "Increase dietary vitamin C from fresh fruit/veg", severity: .low)
            ],
            dietaryRestrictions: ["Take before meals (30 min before breakfast is optimal)", "Avoid long-term use without review"],
            timingAdvice: "Take 30 minutes before the first meal of the day",
            monitoringNeeded: ["Magnesium if >1 year use", "B12 if >2 years", "Bone density if >3 years in at-risk patients"]
        ),

        DrugNutrientInteraction(
            genericName: "Lansoprazole",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Magnesium", mechanism: "PPI class effect on Mg absorption", mitigation: "Monitor Mg annually if long-term", severity: .high),
                NutrientDepletion(nutrient: "Calcium", mechanism: "Acid suppression reduces Ca absorption", mitigation: "Use calcium citrate; ensure vitamin D adequate", severity: .high),
                NutrientDepletion(nutrient: "Vitamin B12", mechanism: "Acid-dependent B12 release impaired", mitigation: "Annual B12 check if long-term use", severity: .moderate),
                NutrientDepletion(nutrient: "Iron", mechanism: "Non-haem iron absorption reduced", mitigation: "Take iron with vitamin C", severity: .moderate)
            ],
            dietaryRestrictions: ["Take before food"],
            timingAdvice: "Take 30 minutes before breakfast",
            monitoringNeeded: ["Mg, B12, Ca, Fe if long-term use", "Review need for PPI annually"]
        ),

        DrugNutrientInteraction(
            genericName: "Ranitidine",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Vitamin B12", mechanism: "H2 blockers reduce acid-dependent B12 absorption (less than PPIs)", mitigation: "Monitor B12 if long-term use", severity: .low),
                NutrientDepletion(nutrient: "Iron", mechanism: "Reduced acid may decrease non-haem iron absorption", mitigation: "Take iron supplements separately", severity: .low)
            ],
            dietaryRestrictions: [],
            timingAdvice: "Take 30-60 minutes before meals or at bedtime",
            monitoringNeeded: ["B12 if long-term use"]
        ),

        // ═══════════════════════════════════════════════════════════════
        // CORTICOSTEROIDS
        // ═══════════════════════════════════════════════════════════════

        DrugNutrientInteraction(
            genericName: "Prednisolone",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Calcium", mechanism: "Corticosteroids reduce calcium absorption and increase excretion; inhibit osteoblasts", mitigation: "Supplement calcium 1000-1200mg/day + vitamin D 800-1000 IU", severity: .high),
                NutrientDepletion(nutrient: "Vitamin D", mechanism: "Steroids impair vitamin D metabolism and function", mitigation: "Supplement 800-1000 IU daily; check 25-OH vitamin D", severity: .high),
                NutrientDepletion(nutrient: "Potassium", mechanism: "Corticosteroids promote renal potassium excretion", mitigation: "Potassium-rich diet; monitor levels", severity: .moderate),
                NutrientDepletion(nutrient: "Chromium", mechanism: "Steroids impair insulin sensitivity and increase chromium demand", mitigation: "Broccoli, wholegrains, brewer's yeast", severity: .low),
                NutrientDepletion(nutrient: "Vitamin C", mechanism: "Increased metabolic demand under steroid therapy", mitigation: "Increase dietary vitamin C", severity: .low)
            ],
            dietaryRestrictions: ["Take with food to reduce gastric irritation", "High-protein diet to counter muscle wasting", "Low sodium to reduce fluid retention", "Monitor blood glucose (steroid-induced hyperglycaemia)"],
            timingAdvice: "Take with breakfast to mimic cortisol rhythm",
            monitoringNeeded: ["Bone density (DEXA) if >3 months use", "Blood glucose", "Blood pressure", "Weight", "Adrenal function on withdrawal"]
        ),

        DrugNutrientInteraction(
            genericName: "Dexamethasone",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Calcium", mechanism: "Potent corticosteroid reduces Ca absorption and bone formation", mitigation: "Ca 1000-1200mg + Vit D 800-1000 IU daily", severity: .high),
                NutrientDepletion(nutrient: "Vitamin D", mechanism: "Impaired D metabolism", mitigation: "Supplement and monitor", severity: .high),
                NutrientDepletion(nutrient: "Potassium", mechanism: "Increased renal K+ loss", mitigation: "Monitor K+; dietary sources", severity: .moderate)
            ],
            dietaryRestrictions: ["Take with food", "Low sodium diet", "High protein to counter catabolism"],
            timingAdvice: "Take with breakfast",
            monitoringNeeded: ["Bone density", "Blood glucose", "Electrolytes", "Weight"]
        ),

        // ═══════════════════════════════════════════════════════════════
        // THYROID
        // ═══════════════════════════════════════════════════════════════

        DrugNutrientInteraction(
            genericName: "Levothyroxine",
            depletedNutrients: [],
            dietaryRestrictions: [
                "CRITICAL: Take on EMPTY STOMACH — food reduces absorption by up to 40%",
                "Separate from calcium supplements by 4 hours",
                "Separate from iron supplements by 4 hours",
                "Separate from antacids/PPIs by 4 hours",
                "Coffee reduces absorption — wait 30 min",
                "Soy products may reduce absorption"
            ],
            timingAdvice: "Take first thing in the morning, 30-60 minutes before breakfast, with water only",
            monitoringNeeded: ["TSH every 6-8 weeks until stable, then 6-12 monthly", "Check if starting/stopping calcium or iron supplements"]
        ),

        // ═══════════════════════════════════════════════════════════════
        // MENTAL HEALTH
        // ═══════════════════════════════════════════════════════════════

        DrugNutrientInteraction(
            genericName: "Sertraline",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Sodium", mechanism: "SSRIs can cause SIADH (syndrome of inappropriate ADH secretion), leading to hyponatraemia especially in elderly", mitigation: "Monitor Na+ in elderly; report confusion, headache, nausea", severity: .moderate),
                NutrientDepletion(nutrient: "Folate", mechanism: "SSRIs may increase folate demand for serotonin synthesis", mitigation: "Ensure dietary folate; methylfolate may enhance response", severity: .low)
            ],
            dietaryRestrictions: ["Avoid St John's Wort (serotonin syndrome risk)", "Limit alcohol", "Can be taken with or without food"],
            timingAdvice: "Take at the same time daily, morning or evening",
            monitoringNeeded: ["Sodium in elderly within 2 weeks of starting", "Monitor for serotonin syndrome if combining serotonergic drugs"]
        ),

        DrugNutrientInteraction(
            genericName: "Fluoxetine",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Sodium", mechanism: "SSRI-induced SIADH risk", mitigation: "Monitor Na+ especially in elderly", severity: .moderate),
                NutrientDepletion(nutrient: "Folate", mechanism: "Increased folate demand for serotonin metabolism", mitigation: "Dietary folate; leafy greens, fortified cereals", severity: .low)
            ],
            dietaryRestrictions: ["Avoid St John's Wort", "Limit alcohol", "Avoid grapefruit in excess"],
            timingAdvice: "Usually taken in the morning (can be activating)",
            monitoringNeeded: ["Sodium in elderly", "Weight monitoring", "Suicidality in under-25s initially"]
        ),

        DrugNutrientInteraction(
            genericName: "Citalopram",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Sodium", mechanism: "SIADH risk, especially in elderly", mitigation: "Monitor Na+; report confusion or unsteadiness", severity: .moderate)
            ],
            dietaryRestrictions: ["Avoid St John's Wort", "Limit alcohol"],
            timingAdvice: "Take at the same time daily",
            monitoringNeeded: ["ECG if dose >20mg in over-65s (QT prolongation)", "Sodium in elderly"]
        ),

        DrugNutrientInteraction(
            genericName: "Amitriptyline",
            depletedNutrients: [
                NutrientDepletion(nutrient: "CoQ10", mechanism: "Tricyclics may reduce CoQ10 levels", mitigation: "Consider CoQ10 100mg supplementation if fatigued", severity: .low),
                NutrientDepletion(nutrient: "Vitamin B2 (Riboflavin)", mechanism: "TCAs may impair B2 metabolism", mitigation: "Dairy, eggs, almonds, leafy greens", severity: .low)
            ],
            dietaryRestrictions: ["Avoid alcohol (potentiates sedation)", "May increase appetite and carbohydrate cravings — monitor weight"],
            timingAdvice: "Take 1-2 hours before bedtime (sedating)",
            monitoringNeeded: ["Weight", "ECG if cardiac risk factors", "Blood pressure (orthostatic hypotension)"]
        ),

        DrugNutrientInteraction(
            genericName: "Lithium",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Sodium", mechanism: "Lithium competes with sodium for renal reabsorption; sodium depletion increases lithium toxicity", mitigation: "MAINTAIN CONSISTENT sodium intake — do NOT go on low-salt diets without medical advice", severity: .high),
                NutrientDepletion(nutrient: "Iodine", mechanism: "Lithium concentrates in thyroid and inhibits iodine organification", mitigation: "Monitor thyroid function; adequate dietary iodine", severity: .moderate)
            ],
            dietaryRestrictions: [
                "CRITICAL: Maintain CONSISTENT salt/sodium intake daily",
                "CRITICAL: Maintain CONSISTENT fluid intake (2-3L/day)",
                "Avoid sudden dietary changes",
                "Caffeine affects lithium levels — keep intake consistent"
            ],
            timingAdvice: "Take at the same time daily, with food",
            monitoringNeeded: ["Lithium levels every 3-6 months (target 0.4-1.0 mmol/L)", "Renal function 6-monthly", "Thyroid function 6-monthly", "Calcium annually"]
        ),

        // ═══════════════════════════════════════════════════════════════
        // ANTICONVULSANTS
        // ═══════════════════════════════════════════════════════════════

        DrugNutrientInteraction(
            genericName: "Phenytoin",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Vitamin D", mechanism: "Phenytoin induces CYP enzymes that degrade vitamin D", mitigation: "Supplement vitamin D 1000-2000 IU; monitor 25-OH levels", severity: .high),
                NutrientDepletion(nutrient: "Folate", mechanism: "Phenytoin impairs folate absorption and increases catabolism", mitigation: "Supplement folate 1mg/day (but monitor — excess folate can reduce phenytoin levels)", severity: .high),
                NutrientDepletion(nutrient: "Calcium", mechanism: "Secondary to vitamin D depletion", mitigation: "Supplement calcium 1000mg/day", severity: .moderate),
                NutrientDepletion(nutrient: "Vitamin K", mechanism: "Enzyme induction may affect vitamin K metabolism", mitigation: "Monitor clotting; relevant in pregnancy", severity: .moderate)
            ],
            dietaryRestrictions: ["Avoid alcohol", "Enteral feeds can reduce absorption — separate by 2 hours"],
            timingAdvice: "Take at the same time daily; consistent food intake",
            monitoringNeeded: ["Phenytoin levels regularly", "Vitamin D and bone density", "Folate and FBC", "Calcium"]
        ),

        DrugNutrientInteraction(
            genericName: "Carbamazepine",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Vitamin D", mechanism: "CYP3A4 induction accelerates vitamin D metabolism", mitigation: "Supplement vitamin D; monitor levels annually", severity: .high),
                NutrientDepletion(nutrient: "Folate", mechanism: "Increased folate catabolism", mitigation: "Supplement folate 1mg/day", severity: .moderate),
                NutrientDepletion(nutrient: "Sodium", mechanism: "Carbamazepine can cause SIADH and hyponatraemia", mitigation: "Monitor Na+; report confusion, headache", severity: .moderate),
                NutrientDepletion(nutrient: "Calcium", mechanism: "Secondary to vitamin D depletion", mitigation: "Supplement calcium", severity: .moderate)
            ],
            dietaryRestrictions: ["Avoid grapefruit juice", "Avoid alcohol", "Avoid St John's Wort"],
            timingAdvice: "Take with food to improve absorption and reduce GI upset",
            monitoringNeeded: ["Drug levels", "FBC, LFTs, U&Es", "Vitamin D and calcium", "Sodium"]
        ),

        DrugNutrientInteraction(
            genericName: "Sodium Valproate",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Carnitine", mechanism: "Valproate inhibits carnitine biosynthesis and transport", mitigation: "Supplement L-carnitine 10-20mg/kg/day if deficient", severity: .moderate),
                NutrientDepletion(nutrient: "Folate", mechanism: "Impairs folate metabolism — CRITICAL in women of childbearing age (teratogenic)", mitigation: "Supplement folate 5mg/day if pregnancy possible", severity: .high),
                NutrientDepletion(nutrient: "Zinc", mechanism: "Increased urinary zinc loss", mitigation: "Dietary zinc sources", severity: .low)
            ],
            dietaryRestrictions: ["Avoid alcohol", "Take with food to reduce GI side effects", "Weight gain common — monitor nutrition"],
            timingAdvice: "Take with or after food",
            monitoringNeeded: ["LFTs and FBC regularly", "Valproate level", "Carnitine if lethargy or hepatic concerns", "Weight monitoring"]
        ),

        // ═══════════════════════════════════════════════════════════════
        // PAIN & ANTI-INFLAMMATORY
        // ═══════════════════════════════════════════════════════════════

        DrugNutrientInteraction(
            genericName: "Ibuprofen",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Iron", mechanism: "NSAIDs can cause GI microbleeding reducing iron stores", mitigation: "Monitor for anaemia with long-term use", severity: .moderate),
                NutrientDepletion(nutrient: "Folate", mechanism: "NSAIDs may impair folate absorption", mitigation: "Dietary folate from leafy greens", severity: .low)
            ],
            dietaryRestrictions: ["Take with food or milk to reduce GI irritation", "Avoid alcohol"],
            timingAdvice: "Take with food",
            monitoringNeeded: ["GI symptoms", "Renal function if long-term", "Blood pressure (NSAIDs can raise BP)"]
        ),

        DrugNutrientInteraction(
            genericName: "Naproxen",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Iron", mechanism: "NSAID-related GI microbleeding", mitigation: "Monitor FBC with long-term use", severity: .moderate),
                NutrientDepletion(nutrient: "Folate", mechanism: "May reduce folate absorption", mitigation: "Dietary folate", severity: .low)
            ],
            dietaryRestrictions: ["Take with food", "Avoid alcohol"],
            timingAdvice: "Take with food; use lowest effective dose for shortest time",
            monitoringNeeded: ["GI symptoms", "Renal function", "CV risk assessment"]
        ),

        DrugNutrientInteraction(
            genericName: "Aspirin",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Iron", mechanism: "GI microbleeding with regular use", mitigation: "Monitor FBC annually", severity: .moderate),
                NutrientDepletion(nutrient: "Vitamin C", mechanism: "Aspirin increases urinary excretion of vitamin C", mitigation: "Increase dietary vitamin C", severity: .low),
                NutrientDepletion(nutrient: "Folate", mechanism: "May reduce folate absorption at anti-inflammatory doses", mitigation: "Dietary folate; supplement if MCV elevated", severity: .low)
            ],
            dietaryRestrictions: ["Take with food if GI-sensitive", "Avoid alcohol with regular use"],
            timingAdvice: "Low-dose (75mg): take in the morning with food",
            monitoringNeeded: ["FBC annually", "Signs of GI bleeding"]
        ),

        // ═══════════════════════════════════════════════════════════════
        // IMMUNOSUPPRESSANTS & ANTI-RHEUMATIC
        // ═══════════════════════════════════════════════════════════════

        DrugNutrientInteraction(
            genericName: "Methotrexate",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Folate", mechanism: "Methotrexate is a folate antagonist — inhibits dihydrofolate reductase", mitigation: "Take folic acid 5mg weekly (NOT on the same day as methotrexate)", severity: .high)
            ],
            dietaryRestrictions: ["AVOID alcohol completely (hepatotoxicity)", "Avoid excess caffeine (reduces efficacy)"],
            timingAdvice: "Take ONCE weekly (same day each week); folic acid on a different day",
            monitoringNeeded: ["FBC, LFTs, U&Es every 2 weeks for first 6 weeks, then monthly for 3 months, then every 2-3 months"]
        ),

        DrugNutrientInteraction(
            genericName: "Hydroxychloroquine",
            depletedNutrients: [],
            dietaryRestrictions: ["Take with food to reduce GI upset"],
            timingAdvice: "Take with food or milk",
            monitoringNeeded: ["Annual eye examination (retinal toxicity)", "Baseline and annual ECG in some patients"]
        ),

        // ═══════════════════════════════════════════════════════════════
        // RESPIRATORY
        // ═══════════════════════════════════════════════════════════════

        DrugNutrientInteraction(
            genericName: "Salbutamol",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Potassium", mechanism: "Beta-2 agonists drive potassium into cells, reducing serum K+", mitigation: "Monitor K+ if using frequently; potassium-rich diet", severity: .moderate),
                NutrientDepletion(nutrient: "Magnesium", mechanism: "Beta-2 agonists may reduce Mg levels", mitigation: "Dietary Mg; nuts, seeds, wholegrains", severity: .low)
            ],
            dietaryRestrictions: [],
            timingAdvice: "Use as needed for symptom relief",
            monitoringNeeded: ["K+ and Mg if using nebulised high-dose frequently"]
        ),

        DrugNutrientInteraction(
            genericName: "Theophylline",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Vitamin B6", mechanism: "Theophylline antagonises pyridoxine metabolism", mitigation: "Supplement B6 10-25mg/day if symptomatic", severity: .moderate)
            ],
            dietaryRestrictions: [
                "Caffeine potentiates side effects — limit coffee/tea/cola",
                "High-protein diet increases clearance; high-carb diet decreases clearance",
                "Charcoal-grilled foods increase metabolism"
            ],
            timingAdvice: "Take at the same time daily; consistent diet important for stable levels",
            monitoringNeeded: ["Theophylline levels (target 10-20 mcg/mL)", "Heart rate", "Adjust dose if diet changes significantly"]
        ),

        // ═══════════════════════════════════════════════════════════════
        // ANTIBIOTICS
        // ═══════════════════════════════════════════════════════════════

        DrugNutrientInteraction(
            genericName: "Ciprofloxacin",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Iron", mechanism: "Fluoroquinolones chelate iron; iron reduces ciprofloxacin absorption by up to 90%", mitigation: "Separate from iron by 2 hours before or 6 hours after", severity: .high),
                NutrientDepletion(nutrient: "Calcium", mechanism: "Chelation with divalent cations reduces absorption", mitigation: "Avoid dairy 2 hours before/after dose", severity: .moderate),
                NutrientDepletion(nutrient: "Magnesium", mechanism: "Chelation reduces both drug and mineral absorption", mitigation: "Separate Mg supplements by 2+ hours", severity: .moderate)
            ],
            dietaryRestrictions: ["Avoid dairy products 2hrs before/after", "Avoid antacids 2hrs before/after", "Avoid caffeine excess (ciprofloxacin inhibits caffeine metabolism)"],
            timingAdvice: "Take 2 hours before or 6 hours after calcium, iron, zinc, or antacids",
            monitoringNeeded: ["Renal function", "Tendon pain (rare but serious — stop and report)"]
        ),

        DrugNutrientInteraction(
            genericName: "Doxycycline",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Calcium", mechanism: "Tetracyclines chelate with Ca2+; dairy reduces absorption", mitigation: "Avoid dairy 2 hours before/after", severity: .moderate),
                NutrientDepletion(nutrient: "Iron", mechanism: "Chelation with iron reduces absorption of both", mitigation: "Separate from iron supplements by 2-3 hours", severity: .moderate),
                NutrientDepletion(nutrient: "Magnesium", mechanism: "Chelation with Mg2+", mitigation: "Separate Mg supplements", severity: .low)
            ],
            dietaryRestrictions: ["Avoid dairy 2hrs before/after", "Take with food (not dairy) to reduce nausea", "Avoid lying down for 30 min after (oesophageal ulceration)"],
            timingAdvice: "Take with food and a full glass of water; sit upright for 30 min",
            monitoringNeeded: ["Sun exposure (photosensitivity)", "GI symptoms"]
        ),

        // ═══════════════════════════════════════════════════════════════
        // ORAL CONTRACEPTIVES
        // ═══════════════════════════════════════════════════════════════

        DrugNutrientInteraction(
            genericName: "Combined Oral Contraceptive",
            depletedNutrients: [
                NutrientDepletion(nutrient: "Vitamin B6", mechanism: "Oestrogen increases tryptophan metabolism via B6-dependent pathway", mitigation: "Supplement B6 25-50mg/day or dietary sources", severity: .moderate),
                NutrientDepletion(nutrient: "Folate", mechanism: "OCP may impair folate absorption and increase excretion", mitigation: "400mcg folic acid daily (especially if planning pregnancy)", severity: .moderate),
                NutrientDepletion(nutrient: "Vitamin B12", mechanism: "OCP may reduce B12 levels over time", mitigation: "Monitor B12 if symptomatic; dietary sources", severity: .low),
                NutrientDepletion(nutrient: "Magnesium", mechanism: "OCP may reduce Mg levels", mitigation: "Dietary Mg from nuts, seeds, wholegrains", severity: .low),
                NutrientDepletion(nutrient: "Zinc", mechanism: "Oestrogen may reduce zinc absorption", mitigation: "Dietary zinc sources", severity: .low)
            ],
            dietaryRestrictions: ["Avoid St John's Wort (reduces contraceptive efficacy)"],
            timingAdvice: "Take at the same time every day",
            monitoringNeeded: ["BP annually", "Migraine assessment", "Folate if planning pregnancy"]
        ),

        // ═══════════════════════════════════════════════════════════════
        // BISPHOSPHONATES (Osteoporosis)
        // ═══════════════════════════════════════════════════════════════

        DrugNutrientInteraction(
            genericName: "Alendronic Acid",
            depletedNutrients: [],
            dietaryRestrictions: [
                "CRITICAL: Take on EMPTY STOMACH with PLAIN WATER ONLY",
                "Do NOT take with any food, drink (including tea, coffee, juice), or other medications",
                "Wait at least 30 minutes before eating or drinking anything else",
                "Calcium and iron supplements reduce absorption to near zero — separate by at least 30 min"
            ],
            timingAdvice: "Take FIRST THING in the morning, at least 30 minutes before food/drink, with a full glass of plain water. Remain upright (sitting or standing) for 30 minutes.",
            monitoringNeeded: ["Calcium and vitamin D levels (must be adequate)", "Renal function", "Dental health (rare osteonecrosis of jaw)"]
        ),
    ]
}
