import UIKit

/// A popup card that slides down from the top of the screen.
/// Shows solver info with Decline/Start buttons.
/// On Decline, transforms to show "Choose action" with "Remove doubt" / "Look for another solver".
final class SolverPopupView: UIView {
    
    // MARK: - Callbacks
    var onStart: (() -> Void)?
    var onRemoveDoubt: (() -> Void)?
    var onLookForAnotherSolver: (() -> Void)?
    var onDismiss: (() -> Void)?
    
    // MARK: - UI
    private let cardView = UIView()
    
    // State 1: Solver Info
    private let solverInfoContainer = UIView()
    private let solverTitleLabel = UILabel()
    private let solverNameLabel = UILabel()
    private let solverInstituteLabel = UILabel()
    private let solverImageView = UIImageView()
    private let declineButton = UIButton(type: .system)
    private let startButton = UIButton(type: .system)
    
    // State 2: Choose Action
    private let chooseActionContainer = UIView()
    private let backButton = UIButton(type: .system)
    private let chooseActionTitle = UILabel()
    private let removeDoubtButton = UIButton(type: .system)
    private let lookForAnotherButton = UIButton(type: .system)
    
    // MARK: - Data
    private var solverName: String = ""
    private var solverInstitute: String = ""
    private var solverImageURL: String?
    
    // MARK: - Init
    init(solverName: String, solverInstitute: String, solverImageURL: String?) {
        self.solverName = solverName
        self.solverInstitute = solverInstitute
        self.solverImageURL = solverImageURL
        super.init(frame: .zero)
        setupUI()
        loadSolverImage()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Full screen dim background
        backgroundColor = UIColor.black.withAlphaComponent(0.3)
        alpha = 0
        
        // Dismiss on background tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)
        
        // Card
        cardView.backgroundColor = UIColor(red: 254/255, green: 234/255, blue: 162/255, alpha: 1.0) // warm yellow
        cardView.layer.cornerRadius = 20
        cardView.layer.masksToBounds = true
        cardView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cardView)
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
        
        setupSolverInfoState()
        setupChooseActionState()
        
