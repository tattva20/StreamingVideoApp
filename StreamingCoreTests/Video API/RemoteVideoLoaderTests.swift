import XCTest
import StreamingCore

@MainActor
class RemoteVideoLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()

        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    func test_load_requestsDataFromURL() async throws {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        client.stub(url: url, withStatusCode: 200, data: makeVideosJSON([]))

        _ = try? await sut.load()

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_loadTwice_requestsDataFromURLTwice() async throws {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        client.stub(url: url, withStatusCode: 200, data: makeVideosJSON([]))

        _ = try? await sut.load()
        _ = try? await sut.load()

        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    func test_load_deliversErrorOnClientError() async {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        let clientError = NSError(domain: "Test", code: 0)
        client.stub(url: url, with: clientError)

        do {
            _ = try await sut.load()
            XCTFail("Expected connectivity error")
        } catch {
            XCTAssertEqual(error as? RemoteVideoLoader.Error, .connectivity)
        }
    }

    func test_load_deliversErrorOnNon200HTTPResponse() async {
        let samples = [199, 201, 300, 400, 500]

        for code in samples {
            let url = URL(string: "https://a-url-\(code).com")!
            let (sut, client) = makeSUT(url: url)

            let json = makeVideosJSON([])
            client.stub(url: url, withStatusCode: code, data: json)

            do {
                _ = try await sut.load()
                XCTFail("Expected invalidData error for status code \(code)")
            } catch {
                XCTAssertEqual(error as? RemoteVideoLoader.Error, .invalidData)
            }
        }
    }

    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() async {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        let invalidJSON = Data("invalid json".utf8)
        client.stub(url: url, withStatusCode: 200, data: invalidJSON)

        do {
            _ = try await sut.load()
            XCTFail("Expected invalidData error")
        } catch {
            XCTAssertEqual(error as? RemoteVideoLoader.Error, .invalidData)
        }
    }

    func test_load_deliversNoVideosOn200HTTPResponseWithEmptyJSONList() async throws {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        let emptyListJSON = makeVideosJSON([])
        client.stub(url: url, withStatusCode: 200, data: emptyListJSON)

        let videos = try await sut.load()

        XCTAssertEqual(videos, [])
    }

    func test_load_deliversVideosOn200HTTPResponseWithJSONVideos() async throws {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

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

        let expectedVideos = [video1.model, video2.model]
        let json = makeVideosJSON([video1.json, video2.json])
        client.stub(url: url, withStatusCode: 200, data: json)

        let receivedVideos = try await sut.load()

        XCTAssertEqual(receivedVideos, expectedVideos)
    }

    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() async {
        let url = anyURL()
        let client = HTTPClientSpy()
        var sut: RemoteVideoLoader? = RemoteVideoLoader(url: url, client: client)

        client.stub(url: url, withStatusCode: 200, data: makeVideosJSON([]))

        weak var weakSUT = sut
        sut = nil

        XCTAssertNil(weakSUT, "SUT should be deallocated")
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
        private var stubs: [URL: Result<(Data, HTTPURLResponse), Error>] = [:]

        func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
            requestedURLs.append(url)
            guard let result = stubs[url] else {
                throw NSError(domain: "HTTPClientSpy", code: 0, userInfo: [NSLocalizedDescriptionKey: "No stub configured for URL: \(url)"])
            }
            return try result.get()
        }

        func stub(url: URL, with error: Error) {
            stubs[url] = .failure(error)
        }

        func stub(url: URL, withStatusCode code: Int, data: Data) {
            let response = HTTPURLResponse(
                url: url,
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            stubs[url] = .success((data, response))
        }
    }
}
