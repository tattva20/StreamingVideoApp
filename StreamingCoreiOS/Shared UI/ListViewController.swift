import UIKit
import StreamingCore

public final class ListViewController: UITableViewController, ResourceLoadingView, ResourceErrorView {
    public private(set) var errorView = ErrorView()
    private var cellControllers = [CellController]()

    public var onRefresh: (() -> Void)?

    public override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
        configureRefreshControl()
    }

    private func configureTableView() {
        tableView.tableHeaderView = errorView.makeContainer()

        errorView.onHide = { [weak self] in
            self?.tableView.beginUpdates()
            self?.tableView.sizeTableHeaderToFit()
            self?.tableView.endUpdates()
        }
    }

    private func configureRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.refreshControl = refreshControl
    }

    @objc private func refresh() {
        onRefresh?()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableView.sizeTableHeaderToFit()
    }

    public func display(_ cellControllers: [CellController]) {
        self.cellControllers = cellControllers
        tableView.reloadData()
    }

    public func display(_ viewModel: ResourceLoadingViewModel) {
        refreshControl?.update(isRefreshing: viewModel.isLoading)
    }

    public func display(_ viewModel: ResourceErrorViewModel) {
        errorView.message = viewModel.message
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellControllers.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cellControllers[indexPath.row].view(in: tableView)
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        cellControllers[indexPath.row].didSelect()
    }
}
