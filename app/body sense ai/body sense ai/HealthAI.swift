//
//  HealthAI.swift
//  body sense ai
//
//  BodySense AI — Comprehensive Medical AI Engine
//  Covers the full spectrum of human health in plain, everyday language.
//  Suitable for patients, students, and anyone wanting to understand their body.
//

import Foundation

// MARK: - Chat Message

enum MessageFeedback: String, Equatable {
    case none, thumbsUp, thumbsDown
}

struct ChatMessage: Identifiable, Equatable {
    let id        = UUID()
    let content   : String
    let isUser    : Bool
    let timestamp : Date = Date()

    // Quick-reply chips attached to an AI message
    var chips: [String] = []

    // User feedback on AI responses
    var feedback: MessageFeedback = .none
}

// MARK: - AI Engine

@Observable
class HealthAIEngine {

    private let store: HealthStore
    var isTyping = false

    // Conversation history for multi-turn memory
    private var conversationHistory: [(role: String, content: String)] = []

    // HealthSense Agent — the learning, adaptive AI brain
    private(set) var agent: HealthSenseAgent?

    // Agent state exposed for UI
    var currentDomain: HealthDomain { agent?.currentDomain ?? .general }
    var agentPersona: String { agent?.agentPersona ?? "HealthSense" }
    var agentLearningCount: Int { agent?.learningCount ?? 0 }

    init(store: HealthStore) {
        self.store = store
        self.agent = HealthSenseAgent(store: store)
    }

    // ── Build personalised health context from user data ──────────────────
    private var userHealthContext: String {
        let p = store.userProfile
        var ctx = "\n\n--- THIS USER'S HEALTH PROFILE (use this to personalise every answer) ---\n"
        let cal = Calendar.current
        let sevenDaysAgo = cal.date(byAdding: .day, value: -7, to: Date())!
        let thirtyDaysAgo = cal.date(byAdding: .day, value: -30, to: Date())!

        ctx += "Name: \(p.name.isEmpty ? "User" : p.name), Age: \(p.age), Gender: \(p.gender)\n"
        // Weight in user's preferred unit
        let displayWeight: String = {
            switch p.weightUnit {
            case .kg: return String(format: "%.1f kg", p.weight)
            case .lbs: return String(format: "%.0f lbs", p.weight / 0.453592)
            case .stones:
                let totalLbs = p.weight / 0.453592
                return "\(Int(totalLbs) / 14)st \(Int(totalLbs) % 14)lb"
            }
        }()
        let displayHeight = p.heightUnit.format(p.height)
        ctx += "Weight: \(displayWeight), Height: \(displayHeight)\n"
        let bmi = p.height > 0 ? p.weight / pow(p.height / 100, 2) : 0
        ctx += "BMI: \(String(format: "%.1f", bmi)) (\(bmi < 18.5 ? "underweight" : bmi < 25 ? "healthy" : bmi < 30 ? "overweight" : "obese"))\n"

        // Conditions & Targets
        var conditions: [String] = []
        if !p.diabetesType.isEmpty { conditions.append(p.diabetesType) }
        if p.hasHypertension { conditions.append("Hypertension") }
        ctx += "Conditions: \(conditions.isEmpty ? "None recorded" : conditions.joined(separator: ", "))\n"
        ctx += "Targets — Glucose: \(Int(p.targetGlucoseMin))-\(Int(p.targetGlucoseMax)) mg/dL, BP: <\(p.targetSystolic)/\(p.targetDiastolic), Steps: \(p.targetSteps)/day, Sleep: \(String(format: "%.1f", p.targetSleep))hrs\n"
        if !p.selectedGoals.isEmpty { ctx += "Health goals: \(p.selectedGoals.joined(separator: ", "))\n" }

        // Medications with adherence + database-enriched context
        let activeMeds = store.medications.filter { $0.isActive }
        ctx += "\nMEDICATIONS (\(activeMeds.count) active):\n"
        if activeMeds.isEmpty {
            ctx += "  None\n"
        } else {
            for med in activeMeds {
                let recentLogs = med.logs.filter { $0.date >= sevenDaysAgo }
                let taken = recentLogs.filter { $0.taken }.count
                let total = recentLogs.count
                let adherence = total > 0 ? Int(Double(taken) / Double(total) * 100) : 0
                ctx += "  \(med.name) \(med.dosage)\(med.unit) — \(med.frequency.rawValue) — 7-day adherence: \(adherence)%\n"

                // Enrich with database info if linked
                if let entry = med.databaseEntry {
                    ctx += "    Class: \(entry.therapeuticClass)\n"
                    if !entry.warnings.isEmpty {
                        ctx += "    Key warnings: \(entry.warnings.prefix(2).joined(separator: "; "))\n"
                    }
                    if !entry.foodInteractions.isEmpty {
                        ctx += "    Food interactions: \(entry.foodInteractions.joined(separator: "; "))\n"
                    }
                }
            }

            // Cross-check drug interactions for users on 2+ meds
            if activeMeds.count >= 2 {
                var interactionNotes: [String] = []
                let medNames = activeMeds.compactMap { $0.genericName ?? $0.name }
                for i in 0..<medNames.count {
                    for j in (i+1)..<medNames.count {
                        let found = MedicineDatabase.shared.interactionsBetween(medNames[i], medNames[j])
                        if !found.isEmpty {
                            interactionNotes.append(contentsOf: found)
                        }
                    }
                }
                if !interactionNotes.isEmpty {
                    ctx += "\n  DRUG INTERACTION ALERTS:\n"
                    for note in interactionNotes.prefix(5) {
                        ctx += "    \u{26A0} \(note)\n"
                    }
                }
            }
        }

        // Glucose Trends
        let recentGlucose = store.glucoseReadings.filter { $0.date >= sevenDaysAgo }
        ctx += "\nGLUCOSE (7 days, \(recentGlucose.count) readings):\n"
        if !recentGlucose.isEmpty {
            let avg = recentGlucose.map { $0.value }.reduce(0, +) / Double(recentGlucose.count)
            let minG = recentGlucose.map { $0.value }.min() ?? 0
            let maxG = recentGlucose.map { $0.value }.max() ?? 0
            let inRange = recentGlucose.filter { $0.value >= p.targetGlucoseMin && $0.value <= p.targetGlucoseMax }.count
            ctx += "  Avg: \(String(format: "%.1f", avg)), Range: \(Int(minG))-\(Int(maxG)), Time in target: \(Int(Double(inRange) / Double(recentGlucose.count) * 100))%\n"
            for r in recentGlucose.sorted(by: { $0.date > $1.date }).prefix(5) {
                ctx += "  \(r.date.formatted(.dateTime.day().month().hour().minute())): \(Int(r.value)) (\(r.context.rawValue))\n"
            }
        } else { ctx += "  No recent readings\n" }

        // Blood Pressure
        let recentBP = store.bpReadings.filter { $0.date >= sevenDaysAgo }
        ctx += "\nBLOOD PRESSURE (7 days, \(recentBP.count) readings):\n"
        if !recentBP.isEmpty {
            let avgSys = recentBP.map { $0.systolic }.reduce(0, +) / recentBP.count
            let avgDia = recentBP.map { $0.diastolic }.reduce(0, +) / recentBP.count
            ctx += "  Avg: \(avgSys)/\(avgDia) mmHg\n"
            for r in recentBP.sorted(by: { $0.date > $1.date }).prefix(5) {
                ctx += "  \(r.date.formatted(.dateTime.day().month().hour().minute())): \(r.systolic)/\(r.diastolic), pulse \(r.pulse)\n"
            }
        } else { ctx += "  No recent readings\n" }

        // Heart Rate & HRV
        let recentHR = store.heartRateReadings.filter { $0.date >= sevenDaysAgo }
        if !recentHR.isEmpty {
            let avgHR = recentHR.map { $0.value }.reduce(0, +) / recentHR.count
            ctx += "\nHEART RATE: Avg \(avgHR) bpm (7 days)\n"
        }
        let recentHRV = store.hrvReadings.filter { $0.date >= sevenDaysAgo }
        if !recentHRV.isEmpty {
            let avgHRV = recentHRV.map { $0.value }.reduce(0, +) / Double(recentHRV.count)
            ctx += "HRV: Avg \(Int(avgHRV)) ms\n"
        }

        // Sleep
        let recentSleep = store.sleepEntries.filter { $0.date >= sevenDaysAgo }
        if !recentSleep.isEmpty {
            let avgDur = recentSleep.map { $0.duration }.reduce(0, +) / Double(recentSleep.count)
            ctx += "\nSLEEP: Avg \(String(format: "%.1f", avgDur))hrs (target: \(String(format: "%.1f", p.targetSleep))hrs)\n"
            for s in recentSleep.sorted(by: { $0.date > $1.date }).prefix(3) {
                ctx += "  \(s.date.formatted(.dateTime.day().month())): \(String(format: "%.1f", s.duration))hrs — \(s.quality.rawValue)\n"
            }
        }

        // Steps & Activity
        ctx += "\nACTIVITY: Today \(store.todaySteps) steps (target: \(p.targetSteps))\n"
        let weekSteps = store.stepEntries.filter { $0.date >= sevenDaysAgo }
        if !weekSteps.isEmpty {
            let avgSteps = weekSteps.map { $0.steps }.reduce(0, +) / weekSteps.count
            ctx += "  7-day avg: \(avgSteps) steps/day\n"
        }

        // Stress
        let recentStress = store.stressReadings.filter { $0.date >= sevenDaysAgo }
        if !recentStress.isEmpty {
            let avgStress = recentStress.map { $0.level }.reduce(0, +) / recentStress.count
            ctx += "\nSTRESS: Avg \(avgStress)/10 (7 days)\n"
        }

        // SYMPTOMS — CRITICAL
        let recentSymptoms = store.symptomLogs.filter { $0.date >= thirtyDaysAgo }
        ctx += "\nSYMPTOMS (30 days, \(recentSymptoms.count) logs):\n"
        if recentSymptoms.isEmpty {
            ctx += "  No symptoms logged\n"
        } else {
            let allSyms = recentSymptoms.flatMap { $0.symptoms }
            let freq = Dictionary(grouping: allSyms, by: { $0 }).mapValues { $0.count }.sorted { $0.value > $1.value }
            for (name, count) in freq.prefix(10) {
                ctx += "  \(name): \(count)x\n"
            }
            let severe = recentSymptoms.filter { $0.severity == .severe }.count
            let moderate = recentSymptoms.filter { $0.severity == .moderate }.count
            ctx += "  Severity: \(severe) severe, \(moderate) moderate, \(recentSymptoms.count - severe - moderate) mild\n"
            for log in recentSymptoms.sorted(by: { $0.date > $1.date }).prefix(5) {
                ctx += "  \(log.date.formatted(.dateTime.day().month())): \(log.symptoms.joined(separator: ", ")) — \(log.severity.rawValue)"
                if !log.notes.isEmpty { ctx += " (\(log.notes))" }
                ctx += "\n"
            }
        }

        // Cycle Tracking
        let recentCycles = store.cycles.filter { $0.startDate >= thirtyDaysAgo }
        if !recentCycles.isEmpty {
            ctx += "\nCYCLE: \(recentCycles.count) entries (30 days)\n"
            for c in recentCycles.sorted(by: { $0.startDate > $1.startDate }).prefix(2) {
                ctx += "  \(c.startDate.formatted(.dateTime.day().month())) — \(c.flow.rawValue)"
                if !c.symptoms.isEmpty { ctx += " — \(c.symptoms.joined(separator: ", "))" }
                ctx += "\n"
            }
        }

        // Nutrition
        let recentNutrition = store.nutritionLogs.filter { $0.date >= sevenDaysAgo }
        if !recentNutrition.isEmpty {
            let avgCal = recentNutrition.map { $0.calories }.reduce(0, +) / recentNutrition.count
            ctx += "\nNUTRITION: ~\(avgCal) kcal/day avg (7 days)\n"
        }

        // Active Alerts
        let activeAlerts = store.healthAlerts.filter { !$0.isRead }
        if !activeAlerts.isEmpty {
            ctx += "\nALERTS:\n"
            for alert in activeAlerts.prefix(3) {
                ctx += "  \(alert.title): \(alert.message)\n"
            }
        }

        ctx += "\n--- IMPORTANT: Cross-reference symptoms with vitals, meds, sleep, activity. Spot patterns. ---\n"
        ctx += "Subscription: \(store.subscription.rawValue)\n"

        // ── Data-first enforcement ──────────────────────────────────────
        let threeDaysAgo = cal.date(byAdding: .day, value: -3, to: Date())!
        var dataGaps: [String] = []

        if !p.diabetesType.isEmpty && !store.glucoseReadings.contains(where: { $0.date >= threeDaysAgo }) {
            dataGaps.append("GLUCOSE: User has diabetes but NO glucose readings in the last 3 days. Do NOT give specific glucose management tips or blood sugar targets. Encourage them to log or sync glucose first.")
        }
        if p.hasHypertension && !store.bpReadings.contains(where: { $0.date >= threeDaysAgo }) {
            dataGaps.append("BP: User has hypertension but NO BP readings in the last 3 days. Do NOT recommend DASH diet, sodium limits, or specific BP strategies. Encourage logging BP first.")
        }
        if !store.sleepEntries.contains(where: { $0.date >= threeDaysAgo }) {
            dataGaps.append("SLEEP: No sleep data in 3 days. Do NOT give specific sleep advice based on their patterns.")
        }
        if !store.nutritionLogs.contains(where: { $0.date >= threeDaysAgo }) {
            dataGaps.append("NUTRITION: No nutrition logs in 3 days. Do NOT give calorie-specific advice.")
        }

        if !dataGaps.isEmpty {
            ctx += "\n--- DATA-FIRST RULES (CRITICAL) ---\n"
            ctx += "This user is still building their health profile. For areas below:\n"
            ctx += "1. Do NOT give specific numerical or condition-tailored advice\n"
            ctx += "2. Warmly encourage them to log or sync data for 2-3 days first\n"
            ctx += "3. You CAN answer general health questions\n\n"
            for gap in dataGaps { ctx += "* \(gap)\n" }
        }

        return ctx
    }

    // ── Entry point ──────────────────────────────────────────────────────────
    func respond(to input: String) async -> ChatMessage {
        isTyping = true

        // ── Emergency detection — prepend banner but still answer the query ─────
        let emergencyKeywords = ["chest pain", "heart attack", "can't breathe", "cannot breathe",
            "stroke", "seizure", "unconscious", "999", "911", "ambulance", "dying", "suicide", "self harm"]
        let isEmergency = emergencyKeywords.contains(where: { input.lowercased().contains($0) })

        // ── HealthSense Agent — adaptive, learning AI (primary path) ─────
        // The agent handles EVERYTHING: API calls, intelligent fallback, learning.
        // It NEVER falls through to the dumb rule-based system.
        if let agent = agent {
            // Pass history WITHOUT the current message (agent adds it internally via API)
            let historyForAgent = Array(conversationHistory.suffix(18))

            let result = await agent.respond(
                to: input,
                conversationHistory: historyForAgent
            )

            // Now update our conversation history
            conversationHistory.append((role: "user", content: input))
            conversationHistory.append((role: "assistant", content: result.response))

            isTyping = false

            var message = ChatMessage(content: result.response, isUser: false)
            message.chips = result.chips
            return message
        }

        // ── Legacy path (only if agent init failed) ──────────────────────
        conversationHistory.append((role: "user", content: input))

        if AIClient.shared.isConfigured() {
            do {
                let personalPrompt = AISystemPrompts.healthCoach + userHealthContext
                let recentHistory = Array(conversationHistory.suffix(20))

                let reply = try await AIClient.shared.sendWithHistory(
                    system: personalPrompt,
                    history: recentHistory.dropLast().map { ($0.role, $0.content) },
                    userMessage: input
                )

                var finalReply = reply
                if isEmergency {
                    finalReply = "\u{26A0}\u{FE0F} **If this is a medical emergency, call 999 (UK) or 911 (US) immediately.**\n\nWhile waiting for help: stay calm, follow the operator's instructions, and do not move the person unless they are in danger.\n\n---\n\n" + reply
                }
                conversationHistory.append((role: "assistant", content: finalReply))
                isTyping = false
                return ChatMessage(content: finalReply, isUser: false)
            } catch {
                print("⚠️ Claude API error: \(error.localizedDescription)")
            }
        }

        // Rule-based as absolute last resort
        let delay = Double.random(in: 0.4...0.8)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        isTyping = false
        let text = input.lowercased()
        var ruleMessage = buildReply(for: text, raw: input)
        if isEmergency {
            ruleMessage = ChatMessage(
                content: "\u{26A0}\u{FE0F} **If this is a medical emergency, call 999 (UK) or 911 (US) immediately.**\n\nWhile waiting for help: stay calm, follow the operator's instructions, and do not move the person unless they are in danger.\n\n---\n\n" + ruleMessage.content,
                isUser: false
            )
        }
        return ruleMessage
    }

