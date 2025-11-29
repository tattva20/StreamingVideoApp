import UIKit
import StreamingCore

public final class VideosViewController: UIViewController, UITableViewDataSource {
    private let loader: VideoLoader
    private(set) public var tableView: UITableView?
    private var videos = [Video]()

    public init(loader: VideoLoader) {
        self.loader = loader
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        let tableView = UITableView()
        tableView.dataSource = self
        self.tableView = tableView

        loader.load { [weak self] result in
            if case let .success(videos) = result {
                self?.videos = videos
                self?.tableView?.reloadData()
            }
        }
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}
