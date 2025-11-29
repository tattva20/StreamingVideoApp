import Foundation

public protocol ResourceLoadingView {
    func display(_ viewModel: ResourceLoadingViewModel)
}

public struct ResourceLoadingViewModel: Equatable {
    public let isLoading: Bool

    public init(isLoading: Bool) {
        self.isLoading = isLoading
    }
}
