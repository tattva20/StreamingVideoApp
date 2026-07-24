import XCTest
@testable import TattvaTV

@MainActor
final class TattvaTVTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        RunLoop.current.run(until: Date())
    }

    func test_appDelegate_didFinishLaunching_returnsTrue() {
        let sut = AppDelegate()

        let result = sut.application(.shared, didFinishLaunchingWithOptions: nil)

        XCTAssertTrue(result)
    }
}
