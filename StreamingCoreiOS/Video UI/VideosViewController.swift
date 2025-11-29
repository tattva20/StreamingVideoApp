import UIKit
import StreamingCore

@MainActor
public final class VideosViewController: UIViewController {
    private let adapter: LoadResourcePresentationAdapter<[Video], VideosViewAdapter>
    private let listViewController = ListViewController()
    private let viewAdapter: VideosViewAdapter

    public var tableView: UITableView? {
        return listViewController.tableView
    }

    public init(loader: VideoLoader, onVideoSelection: ((Video) -> Void)?) {
        self.viewAdapter = VideosViewAdapter(
            controller: listViewController,
            videoSelectionHandler: onVideoSelection
        )
        self.adapter = LoadResourcePresentationAdapter(
            loader: loader.load,
            presenter: viewAdapter
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        title = "Videos"

        setupListViewController()
        listViewController.tableView?.register(VideoCell.self, forCellReuseIdentifier: "VideoCell")

        adapter.loadResource()
    }

    private func setupListViewController() {
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
    }
}
