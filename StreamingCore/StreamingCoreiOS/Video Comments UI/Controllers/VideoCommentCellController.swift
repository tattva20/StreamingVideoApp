//
//  VideoCommentCellController.swift
//  StreamingCoreiOS
//

import UIKit
import StreamingCore

public class VideoCommentCellController: NSObject, UITableViewDataSource {
	private let model: VideoCommentViewModel

	public init(model: VideoCommentViewModel) {
		self.model = model
	}

	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		1
	}

	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell: VideoCommentCell = tableView.dequeueReusableCell()
		cell.messageLabel.text = model.message
		cell.usernameLabel.text = model.username
		cell.dateLabel.text = model.date
		return cell
	}
}
