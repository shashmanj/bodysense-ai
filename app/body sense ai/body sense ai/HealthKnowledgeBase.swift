//
//  HealthKnowledgeBase.swift
//  body sense ai
//
//  Domain-mapped knowledge distilled from 5 research volumes:
//  Vol 1: Health Research Knowledge Base — NCD epidemiology, diabetes, CVD, CKD, nutrition science
//  Vol 2: Natural & Traditional Medicine — Ayurveda, TCM, naturopathy, herbs, breathwork
//  Vol 3: Lifestyle Protocols — Circadian science, 6 body-type protocols, habit architecture
//  Vol 4: Complete Health A-Z — Skin, hair, dental, eye, men's/women's/children's health
//  Vol 5: Ancient Indian Wisdom — Vedic health, Gita psychology, yoga science, meditation
//
//  Architecture: Two-tier injection (compact for on-device AI, extended for cloud API).
//  Each domain pulls relevant facts from ALL 5 volumes.
//

import Foundation

// MARK: - Health Knowledge Base

enum HealthKnowledgeBase {

    // MARK: - Knowledge Tier

    enum Tier {
        case compact    // On-device Apple Foundation Models: ~300 tokens/domain
        case extended   // Cloud Claude Haiku via Railway: ~1500 tokens/domain
    }

    // MARK: - Public API

    /// Returns curated research knowledge for a given health domain and tier.
    /// Optionally filters by query relevance for extended tier.
    static func knowledge(for domain: HealthDomain, tier: Tier, query: String? = nil) -> String {
        let base = baseKnowledge(for: domain, tier: tier)

        // For extended tier with a query, do relevance filtering across sections
        if let query = query, tier == .extended, !query.isEmpty {
            return relevanceFilter(base: base, query: query)
        }
        return base
    }

    // MARK: - Domain → Knowledge Mapping

    private static func baseKnowledge(for domain: HealthDomain, tier: Tier) -> String {
        switch (domain, tier) {
        case (.medical, .compact):      return medicalCompact
        case (.medical, .extended):     return medicalExtended
        case (.nutrition, .compact):    return nutritionCompact
        case (.nutrition, .extended):   return nutritionExtended
        case (.fitness, .compact):      return fitnessCompact
        case (.fitness, .extended):     return fitnessExtended
        case (.chef, .compact):         return chefCompact
        case (.chef, .extended):        return chefExtended
        case (.sleep, .compact):        return sleepCompact
        case (.sleep, .extended):       return sleepExtended
        case (.mentalWellness, .compact):  return mentalWellnessCompact
        case (.mentalWellness, .extended): return mentalWellnessExtended
        case (.personalCare, .compact):    return personalCareCompact
        case (.personalCare, .extended):   return personalCareExtended
        case (.general, .compact):      return generalCompact
        case (.general, .extended):     return generalExtended
        }
    }

    // MARK: - Query-Aware Relevance Filtering

    private static func relevanceFilter(base: String, query: String) -> String {
        let queryWords = Set(query.lowercased().components(separatedBy: .whitespaces).filter { $0.count > 3 })
        let sections = base.components(separatedBy: "\n\n")

        guard sections.count > 3 else { return base }

        let scored = sections.map { section -> (String, Int) in
            let sectionLower = section.lowercased()
            let overlap = queryWords.filter { sectionLower.contains($0) }.count
            return (section, overlap)
        }

        // Keep header + top scoring sections, cap at ~1200 tokens
        let sorted = scored.sorted { $0.1 > $1.1 }
        var result: [String] = []
        var charCount = 0
        for (section, _) in sorted {
            if charCount + section.count > 5000 { break }
            result.append(section)
            charCount += section.count
        }
        return result.joined(separator: "\n\n")
    }

    // ═══════════════════════════════════════════════════════════════════════
    // MARK: - MEDICAL DOMAIN
    // Sources: Vol 1 (diabetes, CVD, CKD, obesity), Vol 2 (Ayurvedic herbs),
    //          Vol 4 (men's/women's health), Vol 5 (yoga clinical evidence)
    // ═══════════════════════════════════════════════════════════════════════

    private static let medicalCompact = """
    RESEARCH KNOWLEDGE:
    NCDs: 41M deaths/yr (74% global), 80% preventable via lifestyle. CVD #1 killer (17.9M/yr). \
    Diabetes: 537M globally, 5.8M UK. South Asians: 6x higher risk, onset 8.2yr earlier, BMI 23 = metabolic risk (not 30). \
    HbA1c target <48 mmol/mol. BP target <140/90 clinic, <135/85 home. DASH diet reduces BP 5.5-11.4 mmHg. \
    CKD: 850M worldwide, protein restrict 0.6-0.8g/kg in stages 3-5 (higher 1.0-1.2g/kg on dialysis). \
    Metabolic syndrome: waist >90cm men / >80cm women (South Asian thresholds). \
    Post-meal walking 15min reduces glucose 30-50%. Exercise: 150min/wk moderate aerobic + 2 resistance sessions. \
    Turmeric (curcumin 500mg + piperine): anti-inflammatory comparable to ibuprofen (Cochrane). \
    Ashwagandha 300-600mg: cortisol reduction 14-28% (RCTs). Berberine: HbA1c reduction ~0.9%. \
    Yoga: HbA1c reduction 0.5%, BP reduction 5mmHg (systematic reviews). \
    PCOS: insulin resistance link, metformin/inositol. Menopause: CVD risk rises, HRT evidence-based. \
    VO2max: strongest predictor of all-cause mortality (Cleveland Clinic, 122K patients). \
    Drug interactions: NSAIDs+blood thinners, ACE inhibitors+potassium, statins+grapefruit, metformin+B12 depletion. \
    CGM targets: Time-in-Range 70-180 >70%, TBR <4%. Dawn phenomenon, post-meal spikes visible via CGM. \
    Cross-device: pair CGM glucose with wearable HRV/sleep for insulin resistance patterns. \
    BP monitoring: Bluetooth cuffs (Omron, Withings, QardioArm) sync via Apple Health. Home target <135/85. \
    Take 2 readings 1min apart, twice daily, 7 days. White coat vs masked hypertension. \
    SpO2 (Apple Watch/Ring): normal 95-100%, <94% concern, <90% urgent. Nocturnal dips suggest sleep apnoea. \
    ECG (Apple Watch via Apple Health): sinus rhythm vs AFib detection. Share PDF with GP. Single-lead only. \
    Temperature (Ring/Apple Watch): relative trends, not absolute. Ovulation tracking, early illness detection. \
    All device data flows through Apple Health (HealthKit) — the central hub for cross-device correlation.
    """

