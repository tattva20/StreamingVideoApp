import Foundation

@MainActor
public protocol ResourcePresenting<Resource>: AnyObject {
    associatedtype Resource
    func didStartLoading()
    func didFinishLoading(with resource: Resource)
    func didFinishLoading(with error: Error)
}

@MainActor
public final class LoadResourcePresentationAdapter<Resource, Presenter: ResourcePresenting> where Presenter.Resource == Resource {
    public typealias Loader = () async throws -> Resource

    private let loader: Loader
    private weak var presenter: Presenter?
    private var task: Task<Void, Never>?
    private var isLoading = false

    public init(loader: @escaping Loader, presenter: Presenter) {
        self.loader = loader
        self.presenter = presenter
    }

    public func loadResource() {
        guard !isLoading else { return }

        presenter?.didStartLoading()
        isLoading = true

        task = Task { [weak self] in
            guard let self else { return }

            do {
                let resource = try await self.loader()
                if !Task.isCancelled {
                    self.presenter?.didFinishLoading(with: resource)
                }
            } catch {
                if !Task.isCancelled {
                    self.presenter?.didFinishLoading(with: error)
                }
            }

            self.isLoading = false
        }
    }

    public func cancelLoad() {
        task?.cancel()
        task = nil
        isLoading = false
    }
}
