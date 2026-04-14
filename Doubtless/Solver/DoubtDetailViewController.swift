import UIKit

final class DoubtDetailViewController: UIViewController {

    // MARK: - Data
    private let doubt: DoubtItem
    private var statusPollingTimer: Timer?
    private var doubtExistenceTimer: Timer?

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let titleLabel = UILabel()

    // Image carousel
    private let imageScrollView = UIScrollView()
    private let imageStack = UIStackView()
    private let pageControl = UIPageControl()

    private let nameView = InfoRow(icon: "person", text: "")
    private let subjectView = InfoRow(icon: "book", text: "")
    private let languageView = InfoRow(icon: "character.bubble", text: "")
    private let descriptionView = InfoRow(icon: "info.circle", text: "")

    private let startButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let buttonContainer = UIView()

    // MARK: - Init
    init(doubt: DoubtItem) {
        self.doubt = doubt
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureSheet()
        setupUI()
        configure()
        startDoubtExistencePolling()
    }
    
    private func configureSheet() {
        guard let sheet = sheetPresentationController else { return }

        sheet.detents = [
            .custom { context in
                return context.maximumDetentValue * 0.75
            }
        ]

        sheet.prefersGrabberVisible = true
        sheet.preferredCornerRadius = 24
        sheet.largestUndimmedDetentIdentifier = .medium
    }

    // MARK: - Setup
    private func setupUI() {

        // Header
        titleLabel.text = "Description of Doubt"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)

        // Image carousel scroll view
        imageScrollView.isPagingEnabled = true
        imageScrollView.showsHorizontalScrollIndicator = false
        imageScrollView.delegate = self
        imageScrollView.layer.cornerRadius = 12
        imageScrollView.clipsToBounds = true
        imageScrollView.backgroundColor = .secondarySystemBackground

        // Page control
        pageControl.currentPageIndicatorTintColor = .systemOrange
        pageControl.pageIndicatorTintColor = .systemGray4
        pageControl.hidesForSinglePage = true

        // Button container (holds start button + cancel button side by side)
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false