    // ── Feedback passthrough to agent ─────────────────────────────────────
    func reportFeedback(_ feedback: MessageFeedback, forQuery query: String) {
        agent?.processFeedback(feedback, forQuery: query, domain: currentDomain)
    }

    // ── Intent Router ────────────────────────────────────────────────────────
    private func buildReply(for text: String, raw: String) -> ChatMessage {
        let name = firstName

        // ── Greetings
        if matches(text, ["hi", "hello", "hey", "good morning", "good afternoon", "good evening", "how are you", "sup", "howdy"]) {
            return greetingReply(name: name)
        }

        // ── Emergency / urgent
        if matches(text, ["chest pain", "heart attack", "stroke", "can't breathe", "cannot breathe", "unconscious", "collapsed", "seizure", "fitting", "not breathing", "emergency", "call 999", "call 911", "call 112", "overdose"]) {
            return emergencyReply()
        }

        // ── Glucose / diabetes / sugar
        if matches(text, ["glucose", "blood sugar", "blood glucose", "sugar level", "hyperglycemi", "hypoglycemi", "high sugar", "low sugar", "diabetes", "diabetic", "type 1", "type 2", "mg/dl", "mmol"]) {
            return glucoseReply(name: name)
        }

        // ── HbA1c
        if matches(text, ["hba1c", "a1c", "a1 c", "glycated", "haemoglobin", "hemoglobin a1", "long-term glucose"]) {
            return hba1cReply(name: name)
        }

        // ── Blood pressure / hypertension
        if matches(text, ["blood pressure", " bp ", "systolic", "diastolic", "hypertension", "high blood pressure", "low blood pressure", "hypotension", "mmhg", "pressure reading"]) {
            return bpReply(name: name)
        }

        // ── Heart health / cardiovascular
        if matches(text, ["heart", "cardiac", "cardiovascular", "palpitation", "arrhythmia", "atrial fibrillation", "afib", "angina", "coronary", "cholesterol", "ldl", "hdl", "triglyceride", "lipid", "statin", "heart failure", "edema in legs"]) {
            return heartReply(name: name, text: text)
        }

        // ── Stroke
        if matches(text, ["stroke", "tia", "transient ischaemic", "mini stroke", "face drooping", "arm weak", "speech slurred"]) {
            return strokeReply(name: name)
        }

        // ── Kidney
        if matches(text, ["kidney", "renal", "creatinine", "egfr", "dialysis", "nephropath", "kidney function", "protein in urine", "albumin in urine", "ckd"]) {
            return kidneyReply(name: name)
        }

        // ── Thyroid
        if matches(text, ["thyroid", "tsh", "hypothyroid", "hyperthyroid", "thyroxine", "levothyroxine", "graves", "hashimoto"]) {
            return thyroidReply(name: name)
        }

        // ── Nutrition / meal plan
        if matches(text, ["meal plan", "diet plan", "weekly plan", "what to eat this week", "plan for the week", "7 day plan", "nutrition plan"]) {
            return mealPlanReply(name: name)
        }

        // ── Food / what to eat / ingredients / specific foods
        if matches(text, ["eat", "food", "snack", "breakfast", "lunch", "dinner", "recipe", "cook", "hungry", "appetite", "meal", "calorie", "carb", "protein", "fat", "fibre", "fiber", "gluten", "lactose", "vegan", "vegetarian", "coconut", "olive oil", "avocado", "banana", "rice", "bread", "egg", "chicken", "salmon", "turmeric", "cinnamon", "ginger", "garlic", "honey", "oats", "nuts", "almond", "walnut", "berry", "blueberry", "apple", "orange", "lemon", "tea", "coffee", "chocolate", "sugar", "salt", "butter", "cheese", "milk", "yogurt", "quinoa", "lentil", "beans", "tofu", "fish", "beef", "pork", "lamb", "shea butter", "seed", "flax", "chia", "hemp", "spirulina", "matcha", "acai", "mango", "kale", "spinach", "broccoli", "sweet potato", "potato", "pasta", "noodle"]) {
            return foodReply(name: name, mealHint: text)
        }

        // ── Weight / BMI / obesity
        if matches(text, ["weight", "bmi", "overweight", "obese", "obesity", "underweight", "body mass", "lose weight", "gain weight", "slim", "fat loss", "belly fat"]) {
            return weightReply(name: name)
        }

        // ── Exercise / fitness
        if matches(text, ["exercise", "workout", "walk", "run", "gym", "activity", "steps", "physical", "sport", "fitness", "strength train", "resistance", "aerobic", "cardio", "hiit", "yoga", "pilates", "swimming", "cycling"]) {
            return exerciseReply(name: name)
        }

        // ── Sleep
        if matches(text, ["sleep", "tired", "fatigue", "rest", "insomnia", "woke up", "can't sleep", "sleep apnea", "snoring", "drowsy", "exhausted", "narcolepsy"]) {
            return sleepReply(name: name)
        }

        // ── Mental health / stress / anxiety / depression
        if matches(text, ["stress", "anxiety", "worried", "anxious", "mental health", "depressed", "depression", "mood", "panic", "panic attack", "sad", "feeling low", "suicidal", "self harm", "ptsd", "trauma", "ocd", "bipolar", "schizophrenia", "phobia"]) {
            return mentalHealthReply(name: name, text: text)
        }

        // ── Medications
        if matches(text, ["medication", "medicine", "pill", "tablet", "drug", "dose", "metformin", "insulin", "amlodipine", "losartan", "statin", "aspirin", "paracetamol", "ibuprofen", "lisinopril", "ramipril", "atorvastatin", "omeprazole", "salbutamol", "warfarin", "antibiotic", "antidepressant", "side effect", "prescription"]) {
            return medicationReply(name: name, text: text)
        }

        // ── Water / hydration
        if matches(text, ["water", "hydrat", "drink more", "thirst", "dehydrat", "fluids"]) {
            return waterReply(name: name)
        }

        // ── Women's health / cycle / hormones
        if matches(text, ["period", "cycle", "menstrual", "pms", "pmdd", "menopause", "perimenopause", "hormones", "estrogen", "oestrogen", "progesterone", "contraception", "pill contraceptive", "coil", "iud", "pregnancy", "pregnant", "fertility", "ovulation", "polycystic", "pcos", "endometriosis", "cervical"]) {
            return womensHealthReply(name: name, text: text)
        }

        // ── Gut / digestion
        if matches(text, ["stomach", "gut", "digestion", "bowel", "ibs", "constipation", "diarrhoea", "diarrhea", "bloating", "acid reflux", "heartburn", "gerd", "ulcer", "nausea", "vomiting", "crohn", "colitis", "coeliac", "celiac", "indigestion", "gallstone"]) {
            return gutReply(name: name, text: text)
        }

        // ── Respiratory / breathing / lungs
        if matches(text, ["breathing", "breath", "asthma", "inhaler", "copd", "bronchitis", "lung", "respiratory", "wheeze", "cough", "pneumonia", "spo2", "oxygen saturation", "shortness of breath", "respiratory infection"]) {
            return respiratoryReply(name: name, text: text)
        }

        // ── Skin
        if matches(text, ["skin", "eczema", "psoriasis", "rash", "acne", "dermatitis", "hives", "urticaria", "sunburn", "wound", "cut", "bruise", "mole", "melanoma", "ringworm", "fungal skin", "itchy skin"]) {
            return skinReply(name: name, text: text)
        }

        // ── Joints / muscles / bones
        if matches(text, ["joint", "arthritis", "osteoarthritis", "rheumatoid", "gout", "back pain", "knee pain", "hip pain", "shoulder pain", "muscle ache", "fibromyalgia", "bone", "osteoporosis", "fracture", "sprain", "tendon", "ligament", "cramp"]) {
            return musculoskeletalReply(name: name, text: text)
        }

        // ── Head / brain / neuro
        if matches(text, ["headache", "migraine", "dizziness", "dizzy", "vertigo", "brain", "memory", "dementia", "alzheimer", "parkinson", "epilepsy", "nerve", "neuropathy", "tingling", "numbness", "ms", "multiple sclerosis"]) {
            return neurologicalReply(name: name, text: text)
        }

        // ── Eyes / vision
        if matches(text, ["eye", "vision", "sight", "glaucoma", "cataract", "diabetic retinopathy", "blind", "blurry vision", "floaters", "conjunctivitis", "dry eyes"]) {
            return eyeReply(name: name)
        }

        // ── Ears / hearing
        if matches(text, ["ear", "hearing", "tinnitus", "ringing in ears", "hearing loss", "ear infection", "otitis", "earache"]) {
            return earReply(name: name)
        }

        // ── Dental / oral health
        if matches(text, ["teeth", "tooth", "gum", "dental", "cavity", "toothache", "mouth", "oral health", "bad breath", "gingivitis", "periodontitis"]) {
            return dentalReply(name: name)
        }

        // ── Immune system / infections / fever
        if matches(text, ["immune", "immunity", "infection", "fever", "cold", "flu", "covid", "virus", "bacteria", "antibiotic", "vaccine", "vaccination", "lymph node", "swollen gland"]) {
            return immuneReply(name: name, text: text)
        }

        // ── Cancer / screening
        if matches(text, ["cancer", "tumour", "tumor", "biopsy", "chemotherapy", "radiotherapy", "screening", "breast cancer", "cervical cancer", "bowel cancer", "prostate cancer", "skin cancer", "melanoma", "lymphoma", "leukaemia"]) {
            return cancerReply(name: name, text: text)
        }

        // ── Vitamins / supplements / nutrition science
        if matches(text, ["vitamin", "mineral", "supplement", "vitamin d", "vitamin b12", "iron deficiency", "anaemia", "anemia", "folic acid", "magnesium", "calcium", "zinc", "omega", "fish oil", "probiotic", "prebiotic"]) {
            return vitaminsReply(name: name, text: text)
        }

        // ── Children / pediatrics
        if matches(text, ["child", "children", "baby", "infant", "toddler", "teenager", "paediatric", "pediatric", "growth", "development", "vaccination child", "fever child"]) {
            return pediatricsReply(name: name, text: text)
        }

        // ── Men's health
        if matches(text, ["prostate", "testosterone", "erectile", "impotence", "testicular", "mens health", "men's health", "bph", "benign prostate"]) {
            return mensHealthReply(name: name)
        }

        // ── Allergies
        if matches(text, ["allergy", "allergic", "anaphylaxis", "epipen", "hay fever", "rhinitis", "food allergy", "nut allergy", "pollen"]) {
            return allergyReply(name: name)
        }

        // ── Summary / how am I doing
        if matches(text, ["summary", "how am i", "how am i doing", "my health", "overview", "status", "report", "health check"]) {
            return summaryReply(name: name)
        }

        // ── Tips / advice
        if matches(text, ["tip", "advice", "suggest", "recommend", "help me", "what should i", "give me advice"]) {
            return tipsReply(name: name)
        }

        // ── Device / ring
        if matches(text, ["ring", "watch", "device", "sensor", "bodysense ring", "apple watch", "sync", "connect", "wearable"]) {
            return deviceReply(name: name)
        }

        // ── Doctor
        if matches(text, ["doctor", "gp", "hospital", "clinic", "appointment", "referral", "see a doctor", "when to see"]) {
            return doctorReply(name: name)
        }

        // ── Smart fallback — try to detect topic from any medical term
        return smartFallback(name: name, text: text, raw: raw)
    }

    // ── GREETING ─────────────────────────────────────────────────────────────
    private func greetingReply(name: String) -> ChatMessage {
        var parts: [String] = ["Hello \(name)! 👋 I'm your BodySense AI — a comprehensive medical assistant."]
        if let g = store.latestGlucose {
            let s = store.glucoseStatus(g.value)
            parts.append("Your latest glucose is **\(Int(g.value)) mg/dL** — \(s.label).")
        }
        if let b = store.latestBP {
            parts.append("Blood pressure: \(b.systolic)/\(b.diastolic) mmHg (\(b.category.rawValue)).")
        }
        parts.append("\nI can answer questions on virtually any health topic in plain, everyday language. What can I help you with?")
        return msg(parts.joined(separator: " "),
                   chips: ["📊 Health summary", "🍽️ Meal plan", "💊 Medications", "🩸 Glucose", "❤️ Blood pressure"])
    }

    // ── EMERGENCY ────────────────────────────────────────────────────────────
    private func emergencyReply() -> ChatMessage {
        return msg("""
        🚨 **This may be a medical emergency.**

        **Call 999 (UK) · 112 (EU) · 911 (US) immediately** if you have:
        • Chest pain, tightness, or pressure
        • Sudden weakness or numbness in face, arm, or leg
        • Sudden severe headache with no known cause
        • Difficulty breathing or shortness of breath
        • Confusion, slurred speech, vision loss
        • Seizure or loss of consciousness
        • Severe bleeding that won't stop
        • Suspected overdose

        **Do not drive yourself.** Stay on the line with the operator.

        While waiting: sit or lie down, stay calm, unlock your front door.
        """, chips: ["💊 My medications", "📋 My health summary"])
    }

    // ── GLUCOSE / DIABETES ───────────────────────────────────────────────────
    private func glucoseReply(name: String) -> ChatMessage {
        guard !store.glucoseReadings.isEmpty else {
            return msg("""
            No glucose readings yet, \(name). Log one in **Track → Vitals**.

            **Understanding blood glucose:**
            • **Normal (fasting):** 70–99 mg/dL (3.9–5.5 mmol/L)
            • **Pre-diabetes (fasting):** 100–125 mg/dL (5.6–6.9 mmol/L)
            • **Diabetes (fasting):** ≥126 mg/dL (≥7.0 mmol/L)
            • **2 hours after eating (normal):** <140 mg/dL (<7.8 mmol/L)

            **What raises glucose:** carbohydrates, stress, illness, poor sleep, inactivity
            **What lowers glucose:** exercise, medication, fiber-rich foods, hydration
            """, chips: ["🍽️ What should I eat?", "💊 Diabetes medications", "🏃 Exercise for diabetes", "📋 Summary"])
        }

        let sorted = store.glucoseReadings.sorted { $0.date > $1.date }
        let latest = sorted[0]
        let status = store.glucoseStatus(latest.value)
        let avg7   = average(sorted.prefix(7).map { $0.value })
        let inRange14 = sorted.prefix(14).filter {
            $0.value >= store.userProfile.targetGlucoseMin &&
            $0.value <= store.userProfile.targetGlucoseMax
        }.count
        let pct = sorted.prefix(14).count > 0 ? Int(Double(inRange14) / Double(min(sorted.count, 14)) * 100) : 0

        var reply = "🩸 **Your Glucose, \(name)**\n\n"
        reply += "• Latest: **\(Int(latest.value)) mg/dL** — \(status.label) \(statusEmoji(status.label))\n"
        reply += "• Target range: \(Int(store.userProfile.targetGlucoseMin))–\(Int(store.userProfile.targetGlucoseMax)) mg/dL\n"
        reply += "• 7-day average: **\(Int(avg7)) mg/dL**\n"
        reply += "• Time in range (14 days): **\(pct)%**\n\n"

        if latest.value > 250 {
            reply += "🔴 **Very high glucose.** Check for ketones (Type 1). Drink water, take your medication if due. If you feel sick, dizzy, or are vomiting — seek urgent medical care.\n\n"
        } else if latest.value > store.userProfile.targetGlucoseMax {
            reply += "🟡 **Above target.** Avoid starchy and sugary foods right now. A 10–15 min walk can bring it down by 20–40 mg/dL. Check again in 1–2 hours.\n\n"
        } else if latest.value < 54 {
            reply += "🚨 **Severe hypo!** Take 15g fast carbs NOW (3–4 glucose tablets, 150ml juice). Sit down. Call someone if alone. Re-check in 15 min.\n\n"
        } else if latest.value < 70 {
            reply += "🔵 **Low glucose.** Eat 15g fast carbs (glucose tab, small juice, 3 Jelly Babies). Wait 15 min then re-check. Follow with a slow-release snack (crackers + cheese).\n\n"
        } else {
            reply += "✅ In range — good work. Keep up consistent meals, activity, and medication timing.\n\n"
        }

        reply += "**Long-term diabetes management:**\n"
        reply += "• Keep HbA1c below 7% (or as your doctor advises)\n"
        reply += "• Check your feet every day for cuts or numbness\n"
        reply += "• Eye screening every 1–2 years (diabetes can affect eyes)\n"
        reply += "• Kidney function test (eGFR, urine albumin) annually\n"
        reply += "• Cholesterol and blood pressure check every 6–12 months"

        return msg(reply, chips: ["🍽️ What to eat now?", "🧪 HbA1c estimate", "💊 Diabetes meds", "🏃 Exercise tips"])
    }

