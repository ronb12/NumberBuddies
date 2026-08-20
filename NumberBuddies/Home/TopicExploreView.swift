import SwiftUI

struct TopicExploreView: View {
    let profileId: UUID
    let ageGroup: AgeGroup

    private var topics: [MathTopic] {
        MathTopic.available(for: ageGroup)
    }

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Practice real-world math skills with pictures, stories, and charts.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.ink.opacity(0.7))
                    .padding(.horizontal, 4)

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(topics) { topic in
                        NavigationLink {
                            TopicPracticeView(
                                topic: topic,
                                profileId: profileId,
                                ageGroup: ageGroup
                            )
                        } label: {
                            TopicCard(topic: topic)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .background(AppTheme.cream.ignoresSafeArea())
        .navigationTitle("Explore Math")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct TopicCard: View {
    let topic: MathTopic

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: topic.iconName)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)

            Text(topic.title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text(topic.subtitle)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .padding(16)
        .background(topic.accentColor, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .accessibilityLabel("\(topic.title). \(topic.subtitle)")
    }
}

#Preview {
    NavigationStack {
        TopicExploreView(profileId: UUID(), ageGroup: .upper)
    }
}
