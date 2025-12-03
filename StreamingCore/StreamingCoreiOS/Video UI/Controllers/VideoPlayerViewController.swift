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

	public private(set) lazy var playButton: UIButton = {
		let button = UIButton(type: .system)
		button.setImage(UIImage(systemName: "play.fill"), for: .normal)
		button.tintColor = .white
		button.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}()

	public private(set) lazy var seekForwardButton: UIButton = {
		let button = UIButton(type: .system)
		button.setImage(UIImage(systemName: "goforward.10"), for: .normal)
		button.tintColor = .white
		button.addTarget(self, action: #selector(seekForwardButtonTapped), for: .touchUpInside)
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}()

	public private(set) lazy var seekBackwardButton: UIButton = {
		let button = UIButton(type: .system)
		button.setImage(UIImage(systemName: "gobackward.10"), for: .normal)
		button.tintColor = .white
		button.addTarget(self, action: #selector(seekBackwardButtonTapped), for: .touchUpInside)
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}()

	public private(set) lazy var progressSlider: UISlider = {
		let slider = UISlider()
		slider.minimumValue = 0
		slider.maximumValue = 1
		slider.minimumTrackTintColor = .white
		slider.maximumTrackTintColor = .gray
		slider.addTarget(self, action: #selector(progressSliderValueChanged), for: .valueChanged)
		slider.translatesAutoresizingMaskIntoConstraints = false
		return slider
	}()

	public private(set) lazy var currentTimeLabel: UILabel = {
		let label = UILabel()
		label.textColor = .white
		label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
		label.text = "0:00"
		label.translatesAutoresizingMaskIntoConstraints = false
		return label
	}()

	public private(set) lazy var durationLabel: UILabel = {
		let label = UILabel()
		label.textColor = .white
		label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
		label.text = "0:00"
		label.translatesAutoresizingMaskIntoConstraints = false
		return label
	}()

	public private(set) lazy var muteButton: UIButton = {
		let button = UIButton(type: .system)
		button.setImage(UIImage(systemName: "speaker.wave.2.fill"), for: .normal)
		button.tintColor = .white
		button.addTarget(self, action: #selector(muteButtonTapped), for: .touchUpInside)
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}()

	public private(set) lazy var volumeSlider: UISlider = {
		let slider = UISlider()
		slider.minimumValue = 0
		slider.maximumValue = 1
		slider.value = 1
		slider.minimumTrackTintColor = .white
		slider.maximumTrackTintColor = .gray
		slider.addTarget(self, action: #selector(volumeSliderValueChanged), for: .valueChanged)
		slider.translatesAutoresizingMaskIntoConstraints = false
		return slider
	}()

	public private(set) lazy var playbackSpeedButton: UIButton = {
		let button = UIButton(type: .system)
		button.setTitle("1x", for: .normal)
		button.setTitleColor(.white, for: .normal)
		button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
		button.addTarget(self, action: #selector(playbackSpeedButtonTapped), for: .touchUpInside)
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}()

	public private(set) lazy var fullscreenButton: UIButton = {
		let button = UIButton(type: .system)
		button.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
		button.tintColor = .white
		button.addTarget(self, action: #selector(fullscreenButtonTapped), for: .touchUpInside)
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}()

	public private(set) lazy var pipButton: UIButton = {
		let button = UIButton(type: .system)
		button.setImage(UIImage(systemName: "pip.enter"), for: .normal)
		button.tintColor = .white
		button.addTarget(self, action: #selector(pipButtonTapped), for: .touchUpInside)
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}()

	public private(set) lazy var landscapeTitleLabel: UILabel = {
		let label = UILabel()
		label.textColor = UIColor.white.withAlphaComponent(0.7)
		label.font = .systemFont(ofSize: 16, weight: .medium)
		label.translatesAutoresizingMaskIntoConstraints = false
		label.tag = 997
		label.isHidden = true
		return label
	}()

	public private(set) var isFullscreen: Bool = false
	public var areControlsVisible: Bool {
		controlsVisibilityController?.areControlsVisible ?? true
	}
	private var controlsVisibilityController: ControlsVisibilityController?
	private var hideControlsTimer: Timer?
	private var isLandscape: Bool = false

	public var onPlaybackPaused: (() -> Void)?
	public var onFullscreenToggle: (() -> Void)?
	public var onPipToggle: (() -> Void)?
	public var pipController: PictureInPictureControlling?

	public private(set) lazy var playerView: PlayerView = {
		let view = PlayerView()
		view.backgroundColor = .black
		view.translatesAutoresizingMaskIntoConstraints = false
		return view
	}()

	private lazy var bottomControlsContainerView: UIView = {
		let view = UIView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.tag = 998
		return view
	}()

	private var commentsContainer: UIView?
	public private(set) var embeddedCommentsController: UIViewController?

	private var portraitConstraints: [NSLayoutConstraint] = []
	private var landscapeConstraints: [NSLayoutConstraint] = []
	private var playerViewHeightConstraint: NSLayoutConstraint?
	private var commentsContainerConstraints: [NSLayoutConstraint] = []
	private var bottomControlsContainerConstraints: [NSLayoutConstraint] = []

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
			containerView.topAnchor.constraint(equalTo: bottomControlsContainerView.bottomAnchor, constant: 16),
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

	public init(viewModel: VideoPlayerViewModel, player: VideoPlayer) {
		self.viewModel = viewModel
		self.player = player
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return .allButUpsideDown
	}

	public override func viewDidLoad() {
		super.viewDidLoad()
		isLandscape = view.bounds.width > view.bounds.height
		updateEdgesForExtendedLayout()
		setupUI()
		configurePlayer()
		setupTapGesture()
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

	private func autoPlay() {
		player.play()
		playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
	}

	public override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		hideControlsTimer?.invalidate()
	}

	private func setupControlsVisibilityController() {
		controlsVisibilityController = ControlsVisibilityController(hideDelay: 5.0, delegate: self)
	}

	public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		coordinator.animate { [weak self] _ in
			guard let self = self else { return }
			let newIsLandscape = size.width > size.height
			self.updateLayoutForOrientation(isLandscape: newIsLandscape)
		}
	}

	public func updateLayoutForOrientation(isLandscape: Bool) {
		self.isLandscape = isLandscape
		self.isFullscreen = isLandscape
		updateEdgesForExtendedLayout()
		updateFullscreenButtonIcon()

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

			bottomControlsContainerView.isHidden = true
			commentsContainer?.isHidden = true
			landscapeTitleLabel.isHidden = false
			navigationController?.setNavigationBarHidden(true, animated: true)

			// When transitioning to landscape with controls hidden, hide all controls
			// This handles the case where portrait auto-hide left bottom controls visible
			// but in landscape ALL controls should be hidden together
			if !areControlsVisible {
				setAllControlsAlpha(0.0)
				setLandscapeControlsInteraction(enabled: false)
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

			bottomControlsContainerView.isHidden = false
			commentsContainer?.isHidden = false
			landscapeTitleLabel.isHidden = true
			navigationController?.setNavigationBarHidden(false, animated: true)
		}

		view.layoutIfNeeded()

		// Restore bottom controls visibility and interaction when returning to portrait
		// This must happen after layoutIfNeeded to override any pending animations
		if !isLandscape {
			playbackSpeedButton.layer.removeAllAnimations()
			pipButton.layer.removeAllAnimations()
			fullscreenButton.layer.removeAllAnimations()
			playbackSpeedButton.alpha = 1.0
			pipButton.alpha = 1.0
			fullscreenButton.alpha = 1.0
			setLandscapeControlsInteraction(enabled: true)
		}
	}

	private func setLandscapeControlsInteraction(enabled: Bool) {
		playbackSpeedButton.isUserInteractionEnabled = enabled
		pipButton.isUserInteractionEnabled = enabled
		fullscreenButton.isUserInteractionEnabled = enabled
	}

	private func updateEdgesForExtendedLayout() {
		edgesForExtendedLayout = isLandscape ? .all : []
	}

	private func setupTapGesture() {
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
		playerView.addGestureRecognizer(tapGesture)
		playerView.isUserInteractionEnabled = true
	}

	@objc private func handleTap() {
		toggleControlsVisibility()
	}

	private func setupUI() {
		title = viewModel.title
		view.backgroundColor = .black

		view.addSubview(playerView)
		view.addSubview(playButton)
		view.addSubview(seekForwardButton)
		view.addSubview(seekBackwardButton)
		view.addSubview(progressSlider)
		view.addSubview(currentTimeLabel)
		view.addSubview(durationLabel)

		view.addSubview(bottomControlsContainerView)
		bottomControlsContainerView.addSubview(muteButton)
		bottomControlsContainerView.addSubview(volumeSlider)

		view.addSubview(playbackSpeedButton)
		view.addSubview(pipButton)
		view.addSubview(fullscreenButton)

		landscapeTitleLabel.text = viewModel.title
		landscapeTitleLabel.textAlignment = .center
		view.addSubview(landscapeTitleLabel)

		setupConstraints()
	}

	private var fullscreenButtonPortraitConstraints: [NSLayoutConstraint] = []
	private var fullscreenButtonLandscapeConstraints: [NSLayoutConstraint] = []
	private var pipButtonPortraitConstraints: [NSLayoutConstraint] = []
	private var pipButtonLandscapeConstraints: [NSLayoutConstraint] = []
	private var durationLabelPortraitConstraint: NSLayoutConstraint?
	private var durationLabelLandscapeConstraint: NSLayoutConstraint?
	private var currentTimeLabelBottomPortraitConstraint: NSLayoutConstraint?
	private var currentTimeLabelBottomLandscapeConstraint: NSLayoutConstraint?
	private var durationLabelBottomPortraitConstraint: NSLayoutConstraint?
	private var durationLabelBottomLandscapeConstraint: NSLayoutConstraint?
	private var currentTimeLabelLeadingPortraitConstraint: NSLayoutConstraint?
	private var currentTimeLabelLeadingLandscapeConstraint: NSLayoutConstraint?
	private var playbackSpeedButtonPortraitConstraints: [NSLayoutConstraint] = []
	private var playbackSpeedButtonLandscapeConstraints: [NSLayoutConstraint] = []

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

		durationLabelPortraitConstraint = durationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
		// In landscape: durationLabel → speedButton → pipButton → fullscreenButton
		durationLabelLandscapeConstraint = durationLabel.trailingAnchor.constraint(equalTo: playbackSpeedButton.leadingAnchor, constant: -8)

		currentTimeLabelBottomPortraitConstraint = currentTimeLabel.bottomAnchor.constraint(equalTo: playerView.bottomAnchor, constant: -16)
		currentTimeLabelBottomLandscapeConstraint = currentTimeLabel.bottomAnchor.constraint(equalTo: playerView.bottomAnchor, constant: -64)
		durationLabelBottomPortraitConstraint = durationLabel.bottomAnchor.constraint(equalTo: playerView.bottomAnchor, constant: -16)
		durationLabelBottomLandscapeConstraint = durationLabel.bottomAnchor.constraint(equalTo: playerView.bottomAnchor, constant: -64)

		// In portrait, currentTimeLabel starts at view.leading; in landscape, use safe area with extra padding
		currentTimeLabelLeadingPortraitConstraint = currentTimeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
		currentTimeLabelLeadingLandscapeConstraint = currentTimeLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24)

		pipButtonPortraitConstraints = [
			pipButton.centerYAnchor.constraint(equalTo: bottomControlsContainerView.centerYAnchor),
			pipButton.trailingAnchor.constraint(equalTo: fullscreenButton.leadingAnchor, constant: -8)
		]

		pipButtonLandscapeConstraints = [
			pipButton.centerYAnchor.constraint(equalTo: durationLabel.centerYAnchor),
			pipButton.trailingAnchor.constraint(equalTo: fullscreenButton.leadingAnchor, constant: -8)
		]

		fullscreenButtonPortraitConstraints = [
			fullscreenButton.centerYAnchor.constraint(equalTo: bottomControlsContainerView.centerYAnchor),
			fullscreenButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
		]

		fullscreenButtonLandscapeConstraints = [
			fullscreenButton.centerYAnchor.constraint(equalTo: durationLabel.centerYAnchor),
			fullscreenButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
		]

		playbackSpeedButtonPortraitConstraints = [
			playbackSpeedButton.centerYAnchor.constraint(equalTo: bottomControlsContainerView.centerYAnchor),
			playbackSpeedButton.trailingAnchor.constraint(equalTo: pipButton.leadingAnchor, constant: -8)
		]

		// In landscape: speedButton is between durationLabel and pipButton
		playbackSpeedButtonLandscapeConstraints = [
			playbackSpeedButton.centerYAnchor.constraint(equalTo: durationLabel.centerYAnchor),
			playbackSpeedButton.trailingAnchor.constraint(equalTo: pipButton.leadingAnchor, constant: -8)
		]

		bottomControlsContainerConstraints = [
			bottomControlsContainerView.topAnchor.constraint(equalTo: playerView.bottomAnchor, constant: 16),
			bottomControlsContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			bottomControlsContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			bottomControlsContainerView.heightAnchor.constraint(equalToConstant: 44)
		]

		NSLayoutConstraint.activate([
			playButton.centerXAnchor.constraint(equalTo: playerView.centerXAnchor),
			playButton.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),
			playButton.widthAnchor.constraint(equalToConstant: 60),
			playButton.heightAnchor.constraint(equalToConstant: 60),

			seekBackwardButton.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),
			seekBackwardButton.trailingAnchor.constraint(equalTo: playButton.leadingAnchor, constant: -40),
			seekBackwardButton.widthAnchor.constraint(equalToConstant: 44),
			seekBackwardButton.heightAnchor.constraint(equalToConstant: 44),

			seekForwardButton.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),
			seekForwardButton.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 40),
			seekForwardButton.widthAnchor.constraint(equalToConstant: 44),
			seekForwardButton.heightAnchor.constraint(equalToConstant: 44),

			progressSlider.leadingAnchor.constraint(equalTo: currentTimeLabel.trailingAnchor, constant: 8),
			progressSlider.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -8),
			progressSlider.centerYAnchor.constraint(equalTo: currentTimeLabel.centerYAnchor),

			muteButton.leadingAnchor.constraint(equalTo: bottomControlsContainerView.leadingAnchor, constant: 16),
			muteButton.centerYAnchor.constraint(equalTo: bottomControlsContainerView.centerYAnchor),
			muteButton.widthAnchor.constraint(equalToConstant: 44),
			muteButton.heightAnchor.constraint(equalToConstant: 44),

			volumeSlider.centerYAnchor.constraint(equalTo: bottomControlsContainerView.centerYAnchor),
			volumeSlider.leadingAnchor.constraint(equalTo: muteButton.trailingAnchor, constant: 8),
			volumeSlider.widthAnchor.constraint(equalToConstant: 100),

			playbackSpeedButton.widthAnchor.constraint(equalToConstant: 50),

			pipButton.widthAnchor.constraint(equalToConstant: 44),
			pipButton.heightAnchor.constraint(equalToConstant: 44),

			fullscreenButton.widthAnchor.constraint(equalToConstant: 44),
			fullscreenButton.heightAnchor.constraint(equalToConstant: 44),

			landscapeTitleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
			landscapeTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			landscapeTitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
			landscapeTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
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

	private func configurePlayer() {
		player.load(url: viewModel.videoURL)
	}

	@objc private func playButtonTapped() {
		if player.isPlaying {
			player.pause()
			playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
			showControlsForPause()
		} else {
			player.play()
			playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
			controlsVisibilityController?.scheduleHide()
		}
	}

	private func showControlsForPause() {
		controlsVisibilityController?.cancelTimer()
		if !areControlsVisible {
			controlsVisibilityController?.show()
		}
		onPlaybackPaused?()
	}

	@objc private func seekForwardButtonTapped() {
		controlsVisibilityController?.scheduleHide()
		player.seekForward(by: 10)
	}

	@objc private func seekBackwardButtonTapped() {
		controlsVisibilityController?.scheduleHide()
		player.seekBackward(by: 10)
	}

	@objc private func progressSliderValueChanged() {
		controlsVisibilityController?.scheduleHide()
		let targetTime = TimeInterval(progressSlider.value) * player.duration
		player.seek(to: targetTime)
	}

	@objc private func muteButtonTapped() {
		player.toggleMute()
		updateMuteButtonIcon()
	}

	@objc private func volumeSliderValueChanged() {
		player.setVolume(volumeSlider.value)
	}

	private func updateMuteButtonIcon() {
		let iconName = player.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"
		muteButton.setImage(UIImage(systemName: iconName), for: .normal)
	}

	private static let playbackSpeeds: [Float] = [1.0, 1.25, 1.5, 2.0, 0.5]

	@objc private func playbackSpeedButtonTapped() {
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
		playbackSpeedButton.setTitle(title, for: .normal)
	}

	@objc private func fullscreenButtonTapped() {
		onFullscreenToggle?()
	}

	@objc private func pipButtonTapped() {
		onPipToggle?()
	}

	private func updateFullscreenButtonIcon() {
		let iconName = isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
		fullscreenButton.setImage(UIImage(systemName: iconName), for: .normal)
	}

	public func toggleControlsVisibility() {
		controlsVisibilityController?.toggle()
	}

	public func triggerAutoHide() {
		guard player.isPlaying else {
			return
		}
		setAllControlsAlpha(0.0)
		controlsVisibilityController?.hide()
	}

	public func showControlsOnPause() {
		controlsVisibilityController?.cancelTimer()
		setAllControlsAlpha(1.0)
	}

	private func setAllControlsAlpha(_ alpha: CGFloat) {
		// Overlay controls - always auto-hide in both orientations
		playButton.alpha = alpha
		seekForwardButton.alpha = alpha
		seekBackwardButton.alpha = alpha
		progressSlider.alpha = alpha
		currentTimeLabel.alpha = alpha
		durationLabel.alpha = alpha

		if isLandscape {
			// In landscape, ALL controls auto-hide together
			muteButton.alpha = alpha
			volumeSlider.alpha = alpha
			playbackSpeedButton.alpha = alpha
			pipButton.alpha = alpha
			fullscreenButton.alpha = alpha
			landscapeTitleLabel.alpha = alpha
		} else if alpha == 1.0 {
			// In portrait, ALWAYS restore bottom controls when showing
			// This fixes bug where controls stay hidden after landscape->portrait rotation
			playbackSpeedButton.alpha = 1.0
			pipButton.alpha = 1.0
			fullscreenButton.alpha = 1.0
		}
		// Note: In portrait when hiding (alpha == 0), we don't touch bottom controls
		// They should always remain visible in portrait mode
	}

	public func updateTimeDisplay() {
		currentTimeLabel.text = VideoPlayerPresenter.formatTime(player.currentTime)
		durationLabel.text = VideoPlayerPresenter.formatTime(player.duration)

		if player.duration > 0 {
			progressSlider.value = Float(player.currentTime / player.duration)
		}
	}
}

extension VideoPlayerViewController: ControlsVisibilityDelegate {
	public func controlsDidShow() {
		if isLandscape {
			setLandscapeControlsInteraction(enabled: true)
		}
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.setAllControlsAlpha(1.0)
		}
	}

	public func controlsDidHide() {
		guard player.isPlaying else {
			return
		}
		if isLandscape {
			setLandscapeControlsInteraction(enabled: false)
		}
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.setAllControlsAlpha(0.0)
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