    // ── HbA1c ─────────────────────────────────────────────────────────────────
    private func hba1cReply(name: String) -> ChatMessage {
        let recent = store.glucoseReadings.sorted { $0.date > $1.date }.prefix(30)
        guard !recent.isEmpty else {
            return msg("""
            **What is HbA1c?**
            HbA1c tells you your average blood sugar level over the past 2–3 months. Think of it as a school report card for your glucose control.

            • **Below 5.7%** = Normal (no diabetes)
            • **5.7–6.4%** = Pre-diabetes — lifestyle changes can reverse this
            • **6.5% or higher** = Diabetes
            • **Target for most people with diabetes:** below 7%
            • **Lower target (<6.5%)** if advised by your doctor
            • **Higher target (7.5–8%)** for elderly or those with frequent hypos

            Log more glucose readings for an estimate, \(name).
            """, chips: ["🩸 Log glucose", "🍽️ Lower my HbA1c", "💊 Medications"])
        }

        let avg   = average(recent.map { $0.value })
        let hba1c = (avg + 46.7) / 28.7

        var reply = "🧪 **Estimated HbA1c for \(name)**\n\n"
        reply += "Based on your last \(recent.count) glucose readings:\n"
        reply += "• Average glucose: **\(Int(avg)) mg/dL**\n"
        reply += "• Estimated HbA1c: **\(String(format: "%.1f", hba1c))%**\n\n"

        if hba1c < 5.7 {
            reply += "✅ **Non-diabetic range.** Your glucose control is excellent.\n\n"
        } else if hba1c < 6.5 {
            reply += "🟡 **Pre-diabetes range.** Lifestyle changes (diet, exercise, weight loss) can bring this back to normal.\n\n"
        } else if hba1c < 7.0 {
            reply += "✅ **Well-controlled diabetes.** You're meeting most guideline targets — keep it up!\n\n"
        } else if hba1c < 8.0 {
            reply += "🟠 **Above target.** Focus on consistent meal timing, reducing high-GI carbs, and medication adherence.\n\n"
        } else {
            reply += "🔴 **Well above target.** Please speak to your doctor — a medication review may be needed. Get a real lab HbA1c done.\n\n"
        }

        reply += "**How to lower HbA1c:**\n"
        reply += "• Cut white carbs (rice, bread, pasta) — swap for whole grain\n"
        reply += "• Walk 30 min after every meal\n"
        reply += "• Don't skip meals — consistent eating = consistent glucose\n"
        reply += "• Take medications at the same time every day\n"
        reply += "• Reduce stress (cortisol raises glucose)\n"
        reply += "• Sleep 7–9 hours (poor sleep raises A1c)\n\n"
        reply += "_Note: This estimate uses the ADAG formula. A lab test is needed for an official result._"

        return msg(reply, chips: ["🍽️ Lower glucose diet", "🏃 Exercise tips", "💊 Medications", "📋 Full summary"])
    }

    // ── BLOOD PRESSURE / HYPERTENSION ────────────────────────────────────────
    private func bpReply(name: String) -> ChatMessage {
        guard let latest = store.latestBP else {
            return msg("""
            **Understanding Blood Pressure**

            Blood pressure is the force your blood puts on artery walls. It's written as two numbers: **systolic/diastolic** (e.g. 120/80 mmHg).

            **What the numbers mean:**
            • Below 120/80 = **Normal** ✅
            • 120–129 / below 80 = **Elevated** — lifestyle changes needed
            • 130–139 / 80–89 = **Stage 1 Hypertension**
            • 140+ / 90+ = **Stage 2 Hypertension**
            • 180+ / 120+ = **Hypertensive Crisis** — seek emergency care

            **What raises BP:** salt, stress, alcohol, smoking, obesity, inactivity, poor sleep
            **What lowers BP:** exercise, DASH diet, potassium-rich foods, reducing alcohol, meditation

            No readings yet, \(name). Log one in Track → Vitals.
            """, chips: ["🧂 Low-salt foods", "🏃 BP exercises", "💊 BP medications", "❤️ Heart health"])
        }

        let sorted = store.bpReadings.sorted { $0.date > $1.date }.prefix(7)
        let avgSys = Int(average(sorted.map { Double($0.systolic) }))
        let avgDia = Int(average(sorted.map { Double($0.diastolic) }))

        var reply = "❤️ **Blood Pressure for \(name)**\n\n"
        reply += "• Latest: **\(latest.systolic)/\(latest.diastolic) mmHg** (\(latest.category.rawValue))\n"
        reply += "• Pulse: \(latest.pulse) bpm\n"
        reply += "• 7-day average: \(avgSys)/\(avgDia) mmHg\n"
        reply += "• Target: <\(store.userProfile.targetSystolic)/\(store.userProfile.targetDiastolic) mmHg\n\n"

        switch latest.category {
        case .normal:
            reply += "✅ **Excellent BP control.** Keep up the low-sodium diet, regular exercise, and healthy weight.\n\n"
        case .elevated:
            reply += "🟡 **Slightly elevated.** Reduce salt (aim <2g/day), limit caffeine, and try 5 deep breaths. Re-check in 30 min.\n\n"
        case .high1:
            reply += "🟠 **Stage 1 hypertension.** If prescribed BP medication, check you've taken it. Avoid caffeine and salty foods today. Rest and re-check.\n\n"
        case .high2:
            reply += "🔴 **Stage 2 hypertension — act now.** Sit and rest. If you have a headache, chest pain, or visual changes, go to A&E immediately.\n\n"
        }

        reply += "**DASH Diet for BP (proven to lower by 8–14 mmHg):**\n"
        reply += "• More: fruits, vegetables, wholegrains, low-fat dairy\n"
        reply += "• Less: red meat, added sugar, sodium, alcohol\n"
        reply += "• Potassium-rich foods (bananas, spinach, sweet potato) help relax blood vessel walls\n\n"
        reply += "**Exercise for BP:** 150 min moderate cardio/week (brisk walking, swimming, cycling) can lower systolic by 5–8 mmHg.\n\n"
        reply += "**Common BP medications (for reference):**\n"
        reply += "• ACE inhibitors: ramipril, lisinopril, perindopril\n"
        reply += "• ARBs: losartan, candesartan, valsartan\n"
        reply += "• Calcium channel blockers: amlodipine, felodipine\n"
        reply += "• Beta-blockers: bisoprolol, atenolol\n"
        reply += "• Diuretics: indapamide, furosemide"

        return msg(reply, chips: ["🧂 Low-salt foods", "🏃 Exercise for BP", "💊 BP meds explained", "📋 Summary"])
    }

    // ── HEART HEALTH ─────────────────────────────────────────────────────────
    private func heartReply(name: String, text: String) -> ChatMessage {
        if text.contains("cholesterol") || text.contains("ldl") || text.contains("hdl") || text.contains("triglyceride") || text.contains("statin") || text.contains("lipid") {
            return cholesterolReply(name: name)
        }
        var reply = "❤️ **Heart Health for \(name)**\n\n"
        reply += "**Normal heart function:**\n"
        reply += "Your heart beats 60–100 times per minute and pumps blood to every organ. Heart disease is the #1 cause of death worldwide, but it's largely preventable.\n\n"
        reply += "**Warning signs to never ignore:**\n"
        reply += "• Chest pain, pressure, or tightness (especially with exercise)\n"
        reply += "• Breathlessness at rest or with minimal effort\n"
        reply += "• Palpitations (racing, irregular, or missed heartbeats)\n"
        reply += "• Swollen ankles or legs (sign of heart failure)\n"
        reply += "• Unexplained fatigue\n\n"
        reply += "**Protecting your heart:**\n"
        reply += "• Don't smoke — smoking doubles heart disease risk\n"
        reply += "• Keep BP below 130/80 mmHg\n"
        reply += "• Keep LDL cholesterol below 70 mg/dL (if high risk)\n"
        reply += "• Keep blood glucose controlled (diabetes damages heart vessels)\n"
        reply += "• Exercise 150 min/week — heart is a muscle; train it\n"
        reply += "• Maintain healthy weight (BMI 18.5–24.9)\n"
        reply += "• Eat oily fish 2× week (omega-3 reduces triglycerides)\n"
        reply += "• Limit alcohol: max 14 units/week (UK guidance)"
        return msg(reply, chips: ["🩺 Cholesterol explained", "❤️ My BP", "🏃 Cardio exercise", "📋 Health summary"])
    }

    private func cholesterolReply(name: String) -> ChatMessage {
        return msg("""
        🩺 **Cholesterol for \(name)**

        Cholesterol is a fatty substance in your blood. Too much damages arteries and raises heart attack risk.

        **Ideal levels:**
        • Total cholesterol: below 5.0 mmol/L (190 mg/dL)
        • LDL ("bad"): below 3.0 mmol/L — below 1.8 if high risk
        • HDL ("good"): above 1.0 (men) / 1.2 (women) mmol/L
        • Triglycerides: below 1.7 mmol/L

        **What raises LDL (bad):**
        • Saturated fat (butter, fatty meat, full-fat dairy, coconut oil)
        • Trans fat (processed biscuits, pastries)
        • Low physical activity
        • Excess weight, smoking

        **What raises HDL (good):**
        • Exercise — even 30 min walking daily raises HDL
        • Oily fish (salmon, mackerel, sardines)
        • Nuts (almonds, walnuts)
        • Olive oil
        • Stopping smoking

        **Statins (cholesterol-lowering medications):**
        • Atorvastatin, rosuvastatin, simvastatin
        • Very effective — reduce heart attack risk by 25–35%
        • Take at night (except rosuvastatin — any time)
        • Common side effect: muscle ache — tell your doctor if severe
        • Do NOT stop without speaking to your doctor

        **Target: get a fasting lipid panel blood test at least every 5 years (or annually if high risk).**
        """, chips: ["❤️ Heart health", "🏃 Exercise for cholesterol", "🍽️ Heart-healthy foods", "💊 Statins"])
    }

    // ── STROKE ───────────────────────────────────────────────────────────────
    private func strokeReply(name: String) -> ChatMessage {
        return msg("""
        🧠 **Stroke Awareness for \(name)**

        A stroke happens when blood supply to part of the brain is cut off. Every minute matters — **FAST** is the key test:

        🅵 **Face** — Is one side drooping or numb?
        🅰 **Arms** — Can they raise both arms? Does one drift down?
        🆂 **Speech** — Is speech slurred or garbled?
        🆃 **Time** — Call 999 / 112 / 911 **immediately**

        **Types:**
        • **Ischaemic (87%)** — clot blocks blood flow. Treated with clot-busting drugs (within 4.5 hours)
        • **Haemorrhagic (13%)** — blood vessel bleeds into brain
        • **TIA (mini stroke)** — temporary symptoms, fully resolves. Still an emergency — high risk of full stroke within 48 hours

        **Risk factors (many are preventable):**
        • High blood pressure (biggest risk factor — treat it!)
        • Atrial fibrillation (irregular heartbeat — blood clots form)
        • Smoking, obesity, inactivity, excess alcohol
        • Diabetes, high cholesterol

        **After a stroke:**
        Recovery depends on which part of the brain was affected. Physiotherapy, speech therapy, and medication all help. Many people make significant recovery.
        """, chips: ["❤️ Blood pressure", "💊 Blood thinners explained", "🏃 Rehabilitation exercises", "📋 My health"])
    }

    // ── KIDNEY ───────────────────────────────────────────────────────────────
    private func kidneyReply(name: String) -> ChatMessage {
        return msg("""
        🫘 **Kidney Health for \(name)**

        Your kidneys filter about 180 litres of blood per day, removing waste and regulating blood pressure. Diabetes and high BP are the two main causes of kidney disease.

        **Key tests (get these annually if you have diabetes or hypertension):**
        • **eGFR** (estimated glomerular filtration rate):
          - Above 90 = Normal
          - 60–89 = Mildly reduced
          - 30–59 = Moderately reduced (CKD stage 3)
          - 15–29 = Severely reduced (stage 4)
          - Below 15 = Kidney failure — dialysis or transplant needed
        • **Urine albumin-to-creatinine ratio (ACR):** detects protein leaking (early damage)

        **Warning signs of kidney problems:**
        • Swollen ankles, feet, or hands
        • Fatigue and weakness
        • Reduced urine output, or very foamy urine
        • High blood pressure that's hard to control
        • Itchy skin (urea builds up)
        • Nausea

        **Protecting your kidneys:**
        • Keep blood glucose controlled (high glucose damages kidney vessels)
        • Keep BP below 130/80 mmHg
        • Stay well hydrated (water, not juice)
        • Avoid NSAIDs (ibuprofen, naproxen) long-term — they harm kidneys
        • Don't smoke
        • Limit protein intake if eGFR is declining (ask your doctor)
        • Medications: ACE inhibitors/ARBs (lisinopril, ramipril, losartan) protect kidney vessels
        """, chips: ["🩸 Glucose control", "❤️ Blood pressure", "💊 Kidney medications", "📋 Summary"])
    }

    // ── THYROID ──────────────────────────────────────────────────────────────
    private func thyroidReply(name: String) -> ChatMessage {
        return msg("""
        🦋 **Thyroid Health for \(name)**

        Your thyroid is a small butterfly-shaped gland in your neck. It controls your metabolism — how fast your body runs.

        **Hypothyroidism (underactive thyroid) — TSH high, T4 low:**
        • Symptoms: fatigue, weight gain, cold intolerance, constipation, dry skin, hair loss, depression, slow heart rate
        • Most common cause: Hashimoto's thyroiditis (autoimmune)
        • Treatment: levothyroxine (daily tablet) — usually lifelong
        • Goal: TSH within 0.4–4.0 mIU/L (or tighter if pregnant)

        **Hyperthyroidism (overactive thyroid) — TSH low, T4/T3 high:**
        • Symptoms: weight loss, tremor, anxiety, palpitations, sweating, heat intolerance, diarrhoea, bulging eyes (Graves')
        • Causes: Graves' disease (autoimmune), toxic nodular goitre
        • Treatments: carbimazole, propylthiouracil, radioiodine, surgery

        **Important:**
        • Take levothyroxine on an empty stomach, 30–60 min before breakfast
        • Avoid calcium, iron, antacids within 4 hours of levothyroxine (they block absorption)
        • Get TSH checked every 6–12 months once stable
        • Thyroid affects cholesterol, heart rate, bone density, fertility, and mood — good control matters
        """, chips: ["⚖️ Thyroid and weight", "💊 Levothyroxine tips", "🧪 Thyroid blood test", "📋 Summary"])
    }

