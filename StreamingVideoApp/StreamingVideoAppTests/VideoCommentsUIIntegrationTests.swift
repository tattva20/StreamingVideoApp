//
//  VideoCommentsUIIntegrationTests.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas all rights reserved.
//
import XCTest
import StreamingCore
import StreamingCoreiOS
import StreamingVideoApp

@MainActor
class VideoCommentsUIIntegrationTests: XCTestCase {

	override func tearDown() {
		super.tearDown()
		// Process any pending async work to avoid Swift runtime crash during deallocation
		for _ in 0..<3 {
			RunLoop.current.run(until: Date())
		}
	}

	func test_commentsView_hasTitle() {
		let (sut, _) = makeSUT()

		sut.loadViewIfNeeded()

		XCTAssertEqual(sut.title, VideoCommentsPresenter.title)
	}

	func test_loadCommentsActions_requestCommentsFromLoader() async {
		let (sut, loader) = makeSUT()
		XCTAssertEqual(loader.loadCallCount, 0, "Expected no loading requests before view appears")

		sut.simulateAppearance()
		XCTAssertEqual(loader.loadCallCount, 1, "Expected a loading request once view appears")

		await loader.completeLoading(at: 0)
		sut.simulateUserInitiatedReload()
		XCTAssertEqual(loader.loadCallCount, 2, "Expected another loading request once user initiates a reload")

		await loader.completeLoading(at: 1)
		sut.simulateUserInitiatedReload()
		XCTAssertEqual(loader.loadCallCount, 3, "Expected yet another loading request once user initiates another reload")
	}


	func test_loadCommentsCompletion_rendersSuccessfullyLoadedComments() async {
		let comment0 = makeComment(message: "a message", username: "a username")
		let comment1 = makeComment(message: "another message", username: "another username")
		let (sut, loader) = makeSUT()

		sut.simulateAppearance()
		assertThat(sut, isRendering: [])

		await loader.completeLoading(with: [comment0], at: 0)
		assertThat(sut, isRendering: [comment0])

		sut.simulateUserInitiatedReload()
		await loader.completeLoading(with: [comment0, comment1], at: 1)
		assertThat(sut, isRendering: [comment0, comment1])
	}

	func test_loadCommentsCompletion_rendersSuccessfullyLoadedEmptyCommentsAfterNonEmptyComments() async {
		let comment = makeComment()
		let (sut, loader) = makeSUT()

		sut.simulateAppearance()
		await loader.completeLoading(with: [comment], at: 0)
		assertThat(sut, isRendering: [comment])

		sut.simulateUserInitiatedReload()
		await loader.completeLoading(with: [], at: 1)
		assertThat(sut, isRendering: [])
	}

	func test_loadCommentsCompletion_doesNotAlterCurrentRenderingStateOnError() async {
		let comment = makeComment()
		let (sut, loader) = makeSUT()

		sut.simulateAppearance()
		await loader.completeLoading(with: [comment], at: 0)
		assertThat(sut, isRendering: [comment])

		sut.simulateUserInitiatedReload()
		await loader.completeLoadingWithError(at: 1)
		assertThat(sut, isRendering: [comment])
	}

	func test_loadCommentsCompletion_rendersErrorMessageOnErrorUntilNextReload() async {
		let (sut, loader) = makeSUT()

		sut.simulateAppearance()
		XCTAssertEqual(sut.errorMessage, nil)

		await loader.completeLoadingWithError(at: 0)
		XCTAssertEqual(sut.errorMessage, loadError)

		sut.simulateUserInitiatedReload()
		XCTAssertEqual(sut.errorMessage, nil)
	}

	func test_tapOnErrorView_hidesErrorMessage() async {
		let (sut, loader) = makeSUT()

		sut.simulateAppearance()
		XCTAssertEqual(sut.errorMessage, nil)

		await loader.completeLoadingWithError(at: 0)
		XCTAssertEqual(sut.errorMessage, loadError)

		sut.simulateTapOnErrorMessage()
		XCTAssertEqual(sut.errorMessage, nil)
	}

	func test_loadingCommentsIndicator_isVisibleWhileLoadingComments() async {
		let (sut, loader) = makeSUT()

		sut.simulateAppearance()
		XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once view appears")

		await loader.completeLoading(at: 0)
		XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once loading completes")

		sut.simulateUserInitiatedReload()
		XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once user initiates a reload")

		await loader.completeLoadingWithError(at: 1)
		XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once loading completes with error")
	}

	// MARK: - Helpers

	private func makeSUT(
		file: StaticString = #filePath,
		line: UInt = #line
	) -> (sut: ListViewController, loader: LoaderSpy) {
		let loader = LoaderSpy()
		let sut = VideoCommentsUIComposer.commentsComposedWith(commentsLoader: loader.load)
		trackForMemoryLeaks(loader, file: file, line: line)
		trackForMemoryLeaks(sut, file: file, line: line)

		addTeardownBlock { [weak loader] in
			await loader?.cancelPendingRequests()
		}

		return (sut, loader)
	}

	private func assertThat(_ sut: ListViewController, isRendering comments: [VideoComment], file: StaticString = #filePath, line: UInt = #line) {
		XCTAssertEqual(sut.numberOfRenderedCommentViews(), comments.count, "comments count", file: file, line: line)

		comments.enumerated().forEach { index, comment in
			assertThat(sut, hasViewConfiguredFor: comment, at: index, file: file, line: line)
		}
	}

	private func assertThat(_ sut: ListViewController, hasViewConfiguredFor comment: VideoComment, at index: Int, file: StaticString = #filePath, line: UInt = #line) {
		let view = sut.commentView(at: index)

		guard let cell = view as? VideoCommentCell else {
			return XCTFail("Expected \(VideoCommentCell.self) instance, got \(String(describing: view)) instead", file: file, line: line)
		}

		XCTAssertEqual(cell.messageText, comment.message, "Expected message text to be \(String(describing: comment.message)) for comment view at index (\(index))", file: file, line: line)
		XCTAssertEqual(cell.usernameText, comment.username, "Expected username text to be \(String(describing: comment.username)) for comment view at index (\(index))", file: file, line: line)
	}

	private func makeComment(
		message: String = "any message",
		username: String = "any username"
	) -> VideoComment {
		return VideoComment(
			id: UUID(),
			message: message,
			createdAt: Date(),
			username: username
		)
	}

	private var loadError: String {
		LoadResourcePresenter<Any, DummyView>.loadError
	}

	private class DummyView: ResourceView {
		func display(_ viewModel: Any) {}
	}
}

extension VideoCommentsUIIntegrationTests {

	@MainActor
	class LoaderSpy {
		private let loader = StreamingVideoAppTests.LoaderSpy<Void, [VideoComment]>()

		var loadCallCount: Int { loader.requests.count }

		func load() async throws -> [VideoComment] {
			try await loader.load(())
		}

		func completeLoading(with comments: [VideoComment] = [], at index: Int = 0) async {
			await loader.complete(with: comments, at: index)
		}

		func completeLoadingWithError(at index: Int = 0) async {
			await loader.fail(with: anyNSError(), at: index)
		}

		func cancelPendingRequests() async {
			await loader.cancelPendingRequests()
		}
	}
}

extension ListViewController {
	func numberOfRenderedCommentViews() -> Int {
		numberOfRows(in: commentsSection)
	}

	func commentView(at row: Int) -> UITableViewCell? {
		cell(row: row, section: commentsSection)
	}

	private var commentsSection: Int { 0 }
}

private extension VideoCommentCell {
	var messageText: String? {
		return messageLabel.text
	}

	var usernameText: String? {
		return usernameLabel.text
	}
}
