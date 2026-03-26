//
//  AgentAnalytics.swift
//  body sense ai
//
//  Aggregates interaction data from all AI agents for CEO intelligence.
//  Nova (CEO Assistant) uses this to report on agent performance,
//  user trends, unanswered questions, and business insights.
//

import Foundation

// MARK: - Agent Analytics Report

struct AgentAnalyticsReport {

    // Per-agent stats
    var agentStats: [AgentStat] = []

    // Overall metrics
    var totalInteractions: Int = 0
    var averageQuality: Double = 0
    var reportPeriodDays: Int = 30

    // Top topics across all agents
    var trendingTopics: [TopicCount] = []

    // Failed/unanswered queries
    var unansweredQueries: [UnansweredQuery] = []

    // Customer suggestions extracted from queries
    var customerSuggestions: [String] = []

    // Report generation timestamp
    var generatedAt: Date = Date()
}

struct AgentStat: Identifiable {
    var id: String { domain.rawValue }
    let domain: HealthDomain
    let agentName: String
    let messageCount: Int
    let avgQuality: Double
    let topTopics: [String]
    let failedCount: Int
}

struct TopicCount: Identifiable {
    var id: String { topic }
    let topic: String
    let count: Int
    let domain: HealthDomain
}

struct UnansweredQuery: Identifiable {
    let id = UUID()
    let query: String
    let domain: HealthDomain
    let date: Date
}

// MARK: - Analytics Engine

enum AgentAnalyticsEngine {

    // Domain → friendly agent name mapping
    private static let agentNames: [HealthDomain: String] = [
        .medical: "Dr. Sage",
        .nutrition: "Maya (Nutritionist)",
        .fitness: "Coach Alex",
        .chef: "Chef Kai",
        .sleep: "Luna (Sleep Coach)",
        .mentalWellness: "Zen (Mindfulness)",
        .personalCare: "Personal Care",
        .general: "HealthSense"
    ]

    // Common stop words to filter from topic extraction
    private static let stopWords: Set<String> = [
        "the", "is", "at", "which", "on", "a", "an", "and", "or", "but",
        "in", "with", "to", "for", "of", "it", "my", "me", "i", "what",
        "how", "can", "do", "does", "should", "would", "could", "about",
        "this", "that", "from", "have", "has", "been", "was", "were",
        "are", "be", "will", "you", "your", "am", "not", "no", "yes",
        "please", "help", "need", "want", "know", "tell", "give", "make"
    ]

    /// Generate a full analytics report from AgentMemoryStore data
    static func generateReport(from memory: AgentMemoryStore, store: HealthStore) -> AgentAnalyticsReport {
        var report = AgentAnalyticsReport()

        let logs = memory.allLogs
        report.totalInteractions = logs.count

        // Calculate average quality
        let qualityLogs = logs.compactMap { $0.responseQuality }
        report.averageQuality = qualityLogs.isEmpty ? 0 : qualityLogs.reduce(0, +) / Double(qualityLogs.count)

        // Group by domain
        let grouped = Dictionary(grouping: logs, by: { $0.domain })

        // Per-agent stats
        for (domain, domainLogs) in grouped {
            let qualities = domainLogs.compactMap { $0.responseQuality }
            let avgQ = qualities.isEmpty ? 0.0 : qualities.reduce(0, +) / Double(qualities.count)
            let failed = domainLogs.filter { $0.feedback == "thumbsDown" || ($0.responseQuality ?? 1.0) < 0.3 }.count
            let topics = extractTopTopics(from: domainLogs, limit: 5)

            report.agentStats.append(AgentStat(
                domain: domain,
                agentName: agentNames[domain] ?? domain.rawValue,
                messageCount: domainLogs.count,
                avgQuality: avgQ,
                topTopics: topics.map { $0.topic },
                failedCount: failed
            ))
        }

        // Sort by message count descending
        report.agentStats.sort { $0.messageCount > $1.messageCount }

        // Trending topics across all agents
        report.trendingTopics = extractTopTopics(from: logs, limit: 15)

        // Unanswered queries
        report.unansweredQueries = logs
            .filter { $0.feedback == "thumbsDown" || ($0.responseQuality ?? 1.0) < 0.3 }
            .map { UnansweredQuery(query: $0.userQuery, domain: $0.domain, date: $0.timestamp) }
            .sorted { $0.date > $1.date }

        // Customer suggestions (queries containing goal/feature request patterns)
        let suggestionPatterns = ["wish", "feature", "add", "would be nice", "suggestion", "missing",
                                   "can't find", "doesn't have", "should have", "please add",
                                   "apple watch", "widget", "integration", "export", "share"]
        report.customerSuggestions = logs
            .filter { log in suggestionPatterns.contains(where: { log.userQuery.lowercased().contains($0) }) }
            .map { $0.userQuery }

        return report
    }

