import XCTest
import StreamingCore
@testable import StreamingCoreiOS

@MainActor
final class LoadResourcePresentationAdapterTests: XCTestCase {

    func test_init_doesNotLoadResource() {
        let (_, loader, _) = makeSUT()

        XCTAssertEqual(loader.loadCallCount, 0)
    }

    func test_loadResource_loadsResource() async {
        let (sut, loader, _) = makeSUT()

        sut.loadResource()
        await fulfillment(of: [loader.loadExpectation], timeout: 1.0)

        XCTAssertEqual(loader.loadCallCount, 1)
    }

    func test_loadResource_callsPresenterDidStartLoading() async {
        let (sut, loader, presenter) = makeSUT()

        sut.loadResource()
        await fulfillment(of: [loader.loadExpectation], timeout: 1.0)

        XCTAssertTrue(presenter.messages.first == .didStartLoading)
    }

    func test_loadResource_callsPresenterDidFinishLoadingOnSuccess() async {
        let resource = ["resource"]
        let (sut, loader, presenter) = makeSUT()
        loader.completeWith(.success(resource))

        sut.loadResource()
        await fulfillment(of: [loader.loadExpectation], timeout: 1.0)

        XCTAssertEqual(presenter.messages, [.didStartLoading, .didFinishLoadingWithResource(resource)])
    }

    func test_loadResource_callsPresenterDidFinishLoadingOnFailure() async {
        let error = anyNSError()
        let (sut, loader, presenter) = makeSUT()
        loader.completeWith(.failure(error))

        sut.loadResource()
        await fulfillment(of: [loader.loadExpectation], timeout: 1.0)

        XCTAssertEqual(presenter.messages, [.didStartLoading, .didFinishLoadingWithError])
    }

    func test_loadResource_doesNotLoadWhenAlreadyLoading() async {
        let (sut, loader, _) = makeSUT()

        sut.loadResource()
        sut.loadResource()
        await fulfillment(of: [loader.loadExpectation], timeout: 1.0)

        XCTAssertEqual(loader.loadCallCount, 1)
    }

    func test_loadResource_loadsAgainAfterCompletion() async {
        let (sut, loader, _) = makeSUT()
        loader.completeWith(.success(["resource"]))

        sut.loadResource()
        await fulfillment(of: [loader.loadExpectation], timeout: 1.0)

        let secondExpectation = XCTestExpectation(description: "Second load")
        loader.loadExpectation = secondExpectation

        sut.loadResource()
        await fulfillment(of: [secondExpectation], timeout: 1.0)

        XCTAssertEqual(loader.loadCallCount, 2)
    }

    func test_cancelLoad_cancelsTask() async {
        let (sut, loader, presenter) = makeSUT()
        loader.delay = 0.1

        sut.loadResource()
        sut.cancelLoad()

        try? await Task.sleep(for: .milliseconds(150))

        XCTAssertEqual(presenter.messages, [.didStartLoading])
    }

    func test_loadResource_doesNotRetainPresenter() async {
        let loader = LoaderSpy()
        var presenter: PresenterSpy? = PresenterSpy()
        var sut: LoadResourcePresentationAdapter? = LoadResourcePresentationAdapter(loader: loader.load, presenter: presenter!)
        loader.completeWith(.success(["resource"]))

        sut?.loadResource()
        await fulfillment(of: [loader.loadExpectation], timeout: 1.0)

        presenter = nil

        XCTAssertNil(presenter)
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: LoadResourcePresentationAdapter<[String], PresenterSpy>, loader: LoaderSpy, presenter: PresenterSpy) {
        let loader = LoaderSpy()
        let presenter = PresenterSpy()
        let sut = LoadResourcePresentationAdapter(loader: loader.load, presenter: presenter)
        return (sut, loader, presenter)
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
}

// MARK: - Test Doubles

@MainActor
private final class LoaderSpy {
    var loadCallCount = 0
    var loadExpectation = XCTestExpectation(description: "Load")
    var result: Result<[String], Error> = .success([])
    var delay: TimeInterval = 0

    func completeWith(_ result: Result<[String], Error>) {
        self.result = result
    }

    func load() async throws -> [String] {
        loadCallCount += 1
        loadExpectation.fulfill()

        if delay > 0 {
            try await Task.sleep(for: .seconds(delay))
        }

        return try result.get()
    }
}

@MainActor
private final class PresenterSpy: ResourcePresenting {
    typealias Resource = [String]

    enum Message: Equatable {
        case didStartLoading
        case didFinishLoadingWithResource([String])
        case didFinishLoadingWithError
    }

    var messages = [Message]()

    func didStartLoading() {
        messages.append(.didStartLoading)
    }

    func didFinishLoading(with resource: [String]) {
        messages.append(.didFinishLoadingWithResource(resource))
    }

    func didFinishLoading(with error: Error) {
        messages.append(.didFinishLoadingWithError)
    }
}
