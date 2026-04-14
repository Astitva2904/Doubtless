import UIKit
import AgoraRtcKit

/// Full-screen 1-on-1 video call powered by Agora SDK.
/// Presented after both student and solver finish the countdown timer.
final class VideoCallViewController: UIViewController {
    
    // MARK: - Properties
    
    private let channelName: String
    private let doubtId: UUID
    
    /// Called when the call ends (tapped End Call or remote user left).
    var onCallEnded: (() -> Void)?
    
    /// Called when the student ends the call within the 2-minute buffer period.
    /// The closure receives the elapsed seconds so the caller knows it was a buffer-end.
    var onBufferEndCall: ((_ elapsedSeconds: Int) -> Void)?
    
    // Agora
    private var agoraKit: AgoraRtcEngineKit?
    private var remoteUid: UInt?
    
    // Timer
    private var sessionSeconds: Int = 0
    private var sessionTimer: Timer?
    
    // Buffer time constants
    private let bufferDuration: Int = 120  // 2 minutes in seconds
    
    /// Whether we are still within the 2-minute free buffer window.
    private var isWithinBufferTime: Bool {
        return sessionSeconds < bufferDuration
    }
    
    // MARK: - UI Elements
    
    /// Remote user's video fills the screen
    private let remoteVideoView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1)
        return v
    }()
    
    /// Local camera preview (picture-in-picture, top-right)
    private let localVideoView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1)
        v.layer.cornerRadius = 12
        v.clipsToBounds = true
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        return v
    }()
    
    /// Waiting label shown until the remote user joins
    private let waitingLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Waiting for the other\nperson to join…"
        lbl.font = .systemFont(ofSize: 20, weight: .medium)
        lbl.textColor = .white.withAlphaComponent(0.7)
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        return lbl
    }()
    
    /// Pulsing indicator while waiting
    private let waitingSpinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .large)
        s.color = .white.withAlphaComponent(0.6)
        s.hidesWhenStopped = true
        return s
    }()
    
    /// Session duration timer at the top
    private let timerContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        v.layer.cornerRadius = 18
        return v
    }()
    
    private let timerIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "clock.fill")
        iv.tintColor = .systemGreen
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let timerLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "00:00"
        lbl.font = .monospacedDigitSystemFont(ofSize: 18, weight: .bold)
        lbl.textColor = UIColor(red: 0.6, green: 1.0, blue: 0.6, alpha: 1.0) // Light green during buffer
        return lbl
    }()
    
    /// "FREE" badge shown during buffer period
    private let bufferBadge: UILabel = {
        let lbl = UILabel()
        lbl.text = "FREE"
        lbl.font = .systemFont(ofSize: 10, weight: .bold)
        lbl.textColor = UIColor(red: 0.6, green: 1.0, blue: 0.6, alpha: 1.0)
        lbl.textAlignment = .center
        return lbl
    }()
    
    /// Bottom control bar
    private let controlBar: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        v.layer.cornerRadius = 28
        return v
    }()
    
    private let cameraButton = VideoCallViewController.makeControlButton(
        icon: "video.fill",
        color: UIColor(red: 0.22, green: 0.22, blue: 0.28, alpha: 1)
    )
    
    private let switchCameraButton = VideoCallViewController.makeControlButton(
        icon: "arrow.triangle.2.circlepath.camera.fill",
        color: UIColor(red: 0.22, green: 0.22, blue: 0.28, alpha: 1)
    )
    
    private let micButton = VideoCallViewController.makeControlButton(
        icon: "mic.fill",
        color: UIColor(red: 0.22, green: 0.22, blue: 0.28, alpha: 1)
    )
    
    private let endCallButton = VideoCallViewController.makeControlButton(
        icon: "phone.down.fill",
        color: .systemRed
    )
    
    // State
    private var isCameraOn = true
    private var isMicOn = true
    
    // MARK: - Init
    
    /// - Parameters:
    ///   - doubtId: The doubt UUID (used to generate the Agora channel name).
    init(doubtId: UUID) {
        self.doubtId = doubtId
        self.channelName = AgoraConfig.channelName(for: doubtId)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.1, alpha: 1)
        
        setupLayout()
        setupActions()
        initializeAgora()
        joinChannel()
        startSessionTimer()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cleanUp()
    }
    
    override var prefersStatusBarHidden: Bool { true }
    
    // MARK: - Layout
    
    private func setupLayout() {
        // Remote video (full screen)
        view.addSubview(remoteVideoView)
        remoteVideoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            remoteVideoView.topAnchor.constraint(equalTo: view.topAnchor),
            remoteVideoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            remoteVideoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            remoteVideoView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Waiting indicator
        remoteVideoView.addSubview(waitingSpinner)
        remoteVideoView.addSubview(waitingLabel)
        waitingSpinner.translatesAutoresizingMaskIntoConstraints = false
        waitingLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            waitingSpinner.centerXAnchor.constraint(equalTo: remoteVideoView.centerXAnchor),
            waitingSpinner.centerYAnchor.constraint(equalTo: remoteVideoView.centerYAnchor, constant: -30),
            waitingLabel.topAnchor.constraint(equalTo: waitingSpinner.bottomAnchor, constant: 16),
            waitingLabel.centerXAnchor.constraint(equalTo: remoteVideoView.centerXAnchor)
        ])
        waitingSpinner.startAnimating()
        
        // Local video (PiP)
        view.addSubview(localVideoView)
        localVideoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            localVideoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
            localVideoView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            localVideoView.widthAnchor.constraint(equalToConstant: 110),
            localVideoView.heightAnchor.constraint(equalToConstant: 160)
        ])
        
        // Make local video draggable
        let pan = UIPanGestureRecognizer(target: self, action: #selector(dragLocalVideo(_:)))
        localVideoView.addGestureRecognizer(pan)
        localVideoView.isUserInteractionEnabled = true
        
        // Timer badge
        view.addSubview(timerContainer)
        timerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Use a stack view to automatically handle the disappearing badge symmetrically
        let timerStack = UIStackView(arrangedSubviews: [timerIcon, timerLabel, bufferBadge])
        timerStack.axis = .horizontal
        timerStack.spacing = 6
        timerStack.alignment = .center
        timerStack.translatesAutoresizingMaskIntoConstraints = false
        timerContainer.addSubview(timerStack)
        
        timerIcon.translatesAutoresizingMaskIntoConstraints = false
        
        // Set initial green tint for buffer period
        timerIcon.tintColor = UIColor(red: 0.6, green: 1.0, blue: 0.6, alpha: 1.0)
        
        NSLayoutConstraint.activate([
            timerContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            timerContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerContainer.heightAnchor.constraint(equalToConstant: 36),
            
            timerIcon.widthAnchor.constraint(equalToConstant: 18),
            timerIcon.heightAnchor.constraint(equalToConstant: 18),
            
            timerStack.leadingAnchor.constraint(equalTo: timerContainer.leadingAnchor, constant: 12),
            timerStack.trailingAnchor.constraint(equalTo: timerContainer.trailingAnchor, constant: -12),
            timerStack.centerYAnchor.constraint(equalTo: timerContainer.centerYAnchor)
        ])
        
        // Control bar
        view.addSubview(controlBar)
        controlBar.translatesAutoresizingMaskIntoConstraints = false
        
        let controlStack = UIStackView(arrangedSubviews: [cameraButton, switchCameraButton, micButton, endCallButton])
        controlStack.axis = .horizontal
        controlStack.spacing = 20
        controlStack.alignment = .center
        controlStack.distribution = .equalSpacing
        controlBar.addSubview(controlStack)
        controlStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            controlBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            controlBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            controlBar.heightAnchor.constraint(equalToConstant: 70),
            
            controlStack.leadingAnchor.constraint(equalTo: controlBar.leadingAnchor, constant: 24),
            controlStack.trailingAnchor.constraint(equalTo: controlBar.trailingAnchor, constant: -24),
            controlStack.centerYAnchor.constraint(equalTo: controlBar.centerYAnchor),
            
            cameraButton.widthAnchor.constraint(equalToConstant: 52),
            cameraButton.heightAnchor.constraint(equalToConstant: 52),
            switchCameraButton.widthAnchor.constraint(equalToConstant: 52),
            switchCameraButton.heightAnchor.constraint(equalToConstant: 52),
            micButton.widthAnchor.constraint(equalToConstant: 52),
            micButton.heightAnchor.constraint(equalToConstant: 52),
            endCallButton.widthAnchor.constraint(equalToConstant: 60),
            endCallButton.heightAnchor.constraint(equalToConstant: 52)
        ])
        
        // Entrance animation
        controlBar.transform = CGAffineTransform(translationX: 0, y: 120)
        timerContainer.alpha = 0
        localVideoView.alpha = 0
        
        UIView.animate(withDuration: 0.6, delay: 0.3, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.controlBar.transform = .identity
            self.timerContainer.alpha = 1
            self.localVideoView.alpha = 1
        }
    }
    
    // MARK: - Control Button Factory
    
    private static func makeControlButton(icon: String, color: UIColor) -> UIButton {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        btn.setImage(UIImage(systemName: icon, withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = color
        btn.layer.cornerRadius = 26
        btn.clipsToBounds = true
        return btn
    }
    
    // MARK: - Actions
    
    private func setupActions() {
        cameraButton.addTarget(self, action: #selector(toggleCamera), for: .touchUpInside)
        switchCameraButton.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
        micButton.addTarget(self, action: #selector(toggleMic), for: .touchUpInside)
        endCallButton.addTarget(self, action: #selector(endCallTapped), for: .touchUpInside)
    }
    
    @objc private func switchCamera() {
        agoraKit?.switchCamera()
        
        // Add a nice rotation animation
        UIView.animate(withDuration: 0.3) {
            self.switchCameraButton.transform = self.switchCameraButton.transform.rotated(by: .pi)
        }
    }
    
    @objc private func toggleCamera() {
        isCameraOn.toggle()
        agoraKit?.enableLocalVideo(isCameraOn)
        
        let iconName = isCameraOn ? "video.fill" : "video.slash.fill"
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        cameraButton.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)
        cameraButton.backgroundColor = isCameraOn
            ? UIColor(red: 0.22, green: 0.22, blue: 0.28, alpha: 1)
            : UIColor.systemRed.withAlphaComponent(0.7)
        
        localVideoView.isHidden = !isCameraOn
        
        // Subtle bounce animation
        UIView.animate(withDuration: 0.15, animations: {
            self.cameraButton.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        }) { _ in
            UIView.animate(withDuration: 0.15) {
                self.cameraButton.transform = .identity
            }
        }
    }
    
    @objc private func toggleMic() {
        isMicOn.toggle()
        agoraKit?.muteLocalAudioStream(!isMicOn)
        
        let iconName = isMicOn ? "mic.fill" : "mic.slash.fill"
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        micButton.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)
        micButton.backgroundColor = isMicOn
            ? UIColor(red: 0.22, green: 0.22, blue: 0.28, alpha: 1)
            : UIColor.systemRed.withAlphaComponent(0.7)
        
        UIView.animate(withDuration: 0.15, animations: {
            self.micButton.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        }) { _ in
            UIView.animate(withDuration: 0.15) {
                self.micButton.transform = .identity
            }
        }
    }
    
    @objc private func endCallTapped() {
        if isWithinBufferTime {
            // Within buffer — confirm and end
            let alert = UIAlertController(
                title: "End Call",
                message: "You are within the free 2-minute window. Session will end without being counted.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "End", style: .destructive) { [weak self] _ in
                self?.leaveChannelForBufferEnd()
            })
            present(alert, animated: true)
        } else {
            let alert = UIAlertController(
                title: "End Call",
                message: "Are you sure you want to end this session?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "End", style: .destructive) { [weak self] _ in
                self?.leaveChannelAndDismiss()
            })
            present(alert, animated: true)
        }
    }
    
    @objc private func dragLocalVideo(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        
        if let dragView = gesture.view {
            dragView.center = CGPoint(
                x: dragView.center.x + translation.x,
                y: dragView.center.y + translation.y
            )
        }
        gesture.setTranslation(.zero, in: view)
        
        // Snap to edges when released
        if gesture.state == .ended {
            guard let dragView = gesture.view else { return }
            let safeArea = view.safeAreaInsets
            let margin: CGFloat = 16
            
            var finalX = dragView.center.x
            var finalY = dragView.center.y
            
            // Snap X
            let halfW = dragView.bounds.width / 2
            if finalX < view.bounds.midX {
                finalX = margin + halfW
            } else {
                finalX = view.bounds.width - margin - halfW
            }
            
            // Clamp Y
            let halfH = dragView.bounds.height / 2
            let minY = safeArea.top + 56 + halfH
            let maxY = view.bounds.height - safeArea.bottom - 100 - halfH
            finalY = max(minY, min(maxY, finalY))
            
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5) {
                dragView.center = CGPoint(x: finalX, y: finalY)
            }
        }
    }
    
    // MARK: - Session Timer
    
    private func startSessionTimer() {
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.sessionSeconds += 1
            let mins = self.sessionSeconds / 60
            let secs = self.sessionSeconds % 60
            self.timerLabel.text = String(format: "%02d:%02d", mins, secs)
            
            // Transition timer color from green to white when buffer ends
            if self.sessionSeconds == self.bufferDuration {
                UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut) {
                    let white = UIColor.white
                    self.timerLabel.textColor = white
                    self.timerIcon.tintColor = .systemGreen
                    self.bufferBadge.isHidden = true
                    self.timerContainer.layoutIfNeeded()
                }
            }
        }
    }
    
    // MARK: - Agora Setup
    
    private func initializeAgora() {
        let config = AgoraRtcEngineConfig()
        config.appId = AgoraConfig.appId
        
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        agoraKit?.setChannelProfile(.communication)
        agoraKit?.enableVideo()
        agoraKit?.enableAudio()
        
        // Setup local video canvas
        let localCanvas = AgoraRtcVideoCanvas()
        localCanvas.uid = 0 // 0 = local user
        localCanvas.renderMode = .hidden
        localCanvas.view = localVideoView
        agoraKit?.setupLocalVideo(localCanvas)
        agoraKit?.startPreview()
    }
    
    private func joinChannel() {
        let option = AgoraRtcChannelMediaOptions()
        option.publishMicrophoneTrack = true
        option.publishCameraTrack = true
        option.autoSubscribeAudio = true
        option.autoSubscribeVideo = true
        option.clientRoleType = .broadcaster
        
        agoraKit?.joinChannel(
            byToken: AgoraConfig.token,
            channelId: channelName,
            uid: 0,
            mediaOptions: option
        ) { channel, uid, elapsed in
            print("✅ Joined Agora channel: \(channel), uid: \(uid), elapsed: \(elapsed)")
        }
    }
    
    /// Normal end-of-call (after buffer period or remote left)
    private func leaveChannelAndDismiss() {
        cleanUp()
        
        // Animate out
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 0
        }) { _ in
            self.dismiss(animated: false) {
                self.onCallEnded?()
            }
        }
    }
    
    /// Buffer-period end-of-call — session too short to count
    private func leaveChannelForBufferEnd() {
        let elapsed = sessionSeconds
        cleanUp()
        
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 0
        }) { _ in
            self.dismiss(animated: false) {
                self.onBufferEndCall?(elapsed)
            }
        }
    }
    
    private func cleanUp() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        
        agoraKit?.leaveChannel(nil)
        agoraKit?.stopPreview()
        AgoraRtcEngineKit.destroy()
        agoraKit = nil
    }
}

