//
//  ClinicalKnowledgeBase.swift
//  body sense ai
//
//  BNF & NICE clinical intelligence: monitoring schedules, red flag symptoms,
//  screening reminders, and escalation triggers. Sources: NICE, BNF, NHS.
//

import Foundation

// MARK: - Clinical Knowledge

enum ClinicalKnowledge {

    // MARK: - Public API

    /// Returns red flag symptoms for the user's conditions.
    static func redFlags(for conditions: [String]) -> [RedFlagSymptom] {
        let normalised = conditions.map { $0.lowercased() }
        var flags: [RedFlagSymptom] = []

        for (key, value) in redFlagDatabase {
            if normalised.contains(where: { key.contains($0) || $0.contains(key) }) {
                flags.append(contentsOf: value)
            }
        }

        // Always include universal red flags
        flags.append(contentsOf: universalRedFlags)
        return flags
    }

    /// Returns monitoring schedule formatted for AI context.
    static func monitoringSchedule(for conditions: [String]) -> String {
        let normalised = conditions.map { $0.lowercased() }
        var schedules: [String] = []

        for (key, value) in monitoringDatabase {
            if normalised.contains(where: { key.contains($0) || $0.contains(key) }) {
                schedules.append(value)
            }
        }

        guard !schedules.isEmpty else { return "" }
        return "--- MONITORING SCHEDULE ---\n" + schedules.joined(separator: "\n\n")
    }

    /// Build complete clinical context for AI prompt injection.
    static func contextForAI(conditions: [String], tier: HealthKnowledgeBase.Tier) -> String {
        let normalised = conditions.map { $0.lowercased() }
        guard !normalised.isEmpty else { return "" }

        var ctx = "--- CLINICAL GUIDELINES (NICE/BNF) ---\n"

        // Add condition-specific guidelines
        for (key, value) in guidelineDatabase {
            if normalised.contains(where: { key.contains($0) || $0.contains(key) }) {
                ctx += "\n" + (tier == .compact ? value.compact : value.extended) + "\n"
            }
        }

        // Add relevant red flags summary (always include)
        let flags = redFlags(for: conditions)
        if !flags.isEmpty {
            ctx += "\nRED FLAG SYMPTOMS TO WATCH FOR:\n"
            for flag in flags.prefix(10) {
                ctx += "• \(flag.symptom) → \(flag.action) [\(flag.urgency.rawValue)]\n"
            }
        }

        // Add monitoring schedule (compact: first 3 items; extended: all)
        let schedule = monitoringSchedule(for: conditions)
        if !schedule.isEmpty {
            ctx += "\n" + schedule + "\n"
        }

        return ctx
    }

    // MARK: - Screening Reminders

    /// Age and sex-appropriate screening reminders.
    static func screeningReminders(age: Int, sex: String) -> [String] {
        var reminders: [String] = []

        // NHS Health Check
        if age >= 40 && age <= 74 {
            reminders.append("NHS Health Check: Every 5 years (CVD risk, cholesterol, BP, diabetes screening)")
        }

        // Cervical screening
        if sex.lowercased() == "female" || sex.lowercased() == "f" {
            if age >= 25 && age <= 49 {
                reminders.append("Cervical screening: Every 3 years (HPV primary screening)")
            } else if age >= 50 && age <= 64 {
                reminders.append("Cervical screening: Every 5 years")
            }
        }

        // Breast screening
        if sex.lowercased() == "female" || sex.lowercased() == "f" {
            if age >= 50 && age <= 71 {
                reminders.append("Breast screening (mammogram): Every 3 years")
            }
        }

        // Bowel cancer screening
        if age >= 60 && age <= 74 {
            reminders.append("Bowel cancer screening (FIT test): Every 2 years")
        }

        // AAA screening (men only)
        if (sex.lowercased() == "male" || sex.lowercased() == "m") && age == 65 {
            reminders.append("Abdominal aortic aneurysm (AAA) screening: One-off at age 65")
        }

        // Eye test
        reminders.append("Eye examination: Every 2 years (annually if diabetic or >60)")

        // Dental check
        reminders.append("Dental check-up: Every 6-24 months based on risk")

        return reminders
    }

