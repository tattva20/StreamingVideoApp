//
//  VideoPlayerViewController.swift
//  StreamingCoreiOS
//
//  Copyright by Octavio Rojas all rights reserved.
//
import UIKit
import StreamingCore

public final class VideoPlayerViewController: UIViewController {
	private let viewModel: VideoPlayerViewModel
	private let player: VideoPlayer

	// MARK: - Views

	public private(set) lazy var playerView: PlayerView = {
		let view = PlayerView()
		view.backgroundColor = .black
		view.translatesAutoresizingMaskIntoConstraints = false
		return view
	}()

	public private(set) lazy var controlsView: VideoPlayerControlsView = {
		let view = VideoPlayerControlsView()
		view.translatesAutoresizingMaskIntoConstraints = false
		return view
	}()

	// MARK: - UI Element Accessors (for backward compatibility)

	public var playButton: UIButton { controlsView.playButton }
	public var seekForwardButton: UIButton { controlsView.seekForwardButton }
	public var seekBackwardButton: UIButton { controlsView.seekBackwardButton }
	public var progressSlider: UISlider { controlsView.progressSlider }
	public var currentTimeLabel: UILabel { controlsView.currentTimeLabel }
	public var durationLabel: UILabel { controlsView.durationLabel }
	public var muteButton: UIButton { controlsView.muteButton }
	public var volumeSlider: UISlider { controlsView.volumeSlider }
	public var playbackSpeedButton: UIButton { controlsView.playbackSpeedButton }
	public var fullscreenButton: UIButton { controlsView.fullscreenButton }
	public var pipButton: UIButton { controlsView.pipButton }
	public var landscapeTitleLabel: UILabel { controlsView.landscapeTitleLabel }

	// MARK: - State

	public private(set) var isFullscreen: Bool = false
	public var areControlsVisible: Bool {
		controlsVisibilityController?.areControlsVisible ?? true
	}
	private var controlsVisibilityController: ControlsVisibilityController?
	private var hideControlsTimer: Timer?
	private var isLandscape: Bool = false

	// MARK: - External Callbacks

	public var onPlaybackPaused: (() -> Void)?
	public var onFullscreenToggle: (() -> Void)?
	public var onPipToggle: (() -> Void)?
	public var pipController: PictureInPictureControlling?

	// MARK: - Comments

	private var commentsContainer: UIView?
	public private(set) var embeddedCommentsController: UIViewController?

	// MARK: - Constraints

	private var portraitConstraints: [NSLayoutConstraint] = []
	private var landscapeConstraints: [NSLayoutConstraint] = []
	private var commentsContainerConstraints: [NSLayoutConstraint] = []
	private var bottomControlsContainerConstraints: [NSLayoutConstraint] = []
	private var fullscreenButtonPortraitConstraints: [NSLayoutConstraint] = []
	private var fullscreenButtonLandscapeConstraints: [NSLayoutConstraint] = []
	private var pipButtonPortraitConstraints: [NSLayoutConstraint] = []
	private var pipButtonLandscapeConstraints: [NSLayoutConstraint] = []
	private var playbackSpeedButtonPortraitConstraints: [NSLayoutConstraint] = []
	private var playbackSpeedButtonLandscapeConstraints: [NSLayoutConstraint] = []
	private var durationLabelPortraitConstraint: NSLayoutConstraint?
	private var durationLabelLandscapeConstraint: NSLayoutConstraint?
	private var currentTimeLabelBottomPortraitConstraint: NSLayoutConstraint?
	private var currentTimeLabelBottomLandscapeConstraint: NSLayoutConstraint?
	private var durationLabelBottomPortraitConstraint: NSLayoutConstraint?
	private var durationLabelBottomLandscapeConstraint: NSLayoutConstraint?
	private var currentTimeLabelLeadingPortraitConstraint: NSLayoutConstraint?
	private var currentTimeLabelLeadingLandscapeConstraint: NSLayoutConstraint?

	// MARK: - Initialization