    private static let medicalExtended = """
    COMPREHENSIVE RESEARCH KNOWLEDGE BASE:

    --- CHRONIC DISEASE EPIDEMIOLOGY (Vol 1) ---
    NCDs cause 41M deaths/yr (74% of global deaths). CVD: 17.9M deaths/yr (leading). Diabetes: 537M adults \
    globally, 5.8M UK (£10.7B NHS cost, 10% of budget). Hypertension: 1.28B worldwide, 14.4M England. \
    CKD: 850M globally, 3.5M UK. 80% of premature CVD, stroke, T2D preventable via lifestyle (WHO). \
    UK NHS spends 70% of budget on long-term conditions (~£70B/yr).

    --- DIABETES DETAIL (Vol 1) ---
    Type 1 (8%): autoimmune, requires insulin, not preventable. Type 2 (90%): insulin resistance, \
    lifestyle-driven, reversible (DiRECT Trial showed remission via sustained weight loss). \
    Gestational: 5% of pregnancies, 50% lifetime T2D risk. South Asian crisis: 6x higher diabetes risk \
    in UK, onset 8.2yr earlier, metabolic risk at BMI 23 (not 30, NICE PH46), visceral fat at lower BMI. \
    HbA1c targets: <48 mmol/mol (NICE NG28). Protein: 1.0-1.5g/kg for normal renal function (ADA 2024). \
    Post-meal walking 2-5min significantly reduces glucose spikes (Sports Medicine 2022 meta-analysis). \
    Key trials: UKPDS (intensive glucose control reduces complications), DPP (58% diabetes prevention \
    with lifestyle), DiRECT (remission via weight loss), DCCT (tight control reduces T1D complications).

    --- CGM & DEVICE-DRIVEN GLUCOSE MANAGEMENT ---
    CGM (Continuous Glucose Monitors) measure interstitial glucose every 1-5 minutes. Key devices: \
    Dexcom G7 (real-time BLE alerts), FreeStyle Libre 3 (NFC tap-to-scan + optional BLE), Medtronic Guardian. \
    CGM targets (ADA/ATTD consensus): Time-in-Range (TIR) 70-180 mg/dL >70%, Time-Below-Range <4%, \
    Time-Above-Range <25%. Coefficient of Variation (CV) <36% indicates stable glucose. \
    CGM reveals patterns invisible to finger-pricks: dawn phenomenon (4-8 AM rise from liver gluconeogenesis), \
    post-meal spikes (peak 60-90min), nocturnal hypoglycaemia, exercise-induced drops. \
    Cross-device correlations: pair CGM with wearable HRV/sleep data — poor sleep → insulin resistance → \
    higher next-day glucose. Post-meal walking (CGM-verified): 2-15 min walk reduces glucose spike 20-40%. \
    Apple Health integration: CGMs sync via HealthKit, enabling trend analysis alongside steps, sleep, heart rate.

    --- BLOOD PRESSURE MONITORING & DEVICES ---
    BP measurement sources: Bluetooth cuffs (Omron Evolv, Withings BPM Connect, QardioArm — sync via BLE to Apple Health), \
    Apple Watch (Series 9+: wrist-based BP trend estimation via pulse wave analysis — not a replacement for cuff, but useful \
    for spotting trends between clinic visits), manual logging (traditional cuff, pharmacy readings), BodySense Ring \
    (pulse wave velocity correlates with arterial stiffness — trend indicator, not diagnostic). \
    Measurement technique matters: seated 5 min, back supported, feet flat, arm at heart level, empty bladder. \
    Validated cuffs recommended (STRIDE BP / BHS list). Cuff size critical — too small overestimates by 5-15 mmHg. \
    Home monitoring (NICE CG136): take 2 readings 1 min apart, twice daily for 7 days. Discard day 1. Average remaining. \
    Home target <135/85 (not <140/90 which is clinic target). White coat hypertension: 15-30% of patients, home monitoring resolves. \
    Masked hypertension: normal in clinic, high at home — dangerous, only caught by home/24hr monitoring. \
    24-hour ambulatory BP monitoring (ABPM): gold standard for diagnosis (NICE CG127). \
    Cross-device correlations: pair BP readings with HRV from wearables (low HRV + high BP = sympathetic overdrive), \
    sleep data (poor sleep → morning BP surge), CGM (insulin resistance → hypertension link), \
    stress logs (acute stress → transient BP spike), sodium intake from nutrition logs. \
    Circadian BP pattern: normal is 10-20% dip during sleep ("dipper"). Non-dipping pattern (detected by \
    wearable trend data) associated with higher CVD risk. Morning surge (6-10 AM) is highest-risk period for MI/stroke.

    --- CARDIOVASCULAR & HYPERTENSION (Vol 1) ---
    BP categories: Normal <120/80, Elevated 120-129/<80, Stage 1 130-139/80-89, Stage 2 ≥140/≥90, \
    Crisis >180/>120 (immediate medical attention). DASH diet: systolic reduction 5.5-11.4 mmHg \
    (comparable to single antihypertensive drug). DASH principles: fruits 4-5 servings, vegetables 4-5, \
    whole grains 6-8, low-fat dairy 2-3, lean protein ≤6, sodium <1500mg for max benefit. \
    South Asians: 40-60% higher CVD mortality. INTERHEART: 9 modifiable risk factors explain 90% of MI risk. \
    PREDIMED Trial: Mediterranean diet + EVOO/nuts reduced CVD events 30%. Oily fish 2x/wk: omega-3 \
    reduces triglycerides, lowers resting HR, anti-inflammatory. Replace red/processed meat with poultry/fish: \
    14% lower CVD mortality (BMJ 2019).

    --- SpO2 & BLOOD OXYGEN MONITORING ---
    SpO2 (blood oxygen saturation) measured by Apple Watch and BodySense Ring via photoplethysmography (PPG). \
    Normal: 95-100%. Below 94%: medical concern. Below 90%: seek urgent care. \
    Useful for: sleep apnoea screening (SpO2 dips during apnoeic episodes), respiratory conditions (asthma, COPD), \
    COVID/pneumonia monitoring, altitude acclimatisation, exercise recovery. \
    Nocturnal SpO2 dips (detected by ring/watch during sleep): repeated drops below 90% suggest obstructive sleep apnoea — \
    correlate with snoring logs, daytime fatigue, HRV patterns. Refer for sleep study if pattern detected. \
    Cross-device: SpO2 + HRV + sleep stages from ring/watch = comprehensive respiratory-sleep picture. \
    Limitation: wrist/finger PPG less accurate than hospital pulse oximeters, affected by skin pigmentation, \
    cold hands, nail polish, tattoos. Trend data more valuable than single readings.

    --- ECG (ELECTROCARDIOGRAM) ---
    ECG data available via Apple Health — recorded by Apple Watch (Series 4+) using single-lead ECG. \
    Classifies: sinus rhythm (normal), atrial fibrillation (AFib), inconclusive, or poor recording. \
    AFib detection: Apple Heart Study (419K participants) — 84% PPV for AFib. Early detection reduces \
    stroke risk (AFib is #1 cause of cardioembolic stroke). Follow-up: share ECG PDF with GP/cardiologist. \
    Limitations: single-lead cannot detect all arrhythmias, MI, or structural issues — clinical 12-lead ECG needed. \
    Cross-device: ECG + resting HR trends + HRV from ring/watch = comprehensive cardiac monitoring. \
    Irregular rhythm notifications (Apple Watch): passive background monitoring between ECG recordings.

    --- SKIN TEMPERATURE TRENDS ---
    Wrist/finger temperature tracked by Apple Watch (Series 8+) and BodySense Ring. \
    Not absolute body temperature — shows relative deviations from personal baseline. \
    Useful for: menstrual cycle tracking (0.2-0.5°C rise after ovulation confirms luteal phase), \
    early illness detection (temperature deviation 1-2 days before symptoms), fever recovery monitoring, \
    circadian rhythm assessment (temperature drops during sleep onset, rises before waking). \
    Cross-device: temperature + HRV + sleep quality = early warning system for illness or overtraining.

    --- CKD (Vol 1) ---
    Staged by eGFR. Top causes: diabetes (40%), hypertension (25%). South Asians 5x more likely to need \
    renal replacement. Protein: normal (0.8-1.0g/kg) stages 1-2, restricted (0.6-0.8g/kg) stages 3-5, \
    increased (1.0-1.2g/kg) on dialysis. High biological value protein (eggs, chicken, fish) preferred \
    — less total protein needed for equivalent amino acids. Phosphorus restriction critical in advanced CKD.

    --- AYURVEDIC & NATURAL MEDICINE (Vol 2) ---
    Turmeric/Curcumin: 12,000+ studies. 500-2000mg/day + piperine. Anti-inflammatory comparable to \
    ibuprofen for osteoarthritis (Cochrane 2022). Reduces CRP, improves HbA1c in pre-diabetes, \
    antidepressant adjunct, hepatoprotective. Caution: mild blood-thinning, avoid high-dose in pregnancy. \
    Ashwagandha: 300-600mg root extract/day. Cortisol reduction 14-28% (systematic review of 12 RCTs). \
    Sleep onset latency reduced 40% (JCM 2022). Testosterone increase 14-40% in subfertile males. \
    May potentiate thyroid medications. Berberine: glucose reduction comparable to metformin (~0.9% HbA1c). \
    250-500mg 2-3x/day. Caution: drug interactions with CYP enzymes. \
    Triphala: gentle laxative, antioxidant, prebiotic (Bifidobacterium growth), dental plaque reduction. \
    Tulsi: 24 human studies show adaptogenic, blood glucose-lowering, immunomodulatory effects.

    --- WOMEN'S & MEN'S HEALTH (Vol 4) ---
    PCOS: insulin resistance link, 1 in 10 women. Treatment: metformin, inositol (4g myo-inositol/day), \
    anti-inflammatory diet, regular exercise, weight management. Menopause: CVD risk rises significantly, \
    HRT evidence-based for symptom management, bone density. Menstrual cycle affects glucose/BP. \
    Men: testosterone optimised by sleep (7-9hr), zinc, vitamin D, resistance training, stress reduction. \
    Prostate: lycopene (tomatoes), PSA awareness after 50. Dental-CVD link: periodontal disease \
    increases CVD risk 20%.

    --- YOGA & ANCIENT WISDOM (Vol 5) ---
    Yoga: systematic reviews show HbA1c reduction ~0.5%, BP reduction ~5mmHg, cortisol reduction. \
    Pranayama (breathwork): 4-7-8 breathing for BP, Nadi Shodhana for autonomic balance. \
    Meditation: 8 weeks mindfulness → measurable cortical thickening (Harvard), increased gamma coherence. \
    Pancha Kosha framework: physical → energetic → mental → wisdom → bliss (5 layers of health). \
    Bhagavad Gita: process-focused goals 2-3x more effective than outcome-focused (confirmed by \
    Health Psychology Review 2019 meta-analysis). Three Gunas: Sattva (balance) through fresh wholesome \
    food, regular exercise, adequate sleep, mindfulness.

    --- DRUG INTERACTION AWARENESS ---
    NSAIDs + blood thinners: increased bleeding risk. ACE inhibitors + potassium supplements: hyperkalaemia. \
    Statins + grapefruit: increased statin levels/toxicity. Metformin + alcohol: lactic acidosis risk. \
    Metformin long-term: B12 depletion (monitor). Levothyroxine: take on empty stomach, 30min before food. \
    Curcumin supplements: mild anticoagulant effect. Ashwagandha: may potentiate thyroid medication. \
    Berberine: interacts with CYP3A4 and CYP2D6 substrates.
    """

