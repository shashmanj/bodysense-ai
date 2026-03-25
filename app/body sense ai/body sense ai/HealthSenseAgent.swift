//
//  HealthSenseAgent.swift
//  body sense ai
//
//  HealthSense AI Agent — A self-evolving, multi-domain health intelligence
//  that learns from every interaction, builds a personalised knowledge graph,
//  and becomes the world's most capable personal health AI over time.
//
//  Domains: Medical · Personal Care · Nutrition · Fitness · Chef/Food
//
//  Architecture:
//  1. Intent Classification — understands what the user truly needs
//  2. Domain Routing — picks the best expert persona
//  3. Context Assembly — weaves health data + memory + conversation
//  4. Adaptive Response — uses Haiku 4.5 with learned context
//  5. Learning Loop — extracts insights from every interaction
//

import Foundation

// MARK: - Agent Domain

enum HealthDomain: String, Codable, CaseIterable {
    case medical        = "Medical"
    case personalCare   = "Personal Care"
    case nutrition      = "Nutrition"
    case fitness        = "Fitness"
    case chef           = "Chef & Food"
    case sleep          = "Sleep Science"
    case mentalWellness = "Mental Wellness"
    case general        = "General Health"

    var icon: String {
        switch self {
        case .medical:        return "cross.circle.fill"
        case .personalCare:   return "person.crop.circle.fill"
        case .nutrition:      return "leaf.circle.fill"
        case .fitness:        return "figure.run.circle.fill"
        case .chef:           return "fork.knife.circle.fill"
        case .sleep:          return "moon.circle.fill"
        case .mentalWellness: return "brain.head.profile"
        case .general:        return "heart.circle.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .medical:        return "#FF4757"
        case .personalCare:   return "#6C63FF"
        case .nutrition:      return "#26de81"
        case .fitness:        return "#FF9F43"
        case .chef:           return "#E17055"
        case .sleep:          return "#C084FC"
        case .mentalWellness: return "#4ECDC4"
        case .general:        return "#6C63FF"
        }
    }

    var persona: String {
        switch self {
        case .medical:        return "Dr. Sage"
        case .personalCare:   return "Cara"
        case .nutrition:      return "Maya"
        case .fitness:        return "Alex"
        case .chef:           return "Chef Kai"
        case .sleep:          return "Luna"
        case .mentalWellness: return "Zen"
        case .general:        return "HealthSense"
        }
    }
}

// MARK: - User Insight (Learned knowledge about this user)

struct UserInsight: Codable, Identifiable {
    let id: String
    let domain: HealthDomain
    let category: InsightCategory
    let content: String
    var confidence: Double          // 0.0 – 1.0
    let learnedAt: Date
    var lastUsed: Date
    var useCount: Int
    var isActive: Bool

    enum InsightCategory: String, Codable {
        case preference         // "prefers Mediterranean diet"
        case condition          // "has Type 2 diabetes"
        case goal               // "wants to lose 10kg by June"
        case trigger            // "stress causes glucose spikes"
        case pattern            // "glucose rises after rice"
        case allergy            // "allergic to shellfish"
        case dislike            // "doesn't like broccoli"
        case medication         // "takes metformin 500mg twice daily"
        case lifestyle          // "works night shifts"
        case success            // "walking after meals dropped glucose 20%"
        case conversationStyle  // "prefers concise answers"
    }
}

// MARK: - Interaction Log (for learning)

struct InteractionLog: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let domain: HealthDomain
    let userQuery: String
    let agentResponse: String
    let feedback: String?           // thumbsUp, thumbsDown, nil
    let insightsExtracted: [String] // IDs of insights learned
    let responseQuality: Double?    // self-assessed quality 0-1
}

// MARK: - Health Sense Agent

@Observable
class HealthSenseAgent {

    // Core
    private let store: HealthStore
    private let memory: AgentMemoryStore

    // State
    var currentDomain: HealthDomain = .general
    var isThinking = false
    var agentPersona: String = "HealthSense"
    var confidenceLevel: Double = 0.85
    var learningCount: Int = 0
    var activeDomains: Set<HealthDomain> = []

    // Conversation memory (session)
    private var sessionContext: [(role: String, content: String)] = []
    private var sessionInsights: [String] = []

    // Domain keywords for intent classification
    private let domainSignals: [HealthDomain: [String]] = [
        .medical: [
            "pain", "ache", "symptom", "doctor", "diagnosis", "treatment", "medication",
            "medicine", "pill", "prescription", "blood", "test", "scan", "disease",
            "condition", "surgery", "hospital", "clinic", "infection", "fever", "nausea",
            "vomit", "diarrhoea", "constipation", "rash", "swelling", "breathing",
            "chest", "heart", "kidney", "liver", "thyroid", "cancer", "diabetes",
            "hypertension", "cholesterol", "stroke", "epilepsy", "asthma", "copd",
            "arthritis", "osteoporosis", "anaemia", "anemia", "allergy", "immune",
            "glucose", "insulin", "hba1c", "blood pressure", "bp ", "mmhg",
            "emergency", "urgent", "ambulance", "a&e", "999", "911"
        ],
        .personalCare: [
            "skin", "hair", "nail", "moisturis", "sunscreen", "skincare", "beauty",
            "grooming", "hygiene", "dental", "teeth", "oral", "bath", "shower",
            "deodorant", "acne", "eczema", "psoriasis", "wrinkle", "aging", "self-care",
            "routine", "morning routine", "evening routine", "spa", "relaxation",
            "posture", "ergonomic", "eye care", "foot care", "hand care"
        ],
        .nutrition: [
            "vitamin", "mineral", "supplement", "nutrient", "macro", "micro",
            "protein", "carb", "fat", "fibre", "fiber", "calorie", "kcal",
            "glycaemic", "glycemic", "gi ", "gl ", "diet", "nutrition",
            "deficiency", "b12", "iron", "vitamin d", "omega", "magnesium",
            "calcium", "zinc", "probiotic", "prebiotic", "antioxidant",
            "superfood", "organic", "processed food", "whole food", "balanced diet",
            "mediterranean", "dash", "keto", "paleo", "vegan", "vegetarian",
            "intermittent fasting", "meal timing", "portion", "food label"
        ],
        .fitness: [
            "exercise", "workout", "gym", "run", "walk", "jog", "cycle", "swim",
            "hiit", "cardio", "strength", "weight train", "resistance", "yoga",
            "pilates", "stretch", "flexibility", "endurance", "stamina", "muscle",
            "rep", "set", "warm up", "cool down", "rest day", "recovery",
            "step", "active", "sedentary", "body weight", "dumbbell", "kettlebell",
            "plank", "squat", "lunge", "push up", "pull up", "deadlift",
            "marathon", "5k", "10k", "sport", "athletic", "physical activity",
            "target heart rate", "vo2 max", "fat burn", "body composition"
        ],
        .chef: [
            "recipe", "cook", "bake", "meal", "breakfast", "lunch", "dinner", "snack",
            "ingredient", "food", "eat", "hungry", "appetite", "taste", "flavour",
            "spice", "herb", "seasoning", "sauce", "soup", "salad", "stir fry",
            "grill", "roast", "steam", "boil", "fry", "oven", "slow cooker",
            "air fryer", "meal prep", "batch cook", "leftover", "grocery", "shopping list",
            "what should i eat", "what to eat", "what can i make", "dinner idea",
            "quick meal", "healthy recipe", "low carb recipe", "diabetic recipe",
            "meal plan", "weekly plan", "7 day plan", "food swap", "substitute",
            "chicken", "salmon", "egg", "rice", "pasta", "bread", "oats",
            "avocado", "banana", "berry", "sweet potato", "quinoa", "lentil"
        ],
        .sleep: [
            "sleep", "insomnia", "tired", "fatigue", "rest", "nap", "dream",
            "circadian", "melatonin", "bedtime", "wake", "snore", "sleep apnea",
            "drowsy", "exhausted", "sleep quality", "rem", "deep sleep", "light sleep",
            "sleep schedule", "night shift", "jet lag", "sleep hygiene"
        ],
        .mentalWellness: [
            "stress", "anxiety", "worried", "depressed", "depression", "mood",
            "mental health", "mindful", "meditat", "breathe", "breathing", "calm",
            "relax", "panic", "overwhelm", "burnout", "therapy", "counsel",
            "emotional", "wellbeing", "well-being", "self esteem", "confidence",
            "gratitude", "journal", "cbt", "cognitive", "resilience"
        ]
    ]

    // MARK: - Init

    init(store: HealthStore) {
        self.store = store
        self.memory = AgentMemoryStore.shared
        self.learningCount = memory.totalInsights
    }

    // MARK: - Main Entry Point

