import SwiftUI

struct EqualGroupsView: View {
    let groups: Int
    let perGroup: Int
    var story: MultiplicationStory?
    var accent: Color = AppTheme.sunny
    var compact: Bool = false

    private var dotSize: CGFloat { compact ? 12 : 18 }
    private var total: Int { groups * perGroup }

    var body: some View {
        VStack(spacing: compact ? 6 : 10) {
            if groups <= 6 {
                VStack(spacing: compact ? 6 : 8) {
                    ForEach(0..<groups, id: \.self) { group in
                        HStack(spacing: compact ? 6 : 8) {
                            Text("\(group + 1)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(accent)
                                .frame(width: compact ? 14 : 18)

                            HStack(spacing: compact ? 3 : 5) {
                                ForEach(0..<perGroup, id: \.self) { _ in
                                    Circle()
                                        .fill(accent)
                                        .frame(width: dotSize, height: dotSize)
                                }
                            }
                            .padding(.horizontal, compact ? 6 : 8)
                            .padding(.vertical, compact ? 4 : 6)
                            .background(accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            } else {
                ArrayGridView(rows: groups, columns: perGroup, accent: accent, compact: compact)
            }

            Text(story?.totalLabel(total: total) ?? "\(groups) groups × \(perGroup) = \(total)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.ink.opacity(0.55))
        }
        .accessibilityLabel("\(groups) equal groups of \(perGroup), \(total) in all")
    }
}
