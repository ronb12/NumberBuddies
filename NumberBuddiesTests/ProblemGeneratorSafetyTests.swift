import XCTest
@testable import NumberBuddies

final class ProblemGeneratorSafetyTests: XCTestCase {
    func testEarlyLowLevelMultiplicationDoesNotCrash() {
        let generator = ProblemGenerator(ageGroup: .early)
        for _ in 0..<20 {
            _ = generator.makeProblem(for: .multiplication, difficulty: 1)
        }
    }

    func testEarlyLowLevelDivisionDoesNotCrash() {
        let generator = ProblemGenerator(ageGroup: .early)
        for _ in 0..<20 {
            _ = generator.makeProblem(for: .division, difficulty: 2)
        }
    }
}