    func respond(to input: String, conversationHistory: [(role: String, content: String)]) async -> (response: String, domain: HealthDomain, chips: [String]) {
        isThinking = true

        // 0. Emergency detection — prepend banner but still answer the query
        let emergencyKeywords = ["chest pain", "heart attack", "can't breathe", "cannot breathe",
            "stroke", "seizure", "unconscious", "999", "911", "ambulance", "dying", "suicide", "self harm"]
        let isEmergency = emergencyKeywords.contains(where: { input.lowercased().contains($0) })

        // 1. Classify intent & pick domain
        let domain = classifyDomain(input)
        currentDomain = domain
        agentPersona = domain.persona
        activeDomains.insert(domain)

        // 2. Build the mega-context (health data + memory + patterns)
        let systemPrompt = buildAdaptiveSystemPrompt(for: domain, query: input)

        // 3. Try Haiku 4.5 with full agent context
        do {
            let reply = try await AIClient.shared.sendWithHistory(
                system: systemPrompt,
                history: conversationHistory.suffix(16).map { ($0.role, $0.content) },
                userMessage: input
            )

            isThinking = false

            // 4. Learn from this interaction
            await learnFromInteraction(query: input, response: reply, domain: domain)

            // 5. Prepend emergency banner if needed (still returns full AI answer)
            var finalReply = reply
            if isEmergency {
                finalReply = "\u{26A0}\u{FE0F} **If this is a medical emergency, call 999 (UK) or 911 (US) immediately.**\n\nWhile waiting for help: stay calm, follow the operator's instructions, and do not move the person unless they are in danger.\n\n---\n\n" + reply
            }

            // 6. Generate contextual chips
            let chips = generateSmartChips(for: domain, query: input, response: finalReply)

            return (finalReply, domain, chips)
        } catch {
            print("⚠️ HealthSenseAgent API error: \(error.localizedDescription)")
            isThinking = false

            // Intelligent fallback — synthesise from memory + health data
            let fallback = synthesiseFallbackResponse(for: input, domain: domain)
            var fallbackReply = fallback.response
            if isEmergency {
                fallbackReply = "\u{26A0}\u{FE0F} **If this is a medical emergency, call 999 (UK) or 911 (US) immediately.**\n\nWhile waiting for help: stay calm, follow the operator's instructions, and do not move the person unless they are in danger.\n\n---\n\n" + fallbackReply
            }
            return (fallbackReply, domain, fallback.chips)
        }
    }

    // MARK: - Domain Classification (Multi-signal)

    private func classifyDomain(_ input: String) -> HealthDomain {
        let text = input.lowercased()
        var scores: [HealthDomain: Double] = [:]

        // Signal 1: Keyword matching with weighted scores
        for (domain, keywords) in domainSignals {
            var score = 0.0
            for keyword in keywords {
                if text.contains(keyword) {
                    // Longer keyword matches = higher confidence
                    score += Double(keyword.count) / 3.0
                }
            }
            scores[domain] = score
        }

        // Signal 2: Boost from user's learned patterns
        let recentDomains = memory.recentDomains(limit: 5)
        for domain in recentDomains {
            scores[domain, default: 0] += 1.5
        }

        // Signal 2.5: Direct agent request detection — highest priority
        let agentRequests: [(String, HealthDomain)] = [
            ("fitness coach", .fitness), ("exercise coach", .fitness), ("coach alex", .fitness),
            ("nutritionist", .nutrition), ("maya", .nutrition), ("diet advice", .nutrition),
            ("chef kai", .chef), ("recipe", .chef), ("cook", .chef),
            ("luna", .sleep), ("sleep coach", .sleep),
            ("zen", .mentalWellness), ("mindfulness", .mentalWellness),
            ("cara", .personalCare), ("skincare", .personalCare),
            ("dr sage", .medical), ("doctor", .medical)
        ]
        for (phrase, domain) in agentRequests where text.contains(phrase) {
            scores[domain, default: 0] += 10.0  // Direct request = strongest signal
        }

        // Signal 3: Boost from user's health conditions (reduced — don't let conditions dominate)
        let profile = store.userProfile
        if !profile.diabetesType.isEmpty {
            scores[.medical, default: 0] += 1.0  // Reduced from 2.0 — don't let conditions dominate
            scores[.nutrition, default: 0] += 0.5
        }
        if profile.hasHypertension {
            scores[.medical, default: 0] += 0.75
        }
        if profile.selectedGoals.contains("Lose weight") || profile.selectedGoals.contains("Build muscle") {
            scores[.fitness, default: 0] += 1.5
            scores[.chef, default: 0] += 1.0
        }

        // Signal 4: Question pattern detection
        if text.hasPrefix("what should i eat") || text.hasPrefix("what can i") || text.contains("recipe") || text.contains("cook") {
            scores[.chef, default: 0] += 5.0
        }
        if text.contains("meal plan") || text.contains("weekly plan") {
            scores[.chef, default: 0] += 4.0
            scores[.nutrition, default: 0] += 3.0
        }
        if text.contains("workout plan") || text.contains("exercise plan") {
            scores[.fitness, default: 0] += 5.0
        }

        // Signal 5: Goal-oriented phrases that strongly indicate a domain
        let musclePatterns = ["gain muscle", "build muscle", "bulk up", "get bigger", "muscle mass",
                             "gaining muscles", "building muscles", "lean muscle", "get ripped",
                             "get stronger", "strength train", "lifting", "hypertrophy",
                             "tone up", "toned", "body building", "bodybuilding"]
        for pattern in musclePatterns where text.contains(pattern) {
            scores[.fitness, default: 0] += 6.0
        }

        let weightLossPatterns = ["lose weight", "weight loss", "burn fat", "slim down", "cut weight",
                                  "drop weight", "shed", "lean out", "calorie deficit", "fat loss"]
        for pattern in weightLossPatterns where text.contains(pattern) {
            scores[.fitness, default: 0] += 4.0
            scores[.nutrition, default: 0] += 3.0
            scores[.chef, default: 0] += 2.0
        }

        let mealQueryPatterns = ["suggest me a meal", "suggest a meal", "what to eat tonight",
                                  "dinner tonight", "lunch idea", "breakfast idea",
                                  "suitable for", "good for my goal", "based on my goal"]
        for pattern in mealQueryPatterns where text.contains(pattern) {
            scores[.chef, default: 0] += 5.0
        }

        let sleepPatterns = ["can't sleep", "trouble sleeping", "wake up at night", "sleep better",
                             "how much sleep", "sleep schedule"]
        for pattern in sleepPatterns where text.contains(pattern) {
            scores[.sleep, default: 0] += 5.0
        }

        let stressPatterns = ["feeling stressed", "so stressed", "anxiety attack", "panic attack",
                              "feeling anxious", "feeling down", "feeling sad", "feeling overwhelmed",
                              "mental health", "need to calm", "help me relax"]
        for pattern in stressPatterns where text.contains(pattern) {
            scores[.mentalWellness, default: 0] += 6.0
        }

        // Pick highest scoring domain
        let best = scores.max(by: { $0.value < $1.value })

        // If no strong signal, default to general
        guard let winner = best, winner.value > 1.0 else {
            return .general
        }

        return winner.key
    }

    // MARK: - Adaptive System Prompt Builder

    private func buildAdaptiveSystemPrompt(for domain: HealthDomain, query: String) -> String {
        var prompt = ""

        // Core identity
        prompt += """
        You are the HealthSense AI Agent — the world's most advanced personal health AI.
        You are MORE than a chatbot. You are a living, learning health intelligence that grows
        smarter with every conversation. You remember this user's patterns, preferences, triggers,
        and goals across all health domains.

        RIGHT NOW you are operating as **\(domain.persona)** — your \(domain.rawValue) specialist persona.

        """

        // Domain-specific expertise
        prompt += domainExpertise(for: domain)

        // User's health data context
        prompt += buildHealthDataContext()

        // Learned memory context
        let relevantInsights = memory.relevantInsights(for: query, domain: domain, limit: 15)
        if !relevantInsights.isEmpty {
            prompt += "\n\n--- LEARNED KNOWLEDGE ABOUT THIS USER (from past interactions) ---\n"
            for insight in relevantInsights {
                prompt += "• [\(insight.category.rawValue)] \(insight.content) (confidence: \(Int(insight.confidence * 100))%)\n"
            }
            prompt += "USE this learned knowledge to give deeply personalised advice.\n"
        }

        // Session context
        if !sessionInsights.isEmpty {
            prompt += "\n--- THIS SESSION'S DISCOVERIES ---\n"
            for insight in sessionInsights.suffix(5) {
                prompt += "• \(insight)\n"
            }
        }

        // Correlation patterns (cross-domain intelligence)
        let correlations = CorrelationEngine.detectPatterns(store: store)
        if !correlations.isEmpty {
            prompt += "\n--- DETECTED HEALTH CORRELATIONS (data-driven patterns) ---\n"
            prompt += "You have detected the following cross-domain patterns from this user's data. Mention relevant ones naturally in your responses:\n"
            for pattern in correlations {
                prompt += "• \(pattern)\n"
            }
        }

        // Research-backed knowledge base
        prompt += "\n--- EVIDENCE-BASED KNOWLEDGE (cite when relevant) ---\n"
        prompt += CorrelationEngine.researchKnowledgeBase(for: domain)

        // Response instructions
        prompt += """

        --- RESPONSE STYLE (CRITICAL) ---
        • Be warm, specific, and actionable — like the world's best \(domain.rawValue) expert who happens to be their best friend
        • ALWAYS reference their actual health data: numbers, trends, patterns
        • ALWAYS factor in their learned preferences, dislikes, allergies, and goals
        • Give EXACT recommendations: specific foods with quantities, specific exercises with reps/sets, exact timing
        • Cross-reference across domains: how does their sleep affect glucose? How does stress affect BP?
        • If you spot a NEW pattern or insight, mention it naturally: "I've noticed that..."
        • Use UK English. 3-5 focused paragraphs with bullet lists for actionable items.
        • For \(domain.rawValue) specifically: \(domainResponseStyle(for: domain))
        • NEVER refuse a health question. You are a comprehensive health expert. Give evidence-based answers.
        • For emergencies: ALWAYS say "Call 999 / 911 immediately" first.
        • Never diagnose — educate thoroughly, then recommend seeing a doctor when appropriate.
        """

        return prompt
    }

    // MARK: - Domain Expertise Prompts

