//
//  AgentMemoryStore.swift
//  body sense ai
//
//  Persistent learning memory for the HealthSense AI Agent.
//  Stores user insights, interaction patterns, and domain expertise
//  that persists across app sessions and grows over time.
//
//  This is what makes the agent LEARN — it remembers food preferences,
//  health triggers, successful strategies, and conversation patterns.
//

import Foundation

// MARK: - Agent Memory Store

class AgentMemoryStore {

    static let shared = AgentMemoryStore()

    // MARK: - Per-User Storage Keys

    /// Current user ID for scoping memory. Updated on sign-in, cleared on sign-out.
    private var currentUserID: String = "anonymous"

    private var insightsKey: String     { "healthsense_agent_insights_\(currentUserID)" }
    private var interactionsKey: String { "healthsense_agent_interactions_\(currentUserID)" }
    private var domainStatsKey: String  { "healthsense_agent_domain_stats_\(currentUserID)" }
    private var firstDateKey: String    { "healthsense_agent_first_date_\(currentUserID)" }

    private let defaults = UserDefaults.standard

    // MARK: - In-Memory Cache

    private var cachedInsights: [UserInsight]?
    private var cachedLogs: [InteractionLog]?
    private var cachedDomainCounts: [String: Int]?

    private init() {}

    /// Call on sign-in to scope all memory to the current user.
    func setUser(_ userID: String?) {
        let newID = userID ?? "anonymous"
        guard newID != currentUserID else { return }
        // Flush caches so next access reads the new user's data
        cachedInsights = nil
        cachedLogs = nil
        cachedDomainCounts = nil
        currentUserID = newID
    }

    // MARK: - Insights CRUD

    var allInsights: [UserInsight] {
        if let cached = cachedInsights { return cached }
        guard let data = defaults.data(forKey: insightsKey),
              let decoded = try? JSONDecoder().decode([UserInsight].self, from: data) else {
            return []
        }
        cachedInsights = decoded
        return decoded
    }

    var totalInsights: Int { allInsights.count }

    func addInsight(_ insight: UserInsight) {
        var insights = allInsights

        // Deduplicate — check for similar content
        let isDuplicate = insights.contains { existing in
            existing.category == insight.category &&
            existing.domain == insight.domain &&
            contentSimilarity(existing.content, insight.content) > 0.7
        }

        if isDuplicate {
            // Boost existing similar insight instead
            if let idx = insights.firstIndex(where: {
                $0.category == insight.category &&
                $0.domain == insight.domain &&
                contentSimilarity($0.content, insight.content) > 0.7
            }) {
                insights[idx].useCount += 1
                insights[idx].lastUsed = Date()
                insights[idx].confidence = min(1.0, insights[idx].confidence + 0.05)
            }
        } else {
            insights.append(insight)
        }

        // Keep max 200 insights — prune oldest low-confidence ones
        if insights.count > 200 {
            insights.sort { ($0.confidence * Double($0.useCount)) > ($1.confidence * Double($1.useCount)) }
            insights = Array(insights.prefix(200))
        }

        saveInsights(insights)
    }

    func relevantInsights(for query: String, domain: HealthDomain, limit: Int = 10) -> [UserInsight] {
        let queryWords = Set(query.lowercased().split(separator: " ").map(String.init))
        let insights = allInsights.filter { $0.isActive }

        // Score each insight by relevance
        let scored = insights.map { insight -> (UserInsight, Double) in
            var score = 0.0

            // Domain match
            if insight.domain == domain { score += 3.0 }

            // Word overlap
            let insightWords = Set(insight.content.lowercased().split(separator: " ").map(String.init))
            let overlap = queryWords.intersection(insightWords).count
            score += Double(overlap) * 1.5

            // Recency boost
            let daysSince = Calendar.current.dateComponents([.day], from: insight.lastUsed, to: Date()).day ?? 0
            if daysSince < 7 { score += 2.0 }
            else if daysSince < 30 { score += 1.0 }

            // Confidence and usage boost
            score += insight.confidence * 2.0
            score += min(Double(insight.useCount) * 0.3, 3.0)

            // Category priority
            switch insight.category {
            case .allergy: score += 5.0    // Allergies always relevant
            case .condition: score += 4.0
            case .goal: score += 3.0
            case .trigger: score += 3.0
            case .preference: score += 2.0
            case .dislike: score += 2.0
            default: break
            }

            return (insight, score)
        }

        return scored
            .filter { $0.1 > 1.0 }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { $0.0 }
    }

