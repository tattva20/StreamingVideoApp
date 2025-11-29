import Foundation
import StreamingCore

@MainActor
public final class VideosViewAdapter: ResourcePresenting {
    public typealias Resource = [Video]

    private weak var controller: ListViewController?
    private let videoSelectionHandler: ((Video) -> Void)?

    public init(controller: ListViewController, videoSelectionHandler: ((Video) -> Void)?) {
        self.controller = controller
        self.videoSelectionHandler = videoSelectionHandler
    }

    public func didStartLoading() {
        // Could show loading indicator in future
    }

    public func didFinishLoading(with videos: [Video]) {
        let cellControllers = videos.map { video in
            VideoCellController(video: video, selection: { [weak self] selectedVideo in
                self?.videoSelectionHandler?(selectedVideo)
            })
        }
        controller?.display(cellControllers)
    }

    public func didFinishLoading(with error: Error) {
        // Could show error message in future
    }
}
