import Foundation

public protocol VideoView {
    func display(isLoading: Bool)
    func display(videos: [Video])
    func display(error: String)
}
