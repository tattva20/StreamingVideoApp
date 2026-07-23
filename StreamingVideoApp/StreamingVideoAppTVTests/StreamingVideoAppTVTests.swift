import XCTest
@testable import StreamingVideoAppTV

@MainActor
final class StreamingVideoAppTVTests: XCTestCase {
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
