//
//  SceneDelegate.swift
//  StreamingVideoApp
//
//  Created by Octavio Rojas on 29/11/25.
//

import UIKit
import StreamingCore
import StreamingCoreiOS

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = makeRootViewController()
        self.window = window
        window.makeKeyAndVisible()
    }

    private func makeRootViewController() -> UIViewController {
        // For demo purposes, using a stub loader with sample videos
        let videosVC = VideosViewController(loader: StubVideoLoader())
        videosVC.onVideoSelection = { [weak videosVC] video in
            let playerVC = VideoPlayerViewController(video: video)
            videosVC?.present(playerVC, animated: true)
        }

        return UINavigationController(rootViewController: videosVC)
    }
}

private class StubVideoLoader: VideoLoader {
    func load(completion: @escaping (Result<[Video], Error>) -> Void) {
        // Sample videos with publicly available test video URLs (using HTTPS)
        let sampleVideos = [
            Video(
                id: UUID(),
                title: "Big Buck Bunny",
                description: "A short computer-animated comedy film",
                url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!,
                thumbnailURL: URL(string: "https://via.placeholder.com/150")!,
                duration: 596
            ),
            Video(
                id: UUID(),
                title: "Elephant Dream",
                description: "The first Blender open movie",
                url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4")!,
                thumbnailURL: URL(string: "https://via.placeholder.com/150")!,
                duration: 653
            ),
            Video(
                id: UUID(),
                title: "For Bigger Blazes",
                description: "Sample video for testing",
                url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4")!,
                thumbnailURL: URL(string: "https://via.placeholder.com/150")!,
                duration: 15
            )
        ]

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(.success(sampleVideos))
        }
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
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