    // ═══════════════════════════════════════════════════════════════════════
    // MARK: - NUTRITION DOMAIN
    // Sources: Vol 1 (macronutrients, dietary patterns), Vol 2 (traditional foods),
    //          Vol 3 (meal timing, protocols), Vol 5 (Sattvic diet)
    // ═══════════════════════════════════════════════════════════════════════

    private static let nutritionCompact = """
    RESEARCH KNOWLEDGE:
    Protein: 1.4-2.0g/kg for exercising individuals (ISSN), 0.8-1.0g/kg sedentary. Leucine threshold \
    2.5g per meal triggers muscle protein synthesis. Distribute 20-40g per meal across day. \
    Chicken breast 100g = 31g protein, 3.6g fat, 165 kcal. Oily fish 2x/wk minimum (NHS). \
    GI/GL: Low GI <55 (vegetables, legumes, whole grains). Brown rice/millets vs white rice. \
    Mediterranean diet: 30% CVD reduction (PREDIMED), 52% diabetes prevention. DASH: BP reduction 5.5-11.4mmHg. \
    Fats: EVOO preferred. Saturated fat: replacing with polyunsaturated reduces CVD risk. Trans fats: eliminate. \
    Vitamin D: >70% UK South Asians deficient. B12: vegetarians at risk, metformin depletes. \
    Magnesium: glucose metabolism, BP regulation. Iron: common deficiency in South Asian women. \
    Ayurvedic superfoods: turmeric, amla (richest vitamin C source), ginger, moringa, ashwagandha. \
    Sattvic diet (Gita): fresh, wholesome, seasonal foods promote clarity. Tamasic: processed, stale foods. \
    Time-restricted eating: food within 10hr window improves metabolic markers.
    """

    private static let nutritionExtended = """
    COMPREHENSIVE NUTRITION KNOWLEDGE:

    --- MACRONUTRIENT SCIENCE (Vol 1) ---
    PROTEIN: Essential for muscle, immunity, satiety. Complete sources: chicken (31g/100g, 165kcal), \
    fish, eggs (up to 7/wk, ADA 2024), dairy. Plant: lentils (high fibre, slows glucose), chickpeas, tofu. \
    Fitness: 1.4-2.0g/kg/day (ISSN), distribute 20-40g per meal for optimal muscle protein synthesis. \
    Leucine threshold ~2.5g triggers MPS. Post-exercise protein within 2hr supports recovery. \
    CKD: restrict 0.6-0.8g/kg stages 3-5. Paneer: complete protein but high saturated fat, use moderately.

    CARBOHYDRATES: Quality > quantity. GI categories: Low <55, Medium 56-69, High >70. \
    White rice = high GI. Brown rice, millets (ragi, jowar, bajra) = significantly lower GI. \
    Whole wheat atta > refined maida. Increase vegetable/dal proportion relative to rice on plate. \
    Fibre: 30g/day target (NHS). Legumes: excellent source, slow glucose absorption.

    FATS: PREDIMED Trial — Mediterranean diet + EVOO/nuts reduced CVD events 30% vs low-fat. \
    Unsaturated (olive oil, nuts, avocado, oily fish): cardioprotective. Saturated (butter, ghee, coconut oil): \
    complex — replacing with polyunsaturated reduces CVD risk, replacing with refined carbs does not. \
    Trans fats (vanaspati ghee, hydrogenated oils): unequivocally harmful, WHO calls for elimination. \
    Use real ghee in small quantities or mustard/groundnut oil instead of vanaspati.

    --- MICRONUTRIENTS (Vol 1) ---
    Vitamin D: insulin sensitivity, immune function, bone health. >70% UK South Asians deficient \
    (darker skin reduces synthesis). Supplement 1000-4000 IU/day in UK. \
    Magnesium: glucose metabolism, BP regulation, 300+ enzyme reactions. Sources: dark greens, nuts, seeds. \
    Iron: common deficiency in South Asian women. Vitamin C enhances absorption. Sources: lentils, spinach, red meat. \
    B12: nerve function, DNA synthesis. Vegetarians at high risk. Metformin reduces absorption — monitor. \
    Chromium: enhances insulin action. Sources: broccoli, whole grains. Zinc: wound healing, immune function. \
    Potassium: BP regulation (counteracts sodium). Must restrict in CKD.

    --- DIETARY PATTERNS (Vol 1) ---
    Mediterranean: most researched pattern (4000+ studies). Fruits, veg, legumes, nuts, EVOO, moderate fish/poultry. \
    PREDIMED: 30% CVD reduction, 52% diabetes prevention, 57% breast cancer reduction (EVOO group). \
    DASH: designed for BP reduction. Fruits 4-5, veg 4-5, whole grains 6-8, low-fat dairy 2-3. \
    Sodium <1500mg/day for maximum BP benefit. Plant-based: EPIC-Oxford — vegetarians 22% lower IHD risk. \
    Adventist study: vegetarians 12% lower all-cause mortality. But South Asian vegetarian diets can be \
    high in refined carbs and saturated fat — need to emphasise whole grains, diverse legumes, supplementation.

    --- TRADITIONAL FOOD WISDOM (Vol 2 & Vol 5) ---
    Ayurvedic superfoods: Amla (Indian gooseberry, richest natural vitamin C source, 20x more than orange). \
    Turmeric in cooking: 1-3g daily with black pepper. Ginger: proven anti-nausea, anti-inflammatory, \
    improves gastric motility. Moringa: protein-rich leaf, iron, calcium. Fenugreek seeds: glucose-lowering \
    effect (RCTs). Cinnamon: modest glucose reduction (1-6g/day). Honey: antimicrobial, but still sugar — \
    moderate use. Coconut oil: high saturated fat — fine in moderation, but limit if high LDL cholesterol. \
    Sattvic diet (Bhagavad Gita Ch 17): fresh, seasonal, minimally processed, wholesome foods promote \
    clarity (Sattva). Rajasic: overly spicy/stimulating foods increase restlessness. \
    Tamasic: processed, stale, reheated foods promote heaviness and lethargy. \
    Dinacharya meal timing: largest meal at midday when digestive fire (Agni) peaks. \
    Time-restricted eating: food within 10-hour window improves glucose, insulin, BP markers (Panda 2018).

    --- SOUTH ASIAN DIETARY ADAPTATION ---
    Replace white rice with brown rice, millets, or cauliflower rice. Whole wheat chapati > refined maida. \
    Increase vegetable portions in curries. Low-fat yoghurt (raita) as regular accompaniment. \
    Reduce cooking oil quantity — use measured amounts. Replace vanaspati with real ghee (small) or mustard oil. \
    Traditional spices (turmeric, cumin, coriander) add flavour and anti-inflammatory benefit, reducing salt need. \
    Dal-based meals daily. Limit sweet consumption during celebrations (swap for fruit-based desserts).
    """

