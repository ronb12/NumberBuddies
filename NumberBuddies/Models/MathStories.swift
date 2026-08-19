import Foundation

struct StoryItem: Equatable, Sendable {
    let itemPlural: String
    let itemSingular: String
    let iconName: String

    func name(count: Int) -> String {
        count == 1 ? itemSingular : itemPlural
    }

    static let pool: [StoryItem] = [
        StoryItem(itemPlural: "pieces of candy", itemSingular: "piece of candy", iconName: "gift.fill"),
        StoryItem(itemPlural: "cookies", itemSingular: "cookie", iconName: "fork.knife"),
        StoryItem(itemPlural: "stickers", itemSingular: "sticker", iconName: "star.fill"),
        StoryItem(itemPlural: "marbles", itemSingular: "marble", iconName: "circle.fill"),
        StoryItem(itemPlural: "apples", itemSingular: "apple", iconName: "leaf.fill"),
        StoryItem(itemPlural: "crackers", itemSingular: "cracker", iconName: "square.fill"),
        StoryItem(itemPlural: "toys", itemSingular: "toy", iconName: "teddybear.fill"),
        StoryItem(itemPlural: "balloons", itemSingular: "balloon", iconName: "balloon.fill"),
        StoryItem(itemPlural: "crayons", itemSingular: "crayon", iconName: "pencil"),
        StoryItem(itemPlural: "books", itemSingular: "book", iconName: "book.fill")
    ]

    static func pick(seedA: Int, seedB: Int) -> StoryItem {
        pool[(seedA * 7 + seedB * 3) % pool.count]
    }
}

struct AdditionStory: Equatable, Sendable {
    let item: StoryItem
    let giver: String

    func startLabel(count: Int) -> String {
        "You have \(count) \(item.name(count: count))"
    }

    func addLabel(count: Int) -> String {
        "\(giver) gives you \(count) more"
    }

    func totalLabel(count: Int) -> String {
        "\(count) \(item.name(count: count)) altogether"
    }

    func storyTitle(start: Int, add: Int) -> String {
        "\(startLabel(count: start)). \(addLabel(count: add)). How many now?"
    }

    func spokenQuestion(start: Int, add: Int) -> String {
        let startWord = SpokenNumbers.word(for: start)
        let addWord = SpokenNumbers.word(for: add)
        let itemStart = item.name(count: start)
        let itemTotal = item.name(count: start + add)
        return "You have \(startWord) \(itemStart). \(giver) gives you \(addWord) more. How many \(itemTotal) do you have now?"
    }

    static func pick(for operandA: Int, operandB: Int) -> AdditionStory {
        let item = StoryItem.pick(seedA: operandA, seedB: operandB)
        let givers = ["Your friend", "Mom", "Dad", "Your teacher", "Your buddy"]
        let giver = givers[(operandA + operandB) % givers.count]
        return AdditionStory(item: item, giver: giver)
    }
}

struct MultiplicationStory: Equatable, Sendable {
    let item: StoryItem
    let containerPlural: String
    let containerSingular: String

    func container(count: Int) -> String {
        count == 1 ? containerSingular : containerPlural
    }

    func introLabel(groups: Int, perGroup: Int) -> String {
        "You have \(groups) \(container(count: groups)). Each has \(perGroup) \(item.name(count: perGroup))."
    }

    func groupLabel(index: Int, perGroup: Int) -> String {
        "\(containerSingular.capitalized) \(index + 1): \(perGroup) \(item.name(count: perGroup))"
    }

    func totalLabel(total: Int) -> String {
        "\(total) \(item.name(count: total)) in all"
    }

    func storyTitle(groups: Int, perGroup: Int) -> String {
        "\(introLabel(groups: groups, perGroup: perGroup)) How many in all?"
    }

    func spokenQuestion(groups: Int, perGroup: Int) -> String {
        let groupsWord = SpokenNumbers.word(for: groups)
        let perGroupWord = SpokenNumbers.word(for: perGroup)
        let containerWord = container(count: groups)
        let itemWord = item.name(count: perGroup)
        return "You have \(groupsWord) \(containerWord). Each has \(perGroupWord) \(itemWord). How many \(item.name(count: groups * perGroup)) do you have in all?"
    }