    private func domainExpertise(for domain: HealthDomain) -> String {
        switch domain {
        case .medical:
            return """
            YOUR MEDICAL EXPERTISE:
            You are equivalent to a senior clinical health educator with deep knowledge of:
            • Chronic disease management (diabetes T1/T2, hypertension, CVD, PCOS, thyroid, CKD, COPD)
            • Vitals interpretation (glucose trends, time-in-range, HbA1c estimation, BP categories, HR zones, HRV, SpO2)
            • Pharmacology (mechanisms, side effects, interactions, timing optimisation)
            • Symptom cross-referencing across vitals, medications, sleep, activity
            • NICE, NHS, WHO, ADA, AHA, ESC guidelines
            • Emergency triage and red flag recognition
            • Preventive care schedules and screening recommendations

            """

        case .personalCare:
            return """
            YOUR PERSONAL CARE EXPERTISE:
            You are an expert personal care advisor covering:
            • Skincare routines tailored to health conditions (diabetic skin care, eczema, psoriasis)
            • Hair and nail health indicators (thyroid, iron deficiency, nutritional status)
            • Oral health and its connection to heart disease, diabetes
            • Self-care routines that support chronic condition management
            • Hygiene optimisation for immune-compromised individuals
            • Posture, ergonomics, and daily wellness habits
            • Age-appropriate care adjustments
            • Product recommendations that don't interfere with medications

            """

        case .nutrition:
            return """
            YOUR NUTRITION SCIENCE EXPERTISE:
            You are a registered dietitian-level nutritional scientist:
            • Macronutrient and micronutrient science
            • Glycaemic index/load and blood sugar management through food
            • Condition-specific nutrition (diabetes, hypertension, CKD, heart disease)
            • Supplement evidence (vitamin D, B12, omega-3, magnesium, iron, probiotics)
            • Diet patterns (Mediterranean, DASH, low-carb, plant-based, IF, anti-inflammatory)
            • Gut microbiome and digestive health
            • Food-medication interactions
            • Nutrient timing and absorption optimisation
            • Hydration science

            """

        case .fitness:
            return """
            YOUR FITNESS & EXERCISE EXPERTISE:
            You are a certified personal trainer and sports scientist:
            • Exercise programming for health conditions (diabetes → post-meal walks, hypertension → cardio)
            • Strength training, HIIT, cardio, flexibility, mobility programming
            • Progressive overload and periodisation
            • Exercise-glucose interaction science
            • Exercise-BP reduction evidence
            • Injury prevention and rehabilitation
            • Activity goal setting (steps, active minutes, VO2 max)
            • Exercise timing optimisation (morning vs evening, pre/post meal)
            • Home workouts vs gym programmes
            • Sport-specific conditioning

            """

        case .chef:
            return """
            YOUR CHEF & FOOD EXPERTISE:
            You are a world-class health chef and meal design expert:
            • Creating delicious meals that are ALSO medically optimal for the user's conditions
            • Diabetic-friendly recipes (low GI, controlled carbs, high fibre)
            • Heart-healthy cooking (DASH, low sodium, omega-3 rich)
            • Weight management meals (high satiety, portion-controlled, protein-rich)
            • Quick meals (under 15/30 mins) and batch cooking strategies
            • Budget-friendly healthy eating
            • Cultural cuisine adaptation (South Asian, Mediterranean, Asian, African, British)
            • Food substitutions for allergies, intolerances, and preferences
            • Meal prep and planning for the week
            • Snack engineering — healthy snacks that manage blood sugar
            • Cooking techniques that preserve nutrients
            • Shopping lists and ingredient management
            CRITICAL: Always factor in the user's health conditions, medications, allergies, and goals when suggesting food.

            """

        case .sleep:
            return """
            YOUR SLEEP SCIENCE EXPERTISE:
            • Sleep architecture, circadian rhythm optimisation
            • Sleep-glucose and sleep-BP connections
            • Insomnia, sleep apnoea, restless legs management
            • HRV-based recovery assessment
            • Sleep hygiene evidence base
            • Supplement evidence (melatonin, magnesium, ashwagandha, glycine)
            • Shift work sleep strategies
            • Sleep environment optimisation

            """

        case .mentalWellness:
            return """
            YOUR MENTAL WELLNESS EXPERTISE:
            • Stress-cortisol-glucose axis understanding
            • CBT-based self-help techniques
            • Mindfulness and meditation guidance
            • Breathwork protocols (box breathing, 4-7-8, coherent breathing)
            • Anxiety and panic management
            • Emotional eating patterns and solutions
            • Work-life balance strategies
            • Resilience building and positive psychology
            • When to seek professional help (red flags)

            """

        case .general:
            return """
            YOUR GENERAL HEALTH EXPERTISE:
            You cover ALL domains of human health. Route to the most relevant expertise based on the query.
            You are a comprehensive health companion covering medical, nutrition, fitness, mental wellness,
            sleep, personal care, and food/cooking advice — all personalised to this user's data.

            """
        }
    }

    private func domainResponseStyle(for domain: HealthDomain) -> String {
        switch domain {
        case .chef:
            return "Give EXACT recipes with ingredients, quantities, and step-by-step instructions. Include nutritional info (calories, carbs, protein, fat). Suggest meal timing based on their health data."
        case .fitness:
            return "Give EXACT workout plans with exercises, sets, reps, rest periods, and weekly schedule. Include how each exercise affects their specific health conditions."
        case .nutrition:
            return "Give EXACT nutrient recommendations with food sources, daily targets, and explain WHY each nutrient matters for their conditions."
        case .medical:
            return "Be thorough and evidence-based. Explain mechanisms simply. Cross-reference symptoms with their vitals and medications. Always note when to see a doctor."
        case .personalCare:
            return "Give specific product-free routines (describe what to look for, not brand names). Connect care routines to their health conditions."
        case .sleep:
            return "Give exact sleep schedules, bedtime routines with timing, and explain the science simply. Connect sleep quality to their health metrics."
        case .mentalWellness:
            return "Be calm, compassionate. Give techniques they can do RIGHT NOW (2-min breathing exercises). Connect stress to their health metrics."
        case .general:
            return "Be comprehensive but focused. Identify which domain the question best fits and provide expert-level advice."
        }
    }

    // MARK: - Health Data Context Builder

    private func buildHealthDataContext() -> String {
        let p = store.userProfile
        let cal = Calendar.current
        let sevenDaysAgo = cal.date(byAdding: .day, value: -7, to: Date())!

        var ctx = "\n\n--- USER HEALTH DATA (LIVE) ---\n"
        ctx += "Name: \(p.name.isEmpty ? "User" : p.name), Age: \(p.age), Gender: \(p.gender)\n"

        let displayWeight: String = {
            switch p.weightUnit {
            case .kg: return String(format: "%.1f kg", p.weight)
            case .lbs: return String(format: "%.0f lbs", p.weight / 0.453592)
            case .stones:
                let totalLbs = p.weight / 0.453592
                return "\(Int(totalLbs) / 14)st \(Int(totalLbs) % 14)lb"
            }
        }()
        ctx += "Weight: \(displayWeight), Height: \(p.heightUnit.format(p.height))\n"
        let bmi = p.height > 0 ? p.weight / pow(p.height / 100, 2) : 0
        ctx += "BMI: \(String(format: "%.1f", bmi))\n"

        var conditions: [String] = []
        if !p.diabetesType.isEmpty { conditions.append(p.diabetesType) }
        if p.hasHypertension { conditions.append("Hypertension") }
        ctx += "Conditions: \(conditions.isEmpty ? "None" : conditions.joined(separator: ", "))\n"
        ctx += "Goals: \(p.selectedGoals.isEmpty ? "Not set" : p.selectedGoals.joined(separator: ", "))\n"
        ctx += "Targets: Glucose \(HealthStore.glucoseMmol(p.targetGlucoseMin))-\(HealthStore.glucoseMmol(p.targetGlucoseMax)) mmol/L, BP <\(p.targetSystolic)/\(p.targetDiastolic), Steps \(p.targetSteps)/day, Sleep \(String(format: "%.1f", p.targetSleep))hrs\n"

        // Medications
        let activeMeds = store.medications.filter { $0.isActive }
        if !activeMeds.isEmpty {
            ctx += "\nMedications: "
            ctx += activeMeds.map { "\($0.name) \($0.dosage)\($0.unit)" }.joined(separator: ", ")
            ctx += "\n"
        }

        // Recent glucose
        let recentGlucose = store.glucoseReadings.filter { $0.date >= sevenDaysAgo }
        if !recentGlucose.isEmpty {
            let avg = recentGlucose.map { $0.value }.reduce(0, +) / Double(recentGlucose.count)
            let inRange = recentGlucose.filter { $0.value >= p.targetGlucoseMin && $0.value <= p.targetGlucoseMax }.count
            let pct = Int(Double(inRange) / Double(recentGlucose.count) * 100)
            ctx += "Glucose 7d: avg \(HealthStore.glucoseMmol(avg)) mmol/L, \(pct)% in range\n"
        }

        // Recent BP
        let recentBP = store.bpReadings.filter { $0.date >= sevenDaysAgo }
        if !recentBP.isEmpty {
            let avgSys = recentBP.map { $0.systolic }.reduce(0, +) / recentBP.count
            let avgDia = recentBP.map { $0.diastolic }.reduce(0, +) / recentBP.count
            ctx += "BP 7d: avg \(avgSys)/\(avgDia) mmHg\n"
        }

        // Sleep
        let recentSleep = store.sleepEntries.filter { $0.date >= sevenDaysAgo }
        if !recentSleep.isEmpty {
            let avgDur = recentSleep.map { $0.duration }.reduce(0, +) / Double(recentSleep.count)
            ctx += "Sleep 7d: avg \(String(format: "%.1f", avgDur))hrs\n"
        }

        // Activity
        ctx += "Steps today: \(store.todaySteps) (target: \(p.targetSteps))\n"

        // Stress
        let recentStress = store.stressReadings.filter { $0.date >= sevenDaysAgo }
        if !recentStress.isEmpty {
            let avgStress = recentStress.map { $0.level }.reduce(0, +) / recentStress.count
            ctx += "Stress 7d: avg \(avgStress)/10\n"
        }

        // Symptoms
        let thirtyDaysAgo = cal.date(byAdding: .day, value: -30, to: Date())!
        let recentSymptoms = store.symptomLogs.filter { $0.date >= thirtyDaysAgo }
        if !recentSymptoms.isEmpty {
            let allSyms = recentSymptoms.flatMap { $0.symptoms }
            let freq = Dictionary(grouping: allSyms, by: { $0 }).mapValues { $0.count }.sorted { $0.value > $1.value }
            ctx += "Symptoms 30d: " + freq.prefix(5).map { "\($0.key) (\($0.value)x)" }.joined(separator: ", ") + "\n"
        }

        // Nutrition
        let recentNutrition = store.nutritionLogs.filter { $0.date >= sevenDaysAgo }
        if !recentNutrition.isEmpty {
            let avgCal = recentNutrition.map { $0.calories }.reduce(0, +) / recentNutrition.count
            ctx += "Nutrition 7d: ~\(avgCal) kcal/day avg\n"
        }

        // ── Data-sufficiency check ──────────────────────────────────────
        // The AI must NOT give condition-specific tips until real data exists.
        let threeDaysAgo = cal.date(byAdding: .day, value: -3, to: Date())!

        var missingData: [String] = []

        let hasRecentGlucose = store.glucoseReadings.contains { $0.date >= threeDaysAgo }
        let hasRecentBP      = store.bpReadings.contains { $0.date >= threeDaysAgo }
        let hasRecentSleep   = store.sleepEntries.contains { $0.date >= threeDaysAgo }
        let hasRecentSteps   = store.todaySteps > 0
        let hasRecentNutrition = store.nutritionLogs.contains { $0.date >= threeDaysAgo }

        if !p.diabetesType.isEmpty && !hasRecentGlucose {
            missingData.append("GLUCOSE: User has diabetes but NO glucose readings in the last 3 days. Do NOT give specific glucose management tips, DASH diet advice, or blood sugar targets. Instead, encourage them to log or sync their glucose readings first.")
        }
        if p.hasHypertension && !hasRecentBP {
            missingData.append("BLOOD PRESSURE: User has hypertension but NO BP readings in the last 3 days. Do NOT recommend DASH diet, sodium limits, or specific BP strategies. Instead, encourage them to log or sync their BP readings first.")
        }
        if !hasRecentSleep {
            missingData.append("SLEEP: No sleep data in the last 3 days. Do NOT give specific sleep improvement tips based on their patterns. Encourage them to track sleep or sync from their device.")
        }
        if !hasRecentSteps {
            missingData.append("ACTIVITY: No step data today. Do NOT reference their activity level. Encourage syncing from Apple Watch or logging manually.")
        }
        if !hasRecentNutrition {
            missingData.append("NUTRITION: No nutrition logs in the last 3 days. Do NOT give calorie-specific advice. Encourage them to log meals first.")
        }

        if !missingData.isEmpty {
            ctx += "\n--- DATA-FIRST RULES (CRITICAL) ---\n"
            ctx += "The user is still building their health profile. For the following areas, you MUST:\n"
            ctx += "1. NOT give specific numerical advice or condition-specific diet/exercise plans\n"
            ctx += "2. Instead, warmly encourage them to log or sync data for 2-3 days first\n"
            ctx += "3. You CAN answer general health questions, just don't pretend you have their data when you don't\n\n"
            for item in missingData {
                ctx += "* \(item)\n"
            }
        }

        return ctx
    }