    /// Extract top topics from interaction logs using keyword frequency
    private static func extractTopTopics(from logs: [InteractionLog], limit: Int) -> [TopicCount] {
        var wordCounts: [String: (count: Int, domain: HealthDomain)] = [:]

        for log in logs {
            let words = log.userQuery.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count > 3 && !stopWords.contains($0) }

            for word in Set(words) { // Deduplicate per-query
                let existing = wordCounts[word] ?? (count: 0, domain: log.domain)
                wordCounts[word] = (count: existing.count + 1, domain: log.domain)
            }
        }

        return wordCounts
            .sorted { $0.value.count > $1.value.count }
            .prefix(limit)
            .map { TopicCount(topic: $0.key, count: $0.value.count, domain: $0.value.domain) }
    }

    // MARK: - Layer 6: Anonymised Pattern Extraction

    /// Extract anonymised health patterns from user insights and interaction logs.
    /// Strips all PII — no names, emails, exact dates, or specific locations.
    static func extractAnonymisedPatterns(from memory: AgentMemoryStore, store: HealthStore) -> [AnonymisedHealthPattern] {
        let insights = memory.allInsights.filter { $0.isActive && $0.confidence >= 0.6 }
        var patterns: [AnonymisedHealthPattern] = []

        // Anonymise age into buckets
        let age = store.userProfile.age
        let ageGroup: String = {
            switch age {
            case ..<20: return "under_20"
            case 20..<30: return "20-30"
            case 30..<40: return "30-40"
            case 40..<50: return "40-50"
            case 50..<60: return "50-60"
            case 60..<70: return "60-70"
            default: return "70+"
            }
        }()

        // Anonymise conditions (strip any personal identifiers)
        var conditions: [String] = []
        let diabetesType = store.userProfile.diabetesType.lowercased()
        if diabetesType.contains("type 1") { conditions.append("type1_diabetes") }
        else if diabetesType.contains("type 2") { conditions.append("type2_diabetes") }
        else if diabetesType.contains("pre") { conditions.append("pre_diabetes") }
        else if diabetesType.contains("gestational") { conditions.append("gestational_diabetes") }
        if store.userProfile.hasHypertension { conditions.append("hypertension") }

        // Extract patterns from trigger/pattern insights
        let triggerInsights = insights.filter { $0.category == .trigger || $0.category == .pattern || $0.category == .success }
        for insight in triggerInsights {
            let (category, trigger, outcome) = classifyInsight(insight)
            guard !category.isEmpty else { continue }

            patterns.append(AnonymisedHealthPattern(
                category: category,
                trigger: trigger,
                outcome: outcome,
                confidence: insight.confidence,
                sampleSize: 1,
                ageGroup: ageGroup,
                conditions: conditions
            ))
        }

        return patterns
    }

    /// Classify an insight into a category/trigger/outcome tuple for anonymised sharing.
    private static func classifyInsight(_ insight: UserInsight) -> (category: String, trigger: String, outcome: String) {
        let content = insight.content.lowercased()

        // Nutrition-glucose patterns
        let glucoseTriggers = ["rice", "bread", "sugar", "carb", "pasta", "cereal", "juice", "potato", "fruit"]
        for food in glucoseTriggers {
            if content.contains(food) && (content.contains("glucose") || content.contains("spike") || content.contains("sugar") || content.contains("blood")) {
                return ("nutrition_glucose", "high_carb_\(food)", content.contains("drop") || content.contains("lower") ? "glucose_decrease" : "glucose_spike")
            }
        }

        // Sleep-activity patterns
        if (content.contains("sleep") || content.contains("rest")) && (content.contains("exercise") || content.contains("walk") || content.contains("activity")) {
            return ("sleep_activity", "physical_activity", content.contains("better") || content.contains("improve") ? "sleep_improved" : "sleep_disrupted")
        }

        // Stress-glucose patterns
        if content.contains("stress") && (content.contains("glucose") || content.contains("sugar") || content.contains("spike")) {
            return ("stress_glucose", "stress_event", "glucose_spike")
        }

        // Exercise-glucose patterns
        if (content.contains("walk") || content.contains("exercise") || content.contains("run")) && (content.contains("glucose") || content.contains("sugar")) {
            return ("exercise_glucose", "post_meal_activity", content.contains("drop") || content.contains("lower") || content.contains("reduce") ? "glucose_decrease" : "glucose_spike")
        }

        // Medication patterns
        if content.contains("metformin") || content.contains("insulin") || content.contains("medication") {
            return ("medication_effect", "medication_timing", "symptom_change")
        }

        // Fallback — use domain
        return (insight.domain.rawValue.lowercased().replacingOccurrences(of: " ", with: "_"), "observed_pattern", "health_change")
    }

    /// Build a text summary for Nova's system prompt context
    static func buildContextForNova(report: AgentAnalyticsReport) -> String {
        var ctx = "AGENT ANALYTICS REPORT (Last \(report.reportPeriodDays) days)\n"
        ctx += "Total interactions: \(report.totalInteractions)\n"
        ctx += "Average quality score: \(String(format: "%.0f", report.averageQuality * 100))%\n\n"

        ctx += "PER-AGENT PERFORMANCE:\n"
        for stat in report.agentStats {
            ctx += "- \(stat.agentName): \(stat.messageCount) messages, "
            ctx += "\(String(format: "%.0f", stat.avgQuality * 100))% quality, "
            ctx += "\(stat.failedCount) failed. Top topics: \(stat.topTopics.joined(separator: ", "))\n"
        }

        if !report.unansweredQueries.isEmpty {
            ctx += "\nUNANSWERED QUERIES (\(report.unansweredQueries.count)):\n"
            for q in report.unansweredQueries.prefix(10) {
                ctx += "- [\(q.domain.rawValue)] \"\(q.query)\"\n"
            }
        }

        if !report.trendingTopics.isEmpty {
            ctx += "\nTRENDING TOPICS:\n"
            for t in report.trendingTopics.prefix(10) {
                ctx += "- \(t.topic) (\(t.count) mentions, via \(t.domain.rawValue))\n"
            }
        }

        if !report.customerSuggestions.isEmpty {
            ctx += "\nCUSTOMER SUGGESTIONS:\n"
            for s in report.customerSuggestions.prefix(5) {
                ctx += "- \"\(s)\"\n"
            }
        }

        return ctx
    }

    /// Build a context string from global patterns for enriching AI prompts.
    static func buildGlobalPatternContext(from patterns: [AnonymisedHealthPattern]) -> String {
        guard !patterns.isEmpty else { return "" }
        var ctx = "\nGLOBAL HEALTH PATTERNS (anonymised, from all users):\n"
        let grouped = Dictionary(grouping: patterns, by: { $0.category })
        for (category, categoryPatterns) in grouped.sorted(by: { $0.key < $1.key }) {
            ctx += "[\(category)]:\n"
            for p in categoryPatterns.prefix(5) {
                ctx += "  - \(p.trigger) -> \(p.outcome) (confidence: \(String(format: "%.0f", p.confidence * 100))%, sample: \(p.sampleSize) users)\n"
            }
        }
        return ctx
    }
}

