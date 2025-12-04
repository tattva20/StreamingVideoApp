//
//  LoadResourcePresentationAdapterTests.swift
//  StreamingVideoAppTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import Combine
import StreamingCore
@testable import StreamingVideoApp

@MainActor
final class LoadResourcePresentationAdapterTests: XCTestCase {
	private var cancellables = Set<AnyCancellable>()

	override func tearDown() {
		super.tearDown()
		cancellables.removeAll()
		for _ in 0..<3 {
			RunLoop.current.run(until: Date())
		}
	}

	// MARK: - Cancellation Tests

	func test_loadResource_cancelsExistingRequestOnNewLoad() {
		var cancelCount = 0
		let loader = makeDelayedLoader(cancelHandler: { cancelCount += 1 })
		let sut = makeSUT(loader: loader)

		sut.loadResource()
		sut.loadResource()

		XCTAssertEqual(cancelCount, 1, "Expected first load to be cancelled when second load starts")
	}

	func test_loadResource_allowsNewLoadAfterCancellation() {
		var loadCount = 0
		let loader = makeDelayedLoader(loadHandler: { loadCount += 1 })
		let sut = makeSUT(loader: loader)

		sut.loadResource()
		sut.loadResource()

		XCTAssertEqual(loadCount, 2, "Expected two load attempts")
	}

	func test_loadResource_notifiesLoadingStartOnEachLoad() {
		let presenter = LoadingViewSpy()
		let sut = makeSUT(loader: makeDelayedLoader(), presenter: presenter)

		sut.loadResource()
		sut.loadResource()

		XCTAssertEqual(presenter.loadingCallCount, 2, "Expected loading notification on each load attempt")
	}

	func test_loadResource_deliversResourceOnSuccess() async {
		let expectedResource = "test resource"
		let presenter = LoadingViewSpy()
		let sut = makeSUT(loader: makeImmediateLoader(result: .success(expectedResource)), presenter: presenter)

		sut.loadResource()
		await Task.yield()
		try? await Task.sleep(nanoseconds: 100_000_000)

		XCTAssertEqual(presenter.receivedResources, [expectedResource])
		XCTAssertEqual(presenter.loadingStates.last, false, "Expected loading to stop after success")
	}

	func test_loadResource_deliversErrorOnFailure() async {
		let presenter = LoadingViewSpy()
		let sut = makeSUT(loader: makeImmediateLoader(result: .failure(anyNSError())), presenter: presenter)

		sut.loadResource()
		await Task.yield()
		try? await Task.sleep(nanoseconds: 100_000_000)

		XCTAssertEqual(presenter.errorCallCount, 1)
		XCTAssertEqual(presenter.loadingStates.last, false, "Expected loading to stop after failure")
	}

	// MARK: - Helpers

	private func makeSUT(
		loader: @escaping () -> AnyPublisher<String, Error>,
		presenter: LoadingViewSpy? = nil,
		file: StaticString = #filePath,
		line: UInt = #line
	) -> LoadResourcePresentationAdapter<String, ResourceViewSpy> {
		let sut = LoadResourcePresentationAdapter<String, ResourceViewSpy>(loader: loader)
		let loadingSpy = presenter ?? LoadingViewSpy()
		let resourceView = ResourceViewSpy(loadingSpy: loadingSpy)
		sut.presenter = LoadResourcePresenter(
			resourceView: resourceView,
			loadingView: loadingSpy,
			errorView: loadingSpy
		)
		trackForMemoryLeaks(sut, file: file, line: line)
		return sut
	}

	private func makeDelayedLoader(
		loadHandler: @escaping () -> Void = {},
		cancelHandler: @escaping () -> Void = {}
	) -> () -> AnyPublisher<String, Error> {
		return {
			loadHandler()
			return Deferred {
				Future<String, Error> { _ in
					// Never completes - simulates slow/hanging request
				}
			}
			.handleEvents(receiveCancel: cancelHandler)
			.eraseToAnyPublisher()
		}
	}

	private func makeImmediateLoader(result: Result<String, Error>) -> () -> AnyPublisher<String, Error> {
		return {
			result.publisher.eraseToAnyPublisher()
		}
	}

	private func anyNSError() -> NSError {
		NSError(domain: "test", code: 0)
	}

	@MainActor
	private final class ResourceViewSpy: ResourceView {
		private(set) var displayedResources: [String] = []
		private weak var loadingSpy: LoadingViewSpy?

		init(loadingSpy: LoadingViewSpy? = nil) {
			self.loadingSpy = loadingSpy
		}

		func display(_ viewModel: String) {
			displayedResources.append(viewModel)
			loadingSpy?.recordResource(viewModel)
		}
	}

	@MainActor
	private final class LoadingViewSpy: ResourceLoadingView, ResourceErrorView {
		private(set) var loadingCallCount = 0
		private(set) var loadingStates: [Bool] = []
		private(set) var errorCallCount = 0
		private(set) var receivedResources: [String] = []

		func display(_ viewModel: ResourceLoadingViewModel) {
			loadingCallCount += 1
			loadingStates.append(viewModel.isLoading)
		}

		func display(_ viewModel: ResourceErrorViewModel) {
			if viewModel.message != nil {
				errorCallCount += 1
			}
		}

		func recordResource(_ resource: String) {
			receivedResources.append(resource)
		}
	}
}