    // ── MEAL PLAN ─────────────────────────────────────────────────────────────
    private func mealPlanReply(name: String) -> ChatMessage {
        let isType1 = store.userProfile.diabetesType.contains("Type 1")
        let hasHyp  = store.userProfile.diabetesType.contains("Hypertension") || store.userProfile.hasHypertension

        var plan = "🍽️ **7-Day Meal Plan for \(name)**\n"
        plan += "_Tailored for: \(store.userProfile.diabetesType)_\n\n"

        let meals: [(String, String, String, String)] = [
            ("Mon", "Porridge + blueberries + boiled egg", "Grilled chicken salad, lemon & olive oil dressing", "Baked salmon + steamed broccoli + brown rice"),
            ("Tue", "Greek yoghurt (low-fat) + chia seeds + walnuts", "Lentil soup + 1 slice whole-grain bread", "Tofu stir-fry + quinoa + pak choi"),
            ("Wed", "Rye toast + avocado + 2 poached eggs", "Turkey & salad wrap (whole wheat)", "Grilled chicken + sweet potato + wilted spinach"),
            ("Thu", "Smoothie: spinach, ½ banana, almond milk, flaxseed", "Chickpea & roasted veg salad + olive oil", "Baked cod + cauliflower mash + asparagus"),
            ("Fri", "Overnight oats + almonds + cinnamon", "Grilled veggie flatbread (wholegrain)", "Beef & vegetable stew + small portion brown rice"),
            ("Sat", "Scrambled eggs + mushrooms + sliced tomato", "Tuna & cucumber open sandwich (rye bread)", "Chicken & lentil curry + basmati rice (⅓ cup) + cucumber raita"),
            ("Sun", "Porridge + pumpkin seeds + raspberries", "Vegetable omelette + mixed green salad", "Grilled king prawns + courgetti + garlic olive oil")
        ]

        for m in meals {
            plan += "**\(m.0)** ☀️ \(m.1) | 🌤 \(m.2) | 🌙 \(m.3)\n"
        }

        plan += "\n**Healthy Snacks:** handful of nuts · celery + hummus · hard-boiled egg · apple + almond butter · low-fat cheese slice\n\n"

        if isType1 {
            plan += "⚡ _Type 1: Count carbs and adjust insulin to your doctor's ratio. Always carry fast carbs._\n"
        }
        if hasHyp {
            plan += "🧂 _Hypertension: Keep sodium below 2g/day. Avoid processed meats, tinned soups, and salty snacks._\n"
        }

        plan += "\n💧 **Drink 2–2.5 litres of water daily** — more if exercising or hot weather."

        return msg(plan, chips: ["🥗 Breakfast ideas", "🍲 Lunch ideas", "🌙 Dinner ideas", "🍎 Snack ideas"])
    }

    // ── FOOD / WHAT TO EAT ────────────────────────────────────────────────────
    private func foodReply(name: String, mealHint: String) -> ChatMessage {
        let g = store.latestGlucose?.value ?? 110
        let status = store.glucoseStatus(g)

        // ── Check for specific food queries first ──
        let specificFoodInfo = getSpecificFoodInfo(for: mealHint)
        if let info = specificFoodInfo {
            var reply = "\(info.emoji) **\(info.name)** — \(name)\n\n"
            reply += "_Current glucose: \(Int(g)) mg/dL (\(status.label))_\n\n"
            reply += info.details
            // Add BMI-personalised context
            let bmi = store.userProfile.height > 0 ? store.userProfile.weight / pow(store.userProfile.height / 100, 2) : 0
            if bmi > 25 {
                reply += "\n\n⚖️ _Based on your BMI of \(String(format: "%.1f", bmi)), watch portion sizes and focus on the lower-calorie preparation methods mentioned above._"
            }
            reply += "\n\n💡 _Use the **Food Search** in Track → Nutrition to look up exact calorie and macro data for any food._"
            return msg(reply, chips: ["🔍 Search foods", "📅 7-day meal plan", "🩸 My glucose", "📋 Summary"])
        }

        // ── General food guide ──
        var reply = "🍽️ **Food Guide for \(name)**\n\n"
        reply += "_Current glucose: \(Int(g)) mg/dL (\(status.label))_\n\n"

        if g > 180 {
            reply += "Your glucose is elevated — choose **very low-GI** options:\n"
            reply += "• Large salad with grilled chicken or tuna (no croutons)\n"
            reply += "• Boiled eggs with cucumber and celery\n"
            reply += "• Steamed non-starchy vegetables (broccoli, courgette, kale)\n"
            reply += "• A handful of unsalted nuts\n\n"
            reply += "⚠️ **Avoid until levels come down:** white rice, bread, pasta, fruit juice, sugary drinks, tropical fruits\n"
        } else if g < 80 {
            reply += "Your glucose is low — have a **15g fast-carb snack first:**\n"
            reply += "• 150ml fruit juice or non-diet soft drink\n"
            reply += "• 3–4 glucose tablets\n"
            reply += "• 3 Jelly Babies\n"
            reply += "• 1 tablespoon of honey or sugar\n\n"
            reply += "Re-check in 15 min. Then follow with a slow-release snack: oatcakes + peanut butter, or toast + eggs.\n"
        } else if mealHint.contains("breakfast") {
            reply += "**Breakfast ideas 🌅**\n• Porridge with berries and almonds (low GI, keeps you full)\n• 2 eggs (scrambled, poached, or boiled) + rye toast\n• Greek yoghurt + chia seeds + mixed nuts\n• Smoothie: spinach, berries, flaxseed, almond milk\n• Avocado on wholegrain toast"
        } else if mealHint.contains("lunch") {
            reply += "**Lunch ideas ☀️**\n• Grilled chicken salad (olive oil + lemon dressing)\n• Lentil or vegetable soup + wholegrain bread\n• Tuna wrap with mixed greens (whole wheat)\n• Chickpea and roasted veg salad\n• Omelette with vegetables"
        } else if mealHint.contains("dinner") {
            reply += "**Dinner ideas 🌙**\n• Baked salmon + broccoli + brown rice (⅓ plate)\n• Grilled chicken + sweet potato + leafy greens\n• Tofu stir-fry with quinoa and pak choi\n• Baked cod + cauliflower mash\n• Chicken & lentil curry (light, low-fat)\n\nKeep dinner portions slightly smaller than lunch — you're less active at night."
        } else if mealHint.contains("snack") {
            reply += "**Healthy snacks 🍎**\n• Handful of almonds or walnuts (15–20 nuts)\n• Apple or pear + 1 tbsp almond/peanut butter\n• Oatcakes + low-fat cheese\n• Celery or carrot sticks + hummus\n• Hard-boiled egg\n• Low-fat Greek yoghurt"
        } else if mealHint.contains("sugar") || mealHint.contains("cut sugar") || mealHint.contains("reduce sugar") {
            reply += "**Cutting Sugar — Personalised Advice**\n\n"
            let bmi = store.userProfile.height > 0 ? store.userProfile.weight / pow(store.userProfile.height / 100, 2) : 0
            if bmi > 0 {
                reply += "Your BMI: **\(String(format: "%.1f", bmi))** — "
                reply += bmi > 25 ? "reducing sugar is especially important for weight management.\n\n" : "great range! Keeping sugar low will help maintain it.\n\n"
            }
            reply += "**Best foods to cut sugar:**\n"
            reply += "• **Swap white bread → wholegrain** (50% less sugar impact)\n"
            reply += "• **Greek yoghurt** instead of flavoured yoghurt (saves ~15g sugar)\n"
            reply += "• **Berries** instead of tropical fruits (lower glycaemic load)\n"
            reply += "• **Cinnamon** in coffee/porridge (may improve insulin sensitivity)\n"
            reply += "• **Nuts & seeds** for snacking (virtually zero sugar)\n"
            reply += "• **Eggs + avocado** for breakfast (keeps blood sugar stable for hours)\n"
            reply += "• **Water + lemon** instead of fruit juice (saves ~25g sugar per glass)\n\n"
            reply += "**Daily sugar target:** NHS recommends no more than 30g free sugars/day for adults."
        } else {
            reply += "**General eating principles:**\n\n"
            reply += "✅ **Eat more:** non-starchy vegetables, whole grains, legumes, lean protein (chicken, fish, tofu, eggs), healthy fats (avocado, nuts, olive oil), berries\n\n"
            reply += "❌ **Reduce:** white bread, white rice, sugary cereals, fruit juice, processed snacks, fried food, red meat, full-fat dairy\n\n"
            reply += "🎯 **The Plate Method (easy guide):**\n• ½ plate = non-starchy vegetables\n• ¼ plate = lean protein\n• ¼ plate = complex carbohydrates\n\n"
            reply += "🕐 **Meal timing matters:**\nEat at consistent times, don't skip meals, and avoid large portions after 7 PM."
        }

        return msg(reply, chips: ["🔍 Search foods", "📅 7-day meal plan", "🥗 Breakfast ideas", "🌙 Dinner ideas"])
    }

    // ── Specific food knowledge base (used when API is unavailable) ──────
    private struct FoodInfo {
        let name: String
        let emoji: String
        let details: String
    }

    private func getSpecificFoodInfo(for text: String) -> FoodInfo? {
        let t = text.lowercased()

        if t.contains("coconut oil") {
            return FoodInfo(name: "Coconut Oil", emoji: "🥥", details: """
            **Nutritional profile (per 15ml/1 tbsp):**
            • Calories: ~130 kcal | Fat: 14g (82% saturated) | Carbs: 0g | Protein: 0g

            **Health benefits:**
            • Contains **MCTs (medium-chain triglycerides)** — metabolised faster than other fats
            • **Lauric acid** (~50% of fat) has antimicrobial and antiviral properties
            • May boost HDL (good) cholesterol levels
            • Good for **skin & hair** when applied topically (moisturising, antibacterial)
            • Excellent for high-heat cooking (smoke point: 177°C)

            **Considerations:**
            • Very high in **saturated fat** — the British Heart Foundation recommends limiting saturated fat
            • Use in moderation: 1–2 tablespoons per day maximum
            • Not a miracle weight-loss food — it's still 862 kcal per 100g
            • For heart health, **olive oil is generally preferred** (more unsaturated fats)

            **Best uses:** cooking oil, smoothies, baking, skin moisturiser, hair treatment.
            """)
        }

        if t.contains("olive oil") {
            return FoodInfo(name: "Olive Oil (Extra Virgin)", emoji: "🫒", details: """
            **Nutritional profile (per 15ml/1 tbsp):**
            • Calories: ~130 kcal | Fat: 14g (mostly monounsaturated) | Carbs: 0g | Protein: 0g

            **Health benefits:**
            • Rich in **oleic acid** (omega-9) — lowers LDL, raises HDL cholesterol
            • Packed with **polyphenols** — powerful antioxidants that reduce inflammation
            • Part of the **Mediterranean diet** (strongest evidence for heart health)
            • May reduce risk of stroke by up to 41% (meta-analysis data)
            • Anti-inflammatory — comparable to low-dose ibuprofen (oleocanthal)
            • Supports gut health and may reduce cancer risk

            **Best uses:** salad dressings, drizzling on food, light cooking (smoke point ~190°C).
            **Tip:** Choose **extra virgin** — cold-pressed, unrefined, highest in polyphenols.
            """)
        }

        if t.contains("shea butter") {
            return FoodInfo(name: "Shea Butter", emoji: "🧴", details: """
            **What is Shea Butter?**
            A natural fat extracted from the nuts of the African shea tree. Primarily used for skincare.

            **Skin benefits:**
            • **Deep moisturiser** — rich in vitamins A, E, and F (essential fatty acids)
            • **Anti-inflammatory** — contains cinnamic acid, helps with eczema, psoriasis, dermatitis
            • **Collagen support** — may help reduce wrinkles and fine lines
            • **UV protection** — provides mild SPF ~6 (not a replacement for sunscreen)
            • **Wound healing** — promotes cell regeneration
            • **Stretch marks** — helps improve skin elasticity during pregnancy or weight changes
            • **Non-comedogenic** — generally won't clog pores

            **How to use on skin:**
            • Apply unrefined shea butter directly to clean, damp skin
            • Best applied after shower when pores are open
            • Can mix with essential oils (tea tree, lavender) for enhanced benefits
            • Use as lip balm, body butter, or hair conditioner

            **Note:** While edible in some African cuisines, it's mainly a topical product in the UK. Rich in stearic and oleic acids.
            """)
        }

        if t.contains("avocado") {
            return FoodInfo(name: "Avocado", emoji: "🥑", details: """
            **Nutritional profile (per 100g):**
            • Calories: 160 kcal | Fat: 15g | Carbs: 8.5g | Protein: 2g | Fibre: 6.7g

            **Health benefits:**
            • Excellent source of **heart-healthy monounsaturated fats** (oleic acid)
            • Very high in **fibre** — 6.7g per 100g, supports digestive health
            • Rich in **potassium** (more than bananas!) — helps control blood pressure
            • Contains **vitamins K, C, B5, B6, E** and **folate**
            • May improve cholesterol: raises HDL, lowers LDL
            • Low glycaemic index — doesn't spike blood sugar
            • **Lutein** — supports eye health

            **Best ways to eat:** on toast, in salads, smoothies, guacamole, or as egg topper.
            **Portion:** Half an avocado (~80g) is a good serving — it's calorie-dense.
            """)
        }

        if t.contains("turmeric") || t.contains("curcumin") {
            return FoodInfo(name: "Turmeric", emoji: "🟡", details: """
            **Active compound: Curcumin** (2–5% of turmeric powder)

            **Health benefits:**
            • **Powerful anti-inflammatory** — may help with arthritis, joint pain, inflammatory bowel disease
            • **Antioxidant** — neutralises free radicals, protects cells
            • **Brain health** — may increase BDNF (brain growth factor), potentially lowering Alzheimer risk
            • **Heart health** — improves endothelial function (blood vessel lining)
            • **Blood sugar** — some evidence it improves insulin sensitivity
            • **Cancer research** — laboratory studies show anti-tumour properties (early research)

            **How to take:**
            • In cooking: curries, golden milk, smoothies, scrambled eggs
            • Always combine with **black pepper** (piperine increases absorption by 2,000%)
            • Take with **fat** (coconut oil, olive oil) for better absorption
            • Supplement: 500–1000mg curcumin daily (check with your doctor)

            **Caution:** High doses may interact with blood thinners and diabetes medication.
            """)
        }

        if t.contains("cinnamon") {
            return FoodInfo(name: "Cinnamon", emoji: "🟤", details: """
            **Health benefits:**
            • May **lower blood sugar** by improving insulin sensitivity (several clinical trials)
            • **Antioxidant-rich** — one of the highest ORAC scores of any spice
            • **Anti-inflammatory** — may reduce markers of inflammation
            • May lower **LDL cholesterol** and triglycerides
            • **Antimicrobial** — cinnamaldehyde fights bacteria and fungi

            **For blood sugar:** Studies suggest 1–6g (½–1 tsp) daily can reduce fasting glucose by 10–29%.
            **Best type:** **Ceylon cinnamon** (true cinnamon) is safer long-term than Cassia (contains coumarin).
            **How to use:** in porridge, coffee, yoghurt, smoothies, baking, curries.
            """)
        }

        if t.contains("banana") {
            return FoodInfo(name: "Banana", emoji: "🍌", details: """
            **Nutritional profile (1 medium banana ~120g):**
            • Calories: 107 kcal | Carbs: 27g | Fibre: 3.1g | Protein: 1.3g | Sugar: 14g

            **Health benefits:**
            • Excellent source of **potassium** (422mg) — helps control blood pressure
            • Good source of **vitamin B6** — supports brain function and mood
            • Contains **resistant starch** (especially when slightly green) — feeds gut bacteria
            • Natural **pre-workout fuel** — easily digestible carbs for energy
            • May support **heart health** and reduce kidney disease risk

            **Diabetes note:** Bananas are medium GI (51). Green/unripe bananas have lower GI. Pair with protein (peanut butter) to slow sugar absorption.
            **Portion tip:** Stick to 1 medium banana per sitting for blood sugar control.
            """)
        }

        if t.contains("egg") && !t.contains("eggplant") {
            return FoodInfo(name: "Eggs", emoji: "🥚", details: """
            **Nutritional profile (1 large egg ~60g):**
            • Calories: 93 kcal | Protein: 7.8g | Fat: 6.6g | Carbs: 0.6g

            **Health benefits:**
            • **Complete protein** — all 9 essential amino acids, very bioavailable
            • Rich in **choline** — critical for brain health and liver function
            • Contains **lutein & zeaxanthin** — protects eyes from macular degeneration
            • Good source of **vitamin D, B12, selenium**
            • **Does NOT raise heart disease risk** — latest evidence (NICE/NHS) says eggs are fine for most people
            • Keeps you full — great for weight management

            **How many:** Up to 2–3 eggs per day is considered safe for most adults.
            **Best prep:** Boiled or poached (no added fat). Scrambled in olive oil is good too.
            **Blood sugar:** Eggs have virtually zero effect on blood glucose — excellent for diabetics.
            """)
        }

        if t.contains("rice") && !t.contains("price") {
            return FoodInfo(name: "Rice", emoji: "🍚", details: """
            **Nutritional comparison (per 100g cooked):**
            • **White rice:** 130 kcal | Carbs: 28g | Protein: 2.7g | Fibre: 0.4g
            • **Brown rice:** 112 kcal | Carbs: 23g | Protein: 2.6g | Fibre: 1.8g
            • **Basmati:** 121 kcal | Carbs: 25g | Protein: 3.5g | Fibre: 0.4g

            **Health notes:**
            • Brown rice has **4.5x more fibre** and more vitamins (B1, B3, magnesium)
            • Basmati has the **lowest GI** among white rices (GI ~50 vs 73 for short-grain)
            • **Cool rice trick:** cooking then cooling rice increases resistant starch by 2–3x (even reheated!) — lowers blood sugar impact
            • A standard portion is **75g dry / 200g cooked**

            **For diabetes:** Choose basmati or brown, keep portions to ¼ plate, pair with protein and vegetables.
            """)
        }

        if t.contains("chicken") {
            return FoodInfo(name: "Chicken", emoji: "🍗", details: """
            **Nutritional profile (per 100g grilled breast, skinless):**
            • Calories: 165 kcal | Protein: 31g | Fat: 3.6g | Carbs: 0g

            **Health benefits:**
            • One of the **best lean protein sources** — high protein, low fat
            • Rich in **B vitamins** (B3, B6) — supports energy metabolism
            • Good source of **selenium** — supports thyroid and immune function
            • **Tryptophan** — helps produce serotonin (mood and sleep)
            • Versatile and affordable

            **Tips:** Remove skin to cut fat by ~50%. Breast is leanest; thigh has more flavour but more fat. Bake, grill, or poach — avoid deep frying.
            **Portion:** A serving is about 150g (palm-sized piece).
            """)
        }

        if t.contains("salmon") {
            return FoodInfo(name: "Salmon", emoji: "🐟", details: """
            **Nutritional profile (per 100g baked):**
            • Calories: 208 kcal | Protein: 20g | Fat: 13g | Omega-3: ~2g

            **Health benefits:**
            • **Richest source of omega-3** fatty acids (EPA & DHA) — reduces inflammation, protects heart
            • May lower risk of heart attack by 25–30% (eating 2 portions/week)
            • Excellent for **brain health** — DHA makes up 40% of brain fatty acids
            • Rich in **vitamin D** (one of few food sources)
            • Good source of **selenium, B12, B6**
            • May improve insulin sensitivity and reduce inflammation markers

            **NHS recommends:** At least 2 portions of fish per week, 1 of which should be oily (salmon, mackerel, sardines).
            """)
        }

        if t.contains("oat") {
            return FoodInfo(name: "Oats / Porridge", emoji: "🥣", details: """
            **Nutritional profile (per 40g dry oats):**
            • Calories: 152 kcal | Protein: 5.3g | Carbs: 27g | Fibre: 4g | Fat: 2.6g

            **Health benefits:**
            • Rich in **beta-glucan** fibre — proven to lower cholesterol by 5–10%
            • **Low GI (55)** — slow, steady energy release, great for blood sugar
            • High in **manganese, phosphorus, magnesium, iron**
            • Keeps you full for hours — excellent for weight management
            • **Heart-protective** — EFSA-approved health claim for cholesterol reduction

            **Best toppings:** berries, cinnamon, chia seeds, nuts, banana.
            **Avoid:** instant oats with added sugar. Choose plain rolled or steel-cut oats.
            """)
        }

        return nil
    }

