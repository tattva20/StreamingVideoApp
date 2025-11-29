import XCTest
import StreamingCore

@MainActor
class RemoteVideoLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()

        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load { _ in }

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load { _ in }
        sut.load { _ in }

        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .failure(.connectivity), when: {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        })
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

    private func expect(_ sut: RemoteVideoLoader,
                       toCompleteWith expectedResult: RemoteVideoLoader.Result,
                       when action: () -> Void,
                       file: StaticString = #filePath,
                       line: UInt = #line) {
        var capturedResults = [RemoteVideoLoader.Result]()
        sut.load { capturedResults.append($0) }

        action()

        XCTAssertEqual(capturedResults.count, 1, file: file, line: line)

        switch (capturedResults.first, expectedResult) {
        case let (.failure(receivedError), .failure(expectedError)):
            XCTAssertEqual(receivedError, expectedError, file: file, line: line)
        case let (.success(receivedVideos), .success(expectedVideos)):
            XCTAssertEqual(receivedVideos, expectedVideos, file: file, line: line)
        default:
            XCTFail("Expected result \(expectedResult), got \(String(describing: capturedResults.first)) instead", file: file, line: line)
        }
    }

    private class HTTPClientSpy: HTTPClient {
        var requestedURLs: [URL] = []
        var completions = [(HTTPClient.Result) -> Void]()

        func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
            requestedURLs.append(url)
            completions.append(completion)
        }

        func complete(with error: Error, at index: Int = 0) {
            completions[index](.failure(error))
        }
    }
}
