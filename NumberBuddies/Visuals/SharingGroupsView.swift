import SwiftUI

struct SharingGroupsView: View {
    let groups: Int
    let perGroup: Int
    var accent: Color = AppTheme.purple

    private var total: Int { groups * perGroup }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(0..<groups, id: \.self) { _ in
                VStack(spacing: 6) {
                    ForEach(0..<perGroup, id: \.self) { _ in
                        Circle()
                            .fill(accent)
                            .frame(width: 20, height: 20)
                    }
                }
                .padding(8)
                .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .accessibilityLabel("\(groups) equal groups with \(perGroup) in each, \(total) in all")
    }
}
