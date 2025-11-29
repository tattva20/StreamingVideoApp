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

    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()

        let samples = [199, 201, 300, 400, 500]

        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: .failure(.invalidData), when: {
                let json = makeVideosJSON([])
                client.complete(withStatusCode: code, data: json, at: index)
            })
        }
    }

    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .failure(.invalidData), when: {
            let invalidJSON = Data("invalid json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        })
    }

    func test_load_deliversNoVideosOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .success([]), when: {
            let emptyListJSON = makeVideosJSON([])
            client.complete(withStatusCode: 200, data: emptyListJSON)
        })
    }

    func test_load_deliversVideosOn200HTTPResponseWithJSONVideos() {
        let (sut, client) = makeSUT()

        let video1 = makeVideo(
            id: UUID(),
            title: "a title",
            description: "a description",
            url: URL(string: "https://any-url.com/video1.mp4")!,
            thumbnailURL: URL(string: "https://any-url.com/thumb1.jpg")!,
            duration: 120
        )

        let video2 = makeVideo(
            id: UUID(),
            title: "another title",
            description: nil,
            url: URL(string: "https://any-url.com/video2.mp4")!,
            thumbnailURL: URL(string: "https://any-url.com/thumb2.jpg")!,
            duration: 240
        )

        let videos = [video1.model, video2.model]

        expect(sut, toCompleteWith: .success(videos), when: {
            let json = makeVideosJSON([video1.json, video2.json])
            client.complete(withStatusCode: 200, data: json)
        })
    }

    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let url = anyURL()
        let client = HTTPClientSpy()
        var sut: RemoteVideoLoader? = RemoteVideoLoader(url: url, client: client)

        var capturedResults = [RemoteVideoLoader.Result]()
        sut?.load { capturedResults.append($0) }

        sut = nil
        client.complete(withStatusCode: 200, data: makeVideosJSON([]))

        XCTAssertTrue(capturedResults.isEmpty)
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

    private func makeVideo(id: UUID, title: String, description: String?, url: URL, thumbnailURL: URL, duration: TimeInterval) -> (model: Video, json: [String: Any]) {
        let model = Video(id: id, title: title, description: description, url: url, thumbnailURL: thumbnailURL, duration: duration)

        let json: [String: Any] = [
            "id": id.uuidString,
            "title": title,
            "description": description as Any,
            "url": url.absoluteString,
            "thumbnail_url": thumbnailURL.absoluteString,
            "duration": duration
        ].compactMapValues { $0 }

        return (model, json)
    }

    private func makeVideosJSON(_ videos: [[String: Any]]) -> Data {
        let json = ["videos": videos]
        return try! JSONSerialization.data(withJSONObject: json)
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

        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            completions[index](.success((data, response)))
        }
    }
}
