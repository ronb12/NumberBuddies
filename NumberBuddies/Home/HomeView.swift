import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var progressItems: [KidProgress] = []

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
        }
        .onAppear(perform: reloadProgress)
    }

    private func reloadProgress() {
        progressItems = (try? modelContext.fetch(FetchDescriptor<KidProgress>())) ?? []
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                MascotView(size: horizontalSizeClass == .regular ? 88 : 72)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Number Buddies")
                        .font(.system(size: horizontalSizeClass == .regular ? 40 : 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                    Text("Let's practice math!")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(AppTheme.ink.opacity(0.7))
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
                        stars: stars(for: operation)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func stars(for operation: MathOperation) -> Int {
        progressItems.first(where: { $0.operationRaw == operation.rawValue })?.stars ?? 0
    }
}

struct OperationCard: View {
    let operation: MathOperation
    let stars: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: operation.iconName)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(AppTheme.sunny)
                        .font(.caption)
                    Text("\(stars)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.ink.opacity(0.8))
                }
            }

            Text(operation.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            Text("Tap to play")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: AppTheme.minTapSize * 2, alignment: .leading)
        .background(AppTheme.color(for: operation), in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .shadow(color: AppTheme.color(for: operation).opacity(0.25), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(operation.title). \(stars) stars earned.")
        .accessibilityHint(operation.accessibilityHint)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: KidProgress.self, inMemory: true)
}
