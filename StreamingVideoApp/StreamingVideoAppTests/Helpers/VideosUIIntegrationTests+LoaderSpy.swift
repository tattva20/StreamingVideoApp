//
//  VideosUIIntegrationTests+LoaderSpy.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation
import StreamingCore
import StreamingCoreiOS
import Combine

extension VideosUIIntegrationTests {

	@MainActor
	class LoaderSpy {

		// MARK: - VideoLoader

		private var videoRequests = [PassthroughSubject<Paginated<Video>, Error>]()

		var loadCallCount: Int {
			return videoRequests.count
		}

		func loadPublisher() -> AnyPublisher<Paginated<Video>, Error> {
			let publisher = PassthroughSubject<Paginated<Video>, Error>()
			videoRequests.append(publisher)
			return publisher.eraseToAnyPublisher()
		}

		func completeLoadingWithError(at index: Int = 0) {
			videoRequests[index].send(completion: .failure(anyNSError()))
		}

		func completeLoading(with videos: [Video] = [], at index: Int = 0) {
			videoRequests[index].send(Paginated(items: videos, loadMorePublisher: { [weak self] in
				self?.loadMorePublisher() ?? Empty().eraseToAnyPublisher()
			}))
			videoRequests[index].send(completion: .finished)
		}

		// MARK: - LoadMore

		private var loadMoreRequests = [PassthroughSubject<Paginated<Video>, Error>]()

		var loadMoreCallCount: Int {
			return loadMoreRequests.count
		}

		func loadMorePublisher() -> AnyPublisher<Paginated<Video>, Error> {
			let publisher = PassthroughSubject<Paginated<Video>, Error>()
			loadMoreRequests.append(publisher)
			return publisher.eraseToAnyPublisher()
		}

		func completeLoadMore(with videos: [Video] = [], lastPage: Bool = false, at index: Int = 0) {
			loadMoreRequests[index].send(Paginated(
				items: videos,
				loadMorePublisher: lastPage ? nil : { [weak self] in
					self?.loadMorePublisher() ?? Empty().eraseToAnyPublisher()
				}))
		}

		func completeLoadMoreWithError(at index: Int = 0) {
			loadMoreRequests[index].send(completion: .failure(anyNSError()))
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

		func cancelPendingRequests() async throws {
			try await imageLoader.cancelPendingRequests()
		}
	}

}