    static func pick(for operandA: Int, operandB: Int) -> MultiplicationStory {
        let item = StoryItem.pick(seedA: operandB, seedB: operandA)
        let containers = [
            ("bags", "bag"),
            ("boxes", "box"),
            ("baskets", "basket"),
            ("plates", "plate"),
            ("packs", "pack")
        ]
        let pair = containers[(operandA + operandB) % containers.count]
        return MultiplicationStory(
            item: item,
            containerPlural: pair.0,
            containerSingular: pair.1
        )
    }
}

struct DivisionStory: Equatable, Sendable {
    let item: StoryItem
    let receiverPlural: String
    let receiverSingular: String

    func receiver(count: Int) -> String {
        count == 1 ? receiverSingular : receiverPlural
    }

    func startLabel(total: Int) -> String {
        "You have \(total) \(item.name(count: total)) to share"
    }

    func shareLabel(friends: Int) -> String {
        "Share equally with \(friends) \(receiver(count: friends))"
    }

    func eachLabel(count: Int) -> String {
        "Each gets \(count) \(item.name(count: count))"
    }

    func storyTitle(total: Int, friends: Int) -> String {
        "\(startLabel(total: total)). \(shareLabel(friends: friends)). How many each?"
    }

    func spokenQuestion(total: Int, friends: Int, each: Int) -> String {
        let totalWord = SpokenNumbers.word(for: total)
        let friendsWord = SpokenNumbers.word(for: friends)
        let eachWord = SpokenNumbers.word(for: each)
        let itemTotal = item.name(count: total)
        let itemEach = item.name(count: each)
        let receiverWord = receiver(count: friends)
        return "You have \(totalWord) \(itemTotal) to share equally with \(friendsWord) \(receiverWord). How many \(itemEach) does each get?"
    }

    static func pick(for dividend: Int, divisor: Int) -> DivisionStory {
        let item = StoryItem.pick(seedA: dividend, seedB: divisor)
        let receivers = [
            ("friends", "friend"),
            ("cousins", "cousin"),
            ("classmates", "classmate"),
            ("siblings", "sibling")
        ]
        let pair = receivers[(dividend + divisor) % receivers.count]
        return DivisionStory(
            item: item,
            receiverPlural: pair.0,
            receiverSingular: pair.1
        )
    }
}

enum MathProblemStory: Equatable, Sendable {
    case addition(AdditionStory)
    case subtraction(SubtractionStory)
    case multiplication(MultiplicationStory)
    case division(DivisionStory)

    static func make(
        for operation: MathOperation,
        operandA: Int,
        operandB: Int
    ) -> MathProblemStory {
        switch operation {
        case .addition:
            return .addition(AdditionStory.pick(for: operandA, operandB: operandB))
        case .subtraction:
            return .subtraction(SubtractionStory.pick(for: operandA, operandB: operandB))
        case .multiplication:
            return .multiplication(MultiplicationStory.pick(for: operandA, operandB: operandB))
        case .division:
            return .division(DivisionStory.pick(for: operandA, divisor: operandB))
        }
    }

    var iconName: String {
        switch self {
        case .addition(let story): story.item.iconName
        case .subtraction(let story): story.iconName
        case .multiplication(let story): story.item.iconName
        case .division(let story): story.item.iconName
        }
    }

    func spokenQuestion(operandA: Int, operandB: Int, answer: Int) -> String {
        switch self {
        case .addition(let story):
            return story.spokenQuestion(start: operandA, add: operandB)
        case .subtraction(let story):
            return story.spokenQuestionShort(start: operandA, remove: operandB)
        case .multiplication(let story):
            return story.spokenQuestion(groups: operandA, perGroup: operandB)
        case .division(let story):
            return story.spokenQuestion(total: operandA, friends: operandB, each: answer)
        }
    }
}