        // Show solver info by default
        chooseActionContainer.isHidden = true
        chooseActionContainer.alpha = 0
    }
    
    // MARK: - State 1: Solver Info
    private func setupSolverInfoState() {
        solverInfoContainer.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(solverInfoContainer)
        
        NSLayoutConstraint.activate([
            solverInfoContainer.topAnchor.constraint(equalTo: cardView.topAnchor),
            solverInfoContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            solverInfoContainer.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            solverInfoContainer.bottomAnchor.constraint(equalTo: cardView.bottomAnchor)
        ])
        
        // Title
        solverTitleLabel.text = "Solver"
        solverTitleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        solverTitleLabel.textColor = .black
        solverTitleLabel.textAlignment = .center
        
        // Solver name
        solverNameLabel.text = solverName
        solverNameLabel.font = .systemFont(ofSize: 22, weight: .bold)
        solverNameLabel.textColor = .black
        
        // Solver institute
        solverInstituteLabel.text = solverInstitute
        solverInstituteLabel.font = .systemFont(ofSize: 16, weight: .regular)
        solverInstituteLabel.textColor = .darkGray
        
        // Profile image
        solverImageView.contentMode = .scaleAspectFill
        solverImageView.clipsToBounds = true
        solverImageView.layer.cornerRadius = 30
        solverImageView.backgroundColor = .systemGray5
        solverImageView.image = UIImage(systemName: "person.circle.fill")
        solverImageView.tintColor = .systemGray3
        
        // Decline button
        var declineConfig = UIButton.Configuration.filled()
        declineConfig.baseBackgroundColor = .systemRed
        declineConfig.baseForegroundColor = .white
        declineConfig.image = UIImage(systemName: "xmark")
        declineConfig.imagePadding = 6
        declineConfig.title = "Decline"
        declineConfig.cornerStyle = .capsule
        declineButton.configuration = declineConfig
        declineButton.addTarget(self, action: #selector(declineTapped), for: .touchUpInside)
        
        // Start button
        var startConfig = UIButton.Configuration.filled()
        startConfig.baseBackgroundColor = .systemOrange
        startConfig.baseForegroundColor = .white
        startConfig.image = UIImage(systemName: "video.fill")
        startConfig.imagePadding = 6
        startConfig.title = "Start"
        startConfig.cornerStyle = .capsule
        startButton.configuration = startConfig
        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)
        
        let buttonStack = UIStackView(arrangedSubviews: [declineButton, startButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        
        // Layout
        [solverTitleLabel, solverNameLabel, solverInstituteLabel, solverImageView, buttonStack].forEach {
            solverInfoContainer.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            solverTitleLabel.topAnchor.constraint(equalTo: solverInfoContainer.topAnchor, constant: 16),
            solverTitleLabel.centerXAnchor.constraint(equalTo: solverInfoContainer.centerXAnchor),
            
            solverImageView.trailingAnchor.constraint(equalTo: solverInfoContainer.trailingAnchor, constant: -20),
            solverImageView.topAnchor.constraint(equalTo: solverTitleLabel.bottomAnchor, constant: 12),
            solverImageView.widthAnchor.constraint(equalToConstant: 60),
            solverImageView.heightAnchor.constraint(equalToConstant: 60),
            
            solverNameLabel.leadingAnchor.constraint(equalTo: solverInfoContainer.leadingAnchor, constant: 20),
            solverNameLabel.trailingAnchor.constraint(equalTo: solverImageView.leadingAnchor, constant: -12),
            solverNameLabel.topAnchor.constraint(equalTo: solverTitleLabel.bottomAnchor, constant: 16),
            
            solverInstituteLabel.leadingAnchor.constraint(equalTo: solverNameLabel.leadingAnchor),
            solverInstituteLabel.trailingAnchor.constraint(equalTo: solverNameLabel.trailingAnchor),
            solverInstituteLabel.topAnchor.constraint(equalTo: solverNameLabel.bottomAnchor, constant: 4),
            
            buttonStack.topAnchor.constraint(equalTo: solverImageView.bottomAnchor, constant: 16),
            buttonStack.leadingAnchor.constraint(equalTo: solverInfoContainer.leadingAnchor, constant: 20),
            buttonStack.trailingAnchor.constraint(equalTo: solverInfoContainer.trailingAnchor, constant: -20),
            buttonStack.heightAnchor.constraint(equalToConstant: 44),
            buttonStack.bottomAnchor.constraint(equalTo: solverInfoContainer.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - State 2: Choose Action
    private func setupChooseActionState() {
        chooseActionContainer.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(chooseActionContainer)
        
        NSLayoutConstraint.activate([
            chooseActionContainer.topAnchor.constraint(equalTo: cardView.topAnchor),
            chooseActionContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            chooseActionContainer.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            chooseActionContainer.bottomAnchor.constraint(equalTo: cardView.bottomAnchor)
        ])
        
        // Back button
        backButton.setImage(UIImage(systemName: "chevron.left.2"), for: .normal)
        backButton.tintColor = .black
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        
        // Title
        chooseActionTitle.text = "Choose action"
        chooseActionTitle.font = .systemFont(ofSize: 22, weight: .bold)
        chooseActionTitle.textColor = .black
        chooseActionTitle.textAlignment = .center
        
        // Remove doubt button
        var removeConfig = UIButton.Configuration.filled()
        removeConfig.baseBackgroundColor = .systemRed
        removeConfig.baseForegroundColor = .white
        removeConfig.title = "Remove doubt"
        removeConfig.cornerStyle = .capsule
        removeDoubtButton.configuration = removeConfig
        removeDoubtButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        removeDoubtButton.addTarget(self, action: #selector(removeDoubtTapped), for: .touchUpInside)
        
        // Look for another solver button
        var lookConfig = UIButton.Configuration.filled()
        lookConfig.baseBackgroundColor = .systemOrange
        lookConfig.baseForegroundColor = .white
        lookConfig.title = "Look for another solver"
        lookConfig.cornerStyle = .capsule
        lookForAnotherButton.configuration = lookConfig
        lookForAnotherButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        lookForAnotherButton.addTarget(self, action: #selector(lookForAnotherTapped), for: .touchUpInside)
        
        // Layout
        [backButton, chooseActionTitle, removeDoubtButton, lookForAnotherButton].forEach {
            chooseActionContainer.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: chooseActionContainer.leadingAnchor, constant: 16),
            backButton.topAnchor.constraint(equalTo: chooseActionContainer.topAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 36),
            backButton.heightAnchor.constraint(equalToConstant: 36),
            
            chooseActionTitle.centerXAnchor.constraint(equalTo: chooseActionContainer.centerXAnchor),
            chooseActionTitle.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            
            removeDoubtButton.topAnchor.constraint(equalTo: chooseActionTitle.bottomAnchor, constant: 20),
            removeDoubtButton.leadingAnchor.constraint(equalTo: chooseActionContainer.leadingAnchor, constant: 20),
            removeDoubtButton.trailingAnchor.constraint(equalTo: chooseActionContainer.trailingAnchor, constant: -20),
            removeDoubtButton.heightAnchor.constraint(equalToConstant: 48),
            
            lookForAnotherButton.topAnchor.constraint(equalTo: removeDoubtButton.bottomAnchor, constant: 12),
            lookForAnotherButton.leadingAnchor.constraint(equalTo: removeDoubtButton.leadingAnchor),
            lookForAnotherButton.trailingAnchor.constraint(equalTo: removeDoubtButton.trailingAnchor),
            lookForAnotherButton.heightAnchor.constraint(equalToConstant: 48),
            lookForAnotherButton.bottomAnchor.constraint(equalTo: chooseActionContainer.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Load Image
    private func loadSolverImage() {
        guard let urlStr = solverImageURL, let url = URL(string: urlStr) else { return }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.solverImageView.image = image
                    }
                }
            } catch {
                print("Failed to load solver popup image:", error)
            }
        }
    }
    
    // MARK: - Actions
    @objc private func startTapped() {
        hide {
            self.onStart?()
        }
    }
    
    @objc private func declineTapped() {
        // Transition to choose action state
        UIView.animate(withDuration: 0.3) {
            self.solverInfoContainer.alpha = 0
        } completion: { _ in
            self.solverInfoContainer.isHidden = true
            self.chooseActionContainer.isHidden = false
            self.chooseActionContainer.alpha = 0
            
            UIView.animate(withDuration: 0.3) {
                self.chooseActionContainer.alpha = 1
            }
        }
    }
    
    @objc private func backTapped() {
        // Go back to solver info state
        UIView.animate(withDuration: 0.3) {
            self.chooseActionContainer.alpha = 0
        } completion: { _ in
            self.chooseActionContainer.isHidden = true
            self.solverInfoContainer.isHidden = false
            self.solverInfoContainer.alpha = 0
            
            UIView.animate(withDuration: 0.3) {
                self.solverInfoContainer.alpha = 1
            }
        }
    }
    
    @objc private func removeDoubtTapped() {
        hide {
            self.onRemoveDoubt?()
        }
    }
    
    @objc private func lookForAnotherTapped() {
        hide {
            self.onLookForAnotherSolver?()
        }
    }
    
    @objc private func backgroundTapped() {
        hide {
            self.onDismiss?()
        }
    }
    
    // MARK: - Show / Hide
    func show(in view: UIView) {
        frame = view.bounds
        view.addSubview(self)
        
        // Start off-screen (above)
        cardView.transform = CGAffineTransform(translationX: 0, y: -300)
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.alpha = 1
            self.cardView.transform = .identity
        }
    }
    
    func hide(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
            self.cardView.transform = CGAffineTransform(translationX: 0, y: -300)
        }) { _ in
            self.removeFromSuperview()
            completion?()
        }
    }
}

// MARK: - Gesture Delegate
extension SolverPopupView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Only dismiss when tapping outside the card
        let location = touch.location(in: self)
        return !cardView.frame.contains(location)
    }
}

