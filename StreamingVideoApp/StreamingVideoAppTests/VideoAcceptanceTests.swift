//
//  VideoAcceptanceTests.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas all rights reserved.
//
import XCTest
import StreamingCore
import StreamingCoreiOS
@testable import StreamingVideoApp

@MainActor
class VideoAcceptanceTests: XCTestCase {

	override func tearDown() {
		super.tearDown()
		// Process any pending async work to avoid Swift runtime crash during deallocation
		// Multiple iterations to ensure all pending work completes
		for _ in 0..<3 {
			RunLoop.current.run(until: Date())
		}
	}

	func test_onVideoSelection_navigatesToVideoPlayer() throws {
		let video = try launch(httpClient: .online(response), store: .empty)

		video.simulateTapOnVideo(at: 0)

		let nav = video.navigationController
		XCTAssertTrue(nav?.topViewController is VideoPlayerViewController)
	}

	func test_onVideoSelection_displaysVideoPlayerWithCorrectTitle() throws {
		let video = try launch(httpClient: .online(response), store: .empty)

		video.simulateTapOnVideo(at: 0)

		let nav = video.navigationController
		let videoPlayer = nav?.topViewController as? VideoPlayerViewController
		XCTAssertEqual(videoPlayer?.title, "Video 0")
	}

	func test_onVideoSelection_displaysCommentsSection() throws {
		let video = try launch(httpClient: .online(response), store: .empty)

		video.simulateTapOnVideo(at: 0)

		let nav = video.navigationController
		let videoPlayer = nav?.topViewController as? VideoPlayerViewController
		XCTAssertNotNil(videoPlayer?.embeddedCommentsController, "Expected comments controller to be embedded in video player")
	}

    func test_onLaunch_displaysRemoteVideosWhenCustomerHasConnectivity() throws {
        let video = try launch(httpClient: .online(response), store: .empty)

        XCTAssertEqual(video.numberOfRenderedVideoViews(), 2)
    }

    func test_onLaunch_displaysCachedRemoteVideosWhenCustomerHasNoConnectivity() throws {
        let sharedStore = try CoreDataVideoStore.empty

        let onlineVideo = try launch(httpClient: .online(response), store: sharedStore)
        onlineVideo.simulateVideoViewVisible(at: 0)
        onlineVideo.simulateVideoViewVisible(at: 1)

        let offlineVideo = try launch(httpClient: .offline, store: sharedStore)

        XCTAssertEqual(offlineVideo.numberOfRenderedVideoViews(), 2)
    }

    func test_onLaunch_displaysEmptyVideosWhenCustomerHasNoConnectivityAndNoCache() throws {
        let video = try launch(httpClient: .offline, store: .empty)

        XCTAssertEqual(video.numberOfRenderedVideoViews(), 0)
    }

    func test_onEnteringBackground_deletesExpiredVideoCache() throws {
        let store = try CoreDataVideoStore.withExpiredVideoCache

        enterBackground(with: store)

        XCTAssertNil(try store.retrieve(), "Expected to delete expired cache")
    }

    func test_onEnteringBackground_keepsNonExpiredVideoCache() throws {
        let store = try CoreDataVideoStore.withNonExpiredVideoCache

        enterBackground(with: store)

        XCTAssertNotNil(try store.retrieve(), "Expected to keep non-expired cache")
    }

    // MARK: - Helpers

    private func launch(
        httpClient: HTTPClientStub = .offline,
        store: CoreDataVideoStore
    ) throws -> ListViewController {
        let sut = SceneDelegate(
			httpClient: httpClient,
			store: store,
			videoPlayerFactory: { _ in VideoPlayerStub() }
		)
        let dummyScene = try XCTUnwrap((UIWindowScene.self as NSObject.Type).init() as? UIWindowScene)
        sut.window = UIWindow(windowScene: dummyScene)
        sut.window?.frame = CGRect(x: 0, y: 0, width: 390, height: 1)
        sut.configureWindow()

        let nav = sut.window?.rootViewController as? UINavigationController
        let vc = nav?.topViewController as! ListViewController
        vc.simulateAppearance()
        return vc
    }

    private func enterBackground(with store: CoreDataVideoStore) {
        let sut = SceneDelegate(httpClient: HTTPClientStub.offline, store: store)
        sut.sceneWillResignActive(UIApplication.shared.connectedScenes.first!)
    }

    private func response(for url: URL) -> (Data, HTTPURLResponse) {
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (makeData(for: url), response)
    }

    private func makeData(for url: URL) -> Data {
        switch url.path {
        case "/thumb-0.jpg": return UIImage.make(withColor: .red).pngData()!
        case "/thumb-1.jpg": return UIImage.make(withColor: .green).pngData()!

        default:
            return makeVideosData()
        }
    }

    private func makeVideosData() -> Data {
        return try! JSONSerialization.data(withJSONObject: [
            "videos": [
                ["id": "00000000-0000-0000-0000-000000000000", "title": "Video 0", "description": "Description 0", "url": "https://video.com/video-0.mp4", "thumbnail_url": "https://video.com/thumb-0.jpg", "duration": 120.0],
                ["id": "00000000-0000-0000-0000-000000000001", "title": "Video 1", "description": "Description 1", "url": "https://video.com/video-1.mp4", "thumbnail_url": "https://video.com/thumb-1.jpg", "duration": 180.0]
            ]
        ])
    }
}