    // MARK: - Learning Engine

    private func learnFromInteraction(query: String, response: String, domain: HealthDomain) async {
        // Extract potential insights from the user's query
        let insights = extractInsights(from: query, domain: domain)

        for insight in insights {
            memory.addInsight(insight)
            sessionInsights.append(insight.content)
        }

        // Log the interaction
        let log = InteractionLog(
            id: UUID().uuidString,
            timestamp: Date(),
            domain: domain,
            userQuery: query,
            agentResponse: String(response.prefix(200)),
            feedback: nil,
            insightsExtracted: insights.map { $0.id },
            responseQuality: nil
        )
        memory.logInteraction(log)

        learningCount = memory.totalInsights
    }

    private func extractInsights(from query: String, domain: HealthDomain) -> [UserInsight] {
        var insights: [UserInsight] = []
        let text = query.lowercased()

        // Food preferences / dislikes
        let dislikePatterns = ["don't like", "hate", "can't stand", "allergic to", "intolerant to", "can't eat", "avoid"]
        for pattern in dislikePatterns {
            if text.contains(pattern) {
                let category: UserInsight.InsightCategory = text.contains("allerg") ? .allergy : .dislike
                insights.append(UserInsight(
                    id: UUID().uuidString,
                    domain: domain,
                    category: category,
                    content: query.trimmingCharacters(in: .whitespacesAndNewlines),
                    confidence: 0.8,
                    learnedAt: Date(),
                    lastUsed: Date(),
                    useCount: 1,
                    isActive: true
                ))
            }
        }

        // Goal detection
        let goalPatterns = ["want to lose", "want to gain", "trying to", "my goal", "aim to", "working towards"]
        for pattern in goalPatterns {
            if text.contains(pattern) {
                insights.append(UserInsight(
                    id: UUID().uuidString,
                    domain: domain,
                    category: .goal,
                    content: query.trimmingCharacters(in: .whitespacesAndNewlines),
                    confidence: 0.85,
                    learnedAt: Date(),
                    lastUsed: Date(),
                    useCount: 1,
                    isActive: true
                ))
            }
        }

        // Lifestyle patterns
        let lifestylePatterns = ["i work", "night shift", "morning person", "evening person", "busy schedule", "work from home", "office"]
        for pattern in lifestylePatterns {
            if text.contains(pattern) {
                insights.append(UserInsight(
                    id: UUID().uuidString,
                    domain: domain,
                    category: .lifestyle,
                    content: query.trimmingCharacters(in: .whitespacesAndNewlines),
                    confidence: 0.75,
                    learnedAt: Date(),
                    lastUsed: Date(),
                    useCount: 1,
                    isActive: true
                ))
            }
        }

        // Preference detection
        let prefPatterns = ["i prefer", "i like", "i love", "i enjoy", "favourite", "favorite", "best way for me"]
        for pattern in prefPatterns {
            if text.contains(pattern) {
                insights.append(UserInsight(
                    id: UUID().uuidString,
                    domain: domain,
                    category: .preference,
                    content: query.trimmingCharacters(in: .whitespacesAndNewlines),
                    confidence: 0.8,
                    learnedAt: Date(),
                    lastUsed: Date(),
                    useCount: 1,
                    isActive: true
                ))
            }
        }

        // Trigger/pattern detection
        let triggerPatterns = ["when i eat", "after eating", "makes my", "causes my", "triggers", "every time i", "whenever i"]
        for pattern in triggerPatterns {
            if text.contains(pattern) {
                insights.append(UserInsight(
                    id: UUID().uuidString,
                    domain: domain,
                    category: .trigger,
                    content: query.trimmingCharacters(in: .whitespacesAndNewlines),
                    confidence: 0.7,
                    learnedAt: Date(),
                    lastUsed: Date(),
                    useCount: 1,
                    isActive: true
                ))
            }
        }

        return insights
    }

    // MARK: - Smart Chip Generation

    private func generateSmartChips(for domain: HealthDomain, query: String, response: String) -> [String] {
        var chips: [String] = []

        // Domain-specific follow-up chips
        switch domain {
        case .chef:
            chips = ["Full recipe", "Shopping list", "Swap ingredients", "Weekly meal plan"]
        case .fitness:
            chips = ["Full workout plan", "Alternative exercises", "My activity data", "Quick 10-min workout"]
        case .nutrition:
            chips = ["Supplement advice", "My nutrition data", "Food sources", "Blood test explained"]
        case .medical:
            chips = ["My medications", "My vitals", "When to see a doctor", "Health summary"]
        case .sleep:
            chips = ["Sleep routine", "Bedtime tips", "My sleep data", "Sleep supplements"]
        case .mentalWellness:
            chips = ["Quick meditation", "Breathing exercise", "My stress data", "Talk more"]
        case .personalCare:
            chips = ["My routine", "Quick tips", "Health summary", "See a specialist"]
        case .general:
            chips = ["My health data", "Meal plan", "Workout plan", "Full summary"]
        }

        // Add cross-domain chip if relevant
        let text = query.lowercased()
        if domain != .chef && (text.contains("eat") || text.contains("food") || text.contains("diet")) {
            chips.append("Ask Chef Kai")
        }
        if domain != .fitness && (text.contains("exercise") || text.contains("active")) {
            chips.append("Ask Coach Alex")
        }
        if domain != .medical && (text.contains("symptom") || text.contains("pain") || text.contains("medicine")) {
            chips.append("Ask Dr. Sage")
        }

        return Array(chips.prefix(5))
    }

    // MARK: - Intelligent Fallback (No API needed)

