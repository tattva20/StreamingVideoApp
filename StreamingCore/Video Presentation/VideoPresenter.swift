import Foundation

public final class VideoPresenter {
    private let view: VideoView

    public init(view: VideoView) {
        self.view = view
    }

    public func didStartLoading() {
        view.display(isLoading: true)
    }
}
