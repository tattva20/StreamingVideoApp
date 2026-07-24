import AVKit
import StreamingCore
import StreamingCorePlayback

@MainActor
public final class TVPlayerViewController: AVPlayerViewController {
	private let video: Video
	private let comments: UIViewController?
	private let analyticsLogger: PlaybackAnalyticsLogger?
	private let structuredLogger: (any StreamingCore.Logger)?
	private var playbackBundle: TVPlayerComposer.Bundle?

	public init(
		video: Video,
		comments: UIViewController? = nil,
		analyticsLogger: PlaybackAnalyticsLogger? = nil,
		structuredLogger: (any StreamingCore.Logger)? = nil
	) {
		self.video = video
		self.comments = comments
		self.analyticsLogger = analyticsLogger
		self.structuredLogger = structuredLogger
		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public override func viewDidLoad() {
		super.viewDidLoad()
		let bundle = TVPlayerComposer.playerComposedWith(
			video: video,
			analyticsLogger: analyticsLogger,
			structuredLogger: structuredLogger
		)
		player = bundle.player
		playbackBundle = bundle

		if let comments {
			customInfoViewControllers = [comments]
		}
	}

	public override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		playbackBundle?.statefulPlayer.play()
	}

	public override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		playbackBundle?.coordinator.stop()
	}
}