    // ── WEIGHT / BMI ──────────────────────────────────────────────────────────
    private func weightReply(name: String) -> ChatMessage {
        let h   = store.userProfile.height / 100
        let w   = store.userProfile.weight
        let bmi = h > 0 ? w / (h * h) : 0

        var reply = "⚖️ **Weight & BMI for \(name)**\n\n"
        if bmi > 0 {
            let cat = bmi < 18.5 ? "Underweight" : bmi < 25 ? "Healthy weight" : bmi < 30 ? "Overweight" : bmi < 35 ? "Obese (Class 1)" : "Obese (Class 2+)"
            reply += "• Weight: **\(Int(w)) kg** | Height: **\(Int(store.userProfile.height)) cm**\n"
            reply += "• BMI: **\(String(format: "%.1f", bmi))** — \(cat)\n\n"
        }

        reply += "**BMI ranges (for most adults):**\n• Below 18.5 = Underweight\n• 18.5–24.9 = Healthy\n• 25–29.9 = Overweight\n• 30+ = Obese\n\n"
        reply += "_Note: BMI is a screening tool, not a diagnosis. Muscle mass, ethnicity, and age affect interpretation._\n\n"
        reply += "**Losing just 5–10% of body weight:**\n"
        reply += "• Lowers blood glucose by 15–20%\n"
        reply += "• Reduces BP by 5–10 mmHg\n"
        reply += "• Improves cholesterol\n"
        reply += "• Reduces joint pain\n"
        reply += "• Improves sleep apnoea\n\n"
        reply += "**Practical steps:**\n"
        reply += "• Eat 3 structured meals — don't skip breakfast\n"
        reply += "• Swap white carbs for whole-grain alternatives\n"
        reply += "• Use a smaller plate — easy way to reduce portions\n"
        reply += "• Walk 30 min after lunch AND dinner\n"
        reply += "• Drink water before meals (reduces appetite by ~13%)\n"
        reply += "• No snacking after 8 PM\n"
        reply += "• Track food for 1 week — awareness alone creates change\n"
        reply += "• Aim to lose 0.5–1 kg per week (safe, sustainable rate)"

        return msg(reply, chips: ["🍽️ Meal plan", "🏃 Exercise plan", "💧 Hydration tips", "📋 Health summary"])
    }

    // ── EXERCISE ───────────────────────────────────────────────────────────────
    private func exerciseReply(name: String) -> ChatMessage {
        let g = store.latestGlucose?.value ?? 110
        var reply = "🏃 **Exercise Guide for \(name)**\n\n"

        if g < 80 {
            reply += "⚠️ Your glucose is low right now. Have a 15g carb snack (e.g. banana, juice) before you start. Re-check glucose after exercise.\n\n"
        } else if g > 250 {
            reply += "⚠️ Your glucose is very high. Wait until it comes down before vigorous exercise. Light walking (15–20 min) is safe and will actually help lower it.\n\n"
        }

        reply += "**Current guidelines (NHS / WHO):**\n"
        reply += "• **150 min moderate** OR **75 min vigorous** aerobic activity per week\n"
        reply += "• Strength/resistance training **2 days per week**\n"
        reply += "• Reduce sitting time — stand/move every 30 min\n\n"

        reply += "**Best exercises for metabolic health:**\n"
        reply += "🚶 **Walking** — post-meal (15–30 min) drops glucose by 20–40 mg/dL\n"
        reply += "🏊 **Swimming** — great for joints, heart, BP, and glucose\n"
        reply += "🚴 **Cycling** — low impact, builds endurance\n"
        reply += "💪 **Resistance training** — builds muscle, improves insulin sensitivity for 24–48 hours\n"
        reply += "🧘 **Yoga/Tai chi** — reduces stress hormones (cortisol), lowers BP\n\n"

        reply += "**For beginners — start here:**\n"
        reply += "Week 1–2: 10 min walk after meals × 3 per day\n"
        reply += "Week 3–4: 20 min continuous walk × 5 days\n"
        reply += "Week 5+: Add cycling or swimming 2× week\n\n"

        reply += "**Safety for diabetics:**\n"
        reply += "• Always carry glucose tablets or a small juice\n"
        reply += "• Check glucose before, during (if 60+ min), and after\n"
        reply += "• Type 1: coordinate exercise with insulin timing\n"
        reply += "• Stay hydrated — drink water every 20 min during exercise\n"
        reply += "• Wear proper footwear — check feet before and after"

        return msg(reply, chips: ["🩸 Check glucose now", "🍎 Pre-workout snack", "💧 Hydration guide", "📋 Summary"])
    }

    // ── SLEEP ─────────────────────────────────────────────────────────────────
    private func sleepReply(name: String) -> ChatMessage {
        let lastSleep = store.lastSleep

        var reply = "😴 **Sleep Health for \(name)**\n\n"

        if let s = lastSleep {
            let hrs = String(format: "%.1f", s.duration)
            reply += "Last recorded sleep: **\(hrs) hours** (\(s.quality.rawValue))\n\n"
        }

        reply += "**Why sleep matters for your health:**\n"
        reply += "• Poor sleep raises cortisol → directly raises blood glucose and BP\n"
        reply += "• Less than 6 hours → insulin resistance increases by 30–40%\n"
        reply += "• Sleep deprivation raises appetite hormones (ghrelin) → weight gain\n"
        reply += "• Deep sleep is when your heart rate and BP drop to recover\n\n"

        reply += "**Adults need 7–9 hours per night**\n\n"

        reply += "**Evidence-based tips to improve sleep:**\n"
        reply += "• Same bedtime and wake time every day (even weekends)\n"
        reply += "• No screens (phone/TV) for 1 hour before bed — blue light delays melatonin\n"
        reply += "• Keep room cool: 18–20°C is optimal\n"
        reply += "• Avoid caffeine after 2 PM (half-life is 5–7 hours)\n"
        reply += "• No alcohol as a sleep aid — it fragments deep sleep\n"
        reply += "• Check glucose before bed — keep it 100–140 mg/dL to avoid hypos or highs waking you\n"
        reply += "• 4-7-8 breathing technique: inhale 4s, hold 7s, exhale 8s\n\n"

        reply += "**When to see a doctor:**\n"
        reply += "• If you snore loudly or are told you stop breathing — this is sleep apnoea (treat it: raises BP, glucose, and heart risk)\n"
        reply += "• If you've tried sleep hygiene for 4 weeks with no improvement\n"
        reply += "• If fatigue is severely affecting daily life"

        return msg(reply, chips: ["🩸 Bedtime glucose check", "🧘 Relaxation techniques", "💊 Medications & sleep", "📋 Summary"])
    }

    // ── MENTAL HEALTH ─────────────────────────────────────────────────────────
    private func mentalHealthReply(name: String, text: String) -> ChatMessage {
        if text.contains("suicid") || text.contains("self harm") || text.contains("kill myself") || text.contains("end my life") {
            return msg("""
            💙 I'm really glad you reached out.

            If you're having thoughts of ending your life or harming yourself, please talk to someone right now:

            🆘 **Samaritans (UK):** Call or text 116 123 (free, 24/7)
            🆘 **Crisis Text Line:** Text HELLO to 85258
            🆘 **Emergency:** Call 999 or go to your nearest A&E

            You don't have to face this alone. These feelings can be treated and do get better with the right support. Your life has value. 💙
            """, chips: ["📞 Find local support", "🧘 Breathing techniques", "💊 Mental health treatment"])
        }

        var reply = "🧠 **Mental Health for \(name)**\n\n"

        if text.contains("depress") {
            reply += "**Depression:**\n"
            reply += "Depression is a real medical condition — not weakness or laziness. It changes brain chemistry.\n\n"
            reply += "• **Symptoms:** persistent low mood, loss of interest, fatigue, poor sleep, difficulty concentrating, worthlessness, appetite changes (2+ weeks)\n"
            reply += "• **Physical link:** diabetes doubles the risk of depression; depression worsens glucose control — they affect each other\n"
            reply += "• **Treatment:** CBT (talking therapy), antidepressants (SSRIs like sertraline, fluoxetine), exercise (as effective as mild antidepressants)\n"
            reply += "• **Self-help:** routine, exercise, sunlight, social connection, limiting alcohol\n\n"
        }

        if text.contains("anxi") || text.contains("worri") || text.contains("panic") {
            reply += "**Anxiety:**\n"
            reply += "Anxiety triggers your 'fight or flight' response — adrenaline releases, heart rate and glucose rise.\n\n"
            reply += "• **Box breathing:** Inhale 4s → Hold 4s → Exhale 4s → Hold 4s. Repeat 4 times\n"
            reply += "• **5-4-3-2-1 grounding:** Name 5 things you see, 4 you hear, 3 you can touch, 2 you smell, 1 you taste\n"
            reply += "• **Medication:** SSRIs, SNRIs, short-term benzodiazepines (only for acute use)\n\n"
        }

        reply += "**Stress management:**\n"
        reply += "• Exercise is the single most effective stress reducer available — releases endorphins, lowers cortisol\n"
        reply += "• Journaling: write thoughts down — gets them out of the 'mental loop'\n"
        reply += "• Mindfulness (10 min/day): reduces anxiety and depression measurably\n"
        reply += "• Sleep — see sleep section — restorative sleep resets the stress response\n"
        reply += "• Reduce caffeine and alcohol — both worsen anxiety\n"
        reply += "• Social connection — isolation worsens mental health\n\n"
        reply += "**When to seek help:** If symptoms affect your daily life for 2+ weeks, see your GP. Talking therapy (CBT) works. You don't have to suffer alone."

        return msg(reply, chips: ["😴 Sleep tips", "🏃 Exercise for mood", "🧘 Breathing techniques", "📋 Summary"])
    }

