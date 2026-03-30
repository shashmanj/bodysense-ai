//
//  LifestylePillarKnowledge.swift
//  body sense ai
//
//  6-pillar lifestyle-health correlation framework. Each pillar has health
//  impact metrics, cross-pillar interactions, scoring criteria, and
//  improvement protocols. Two-tier knowledge for on-device and cloud.
//

import Foundation

// MARK: - Lifestyle Pillar Knowledge

enum LifestylePillarKnowledge {

    // MARK: - Public API

    /// Returns lifestyle pillar knowledge relevant to a health domain.
    static func pillarContext(for domain: HealthDomain, tier: HealthKnowledgeBase.Tier) -> String {
        let relevantPillars: [LifestylePillar]

        switch domain {
        case .nutrition:      relevantPillars = [.nutrition, .avoidance]
        case .fitness:        relevantPillars = [.exercise, .nutrition, .sleep]
        case .sleep:          relevantPillars = [.sleep, .stress, .exercise]
        case .mentalWellness: relevantPillars = [.stress, .socialConnection, .sleep, .exercise]
        case .medical:        relevantPillars = LifestylePillar.allCases
        case .chef:           relevantPillars = [.nutrition, .avoidance]
        case .personalCare:   relevantPillars = [.nutrition, .sleep, .stress]
        case .general:        relevantPillars = LifestylePillar.allCases
        }

        let pillarTexts = relevantPillars.compactMap { pillar -> String? in
            guard let data = pillarData[pillar] else { return nil }
            return tier == .compact ? data.compact : data.extended
        }

        guard !pillarTexts.isEmpty else { return "" }
        return "--- LIFESTYLE PILLAR FRAMEWORK ---\n" + pillarTexts.joined(separator: "\n\n")
    }

    /// Compute cross-pillar insights based on user's health data.
    static func crossPillarInsights(store: HealthStore) -> [String] {
        var insights: [String] = []
        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!

        // Sleep → Glucose correlation
        let recentSleep = store.sleepEntries.filter { $0.date >= sevenDaysAgo }
        let recentGlucose = store.glucoseReadings.filter { $0.date >= sevenDaysAgo }
        if !recentSleep.isEmpty && !recentGlucose.isEmpty {
            let avgSleep = recentSleep.map(\.duration).reduce(0, +) / Double(recentSleep.count)
            if avgSleep < 6 {
                insights.append("SLEEP→GLUCOSE: Average sleep \(String(format: "%.1f", avgSleep))hrs this week — poor sleep (<7hrs) typically raises fasting glucose by 0.5-1.5 mmol/L and reduces insulin sensitivity 20-40%.")
            }
        }

        // Stress → BP correlation
        let recentStress = store.stressReadings.filter { $0.date >= sevenDaysAgo }
        let recentBP = store.bpReadings.filter { $0.date >= sevenDaysAgo }
        if !recentStress.isEmpty && !recentBP.isEmpty {
            let avgStress = recentStress.map { Double($0.level) }.reduce(0, +) / Double(recentStress.count)
            if avgStress > 6 {
                let avgSystolic = recentBP.map(\.systolic).reduce(0, +) / recentBP.count
                insights.append("STRESS→BP: Average stress \(String(format: "%.1f", avgStress))/10 this week with avg systolic \(avgSystolic)mmHg. High chronic stress can raise systolic BP 5-15 mmHg via cortisol and sympathetic activation.")
            }
        }

        // Exercise → Sleep correlation
        let recentSteps = store.stepEntries.filter { $0.date >= sevenDaysAgo }
        if !recentSteps.isEmpty && !recentSleep.isEmpty {
            let avgSteps = recentSteps.map(\.steps).reduce(0, +) / recentSteps.count
            let avgSleep = recentSleep.map(\.duration).reduce(0, +) / Double(recentSleep.count)
            if avgSteps < 5000 && avgSleep < 7 {
                insights.append("EXERCISE→SLEEP: Low activity (\(avgSteps) steps/day avg) combined with poor sleep (\(String(format: "%.1f", avgSleep))hrs). Regular exercise (especially 4-6hrs before bed) improves sleep quality by 65% and reduces sleep onset time.")
            }
        }

        // Nutrition → Stress (via caffeine/sugar patterns)
        let recentNutrition = store.nutritionLogs.filter { $0.date >= sevenDaysAgo }
        if !recentNutrition.isEmpty && !recentStress.isEmpty {
            let avgStress = recentStress.map { Double($0.level) }.reduce(0, +) / Double(recentStress.count)
            if avgStress > 5 {
                insights.append("NUTRITION→STRESS: Consider nutrition's role in stress management. Magnesium-rich foods (dark leafy greens, nuts, seeds), omega-3 fatty acids, and fermented foods support stress resilience via the gut-brain axis.")
            }
        }

        // Compound risk detection
        let poorSleep = recentSleep.isEmpty || (recentSleep.map(\.duration).reduce(0, +) / Double(max(recentSleep.count, 1))) < 6
        let highStress = !recentStress.isEmpty && (recentStress.map { Double($0.level) }.reduce(0, +) / Double(recentStress.count)) > 7
        let lowActivity = recentSteps.isEmpty || (recentSteps.map(\.steps).reduce(0, +) / max(recentSteps.count, 1)) < 4000

        if poorSleep && highStress && lowActivity {
            insights.append("⚠️ COMPOUND RISK: Poor sleep + high stress + low activity detected this week. This combination significantly increases CVD risk, impairs glucose regulation, and weakens immune function. Prioritise: 1) Sleep hygiene tonight 2) 15-min walk today 3) 5-min breathing exercise.")
        }

        return insights
    }