    // ═══════════════════════════════════════════════════════════════════════
    // MARK: - FITNESS DOMAIN
    // Sources: Vol 1 (exercise science), Vol 3 (6 protocols), Vol 5 (yoga evidence)
    // ═══════════════════════════════════════════════════════════════════════

    private static let fitnessCompact = """
    RESEARCH KNOWLEDGE:
    Guidelines: 150min/wk moderate aerobic OR 75min vigorous + 2 resistance sessions (WHO 2020). \
    Post-meal walking 2-5min reduces glucose spikes significantly (Sports Medicine 2022). \
    VO2max: strongest predictor of all-cause mortality — stronger than smoking or diabetes (Cleveland Clinic). \
    Protein for fitness: 1.4-2.0g/kg/day, 20-40g per meal, post-exercise within 2hr. \
    Yoga: HbA1c reduction ~0.5%, BP reduction ~5mmHg, cortisol reduction (systematic reviews). \
    Morning exercise: best insulin sensitivity improvement. Afternoon: peak cardiovascular efficiency. \
    Protocols: Overweight→Fit (24 weeks, 3 phases). Skinny→Fit (surplus +300-500kcal, progressive overload). \
    Sedentary→Active (12 weeks, graduate from 10min walks to 30min structured). \
    60+ Healthy Ageing (balance, bone density, sarcopenia prevention). \
    Pregnancy (trimester-specific modifications). Teens (growth-appropriate, no restrictive dieting). \
    HIIT: time-efficient, 2-3 sessions/wk. Resistance training: improves insulin sensitivity, metabolic rate. \
    Breaking sedentary time every 30min improves postprandial glucose 20-30%.
    """

    private static let fitnessExtended = """
    COMPREHENSIVE FITNESS KNOWLEDGE:

    --- EXERCISE SCIENCE (Vol 1) ---
    WHO 2020: 150min/wk moderate aerobic OR 75min vigorous + resistance training 2+ days. \
    Post-meal walking: even 2-5 minutes significantly reduces glucose spikes vs sitting (Sports Medicine 2022). \
    Especially relevant for South Asians with carb-heavy traditional meals. \
    Breaking prolonged sitting every 30min: improves postprandial glucose 20-30%. \
    Exercise by type: Aerobic — CVD risk reduction, glucose control, weight management, mental health. \
    Resistance — muscle mass, bone density, insulin sensitivity, metabolic rate. \
    HIIT — time-efficient CV fitness, glucose control, fat loss (2-3 sessions/wk, 20-30min). \
    Yoga — flexibility, stress, BP, glucose (culturally aligned for South Asians, RCTs show HbA1c reduction). \
    VO2max: Cleveland Clinic study (122,007 patients, 23 years) — low cardiorespiratory fitness associated \
    with higher mortality than smoking, diabetes, or CAD. Dose-dependent, no upper limit of benefit. \
    VO2max declines ~10%/decade after 30 in sedentary, but exercise slows decline by 50%+.

    --- LIFESTYLE PROTOCOLS (Vol 3) ---
    PROTOCOL 1 — Overweight to Fit (24 weeks, 3 phases):
    Phase 1 (Weeks 1-4 Foundation): Daily walking 30min, 2 bodyweight sessions/wk. \
    Caloric deficit 300-500kcal. Focus: build consistency, not intensity. \
    Phase 2 (Weeks 5-12 Acceleration): Walking 45min + 3 resistance sessions. \
    Add HIIT 1x/wk. Increase protein to 1.6g/kg. Deficit 500kcal. \
    Phase 3 (Weeks 13-24 Optimisation): 4 structured sessions/wk (2 resistance, 1 HIIT, 1 cardio). \
    Body recomposition focus. Maintenance calories on training days.

    PROTOCOL 2 — Skinny to Fit (Lean Mass Building):
    Caloric surplus +300-500kcal (clean bulk). Protein 1.8-2.2g/kg. \
    4-day resistance split: Upper Push / Lower / Upper Pull / Lower. Progressive overload mandatory. \
    Compound lifts priority: squat, deadlift, bench, overhead press, rows. \
    Sleep 8-9hr for optimal growth hormone and testosterone. Creatine 5g/day (most studied supplement).

    PROTOCOL 3 — Sedentary to Active (12-week graduation):
    Weeks 1-2: 10min walk 3x/wk. Weeks 3-4: 15min walk 4x/wk. \
    Weeks 5-6: 20min walk 5x/wk + 1 bodyweight session. \
    Weeks 7-8: 25min walk/jog + 2 bodyweight sessions. \
    Weeks 9-12: 30min structured exercise 4-5x/wk. Goal: habit formation before intensity.

    PROTOCOL 4 — Healthy Ageing (60+):
    Balance work: single-leg stands, heel-to-toe walking (falls prevention). \
    Resistance: light weights, higher reps (12-15), 2-3x/wk (sarcopenia prevention). \
    Bone density: weight-bearing exercise essential (walking, dancing, stair climbing). \
    Protein: 1.0-1.2g/kg minimum (higher than general adult). Vitamin D + calcium supplementation. \
    Flexibility: daily gentle stretching. Tai chi: evidence-based for balance and falls reduction.

    PROTOCOL 5 — Pregnancy:
    First trimester: continue pre-pregnancy exercise if uncomplicated, moderate intensity. \
    Avoid supine exercise after 16 weeks. Pelvic floor exercises throughout. \
    Second trimester: swimming, walking, prenatal yoga. Low-impact preferred. \
    Third trimester: reduce intensity, focus on mobility and breathing. \
    Postpartum: gradual return (6-8 weeks postnatal check first). Rebuild core and pelvic floor before impact.

    PROTOCOL 6 — Adolescents (13-18):
    Structured play and sport 60min/day. Multi-sport encouraged over specialisation. \
    Resistance training safe with proper supervision (bodyweight and light loads). \
    No restrictive dieting — growing bodies need adequate nutrition. \
    Sleep 9-12 hours. Limit screen time. Social physical activity preferred.

    --- YOGA CLINICAL EVIDENCE (Vol 5) ---
    Systematic reviews: HbA1c reduction ~0.5%, BP reduction ~5mmHg, cortisol reduction, \
    improved lipid profiles, reduced inflammatory markers. Patanjali's 8 limbs: asana (postures), \
    pranayama (breath control), dharana (concentration), dhyana (meditation) — each with clinical evidence. \
    Key practices: Sun Salutation (cardiovascular), Warrior poses (strength), Tree pose (balance), \
    Savasana (HRV improvement, stress reduction). Safe for all ages when properly guided.

    --- CIRCADIAN EXERCISE TIMING (Vol 3) ---
    Morning (6-9 AM): best for insulin sensitivity improvement, cortisol regulation. Testosterone peaks (men). \
    Afternoon (4-7 PM): body temperature peaks, coordination and reaction time best, CV efficiency highest, \
    injury risk lowest. Optimal for performance. \
    Key: consistency of timing matters more than which time — pick one and build the habit.
    """