    // ── MEDICATIONS ───────────────────────────────────────────────────────────
    private func medicationReply(name: String, text: String) -> ChatMessage {
        let meds = store.medications.filter { $0.isActive }

        // Specific medication lookups
        let drugInfo: [(keywords: [String], info: String)] = [
            (["metformin"], "**Metformin:** First-line diabetes medication. Lowers glucose production in the liver. Take with food (reduces stomach upset). Do NOT take before CT scan with contrast dye. Common side effects: nausea, diarrhoea (usually improves). Rare but serious: lactic acidosis (if kidneys impaired)."),
            (["insulin"], "**Insulin:** Lowers blood glucose directly. Types: rapid-acting (NovoRapid, Humalog) taken before meals; long-acting (Lantus, Levemir, Tresiba) taken once/twice daily as basal. Store open insulin at room temp. Dispose of needles safely. Always carry fast carbs in case of hypo."),
            (["amlodipine"], "**Amlodipine:** Calcium channel blocker for high blood pressure and angina. Take at any time — same time daily. Common side effect: ankle swelling (normal), facial flushing. Tell doctor if you have severe leg swelling."),
            (["losartan", "candesartan", "valsartan"], "**ARBs (losartan, candesartan, valsartan):** Lower BP and protect kidneys in diabetes. Take at same time daily. Avoid if pregnant (can harm baby). May raise potassium — avoid potassium supplements. Side effect: dizziness — rise slowly from sitting."),
            (["ramipril", "lisinopril", "perindopril"], "**ACE inhibitors (ramipril, lisinopril):** Lower BP and protect heart and kidneys. Common side effect: dry cough (affects ~15% — if intolerable, switch to ARB). Avoid if pregnant. First dose can cause dizziness."),
            (["atorvastatin", "rosuvastatin", "simvastatin", "statin"], "**Statins:** Reduce 'bad' LDL cholesterol and heart attack risk by 25–35%. Take atorvastatin/simvastatin at night. Rosuvastatin any time. Side effect: muscle aching — usually mild, but report severe pain. Do NOT stop without doctor's advice. Avoid grapefruit juice with some statins."),
            (["aspirin"], "**Aspirin (low dose 75mg):** Thins blood to prevent heart attacks and strokes. Take with food. Do NOT take if you have a stomach ulcer. Avoid if under 16 unless prescribed. Interacts with ibuprofen (reduces effectiveness)."),
            (["warfarin"], "**Warfarin:** Blood thinner (anticoagulant). Requires regular INR blood tests to ensure it's in safe range. Many drug and food interactions — keep consistent vitamin K intake (leafy greens). Any unusual bleeding → contact doctor. Carry a warfarin alert card."),
            (["omeprazole", "lansoprazole"], "**PPIs (omeprazole, lansoprazole):** Reduce stomach acid for reflux/ulcers. Take 30 min before meals. Long-term use may reduce magnesium and B12 — supplements may be needed. Don't take indefinitely without doctor review."),
            (["salbutamol", "ventolin"], "**Salbutamol/Ventolin (blue inhaler):** Quick-relief bronchodilator for asthma. Use when needed for breathlessness/wheeze. If using more than 3× per week, asthma is poorly controlled — see your doctor for a preventer inhaler. Spacer improves delivery."),
            (["paracetamol"], "**Paracetamol:** Safe painkiller/fever reducer when used correctly. Max 4g (8 × 500mg tablets) per 24 hours for adults. Do NOT exceed — liver damage is possible. Safe in pregnancy. Can be taken with ibuprofen for better pain relief."),
            (["ibuprofen", "naproxen"], "**NSAIDs (ibuprofen, naproxen):** Reduce pain, fever, and inflammation. Take with food (protects stomach). Avoid long-term if you have kidney disease, heart failure, or stomach ulcers. May raise BP and worsen asthma in some people.")
        ]

        for drug in drugInfo {
            if drug.keywords.contains(where: { text.contains($0) }) {
                var reply = "💊 " + drug.info + "\n\n"
                if !meds.isEmpty {
                    reply += "**Your active medications:**\n"
                    for med in meds.prefix(5) {
                        reply += "• \(med.name) \(med.dosage)\(med.unit) — \(med.frequency.rawValue)\n"
                    }
                }
                return msg(reply, chips: ["⏰ Missed a dose?", "⚠️ Side effects", "🍽️ Take with food?", "💊 All my meds"])
            }
        }

        // Dynamic database lookup — find any medicine mentioned in user text
        let searchResults = MedicineDatabase.shared.search(text)
        if let dbMed = searchResults.first {
            var reply = "💊 **\(dbMed.genericName)** (\(dbMed.therapeuticClass))\n\n"
            reply += "\(dbMed.description)\n\n"
            if !dbMed.brandNames.isEmpty {
                reply += "**Brand names:** \(dbMed.brandNames.joined(separator: ", "))\n\n"
            }
            reply += "**Typical dosages:** \(dbMed.typicalDosages.joined(separator: ", "))\n"
            reply += "**Form:** \(dbMed.forms.map { $0.rawValue }.joined(separator: ", "))\n"
            reply += "**OTC:** \(dbMed.isOTC ? "Yes" : "Prescription only")\n\n"
            if !dbMed.warnings.isEmpty {
                reply += "⚠️ **Warnings:**\n"
                for w in dbMed.warnings { reply += "• \(w)\n" }
                reply += "\n"
            }
            if !dbMed.sideEffects.isEmpty {
                reply += "**Common side effects:** \(dbMed.sideEffects.prefix(5).joined(separator: ", "))\n\n"
            }
            if !dbMed.foodInteractions.isEmpty {
                reply += "🍽️ **Food interactions:**\n"
                for f in dbMed.foodInteractions { reply += "• \(f)\n" }
                reply += "\n"
            }
            if !dbMed.interactions.isEmpty {
                reply += "⚠️ **Drug interactions:** \(dbMed.interactions.prefix(3).joined(separator: "; "))\n\n"
            }
            if !meds.isEmpty {
                reply += "**Your active medications:**\n"
                for med in meds.prefix(5) {
                    reply += "• \(med.name) \(med.dosage)\(med.unit) — \(med.frequency.rawValue)\n"
                }
            }
            return msg(reply, chips: ["⏰ Missed a dose?", "⚠️ Side effects", "🍽️ Take with food?", "💊 All my meds"])
        }

        // General medication reply
        guard !meds.isEmpty else {
            return msg("No medications added yet, \(name). Go to **Track → Meds** to add your prescriptions.", chips: ["📋 Summary"])
        }

        var reply = "💊 **Your Medications, \(name)**\n\n"
        for med in meds {
            let times = med.timeOfDay.map { $0.rawValue }.joined(separator: ", ")
            reply += "• **\(med.name)** \(med.dosage) \(med.unit) — \(med.frequency.rawValue) at \(times)\n"
            // Add database-enriched info per medication
            if let entry = med.databaseEntry {
                reply += "  _\(entry.therapeuticClass)_"
                if !entry.warnings.isEmpty {
                    reply += " · ⚠️ \(entry.warnings.first!)"
                }
                reply += "\n"
            }
        }

        // Drug interaction cross-check
        if meds.count >= 2 {
            let medNames = meds.compactMap { $0.genericName ?? $0.name }
            var interactions: [String] = []
            for i in 0..<medNames.count {
                for j in (i+1)..<medNames.count {
                    interactions.append(contentsOf: MedicineDatabase.shared.interactionsBetween(medNames[i], medNames[j]))
                }
            }
            if !interactions.isEmpty {
                reply += "\n🚨 **Drug Interaction Alerts:**\n"
                for note in interactions.prefix(5) {
                    reply += "• ⚠️ \(note)\n"
                }
            }
        }

        reply += "\n**Universal medication rules:**\n"
        reply += "• Take at the same time every day — builds habit and keeps levels stable\n"
        reply += "• Never halve or crush tablets without checking — some are slow-release\n"
        reply += "• If you miss a dose: take it as soon as you remember, UNLESS it's almost time for the next — then skip (don't double up)\n"
        reply += "• Store most tablets at room temperature, away from moisture\n"
        reply += "• Never stop medications without talking to your doctor first\n"
        reply += "• Tell every doctor you see ALL the medications you take (including herbal supplements)\n"
        reply += "• Ask your pharmacist — they are medication experts and available without appointment"

        return msg(reply, chips: ["⏰ Missed a dose?", "🔍 Explain my med", "⚠️ Side effects?", "📋 Summary"])
    }

    // ── WATER / HYDRATION ─────────────────────────────────────────────────────
    private func waterReply(name: String) -> ChatMessage {
        let goal = Int(store.userProfile.weight * 0.033)
        let today = Int(store.todayWaterML)
        return msg("""
        💧 **Hydration for \(name)**

        Based on your weight, aim for **\(goal)–\(goal + 1) litres per day**.
        Today so far: **\(today) ml** (\(Int(Double(today) / Double(goal * 1000) * 100))% of goal)

        **Why hydration matters:**
        • Dehydration concentrates glucose in the blood — raises readings
        • High glucose causes kidneys to flush water — drink more when glucose is high
        • Dehydration raises BP by making blood thicker
        • Even 2% dehydration reduces cognitive performance and mood

        **Best drinks:**
        ✅ Water (still or sparkling), herbal teas, diluted squash (no added sugar)
        ❌ Avoid: sugary drinks, fruit juice, energy drinks, excessive alcohol

        **Tips to hit your target:**
        • Keep a 1L bottle on your desk — refill twice
        • Drink a full glass on waking up (you've been 6–8 hours without water)
        • Drink a glass before each meal — also reduces appetite
        • Set hourly phone reminders
        • Add lemon, cucumber, or mint for flavour
        • Drink before you feel thirsty — thirst means you're already mildly dehydrated
        """, chips: ["🩸 Check glucose", "🍽️ What to eat", "📋 Summary"])
    }

    // ── WOMEN'S HEALTH ────────────────────────────────────────────────────────
    private func womensHealthReply(name: String, text: String) -> ChatMessage {
        if text.contains("pregnant") || text.contains("pregnancy") {
            return msg("""
            🤰 **Pregnancy Health for \(name)**

            **If you have diabetes and are pregnant (or planning to be):**
            • Aim for HbA1c below 6.5% before conceiving
            • Fasting glucose target: 3.5–5.9 mmol/L; 1-hr post-meal: below 7.8
            • Take **5mg folic acid** daily (higher dose for diabetes) from before conception until 12 weeks
            • Metformin is often continued; insulin adjustments are common
            • Regular growth scans — babies of diabetic mothers may grow larger
            • Watch for gestational diabetes if not previously diagnosed

            **Gestational diabetes (GDM):**
            • Occurs in 2–5% of pregnancies
            • Often managed by diet alone (low-GI carbs, regular meals)
            • If diet insufficient: metformin or insulin
            • Usually resolves after birth — but 50% risk of Type 2 diabetes within 10 years — annual glucose check recommended

            **General pregnancy advice:**
            • Take folic acid (400mcg) before conception – 12 weeks (prevents neural tube defects)
            • Vitamin D 10 mcg/day throughout
            • Avoid: alcohol, smoking, raw meat/fish, unpasteurised cheese, liver
            • Register with midwife before 10 weeks
            """, chips: ["🩸 Glucose in pregnancy", "💊 Safe meds in pregnancy", "🍽️ Pregnancy diet", "📋 Summary"])
        }

        if text.contains("menopause") || text.contains("perimenopause") {
            return msg("""
            🌸 **Menopause Health for \(name)**

            **What is it?** Menopause is when periods permanently stop (12 months without a period). Average age in UK: 51. Perimenopause (the years before) can start from mid-40s.

            **Common symptoms:**
            • Hot flushes and night sweats
            • Mood changes, anxiety, brain fog
            • Sleep problems
            • Vaginal dryness
            • Reduced sex drive
            • Joint aches
            • Weight gain (especially around the middle)

            **Impact on diabetes & metabolic health:**
            • Oestrogen protects insulin sensitivity — its decline increases glucose and BP
            • More abdominal fat → increased insulin resistance
            • Bone density decreases — risk of osteoporosis rises

            **HRT (Hormone Replacement Therapy):**
            • Modern HRT is safe for most women — benefits often outweigh risks
            • Reduces hot flushes, protects bones, improves mood and sleep
            • Transdermal HRT (patch/gel) has lower blood clot risk than tablets
            • Discuss with your GP — NICE guidelines now recommend offering HRT

            **Lifestyle:** Regular weight-bearing exercise (protect bones), strength training, calcium-rich diet, vitamin D supplement, adequate sleep.
            """, chips: ["⚖️ Weight at menopause", "🦴 Bone health", "💊 HRT explained", "📋 Summary"])
        }

        var reply = "🌸 **Women's Health & Hormones for \(name)**\n\n"
        reply += "**Menstrual cycle and blood glucose:**\n"
        reply += "Hormone changes throughout your cycle affect insulin sensitivity:\n\n"
        reply += "**Week 1–2 (Follicular phase):** Oestrogen rises → better insulin sensitivity → glucose tends to run lower ✅\n"
        reply += "**Week 3–4 (Luteal phase):** Progesterone rises → insulin resistance increases → glucose tends to run higher ⚠️\n\n"
        reply += "**During period:** Pain and inflammation can spike glucose. Stay hydrated. Keep carbs consistent.\n\n"
        reply += "**Tracking tip:** Note where you are in your cycle when glucose is unusually high or low. Patterns often emerge — share them with your doctor.\n\n"
        reply += "**Iron:** Heavy periods can cause iron-deficiency anaemia. Eat iron-rich foods: lean red meat, spinach, lentils, fortified cereals. Vitamin C helps absorption.\n\n"
        reply += "**PCOS:** Polycystic ovary syndrome affects 10% of women. Strongly linked to insulin resistance. Metformin can help. Low-GI diet and exercise are key.\n\n"
        reply += "**Cervical screening:** Smear test every 3 years (25–49) or every 5 years (50–64). Don't skip — it prevents cervical cancer.\n"
        reply += "**Breast screening:** Mammogram every 3 years (50–71) via NHS Breast Screening Programme."

        return msg(reply, chips: ["📅 Meal plan", "🏃 Exercise for hormones", "💊 My medications", "📋 Summary"])
    }

    // ── GUT / DIGESTION ───────────────────────────────────────────────────────
    private func gutReply(name: String, text: String) -> ChatMessage {
        return msg("""
        🫀 **Digestive Health for \(name)**

        **Common conditions explained:**

        **IBS (Irritable Bowel Syndrome):**
        • Causes: abdominal pain, bloating, constipation and/or diarrhoea
        • Not dangerous — but affects quality of life
        • Triggers: stress, certain foods (use FODMAP diet to identify), caffeine, alcohol
        • Treatment: low-FODMAP diet, probiotics, peppermint oil, stress management, NICE-approved medications

        **Acid Reflux / GERD:**
        • Stomach acid rises into the oesophagus — causes heartburn, regurgitation
        • Triggers: large meals, lying down after eating, spicy/fatty food, alcohol, smoking, obesity
        • Treatment: raise head of bed, avoid triggers, omeprazole/lansoprazole (PPIs), losing weight

        **Constipation:**
        • Fewer than 3 bowel movements per week, or straining
        • Fix: increase fibre (25–30g/day: vegetables, fruit, whole grains, flaxseed), drink more water, exercise more, establish a toilet routine
        • Short-term: lactulose, senna, or Movicol
        • Note: metformin and iron supplements can affect gut function

        **Diarrhoea:**
        • Acute (< 2 weeks): usually viral/bacterial — rest, oral rehydration salts, BRAT diet (banana, rice, applesauce, toast)
        • Chronic: see your GP (could be IBS, coeliac disease, Crohn's, or medications)

        **When to see a doctor URGENTLY:**
        • Blood in stools (red or black/tarry)
        • Unexplained weight loss
        • Change in bowel habits lasting 3+ weeks (especially in over-40s)
        • Persistent abdominal pain
        • Difficulty swallowing
        """, chips: ["🍽️ IBS-friendly foods", "💧 Hydration for digestion", "💊 Gut medications", "📋 Summary"])
    }

    // ── RESPIRATORY ───────────────────────────────────────────────────────────
    private func respiratoryReply(name: String, text: String) -> ChatMessage {
        return msg("""
        🫁 **Respiratory Health for \(name)**

        **Asthma:**
        • Airways become inflamed and narrow → wheezing, breathlessness, chest tightness, cough
        • **Blue inhaler (reliever - salbutamol/Ventolin):** Use when symptoms occur. Opens airways fast.
        • **Brown/purple inhaler (preventer - ICS):** Use every day even when feeling well. Reduces inflammation.
        • Triggers: dust, pet dander, pollen, cold air, smoke, exercise, stress
        • If using reliever inhaler >3×/week — see your GP: asthma is undertreated
        • Spacer device improves delivery to lungs significantly

        **COPD (Chronic Obstructive Pulmonary Disease):**
        • Usually caused by smoking. Main symptom: progressive breathlessness.
        • Cannot be cured — but managed with inhalers, pulmonary rehab, and stopping smoking
        • Annual flu vaccine and pneumococcal vaccine recommended

        **COVID and respiratory infections:**
        • Most resolve with rest, fluids, and paracetamol
        • Seek care if: SpO2 drops below 94%, persistent fever >5 days, confusion, unable to stand

        **SpO2 (blood oxygen):**
        • Normal: 95–100%
        • 94% or below: seek medical advice
        • 90% or below: medical emergency — oxygen needed

        **Smoking cessation:**
        Within 20 minutes of quitting, your BP drops. Within 8 hours, oxygen levels normalise. Within 1 year, heart disease risk halves. Combinations of NRT + varenicline (Champix) are most effective. NHS Stop Smoking Service has high success rates.
        """, chips: ["🩸 SpO2 monitoring", "💊 Inhaler explained", "🏃 Breathing exercises", "📋 Summary"])
    }

    // ── SKIN ─────────────────────────────────────────────────────────────────
    private func skinReply(name: String, text: String) -> ChatMessage {
        return msg("""
        🧴 **Skin Health for \(name)**

        **Diabetes and skin:**
        High glucose makes you more prone to infections, slow wound healing, and specific skin conditions (acanthosis nigricans = darkening in skin folds; diabetic dermopathy = brown patches on shins).

        **Common skin conditions:**

        **Eczema (Atopic Dermatitis):** Itchy, dry, inflamed skin. Avoid harsh soaps, use fragrance-free emollient (moisturiser) generously. Steroid creams for flares. Triggers: certain foods, stress, heat.

        **Psoriasis:** Raised red/silvery scaly patches. Triggered by stress, infections, alcohol. Treatment: emollients, topical steroids, vitamin D analogues, light therapy (phototherapy), biologics for severe cases.

        **Acne:** Blocked pores + bacteria. Treatment ladder: benzoyl peroxide (OTC) → topical antibiotics → oral antibiotics → isotretinoin (only via dermatologist).

        **Wound care (especially for diabetics):**
        • Clean gently with clean water, cover with a sterile dressing
        • Check daily — any redness spreading, increasing warmth, discharge, or not healing in 5–7 days = see your GP (risk of infection/cellulitis)
        • Foot wounds especially: never ignore. Diabetic foot ulcers can worsen rapidly.

        **Skin cancer awareness — check your moles monthly:**
        Use ABCDE rule:
        A = Asymmetry | B = Border (irregular) | C = Colour (uneven) | D = Diameter (>6mm) | E = Evolving (changing)
        Any mole that changes → see a GP promptly.
        """, chips: ["🦶 Foot care for diabetics", "🏥 When to see a doctor", "💊 Skin medications", "📋 Summary"])
    }

