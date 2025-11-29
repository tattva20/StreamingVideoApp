import Foundation

public protocol VideoView: AnyObject {
    func display(isLoading: Bool)
    func display(videos: [Video])
    func display(error: String)
}