    // MARK: - Guideline Database

    private struct GuidelinePair {
        let compact: String
        let extended: String
    }

    private static let guidelineDatabase: [String: GuidelinePair] = [

        "diabetes": GuidelinePair(
            compact: """
            NICE NG28 (T2D): HbA1c target 48 mmol/mol (6.5%) or 53 if on hypo-risk meds. \
            Annual review: eyes, feet, kidneys, BP, cholesterol. Structured education (DESMOND/DAFNE). \
            Metformin first-line. Add SGLT2i if CVD risk. Self-monitor if on insulin or hypo-risk meds.
            """,
            extended: """
            NICE NG28 — TYPE 2 DIABETES:

            HbA1c TARGETS:
            • First-line (metformin): target 48 mmol/mol (6.5%)
            • If on hypoglycaemia-risk drugs (SU, insulin): target 53 mmol/mol (7.0%)
            • Individualise for frail/elderly: may accept 58-64 mmol/mol

            TREATMENT PATHWAY:
            1. Lifestyle + Metformin (first-line)
            2. Dual therapy: add SU, DPP-4i, SGLT2i, or pioglitazone
            3. Triple therapy or insulin
            • SGLT2 inhibitor if: established CVD, heart failure, or CKD
            • GLP-1 RA if: BMI ≥35 with weight-related comorbidity

            ANNUAL REVIEW (15 HEALTHCARE ESSENTIALS):
            1. HbA1c measurement
            2. Blood pressure check and treatment review
            3. Cholesterol and lipid profile
            4. Eye screening (retinopathy)
            5. Foot examination (neuropathy, pulses, ulcers)
            6. Kidney function (eGFR + uACR)
            7. Weight/BMI measurement
            8. Smoking status and cessation support
            9. Emotional wellbeing assessment
            10. Medication review (including insulin technique)
            11. Structured education (DESMOND for T2D, DAFNE for T1D)
            12. Care planning and goal setting
            13. Immunisation status (flu, pneumococcal)
            14. Erectile dysfunction screening (men)
            15. Sick day rules education
            """
        ),

        "hypertension": GuidelinePair(
            compact: """
            NICE CG127/NG136: Clinic BP ≥140/90 → ABPM. Stage 1: ≥135/85 ABPM. \
            Stage 2: ≥150/95 ABPM. ACE-i/ARB first-line (<55y or diabetic). \
            CCB first-line (≥55y or Black African/Caribbean). Target <140/90 clinic, <135/85 ABPM.
            """,
            extended: """
            NICE NG136 — HYPERTENSION:

            DIAGNOSIS:
            • Clinic BP ≥140/90 → offer ABPM (ambulatory) or HBPM (home)
            • Stage 1: ABPM/HBPM ≥135/85
            • Stage 2: ABPM/HBPM ≥150/95
            • Stage 3 (severe): clinic systolic ≥180 or diastolic ≥120

            TREATMENT:
            • Step 1: ACE inhibitor (or ARB) if <55y, diabetic, or CKD
            • Step 1: CCB (e.g. amlodipine) if ≥55y or Black African/Caribbean
            • Step 2: ACE-i/ARB + CCB
            • Step 3: ACE-i/ARB + CCB + thiazide-like diuretic
            • Step 4 (resistant): add spironolactone if K+ ≤4.5, or alpha/beta blocker

            TARGETS:
            • <80 years: <140/90 clinic, <135/85 ABPM/HBPM
            • ≥80 years: <150/90 clinic, <145/85 ABPM/HBPM

            MONITORING:
            • After starting/changing: recheck in 4-6 weeks
            • Once stable: check at least annually
            • Check U&Es before and 1-2 weeks after starting ACE-i/ARB
            • Annual: BP, U&Es, CVD risk assessment
            """
        ),

        "ckd": GuidelinePair(
            compact: """
            NICE CG182 (CKD): Stage by eGFR and albuminuria. ACE-i/ARB if uACR ≥30. \
            BP target <130/80 if uACR ≥70. Refer if eGFR <30 or rapidly declining. \
            Monitor eGFR and uACR at least annually (more often if declining).
            """,
            extended: """
            NICE CG182 — CHRONIC KIDNEY DISEASE:

            STAGING:
            • Stage 1: eGFR ≥90 with kidney damage markers
            • Stage 2: eGFR 60-89 with markers
            • Stage 3a: eGFR 45-59
            • Stage 3b: eGFR 30-44
            • Stage 4: eGFR 15-29
            • Stage 5: eGFR <15 or dialysis

            KEY MANAGEMENT:
            • ACE-i/ARB if uACR ≥30 mg/mmol (even if normotensive)
            • SGLT2 inhibitor if T2D + uACR ≥30 (DAPA-CKD, EMPA-KIDNEY evidence)
            • BP target: <140/90 (or <130/80 if uACR ≥70)
            • Statin for CVD prevention in all CKD patients

            MONITORING FREQUENCY:
            • eGFR ≥60 + stable: annually
            • eGFR 30-59: 6-monthly
            • eGFR 15-29: 3-monthly
            • eGFR <15: monthly or as nephrologist advises
            • Check eGFR + uACR + electrolytes at each visit

            REFERRAL CRITERIA:
            • eGFR <30 (or <45 if rapidly declining)
            • eGFR decline >25% or >15 ml/min in 12 months
            • uACR ≥70 (unless known cause being treated)
            • Uncontrolled hypertension on 4+ drugs
            • Suspected renal artery stenosis
            """
        ),

        "heart failure": GuidelinePair(
            compact: """
            NICE NG106 (HF): ACE-i + beta-blocker first-line. Add MRA if still symptomatic. \
            SGLT2i for HFrEF. Fluid restrict 1.5-2L/day. Daily weight (>2kg in 3 days = concern). \
            Sodium <2000mg/day. Annual flu + one-off pneumococcal vaccine.
            """,
            extended: """
            NICE NG106 — HEART FAILURE:

            TREATMENT (HFrEF):
            1. ACE-i (or ARB) + beta-blocker
            2. Add MRA (spironolactone/eplerenone) if still NYHA II-IV
            3. Add SGLT2 inhibitor (dapagliflozin/empagliflozin)
            4. Consider sacubitril/valsartan (replacing ACE-i) if NYHA II-IV
            5. Ivabradine if sinus rhythm >75 bpm despite beta-blocker
            6. Device therapy: ICD/CRT if indicated

            SELF-MANAGEMENT:
            • Daily weight: report gain >2kg in 3 days to heart failure team
            • Fluid restriction: 1.5-2L/day (unless told otherwise)
            • Sodium: <2000mg/day
            • Alcohol: limit to 14 units/week or abstain
            • Exercise: cardiac rehabilitation, then regular moderate exercise
            • Immunisation: annual flu + one-off pneumococcal

            MONITORING:
            • Renal function + electrolytes: 1-2 weeks after starting/changing ACE-i/ARB/MRA
            • NT-proBNP: at diagnosis, during titration, and if decompensation suspected
            • Echocardiogram: at diagnosis and if clinical change
            • 6-monthly review minimum when stable
            """
        ),

        "asthma": GuidelinePair(
            compact: """
            NICE NG80/BTS: SABA reliever (salbutamol) for all. Low-dose ICS if using SABA ≥3x/week. \
            Step up: ICS+LABA, then increase ICS, then add LTRA/theophylline. \
            Annual review. Peak flow monitoring. Personalised asthma action plan.
            """,
            extended: """
            NICE NG80 / BTS — ASTHMA:

            STEPWISE TREATMENT:
            1. SABA as needed (if using ≥3/week → step up)
            2. Low-dose ICS (e.g. beclometasone 200mcg/day)
            3. ICS + LABA (e.g. fluticasone/salmeterol)
            4. Medium-dose ICS + LABA
            5. High-dose ICS + LABA ± LTRA/theophylline
            6. Specialist referral for biologic therapy

            MONITORING:
            • Annual review minimum
            • Peak flow diary if variable symptoms
            • ACQ or ACT questionnaire at each review
            • Inhaler technique check every visit
            • Side effects of ICS: oral thrush (rinse mouth), voice hoarseness

            RED FLAGS:
            • Needing SABA ≥3 times/week
            • Waking at night with asthma
            • Peak flow <75% personal best
            • Any hospital admission or A&E attendance
            """
        ),
    ]