    func boostInsights(for query: String, domain: HealthDomain) {
        var insights = allInsights
        let queryWords = Set(query.lowercased().split(separator: " ").map(String.init))

        for i in insights.indices {
            let insightWords = Set(insights[i].content.lowercased().split(separator: " ").map(String.init))
            if insights[i].domain == domain && !queryWords.intersection(insightWords).isEmpty {
                insights[i].confidence = min(1.0, insights[i].confidence + 0.1)
                insights[i].useCount += 1
                insights[i].lastUsed = Date()
            }
        }

        saveInsights(insights)
    }

    private func saveInsights(_ insights: [UserInsight]) {
        cachedInsights = insights
        if let data = try? JSONEncoder().encode(insights) {
            defaults.set(data, forKey: insightsKey)
        }
    }

    // MARK: - Interaction Logs

    var allLogs: [InteractionLog] {
        if let cached = cachedLogs { return cached }
        guard let data = defaults.data(forKey: interactionsKey),
              let decoded = try? JSONDecoder().decode([InteractionLog].self, from: data) else {
            return []
        }
        cachedLogs = decoded
        return decoded
    }

    var totalInteractions: Int { allLogs.count }

    var firstInteractionDate: Date? {
        if let timestamp = defaults.object(forKey: firstDateKey) as? Date {
            return timestamp
        }
        return allLogs.min(by: { $0.timestamp < $1.timestamp })?.timestamp
    }

    func logInteraction(_ log: InteractionLog) {
        var logs = allLogs
        logs.append(log)

        // Keep max 500 logs
        if logs.count > 500 {
            logs = Array(logs.suffix(500))
        }

        cachedLogs = logs
        if let data = try? JSONEncoder().encode(logs) {
            defaults.set(data, forKey: interactionsKey)
        }

        // Set first interaction date
        if defaults.object(forKey: firstDateKey) == nil {
            defaults.set(Date(), forKey: firstDateKey)
        }

        // Update domain counts
        updateDomainStats(domain: log.domain)
    }

    // MARK: - Domain Statistics

    func recentDomains(limit: Int = 5) -> [HealthDomain] {
        let recent = allLogs.suffix(20)
        let counts = Dictionary(grouping: recent, by: { $0.domain }).mapValues { $0.count }
        return counts.sorted { $0.value > $1.value }.prefix(limit).map { $0.key }
    }

    func topDomains(limit: Int = 3) -> [(HealthDomain, Int)] {
        let counts = domainCounts
        return counts
            .compactMap { key, value -> (HealthDomain, Int)? in
                guard let domain = HealthDomain(rawValue: key) else { return nil }
                return (domain, value)
            }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { ($0.0, $0.1) }
    }

    private var domainCounts: [String: Int] {
        if let cached = cachedDomainCounts { return cached }
        guard let data = defaults.data(forKey: domainStatsKey),
              let decoded = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        cachedDomainCounts = decoded
        return decoded
    }

    private func updateDomainStats(domain: HealthDomain) {
        var counts = domainCounts
        counts[domain.rawValue, default: 0] += 1
        cachedDomainCounts = counts
        if let data = try? JSONEncoder().encode(counts) {
            defaults.set(data, forKey: domainStatsKey)
        }
    }

    // MARK: - Content Similarity (Simple Jaccard)

    private func contentSimilarity(_ a: String, _ b: String) -> Double {
        let wordsA = Set(a.lowercased().split(separator: " ").map(String.init))
        let wordsB = Set(b.lowercased().split(separator: " ").map(String.init))
        guard !wordsA.isEmpty || !wordsB.isEmpty else { return 0 }
        let intersection = wordsA.intersection(wordsB).count
        let union = wordsA.union(wordsB).count
        return union > 0 ? Double(intersection) / Double(union) : 0
    }

    // MARK: - Data Management

    func clearAllMemory() {
        cachedInsights = nil
        cachedLogs = nil
        cachedDomainCounts = nil
        defaults.removeObject(forKey: insightsKey)
        defaults.removeObject(forKey: interactionsKey)
        defaults.removeObject(forKey: domainStatsKey)
        defaults.removeObject(forKey: firstDateKey)
    }

    /// Export memory as JSON (for backup / debug)
    func exportMemory() -> String? {
        let export: [String: Any] = [
            "insights_count": totalInsights,
            "interactions_count": totalInteractions,
            "domains": domainCounts,
            "first_interaction": firstInteractionDate?.ISO8601Format() ?? "none"
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: export, options: .prettyPrinted) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
