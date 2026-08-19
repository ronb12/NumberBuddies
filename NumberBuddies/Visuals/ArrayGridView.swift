import SwiftUI

struct ArrayGridView: View {
    let rows: Int
    let columns: Int
    var accent: Color = AppTheme.sunny
    var compact: Bool = false

    private var total: Int { rows * columns }
    private var cellSize: CGFloat { compact ? 16 : 24 }
    private var spacing: CGFloat { compact ? 4 : 6 }

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(0..<rows, id: \.self) { _ in
                HStack(spacing: spacing) {
                    ForEach(0..<columns, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: compact ? 4 : 6)
                            .fill(accent)
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
        .accessibilityLabel("\(rows) rows of \(columns), \(total) in all")
    }
}
