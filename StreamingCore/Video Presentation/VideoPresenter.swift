import Foundation

public final class VideoPresenter {
    private let view: VideoViewProxy

    public init(view: some VideoView) {
        self.view = VideoViewProxy(view)
    }

    public func didStartLoading() {
        view.display(isLoading: true)
    }

    public func didFinishLoading(with videos: [Video]) {
        view.display(isLoading: false)
        view.display(videos: videos)
    }

    public func didFinishLoading(with error: Error) {
        view.display(isLoading: false)
        view.display(error: "Could not load videos. Please try again.")
    }
}

private final class VideoViewProxy {
    private weak var view: (any VideoView)?

    init(_ view: some VideoView) {
        self.view = view
    }

    func display(isLoading: Bool) {
        view?.display(isLoading: isLoading)
    }

    func display(videos: [Video]) {
        view?.display(videos: videos)
    }

    func display(error: String) {
        view?.display(error: error)
    }
}