    // ── MUSCULOSKELETAL ───────────────────────────────────────────────────────
    private func musculoskeletalReply(name: String, text: String) -> ChatMessage {
        return msg("""
        🦴 **Joint & Muscle Health for \(name)**

        **Osteoarthritis (most common joint condition):**
        • Wear and tear of cartilage — knees, hips, and hands most affected
        • Symptoms: pain and stiffness that worsens with activity, improves with rest
        • Treatment: exercise (strengthens supporting muscles), weight loss (1kg lost = 4kg less pressure on knees), paracetamol, NSAIDs (short-term), physiotherapy, steroid injections, joint replacement (last resort)

        **Rheumatoid Arthritis (autoimmune):**
        • Immune system attacks joints — causes symmetrical joint pain/swelling, morning stiffness >1 hour
        • Treatment: disease-modifying drugs (methotrexate, hydroxychloroquine) + biologics. Start early to prevent damage.

        **Gout:**
        • Uric acid crystals in joints — causes sudden, severe pain (especially big toe)
        • Triggered by: red meat, shellfish, alcohol (especially beer), sugary drinks
        • Treatment: colchicine or NSAIDs for attacks; allopurinol (daily) to prevent recurrence
        • Drink plenty of water. Lose weight. Reduce purine-rich foods.

        **Back pain:**
        • 80% of people have back pain at some point — most resolves within 6 weeks
        • Stay active (bed rest makes it worse). Walking, swimming, and yoga help.
        • Heat pack for muscle pain, ice for acute injury
        • Red flags → see doctor urgently: numbness in groin/inner thigh, loss of bladder/bowel control, pain waking you at night, unexplained weight loss

        **Osteoporosis (thin bones):**
        • Especially risk for post-menopausal women, long-term steroid users
        • Prevention: calcium (dairy, sardines, kale) + vitamin D (supplement 10 mcg/day), weight-bearing exercise, don't smoke, limit alcohol
        """, chips: ["🏃 Exercise for joints", "💊 Pain relief options", "⚖️ Weight and joints", "📋 Summary"])
    }

    // ── NEUROLOGICAL ─────────────────────────────────────────────────────────
    private func neurologicalReply(name: String, text: String) -> ChatMessage {
        if text.contains("headache") || text.contains("migraine") {
            return msg("""
            🧠 **Headaches & Migraines for \(name)**

            **Tension headache (most common):**
            • Dull, squeezing pressure around the head
            • Causes: stress, poor posture, eye strain, dehydration, poor sleep
            • Treatment: paracetamol, ibuprofen, rest, hydration, neck stretches

            **Migraine:**
            • Throbbing, usually one-sided, with nausea, light/sound sensitivity. May have aura (visual disturbances, tingling) before.
            • Triggers: stress, hormonal changes, certain foods (wine, aged cheese, chocolate), bright lights, dehydration, sleep disruption
            • Acute treatment: triptans (sumatriptan) are most effective. Take early.
            • Prevention (if >3/month): propranolol, amitriptyline, topiramate, CGRP inhibitors

            **Diabetes and headaches:**
            High or low glucose commonly cause headaches. Always check your glucose when you get a headache.

            **When to go to A&E immediately:**
            • "Thunderclap" headache — sudden, worst headache of your life (subarachnoid haemorrhage)
            • Headache with stiff neck, fever, rash → meningitis
            • Headache after head injury
            • Headache with vision loss, weakness, or speech problems → stroke
            """, chips: ["🩸 Check glucose", "💊 Headache medications", "😴 Sleep and headaches", "📋 Summary"])
        }

        return msg("""
        🧠 **Neurological Health for \(name)**

        **Diabetic neuropathy (nerve damage from high glucose):**
        • Affects ~50% of people with diabetes over time
        • Symptoms: tingling, burning, or numbness in feet and hands (starts in feet); sharp pains; loss of sensation
        • Prevention: keep glucose controlled (most important), don't smoke, B12 sufficient
        • Treatment: painkillers (gabapentin, amitriptyline, duloxetine), good glucose control slows progression

        **Dizziness / vertigo:**
        • Benign positional vertigo (BPPV): Room spins when you move head — Epley manoeuvre often cures it
        • Low BP: Dizziness on standing = postural hypotension (common with BP medications, dehydration, or high glucose)
        • Check BP and glucose when dizzy

        **Memory and dementia:**
        • Diabetes doubles the risk of Alzheimer's disease
        • Keeping glucose, BP, and cholesterol controlled protects the brain
        • Exercise and mental stimulation are protective
        • If concerned about memory changes in yourself or a relative, see the GP for assessment

        **Peripheral neuropathy (non-diabetic causes):**
        B12 deficiency, alcohol excess, thyroid problems, kidney disease — all treatable causes
        """, chips: ["🦶 Foot care & neuropathy", "🩸 Glucose & brain health", "💊 Neuropathy treatments", "📋 Summary"])
    }

    // ── EYES ─────────────────────────────────────────────────────────────────
    private func eyeReply(name: String) -> ChatMessage {
        return msg("""
        👁️ **Eye Health for \(name)**

        **Diabetic retinopathy (most important for you):**
        • High blood glucose damages the tiny blood vessels in your retina
        • Can cause: blurry vision, floaters, dark spots, vision loss (if untreated)
        • **Early stages have no symptoms** — that's why annual eye screening is essential
        • Treatment: laser therapy, injections (anti-VEGF), vitrectomy surgery
        • Prevention: keep glucose and BP well-controlled — this is the most effective intervention

        **Get a retinal screening (dilated eye exam) every year if you have diabetes.**

        **Other common eye conditions:**
        • **Cataracts** (cloudy lens): more common with diabetes. Fixed with 15-min surgery — very effective.
        • **Glaucoma** (raised eye pressure): painless, damages peripheral vision first. Check intraocular pressure at optician.
        • **Age-related macular degeneration (AMD)**: affects central vision. Stop smoking, eat leafy greens (lutein), wear UV sunglasses.
        • **Conjunctivitis**: bacterial (discharge, treated with antibiotic drops) or viral (watery, self-limiting)
        • **Dry eyes**: artificial tears, omega-3 supplements, reduce screen time

        **Go to A&E immediately for:**
        • Sudden vision loss in one or both eyes
        • Flashing lights + shower of new floaters (retinal detachment)
        • Painful red eye with vomiting (acute angle closure glaucoma)
        """, chips: ["🩸 Glucose & eye health", "🏥 Eye screening", "💊 Eye drop explained", "📋 Summary"])
    }

    // ── EARS ─────────────────────────────────────────────────────────────────
    private func earReply(name: String) -> ChatMessage {
        return msg("""
        👂 **Ear & Hearing Health for \(name)**

        **Tinnitus (ringing in the ears):**
        • Very common — affects ~15% of adults
        • Causes: noise exposure (most common), age-related, earwax, high BP, ototoxic medications (aspirin, gentamicin)
        • No cure for most cases, but management helps: sound therapy, CBT, avoid silence (background music), protect ears from loud noise
        • If sudden one-sided tinnitus with hearing loss → urgent ENT referral needed

        **Hearing loss:**
        • Gradual (sensorineural): most common with age — treated with hearing aids. Don't delay — social isolation from hearing loss worsens mental health and dementia risk.
        • Sudden: can be treated if caught early (within 72 hours) with steroids — see GP urgently

        **Ear infections:**
        • Outer ear (otitis externa — "swimmer's ear"): pain, discharge, itching. Antibiotic/steroid ear drops.
        • Middle ear (otitis media): common in children, causes ear pain and fever. Often viral — antibiotics only if severe/prolonged.

        **Earwax:**
        • Never put cotton buds in your ear canal (pushes wax deeper)
        • Use olive oil drops for 1–2 weeks to soften, then ear irrigation (nurse) if needed

        **Diabetes and ears:** High glucose can impair small blood vessels supplying the inner ear — another reason good glucose control protects you.
        """, chips: ["🩺 Ear care tips", "🏥 When to see a specialist", "📋 Summary"])
    }

    // ── DENTAL ───────────────────────────────────────────────────────────────
    private func dentalReply(name: String) -> ChatMessage {
        return msg("""
        🦷 **Dental & Oral Health for \(name)**

        **Diabetes and dental health:**
        High glucose raises risk of gum disease (gingivitis/periodontitis) significantly. Conversely, gum disease makes glucose control harder — it causes inflammation that raises glucose. Getting dental treatment can lower HbA1c.

        **Gum disease (most common preventable disease globally):**
        • Symptoms: bleeding gums (when brushing), red/swollen gums, bad breath, gum recession
        • Treatment: professional cleaning (scale and polish), improved home care, antibiotics if severe
        • Prevention: brush 2 min × 2/day, floss or interdental brush daily, regular dental checkups

        **Tooth decay (cavities):**
        • Caused by acid produced by bacteria from sugary foods
        • Prevention: limit sugar (especially between meals), fluoride toothpaste, dental checkups
        • Don't rinse mouth immediately after brushing — let fluoride sit on teeth

        **Dry mouth:**
        • Caused by diabetes, some medications (antihistamines, antidepressants), dehydration
        • Increases cavity risk — saliva protects teeth
        • Fix: drink water regularly, sugar-free chewing gum (stimulates saliva), alcohol-free mouthwash

        **Dental checklist:**
        • Dentist checkup every 6–12 months (more often if gum disease)
        • Brush with fluoride toothpaste twice daily
        • Floss once daily
        • Avoid smoking (biggest cause of severe gum disease)
        • If pregnant: oral health affects birth outcomes — see dentist
        """, chips: ["🩸 Glucose & dental health", "💊 Dental medications", "🏥 Finding an NHS dentist", "📋 Summary"])
    }

    // ── IMMUNE / INFECTIONS ──────────────────────────────────────────────────
    private func immuneReply(name: String, text: String) -> ChatMessage {
        return msg("""
        🛡️ **Immune System & Infections for \(name)**

        **Diabetes and infection risk:**
        High glucose impairs immune cell function — you're more susceptible to infections and they're often more severe. Infections also spike glucose — a cycle. Any infection → monitor glucose more frequently.

        **Cold vs Flu:**
        • Cold: gradual onset, runny nose, mild fever. Treat: rest, fluids, paracetamol
        • Flu: sudden severe onset, high fever, muscle aches, exhaustion. Treat: rest, fluids, paracetamol/ibuprofen, antivirals (oseltamivir/Tamiflu — most effective if started within 48 hours)
        • **Annual flu vaccine strongly recommended** for anyone with diabetes, heart disease, asthma, kidney disease, or age 65+

        **Fever:**
        • Adults: 38°C or above
        • Treat: paracetamol or ibuprofen, stay hydrated
        • Seek care: fever >39°C not responding to paracetamol, fever with stiff neck/rash, fever with confusion, fever in elderly or immunocompromised

        **When NOT to take antibiotics:**
        • Viral infections (colds, flu, most sore throats) — antibiotics do nothing
        • Taking unnecessary antibiotics contributes to antibiotic resistance
        • Finish the full course if prescribed

        **Vaccination schedule for adults with diabetes:**
        • Annual flu vaccine (free on NHS)
        • Pneumococcal vaccine (once — protects against pneumonia)
        • COVID-19 booster (as advised)
        • Shingles vaccine (at 70)

        **Boosting immunity naturally:**
        Sleep, regular exercise, balanced diet (especially zinc, vitamin C, vitamin D), stress management, not smoking, moderate alcohol only
        """, chips: ["🩸 Sick day rules for diabetes", "💊 When antibiotics help", "🏃 Exercise & immunity", "📋 Summary"])
    }

    // ── CANCER SCREENING ─────────────────────────────────────────────────────
    private func cancerReply(name: String, text: String) -> ChatMessage {
        return msg("""
        🔬 **Cancer Awareness & Screening for \(name)**

        **Key screening programmes in the UK (all free on NHS):**

        🩺 **Bowel cancer screening:** Every 2 years from age 50 (FIT test kit sent to home). Colonoscopy if positive.
        🩺 **Breast screening:** Every 3 years, age 50–71 (mammogram). 40s invited in some areas.
        🩺 **Cervical screening:** Every 3 years (25–49) or 5 years (50–64). Do not skip — it prevents 75% of cervical cancers.
        🩺 **Lung cancer screening (pilot):** Being rolled out for high-risk smokers aged 55–74.
        🩺 **Prostate (PSA test):** Not routinely screened — discuss with GP if concerned (especially over 50 or with family history).

        **Diabetes and cancer risk:**
        Type 2 diabetes is linked to increased risk of certain cancers (colon, liver, pancreas, bladder, endometrial). Keeping glucose and weight controlled reduces this risk.

        **Warning signs (see a GP promptly — most are NOT cancer, but must be checked):**
        • Unexplained weight loss
        • A lump you can feel
        • Unexplained bleeding (urine, stool, vomiting blood, post-menopausal bleeding)
        • Change in bowel/bladder habits lasting 3+ weeks
        • A sore that doesn't heal
        • Persistent hoarse voice or difficulty swallowing
        • New or changing mole

        **Reducing cancer risk:**
        • Don't smoke (causes 15 different cancers)
        • Maintain a healthy weight
        • Limit alcohol
        • Eat plenty of fruits, vegetables, and fibre
        • Exercise regularly
        • Use sunscreen (factor 50 for skin cancer prevention)
        • Attend all screening appointments
        """, chips: ["🏥 Cancer screening dates", "⚖️ Weight & cancer risk", "🩺 Check symptoms", "📋 Summary"])
    }

    // ── VITAMINS / SUPPLEMENTS ────────────────────────────────────────────────
    private func vitaminsReply(name: String, text: String) -> ChatMessage {
        return msg("""
        💊 **Vitamins & Supplements for \(name)**

        **Most important for people with diabetes:**

        **Vitamin D:** Most UK adults are deficient (especially Oct–Mar). Deficiency worsens insulin resistance, immune function, and bone strength. Take **10 mcg/day** (400 IU) — or 25 mcg if low. Get tested if unsure.

        **Vitamin B12:** Metformin reduces B12 absorption over time. Deficiency causes fatigue, numbness/tingling (mimics neuropathy), anaemia, depression. Check levels annually if on long-term metformin. Supplement 500–1000 mcg/day if low.

        **Magnesium:** Low magnesium is common in diabetes and worsens insulin resistance. Sources: dark chocolate, nuts, seeds, leafy greens, whole grains. Supplement 200–400 mg/day if levels are low.

        **Omega-3 (fish oil):** Reduces triglycerides, inflammation, and BP. Eat oily fish 2× week (salmon, mackerel, sardines), or supplement 1–2g EPA+DHA/day.

        **Iron:** Deficiency causes fatigue, poor concentration, anaemia. Most common in women with heavy periods. Supplement with iron + vitamin C (improves absorption). Check ferritin level first.

        **Folic acid:** Essential before/during pregnancy (400 mcg; 5 mg if diabetic). Also helps cell division.

        **Probiotics:** Live bacteria (Lactobacillus, Bifidobacterium) that may help IBS, gut microbiome, and immunity. Yoghurt, kefir, sauerkraut are natural sources.

        **What NOT to take without advice:**
        • High-dose vitamin A (toxic at excess levels)
        • High-dose B6 (nerve damage risk)
        • St John's Wort (interacts with many medications including contraceptives)
        • Iron (only if genuinely deficient — excess is harmful)
        """, chips: ["💊 My medications", "🍽️ Nutrition for health", "🩸 Glucose & supplements", "📋 Summary"])
    }

