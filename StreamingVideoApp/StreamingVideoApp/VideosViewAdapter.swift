//
//  VideosViewAdapter.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas all rights reserved.
//
import UIKit
import StreamingCore
import StreamingCoreiOS

@MainActor
final class VideosViewAdapter: ResourceView {
    private weak var controller: ListViewController?
    private let imageLoader: (URL) async throws -> Data
    private let selection: (Video) -> Void
    private let currentFeed: [Video: CellController]

    private typealias ImageDataPresentationAdapter = AsyncLoadResourcePresentationAdapter<Data, WeakRefVirtualProxy<StreamingCoreiOS.VideoCellController>>
    private typealias LoadMorePresentationAdapter = LoadResourcePresentationAdapter<Paginated<Video>, VideosViewAdapter>

    init(currentFeed: [Video: CellController] = [:], controller: ListViewController, imageLoader: @escaping (URL) async throws -> Data, selection: @escaping (Video) -> Void) {
        self.currentFeed = currentFeed
        self.controller = controller
        self.imageLoader = imageLoader
        self.selection = selection
    }

    func display(_ viewModel: Paginated<Video>) {
        guard let controller = controller else { return }

        var currentFeed = self.currentFeed
        let feed: [CellController] = viewModel.items.map { model in
            if let controller = currentFeed[model] {
                return controller
            }

            let adapter = ImageDataPresentationAdapter(loader: { [imageLoader] in
                try await imageLoader(model.thumbnailURL)
            })

            let view = StreamingCoreiOS.VideoCellController(
                viewModel: VideoViewModel(title: model.title, description: model.description),
                delegate: adapter,
                selection: { [selection] in
                    selection(model)
                })

            adapter.presenter = LoadResourcePresenter(
                resourceView: WeakRefVirtualProxy(view),
                loadingView: WeakRefVirtualProxy(view),
                errorView: WeakRefVirtualProxy(view),
                mapper: UIImage.tryMake)

            let controller = CellController(id: model, view)
            currentFeed[model] = controller
            return controller
        }

        guard let loadMorePublisher = viewModel.loadMorePublisher else {
            controller.display(feed)
            return
        }

        let loadMoreAdapter = LoadMorePresentationAdapter(loader: loadMorePublisher)
        let loadMore = LoadMoreCellController(callback: loadMoreAdapter.loadResource)

        loadMoreAdapter.presenter = LoadResourcePresenter(
            resourceView: VideosViewAdapter(
                currentFeed: currentFeed,
                controller: controller,
                imageLoader: imageLoader,
                selection: selection
            ),
            loadingView: WeakRefVirtualProxy(loadMore),
            errorView: WeakRefVirtualProxy(loadMore))

        let loadMoreSection = [CellController(id: UUID(), loadMore)]

        controller.display(feed, loadMoreSection)
    }
}

extension UIImage {
    struct InvalidImageData: Error {}

    static func tryMake(data: Data) throws -> UIImage {
        guard let image = UIImage(data: data) else {
            throw InvalidImageData()
        }
        return image
    }
}