// MARK: - AgoraRtcEngineDelegate

extension VideoCallViewController: AgoraRtcEngineDelegate {
    
    /// Remote user joined — show their video
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("👤 Remote user joined: \(uid)")
        remoteUid = uid
        
        DispatchQueue.main.async {
            // Hide waiting state
            self.waitingSpinner.stopAnimating()
            self.waitingLabel.isHidden = true
            
            // Setup remote video canvas
            let remoteCanvas = AgoraRtcVideoCanvas()
            remoteCanvas.uid = uid
            remoteCanvas.renderMode = .hidden
            remoteCanvas.view = self.remoteVideoView
            engine.setupRemoteVideo(remoteCanvas)
        }
    }
    
    /// Remote user left — show waiting state or end call
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        print("👤 Remote user left: \(uid), reason: \(reason.rawValue)")
        
        DispatchQueue.main.async {
            if uid == self.remoteUid {
                self.remoteUid = nil
                
                if self.isWithinBufferTime {
                    // Remote left during buffer — session not counted
                    let alert = UIAlertController(
                        title: "Session Ended",
                        message: "The other person left within the free 2-minute window. Session will not be counted.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                        self?.leaveChannelForBufferEnd()
                    })
                    self.present(alert, animated: true)
                } else {
                    // Normal end — show regular alert
                    let alert = UIAlertController(
                        title: "Session Ended",
                        message: "The other person has left the call.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                        self?.leaveChannelAndDismiss()
                    })
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    /// Handle any errors
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        print("❌ Agora error: \(errorCode.rawValue)")
        
        let message: String
        if errorCode == .tokenExpired || errorCode == .invalidToken {
            message = "Token Error. If your Agora project requires a token, you cannot use token: nil. Go to the Agora console and test with a 'No Certificate (App ID)' project or disable certificates."
        } else {
            message = "An Agora error occurred: \(errorCode.rawValue)"
        }
        
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Connection Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            // Avoid presenting multiple alerts at once
            if self.presentedViewController == nil {
                self.present(alert, animated: true)
            }
        }
    }
    
    /// Observe connection state changes
    func rtcEngine(_ engine: AgoraRtcEngineKit, connectionChangedTo state: AgoraConnectionState, reason: AgoraConnectionChangedReason) {
        print("📶 Connection State: \(state.rawValue), Reason: \(reason.rawValue)")
        
        DispatchQueue.main.async {
            if reason == .reasonInvalidToken {
                let alert = UIAlertController(
                    title: "Invalid Token Setting",
                    message: "It looks like your Agora Project has 'App Certificate' enabled. For this testing code, you must use a project configured as 'No Certificate (App ID only)'.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                if self.presentedViewController == nil {
                    self.present(alert, animated: true)
                }
            }
        }
    }
}