        // Accept / Waiting button
        startButton.setTitle("Accept Request", for: .normal)
        startButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        startButton.backgroundColor = .systemGreen
        startButton.tintColor = .white
        startButton.layer.cornerRadius = 22
        startButton.addTarget(self, action: #selector(acceptRequestTapped), for: .touchUpInside)

        // Cancel button (hidden by default, shown when waiting)
        cancelButton.setTitle("✕", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        cancelButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.85)
        cancelButton.tintColor = .white
        cancelButton.layer.cornerRadius = 22
        cancelButton.isHidden = true
        cancelButton.alpha = 0
        cancelButton.addTarget(self, action: #selector(cancelRequestTapped), for: .touchUpInside)

        buttonContainer.addSubview(startButton)
        buttonContainer.addSubview(cancelButton)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        // Layout
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [titleLabel, imageScrollView, pageControl, nameView, subjectView, languageView, descriptionView, buttonContainer]
            .forEach { contentView.addSubview($0) }

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        [titleLabel, imageScrollView, pageControl, nameView, subjectView, languageView, descriptionView]
            .forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            imageScrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            imageScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            imageScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            imageScrollView.heightAnchor.constraint(equalToConstant: 220),

            pageControl.topAnchor.constraint(equalTo: imageScrollView.bottomAnchor, constant: 8),
            pageControl.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            nameView.topAnchor.constraint(equalTo: pageControl.bottomAnchor, constant: 12),
            nameView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            subjectView.topAnchor.constraint(equalTo: nameView.bottomAnchor, constant: 12),
            subjectView.leadingAnchor.constraint(equalTo: nameView.leadingAnchor),
            subjectView.trailingAnchor.constraint(equalTo: nameView.trailingAnchor),

            languageView.topAnchor.constraint(equalTo: subjectView.bottomAnchor, constant: 12),
            languageView.leadingAnchor.constraint(equalTo: subjectView.leadingAnchor),
            languageView.trailingAnchor.constraint(equalTo: subjectView.trailingAnchor),

            descriptionView.topAnchor.constraint(equalTo: languageView.bottomAnchor, constant: 12),
            descriptionView.leadingAnchor.constraint(equalTo: languageView.leadingAnchor),
            descriptionView.trailingAnchor.constraint(equalTo: languageView.trailingAnchor),

            buttonContainer.topAnchor.constraint(equalTo: descriptionView.bottomAnchor, constant: 24),
            buttonContainer.leadingAnchor.constraint(equalTo: descriptionView.leadingAnchor),
            buttonContainer.trailingAnchor.constraint(equalTo: descriptionView.trailingAnchor),
            buttonContainer.heightAnchor.constraint(equalToConstant: 50),
            buttonContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30),

            // Start button fills the container but leaves room for cancel button when visible
            startButton.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            startButton.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor),
            startButton.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor),

            // Cancel button pinned to the right
            cancelButton.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor),
            cancelButton.widthAnchor.constraint(equalToConstant: 50)
        ])

        // Set up dynamic trailing constraints for the start button
        startButtonTrailingToContainer = startButton.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor)
        startButtonTrailingToCancelButton = startButton.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor, constant: -10)
        startButtonTrailingToContainer?.isActive = true
    }

    // MARK: - Configure

    private func configure() {
        nameView.setText(doubt.name)
        subjectView.setText(doubt.subject)
        languageView.setText(doubt.language ?? "Not specified")
        descriptionView.setText(doubt.description)
    }

    private var hasLoadedImages = false
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Only load images once the geometry of imageScrollView is finalized
        if !hasLoadedImages && imageScrollView.bounds.width > 0 {
            hasLoadedImages = true
            loadImages()
        }
    }

    // MARK: - Load Images from URLs

    private func loadImages() {
        let urls = doubt.imageURLs
        guard !urls.isEmpty else {
            // Show a placeholder if there are no images
            let placeholder = UIImageView()
            placeholder.image = UIImage(systemName: "photo")
            placeholder.tintColor = .tertiaryLabel
            placeholder.contentMode = .scaleAspectFit
            placeholder.clipsToBounds = true
            placeholder.translatesAutoresizingMaskIntoConstraints = false
            imageScrollView.addSubview(placeholder)

            NSLayoutConstraint.activate([
                placeholder.widthAnchor.constraint(equalTo: imageScrollView.frameLayoutGuide.widthAnchor),
                placeholder.heightAnchor.constraint(equalTo: imageScrollView.frameLayoutGuide.heightAnchor),
                placeholder.leadingAnchor.constraint(equalTo: imageScrollView.contentLayoutGuide.leadingAnchor),
                placeholder.trailingAnchor.constraint(equalTo: imageScrollView.contentLayoutGuide.trailingAnchor),
                placeholder.topAnchor.constraint(equalTo: imageScrollView.contentLayoutGuide.topAnchor),
                placeholder.bottomAnchor.constraint(equalTo: imageScrollView.contentLayoutGuide.bottomAnchor)
            ])
            pageControl.numberOfPages = 0
            return
        }

        pageControl.numberOfPages = urls.count
        pageControl.currentPage = 0

        var previousImageView: UIImageView? = nil

        for (index, urlString) in urls.enumerated() {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill // Changed to aspect fill so it visually occupies the area
            imageView.clipsToBounds = true
            imageView.backgroundColor = .secondarySystemBackground
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            // Add interaction
            imageView.isUserInteractionEnabled = true
            imageView.tag = index
            let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
            imageView.addGestureRecognizer(tap)

            let spinner = UIActivityIndicatorView(style: .large)
            spinner.color = .systemBlue
            spinner.translatesAutoresizingMaskIntoConstraints = false
            spinner.startAnimating()

            imageView.addSubview(spinner)
            imageScrollView.addSubview(imageView)

            var constraints = [
                imageView.widthAnchor.constraint(equalTo: imageScrollView.frameLayoutGuide.widthAnchor),
                imageView.heightAnchor.constraint(equalTo: imageScrollView.frameLayoutGuide.heightAnchor),
                imageView.topAnchor.constraint(equalTo: imageScrollView.contentLayoutGuide.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: imageScrollView.contentLayoutGuide.bottomAnchor),
                spinner.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
                spinner.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
            ]

            if let prev = previousImageView {
                constraints.append(imageView.leadingAnchor.constraint(equalTo: prev.trailingAnchor))
            } else {
                constraints.append(imageView.leadingAnchor.constraint(equalTo: imageScrollView.contentLayoutGuide.leadingAnchor))
            }

            if index == urls.count - 1 {
                constraints.append(imageView.trailingAnchor.constraint(equalTo: imageScrollView.contentLayoutGuide.trailingAnchor))
            }

            NSLayoutConstraint.activate(constraints)
            previousImageView = imageView

            guard let url = URL(string: urlString) else {
                imageView.backgroundColor = .systemYellow // Invalid URL
                spinner.stopAnimating()
                continue
            }

            Task {
                do {
                    let (data, response) = try await URLSession.shared.data(from: url)
                    await MainActor.run {
                        spinner.stopAnimating()
                        spinner.removeFromSuperview()
                        
                        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                            imageView.backgroundColor = .systemOrange // HTTP Error
                            return
                        }
                        
                        if let image = UIImage(data: data) {
                            imageView.backgroundColor = .clear // Success
                            imageView.image = image
                        } else {
                            imageView.backgroundColor = .systemRed // Decoding Error
                        }
                    }
                } catch {
                    await MainActor.run {
                        spinner.stopAnimating()
                        spinner.removeFromSuperview()
                        imageView.backgroundColor = .systemPurple // Network Error
                        print("Network Error:", error)
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func acceptRequestTapped() {
        guard let doubtId = doubt.id else {
            print("No doubt ID available")
            return
        }
        
        // Show loading state
        startButton.isEnabled = false
        startButton.setTitle("Accepting...", for: .normal)
        startButton.backgroundColor = .systemGray3
        
        Task {
            do {
                // Get current solver's info
                let solverInfo = try await SupabaseManager.shared.getCurrentSolverInfo()
                
                // Update the doubt in Supabase
                try await SupabaseManager.shared.acceptDoubt(
                    doubtId: doubtId,
                    solverName: solverInfo.name,
                    solverInstitute: solverInfo.institute,
                    solverImageURL: solverInfo.imageURL
                )
                
                DispatchQueue.main.async {
                    self.startButton.setTitle("Accepted ✓", for: .normal)
                    self.startButton.backgroundColor = .systemGreen
                    self.isModalInPresentation = true // Prevent swipe down
                    
                    // Wait for student to start
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.startButton.setTitle("Waiting for student...", for: .normal)
                        self.startButton.backgroundColor = .systemOrange
                        self.showCancelButton()
                        self.listenForCountdown()
                    }
                }
                
            } catch {
                print("Failed to accept doubt:", error)
                DispatchQueue.main.async {
                    self.startButton.isEnabled = true
                    self.startButton.setTitle("Accept Request", for: .normal)
                    self.startButton.backgroundColor = .systemGreen
                    
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to accept this doubt. Try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    @objc private func imageTapped(_ sender: UITapGestureRecognizer) {
        guard let imageView = sender.view as? UIImageView, let image = imageView.image else { return }
        
        let zoomVC = ImageZoomViewController(image: image)
        present(zoomVC, animated: true)
    }

    // MARK: - Cancel Request

    private var startButtonTrailingToContainer: NSLayoutConstraint?
    private var startButtonTrailingToCancelButton: NSLayoutConstraint?

    private func showCancelButton() {
        // Swap trailing constraint to make room for cancel button
        startButtonTrailingToContainer?.isActive = false
        startButtonTrailingToCancelButton?.isActive = true

        cancelButton.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.cancelButton.alpha = 1
            self.buttonContainer.layoutIfNeeded()
        }
    }

    private func hideCancelButton() {
        startButtonTrailingToCancelButton?.isActive = false
        startButtonTrailingToContainer?.isActive = true

        UIView.animate(withDuration: 0.25, animations: {
            self.cancelButton.alpha = 0
            self.buttonContainer.layoutIfNeeded()
        }) { _ in
            self.cancelButton.isHidden = true
        }
    }

    @objc private func cancelRequestTapped() {
        guard let doubtId = doubt.id else { return }

        let alert = UIAlertController(
            title: "Decline Request",
            message: "Do you want to decline the connection request?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Go Back", style: .cancel))

        alert.addAction(UIAlertAction(title: "Decline", style: .destructive) { [weak self] _ in
            guard let self = self else { return }

            // Immediate UI feedback
            self.cancelButton.isEnabled = false
            self.startButton.setTitle("Declining...", for: .normal)
            self.startButton.backgroundColor = .systemGray3

            self.stopStatusPolling()

            Task {
                do {
                    // Set status to "declined" so student side detects it
                    try await SupabaseManager.shared.updateDoubtStatus(doubtId: doubtId, status: "declined")

                    DispatchQueue.main.async {
                        self.isModalInPresentation = false
                        self.dismiss(animated: true)
                    }
                } catch {
                    print("Failed to decline acceptance:", error)
                    DispatchQueue.main.async {
                        // Revert UI so solver can try again
                        self.cancelButton.isEnabled = true
                        self.startButton.setTitle("Waiting for student...", for: .normal)
                        self.startButton.backgroundColor = .systemOrange
                        self.listenForCountdown()

                        let errorAlert = UIAlertController(
                            title: "Error",
                            message: "Failed to decline. Please try again.",
                            preferredStyle: .alert
                        )
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(errorAlert, animated: true)
                    }
                }
            }
        })

        present(alert, animated: true)
    }
    
    private func listenForCountdown() {
        guard doubt.id != nil else { return }
        stopStatusPolling()
        
        // Poll every 2 seconds — reliable fallback instead of realtime
        statusPollingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkDoubtStatusForCountdown()
        }
        // Also check immediately
        checkDoubtStatusForCountdown()
    }
    
    private func stopStatusPolling() {
        statusPollingTimer?.invalidate()
        statusPollingTimer = nil
    }
    
    private func checkDoubtStatusForCountdown() {
        guard let doubtId = doubt.id else {
            stopStatusPolling()
            return
        }
        
        Task {
            do {
                let updatedDoubt = try await SupabaseManager.shared.fetchDoubtById(doubtId: doubtId)
                guard let updatedDoubt = updatedDoubt else {
                    // Doubt was deleted by the student
                    DispatchQueue.main.async {
                        self.stopStatusPolling()
                        self.stopDoubtExistencePolling()
                        self.showDoubtRemovedAlert()
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    if updatedDoubt.status == "countdown_started" {
                        self.stopStatusPolling()
                        
                        let countdownVC = CountdownViewController(themeColor: .systemCyan, doubtId: updatedDoubt.id)
                        countdownVC.modalPresentationStyle = .overFullScreen
                        countdownVC.modalTransitionStyle = .crossDissolve
                        let doubtId = updatedDoubt.id
                        countdownVC.onCountdownFinished = {
                            print("✅ Video call ended (Solver side)")
                            Task {
                                _ = try? await SupabaseManager.shared.updateDoubtStatus(doubtId: doubtId, status: "completed")
                                DispatchQueue.main.async {
                                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                          let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
                                    
                                    rootVC.dismiss(animated: true) {
                                        var topVC = rootVC
                                        while let presented = topVC.presentedViewController {
                                            topVC = presented
                                        }
                                        let alert = UIAlertController(title: "Session Completed", message: "+₹20.40 Earned from Session", preferredStyle: .alert)
                                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                                        topVC.present(alert, animated: true)
                                    }
                                }
                            }
                        }
                        
                        // Handle buffer-end on solver side (student left within 2 min)
                        countdownVC.onBufferEndCall = { elapsedSeconds in
                            print("⏱️ Buffer end on SOLVER side at \(elapsedSeconds)s")
                            // Just dismiss everything and return to the solve feed.
                            DispatchQueue.main.async {
                                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                      let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
                                
                                rootVC.dismiss(animated: true) {
                                    var topVC = rootVC
                                    while let presented = topVC.presentedViewController {
                                        topVC = presented
                                    }
                                    
                                    let alert = UIAlertController(
                                        title: "Session Ended Early",
                                        message: "The student ended the session within the free window.",
                                        preferredStyle: .alert
                                    )
                                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                                    topVC.present(alert, animated: true)
                                }
                            }
                        }
                        
                        // Dismiss this sheet first, then present the countdown
                        // from the root VC so it covers the full screen properly
                        self.dismiss(animated: false) {
                            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                  let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
                            
                            // Walk to the topmost presented VC
                            var topVC = rootVC
                            while let presented = topVC.presentedViewController {
                                topVC = presented
                            }
                            topVC.present(countdownVC, animated: true)
                        }
                    } else if updatedDoubt.status == "removed" || updatedDoubt.status == "pending" {
                        self.stopStatusPolling()
                        self.dismiss(animated: true)
                    }
                }
            } catch {
                print("Error polling doubt status:", error)
            }
        }
    }
    
    // MARK: - Doubt Existence Polling
    
    private func startDoubtExistencePolling() {
        stopDoubtExistencePolling()
        doubtExistenceTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.checkDoubtStillExists()
        }
    }
    
    private func stopDoubtExistencePolling() {
        doubtExistenceTimer?.invalidate()
        doubtExistenceTimer = nil
    }
    
    private func checkDoubtStillExists() {
        guard let doubtId = doubt.id else { return }
        
        Task {
            do {
                let fetchedDoubt = try await SupabaseManager.shared.fetchDoubtById(doubtId: doubtId)
                if fetchedDoubt == nil {
                    DispatchQueue.main.async {
                        self.stopDoubtExistencePolling()
                        self.stopStatusPolling()
                        self.showDoubtRemovedAlert()
                    }
                }
            } catch {
                print("Error checking doubt existence:", error)
            }
        }
    }
    
    private func showDoubtRemovedAlert() {
        // Prevent duplicate alerts
        guard presentedViewController == nil else { return }
        
        let alert = UIAlertController(
            title: "Doubt Removed",
            message: "The student removed the doubt.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.isModalInPresentation = false
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopStatusPolling()
        stopDoubtExistencePolling()
    }
}

// MARK: - UIScrollViewDelegate (page control)

extension DoubtDetailViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == imageScrollView, imageScrollView.bounds.width > 0 else { return }
        let page = Int(round(scrollView.contentOffset.x / imageScrollView.bounds.width))
        pageControl.currentPage = page
    }
}
