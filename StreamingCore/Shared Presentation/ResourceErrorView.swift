import Foundation

public protocol ResourceErrorView: AnyObject {
    func display(_ viewModel: ResourceErrorViewModel)
}

public struct ResourceErrorViewModel: Equatable {
    public let message: String?

    public init(message: String?) {
        self.message = message
    }

    public static var noError: ResourceErrorViewModel {
        return ResourceErrorViewModel(message: nil)
    }

    public static func error(message: String) -> ResourceErrorViewModel {
        return ResourceErrorViewModel(message: message)
    }
}