    // MARK: - Red Flag Symptoms Database

    private static let redFlagDatabase: [String: [RedFlagSymptom]] = [

        "diabetes": [
            RedFlagSymptom(condition: "Diabetes", symptom: "Fruity/acetone breath with nausea, vomiting, or confusion", urgency: .urgent, action: "Possible DKA — seek emergency care immediately. Check blood ketones if available."),
            RedFlagSymptom(condition: "Diabetes", symptom: "Blood glucose >20 mmol/L with symptoms (thirst, polyuria, blurred vision)", urgency: .urgent, action: "Severe hyperglycaemia — contact diabetes team or 111. Check ketones."),
            RedFlagSymptom(condition: "Diabetes", symptom: "Hypoglycaemia not responding to 2 rounds of treatment", urgency: .urgent, action: "Severe hypo — call 999. If unconscious, do NOT give oral glucose; use glucagon if available."),
            RedFlagSymptom(condition: "Diabetes", symptom: "New foot ulcer, colour change, or loss of sensation", urgency: .soon, action: "Contact diabetic foot team within 24 hours. Do not self-treat."),
            RedFlagSymptom(condition: "Diabetes", symptom: "Sudden vision changes or new floaters", urgency: .soon, action: "Contact eye casualty or diabetes team — possible retinal bleed."),
        ],

        "hypertension": [
            RedFlagSymptom(condition: "Hypertension", symptom: "BP ≥180/120 with headache, visual changes, or chest pain", urgency: .urgent, action: "Hypertensive emergency — call 999. This requires immediate medical attention."),
            RedFlagSymptom(condition: "Hypertension", symptom: "Sudden severe headache unlike any before", urgency: .urgent, action: "Call 999 — possible stroke or subarachnoid haemorrhage."),
            RedFlagSymptom(condition: "Hypertension", symptom: "Chest pain or tightness with breathlessness", urgency: .urgent, action: "Call 999 — possible MI or aortic dissection."),
            RedFlagSymptom(condition: "Hypertension", symptom: "Sudden weakness/numbness on one side, speech difficulty", urgency: .urgent, action: "FAST: Face-Arms-Speech-Time. Call 999 immediately — stroke."),
        ],

        "ckd": [
            RedFlagSymptom(condition: "CKD", symptom: "Sudden decrease in urine output", urgency: .urgent, action: "May indicate acute kidney injury — seek medical attention today."),
            RedFlagSymptom(condition: "CKD", symptom: "Swelling in legs/ankles getting rapidly worse", urgency: .soon, action: "Fluid overload — contact your kidney team within 24 hours."),
            RedFlagSymptom(condition: "CKD", symptom: "Persistent nausea, vomiting, or metallic taste", urgency: .soon, action: "May indicate worsening uraemia — contact kidney team."),
            RedFlagSymptom(condition: "CKD", symptom: "Chest pain or significant breathlessness", urgency: .urgent, action: "Call 999 — fluid overload or cardiovascular event."),
        ],

        "heart failure": [
            RedFlagSymptom(condition: "Heart Failure", symptom: "Weight gain >2kg in 3 days", urgency: .soon, action: "Fluid retention — contact heart failure team. May need diuretic adjustment."),
            RedFlagSymptom(condition: "Heart Failure", symptom: "Worsening breathlessness at rest or lying flat", urgency: .urgent, action: "Possible decompensation — seek medical attention today."),
            RedFlagSymptom(condition: "Heart Failure", symptom: "New or worsening leg swelling", urgency: .soon, action: "Contact heart failure team within 24-48 hours."),
            RedFlagSymptom(condition: "Heart Failure", symptom: "Chest pain or fainting", urgency: .urgent, action: "Call 999 — possible arrhythmia or acute event."),
        ],

        "asthma": [
            RedFlagSymptom(condition: "Asthma", symptom: "Peak flow <50% of personal best", urgency: .urgent, action: "Severe attack — use reliever, call 999 if no improvement in 10 minutes."),
            RedFlagSymptom(condition: "Asthma", symptom: "Unable to complete sentences due to breathlessness", urgency: .urgent, action: "Call 999 — life-threatening asthma attack."),
            RedFlagSymptom(condition: "Asthma", symptom: "Blue lips or fingertips", urgency: .urgent, action: "Call 999 immediately — severe oxygen deprivation."),
        ],
    ]

