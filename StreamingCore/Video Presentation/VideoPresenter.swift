import Foundation

public final class VideoPresenter {
    private let view: VideoView

    public init(view: VideoView) {
        self.view = view
    }

    public func didStartLoading() {
        view.display(isLoading: true)
    }

    public func didFinishLoading(with videos: [Video]) {
        view.display(isLoading: false)
        view.display(videos: videos)
    }
}