    /// Score a user's lifestyle pillars based on their health data.
    static func computeScores(store: HealthStore) -> LifestylePillarScores {
        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!

        var scores: [LifestylePillarScore] = []

        // NUTRITION SCORE
        let nutritionLogs = store.nutritionLogs.filter { $0.date >= sevenDaysAgo }
        let nutritionScore: Double
        let nutritionTrend: String
        let nutritionInsight: String
        let nutritionRec: String

        if nutritionLogs.isEmpty {
            nutritionScore = 0
            nutritionTrend = "unknown"
            nutritionInsight = "No nutrition data logged this week"
            nutritionRec = "Start logging your meals to get personalised insights"
        } else {
            let daysLogged = Set(nutritionLogs.map { calendar.startOfDay(for: $0.date) }).count
            nutritionScore = min(100, Double(daysLogged) / 7.0 * 70 + 30) // Base 30 for logging, up to 100
            nutritionTrend = daysLogged >= 5 ? "stable" : "improving"
            nutritionInsight = "Logged nutrition on \(daysLogged)/7 days this week"
            nutritionRec = daysLogged < 5 ? "Try to log meals consistently for better AI insights" : "Great consistency! Focus on meeting your protein targets"
        }
        scores.append(LifestylePillarScore(pillar: .nutrition, score: nutritionScore, trend: nutritionTrend, topInsight: nutritionInsight, recommendation: nutritionRec))

        // EXERCISE SCORE
        let steps = store.stepEntries.filter { $0.date >= sevenDaysAgo }
        let exerciseScore: Double
        let exerciseTrend: String
        let exerciseInsight: String
        let exerciseRec: String

        if steps.isEmpty {
            exerciseScore = 0
            exerciseTrend = "unknown"
            exerciseInsight = "No activity data this week"
            exerciseRec = "Connect Apple Health or log steps manually"
        } else {
            let avgSteps = steps.map(\.steps).reduce(0, +) / max(steps.count, 1)
            exerciseScore = min(100, Double(avgSteps) / 10000.0 * 100)
            exerciseTrend = avgSteps >= 7500 ? "stable" : avgSteps >= 5000 ? "improving" : "declining"
            exerciseInsight = "Averaging \(avgSteps) steps/day this week"
            exerciseRec = avgSteps < 7500 ? "Aim for 7,500+ steps daily — even a 15-min walk after meals helps" : "Excellent activity level! Consider adding resistance training 2x/week"
        }
        scores.append(LifestylePillarScore(pillar: .exercise, score: exerciseScore, trend: exerciseTrend, topInsight: exerciseInsight, recommendation: exerciseRec))

        // SLEEP SCORE
        let sleepEntries = store.sleepEntries.filter { $0.date >= sevenDaysAgo }
        let sleepScore: Double
        let sleepTrend: String
        let sleepInsight: String
        let sleepRec: String

        if sleepEntries.isEmpty {
            sleepScore = 0
            sleepTrend = "unknown"
            sleepInsight = "No sleep data this week"
            sleepRec = "Track your sleep for personalised insights"
        } else {
            let avgDuration = sleepEntries.map(\.duration).reduce(0, +) / Double(sleepEntries.count)
            sleepScore = min(100, avgDuration / 8.0 * 100)
            sleepTrend = avgDuration >= 7 ? "stable" : avgDuration >= 6 ? "improving" : "declining"
            sleepInsight = "Averaging \(String(format: "%.1f", avgDuration))hrs sleep this week"
            sleepRec = avgDuration < 7 ? "Aim for 7-9 hours. Try a consistent bedtime and avoid screens 1hr before bed" : "Good sleep duration! Focus on sleep quality — cool room, dark, quiet"
        }
        scores.append(LifestylePillarScore(pillar: .sleep, score: sleepScore, trend: sleepTrend, topInsight: sleepInsight, recommendation: sleepRec))

        // STRESS SCORE (inverted — lower stress = higher score)
        let stressReadings = store.stressReadings.filter { $0.date >= sevenDaysAgo }
        let stressScore: Double
        let stressTrend: String
        let stressInsight: String
        let stressRec: String

        if stressReadings.isEmpty {
            stressScore = 50 // Neutral
            stressTrend = "unknown"
            stressInsight = "No stress data logged this week"
            stressRec = "Log your stress levels to understand patterns"
        } else {
            let avgStress = stressReadings.map { Double($0.level) }.reduce(0, +) / Double(stressReadings.count)
            stressScore = max(0, min(100, (10 - avgStress) / 10.0 * 100))
            stressTrend = avgStress <= 4 ? "stable" : avgStress <= 6 ? "improving" : "declining"
            stressInsight = "Average stress \(String(format: "%.1f", avgStress))/10 this week"
            stressRec = avgStress > 5 ? "Try 4-7-8 breathing: inhale 4s, hold 7s, exhale 8s. Just 3 cycles can reduce cortisol" : "Well managed stress levels. Keep up your current practices"
        }
        scores.append(LifestylePillarScore(pillar: .stress, score: stressScore, trend: stressTrend, topInsight: stressInsight, recommendation: stressRec))

        // SOCIAL CONNECTION SCORE (based on mindfulness sessions as proxy)
        let mindful = store.mindfulSessions.filter { $0.date >= sevenDaysAgo }
        let socialScore = min(100, Double(mindful.count) * 15 + 20) // Base 20, each session +15
        scores.append(LifestylePillarScore(
            pillar: .socialConnection,
            score: socialScore,
            trend: mindful.count >= 3 ? "stable" : "improving",
            topInsight: mindful.count > 0 ? "\(mindful.count) mindfulness sessions this week" : "No mindfulness sessions logged",
            recommendation: mindful.count < 3 ? "Try scheduling 10 minutes of mindfulness daily — even a short walk in nature counts" : "Great mindfulness practice! Social connection is equally important — reach out to someone today"
        ))

        // AVOIDANCE SCORE (based on absence of negative markers)
        let avoidanceScore: Double = 70 // Default — would be calculated from alcohol, smoking, ultra-processed food logs
        scores.append(LifestylePillarScore(
            pillar: .avoidance,
            score: avoidanceScore,
            trend: "stable",
            topInsight: "Avoidance score based on harmful habit tracking",
            recommendation: "Reduce ultra-processed foods, limit alcohol to 14 units/week, avoid smoking"
        ))

        let overall = scores.map(\.score).reduce(0, +) / Double(max(scores.count, 1))
        return LifestylePillarScores(scores: scores, overallScore: overall)
    }

