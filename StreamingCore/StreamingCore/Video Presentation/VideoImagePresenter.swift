import Foundation

public final class VideoImagePresenter {
    public static func map(_ video: Video) -> VideoImageViewModel {
        VideoImageViewModel(
            title: video.title,
            description: video.description)
    }
}