    private static let universalRedFlags: [RedFlagSymptom] = [
        RedFlagSymptom(condition: "General", symptom: "Chest pain or tightness", urgency: .urgent, action: "Call 999 — do not drive yourself. Chew aspirin 300mg if available and not allergic."),
        RedFlagSymptom(condition: "General", symptom: "Sudden severe headache (thunderclap)", urgency: .urgent, action: "Call 999 — possible subarachnoid haemorrhage or stroke."),
        RedFlagSymptom(condition: "General", symptom: "FAST signs (Face drooping, Arm weakness, Speech difficulty)", urgency: .urgent, action: "Call 999 immediately — Time is critical for stroke treatment."),
        RedFlagSymptom(condition: "General", symptom: "Difficulty breathing or feeling like you can't get enough air", urgency: .urgent, action: "Call 999 if severe. Sit upright, try to stay calm."),
        RedFlagSymptom(condition: "General", symptom: "Unexplained weight loss >5% in 3 months", urgency: .soon, action: "Book GP appointment — needs investigation to rule out serious causes."),
        RedFlagSymptom(condition: "General", symptom: "Blood in urine, stool, or coughed up", urgency: .soon, action: "Book urgent GP appointment within 48 hours."),
    ]

    // MARK: - Monitoring Schedule Database

