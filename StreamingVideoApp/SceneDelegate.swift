//
//  SceneDelegate.swift
//  StreamingVideoApp
//
//  Created by Octavio Rojas on 29/11/25.
//

import UIKit
import CoreData
import StreamingCore
import StreamingCoreiOS

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private lazy var store: VideoStore = {
        let storeURL = NSPersistentContainer.defaultDirectoryURL()
            .appendingPathComponent("video-store.sqlite")
        return try! CoreDataVideoStore(storeURL: storeURL)
    }()

    private lazy var localVideoLoader = LocalVideoLoader(store: store, currentDate: Date.init)

    private lazy var httpClient: HTTPClient = URLSessionHTTPClient()

    private lazy var remoteVideoLoader: VideoLoader = {
        // Production API: GitHub Pages
        // Repository: https://github.com/tattva20/streaming-videos-api
        // Serves videos.json with direct streaming URLs
        let apiURL = URL(string: "https://tattva20.github.io/streaming-videos-api/videos.json")!
        return RemoteVideoLoader(url: apiURL, client: httpClient)
    }()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        configureAudioSession()

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = makeRootViewController()
        self.window = window
        window.makeKeyAndVisible()
    }

    private func configureAudioSession() {
        let audioSessionConfigurator = AVAudioSessionAdapter()
        try? audioSessionConfigurator.configureForPlayback()
    }

    private func makeRootViewController() -> UIViewController {
        let videoLoader = makeVideoLoaderWithCacheFallback()
        let videosVC = VideosViewController(
            loader: videoLoader,
            onVideoSelection: { [weak self] video in
                guard let rootVC = self?.window?.rootViewController as? UINavigationController else { return }
                let playerVC = VideoPlayerViewController(video: video)
                rootVC.topViewController?.present(playerVC, animated: true)
            }
        )

        return UINavigationController(rootViewController: videosVC)
    }

    private func makeVideoLoaderWithCacheFallback() -> VideoLoader {
        // Composition: Remote API -> Cache on success -> Fallback to local cache on error
        let cachedRemoteLoader = VideoLoaderCacheDecorator(
            decoratee: remoteVideoLoader,
            cache: localVideoLoader
        )
        return VideoLoaderComposite(
            primary: cachedRemoteLoader,
            fallback: localVideoLoader
        )
    }
}

extension SceneDelegate {
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Validate cache when app enters background
        try? localVideoLoader.validateCache()
    }


}

