import UIKit

public protocol CellController {
    func view(in tableView: UITableView) -> UITableViewCell
    func didSelect()
}
