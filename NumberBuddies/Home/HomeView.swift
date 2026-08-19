import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \KidProgress.operationRaw) private var progressItems: [KidProgress]
    @State private var showSettings = false

    private var totalStars: Int {
        progressItems.reduce(0) { $0 + $1.stars }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PlayfulBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        header
                        operationGrid
                    }
                    .padding(.horizontal, horizontalSizeClass == .regular ? 48 : 20)
                    .padding(.vertical, 24)
                }
            }
            .navigationBarHidden(true)
            .overlay(alignment: .topTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.ink.opacity(0.55))
                        .padding(12)
                        .background(.white.opacity(0.85), in: Circle())
                }
                .padding(.trailing, horizontalSizeClass == .regular ? 48 : 20)
                .padding(.top, 8)
                .accessibilityLabel("Settings")
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                MascotView(size: horizontalSizeClass == .regular ? 88 : 72)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Number Buddies")
                        .font(.system(size: horizontalSizeClass == .regular ? 40 : 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Text("Let's practice math!")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(AppTheme.ink.opacity(0.7))
                        .minimumScaleFactor(0.8)
                }
                Spacer()
            }

            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(AppTheme.sunny)
                Text("\(totalStars) stars collected")
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.white.opacity(0.85), in: Capsule())
            .accessibilityElement(children: .combine)
        }
    }

    private var operationGrid: some View {
        let columns = horizontalSizeClass == .regular
            ? [GridItem(.flexible()), GridItem(.flexible())]
            : [GridItem(.flexible())]

        return LazyVGrid(columns: columns, spacing: 16) {
            ForEach(MathOperation.allCases) { operation in
                NavigationLink {
                    PracticeView(operation: operation)
                } label: {
                    OperationCard(
                        operation: operation,
                        stars: stars(for: operation),
                        difficulty: difficulty(for: operation)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func stars(for operation: MathOperation) -> Int {
        progressItems.first(where: { $0.operationRaw == operation.rawValue })?.stars ?? 0
    }

    private func difficulty(for operation: MathOperation) -> Int {
        progressItems.first(where: { $0.operationRaw == operation.rawValue })?.difficulty ?? 1
    }
}

struct OperationCard: View {
    let operation: MathOperation
    let stars: Int
    let difficulty: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: operation.iconName)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(AppTheme.sunny)
                            .font(.caption)
                        Text("\(stars)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.95))
                    }
                    Text("Level \(difficulty)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.2), in: Capsule())
                }
            }

            Text(operation.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.8)

            Text("Tap to play")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: AppTheme.minTapSize * 2, alignment: .leading)
        .background(AppTheme.color(for: operation), in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .shadow(color: AppTheme.color(for: operation).opacity(0.25), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(operation.title). Level \(difficulty). \(stars) stars earned.")
        .accessibilityHint(operation.accessibilityHint)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: KidProgress.self, inMemory: true)
}
