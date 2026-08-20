import XCTest
@testable import NumberBuddies

final class CheerSoundTests: XCTestCase {
    func testCheerClipsAreBundled() {
        let names = [
            "cheer-pop",
            "cheer-sparkle",
            "cheer-star",
            "cheer-yay",
            "cheer-bonus",
        ]

        for name in names {
            let url = Bundle.main.url(forResource: name, withExtension: "caf", subdirectory: "Resources/Cheers")
                ?? Bundle.main.url(forResource: name, withExtension: "caf", subdirectory: "Cheers")
                ?? Bundle.main.url(forResource: name, withExtension: "caf")
            XCTAssertNotNil(url, "Missing bundled cheer clip \(name).caf")
        }
    }

    func testCheerSoundsDefaultOn() {
        XCTAssertTrue(AppSettings.cheerSoundsEnabled)
    }
}
