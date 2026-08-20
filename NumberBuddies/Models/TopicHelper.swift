import Foundation

enum TopicHelper: Equatable, Sendable {
    case addition(a: Int, b: Int)
    case subtraction(total: Int, remove: Int)
    case multiplicationThenSubtract(groups: Int, perGroup: Int, remove: Int)
    case difference(larger: Int, smaller: Int)
    case percentOf(percent: Int, whole: Int)
    case decimalTenthsSum(a: Int, b: Int)
}