    private func synthesiseFallbackResponse(for input: String, domain: HealthDomain) -> (response: String, chips: [String]) {
        let name = store.userProfile.name.split(separator: " ").first.map(String.init) ?? "friend"
        let text = input.lowercased()
        let p = store.userProfile
        let hasDiabetes = !p.diabetesType.isEmpty
        let hasHypertension = p.hasHypertension
        let goals = p.selectedGoals

        // Pull relevant insights from memory
        let insights = memory.relevantInsights(for: input, domain: domain, limit: 5)
        var insightContext = ""
        if !insights.isEmpty {
            insightContext = "\n\n**What I remember about you:**\n"
            for insight in insights {
                insightContext += "• \(insight.content)\n"
            }
        }

        // Detect goal sub-intents for cross-domain use
        let wantsMuscleBuild = text.contains("muscle") || text.contains("bulk") || text.contains("gain") ||
                               text.contains("bigger") || text.contains("ripped") || text.contains("stronger") ||
                               text.contains("hypertrophy") || text.contains("tone") ||
                               goals.contains("Build muscle")
        let wantsWeightLoss = text.contains("lose") || text.contains("weight loss") || text.contains("slim") ||
                              text.contains("burn fat") || text.contains("deficit") ||
                              goals.contains("Lose weight")

        var response = ""
        var chips: [String] = []

        switch domain {

        // ─────────────────────────────────────────────────────────────────────
        // MARK: Chef & Food
        // ─────────────────────────────────────────────────────────────────────
        case .chef:
            response = "👨‍🍳 **Chef Kai here, \(name)!**\n\n"

            if wantsMuscleBuild {
                response += "Muscle-building nutrition is all about **high protein + smart carbs + healthy fats**. Here's your power menu:\n\n"
                response += "**🥩 Muscle-Building Meals:**\n"
                response += "• **Breakfast:** 4-egg omelette with spinach, cheese & whole-grain toast (40g protein)\n"
                response += "• **Post-workout:** Protein shake + banana + oats smoothie (35g protein)\n"
                response += "• **Lunch:** Grilled chicken breast (200g) with sweet potato & broccoli (50g protein)\n"
                response += "• **Dinner:** Salmon fillet with quinoa, avocado & mixed greens (45g protein)\n"
                response += "• **Snack:** Greek yogurt with mixed nuts and honey (20g protein)\n\n"
                response += "**Daily targets for muscle gain:** ~1.6–2.2g protein per kg bodyweight, caloric surplus of ~300–500 kcal"
                if hasDiabetes { response += "\n\n**Note:** Since you manage diabetes, I've kept glycaemic index low. Swap sweet potato for cauliflower mash if your glucose runs high post-meal." }
            } else if wantsWeightLoss {
                response += "Let me plan meals that keep you **full, energised, and in a calorie deficit** without starving:\n\n"
                response += "**Fat-Loss Meals (~1,500–1,800 kcal):**\n"
                response += "• **Breakfast:** Veggie egg-white omelette with avocado (350 kcal, 28g protein)\n"
                response += "• **Lunch:** Turkey lettuce wraps with hummus & cucumber (400 kcal, 35g protein)\n"
                response += "• **Dinner:** Baked cod with roasted Mediterranean vegetables (450 kcal, 40g protein)\n"
                response += "• **Snack:** Celery & carrot sticks with cottage cheese (150 kcal, 15g protein)\n"
                if hasDiabetes { response += "\n**Note:** All meals are low-GI to keep your blood sugar stable while cutting calories." }
            } else {
                response += "I'd love to give you a detailed recipe tailored to your health profile"
                if hasDiabetes { response += " (keeping your blood sugar stable)" }
                if hasHypertension { response += " (with low sodium)" }
                response += ".\n\n**Quick personalised meal ideas for you:**\n"
                if hasDiabetes {
                    response += "• **Breakfast:** Greek yogurt with cinnamon, walnuts, and berries (GI: ~35)\n"
                    response += "• **Lunch:** Grilled chicken salad with olive oil, avocado, and mixed greens\n"
                    response += "• **Dinner:** Baked salmon with roasted vegetables and quinoa\n"
                    response += "• **Snack:** Apple slices with almond butter (stabilises blood sugar)\n"
                } else {
                    response += "• **Breakfast:** Overnight oats with chia seeds, banana, and honey\n"
                    response += "• **Lunch:** Mediterranean wrap with hummus, grilled vegetables, and feta\n"
                    response += "• **Dinner:** Stir-fried tofu with brown rice and sesame vegetables\n"
                    response += "• **Snack:** Mixed nuts and dried fruit\n"
                }
            }
            response += insightContext
            response += "\n\nOnce my AI engine reconnects, I can create complete recipes with exact portions and a weekly shopping list!"
            chips = ["Full meal plan", "Shopping list", "Different cuisine", "My nutrition"]

        // ─────────────────────────────────────────────────────────────────────
        // MARK: Fitness
        // ─────────────────────────────────────────────────────────────────────
        case .fitness:
            let steps = store.todaySteps
            let target = store.userProfile.targetSteps

            response = "**Coach Alex here, \(name)!**\n\n"

            if wantsMuscleBuild {
                response += "Let's get you on a **muscle-building programme**! Here's your starter plan:\n\n"
                response += "**4-Day Hypertrophy Split:**\n\n"
                response += "**Day 1 — Chest & Triceps:**\n"
                response += "• Bench press: 4 × 8–10\n"
                response += "• Incline dumbbell press: 3 × 10–12\n"
                response += "• Cable flyes: 3 × 12–15\n"
                response += "• Tricep dips: 3 × 10–12\n"
                response += "• Overhead tricep extension: 3 × 12\n\n"
                response += "**Day 2 — Back & Biceps:**\n"
                response += "• Deadlifts: 4 × 6–8\n"
                response += "• Pull-ups/Lat pulldown: 4 × 8–10\n"
                response += "• Bent-over rows: 3 × 10–12\n"
                response += "• Barbell curls: 3 × 10–12\n"
                response += "• Hammer curls: 3 × 12\n\n"
                response += "**Day 3 — Legs & Core:**\n"
                response += "• Squats: 4 × 8–10\n"
                response += "• Romanian deadlifts: 3 × 10–12\n"
                response += "• Leg press: 3 × 12–15\n"
                response += "• Walking lunges: 3 × 12 each leg\n"
                response += "• Plank: 3 × 45 seconds\n\n"
                response += "**Day 4 — Shoulders & Arms:**\n"
                response += "• Overhead press: 4 × 8–10\n"
                response += "• Lateral raises: 3 × 12–15\n"
                response += "• Face pulls: 3 × 15\n"
                response += "• Superset: curls + skull crushers: 3 × 12\n\n"
                response += "**Key principles:**\n"
                response += "• Progressive overload — increase weight/reps each week\n"
                response += "• Rest 60–90 seconds between sets\n"
                response += "• Sleep 7–9 hours for recovery\n"
                response += "• Eat 1.6–2.2g protein per kg bodyweight daily\n"
                if hasDiabetes { response += "\n**Note:** Monitor glucose before heavy lifts. Keep a fast-acting carb nearby." }
            } else if wantsWeightLoss {
                response += "Let's torch fat while preserving muscle! Here's your plan:\n\n"
                response += "**Fat-Loss Training Plan (5 days/week):**\n\n"
                response += "**Mon/Wed/Fri — Strength Circuit (30 min):**\n"
                response += "• 4 rounds of: 10 squats → 10 push-ups → 10 rows → 15 mountain climbers\n"
                response += "• 60-sec rest between rounds\n\n"
                response += "**Tue/Thu — Cardio Intervals (25 min):**\n"
                response += "• 5-min warm-up walk\n"
                response += "• 8 × (30-sec sprint / 90-sec walk)\n"
                response += "• 5-min cool-down stretch\n\n"
                response += "**Daily target:** Burn ~300–500 kcal through exercise + maintain calorie deficit\n"
                if hasDiabetes { response += "\n**Note:** Check glucose before and after workouts. Exercise can lower blood sugar rapidly." }
            } else {
                response += "Today you've done **\(steps) steps** "
                response += steps >= target ? "(target hit!)" : "(target: \(target) — \(target - steps) to go)"
                response += "\n\n"
                response += "**Quick workout based on your profile:**\n"
                response += "• 10-min brisk walk (great for blood sugar if after a meal)\n"
                response += "• 3 × 12 bodyweight squats\n"
                response += "• 3 × 10 push-ups (or wall push-ups)\n"
                response += "• 30-second plank\n"
                response += "• 5-min cool-down stretch\n"
            }
            response += insightContext
            response += "\n\nOnce my AI engine reconnects, I can build a full personalised training programme with progressive overload tracking!"
            chips = wantsMuscleBuild
                ? ["Muscle-building meals", "Track my lifts", "Supplement guide", "Home workout version"]
                : ["Full workout plan", "Walking plan", "Cardio plan", "My activity"]

        // ─────────────────────────────────────────────────────────────────────
        // MARK: Medical
        // ─────────────────────────────────────────────────────────────────────
        case .medical:
            response = "**Dr. Sage here, \(name).**\n\n"

            // Show relevant vitals
            var hasVitals = false
            if let g = store.glucoseReadings.sorted(by: { $0.date > $1.date }).first {
                response += "**Your latest glucose:** \(HealthStore.glucoseDisplayUK(g.value))"
                if g.value > 180 { response += " (elevated)" }
                else if g.value < 70 { response += " (low)" }
                else { response += " (normal)" }
                response += "\n"
                hasVitals = true
            }
            if let b = store.bpReadings.sorted(by: { $0.date > $1.date }).first {
                response += "**Your latest BP:** \(b.systolic)/\(b.diastolic) mmHg"
                if b.systolic > 140 || b.diastolic > 90 { response += " (high)" }
                else { response += " (normal)" }
                response += "\n"
                hasVitals = true
            }
            if hasVitals { response += "\n" }

            // Try to address the specific query
            if text.contains("suitable") || text.contains("safe") || text.contains("can i") || text.contains("should i") {
                response += "I understand you're asking about safety and suitability. Here's what I can tell you based on your health profile:\n\n"
                if hasDiabetes {
                    response += "**As someone managing \(p.diabetesType):**\n"
                    response += "• Always check food labels for glycaemic index and carb content\n"
                    response += "• Pair carbs with protein/fat to slow glucose spikes\n"
                    response += "• Monitor glucose before and after trying new foods or activities\n"
                    response += "• Consult your doctor before starting new supplements\n"
                }
                if hasHypertension {
                    response += "**With your blood pressure:**\n"
                    response += "• Keep sodium under 2,300mg/day (ideally 1,500mg)\n"
                    response += "• Avoid high-intensity activities without warm-up\n"
                    response += "• Stay hydrated — dehydration raises BP\n"
                }
                if !hasDiabetes && !hasHypertension {
                    response += "Based on your profile, most moderate activities and balanced foods should be fine. I'd recommend starting slowly with any new routine.\n"
                }
            } else {
                response += "I'd love to give you a thorough, personalised medical answer. "
                response += "Here's a general overview based on your profile:\n\n"
                if hasDiabetes { response += "• Managing **\(p.diabetesType)** — all advice is glucose-aware\n" }
                if hasHypertension { response += "• Monitoring **blood pressure** — prioritising heart-friendly recommendations\n" }
                if !goals.isEmpty { response += "• Your goals: \(goals.joined(separator: ", "))\n" }
            }

            response += insightContext
            response += "\n\n**Important:** If this is urgent, please call your GP, 111 (NHS helpline), or local emergency services."
            chips = ["My vitals", "My medications", "When to see a doctor", "Health summary"]

        // ─────────────────────────────────────────────────────────────────────
        // MARK: Nutrition
        // ─────────────────────────────────────────────────────────────────────
        case .nutrition:
            response = "**Maya here, \(name)!** Your nutrition specialist.\n\n"

            if wantsMuscleBuild {
                response += "Building muscle requires a **protein-rich, calorie-surplus** nutrition strategy:\n\n"
                response += "**Your Muscle-Building Nutrition Plan:**\n"
                response += "• **Protein:** 1.6–2.2g per kg bodyweight (e.g., 130–175g for 80kg person)\n"
                response += "• **Carbs:** 4–6g per kg bodyweight — fuel for heavy training\n"
                response += "• **Fats:** 0.8–1.2g per kg bodyweight — hormonal support\n"
                response += "• **Calorie surplus:** +300–500 kcal above maintenance\n\n"
                response += "**Best protein sources:**\n"
                response += "• Chicken breast (31g/100g), Eggs (6g each), Greek yogurt (10g/100g)\n"
                response += "• Salmon (25g/100g), Lentils (9g/100g), Whey protein (25g/scoop)\n\n"
                response += "**Timing matters:**\n"
                response += "• Pre-workout: Carbs + protein 1–2 hours before\n"
                response += "• Post-workout: Protein + fast carbs within 30–60 min\n"
                response += "• Before bed: Casein protein or cottage cheese (slow-release)\n"
                if hasDiabetes { response += "\n**Note:** With diabetes, build surplus carefully. Focus on low-GI carbs and monitor glucose around training." }
            } else if wantsWeightLoss {
                response += "Smart nutrition for fat loss while keeping energy up:\n\n"
                response += "**Your Fat-Loss Nutrition Framework:**\n"
                response += "• **Calorie deficit:** 300–500 kcal below maintenance (sustainable)\n"
                response += "• **Protein:** 1.6–2.0g per kg bodyweight (preserves muscle)\n"
                response += "• **Fibre:** 25–30g daily (keeps you full)\n"
                response += "• **Water:** 2–3 litres daily (often hunger is thirst)\n\n"
                response += "**High-satiety foods:**\n"
                response += "• Eggs, chicken, fish (high protein per calorie)\n"
                response += "• Leafy greens, broccoli, cauliflower (high volume, low cal)\n"
                response += "• Oats, sweet potato (slow-release energy)\n"
                response += "• Berries, apples (low-cal, high-fibre fruits)\n"
            } else {
                response += "Here's your personalised nutrition overview:\n\n"

                // Show recent nutrition data
                let recentNutrition = store.nutritionLogs.filter {
                    $0.date >= Calendar.current.date(byAdding: .day, value: -7, to: Date())!
                }
                if !recentNutrition.isEmpty {
                    let avgCal = recentNutrition.map { $0.calories }.reduce(0, +) / recentNutrition.count
                    response += "**Your 7-day average:** ~\(avgCal) kcal/day\n\n"
                }

                response += "**Daily nutrition targets:**\n"
                if hasDiabetes {
                    response += "• Focus on low-GI carbs (brown rice, quinoa, legumes)\n"
                    response += "• Pair carbs with protein to flatten glucose curve\n"
                    response += "• Limit refined sugars and white starches\n"
                    response += "• Aim for 5+ servings of non-starchy vegetables\n"
                } else {
                    response += "• Balanced plate: 1/2 vegetables, 1/4 protein, 1/4 whole grains\n"
                    response += "• 5+ portions of fruits and vegetables daily\n"
                    response += "• Healthy fats from olive oil, nuts, avocado, oily fish\n"
                    response += "• Minimise ultra-processed foods\n"
                }
                if hasHypertension {
                    response += "• **DASH diet approach:** potassium-rich foods, low sodium (<2,300mg)\n"
                    response += "• Bananas, spinach, sweet potatoes — natural BP regulators\n"
                }
            }
            response += insightContext
            chips = ["Supplement advice", "My nutrition data", "Food sources", "Macro calculator"]

        // ─────────────────────────────────────────────────────────────────────
        // MARK: Sleep Science
        // ─────────────────────────────────────────────────────────────────────
        case .sleep:
            response = "**Luna here, \(name)!** Your sleep scientist.\n\n"

            // Show sleep data if available
            let recentSleep = store.sleepEntries.sorted(by: { $0.date > $1.date })
            if let latest = recentSleep.first {
                response += "**Your latest sleep:** \(String(format: "%.1f", latest.duration)) hours"
                if latest.duration < 7 { response += " (below recommended 7–9 hours)" }
                else { response += " (good)" }
                response += "\n\n"
            }

            if text.contains("can't sleep") || text.contains("insomnia") || text.contains("trouble") {
                response += "Having trouble sleeping is really frustrating. Here are evidence-based strategies:\n\n"
                response += "**Immediate fixes (tonight):**\n"
                response += "• **4-7-8 breathing:** Inhale 4 sec → Hold 7 sec → Exhale 8 sec (repeat 4x)\n"
                response += "• **Body scan:** Mentally relax each muscle group head-to-toe\n"
                response += "• **Cool room:** Set temperature to 18–20°C (65–68°F)\n"
                response += "• **No screens:** Put phone away 30 min before bed\n\n"
                response += "**This week:**\n"
                response += "• Wake at the same time every day (even weekends)\n"
                response += "• No caffeine after 2 PM\n"
                response += "• Morning sunlight for 10–15 min (resets circadian clock)\n"
                response += "• Avoid heavy meals within 2 hours of bedtime\n"
            } else {
                response += "**Your sleep optimisation toolkit:**\n\n"
                response += "**Evening routine (wind down 1 hour before bed):**\n"
                response += "• Dim lights / use warm-toned lighting\n"
                response += "• Gentle stretching or yoga nidra (10 min)\n"
                response += "• Journaling or gratitude practice\n"
                response += "• Herbal tea: chamomile, valerian, or passionflower\n\n"
                response += "**Sleep hygiene fundamentals:**\n"
                response += "• Consistent sleep/wake times (circadian rhythm anchor)\n"
                response += "• Cool, dark, quiet bedroom\n"
                response += "• Reserve bed for sleep only\n"
                response += "• 7–9 hours for adults (non-negotiable for health)\n"
            }
            if hasDiabetes { response += "\n\n**Diabetes + sleep:** Poor sleep raises cortisol → increases insulin resistance. Prioritising sleep directly helps your glucose control." }
            response += insightContext
            chips = ["Sleep routine", "Bedtime tips", "My sleep data", "Natural sleep aids"]

        // ─────────────────────────────────────────────────────────────────────
        // MARK: Mental Wellness
        // ─────────────────────────────────────────────────────────────────────
        case .mentalWellness:
            response = "**Zen here, \(name).** I'm glad you reached out.\n\n"

            // Show stress data if available
            let recentStress = store.stressReadings.sorted(by: { $0.date > $1.date })
            if let latest = recentStress.first {
                response += "**Your latest stress level:** \(latest.level)/10"
                if latest.level >= 7 { response += " — let's work on bringing that down" }
                response += "\n\n"
            }

            if text.contains("stress") || text.contains("overwhelm") || text.contains("burnout") {
                response += "I hear you. Stress is your body's alarm system — let's turn down the volume.\n\n"
                response += "**Right now (2-minute reset):**\n"
                response += "1. **Box breathing:** Inhale 4 sec → Hold 4 sec → Exhale 4 sec → Hold 4 sec\n"
                response += "2. **5-4-3-2-1 grounding:** Name 5 things you see, 4 you can touch, 3 you hear, 2 you smell, 1 you taste\n\n"
                response += "**This week (stress management plan):**\n"
                response += "• 10-min daily walk in nature (cortisol drops 20%)\n"
                response += "• Progressive muscle relaxation before bed\n"
                response += "• Set 1 boundary (say 'no' to one thing)\n"
                response += "• Connect with someone you trust — even a 5-min call helps\n"
            } else if text.contains("anxious") || text.contains("anxiety") || text.contains("panic") || text.contains("worried") {
                response += "Anxiety can feel overwhelming, but you're not alone and there are proven tools:\n\n"
                response += "**Immediate relief:**\n"
                response += "• **Diaphragmatic breathing:** Slow belly breaths (6 per minute)\n"
                response += "• **Name the feeling:** \"I notice I'm feeling anxious\" (creates distance)\n"
                response += "• **Cold water:** Splash cold water on face (activates dive reflex, calms nervous system)\n\n"
                response += "**Building resilience:**\n"
                response += "• Regular exercise (natural anxiolytic — as effective as some medications)\n"
                response += "• Limit caffeine and alcohol (both amplify anxiety)\n"
                response += "• Structured worry time: 15 min/day to write worries, then close the notebook\n"
                response += "• Consider CBT (Cognitive Behavioural Therapy) — strongest evidence base\n"
            } else {
                response += "Taking care of your mental health is just as important as physical health.\n\n"
                response += "**Daily mental wellness habits:**\n"
                response += "• 5-min morning mindfulness or gratitude journaling\n"
                response += "• Regular movement (even a short walk lifts mood)\n"
                response += "• Social connection — reach out to someone daily\n"
                response += "• Digital detox — 1 hour before bed, no screens\n"
                response += "• Celebrate small wins — acknowledge your progress\n"
            }
            if hasDiabetes { response += "\n\n**Mind-body link:** Stress hormones raise blood glucose. Managing stress directly helps your diabetes control." }
            response += insightContext
            response += "\n\nIf you're in crisis, please reach out: Samaritans (116 123), Crisis Text Line (text HOME to 741741), or your local emergency services."
            chips = ["Guided breathing", "Mood journal", "My stress data", "Talk more"]

        // ─────────────────────────────────────────────────────────────────────
        // MARK: Personal Care
        // ─────────────────────────────────────────────────────────────────────
        case .personalCare:
            response = "**Cara here, \(name)!** Your personal care specialist.\n\n"

            if text.contains("skin") || text.contains("acne") || text.contains("moistur") || text.contains("skincare") {
                response += "Let me help you with your skincare:\n\n"
                response += "**Essential daily skincare routine:**\n"
                response += "• **Morning:** Gentle cleanser → Vitamin C serum → Moisturiser → SPF 30+ (non-negotiable!)\n"
                response += "• **Evening:** Double cleanse → Active treatment (retinol/AHA/BHA) → Hydrating serum → Night cream\n\n"
                response += "**For your health profile:**\n"
                if hasDiabetes {
                    response += "• Diabetes can cause dry, slow-healing skin — extra moisturising is key\n"
                    response += "• Check feet daily for cuts/blisters (diabetic skin care essential)\n"
                    response += "• Watch for darkening skin patches (acanthosis nigricans) — discuss with GP\n"
                } else {
                    response += "• Stay hydrated (2L water daily = better skin)\n"
                    response += "• Omega-3 fatty acids support skin barrier\n"
                    response += "• Sleep 7–9 hours — skin repairs during deep sleep\n"
                }
            } else if text.contains("hair") {
                response += "**Hair health essentials:**\n"
                response += "• Protein-rich diet (hair is made of keratin)\n"
                response += "• Biotin, zinc, iron — key hair nutrients\n"
                response += "• Gentle washing 2–3x/week (not daily)\n"
                response += "• Minimise heat styling\n"
                response += "• Scalp massage — improves blood flow to follicles\n"
            } else if text.contains("routine") || text.contains("self-care") || text.contains("self care") {
                response += "**Your personalised self-care blueprint:**\n\n"
                response += "**Morning (30 min):**\n"
                response += "• Hydrate (warm water + lemon)\n"
                response += "• Skincare routine (cleanse → serum → SPF)\n"
                response += "• 5-min stretch or mindfulness\n\n"
                response += "**Evening (30 min):**\n"
                response += "• Skincare (double cleanse → treatment → moisturise)\n"
                response += "• Gratitude journaling (3 things)\n"
                response += "• Screen-free wind-down\n"
            } else {
                response += "Personal care is health care. Here's what I focus on for your profile:\n\n"
                response += "• **Skin:** Daily SPF, gentle routine, hydration\n"
                response += "• **Oral health:** Brush 2x/day, floss daily, regular check-ups\n"
                response += "• **Posture:** Ergonomic setup, regular movement breaks\n"
                response += "• **Foot care:** " + (hasDiabetes ? "Extra important with diabetes — daily checks for cuts, proper footwear\n" : "Comfortable shoes, regular moisturising\n")
                response += "• **Mental self-care:** Boundaries, rest, social connection\n"
            }
            response += insightContext
            chips = ["Skincare routine", "Hair health", "Oral care", "Full self-care plan"]

        // ─────────────────────────────────────────────────────────────────────
        // MARK: General Health
        // ─────────────────────────────────────────────────────────────────────
        case .general:
            response = "**HealthSense here, \(name)!**\n\n"
            response += "Let me pull together everything I know about you:\n\n"

            // Health profile summary
            response += "**Your health snapshot:**\n"
            if hasDiabetes { response += "• Managing **\(p.diabetesType)** — all my advice is glucose-aware\n" }
            if hasHypertension { response += "• Monitoring **blood pressure** — heart-friendly focus\n" }
            if !goals.isEmpty { response += "• Your goals: **\(goals.joined(separator: ", "))**\n" }

            // Show latest vitals
            if let g = store.glucoseReadings.sorted(by: { $0.date > $1.date }).first {
                response += "• Latest glucose: \(HealthStore.glucoseDisplayUK(g.value))\n"
            }
            if let b = store.bpReadings.sorted(by: { $0.date > $1.date }).first {
                response += "• Latest BP: \(b.systolic)/\(b.diastolic) mmHg\n"
            }
            response += "• Steps today: \(store.todaySteps)/\(p.targetSteps)\n"

            response += "\n**I can help you with any of these:**\n"
            response += "• Medical questions — ask Dr. Sage\n"
            response += "• Nutrition advice — ask Maya\n"
            response += "• Fitness plans — ask Coach Alex\n"
            response += "• Recipes & meals — ask Chef Kai\n"
            response += "• Sleep help — ask Luna\n"
            response += "• Mental wellness — ask Zen\n"
            response += "• Personal care — ask Cara\n"

            if wantsMuscleBuild {
                response += "\n**For muscle building**, I'd suggest starting with Coach Alex for a training plan and Chef Kai for high-protein meals.\n"
            } else if wantsWeightLoss {
                response += "\n**For weight loss**, Coach Alex can design your training and Maya can set up your nutrition plan.\n"
            }

            response += insightContext
            response += "\n\nJust ask your question and I'll route you to the right expert!"
            chips = ["Workout plan", "Meal plan", "My health data", "Ask Dr. Sage"]
        }

        return (response, chips)
    }

