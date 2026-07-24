import UIKit

public struct TVCellController {
	let id: any Hashable & Sendable
	let dataSource: UICollectionViewDataSource
	let delegate: UICollectionViewDelegate?
	let dataSourcePrefetching: UICollectionViewDataSourcePrefetching?

	public init(id: any Hashable & Sendable, _ dataSource: UICollectionViewDataSource) {
		self.id = id
		self.dataSource = dataSource
		self.delegate = dataSource as? UICollectionViewDelegate
		self.dataSourcePrefetching = dataSource as? UICollectionViewDataSourcePrefetching
	}
}

extension TVCellController: nonisolated Equatable {
	public nonisolated static func == (lhs: TVCellController, rhs: TVCellController) -> Bool {
		AnyHashable(lhs.id) == AnyHashable(rhs.id)
	}
}

extension TVCellController: nonisolated Hashable {
	public nonisolated func hash(into hasher: inout Hasher) {
		let id = AnyHashable(self.id)
		hasher.combine(id)
	}
}

extension TVCellController: @unchecked Sendable {}
