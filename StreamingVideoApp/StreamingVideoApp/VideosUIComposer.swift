//
//  VideosUIComposer.swift
//  StreamingCoreiOS
//
//  Created by Octavio Rojas on 30/11/25.
//

import UIKit
import Combine
import StreamingCore
import StreamingCoreiOS

@MainActor
public final class VideosUIComposer {
    private init() {}

    private typealias VideosPresentationAdapter = LoadResourcePresentationAdapter<Paginated<Video>, VideosViewAdapter>

    public static func videosComposedWith(
        videoLoader: @MainActor @escaping () -> AnyPublisher<Paginated<Video>, Error>,
        imageLoader: @MainActor @escaping (URL) async throws -> Data,
        selection: @MainActor @escaping (Video) -> Void = { _ in }
    ) -> ListViewController {
        let presentationAdapter = VideosPresentationAdapter(loader: videoLoader)

        let videosController = makeVideosViewController()
        videosController.onRefresh = presentationAdapter.loadResource

        presentationAdapter.presenter = LoadResourcePresenter(
            resourceView: VideosViewAdapter(
                controller: videosController,
                imageLoader: imageLoader,
                selection: selection),
            loadingView: WeakRefVirtualProxy(videosController),
            errorView: WeakRefVirtualProxy(videosController))

        return videosController
    }

    private static func makeVideosViewController() -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: "Videos", bundle: bundle)
        let videosController = storyboard.instantiateInitialViewController() as! ListViewController
        videosController.title = VideosPresenter.title
        return videosController
    }
}

