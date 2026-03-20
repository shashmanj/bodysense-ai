//
//  AgentReportExporter.swift
//  body sense ai
//
//  Generates a CEO intelligence PDF report from AgentAnalytics data.
//  Includes per-agent performance, unanswered queries, customer suggestions,
//  escalated tickets, and business insights.
//

import Foundation
import UIKit

enum AgentReportExporter {

    /// Generate a PDF report from the analytics data.
    static func exportPDF(report: AgentAnalyticsReport, store: HealthStore) -> Data? {
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4
        let margin: CGFloat = 50
        let contentWidth = pageRect.width - margin * 2

        let titleFont   = UIFont.systemFont(ofSize: 22, weight: .bold)
        let headingFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let bodyFont    = UIFont.systemFont(ofSize: 11, weight: .regular)
        let boldBody    = UIFont.systemFont(ofSize: 11, weight: .semibold)
        let smallFont   = UIFont.systemFont(ofSize: 9, weight: .regular)

        let darkText    = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0)
        let grayText    = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        let accentColor = UIColor(red: 0.42, green: 0.39, blue: 1.0, alpha: 1.0)
        let reportID    = UUID().uuidString.prefix(8)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { ctx in
            var yPos: CGFloat = 0

            func ensureSpace(_ needed: CGFloat) {
                if yPos + needed > pageRect.height - 60 {
                    drawFooter(ctx: ctx, pageRect: pageRect, smallFont: smallFont, grayText: grayText, reportID: String(reportID))
                    ctx.beginPage()
                    yPos = margin
                }
            }

            @discardableResult
            func drawText(_ text: String, x: CGFloat, font: UIFont, color: UIColor, maxWidth: CGFloat? = nil) -> CGFloat {
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                let w = maxWidth ?? contentWidth
                let size = (text as NSString).boundingRect(with: CGSize(width: w, height: .greatestFiniteMagnitude),
                                                           options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
                (text as NSString).draw(in: CGRect(x: x, y: yPos, width: w, height: size.height), withAttributes: attrs)
                return size.height
            }

            // ── Page 1: Title & Executive Summary ──
            ctx.beginPage()
            yPos = margin

            // Title
            let titleH = drawText("BodySense AI — CEO Intelligence Report", x: margin, font: titleFont, color: accentColor)
            yPos += titleH + 8

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            let dateH = drawText("Generated: \(dateFormatter.string(from: report.generatedAt))", x: margin, font: smallFont, color: grayText)
            yPos += dateH + 4
            let periodH = drawText("Report period: Last \(report.reportPeriodDays) days", x: margin, font: smallFont, color: grayText)
            yPos += periodH + 20

            // Executive Summary
            let sumH = drawText("Executive Summary", x: margin, font: headingFont, color: darkText)
            yPos += sumH + 10

            let summaryLines = [
                "Total interactions: \(report.totalInteractions)",
                "Average quality score: \(String(format: "%.0f", report.averageQuality * 100))%",
                "Active agents: \(report.agentStats.count)",
                "Unanswered queries: \(report.unansweredQueries.count)",
                "Customer suggestions: \(report.customerSuggestions.count)",
                "Escalated tickets: \(store.supportTickets.filter { $0.isEscalated }.count)"
            ]
            for line in summaryLines {
                let h = drawText("  •  \(line)", x: margin, font: bodyFont, color: darkText)
                yPos += h + 4
            }
            yPos += 16

            // ── Per-Agent Performance ──
            ensureSpace(40)
            let perfH = drawText("Per-Agent Performance", x: margin, font: headingFont, color: darkText)
            yPos += perfH + 10

            // Table header
            let colWidths: [CGFloat] = [140, 60, 60, 60, contentWidth - 320]
            let headers = ["Agent", "Messages", "Quality", "Failed", "Top Topics"]
            var xOffset = margin
            for (i, header) in headers.enumerated() {
                drawText(header, x: xOffset, font: boldBody, color: accentColor, maxWidth: colWidths[i])
                xOffset += colWidths[i]
            }
            yPos += 16

            for stat in report.agentStats {
                ensureSpace(20)
                xOffset = margin
                let row = [
                    stat.agentName,
                    "\(stat.messageCount)",
                    "\(String(format: "%.0f", stat.avgQuality * 100))%",
                    "\(stat.failedCount)",
                    stat.topTopics.prefix(3).joined(separator: ", ")
                ]
                for (i, cell) in row.enumerated() {
                    drawText(cell, x: xOffset, font: bodyFont, color: darkText, maxWidth: colWidths[i])
                    xOffset += colWidths[i]
                }
                yPos += 16
            }
            yPos += 16

            // ── Trending Topics ──
            if !report.trendingTopics.isEmpty {
                ensureSpace(40)
                let tH = drawText("Trending Topics", x: margin, font: headingFont, color: darkText)
                yPos += tH + 10

                for topic in report.trendingTopics.prefix(10) {
                    ensureSpace(16)
                    let h = drawText("  •  \(topic.topic) — \(topic.count) mentions (via \(topic.domain.rawValue))",
                                     x: margin, font: bodyFont, color: darkText)
                    yPos += h + 4
                }
                yPos += 16
            }

            // ── Unanswered Queries ──
            if !report.unansweredQueries.isEmpty {
                ensureSpace(40)
                let uH = drawText("Unanswered Queries", x: margin, font: headingFont, color: darkText)
                yPos += uH + 10

                for query in report.unansweredQueries.prefix(10) {
                    ensureSpace(20)
                    let h = drawText("  •  [\(query.domain.rawValue)] \"\(query.query)\"",
                                     x: margin, font: bodyFont, color: darkText)
                    yPos += h + 4
                }
                yPos += 16
            }

            // ── Escalated Customer Tickets ──
            let escalated = store.supportTickets.filter { $0.isEscalated }
            if !escalated.isEmpty {
                ensureSpace(40)
                let eH = drawText("Escalated Customer Tickets", x: margin, font: headingFont, color: UIColor.red)
                yPos += eH + 10

                for ticket in escalated.prefix(10) {
                    ensureSpace(30)
                    let dateStr = dateFormatter.string(from: ticket.createdAt)
                    let h1 = drawText("  Ticket: \(ticket.id.uuidString.prefix(8)) — \(ticket.issue)",
                                      x: margin, font: boldBody, color: darkText)
                    yPos += h1 + 2
                    let h2 = drawText("  Category: \(ticket.category) | Status: \(ticket.status) | Date: \(dateStr)",
                                      x: margin, font: smallFont, color: grayText)
                    yPos += h2 + 2
                    if !ticket.detail.isEmpty {
                        let h3 = drawText("  Detail: \(ticket.detail)", x: margin, font: bodyFont, color: darkText)
                        yPos += h3 + 2
                    }
                    yPos += 8
                }
                yPos += 16
            }

            // ── Customer Suggestions ──
            if !report.customerSuggestions.isEmpty {
                ensureSpace(40)
                let sH = drawText("Customer Suggestions / Feature Requests", x: margin, font: headingFont, color: darkText)
                yPos += sH + 10

                for suggestion in report.customerSuggestions.prefix(5) {
                    ensureSpace(16)
                    let h = drawText("  •  \"\(suggestion)\"", x: margin, font: bodyFont, color: darkText)
                    yPos += h + 4
                }
            }

            // Footer on last page
            drawFooter(ctx: ctx, pageRect: pageRect, smallFont: smallFont, grayText: grayText, reportID: String(reportID))
        }

        return data
    }

    /// Draw page footer
    private static func drawFooter(ctx: UIGraphicsPDFRendererContext, pageRect: CGRect,
                                    smallFont: UIFont, grayText: UIColor, reportID: String) {
        let footerAttrs: [NSAttributedString.Key: Any] = [.font: smallFont, .foregroundColor: grayText]
        let footerText = "BodySense AI CEO Report  |  ID: \(reportID)  |  Confidential"
        let footerSize = (footerText as NSString).size(withAttributes: footerAttrs)
        (footerText as NSString).draw(
            at: CGPoint(x: (pageRect.width - footerSize.width) / 2, y: pageRect.height - 30),
            withAttributes: footerAttrs
        )
    }

    /// Create a temporary PDF file and return its URL for sharing.
    static func createPDFFile(report: AgentAnalyticsReport, store: HealthStore) -> URL? {
        guard let data = exportPDF(report: report, store: store) else { return nil }
        let dateStr = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let fileName = "BodySenseAI_CEO_Report_\(dateStr).pdf"

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }
}
