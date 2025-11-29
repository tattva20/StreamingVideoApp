import Foundation

public final class WeakRefVirtualProxy<T: AnyObject> {
    public weak var object: T?

    public init(_ object: T) {
        self.object = object
    }
}
