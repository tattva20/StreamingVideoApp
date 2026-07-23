import os
import UIKit
import CoreData
import StreamingCore
import StreamingCorePlayback

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?

	private lazy var logger = Logger(subsystem: "com.octavio.rojas.StreamingVideoAppTV", category: "main")

	private lazy var httpClient: HTTPClient = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))

	private lazy var store: VideoStore & VideoImageDataStore & StoreScheduler & Sendable = {
		do {
			return try CoreDataVideoStore(
				storeURL: NSPersistentContainer
					.defaultDirectoryURL()
					.appendingPathComponent("video-store.sqlite"))
		} catch {
			logger.fault("Failed to instantiate CoreData store: \(error.localizedDescription)")
			return InMemoryVideoStore()
		}
	}()

	private lazy var videoService = VideoService(httpClient: httpClient, store: store, logger: logger)

	func scene(
		_ scene: UIScene,
		willConnectTo session: UISceneSession,
		options connectionOptions: UIScene.ConnectionOptions
	) {
		guard let windowScene = scene as? UIWindowScene else { return }
		let window = UIWindow(windowScene: windowScene)
		window.rootViewController = makeMessageViewController("Loading…")
		self.window = window
		window.makeKeyAndVisible()

		presentFirstVideoPlayer()
	}

	private func presentFirstVideoPlayer() {
		Task { @MainActor in
			do {
				let page = try await videoService.loadRemoteVideosWithLocalFallback()
				guard let video = page.items.first else {
					window?.rootViewController = makeMessageViewController("No videos available")
					return
				}
				window?.rootViewController = TVPlayerViewController(video: video)
			} catch {
				logger.error("Failed to load videos: \(error.localizedDescription)")
				window?.rootViewController = makeMessageViewController("Failed to load videos")
			}
		}
	}

	private func makeMessageViewController(_ message: String) -> UIViewController {
		let viewController = UIViewController()
		viewController.view.backgroundColor = .black

		let label = UILabel()
		label.text = message
		label.font = .preferredFont(forTextStyle: .title1)
		label.textColor = .label
		label.translatesAutoresizingMaskIntoConstraints = false
		viewController.view.addSubview(label)
		NSLayoutConstraint.activate([
			label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
			label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
		])
		return viewController
	}
}
