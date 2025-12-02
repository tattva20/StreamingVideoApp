import Foundation

public struct VideoImageViewModel {
    public let title: String
    public let description: String?

    public var hasDescription: Bool {
        return description != nil
    }
}