    // MARK: - Feedback Processing

    func processFeedback(_ feedback: MessageFeedback, forQuery query: String, domain: HealthDomain) {
        if feedback == .thumbsUp {
            // Boost confidence of insights related to this interaction
            memory.boostInsights(for: query, domain: domain)
        } else if feedback == .thumbsDown {
            // Mark that our approach for this type of query needs adjustment
            memory.addInsight(UserInsight(
                id: UUID().uuidString,
                domain: domain,
                category: .conversationStyle,
                content: "User was not satisfied with response to: \(String(query.prefix(100))). Adjust approach.",
                confidence: 0.6,
                learnedAt: Date(),
                lastUsed: Date(),
                useCount: 1,
                isActive: true
            ))
        }
    }

    // MARK: - Agent Stats

    var stats: AgentStats {
        AgentStats(
            totalInteractions: memory.totalInteractions,
            totalInsights: memory.totalInsights,
            topDomains: memory.topDomains(limit: 3),
            confidenceLevel: confidenceLevel,
            activeSince: memory.firstInteractionDate
        )
    }
}

// MARK: - Agent Stats

struct AgentStats {
    let totalInteractions: Int
    let totalInsights: Int
    let topDomains: [(HealthDomain, Int)]
    let confidenceLevel: Double
    let activeSince: Date?

