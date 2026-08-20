import SwiftData
import SwiftUI

private enum ReportText {
    static let ink = AppTheme.ink
    static let body = AppTheme.ink.opacity(0.92)
    static let muted = AppTheme.ink.opacity(0.68)
    static let caption = AppTheme.ink.opacity(0.58)
}

struct ParentReportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let profile: KidProfile

    @State private var shareURL: URL?
    @State private var showShareSheet = false
    @State private var showPrintSheet = false
    @State private var pdfData: Data?

    private var report: AcademicProgressReport {
        AcademicReportBuilder.build(profile: profile, context: modelContext)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    reportHeader
                    studentInfoSection
                    overallPerformanceSection
                    attendanceSection
                    subjectGradesSection
                    if !report.subjects.isEmpty {
                        standardsSection
                    }
                    weeklyActivitySection
                    narrativeSection
                    nextStepsSection
                    footerSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(AppTheme.cream.ignoresSafeArea())
            .colorScheme(.light)
            .navigationTitle("Progress Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            exportPDF(action: .share)
                        } label: {
                            Label("Share PDF", systemImage: "square.and.arrow.up")
                        }
                        Button {
                            exportPDF(action: .print)
                        } label: {
                            Label("Print", systemImage: "printer")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Export progress report")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let shareURL {
                    ProgressReportShareSheet(items: [shareURL])
                }
            }
            .background {
                if showPrintSheet, let pdfData {
                    ProgressReportPrintPresenter(
                        pdfData: pdfData,
                        jobName: "\(report.studentName) Progress Report",
                        isPresented: $showPrintSheet
                    )
                    .frame(width: 0, height: 0)
                }
            }
        }
    }

    private enum PDFAction {
        case share
        case print
    }

    private func exportPDF(action: PDFAction) {
        let data = ProgressReportPDFExporter.generatePDF(from: report)
        pdfData = data
        switch action {
        case .share:
            let url = ProgressReportPDFExporter.temporaryFileURL(for: report)
            do {
                try data.write(to: url, options: .atomic)
                shareURL = url
                showShareSheet = true
            } catch {
                shareURL = nil
            }
        case .print:
            showPrintSheet = true
        }
    }

    private var reportHeader: some View {
        ReportCard {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    MascotView(size: 44)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Number Buddies")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.teal)
                        Text("Mathematics Progress Report")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AppTheme.ink)
                    }
                    Spacer()
                }

                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reporting period")
                            .font(.caption)
                            .foregroundStyle(ReportText.caption)
                        Text(report.reportingPeriodLabel)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(ReportText.body)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Report date")
                            .font(.caption)
                            .foregroundStyle(ReportText.caption)
                        Text(report.reportDate, style: .date)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(ReportText.body)
                    }
                }
            }
        }
    }

    private var studentInfoSection: some View {
        ReportCard(title: "Student Information") {
            ReportRow(label: "Student", value: report.studentName)
            ReportRow(label: "Grade equivalent", value: report.gradeEquivalent)
            ReportRow(label: "Curriculum track", value: report.curriculumBand)
            ReportRow(label: "Daily streak", value: "\(report.dailyStreak) day\(report.dailyStreak == 1 ? "" : "s")")
        }
    }

    private var overallPerformanceSection: some View {
        ReportCard(title: "Overall Performance") {
            HStack(spacing: 20) {
                GradeBadge(letter: report.overallLetterGrade)
                VStack(alignment: .leading, spacing: 8) {
                    ProficiencyBadge(level: report.overallProficiency)
                    Text("\(report.overallAccuracy)% accuracy this period")
                        .font(.subheadline)
                        .foregroundStyle(ReportText.muted)
                    if report.lifetimeAccuracy != report.overallAccuracy {
                        Text("\(report.lifetimeAccuracy)% lifetime accuracy")
                            .font(.caption)
                            .foregroundStyle(ReportText.caption)
                    }
                }
                Spacer()
            }

            if !report.hasPeriodActivity {
                Text("Complete a practice round during this reporting period to unlock period grades.")
                    .font(.footnote)
                    .foregroundStyle(ReportText.muted)
                    .padding(.top, 4)
            }
        }
    }

    private var attendanceSection: some View {
        ReportCard(title: "Attendance & Engagement") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricTile(title: "Practice days", value: "\(report.daysPracticed)/\(report.daysInPeriod)")
                MetricTile(title: "Participation", value: "\(report.participationRate)%")
                MetricTile(title: "Rounds", value: "\(report.periodRounds)")
                MetricTile(title: "Time spent", value: SessionStore.formattedDuration(report.totalTimeSeconds))
            }
            ReportRow(label: "Total stars earned", value: "\(report.totalStars)")
            ReportRow(label: "Lifetime rounds", value: "\(report.lifetimeRounds)")
        }
    }

    private var subjectGradesSection: some View {
        ReportCard(title: "Subject Grades") {
            if report.subjects.isEmpty {
                Text("No subjects unlocked yet.")
                    .font(.subheadline)
                    .foregroundStyle(ReportText.muted)
            } else {
                ForEach(report.subjects) { subject in
                    SubjectGradeRow(subject: subject)
                    if subject.id != report.subjects.last?.id {
                        Divider().padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private var standardsSection: some View {
        ReportCard(title: "Standards-Based Comments") {
            ForEach(report.subjects) { subject in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label(subject.operation.title, systemImage: subject.operation.iconName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.color(for: subject.operation))
                        Spacer()
                        Text("Level \(subject.level)/\(subject.maxLevel)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(ReportText.caption)
                    }
                    Text(subject.standardDescription)
                        .font(.caption)
                        .foregroundStyle(ReportText.muted)
                    Text(subject.comment)
                        .font(.footnote)
                        .foregroundStyle(ReportText.body)
                }
                .padding(.vertical, 4)

                if subject.id != report.subjects.last?.id {
                    Divider()
                }
            }
        }
    }

    private var weeklyActivitySection: some View {
        ReportCard(title: "Weekly Activity Log") {
            if report.weeklyLog.isEmpty {
                Text("No practice logged in the last 7 days.")
                    .font(.subheadline)
                    .foregroundStyle(ReportText.muted)
            } else {
                ForEach(report.weeklyLog) { day in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(SessionStore.formattedDayLabel(for: day.dayKey))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(ReportText.ink)
                            Text("\(day.rounds) round\(day.rounds == 1 ? "" : "s") · \(day.correct)/\(day.total) correct")
                                .font(.caption)
                                .foregroundStyle(ReportText.muted)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(day.accuracyPercent)%")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.teal)
                            Text(SessionStore.formattedDuration(day.durationSeconds))
                                .font(.caption)
                                .foregroundStyle(ReportText.caption)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var narrativeSection: some View {
        VStack(spacing: 16) {
            ReportCard(title: "Areas of Strength") {
                if report.strengths.isEmpty {
                    Text("Strengths will appear after more practice sessions.")
                        .font(.subheadline)
                        .foregroundStyle(ReportText.muted)
                } else {
                    BulletedList(items: report.strengths)
                }
            }

            ReportCard(title: "Areas for Growth") {
                if report.growthAreas.isEmpty {
                    Text("No specific growth areas identified — keep practicing!")
                        .font(.subheadline)
                        .foregroundStyle(ReportText.muted)
                } else {
                    BulletedList(items: report.growthAreas)
                }
            }

            ReportCard(title: "Teacher Comments") {
                Text(report.teacherComment)
                    .font(.body)
                    .foregroundStyle(ReportText.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var nextStepsSection: some View {
        ReportCard(title: "Recommended Next Steps") {
            BulletedList(items: report.nextSteps)
        }
    }

    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("This report is generated from on-device practice data. It aligns with common K–5 math standards and is intended as a family progress snapshot, not an official school transcript.")
                .font(.caption)
                .foregroundStyle(ReportText.muted)
                .multilineTextAlignment(.center)
            Text("Bradley Virtual Solutions, LLC")
                .font(.caption.weight(.medium))
                .foregroundStyle(ReportText.caption)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }
}

// MARK: - Report components

private struct ReportCard<Content: View>: View {
    var title: String?
    @ViewBuilder var content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.ink.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct ReportRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(ReportText.muted)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(ReportText.ink)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

private struct MetricTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ReportText.muted)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(ReportText.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppTheme.ink.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.ink.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct GradeBadge: View {
    let letter: String

    var body: some View {
        Text(letter)
            .font(.system(size: 36, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 72, height: 72)
            .background(
                LinearGradient(
                    colors: [AppTheme.teal, AppTheme.teal.opacity(0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .accessibilityLabel("Overall grade \(letter)")
    }
}

private struct ProficiencyBadge: View {
    let level: ProficiencyLevel

    private var backgroundColor: Color {
        switch level {
        case .exceeds: AppTheme.teal.opacity(0.22)
        case .meets: AppTheme.sunny.opacity(0.42)
        case .approaching: AppTheme.coral.opacity(0.24)
        case .beginning: AppTheme.ink.opacity(0.1)
        }
    }

    private var textColor: Color {
        switch level {
        case .exceeds: Color(red: 0.08, green: 0.48, blue: 0.45)
        case .meets: AppTheme.ink
        case .approaching: Color(red: 0.72, green: 0.22, blue: 0.18)
        case .beginning: AppTheme.ink.opacity(0.82)
        }
    }

    var body: some View {
        Text(level.rawValue)
            .font(.caption.weight(.semibold))
            .foregroundStyle(textColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(backgroundColor, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(textColor.opacity(0.18), lineWidth: 1)
            }
    }
}

private struct SubjectGradeRow: View {
    let subject: SubjectAssessment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(subject.letterGrade)
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.color(for: subject.operation))
                .frame(width: 36, alignment: .center)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Label(subject.operation.title, systemImage: subject.operation.iconName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.color(for: subject.operation))
                    Spacer()
                    Text(subject.proficiency.shortLabel)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(ReportText.muted)
                }

                HStack(spacing: 12) {
                    Text("Level \(subject.level)/\(subject.maxLevel)")
                    Text("\(subject.stars) stars")
                    if let accuracy = subject.periodAccuracy {
                        Text("\(accuracy)% this period")
                    }
                }
                .font(.caption)
                .foregroundStyle(ReportText.muted)

                if subject.missedCount > 0 {
                    Text("\(subject.missedCount) needed extra support")
                        .font(.caption)
                        .foregroundStyle(AppTheme.coral)
                }
            }
        }
    }
}

private struct BulletedList: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundStyle(AppTheme.teal)
                    Text(item)
                        .font(.subheadline)
                        .foregroundStyle(ReportText.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

#Preview {
    ParentReportView(profile: KidProfile(name: "Sam", ageGroup: .early))
        .modelContainer(for: [KidProfile.self, KidProgress.self, PracticeSession.self], inMemory: true)
}
