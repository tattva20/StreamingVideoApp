//
//  VideoService.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas all rights reserved.
//
import os
import CoreData
import Foundation
import StreamingCore

@MainActor
final class VideoService {
	private let httpClient: HTTPClient
	private let store: VideoStore & VideoImageDataStore & StoreScheduler & Sendable
	private let logger: os.Logger

	private lazy var localVideoLoader: LocalVideoLoader = {
		LocalVideoLoader(store: store, currentDate: Date.init)
	}()

	private lazy var baseURL = URL(string: "https://streaming-videos-api.vercel.app")!

	init(
		httpClient: HTTPClient,
		store: VideoStore & VideoImageDataStore & StoreScheduler & Sendable,
		logger: os.Logger = os.Logger(subsystem: "com.streamingvideoapp.StreamingVideoApp", category: "main")
	) {
		self.httpClient = httpClient
		self.store = store
		self.logger = logger
	}

	func validateCache() {
		Task.immediate { @MainActor in
			await store.schedule { [store, logger] in
				do {
					let localVideoLoader = LocalVideoLoader(store: store, currentDate: Date.init)
					try localVideoLoader.validateCache()
				} catch {
					logger.error("Failed to validate cache with error: \(error.localizedDescription)")
				}
			}
		}
	}

	func loadComments(for video: Video) -> () async throws -> [VideoComment] {
		return { [httpClient, baseURL] in
			let url = VideoCommentsEndpoint.get(video.id).url(baseURL: baseURL)
			let (data, response) = try await httpClient.get(from: url)
			return try VideoCommentsMapper.map(data, from: response)
		}
	}

	func loadRemoteVideosWithLocalFallback() async throws -> Paginated<Video> {
		do {
			let items = try await loadRemoteVideos()
			try? localVideoLoader.save(items)
			return makeFirstPage(items: items)
		} catch {
			return makeFirstPage(items: try localVideoLoader.load())
		}
	}

	private func loadMoreRemoteVideos(last: Video?) async throws -> Paginated<Video> {
		async let remote = loadRemoteVideos(after: last)
		let cachedItems = try localVideoLoader.load()
		let newItems = try await remote
		let items = cachedItems + newItems
		try? localVideoLoader.save(items)
		return makePage(items: items, last: newItems.last)
	}

	private func loadRemoteVideos(after: Video? = nil) async throws -> [Video] {
		let url = VideoEndpoint.get(after: after).url(baseURL: baseURL)
		let (data, response) = try await httpClient.get(from: url)
		return try VideoItemsMapper.map(data, from: response)
	}

	private func makeFirstPage(items: [Video]) -> Paginated<Video> {
		makePage(items: items, last: items.last)
	}

	private func makePage(items: [Video], last: Video?) -> Paginated<Video> {
		Paginated(items: items, loadMore: last.map { last in
			{ @MainActor @Sendable in try await self.loadMoreRemoteVideos(last: last) }
		})
	}

	func loadLocalImageWithRemoteFallback(url: URL) async throws -> Data {
		do {
			return try await loadLocalImage(url: url)
		} catch {
			return try await loadAndCacheRemoteImage(url: url)
		}
	}

	private func loadLocalImage(url: URL) async throws -> Data {
		try await store.schedule { [store] in
			let localImageLoader = LocalVideoImageDataLoader(store: store)
			return try localImageLoader.loadImageData(from: url)
		}
	}

	private func loadAndCacheRemoteImage(url: URL) async throws -> Data {
		let (data, response) = try await httpClient.get(from: url)
		let imageData = try VideoImageDataMapper.map(data, from: response)
		await store.schedule { [store] in
			let localImageLoader = LocalVideoImageDataLoader(store: store)
			try? localImageLoader.save(data, for: url)
		}
		return imageData
	}
}

protocol StoreScheduler {
	@MainActor
	func schedule<T>(_ action: @escaping @Sendable () throws -> T) async rethrows -> T
}

extension CoreDataVideoStore: StoreScheduler {
	@MainActor
	func schedule<T>(_ action: @escaping @Sendable () throws -> T) async rethrows -> T {
		if contextQueue == .main {
			return try action()
		} else {
			return try await perform(action)
		}
	}
}

extension InMemoryVideoStore: StoreScheduler {
	@MainActor
	func schedule<T>(_ action: @escaping @Sendable () throws -> T) async rethrows -> T {
		try action()
	}
}
