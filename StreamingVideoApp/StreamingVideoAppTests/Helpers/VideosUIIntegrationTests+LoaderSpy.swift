//
//  VideosUIIntegrationTests+LoaderSpy.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation
import StreamingCore
import StreamingCoreiOS

extension VideosUIIntegrationTests {

	@MainActor
	class LoaderSpy {

		// MARK: - VideoLoader

		private var videoLoader = StreamingVideoAppTests.LoaderSpy<Void, Paginated<Video>>()

		var loadCallCount: Int {
			return videoLoader.requests.count
		}

		func load() async throws -> Paginated<Video> {
			try await videoLoader.load(())
		}

		func completeLoadingWithError(at index: Int = 0) async {
			videoLoader.fail(with: anyNSError(), at: index)
		}

		func completeLoading(with videos: [Video] = [], at index: Int = 0) async {
			videoLoader.complete(
				with: Paginated(
					items: videos,
					loadMore: { @MainActor [weak self] in
						try await self?.loadMore() ?? Paginated(items: [])
					}),
				at: index)
		}

		// MARK: - LoadMore

		private var loadMoreLoader = StreamingVideoAppTests.LoaderSpy<Void, Paginated<Video>>()

		var loadMoreCallCount: Int {
			return loadMoreLoader.requests.count
		}

		func loadMore() async throws -> Paginated<Video> {
			try await loadMoreLoader.load(())
		}

		func completeLoadMore(with videos: [Video] = [], lastPage: Bool = false, at index: Int = 0) async {
			let loadMore: @Sendable () async throws -> Paginated<Video> = { @MainActor [weak self] in
				try await self?.loadMore() ?? Paginated(items: [])
			}

			loadMoreLoader.complete(
				with: Paginated(
					items: videos,
					loadMore: lastPage ? nil : loadMore),
				at: index)
		}

		func completeLoadMoreWithError(at index: Int = 0) async {
			loadMoreLoader.fail(with: anyNSError(), at: index)
		}

		// MARK: - VideoImageDataLoader

		private var imageLoader = StreamingVideoAppTests.LoaderSpy<URL, Data>()

		var loadedImageURLs: [URL] {
			return imageLoader.requests.map { $0.param }
		}

		var cancelledImageURLs: [URL] {
			return imageLoader.requests.filter({ $0.result == .cancelled }).map { $0.param }
		}

		func loadImageData(from url: URL) async throws -> Data {
			try await imageLoader.load(url)
		}

		func completeImageLoading(with imageData: Data = Data(), at index: Int = 0) {
			imageLoader.complete(with: imageData, at: index)
		}

		func completeImageLoadingWithError(at index: Int = 0) {
			imageLoader.fail(with: anyNSError(), at: index)
		}

		func imageResult(at index: Int, timeout: TimeInterval = 1) async throws -> AsyncResult {
			try await imageLoader.result(at: index, timeout: timeout)
		}

		func cancelPendingRequests() {
			imageLoader.cancelPendingRequests()
			videoLoader.cancelPendingRequests()
			loadMoreLoader.cancelPendingRequests()
		}
	}

}
