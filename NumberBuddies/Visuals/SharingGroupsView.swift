import SwiftUI

struct SharingGroupsView: View {
    let groups: Int
    let perGroup: Int
    var remainder: Int = 0
    var story: DivisionStory?
    var accent: Color = AppTheme.purple
    var compact: Bool = false

    private var sharedTotal: Int { groups * perGroup }
    private var total: Int { sharedTotal + remainder }
    private var dotSize: CGFloat { compact ? 12 : 18 }

    var body: some View {
        VStack(spacing: compact ? 8 : 12) {
            HelperGroupBox(
                title: story?.startLabel(total: total) ?? "\(total) to share",
                tint: accent,
                compact: compact
            ) {
                mergedPile
            }

            HelperStepLabel(
                text: story?.shareLabel(friends: groups) ?? "Split into \(groups) equal groups",
                color: accent
            )

            Image(systemName: "arrow.down")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.ink.opacity(0.35))

            HStack(alignment: .top, spacing: compact ? 6 : 10) {
                ForEach(0..<groups, id: \.self) { group in
                    VStack(spacing: compact ? 4 : 6) {
                        Text("\(story?.receiverSingular.capitalized ?? "Group") \(group + 1)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(accent)

                        VStack(spacing: compact ? 3 : 5) {
                            ForEach(0..<perGroup, id: \.self) { _ in
                                Circle()
                                    .fill(accent)
                                    .frame(width: dotSize, height: dotSize)
                            }
                        }
                    }
                    .padding(compact ? 6 : 8)
                    .background(accent.opacity(0.1), in: RoundedRectangle(cornerRadius: compact ? 8 : 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: compact ? 8 : 12)
                            .stroke(accent.opacity(0.25), lineWidth: 1)
                    }
                }
            }

            Text(story?.eachLabel(count: perGroup) ?? "\(perGroup) in each group")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.ink.opacity(0.55))

            if remainder > 0 {
                HelperStepLabel(
                    text: "\(remainder) left over",
                    color: AppTheme.coral
                )
            }
        }
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        if remainder > 0 {
            return "\(groups) equal groups with \(perGroup) in each and \(remainder) left over"
        }
        return "\(groups) equal groups with \(perGroup) in each, \(total) in all"
    }

    private var mergedPile: some View {
        let dotsPerRow = compact ? 6 : 10
        let rows = max(1, Int(ceil(Double(total) / Double(dotsPerRow))))
        return VStack(spacing: compact ? 3 : 5) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: compact ? 3 : 5) {
                    ForEach(dotsInRow(row, dotsPerRow: dotsPerRow), id: \.self) { index in
                        Circle()
                            .fill(index >= sharedTotal ? AppTheme.coral.opacity(0.85) : accent.opacity(0.85))
                            .frame(width: dotSize, height: dotSize)
                    }
                }
            }
        }
    }

    private func dotsInRow(_ row: Int, dotsPerRow: Int) -> [Int] {
        let start = row * dotsPerRow
        let end = min(start + dotsPerRow, total)
        guard start < end else { return [] }
        return Array(start..<end)
    }
}
