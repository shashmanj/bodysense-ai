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
}
