//
//  VideoCommentCell.swift
//  StreamingCoreiOS
//

import UIKit

public final class VideoCommentCell: UITableViewCell {
	public private(set) var messageLabel: UILabel = {
		let label = UILabel()
		label.font = .preferredFont(forTextStyle: .body)
		label.numberOfLines = 0
		label.textColor = .label
		label.translatesAutoresizingMaskIntoConstraints = false
		return label
	}()

	public private(set) var usernameLabel: UILabel = {
		let label = UILabel()
		label.font = .preferredFont(forTextStyle: .headline)
		label.textColor = .label
		label.translatesAutoresizingMaskIntoConstraints = false
		return label
	}()

	public private(set) var dateLabel: UILabel = {
		let label = UILabel()
		label.font = .preferredFont(forTextStyle: .caption1)
		label.textColor = .secondaryLabel
		label.translatesAutoresizingMaskIntoConstraints = false
		return label
	}()

	public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		setupUI()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setupUI()
	}

	private func setupUI() {
		contentView.addSubview(usernameLabel)
		contentView.addSubview(dateLabel)
		contentView.addSubview(messageLabel)

		NSLayoutConstraint.activate([
			usernameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
			usernameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

			dateLabel.centerYAnchor.constraint(equalTo: usernameLabel.centerYAnchor),
			dateLabel.leadingAnchor.constraint(equalTo: usernameLabel.trailingAnchor, constant: 8),
			dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),

			messageLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 4),
			messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
			messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
			messageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
		])
	}
}