    // ── PEDIATRICS ───────────────────────────────────────────────────────────
    private func pediatricsReply(name: String, text: String) -> ChatMessage {
        return msg("""
        👶 **Children's Health for \(name)**

        **Childhood vaccinations (UK schedule — key milestones):**
        • 8 weeks: 6-in-1, MenB, rotavirus
        • 12 weeks: 6-in-1, PCV (pneumococcal)
        • 16 weeks: 6-in-1, MenB
        • 1 year: MMR, MenC+ACWY, PCV, MenB
        • 3–4 years: MMR booster, 4-in-1 pre-school booster
        • 12–13 years: HPV (girls and boys)
        • 14 years: 3-in-1 teenage booster, MenACWY

        **Fever in children:**
        • Babies under 3 months with fever >38°C: Go to A&E immediately
        • Children 3–6 months, fever >38°C: Contact GP
        • Children over 6 months: Treat with paracetamol (Calpol), keep hydrated
        • Worry about: rash that doesn't fade with glass test, very lethargic/unresponsive, stiff neck, bulging fontanelle (babies), difficulty breathing

        **Type 1 diabetes in children:**
        • Often presents with: excessive thirst, frequent urination, weight loss, tiredness, blurred vision, recurrent infections
        • Ketoacidosis (DKA) is the most dangerous presentation — fruity breath, vomiting, deep rapid breathing → emergency
        • Managed with insulin — children need more frequent monitoring, particularly around growth spurts and puberty

        **Growth and development:**
        • Height/weight tracked on growth charts (centile lines)
        • Normal variation is wide — consult health visitor if concerns about growth or development milestones
        """, chips: ["🩸 Type 1 diabetes in children", "💉 Vaccination schedule", "🤒 Fever management", "📋 Summary"])
    }

    // ── MEN'S HEALTH ─────────────────────────────────────────────────────────
    private func mensHealthReply(name: String) -> ChatMessage {
        return msg("""
        🧔 **Men's Health for \(name)**

        **Prostate health:**
        • BPH (benign prostatic hyperplasia): enlarged prostate — causes weak urine flow, frequent urination, especially at night. Very common over 50. Treatment: alpha-blockers (tamsulosin), 5-alpha reductase inhibitors, or surgery (TURP).
        • Prostate cancer: often no symptoms early. PSA blood test is available but not part of routine screening — discuss with GP if you have a family history or concerns.
        • See GP for: blood in urine, inability to urinate, unexplained weight loss, back/bone pain.

        **Testosterone:**
        • Naturally decreases by ~1% per year after 30
        • Low testosterone (hypogonadism): symptoms include fatigue, low mood, reduced libido, weight gain, reduced muscle, poor concentration
        • Diagnosis: morning blood test (testosterone levels vary by time of day)
        • Treatment: testosterone replacement therapy (only prescribed if confirmed deficiency)
        • Many symptoms overlap with depression, thyroid disease, sleep problems — rule these out first

        **Erectile dysfunction (ED):**
        • Very common — affects 50% of men over 50 at some point
        • Often a sign of cardiovascular disease (same vessel damage) — important to investigate
        • Diabetes, high BP, cholesterol, smoking, obesity, and anxiety are major causes
        • Treatment: PDE5 inhibitors (sildenafil/Viagra, tadalafil/Cialis), lifestyle changes, psychotherapy
        • Seek GP review if new ED — it may be the first sign of heart disease

        **Key health checks for men:**
        • BP check every 5 years (more often if elevated)
        • Cholesterol and glucose from age 40
        • BMI and waist measurement
        • Mental health — men are less likely to seek help but have higher suicide rates
        """, chips: ["❤️ Cardiovascular risk", "💊 Medications for men", "🏃 Exercise for men", "📋 Summary"])
    }

    // ── ALLERGIES ─────────────────────────────────────────────────────────────
    private func allergyReply(name: String) -> ChatMessage {
        return msg("""
        🌿 **Allergies for \(name)**

        **Hay fever (seasonal allergic rhinitis):**
        • Caused by pollen (tree: Mar–May, grass: May–Jul, weed: Jun–Sep)
        • Symptoms: runny/blocked nose, itchy eyes, sneezing
        • Treatment: non-drowsy antihistamines (cetirizine, loratadine), nasal steroid sprays (mometasone, fluticasone — very effective, start 2 weeks before season), antihistamine eye drops

        **Food allergies:**
        • True allergy: immune response — can cause anaphylaxis within minutes
        • Common allergens (the Big 14): milk, eggs, nuts (peanuts, tree nuts), gluten (wheat), fish, shellfish, sesame, soy, celery, mustard, sulphites, lupin, molluscs
        • Carry an EpiPen (adrenaline auto-injector) if you've had a severe reaction
        • Anaphylaxis signs: throat swelling, difficulty breathing, drop in BP, collapsing → 999 immediately, use EpiPen first

        **Food intolerance vs allergy:**
        • Intolerance: slower response (hours), digestive symptoms, not life-threatening (e.g. lactose intolerance, mild gluten sensitivity)
        • Allergy: rapid, can be severe or fatal

        **Drug allergies:**
        • Most common: penicillin — but 90% of people labelled allergic are actually not (tolerance). Review with GP.
        • If genuinely allergic: wear a MedicAlert bracelet, inform all healthcare providers

        **Diabetes and allergies:**
        • Antihistamines are generally safe with diabetes medications
        • Oral steroids (for severe allergies) significantly raise blood glucose — monitor more closely
        """, chips: ["💊 Allergy medications", "🏥 When to see a specialist", "🌿 Hay fever season tips", "📋 Summary"])
    }

    // ── SUMMARY ────────────────────────────────────────────────────────────────
    private func summaryReply(name: String) -> ChatMessage {
        let glucose = store.latestGlucose
        let bp      = store.latestBP
        let meds    = store.medications.filter { $0.isActive }
        let readings14 = store.glucoseReadings.sorted { $0.date > $1.date }.prefix(14)
        let inRange = readings14.filter {
            $0.value >= store.userProfile.targetGlucoseMin &&
            $0.value <= store.userProfile.targetGlucoseMax
        }.count
        let pct = readings14.count > 0 ? Int(Double(inRange) / Double(readings14.count) * 100) : 0

        var reply = "📊 **Health Summary — \(name)**\n_\(store.userProfile.diabetesType)_\n\n"

        reply += "🩸 **Glucose**\n"
        if let g = glucose {
            let s = store.glucoseStatus(g.value)
            reply += "Latest: **\(Int(g.value)) mg/dL** (\(s.label)) | In range 14d: **\(pct)%**\n\n"
        } else { reply += "No readings yet\n\n" }

        reply += "❤️ **Blood Pressure**\n"
        if let b = bp {
            reply += "Latest: **\(b.systolic)/\(b.diastolic) mmHg** (\(b.category.rawValue)) | Pulse: \(b.pulse) bpm\n\n"
        } else { reply += "No readings yet\n\n" }

        reply += "💊 **Medications:** \(meds.count) active\n"
        for m in meds.prefix(3) { reply += "  · \(m.name) \(m.dosage)\(m.unit)\n" }
        if meds.count > 3 { reply += "  · …+\(meds.count - 3) more\n" }
        reply += "\n"

        reply += "🏃 **Steps today:** \(store.todaySteps)\n"
        reply += "💧 **Water today:** \(Int(store.todayWaterML)) ml\n"
        if let s = store.lastSleep { reply += "😴 **Last sleep:** \(String(format: "%.1f", s.duration)) hours (\(s.quality.rawValue))\n" }

        return msg(reply, chips: ["🩸 Glucose details", "❤️ BP details", "🍽️ Meal plan", "🏃 Exercise tips"])
    }

    // ── TIPS ──────────────────────────────────────────────────────────────────
    private func tipsReply(name: String) -> ChatMessage {
        let tips = [
            "🌅 Check glucose every morning before eating — this 'fasting' reading reveals your overnight control.",
            "🦶 Walk 10–15 minutes after meals — this single habit lowers post-meal glucose by 20–40 mg/dL.",
            "🧂 Reduce sodium by 500 mg/day — this alone can lower systolic BP by 2–5 mmHg.",
            "💊 Take medications at the same time daily — consistent timing is the most important factor in their effectiveness.",
            "😴 7–9 hours of sleep improves insulin sensitivity and reduces appetite hormones — prioritise it.",
            "🥑 Add a healthy fat (avocado, nuts, olive oil) to each meal — fats slow carb absorption and flatten the glucose spike.",
            "🍋 Add lemon juice or apple cider vinegar to meals — acetic acid blunts post-meal glucose spikes by ~20%.",
            "📊 Logging food consistently is the #1 predictor of better metabolic outcomes — what gets measured gets managed.",
            "💧 Drink a full glass of water before every meal — reduces appetite by ~13% and keeps glucose concentration down.",
            "🧘 5 minutes of deep breathing before a meal lowers cortisol, which reduces post-meal glucose spike.",
            "💪 2 sessions of resistance training per week improves insulin sensitivity for up to 48 hours.",
            "🥦 Fill half your plate with non-starchy vegetables at every meal — they're filling, nutrient-dense, and low-glycaemic.",
            "🎯 Eat carbohydrates last in a meal (vegetables and protein first) — reduces post-meal glucose peak by up to 37%.",
            "🚫 Avoid highly processed foods — they raise glucose rapidly, contain hidden salt, and trigger inflammation.",
            "☀️ Get sunlight exposure in the morning — it regulates your circadian rhythm, improving sleep quality at night.",
            "🧡 Social connection is medicine — loneliness and isolation raise cortisol, blood pressure, and inflammation.",
            "📱 Put your phone down an hour before bed — the mental stimulation delays sleep onset even without blue light.",
            "🍵 Green tea contains EGCG which modestly improves insulin sensitivity and has antioxidant benefits.",
            "🏥 Annual blood tests: glucose, HbA1c, kidney function, cholesterol, liver, full blood count, thyroid — don't skip your health review.",
            "❤️ The single most important thing for heart health: don't smoke. If you do, stopping is the most powerful health decision you can make."
        ]
        let tip = tips[Int.random(in: 0..<tips.count)]
        return msg("💡 **Health Tip for \(name)**\n\n\(tip)\n\nWant another one? Just ask!", chips: ["💡 Another tip", "📅 Meal plan", "🏃 Exercise guide", "📋 Health summary"])
    }

    // ── DEVICE ────────────────────────────────────────────────────────────────
    private func deviceReply(name: String) -> ChatMessage {
        return msg("""
        💍 **BodySense Ring for \(name)**

        Your BodySense ring continuously and passively tracks:
        • ❤️ Heart rate and heart rate variability (HRV)
        • 😴 Sleep stages — light, deep, and REM
        • 🏃 Steps, active calories, and activity zones
        • 🌡️ Skin temperature (detects fever, illness, ovulation)
        • 🩸 SpO2 (blood oxygen saturation)

        **To pair/sync:**
        1. Open Settings → Bluetooth on your phone
        2. Hold the ring button for 3 seconds (LED flashes white)
        3. Select 'BodySense Ring' from the device list
        4. Open the app — data syncs automatically

        **Apple Health / Google Fit:**
        Grant access: Settings → Privacy → Health → BodySense AI → Allow

        **Battery:** Charge every 5–7 days. Avoid wearing in pool/ocean (splash resistant only).

        Once connected, all your ring data appears automatically in your Dashboard. The AI engine uses this data to personalise your recommendations — the more you wear it, the smarter the advice.
        """, chips: ["📊 My dashboard", "🏃 Activity data", "😴 Sleep analysis", "📋 Summary"])
    }

    // ── DOCTOR / WHEN TO SEE A GP ──────────────────────────────────────────────
    private func doctorReply(name: String) -> ChatMessage {
        return msg("""
        🏥 **When to See a Doctor, \(name)**

        **See a GP within 1–2 weeks for:**
        • Unexplained weight loss
        • Blood in urine or stools
        • New lump or swelling
        • Change in bowel or bladder habits lasting 3+ weeks
        • Wound not healing after 2 weeks (especially feet)
        • Persistent headache or dizziness
        • Any mole changing in size, shape, or colour
        • Persistent fatigue despite rest
        • Glucose poorly controlled despite medication

        **Go to A&E / call 999 for:**
        • Chest pain, jaw pain, or left arm pain
        • Sudden weakness, facial droop, or speech difficulty → stroke
        • Glucose below 50 mg/dL with symptoms
        • Glucose above 400 mg/dL (or 350 + feeling very unwell)
        • Difficulty breathing
        • Severe allergic reaction (face swelling, throat closing)
        • Any loss of consciousness

        **Book an appointment with your GP for annual reviews:**
        • HbA1c + kidney function + cholesterol + urine albumin
        • Foot examination
        • Blood pressure check
        • Retinal (eye) screening
        • Medication review

        **You can book free specialist appointments through BodySense AI in the Doctors tab.**
        """, chips: ["📅 Book a doctor", "📋 My health summary", "🚨 Emergency signs", "💊 My medications"])
    }

    // ── SMART FALLBACK ────────────────────────────────────────────────────────
    private func smartFallback(name: String, text: String, raw: String) -> ChatMessage {
        // Try to give a useful response based on detected medical concepts
        let medicalTerms: [(keywords: [String], topic: String, chips: [String])] = [
            (["pain", "ache", "hurt", "sore"], "pain management", ["💊 Pain relief options", "🦴 Joint health", "🏥 When to see a doctor", "📋 Summary"]),
            (["tired", "fatigue", "exhausted", "no energy", "weak"], "fatigue", ["😴 Sleep health", "🩸 Anaemia check", "💊 B12 & iron", "📋 Summary"]),
            (["dizzy", "lightheaded", "faint"], "dizziness", ["❤️ Blood pressure", "🩸 Check glucose", "💧 Hydration", "🏥 When to see a doctor"]),
            (["cold", "flu", "fever", "temperature"], "common illness", ["🛡️ Immunity", "💊 Cold remedies", "🤒 Fever management", "📋 Summary"]),
            (["numb", "tingling", "pins and needles"], "neuropathy", ["🧠 Nerve health", "🩸 Glucose control", "💊 B12 levels", "📋 Summary"]),
            (["itch", "rash", "skin problem"], "skin health", ["🧴 Skin conditions", "💊 Skin treatments", "🏥 See a doctor", "📋 Summary"])
        ]

        for term in medicalTerms {
            if term.keywords.contains(where: { text.contains($0) }) {
                return msg("""
                I noticed you mentioned something about **\(term.topic)**, \(name). I can help with that!

                Could you tell me a bit more? For example:
                • Where is the \(term.topic) located?
                • How long have you had it?
                • Is it constant or does it come and go?
                • Does anything make it better or worse?

                Or you can tap one of the quick options below and I'll give you detailed information right away.
                """, chips: term.chips)
            }
        }

        // Pure fallback — try to give a helpful answer about whatever they asked
        return msg("""
        Great question about "\(raw)", \(name)! 🤔

        I'd love to give you a detailed, personalised answer on this topic. My AI engine is currently connecting — here's what I can do right now:

        **Try asking me about specific health topics like:**
        • "What should I eat for breakfast?" — I'll suggest meals based on your health profile
        • "My glucose" — I'll show your latest readings and trends
        • "Meal plan" — I'll create a personalised 7-day plan
        • "How to lower blood pressure" — evidence-based lifestyle tips
        • "Benefits of walking after meals" — exercise guidance

        Or tap one of the quick options below!
        """, chips: ["🍽️ Meal plan", "📊 My health", "🩸 My glucose", "❤️ My BP"])
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    private func msg(_ content: String, chips: [String] = []) -> ChatMessage {
        var m = ChatMessage(content: content, isUser: false)
        m.chips = chips
        return m
    }

    private func matches(_ text: String, _ keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }

    private func average(_ values: [Double]) -> Double {
        values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }

    private func statusEmoji(_ label: String) -> String {
        switch label {
        case "Low":       return "🔵"
        case "Normal":    return "🟢"
        case "Good":      return "✅"
        case "High":      return "🟡"
        case "Very High": return "🔴"
        default:          return ""
        }
    }

    private var firstName: String {
        let n = store.userProfile.name.trimmingCharacters(in: .whitespaces)
        return n.isEmpty ? "friend" : String(n.split(separator: " ").first ?? Substring(n))
    }
}