	public init(viewModel: VideoPlayerViewModel, player: VideoPlayer) {
		self.viewModel = viewModel
		self.player = player
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Lifecycle

	public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return .allButUpsideDown
	}

	public override func viewDidLoad() {
		super.viewDidLoad()
		isLandscape = view.bounds.width > view.bounds.height
		updateEdgesForExtendedLayout()
		setupUI()
		configureControlsCallbacks()
		configurePlayer()
		setupControlsVisibilityController()

		if let commentsController = embeddedCommentsController {
			embedCommentsController(commentsController)
		}
	}

	public override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		autoPlay()
		controlsVisibilityController?.scheduleHide()
	}

	public override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		hideControlsTimer?.invalidate()
	}

	public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		coordinator.animate { [weak self] _ in
			guard let self = self else { return }
			let newIsLandscape = size.width > size.height
			self.updateLayoutForOrientation(isLandscape: newIsLandscape)
		}
	}

	// MARK: - Setup

	private func setupUI() {
		title = viewModel.title
		view.backgroundColor = .black

		view.addSubview(playerView)
		view.addSubview(controlsView.playButton)
		view.addSubview(controlsView.seekForwardButton)
		view.addSubview(controlsView.seekBackwardButton)
		view.addSubview(controlsView.progressSlider)
		view.addSubview(controlsView.currentTimeLabel)
		view.addSubview(controlsView.durationLabel)

		view.addSubview(controlsView.bottomControlsContainer)
		controlsView.bottomControlsContainer.addSubview(controlsView.muteButton)
		controlsView.bottomControlsContainer.addSubview(controlsView.volumeSlider)

		view.addSubview(controlsView.playbackSpeedButton)
		view.addSubview(controlsView.pipButton)
		view.addSubview(controlsView.fullscreenButton)

		controlsView.setTitle(viewModel.title)
		view.addSubview(controlsView.landscapeTitleLabel)

		setupTapGesture()
		setupConstraints()
	}

	private func configureControlsCallbacks() {
		controlsView.onPlayTapped = { [weak self] in self?.handlePlayTapped() }
		controlsView.onSeekForwardTapped = { [weak self] in self?.handleSeekForwardTapped() }
		controlsView.onSeekBackwardTapped = { [weak self] in self?.handleSeekBackwardTapped() }
		controlsView.onProgressChanged = { [weak self] in self?.handleProgressChanged($0) }
		controlsView.onMuteTapped = { [weak self] in self?.handleMuteTapped() }
		controlsView.onVolumeChanged = { [weak self] in self?.handleVolumeChanged($0) }
		controlsView.onSpeedTapped = { [weak self] in self?.handleSpeedTapped() }
		controlsView.onFullscreenTapped = { [weak self] in self?.onFullscreenToggle?() }
		controlsView.onPipTapped = { [weak self] in self?.onPipToggle?() }
	}

	private func setupTapGesture() {
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
		playerView.addGestureRecognizer(tapGesture)
		playerView.isUserInteractionEnabled = true
	}

	private func setupControlsVisibilityController() {
		controlsVisibilityController = ControlsVisibilityController(hideDelay: 5.0, delegate: self)
	}

	private func configurePlayer() {
		player.load(url: viewModel.videoURL)
	}

	// MARK: - Control Handlers

	private func handlePlayTapped() {
		if player.isPlaying {
			player.pause()
			controlsView.setPlayButtonPlaying(false)
			showControlsForPause()
		} else {
			player.play()
			controlsView.setPlayButtonPlaying(true)
			controlsVisibilityController?.scheduleHide()
		}
	}

	private func handleSeekForwardTapped() {
		controlsVisibilityController?.scheduleHide()
		player.seekForward(by: 10)
	}

	private func handleSeekBackwardTapped() {
		controlsVisibilityController?.scheduleHide()
		player.seekBackward(by: 10)
	}

	private func handleProgressChanged(_ value: Float) {
		controlsVisibilityController?.scheduleHide()
		let targetTime = TimeInterval(value) * player.duration
		player.seek(to: targetTime)
	}

	private func handleMuteTapped() {
		player.toggleMute()
		controlsView.setMuteButtonMuted(player.isMuted)
	}

	private func handleVolumeChanged(_ value: Float) {
		player.setVolume(value)
	}

	private static let playbackSpeeds: [Float] = [1.0, 1.25, 1.5, 2.0, 0.5]

	private func handleSpeedTapped() {
		let currentSpeed = player.playbackSpeed
		let currentIndex = Self.playbackSpeeds.firstIndex(of: currentSpeed) ?? 0
		let nextIndex = (currentIndex + 1) % Self.playbackSpeeds.count
		let newSpeed = Self.playbackSpeeds[nextIndex]
		player.setPlaybackSpeed(newSpeed)
		updatePlaybackSpeedButtonTitle()
	}

	private func updatePlaybackSpeedButtonTitle() {
		let speed = player.playbackSpeed
		let title = speed == 1.0 ? "1x" : String(format: "%.2gx", speed)
		controlsView.setSpeedButtonTitle(title)
	}

	// MARK: - Playback

	private func autoPlay() {
		player.play()
		controlsView.setPlayButtonPlaying(true)
	}

	private func showControlsForPause() {
		controlsVisibilityController?.cancelTimer()
		if !areControlsVisible {
			controlsVisibilityController?.show()
		}
		onPlaybackPaused?()
	}

	// MARK: - Tap Handling

	@objc private func handleTap() {
		toggleControlsVisibility()
	}

	public func toggleControlsVisibility() {
		controlsVisibilityController?.toggle()
	}

	public func triggerAutoHide() {
		guard player.isPlaying else { return }
		controlsView.setControlsAlpha(0.0, isLandscape: isLandscape)
		controlsVisibilityController?.hide()
	}

	public func showControlsOnPause() {
		controlsVisibilityController?.cancelTimer()
		controlsView.setControlsAlpha(1.0, isLandscape: isLandscape)
	}

	// MARK: - Time Display

	public func updateTimeDisplay() {
		let current = VideoPlayerPresenter.formatTime(player.currentTime)
		let duration = VideoPlayerPresenter.formatTime(player.duration)
		let progress = player.duration > 0 ? Float(player.currentTime / player.duration) : 0
		controlsView.updateTime(current: current, duration: duration, progress: progress)
	}

	// MARK: - Comments

	public func setCommentsController(_ controller: UIViewController) {
		embeddedCommentsController = controller
		if isViewLoaded {
			embedCommentsController(controller)
		}
	}

	private func embedCommentsController(_ controller: UIViewController) {
		guard commentsContainer == nil else { return }

		let containerView = UIView()
		containerView.translatesAutoresizingMaskIntoConstraints = false
		containerView.backgroundColor = .systemBackground
		containerView.tag = 999
		view.addSubview(containerView)
		commentsContainer = containerView

		addChild(controller)
		controller.view.translatesAutoresizingMaskIntoConstraints = false
		containerView.addSubview(controller.view)
		controller.didMove(toParent: self)

		commentsContainerConstraints = [
			containerView.topAnchor.constraint(equalTo: controlsView.bottomControlsContainer.bottomAnchor, constant: 16),
			containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
			controller.view.topAnchor.constraint(equalTo: containerView.topAnchor),
			controller.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
			controller.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
			controller.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
		]

		if !isLandscape {
			NSLayoutConstraint.activate(commentsContainerConstraints)
		}

		updateLayoutForOrientation(isLandscape: isLandscape)
	}

	// MARK: - Layout

	private func updateEdgesForExtendedLayout() {
		edgesForExtendedLayout = isLandscape ? .all : []
	}

	public func updateLayoutForOrientation(isLandscape: Bool) {
		self.isLandscape = isLandscape
		self.isFullscreen = isLandscape
		updateEdgesForExtendedLayout()
		controlsView.setFullscreenButtonExpanded(isFullscreen)

		if isLandscape {
			NSLayoutConstraint.deactivate(portraitConstraints)
			NSLayoutConstraint.deactivate(fullscreenButtonPortraitConstraints)
			NSLayoutConstraint.deactivate(pipButtonPortraitConstraints)
			NSLayoutConstraint.deactivate(playbackSpeedButtonPortraitConstraints)
			NSLayoutConstraint.deactivate(commentsContainerConstraints)
			NSLayoutConstraint.deactivate(bottomControlsContainerConstraints)
			durationLabelPortraitConstraint?.isActive = false
			currentTimeLabelBottomPortraitConstraint?.isActive = false
			durationLabelBottomPortraitConstraint?.isActive = false
			currentTimeLabelLeadingPortraitConstraint?.isActive = false

			NSLayoutConstraint.activate(landscapeConstraints)
			NSLayoutConstraint.activate(fullscreenButtonLandscapeConstraints)
			NSLayoutConstraint.activate(pipButtonLandscapeConstraints)
			NSLayoutConstraint.activate(playbackSpeedButtonLandscapeConstraints)
			durationLabelLandscapeConstraint?.isActive = true
			currentTimeLabelBottomLandscapeConstraint?.isActive = true
			durationLabelBottomLandscapeConstraint?.isActive = true
			currentTimeLabelLeadingLandscapeConstraint?.isActive = true

			controlsView.updateLayout(for: .landscape)
			commentsContainer?.isHidden = true
			navigationController?.setNavigationBarHidden(true, animated: true)

			if !areControlsVisible {
				controlsView.setControlsAlpha(0.0, isLandscape: true)
				controlsView.setLandscapeControlsInteraction(enabled: false)
			}
		} else {
			NSLayoutConstraint.deactivate(landscapeConstraints)
			NSLayoutConstraint.deactivate(fullscreenButtonLandscapeConstraints)
			NSLayoutConstraint.deactivate(pipButtonLandscapeConstraints)
			NSLayoutConstraint.deactivate(playbackSpeedButtonLandscapeConstraints)
			durationLabelLandscapeConstraint?.isActive = false
			currentTimeLabelBottomLandscapeConstraint?.isActive = false
			durationLabelBottomLandscapeConstraint?.isActive = false
			currentTimeLabelLeadingLandscapeConstraint?.isActive = false

			NSLayoutConstraint.activate(portraitConstraints)
			NSLayoutConstraint.activate(fullscreenButtonPortraitConstraints)
			NSLayoutConstraint.activate(pipButtonPortraitConstraints)
			NSLayoutConstraint.activate(playbackSpeedButtonPortraitConstraints)
			NSLayoutConstraint.activate(commentsContainerConstraints)
			NSLayoutConstraint.activate(bottomControlsContainerConstraints)
			durationLabelPortraitConstraint?.isActive = true
			currentTimeLabelBottomPortraitConstraint?.isActive = true
			durationLabelBottomPortraitConstraint?.isActive = true
			currentTimeLabelLeadingPortraitConstraint?.isActive = true

			controlsView.updateLayout(for: .portrait)
			commentsContainer?.isHidden = false
			navigationController?.setNavigationBarHidden(false, animated: true)
		}

		view.layoutIfNeeded()

		if !isLandscape {
			controlsView.clearPendingAnimations()
			controlsView.playbackSpeedButton.alpha = 1.0
			controlsView.pipButton.alpha = 1.0
			controlsView.fullscreenButton.alpha = 1.0
			controlsView.setLandscapeControlsInteraction(enabled: true)
		}
	}

	private func setupConstraints() {
		let playerViewAspectRatio = playerView.heightAnchor.constraint(equalTo: playerView.widthAnchor, multiplier: 9.0/16.0)

		portraitConstraints = [
			playerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
			playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			playerViewAspectRatio
		]

		landscapeConstraints = [
			playerView.topAnchor.constraint(equalTo: view.topAnchor),
			playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		]

		durationLabelPortraitConstraint = controlsView.durationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
		durationLabelLandscapeConstraint = controlsView.durationLabel.trailingAnchor.constraint(equalTo: controlsView.playbackSpeedButton.leadingAnchor, constant: -8)

		currentTimeLabelBottomPortraitConstraint = controlsView.currentTimeLabel.bottomAnchor.constraint(equalTo: playerView.bottomAnchor, constant: -16)
		currentTimeLabelBottomLandscapeConstraint = controlsView.currentTimeLabel.bottomAnchor.constraint(equalTo: playerView.bottomAnchor, constant: -64)
		durationLabelBottomPortraitConstraint = controlsView.durationLabel.bottomAnchor.constraint(equalTo: playerView.bottomAnchor, constant: -16)
		durationLabelBottomLandscapeConstraint = controlsView.durationLabel.bottomAnchor.constraint(equalTo: playerView.bottomAnchor, constant: -64)

		currentTimeLabelLeadingPortraitConstraint = controlsView.currentTimeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
		currentTimeLabelLeadingLandscapeConstraint = controlsView.currentTimeLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24)

		pipButtonPortraitConstraints = [
			controlsView.pipButton.centerYAnchor.constraint(equalTo: controlsView.bottomControlsContainer.centerYAnchor),
			controlsView.pipButton.trailingAnchor.constraint(equalTo: controlsView.fullscreenButton.leadingAnchor, constant: -8)
		]

		pipButtonLandscapeConstraints = [
			controlsView.pipButton.centerYAnchor.constraint(equalTo: controlsView.durationLabel.centerYAnchor),
			controlsView.pipButton.trailingAnchor.constraint(equalTo: controlsView.fullscreenButton.leadingAnchor, constant: -8)
		]

		fullscreenButtonPortraitConstraints = [
			controlsView.fullscreenButton.centerYAnchor.constraint(equalTo: controlsView.bottomControlsContainer.centerYAnchor),
			controlsView.fullscreenButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
		]

		fullscreenButtonLandscapeConstraints = [
			controlsView.fullscreenButton.centerYAnchor.constraint(equalTo: controlsView.durationLabel.centerYAnchor),
			controlsView.fullscreenButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
		]

		playbackSpeedButtonPortraitConstraints = [
			controlsView.playbackSpeedButton.centerYAnchor.constraint(equalTo: controlsView.bottomControlsContainer.centerYAnchor),
			controlsView.playbackSpeedButton.trailingAnchor.constraint(equalTo: controlsView.pipButton.leadingAnchor, constant: -8)
		]

		playbackSpeedButtonLandscapeConstraints = [
			controlsView.playbackSpeedButton.centerYAnchor.constraint(equalTo: controlsView.durationLabel.centerYAnchor),
			controlsView.playbackSpeedButton.trailingAnchor.constraint(equalTo: controlsView.pipButton.leadingAnchor, constant: -8)
		]

		bottomControlsContainerConstraints = [
			controlsView.bottomControlsContainer.topAnchor.constraint(equalTo: playerView.bottomAnchor, constant: 16),
			controlsView.bottomControlsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			controlsView.bottomControlsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			controlsView.bottomControlsContainer.heightAnchor.constraint(equalToConstant: 44)
		]

		NSLayoutConstraint.activate([
			controlsView.playButton.centerXAnchor.constraint(equalTo: playerView.centerXAnchor),
			controlsView.playButton.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),
			controlsView.playButton.widthAnchor.constraint(equalToConstant: 60),
			controlsView.playButton.heightAnchor.constraint(equalToConstant: 60),

			controlsView.seekBackwardButton.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),
			controlsView.seekBackwardButton.trailingAnchor.constraint(equalTo: controlsView.playButton.leadingAnchor, constant: -40),
			controlsView.seekBackwardButton.widthAnchor.constraint(equalToConstant: 44),
			controlsView.seekBackwardButton.heightAnchor.constraint(equalToConstant: 44),

			controlsView.seekForwardButton.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),
			controlsView.seekForwardButton.leadingAnchor.constraint(equalTo: controlsView.playButton.trailingAnchor, constant: 40),
			controlsView.seekForwardButton.widthAnchor.constraint(equalToConstant: 44),
			controlsView.seekForwardButton.heightAnchor.constraint(equalToConstant: 44),

			controlsView.progressSlider.leadingAnchor.constraint(equalTo: controlsView.currentTimeLabel.trailingAnchor, constant: 8),
			controlsView.progressSlider.trailingAnchor.constraint(equalTo: controlsView.durationLabel.leadingAnchor, constant: -8),
			controlsView.progressSlider.centerYAnchor.constraint(equalTo: controlsView.currentTimeLabel.centerYAnchor),

			controlsView.muteButton.leadingAnchor.constraint(equalTo: controlsView.bottomControlsContainer.leadingAnchor, constant: 16),
			controlsView.muteButton.centerYAnchor.constraint(equalTo: controlsView.bottomControlsContainer.centerYAnchor),
			controlsView.muteButton.widthAnchor.constraint(equalToConstant: 44),
			controlsView.muteButton.heightAnchor.constraint(equalToConstant: 44),

			controlsView.volumeSlider.centerYAnchor.constraint(equalTo: controlsView.bottomControlsContainer.centerYAnchor),
			controlsView.volumeSlider.leadingAnchor.constraint(equalTo: controlsView.muteButton.trailingAnchor, constant: 8),
			controlsView.volumeSlider.widthAnchor.constraint(equalToConstant: 100),

			controlsView.playbackSpeedButton.widthAnchor.constraint(equalToConstant: 50),

			controlsView.pipButton.widthAnchor.constraint(equalToConstant: 44),
			controlsView.pipButton.heightAnchor.constraint(equalToConstant: 44),

			controlsView.fullscreenButton.widthAnchor.constraint(equalToConstant: 44),
			controlsView.fullscreenButton.heightAnchor.constraint(equalToConstant: 44),

			controlsView.landscapeTitleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
			controlsView.landscapeTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			controlsView.landscapeTitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
			controlsView.landscapeTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
		])

		NSLayoutConstraint.activate(portraitConstraints)
		NSLayoutConstraint.activate(fullscreenButtonPortraitConstraints)
		NSLayoutConstraint.activate(pipButtonPortraitConstraints)
		NSLayoutConstraint.activate(playbackSpeedButtonPortraitConstraints)
		NSLayoutConstraint.activate(bottomControlsContainerConstraints)
		durationLabelPortraitConstraint?.isActive = true
		currentTimeLabelBottomPortraitConstraint?.isActive = true
		durationLabelBottomPortraitConstraint?.isActive = true
		currentTimeLabelLeadingPortraitConstraint?.isActive = true
	}
}

// MARK: - ControlsVisibilityDelegate

extension VideoPlayerViewController: ControlsVisibilityDelegate {
	public func controlsDidShow() {
		if isLandscape {
			controlsView.setLandscapeControlsInteraction(enabled: true)
		}
		UIView.animate(withDuration: 0.3) { [weak self] in
			guard let self = self else { return }
			self.controlsView.setControlsAlpha(1.0, isLandscape: self.isLandscape)
		}
	}

	public func controlsDidHide() {
		guard player.isPlaying else { return }
		if isLandscape {
			controlsView.setLandscapeControlsInteraction(enabled: false)
		}
		UIView.animate(withDuration: 0.3) { [weak self] in
			guard let self = self else { return }
			self.controlsView.setControlsAlpha(0.0, isLandscape: self.isLandscape)
		}
	}

	public func scheduleTimer(withDelay delay: TimeInterval, callback: @escaping () -> Void) {
		hideControlsTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
			guard self?.player.isPlaying == true else { return }
			callback()
		}
	}

	public func cancelTimer() {
		hideControlsTimer?.invalidate()
	}
}
