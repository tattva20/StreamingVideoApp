import UIKit
import StreamingCore

public final class TVCommentsViewController: UICollectionViewController {
	public var onRefresh: (() -> Void)?

	private lazy var dataSource = UICollectionViewDiffableDataSource<Int, VideoCommentViewModel>(collectionView: collectionView) { collectionView, indexPath, viewModel in
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TVCommentCell.reuseID, for: indexPath) as! TVCommentCell
		cell.configure(with: viewModel)
		return cell
	}

	public init() {
		super.init(collectionViewLayout: Self.makeLayout())
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public override func viewDidLoad() {
		super.viewDidLoad()
		collectionView.register(TVCommentCell.self, forCellWithReuseIdentifier: TVCommentCell.reuseID)
		collectionView.dataSource = dataSource
		onRefresh?()
	}

	public func display(_ viewModel: VideoCommentsViewModel) {
		var snapshot = NSDiffableDataSourceSnapshot<Int, VideoCommentViewModel>()
		snapshot.appendSections([0])
		snapshot.appendItems(viewModel.comments, toSection: 0)
		dataSource.apply(snapshot, animatingDifferences: false)
	}

	private static func makeLayout() -> UICollectionViewLayout {
		let item = NSCollectionLayoutItem(
			layoutSize: NSCollectionLayoutSize(
				widthDimension: .fractionalWidth(1.0),
				heightDimension: .estimated(120)))

		let group = NSCollectionLayoutGroup.vertical(
			layoutSize: NSCollectionLayoutSize(
				widthDimension: .fractionalWidth(1.0),
				heightDimension: .estimated(120)),
			subitems: [item])

		let section = NSCollectionLayoutSection(group: group)
		section.interGroupSpacing = 8
		section.contentInsets = NSDirectionalEdgeInsets(top: 40, leading: 60, bottom: 40, trailing: 60)

		return UICollectionViewCompositionalLayout(section: section)
	}
}
