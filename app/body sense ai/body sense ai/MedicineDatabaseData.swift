//
//  MedicineDatabaseData.swift
//  body sense ai
//
//  Static medicine database with 250+ entries across all 20 categories.
//

import Foundation

extension MedicineDatabase {
    static func buildDatabase() -> [MedicineItem] {
        var db: [MedicineItem] = []

        func add(_ generic: String, brands: [String], cat: MedicineCategory, therapeutic: String,
                 active: String, forms: [MedicineForm], dosages: [String], defDose: String, defUnit: String,
                 freq: MedFrequency, warnings: [String] = [], sides: [String] = [], interactions: [String] = [],
                 foodInt: [String] = [], desc: String, otc: Bool) {
            db.append(MedicineItem(genericName: generic, brandNames: brands, category: cat,
                                   therapeuticClass: therapeutic, activeIngredient: active, forms: forms,
                                   typicalDosages: dosages, defaultDosage: defDose, defaultUnit: defUnit,
                                   commonFrequency: freq, warnings: warnings, sideEffects: sides,
                                   interactions: interactions, foodInteractions: foodInt, description: desc, isOTC: otc))
        }

        // ============================================================
        // MARK: - Pain Relief (20)
        // ============================================================

        add("Paracetamol", brands: ["Tylenol", "Panadol", "Calpol", "Crocin", "Dolo", "Calpol-T", "Pacimol"], cat: .painRelief,
            therapeutic: "Analgesic / Antipyretic", active: "Paracetamol (Acetaminophen)",
            forms: [.tablet, .liquid, .suppository], dosages: ["250mg", "500mg", "650mg", "1000mg"],
            defDose: "500", defUnit: "mg", freq: .thrice,
            warnings: ["Do not exceed 4g per day", "Avoid with liver disease", "Check combination products for hidden paracetamol"],
            sides: ["Nausea", "Rash", "Liver damage at high doses", "Allergic reaction"],
            interactions: ["Warfarin — increased bleeding risk", "Carbamazepine — increased hepatotoxicity risk", "Isoniazid — increased hepatotoxicity"],
            foodInt: ["Avoid alcohol — increases liver damage risk", "Can be taken with or without food"],
            desc: "A widely used pain reliever and fever reducer suitable for mild to moderate pain.", otc: true)

        add("Ibuprofen", brands: ["Advil", "Nurofen", "Brufen", "Ibugesic", "Combiflam"], cat: .painRelief,
            therapeutic: "NSAID", active: "Ibuprofen",
            forms: [.tablet, .capsule, .liquid], dosages: ["200mg", "400mg", "600mg", "800mg"],
            defDose: "400", defUnit: "mg", freq: .thrice,
            warnings: ["Take with food to reduce stomach upset", "Avoid in third trimester of pregnancy", "Risk of cardiovascular events with long-term use"],
            sides: ["Stomach pain", "Nausea", "Dizziness", "Heartburn"],
            interactions: ["Aspirin — reduced cardioprotective effect", "Warfarin — increased bleeding risk", "Lithium — increased lithium levels"],
            foodInt: ["Take with food or milk", "Avoid alcohol"],
            desc: "A nonsteroidal anti-inflammatory drug used for pain, fever, and inflammation.", otc: true)

        add("Aspirin", brands: ["Bayer", "Disprin", "Ecotrin"], cat: .painRelief,
            therapeutic: "NSAID / Antiplatelet", active: "Acetylsalicylic Acid",
            forms: [.tablet], dosages: ["75mg", "150mg", "300mg", "500mg"],
            defDose: "500", defUnit: "mg", freq: .thrice,
            warnings: ["Not for children under 16 — risk of Reye syndrome", "Avoid if allergic to NSAIDs", "May cause stomach bleeding"],
            sides: ["Stomach irritation", "Nausea", "Bleeding", "Tinnitus at high doses"],
            interactions: ["Warfarin — greatly increased bleeding risk", "Ibuprofen — reduced antiplatelet effect", "Methotrexate — increased methotrexate toxicity"],
            foodInt: ["Take with food", "Avoid alcohol"],
            desc: "Used for pain relief, fever reduction, and at low doses to reduce the risk of heart attack and stroke.", otc: true)

        add("Naproxen", brands: ["Aleve", "Naprosyn", "Naprogesic"], cat: .painRelief,
            therapeutic: "NSAID", active: "Naproxen Sodium",
            forms: [.tablet], dosages: ["220mg", "250mg", "375mg", "500mg"],
            defDose: "250", defUnit: "mg", freq: .twice,
            warnings: ["Take with food", "Avoid in late pregnancy", "Monitor kidney function with long-term use"],
            sides: ["Heartburn", "Stomach pain", "Dizziness", "Drowsiness"],
            interactions: ["Warfarin — increased bleeding", "Lithium — elevated lithium levels", "ACE inhibitors — reduced antihypertensive effect"],
            foodInt: ["Take with food or milk", "Avoid alcohol"],
            desc: "A long-acting NSAID for pain, inflammation, and fever often used for arthritis and menstrual cramps.", otc: true)

        add("Diclofenac", brands: ["Voltaren", "Voveran", "Cataflam", "Dynapar", "Reactin"], cat: .painRelief,
            therapeutic: "NSAID", active: "Diclofenac Sodium",
            forms: [.tablet, .topical, .injection], dosages: ["25mg", "50mg", "75mg", "100mg"],
            defDose: "50", defUnit: "mg", freq: .twice,
            warnings: ["Increased cardiovascular risk", "Avoid in severe heart failure", "Monitor liver function"],
            sides: ["Abdominal pain", "Nausea", "Headache", "Elevated liver enzymes"],
            interactions: ["Warfarin — increased bleeding risk", "Methotrexate — increased toxicity", "Cyclosporine — increased nephrotoxicity"],
            foodInt: ["Take with food", "Avoid alcohol"],
            desc: "A potent NSAID used for moderate pain, arthritis, and musculoskeletal injuries.", otc: false)

        add("Tramadol", brands: ["Ultram", "Tramal", "Zydol"], cat: .painRelief,
            therapeutic: "Opioid Analgesic", active: "Tramadol Hydrochloride",
            forms: [.tablet, .capsule, .injection], dosages: ["50mg", "100mg", "150mg", "200mg"],
            defDose: "50", defUnit: "mg", freq: .thrice,
            warnings: ["Risk of dependence and addiction", "May cause seizures", "Do not combine with other CNS depressants"],
            sides: ["Nausea", "Dizziness", "Constipation", "Drowsiness"],
            interactions: ["SSRIs — risk of serotonin syndrome", "Carbamazepine — reduced tramadol effect", "MAO inhibitors — serious adverse reactions"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol"],
            desc: "A centrally acting opioid analgesic for moderate to moderately severe pain.", otc: false)

        add("Codeine", brands: ["Codeine Phosphate"], cat: .painRelief,
            therapeutic: "Opioid Analgesic", active: "Codeine Phosphate",
            forms: [.tablet, .liquid], dosages: ["15mg", "30mg", "60mg"],
            defDose: "30", defUnit: "mg", freq: .thrice,
            warnings: ["Risk of dependence", "Avoid in children under 12", "Ultra-rapid metabolizers at risk of overdose"],
            sides: ["Constipation", "Drowsiness", "Nausea", "Dizziness"],
            interactions: ["Benzodiazepines — additive CNS depression", "SSRIs — serotonin syndrome risk", "CYP2D6 inhibitors — reduced efficacy"],
            foodInt: ["Can be taken with food", "Avoid alcohol"],
            desc: "An opioid used for mild to moderate pain, often combined with paracetamol.", otc: false)

        add("Morphine", brands: ["MS Contin", "Oramorph", "Kadian"], cat: .painRelief,
            therapeutic: "Opioid Analgesic", active: "Morphine Sulfate",
            forms: [.tablet, .liquid, .injection], dosages: ["10mg", "15mg", "30mg", "60mg"],
            defDose: "10", defUnit: "mg", freq: .thrice,
            warnings: ["High abuse potential — Schedule II", "Respiratory depression risk", "Do not crush extended-release forms"],
            sides: ["Constipation", "Nausea", "Sedation", "Respiratory depression"],
            interactions: ["Benzodiazepines — fatal respiratory depression", "MAO inhibitors — severe reactions", "Rifampin — reduced morphine effect"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol — potentially fatal interaction"],
            desc: "A potent opioid analgesic reserved for severe pain not controlled by other medications.", otc: false)

        add("Celecoxib", brands: ["Celebrex"], cat: .painRelief,
            therapeutic: "COX-2 Selective NSAID", active: "Celecoxib",
            forms: [.capsule], dosages: ["100mg", "200mg", "400mg"],
            defDose: "200", defUnit: "mg", freq: .daily,
            warnings: ["Cardiovascular risk with prolonged use", "Sulfonamide allergy cross-reactivity", "Monitor blood pressure"],
            sides: ["Abdominal pain", "Diarrhea", "Headache", "Peripheral edema"],
            interactions: ["Warfarin — increased bleeding risk", "Fluconazole — increased celecoxib levels", "Lithium — increased lithium levels"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol"],
            desc: "A selective COX-2 inhibitor for arthritis pain with lower GI side effects than traditional NSAIDs.", otc: false)

        add("Meloxicam", brands: ["Mobic", "Melox"], cat: .painRelief,
            therapeutic: "NSAID", active: "Meloxicam",
            forms: [.tablet, .liquid], dosages: ["7.5mg", "15mg"],
            defDose: "7.5", defUnit: "mg", freq: .daily,
            warnings: ["Cardiovascular thrombotic risk", "GI bleeding risk", "Renal impairment risk"],
            sides: ["Dyspepsia", "Nausea", "Dizziness", "Edema"],
            interactions: ["Warfarin — increased bleeding", "Lithium — increased levels", "ACE inhibitors — reduced effect"],
            foodInt: ["Take with food", "Avoid alcohol"],
            desc: "A once-daily NSAID commonly used for osteoarthritis and rheumatoid arthritis.", otc: false)

        add("Ketorolac", brands: ["Toradol"], cat: .painRelief,
            therapeutic: "NSAID", active: "Ketorolac Tromethamine",
            forms: [.tablet, .injection], dosages: ["10mg"],
            defDose: "10", defUnit: "mg", freq: .thrice,
            warnings: ["Limit use to 5 days maximum", "Not for minor or chronic pain", "High GI bleeding risk"],
            sides: ["Nausea", "GI pain", "Drowsiness", "Injection site pain"],
            interactions: ["Aspirin — increased bleeding", "Probenecid — increased ketorolac levels", "Pentoxifylline — increased bleeding risk"],
            foodInt: ["Take with food if oral form", "Avoid alcohol"],
            desc: "A potent short-term NSAID for moderate to severe acute pain, often used post-operatively.", otc: false)

        add("Piroxicam", brands: ["Feldene"], cat: .painRelief,
            therapeutic: "NSAID", active: "Piroxicam",
            forms: [.capsule, .topical], dosages: ["10mg", "20mg"],
            defDose: "20", defUnit: "mg", freq: .daily,
            warnings: ["Higher GI risk than other NSAIDs", "Avoid in elderly if possible", "Monitor blood counts"],
            sides: ["GI upset", "Dizziness", "Rash", "Edema"],
            interactions: ["Warfarin — increased bleeding", "Lithium — elevated levels", "Aspirin — increased GI risk"],
            foodInt: ["Take with food", "Avoid alcohol"],
            desc: "A long-acting NSAID used for chronic arthritis conditions requiring once-daily dosing.", otc: false)

        add("Mefenamic Acid", brands: ["Ponstan", "Ponstel"], cat: .painRelief,
            therapeutic: "NSAID", active: "Mefenamic Acid",
            forms: [.tablet, .capsule], dosages: ["250mg", "500mg"],
            defDose: "500", defUnit: "mg", freq: .thrice,
            warnings: ["Limit use to 7 days", "GI bleeding risk", "Not recommended in renal impairment"],
            sides: ["Diarrhea", "Nausea", "Abdominal pain", "Headache"],
            interactions: ["Warfarin — increased bleeding", "Methotrexate — increased toxicity", "Antihypertensives — reduced effect"],
            foodInt: ["Take with food", "Avoid alcohol"],
            desc: "An NSAID commonly prescribed for menstrual pain and mild to moderate pain.", otc: false)

        add("Gabapentin", brands: ["Neurontin", "Gabapin", "Gabator", "Gabantin"], cat: .painRelief,
            therapeutic: "Anticonvulsant / Neuropathic Pain Agent", active: "Gabapentin",
            forms: [.capsule, .tablet, .liquid], dosages: ["100mg", "300mg", "400mg", "600mg", "800mg"],
            defDose: "300", defUnit: "mg", freq: .thrice,
            warnings: ["May cause suicidal thoughts", "Do not stop abruptly — taper dose", "Causes drowsiness"],
            sides: ["Drowsiness", "Dizziness", "Fatigue", "Peripheral edema"],
            interactions: ["Opioids — increased CNS depression", "Antacids — reduced gabapentin absorption", "Morphine — increased gabapentin levels"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol"],
            desc: "Used for neuropathic pain and seizures, it calms overactive nerve signals.", otc: false)

        add("Pregabalin", brands: ["Lyrica", "Pregastar", "Pregalin", "Nervigesic"], cat: .painRelief,
            therapeutic: "Anticonvulsant / Neuropathic Pain Agent", active: "Pregabalin",
            forms: [.capsule], dosages: ["25mg", "50mg", "75mg", "150mg", "300mg"],
            defDose: "75", defUnit: "mg", freq: .twice,
            warnings: ["Risk of dependence", "May cause suicidal ideation", "Do not stop abruptly"],
            sides: ["Dizziness", "Somnolence", "Weight gain", "Blurred vision"],
            interactions: ["Opioids — respiratory depression", "Lorazepam — additive CNS depression", "ACE inhibitors — increased angioedema risk"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol"],
            desc: "Treats nerve pain from diabetes, shingles, fibromyalgia, and is also used for certain seizures.", otc: false)

        add("Oxycodone", brands: ["OxyContin", "Percocet", "Endone"], cat: .painRelief,
            therapeutic: "Opioid Analgesic", active: "Oxycodone Hydrochloride",
            forms: [.tablet, .capsule, .liquid], dosages: ["5mg", "10mg", "15mg", "20mg", "40mg"],
            defDose: "5", defUnit: "mg", freq: .thrice,
            warnings: ["High abuse potential — Schedule II", "Respiratory depression risk", "Do not crush extended-release tablets"],
            sides: ["Constipation", "Nausea", "Drowsiness", "Respiratory depression"],
            interactions: ["Benzodiazepines — fatal respiratory depression", "CYP3A4 inhibitors — increased oxycodone levels", "Serotonergic drugs — serotonin syndrome"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol — potentially fatal"],
            desc: "A strong opioid prescribed for moderate to severe pain when other analgesics are insufficient.", otc: false)

        add("Lidocaine Topical", brands: ["Lidoderm", "Xylocaine"], cat: .painRelief,
            therapeutic: "Local Anesthetic", active: "Lidocaine",
            forms: [.topical, .patch], dosages: ["2%", "4%", "5%"],
            defDose: "5", defUnit: "%", freq: .asNeeded,
            warnings: ["Do not apply to broken skin", "Limit application area to avoid systemic absorption", "Remove patch after 12 hours"],
            sides: ["Skin irritation", "Redness at application site", "Numbness", "Rash"],
            interactions: ["Antiarrhythmics — additive cardiac effects", "Other local anesthetics — additive toxicity", "Beta-blockers — increased lidocaine levels"],
            foodInt: ["Not applicable — topical use"],
            desc: "A topical anesthetic that numbs the skin to relieve localized pain such as post-herpetic neuralgia.", otc: true)

        add("Capsaicin", brands: ["Zostrix", "Qutenza"], cat: .painRelief,
            therapeutic: "Topical Analgesic", active: "Capsaicin",
            forms: [.topical, .patch], dosages: ["0.025%", "0.075%", "8%"],
            defDose: "0.075", defUnit: "%", freq: .thrice,
            warnings: ["Avoid contact with eyes", "Wash hands thoroughly after application", "Burning sensation is expected initially"],
            sides: ["Burning sensation", "Redness", "Skin irritation", "Cough if inhaled"],
            interactions: ["ACE inhibitors — may worsen cough", "Topical anesthetics — may reduce burning", "Anticoagulants — theoretical increased bleeding"],
            foodInt: ["Not applicable — topical use"],
            desc: "A natural pepper extract applied to the skin to relieve nerve and joint pain by depleting substance P.", otc: true)

        add("Methocarbamol", brands: ["Robaxin"], cat: .painRelief,
            therapeutic: "Muscle Relaxant", active: "Methocarbamol",
            forms: [.tablet, .injection], dosages: ["500mg", "750mg"],
            defDose: "750", defUnit: "mg", freq: .thrice,
            warnings: ["Causes drowsiness — avoid driving", "May discolor urine brown or green", "Use caution in renal impairment"],
            sides: ["Drowsiness", "Dizziness", "Nausea", "Blurred vision"],
            interactions: ["CNS depressants — additive sedation", "Pyridostigmine — reduced effect in myasthenia", "Alcohol — increased drowsiness"],
            foodInt: ["Can be taken with food", "Avoid alcohol"],
            desc: "A muscle relaxant used alongside rest and physical therapy for acute musculoskeletal pain.", otc: false)

        add("Cyclobenzaprine", brands: ["Flexeril", "Amrix"], cat: .painRelief,
            therapeutic: "Muscle Relaxant", active: "Cyclobenzaprine Hydrochloride",
            forms: [.tablet, .capsule], dosages: ["5mg", "10mg", "15mg"],
            defDose: "10", defUnit: "mg", freq: .thrice,
            warnings: ["Do not use with MAO inhibitors", "Not for long-term use beyond 2-3 weeks", "Causes significant drowsiness"],
            sides: ["Drowsiness", "Dry mouth", "Dizziness", "Fatigue"],
            interactions: ["MAO inhibitors — hypertensive crisis", "SSRIs — serotonin syndrome risk", "CNS depressants — additive sedation"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol"],
            desc: "A muscle relaxant structurally related to tricyclic antidepressants, used for short-term muscle spasm relief.", otc: false)


        // ============================================================
        // MARK: - Anti-Inflammatory (10)
        // ============================================================

        add("Prednisone", brands: ["Deltasone", "Rayos"], cat: .antiInflammatory,
            therapeutic: "Corticosteroid", active: "Prednisone",
            forms: [.tablet, .liquid], dosages: ["1mg", "5mg", "10mg", "20mg", "50mg"],
            defDose: "10", defUnit: "mg", freq: .daily,
            warnings: ["Do not stop abruptly — taper required", "Increases infection risk", "Long-term use causes bone loss"],
            sides: ["Weight gain", "Insomnia", "Mood changes", "Elevated blood sugar"],
            interactions: ["NSAIDs — increased GI bleeding risk", "Warfarin — altered anticoagulant effect", "Diabetes medications — reduced glucose control"],
            foodInt: ["Take with food to reduce stomach upset", "Avoid grapefruit juice"],
            desc: "A corticosteroid that suppresses inflammation and the immune system for many conditions.", otc: false)

        add("Prednisolone", brands: ["Prelone", "Orapred"], cat: .antiInflammatory,
            therapeutic: "Corticosteroid", active: "Prednisolone",
            forms: [.tablet, .liquid], dosages: ["5mg", "10mg", "15mg", "20mg"],
            defDose: "5", defUnit: "mg", freq: .daily,
            warnings: ["Taper gradually", "Monitor blood glucose", "Risk of adrenal suppression"],
            sides: ["Increased appetite", "Fluid retention", "Mood swings", "Insomnia"],
            interactions: ["NSAIDs — increased GI risk", "Phenytoin — reduced prednisolone effect", "Live vaccines — contraindicated"],
            foodInt: ["Take with food", "Limit sodium intake"],
            desc: "An active corticosteroid often preferred in liver disease since it does not require hepatic conversion.", otc: false)

        add("Dexamethasone", brands: ["Decadron", "Dexona"], cat: .antiInflammatory,
            therapeutic: "Corticosteroid", active: "Dexamethasone",
            forms: [.tablet, .injection, .liquid], dosages: ["0.5mg", "0.75mg", "4mg", "6mg"],
            defDose: "4", defUnit: "mg", freq: .daily,
            warnings: ["Very potent — use lowest effective dose", "Adrenal suppression with prolonged use", "Immunosuppression risk"],
            sides: ["Insomnia", "Increased appetite", "Hyperglycemia", "Mood changes"],
            interactions: ["Phenytoin — reduced dexamethasone levels", "Warfarin — altered effect", "Diabetes medications — decreased efficacy"],
            foodInt: ["Take with food", "Avoid alcohol"],
            desc: "A highly potent corticosteroid used for severe inflammation, allergic reactions, and cerebral edema.", otc: false)

        add("Methylprednisolone", brands: ["Medrol", "Depo-Medrol", "Solu-Medrol"], cat: .antiInflammatory,
            therapeutic: "Corticosteroid", active: "Methylprednisolone",
            forms: [.tablet, .injection], dosages: ["4mg", "8mg", "16mg", "32mg"],
            defDose: "4", defUnit: "mg", freq: .daily,
            warnings: ["Taper dose gradually", "Increases infection susceptibility", "GI bleeding risk"],
            sides: ["Fluid retention", "Elevated blood pressure", "Mood disturbances", "Weight gain"],
            interactions: ["Aspirin — increased GI bleeding", "Cyclosporine — mutual elevation of levels", "CYP3A4 inhibitors — increased steroid effect"],
            foodInt: ["Take with food", "Limit salt intake"],
            desc: "An intermediate-acting corticosteroid used in dose packs for acute inflammation flares.", otc: false)

        add("Hydrocortisone", brands: ["Cortef", "Solu-Cortef"], cat: .antiInflammatory,
            therapeutic: "Corticosteroid", active: "Hydrocortisone",
            forms: [.tablet, .injection, .topical], dosages: ["5mg", "10mg", "20mg"],
            defDose: "20", defUnit: "mg", freq: .twice,
            warnings: ["Do not stop suddenly", "Monitor for adrenal insufficiency", "Topical: do not use on face long-term"],
            sides: ["Weight gain", "Skin thinning (topical)", "Elevated glucose", "Fluid retention"],
            interactions: ["NSAIDs — increased GI bleeding", "Antidiabetic drugs — reduced glycemic control", "Barbiturates — reduced hydrocortisone effect"],
            foodInt: ["Take oral form with food", "Avoid alcohol"],
            desc: "A natural corticosteroid used for adrenal insufficiency and inflammatory conditions.", otc: true)

        add("Budesonide", brands: ["Entocort", "Uceris"], cat: .antiInflammatory,
            therapeutic: "Corticosteroid", active: "Budesonide",
            forms: [.capsule, .tablet], dosages: ["3mg", "9mg"],
            defDose: "9", defUnit: "mg", freq: .daily,
            warnings: ["Do not crush or chew capsules", "Taper when discontinuing", "Monitor for infections"],
            sides: ["Headache", "Nausea", "Acne", "Mood changes"],
            interactions: ["CYP3A4 inhibitors (ketoconazole) — increased budesonide levels", "Grapefruit juice — increased levels", "Antacids — do not take together"],
            foodInt: ["Avoid grapefruit juice", "Can be taken with or without food"],
            desc: "A locally acting steroid for Crohn disease and ulcerative colitis with fewer systemic side effects.", otc: false)

        add("Colchicine", brands: ["Colcrys", "Mitigare"], cat: .antiInflammatory,
            therapeutic: "Anti-gout Agent", active: "Colchicine",
            forms: [.tablet], dosages: ["0.5mg", "0.6mg"],
            defDose: "0.6", defUnit: "mg", freq: .twice,
            warnings: ["Narrow therapeutic index — do not exceed dose", "Toxic in overdose", "Reduce dose in renal or hepatic impairment"],
            sides: ["Diarrhea", "Nausea", "Abdominal pain", "Vomiting"],
            interactions: ["Clarithromycin — increased colchicine toxicity", "Statins — increased myopathy risk", "Cyclosporine — increased colchicine levels"],
            foodInt: ["Can be taken with or without food", "Avoid grapefruit juice"],
            desc: "An anti-inflammatory specifically for gout flares and familial Mediterranean fever.", otc: false)

        add("Sulfasalazine", brands: ["Azulfidine", "Salazopyrin"], cat: .antiInflammatory,
            therapeutic: "DMARD / Aminosalicylate", active: "Sulfasalazine",
            forms: [.tablet], dosages: ["500mg"],
            defDose: "500", defUnit: "mg", freq: .twice,
            warnings: ["Sulfa allergy risk", "Monitor CBC and liver enzymes", "Adequate hydration required"],
            sides: ["Nausea", "Headache", "Orange discoloration of urine", "Rash"],
            interactions: ["Digoxin — reduced digoxin absorption", "Folic acid — reduced absorption", "Methotrexate — increased hepatotoxicity"],
            foodInt: ["Take with food", "Take with full glass of water"],
            desc: "Used for rheumatoid arthritis and inflammatory bowel disease by reducing gut and joint inflammation.", otc: false)

        add("Methotrexate", brands: ["Trexall", "Otrexup", "Rasuvo"], cat: .antiInflammatory,
            therapeutic: "DMARD / Antimetabolite", active: "Methotrexate",
            forms: [.tablet, .injection], dosages: ["2.5mg", "5mg", "7.5mg", "10mg", "15mg"],
            defDose: "7.5", defUnit: "mg", freq: .weekly,
            warnings: ["Take only ONCE weekly — daily use is fatal", "Requires folic acid supplementation", "Monitor CBC, liver, and renal function regularly"],
            sides: ["Nausea", "Mouth sores", "Fatigue", "Liver toxicity"],
            interactions: ["NSAIDs — increased methotrexate toxicity", "Trimethoprim — increased bone marrow suppression", "Proton pump inhibitors — increased methotrexate levels"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol — liver toxicity"],
            desc: "A disease-modifying drug used weekly for rheumatoid arthritis, psoriasis, and certain cancers.", otc: false)

        add("Hydroxychloroquine", brands: ["Plaquenil"], cat: .antiInflammatory,
            therapeutic: "DMARD / Antimalarial", active: "Hydroxychloroquine Sulfate",
            forms: [.tablet], dosages: ["200mg", "400mg"],
            defDose: "200", defUnit: "mg", freq: .twice,
            warnings: ["Requires annual eye exams — retinal toxicity", "Avoid in G6PD deficiency", "QT prolongation risk"],
            sides: ["Nausea", "Headache", "Dizziness", "Retinal damage with long-term use"],
            interactions: ["Digoxin — increased digoxin levels", "Tamoxifen — increased retinal toxicity risk", "Metformin — increased hypoglycemia risk"],
            foodInt: ["Take with food or milk", "Avoid antacids within 4 hours"],
            desc: "An antimalarial drug widely used for lupus and rheumatoid arthritis to reduce flares.", otc: false)


        // ═══════════════════════════════════════
        // MARK: - Respiratory
        // ═══════════════════════════════════════

        add("Salbutamol", brands: ["Ventolin","ProAir","Asthalin","Airomir"], cat: .respiratory, therapeutic: "Short-acting Beta-2 Agonist", active: "Salbutamol/Albuterol Sulfate", forms: [.inhaler,.liquid,.tablet], dosages: ["100mcg","200mcg","2mg","4mg"], defDose: "100", defUnit: "mcg", freq: .asNeeded, warnings: ["Reliever only — not for prevention","Seek help if needing more than 8 puffs/day","Shake inhaler before use"], sides: ["Tremor","Palpitations","Headache","Muscle cramps"], interactions: ["Beta-blockers — may reduce bronchodilation","Digoxin — may lower digoxin levels","Diuretics — may worsen low potassium"], foodInt: ["Inhaler: no food interaction"], desc: "Quick-relief rescue inhaler for asthma and COPD attacks. Works within 5 minutes.", otc: false)

        add("Fluticasone Inhaler", brands: ["Flovent","Flixotide","Flonase"], cat: .respiratory, therapeutic: "Inhaled Corticosteroid", active: "Fluticasone Propionate", forms: [.inhaler], dosages: ["50mcg","125mcg","250mcg","500mcg"], defDose: "250", defUnit: "mcg", freq: .twice, warnings: ["Rinse mouth after use to prevent thrush","Not for acute attacks","Regular daily use needed"], sides: ["Oral thrush","Hoarse voice","Sore throat","Cough"], interactions: ["Ritonavir — increased steroid levels","Ketoconazole — increased fluticasone levels"], foodInt: ["Inhaler: no food interaction"], desc: "Preventive steroid inhaler for daily asthma and COPD control.", otc: false)

        add("Montelukast", brands: ["Singulair","Montair","Montek"], cat: .respiratory, therapeutic: "Leukotriene Receptor Antagonist", active: "Montelukast Sodium", forms: [.tablet], dosages: ["4mg","5mg","10mg"], defDose: "10", defUnit: "mg", freq: .daily, warnings: ["Take in the evening","Monitor for mood changes","Rare neuropsychiatric events reported"], sides: ["Headache","Stomach pain","Fatigue","Mood changes","Sleep disturbances"], interactions: ["Phenobarbital — reduced montelukast levels","CYP3A4 inducers — may reduce effect"], foodInt: ["Can be taken with or without food, in the evening"], desc: "Daily tablet for asthma prevention and allergic rhinitis. Add-on to inhaled steroids.", otc: false)

        add("Tiotropium", brands: ["Spiriva","Braltus"], cat: .respiratory, therapeutic: "Long-acting Anticholinergic", active: "Tiotropium Bromide", forms: [.inhaler,.capsule], dosages: ["2.5mcg","5mcg","18mcg"], defDose: "18", defUnit: "mcg", freq: .daily, warnings: ["Not for acute attacks","Avoid contact with eyes","Dry mouth is common"], sides: ["Dry mouth","Constipation","UTI","Blurred vision"], interactions: ["Other anticholinergics — additive effects","Ipratropium — avoid combining"], foodInt: ["Inhaler: no food interaction"], desc: "Once-daily long-acting inhaler for COPD maintenance. Reduces flare-ups.", otc: false)

        add("Budesonide-Formoterol", brands: ["Symbicort"], cat: .respiratory, therapeutic: "ICS/LABA Combination", active: "Budesonide + Formoterol Fumarate", forms: [.inhaler], dosages: ["80/4.5mcg","160/4.5mcg","320/9mcg"], defDose: "160/4.5", defUnit: "mcg", freq: .twice, warnings: ["Rinse mouth after use","Not a rescue inhaler","Regular daily use"], sides: ["Oral thrush","Headache","Tremor","Palpitations"], interactions: ["Beta-blockers — reduced bronchodilation","Ketoconazole — increased budesonide levels","MAO inhibitors — cardiovascular effects"], foodInt: ["Inhaler: no food interaction"], desc: "Combination preventer inhaler with steroid and long-acting bronchodilator.", otc: false)

        add("Fluticasone-Salmeterol", brands: ["Advair","Seretide"], cat: .respiratory, therapeutic: "ICS/LABA Combination", active: "Fluticasone + Salmeterol", forms: [.inhaler], dosages: ["100/50mcg","250/50mcg","500/50mcg"], defDose: "250/50", defUnit: "mcg", freq: .twice, warnings: ["Rinse mouth after use","Not a rescue inhaler","Do not exceed prescribed dose"], sides: ["Oral thrush","Hoarse voice","Headache","Tremor"], interactions: ["Ritonavir — increased steroid levels","Beta-blockers — reduced bronchodilation","Ketoconazole — increased fluticasone levels"], foodInt: ["Inhaler: no food interaction"], desc: "Combination preventer inhaler for moderate-severe asthma and COPD.", otc: false)

        add("Guaifenesin", brands: ["Mucinex","Robitussin","Benylin"], cat: .respiratory, therapeutic: "Expectorant", active: "Guaifenesin", forms: [.tablet,.liquid], dosages: ["200mg","400mg","600mg","1200mg"], defDose: "400", defUnit: "mg", freq: .twice, warnings: ["Drink plenty of water","Not for chronic cough","Check for other active ingredients in combination products"], sides: ["Nausea","Vomiting","Dizziness","Headache"], interactions: ["Few significant interactions"], foodInt: ["Take with a full glass of water"], desc: "Expectorant that thins and loosens mucus to relieve chest congestion.", otc: true)

        add("Pseudoephedrine", brands: ["Sudafed","Nexafed","Dimetapp"], cat: .respiratory, therapeutic: "Decongestant", active: "Pseudoephedrine Hydrochloride", forms: [.tablet,.liquid], dosages: ["30mg","60mg","120mg","240mg"], defDose: "60", defUnit: "mg", freq: .thrice, warnings: ["Avoid in uncontrolled hypertension","May cause insomnia — take early in day","Not for children under 6"], sides: ["Insomnia","Nervousness","Increased heart rate","Increased blood pressure"], interactions: ["MAO inhibitors — hypertensive crisis","Beta-blockers — reduced effect","Antihypertensives — counteracted effect"], foodInt: ["Can be taken with or without food"], desc: "Nasal decongestant for cold and sinus congestion. Behind-the-counter in many countries.", otc: true)

        // ═══════════════════════════════════════
        // MARK: - Gastrointestinal
        // ═══════════════════════════════════════

        add("Omeprazole", brands: ["Prilosec","Losec","Omez"], cat: .gastrointestinal, therapeutic: "Proton Pump Inhibitor", active: "Omeprazole", forms: [.capsule,.tablet], dosages: ["10mg","20mg","40mg"], defDose: "20", defUnit: "mg", freq: .daily, warnings: ["Take 30 min before meals","Long-term use may reduce magnesium/B12","Increased fracture risk with prolonged use"], sides: ["Headache","Nausea","Diarrhea","Stomach pain","B12 deficiency"], interactions: ["Clopidogrel — reduced antiplatelet effect","Methotrexate — increased toxicity","Diazepam — increased levels"], foodInt: ["Take 30 minutes before first meal of the day"], desc: "Acid blocker for heartburn, GERD, ulcers, and H. pylori treatment.", otc: true)

        add("Pantoprazole", brands: ["Protonix","Pantop","Controloc"], cat: .gastrointestinal, therapeutic: "Proton Pump Inhibitor", active: "Pantoprazole Sodium", forms: [.tablet,.injection], dosages: ["20mg","40mg"], defDose: "40", defUnit: "mg", freq: .daily, warnings: ["Take before meals","Long-term use: monitor magnesium","Does not interact with clopidogrel"], sides: ["Headache","Diarrhea","Nausea","Flatulence"], interactions: ["Methotrexate — increased levels","Warfarin — monitor INR"], foodInt: ["Take 30 minutes before a meal"], desc: "PPI for acid reflux and ulcers. Less drug interactions than omeprazole.", otc: false)

        add("Esomeprazole", brands: ["Nexium","Esomep","Emanera"], cat: .gastrointestinal, therapeutic: "Proton Pump Inhibitor", active: "Esomeprazole Magnesium", forms: [.capsule,.tablet], dosages: ["20mg","40mg"], defDose: "20", defUnit: "mg", freq: .daily, warnings: ["Take before meals","Long-term use concerns","May reduce magnesium"], sides: ["Headache","Nausea","Diarrhea","Flatulence"], interactions: ["Clopidogrel — may reduce effect","Methotrexate — increased levels","Diazepam — increased levels"], foodInt: ["Take at least 1 hour before food"], desc: "PPI for GERD, erosive esophagitis, and H. pylori eradication.", otc: true)

        add("Famotidine", brands: ["Pepcid","Famotack"], cat: .gastrointestinal, therapeutic: "H2 Receptor Antagonist", active: "Famotidine", forms: [.tablet,.liquid,.injection], dosages: ["10mg","20mg","40mg"], defDose: "20", defUnit: "mg", freq: .twice, warnings: ["Adjust dose in kidney disease","Headache common initially"], sides: ["Headache","Dizziness","Constipation","Diarrhea"], interactions: ["Ketoconazole — reduced absorption","Atazanavir — reduced absorption"], foodInt: ["Can be taken with or without food"], desc: "Acid reducer for heartburn, GERD, and stomach ulcers. Fewer interactions than PPIs.", otc: true)

        add("Ondansetron", brands: ["Zofran","Emeset","Ondanset"], cat: .gastrointestinal, therapeutic: "5-HT3 Antagonist / Antiemetic", active: "Ondansetron", forms: [.tablet,.liquid,.injection], dosages: ["4mg","8mg","16mg"], defDose: "4", defUnit: "mg", freq: .thrice, warnings: ["May prolong QT interval","Use lowest effective dose","Constipation common"], sides: ["Headache","Constipation","Fatigue","Dizziness"], interactions: ["QT-prolonging drugs — increased arrhythmia risk","Apomorphine — severe hypotension","Tramadol — reduced pain relief"], foodInt: ["Can be taken with or without food"], desc: "Anti-nausea medication for chemotherapy, surgery, and pregnancy-related nausea.", otc: false)

        add("Loperamide", brands: ["Imodium","Loperam","Diar-Aid"], cat: .gastrointestinal, therapeutic: "Antidiarrheal", active: "Loperamide Hydrochloride", forms: [.capsule,.tablet,.liquid], dosages: ["2mg"], defDose: "2", defUnit: "mg", freq: .asNeeded, warnings: ["Max 16mg/day","Not for bloody diarrhea or C. diff","Stay hydrated"], sides: ["Constipation","Abdominal cramps","Nausea","Dizziness"], interactions: ["QT-prolonging drugs — risk at high doses","Ritonavir — increased loperamide levels"], foodInt: ["Can be taken with or without food"], desc: "Controls diarrhea by slowing gut movement. Take after each loose stool.", otc: true)

        add("Lactulose", brands: ["Duphalac","Enulose","Kristalose"], cat: .gastrointestinal, therapeutic: "Osmotic Laxative", active: "Lactulose", forms: [.liquid], dosages: ["10mL","15mL","20mL","30mL"], defDose: "15", defUnit: "mL", freq: .twice, warnings: ["May cause bloating initially","Adjust dose to achieve soft stools","Safe for long-term use"], sides: ["Bloating","Gas","Stomach cramps","Diarrhea if dose too high"], interactions: ["Antacids — may reduce lactulose effect"], foodInt: ["Can be mixed with water or juice"], desc: "Gentle osmotic laxative for chronic constipation and liver-related confusion (hepatic encephalopathy).", otc: true)

        add("Bisacodyl", brands: ["Dulcolax","Correctol"], cat: .gastrointestinal, therapeutic: "Stimulant Laxative", active: "Bisacodyl", forms: [.tablet,.suppository], dosages: ["5mg","10mg"], defDose: "5", defUnit: "mg", freq: .daily, warnings: ["Not for daily long-term use","Works in 6-12 hours (oral) or 15-60 min (rectal)","Do not crush enteric-coated tablets"], sides: ["Stomach cramps","Diarrhea","Nausea"], interactions: ["Antacids — do not take within 1 hour","Milk — do not take with milk (dissolves coating)"], foodInt: ["Do not take with milk or antacids"], desc: "Fast-acting stimulant laxative for occasional constipation.", otc: true)

        add("Metoclopramide", brands: ["Reglan","Maxolon","Primperan"], cat: .gastrointestinal, therapeutic: "Prokinetic / Antiemetic", active: "Metoclopramide Hydrochloride", forms: [.tablet,.liquid,.injection], dosages: ["5mg","10mg"], defDose: "10", defUnit: "mg", freq: .thrice, warnings: ["Max 5 days use recommended","Risk of tardive dyskinesia with long-term use","Not for bowel obstruction"], sides: ["Drowsiness","Restlessness","Diarrhea","Fatigue"], interactions: ["Dopamine agonists — opposing effects","Opioids — counteracted gut slowing","SSRIs — serotonin syndrome risk"], foodInt: ["Take 30 minutes before meals"], desc: "Speeds up stomach emptying and relieves nausea. Short-term use recommended.", otc: false)

        add("Domperidone", brands: ["Motilium","Domperan"], cat: .gastrointestinal, therapeutic: "Dopamine Antagonist / Prokinetic", active: "Domperidone", forms: [.tablet,.liquid], dosages: ["10mg","20mg"], defDose: "10", defUnit: "mg", freq: .thrice, warnings: ["Take before meals","Risk of cardiac arrhythmia at high doses","Use lowest dose for shortest time"], sides: ["Dry mouth","Headache","Abdominal cramps"], interactions: ["Ketoconazole — increased domperidone levels","QT-prolonging drugs — arrhythmia risk","Opioids — opposing effects"], foodInt: ["Take 15-30 minutes before meals"], desc: "Anti-nausea and gut motility enhancer. Does not cross blood-brain barrier like metoclopramide.", otc: false)

        // ═══════════════════════════════════════
        // MARK: - Mental Health
        // ═══════════════════════════════════════

        add("Sertraline", brands: ["Zoloft","Lustral","Serlift"], cat: .mentalHealth, therapeutic: "SSRI Antidepressant", active: "Sertraline Hydrochloride", forms: [.tablet,.liquid], dosages: ["25mg","50mg","100mg","150mg","200mg"], defDose: "50", defUnit: "mg", freq: .daily, warnings: ["Takes 2-6 weeks to work fully","Do not stop abruptly — taper gradually","May increase suicidal thoughts in under 25 initially"], sides: ["Nausea","Headache","Insomnia","Diarrhea","Sexual dysfunction","Drowsiness"], interactions: ["MAO inhibitors — serotonin syndrome (contraindicated)","Tramadol — serotonin syndrome risk","Warfarin — increased bleeding"], foodInt: ["Can be taken with or without food"], desc: "Most prescribed antidepressant. For depression, anxiety, OCD, PTSD, and panic disorder.", otc: false)

        add("Fluoxetine", brands: ["Prozac","Sarafem","Fludac"], cat: .mentalHealth, therapeutic: "SSRI Antidepressant", active: "Fluoxetine Hydrochloride", forms: [.capsule,.tablet,.liquid], dosages: ["10mg","20mg","40mg","60mg"], defDose: "20", defUnit: "mg", freq: .daily, warnings: ["Long half-life — effects persist after stopping","Do not use with MAO inhibitors","May cause initial anxiety"], sides: ["Nausea","Insomnia","Anxiety","Headache","Sexual dysfunction"], interactions: ["MAO inhibitors — serotonin syndrome","Tamoxifen — reduced effectiveness","Thioridazine — contraindicated"], foodInt: ["Can be taken with or without food"], desc: "Long-acting SSRI for depression, OCD, bulimia, and panic disorder.", otc: false)

        add("Escitalopram", brands: ["Lexapro","Cipralex","Nexito"], cat: .mentalHealth, therapeutic: "SSRI Antidepressant", active: "Escitalopram Oxalate", forms: [.tablet,.liquid], dosages: ["5mg","10mg","20mg"], defDose: "10", defUnit: "mg", freq: .daily, warnings: ["Takes 2-4 weeks to work","Do not stop abruptly","May prolong QT interval at high doses"], sides: ["Nausea","Insomnia","Fatigue","Sexual dysfunction","Dry mouth"], interactions: ["MAO inhibitors — serotonin syndrome","Tramadol — serotonin risk","Omeprazole — may increase escitalopram levels"], foodInt: ["Can be taken with or without food"], desc: "Clean SSRI with fewest drug interactions. For depression and generalized anxiety.", otc: false)

        add("Venlafaxine", brands: ["Effexor","Efexor","Venlor"], cat: .mentalHealth, therapeutic: "SNRI Antidepressant", active: "Venlafaxine Hydrochloride", forms: [.capsule,.tablet], dosages: ["37.5mg","75mg","150mg","225mg"], defDose: "75", defUnit: "mg", freq: .daily, warnings: ["Taper gradually when stopping — withdrawal symptoms","Monitor blood pressure at high doses","Takes 2-4 weeks to work"], sides: ["Nausea","Headache","Insomnia","Sweating","Dry mouth","Dizziness"], interactions: ["MAO inhibitors — serotonin syndrome","Tramadol — serotonin risk","Warfarin — increased bleeding"], foodInt: ["Take with food"], desc: "Dual-action antidepressant for depression, anxiety, and neuropathic pain.", otc: false)

        add("Duloxetine", brands: ["Cymbalta","Duzela","Yentreve"], cat: .mentalHealth, therapeutic: "SNRI Antidepressant", active: "Duloxetine Hydrochloride", forms: [.capsule], dosages: ["20mg","30mg","60mg","90mg","120mg"], defDose: "60", defUnit: "mg", freq: .daily, warnings: ["Do not crush capsules","Taper gradually","Avoid in liver disease and heavy alcohol use"], sides: ["Nausea","Dry mouth","Fatigue","Constipation","Drowsiness"], interactions: ["MAO inhibitors — serotonin syndrome","Tramadol — serotonin risk","Ciprofloxacin — increased duloxetine levels"], foodInt: ["Can be taken with or without food"], desc: "SNRI for depression, anxiety, diabetic nerve pain, fibromyalgia, and chronic pain.", otc: false)

        add("Bupropion", brands: ["Wellbutrin","Zyban","Elontril"], cat: .mentalHealth, therapeutic: "NDRI Antidepressant", active: "Bupropion Hydrochloride", forms: [.tablet], dosages: ["75mg","100mg","150mg","300mg"], defDose: "150", defUnit: "mg", freq: .daily, warnings: ["Seizure risk — dose-dependent","Do not crush extended-release","Avoid in eating disorders"], sides: ["Insomnia","Dry mouth","Agitation","Headache","Weight loss"], interactions: ["MAO inhibitors — contraindicated","Alcohol — increased seizure risk","CYP2D6 substrates — increased levels"], foodInt: ["Can be taken with or without food"], desc: "Unique antidepressant that also helps smoking cessation. Does not cause sexual dysfunction or weight gain.", otc: false)

        add("Mirtazapine", brands: ["Remeron","Avanza","Zispin"], cat: .mentalHealth, therapeutic: "NaSSA Antidepressant", active: "Mirtazapine", forms: [.tablet], dosages: ["7.5mg","15mg","30mg","45mg"], defDose: "15", defUnit: "mg", freq: .daily, warnings: ["Take at bedtime — very sedating","Weight gain is common","Do not use with MAO inhibitors"], sides: ["Drowsiness","Increased appetite","Weight gain","Dry mouth","Dizziness"], interactions: ["MAO inhibitors — serotonin syndrome","Alcohol — enhanced sedation","Benzodiazepines — additive sedation"], foodInt: ["Can be taken with or without food"], desc: "Sedating antidepressant taken at bedtime. Good for depression with insomnia and poor appetite.", otc: false)

        add("Alprazolam", brands: ["Xanax","Alprax","Kalma"], cat: .mentalHealth, therapeutic: "Benzodiazepine Anxiolytic", active: "Alprazolam", forms: [.tablet], dosages: ["0.25mg","0.5mg","1mg","2mg"], defDose: "0.25", defUnit: "mg", freq: .thrice, warnings: ["High risk of dependence","Do not stop abruptly — seizure risk","Avoid alcohol"], sides: ["Drowsiness","Dizziness","Memory impairment","Fatigue","Dependence"], interactions: ["Opioids — respiratory depression","Alcohol — potentially fatal sedation","Ketoconazole — increased levels"], foodInt: ["Can be taken with or without food"], desc: "Fast-acting anti-anxiety medication. For short-term use only due to dependence risk.", otc: false)

        add("Diazepam", brands: ["Valium","Antenex","Ducene"], cat: .mentalHealth, therapeutic: "Benzodiazepine", active: "Diazepam", forms: [.tablet,.liquid,.injection], dosages: ["2mg","5mg","10mg"], defDose: "5", defUnit: "mg", freq: .twice, warnings: ["Risk of dependence","Very long-acting — accumulates","Do not combine with opioids or alcohol"], sides: ["Drowsiness","Fatigue","Muscle weakness","Memory impairment"], interactions: ["Opioids — fatal respiratory depression","Alcohol — extreme sedation","CYP3A4 inhibitors — increased levels"], foodInt: ["Can be taken with or without food"], desc: "Long-acting benzodiazepine for anxiety, muscle spasms, seizures, and alcohol withdrawal.", otc: false)

        add("Quetiapine", brands: ["Seroquel","Qutipin"], cat: .mentalHealth, therapeutic: "Atypical Antipsychotic", active: "Quetiapine Fumarate", forms: [.tablet], dosages: ["25mg","50mg","100mg","200mg","300mg","400mg"], defDose: "50", defUnit: "mg", freq: .daily, warnings: ["Metabolic effects — monitor glucose, lipids, weight","Sedating — take at bedtime","Do not stop abruptly"], sides: ["Drowsiness","Weight gain","Dry mouth","Dizziness","Elevated blood sugar"], interactions: ["CYP3A4 inhibitors — increased levels","Carbamazepine — decreased quetiapine","Alcohol — enhanced sedation"], foodInt: ["Can be taken with or without food"], desc: "Atypical antipsychotic for schizophrenia, bipolar disorder, and treatment-resistant depression.", otc: false)

        add("Lithium", brands: ["Lithobid","Camcolit","Priadel"], cat: .mentalHealth, therapeutic: "Mood Stabilizer", active: "Lithium Carbonate", forms: [.tablet,.capsule,.liquid], dosages: ["150mg","300mg","450mg","600mg"], defDose: "300", defUnit: "mg", freq: .twice, warnings: ["Narrow therapeutic window — regular blood level monitoring","Stay hydrated — dehydration increases toxicity","Monitor thyroid and kidney function"], sides: ["Tremor","Thirst","Frequent urination","Weight gain","Thyroid problems"], interactions: ["NSAIDs — increased lithium toxicity","ACE inhibitors — increased levels","Diuretics — increased toxicity"], foodInt: ["Take with food","Maintain consistent salt and water intake"], desc: "Gold standard mood stabilizer for bipolar disorder. Prevents manic and depressive episodes.", otc: false)


        // ============================================================
        // MARK: - Antibiotics (25)
        // ============================================================

        add("Amoxicillin", brands: ["Amoxil", "Trimox", "Mox", "Novamox", "Wymox"], cat: .antibiotics,
            therapeutic: "Penicillin Antibiotic", active: "Amoxicillin Trihydrate",
            forms: [.capsule, .tablet, .liquid], dosages: ["250mg", "500mg", "875mg"],
            defDose: "500", defUnit: "mg", freq: .thrice,
            warnings: ["Check for penicillin allergy", "Complete full course", "May cause rash with EBV infection"],
            sides: ["Diarrhea", "Nausea", "Rash", "Vomiting"],
            interactions: ["Warfarin — increased bleeding risk", "Methotrexate — increased toxicity", "Oral contraceptives — potentially reduced efficacy"],
            foodInt: ["Can be taken with or without food", "Refrigerate liquid form"],
            desc: "A broad-spectrum penicillin antibiotic for ear infections, sinusitis, UTIs, and respiratory infections.", otc: false)

        add("Azithromycin", brands: ["Zithromax", "Z-Pack", "Azee", "Azithral", "Azicip", "Azifast"], cat: .antibiotics,
            therapeutic: "Macrolide Antibiotic", active: "Azithromycin Dihydrate",
            forms: [.tablet, .liquid, .injection], dosages: ["250mg", "500mg"],
            defDose: "500", defUnit: "mg", freq: .daily,
            warnings: ["QT prolongation risk", "Hepatotoxicity possible", "Complete full course even though short duration"],
            sides: ["Diarrhea", "Nausea", "Abdominal pain", "Headache"],
            interactions: ["Warfarin — increased bleeding risk", "Antacids — reduced absorption (take 1hr before or 2hr after)", "Digoxin — increased digoxin levels"],
            foodInt: ["Tablets can be taken with or without food", "Oral suspension: take on empty stomach"],
            desc: "A convenient macrolide antibiotic often prescribed as a 3- or 5-day course for respiratory and skin infections.", otc: false)

        add("Ciprofloxacin", brands: ["Cipro", "Ciproxin", "Ciplox", "Cifran"], cat: .antibiotics,
            therapeutic: "Fluoroquinolone Antibiotic", active: "Ciprofloxacin Hydrochloride",
            forms: [.tablet, .liquid, .injection], dosages: ["250mg", "500mg", "750mg"],
            defDose: "500", defUnit: "mg", freq: .twice,
            warnings: ["Risk of tendon rupture", "Avoid in children and pregnancy", "Photosensitivity — avoid sun exposure"],
            sides: ["Nausea", "Diarrhea", "Headache", "Tendinitis"],
            interactions: ["Theophylline — increased theophylline toxicity", "Tizanidine — contraindicated, increased sedation", "Antacids/iron — reduced absorption"],
            foodInt: ["Do not take with dairy products alone", "Avoid calcium-fortified juices within 2 hours"],
            desc: "A fluoroquinolone reserved for serious bacterial infections of the urinary tract, lungs, and abdomen.", otc: false)

        add("Levofloxacin", brands: ["Levaquin", "Tavanic"], cat: .antibiotics,
            therapeutic: "Fluoroquinolone Antibiotic", active: "Levofloxacin",
            forms: [.tablet, .liquid, .injection], dosages: ["250mg", "500mg", "750mg"],
            defDose: "500", defUnit: "mg", freq: .daily,
            warnings: ["Tendon rupture risk — especially with corticosteroids", "QT prolongation", "CNS effects including seizures"],
            sides: ["Nausea", "Diarrhea", "Headache", "Insomnia"],
            interactions: ["NSAIDs — increased seizure risk", "Warfarin — increased bleeding", "Antacids/iron/zinc — reduced absorption"],
            foodInt: ["Can be taken with or without food", "Separate from antacids by 2 hours"],
            desc: "A broad-spectrum fluoroquinolone for pneumonia, sinusitis, and urinary tract infections.", otc: false)

        add("Doxycycline", brands: ["Vibramycin", "Doryx", "Monodox"], cat: .antibiotics,
            therapeutic: "Tetracycline Antibiotic", active: "Doxycycline Hyclate",
            forms: [.capsule, .tablet, .liquid], dosages: ["50mg", "100mg"],
            defDose: "100", defUnit: "mg", freq: .twice,
            warnings: ["Photosensitivity — use sunscreen", "Avoid in pregnancy and children under 8", "Take upright with full glass of water"],
            sides: ["Nausea", "Photosensitivity", "Esophageal irritation", "Diarrhea"],
            interactions: ["Antacids/calcium/iron — reduced absorption", "Warfarin — increased bleeding risk", "Oral contraceptives — potentially reduced efficacy"],
            foodInt: ["Take with food to reduce nausea", "Avoid dairy within 2 hours"],
            desc: "A versatile tetracycline antibiotic for acne, Lyme disease, respiratory infections, and malaria prevention.", otc: false)

        add("Metronidazole", brands: ["Flagyl", "Metrogyl"], cat: .antibiotics,
            therapeutic: "Nitroimidazole Antibiotic", active: "Metronidazole",
            forms: [.tablet, .capsule, .injection, .topical], dosages: ["250mg", "400mg", "500mg"],
            defDose: "400", defUnit: "mg", freq: .thrice,
            warnings: ["Absolutely no alcohol during and 48 hours after treatment", "Metallic taste is common", "Neurotoxicity with prolonged use"],
            sides: ["Nausea", "Metallic taste", "Headache", "Dark urine"],
            interactions: ["Alcohol — severe disulfiram-like reaction", "Warfarin — increased bleeding", "Lithium — increased lithium toxicity"],
            foodInt: ["Avoid ALL alcohol including in mouthwash", "Take with food to reduce nausea"],
            desc: "An antibiotic effective against anaerobic bacteria and parasites, commonly used for dental and abdominal infections.", otc: false)

        add("Cephalexin", brands: ["Keflex", "Cefalin"], cat: .antibiotics,
            therapeutic: "First-gen Cephalosporin", active: "Cephalexin Monohydrate",
            forms: [.capsule, .liquid], dosages: ["250mg", "500mg"],
            defDose: "500", defUnit: "mg", freq: .thrice,
            warnings: ["Cross-allergy possible with penicillin allergy", "Complete full course", "Adjust dose in renal impairment"],
            sides: ["Diarrhea", "Nausea", "Dyspepsia", "Rash"],
            interactions: ["Metformin — increased metformin levels", "Probenecid — increased cephalexin levels", "Warfarin — monitor INR"],
            foodInt: ["Can be taken with or without food", "Refrigerate liquid suspension"],
            desc: "A first-generation cephalosporin for skin, bone, respiratory, and urinary tract infections.", otc: false)

        add("Ceftriaxone", brands: ["Rocephin"], cat: .antibiotics,
            therapeutic: "Third-gen Cephalosporin", active: "Ceftriaxone Sodium",
            forms: [.injection], dosages: ["250mg", "500mg", "1g", "2g"],
            defDose: "1", defUnit: "g", freq: .daily,
            warnings: ["Do not mix with calcium-containing IV solutions", "Possible cross-allergy with penicillin", "Monitor for C. difficile colitis"],
            sides: ["Injection site pain", "Diarrhea", "Rash", "Elevated liver enzymes"],
            interactions: ["Calcium-containing IV fluids — fatal precipitation in neonates", "Warfarin — increased bleeding", "Loop diuretics — increased nephrotoxicity"],
            foodInt: ["Not applicable — injection only"],
            desc: "A powerful injectable cephalosporin for meningitis, pneumonia, and serious infections.", otc: false)

        add("Clindamycin", brands: ["Cleocin", "Dalacin"], cat: .antibiotics,
            therapeutic: "Lincosamide Antibiotic", active: "Clindamycin Hydrochloride",
            forms: [.capsule, .liquid, .injection, .topical], dosages: ["150mg", "300mg", "600mg"],
            defDose: "300", defUnit: "mg", freq: .thrice,
            warnings: ["High risk of C. difficile colitis", "Stop if severe diarrhea occurs", "Take capsules with full glass of water"],
            sides: ["Diarrhea", "Nausea", "Rash", "Abdominal pain"],
            interactions: ["Erythromycin — antagonistic effect", "Neuromuscular blockers — enhanced blockade", "Warfarin — increased bleeding risk"],
            foodInt: ["Take with food to reduce GI upset", "Take with full glass of water"],
            desc: "An antibiotic for serious infections where penicillin is not suitable, including bone and skin infections.", otc: false)

        add("Trimethoprim-Sulfamethoxazole", brands: ["Bactrim", "Septra", "Co-trimoxazole"], cat: .antibiotics,
            therapeutic: "Sulfonamide / Diaminopyrimidine", active: "Trimethoprim + Sulfamethoxazole",
            forms: [.tablet, .liquid, .injection], dosages: ["400/80mg", "800/160mg"],
            defDose: "800/160", defUnit: "mg", freq: .twice,
            warnings: ["Sulfa allergy risk", "Adequate hydration required", "Monitor potassium — can cause hyperkalemia"],
            sides: ["Nausea", "Rash", "Photosensitivity", "Hyperkalemia"],
            interactions: ["Warfarin — significantly increased bleeding", "Methotrexate — increased bone marrow toxicity", "ACE inhibitors — hyperkalemia risk"],
            foodInt: ["Take with full glass of water", "Can be taken with or without food"],
            desc: "A combination antibiotic for UTIs, traveler diarrhea, and Pneumocystis pneumonia.", otc: false)

        add("Penicillin V", brands: ["Pen-Vee K", "Veetids"], cat: .antibiotics,
            therapeutic: "Penicillin Antibiotic", active: "Phenoxymethylpenicillin Potassium",
            forms: [.tablet, .liquid], dosages: ["250mg", "500mg"],
            defDose: "500", defUnit: "mg", freq: .thrice,
            warnings: ["Check for penicillin allergy", "Complete full course", "Take on empty stomach for best absorption"],
            sides: ["Nausea", "Diarrhea", "Rash", "Oral thrush"],
            interactions: ["Methotrexate — increased toxicity", "Warfarin — increased bleeding risk", "Oral contraceptives — potentially reduced efficacy"],
            foodInt: ["Take on empty stomach 1 hour before meals", "Can take with water"],
            desc: "An oral penicillin for strep throat, dental infections, and rheumatic fever prophylaxis.", otc: false)

        add("Amoxicillin-Clavulanate", brands: ["Augmentin", "Co-amoxiclav", "Clavam", "Moxikind-CV"], cat: .antibiotics,
            therapeutic: "Penicillin + Beta-lactamase Inhibitor", active: "Amoxicillin + Clavulanic Acid",
            forms: [.tablet, .liquid], dosages: ["375mg", "625mg", "1000mg"],
            defDose: "625", defUnit: "mg", freq: .twice,
            warnings: ["Penicillin allergy check required", "Higher diarrhea risk than amoxicillin alone", "Hepatotoxicity risk — monitor liver function"],
            sides: ["Diarrhea", "Nausea", "Vomiting", "Skin rash"],
            interactions: ["Warfarin — increased bleeding", "Methotrexate — increased toxicity", "Allopurinol — increased rash risk"],
            foodInt: ["Take with food to reduce GI upset and improve absorption", "Refrigerate liquid form"],
            desc: "Amoxicillin boosted with clavulanic acid to treat resistant infections of the ear, sinus, and lungs.", otc: false)

        add("Nitrofurantoin", brands: ["Macrobid", "Macrodantin"], cat: .antibiotics,
            therapeutic: "Nitrofuran Antibiotic", active: "Nitrofurantoin",
            forms: [.capsule], dosages: ["50mg", "100mg"],
            defDose: "100", defUnit: "mg", freq: .twice,
            warnings: ["Not effective for kidney infections", "Avoid if creatinine clearance below 30", "Risk of pulmonary toxicity with long-term use"],
            sides: ["Nausea", "Headache", "Dark yellow/brown urine", "Flatulence"],
            interactions: ["Antacids with magnesium — reduced absorption", "Probenecid — reduced urinary levels (less effective)", "Norfloxacin — antagonistic effect"],
            foodInt: ["Take with food to increase absorption and reduce nausea", "Avoid antacids"],
            desc: "An antibiotic specifically for urinary tract infections that concentrates in the urine.", otc: false)

        add("Fluconazole", brands: ["Diflucan"], cat: .antibiotics,
            therapeutic: "Azole Antifungal", active: "Fluconazole",
            forms: [.capsule, .tablet, .liquid, .injection], dosages: ["50mg", "100mg", "150mg", "200mg"],
            defDose: "150", defUnit: "mg", freq: .daily,
            warnings: ["Hepatotoxicity risk", "QT prolongation", "Multiple drug interactions via CYP enzymes"],
            sides: ["Headache", "Nausea", "Abdominal pain", "Rash"],
            interactions: ["Warfarin — significantly increased bleeding", "Statins — increased myopathy risk", "Phenytoin — increased phenytoin levels"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol"],
            desc: "An antifungal used for yeast infections, thrush, and systemic fungal infections.", otc: false)

        add("Acyclovir", brands: ["Zovirax"], cat: .antibiotics,
            therapeutic: "Antiviral — Nucleoside Analog", active: "Acyclovir",
            forms: [.tablet, .capsule, .liquid, .injection, .topical], dosages: ["200mg", "400mg", "800mg"],
            defDose: "400", defUnit: "mg", freq: .thrice,
            warnings: ["Maintain adequate hydration", "Adjust dose for renal impairment", "Start within 72 hours of symptom onset for best results"],
            sides: ["Nausea", "Headache", "Diarrhea", "Malaise"],
            interactions: ["Probenecid — increased acyclovir levels", "Nephrotoxic drugs — increased kidney toxicity", "Zidovudine — lethargy risk"],
            foodInt: ["Can be taken with or without food", "Drink plenty of water"],
            desc: "An antiviral for herpes simplex, shingles, and chickenpox infections.", otc: false)

        add("Oseltamivir", brands: ["Tamiflu"], cat: .antibiotics,
            therapeutic: "Neuraminidase Inhibitor Antiviral", active: "Oseltamivir Phosphate",
            forms: [.capsule, .liquid], dosages: ["30mg", "45mg", "75mg"],
            defDose: "75", defUnit: "mg", freq: .twice,
            warnings: ["Start within 48 hours of flu symptoms", "Adjust dose in renal impairment", "Monitor for neuropsychiatric events in children"],
            sides: ["Nausea", "Vomiting", "Headache", "Insomnia"],
            interactions: ["Live influenza vaccine — may reduce vaccine efficacy", "Probenecid — increased oseltamivir levels", "Warfarin — monitor INR"],
            foodInt: ["Take with food to reduce nausea", "Can be taken with or without food"],
            desc: "An antiviral that reduces flu duration by 1-2 days when started early.", otc: false)

        add("Clarithromycin", brands: ["Biaxin", "Klacid"], cat: .antibiotics,
            therapeutic: "Macrolide Antibiotic", active: "Clarithromycin",
            forms: [.tablet, .liquid], dosages: ["250mg", "500mg"],
            defDose: "500", defUnit: "mg", freq: .twice,
            warnings: ["QT prolongation risk", "Many drug interactions via CYP3A4", "Hepatotoxicity possible"],
            sides: ["Diarrhea", "Nausea", "Abnormal taste", "Abdominal pain"],
            interactions: ["Statins — increased myopathy/rhabdomyolysis risk", "Colchicine — fatal toxicity possible", "Carbamazepine — increased carbamazepine levels"],
            foodInt: ["Can be taken with or without food", "Avoid grapefruit juice"],
            desc: "A macrolide antibiotic for respiratory infections, H. pylori eradication, and skin infections.", otc: false)

        add("Erythromycin", brands: ["E-Mycin", "Eryc", "Erythrocin"], cat: .antibiotics,
            therapeutic: "Macrolide Antibiotic", active: "Erythromycin",
            forms: [.tablet, .capsule, .liquid, .topical], dosages: ["250mg", "500mg"],
            defDose: "500", defUnit: "mg", freq: .thrice,
            warnings: ["GI side effects common", "QT prolongation risk", "Many drug interactions"],
            sides: ["Nausea", "Abdominal cramps", "Diarrhea", "Vomiting"],
            interactions: ["Theophylline — increased theophylline toxicity", "Statins — increased myopathy risk", "Warfarin — increased bleeding"],
            foodInt: ["Take on empty stomach or with food depending on formulation", "Avoid grapefruit juice"],
            desc: "One of the oldest macrolide antibiotics, used for respiratory infections and as a penicillin alternative.", otc: false)

        add("Cefuroxime", brands: ["Zinnat", "Ceftin"], cat: .antibiotics,
            therapeutic: "Second-gen Cephalosporin", active: "Cefuroxime Axetil",
            forms: [.tablet, .liquid, .injection], dosages: ["125mg", "250mg", "500mg"],
            defDose: "250", defUnit: "mg", freq: .twice,
            warnings: ["Cross-allergy with penicillin possible", "Take tablets with food", "Complete full course"],
            sides: ["Diarrhea", "Nausea", "Headache", "Vomiting"],
            interactions: ["Probenecid — increased cefuroxime levels", "Antacids — reduced absorption", "Aminoglycosides — additive nephrotoxicity"],
            foodInt: ["Take tablets with food for better absorption", "Suspension can be taken with or without food"],
            desc: "A second-generation cephalosporin for sinusitis, otitis media, UTIs, and Lyme disease.", otc: false)

        add("Vancomycin", brands: ["Vancocin"], cat: .antibiotics,
            therapeutic: "Glycopeptide Antibiotic", active: "Vancomycin Hydrochloride",
            forms: [.injection, .capsule], dosages: ["125mg", "250mg", "500mg", "1g"],
            defDose: "1", defUnit: "g", freq: .twice,
            warnings: ["Requires therapeutic drug monitoring", "Red man syndrome with rapid IV infusion", "Nephrotoxicity and ototoxicity risk"],
            sides: ["Nephrotoxicity", "Red man syndrome", "Ototoxicity", "Nausea"],
            interactions: ["Aminoglycosides — additive nephro- and ototoxicity", "NSAIDs — increased nephrotoxicity", "Neuromuscular blockers — enhanced blockade"],
            foodInt: ["Oral capsules: can be taken with or without food", "IV form: not applicable"],
            desc: "A glycopeptide antibiotic reserved for serious MRSA infections and C. difficile colitis (oral).", otc: false)

        add("Rifampin", brands: ["Rifadin", "Rimactane"], cat: .antibiotics,
            therapeutic: "Rifamycin Antibiotic", active: "Rifampin",
            forms: [.capsule, .injection], dosages: ["150mg", "300mg", "600mg"],
            defDose: "600", defUnit: "mg", freq: .daily,
            warnings: ["Turns body fluids orange-red", "Potent CYP inducer — many drug interactions", "Hepatotoxicity risk"],
            sides: ["Orange discoloration of urine/tears/sweat", "Nausea", "Hepatitis", "Rash"],
            interactions: ["Oral contraceptives — significantly reduced efficacy", "Warfarin — greatly reduced anticoagulant effect", "HIV antiretrovirals — reduced antiviral levels"],
            foodInt: ["Take on empty stomach 1 hour before meals", "Avoid alcohol"],
            desc: "A key tuberculosis drug that also treats other serious infections; causes orange discoloration of body fluids.", otc: false)

        add("Isoniazid", brands: ["INH", "Nydrazid"], cat: .antibiotics,
            therapeutic: "Antimycobacterial", active: "Isoniazid",
            forms: [.tablet, .liquid, .injection], dosages: ["100mg", "300mg"],
            defDose: "300", defUnit: "mg", freq: .daily,
            warnings: ["Hepatotoxicity — monitor liver function monthly", "Peripheral neuropathy — take with pyridoxine (B6)", "Avoid in acute liver disease"],
            sides: ["Hepatitis", "Peripheral neuropathy", "Nausea", "Rash"],
            interactions: ["Paracetamol — increased hepatotoxicity", "Phenytoin — increased phenytoin toxicity", "Carbamazepine — increased carbamazepine levels"],
            foodInt: ["Take on empty stomach for best absorption", "Avoid tyramine-rich foods (aged cheese, cured meats)"],
            desc: "A cornerstone drug for tuberculosis treatment and prevention, always given with vitamin B6.", otc: false)

        add("Clotrimazole", brands: ["Lotrimin", "Canesten"], cat: .antibiotics,
            therapeutic: "Azole Antifungal", active: "Clotrimazole",
            forms: [.topical, .tablet], dosages: ["1%", "2%", "10mg troche"],
            defDose: "1", defUnit: "%", freq: .twice,
            warnings: ["For external use only (cream)", "Do not use in eyes", "Discontinue if severe irritation occurs"],
            sides: ["Local burning", "Skin irritation", "Redness", "Stinging"],
            interactions: ["Tacrolimus topical — possible increased absorption", "Corticosteroid creams — may mask infection", "Nystatin — no significant interactions"],
            foodInt: ["Not applicable — topical use", "Troches: let dissolve slowly in mouth"],
            desc: "A topical antifungal for athlete foot, ringworm, and vaginal yeast infections.", otc: true)

        add("Nystatin", brands: ["Mycostatin", "Nilstat"], cat: .antibiotics,
            therapeutic: "Polyene Antifungal", active: "Nystatin",
            forms: [.liquid, .tablet, .topical], dosages: ["100000 units/mL", "500000 units"],
            defDose: "500000", defUnit: "units", freq: .thrice,
            warnings: ["Swish and hold oral suspension before swallowing", "Not absorbed systemically", "Continue for 48 hours after symptoms resolve"],
            sides: ["Nausea", "Vomiting", "Diarrhea", "Stomach pain"],
            interactions: ["No significant systemic drug interactions", "Progesterone cream — no interactions", "Can be used with antibiotics concurrently"],
            foodInt: ["Oral suspension: use between meals for best contact", "Tablets: can be taken with or without food"],
            desc: "An antifungal for oral thrush and intestinal candidiasis that works locally without systemic absorption.", otc: false)

        add("Valacyclovir", brands: ["Valtrex"], cat: .antibiotics,
            therapeutic: "Antiviral — Nucleoside Analog", active: "Valacyclovir Hydrochloride",
            forms: [.tablet], dosages: ["500mg", "1000mg"],
            defDose: "500", defUnit: "mg", freq: .twice,
            warnings: ["Stay well hydrated", "Adjust dose in renal impairment", "Start treatment at first sign of outbreak"],
            sides: ["Headache", "Nausea", "Abdominal pain", "Dizziness"],
            interactions: ["Probenecid — increased valacyclovir levels", "Nephrotoxic drugs — increased renal risk", "Cimetidine — increased valacyclovir levels"],
            foodInt: ["Can be taken with or without food", "Drink plenty of fluids"],
            desc: "A prodrug of acyclovir with better absorption, used for herpes, shingles, and cold sores.", otc: false)


        // ============================================================
        // MARK: - Cardiovascular (25)
        // ============================================================

        add("Amlodipine", brands: ["Norvasc", "Amlong", "Stamlo", "Amlip", "Amlopin"], cat: .cardiovascular,
            therapeutic: "Calcium Channel Blocker", active: "Amlodipine Besylate",
            forms: [.tablet], dosages: ["2.5mg", "5mg", "10mg"],
            defDose: "5", defUnit: "mg", freq: .daily,
            warnings: ["May cause peripheral edema", "Do not stop abruptly", "Monitor for gingival hyperplasia"],
            sides: ["Peripheral edema", "Dizziness", "Flushing", "Fatigue"],
            interactions: ["Simvastatin — limit simvastatin to 20mg", "Cyclosporine — increased cyclosporine levels", "CYP3A4 inhibitors — increased amlodipine levels"],
            foodInt: ["Can be taken with or without food", "Avoid grapefruit juice — increases drug levels"],
            desc: "A long-acting calcium channel blocker for high blood pressure and angina.", otc: false)

        add("Lisinopril", brands: ["Zestril", "Prinivil"], cat: .cardiovascular,
            therapeutic: "ACE Inhibitor", active: "Lisinopril",
            forms: [.tablet], dosages: ["2.5mg", "5mg", "10mg", "20mg", "40mg"],
            defDose: "10", defUnit: "mg", freq: .daily,
            warnings: ["Can cause angioedema", "Contraindicated in pregnancy", "Monitor potassium and renal function"],
            sides: ["Dry cough", "Dizziness", "Headache", "Hyperkalemia"],
            interactions: ["Potassium supplements — hyperkalemia", "NSAIDs — reduced antihypertensive effect", "Lithium — increased lithium levels"],
            foodInt: ["Can be taken with or without food", "Limit high-potassium foods"],
            desc: "An ACE inhibitor for high blood pressure, heart failure, and kidney protection in diabetes.", otc: false)

        add("Losartan", brands: ["Cozaar", "Losar", "Losacar", "Repace"], cat: .cardiovascular,
            therapeutic: "ARB (Angiotensin II Receptor Blocker)", active: "Losartan Potassium",
            forms: [.tablet], dosages: ["25mg", "50mg", "100mg"],
            defDose: "50", defUnit: "mg", freq: .daily,
            warnings: ["Contraindicated in pregnancy", "Monitor potassium", "May cause hypotension at start"],
            sides: ["Dizziness", "Hyperkalemia", "Fatigue", "Nasal congestion"],
            interactions: ["Potassium-sparing diuretics — hyperkalemia", "NSAIDs — reduced effect", "Lithium — increased lithium levels"],
            foodInt: ["Can be taken with or without food", "Limit high-potassium foods"],
            desc: "An ARB for hypertension and diabetic kidney disease, well tolerated without the cough seen with ACE inhibitors.", otc: false)

        add("Metoprolol", brands: ["Lopressor", "Toprol-XL", "Betaloc", "Met XL", "Metolar"], cat: .cardiovascular,
            therapeutic: "Beta-1 Selective Blocker", active: "Metoprolol Tartrate / Succinate",
            forms: [.tablet], dosages: ["25mg", "50mg", "100mg", "200mg"],
            defDose: "50", defUnit: "mg", freq: .twice,
            warnings: ["Do not stop abruptly — taper", "May mask hypoglycemia symptoms", "Use caution in asthma"],
            sides: ["Fatigue", "Bradycardia", "Dizziness", "Cold extremities"],
            interactions: ["Verapamil — severe bradycardia/heart block", "Clonidine — rebound hypertension if clonidine stopped", "CYP2D6 inhibitors — increased metoprolol levels"],
            foodInt: ["Take with food", "Consistent intake with meals recommended"],
            desc: "A beta-blocker for high blood pressure, heart failure, and heart attack prevention.", otc: false)

        add("Atenolol", brands: ["Tenormin"], cat: .cardiovascular,
            therapeutic: "Beta-1 Selective Blocker", active: "Atenolol",
            forms: [.tablet], dosages: ["25mg", "50mg", "100mg"],
            defDose: "50", defUnit: "mg", freq: .daily,
            warnings: ["Do not stop abruptly", "May mask hypoglycemia", "Adjust dose in renal impairment"],
            sides: ["Fatigue", "Cold extremities", "Bradycardia", "Dizziness"],
            interactions: ["Calcium channel blockers — additive bradycardia", "Clonidine — rebound hypertension risk", "NSAIDs — reduced antihypertensive effect"],
            foodInt: ["Can be taken with or without food", "Consistent daily timing recommended"],
            desc: "A once-daily beta-blocker for hypertension and angina.", otc: false)

        add("Propranolol", brands: ["Inderal", "Hemangeol"], cat: .cardiovascular,
            therapeutic: "Non-selective Beta Blocker", active: "Propranolol Hydrochloride",
            forms: [.tablet, .capsule, .liquid], dosages: ["10mg", "20mg", "40mg", "80mg"],
            defDose: "40", defUnit: "mg", freq: .twice,
            warnings: ["Contraindicated in asthma", "Do not stop abruptly", "May mask hypoglycemia signs"],
            sides: ["Fatigue", "Bradycardia", "Bronchospasm", "Cold hands"],
            interactions: ["Verapamil — severe cardiac depression", "Insulin — masked hypoglycemia symptoms", "Rizatriptan — increased rizatriptan levels"],
            foodInt: ["Take consistently with or without food", "Avoid alcohol"],
            desc: "A non-selective beta-blocker used for hypertension, tremor, migraine prevention, and performance anxiety.", otc: false)

        add("Carvedilol", brands: ["Coreg"], cat: .cardiovascular,
            therapeutic: "Alpha/Beta Blocker", active: "Carvedilol",
            forms: [.tablet, .capsule], dosages: ["3.125mg", "6.25mg", "12.5mg", "25mg"],
            defDose: "6.25", defUnit: "mg", freq: .twice,
            warnings: ["Take with food to slow absorption", "Do not stop abruptly", "May worsen heart failure initially"],
            sides: ["Dizziness", "Fatigue", "Hypotension", "Weight gain"],
            interactions: ["Digoxin — increased digoxin levels", "Insulin — masked hypoglycemia", "CYP2D6 inhibitors — increased carvedilol levels"],
            foodInt: ["Must take with food", "Avoid alcohol"],
            desc: "A combined alpha-beta blocker for heart failure and hypertension, proven to improve survival.", otc: false)

        add("Valsartan", brands: ["Diovan"], cat: .cardiovascular,
            therapeutic: "ARB", active: "Valsartan",
            forms: [.tablet, .capsule], dosages: ["40mg", "80mg", "160mg", "320mg"],
            defDose: "80", defUnit: "mg", freq: .daily,
            warnings: ["Contraindicated in pregnancy", "Monitor potassium", "Hypotension risk in volume-depleted patients"],
            sides: ["Dizziness", "Fatigue", "Hyperkalemia", "Headache"],
            interactions: ["ACE inhibitors — do not combine", "Potassium supplements — hyperkalemia", "NSAIDs — reduced effect and renal risk"],
            foodInt: ["Can be taken with or without food", "Limit high-potassium foods"],
            desc: "An ARB for high blood pressure and post-heart attack management.", otc: false)

        add("Ramipril", brands: ["Altace", "Tritace"], cat: .cardiovascular,
            therapeutic: "ACE Inhibitor", active: "Ramipril",
            forms: [.capsule, .tablet], dosages: ["1.25mg", "2.5mg", "5mg", "10mg"],
            defDose: "5", defUnit: "mg", freq: .daily,
            warnings: ["Contraindicated in pregnancy", "Angioedema risk", "Monitor renal function and potassium"],
            sides: ["Dry cough", "Dizziness", "Hyperkalemia", "Headache"],
            interactions: ["Potassium-sparing diuretics — hyperkalemia", "NSAIDs — reduced effect", "Lithium — increased toxicity"],
            foodInt: ["Can be taken with or without food", "Limit potassium-rich foods"],
            desc: "An ACE inhibitor for hypertension, heart failure, and cardiovascular risk reduction.", otc: false)

        add("Enalapril", brands: ["Vasotec", "Enapril"], cat: .cardiovascular,
            therapeutic: "ACE Inhibitor", active: "Enalapril Maleate",
            forms: [.tablet], dosages: ["2.5mg", "5mg", "10mg", "20mg"],
            defDose: "10", defUnit: "mg", freq: .daily,
            warnings: ["Contraindicated in pregnancy", "Angioedema risk", "First-dose hypotension possible"],
            sides: ["Dry cough", "Dizziness", "Hyperkalemia", "Fatigue"],
            interactions: ["Potassium supplements — hyperkalemia", "NSAIDs — reduced effect", "Lithium — increased levels"],
            foodInt: ["Can be taken with or without food", "Limit potassium-rich foods"],
            desc: "An ACE inhibitor for hypertension and heart failure.", otc: false)

        add("Nifedipine", brands: ["Adalat", "Procardia"], cat: .cardiovascular,
            therapeutic: "Calcium Channel Blocker", active: "Nifedipine",
            forms: [.tablet, .capsule], dosages: ["10mg", "20mg", "30mg", "60mg", "90mg"],
            defDose: "30", defUnit: "mg", freq: .daily,
            warnings: ["Immediate-release not for hypertension", "Reflex tachycardia risk", "Peripheral edema common"],
            sides: ["Peripheral edema", "Flushing", "Headache", "Dizziness"],
            interactions: ["Beta-blockers — additive hypotension", "CYP3A4 inhibitors — increased nifedipine levels", "Digoxin — increased digoxin levels"],
            foodInt: ["Avoid grapefruit juice", "Take consistently with or without food"],
            desc: "A calcium channel blocker for hypertension and angina, available in extended-release forms.", otc: false)

        add("Diltiazem", brands: ["Cardizem", "Tiazac", "Dilzem"], cat: .cardiovascular,
            therapeutic: "Calcium Channel Blocker", active: "Diltiazem Hydrochloride",
            forms: [.tablet, .capsule, .injection], dosages: ["30mg", "60mg", "120mg", "180mg", "240mg"],
            defDose: "120", defUnit: "mg", freq: .daily,
            warnings: ["Do not crush extended-release forms", "Monitor heart rate", "Avoid with severe heart failure"],
            sides: ["Bradycardia", "Dizziness", "Edema", "Headache"],
            interactions: ["Beta-blockers — severe bradycardia risk", "Simvastatin — increased statin levels", "Cyclosporine — increased cyclosporine levels"],
            foodInt: ["Can be taken with or without food", "Avoid grapefruit juice"],
            desc: "A calcium channel blocker for hypertension, angina, and certain arrhythmias.", otc: false)

        add("Verapamil", brands: ["Calan", "Isoptin", "Verelan"], cat: .cardiovascular,
            therapeutic: "Calcium Channel Blocker", active: "Verapamil Hydrochloride",
            forms: [.tablet, .capsule, .injection], dosages: ["40mg", "80mg", "120mg", "180mg", "240mg"],
            defDose: "120", defUnit: "mg", freq: .thrice,
            warnings: ["Contraindicated with beta-blockers IV", "Monitor heart rate and rhythm", "Avoid in heart failure with reduced EF"],
            sides: ["Constipation", "Bradycardia", "Dizziness", "Edema"],
            interactions: ["Beta-blockers — AV block risk", "Digoxin — increased digoxin levels", "Statins — increased myopathy risk"],
            foodInt: ["Take with food", "Avoid grapefruit juice"],
            desc: "A calcium channel blocker for hypertension, angina, and supraventricular tachycardia.", otc: false)

        add("Hydrochlorothiazide", brands: ["Microzide", "HydroDIURIL"], cat: .cardiovascular,
            therapeutic: "Thiazide Diuretic", active: "Hydrochlorothiazide",
            forms: [.tablet, .capsule], dosages: ["12.5mg", "25mg", "50mg"],
            defDose: "25", defUnit: "mg", freq: .daily,
            warnings: ["Monitor electrolytes especially potassium", "Photosensitivity", "May raise blood glucose and uric acid"],
            sides: ["Hypokalemia", "Dizziness", "Increased urination", "Photosensitivity"],
            interactions: ["Lithium — increased lithium toxicity", "Digoxin — hypokalemia increases digoxin toxicity", "NSAIDs — reduced diuretic effect"],
            foodInt: ["Take in the morning to avoid nighttime urination", "Eat potassium-rich foods"],
            desc: "A thiazide diuretic commonly used as first-line treatment for mild to moderate hypertension.", otc: false)

        add("Furosemide", brands: ["Lasix"], cat: .cardiovascular,
            therapeutic: "Loop Diuretic", active: "Furosemide",
            forms: [.tablet, .liquid, .injection], dosages: ["20mg", "40mg", "80mg"],
            defDose: "40", defUnit: "mg", freq: .daily,
            warnings: ["Monitor electrolytes closely", "Ototoxicity with rapid IV administration", "Dehydration risk"],
            sides: ["Dehydration", "Hypokalemia", "Dizziness", "Hyperuricemia"],
            interactions: ["Aminoglycosides — increased ototoxicity", "Digoxin — hypokalemia increases toxicity", "Lithium — increased lithium levels"],
            foodInt: ["Take in the morning", "Eat potassium-rich foods like bananas"],
            desc: "A potent loop diuretic for fluid overload in heart failure, kidney disease, and edema.", otc: false)

        add("Spironolactone", brands: ["Aldactone"], cat: .cardiovascular,
            therapeutic: "Potassium-Sparing Diuretic / Aldosterone Antagonist", active: "Spironolactone",
            forms: [.tablet], dosages: ["25mg", "50mg", "100mg"],
            defDose: "25", defUnit: "mg", freq: .daily,
            warnings: ["Monitor potassium — hyperkalemia risk", "Gynecomastia in males", "Contraindicated in severe renal impairment"],
            sides: ["Hyperkalemia", "Gynecomastia", "Dizziness", "GI upset"],
            interactions: ["ACE inhibitors/ARBs — additive hyperkalemia", "Potassium supplements — dangerous hyperkalemia", "NSAIDs — reduced effect and hyperkalemia"],
            foodInt: ["Take with food", "Avoid potassium-rich food supplements"],
            desc: "A potassium-sparing diuretic used in heart failure, resistant hypertension, and hormonal acne.", otc: false)

        add("Telmisartan", brands: ["Micardis", "Telma", "Telsartan", "Telmikind"], cat: .cardiovascular,
            therapeutic: "ARB", active: "Telmisartan",
            forms: [.tablet], dosages: ["20mg", "40mg", "80mg"],
            defDose: "40", defUnit: "mg", freq: .daily,
            warnings: ["Contraindicated in pregnancy", "Monitor potassium", "Hypotension risk"],
            sides: ["Dizziness", "Back pain", "Diarrhea", "Upper respiratory infection"],
            interactions: ["ACE inhibitors — avoid combination", "NSAIDs — reduced effect", "Digoxin — monitor levels"],
            foodInt: ["Can be taken with or without food", "Limit high-potassium foods"],
            desc: "A long-acting ARB for hypertension and cardiovascular risk reduction.", otc: false)

        add("Bisoprolol", brands: ["Zebeta", "Concor"], cat: .cardiovascular,
            therapeutic: "Beta-1 Selective Blocker", active: "Bisoprolol Fumarate",
            forms: [.tablet], dosages: ["1.25mg", "2.5mg", "5mg", "10mg"],
            defDose: "5", defUnit: "mg", freq: .daily,
            warnings: ["Do not stop abruptly", "May mask hypoglycemia", "Caution in asthma/COPD"],
            sides: ["Fatigue", "Dizziness", "Bradycardia", "Cold extremities"],
            interactions: ["Verapamil — AV block risk", "Clonidine — rebound hypertension", "Antidiabetics — masked hypoglycemia"],
            foodInt: ["Can be taken with or without food", "Take at same time daily"],
            desc: "A highly selective beta-1 blocker for hypertension and heart failure.", otc: false)

        add("Nebivolol", brands: ["Bystolic"], cat: .cardiovascular,
            therapeutic: "Beta-1 Selective Blocker", active: "Nebivolol Hydrochloride",
            forms: [.tablet], dosages: ["2.5mg", "5mg", "10mg", "20mg"],
            defDose: "5", defUnit: "mg", freq: .daily,
            warnings: ["Do not stop abruptly", "Avoid in severe hepatic impairment", "Less effective in CYP2D6 poor metabolizers"],
            sides: ["Headache", "Fatigue", "Dizziness", "Nausea"],
            interactions: ["CYP2D6 inhibitors — increased nebivolol levels", "Verapamil — additive cardiac depression", "Clonidine — rebound hypertension"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol"],
            desc: "A newer beta-blocker with vasodilating properties via nitric oxide, well tolerated for hypertension.", otc: false)

        add("Clonidine", brands: ["Catapres", "Kapvay"], cat: .cardiovascular,
            therapeutic: "Central Alpha-2 Agonist", active: "Clonidine Hydrochloride",
            forms: [.tablet, .patch], dosages: ["0.1mg", "0.2mg", "0.3mg"],
            defDose: "0.1", defUnit: "mg", freq: .twice,
            warnings: ["Do not stop abruptly — rebound hypertension", "Causes significant drowsiness", "Patch: rotate application sites"],
            sides: ["Drowsiness", "Dry mouth", "Constipation", "Dizziness"],
            interactions: ["Beta-blockers — rebound hypertension if clonidine withdrawn first", "CNS depressants — additive sedation", "Tricyclic antidepressants — reduced clonidine effect"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol"],
            desc: "A centrally acting antihypertensive also used for ADHD, opioid withdrawal, and hot flashes.", otc: false)

        add("Digoxin", brands: ["Lanoxin"], cat: .cardiovascular,
            therapeutic: "Cardiac Glycoside", active: "Digoxin",
            forms: [.tablet, .liquid, .injection], dosages: ["0.0625mg", "0.125mg", "0.25mg"],
            defDose: "0.125", defUnit: "mg", freq: .daily,
            warnings: ["Narrow therapeutic index — monitor drug levels", "Toxicity risk with hypokalemia", "Renal dose adjustment required"],
            sides: ["Nausea", "Visual disturbances (yellow vision)", "Arrhythmias", "Anorexia"],
            interactions: ["Amiodarone — increases digoxin levels by 70-100%", "Verapamil — increased digoxin levels", "Diuretics — hypokalemia increases toxicity"],
            foodInt: ["Take consistently with or without food", "High-fiber meals may reduce absorption"],
            desc: "A cardiac glycoside for heart failure and atrial fibrillation rate control.", otc: false)

        add("Amiodarone", brands: ["Cordarone", "Pacerone"], cat: .cardiovascular,
            therapeutic: "Class III Antiarrhythmic", active: "Amiodarone Hydrochloride",
            forms: [.tablet, .injection], dosages: ["100mg", "200mg", "400mg"],
            defDose: "200", defUnit: "mg", freq: .daily,
            warnings: ["Thyroid toxicity — monitor TFTs regularly", "Pulmonary toxicity risk", "Corneal microdeposits — annual eye exams"],
            sides: ["Thyroid dysfunction", "Pulmonary fibrosis", "Photosensitivity", "Corneal deposits"],
            interactions: ["Warfarin — dramatically increased bleeding", "Digoxin — doubled digoxin levels", "Statins — increased myopathy risk"],
            foodInt: ["Take with food for better absorption", "Avoid grapefruit juice"],
            desc: "A potent antiarrhythmic for life-threatening heart rhythm disorders with many potential side effects.", otc: false)

        add("Isosorbide Mononitrate", brands: ["Imdur", "Monoket"], cat: .cardiovascular,
            therapeutic: "Nitrate Vasodilator", active: "Isosorbide Mononitrate",
            forms: [.tablet], dosages: ["10mg", "20mg", "30mg", "60mg", "120mg"],
            defDose: "30", defUnit: "mg", freq: .daily,
            warnings: ["Headache is common initially", "Allow a nitrate-free interval to prevent tolerance", "Do not use with PDE5 inhibitors"],
            sides: ["Headache", "Dizziness", "Flushing", "Hypotension"],
            interactions: ["Sildenafil/Tadalafil — severe hypotension, contraindicated", "Antihypertensives — additive hypotension", "Alcohol — increased hypotension"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol"],
            desc: "A long-acting nitrate for preventing angina chest pain episodes.", otc: false)

        add("Nitroglycerin", brands: ["Nitrostat", "Nitro-Dur", "Minitran"], cat: .cardiovascular,
            therapeutic: "Nitrate Vasodilator", active: "Nitroglycerin",
            forms: [.tablet, .patch, .liquid], dosages: ["0.3mg", "0.4mg", "0.6mg"],
            defDose: "0.4", defUnit: "mg", freq: .asNeeded,
            warnings: ["Sublingual: place under tongue, do not swallow", "Call 911 if pain persists after 3 doses", "Absolutely no PDE5 inhibitors"],
            sides: ["Headache", "Dizziness", "Flushing", "Hypotension"],
            interactions: ["PDE5 inhibitors (sildenafil) — life-threatening hypotension", "Antihypertensives — additive hypotension", "Heparin — may reduce heparin effectiveness"],
            foodInt: ["Sublingual: do not eat or drink", "Avoid alcohol"],
            desc: "A fast-acting nitrate placed under the tongue for acute angina chest pain relief.", otc: false)

        add("Hydralazine", brands: ["Apresoline"], cat: .cardiovascular,
            therapeutic: "Direct Vasodilator", active: "Hydralazine Hydrochloride",
            forms: [.tablet, .injection], dosages: ["10mg", "25mg", "50mg", "100mg"],
            defDose: "25", defUnit: "mg", freq: .thrice,
            warnings: ["Drug-induced lupus with high doses or slow acetylators", "Reflex tachycardia possible", "Monitor CBC and ANA periodically"],
            sides: ["Headache", "Tachycardia", "Flushing", "Lupus-like syndrome"],
            interactions: ["Beta-blockers — may help counteract reflex tachycardia", "MAO inhibitors — enhanced hypotension", "NSAIDs — reduced antihypertensive effect"],
            foodInt: ["Take with food for better absorption", "Avoid alcohol"],
            desc: "A vasodilator used for hypertension and heart failure, often combined with isosorbide dinitrate.", otc: false)


        // ═══════════════════════════════════════
        // MARK: - Blood Thinners
        // ═══════════════════════════════════════

        add("Warfarin", brands: ["Coumadin","Jantoven","Marevan"], cat: .bloodThinners, therapeutic: "Vitamin K Antagonist", active: "Warfarin Sodium", forms: [.tablet], dosages: ["1mg","2mg","3mg","5mg","7.5mg","10mg"], defDose: "5", defUnit: "mg", freq: .daily, warnings: ["Regular INR blood tests required","Many drug and food interactions","Bleeding risk — watch for unusual bruising"], sides: ["Bleeding","Bruising","Nausea","Hair loss"], interactions: ["NSAIDs — major bleeding risk","Antibiotics — altered INR","Vitamin K foods — reduced effect"], foodInt: ["Maintain consistent vitamin K intake (leafy greens)","Avoid cranberry juice in large amounts"], desc: "Blood thinner for atrial fibrillation, DVT, and mechanical heart valves. Requires regular monitoring.", otc: false)

        add("Rivaroxaban", brands: ["Xarelto"], cat: .bloodThinners, therapeutic: "Direct Factor Xa Inhibitor", active: "Rivaroxaban", forms: [.tablet], dosages: ["2.5mg","10mg","15mg","20mg"], defDose: "20", defUnit: "mg", freq: .daily, warnings: ["Take with food (15mg and 20mg doses)","No routine monitoring needed","Bleeding risk — no specific reversal agent widely available"], sides: ["Bleeding","Bruising","Nausea","Back pain"], interactions: ["Strong CYP3A4 inhibitors — increased levels","NSAIDs — increased bleeding","Antiplatelet agents — additive bleeding risk"], foodInt: ["Take 15mg and 20mg doses with food"], desc: "Modern blood thinner for atrial fibrillation and blood clots. No INR monitoring needed.", otc: false)

        add("Apixaban", brands: ["Eliquis"], cat: .bloodThinners, therapeutic: "Direct Factor Xa Inhibitor", active: "Apixaban", forms: [.tablet], dosages: ["2.5mg","5mg"], defDose: "5", defUnit: "mg", freq: .twice, warnings: ["Do not stop without medical advice","Bleeding risk","Dose adjustment for elderly/low weight/kidney disease"], sides: ["Bleeding","Bruising","Nausea","Anemia"], interactions: ["Strong CYP3A4 inhibitors — increased levels","NSAIDs — increased bleeding","Aspirin — additive bleeding"], foodInt: ["Can be taken with or without food"], desc: "Blood thinner for atrial fibrillation and DVT/PE. Lowest bleeding risk among DOACs.", otc: false)

        add("Clopidogrel", brands: ["Plavix","Clopilet","Plagril"], cat: .bloodThinners, therapeutic: "P2Y12 Antiplatelet", active: "Clopidogrel Bisulfate", forms: [.tablet], dosages: ["75mg","300mg"], defDose: "75", defUnit: "mg", freq: .daily, warnings: ["Do not stop without doctor approval after stent placement","Bleeding risk","Genetic poor metabolizers may not respond"], sides: ["Bleeding","Bruising","Diarrhea","Rash","Stomach pain"], interactions: ["Omeprazole — reduced effectiveness (use pantoprazole instead)","NSAIDs — increased bleeding","Warfarin — additive bleeding risk"], foodInt: ["Can be taken with or without food"], desc: "Antiplatelet drug to prevent heart attacks and strokes, especially after stent placement.", otc: false)

        add("Enoxaparin", brands: ["Lovenox","Clexane"], cat: .bloodThinners, therapeutic: "Low Molecular Weight Heparin", active: "Enoxaparin Sodium", forms: [.injection], dosages: ["20mg","40mg","60mg","80mg","100mg"], defDose: "40", defUnit: "mg", freq: .daily, warnings: ["Subcutaneous injection only","Rotate injection sites","Monitor platelet count"], sides: ["Injection site bruising","Bleeding","Anemia","Elevated liver enzymes"], interactions: ["NSAIDs — increased bleeding","Antiplatelet agents — additive bleeding","Spinal/epidural anesthesia — risk of spinal hematoma"], foodInt: ["Injection: no food interaction"], desc: "Injectable blood thinner for DVT prevention and treatment, and during heart attacks.", otc: false)

        add("Dabigatran", brands: ["Pradaxa"], cat: .bloodThinners, therapeutic: "Direct Thrombin Inhibitor", active: "Dabigatran Etexilate", forms: [.capsule], dosages: ["75mg","110mg","150mg"], defDose: "150", defUnit: "mg", freq: .twice, warnings: ["Do not crush or open capsules","Store in original packaging","Specific reversal agent (idarucizumab) available"], sides: ["Bleeding","Dyspepsia","Gastritis","Nausea"], interactions: ["P-glycoprotein inhibitors — increased levels","NSAIDs — increased bleeding","Proton pump inhibitors — may reduce absorption slightly"], foodInt: ["Can be taken with or without food"], desc: "Blood thinner for atrial fibrillation. Has specific reversal agent (Praxbind).", otc: false)

        // ═══════════════════════════════════════
        // MARK: - Cholesterol
        // ═══════════════════════════════════════

        add("Atorvastatin", brands: ["Lipitor","Atorva","Torvast"], cat: .cholesterol, therapeutic: "HMG-CoA Reductase Inhibitor (Statin)", active: "Atorvastatin Calcium", forms: [.tablet], dosages: ["10mg","20mg","40mg","80mg"], defDose: "20", defUnit: "mg", freq: .daily, warnings: ["Report unexplained muscle pain immediately","Monitor liver function","Avoid in pregnancy"], sides: ["Muscle pain","Headache","Nausea","Joint pain","Elevated liver enzymes"], interactions: ["Grapefruit juice — increased levels","Clarithromycin — increased myopathy risk","Gemfibrozil — severe myopathy risk","Cyclosporine — increased statin toxicity"], foodInt: ["Avoid large amounts of grapefruit juice"], desc: "Most prescribed statin for lowering cholesterol and preventing heart disease.", otc: false)

        add("Rosuvastatin", brands: ["Crestor","Rosuvas","Rozavel"], cat: .cholesterol, therapeutic: "HMG-CoA Reductase Inhibitor (Statin)", active: "Rosuvastatin Calcium", forms: [.tablet], dosages: ["5mg","10mg","20mg","40mg"], defDose: "10", defUnit: "mg", freq: .daily, warnings: ["Report muscle pain","Monitor liver and kidney function","Most potent statin — start low"], sides: ["Muscle pain","Headache","Nausea","Weakness","Elevated liver enzymes"], interactions: ["Cyclosporine — contraindicated at higher doses","Gemfibrozil — myopathy risk","Warfarin — increased INR"], foodInt: ["Can be taken with or without food, any time of day"], desc: "Most potent statin available. Greater LDL reduction than atorvastatin at lower doses.", otc: false)

        add("Simvastatin", brands: ["Zocor","Simcard","Simvor"], cat: .cholesterol, therapeutic: "HMG-CoA Reductase Inhibitor (Statin)", active: "Simvastatin", forms: [.tablet], dosages: ["5mg","10mg","20mg","40mg","80mg"], defDose: "20", defUnit: "mg", freq: .daily, warnings: ["Take in the evening","80mg dose not recommended (myopathy risk)","Avoid grapefruit"], sides: ["Muscle pain","Constipation","Headache","Nausea"], interactions: ["Amlodipine — limit simvastatin to 20mg","Diltiazem — limit simvastatin to 20mg","Amiodarone — limit simvastatin to 20mg","Grapefruit — significantly increased levels"], foodInt: ["Avoid grapefruit juice","Take in the evening for maximum effect"], desc: "Statin best taken in the evening. Many dose restrictions with other medications.", otc: false)

        add("Ezetimibe", brands: ["Zetia","Ezetrol","Ezedoc"], cat: .cholesterol, therapeutic: "Cholesterol Absorption Inhibitor", active: "Ezetimibe", forms: [.tablet], dosages: ["10mg"], defDose: "10", defUnit: "mg", freq: .daily, warnings: ["Monitor liver function when combined with statin","Report muscle pain"], sides: ["Diarrhea","Stomach pain","Fatigue","Joint pain"], interactions: ["Fibrates — increased gallstone risk","Cyclosporine — increased ezetimibe levels","Cholestyramine — reduced absorption"], foodInt: ["Can be taken with or without food"], desc: "Lowers cholesterol by blocking absorption in the intestine. Often combined with a statin.", otc: false)

        add("Fenofibrate", brands: ["Tricor","Lipanthyl","Fenoglide"], cat: .cholesterol, therapeutic: "Fibrate", active: "Fenofibrate", forms: [.tablet,.capsule], dosages: ["48mg","145mg","160mg","200mg"], defDose: "145", defUnit: "mg", freq: .daily, warnings: ["Monitor liver and kidney function","Risk of myopathy especially with statins","May increase gallstone risk"], sides: ["Nausea","Stomach pain","Headache","Muscle pain","Elevated liver enzymes"], interactions: ["Warfarin — increased bleeding (reduce warfarin dose)","Statins — increased myopathy risk","Bile acid sequestrants — take 1hr apart"], foodInt: ["Take with food for better absorption"], desc: "Fibrate that primarily lowers triglycerides and raises HDL (good) cholesterol.", otc: false)

        // ═══════════════════════════════════════
        // MARK: - Thyroid
        // ═══════════════════════════════════════

        add("Levothyroxine", brands: ["Synthroid","Eltroxin","Euthyrox","Levoxyl"], cat: .thyroid, therapeutic: "Thyroid Hormone Replacement", active: "Levothyroxine Sodium", forms: [.tablet,.capsule,.liquid], dosages: ["25mcg","50mcg","75mcg","88mcg","100mcg","112mcg","125mcg","150mcg","200mcg"], defDose: "50", defUnit: "mcg", freq: .daily, warnings: ["Take on empty stomach 30-60 min before food","Consistent timing daily","Regular TSH monitoring"], sides: ["Palpitations (if dose too high)","Weight loss (dose too high)","Insomnia","Tremor"], interactions: ["Calcium/Iron supplements — take 4 hours apart","Antacids — reduce absorption","Warfarin — increased anticoagulation"], foodInt: ["Take on empty stomach with water, 30-60 min before breakfast","Coffee, fiber, soy reduce absorption"], desc: "Thyroid hormone replacement for hypothyroidism (underactive thyroid). Most prescribed thyroid medication.", otc: false)

        add("Methimazole", brands: ["Tapazole","Thymazole","Carbimazole"], cat: .thyroid, therapeutic: "Antithyroid Agent", active: "Methimazole", forms: [.tablet], dosages: ["5mg","10mg","20mg"], defDose: "10", defUnit: "mg", freq: .daily, warnings: ["Regular blood count monitoring","Risk of agranulocytosis — report sore throat/fever immediately","Not in first trimester of pregnancy"], sides: ["Rash","Joint pain","Nausea","Taste changes","Agranulocytosis (rare but serious)"], interactions: ["Warfarin — reduced anticoagulation as thyroid normalizes","Beta-blockers — may need dose reduction","Digoxin — levels change as thyroid corrects"], foodInt: ["Can be taken with or without food"], desc: "Reduces thyroid hormone production for hyperthyroidism (overactive thyroid) and Graves' disease.", otc: false)

        // ═══════════════════════════════════════
        // MARK: - Allergy & Antihistamines
        // ═══════════════════════════════════════

        add("Cetirizine", brands: ["Zyrtec","Reactine","Alerid","Cetzine","Okacet","CTZ"], cat: .allergy, therapeutic: "Second-gen Antihistamine", active: "Cetirizine Hydrochloride", forms: [.tablet,.liquid], dosages: ["5mg","10mg"], defDose: "10", defUnit: "mg", freq: .daily, warnings: ["May cause mild drowsiness","Reduce dose in kidney disease"], sides: ["Drowsiness","Dry mouth","Headache","Fatigue"], interactions: ["Alcohol — enhanced drowsiness","CNS depressants — additive sedation","Theophylline — slightly reduced cetirizine clearance"], foodInt: ["Can be taken with or without food"], desc: "Non-drowsy antihistamine for hay fever, hives, and allergic rhinitis.", otc: true)

        add("Loratadine", brands: ["Claritin","Clarityn","Alavert"], cat: .allergy, therapeutic: "Second-gen Antihistamine", active: "Loratadine", forms: [.tablet,.liquid], dosages: ["10mg"], defDose: "10", defUnit: "mg", freq: .daily, warnings: ["True non-drowsy antihistamine","Adjust dose in liver disease"], sides: ["Headache","Drowsiness (rare)","Dry mouth","Fatigue"], interactions: ["Erythromycin — increased loratadine levels","Ketoconazole — increased levels","Alcohol — minimal interaction"], foodInt: ["Can be taken with or without food"], desc: "Non-drowsy antihistamine for allergies. One of the least sedating options.", otc: true)

        add("Fexofenadine", brands: ["Allegra","Telfast","Fexet"], cat: .allergy, therapeutic: "Second-gen Antihistamine", active: "Fexofenadine Hydrochloride", forms: [.tablet], dosages: ["60mg","120mg","180mg"], defDose: "180", defUnit: "mg", freq: .daily, warnings: ["Truly non-sedating","Avoid fruit juices within 4 hours (reduce absorption)"], sides: ["Headache","Nausea","Drowsiness (rare)","Menstrual cramps"], interactions: ["Antacids — reduced absorption","Erythromycin — increased levels","Ketoconazole — increased levels"], foodInt: ["Avoid apple, orange, and grapefruit juice within 4 hours"], desc: "Non-sedating antihistamine for hay fever and hives. Does not cause drowsiness.", otc: true)

        add("Diphenhydramine", brands: ["Benadryl","Nytol","ZzzQuil"], cat: .allergy, therapeutic: "First-gen Antihistamine", active: "Diphenhydramine Hydrochloride", forms: [.tablet,.capsule,.liquid], dosages: ["25mg","50mg"], defDose: "25", defUnit: "mg", freq: .thrice, warnings: ["Very drowsy — do not drive","Not recommended for elderly","Anticholinergic effects"], sides: ["Drowsiness","Dry mouth","Blurred vision","Constipation","Urinary retention"], interactions: ["Alcohol — severe drowsiness","Opioids — respiratory depression","MAO inhibitors — increased anticholinergic effects"], foodInt: ["Can be taken with or without food"], desc: "First-generation antihistamine for allergies, insomnia, and motion sickness. Very sedating.", otc: true)

        // ═══════════════════════════════════════
        // MARK: - Vitamins & Supplements
        // ═══════════════════════════════════════

        add("Vitamin D3", brands: ["Cholecalciferol","D-Cal","Ddrops"], cat: .vitamins, therapeutic: "Vitamin Supplement", active: "Cholecalciferol", forms: [.tablet,.capsule,.drops,.liquid], dosages: ["400IU","1000IU","2000IU","5000IU","50000IU"], defDose: "1000", defUnit: "IU", freq: .daily, warnings: ["Excess can cause hypercalcemia","Take with fat-containing food for absorption","Check levels before high-dose supplementation"], sides: ["Nausea (at high doses)","Constipation","Weakness","Kidney stones (excess)"], interactions: ["Thiazide diuretics — hypercalcemia risk","Steroids — reduced vitamin D effect","Orlistat — reduced absorption"], foodInt: ["Take with a meal containing fat for better absorption"], desc: "Essential vitamin for bone health, immune function, and mood. Most people are deficient.", otc: true)

        add("Vitamin B12", brands: ["Cyanocobalamin","Methylcobalamin","Neurobion"], cat: .vitamins, therapeutic: "Vitamin Supplement", active: "Cyanocobalamin / Methylcobalamin", forms: [.tablet,.injection,.liquid], dosages: ["500mcg","1000mcg","2500mcg","5000mcg"], defDose: "1000", defUnit: "mcg", freq: .daily, warnings: ["Injection needed if absorption problem (pernicious anemia)","Safe at high doses — water soluble"], sides: ["Rare — very safe","Injection site pain"], interactions: ["Metformin — B12 deficiency with long-term metformin use","Proton pump inhibitors — reduced B12 absorption","Colchicine — reduced B12 absorption"], foodInt: ["Can be taken with or without food"], desc: "Essential for nerve function and red blood cell production. Common deficiency with metformin and PPIs.", otc: true)

        add("Iron Supplement", brands: ["Ferrous Sulfate","Feramax","Slow Fe","Ferrograd"], cat: .vitamins, therapeutic: "Mineral Supplement", active: "Ferrous Sulfate / Ferrous Fumarate", forms: [.tablet,.capsule,.liquid], dosages: ["65mg","100mg","200mg","325mg"], defDose: "325", defUnit: "mg", freq: .daily, warnings: ["May cause constipation","Take on empty stomach if tolerated","Black stools are normal"], sides: ["Constipation","Nausea","Dark stools","Stomach pain","Diarrhea"], interactions: ["Levothyroxine — take 4 hours apart","Calcium — reduced iron absorption","Antacids/PPIs — reduced absorption","Tetracyclines — mutual reduction"], foodInt: ["Take with vitamin C (orange juice) for better absorption","Avoid with tea, coffee, dairy within 2 hours"], desc: "Iron supplement for iron-deficiency anemia. Take with vitamin C to enhance absorption.", otc: true)

        add("Folic Acid", brands: ["Folate","Folvite"], cat: .vitamins, therapeutic: "B Vitamin Supplement", active: "Folic Acid", forms: [.tablet], dosages: ["400mcg","800mcg","1mg","5mg"], defDose: "400", defUnit: "mcg", freq: .daily, warnings: ["Essential before and during pregnancy (prevents neural tube defects)","High doses can mask B12 deficiency"], sides: ["Very rare — extremely safe","Bitter taste at high doses"], interactions: ["Methotrexate — folic acid reduces side effects (take on non-MTX days)","Phenytoin — mutual interference","Sulfasalazine — reduced folate absorption"], foodInt: ["Can be taken with or without food"], desc: "B vitamin essential for pregnancy, DNA synthesis, and red blood cell formation.", otc: true)

        add("Calcium + Vitamin D", brands: ["Caltrate","Citracal","Os-Cal","Calcichew"], cat: .vitamins, therapeutic: "Mineral + Vitamin Supplement", active: "Calcium Carbonate + Cholecalciferol", forms: [.tablet,.capsule], dosages: ["500mg+200IU","600mg+400IU","1000mg+800IU"], defDose: "600", defUnit: "mg", freq: .twice, warnings: ["Do not exceed 2500mg calcium/day","Take with food for calcium carbonate","Separate from other medications by 2 hours"], sides: ["Constipation","Gas","Bloating","Kidney stones (excess)"], interactions: ["Levothyroxine — take 4 hours apart","Iron — take 2 hours apart","Tetracyclines — reduced absorption","Bisphosphonates — take 30 min apart"], foodInt: ["Take calcium carbonate with food for best absorption"], desc: "Combined calcium and vitamin D for bone health. Essential for osteoporosis prevention.", otc: true)

        add("Omega-3 Fish Oil", brands: ["Lovaza","Omacor","Nordic Naturals"], cat: .vitamins, therapeutic: "Essential Fatty Acid Supplement", active: "EPA + DHA", forms: [.capsule,.liquid], dosages: ["500mg","1000mg","2000mg","4000mg"], defDose: "1000", defUnit: "mg", freq: .daily, warnings: ["May increase bleeding risk at high doses","Fishy burps possible — freeze capsules to reduce","Check for mercury content"], sides: ["Fishy aftertaste","Nausea","Diarrhea","Easy bruising at high doses"], interactions: ["Warfarin — slight increase in bleeding risk","Aspirin — additive bleeding risk","Blood pressure meds — may enhance BP-lowering effect"], foodInt: ["Take with meals to reduce fishy aftertaste and improve absorption"], desc: "Omega-3 fatty acids for heart health, triglyceride reduction, and anti-inflammatory benefits.", otc: true)

        add("Magnesium", brands: ["Mag-Tab","SlowMag","Natural Calm"], cat: .vitamins, therapeutic: "Mineral Supplement", active: "Magnesium Citrate / Oxide / Glycinate", forms: [.tablet,.capsule,.powder], dosages: ["200mg","250mg","400mg","500mg"], defDose: "400", defUnit: "mg", freq: .daily, warnings: ["May cause loose stools (especially oxide form)","Reduce dose in kidney disease","Glycinate form is gentler on stomach"], sides: ["Diarrhea","Nausea","Stomach cramps"], interactions: ["Bisphosphonates — take 2 hours apart","Antibiotics — take 2 hours apart","Diuretics — may worsen magnesium loss"], foodInt: ["Take with food to reduce stomach upset"], desc: "Essential mineral for muscle function, sleep, heart rhythm, and blood sugar control.", otc: true)

        add("Vitamin C", brands: ["Ascorbic Acid","Celin","Limcee","Ester-C","Redoxon"], cat: .vitamins, therapeutic: "Vitamin Supplement", active: "Ascorbic Acid", forms: [.tablet,.capsule,.powder,.drops], dosages: ["250mg","500mg","1000mg","2000mg"], defDose: "500", defUnit: "mg", freq: .daily, warnings: ["High doses (>2000mg) may cause kidney stones","May interfere with certain lab tests","Excess is excreted in urine"], sides: ["Nausea (high doses)","Diarrhea","Heartburn","Kidney stones (excess)"], interactions: ["Iron supplements — vitamin C enhances iron absorption","Warfarin — high doses may reduce warfarin effect","Aspirin — may increase aspirin levels"], foodInt: ["Can be taken with or without food","Enhances iron absorption when taken together"], desc: "Antioxidant vitamin essential for immune function, collagen synthesis, and wound healing.", otc: true)

        add("Zinc", brands: ["Zincovit","Zincofer","Zinc Picolinate","Zinconia"], cat: .vitamins, therapeutic: "Mineral Supplement", active: "Zinc Sulfate / Zinc Gluconate / Zinc Picolinate", forms: [.tablet,.capsule,.liquid], dosages: ["10mg","15mg","25mg","50mg"], defDose: "15", defUnit: "mg", freq: .daily, warnings: ["Do not exceed 40mg/day long-term","Take with food to reduce nausea","Long-term high doses can cause copper deficiency"], sides: ["Nausea","Metallic taste","Stomach pain","Headache"], interactions: ["Antibiotics (quinolones, tetracyclines) — take 2 hours apart","Penicillamine — reduced absorption","Copper supplements — zinc reduces copper absorption"], foodInt: ["Take with food to reduce nausea","Avoid taking with high-fiber foods or dairy"], desc: "Essential trace mineral for immune function, wound healing, taste/smell, and testosterone production.", otc: true)

        add("Multivitamin", brands: ["Centrum","One-A-Day","Supradyn","Becosules","Zincovit","A to Z"], cat: .vitamins, therapeutic: "Multivitamin/Multimineral", active: "Multiple Vitamins and Minerals", forms: [.tablet,.capsule], dosages: ["1 tablet"], defDose: "1", defUnit: "tablet", freq: .daily, warnings: ["Do not take with other single vitamin supplements without checking doses","Keep away from children (iron toxicity risk)","Choose age/gender-appropriate formula"], sides: ["Nausea","Constipation","Dark stools (from iron)","Stomach upset"], interactions: ["Levothyroxine — take 4 hours apart","Antibiotics — take 2 hours apart (calcium, iron, zinc interfere)","Warfarin — vitamin K content may affect INR"], foodInt: ["Take with meals for better absorption and to reduce nausea"], desc: "Complete vitamin and mineral supplement for daily nutritional insurance.", otc: true)

        add("Biotin", brands: ["Biotin","Hairburst","Natrol Biotin"], cat: .vitamins, therapeutic: "B-Vitamin Supplement", active: "Biotin (Vitamin B7)", forms: [.tablet,.capsule], dosages: ["1000mcg","2500mcg","5000mcg","10000mcg"], defDose: "5000", defUnit: "mcg", freq: .daily, warnings: ["High doses can interfere with lab tests (thyroid, troponin)","Stop 72 hours before blood tests","Water-soluble — excess excreted"], sides: ["Very rare — extremely safe","May cause breakouts in some people"], interactions: ["Lab test interference — falsely abnormal thyroid and cardiac biomarker results","Anticonvulsants — may reduce biotin levels"], foodInt: ["Can be taken with or without food"], desc: "B-vitamin for hair, skin, and nail health. Popular supplement for hair growth.", otc: true)

        add("Probiotics", brands: ["Culturelle","Yakult","VSL#3","Econorm","Vizylac","Bifilac"], cat: .vitamins, therapeutic: "Probiotic Supplement", active: "Lactobacillus / Bifidobacterium / Saccharomyces", forms: [.capsule,.powder,.liquid], dosages: ["1 billion CFU","5 billion CFU","10 billion CFU","50 billion CFU"], defDose: "10", defUnit: "billion CFU", freq: .daily, warnings: ["Refrigerate if required","Start with lower dose to reduce gas","Immunocompromised patients should consult doctor"], sides: ["Gas","Bloating (initial)","Mild stomach discomfort"], interactions: ["Antibiotics — take 2 hours apart to avoid killing probiotics","Immunosuppressants — risk of probiotic infection in immunocompromised"], foodInt: ["Take with or just before meals for best survival through stomach acid"], desc: "Live beneficial bacteria for gut health, digestion, immunity, and antibiotic-associated diarrhea prevention.", otc: true)

        add("Whey Protein", brands: ["Optimum Nutrition","MyProtein","Dymatize","MuscleBlaze","ON Gold Standard"], cat: .vitamins, therapeutic: "Protein Supplement", active: "Whey Protein Isolate / Concentrate", forms: [.powder,.liquid], dosages: ["25g","30g","40g","50g"], defDose: "30", defUnit: "g", freq: .daily, warnings: ["Check for lactose intolerance","Excess protein stresses kidneys in renal disease","Choose isolate for lower lactose"], sides: ["Bloating","Gas","Stomach cramps (lactose)","Acne (some individuals)"], interactions: ["Levodopa — protein may reduce absorption","Antibiotics (tetracycline) — calcium in whey may reduce absorption"], foodInt: ["Mix with water or milk","Best taken post-workout or between meals"], desc: "Fast-absorbing protein supplement for muscle recovery, growth, and daily protein intake.", otc: true)

        add("Creatine Monohydrate", brands: ["Optimum Nutrition","MuscleTech","MyProtein","Creapure","MuscleBlaze"], cat: .vitamins, therapeutic: "Sports Supplement", active: "Creatine Monohydrate", forms: [.powder,.capsule,.tablet], dosages: ["3g","5g","10g"], defDose: "5", defUnit: "g", freq: .daily, warnings: ["Stay well hydrated","Loading phase optional (20g/day for 5 days)","Safe for long-term use at recommended doses"], sides: ["Water retention","Weight gain (water)","Stomach cramps (if not enough water)","Bloating initially"], interactions: ["NSAIDs — theoretical increased kidney stress","Caffeine — may slightly reduce creatine benefits","Diuretics — increased dehydration risk"], foodInt: ["Take with carbohydrate-rich meal for better absorption","Mix in water or juice"], desc: "Most researched sports supplement. Increases strength, power, and muscle mass. Safe for long-term use.", otc: true)

        add("BCAA", brands: ["Xtend","MyProtein BCAA","Scivation","MusclePharm"], cat: .vitamins, therapeutic: "Amino Acid Supplement", active: "L-Leucine / L-Isoleucine / L-Valine", forms: [.powder,.capsule,.tablet], dosages: ["5g","7g","10g"], defDose: "5", defUnit: "g", freq: .daily, warnings: ["Unnecessary if protein intake is adequate","May affect blood sugar levels","Maple Syrup Urine Disease — contraindicated"], sides: ["Nausea (high doses)","Fatigue","Loss of coordination (excess)"], interactions: ["Levodopa — BCAAs may reduce effectiveness","Diabetes medications — may alter blood sugar","Thyroid medications — may interfere"], foodInt: ["Take before, during, or after workout","Can take on empty stomach"], desc: "Branched-chain amino acids for muscle recovery and reducing exercise fatigue.", otc: true)

        add("Electrolyte Supplement", brands: ["Dioralyte","O.R.S.","SIS Go","Nuun","Pedialyte","Enerzal"], cat: .vitamins, therapeutic: "Electrolyte Replacement", active: "Sodium / Potassium / Magnesium / Chloride", forms: [.powder,.tablet,.liquid], dosages: ["1 sachet","1 tablet"], defDose: "1", defUnit: "sachet", freq: .asNeeded, warnings: ["Essential during illness with diarrhea/vomiting","Monitor sodium in heart/kidney disease","Do not exceed recommended dose"], sides: ["Nausea (if too concentrated)","Metallic taste"], interactions: ["ACE inhibitors — hyperkalemia risk with potassium","Diuretics — may need electrolyte replacement","Lithium — sodium affects lithium levels"], foodInt: ["Dissolve in water as directed","Sip frequently rather than gulping"], desc: "Oral rehydration for dehydration from illness, sport, or heat. NHS recommended for gastroenteritis.", otc: true)

        add("Glucosamine", brands: ["Flexadin","Jointace","Osteo Bi-Flex","Regoflex"], cat: .vitamins, therapeutic: "Joint Supplement", active: "Glucosamine Sulfate / Hydrochloride", forms: [.tablet,.capsule,.powder,.liquid], dosages: ["500mg","750mg","1500mg"], defDose: "1500", defUnit: "mg", freq: .daily, warnings: ["Shellfish allergy — check source","May take 4-8 weeks to show benefits","Monitor blood sugar in diabetics"], sides: ["Nausea","Heartburn","Diarrhea","Constipation"], interactions: ["Warfarin — may increase bleeding risk","Diabetes medications — may increase blood sugar","Paracetamol — may reduce glucosamine absorption"], foodInt: ["Take with food to reduce GI side effects"], desc: "Joint health supplement for osteoarthritis. May reduce cartilage breakdown and joint pain.", otc: true)

        add("Collagen Peptides", brands: ["Vital Proteins","Great Lakes","MyProtein Collagen","Revive"], cat: .vitamins, therapeutic: "Protein Supplement", active: "Hydrolyzed Collagen Peptides", forms: [.powder,.capsule,.liquid], dosages: ["5g","10g","15g","20g"], defDose: "10", defUnit: "g", freq: .daily, warnings: ["Source matters — bovine, marine, or chicken","May take 8-12 weeks for visible benefits","Check for allergens"], sides: ["Mild digestive discomfort","Feeling of fullness","Bad taste (some brands)"], interactions: ["No significant drug interactions known","May enhance calcium absorption"], foodInt: ["Mix into hot or cold beverages","Can be added to food"], desc: "Protein supplement for skin elasticity, joint health, hair, nails, and gut lining support.", otc: true)

        add("Caffeine Tablets", brands: ["Pro Plus","No-Doz","Vivarin","Boots Caffeine"], cat: .vitamins, therapeutic: "Stimulant Supplement", active: "Caffeine Anhydrous", forms: [.tablet], dosages: ["50mg","100mg","200mg"], defDose: "200", defUnit: "mg", freq: .asNeeded, warnings: ["Do not exceed 400mg/day","Avoid after 2pm to protect sleep","May cause anxiety and palpitations"], sides: ["Anxiety","Insomnia","Heart palpitations","Restlessness","Stomach upset","Dependency"], interactions: ["Adenosine — caffeine blocks adenosine effect","Bronchodilators — additive stimulant effects","Lithium — caffeine withdrawal increases lithium levels"], foodInt: ["Can be taken with or without food","Avoid combining with other caffeine sources"], desc: "Concentrated caffeine for alertness and exercise performance. Common pre-workout supplement.", otc: true)

        // ═══════════════════════════════════════
        // MARK: - UK Pharmacy Essentials
        // ═══════════════════════════════════════

        add("Co-codamol", brands: ["Solpadol","Kapake","Zapain","Codipar","Boots Co-codamol"], cat: .painRelief, therapeutic: "Combination Analgesic", active: "Paracetamol + Codeine Phosphate", forms: [.tablet,.capsule], dosages: ["8/500mg","15/500mg","30/500mg"], defDose: "30/500", defUnit: "mg", freq: .thrice, warnings: ["Do not take with other paracetamol products","Risk of dependency — short-term use only","Constipation is very common"], sides: ["Constipation","Drowsiness","Nausea","Dizziness","Dependency"], interactions: ["Alcohol — enhanced sedation and liver risk","Other opioids — respiratory depression","MAO inhibitors — dangerous interaction"], foodInt: ["Take with or after food"], desc: "UK prescription combination painkiller. 8/500 available OTC, 30/500 prescription only (POM).", otc: false)

        add("Co-dydramol", brands: ["Remedeine","Paramol"], cat: .painRelief, therapeutic: "Combination Analgesic", active: "Paracetamol + Dihydrocodeine", forms: [.tablet], dosages: ["10/500mg","20/500mg","30/500mg"], defDose: "10/500", defUnit: "mg", freq: .thrice, warnings: ["Do not exceed 8 tablets in 24 hours","Risk of dependency","Do not combine with other paracetamol"], sides: ["Constipation","Drowsiness","Nausea","Dizziness"], interactions: ["Alcohol — enhanced sedation","CNS depressants — additive effects","MAO inhibitors — avoid"], foodInt: ["Take with or after food"], desc: "UK combination painkiller for moderate pain. Stronger than co-codamol at equivalent doses.", otc: false)

        add("Naproxen", brands: ["Naprosyn","Aleve","Naprogesic","Feminax Ultra","Boots Period Pain"], cat: .painRelief, therapeutic: "NSAID", active: "Naproxen Sodium", forms: [.tablet], dosages: ["250mg","375mg","500mg"], defDose: "500", defUnit: "mg", freq: .twice, warnings: ["Take with food — GI bleed risk","Avoid in heart failure and kidney disease","Lowest dose for shortest time"], sides: ["Stomach pain","Nausea","Heartburn","Headache","Dizziness","GI bleeding"], interactions: ["Warfarin — increased bleeding risk","Aspirin — reduced cardioprotection","ACE inhibitors — reduced effect and kidney risk","SSRIs — increased GI bleeding"], foodInt: ["Always take with food or milk","Avoid alcohol"], desc: "Long-acting NSAID for arthritis, period pain, gout, and musculoskeletal pain. Twice daily dosing.", otc: true)

        add("Mebeverine", brands: ["Colofac","Colofac IBS","Boots IBS Relief"], cat: .gastrointestinal, therapeutic: "Antispasmodic", active: "Mebeverine Hydrochloride", forms: [.tablet], dosages: ["135mg","200mg MR"], defDose: "135", defUnit: "mg", freq: .thrice, warnings: ["Take 20 minutes before meals","Safe for long-term use","First-line IBS treatment in UK"], sides: ["Very few — well tolerated","Rare: rash, swelling"], interactions: ["Very few drug interactions","Safe to combine with other IBS treatments"], foodInt: ["Take 20 minutes before meals for best effect"], desc: "Antispasmodic for IBS (irritable bowel syndrome). First-line NHS treatment. Very well tolerated.", otc: true)

        add("Buscopan", brands: ["Buscopan","Buscopan IBS Relief"], cat: .gastrointestinal, therapeutic: "Antispasmodic (Anticholinergic)", active: "Hyoscine Butylbromide", forms: [.tablet], dosages: ["10mg","20mg"], defDose: "10", defUnit: "mg", freq: .thrice, warnings: ["May cause dry mouth","Avoid in glaucoma","Do not chew tablets"], sides: ["Dry mouth","Blurred vision","Constipation","Tachycardia"], interactions: ["Anticholinergics — additive effects","Metoclopramide — opposing effects on GI motility"], foodInt: ["Can be taken with or without food"], desc: "Antispasmodic for stomach cramps, period pain, and IBS. UK pharmacy staple.", otc: true)

        add("Loperamide", brands: ["Imodium","Imodium Instants","Boots Diarrhoea Relief","Norimode"], cat: .gastrointestinal, therapeutic: "Antidiarrheal", active: "Loperamide Hydrochloride", forms: [.capsule,.tablet,.liquid], dosages: ["2mg"], defDose: "2", defUnit: "mg", freq: .asNeeded, warnings: ["Do not exceed 16mg/day","Not for bloody diarrhea or fever","Rehydrate with ORS alongside"], sides: ["Constipation","Stomach cramps","Bloating","Nausea","Dizziness"], interactions: ["Ritonavir — increased loperamide levels","Quinidine — increased loperamide levels","Opioids — additive constipation"], foodInt: ["Can be taken with or without food","Ensure adequate fluid intake"], desc: "Stops diarrhea by slowing gut movement. Take after each loose stool. UK pharmacy essential.", otc: true)

        add("Gaviscon", brands: ["Gaviscon","Gaviscon Advance","Gaviscon Double Action"], cat: .gastrointestinal, therapeutic: "Alginate Antacid", active: "Sodium Alginate + Sodium Bicarbonate", forms: [.liquid,.tablet], dosages: ["5mL","10mL","15mL","20mL"], defDose: "10", defUnit: "mL", freq: .asNeeded, warnings: ["High sodium content — caution in heart failure and hypertension","Do not take with other antacids","Shake well before use"], sides: ["Very few — mild nausea","Bloating"], interactions: ["Reduces absorption of many drugs — take 2 hours apart","Particularly affects: levothyroxine, iron, antibiotics"], foodInt: ["Take after meals and before bed","Do not take with other medications"], desc: "UK's most popular heartburn remedy. Forms a raft on stomach acid to prevent reflux.", otc: true)

        add("Chlorphenamine", brands: ["Piriton","Boots Allergy Relief","Pollenase"], cat: .allergy, therapeutic: "First-gen Antihistamine", active: "Chlorphenamine Maleate", forms: [.tablet,.liquid], dosages: ["4mg"], defDose: "4", defUnit: "mg", freq: .thrice, warnings: ["Causes drowsiness — do not drive","Avoid alcohol","Used in anaphylaxis (injection form in hospitals)"], sides: ["Drowsiness","Dry mouth","Blurred vision","Urinary retention","GI upset"], interactions: ["Alcohol — severe drowsiness","CNS depressants — additive sedation","MAO inhibitors — prolonged anticholinergic effects"], foodInt: ["Can be taken with or without food"], desc: "UK's classic antihistamine (Piriton). Sedating — useful for itchy allergic reactions and urticaria.", otc: true)

        add("Cyclizine", brands: ["Valoid","Boots Travel Sickness"], cat: .gastrointestinal, therapeutic: "Antiemetic / Antihistamine", active: "Cyclizine Hydrochloride", forms: [.tablet,.injection], dosages: ["50mg"], defDose: "50", defUnit: "mg", freq: .thrice, warnings: ["Causes drowsiness","Avoid in severe heart failure","Commonly used in palliative care"], sides: ["Drowsiness","Dry mouth","Blurred vision","Constipation"], interactions: ["Opioids — commonly combined but additive sedation","CNS depressants — enhanced effects","Anticholinergics — additive effects"], foodInt: ["Take 30 minutes before travel for motion sickness"], desc: "Anti-sickness tablet for travel sickness, vertigo, and post-operative nausea. UK pharmacy staple.", otc: true)

        add("Senna", brands: ["Senokot","Senokot Max","Boots Senna","Manevac"], cat: .gastrointestinal, therapeutic: "Stimulant Laxative", active: "Sennosides A & B", forms: [.tablet,.liquid], dosages: ["7.5mg","15mg"], defDose: "15", defUnit: "mg", freq: .daily, warnings: ["Take at bedtime — works in 8-12 hours","Short-term use only","Do not use if bowel obstruction suspected"], sides: ["Stomach cramps","Diarrhea","Urine discoloration","Electrolyte imbalance (prolonged use)"], interactions: ["Digoxin — potassium loss may increase toxicity","Diuretics — additive potassium loss","Warfarin — diarrhea may alter absorption"], foodInt: ["Take at bedtime with water"], desc: "Natural stimulant laxative for constipation relief. Works overnight. UK pharmacy standard.", otc: true)

        add("Lactulose", brands: ["Duphalac","Lactugal","Boots Lactulose"], cat: .gastrointestinal, therapeutic: "Osmotic Laxative", active: "Lactulose", forms: [.liquid], dosages: ["10mL","15mL","20mL","30mL"], defDose: "15", defUnit: "mL", freq: .twice, warnings: ["May take 48 hours to work","Causes bloating initially","Safe for long-term use","Also used for hepatic encephalopathy"], sides: ["Flatulence","Bloating","Abdominal cramps","Nausea"], interactions: ["Very few interactions","Antacids — may reduce lactulose effect"], foodInt: ["Can be taken with or without food","Mix with water or juice if desired"], desc: "Gentle osmotic laxative safe for long-term use. First-line NHS laxative. Takes 2-3 days to work.", otc: true)

        add("Macrogol", brands: ["Laxido","Movicol","CosmoCol","Boots Macrogol"], cat: .gastrointestinal, therapeutic: "Osmotic Laxative", active: "Macrogol 3350 + Electrolytes", forms: [.powder], dosages: ["1 sachet","2 sachets","8 sachets (disimpaction)"], defDose: "1", defUnit: "sachet", freq: .daily, warnings: ["Dissolve fully in water before drinking","Can be used for faecal impaction at higher doses","Safe for long-term use"], sides: ["Bloating","Abdominal pain","Nausea","Diarrhea (excess dose)"], interactions: ["May speed transit of other oral drugs — affecting absorption","Take other medications 1 hour before or after"], foodInt: ["Dissolve in 125mL water","Can be taken at any time"], desc: "NHS first-line laxative for chronic constipation and faecal impaction. Safe and effective.", otc: true)

        add("Lansoprazole", brands: ["Zoton","Prevacid","Boots Acid Reflux"], cat: .gastrointestinal, therapeutic: "Proton Pump Inhibitor", active: "Lansoprazole", forms: [.capsule,.tablet], dosages: ["15mg","30mg"], defDose: "30", defUnit: "mg", freq: .daily, warnings: ["Take 30 minutes before food","Long-term use: monitor magnesium and B12","NHS commonly prescribed PPI"], sides: ["Headache","Nausea","Diarrhea","Stomach pain","Dizziness"], interactions: ["Clopidogrel — less interaction than omeprazole","Methotrexate — increased toxicity risk","St John's Wort — reduced lansoprazole effect"], foodInt: ["Take 30 minutes before breakfast"], desc: "PPI for acid reflux, GERD, and stomach ulcers. Second most prescribed PPI on NHS.", otc: true)

        add("Sumatriptan", brands: ["Imigran","Boots Migraine Relief","Treximet"], cat: .neurological, therapeutic: "Triptan (5-HT1 Agonist)", active: "Sumatriptan Succinate", forms: [.tablet,.injection,.liquid], dosages: ["50mg","100mg","6mg injection"], defDose: "50", defUnit: "mg", freq: .asNeeded, warnings: ["Not for prevention — acute treatment only","Do not use within 24 hours of other triptans or ergotamines","Avoid in uncontrolled hypertension or heart disease"], sides: ["Tingling","Warm sensation","Chest tightness","Drowsiness","Dizziness"], interactions: ["SSRIs/SNRIs — serotonin syndrome risk","Ergotamines — vasospasm risk (wait 24 hours)","MAO inhibitors — contraindicated"], foodInt: ["Can be taken with or without food"], desc: "Migraine-specific painkiller. Relieves headache, nausea, and light sensitivity. Available OTC in UK.", otc: true)

        add("Metoclopramide", brands: ["Maxolon","Primperan"], cat: .gastrointestinal, therapeutic: "Dopamine Antagonist Antiemetic", active: "Metoclopramide Hydrochloride", forms: [.tablet,.liquid,.injection], dosages: ["5mg","10mg"], defDose: "10", defUnit: "mg", freq: .thrice, warnings: ["Max 5 days use — risk of movement disorders","Not for under 18s (UK restriction)","Avoid in epilepsy and Parkinson's"], sides: ["Drowsiness","Restlessness","Diarrhea","Movement disorders (tardive dyskinesia)"], interactions: ["Levodopa — opposing effects","Opioids — opposing GI effects but used together for nausea","SSRIs — serotonin syndrome risk"], foodInt: ["Take 30 minutes before meals"], desc: "Anti-sickness medicine that also speeds gastric emptying. Short-term use only per NHS guidelines.", otc: false)

        add("Domperidone", brands: ["Motilium","Boots Anti-Sickness"], cat: .gastrointestinal, therapeutic: "Dopamine Antagonist Antiemetic", active: "Domperidone", forms: [.tablet], dosages: ["10mg"], defDose: "10", defUnit: "mg", freq: .thrice, warnings: ["Use lowest dose for shortest time","Cardiac arrhythmia risk — ECG monitoring may be needed","Not for long-term use"], sides: ["Dry mouth","Headache","Diarrhea","QT prolongation (rare)","Breast enlargement/galactorrhea"], interactions: ["QT-prolonging drugs — additive cardiac risk","CYP3A4 inhibitors — increased levels","Ketoconazole — contraindicated"], foodInt: ["Take 15-30 minutes before meals"], desc: "Anti-sickness medicine. Does not cross blood-brain barrier well — fewer neurological side effects.", otc: true)

        add("Prednisolone", brands: ["Deltacortril","Pevanti","Boots Prednisolone"], cat: .antiInflammatory, therapeutic: "Corticosteroid", active: "Prednisolone", forms: [.tablet,.liquid], dosages: ["1mg","2.5mg","5mg","10mg","20mg","25mg"], defDose: "5", defUnit: "mg", freq: .daily, warnings: ["Do not stop abruptly after long-term use","Take in the morning with food","Carry a steroid card if on long-term","Increased infection risk"], sides: ["Weight gain","Mood changes","Insomnia","Increased appetite","Thinning skin","Osteoporosis (long-term)","Diabetes risk"], interactions: ["NSAIDs — increased GI bleeding risk","Diabetes medications — may need dose increase","Warfarin — altered effect","Live vaccines — contraindicated"], foodInt: ["Take with breakfast to reduce stomach irritation and mimic natural cortisol rhythm"], desc: "Most commonly prescribed oral steroid on NHS. For asthma attacks, inflammatory conditions, and autoimmune diseases.", otc: false)

        add("Trimethoprim", brands: ["Monotrim","Trimopan","Boots UTI Relief"], cat: .antibiotics, therapeutic: "Dihydrofolate Reductase Inhibitor", active: "Trimethoprim", forms: [.tablet,.liquid], dosages: ["100mg","200mg"], defDose: "200", defUnit: "mg", freq: .twice, warnings: ["3-day course for uncomplicated UTI (women)","Monitor blood counts in long-term use","Avoid in folate deficiency"], sides: ["Nausea","Rash","Itching","Headache","Blood disorders (rare)"], interactions: ["Methotrexate — increased toxicity (both are folate antagonists)","Warfarin — increased bleeding risk","ACE inhibitors — hyperkalemia risk","Phenytoin — increased phenytoin levels"], foodInt: ["Can be taken with or without food"], desc: "First-line NHS antibiotic for uncomplicated urinary tract infections. 3-day course standard.", otc: false)

        add("Nitrofurantoin", brands: ["Macrobid","Macrodantin","Furadantin"], cat: .antibiotics, therapeutic: "Nitrofuran Antibiotic", active: "Nitrofurantoin", forms: [.capsule,.tablet,.liquid], dosages: ["50mg","100mg MR"], defDose: "100", defUnit: "mg", freq: .twice, warnings: ["Take with food — improves absorption and reduces nausea","Avoid in severe kidney disease (eGFR <45)","Urine may turn brown/dark — this is normal"], sides: ["Nausea","Headache","Dark urine","Loss of appetite","Lung reactions (rare, long-term)"], interactions: ["Antacids with magnesium — reduced absorption","Probenecid — increased nitrofurantoin levels","Warfarin — monitor INR"], foodInt: ["Must take with food for proper absorption"], desc: "UK second-line UTI antibiotic. Well suited for lower urinary tract infections. Urine turns dark.", otc: false)

        add("Flucloxacillin", brands: ["Floxapen","Fluclomix","Ladropen"], cat: .antibiotics, therapeutic: "Penicillinase-Resistant Penicillin", active: "Flucloxacillin Sodium", forms: [.capsule,.liquid,.injection], dosages: ["250mg","500mg","1g"], defDose: "500", defUnit: "mg", freq: .thrice, warnings: ["Take on empty stomach (1 hour before food)","Penicillin allergy — do not use","Risk of cholestatic jaundice — inform doctor if yellowing"], sides: ["Nausea","Diarrhea","Rash","Cholestatic jaundice (rare)","Stomach pain"], interactions: ["Warfarin — monitor INR","Methotrexate — reduced excretion","Oral contraceptives — historically debated, now considered safe"], foodInt: ["Take on empty stomach — 1 hour before or 2 hours after food"], desc: "NHS first-line antibiotic for skin and soft tissue infections (cellulitis, impetigo, wound infections).", otc: false)

        add("Phenoxymethylpenicillin", brands: ["Penicillin V","Penicillin VK"], cat: .antibiotics, therapeutic: "Penicillin Antibiotic", active: "Phenoxymethylpenicillin", forms: [.tablet,.liquid], dosages: ["250mg","500mg"], defDose: "500", defUnit: "mg", freq: .thrice, warnings: ["Take on empty stomach","Complete the full course","Penicillin allergy — do not use"], sides: ["Nausea","Diarrhea","Rash","Candidiasis"], interactions: ["Warfarin — monitor INR","Methotrexate — reduced excretion"], foodInt: ["Take on empty stomach — 1 hour before food"], desc: "Classic penicillin for sore throat (strep), dental infections, and rheumatic fever prevention on NHS.", otc: false)

        add("Emollients", brands: ["Diprobase","E45","Cetraben","Doublebase","Aveeno","Epaderm"], cat: .skinCare, therapeutic: "Moisturiser / Emollient", active: "White Soft Paraffin + Liquid Paraffin", forms: [.topical], dosages: ["Apply liberally"], defDose: "1", defUnit: "application", freq: .thrice, warnings: ["Fire hazard — do not smoke or use near naked flames","Apply 30 min before steroid creams","Use liberally and frequently"], sides: ["Very safe","Rare: folliculitis if applied too thickly"], interactions: ["Apply before topical steroids (wait 30 min)"], foodInt: [], desc: "NHS prescribed moisturisers for eczema, dry skin, and psoriasis. Use as soap substitute too.", otc: true)

        add("Dermol", brands: ["Dermol 500","Dermol Wash","Dermol Cream"], cat: .skinCare, therapeutic: "Antimicrobial Emollient", active: "Benzalkonium Chloride + Liquid Paraffin + Isopropyl Myristate", forms: [.topical,.liquid], dosages: ["Apply as needed"], defDose: "1", defUnit: "application", freq: .twice, warnings: ["For external use only","Can be used as soap substitute","Avoid contact with eyes"], sides: ["Very rare — mild skin irritation"], interactions: ["No significant interactions"], foodInt: [], desc: "NHS antimicrobial moisturiser and wash for eczema-prone skin with bacterial colonisation.", otc: true)

        add("Solpadeine", brands: ["Solpadeine Plus","Solpadeine Max","Solpadeine Headache"], cat: .painRelief, therapeutic: "Combination Analgesic", active: "Paracetamol + Codeine + Caffeine", forms: [.tablet,.capsule], dosages: ["500/8/30mg","500/12.8/30mg"], defDose: "500/8/30", defUnit: "mg", freq: .thrice, warnings: ["OTC but contains codeine — dependency risk","Do not take with other paracetamol products","Max 3 days for headache to avoid medication-overuse headache"], sides: ["Constipation","Drowsiness","Nausea","Dizziness","Dependency"], interactions: ["Alcohol — enhanced sedation","Other paracetamol products — overdose risk","CNS depressants — additive effects"], foodInt: ["Take with or after food"], desc: "Popular UK OTC painkiller with paracetamol, codeine and caffeine for headaches and pain.", otc: true)

        add("Nurofen Plus", brands: ["Nurofen Plus"], cat: .painRelief, therapeutic: "Combination NSAID + Opioid", active: "Ibuprofen 200mg + Codeine 12.8mg", forms: [.tablet], dosages: ["200/12.8mg"], defDose: "200/12.8", defUnit: "mg", freq: .thrice, warnings: ["Max 3 days use without medical advice","Dependency risk from codeine","Take with food — NSAID stomach risk"], sides: ["Stomach pain","Nausea","Constipation","Drowsiness","Headache"], interactions: ["Aspirin — do not combine NSAIDs","Warfarin — increased bleeding","Other opioids — respiratory depression"], foodInt: ["Take with or after food"], desc: "UK pharmacy painkiller combining ibuprofen with codeine for moderate pain. Short-term use only.", otc: true)

        add("Anusol", brands: ["Anusol","Anusol HC","Germoloids","Preparation H"], cat: .gastrointestinal, therapeutic: "Hemorrhoid Treatment", active: "Zinc Oxide + Bismuth Subgallate + Hydrocortisone (HC)", forms: [.topical,.suppository], dosages: ["Apply 2-3 times daily"], defDose: "1", defUnit: "application", freq: .thrice, warnings: ["HC version: max 7 days use","Keep area clean and dry","See GP if bleeding persists"], sides: ["Mild stinging on application","Skin thinning (HC version with prolonged use)"], interactions: ["No significant systemic interactions"], foodInt: [], desc: "UK pharmacy standard for haemorrhoids. Soothes, protects, and reduces swelling.", otc: true)

        add("Canesten", brands: ["Canesten","Canesten Duo","Canesten Oral","Boots Thrush"], cat: .skinCare, therapeutic: "Antifungal", active: "Clotrimazole / Fluconazole (oral)", forms: [.topical,.tablet], dosages: ["1% cream","2% cream","500mg pessary","150mg oral"], defDose: "1", defUnit: "%", freq: .daily, warnings: ["Complete the full course","Internal cream for vaginal thrush","Oral capsule: single dose"], sides: ["Mild burning","Itching","Rash","Nausea (oral form)"], interactions: ["Oral fluconazole: warfarin — increased bleeding risk","Oral: statins — increased myopathy risk","Topical: may damage latex condoms"], foodInt: ["Oral capsule can be taken with or without food"], desc: "UK's most popular antifungal for thrush (vaginal and skin). Cream, pessary, and oral capsule.", otc: true)

        // ═══════════════════════════════════════
        // MARK: - Dermatological
        // ═══════════════════════════════════════

        add("Hydrocortisone Cream", brands: ["Cortizone-10","Cortaid","HC45"], cat: .skinCare, therapeutic: "Mild Topical Corticosteroid", active: "Hydrocortisone", forms: [.topical], dosages: ["0.5%","1%","2.5%"], defDose: "1", defUnit: "%", freq: .twice, warnings: ["Do not use on face for more than 7 days","Not for infected skin","Thin skin areas: use sparingly"], sides: ["Skin thinning","Stretch marks (prolonged use)","Burning","Itching"], interactions: ["Few systemic interactions with topical use"], foodInt: [], desc: "Mild steroid cream for eczema, dermatitis, insect bites, and skin irritation.", otc: true)

        add("Betamethasone", brands: ["Betnovate","Diprosone","Celestoderm"], cat: .skinCare, therapeutic: "Potent Topical Corticosteroid", active: "Betamethasone Valerate", forms: [.topical], dosages: ["0.025%","0.05%","0.1%"], defDose: "0.1", defUnit: "%", freq: .twice, warnings: ["Do not use on face","Short-term use only","Do not use under occlusive dressings without medical advice"], sides: ["Skin thinning","Stretch marks","Folliculitis","Skin discoloration"], interactions: ["Few systemic interactions"], foodInt: [], desc: "Potent steroid cream for severe eczema, psoriasis, and inflammatory skin conditions.", otc: false)

        add("Tretinoin", brands: ["Retin-A","Retino-A","Stieva-A"], cat: .skinCare, therapeutic: "Retinoid", active: "Tretinoin", forms: [.topical], dosages: ["0.025%","0.05%","0.1%"], defDose: "0.025", defUnit: "%", freq: .daily, warnings: ["Apply at bedtime — increases sun sensitivity","Initial worsening is normal (purging)","Not for use in pregnancy"], sides: ["Dryness","Peeling","Redness","Burning","Sun sensitivity"], interactions: ["Other drying agents — increased irritation","Benzoyl peroxide — may inactivate tretinoin"], foodInt: [], desc: "Vitamin A derivative for acne, fine wrinkles, and skin aging. Apply at night with sunscreen daily.", otc: false)

        add("Benzoyl Peroxide", brands: ["Benzac","PanOxyl","Clearasil"], cat: .skinCare, therapeutic: "Acne Agent", active: "Benzoyl Peroxide", forms: [.topical], dosages: ["2.5%","5%","10%"], defDose: "5", defUnit: "%", freq: .daily, warnings: ["Start low (2.5%) to reduce irritation","Bleaches fabrics and hair","May cause dryness and peeling initially"], sides: ["Dryness","Peeling","Redness","Burning","Bleaching of fabrics"], interactions: ["Tretinoin — may reduce each other's effectiveness","Dapsone — may cause temporary orange skin discoloration"], foodInt: [], desc: "Antibacterial acne treatment that kills acne-causing bacteria and unclogs pores.", otc: true)

        // ═══════════════════════════════════════
        // MARK: - Eye & Ear
        // ═══════════════════════════════════════

        add("Timolol Eye Drops", brands: ["Timoptic","Betimol","Istalol"], cat: .eyeEar, therapeutic: "Beta-Blocker (Ophthalmic)", active: "Timolol Maleate", forms: [.drops], dosages: ["0.25%","0.5%"], defDose: "0.5", defUnit: "%", freq: .twice, warnings: ["Can be absorbed systemically — avoid in asthma","May slow heart rate","Punctal occlusion reduces systemic absorption"], sides: ["Eye stinging","Blurred vision","Dry eyes","Slow heart rate","Fatigue"], interactions: ["Oral beta-blockers — additive effects","Calcium channel blockers — enhanced hypotension","Clonidine — rebound hypertension risk"], foodInt: [], desc: "Eye drops that lower eye pressure in glaucoma and ocular hypertension.", otc: false)

        add("Latanoprost", brands: ["Xalatan","Latoprost"], cat: .eyeEar, therapeutic: "Prostaglandin Analog (Ophthalmic)", active: "Latanoprost", forms: [.drops], dosages: ["0.005%"], defDose: "0.005", defUnit: "%", freq: .daily, warnings: ["Apply at bedtime","May permanently darken iris color","May increase eyelash growth"], sides: ["Eye redness","Stinging","Iris darkening","Increased eyelash growth","Blurred vision"], interactions: ["Thimerosal-containing eye drops — precipitate (wait 5 min)","Other prostaglandin eye drops — not recommended together"], foodInt: [], desc: "Once-daily eye drop for glaucoma. Most effective pressure-lowering eye drop class.", otc: false)

        add("Artificial Tears", brands: ["Systane","Refresh","TheraTears","Hylo"], cat: .eyeEar, therapeutic: "Ocular Lubricant", active: "Carboxymethylcellulose / Hyaluronic Acid", forms: [.drops], dosages: ["0.5%","1%"], defDose: "0.5", defUnit: "%", freq: .asNeeded, warnings: ["Preservative-free preferred for frequent use","Wait 5 min between different eye drops"], sides: ["Temporary blurred vision","Mild stinging"], interactions: ["Wait 5 minutes before applying other eye medications"], foodInt: [], desc: "Lubricating eye drops for dry eyes, screen fatigue, and contact lens dryness.", otc: true)

        // ═══════════════════════════════════════
        // MARK: - Musculoskeletal
        // ═══════════════════════════════════════

        add("Allopurinol", brands: ["Zyloprim","Zyloric","Allohexal"], cat: .musculoskeletal, therapeutic: "Xanthine Oxidase Inhibitor", active: "Allopurinol", forms: [.tablet], dosages: ["100mg","200mg","300mg"], defDose: "100", defUnit: "mg", freq: .daily, warnings: ["May trigger gout flare when starting — co-prescribe colchicine","Start low and titrate","Rash may indicate serious reaction — stop immediately"], sides: ["Gout flare (initially)","Rash","Nausea","Drowsiness"], interactions: ["Azathioprine — life-threatening toxicity (reduce azathioprine 75%)","Warfarin — increased bleeding","ACE inhibitors — increased hypersensitivity risk"], foodInt: ["Take after food to reduce stomach upset"], desc: "Lowers uric acid to prevent gout attacks and kidney stones. Takes weeks to reach full effect.", otc: false)

        add("Alendronate", brands: ["Fosamax","Binosto","Fosavance"], cat: .musculoskeletal, therapeutic: "Bisphosphonate", active: "Alendronic Acid", forms: [.tablet], dosages: ["10mg","35mg","70mg"], defDose: "70", defUnit: "mg", freq: .weekly, warnings: ["Take first thing in morning with full glass of water","Stay upright for 30 min — prevents esophageal irritation","Do not lie down after taking"], sides: ["Heartburn","Stomach pain","Nausea","Muscle pain","Jaw osteonecrosis (rare)"], interactions: ["Calcium/Iron — take at least 30 min apart","NSAIDs — increased GI irritation","Aspirin — increased GI side effects"], foodInt: ["Take on completely empty stomach with plain water only","Wait 30 min before any food, drink, or other medications"], desc: "Weekly tablet for osteoporosis prevention and treatment. Strengthens bones.", otc: false)

        add("Baclofen", brands: ["Lioresal","Gablofen"], cat: .musculoskeletal, therapeutic: "Muscle Relaxant (GABA-B Agonist)", active: "Baclofen", forms: [.tablet,.liquid], dosages: ["5mg","10mg","20mg","25mg"], defDose: "10", defUnit: "mg", freq: .thrice, warnings: ["Do not stop abruptly — withdrawal seizures","Start low and increase gradually","Causes drowsiness"], sides: ["Drowsiness","Dizziness","Weakness","Nausea","Confusion"], interactions: ["Alcohol — enhanced sedation","CNS depressants — additive effects","Antihypertensives — enhanced BP lowering"], foodInt: ["Take with food to reduce stomach upset"], desc: "Muscle relaxant for spasticity in MS, spinal cord injuries, and cerebral palsy.", otc: false)

        // ═══════════════════════════════════════
        // MARK: - Neurological
        // ═══════════════════════════════════════

        add("Levodopa-Carbidopa", brands: ["Sinemet","Madopar","Stalevo"], cat: .neurological, therapeutic: "Dopamine Precursor", active: "Levodopa + Carbidopa", forms: [.tablet], dosages: ["100/25mg","250/25mg","200/50mg"], defDose: "100/25", defUnit: "mg", freq: .thrice, warnings: ["Do not stop abruptly","May cause dyskinesia (involuntary movements)","Avoid high-protein meals near dose time"], sides: ["Nausea","Dizziness","Dyskinesia","Drowsiness","Dark urine"], interactions: ["MAO-B inhibitors — use cautiously","Iron supplements — reduced absorption","Antipsychotics — reduced levodopa effect"], foodInt: ["High-protein meals reduce absorption — take 30 min before meals","Distribute protein intake evenly through the day"], desc: "Gold standard treatment for Parkinson's disease. Replaces lost dopamine in the brain.", otc: false)

        add("Donepezil", brands: ["Aricept","Donep"], cat: .neurological, therapeutic: "Cholinesterase Inhibitor", active: "Donepezil Hydrochloride", forms: [.tablet], dosages: ["5mg","10mg","23mg"], defDose: "5", defUnit: "mg", freq: .daily, warnings: ["Take at bedtime","Start at 5mg for first 4-6 weeks","May cause vivid dreams"], sides: ["Nausea","Diarrhea","Insomnia","Vivid dreams","Muscle cramps"], interactions: ["Anticholinergics — opposing effects","Beta-blockers — enhanced bradycardia","NSAIDs — increased GI bleeding risk"], foodInt: ["Can be taken with or without food"], desc: "Slows cognitive decline in Alzheimer's disease by boosting acetylcholine in the brain.", otc: false)

        add("Carbamazepine", brands: ["Tegretol","Carbatrol","Equetro"], cat: .neurological, therapeutic: "Anticonvulsant / Mood Stabilizer", active: "Carbamazepine", forms: [.tablet,.liquid,.capsule], dosages: ["100mg","200mg","400mg"], defDose: "200", defUnit: "mg", freq: .twice, warnings: ["Regular blood count monitoring","HLA-B*1502 testing in certain ethnicities (SJS risk)","Many drug interactions — potent enzyme inducer"], sides: ["Drowsiness","Dizziness","Nausea","Blurred vision","Rash"], interactions: ["Oral contraceptives — reduced effectiveness","Warfarin — reduced effect","Many drugs affected by enzyme induction"], foodInt: ["Take with food to reduce stomach upset"], desc: "Anticonvulsant for epilepsy, trigeminal neuralgia, and bipolar disorder.", otc: false)

        add("Lamotrigine", brands: ["Lamictal","Lamotrin"], cat: .neurological, therapeutic: "Anticonvulsant / Mood Stabilizer", active: "Lamotrigine", forms: [.tablet], dosages: ["25mg","50mg","100mg","150mg","200mg"], defDose: "25", defUnit: "mg", freq: .daily, warnings: ["Very slow titration required — rash risk","Stop immediately if rash develops (SJS risk)","Dose changes needed with valproate or oral contraceptives"], sides: ["Headache","Dizziness","Nausea","Rash","Insomnia","Blurred vision"], interactions: ["Valproate — doubles lamotrigine levels (halve dose)","Carbamazepine — halves lamotrigine levels (double dose)","Oral contraceptives — mutual dose changes needed"], foodInt: ["Can be taken with or without food"], desc: "Anticonvulsant and mood stabilizer for epilepsy and bipolar depression. Requires very slow dose increases.", otc: false)

        add("Topiramate", brands: ["Topamax","Topamac"], cat: .neurological, therapeutic: "Anticonvulsant", active: "Topiramate", forms: [.tablet,.capsule], dosages: ["25mg","50mg","100mg","200mg"], defDose: "25", defUnit: "mg", freq: .twice, warnings: ["Drink plenty of water (kidney stone risk)","May impair thinking — cognitive side effects","Causes weight loss"], sides: ["Tingling","Weight loss","Cognitive dulling","Kidney stones","Taste changes"], interactions: ["Oral contraceptives — reduced effectiveness at >200mg","Valproate — hyperammonemia risk","Metformin — altered metformin levels"], foodInt: ["Can be taken with or without food","Stay well hydrated"], desc: "Anticonvulsant for epilepsy and migraine prevention. Also causes weight loss.", otc: false)

        add("Valproic Acid", brands: ["Depakote","Epilim","Convulex"], cat: .neurological, therapeutic: "Anticonvulsant / Mood Stabilizer", active: "Valproic Acid / Sodium Valproate", forms: [.tablet,.capsule,.liquid], dosages: ["200mg","250mg","500mg","1000mg"], defDose: "500", defUnit: "mg", freq: .twice, warnings: ["Regular blood tests needed","Teratogenic — not for women of childbearing potential without contraception","Monitor liver function and blood counts"], sides: ["Weight gain","Tremor","Nausea","Hair loss","Drowsiness"], interactions: ["Lamotrigine — doubles lamotrigine levels","Carbapenems — dramatically reduces valproate levels","Aspirin — increased valproate toxicity"], foodInt: ["Take with food to reduce stomach upset"], desc: "Broad-spectrum anticonvulsant for epilepsy, bipolar disorder, and migraine prevention.", otc: false)

        // ═══════════════════════════════════════
        // MARK: - Urological
        // ═══════════════════════════════════════

        add("Tamsulosin", brands: ["Flomax","Urimax","Omnic"], cat: .urological, therapeutic: "Alpha-1 Blocker", active: "Tamsulosin Hydrochloride", forms: [.capsule,.tablet], dosages: ["0.4mg","0.8mg"], defDose: "0.4", defUnit: "mg", freq: .daily, warnings: ["Take after same meal daily","First-dose dizziness — take at bedtime initially","Inform ophthalmologist before cataract surgery (IFIS risk)"], sides: ["Dizziness","Abnormal ejaculation","Runny nose","Headache"], interactions: ["Other alpha-blockers — severe hypotension","CYP3A4 inhibitors — increased levels","PDE5 inhibitors — enhanced hypotension"], foodInt: ["Take 30 minutes after the same meal each day"], desc: "Relaxes prostate and bladder neck muscles to improve urine flow in BPH (enlarged prostate).", otc: false)

        add("Finasteride", brands: ["Proscar","Propecia"], cat: .urological, therapeutic: "5-Alpha Reductase Inhibitor", active: "Finasteride", forms: [.tablet], dosages: ["1mg","5mg"], defDose: "5", defUnit: "mg", freq: .daily, warnings: ["Women must not handle crushed tablets (teratogenic)","Takes 6 months for full effect","May affect PSA test results — inform doctor"], sides: ["Sexual dysfunction","Decreased libido","Breast tenderness","Dizziness"], interactions: ["Few significant drug interactions","St John's Wort — may reduce effectiveness"], foodInt: ["Can be taken with or without food"], desc: "Shrinks enlarged prostate (5mg) or treats male pattern baldness (1mg). Slow onset.", otc: false)

        add("Sildenafil", brands: ["Viagra","Revatio","Kamagra"], cat: .urological, therapeutic: "PDE5 Inhibitor", active: "Sildenafil Citrate", forms: [.tablet], dosages: ["25mg","50mg","100mg"], defDose: "50", defUnit: "mg", freq: .asNeeded, warnings: ["Do NOT take with nitrates — life-threatening hypotension","Seek help if erection lasts >4 hours","Avoid large meals before taking"], sides: ["Headache","Flushing","Indigestion","Nasal congestion","Visual changes"], interactions: ["Nitrates — CONTRAINDICATED (fatal hypotension)","Alpha-blockers — enhanced hypotension","CYP3A4 inhibitors — increased sildenafil levels"], foodInt: ["High-fat meals delay absorption and reduce effectiveness"], desc: "For erectile dysfunction. Take 30-60 minutes before activity. Also used for pulmonary hypertension.", otc: false)

        // ═══════════════════════════════════════
        // MARK: - Immunological
        // ═══════════════════════════════════════

        add("Azathioprine", brands: ["Imuran","Azasan"], cat: .immunological, therapeutic: "Immunosuppressant", active: "Azathioprine", forms: [.tablet], dosages: ["25mg","50mg","75mg","100mg"], defDose: "50", defUnit: "mg", freq: .daily, warnings: ["TPMT testing before starting","Regular blood count monitoring","Increased infection and cancer risk"], sides: ["Nausea","Vomiting","Low blood counts","Liver toxicity","Increased infection risk"], interactions: ["Allopurinol — LIFE-THREATENING (reduce azathioprine 75%)","Warfarin — reduced warfarin effect","ACE inhibitors — increased leukopenia risk"], foodInt: ["Take with food to reduce nausea"], desc: "Immune suppressant for organ transplant rejection, Crohn's disease, and autoimmune conditions.", otc: false)

        add("Cyclosporine", brands: ["Neoral","Sandimmune","Gengraf"], cat: .immunological, therapeutic: "Calcineurin Inhibitor", active: "Cyclosporine", forms: [.capsule,.liquid], dosages: ["25mg","50mg","100mg"], defDose: "100", defUnit: "mg", freq: .twice, warnings: ["Regular blood level monitoring required","Monitor kidney function closely","Avoid live vaccines"], sides: ["Kidney toxicity","High blood pressure","Tremor","Excessive hair growth","Gum overgrowth"], interactions: ["Grapefruit — significantly increased levels","NSAIDs — increased kidney toxicity","Statins — increased myopathy risk","Potassium-sparing diuretics — hyperkalemia"], foodInt: ["Avoid grapefruit","Take consistently with or without food"], desc: "Powerful immunosuppressant for organ transplants, psoriasis, and rheumatoid arthritis.", otc: false)

        add("Adalimumab", brands: ["Humira","Hadlima","Hyrimoz"], cat: .immunological, therapeutic: "TNF-alpha Inhibitor (Biologic)", active: "Adalimumab", forms: [.injection], dosages: ["20mg","40mg","80mg"], defDose: "40", defUnit: "mg", freq: .weekly, warnings: ["Increased serious infection risk including TB","Screen for TB before starting","Avoid live vaccines"], sides: ["Injection site reactions","Upper respiratory infections","Headache","Rash","Increased infection risk"], interactions: ["Live vaccines — contraindicated","Other biologics — increased infection risk","Methotrexate — commonly co-prescribed"], foodInt: ["Injection: no food interaction"], desc: "Biologic injection for rheumatoid arthritis, Crohn's, psoriasis, and other autoimmune diseases.", otc: false)

        // ═══════════════════════════════════════
        // MARK: - Hormones & Endocrine
        // ═══════════════════════════════════════

        add("Estradiol", brands: ["Estrace","Climara","Divigel"], cat: .hormones, therapeutic: "Estrogen Replacement", active: "Estradiol", forms: [.tablet,.patch,.topical], dosages: ["0.5mg","1mg","2mg"], defDose: "1", defUnit: "mg", freq: .daily, warnings: ["Increased risk of blood clots","Use lowest effective dose for shortest time","Regular breast exams needed"], sides: ["Breast tenderness","Headache","Nausea","Bloating","Mood changes"], interactions: ["CYP3A4 inducers — reduced effectiveness","Thyroid hormone — may need dose adjustment","Warfarin — altered anticoagulation"], foodInt: ["Can be taken with or without food"], desc: "Estrogen hormone replacement for menopause symptoms (hot flashes, vaginal dryness).", otc: false)

        add("Progesterone", brands: ["Prometrium","Utrogestan","Crinone"], cat: .hormones, therapeutic: "Progestogen", active: "Micronized Progesterone", forms: [.capsule,.injection,.topical], dosages: ["100mg","200mg","400mg"], defDose: "200", defUnit: "mg", freq: .daily, warnings: ["Take at bedtime — causes drowsiness","Essential alongside estrogen to protect uterus","Peanut allergy — some formulations contain peanut oil"], sides: ["Drowsiness","Dizziness","Breast tenderness","Bloating","Mood changes"], interactions: ["CYP3A4 inducers — reduced levels","Ketoconazole — increased levels"], foodInt: ["Take at bedtime with food"], desc: "Progesterone for HRT, menstrual irregularities, and pregnancy support.", otc: false)

        add("Tamoxifen", brands: ["Nolvadex","Soltamox","Tamoplex"], cat: .hormones, therapeutic: "Selective Estrogen Receptor Modulator", active: "Tamoxifen Citrate", forms: [.tablet], dosages: ["10mg","20mg"], defDose: "20", defUnit: "mg", freq: .daily, warnings: ["Increased risk of blood clots and uterine cancer","5-10 year treatment course","Regular gynecological exams needed"], sides: ["Hot flashes","Nausea","Fatigue","Vaginal discharge","Blood clot risk"], interactions: ["CYP2D6 inhibitors (paroxetine, fluoxetine) — reduced effectiveness","Warfarin — increased bleeding","Aromatase inhibitors — do not use together"], foodInt: ["Can be taken with or without food"], desc: "Hormone therapy for estrogen-receptor positive breast cancer treatment and prevention.", otc: false)

        add("Desmopressin", brands: ["DDAVP","Minirin","Stimate"], cat: .hormones, therapeutic: "Vasopressin Analog", active: "Desmopressin Acetate", forms: [.tablet,.liquid,.injection], dosages: ["0.1mg","0.2mg","120mcg","240mcg"], defDose: "0.2", defUnit: "mg", freq: .daily, warnings: ["Monitor sodium levels — hyponatremia risk","Restrict fluid intake 1 hour before and 8 hours after","Not for primary nocturnal enuresis in elderly"], sides: ["Headache","Nausea","Nasal congestion (nasal form)","Hyponatremia","Abdominal cramps"], interactions: ["NSAIDs — increased hyponatremia risk","SSRIs — increased hyponatremia risk","Tricyclic antidepressants — enhanced effect"], foodInt: ["Restrict fluids around dosing time"], desc: "Synthetic vasopressin for diabetes insipidus, bedwetting, and bleeding disorders.", otc: false)

        // ============================================================
        // MARK: - Diabetes (25)
        // ============================================================

        add("Metformin", brands: ["Glucophage", "Glycomet", "Glyciphage", "Obimet", "Walaphage"], cat: .diabetes,
            therapeutic: "Biguanide", active: "Metformin Hydrochloride",
            forms: [.tablet], dosages: ["250mg", "500mg", "850mg", "1000mg"],
            defDose: "500", defUnit: "mg", freq: .twice,
            warnings: ["Take with food to reduce GI side effects", "Stop before contrast dye procedures", "Monitor kidney function", "Risk of lactic acidosis (rare)"],
            sides: ["Nausea", "Diarrhea", "Stomach pain", "Metallic taste", "B12 deficiency (long-term)"],
            interactions: ["Contrast dye — lactic acidosis risk", "Alcohol — increased lactic acidosis risk", "ACE inhibitors — may increase hypoglycemia"],
            foodInt: ["Take with meals", "Avoid excessive alcohol"],
            desc: "First-line treatment for Type 2 diabetes. Reduces glucose production and improves insulin sensitivity.", otc: false)

        add("Glimepiride", brands: ["Amaryl", "Glimisave", "Glimy", "Glimpid"], cat: .diabetes,
            therapeutic: "Sulfonylurea", active: "Glimepiride",
            forms: [.tablet], dosages: ["1mg", "2mg", "3mg", "4mg"],
            defDose: "2", defUnit: "mg", freq: .daily,
            warnings: ["Risk of hypoglycemia", "Take with breakfast", "Elderly patients need lower doses"],
            sides: ["Hypoglycemia", "Weight gain", "Dizziness", "Nausea", "Headache"],
            interactions: ["Beta-blockers — may mask hypoglycemia symptoms", "NSAIDs — increased hypoglycemia", "Fluconazole — increased glimepiride levels"],
            foodInt: ["Take with breakfast or first main meal"],
            desc: "Stimulates insulin release from the pancreas. Used when metformin alone is not enough.", otc: false)

        add("Gliclazide", brands: ["Diamicron", "Glizid", "Reclide", "Glycinorm"], cat: .diabetes,
            therapeutic: "Sulfonylurea", active: "Gliclazide",
            forms: [.tablet], dosages: ["40mg", "80mg", "30mg MR", "60mg MR"],
            defDose: "80", defUnit: "mg", freq: .daily,
            warnings: ["Risk of hypoglycemia", "Take with meals", "Avoid in severe liver/kidney disease"],
            sides: ["Hypoglycemia", "Weight gain", "GI upset", "Skin rash"],
            interactions: ["Fluconazole — increased effect", "Beta-blockers — mask hypoglycemia", "ACE inhibitors — enhanced glucose lowering"],
            foodInt: ["Take with breakfast"],
            desc: "Sulfonylurea for Type 2 diabetes with possible cardiovascular benefits.", otc: false)

        add("Glipizide", brands: ["Glucotrol", "Glynase", "Dibizide"], cat: .diabetes,
            therapeutic: "Sulfonylurea", active: "Glipizide",
            forms: [.tablet], dosages: ["2.5mg", "5mg", "10mg"],
            defDose: "5", defUnit: "mg", freq: .daily,
            warnings: ["Take 30 minutes before meals", "Risk of hypoglycemia", "Dose adjustment in elderly"],
            sides: ["Hypoglycemia", "Weight gain", "Nausea", "Dizziness"],
            interactions: ["NSAIDs — increased hypoglycemia", "Thiazide diuretics — may increase glucose", "Beta-blockers — mask hypoglycemia signs"],
            foodInt: ["Take 30 minutes before meals for best absorption"],
            desc: "Short-acting sulfonylurea for Type 2 diabetes. Stimulates pancreatic insulin secretion.", otc: false)

        add("Sitagliptin", brands: ["Januvia", "Istavel", "Zita"], cat: .diabetes,
            therapeutic: "DPP-4 Inhibitor", active: "Sitagliptin Phosphate",
            forms: [.tablet], dosages: ["25mg", "50mg", "100mg"],
            defDose: "100", defUnit: "mg", freq: .daily,
            warnings: ["Monitor for pancreatitis", "Dose adjustment for kidney disease", "Joint pain reported rarely"],
            sides: ["Upper respiratory infection", "Headache", "Nasopharyngitis", "Pancreatitis (rare)"],
            interactions: ["Digoxin — slight increase in digoxin levels", "Sulfonylureas — may increase hypoglycemia risk"],
            foodInt: ["Can be taken with or without food"],
            desc: "Incretin-based therapy that increases insulin release and decreases glucagon when blood sugar is high.", otc: false)

        add("Vildagliptin", brands: ["Galvus", "Jalra", "Zomelis"], cat: .diabetes,
            therapeutic: "DPP-4 Inhibitor", active: "Vildagliptin",
            forms: [.tablet], dosages: ["50mg"],
            defDose: "50", defUnit: "mg", freq: .twice,
            warnings: ["Monitor liver function", "Not for Type 1 diabetes", "Dose adjust in kidney disease"],
            sides: ["Headache", "Dizziness", "Tremor", "Peripheral edema"],
            interactions: ["ACE inhibitors — increased angioedema risk", "Sulfonylureas — may need dose reduction"],
            foodInt: ["Can be taken with or without food"],
            desc: "DPP-4 inhibitor for Type 2 diabetes. Often combined with metformin.", otc: false)

        add("Linagliptin", brands: ["Tradjenta", "Trajenta"], cat: .diabetes,
            therapeutic: "DPP-4 Inhibitor", active: "Linagliptin",
            forms: [.tablet], dosages: ["5mg"],
            defDose: "5", defUnit: "mg", freq: .daily,
            warnings: ["Monitor for pancreatitis", "No dose adjustment needed for kidney disease", "Rare bullous pemphigoid"],
            sides: ["Nasopharyngitis", "Cough", "Hypoglycemia (with sulfonylureas)"],
            interactions: ["Rifampin — may reduce effectiveness", "CYP3A4 inducers — may reduce effect"],
            foodInt: ["Can be taken with or without food"],
            desc: "DPP-4 inhibitor unique for requiring no kidney dose adjustment. Good for elderly patients.", otc: false)

        add("Empagliflozin", brands: ["Jardiance", "Gibtulio"], cat: .diabetes,
            therapeutic: "SGLT2 Inhibitor", active: "Empagliflozin",
            forms: [.tablet], dosages: ["10mg", "25mg"],
            defDose: "10", defUnit: "mg", freq: .daily,
            warnings: ["Risk of genital infections", "Monitor for ketoacidosis", "May cause dehydration", "Proven cardiovascular benefits"],
            sides: ["UTI", "Genital yeast infections", "Increased urination", "Dehydration", "Hypotension"],
            interactions: ["Diuretics — additive dehydration/hypotension", "Insulin — may need dose reduction", "Lithium — altered lithium levels"],
            foodInt: ["Can be taken with or without food", "Drink plenty of water"],
            desc: "SGLT2 inhibitor with proven heart and kidney protective benefits beyond glucose lowering.", otc: false)

        add("Dapagliflozin", brands: ["Farxiga", "Forxiga", "Oxra"], cat: .diabetes,
            therapeutic: "SGLT2 Inhibitor", active: "Dapagliflozin",
            forms: [.tablet], dosages: ["5mg", "10mg"],
            defDose: "10", defUnit: "mg", freq: .daily,
            warnings: ["Risk of genital mycotic infections", "Monitor for ketoacidosis", "Avoid if eGFR < 25", "Heart failure benefits"],
            sides: ["Genital infections", "UTI", "Back pain", "Increased urination", "Nasopharyngitis"],
            interactions: ["Diuretics — risk of dehydration", "Insulin/sulfonylureas — hypoglycemia risk", "Lithium — monitor levels"],
            foodInt: ["Can be taken with or without food"],
            desc: "SGLT2 inhibitor approved for diabetes, heart failure, and chronic kidney disease.", otc: false)

        add("Canagliflozin", brands: ["Invokana", "Sulisent"], cat: .diabetes,
            therapeutic: "SGLT2 Inhibitor", active: "Canagliflozin",
            forms: [.tablet], dosages: ["100mg", "300mg"],
            defDose: "100", defUnit: "mg", freq: .daily,
            warnings: ["Increased risk of lower limb amputation", "Monitor for ketoacidosis", "Genital infection risk", "Bone fracture risk"],
            sides: ["Genital yeast infections", "UTI", "Increased urination", "Thirst", "Hypotension"],
            interactions: ["Digoxin — monitor levels", "Diuretics — additive hypotension", "Phenytoin/rifampin — reduced canagliflozin effect"],
            foodInt: ["Take before first meal of the day"],
            desc: "SGLT2 inhibitor for Type 2 diabetes. Use with caution in patients with peripheral vascular disease.", otc: false)

        add("Pioglitazone", brands: ["Actos", "Pioz", "Piozone"], cat: .diabetes,
            therapeutic: "Thiazolidinedione", active: "Pioglitazone Hydrochloride",
            forms: [.tablet], dosages: ["15mg", "30mg", "45mg"],
            defDose: "30", defUnit: "mg", freq: .daily,
            warnings: ["Risk of fluid retention and heart failure", "Bladder cancer risk (long-term)", "Monitor liver function", "May cause weight gain"],
            sides: ["Weight gain", "Edema", "Fractures (women)", "Upper respiratory infections"],
            interactions: ["CYP2C8 inhibitors — increased pioglitazone levels", "Insulin — increased edema and heart failure risk", "Oral contraceptives — may reduce effectiveness"],
            foodInt: ["Can be taken with or without food"],
            desc: "Insulin sensitizer that improves glucose utilization. Also improves lipid profile.", otc: false)

        add("Semaglutide", brands: ["Ozempic", "Wegovy", "Rybelsus"], cat: .diabetes,
            therapeutic: "GLP-1 Receptor Agonist", active: "Semaglutide",
            forms: [.injection, .tablet], dosages: ["0.25mg", "0.5mg", "1mg", "2mg", "3mg oral", "7mg oral", "14mg oral"],
            defDose: "0.5", defUnit: "mg", freq: .weekly,
            warnings: ["Thyroid C-cell tumor risk (boxed warning)", "Pancreatitis risk", "Do not use in Type 1 diabetes", "Significant weight loss expected"],
            sides: ["Nausea", "Vomiting", "Diarrhea", "Constipation", "Decreased appetite"],
            interactions: ["Insulin/sulfonylureas — increased hypoglycemia", "Oral medications — delayed gastric emptying may alter absorption", "Warfarin — monitor INR"],
            foodInt: ["Injection: any time, with or without food", "Oral: take on empty stomach with small sip of water, wait 30 min before eating"],
            desc: "Weekly GLP-1 injection (or daily oral) for Type 2 diabetes and weight management. Powerful glucose and weight reduction.", otc: false)

        add("Liraglutide", brands: ["Victoza", "Saxenda"], cat: .diabetes,
            therapeutic: "GLP-1 Receptor Agonist", active: "Liraglutide",
            forms: [.injection], dosages: ["0.6mg", "1.2mg", "1.8mg"],
            defDose: "1.2", defUnit: "mg", freq: .daily,
            warnings: ["Thyroid C-cell tumor risk", "Pancreatitis risk", "Not for Type 1 diabetes", "Cardiovascular benefit proven"],
            sides: ["Nausea", "Diarrhea", "Vomiting", "Decreased appetite", "Injection site reactions"],
            interactions: ["Sulfonylureas — increased hypoglycemia", "Oral medications — may delay absorption", "Warfarin — monitor INR"],
            foodInt: ["Inject at any time, independent of meals"],
            desc: "Daily GLP-1 injection for Type 2 diabetes with proven cardiovascular benefits.", otc: false)

        add("Dulaglutide", brands: ["Trulicity"], cat: .diabetes,
            therapeutic: "GLP-1 Receptor Agonist", active: "Dulaglutide",
            forms: [.injection], dosages: ["0.75mg", "1.5mg", "3mg", "4.5mg"],
            defDose: "0.75", defUnit: "mg", freq: .weekly,
            warnings: ["Thyroid C-cell tumor risk", "Pancreatitis risk", "Dose escalation recommended"],
            sides: ["Nausea", "Diarrhea", "Vomiting", "Abdominal pain", "Decreased appetite"],
            interactions: ["Insulin — hypoglycemia risk", "Sulfonylureas — hypoglycemia risk", "Oral drugs — delayed absorption possible"],
            foodInt: ["Inject at any time, with or without meals"],
            desc: "Once-weekly GLP-1 injection for Type 2 diabetes. Pre-filled single-use pen.", otc: false)

        add("Insulin Glargine", brands: ["Lantus", "Basaglar", "Toujeo", "Semglee"], cat: .diabetes,
            therapeutic: "Long-Acting Insulin", active: "Insulin Glargine",
            forms: [.injection], dosages: ["100 units/mL", "300 units/mL"],
            defDose: "10", defUnit: "units", freq: .daily,
            warnings: ["Never share insulin pens", "Rotate injection sites", "Monitor blood glucose regularly", "Risk of hypoglycemia"],
            sides: ["Hypoglycemia", "Weight gain", "Injection site reactions", "Lipodystrophy"],
            interactions: ["Beta-blockers — may mask hypoglycemia", "Thiazolidinediones — increased fluid retention", "ACE inhibitors — increased hypoglycemia"],
            foodInt: ["Inject at same time daily, independent of meals"],
            desc: "Long-acting basal insulin providing 24-hour coverage. Peakless profile reduces night-time hypoglycemia risk.", otc: false)

        add("Insulin Lispro", brands: ["Humalog", "Admelog", "Lyumjev"], cat: .diabetes,
            therapeutic: "Rapid-Acting Insulin", active: "Insulin Lispro",
            forms: [.injection], dosages: ["100 units/mL", "200 units/mL"],
            defDose: "5", defUnit: "units", freq: .thrice,
            warnings: ["Inject within 15 minutes of meals", "Risk of hypoglycemia", "Rotate injection sites", "Never share pens"],
            sides: ["Hypoglycemia", "Weight gain", "Injection site reactions", "Allergic reactions (rare)"],
            interactions: ["Beta-blockers — mask hypoglycemia", "ACE inhibitors — enhanced glucose lowering", "Alcohol — unpredictable glucose effects"],
            foodInt: ["Inject 0-15 minutes before meals"],
            desc: "Rapid-acting mealtime insulin. Starts working within 15 minutes, peaks at 1 hour.", otc: false)

        add("Insulin Aspart", brands: ["NovoLog", "NovoRapid", "Fiasp"], cat: .diabetes,
            therapeutic: "Rapid-Acting Insulin", active: "Insulin Aspart",
            forms: [.injection], dosages: ["100 units/mL"],
            defDose: "5", defUnit: "units", freq: .thrice,
            warnings: ["Inject just before meals", "Risk of hypoglycemia", "Can be used in insulin pumps", "Rotate injection sites"],
            sides: ["Hypoglycemia", "Weight gain", "Injection site lipodystrophy", "Allergic reactions"],
            interactions: ["Beta-blockers — mask hypoglycemia", "Corticosteroids — may increase glucose", "ACE inhibitors — increased hypoglycemia"],
            foodInt: ["Inject 0-10 minutes before start of meal"],
            desc: "Rapid-acting mealtime insulin for bolus dosing. Compatible with insulin pumps.", otc: false)

        add("Insulin Detemir", brands: ["Levemir"], cat: .diabetes,
            therapeutic: "Long-Acting Insulin", active: "Insulin Detemir",
            forms: [.injection], dosages: ["100 units/mL"],
            defDose: "10", defUnit: "units", freq: .daily,
            warnings: ["May be given once or twice daily", "Rotate injection sites", "Less weight gain than other insulins"],
            sides: ["Hypoglycemia", "Injection site reactions", "Weight gain (less than other insulins)"],
            interactions: ["Beta-blockers — mask hypoglycemia", "Thiazolidinediones — fluid retention", "ACE inhibitors — enhanced glucose lowering"],
            foodInt: ["Inject at same time daily, with or without food"],
            desc: "Long-acting basal insulin with less weight gain compared to other basal insulins.", otc: false)

        add("Acarbose", brands: ["Precose", "Glucobay", "Rebose"], cat: .diabetes,
            therapeutic: "Alpha-Glucosidase Inhibitor", active: "Acarbose",
            forms: [.tablet], dosages: ["25mg", "50mg", "100mg"],
            defDose: "50", defUnit: "mg", freq: .thrice,
            warnings: ["Take with first bite of each meal", "May cause significant GI side effects initially", "Monitor liver function"],
            sides: ["Flatulence", "Diarrhea", "Abdominal pain", "Bloating"],
            interactions: ["Insulin/sulfonylureas — use glucose (not sucrose) to treat hypoglycemia", "Digoxin — may reduce absorption", "Charcoal — reduces acarbose effect"],
            foodInt: ["Must be taken with the first bite of each main meal"],
            desc: "Slows carbohydrate digestion to reduce post-meal glucose spikes. Particularly useful in Asian diets.", otc: false)

        add("Repaglinide", brands: ["Prandin", "NovoNorm", "Eurepa"], cat: .diabetes,
            therapeutic: "Meglitinide", active: "Repaglinide",
            forms: [.tablet], dosages: ["0.5mg", "1mg", "2mg"],
            defDose: "1", defUnit: "mg", freq: .thrice,
            warnings: ["Take within 30 minutes of meals", "Skip dose if skipping meal", "Risk of hypoglycemia"],
            sides: ["Hypoglycemia", "Weight gain", "Upper respiratory infection", "Headache"],
            interactions: ["Gemfibrozil — greatly increased repaglinide levels (contraindicated)", "CYP3A4 inhibitors — increased levels", "Beta-blockers — mask hypoglycemia"],
            foodInt: ["Take 15-30 minutes before each meal, skip if not eating"],
            desc: "Short-acting insulin secretagogue taken before meals. Flexible dosing for irregular meal patterns.", otc: false)

        add("Teneligliptin", brands: ["Tenelia", "Tenlimac", "Tenepure"], cat: .diabetes,
            therapeutic: "DPP-4 Inhibitor", active: "Teneligliptin",
            forms: [.tablet], dosages: ["20mg", "40mg"],
            defDose: "20", defUnit: "mg", freq: .daily,
            warnings: ["Monitor for pancreatitis", "No dose adjustment in mild-moderate kidney disease", "Popular in India and Japan"],
            sides: ["Hypoglycemia (with sulfonylureas)", "Constipation", "Upper respiratory infection"],
            interactions: ["Sulfonylureas — may increase hypoglycemia", "CYP3A4 inhibitors — may increase levels"],
            foodInt: ["Can be taken with or without food"],
            desc: "DPP-4 inhibitor widely used in India and Japan. No dose adjustment needed for kidney disease.", otc: false)

        add("Insulin Degludec", brands: ["Tresiba"], cat: .diabetes,
            therapeutic: "Ultra-Long-Acting Insulin", active: "Insulin Degludec",
            forms: [.injection], dosages: ["100 units/mL", "200 units/mL"],
            defDose: "10", defUnit: "units", freq: .daily,
            warnings: ["Ultra-long duration (42+ hours)", "Flexible dosing time", "Lower hypoglycemia risk vs glargine"],
            sides: ["Hypoglycemia", "Weight gain", "Injection site reactions", "Upper respiratory infection"],
            interactions: ["Beta-blockers — mask hypoglycemia", "ACE inhibitors — enhanced effect", "Corticosteroids — increased glucose"],
            foodInt: ["Inject at any time of day, independent of meals"],
            desc: "Ultra-long-acting basal insulin lasting 42+ hours. Allows flexible daily injection timing.", otc: false)

        // ============================================================
        // MARK: - Respiratory (15)
        // ============================================================

        add("Salbutamol", brands: ["Ventolin", "ProAir", "Asthalin"], cat: .respiratory,
            therapeutic: "Short-acting Beta-2 Agonist (SABA)", active: "Salbutamol (Albuterol)",
            forms: [.inhaler, .liquid, .tablet], dosages: ["100mcg/puff", "2mg", "4mg"],
            defDose: "100", defUnit: "mcg", freq: .asNeeded,
            warnings: ["Overuse indicates poor asthma control", "May cause paradoxical bronchospasm", "Shake inhaler well before use"],
            sides: ["Tremor", "Tachycardia", "Headache", "Nervousness"],
            interactions: ["Beta-blockers — mutual antagonism", "Diuretics — additive hypokalemia", "MAO inhibitors — increased cardiovascular effects"],
            foodInt: ["Not applicable — inhaled", "No food restrictions"],
            desc: "A quick-relief inhaler that rapidly opens airways during asthma attacks and bronchospasm.", otc: false)

        add("Fluticasone Inhaler", brands: ["Flovent", "Flixotide"], cat: .respiratory,
            therapeutic: "Inhaled Corticosteroid (ICS)", active: "Fluticasone Propionate",
            forms: [.inhaler], dosages: ["44mcg", "110mcg", "220mcg", "250mcg"],
            defDose: "110", defUnit: "mcg", freq: .twice,
            warnings: ["Rinse mouth after use to prevent thrush", "Not for acute rescue", "Monitor growth in children"],
            sides: ["Oral thrush", "Hoarseness", "Sore throat", "Cough"],
            interactions: ["CYP3A4 inhibitors (ritonavir) — increased systemic steroid effects", "Ketoconazole — increased fluticasone levels", "No major interactions when inhaled properly"],
            foodInt: ["Not applicable — inhaled", "Rinse mouth after use"],
            desc: "A daily inhaled steroid for long-term asthma control that reduces airway inflammation.", otc: false)

        add("Budesonide Inhaler", brands: ["Pulmicort", "Budecort"], cat: .respiratory,
            therapeutic: "Inhaled Corticosteroid (ICS)", active: "Budesonide",
            forms: [.inhaler, .liquid], dosages: ["90mcg", "180mcg", "200mcg", "400mcg"],
            defDose: "200", defUnit: "mcg", freq: .twice,
            warnings: ["Not a rescue inhaler", "Rinse mouth after use", "May affect growth velocity in children"],
            sides: ["Oral candidiasis", "Cough", "Hoarseness", "Headache"],
            interactions: ["CYP3A4 inhibitors — increased systemic exposure", "Ketoconazole — increased budesonide levels", "No major inhaled-drug interactions"],
            foodInt: ["Not applicable — inhaled", "Rinse mouth after each use"],
            desc: "An inhaled corticosteroid for maintenance asthma therapy, also available as a nebulizer solution.", otc: false)

        add("Montelukast", brands: ["Singulair", "Montair", "Montek", "Romilast"], cat: .respiratory,
            therapeutic: "Leukotriene Receptor Antagonist", active: "Montelukast Sodium",
            forms: [.tablet, .liquid], dosages: ["4mg", "5mg", "10mg"],
            defDose: "10", defUnit: "mg", freq: .daily,
            warnings: ["Black box: neuropsychiatric events (mood changes, suicidality)", "Not for acute asthma attacks", "Monitor for behavioral changes"],
            sides: ["Headache", "Abdominal pain", "Behavioral changes", "Upper respiratory infection"],
            interactions: ["Phenobarbital — reduced montelukast levels", "Rifampin — reduced montelukast levels", "CYP3A4 inducers — decreased efficacy"],
            foodInt: ["Can be taken with or without food", "Take in the evening for asthma"],
            desc: "A leukotriene blocker for asthma and allergic rhinitis, taken once daily in the evening.", otc: false)

        add("Tiotropium", brands: ["Spiriva"], cat: .respiratory,
            therapeutic: "Long-acting Muscarinic Antagonist (LAMA)", active: "Tiotropium Bromide",
            forms: [.inhaler], dosages: ["1.25mcg", "2.5mcg", "18mcg"],
            defDose: "18", defUnit: "mcg", freq: .daily,
            warnings: ["Not for acute bronchospasm", "May worsen narrow-angle glaucoma", "Urinary retention risk"],
            sides: ["Dry mouth", "Constipation", "Urinary retention", "Sinusitis"],
            interactions: ["Other anticholinergics — additive side effects", "Beta-blockers — mutual respiratory antagonism", "No major drug-drug interactions"],
            foodInt: ["Not applicable — inhaled", "No food restrictions"],
            desc: "A once-daily long-acting inhaler for COPD maintenance that keeps airways open for 24 hours.", otc: false)

        add("Salmeterol", brands: ["Serevent"], cat: .respiratory,
            therapeutic: "Long-acting Beta-2 Agonist (LABA)", active: "Salmeterol Xinafoate",
            forms: [.inhaler], dosages: ["50mcg"],
            defDose: "50", defUnit: "mcg", freq: .twice,
            warnings: ["Black box: increased asthma-related death if used without ICS", "Not for acute relief", "Always use with inhaled steroid in asthma"],
            sides: ["Headache", "Tremor", "Palpitations", "Throat irritation"],
            interactions: ["Beta-blockers — mutual antagonism", "CYP3A4 inhibitors — increased salmeterol levels", "MAO inhibitors — potentiated cardiovascular effects"],
            foodInt: ["Not applicable — inhaled", "No food restrictions"],
            desc: "A long-acting bronchodilator for maintenance asthma and COPD therapy, always with an inhaled steroid.", otc: false)

        add("Formoterol", brands: ["Foradil", "Oxis"], cat: .respiratory,
            therapeutic: "Long-acting Beta-2 Agonist (LABA)", active: "Formoterol Fumarate",
            forms: [.inhaler], dosages: ["6mcg", "12mcg"],
            defDose: "12", defUnit: "mcg", freq: .twice,
            warnings: ["Must be used with ICS in asthma", "Not primary rescue inhaler", "Cardiovascular effects at high doses"],
            sides: ["Tremor", "Palpitations", "Headache", "Muscle cramps"],
            interactions: ["Beta-blockers — reduced bronchodilator effect", "Diuretics — hypokalemia risk", "MAO inhibitors — increased cardiovascular effects"],
            foodInt: ["Not applicable — inhaled", "No food restrictions"],
            desc: "A long-acting bronchodilator with rapid onset, used for maintenance in asthma and COPD.", otc: false)

        add("Beclometasone", brands: ["Qvar", "Clenil"], cat: .respiratory,
            therapeutic: "Inhaled Corticosteroid (ICS)", active: "Beclometasone Dipropionate",
            forms: [.inhaler], dosages: ["40mcg", "80mcg", "100mcg", "200mcg", "250mcg"],
            defDose: "100", defUnit: "mcg", freq: .twice,
            warnings: ["Not for acute attacks", "Rinse mouth after use", "Adrenal suppression at high doses"],
            sides: ["Oral thrush", "Dysphonia", "Cough", "Sore throat"],
            interactions: ["CYP3A4 inhibitors — increased systemic steroid effect", "Ritonavir — avoid combination", "No major inhaled interactions"],
            foodInt: ["Not applicable — inhaled", "Rinse mouth thoroughly after use"],
            desc: "An inhaled corticosteroid for asthma maintenance, one of the oldest and most studied ICS options.", otc: false)

        add("Theophylline", brands: ["Theo-24", "Uniphyl", "Deriphyllin"], cat: .respiratory,
            therapeutic: "Methylxanthine Bronchodilator", active: "Theophylline",
            forms: [.tablet, .capsule, .liquid], dosages: ["100mg", "200mg", "300mg", "400mg"],
            defDose: "200", defUnit: "mg", freq: .twice,
            warnings: ["Narrow therapeutic index — monitor drug levels", "Toxicity causes seizures and arrhythmias", "Many drug and food interactions"],
            sides: ["Nausea", "Insomnia", "Headache", "Tachycardia"],
            interactions: ["Ciprofloxacin — doubled theophylline levels", "Erythromycin — increased theophylline toxicity", "Phenytoin — mutual interaction affecting levels"],
            foodInt: ["High-protein diet decreases levels; high-carb diet increases levels", "Caffeine increases side effects"],
            desc: "An older bronchodilator for asthma and COPD that requires blood level monitoring.", otc: false)

        add("Fluticasone-Salmeterol", brands: ["Advair", "Seretide"], cat: .respiratory,
            therapeutic: "ICS + LABA Combination", active: "Fluticasone Propionate + Salmeterol",
            forms: [.inhaler], dosages: ["100/50mcg", "250/50mcg", "500/50mcg"],
            defDose: "250/50", defUnit: "mcg", freq: .twice,
            warnings: ["Not for acute bronchospasm", "Rinse mouth after use", "Monitor for pneumonia in COPD"],
            sides: ["Oral thrush", "Hoarseness", "Headache", "Upper respiratory infection"],
            interactions: ["CYP3A4 inhibitors — increased steroid/LABA levels", "Beta-blockers — reduced bronchodilator effect", "Diuretics — hypokalemia"],
            foodInt: ["Not applicable — inhaled", "Rinse mouth after inhalation"],
            desc: "A combination inhaler providing both anti-inflammatory and bronchodilator effects for asthma and COPD.", otc: false)

        add("Budesonide-Formoterol", brands: ["Symbicort"], cat: .respiratory,
            therapeutic: "ICS + LABA Combination", active: "Budesonide + Formoterol Fumarate",
            forms: [.inhaler], dosages: ["80/4.5mcg", "160/4.5mcg", "200/6mcg", "400/12mcg"],
            defDose: "160/4.5", defUnit: "mcg", freq: .twice,
            warnings: ["Can be used as maintenance and reliever (MART)", "Rinse mouth after use", "Monitor growth in children"],
            sides: ["Oral thrush", "Headache", "Tremor", "Palpitations"],
            interactions: ["Beta-blockers — reduced bronchodilator effect", "CYP3A4 inhibitors — increased budesonide levels", "Potassium-lowering drugs — additive hypokalemia"],
            foodInt: ["Not applicable — inhaled", "Rinse mouth after use"],
            desc: "A combination controller inhaler for asthma and COPD that can also serve as a rescue inhaler.", otc: false)

        add("Dextromethorphan", brands: ["Robitussin DM", "Delsym"], cat: .respiratory,
            therapeutic: "Antitussive", active: "Dextromethorphan Hydrobromide",
            forms: [.liquid, .capsule, .tablet], dosages: ["10mg", "15mg", "30mg"],
            defDose: "15", defUnit: "mg", freq: .thrice,
            warnings: ["Abuse potential in high doses", "Avoid with MAO inhibitors", "Not for productive cough"],
            sides: ["Drowsiness", "Dizziness", "Nausea", "GI upset"],
            interactions: ["MAO inhibitors — serotonin syndrome risk", "SSRIs — serotonin syndrome risk", "CYP2D6 inhibitors — increased dextromethorphan levels"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol"],
            desc: "An over-the-counter cough suppressant for dry, non-productive coughs.", otc: true)

        add("Guaifenesin", brands: ["Mucinex", "Robitussin"], cat: .respiratory,
            therapeutic: "Expectorant", active: "Guaifenesin",
            forms: [.tablet, .liquid], dosages: ["200mg", "400mg", "600mg", "1200mg"],
            defDose: "400", defUnit: "mg", freq: .twice,
            warnings: ["Drink plenty of water for best effect", "Do not crush extended-release tablets", "Not effective for all cough types"],
            sides: ["Nausea", "Vomiting", "Dizziness", "Headache"],
            interactions: ["No clinically significant interactions", "May interfere with uric acid lab tests", "Minimal drug interactions"],
            foodInt: ["Take with a full glass of water", "Can be taken with or without food"],
            desc: "An expectorant that thins and loosens mucus to make coughs more productive.", otc: true)

        add("Pseudoephedrine", brands: ["Sudafed"], cat: .respiratory,
            therapeutic: "Decongestant", active: "Pseudoephedrine Hydrochloride",
            forms: [.tablet, .liquid], dosages: ["30mg", "60mg", "120mg", "240mg"],
            defDose: "60", defUnit: "mg", freq: .thrice,
            warnings: ["May raise blood pressure", "Behind-the-counter purchase restrictions", "Avoid in severe hypertension or coronary artery disease"],
            sides: ["Insomnia", "Nervousness", "Tachycardia", "Elevated blood pressure"],
            interactions: ["MAO inhibitors — hypertensive crisis", "Beta-blockers — reduced antihypertensive effect", "Other sympathomimetics — additive cardiovascular effects"],
            foodInt: ["Can be taken with or without food", "Avoid caffeine — additive stimulation"],
            desc: "A decongestant that shrinks swollen nasal passages to relieve sinus and nasal congestion.", otc: true)

        add("Benzonatate", brands: ["Tessalon", "Tessalon Perles"], cat: .respiratory,
            therapeutic: "Antitussive", active: "Benzonatate",
            forms: [.capsule], dosages: ["100mg", "200mg"],
            defDose: "100", defUnit: "mg", freq: .thrice,
            warnings: ["Do NOT chew or break capsules — oropharyngeal anesthesia risk", "Keep away from children — accidental ingestion can be fatal", "Swallow whole"],
            sides: ["Drowsiness", "Headache", "Dizziness", "Nausea"],
            interactions: ["CNS depressants — additive sedation", "Other local anesthetics — additive numbing effects", "No major drug interactions"],
            foodInt: ["Can be taken with or without food", "Do not chew capsules"],
            desc: "A non-narcotic cough suppressant that numbs stretch receptors in the lungs to reduce cough reflex.", otc: false)

        // ============================================================
        // MARK: - Gastrointestinal (15)
        // ============================================================

        add("Omeprazole", brands: ["Prilosec", "Losec", "Omez", "Ocid", "Omesec"], cat: .gastrointestinal,
            therapeutic: "Proton Pump Inhibitor (PPI)", active: "Omeprazole",
            forms: [.capsule, .tablet], dosages: ["10mg", "20mg", "40mg"],
            defDose: "20", defUnit: "mg", freq: .daily,
            warnings: ["Long-term use: fracture risk, B12 deficiency, C. difficile risk", "Take 30 minutes before meals", "Magnesium deficiency with prolonged use"],
            sides: ["Headache", "Diarrhea", "Abdominal pain", "Nausea"],
            interactions: ["Clopidogrel — reduced clopidogrel activation (avoid combination)", "Methotrexate — increased methotrexate levels", "Diazepam — increased diazepam levels"],
            foodInt: ["Take 30 minutes before first meal", "Avoid excessive alcohol"],
            desc: "A proton pump inhibitor that reduces stomach acid for ulcers, GERD, and heartburn.", otc: true)

        add("Pantoprazole", brands: ["Protonix", "Pantocid", "Pan", "Pantodac", "Pan-D"], cat: .gastrointestinal,
            therapeutic: "Proton Pump Inhibitor (PPI)", active: "Pantoprazole Sodium",
            forms: [.tablet, .injection], dosages: ["20mg", "40mg"],
            defDose: "40", defUnit: "mg", freq: .daily,
            warnings: ["Long-term risks similar to other PPIs", "Take before meals", "Less CYP2C19 interaction than omeprazole"],
            sides: ["Headache", "Diarrhea", "Nausea", "Flatulence"],
            interactions: ["Methotrexate — increased toxicity", "Warfarin — monitor INR", "Atazanavir — reduced absorption"],
            foodInt: ["Take 30 minutes before a meal", "Can be taken without food but best before meals"],
            desc: "A PPI with fewer drug interactions than omeprazole, used for GERD and erosive esophagitis.", otc: false)

        add("Esomeprazole", brands: ["Nexium", "Neksium", "Raciper", "Izra"], cat: .gastrointestinal,
            therapeutic: "Proton Pump Inhibitor (PPI)", active: "Esomeprazole Magnesium",
            forms: [.capsule, .tablet, .injection], dosages: ["20mg", "40mg"],
            defDose: "40", defUnit: "mg", freq: .daily,
            warnings: ["Same long-term risks as other PPIs", "Do not crush capsules", "Monitor magnesium with long-term use"],
            sides: ["Headache", "Diarrhea", "Nausea", "Abdominal pain"],
            interactions: ["Clopidogrel — reduced antiplatelet effect", "Methotrexate — elevated levels", "Tacrolimus — increased tacrolimus levels"],
            foodInt: ["Take at least 1 hour before meals", "Swallow whole or mix granules in applesauce"],
            desc: "The S-isomer of omeprazole, a PPI for GERD, ulcers, and Zollinger-Ellison syndrome.", otc: true)

        add("Lansoprazole", brands: ["Prevacid"], cat: .gastrointestinal,
            therapeutic: "Proton Pump Inhibitor (PPI)", active: "Lansoprazole",
            forms: [.capsule, .tablet], dosages: ["15mg", "30mg"],
            defDose: "30", defUnit: "mg", freq: .daily,
            warnings: ["Fracture risk with long-term use", "Take before meals", "C. difficile infection risk"],
            sides: ["Diarrhea", "Headache", "Abdominal pain", "Nausea"],
            interactions: ["Sucralfate — take lansoprazole 30 min before sucralfate", "Theophylline — monitor levels", "Methotrexate — increased toxicity"],
            foodInt: ["Take 30 minutes before eating", "Do not crush or chew capsules"],
            desc: "A PPI for acid reflux, peptic ulcers, and H. pylori eradication therapy.", otc: true)

        add("Ranitidine", brands: ["Zantac", "Rantac", "Aciloc", "Zinetac"], cat: .gastrointestinal,
            therapeutic: "H2 Receptor Antagonist", active: "Ranitidine Hydrochloride",
            forms: [.tablet, .liquid], dosages: ["75mg", "150mg", "300mg"],
            defDose: "150", defUnit: "mg", freq: .twice,
            warnings: ["Withdrawn in many countries due to NDMA contamination", "Check availability in your region", "Consider alternatives"],
            sides: ["Headache", "Dizziness", "Constipation", "Diarrhea"],
            interactions: ["Atazanavir — reduced absorption", "Ketoconazole — reduced absorption", "Warfarin — possible increased bleeding"],
            foodInt: ["Can be taken with or without food", "Avoid excessive alcohol"],
            desc: "An H2 blocker for heartburn and ulcers — withdrawn in some markets; check local availability.", otc: true)

        add("Famotidine", brands: ["Pepcid"], cat: .gastrointestinal,
            therapeutic: "H2 Receptor Antagonist", active: "Famotidine",
            forms: [.tablet, .liquid, .injection], dosages: ["10mg", "20mg", "40mg"],
            defDose: "20", defUnit: "mg", freq: .twice,
            warnings: ["Adjust dose in renal impairment", "Headache is most common side effect", "Not as effective as PPIs for severe GERD"],
            sides: ["Headache", "Dizziness", "Constipation", "Diarrhea"],
            interactions: ["Atazanavir — reduced absorption", "Ketoconazole — reduced absorption", "Dasatinib — reduced absorption"],
            foodInt: ["Can be taken with or without food", "Limit caffeine and spicy foods for GERD"],
            desc: "An H2 blocker for heartburn and ulcer prevention, preferred over ranitidine since its withdrawal.", otc: true)

        add("Loperamide", brands: ["Imodium"], cat: .gastrointestinal,
            therapeutic: "Antidiarrheal", active: "Loperamide Hydrochloride",
            forms: [.capsule, .tablet, .liquid], dosages: ["2mg"],
            defDose: "2", defUnit: "mg", freq: .asNeeded,
            warnings: ["Do not exceed 16mg per day", "Avoid in bloody diarrhea or C. difficile", "Cardiac toxicity with abuse/overdose"],
            sides: ["Constipation", "Abdominal cramps", "Nausea", "Dizziness"],
            interactions: ["P-glycoprotein inhibitors — increased loperamide levels and cardiac risk", "Ritonavir — increased loperamide levels", "Gemfibrozil — increased loperamide levels"],
            foodInt: ["Can be taken with or without food", "Maintain clear fluid intake"],
            desc: "An over-the-counter antidiarrheal that slows gut motility to reduce loose stools.", otc: true)

        add("Ondansetron", brands: ["Zofran"], cat: .gastrointestinal,
            therapeutic: "5-HT3 Receptor Antagonist / Antiemetic", active: "Ondansetron",
            forms: [.tablet, .liquid, .injection], dosages: ["4mg", "8mg"],
            defDose: "4", defUnit: "mg", freq: .thrice,
            warnings: ["QT prolongation risk at higher doses", "Constipation common", "Headache is most frequent side effect"],
            sides: ["Headache", "Constipation", "Dizziness", "Fatigue"],
            interactions: ["Apomorphine — contraindicated, severe hypotension", "Serotonergic drugs — serotonin syndrome risk", "Phenytoin — reduced phenytoin levels"],
            foodInt: ["Can be taken with or without food", "Dissolving tablet: place on tongue without water"],
            desc: "A potent anti-nausea medication for chemotherapy, surgery, and pregnancy-related vomiting.", otc: false)

        add("Metoclopramide", brands: ["Reglan", "Maxolon"], cat: .gastrointestinal,
            therapeutic: "Dopamine Antagonist / Prokinetic", active: "Metoclopramide Hydrochloride",
            forms: [.tablet, .liquid, .injection], dosages: ["5mg", "10mg"],
            defDose: "10", defUnit: "mg", freq: .thrice,
            warnings: ["Black box: tardive dyskinesia with prolonged use", "Limit use to 12 weeks", "Avoid in Parkinson disease"],
            sides: ["Drowsiness", "Restlessness", "Diarrhea", "Tardive dyskinesia"],
            interactions: ["Levodopa — mutual antagonism", "CNS depressants — additive sedation", "Opioids — antagonized GI motility effects"],
            foodInt: ["Take 30 minutes before meals", "Avoid alcohol"],
            desc: "A prokinetic antiemetic that speeds stomach emptying, used for gastroparesis and nausea.", otc: false)

        add("Bisacodyl", brands: ["Dulcolax"], cat: .gastrointestinal,
            therapeutic: "Stimulant Laxative", active: "Bisacodyl",
            forms: [.tablet, .suppository], dosages: ["5mg", "10mg"],
            defDose: "5", defUnit: "mg", freq: .daily,
            warnings: ["Not for long-term daily use", "Do not chew enteric-coated tablets", "Abdominal cramps expected"],
            sides: ["Abdominal cramps", "Diarrhea", "Nausea", "Electrolyte imbalance"],
            interactions: ["Antacids — premature dissolution of coating (cramps)", "Diuretics — additive electrolyte loss", "Milk — dissolves coating, take 1 hour apart"],
            foodInt: ["Do not take with milk or antacids", "Take on empty stomach for overnight effect"],
            desc: "A stimulant laxative for occasional constipation and bowel preparation before procedures.", otc: true)

        add("Lactulose", brands: ["Duphalac", "Enulose", "Kristalose"], cat: .gastrointestinal,
            therapeutic: "Osmotic Laxative", active: "Lactulose",
            forms: [.liquid, .powder], dosages: ["10g/15mL", "15mL", "30mL"],
            defDose: "15", defUnit: "mL", freq: .daily,
            warnings: ["Electrolyte monitoring needed at high doses", "Diabetics: contains galactose and lactose", "May take 24-48 hours to work"],
            sides: ["Flatulence", "Bloating", "Abdominal cramps", "Diarrhea"],
            interactions: ["Antacids — may reduce lactulose effect in hepatic encephalopathy", "Other laxatives — avoid combination", "Neomycin — variable interaction in hepatic encephalopathy"],
            foodInt: ["Can be mixed with juice or water", "Can be taken with or without food"],
            desc: "An osmotic laxative for constipation and to reduce ammonia levels in liver disease.", otc: true)

        add("Mesalamine", brands: ["Asacol", "Pentasa", "Lialda"], cat: .gastrointestinal,
            therapeutic: "5-Aminosalicylate (5-ASA)", active: "Mesalamine (Mesalazine)",
            forms: [.tablet, .capsule, .suppository], dosages: ["250mg", "400mg", "500mg", "800mg", "1.2g"],
            defDose: "800", defUnit: "mg", freq: .thrice,
            warnings: ["Monitor renal function", "Rare pancreatitis", "Report bloody diarrhea worsening"],
            sides: ["Headache", "Nausea", "Abdominal pain", "Diarrhea"],
            interactions: ["NSAIDs — increased nephrotoxicity risk", "Azathioprine — increased myelosuppression", "Warfarin — possible altered INR"],
            foodInt: ["Depends on formulation — check specific product", "Take consistently with or without food"],
            desc: "An anti-inflammatory drug that acts locally in the gut for ulcerative colitis maintenance.", otc: false)

        add("Domperidone", brands: ["Motilium"], cat: .gastrointestinal,
            therapeutic: "Dopamine Antagonist / Prokinetic", active: "Domperidone",
            forms: [.tablet, .liquid], dosages: ["10mg"],
            defDose: "10", defUnit: "mg", freq: .thrice,
            warnings: ["QT prolongation risk — use lowest dose for shortest time", "Not available in the US", "Avoid in hepatic impairment"],
            sides: ["Headache", "Dry mouth", "Galactorrhea", "QT prolongation"],
            interactions: ["CYP3A4 inhibitors (ketoconazole) — increased domperidone and QT risk", "QT-prolonging drugs — additive risk", "Anticholinergics — antagonized prokinetic effect"],
            foodInt: ["Take 15-30 minutes before meals", "Take before bedtime dose"],
            desc: "A prokinetic for nausea and gastroparesis that does not cross the blood-brain barrier significantly.", otc: false)

        add("Sucralfate", brands: ["Carafate"], cat: .gastrointestinal,
            therapeutic: "Mucosal Protectant", active: "Sucralfate",
            forms: [.tablet, .liquid], dosages: ["500mg", "1g"],
            defDose: "1", defUnit: "g", freq: .thrice,
            warnings: ["Take on empty stomach", "Separate from other drugs by 2 hours", "Contains aluminum — avoid in renal failure"],
            sides: ["Constipation", "Dry mouth", "Nausea", "Headache"],
            interactions: ["Fluoroquinolones — markedly reduced absorption", "Phenytoin — reduced absorption", "Levothyroxine — reduced absorption"],
            foodInt: ["Take 1 hour before meals on empty stomach", "Separate from food by at least 1 hour"],
            desc: "A mucosal protectant that forms a barrier over ulcers to protect them from acid and promote healing.", otc: false)

        add("Polyethylene Glycol", brands: ["Miralax", "GoLytely", "Movicol"], cat: .gastrointestinal,
            therapeutic: "Osmotic Laxative", active: "Polyethylene Glycol 3350",
            forms: [.powder], dosages: ["17g"],
            defDose: "17", defUnit: "g", freq: .daily,
            warnings: ["Not for children under 2 without prescription", "Limit use to 7 days OTC without medical advice", "Diarrhea indicates overuse"],
            sides: ["Bloating", "Nausea", "Cramping", "Flatulence"],
            interactions: ["No significant drug interactions", "May alter absorption of other drugs if causing diarrhea", "Starch-based thickeners — decreased thickening effect"],
            foodInt: ["Mix in 8 oz of water or beverage", "Can be taken with or without food"],
            desc: "A gentle osmotic laxative that draws water into the colon to soften stool and relieve constipation.", otc: true)


        // ============================================================
        // MARK: - Mental Health (20)
        // ============================================================

        add("Sertraline", brands: ["Zoloft", "Serlift", "Daxid"], cat: .mentalHealth,
            therapeutic: "SSRI Antidepressant", active: "Sertraline Hydrochloride",
            forms: [.tablet, .liquid], dosages: ["25mg", "50mg", "100mg", "150mg", "200mg"],
            defDose: "50", defUnit: "mg", freq: .daily,
            warnings: ["Black box: increased suicidality in youth under 25", "Do not stop abruptly — taper", "Serotonin syndrome risk with other serotonergic drugs"],
            sides: ["Nausea", "Diarrhea", "Insomnia", "Sexual dysfunction"],
            interactions: ["MAO inhibitors — contraindicated, serotonin syndrome", "Warfarin — increased bleeding", "Tramadol — serotonin syndrome risk"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol"],
            desc: "The most prescribed antidepressant worldwide, used for depression, anxiety, PTSD, and OCD.", otc: false)

        add("Fluoxetine", brands: ["Prozac", "Sarafem", "Fludac", "Flunil"], cat: .mentalHealth,
            therapeutic: "SSRI Antidepressant", active: "Fluoxetine Hydrochloride",
            forms: [.capsule, .tablet, .liquid], dosages: ["10mg", "20mg", "40mg", "60mg"],
            defDose: "20", defUnit: "mg", freq: .daily,
            warnings: ["Long half-life — drug interactions persist after stopping", "Suicidality risk in young adults", "Mania risk in bipolar disorder"],
            sides: ["Nausea", "Headache", "Insomnia", "Anxiety"],
            interactions: ["MAO inhibitors — serotonin syndrome", "Tamoxifen — reduced tamoxifen efficacy", "Thioridazine — QT prolongation, contraindicated"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol"],
            desc: "A long-acting SSRI for depression, OCD, bulimia, and panic disorder.", otc: false)

        add("Escitalopram", brands: ["Lexapro", "Cipralex"], cat: .mentalHealth,
            therapeutic: "SSRI Antidepressant", active: "Escitalopram Oxalate",
            forms: [.tablet, .liquid], dosages: ["5mg", "10mg", "20mg"],
            defDose: "10", defUnit: "mg", freq: .daily,
            warnings: ["QT prolongation at doses above 20mg", "Suicidality risk in youth", "Taper gradually to discontinue"],
            sides: ["Nausea", "Insomnia", "Fatigue", "Sexual dysfunction"],
            interactions: ["MAO inhibitors — serotonin syndrome", "Cimetidine — increased escitalopram levels", "NSAIDs — increased bleeding risk"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol"],
            desc: "The most selective SSRI for depression and generalized anxiety disorder with a clean side effect profile.", otc: false)

        add("Citalopram", brands: ["Celexa"], cat: .mentalHealth,
            therapeutic: "SSRI Antidepressant", active: "Citalopram Hydrobromide",
            forms: [.tablet, .liquid], dosages: ["10mg", "20mg", "40mg"],
            defDose: "20", defUnit: "mg", freq: .daily,
            warnings: ["Maximum 40mg/day due to QT prolongation", "Dose-dependent QT risk", "Taper to discontinue"],
            sides: ["Nausea", "Dry mouth", "Drowsiness", "Sexual dysfunction"],
            interactions: ["MAO inhibitors — serotonin syndrome", "Pimozide — contraindicated", "QT-prolonging drugs — additive QT risk"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol"],
            desc: "An SSRI for depression with a dose ceiling of 40mg due to cardiac rhythm concerns.", otc: false)

        add("Paroxetine", brands: ["Paxil", "Seroxat"], cat: .mentalHealth,
            therapeutic: "SSRI Antidepressant", active: "Paroxetine Hydrochloride",
            forms: [.tablet, .liquid], dosages: ["10mg", "20mg", "30mg", "40mg"],
            defDose: "20", defUnit: "mg", freq: .daily,
            warnings: ["Worst SSRI for discontinuation syndrome — taper very slowly", "Contraindicated in pregnancy (category D)", "Weight gain more common than other SSRIs"],
            sides: ["Drowsiness", "Weight gain", "Sexual dysfunction", "Dry mouth"],
            interactions: ["MAO inhibitors — serotonin syndrome", "Tamoxifen — significantly reduced efficacy", "Thioridazine — QT prolongation"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol"],
            desc: "An SSRI for depression, anxiety, and PTSD that requires very gradual tapering to discontinue.", otc: false)

        add("Venlafaxine", brands: ["Effexor", "Efexor"], cat: .mentalHealth,
            therapeutic: "SNRI Antidepressant", active: "Venlafaxine Hydrochloride",
            forms: [.capsule, .tablet], dosages: ["37.5mg", "75mg", "150mg", "225mg"],
            defDose: "75", defUnit: "mg", freq: .daily,
            warnings: ["Monitor blood pressure — dose-related hypertension", "Severe discontinuation syndrome", "Suicidality risk in youth"],
            sides: ["Nausea", "Headache", "Insomnia", "Dizziness"],
            interactions: ["MAO inhibitors — serotonin syndrome", "CYP2D6 inhibitors — increased venlafaxine levels", "Tramadol — seizure and serotonin syndrome risk"],
            foodInt: ["Take with food", "Avoid alcohol"],
            desc: "An SNRI for depression, anxiety, and panic disorder that also helps with pain at higher doses.", otc: false)

        add("Duloxetine", brands: ["Cymbalta"], cat: .mentalHealth,
            therapeutic: "SNRI Antidepressant", active: "Duloxetine Hydrochloride",
            forms: [.capsule], dosages: ["20mg", "30mg", "60mg", "90mg", "120mg"],
            defDose: "60", defUnit: "mg", freq: .daily,
            warnings: ["Avoid in heavy alcohol use — hepatotoxicity", "Do not open or crush capsules", "Discontinuation syndrome — taper slowly"],
            sides: ["Nausea", "Dry mouth", "Fatigue", "Constipation"],
            interactions: ["MAO inhibitors — serotonin syndrome", "CYP1A2 inhibitors (fluvoxamine) — greatly increased levels", "Thioridazine — contraindicated"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol — liver damage risk"],
            desc: "An SNRI for depression, anxiety, diabetic neuropathy, fibromyalgia, and chronic musculoskeletal pain.", otc: false)

        add("Bupropion", brands: ["Wellbutrin", "Zyban"], cat: .mentalHealth,
            therapeutic: "NDRI Antidepressant", active: "Bupropion Hydrochloride",
            forms: [.tablet], dosages: ["75mg", "100mg", "150mg", "300mg"],
            defDose: "150", defUnit: "mg", freq: .daily,
            warnings: ["Dose-related seizure risk", "Contraindicated in eating disorders", "Do not crush extended-release forms"],
            sides: ["Insomnia", "Dry mouth", "Headache", "Agitation"],
            interactions: ["MAO inhibitors — hypertensive crisis", "CYP2D6 substrates — increased levels of other drugs", "Alcohol — increased seizure risk"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol — seizure risk"],
            desc: "A unique antidepressant that does not cause sexual dysfunction or weight gain, also used for smoking cessation.", otc: false)

        add("Mirtazapine", brands: ["Remeron"], cat: .mentalHealth,
            therapeutic: "NaSSA Antidepressant", active: "Mirtazapine",
            forms: [.tablet], dosages: ["7.5mg", "15mg", "30mg", "45mg"],
            defDose: "15", defUnit: "mg", freq: .daily,
            warnings: ["Significant sedation and weight gain", "Take at bedtime", "Agranulocytosis (rare) — report fever or sore throat"],
            sides: ["Drowsiness", "Weight gain", "Increased appetite", "Dry mouth"],
            interactions: ["MAO inhibitors — serotonin syndrome", "CNS depressants — additive sedation", "CYP3A4 inhibitors — increased mirtazapine levels"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol — additive sedation"],
            desc: "A sedating antidepressant useful for depression with insomnia and poor appetite.", otc: false)

        add("Amitriptyline", brands: ["Elavil"], cat: .mentalHealth,
            therapeutic: "Tricyclic Antidepressant (TCA)", active: "Amitriptyline Hydrochloride",
            forms: [.tablet], dosages: ["10mg", "25mg", "50mg", "75mg", "100mg"],
            defDose: "25", defUnit: "mg", freq: .daily,
            warnings: ["Cardiotoxic in overdose", "Anticholinergic effects — avoid in elderly", "Orthostatic hypotension risk"],
            sides: ["Drowsiness", "Dry mouth", "Constipation", "Weight gain"],
            interactions: ["MAO inhibitors — contraindicated", "CYP2D6 inhibitors — increased amitriptyline levels", "Anticholinergics — additive effects"],
            foodInt: ["Can be taken with food", "Avoid alcohol"],
            desc: "A tricyclic antidepressant now mainly used for neuropathic pain, migraine prevention, and insomnia.", otc: false)

        add("Alprazolam", brands: ["Xanax"], cat: .mentalHealth,
            therapeutic: "Benzodiazepine", active: "Alprazolam",
            forms: [.tablet], dosages: ["0.25mg", "0.5mg", "1mg", "2mg"],
            defDose: "0.25", defUnit: "mg", freq: .thrice,
            warnings: ["High dependence and addiction potential", "Do not stop abruptly — seizure risk", "Avoid in respiratory depression"],
            sides: ["Drowsiness", "Dizziness", "Memory impairment", "Paradoxical agitation"],
            interactions: ["Opioids — respiratory depression, potentially fatal", "CYP3A4 inhibitors (ketoconazole) — increased levels", "Alcohol — dangerous CNS depression"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol — potentially fatal"],
            desc: "A fast-acting benzodiazepine for panic disorder and acute anxiety, intended for short-term use only.", otc: false)

        add("Diazepam", brands: ["Valium"], cat: .mentalHealth,
            therapeutic: "Benzodiazepine", active: "Diazepam",
            forms: [.tablet, .liquid, .injection], dosages: ["2mg", "5mg", "10mg"],
            defDose: "5", defUnit: "mg", freq: .twice,
            warnings: ["Long half-life with active metabolites", "Dependence risk", "Accumulates in elderly"],
            sides: ["Drowsiness", "Fatigue", "Ataxia", "Memory impairment"],
            interactions: ["Opioids — fatal respiratory depression", "Cimetidine — increased diazepam levels", "Alcohol — severe CNS depression"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol"],
            desc: "A long-acting benzodiazepine for anxiety, muscle spasms, seizures, and alcohol withdrawal.", otc: false)

        add("Lorazepam", brands: ["Ativan"], cat: .mentalHealth,
            therapeutic: "Benzodiazepine", active: "Lorazepam",
            forms: [.tablet, .injection], dosages: ["0.5mg", "1mg", "2mg"],
            defDose: "1", defUnit: "mg", freq: .twice,
            warnings: ["Dependence risk", "Taper to discontinue", "Preferred in liver disease — no active metabolites"],
            sides: ["Sedation", "Dizziness", "Weakness", "Unsteadiness"],
            interactions: ["Opioids — respiratory depression", "CNS depressants — additive sedation", "Valproic acid — increased lorazepam levels"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol"],
            desc: "An intermediate-acting benzodiazepine for anxiety, insomnia, and acute seizures.", otc: false)

        add("Clonazepam", brands: ["Klonopin", "Rivotril"], cat: .mentalHealth,
            therapeutic: "Benzodiazepine", active: "Clonazepam",
            forms: [.tablet], dosages: ["0.25mg", "0.5mg", "1mg", "2mg"],
            defDose: "0.5", defUnit: "mg", freq: .twice,
            warnings: ["Dependence risk with chronic use", "Taper very slowly to avoid seizures", "Drowsiness impairs driving"],
            sides: ["Drowsiness", "Cognitive impairment", "Depression", "Ataxia"],
            interactions: ["Opioids — fatal respiratory depression", "Phenytoin — variable interaction", "CNS depressants — additive effects"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol"],
            desc: "A long-acting benzodiazepine for seizure disorders, panic disorder, and certain movement disorders.", otc: false)

        add("Quetiapine", brands: ["Seroquel"], cat: .mentalHealth,
            therapeutic: "Atypical Antipsychotic", active: "Quetiapine Fumarate",
            forms: [.tablet], dosages: ["25mg", "50mg", "100mg", "200mg", "300mg", "400mg"],
            defDose: "100", defUnit: "mg", freq: .twice,
            warnings: ["Black box: increased mortality in elderly with dementia", "Metabolic syndrome risk", "Monitor blood glucose and lipids"],
            sides: ["Sedation", "Weight gain", "Dizziness", "Dry mouth"],
            interactions: ["CYP3A4 inhibitors — increased quetiapine levels", "Phenytoin — reduced quetiapine levels", "CNS depressants — additive sedation"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol"],
            desc: "An atypical antipsychotic for schizophrenia, bipolar disorder, and adjunctive depression treatment.", otc: false)

        add("Olanzapine", brands: ["Zyprexa"], cat: .mentalHealth,
            therapeutic: "Atypical Antipsychotic", active: "Olanzapine",
            forms: [.tablet, .injection], dosages: ["2.5mg", "5mg", "10mg", "15mg", "20mg"],
            defDose: "10", defUnit: "mg", freq: .daily,
            warnings: ["Significant weight gain and metabolic effects", "Monitor glucose, lipids, and weight", "Elderly dementia mortality risk"],
            sides: ["Weight gain", "Sedation", "Hyperglycemia", "Dyslipidemia"],
            interactions: ["Fluvoxamine — increased olanzapine levels", "Carbamazepine — reduced olanzapine levels", "CNS depressants — additive sedation"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol"],
            desc: "An atypical antipsychotic for schizophrenia and bipolar disorder with significant metabolic side effects.", otc: false)

        add("Risperidone", brands: ["Risperdal"], cat: .mentalHealth,
            therapeutic: "Atypical Antipsychotic", active: "Risperidone",
            forms: [.tablet, .liquid, .injection], dosages: ["0.25mg", "0.5mg", "1mg", "2mg", "3mg", "4mg"],
            defDose: "2", defUnit: "mg", freq: .daily,
            warnings: ["Hyperprolactinemia common", "EPS risk higher than other atypicals", "Elderly dementia mortality risk"],
            sides: ["EPS/tremor", "Hyperprolactinemia", "Weight gain", "Sedation"],
            interactions: ["CYP2D6 inhibitors — increased risperidone levels", "Carbamazepine — reduced risperidone levels", "CNS depressants — additive sedation"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol"],
            desc: "An atypical antipsychotic for schizophrenia, bipolar mania, and irritability in autism.", otc: false)

        add("Aripiprazole", brands: ["Abilify"], cat: .mentalHealth,
            therapeutic: "Atypical Antipsychotic — Partial Dopamine Agonist", active: "Aripiprazole",
            forms: [.tablet, .liquid, .injection], dosages: ["2mg", "5mg", "10mg", "15mg", "20mg", "30mg"],
            defDose: "10", defUnit: "mg", freq: .daily,
            warnings: ["Compulsive behavior reported (gambling, eating)", "Less metabolic effects than other antipsychotics", "Akathisia (restlessness) common"],
            sides: ["Akathisia", "Insomnia", "Nausea", "Headache"],
            interactions: ["CYP2D6 inhibitors — reduce aripiprazole dose by 50%", "CYP3A4 inhibitors — reduce dose", "CYP3A4 inducers (carbamazepine) — increase dose"],
            foodInt: ["Can be taken with or without food", "Avoid alcohol"],
            desc: "A unique partial dopamine agonist antipsychotic for schizophrenia, bipolar disorder, and adjunctive depression treatment.", otc: false)

        add("Lithium", brands: ["Lithobid", "Eskalith"], cat: .mentalHealth,
            therapeutic: "Mood Stabilizer", active: "Lithium Carbonate",
            forms: [.tablet, .capsule, .liquid], dosages: ["150mg", "300mg", "450mg", "600mg"],
            defDose: "300", defUnit: "mg", freq: .twice,
            warnings: ["Narrow therapeutic index — regular blood level monitoring required", "Toxicity causes tremor, confusion, seizures", "Maintain consistent salt and water intake"],
            sides: ["Tremor", "Weight gain", "Polyuria", "Thyroid dysfunction"],
            interactions: ["NSAIDs — increased lithium levels", "ACE inhibitors — increased lithium levels", "Diuretics — increased lithium levels and toxicity"],
            foodInt: ["Take with food to reduce GI upset", "Maintain consistent salt and fluid intake"],
            desc: "The gold standard mood stabilizer for bipolar disorder, requiring regular blood level monitoring.", otc: false)

        add("Buspirone", brands: ["Buspar"], cat: .mentalHealth,
            therapeutic: "Azapirone Anxiolytic", active: "Buspirone Hydrochloride",
            forms: [.tablet], dosages: ["5mg", "7.5mg", "10mg", "15mg"],
            defDose: "10", defUnit: "mg", freq: .twice,
            warnings: ["Takes 2-4 weeks for full effect", "Not effective for acute anxiety or panic", "No dependence risk — unlike benzodiazepines"],
            sides: ["Dizziness", "Nausea", "Headache", "Nervousness"],
            interactions: ["MAO inhibitors — hypertensive crisis", "CYP3A4 inhibitors — increased buspirone levels", "Grapefruit juice — significantly increased levels"],
            foodInt: ["Take consistently with or without food", "Avoid large amounts of grapefruit juice"],
            desc: "A non-addictive anxiolytic for generalized anxiety disorder that does not cause dependence or sedation.", otc: false)


        // ============================================================
        // MARK: - Hormones (10)
        // ============================================================

        add("Levothyroxine", brands: ["Synthroid", "Eltroxin", "Euthyrox", "Levoxyl"], cat: .hormones,
            therapeutic: "Thyroid Hormone Replacement", active: "Levothyroxine Sodium",
            forms: [.tablet, .capsule, .liquid], dosages: ["25mcg", "50mcg", "75mcg", "88mcg", "100mcg", "112mcg", "125mcg", "150mcg"],
            defDose: "50", defUnit: "mcg", freq: .daily,
            warnings: ["Take on empty stomach 30-60 min before breakfast", "Many absorption interactions", "Do not switch brands without physician guidance"],
            sides: ["Palpitations (if dose too high)", "Weight loss (dose-related)", "Insomnia", "Heat intolerance"],
            interactions: ["Calcium/iron supplements — reduced absorption (separate by 4 hours)", "Warfarin — increased bleeding risk", "PPIs — may reduce absorption"],
            foodInt: ["Take on empty stomach with water only", "Separate from coffee, food, and supplements by 30-60 minutes"],
            desc: "Synthetic thyroid hormone replacement for hypothyroidism, one of the most prescribed drugs worldwide.", otc: false)

        add("Estradiol", brands: ["Estrace", "Climara", "Divigel"], cat: .hormones,
            therapeutic: "Estrogen Hormone", active: "Estradiol",
            forms: [.tablet, .patch, .topical], dosages: ["0.5mg", "1mg", "2mg"],
            defDose: "1", defUnit: "mg", freq: .daily,
            warnings: ["Increased risk of blood clots and stroke", "Breast cancer risk with prolonged use", "Use lowest effective dose for shortest duration"],
            sides: ["Breast tenderness", "Headache", "Nausea", "Bloating"],
            interactions: ["CYP3A4 inducers (rifampin) — reduced estradiol levels", "Thyroid hormones — may need dose increase", "Warfarin — altered anticoagulant effect"],
            foodInt: ["Can be taken with or without food", "Avoid grapefruit juice"],
            desc: "A bioidentical estrogen for menopausal symptoms and osteoporosis prevention.", otc: false)

        add("Progesterone", brands: ["Prometrium", "Utrogestan"], cat: .hormones,
            therapeutic: "Progestogen", active: "Micronized Progesterone",
            forms: [.capsule, .injection, .topical], dosages: ["100mg", "200mg"],
            defDose: "200", defUnit: "mg", freq: .daily,
            warnings: ["Take at bedtime — causes drowsiness", "Peanut allergy — some formulations contain peanut oil", "Use with estrogen to protect uterus"],
            sides: ["Dizziness", "Drowsiness", "Breast tenderness", "Bloating"],
            interactions: ["CYP3A4 inducers — reduced levels", "Ketoconazole — increased progesterone levels", "CNS depressants — additive sedation"],
            foodInt: ["Take at bedtime with food for better absorption", "Avoid alcohol — additive drowsiness"],
            desc: "A natural progesterone for menstrual disorders, menopausal HRT, and pregnancy support.", otc: false)

        add("Testosterone", brands: ["AndroGel", "Testim", "Axiron"], cat: .hormones,
            therapeutic: "Androgen Hormone", active: "Testosterone",
            forms: [.topical, .injection, .patch], dosages: ["1%", "1.62%", "50mg/5g", "100mg/mL"],
            defDose: "50", defUnit: "mg", freq: .daily,
            warnings: ["Black box: secondary exposure risk to women and children", "Monitor PSA and hematocrit", "Cardiovascular risk in older men"],
            sides: ["Acne", "Polycythemia", "Skin irritation (topical)", "Mood changes"],
            interactions: ["Warfarin — increased bleeding risk", "Insulin — increased insulin sensitivity", "Corticosteroids — additive fluid retention"],
            foodInt: ["Not applicable — topical/injection", "Apply gel to shoulders/upper arms, let dry before dressing"],
            desc: "Testosterone replacement for male hypogonadism, improving energy, mood, and muscle mass.", otc: false)

        add("Medroxyprogesterone", brands: ["Provera", "Depo-Provera"], cat: .hormones,
            therapeutic: "Progestin", active: "Medroxyprogesterone Acetate",
            forms: [.tablet, .injection], dosages: ["2.5mg", "5mg", "10mg", "150mg injection"],
            defDose: "10", defUnit: "mg", freq: .daily,
            warnings: ["Black box (Depo): bone density loss with prolonged use", "May cause irregular bleeding", "Not for use in pregnancy"],
            sides: ["Weight gain", "Irregular bleeding", "Headache", "Mood changes"],
            interactions: ["CYP3A4 inducers — reduced efficacy", "Aminoglutethimide — reduced medroxyprogesterone levels", "Warfarin — altered coagulation"],
            foodInt: ["Can be taken with or without food", "No specific food restrictions"],
            desc: "A synthetic progestin for abnormal uterine bleeding, contraception (Depo shot), and endometriosis.", otc: false)

        add("Combined OCP (Ethinyl Estradiol/Drospirenone)", brands: ["Yasmin", "Yaz"], cat: .hormones,
            therapeutic: "Combined Oral Contraceptive", active: "Ethinyl Estradiol + Drospirenone",
            forms: [.tablet], dosages: ["0.03mg/3mg", "0.02mg/3mg"],
            defDose: "0.03/3", defUnit: "mg", freq: .daily,
            warnings: ["Blood clot risk — avoid in smokers over 35", "Take at same time daily", "Drospirenone has anti-mineralocorticoid activity — monitor potassium"],
            sides: ["Nausea", "Breast tenderness", "Headache", "Breakthrough bleeding"],
            interactions: ["Rifampin — significantly reduced contraceptive efficacy", "Anticonvulsants (carbamazepine, phenytoin) — reduced efficacy", "Potassium-sparing diuretics — hyperkalemia with drospirenone"],
            foodInt: ["Can be taken with or without food", "Consistent daily timing is critical"],
            desc: "A combined hormonal contraceptive pill that also helps with acne and premenstrual symptoms.", otc: false)

        add("Tamoxifen", brands: ["Nolvadex", "Soltamox"], cat: .hormones,
            therapeutic: "Selective Estrogen Receptor Modulator (SERM)", active: "Tamoxifen Citrate",
            forms: [.tablet], dosages: ["10mg", "20mg"],
            defDose: "20", defUnit: "mg", freq: .daily,
            warnings: ["Endometrial cancer risk", "Blood clot risk", "Hot flashes are common"],
            sides: ["Hot flashes", "Vaginal discharge", "Blood clots", "Endometrial changes"],
            interactions: ["CYP2D6 inhibitors (fluoxetine, paroxetine) — reduced tamoxifen efficacy", "Warfarin — increased bleeding", "Aromatase inhibitors — do not combine"],
            foodInt: ["Can be taken with or without food", "No specific food restrictions"],
            desc: "An estrogen receptor modulator for breast cancer treatment and prevention in high-risk women.", otc: false)

        add("Letrozole", brands: ["Femara"], cat: .hormones,
            therapeutic: "Aromatase Inhibitor", active: "Letrozole",
            forms: [.tablet], dosages: ["2.5mg"],
            defDose: "2.5", defUnit: "mg", freq: .daily,
            warnings: ["Bone density loss — monitor and supplement calcium/vitamin D", "Not for premenopausal women", "Arthralgias very common"],
            sides: ["Hot flashes", "Joint pain", "Fatigue", "Osteoporosis"],
            interactions: ["Tamoxifen — reduced letrozole levels", "Estrogen-containing products — counteract efficacy", "CYP3A4 inhibitors — possible increased levels"],
            foodInt: ["Can be taken with or without food", "No specific restrictions"],
            desc: "An aromatase inhibitor for hormone-receptor-positive breast cancer in postmenopausal women.", otc: false)

        add("Desmopressin", brands: ["DDAVP", "Stimate"], cat: .hormones,
            therapeutic: "Vasopressin Analog", active: "Desmopressin Acetate",
            forms: [.tablet, .liquid, .injection], dosages: ["0.1mg", "0.2mg", "10mcg nasal"],
            defDose: "0.2", defUnit: "mg", freq: .twice,
            warnings: ["Hyponatremia risk — restrict fluid intake", "Monitor sodium levels", "Avoid in conditions with fluid overload"],
            sides: ["Headache", "Hyponatremia", "Nausea", "Nasal congestion (spray)"],
            interactions: ["Carbamazepine — enhanced antidiuretic effect", "NSAIDs — increased hyponatremia risk", "Tricyclic antidepressants — enhanced antidiuretic effect"],
            foodInt: ["Restrict fluid intake as directed", "Take tablets 30 minutes before meals"],
            desc: "A synthetic vasopressin for diabetes insipidus, bedwetting, and certain bleeding disorders.", otc: false)

        add("Octreotide", brands: ["Sandostatin"], cat: .hormones,
            therapeutic: "Somatostatin Analog", active: "Octreotide Acetate",
            forms: [.injection], dosages: ["50mcg", "100mcg", "200mcg", "500mcg"],
            defDose: "100", defUnit: "mcg", freq: .thrice,
            warnings: ["Gallstone risk with chronic use", "Monitor glucose — may cause hypo or hyperglycemia", "Injection site rotation required"],
            sides: ["Diarrhea", "Abdominal pain", "Gallstones", "Injection site pain"],
            interactions: ["Cyclosporine — reduced cyclosporine levels", "Insulin — altered glucose control", "Bromocriptine — increased octreotide bioavailability"],
            foodInt: ["Inject between meals or at bedtime", "No specific food restrictions"],
            desc: "A somatostatin analog for acromegaly, carcinoid tumors, and variceal bleeding.", otc: false)

        // ============================================================
        // MARK: - Blood Thinners (10)
        // ============================================================

        add("Warfarin", brands: ["Coumadin", "Jantoven"], cat: .bloodThinners,
            therapeutic: "Vitamin K Antagonist", active: "Warfarin Sodium",
            forms: [.tablet], dosages: ["1mg", "2mg", "2.5mg", "3mg", "4mg", "5mg", "7.5mg", "10mg"],
            defDose: "5", defUnit: "mg", freq: .daily,
            warnings: ["Requires regular INR monitoring", "Highly variable dosing", "Bleeding risk — carry ID card"],
            sides: ["Bleeding", "Bruising", "Hair loss", "Skin necrosis (rare)"],
            interactions: ["Aspirin/NSAIDs — greatly increased bleeding", "Amiodarone — significantly increased INR", "Rifampin — greatly reduced warfarin effect"],
            foodInt: ["Maintain consistent vitamin K intake (green leafy vegetables)", "Avoid cranberry juice in large amounts"],
            desc: "The oldest oral anticoagulant for preventing blood clots in atrial fibrillation, DVT, and mechanical heart valves.", otc: false)

        add("Heparin", brands: ["Heparin Sodium"], cat: .bloodThinners,
            therapeutic: "Unfractionated Heparin", active: "Heparin Sodium",
            forms: [.injection], dosages: ["1000 units/mL", "5000 units/mL", "10000 units/mL"],
            defDose: "5000", defUnit: "units", freq: .twice,
            warnings: ["HIT (heparin-induced thrombocytopenia) risk", "Monitor aPTT for therapeutic dosing", "Protamine reverses effect"],
            sides: ["Bleeding", "HIT", "Injection site hematoma", "Osteoporosis with long-term use"],
            interactions: ["Aspirin — increased bleeding", "NSAIDs — increased bleeding risk", "Thrombolytics — increased hemorrhage risk"],
            foodInt: ["Not applicable — injection only", "No food restrictions"],
            desc: "An injectable anticoagulant for immediate blood clot prevention and treatment in hospitals.", otc: false)

        add("Enoxaparin", brands: ["Lovenox", "Clexane"], cat: .bloodThinners,
            therapeutic: "Low Molecular Weight Heparin", active: "Enoxaparin Sodium",
            forms: [.injection], dosages: ["20mg", "30mg", "40mg", "60mg", "80mg", "100mg"],
            defDose: "40", defUnit: "mg", freq: .daily,
            warnings: ["Spinal/epidural hematoma risk with neuraxial anesthesia", "Adjust dose in renal impairment", "Do not expel air bubble from prefilled syringe"],
            sides: ["Injection site bruising", "Bleeding", "Thrombocytopenia", "Elevated liver enzymes"],
            interactions: ["Aspirin — increased bleeding", "NSAIDs — increased bleeding", "Other anticoagulants — additive bleeding risk"],
            foodInt: ["Not applicable — injection only", "No food restrictions"],
            desc: "A subcutaneous blood thinner for DVT prevention after surgery and treatment of blood clots.", otc: false)

        add("Rivaroxaban", brands: ["Xarelto"], cat: .bloodThinners,
            therapeutic: "Direct Factor Xa Inhibitor", active: "Rivaroxaban",
            forms: [.tablet], dosages: ["2.5mg", "10mg", "15mg", "20mg"],
            defDose: "20", defUnit: "mg", freq: .daily,
            warnings: ["Take with food for 15mg and 20mg doses", "No routine monitoring needed but no easy reversal", "Spinal hematoma risk with epidurals"],
            sides: ["Bleeding", "Bruising", "Back pain", "Pruritus"],
            interactions: ["CYP3A4/P-gp inhibitors — increased levels and bleeding", "Rifampin — reduced rivaroxaban effect", "Aspirin — increased bleeding risk"],
            foodInt: ["Take 15mg and 20mg doses with food", "10mg dose can be taken with or without food"],
            desc: "A direct oral anticoagulant (DOAC) for atrial fibrillation, DVT, and PE that does not require routine monitoring.", otc: false)

        add("Apixaban", brands: ["Eliquis"], cat: .bloodThinners,
            therapeutic: "Direct Factor Xa Inhibitor", active: "Apixaban",
            forms: [.tablet], dosages: ["2.5mg", "5mg"],
            defDose: "5", defUnit: "mg", freq: .twice,
            warnings: ["Lowest bleeding risk among DOACs", "Do not stop without alternative anticoagulation", "Renal dose adjustment for certain criteria"],
            sides: ["Bleeding", "Bruising", "Nausea", "Anemia"],
            interactions: ["Strong CYP3A4/P-gp inhibitors — reduce dose", "Rifampin — avoid combination", "Aspirin — increased bleeding"],
            foodInt: ["Can be taken with or without food", "No specific food restrictions"],
            desc: "A direct oral anticoagulant with the lowest bleeding rate among DOACs for atrial fibrillation.", otc: false)

        add("Dabigatran", brands: ["Pradaxa"], cat: .bloodThinners,
            therapeutic: "Direct Thrombin Inhibitor", active: "Dabigatran Etexilate",
            forms: [.capsule], dosages: ["75mg", "110mg", "150mg"],
            defDose: "150", defUnit: "mg", freq: .twice,
            warnings: ["Do not open capsules — dramatically increases absorption", "Reversible with idarucizumab (Praxbind)", "Avoid in mechanical heart valves"],
            sides: ["Dyspepsia", "Bleeding", "GI upset", "Abdominal pain"],
            interactions: ["P-gp inhibitors (dronedarone) — increased levels", "P-gp inducers (rifampin) — reduced effect", "Aspirin — increased bleeding"],
            foodInt: ["Can be taken with or without food", "Do not remove from original packaging until use"],
            desc: "A direct thrombin inhibitor anticoagulant with a specific reversal agent available.", otc: false)

        add("Clopidogrel", brands: ["Plavix", "Clopilet", "Deplatt", "Clavix"], cat: .bloodThinners,
            therapeutic: "P2Y12 Platelet Inhibitor", active: "Clopidogrel Bisulfate",
            forms: [.tablet], dosages: ["75mg", "300mg loading"],
            defDose: "75", defUnit: "mg", freq: .daily,
            warnings: ["CYP2C19 poor metabolizers have reduced efficacy", "Do not stop abruptly after stent placement", "Bleeding risk with invasive procedures"],
            sides: ["Bleeding", "Bruising", "Rash", "Diarrhea"],
            interactions: ["Omeprazole — reduced clopidogrel activation (use pantoprazole instead)", "Aspirin — increased bleeding (but often used together)", "Warfarin — increased bleeding"],
            foodInt: ["Can be taken with or without food", "No specific food restrictions"],
            desc: "An antiplatelet drug to prevent heart attacks and strokes, especially after stent placement.", otc: false)

        add("Ticagrelor", brands: ["Brilinta"], cat: .bloodThinners,
            therapeutic: "P2Y12 Platelet Inhibitor", active: "Ticagrelor",
            forms: [.tablet], dosages: ["60mg", "90mg"],
            defDose: "90", defUnit: "mg", freq: .twice,
            warnings: ["Keep aspirin dose at 100mg or less when combined", "Dyspnea is common and usually benign", "Do not use with strong CYP3A4 inhibitors"],
            sides: ["Dyspnea", "Bleeding", "Headache", "Dizziness"],
            interactions: ["Strong CYP3A4 inhibitors — contraindicated", "Aspirin >100mg — reduced ticagrelor efficacy", "Simvastatin — limit simvastatin to 40mg"],
            foodInt: ["Can be taken with or without food", "No specific food restrictions"],
            desc: "A more potent antiplatelet than clopidogrel for acute coronary syndromes, taken twice daily.", otc: false)

        add("Prasugrel", brands: ["Effient"], cat: .bloodThinners,
            therapeutic: "P2Y12 Platelet Inhibitor", active: "Prasugrel Hydrochloride",
            forms: [.tablet], dosages: ["5mg", "10mg"],
            defDose: "10", defUnit: "mg", freq: .daily,
            warnings: ["Contraindicated with history of stroke/TIA", "Higher bleeding risk than clopidogrel", "Reduce dose in patients under 60kg"],
            sides: ["Bleeding", "Bruising", "Back pain", "Hypertension"],
            interactions: ["Warfarin — increased bleeding", "NSAIDs — increased bleeding", "Opioids — delayed prasugrel absorption"],
            foodInt: ["Can be taken with or without food", "No specific restrictions"],
            desc: "A potent antiplatelet for patients undergoing coronary stenting after heart attack.", otc: false)

        add("Dipyridamole", brands: ["Persantine", "Aggrenox"], cat: .bloodThinners,
            therapeutic: "Antiplatelet / Vasodilator", active: "Dipyridamole",
            forms: [.tablet, .capsule], dosages: ["25mg", "50mg", "75mg", "200mg ER"],
            defDose: "200", defUnit: "mg", freq: .twice,
            warnings: ["May cause headache initially", "Caution in coronary artery disease — coronary steal", "Caffeine and theophylline reduce efficacy"],
            sides: ["Headache", "Dizziness", "Nausea", "Abdominal pain"],
            interactions: ["Adenosine — potentiated effect", "Theophylline — blocks dipyridamole effect", "Aspirin — additive antiplatelet effect (used in Aggrenox)"],
            foodInt: ["Take on empty stomach 1 hour before meals", "Avoid excessive caffeine — blocks the drug"],
            desc: "An antiplatelet and vasodilator combined with aspirin for secondary stroke prevention.", otc: false)


        // ============================================================
        // MARK: - Cholesterol (10)
        // ============================================================

        add("Atorvastatin", brands: ["Lipitor", "Atorva", "Tonact", "Storvas", "Atocor"], cat: .cholesterol,
            therapeutic: "HMG-CoA Reductase Inhibitor (Statin)", active: "Atorvastatin Calcium",
            forms: [.tablet], dosages: ["10mg", "20mg", "40mg", "80mg"],
            defDose: "20", defUnit: "mg", freq: .daily,
            warnings: ["Report unexplained muscle pain immediately", "Monitor liver enzymes", "Rhabdomyolysis risk — rare but serious"],
            sides: ["Muscle pain", "Diarrhea", "Joint pain", "Elevated liver enzymes"],
            interactions: ["Clarithromycin — increased statin levels and myopathy", "Cyclosporine — increased atorvastatin levels", "Gemfibrozil — increased myopathy risk"],
            foodInt: ["Can be taken any time of day with or without food", "Avoid excessive grapefruit juice"],
            desc: "The most prescribed statin worldwide for lowering LDL cholesterol and reducing cardiovascular risk.", otc: false)

        add("Rosuvastatin", brands: ["Crestor", "Rozavel", "Rosuvas", "Rosulip"], cat: .cholesterol,
            therapeutic: "HMG-CoA Reductase Inhibitor (Statin)", active: "Rosuvastatin Calcium",
            forms: [.tablet], dosages: ["5mg", "10mg", "20mg", "40mg"],
            defDose: "10", defUnit: "mg", freq: .daily,
            warnings: ["Most potent statin — start at low dose in Asians", "Proteinuria at high doses", "Myopathy risk"],
            sides: ["Muscle pain", "Headache", "Abdominal pain", "Nausea"],
            interactions: ["Cyclosporine — contraindicated with rosuvastatin 40mg", "Gemfibrozil — limit rosuvastatin to 10mg", "Warfarin — increased INR"],
            foodInt: ["Can be taken with or without food", "Can be taken at any time of day"],
            desc: "The most potent statin, capable of lowering LDL cholesterol by up to 63%.", otc: false)

        add("Simvastatin", brands: ["Zocor"], cat: .cholesterol,
            therapeutic: "HMG-CoA Reductase Inhibitor (Statin)", active: "Simvastatin",
            forms: [.tablet], dosages: ["5mg", "10mg", "20mg", "40mg", "80mg"],
            defDose: "20", defUnit: "mg", freq: .daily,
            warnings: ["80mg dose restricted to those already stable on it", "Many drug interactions due to CYP3A4 metabolism", "Take in the evening"],
            sides: ["Muscle pain", "Constipation", "Headache", "Nausea"],
            interactions: ["Amlodipine — limit simvastatin to 20mg", "Amiodarone — limit simvastatin to 20mg", "CYP3A4 inhibitors — increased myopathy risk"],
            foodInt: ["Take in the evening (short half-life)", "Avoid grapefruit juice"],
            desc: "A statin best taken at night for optimal cholesterol reduction, with many dose-limiting interactions.", otc: false)

        add("Pravastatin", brands: ["Pravachol"], cat: .cholesterol,
            therapeutic: "HMG-CoA Reductase Inhibitor (Statin)", active: "Pravastatin Sodium",
            forms: [.tablet], dosages: ["10mg", "20mg", "40mg", "80mg"],
            defDose: "40", defUnit: "mg", freq: .daily,
            warnings: ["Fewest drug interactions among statins", "Monitor liver function", "Myopathy risk lower than other statins"],
            sides: ["Headache", "Nausea", "Rash", "Dizziness"],
            interactions: ["Cyclosporine — increased pravastatin levels", "Gemfibrozil — increased myopathy risk", "Colchicine — rare myopathy"],
            foodInt: ["Can be taken with or without food", "No grapefruit restriction"],
            desc: "A hydrophilic statin with the fewest drug interactions, suitable for patients on multiple medications.", otc: false)

        add("Lovastatin", brands: ["Mevacor", "Altoprev"], cat: .cholesterol,
            therapeutic: "HMG-CoA Reductase Inhibitor (Statin)", active: "Lovastatin",
            forms: [.tablet], dosages: ["10mg", "20mg", "40mg"],
            defDose: "20", defUnit: "mg", freq: .daily,
            warnings: ["Must take with evening meal for absorption", "CYP3A4 interactions similar to simvastatin", "Myopathy risk"],
            sides: ["Muscle pain", "GI upset", "Headache", "Rash"],
            interactions: ["Itraconazole — contraindicated", "Cyclosporine — limit to 20mg", "Amiodarone — limit to 40mg"],
            foodInt: ["Must take with evening meal", "Avoid grapefruit juice"],
            desc: "The first statin approved, derived from a natural fungal product, must be taken with food.", otc: false)

        add("Ezetimibe", brands: ["Zetia", "Ezetrol"], cat: .cholesterol,
            therapeutic: "Cholesterol Absorption Inhibitor", active: "Ezetimibe",
            forms: [.tablet], dosages: ["10mg"],
            defDose: "10", defUnit: "mg", freq: .daily,
            warnings: ["Monitor liver function when combined with statin", "Rare myopathy when combined with statin", "Not effective as monotherapy for most patients"],
            sides: ["Diarrhea", "Upper respiratory infection", "Joint pain", "Fatigue"],
            interactions: ["Cyclosporine — increased ezetimibe levels", "Fibrates — increased gallstone risk", "Cholestyramine — reduced ezetimibe absorption"],
            foodInt: ["Can be taken with or without food", "No specific food restrictions"],
            desc: "Blocks cholesterol absorption in the intestine, often added to a statin for additional LDL lowering.", otc: false)

        add("Fenofibrate", brands: ["Tricor", "Fenoglide", "Lipofen"], cat: .cholesterol,
            therapeutic: "Fibrate", active: "Fenofibrate",
            forms: [.tablet, .capsule], dosages: ["48mg", "54mg", "120mg", "145mg", "160mg"],
            defDose: "145", defUnit: "mg", freq: .daily,
            warnings: ["Monitor liver function", "Increased creatinine (reversible)", "Gallstone risk"],
            sides: ["Nausea", "Elevated liver enzymes", "Abdominal pain", "Increased creatinine"],
            interactions: ["Warfarin — significantly increased bleeding risk", "Statins — increased myopathy risk (gemfibrozil worse)", "Cyclosporine — increased nephrotoxicity"],
            foodInt: ["Take with food for better absorption", "No specific food restrictions"],
            desc: "A fibrate primarily for lowering high triglycerides and raising HDL cholesterol.", otc: false)

        add("Gemfibrozil", brands: ["Lopid"], cat: .cholesterol,
            therapeutic: "Fibrate", active: "Gemfibrozil",
            forms: [.tablet], dosages: ["600mg"],
            defDose: "600", defUnit: "mg", freq: .twice,
            warnings: ["Contraindicated with repaglinide and dasabuvir", "Increased myopathy risk with statins — use fenofibrate instead", "Gallstone risk"],
            sides: ["Dyspepsia", "Abdominal pain", "Diarrhea", "Fatigue"],
            interactions: ["Statins — high myopathy/rhabdomyolysis risk", "Repaglinide — contraindicated, severe hypoglycemia", "Warfarin — increased bleeding"],
            foodInt: ["Take 30 minutes before meals", "No specific food restrictions"],
            desc: "A fibrate for high triglycerides that has more drug interactions than fenofibrate.", otc: false)

        add("Alirocumab", brands: ["Praluent"], cat: .cholesterol,
            therapeutic: "PCSK9 Inhibitor", active: "Alirocumab",
            forms: [.injection], dosages: ["75mg", "150mg"],
            defDose: "75", defUnit: "mg", freq: .twice,
            warnings: ["Refrigerate — do not freeze", "Injection site rotation required", "Very expensive — insurance criteria apply"],
            sides: ["Injection site reactions", "Nasopharyngitis", "Flu-like symptoms", "Itching"],
            interactions: ["Statins — additive LDL reduction (used together)", "No significant drug-drug interactions", "No CYP450 interactions"],
            foodInt: ["Not applicable — injection", "No food restrictions"],
            desc: "A PCSK9 inhibitor injection for patients needing additional LDL lowering beyond statin therapy.", otc: false)

        add("Evolocumab", brands: ["Repatha"], cat: .cholesterol,
            therapeutic: "PCSK9 Inhibitor", active: "Evolocumab",
            forms: [.injection], dosages: ["140mg", "420mg"],
            defDose: "140", defUnit: "mg", freq: .twice,
            warnings: ["Refrigerate — bring to room temperature before injection", "Latex allergy — needle cap contains latex", "Injection site rotation"],
            sides: ["Injection site reactions", "Upper respiratory infection", "Back pain", "Muscle pain"],
            interactions: ["No significant drug interactions", "Statins — additive LDL lowering", "No CYP450 metabolism"],
            foodInt: ["Not applicable — injection", "No food restrictions"],
            desc: "A PCSK9 inhibitor that can lower LDL cholesterol by 60%, used when statins alone are insufficient.", otc: false)

        // ============================================================
        // MARK: - Thyroid (5)
        // ============================================================

        add("Liothyronine", brands: ["Cytomel", "Triostat"], cat: .thyroid,
            therapeutic: "Thyroid Hormone (T3)", active: "Liothyronine Sodium",
            forms: [.tablet, .injection], dosages: ["5mcg", "25mcg", "50mcg"],
            defDose: "25", defUnit: "mcg", freq: .daily,
            warnings: ["Rapid onset — cardiac risk in elderly", "Shorter half-life — inconsistent levels", "Not first-line for hypothyroidism"],
            sides: ["Palpitations", "Tachycardia", "Tremor", "Headache"],
            interactions: ["Warfarin — increased bleeding risk", "Insulin — may need to adjust diabetes medications", "Cholestyramine — reduced absorption"],
            foodInt: ["Take on empty stomach", "Separate from calcium and iron by 4 hours"],
            desc: "The active T3 thyroid hormone for patients not converting T4 adequately, with rapid onset.", otc: false)

        add("Methimazole", brands: ["Tapazole"], cat: .thyroid,
            therapeutic: "Antithyroid Agent", active: "Methimazole",
            forms: [.tablet], dosages: ["5mg", "10mg", "20mg"],
            defDose: "10", defUnit: "mg", freq: .daily,
            warnings: ["Agranulocytosis risk — report fever and sore throat immediately", "Teratogenic in first trimester — use PTU instead", "Monitor CBC and liver function"],
            sides: ["Rash", "Joint pain", "Nausea", "Agranulocytosis (rare)"],
            interactions: ["Warfarin — reduced anticoagulant effect as patient becomes euthyroid", "Beta-blockers — may need dose reduction as thyroid normalizes", "Digoxin — increased digoxin levels as thyroid normalizes"],
            foodInt: ["Can be taken with or without food", "No specific restrictions"],
            desc: "An antithyroid drug for hyperthyroidism that blocks thyroid hormone production.", otc: false)

        add("Propylthiouracil", brands: ["PTU"], cat: .thyroid,
            therapeutic: "Antithyroid Agent", active: "Propylthiouracil",
            forms: [.tablet], dosages: ["50mg"],
            defDose: "50", defUnit: "mg", freq: .thrice,
            warnings: ["Black box: hepatotoxicity including liver failure", "Preferred only in first trimester of pregnancy", "Agranulocytosis risk"],
            sides: ["Rash", "Hepatotoxicity", "Nausea", "Joint pain"],
            interactions: ["Warfarin — reduced warfarin effect", "Theophylline — increased theophylline levels", "Beta-blockers — reduced clearance as thyroid normalizes"],
            foodInt: ["Can be taken with or without food", "No specific restrictions"],
            desc: "An antithyroid drug reserved mainly for first-trimester pregnancy and thyroid storm due to liver toxicity risk.", otc: false)

        add("Carbimazole", brands: ["Neo-Mercazole"], cat: .thyroid,
            therapeutic: "Antithyroid Agent", active: "Carbimazole",
            forms: [.tablet], dosages: ["5mg", "10mg", "20mg"],
            defDose: "20", defUnit: "mg", freq: .daily,
            warnings: ["Prodrug of methimazole", "Agranulocytosis risk — same as methimazole", "Monitor blood counts regularly"],
            sides: ["Rash", "GI upset", "Joint pain", "Agranulocytosis"],
            interactions: ["Warfarin — altered effect as thyroid normalizes", "Beta-blockers — may need dose adjustment", "Iodine — may interfere with antithyroid action"],
            foodInt: ["Can be taken with or without food", "No specific restrictions"],
            desc: "A prodrug converted to methimazole in the body, widely used outside the US for hyperthyroidism.", otc: false)

        add("Lugol Iodine Solution", brands: ["Lugol Solution", "SSKI"], cat: .thyroid,
            therapeutic: "Iodine Supplement / Antithyroid", active: "Potassium Iodide",
            forms: [.liquid, .tablet], dosages: ["65mg", "130mg"],
            defDose: "130", defUnit: "mg", freq: .daily,
            warnings: ["Short-term use only for thyroid storm preparation", "May worsen thyroid disease long-term", "Metallic taste common"],
            sides: ["Metallic taste", "GI upset", "Salivary gland swelling", "Rash"],
            interactions: ["Lithium — additive hypothyroid effect", "Antithyroid drugs — additive thyroid suppression", "ACE inhibitors — hyperkalemia risk"],
            foodInt: ["Dilute in water or juice", "Take with food to reduce GI upset"],
            desc: "Potassium iodide used short-term before thyroid surgery and for thyroid storm to rapidly block hormone release.", otc: false)

        return db
    }
}

