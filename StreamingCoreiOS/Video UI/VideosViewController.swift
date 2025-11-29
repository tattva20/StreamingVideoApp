import UIKit
import StreamingCore

public final class VideosViewController: UIViewController {
    private let loader: VideoLoader
    private let listViewController = ListViewController()
    public var onVideoSelection: ((Video) -> Void)?

    public var tableView: UITableView? {
        return listViewController.tableView
    }

    public init(loader: VideoLoader) {
        self.loader = loader
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        title = "Videos"

        addChild(listViewController)
        view.addSubview(listViewController.view)
        listViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            listViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            listViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            listViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            listViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        listViewController.didMove(toParent: self)

        listViewController.tableView?.register(VideoCell.self, forCellReuseIdentifier: "VideoCell")

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let videos = try await self.loader.load()
                let cellControllers = videos.map { video in
                    VideoCellController(video: video, selection: { [weak self] selectedVideo in
                        self?.onVideoSelection?(selectedVideo)
                    })
                }
                self.listViewController.display(cellControllers)
            } catch {
                // Handle error silently for now
            }
        }
    }
}
