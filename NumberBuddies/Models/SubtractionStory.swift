import Foundation

struct SubtractionStory: Equatable, Sendable {
    let itemPlural: String
    let itemSingular: String
    let action: String
    let iconName: String

    func startLabel(count: Int) -> String {
        "You have \(count) \(itemName(count: count))"
    }

    func actionLabel(count: Int) -> String {
        "You \(action) \(count)"
    }

    func leftLabel(count: Int) -> String {
        "\(count) \(itemName(count: count)) left"
    }

    func spokenQuestionShort(start: Int, remove: Int) -> String {
        let startWord = SpokenNumbers.word(for: start)
        let removeWord = SpokenNumbers.word(for: remove)
        let itemStart = itemName(count: start)
        let itemLeft = itemName(count: max(start - remove, 0))
        return "You have \(startWord) \(itemStart). You \(action) \(removeWord). How many \(itemLeft) do you have left?"
    }

    private func itemName(count: Int) -> String {
        count == 1 ? itemSingular : itemPlural
    }

    static func pick(for operandA: Int, operandB: Int) -> SubtractionStory {
        let index = (operandA * 7 + operandB * 3) % templates.count
        return templates[index]
    }

    private static let templates: [SubtractionStory] = [
        SubtractionStory(
            itemPlural: "pieces of candy",
            itemSingular: "piece of candy",
            action: "ate",
            iconName: "gift.fill"
        ),
        SubtractionStory(
            itemPlural: "cookies",
            itemSingular: "cookie",
            action: "ate",
            iconName: "fork.knife"
        ),
        SubtractionStory(
            itemPlural: "stickers",
            itemSingular: "sticker",
            action: "gave away",
            iconName: "star.fill"
        ),
        SubtractionStory(
            itemPlural: "marbles",
            itemSingular: "marble",
            action: "lost",
            iconName: "circle.fill"
        ),
        SubtractionStory(
            itemPlural: "apples",
            itemSingular: "apple",
            action: "ate",
            iconName: "leaf.fill"
        ),
        SubtractionStory(
            itemPlural: "crackers",
            itemSingular: "cracker",
            action: "ate",
            iconName: "square.fill"
        ),
        SubtractionStory(
            itemPlural: "toys",
            itemSingular: "toy",
            action: "put away",
            iconName: "teddybear.fill"
        ),
        SubtractionStory(
            itemPlural: "balloons",
            itemSingular: "balloon",
            action: "let go of",
            iconName: "balloon.fill"
        )
    ]
}
