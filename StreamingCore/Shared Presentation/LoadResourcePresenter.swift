import Foundation

public final class LoadResourcePresenter<Resource, View: ResourceView> where View: AnyObject {
    public typealias Mapper = (Resource) throws -> View.ResourceViewModel

    private let resourceView: WeakRefVirtualProxy<View>
    private let loadingView: ResourceLoadingViewProxy
    private let errorView: ResourceErrorViewProxy
    private let mapper: Mapper

    public static var loadError: String {
        return "Failed to load resource"
    }

    public init(resourceView: View, loadingView: some ResourceLoadingView, errorView: some ResourceErrorView, mapper: @escaping Mapper) {
        self.resourceView = WeakRefVirtualProxy(resourceView)
        self.loadingView = ResourceLoadingViewProxy(loadingView)
        self.errorView = ResourceErrorViewProxy(errorView)
        self.mapper = mapper
    }

    public init(resourceView: View, loadingView: some ResourceLoadingView, errorView: some ResourceErrorView) where Resource == View.ResourceViewModel {
        self.resourceView = WeakRefVirtualProxy(resourceView)
        self.loadingView = ResourceLoadingViewProxy(loadingView)
        self.errorView = ResourceErrorViewProxy(errorView)
        self.mapper = { $0 }
    }

    public func didStartLoading() {
        errorView.display(.noError)
        loadingView.display(ResourceLoadingViewModel(isLoading: true))
    }

    public func didFinishLoading(with resource: Resource) {
        do {
            resourceView.object?.display(try mapper(resource))
            loadingView.display(ResourceLoadingViewModel(isLoading: false))
        } catch {
            didFinishLoading(with: error)
        }
    }

    public func didFinishLoading(with error: Error) {
        errorView.display(.error(message: Self.loadError))
        loadingView.display(ResourceLoadingViewModel(isLoading: false))
    }
}

private final class ResourceLoadingViewProxy {
    private weak var view: (any ResourceLoadingView)?

    init(_ view: some ResourceLoadingView) {
        self.view = view
    }

    func display(_ viewModel: ResourceLoadingViewModel) {
        view?.display(viewModel)
    }
}

private final class ResourceErrorViewProxy {
    private weak var view: (any ResourceErrorView)?

    init(_ view: some ResourceErrorView) {
        self.view = view
    }

    func display(_ viewModel: ResourceErrorViewModel) {
        view?.display(viewModel)
    }
}
