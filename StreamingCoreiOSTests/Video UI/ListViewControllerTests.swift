import XCTest
import StreamingCoreiOS

@MainActor
final class ListViewControllerTests: XCTestCase {

    func test_init_doesNotLoadTableView() {
        let (_, view) = makeSUT()

        XCTAssertNil(view.tableView, "Expected tableView to be nil before view is loaded")
    }

    func test_viewDidLoad_rendersTableView() {
        let (_, view) = makeSUT()

        view.loadViewIfNeeded()

        XCTAssertNotNil(view.tableView, "Expected tableView to be configured after view loads")
    }

    func test_numberOfRowsInSection_matchesCellControllersCount() {
        let (sut, view) = makeSUT()

        view.loadViewIfNeeded()
        sut.display([makeCellController(), makeCellController()])

        XCTAssertEqual(numberOfRows(in: view), 2)
    }

    func test_cellForRowAt_requestsCellFromCellController() {
        let (sut, view) = makeSUT()
        let controller0 = CellControllerSpy()
        let controller1 = CellControllerSpy()

        view.loadViewIfNeeded()
        sut.display([controller0, controller1])

        let _ = cellForRow(at: 0, in: view)
        XCTAssertEqual(controller0.requestedCells.count, 1)
        XCTAssertEqual(controller1.requestedCells.count, 0)

        let _ = cellForRow(at: 1, in: view)
        XCTAssertEqual(controller0.requestedCells.count, 1)
        XCTAssertEqual(controller1.requestedCells.count, 1)
    }

    func test_didSelectRowAt_notifiesCellController() {
        let (sut, view) = makeSUT()
        let controller0 = CellControllerSpy()
        let controller1 = CellControllerSpy()

        view.loadViewIfNeeded()
        sut.display([controller0, controller1])

        selectRow(at: 0, in: view)
        XCTAssertEqual(controller0.selections, 1)
        XCTAssertEqual(controller1.selections, 0)

        selectRow(at: 1, in: view)
        XCTAssertEqual(controller0.selections, 1)
        XCTAssertEqual(controller1.selections, 1)
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (ListViewController, ListViewController) {
        let sut = ListViewController()
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, sut)
    }

    private func makeCellController() -> CellController {
        return CellControllerSpy()
    }

    private func numberOfRows(in view: ListViewController) -> Int {
        return view.tableView?.numberOfRows(inSection: 0) ?? 0
    }

    private func cellForRow(at row: Int, in view: ListViewController) -> UITableViewCell? {
        let indexPath = IndexPath(row: row, section: 0)
        return view.tableView?.dataSource?.tableView(view.tableView!, cellForRowAt: indexPath)
    }

    private func selectRow(at row: Int, in view: ListViewController) {
        let indexPath = IndexPath(row: row, section: 0)
        view.tableView?.delegate?.tableView?(view.tableView!, didSelectRowAt: indexPath)
    }

    private class CellControllerSpy: CellController {
        private(set) var requestedCells = [UITableView]()
        private(set) var selections = 0

        func view(in tableView: UITableView) -> UITableViewCell {
            requestedCells.append(tableView)
            return UITableViewCell()
        }

        func didSelect() {
            selections += 1
        }
    }
}
