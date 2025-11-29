import XCTest
import StreamingCore

@MainActor
class RemoteVideoLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()

        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = anyURL(),
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: RemoteVideoLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteVideoLoader(url: url, client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }

    private class HTTPClientSpy: HTTPClient {
        var requestedURLs: [URL] = []

        func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
            requestedURLs.append(url)
        }
    }
}