// MARK: - Layer 6: Server-Side Anonymised Learning Service

enum AnonymisedLearningService {

    private static let railwayURL = "https://body-sense-ai-production.up.railway.app"

    // MARK: - Upload Anonymised Patterns

    /// Upload locally-extracted anonymised patterns to the backend.
    /// Only sends if user has opted in via `healthDataSharingEnabled`.
    static func uploadAnonymisedPatterns(store: HealthStore) async {
        // Gate: user must opt in
        guard store.userProfile.healthDataSharingEnabled else { return }

        let patterns = AgentAnalyticsEngine.extractAnonymisedPatterns(
            from: AgentMemoryStore.shared, store: store
        )
        guard !patterns.isEmpty else { return }

        guard let url = URL(string: "\(railwayURL)/ai/upload-patterns") else { return }

        // Validate no PII before sending
        let sanitised = patterns.map { pattern -> [String: Any] in
            [
                "category": pattern.category,
                "trigger": pattern.trigger,
                "outcome": pattern.outcome,
                "confidence": pattern.confidence,
                "sampleSize": pattern.sampleSize,
                "ageGroup": pattern.ageGroup,
                "conditions": pattern.conditions,
                "createdAt": ISO8601DateFormatter().string(from: pattern.createdAt)
            ]
        }

        guard let body = try? JSONSerialization.data(withJSONObject: ["patterns": sanitised]) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                print("[Layer6] Uploaded \(patterns.count) anonymised patterns")
            }
        } catch {
            print("[Layer6] Upload failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Download Global Patterns

    /// Download top global patterns from all users to improve AI responses.
    static func downloadGlobalPatterns(store: HealthStore) async {
        guard let url = URL(string: "\(railwayURL)/ai/global-patterns") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else { return }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let patternsArray = json["patterns"] as? [[String: Any]] else { return }

            let formatter = ISO8601DateFormatter()
            let patterns: [AnonymisedHealthPattern] = patternsArray.compactMap { dict in
                guard let category = dict["category"] as? String,
                      let trigger = dict["trigger"] as? String,
                      let outcome = dict["outcome"] as? String,
                      let confidence = dict["confidence"] as? Double,
                      let sampleSize = dict["sampleSize"] as? Int else { return nil }
                return AnonymisedHealthPattern(
                    category: category,
                    trigger: trigger,
                    outcome: outcome,
                    confidence: confidence,
                    sampleSize: sampleSize,
                    ageGroup: dict["ageGroup"] as? String ?? "unknown",
                    conditions: dict["conditions"] as? [String] ?? [],
                    createdAt: formatter.date(from: dict["createdAt"] as? String ?? "") ?? Date()
                )
            }

            await MainActor.run {
                store.cachedGlobalPatterns = patterns
                store.save()
            }
            print("[Layer6] Downloaded \(patterns.count) global patterns")
        } catch {
            print("[Layer6] Download failed: \(error.localizedDescription)")
        }
    }
}
