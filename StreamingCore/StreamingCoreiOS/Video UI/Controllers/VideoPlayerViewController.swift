//
//  VideoPlayerViewController.swift
//  StreamingCoreiOS
//
//  Created by Octavio Rojas on 02/12/25.
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

	public private(set) var isFullscreen: Bool = false
	public var areControlsVisible: Bool {
		controlsVisibilityController?.areControlsVisible ?? true
	}
	private var controlsVisibilityController: ControlsVisibilityController?
	private var hideControlsTimer: Timer?

	private lazy var controlsOverlay: UIView = {
		let view = UIView()
		view.backgroundColor = .clear
		view.translatesAutoresizingMaskIntoConstraints = false
		return view
	}()

	public private(set) lazy var playerView: PlayerView = {
		let view = PlayerView()
		view.backgroundColor = .black
		view.translatesAutoresizingMaskIntoConstraints = false
		return view
	}()

	public init(viewModel: VideoPlayerViewModel, player: VideoPlayer) {
		self.viewModel = viewModel
		self.player = player
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public override func viewDidLoad() {
		super.viewDidLoad()
		updateEdgesForExtendedLayout()
		setupUI()
		configurePlayer()
		setupTapGesture()
		setupControlsVisibilityController()
	}

	public override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		controlsVisibilityController?.scheduleHide()
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
			self?.updateEdgesForExtendedLayout()
		}
	}

	private func updateEdgesForExtendedLayout() {
		let isLandscape = view.bounds.width > view.bounds.height
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
		view.addSubview(muteButton)
		view.addSubview(volumeSlider)
		view.addSubview(playbackSpeedButton)
		view.addSubview(fullscreenButton)

		NSLayoutConstraint.activate([
			playerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
			playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			playerView.heightAnchor.constraint(equalTo: playerView.widthAnchor, multiplier: 9.0/16.0),

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

			currentTimeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
			currentTimeLabel.bottomAnchor.constraint(equalTo: playerView.bottomAnchor, constant: -16),

			durationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
			durationLabel.bottomAnchor.constraint(equalTo: playerView.bottomAnchor, constant: -16),

			progressSlider.leadingAnchor.constraint(equalTo: currentTimeLabel.trailingAnchor, constant: 8),
			progressSlider.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -8),
			progressSlider.centerYAnchor.constraint(equalTo: currentTimeLabel.centerYAnchor),

			muteButton.topAnchor.constraint(equalTo: playerView.bottomAnchor, constant: 16),
			muteButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
			muteButton.widthAnchor.constraint(equalToConstant: 44),
			muteButton.heightAnchor.constraint(equalToConstant: 44),

			volumeSlider.centerYAnchor.constraint(equalTo: muteButton.centerYAnchor),
			volumeSlider.leadingAnchor.constraint(equalTo: muteButton.trailingAnchor, constant: 8),
			volumeSlider.widthAnchor.constraint(equalToConstant: 120),

			playbackSpeedButton.centerYAnchor.constraint(equalTo: muteButton.centerYAnchor),
			playbackSpeedButton.trailingAnchor.constraint(equalTo: fullscreenButton.leadingAnchor, constant: -16),
			playbackSpeedButton.widthAnchor.constraint(equalToConstant: 50),

			fullscreenButton.centerYAnchor.constraint(equalTo: muteButton.centerYAnchor),
			fullscreenButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
			fullscreenButton.widthAnchor.constraint(equalToConstant: 44),
			fullscreenButton.heightAnchor.constraint(equalToConstant: 44)
		])
	}

	private func configurePlayer() {
		player.load(url: viewModel.videoURL)
	}

	@objc private func playButtonTapped() {
		controlsVisibilityController?.scheduleHide()
		if player.isPlaying {
			player.pause()
			playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
		} else {
			player.play()
			playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
		}
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
		isFullscreen.toggle()
		updateFullscreenButtonIcon()
	}

	private func updateFullscreenButtonIcon() {
		let iconName = isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
		fullscreenButton.setImage(UIImage(systemName: iconName), for: .normal)
	}

	public func toggleControlsVisibility() {
		controlsVisibilityController?.toggle()
	}

	private func setPlaybackControlsAlpha(_ alpha: CGFloat) {
		playButton.alpha = alpha
		seekForwardButton.alpha = alpha
		seekBackwardButton.alpha = alpha
		progressSlider.alpha = alpha
		currentTimeLabel.alpha = alpha
		durationLabel.alpha = alpha
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
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.setPlaybackControlsAlpha(1.0)
		}
	}

	public func controlsDidHide() {
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.setPlaybackControlsAlpha(0.0)
		}
	}

	public func scheduleTimer(withDelay delay: TimeInterval, callback: @escaping () -> Void) {
		hideControlsTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
			callback()
		}
	}

	public func cancelTimer() {
		hideControlsTimer?.invalidate()
	}
}
