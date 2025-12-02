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
import Combine

@MainActor
class VideoCommentsUIIntegrationTests: XCTestCase {

	func test_commentsView_hasTitle() {
		let (sut, _) = makeSUT()

		sut.loadViewIfNeeded()

		XCTAssertEqual(sut.title, VideoCommentsPresenter.title)
	}

	func test_loadCommentsActions_requestCommentsFromLoader() {
		let (sut, loader) = makeSUT()
		XCTAssertEqual(loader.loadCallCount, 0, "Expected no loading requests before view appears")

		sut.simulateAppearance()
		XCTAssertEqual(loader.loadCallCount, 1, "Expected a loading request once view appears")

		loader.completeLoading(at: 0)
		sut.simulateUserInitiatedReload()
		XCTAssertEqual(loader.loadCallCount, 2, "Expected another loading request once user initiates a reload")

		loader.completeLoading(at: 1)
		sut.simulateUserInitiatedReload()
		XCTAssertEqual(loader.loadCallCount, 3, "Expected yet another loading request once user initiates another reload")
	}


	func test_loadCommentsCompletion_rendersSuccessfullyLoadedComments() {
		let comment0 = makeComment(message: "a message", username: "a username")
		let comment1 = makeComment(message: "another message", username: "another username")
		let (sut, loader) = makeSUT()

		sut.simulateAppearance()
		assertThat(sut, isRendering: [])

		loader.completeLoading(with: [comment0], at: 0)
		assertThat(sut, isRendering: [comment0])

		sut.simulateUserInitiatedReload()
		loader.completeLoading(with: [comment0, comment1], at: 1)
		assertThat(sut, isRendering: [comment0, comment1])
	}

	func test_loadCommentsCompletion_rendersSuccessfullyLoadedEmptyCommentsAfterNonEmptyComments() {
		let comment = makeComment()
		let (sut, loader) = makeSUT()

		sut.simulateAppearance()
		loader.completeLoading(with: [comment], at: 0)
		assertThat(sut, isRendering: [comment])

		sut.simulateUserInitiatedReload()
		loader.completeLoading(with: [], at: 1)
		assertThat(sut, isRendering: [])
	}

	func test_loadCommentsCompletion_doesNotAlterCurrentRenderingStateOnError() {
		let comment = makeComment()
		let (sut, loader) = makeSUT()

		sut.simulateAppearance()
		loader.completeLoading(with: [comment], at: 0)
		assertThat(sut, isRendering: [comment])

		sut.simulateUserInitiatedReload()
		loader.completeLoadingWithError(at: 1)
		assertThat(sut, isRendering: [comment])
	}

	func test_loadCommentsCompletion_rendersErrorMessageOnErrorUntilNextReload() {
		let (sut, loader) = makeSUT()

		sut.simulateAppearance()
		XCTAssertEqual(sut.errorMessage, nil)

		loader.completeLoadingWithError(at: 0)
		XCTAssertEqual(sut.errorMessage, loadError)

		sut.simulateUserInitiatedReload()
		XCTAssertEqual(sut.errorMessage, nil)
	}

	func test_tapOnErrorView_hidesErrorMessage() {
		let (sut, loader) = makeSUT()

		sut.simulateAppearance()
		XCTAssertEqual(sut.errorMessage, nil)

		loader.completeLoadingWithError(at: 0)
		XCTAssertEqual(sut.errorMessage, loadError)

		sut.simulateTapOnErrorMessage()
		XCTAssertEqual(sut.errorMessage, nil)
	}

	func test_loadingCommentsIndicator_isVisibleWhileLoadingComments() {
		let (sut, loader) = makeSUT()

		sut.simulateAppearance()
		XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once view appears")

		loader.completeLoading(at: 0)
		XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once loading completes")

		sut.simulateUserInitiatedReload()
		XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once user initiates a reload")

		loader.completeLoadingWithError(at: 1)
		XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once loading completes with error")
	}

	// MARK: - Helpers

	private func makeSUT(
		file: StaticString = #filePath,
		line: UInt = #line
	) -> (sut: ListViewController, loader: LoaderSpy) {
		let loader = LoaderSpy()
		let sut = VideoCommentsUIComposer.commentsComposedWith(commentsLoader: loader.loadPublisher)
		trackForMemoryLeaks(loader, file: file, line: line)
		trackForMemoryLeaks(sut, file: file, line: line)
		return (sut, loader)
	}

	private func assertThat(_ sut: ListViewController, isRendering comments: [VideoComment], file: StaticString = #filePath, line: UInt = #line) {
		sut.view.enforceLayoutCycle()

		guard sut.numberOfRenderedCommentViews() == comments.count else {
			return XCTFail("Expected \(comments.count) comments, got \(sut.numberOfRenderedCommentViews()) instead.", file: file, line: line)
		}

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
		private var requests = [PassthroughSubject<[VideoComment], Error>]()

		var loadCallCount: Int {
			return requests.count
		}

		func loadPublisher() -> AnyPublisher<[VideoComment], Error> {
			let publisher = PassthroughSubject<[VideoComment], Error>()
			requests.append(publisher)
			return publisher.eraseToAnyPublisher()
		}

		func completeLoading(with comments: [VideoComment] = [], at index: Int = 0) {
			requests[index].send(comments)
			requests[index].send(completion: .finished)
		}

		func completeLoadingWithError(at index: Int = 0) {
			requests[index].send(completion: .failure(anyNSError()))
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