    private static let monitoringDatabase: [String: String] = [

        "diabetes": """
        DIABETES MONITORING:
        • HbA1c: Every 3-6 months (target 48-53 mmol/mol)
        • Self-monitoring blood glucose: if on insulin or hypo-risk meds
        • CGM/Flash glucose: if T1D or T2D on insulin with hypo issues
        • Annual eye screening (retinopathy)
        • Annual foot check (neuropathy + vascular)
        • Annual kidney check (eGFR + uACR)
        • Annual cholesterol/lipids
        • BP at every visit
        • Weight/BMI at every visit
        • Flu vaccine annually; pneumococcal one-off
        """,

        "hypertension": """
        HYPERTENSION MONITORING:
        • After starting/changing treatment: recheck in 4-6 weeks
        • Once stable: at least annually
        • Home BP monitoring encouraged (morning + evening, 7-day average)
        • U&Es: before and 1-2 weeks after starting ACE-i/ARB
        • Annual: U&Es, eGFR, lipids, glucose/HbA1c, CVD risk score
        """,

        "ckd": """
        CKD MONITORING:
        • eGFR + uACR + electrolytes at each visit
        • Stage 3a (eGFR 45-59): 6-monthly
        • Stage 3b (eGFR 30-44): 3-6 monthly
        • Stage 4 (eGFR 15-29): 3-monthly
        • Stage 5 (eGFR <15): monthly or as nephrologist
        • Annual: calcium, phosphate, PTH (stage 4-5), vitamin D
        • Annual: haemoglobin (anaemia screen)
        • BP at every visit
        """,

        "heart failure": """
        HEART FAILURE MONITORING:
        • Self-monitor: daily weight, fluid intake, symptoms
        • Report weight gain >2kg in 3 days
        • U&Es: 1-2 weeks after starting/changing ACE-i/ARB/MRA, then 3-6 monthly
        • NT-proBNP: at diagnosis, during titration, if decompensation
        • 6-monthly clinic review minimum when stable
        • Annual: echo if clinical change, flu vaccine
        """,

        "asthma": """
        ASTHMA MONITORING:
        • Annual review minimum (more if poorly controlled)
        • Peak flow: daily diary if variable symptoms
        • Inhaler technique: check at every consultation
        • ACQ or ACT score at each review
        • Review step-up/step-down at every visit
        • Check adherence, triggers, and action plan at every visit
        """,
    ]
}