    // MARK: - Pillar Data

    private struct PillarPair {
        let compact: String
        let extended: String
    }

    private static let pillarData: [LifestylePillar: PillarPair] = [

        .nutrition: PillarPair(
            compact: """
            NUTRITION PILLAR: Diet quality affects every health marker. Mediterranean diet reduces CVD 30%. \
            Fibre >30g/day improves glucose, gut health, and satiety. Ultra-processed foods increase \
            all-cause mortality 62%. Meal timing matters: eating within 10-12hr window improves metabolic health.
            """,
            extended: """
            NUTRITION PILLAR — HEALTH IMPACTS:

            DIRECT HEALTH CORRELATIONS:
            • Diet quality → CVD risk: Mediterranean diet reduces events by 30% (PREDIMED)
            • Fibre → Glucose: Each 10g fibre increase reduces T2D risk by 25%
            • Sodium → BP: Reducing from 10g to 5g/day = 5-7 mmHg systolic reduction
            • Ultra-processed foods → Mortality: 10% increase in UPF = 14% higher mortality (BMJ 2019)
            • Omega-3 → Inflammation: 2g/day EPA+DHA reduces CRP by 30%

            CROSS-PILLAR INTERACTIONS:
            • Nutrition → Sleep: Tryptophan-rich foods (turkey, milk, bananas) support melatonin production
            • Nutrition → Stress: Magnesium deficiency worsens anxiety; gut microbiome affects mood via vagus nerve
            • Nutrition → Exercise: Protein timing within 2hrs of exercise optimises recovery
            • Nutrition → Avoidance: High-sugar diet increases alcohol cravings; gut dysbiosis drives UPF cravings
            """
        ),

        .exercise: PillarPair(
            compact: """
            EXERCISE PILLAR: 150min/wk moderate aerobic + 2 resistance sessions (WHO). \
            Post-meal walking 15min reduces glucose 30-50%. Each 2000 steps/day reduces all-cause mortality 10%. \
            Exercise is as effective as medication for mild-moderate depression. Reduces BP 5-8 mmHg.
            """,
            extended: """
            EXERCISE PILLAR — HEALTH IMPACTS:

            DIRECT HEALTH CORRELATIONS:
            • Steps → Mortality: Each 2000 steps/day reduces all-cause mortality ~10% (up to 10,000)
            • Exercise → Glucose: 15-min post-meal walk reduces glucose spike 30-50%
            • Exercise → BP: Regular exercise reduces systolic 5-8 mmHg
            • Exercise → Mental health: As effective as SSRIs for mild-moderate depression
            • Resistance training → Sarcopenia: Preserves muscle mass, prevents falls in elderly
            • HIIT → VO2max: Superior to steady-state for cardiovascular fitness

            CROSS-PILLAR INTERACTIONS:
            • Exercise → Sleep: 150min/week improves sleep quality 65% (meta-analysis). Best 4-6hrs before bed.
            • Exercise → Stress: Single bout reduces cortisol for 24hrs; regular exercise builds stress resilience
            • Exercise → Nutrition: Exercise increases insulin sensitivity for 24-48hrs; post-exercise meal timing critical
            • Exercise → Social: Group exercise adds social connection benefit; adherence 26% higher vs solo
            """
        ),

        .sleep: PillarPair(
            compact: """
            SLEEP PILLAR: 7-9hrs optimal for adults. <6hrs increases T2D risk 28%, CVD risk 48%. \
            Sleep quality matters: deep sleep (N3) for physical repair, REM for memory/emotion. \
            Circadian rhythm: consistent bed/wake times ±30min. Blue light exposure 2hrs before bed \
            delays melatonin by 90min.
            """,
            extended: """
            SLEEP PILLAR — HEALTH IMPACTS:

            DIRECT HEALTH CORRELATIONS:
            • Duration → T2D: <6hrs increases risk 28%; <5hrs increases risk 48%
            • Duration → CVD: <6hrs increases risk 48% (Cappuccio meta-analysis, 15 studies)
            • Duration → Obesity: Short sleep increases ghrelin 15% and reduces leptin 15%
            • Quality → Immunity: One night of poor sleep reduces NK cell activity by 70%
            • Deep sleep → Growth hormone: 75% of daily GH released during N3 sleep

            SLEEP ARCHITECTURE:
            • N1 (Light): 5% — transition stage
            • N2 (Core): 45% — memory consolidation, heart rate/temp drop
            • N3 (Deep/SWS): 25% — physical repair, growth hormone, immune function
            • REM: 25% — emotional processing, memory consolidation, dreaming

            CROSS-PILLAR INTERACTIONS:
            • Sleep → Glucose: Poor sleep reduces insulin sensitivity 20-40% the next day
            • Sleep → Stress: Sleep deprivation increases cortisol 37% and amygdala reactivity 60%
            • Sleep → Exercise: Poor sleep reduces exercise performance 20-30% and increases injury risk
            • Sleep → Nutrition: Sleep-deprived people consume 385 extra calories/day on average
            """
        ),

        .stress: PillarPair(
            compact: """
            STRESS PILLAR: Chronic stress raises cortisol → increases BP 5-15mmHg, impairs glucose \
            regulation, weakens immunity. HRV is best biomarker. 4-7-8 breathing reduces cortisol 14-28%. \
            Ashwagandha 300mg: cortisol reduction 14-28% (RCTs). Nature exposure 20min reduces cortisol 21%.
            """,
            extended: """
            STRESS PILLAR — HEALTH IMPACTS:

            DIRECT HEALTH CORRELATIONS:
            • Chronic stress → BP: Sustained cortisol raises systolic 5-15 mmHg
            • Chronic stress → Glucose: Cortisol increases hepatic glucose output; impairs insulin sensitivity
            • Chronic stress → Immunity: Chronic cortisol suppresses lymphocyte proliferation
            • Chronic stress → CVD: Doubles heart attack risk (INTERHEART study)
            • Chronic stress → Gut: Increases permeability (leaky gut), alters microbiome

            BIOMARKERS:
            • HRV (Heart Rate Variability): Best real-time stress indicator; higher = more resilient
            • Cortisol: Salivary cortisol follows diurnal curve; should be highest AM, lowest PM
            • Resting heart rate: Elevated RHR suggests sympathetic dominance

            EVIDENCE-BASED INTERVENTIONS:
            • 4-7-8 breathing: 3 cycles reduces acute cortisol — inhale 4s, hold 7s, exhale 8s
            • Box breathing: 4-4-4-4 pattern — Navy SEAL stress management technique
            • Ashwagandha (KSM-66): 300-600mg/day — cortisol reduction 14-28% in 8 weeks (RCTs)
            • Nature exposure: 20 min in green space reduces cortisol 21% (Frontiers in Psychology 2019)
            • Mindfulness meditation: 8 weeks MBSR reduces cortisol 13%, improves HRV
            • Progressive muscle relaxation: systematic tension/release of muscle groups

            CROSS-PILLAR INTERACTIONS:
            • Stress → Sleep: Cortisol suppresses melatonin; high evening stress delays sleep onset
            • Stress → Nutrition: Cortisol increases cravings for high-fat, high-sugar foods
            • Stress → Exercise: Moderate exercise reduces cortisol; but overtraining increases it
            • Stress → Social: Strong social support reduces cortisol response by 50%
            """
        ),

        .socialConnection: PillarPair(
            compact: """
            SOCIAL CONNECTION PILLAR: Loneliness increases mortality risk 26% (equivalent to 15 cigarettes/day). \
            Strong social ties reduce CVD risk 29%. Social support reduces cortisol response 50%. \
            Group activities improve adherence to health goals by 26%.
            """,
            extended: """
            SOCIAL CONNECTION PILLAR — HEALTH IMPACTS:

            DIRECT HEALTH CORRELATIONS:
            • Loneliness → Mortality: 26% increased risk (Holt-Lunstad meta-analysis, 3.4M people)
            • Social isolation → CVD: 29% increased risk of coronary events
            • Social isolation → Dementia: 50% increased risk (Lancet Commission)
            • Social support → Immunity: Strong ties improve vaccine response and reduce infection severity
            • Social eating → Nutrition: People eat more varied, nutritious meals when eating with others

            INTERVENTIONS:
            • Regular social meals (eating with others improves diet quality)
            • Group exercise (adherence 26% higher; added mental health benefit)
            • Volunteering (reduces depression 22%; improves sense of purpose)
            • Community health challenges (gamification + social accountability)
            • Digital connection (video calls provide 70% of in-person benefit for isolated individuals)
            """
        ),

        .avoidance: PillarPair(
            compact: """
            AVOIDANCE PILLAR: Smoking = #1 preventable cause of death. Alcohol >14 units/week increases \
            cancer and liver disease risk. Ultra-processed foods (NOVA 4) drive obesity and CVD. \
            Excess sitting >8hrs/day increases mortality 60% even with exercise.
            """,
            extended: """
            AVOIDANCE PILLAR — HARM REDUCTION:

            SMOKING:
            • #1 preventable cause of death globally (8M/year WHO)
            • Quitting at any age provides benefit; 10-year cessation halves CVD risk
            • NRT + behavioural support: best evidence-based approach (NICE PH10)
            • Vaping: harm reduction tool (not risk-free), only for existing smokers

            ALCOHOL:
            • UK guideline: ≤14 units/week spread over 3+ days
            • 1 unit = 10ml pure alcohol = half pint beer, small wine, single spirit
            • >14 units/week: increased risk of liver disease, cancer (breast, bowel, liver, throat), CVD
            • Alcohol + medications: potentiates sedation, liver toxicity, BP elevation

            ULTRA-PROCESSED FOODS (NOVA 4):
            • >50% of UK energy intake is ultra-processed (NDNS)
            • 10% increase in UPF consumption → 14% higher all-cause mortality
            • Mechanism: high sugar, salt, fat, additives; low fibre, micronutrients
            • Examples: ready meals, crisps, sugary cereals, instant noodles, fizzy drinks

            SEDENTARY BEHAVIOUR:
            • >8hrs sitting/day: 60% higher mortality risk (even with exercise)
            • Break every 30 min: stand, walk, stretch for 2-3 minutes
            • Standing desks: reduce sitting time but not a replacement for exercise
            """
        ),
    ]
}
