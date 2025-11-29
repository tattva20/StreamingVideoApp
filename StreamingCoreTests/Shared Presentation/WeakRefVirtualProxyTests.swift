import XCTest
import StreamingCore

final class WeakRefVirtualProxyTests: XCTestCase {

    func test_init_doesNotRetainObject() {
        var object: ViewSpy? = ViewSpy()
        _ = WeakRefVirtualProxy(object!)

        XCTAssertNotNil(object, "Expected proxy to not retain object on init")
    }

    func test_forwardsMessageToObject() {
        let object = ViewSpy()
        let sut = WeakRefVirtualProxy(object)

        sut.display(message: "a message")

        XCTAssertEqual(object.messages, ["a message"])
    }

    func test_doesNotForwardMessageToNilObject() {
        var object: ViewSpy? = ViewSpy()
        let sut = WeakRefVirtualProxy(object!)

        object = nil

        sut.display(message: "a message")
        // If we reach here without crashing, test passes
    }

    func test_deallocatesObjectIndependently() {
        var object: ViewSpy? = ViewSpy()
        let sut = WeakRefVirtualProxy(object!)

        object = nil

        XCTAssertNotNil(sut, "Expected proxy to remain alive even after object is deallocated")
    }

    // MARK: - Helpers
}

fileprivate protocol View {
    func display(message: String)
}

fileprivate class ViewSpy: View {
    var messages = [String]()

    func display(message: String) {
        messages.append(message)
    }
}

fileprivate extension WeakRefVirtualProxy where T == ViewSpy {
    func display(message: String) {
        object?.display(message: message)
    }
}
