import StreamingCore

final class TVWeakRefVirtualProxy<T: AnyObject> {
	private weak var object: T?

	init(_ object: T) {
		self.object = object
	}
}

extension TVWeakRefVirtualProxy: ResourceLoadingView where T: ResourceLoadingView {
	func display(_ viewModel: ResourceLoadingViewModel) {
		object?.display(viewModel)
	}
}

extension TVWeakRefVirtualProxy: ResourceErrorView where T: ResourceErrorView {
	func display(_ viewModel: ResourceErrorViewModel) {
		object?.display(viewModel)
	}
}

extension TVWeakRefVirtualProxy: ResourceView where T: ResourceView {
	func display(_ viewModel: T.ResourceViewModel) {
		object?.display(viewModel)
	}
}