    // ═══════════════════════════════════════════════════════════════════════
    // MARK: - CHEF & FOOD DOMAIN
    // Sources: Vol 1 (food-health correlations), Vol 2 (kitchen remedies),
    //          Vol 3 (meal frameworks), Vol 5 (Sattvic food principles)
    // ═══════════════════════════════════════════════════════════════════════

    private static let chefCompact = """
    RESEARCH KNOWLEDGE:
    Meal timing: largest meal at midday when digestive capacity peaks (circadian + Ayurvedic Agni). \
    Dinner light, finish 3hr before sleep. Time-restricted eating 10hr window improves metabolic markers. \
    South Asian swaps: white rice → brown rice/millets, refined maida → whole wheat atta, \
    deep-fried → air-fried/baked, vanaspati ghee → real ghee (small amount) or mustard oil. \
    Anti-inflammatory spices: turmeric + black pepper, cumin, coriander, ginger, cinnamon, fenugreek. \
    Protein per meal: 20-40g. Chicken breast 100g = 31g protein. Lentils: high fibre, low GI. \
    Post-meal walk 15min reduces glucose spike 30-50%. Plate method: 50% vegetables, 25% protein, 25% carbs. \
    Diabetic-friendly: low GI carbs, adequate protein, healthy fats, fibre-rich. \
    Sattvic cooking: fresh, seasonal, minimal processing, cooked with love and intention.
    """

    private static let chefExtended = """
    COMPREHENSIVE FOOD & COOKING KNOWLEDGE:

    --- MEAL TIMING & STRUCTURE (Vol 3 + Vol 2) ---
    Circadian eating: digestive capacity peaks at midday (gastric acid, glucose tolerance, metabolic rate \
    all highest). Ayurvedic Dinacharya confirms: eat largest meal 12-1 PM. Dinner should be light, \
    ideally finished by 7 PM (or 3 hours before sleep). Early dinner improves overnight glucose, fat \
    oxidation, and sleep quality (RCTs 2020). Time-restricted eating within 10-hour window improves \
    glucose, insulin, blood pressure (Panda 2018). Post-meal walking 15min: reduces glucose spikes 30-50%.

    Plate composition: 50% vegetables (diverse colours for micronutrients), 25% protein (20-40g per meal), \
    25% complex carbohydrates (low GI: brown rice, millets, whole wheat). Add healthy fat: 1 tbsp EVOO, \
    small handful nuts, or quarter avocado.

    --- SOUTH ASIAN FOOD INTELLIGENCE ---
    SMART SWAPS: White rice → brown rice, quinoa, millets (ragi/jowar/bajra — lower GI, more micronutrients). \
    Refined maida → whole wheat atta. Deep-fried → air-fried, baked, or shallow-fried with measured oil. \
    Vanaspati ghee → real ghee (1 tsp) or mustard/groundnut oil. Sugar in chai → reduce gradually to none. \
    Sweetened lassi → plain yoghurt/buttermilk with cumin. Sweet mithai → fruit-based desserts, dates, dark chocolate.

    DAL MASTERY: Daily lentil consumption is excellent — high fibre slows glucose, plant protein, prebiotic. \
    Combine different dals for complete amino acid profile. 1 cup cooked per meal. \
    Add turmeric + cumin to tempering for anti-inflammatory benefit.

    SPICE PHARMACY: Turmeric (anti-inflammatory, add black pepper for 2000% absorption increase). \
    Cumin (digestive aid, iron source). Coriander (anti-inflammatory). Ginger (anti-nausea, improves \
    gastric motility). Cinnamon (modest glucose reduction 1-6g/day). Fenugreek seeds (glucose-lowering RCTs). \
    Cardamom (digestive). Ajwain (carminative). Asafoetida/hing (digestive, reduces bloating).

    --- CONDITION-SPECIFIC COOKING ---
    DIABETES-FRIENDLY: Focus on low GI carbs, adequate protein each meal, fibre-rich vegetables. \
    Replace white rice with cauliflower rice for 80% carb reduction. Use cinnamon in porridge. \
    Bitter gourd (karela): traditional glucose-lowering vegetable (moderate evidence).

    HYPERTENSION-FRIENDLY (DASH adapted): Reduce salt — use spices for flavour instead. \
    Increase potassium: bananas, potatoes, spinach, coconut water. Low-fat dairy (raita). \
    Limit pickles (achaar — very high sodium). Garlic: modest BP reduction (meta-analysis).

    WEIGHT LOSS: Protein-first approach at each meal (satiety). Soup/salad before main course. \
    Smaller plate sizes. Eat slowly (20 min minimum for satiety hormones). Avoid liquid calories.

    MUSCLE BUILDING: 30-40g protein per meal, 4-5 meals/day. Post-workout: protein + simple carb within 2hr. \
    Examples: chicken breast + brown rice, Greek yoghurt + banana, egg omelette + toast.

    --- FOOD WISDOM (Vol 5 — Bhagavad Gita Ch 17) ---
    Sattvic foods (promote clarity, health, vitality): fresh fruits and vegetables, whole grains, nuts, \
    seeds, dairy, honey, herbal teas. Cooked with care, eaten mindfully. \
    Rajasic foods (promote restlessness, overstimulation): excessively spicy, sour, salty, hot. \
    Too much caffeine, garlic, onion in excess. \
    Tamasic foods (promote heaviness, lethargy): processed foods, reheated leftovers, fast food, \
    excessive alcohol, stale food, overeating. \
    Principle: "Let food be fresh, seasonal, and prepared with positive intention."
    """

    // ═══════════════════════════════════════════════════════════════════════
    // MARK: - SLEEP DOMAIN
    // Sources: Vol 1 (sleep science), Vol 3 (circadian protocols), Vol 5 (consciousness states)
    // ═══════════════════════════════════════════════════════════════════════

    private static let sleepCompact = """
    RESEARCH KNOWLEDGE:
    Duration: 7-9hr adults (National Sleep Foundation). <6hr chronic: 45% increased diabetes risk, \
    48% increased CHD risk, impaired glucose tolerance. Architecture: 90min cycles — \
    N1 (5%), N2 (50%), N3/deep sleep (20-25%), REM (20-25%). Deep sleep: growth hormone, immune repair, \
    glymphatic clearance of brain waste. REM: memory consolidation, emotional processing. \
    Sleep before 11 PM maximises slow-wave sleep. Melatonin onset triggered by dim light 2-3hr before bed. \
    Morning sunlight 2-10min sets circadian clock (Huberman/Stanford). Screen blue light suppresses \
    melatonin 50%, delays sleep onset 30-60min. HRV increases during deep sleep, fluctuates in REM. \
    Mandukya Upanishad: 4 consciousness states (waking, dreaming, deep sleep, pure awareness) \
    map precisely to modern sleep stages + meditation states. \
    Ashwagandha 600mg: sleep onset latency reduced 40% (RCT). Magnesium: improves sleep quality. \
    NASA nap: 26min improves performance 34%, alertness 54%.
    """

