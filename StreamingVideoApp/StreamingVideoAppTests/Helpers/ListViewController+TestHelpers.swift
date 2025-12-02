import UIKit
import StreamingCoreiOS

extension ListViewController {
	func simulateAppearance() {
		if !isViewLoaded {
			loadViewIfNeeded()
			prepareForFirstAppearance()
		}

		beginAppearanceTransition(true, animated: false)
		endAppearanceTransition()
	}

	private func prepareForFirstAppearance() {
		setSmallFrameToPreventRenderingCells()
		replaceRefreshControlWithFakeForiOS17PlusSupport()
	}

	private func setSmallFrameToPreventRenderingCells() {
		tableView.frame = CGRect(x: 0, y: 0, width: 390, height: 1)
	}

	private func replaceRefreshControlWithFakeForiOS17PlusSupport() {
		let fakeRefreshControl = FakeUIRefreshControl()

		refreshControl?.allTargets.forEach { target in
			refreshControl?.actions(forTarget: target, forControlEvent: .valueChanged)?.forEach { action in
				fakeRefreshControl.addTarget(target, action: Selector(action), for: .valueChanged)
			}
		}

		refreshControl = fakeRefreshControl
	}

	private class FakeUIRefreshControl: UIRefreshControl {
		private var _isRefreshing = false

		override var isRefreshing: Bool { _isRefreshing }

		override func beginRefreshing() {
			_isRefreshing = true
		}

		override func endRefreshing() {
			_isRefreshing = false
		}
	}

	func simulateUserInitiatedReload() {
		refreshControl?.simulatePullToRefresh()
	}

	var isShowingLoadingIndicator: Bool {
		return refreshControl?.isRefreshing == true
	}

	func simulateErrorViewTap() {
		errorView.simulateTap()
	}

	func simulateTapOnErrorMessage() {
		errorView.simulateTap()
	}

	var errorMessage: String? {
		return errorView.message
	}

	func numberOfRows(in section: Int) -> Int {
		tableView.numberOfSections > section ? tableView.numberOfRows(inSection: section) : 0
	}

	func cell(row: Int, section: Int) -> UITableViewCell? {
		guard numberOfRows(in: section) > row else {
			return nil
		}
		let ds = tableView.dataSource
		let index = IndexPath(row: row, section: section)
		return ds?.tableView(tableView, cellForRowAt: index)
	}
}

extension ListViewController {
	@discardableResult
	func simulateVideoViewVisible(at index: Int) -> VideoCell? {
		return videoView(at: index) as? VideoCell
	}

	@discardableResult
	func simulateVideoBecomingVisibleAgain(at row: Int) -> VideoCell? {
		let view = simulateVideoViewNotVisible(at: row)

		let delegate = tableView.delegate
		let index = IndexPath(row: row, section: videosSection)
		delegate?.tableView?(tableView, willDisplay: view!, forRowAt: index)

		return view
	}

	@discardableResult
	func simulateVideoViewNotVisible(at row: Int) -> VideoCell? {
		let view = simulateVideoViewVisible(at: row)

		let delegate = tableView.delegate
		let index = IndexPath(row: row, section: videosSection)
		delegate?.tableView?(tableView, didEndDisplaying: view!, forRowAt: index)

		return view
	}

	func simulateTapOnVideo(at row: Int) {
		let delegate = tableView.delegate
		let index = IndexPath(row: row, section: videosSection)
		delegate?.tableView?(tableView, didSelectRowAt: index)
	}

	func simulateTapOnVideoView(at row: Int) {
		simulateTapOnVideo(at: row)
	}

	func simulateVideoViewNearVisible(at row: Int) {
		let ds = tableView.prefetchDataSource
		let index = IndexPath(row: row, section: videosSection)
		ds?.tableView(tableView, prefetchRowsAt: [index])
	}

	func simulateVideoViewNotNearVisible(at row: Int) {
		simulateVideoViewNearVisible(at: row)

		let ds = tableView.prefetchDataSource
		let index = IndexPath(row: row, section: videosSection)
		ds?.tableView?(tableView, cancelPrefetchingForRowsAt: [index])
	}

	func renderedVideoImageData(at index: Int) -> Data? {
		return simulateVideoViewVisible(at: index)?.renderedImage
	}

	func numberOfRenderedVideoViews() -> Int {
		numberOfRows(in: videosSection)
	}

	func videoView(at row: Int) -> UITableViewCell? {
		cell(row: row, section: videosSection)
	}

	private var videosSection: Int { 0 }
	private var loadMoreSection: Int { 1 }
}

extension ListViewController {
	func simulateLoadMoreAction() {
		guard let view = loadMoreView() else { return }

		let delegate = tableView.delegate
		let index = IndexPath(row: 0, section: loadMoreSection)
		delegate?.tableView?(tableView, willDisplay: view, forRowAt: index)
	}

	func simulateTapOnLoadMoreError() {
		let delegate = tableView.delegate
		let index = IndexPath(row: 0, section: loadMoreSection)
		delegate?.tableView?(tableView, didSelectRowAt: index)
	}

	var isShowingLoadMoreIndicator: Bool {
		return loadMoreView()?.isLoading == true
	}

	var loadMoreErrorMessage: String? {
		return loadMoreView()?.message
	}

	var canLoadMore: Bool {
		loadMoreView() != nil
	}

	private func loadMoreView() -> LoadMoreCell? {
		cell(row: 0, section: loadMoreSection) as? LoadMoreCell
	}
}
