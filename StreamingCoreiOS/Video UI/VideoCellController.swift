import UIKit
import StreamingCore

public final class VideoCellController: CellController {
    private let video: Video
    private let selection: (Video) -> Void

    public init(video: Video, selection: @escaping (Video) -> Void) {
        self.video = video
        self.selection = selection
    }

    public func view(in tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VideoCell") as! VideoCell
        cell.titleLabel.text = video.title
        cell.descriptionLabel.text = video.description
        return cell
    }

    public func didSelect() {
        selection(video)
    }
}