final class CountdownViewController: UIViewController {
    
    // MARK: - Callbacks
    /// Called after the video call ends (or immediately if no doubtId is set).
    var onCountdownFinished: (() -> Void)?
    
    /// Called when the student ends the call within the 2-minute buffer period.
    var onBufferEndCall: ((_ elapsedSeconds: Int) -> Void)?
    
    // MARK: - Properties
    private let themeColor: UIColor
    private let doubtId: UUID?
    private var secondsRemaining = 10
    private var timer: Timer?
    
    // MARK: - UI Elements
    private let containerStack = UIStackView()
    private let countdownLabel = UILabel()
    private let clockImageView = UIImageView()
    private let instructionsLabel = UILabel()
    
    /// - Parameters:
    ///   - themeColor: Accent color for the countdown screen.
    ///   - doubtId: Optional doubt UUID. When set, the countdown will automatically
    ///              present `VideoCallViewController` when it reaches zero.
    init(themeColor: UIColor, doubtId: UUID? = nil) {
        self.themeColor = themeColor
        self.doubtId = doubtId
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        startCountdown()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timer?.invalidate()
        timer = nil
    }
    
    private func setupUI() {
        // Container
        containerStack.axis = .vertical
        containerStack.alignment = .center
        containerStack.spacing = 30
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerStack)
        
