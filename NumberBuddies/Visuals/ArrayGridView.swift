import SwiftUI

struct ArrayGridView: View {
    let rows: Int
    let columns: Int
    var accent: Color = AppTheme.sunny

    private var total: Int { rows * columns }

    var body: some View {
        VStack(spacing: 6) {
            ForEach(0..<rows, id: \.self) { _ in
                HStack(spacing: 6) {
                    ForEach(0..<columns, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(accent)
                            .frame(width: 24, height: 24)
                    }
                }
            }
        }
        .accessibilityLabel("\(rows) rows of \(columns), \(total) in all")
    }
}
