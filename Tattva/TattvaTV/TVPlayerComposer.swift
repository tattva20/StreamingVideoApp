import AVFoundation
import StreamingCore
import StreamingCorePlayback

@MainActor
public enum TVPlayerComposer {
	public struct Bundle {
		public let player: AVPlayer
		let statefulPlayer: StatefulVideoPlayer
		let coordinator: PlaybackCoordinator
		let performanceAdapter: VideoPlayerPerformanceAdapter
	}

	public static func playerComposedWith(
		video: Video,
		basePlayer: AVPlayerVideoPlayer = AVPlayerVideoPlayer(),
		analyticsLogger: PlaybackAnalyticsLogger? = nil,
		structuredLogger: (any StreamingCore.Logger)? = nil
	) -> Bundle {
		var videoPlayer: VideoPlayer = basePlayer

		if let structuredLogger {
			videoPlayer = LoggingVideoPlayerDecorator(decoratee: videoPlayer, logger: structuredLogger)
		}

		if let analyticsLogger {
			videoPlayer = AnalyticsVideoPlayerDecorator(decoratee: videoPlayer, analyticsLogger: analyticsLogger)
		}

		let stateMachine = DefaultPlaybackStateMachine()
		let statefulPlayer = StatefulVideoPlayer(decoratee: videoPlayer, stateMachine: stateMachine)

		let performanceAdapter = VideoPlayerPerformanceAdapter(
			performanceService: PlaybackPerformanceService(),
			bandwidthEstimator: NetworkBandwidthEstimator()
		)
		performanceAdapter.startMonitoring(sessionID: UUID())

		let coordinator = PlaybackCoordinator(
			player: basePlayer.player,
			stateMachine: stateMachine,
			performanceAdapter: performanceAdapter
		)
		coordinator.start()

		basePlayer.load(url: video.url)

		return Bundle(
			player: basePlayer.player,
			statefulPlayer: statefulPlayer,
			coordinator: coordinator,
			performanceAdapter: performanceAdapter
		)
	}
}
