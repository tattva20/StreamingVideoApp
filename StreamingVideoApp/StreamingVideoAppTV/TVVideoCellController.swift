import UIKit
import StreamingCore

public final class TVVideoCellController: NSObject {
	private let viewModel: VideoViewModel
	private let selection: () -> Void

	public init(viewModel: VideoViewModel, selection: @escaping () -> Void) {
		self.viewModel = viewModel
		self.selection = selection
	}
}

extension TVVideoCellController: UICollectionViewDataSource, UICollectionViewDelegate {
	public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		1
	}

	public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TVVideoPosterCell.reuseID, for: indexPath) as! TVVideoPosterCell
		cell.titleLabel.text = viewModel.title
		return cell
	}

	public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		selection()
	}
}