    private static let sleepExtended = """
    COMPREHENSIVE SLEEP KNOWLEDGE:

    --- SLEEP SCIENCE (Vol 1) ---
    7-9 hours recommended for adults. Chronic short sleep (<6hr): 45% increased diabetes risk, \
    48% increased coronary heart disease risk, elevated inflammatory markers (CRP, IL-6, TNF-alpha), \
    disrupted leptin/ghrelin signalling (increased appetite/weight gain), impaired glucose tolerance \
    equivalent to pre-diabetic state, elevated cortisol promoting visceral fat.

    Sleep architecture: ~90min cycles. N1 (light sleep, 5%). N2 (moderate, sleep spindles, K-complexes, 50%). \
    N3/deep sleep (slow-wave, 20-25%): physical recovery, immune function, growth hormone release, \
    glucose metabolism, glymphatic system clears brain metabolic waste including amyloid-beta. \
    REM sleep (20-25%): memory consolidation, emotional processing, cognitive function, creative problem-solving. \
    Both deep sleep and REM decline with age.

    Wearable tracking (ring, watch, or fitness band): during deep sleep, HRV increases and heart rate decreases. During REM, \
    HRV becomes more variable and heart rate fluctuates. Skin temperature drops during sleep onset. \
    CGM data can reveal nocturnal glucose dips that fragment sleep.

    --- CIRCADIAN SLEEP OPTIMIZATION (Vol 3) ---
    Light is the master synchroniser. Morning sunlight 2-10 minutes within 30-60 min of waking sets \
    circadian clock, suppresses melatonin, initiates cortisol awakening response (Huberman/Stanford). \
    Even cloudy outdoor light is 10-50x brighter than indoor. Evening blue light from screens \
    suppresses melatonin up to 50%, delays sleep onset 30-60min. Mitigation: night mode on devices, \
    warm-toned evening lighting, dim progressively after sunset.

    Hormone clock: melatonin production begins 7-9 PM (dim light onset). Growth hormone surge 11 PM-2 AM \
    (must be asleep by 11 PM for full benefit). REM dominant 2-5 AM. Cortisol begins rising ~4 AM.

    Sleep before 11 PM maximises slow-wave sleep duration. Consistent sleep/wake times (even weekends) \
    strengthen circadian entrainment. Ideal bedroom: cool (16-18°C), dark, quiet.

    --- SLEEP HYGIENE PROTOCOL ---
    2-3hr before bed: finish eating (digestion disrupts sleep). No caffeine after 2 PM (half-life 5-6hr). \
    Limit alcohol (disrupts REM architecture). 1hr before: dim lights, no screens or use blue light filter. \
    30min before: warm bath/shower (rapid cooling triggers sleepiness), reading, gentle stretching. \
    Bedroom: blackout curtains, 16-18°C, remove electronics. White noise if needed. \
    If can't sleep after 20min: get up, do something calm in dim light, return when sleepy.

    --- SLEEP SUPPLEMENTS & NATURAL AIDS (Vol 2) ---
    Ashwagandha: 600mg daily for 8 weeks improved sleep quality, onset latency reduced 40% (RCT, JCM 2022). \
    Magnesium (glycinate/threonate): improves sleep quality, especially in deficiency. 200-400mg before bed. \
    Melatonin: 0.5-3mg, useful for jet lag and shift work, not for long-term insomnia. \
    Valerian: traditional sedative, mixed clinical evidence. Chamomile: mild anxiolytic, promotes relaxation. \
    Warm milk with nutmeg (Ayurvedic): increases melatonin precursors, nutmeg has mild sedative properties. \
    Tart cherry juice: natural melatonin source, small studies show benefit.

    --- ANCIENT WISDOM ON CONSCIOUSNESS & SLEEP (Vol 5) ---
    Mandukya Upanishad describes 4 states: Jagrat (waking = beta waves), Svapna (dreaming = REM, theta waves), \
    Sushupti (deep dreamless sleep = N3, delta waves), Turiya (pure awareness = meditation, gamma waves). \
    This 2,500-year-old framework maps precisely to modern sleep science. Deep sleep (Sushupti) is \
    when physical repair occurs. REM (Svapna) processes emotions and consolidates learning. \
    Turiya may describe the neurological state cultivated by long-term meditation — increased gamma coherence, \
    thicker prefrontal cortex, reduced amygdala reactivity.

    Sleep position matters: left lateral (Ayurvedic recommendation) may improve digestion and reduce reflux. \
    Avoid sleeping immediately after eating (minimum 2-3 hour gap).
    """

    // ═══════════════════════════════════════════════════════════════════════
    // MARK: - MENTAL WELLNESS DOMAIN
    // Sources: Vol 1 (stress-cortisol, mental health), Vol 2 (breathwork, adaptogens),
    //          Vol 5 (Gita psychology, meditation, Pancha Kosha)
    // ═══════════════════════════════════════════════════════════════════════

    private static let mentalWellnessCompact = """
    RESEARCH KNOWLEDGE:
    Stress-cortisol axis: chronic stress → elevated cortisol → increased glucose, BP, visceral fat, \
    inflammation, immune suppression. HRV: biomarker for autonomic balance/stress. \
    SMILES Trial: Mediterranean diet improved depression (32% remission vs 8% control). \
    Gut-brain axis: microbiome directly influences mood via vagus nerve. \
    Ashwagandha: cortisol reduction 14-28% (12 RCTs). Meditation: 8 weeks → cortical thickening (Harvard). \
    Pranayama: 4-7-8 breathing (inhale 4, hold 7, exhale 8) activates parasympathetic. \
    Nadi Shodhana (alternate nostril): balances autonomic nervous system. Box breathing: 4-4-4-4. \
    Bhagavad Gita: equanimity (Samatvam) = master skill for mental health. Process goals 2-3x more \
    effective than outcome goals (meta-analysis confirms Gita's Karma Yoga principle). \
    Three Gunas: Sattva through balanced diet, exercise, sleep, nature, meditation. \
    Social connection: loneliness mortality risk equivalent to smoking 15 cigarettes/day. \
    Blue Zones: purpose (ikigai) + social integration → longevity.
    """