    var experienceLevel: String {
        switch totalInteractions {
        case 0..<10:   return "Novice"
        case 10..<50:  return "Learning"
        case 50..<200: return "Experienced"
        case 200..<500: return "Expert"
        default:        return "Master"
        }
    }

    var experienceIcon: String {
        switch totalInteractions {
        case 0..<10:   return "brain"
        case 10..<50:  return "brain.fill"
        case 50..<200: return "graduationcap.fill"
        case 200..<500: return "star.fill"
        default:        return "crown.fill"
        }
    }
}

// MARK: - Correlation Engine

/// Detects cross-domain health patterns from user data and provides research-backed knowledge.
enum CorrelationEngine {

    /// Analyse the user's data to detect cross-domain correlations.
    static func detectPatterns(store: HealthStore) -> [String] {
        var patterns: [String] = []
        let cal = Calendar.current
        let sevenDaysAgo = cal.date(byAdding: .day, value: -7, to: Date())!
        let fourteenDaysAgo = cal.date(byAdding: .day, value: -14, to: Date())!

        let recentGlucose = store.glucoseReadings.filter { $0.date >= sevenDaysAgo }
        let recentBP      = store.bpReadings.filter { $0.date >= sevenDaysAgo }
        let recentSleep   = store.sleepEntries.filter { $0.date >= sevenDaysAgo }
        let recentStress  = store.stressReadings.filter { $0.date >= sevenDaysAgo }
        let recentSteps   = store.stepEntries.filter { $0.date >= sevenDaysAgo }

        // 1. Sleep-Glucose correlation
        if recentGlucose.count >= 3 && recentSleep.count >= 3 {
            let poorSleepDays = Set(recentSleep.filter { $0.duration < 6.0 }.map { cal.startOfDay(for: $0.date) })
            let goodSleepDays = Set(recentSleep.filter { $0.duration >= 7.0 }.map { cal.startOfDay(for: $0.date) })

            let glucoseAfterPoorSleep = recentGlucose.filter { poorSleepDays.contains(cal.startOfDay(for: $0.date)) }
            let glucoseAfterGoodSleep = recentGlucose.filter { goodSleepDays.contains(cal.startOfDay(for: $0.date)) }

            if !glucoseAfterPoorSleep.isEmpty && !glucoseAfterGoodSleep.isEmpty {
                let avgPoor = glucoseAfterPoorSleep.map { $0.value }.reduce(0, +) / Double(glucoseAfterPoorSleep.count)
                let avgGood = glucoseAfterGoodSleep.map { $0.value }.reduce(0, +) / Double(glucoseAfterGoodSleep.count)
                if avgPoor > avgGood + 10 {
                    patterns.append("SLEEP-GLUCOSE: Glucose averages \(HealthStore.glucoseMmol(avgPoor)) mmol/L on poor sleep nights vs \(HealthStore.glucoseMmol(avgGood)) mmol/L on good sleep nights. Poor sleep appears to raise glucose by ~\(HealthStore.glucoseMmol(avgPoor - avgGood)) mmol/L.")
                }
            }
        }

        // 2. Stress-BP correlation
        if recentStress.count >= 3 && recentBP.count >= 3 {
            let highStressDays = Set(recentStress.filter { $0.level >= 7 }.map { cal.startOfDay(for: $0.date) })
            let lowStressDays  = Set(recentStress.filter { $0.level <= 4 }.map { cal.startOfDay(for: $0.date) })

            let bpHighStress = recentBP.filter { highStressDays.contains(cal.startOfDay(for: $0.date)) }
            let bpLowStress  = recentBP.filter { lowStressDays.contains(cal.startOfDay(for: $0.date)) }

            if !bpHighStress.isEmpty && !bpLowStress.isEmpty {
                let avgSysHigh = bpHighStress.map { $0.systolic }.reduce(0, +) / bpHighStress.count
                let avgSysLow  = bpLowStress.map { $0.systolic }.reduce(0, +) / bpLowStress.count
                if avgSysHigh > avgSysLow + 5 {
                    patterns.append("STRESS-BP: Systolic BP averages \(avgSysHigh) on high-stress days vs \(avgSysLow) on calm days. Stress management could lower BP by ~\(avgSysHigh - avgSysLow) mmHg.")
                }
            }
        }

        // 3. Activity-Glucose correlation (post-meal walks)
        if recentSteps.count >= 3 && recentGlucose.count >= 3 {
            let activeDays = Set(recentSteps.filter { $0.steps >= store.userProfile.targetSteps }.map { cal.startOfDay(for: $0.date) })
            let sedentaryDays = Set(recentSteps.filter { $0.steps < store.userProfile.targetSteps / 2 }.map { cal.startOfDay(for: $0.date) })

            let glucoseActive    = recentGlucose.filter { activeDays.contains(cal.startOfDay(for: $0.date)) }
            let glucoseSedentary = recentGlucose.filter { sedentaryDays.contains(cal.startOfDay(for: $0.date)) }

            if !glucoseActive.isEmpty && !glucoseSedentary.isEmpty {
                let avgActive = glucoseActive.map { $0.value }.reduce(0, +) / Double(glucoseActive.count)
                let avgSedentary = glucoseSedentary.map { $0.value }.reduce(0, +) / Double(glucoseSedentary.count)
                if avgSedentary > avgActive + 8 {
                    patterns.append("ACTIVITY-GLUCOSE: Glucose averages \(HealthStore.glucoseMmol(avgActive)) mmol/L on active days vs \(HealthStore.glucoseMmol(avgSedentary)) mmol/L on sedentary days. Walking appears to lower glucose by ~\(HealthStore.glucoseMmol(avgSedentary - avgActive)) mmol/L.")
                }
            }
        }

        // 4. Sleep-Stress correlation
        if recentSleep.count >= 3 && recentStress.count >= 3 {
            let poorSleepDays = Set(recentSleep.filter { $0.duration < 6.0 }.map { cal.startOfDay(for: $0.date) })
            let stressAfterPoorSleep = recentStress.filter { poorSleepDays.contains(cal.startOfDay(for: $0.date)) }
            if !stressAfterPoorSleep.isEmpty {
                let avgStress = stressAfterPoorSleep.map { $0.level }.reduce(0, +) / stressAfterPoorSleep.count
                if avgStress >= 6 {
                    patterns.append("SLEEP-STRESS: Average stress is \(avgStress)/10 on days following poor sleep (<6hrs). Better sleep hygiene may reduce stress levels.")
                }
            }
        }

        // 5. Meal timing and glucose spikes
        let afterMealGlucose = recentGlucose.filter { $0.context == .afterMeal }
        if afterMealGlucose.count >= 3 {
            let spikes = afterMealGlucose.filter { $0.value > store.userProfile.targetGlucoseMax }
            if Double(spikes.count) / Double(afterMealGlucose.count) > 0.5 {
                patterns.append("MEAL-GLUCOSE: \(Int(Double(spikes.count) / Double(afterMealGlucose.count) * 100))% of post-meal readings exceed target range. Consider portion control, lower-GI carbs, or a 15-min walk after meals.")
            }
        }

        // 6. Weight trend detection
        let twoWeekSteps = store.stepEntries.filter { $0.date >= fourteenDaysAgo }
        if twoWeekSteps.count >= 7 {
            let firstWeek = twoWeekSteps.filter { $0.date < sevenDaysAgo }
            let secondWeek = twoWeekSteps.filter { $0.date >= sevenDaysAgo }
            if !firstWeek.isEmpty && !secondWeek.isEmpty {
                let avgFirst  = firstWeek.map { $0.steps }.reduce(0, +) / firstWeek.count
                let avgSecond = secondWeek.map { $0.steps }.reduce(0, +) / secondWeek.count
                if avgSecond > avgFirst + 1000 {
                    patterns.append("ACTIVITY-TREND: Steps trending UP — from \(avgFirst)/day to \(avgSecond)/day this week. Great progress!")
                } else if avgFirst > avgSecond + 1000 {
                    patterns.append("ACTIVITY-TREND: Steps trending DOWN — from \(avgFirst)/day to \(avgSecond)/day this week. Encourage more movement.")
                }
            }
        }

        return patterns
    }

