//
//  SceneDelegate.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas all rights reserved.
//
import os
import UIKit
import CoreData
import Combine
import StreamingCore
import StreamingCoreiOS

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?

	private var videoPlayerFactory: ((Video) -> VideoPlayer)?

	private lazy var analyticsStore: AnalyticsStore = {
		InMemoryAnalyticsStore()
	}()

	private lazy var analyticsLogger: PlaybackAnalyticsLogger = {
		PlaybackAnalyticsService(store: analyticsStore)
	}()

	private lazy var structuredLogger: any StreamingCore.Logger = {
		LoggingConfiguration.makeLogger()
	}()

	private lazy var scheduler: AnyDispatchQueueScheduler = {
		if let store = store as? CoreDataVideoStore {
			return .scheduler(for: store)
		}

		return DispatchQueue(
			label: "com.streamingvideoapp.infra.queue",
			qos: .userInitiated
		).eraseToAnyScheduler()
	}()

	private lazy var httpClient: HTTPClient = {
		URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
	}()

	private lazy var logger = Logger(subsystem: "com.streamingvideoapp.StreamingVideoApp", category: "main")

	private lazy var store: VideoStore & VideoImageDataStore & StoreScheduler & Sendable = {
		do {
			return try CoreDataVideoStore(
				storeURL: NSPersistentContainer
					.defaultDirectoryURL()
					.appendingPathComponent("video-store.sqlite"))
		} catch {
			assertionFailure("Failed to instantiate CoreData store with error: \(error.localizedDescription)")
			logger.fault("Failed to instantiate CoreData store with error: \(error.localizedDescription)")
			return InMemoryVideoStore()
		}
	}()

	private lazy var localVideoLoader: LocalVideoLoader = {
		LocalVideoLoader(store: store, currentDate: Date.init)
	}()

	private lazy var baseURL = URL(string: "https://streaming-videos-c6camc99n-financieraufc-5358s-projects.vercel.app")!

	private lazy var navigationController = UINavigationController(
		rootViewController: VideosUIComposer.videosComposedWith(
			videoLoader: makeRemoteVideoLoaderWithLocalFallback,
			imageLoader: loadLocalImageWithRemoteFallback,
			selection: showVideoPlayer))

	convenience init(
		httpClient: HTTPClient,
		store: VideoStore & VideoImageDataStore & StoreScheduler & Sendable,
		videoPlayerFactory: ((Video) -> VideoPlayer)? = nil
	) {
		self.init()
		self.httpClient = httpClient
		self.store = store
		self.videoPlayerFactory = videoPlayerFactory
	}

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let scene = (scene as? UIWindowScene) else { return }

		configureAudioSession()
		window = UIWindow(windowScene: scene)
		configureWindow()
	}

	private func configureAudioSession() {
		// Skip audio session configuration during tests to avoid simulator-only malloc crash
		// See: https://stackoverflow.com/questions/78182592/a-fix-for-addinstanceforfactory-no-factory-registered-for-id-cfuuid-0x60000
		guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }

		let audioSessionConfigurator = AVAudioSessionAdapter()
		try? audioSessionConfigurator.configureForPlayback()
	}

	func configureWindow() {
		window?.rootViewController = navigationController
		window?.makeKeyAndVisible()
	}

	func sceneWillResignActive(_ scene: UIScene) {
		scheduler.schedule { [localVideoLoader, logger] in
			do {
				try localVideoLoader.validateCache()
			} catch {
				logger.error("Failed to validate cache with error: \(error.localizedDescription)")
			}
		}
	}

	private func showVideoPlayer(for video: Video) {
		let commentsController = VideoCommentsUIComposer.commentsComposedWith(
			commentsLoader: { [httpClient, baseURL] in
				let url = VideoCommentsEndpoint.get(video.id).url(baseURL: baseURL)
				return httpClient
					.getPublisher(url: url)
					.tryMap(VideoCommentsMapper.map)
					.eraseToAnyPublisher()
			})

		let player = videoPlayerFactory?(video)
		let videoPlayerController = VideoPlayerUIComposer.videoPlayerComposedWith(
			video: video,
			player: player,
			commentsController: commentsController,
			analyticsLogger: analyticsLogger,
			structuredLogger: structuredLogger)
		navigationController.pushViewController(videoPlayerController, animated: true)
	}

	private func makeRemoteVideoLoaderWithLocalFallback() -> AnyPublisher<Paginated<Video>, Error> {
		makeRemoteVideoLoader()
			.receive(on: scheduler)
			.caching(to: localVideoLoader)
			.fallback(to: localVideoLoader.loadPublisher)
			.map(makeFirstPage)
			.eraseToAnyPublisher()
	}

	private func makeRemoteLoadMoreLoader(last: Video?) -> AnyPublisher<Paginated<Video>, Error> {
		localVideoLoader.loadPublisher()
			.zip(makeRemoteVideoLoader(after: last))
			.map { (cachedItems, newItems) in
				(cachedItems + newItems, newItems.last)
			}
			.map(makePage)
			.receive(on: scheduler)
			.caching(to: localVideoLoader)
			.subscribe(on: scheduler)
			.eraseToAnyPublisher()
	}

	private func makeRemoteVideoLoader(after: Video? = nil) -> AnyPublisher<[Video], Error> {
		let url = VideoEndpoint.get(after: after).url(baseURL: baseURL)

		return httpClient
			.getPublisher(url: url)
			.tryMap(VideoItemsMapper.map)
			.eraseToAnyPublisher()
	}

	private func makeFirstPage(items: [Video]) -> Paginated<Video> {
		makePage(items: items, last: items.last)
	}

	private func makePage(items: [Video], last: Video?) -> Paginated<Video> {
		Paginated(items: items, loadMorePublisher: last.map { last in
			{ self.makeRemoteLoadMoreLoader(last: last) }
		})
	}

	private func loadLocalImageWithRemoteFallback(url: URL) async throws -> Data {
		do {
			return try await loadLocalImage(url: url)
		} catch {
			return try await loadAndCacheRemoteImage(url: url)
		}
	}

	private func loadLocalImage(url: URL) async throws -> Data {
		try await store.schedule { [store] in
			let localImageLoader = LocalVideoImageDataLoader(store: store)
			let imageData = try localImageLoader.loadImageData(from: url)
			return imageData
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