import SwiftUI

struct MascotView: View {
    var size: CGFloat = 72

    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.teal.opacity(0.2))
                .frame(width: size, height: size)
            Image(systemName: "teddybear.fill")
                .font(.system(size: size * 0.42))
                .foregroundStyle(AppTheme.teal)
                .accessibilityHidden(true)
        }
        .accessibilityLabel("Number Buddy mascot")
    }
}