    private static let mentalWellnessExtended = """
    COMPREHENSIVE MENTAL WELLNESS KNOWLEDGE:

    --- STRESS & CORTISOL (Vol 1) ---
    Chronic stress pathway: perceived threat → HPA axis activation → cortisol release → \
    increased blood glucose, elevated blood pressure, visceral fat deposition, systemic inflammation, \
    immune suppression, impaired wound healing, disrupted sleep. Chronic elevation linked to \
    metabolic syndrome, cardiovascular disease, depression, cognitive decline.

    HRV (Heart Rate Variability): the gold-standard biomarker for autonomic nervous system balance. \
    Higher HRV = better stress resilience, parasympathetic tone. Lower HRV = sympathetic dominance, \
    chronic stress, poor recovery. Wearables (ring, Apple Watch, chest strap) track HRV continuously. \
    Evidence-based stress reduction techniques (ranked by evidence strength): \
    Regular exercise, meditation/mindfulness, adequate sleep, social connection, cognitive behavioural \
    techniques, time in nature, breathwork, music therapy.

    --- NUTRITIONAL PSYCHIATRY (Vol 1) ---
    SMILES Trial (landmark): Mediterranean-style diet as intervention for clinical depression. \
    32% achieved remission in diet group vs 8% in social support control. Food IS medicine for mood. \
    Gut-brain axis: microbiome produces ~95% of serotonin. Prebiotic/probiotic foods support mood. \
    Key nutrients for mental health: omega-3 (anti-inflammatory, neuronal membrane), B vitamins \
    (neurotransmitter synthesis), vitamin D (receptor throughout brain), magnesium (GABAergic), \
    zinc (hippocampal function), iron (dopamine synthesis). Deficiency in any → increased depression risk.

    --- ADAPTOGENS & HERBS (Vol 2) ---
    Ashwagandha: 300-600mg/day. Cortisol reduction 14-28% (systematic review, 12 RCTs). \
    Reduced anxiety on Hamilton Anxiety Scale. Improved sleep quality. Mechanism: modulates \
    HPA axis, reduces cortisol, increases GABA activity. \
    Tulsi (Holy Basil): adaptogenic, anxiolytic. 24 human studies support anti-stress effects. \
    Brahmi (Bacopa monnieri): cognitive enhancement, memory improvement. 300mg/day for 12 weeks (RCTs). \
    L-theanine (green tea): promotes alpha brain waves (calm alertness). 100-200mg. \
    Saffron: antidepressant effect comparable to fluoxetine in mild-moderate depression (RCTs).

    --- BREATHWORK & PRANAYAMA (Vol 2 & Vol 5) ---
    4-7-8 Breathing: Inhale 4 counts, hold 7, exhale 8. Activates parasympathetic nervous system. \
    Reduces BP and anxiety within minutes. Dr Andrew Weil protocol. \
    Nadi Shodhana (alternate nostril): balances left/right brain hemispheres and autonomic nervous system. \
    Clinical evidence for BP reduction and anxiety reduction. \
    Box Breathing: 4-4-4-4 (inhale-hold-exhale-hold). Used by Navy SEALs. Activates vagus nerve. \
    Bhramari (humming bee breath): vibration stimulates vagus nerve, reduces tinnitus, calms anxiety. \
    Kapalbhati (skull-shining breath): energising, improves oxygenation. Caution in hypertension.

    --- BHAGAVAD GITA PSYCHOLOGY (Vol 5) ---
    Karma Yoga (Ch 2-3): "You have the right to perform your actions, but not to the fruits." \
    Process-focused goals are 2-3x more effective than outcome goals for sustaining health behaviour \
    (Health Psychology Review 2019 meta-analysis confirms this 2,200-year-old principle). \
    Focus on eating well TODAY, exercising TODAY — release obsession with the scale number.

    Samatvam (equanimity, Ch 2.48): treating success and failure with equal composure. \
    Modern resilience research confirms: emotional regulation and equanimity are trainable skills \
    that predict better health outcomes, lower cortisol, and greater life satisfaction.

    Three Gunas (Ch 14): Sattva (clarity, balance) promoted by fresh food, regular exercise, \
    adequate sleep, nature time, meditation. Rajas (restlessness) from overstimulation, excessive \
    caffeine, overwork, competitive comparison. Tamas (inertia) from processed food, oversleeping, \
    excessive screen time, isolation. Goal: increase Sattva through daily choices.

    Pancha Kosha (Taittiriya Upanishad): True wellness requires attention to ALL 5 layers — \
    physical (diet, exercise), energetic (breathwork, HRV), mental (emotional regulation), \
    wisdom (self-awareness, health literacy), bliss (purpose, meaning, connection).

    --- SOCIAL CONNECTION & PURPOSE (Vol 1) ---
    Social isolation: mortality risk equivalent to smoking 15 cigarettes/day (Holt-Lunstad meta-analysis). \
    Blue Zone longevity research: all 5 Blue Zones share strong social integration and sense of purpose. \
    Okinawan ikigai (reason for being): associated with lower mortality and better mental health. \
    Community health groups, family connection, and purposeful living are as important as diet and exercise.
    """

    // ═══════════════════════════════════════════════════════════════════════
    // MARK: - PERSONAL CARE DOMAIN
    // Sources: Vol 4 (skin, hair, dental, eye), Vol 2 (naturopathy, Ayurvedic care)
    // ═══════════════════════════════════════════════════════════════════════

    private static let personalCareCompact = """
    RESEARCH KNOWLEDGE:
    Skin: 70% determined by internal factors (nutrition, hydration, sleep, stress). Vitamin C + zinc = \
    collagen synthesis. Acne-gut connection (probiotics help). SPF 30+ daily. Collagen peptides: \
    RCTs show improved elasticity. Niacinamide: strong evidence for hyperpigmentation. \
    Hair: iron (ferritin >70), B12, vitamin D, zinc, biotin for hair loss. Rosemary oil: \
    comparable to minoxidil 2% at 6 months (RCT). Coconut oil: reduces protein loss 39%. \
    Dental: oral-CVD link (periodontal disease increases CVD risk 20%). Oil pulling: \
    reduces S. mutans comparable to chlorhexidine. Tongue scraping: reduces bacteria. Xylitol gum 6g/day. \
    Eyes: 20-20-20 rule (every 20min, look 20ft away, 20sec). Lutein + zeaxanthin for macular degeneration. \
    Ayurvedic self-care: Abhyanga (self-massage) reduces cortisol 31%, increases serotonin 28%. \
    Dinacharya: tongue scraping, oil pulling, warm water with lemon — all validated by modern research.
    """

    private static let personalCareExtended = """
    COMPREHENSIVE PERSONAL CARE KNOWLEDGE:

    --- SKIN HEALTH (Vol 4) ---
    Skin is the largest organ (1.8m²). 70% of skin health determined by internal factors. \
    Key nutrients: Vitamin C (collagen synthesis, UV protection — amla is richest source, 20x orange), \
    Vitamin E (lipid antioxidant), Vitamin A/retinol (cell turnover), Zinc (wound healing, acne — 30mg/day \
    RCTs positive), Omega-3 (anti-inflammatory, skin barrier), Collagen peptides (RCTs: improved elasticity). \
    Water: 2-3L daily for hydration and plumpness.

    Condition-specific: Acne — zinc 30mg/day, tea tree oil (Cochrane: comparable to benzoyl peroxide), \
    reduce dairy and high-GI foods, gut health (probiotics). Eczema — evening primrose oil, probiotics \
    (modest benefit in children, Cochrane), oat baths, coconut oil moisturiser. Psoriasis — vitamin D, \
    fish oil, turmeric/curcumin (pilot trials), stress management (major trigger). \
    Hyperpigmentation (South Asian): niacinamide (strong evidence), vitamin C topical, liquorice extract. \
    SPF 30+ daily essential. Premature ageing: vitamin C serum, sleep 7-9hr (growth hormone), no smoking.

    --- HAIR HEALTH (Vol 4) ---
    Hair = 95% keratin protein. Thinning causes: iron deficiency (#1 in women), thyroid, stress \
    (telogen effluvium), hormonal (androgenetic alopecia), B12/D/zinc deficiency. \
    Targets: ferritin >70, vitamin D >50 nmol/L, zinc adequate. \
    Natural: Rosemary oil scalp massage — RCT showed comparable to minoxidil 2% at 6 months. \
    Coconut oil pre-wash: penetrates hair shaft, reduces protein loss 39%. \
    Pumpkin seed oil, saw palmetto: DHT inhibition (androgenetic alopecia). \
    Scalp massage: increases hair thickness 10% (standardised study). \
    Premature greying: B12, copper, antioxidants. Amla oil (traditional, antioxidant-rich). \
    Breakage: ensure protein 1g/kg minimum, biotin, avoid excessive heat styling.

    --- DENTAL & ORAL HEALTH (Vol 4) ---
    Oral-systemic connection: periodontal disease increases CVD risk 20%, complicates diabetes, \
    linked to adverse pregnancy outcomes, possibly Alzheimer's. Oral microbiome: 700+ bacterial species.
    Evidence-based care: Brush 2x daily with fluoride (24% caries reduction, Cochrane). \
    Floss/interdental brushes daily. Tongue scraping: reduces volatile sulphur compounds by 75%. \
    Oil pulling (coconut/sesame oil, 10-15min): reduces S. mutans comparable to chlorhexidine (systematic reviews). \
    Xylitol gum: FDA-approved, 6g/day prevents caries. \
    Protective foods: cheese (raises pH, calcium), green tea (catechins), crunchy vegetables. \
    Damaging: sugar, acidic drinks, dried fruit (sticky sugar), frequent snacking.

    --- EYE HEALTH (Vol 4) ---
    Myopia epidemic: doubled in 30 years (30% global, projected 50% by 2050). Driven by screen time \
    and reduced outdoor time. 20-20-20 rule: every 20 minutes, look at something 20 feet away, \
    for 20 seconds. Outdoor time 2hr/day reduces myopia risk in children.
    Nutrients: Lutein + zeaxanthin (macular degeneration — kale, spinach, eggs). Omega-3 (dry eye, \
    retinal health). Vitamin A (night vision — sweet potato, carrots). Vitamin C + E (antioxidant protection). \
    Zinc (retinal metabolism). AREDS2 formula for AMD: lutein 10mg, zeaxanthin 2mg, vitamin C, E, zinc, copper.

    --- AYURVEDIC SELF-CARE (Vol 2) ---
    Dinacharya daily routine (validated by modern research): \
    Tongue scraping (morning): reduces oral bacteria, bad breath. Copper or stainless steel scraper. \
    Oil pulling (morning): 10-15min coconut/sesame oil swish. Antibacterial, anti-inflammatory. \
    Warm water with lemon (morning): hydration, stimulates digestion, gastric motility. \
    Abhyanga (self-massage with warm sesame/coconut oil): reduces cortisol 31%, increases serotonin 28%, \
    increases dopamine 31% (Field et al. meta-analysis). Nourishes skin, calms nervous system. \
    Nasya (nasal oil application): traditional sinus care, may reduce allergic rhinitis symptoms. \
    Dry brushing (Garshana): stimulates lymphatic drainage, exfoliates dead skin.
    """

