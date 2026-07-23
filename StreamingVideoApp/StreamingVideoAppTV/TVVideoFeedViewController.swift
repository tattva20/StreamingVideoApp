import UIKit

public final class TVVideoFeedViewController: UICollectionViewController {
	public var onRefresh: (() -> Void)?

	private lazy var dataSource: UICollectionViewDiffableDataSource<Int, TVCellController> = {
		UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, controller in
			controller.dataSource.collectionView(collectionView, cellForItemAt: indexPath)
		}
	}()

	public init() {
		super.init(collectionViewLayout: Self.makeLayout())
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public override func viewDidLoad() {
		super.viewDidLoad()
		collectionView.register(TVVideoPosterCell.self, forCellWithReuseIdentifier: TVVideoPosterCell.reuseID)
		collectionView.dataSource = dataSource
		onRefresh?()
	}

	public func display(_ controllers: [TVCellController]) {
		var snapshot = NSDiffableDataSourceSnapshot<Int, TVCellController>()
		snapshot.appendSections([0])
		snapshot.appendItems(controllers, toSection: 0)
		dataSource.apply(snapshot, animatingDifferences: false)
	}

	public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let controller = dataSource.itemIdentifier(for: indexPath)
		controller?.delegate?.collectionView?(collectionView, didSelectItemAt: indexPath)
	}

	private static func makeLayout() -> UICollectionViewLayout {
		let item = NSCollectionLayoutItem(
			layoutSize: NSCollectionLayoutSize(
				widthDimension: .fractionalWidth(1.0),
				heightDimension: .fractionalHeight(1.0)))
		item.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)

		let group = NSCollectionLayoutGroup.horizontal(
			layoutSize: NSCollectionLayoutSize(
				widthDimension: .fractionalWidth(0.2),
				heightDimension: .absolute(360)),
			subitems: [item])

		let section = NSCollectionLayoutSection(group: group)
		section.contentInsets = NSDirectionalEdgeInsets(top: 40, leading: 60, bottom: 40, trailing: 60)

		return UICollectionViewCompositionalLayout(section: section)
	}
}