        NSLayoutConstraint.activate([
            containerStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            containerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
        
        // Countdown Label
        countdownLabel.text = "\(secondsRemaining)s"
        countdownLabel.font = .systemFont(ofSize: 80, weight: .black)
        countdownLabel.textColor = themeColor
        countdownLabel.textAlignment = .center
        containerStack.addArrangedSubview(countdownLabel)
        
        // Clock Image
        let config = UIImage.SymbolConfiguration(pointSize: 140, weight: .medium)
        clockImageView.image = UIImage(systemName: "stopwatch.fill", withConfiguration: config)
        clockImageView.tintColor = themeColor
        clockImageView.contentMode = .scaleAspectFit
        clockImageView.translatesAutoresizingMaskIntoConstraints = false
        containerStack.addArrangedSubview(clockImageView)
        
        // Instructions Label
        instructionsLabel.text = "Get ready with your pen\nand paper..."
        instructionsLabel.font = .systemFont(ofSize: 28, weight: .bold)
        instructionsLabel.textColor = themeColor
        instructionsLabel.textAlignment = .center
        instructionsLabel.numberOfLines = 0
        containerStack.addArrangedSubview(instructionsLabel)
        
        // Optional Animations for clock
        animateClock()
    }
    
    private func animateClock() {
        UIView.animate(withDuration: 1.0, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.clockImageView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }, completion: nil)
    }
    
    private func startCountdown() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.secondsRemaining -= 1
            
            UIView.transition(with: self.countdownLabel, duration: 0.2, options: .transitionCrossDissolve, animations: {
                self.countdownLabel.text = "\(self.secondsRemaining)s"
            }, completion: nil)
            
            if self.secondsRemaining <= 0 {
                self.timer?.invalidate()
                self.timer = nil
                self.countdownDidFinish()
            }
        }
    }
    
    /// Called when the timer reaches zero.
    /// If a doubtId was provided, presents the video call screen;
    /// otherwise fires the callback directly.
    private func countdownDidFinish() {
        guard let doubtId = doubtId else {
            // No doubtId → legacy behaviour
            onCountdownFinished?()
            return
        }
        
        // Present the video call directly on top of the countdown VC
        let videoVC = VideoCallViewController(doubtId: doubtId)
        videoVC.onCallEnded = { [weak self] in
            guard let self = self else { return }
            // Trigger the callback without dismissing so the underlying UI is not exposed.
            // The presenter (UploadDoubtVC or rootVC) handles dismissing or presenting the next screen over it.
            self.onCountdownFinished?()
        }
        
        videoVC.onBufferEndCall = { [weak self] elapsedSeconds in
            guard let self = self else { return }
            self.onBufferEndCall?(elapsedSeconds)
        }
        
        self.present(videoVC, animated: true)
    }
}