    // ═══════════════════════════════════════════════════════════════════════
    // MARK: - GENERAL HEALTH DOMAIN
    // Sources: Vol 1 (Blue Zones, longevity), Vol 3 (daily framework, habits),
    //          Vol 5 (purpose, Purusharthas, holistic health)
    // ═══════════════════════════════════════════════════════════════════════

    private static let generalCompact = """
    RESEARCH KNOWLEDGE:
    Blue Zones (5 regions of extreme longevity): Okinawa, Sardinia, Nicoya, Ikaria, Loma Linda. \
    9 shared principles: move naturally, purpose (ikigai), downshift (stress management), 80% rule \
    (stop eating at 80% full), plant-slant diet, moderate alcohol (1-2 glasses wine), belong \
    (faith/community), loved ones first, right tribe (social circles supporting health). \
    Habit formation: 66 days average to automaticity (not 21). Implementation intentions: \
    "When X happens, I will do Y" — increases follow-through 200-300%. \
    Keystone habits: one habit that cascades into others (e.g., morning exercise → better eating → better sleep). \
    Pancha Kosha: health requires all 5 layers — physical, energetic, mental, wisdom, bliss. \
    Four Purusharthas (Vedic life framework): Dharma (purpose), Artha (prosperity), \
    Kama (pleasure), Moksha (liberation) — balance across all four. \
    WHO: 80% of premature NCD deaths preventable through lifestyle. \
    Longevity science: VO2max, sleep quality, social connection, purpose, diet quality.
    """

    private static let generalExtended = """
    COMPREHENSIVE GENERAL HEALTH KNOWLEDGE:

    --- BLUE ZONES & LONGEVITY (Vol 1) ---
    Five Blue Zones where people regularly live to 100+: Okinawa (Japan), Sardinia (Italy), \
    Nicoya Peninsula (Costa Rica), Ikaria (Greece), Loma Linda (California, USA). \
    Nine shared principles (Power 9): \
    1. Move Naturally — gardening, walking, manual tasks (not gym-based exercise). \
    2. Purpose — Okinawan ikigai or Nicoya plan de vida. Associated with 7 extra years of life. \
    3. Downshift — daily rituals to reverse stress (prayer, nap, happy hour). \
    4. 80% Rule — Hara Hachi Bu (stop eating at 80% full). 2,000-calorie daily average. \
    5. Plant Slant — meat 5x/month average, mostly plant-based. Beans/legumes daily. \
    6. Wine at 5 — moderate alcohol (1-2 glasses, especially Cannonau wine in Sardinia). \
    7. Belong — faith-based community (denomination doesn't matter, attendance does). \
    8. Loved Ones First — aging parents nearby, committed partner, invested in children. \
    9. Right Tribe — social circles that support healthy behaviours.

    For South Asian communities: many principles already present — strong family bonds, \
    daily dal (legumes), faith communities, natural movement. Gaps: processed food increasing, \
    sedentary work, stress of migration, loss of outdoor time.

    --- HABIT ARCHITECTURE (Vol 3) ---
    66 days: average time to habit automaticity (Phillippa Lally, UCL), not 21 days (myth). \
    Range: 18-254 days depending on complexity. Missing one day does not reset progress. \
    Implementation intentions: "When [situation], I will [behaviour]" — increases follow-through 200-300% (RCTs). \
    Habit stacking: attach new habit to existing one ("After I brush my teeth, I will meditate 5 minutes"). \
    Keystone habits: one habit that cascades into others. Morning exercise is the most powerful keystone \
    — leads to better eating, better sleep, better mood, better productivity.

    Morning routine (keystone): Hydrate → Sunlight → Breathwork/Meditation → Exercise → Protein breakfast. \
    Evening routine (recovery): Dim lights → No screens → Gratitude/reflection → Sleep hygiene → Sleep by 10-11 PM.

    Willpower is a depletable resource (ego depletion theory). Design environment to make healthy choices \
    default (remove junk food, prep healthy meals, set exercise clothes out night before). \
    Reduce friction for good habits, increase friction for bad habits.

    --- HOLISTIC HEALTH FRAMEWORK (Vol 5) ---
    Pancha Kosha (5 Sheaths of Being, Taittiriya Upanishad): \
    1. Annamaya Kosha (physical): diet, exercise, sleep, biometrics. Foundation of all health. \
    2. Pranamaya Kosha (energetic): breathwork, HRV, energy management, autonomic balance. \
    3. Manomaya Kosha (mental): emotions, stress, anxiety, mood. Mindfulness and regulation. \
    4. Vijnanamaya Kosha (wisdom): self-awareness, discernment, health literacy, breaking autopilot. \
    5. Anandamaya Kosha (bliss): purpose, meaning, deep contentment, connection.

    True health requires attention to ALL five layers. Treating only the physical body (diet, exercise) \
    while ignoring mental health, purpose, and social connection produces incomplete results. \
    Body Sense AI addresses all five through biometrics (1), HRV/breathwork (2), mood tracking (3), \
    personalised insights (4), and community/goal features (5).

    Four Purusharthas (Vedic life framework, Vol 5): \
    Dharma (purpose/duty) — what you are meant to do and contribute. \
    Artha (prosperity/security) — material wellbeing that supports your purpose. \
    Kama (pleasure/enjoyment) — healthy enjoyment of life's experiences. \
    Moksha (liberation/self-realisation) — freedom from suffering, inner peace. \
    Balance across all four = complete human flourishing.

    --- PREVENTIVE CARE ESSENTIALS ---
    Screening schedules: NHS Health Check (40-74, every 5 years). Diabetes screening (if risk factors). \
    BP checks annually. Cervical screening (25-64). Breast screening (50-70). Bowel screening (60-74). \
    Cholesterol check every 5 years (or more often with risk factors). \
    Dental: every 6-12 months. Eye test: every 2 years (annual if diabetic). \
    Skin checks: monthly self-exam. Know your moles (ABCDE rule). \
    Vaccinations: flu (annual if at risk), COVID boosters, shingles (70+), pneumonia (65+).

    --- LONGEVITY SCIENCE SUMMARY (Vol 1 + Vol 4) ---
    Top evidence-based longevity interventions: \
    1. Cardiorespiratory fitness (VO2max) — strongest predictor (Cleveland Clinic). \
    2. Sleep quality (7-9hr, circadian-aligned). 3. Plant-rich diet (Mediterranean/DASH). \
    4. Social connection and purpose. 5. Stress management. 6. Not smoking. 7. Moderate alcohol or none. \
    8. Maintain healthy weight (BMI 18.5-24.9, or 18.5-22.9 for South Asians). \
    Hallmarks of ageing (Vol 4): genomic instability, telomere attrition, epigenetic alterations, \
    loss of proteostasis, deregulated nutrient sensing, mitochondrial dysfunction, cellular senescence, \
    stem cell exhaustion, altered intercellular communication. \
    Emerging: rapamycin/metformin research for ageing (early stage). Telomere preservation through \
    exercise, meditation, and healthy diet (Blackburn Nobel Prize research).
    """
}
