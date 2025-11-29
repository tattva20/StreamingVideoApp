import UIKit
import StreamingCore

public final class VideosViewController: UIViewController {
    private let loader: VideoLoader

    public init(loader: VideoLoader) {
        self.loader = loader
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
