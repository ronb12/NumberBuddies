import UIKit

enum ProgressReportPDFExporter {
    private static let pageSize = CGSize(width: 612, height: 792)
    private static let margin: CGFloat = 54
    private static let contentWidth: CGFloat = pageSize.width - margin * 2

    private static let ink = UIColor(red: 0.18, green: 0.16, blue: 0.22, alpha: 1)
    private static let muted = UIColor(red: 0.18, green: 0.16, blue: 0.22, alpha: 0.68)
    private static let teal = UIColor(red: 0.18, green: 0.72, blue: 0.68, alpha: 1)

    static func generatePDF(from report: AcademicProgressReport) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        return renderer.pdfData { context in
            let drawer = PageDrawer(context: context)
            drawer.drawReport(report)
        }
    }

    static func temporaryFileURL(for report: AcademicProgressReport) -> URL {
        let safeName = report.studentName
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
        let filename = (safeName.isEmpty ? "student" : safeName) + "-progress-report.pdf"
        return FileManager.default.temporaryDirectory.appendingPathComponent(filename)
    }

    private final class PageDrawer {
        let context: UIGraphicsPDFRendererContext
        var y: CGFloat = margin
        var pageNumber = 0

        init(context: UIGraphicsPDFRendererContext) {
            self.context = context
        }

        func drawReport(_ report: AcademicProgressReport) {
            beginPage()
            drawHeader(report: report)
            drawSection("Student Information") {
                drawRow("Student", report.studentName)
                drawRow("Grade equivalent", report.gradeEquivalent)
                drawRow("Curriculum track", report.curriculumBand)
                drawRow("Daily streak", "\(report.dailyStreak) day\(report.dailyStreak == 1 ? "" : "s")")
            }
            drawSection("Overall Performance") {
                drawParagraph("Overall grade: \(report.overallLetterGrade) · \(report.overallProficiency.rawValue)", font: .boldBody)
                drawParagraph("\(report.overallAccuracy)% accuracy this period", font: .body)
                if report.lifetimeAccuracy != report.overallAccuracy {
                    drawParagraph("\(report.lifetimeAccuracy)% lifetime accuracy", font: .caption)
                }
                if !report.hasPeriodActivity {
                    drawParagraph("Complete a practice round during this reporting period to unlock period grades.", font: .caption)
                }
            }
            drawSection("Attendance & Engagement") {
                drawRow("Practice days", "\(report.daysPracticed)/\(report.daysInPeriod)")
                drawRow("Participation", "\(report.participationRate)%")
                drawRow("Rounds", "\(report.periodRounds)")
                drawRow("Time spent", SessionStore.formattedDuration(report.totalTimeSeconds))
                drawRow("Total stars earned", "\(report.totalStars)")
                drawRow("Lifetime rounds", "\(report.lifetimeRounds)")
            }
            drawSection("Subject Grades") {
                if report.subjects.isEmpty {
                    drawParagraph("No subjects unlocked yet.", font: .caption)
                } else {
                    for subject in report.subjects {
                        ensureSpace(72)
                        drawSubject(subject)
                    }
                }
            }
            if !report.subjects.isEmpty {
                drawSection("Standards-Based Comments") {
                    for subject in report.subjects {
                        ensureSpace(88)
                        drawParagraph("\(subject.operation.title) — \(subject.proficiency.shortLabel)", font: .boldBody)
                        drawParagraph(subject.standardDescription, font: .caption)
                        drawParagraph(subject.comment, font: .body)
                        y += 6
                    }
                }
            }
            drawSection("Weekly Activity Log") {
                if report.weeklyLog.isEmpty {
                    drawParagraph("No practice logged in the last 7 days.", font: .caption)
                } else {
                    for day in report.weeklyLog {
                        ensureSpace(28)
                        drawWeeklyRow(day)
                    }
                }
            }
            drawSection("Areas of Strength") {
                if report.strengths.isEmpty {
                    drawParagraph("Strengths will appear after more practice sessions.", font: .caption)
                } else {
                    drawBullets(report.strengths)
                }
            }
            drawSection("Areas for Growth") {
                if report.growthAreas.isEmpty {
                    drawParagraph("No specific growth areas identified — keep practicing!", font: .caption)
                } else {
                    drawBullets(report.growthAreas)
                }
            }
            drawSection("Teacher Comments") {
                drawParagraph(report.teacherComment, font: .body)
            }
            drawSection("Recommended Next Steps") {
                drawBullets(report.nextSteps)
            }
            ensureSpace(48)
            drawParagraph(
                "This report is generated from on-device practice data. It aligns with common K–5 math standards and is intended as a family progress snapshot, not an official school transcript.",
                font: .caption
            )
            y += 8
            drawParagraph("Bradley Virtual Solutions, LLC", font: .caption, alignment: .center)
            drawPageFooter()
        }

        private func beginPage() {
            context.beginPage()
            pageNumber += 1
            y = margin
        }

        private func ensureSpace(_ height: CGFloat) {
            if y + height > pageSize.height - margin - 24 {
                drawPageFooter()
                beginPage()
            }
        }

        private func drawHeader(report: AcademicProgressReport) {
            let title = "Number Buddies — Mathematics Progress Report"
            drawParagraph(title, font: .title, color: ink)
            y += 4
            drawParagraph("Reporting period: \(report.reportingPeriodLabel)", font: .caption)
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            drawParagraph("Report date: \(dateFormatter.string(from: report.reportDate))", font: .caption)
            y += 10
            drawDivider()
        }

        private func drawSection(_ title: String, content: () -> Void) {
            ensureSpace(40)
            y += 8
            drawParagraph(title, font: .section, color: ink)
            y += 4
            content()
        }

        private func drawRow(_ label: String, _ value: String) {
            ensureSpace(18)
            let attributes = TextStyle.body.attributes(color: ink)
            let labelAttrs = TextStyle.body.attributes(color: muted)
            let labelWidth: CGFloat = 160
            label.draw(in: CGRect(x: margin, y: y, width: labelWidth, height: 18), withAttributes: labelAttrs)
            value.draw(
                in: CGRect(x: margin + labelWidth, y: y, width: contentWidth - labelWidth, height: 18),
                withAttributes: attributes
            )
            y += 18
        }

        private func drawSubject(_ subject: SubjectAssessment) {
            var line = "\(subject.letterGrade)  \(subject.operation.title) — \(subject.proficiency.shortLabel)"
            line += " · Level \(subject.level)/\(subject.maxLevel) · \(subject.stars) stars"
            if let accuracy = subject.periodAccuracy {
                line += " · \(accuracy)% this period"
            }
            drawParagraph(line, font: .boldBody)
            if subject.missedCount > 0 {
                drawParagraph("\(subject.missedCount) needed extra support", font: .caption, color: UIColor(red: 1, green: 0.45, blue: 0.42, alpha: 1))
            }
            y += 4
        }

        private func drawWeeklyRow(_ day: DayPracticeSummary) {
            let dayLabel = SessionStore.formattedDayLabel(for: day.dayKey)
            let left = "\(dayLabel): \(day.rounds) round\(day.rounds == 1 ? "" : "s"), \(day.correct)/\(day.total) correct"
            let right = "\(day.accuracyPercent)% · \(SessionStore.formattedDuration(day.durationSeconds))"
            drawParagraph("\(left)  (\(right))", font: .body)
        }

        private func drawBullets(_ items: [String]) {
            for item in items {
                drawParagraph("• \(item)", font: .body)
            }
        }

        private func drawDivider() {
            ensureSpace(8)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: margin, y: y))
            path.addLine(to: CGPoint(x: margin + contentWidth, y: y))
            muted.setStroke()
            path.lineWidth = 0.5
            path.stroke()
            y += 10
        }

        private func drawParagraph(
            _ text: String,
            font: TextStyle,
            color: UIColor? = nil,
            alignment: NSTextAlignment = .left
        ) {
            let attrs = font.attributes(color: color ?? (font == .caption ? muted : ink))
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = alignment
            paragraph.lineBreakMode = .byWordWrapping
            var merged = attrs
            merged[.paragraphStyle] = paragraph

            let bounding = (text as NSString).boundingRect(
                with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: merged,
                context: nil
            )
            ensureSpace(ceil(bounding.height) + 4)
            (text as NSString).draw(
                with: CGRect(x: margin, y: y, width: contentWidth, height: ceil(bounding.height)),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: merged,
                context: nil
            )
            y += ceil(bounding.height) + 4
        }

        private func drawPageFooter() {
            let footerY = pageSize.height - margin + 12
            let text = "Page \(pageNumber)"
            let attrs = TextStyle.caption.attributes(color: muted)
            let size = (text as NSString).size(withAttributes: attrs)
            (text as NSString).draw(
                at: CGPoint(x: (pageSize.width - size.width) / 2, y: footerY),
                withAttributes: attrs
            )
        }
    }

    private enum TextStyle {
        case title
        case section
        case boldBody
        case body
        case caption

        func attributes(color: UIColor) -> [NSAttributedString.Key: Any] {
            switch self {
            case .title:
                return [.font: UIFont.systemFont(ofSize: 20, weight: .bold), .foregroundColor: color]
            case .section:
                return [.font: UIFont.systemFont(ofSize: 14, weight: .bold), .foregroundColor: color]
            case .boldBody:
                return [.font: UIFont.systemFont(ofSize: 11, weight: .semibold), .foregroundColor: color]
            case .body:
                return [.font: UIFont.systemFont(ofSize: 11, weight: .regular), .foregroundColor: color]
            case .caption:
                return [.font: UIFont.systemFont(ofSize: 10, weight: .regular), .foregroundColor: color]
            }
        }
    }
}