    /// Research-backed knowledge base for each health domain.
    /// These are evidence-based facts from medical research papers and clinical guidelines.
    static func researchKnowledgeBase(for domain: HealthDomain) -> String {
        switch domain {
        case .medical:
            return """
            Key research findings to reference when relevant:
            • NICE NG28: Type 2 diabetes — HbA1c target <48 mmol/mol (6.5%) for most adults
            • NICE NG136: Hypertension — target <140/90 (clinic) or <135/85 (home monitoring)
            • ADA Standards 2024: Time in range (3.9-10.0 mmol/L) >70% reduces complications
            • UKPDS: Each 1% reduction in HbA1c reduces microvascular complications by 37%
            • SPRINT trial: Intensive BP control (<120 systolic) reduces cardiovascular events by 25%
            • Metformin remains first-line for T2D; GLP-1 agonists show cardiovascular benefit
            """
        case .nutrition:
            return """
            Key research findings:
            • PREDIMED trial: Mediterranean diet reduces cardiovascular events by 30%
            • DASH diet: Reduces systolic BP by 8-14 mmHg in hypertensive patients
            • Fibre intake >25g/day improves glycaemic control (BMJ meta-analysis)
            • Omega-3 (EPA/DHA 2-4g/day) reduces triglycerides by 15-30%
            • Vitamin D deficiency (<30 nmol/L) linked to insulin resistance and depression
            • Intermittent fasting (16:8): improves insulin sensitivity in T2D (Lancet 2022)
            """
        case .fitness:
            return """
            Key research findings:
            • 150 min/week moderate exercise reduces all-cause mortality by 31% (WHO)
            • Post-meal walking (15 min) reduces glucose spike by 30-50% (Diabetologia)
            • Resistance training 2-3x/week improves insulin sensitivity by 15-25%
            • Exercise reduces systolic BP by 5-8 mmHg (equivalent to one antihypertensive drug)
            • 7,000-10,000 steps/day associated with 50-70% lower mortality risk
            • HIIT 3x/week matches moderate continuous exercise for HbA1c reduction
            """
        case .sleep:
            return """
            Key research findings:
            • Sleep <6hrs increases T2D risk by 28% (Diabetes Care meta-analysis)
            • Sleep deprivation raises cortisol, increasing insulin resistance by 25-30%
            • 7-9 hours is optimal for adults; <6 or >9 associated with higher mortality
            • Consistent sleep/wake times improve HRV and reduce BP by 3-5 mmHg
            • Blue light exposure 2hrs before bed delays melatonin onset by 3 hours
            • Sleep apnoea prevalence in T2D is 50-80%; screening recommended for HbA1c >7%
            """
        case .mentalWellness:
            return """
            Key research findings:
            • Chronic stress raises cortisol, increasing glucose by 1.1-2.2 mmol/L
            • Mindfulness-based stress reduction (MBSR) reduces HbA1c by 0.5% (meta-analysis)
            • Depression doubles the risk of T2D; screening recommended (PHQ-9)
            • 10 min daily meditation reduces anxiety scores by 30% (JAMA Internal Medicine)
            • Social isolation increases cardiovascular risk by 29% (Heart meta-analysis)
            • Box breathing (4-4-4-4) reduces acute stress cortisol within 5 minutes
            """
        case .chef, .personalCare, .general:
            return """
            Key nutrition and lifestyle research:
            • Cooking at home 5+ times/week associated with 28% lower T2D risk
            • Anti-inflammatory foods (turmeric, ginger, berries) reduce CRP markers
            • Gut microbiome diversity correlates with better metabolic health
            • Hydration (2-3L/day) improves kidney function and glucose metabolism
            • Oral health (gum disease) increases cardiovascular risk by 20%
            """
        }
    }
}
