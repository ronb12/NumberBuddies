import SwiftUI

struct ArrayGridView: View {
    let rows: Int
    let columns: Int
    var accent: Color = AppTheme.sunny

    var body: some View {
        VStack(spacing: 6) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(0..<columns, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(accent)
                            .frame(width: 24, height: 24)
                    }
                }
            }
        }
        .accessibilityLabel("Array showing \(rows) rows of \(columns)")
    }
}
