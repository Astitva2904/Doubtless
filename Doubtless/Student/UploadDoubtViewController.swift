import UIKit
import PhotosUI
import Auth

class AnimatedButton: UIButton {
    override var isHighlighted: Bool {
        didSet {
            let transform: CGAffineTransform = isHighlighted ? .init(scaleX: 0.95, y: 0.95) : .identity
            UIView.animate(withDuration: 0.1, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
                self.transform = transform
            }
        }
    }
}

final class UploadDoubtViewController: UIViewController {

    // MARK: - State
    private var selectedImages: [UIImage] = []
    private var uploadedDoubts: [Doubt] = []
    private var spinnerButton: SpinnerButton!
    
    // Track current doubt for status polling
    private var currentDoubtId: UUID?
    private var solverAcceptedButton: SolverAcceptedButton?
    private var acceptedDoubt: DoubtDB?
    private var statusPollingTimer: Timer?
    private var doubtUploadTime: Date?

    // MARK: - Nav Spinner
    private let navSpinner = UIActivityIndicatorView(style: .medium)

    // MARK: - Active Doubt Overlay
    private let activeDoubtOverlayView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.alpha = 0
        effectView.isUserInteractionEnabled = true
        
        let label = UILabel()
        label.text = "You already have\nan active doubt request"
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        
        let subLabel = UILabel()
        subLabel.text = "Either solve or remove your existing doubt to be able to upload another."
        subLabel.font = .systemFont(ofSize: 16)
        subLabel.textColor = .lightGray
        subLabel.numberOfLines = 0
        subLabel.textAlignment = .center
        
        // Let's add an icon too
        let iconView = UIImageView(image: UIImage(systemName: "hand.raised.fill"))
        iconView.tintColor = .systemOrange
        iconView.contentMode = .scaleAspectFit
        iconView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        iconView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        
        let stack = UIStackView(arrangedSubviews: [iconView, label, subLabel])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        effectView.contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: effectView.contentView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: effectView.contentView.centerYAnchor, constant: -40),
            stack.leadingAnchor.constraint(equalTo: effectView.contentView.leadingAnchor, constant: 40),
            stack.trailingAnchor.constraint(equalTo: effectView.contentView.trailingAnchor, constant: -40)
        ])
        
        return effectView
    }()

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let uploadCard = UIView()
    private let uploadButton: UIButton = {
        var config = UIButton.Configuration.plain()
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 34, weight: .regular)
        config.image = UIImage(systemName: "photo.on.rectangle", withConfiguration: imageConfig)
        config.title = "Add photos"
        config.imagePlacement = .top
        config.imagePadding = 12
        config.baseForegroundColor = .label
        return UIButton(configuration: config)
    }()

    private let imageScrollView = UIScrollView()
    private let imageStack = UIStackView()

    private let subjectButton = UIButton(type: .system)
    private let languageButton = UIButton(type: .system)

    private let doubtTextView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16)
        tv.backgroundColor = .secondarySystemBackground
        tv.layer.cornerRadius = 12
        tv.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
        return tv
    }()

    private let uploadActionButton: AnimatedButton = {
        let b = AnimatedButton(type: .custom)
        b.setTitle("Upload Doubt", for: .normal)
        b.backgroundColor = .systemOrange
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.layer.cornerRadius = 26
        b.alpha = 0.4
        b.isEnabled = false
        return b
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Upload"
        view.backgroundColor = .systemBackground

        setupUI()
        setupMenus()
        setupActions()

        doubtTextView.delegate = self
        updateUploadButtonState()
        
        setupKeyboardHandling()
    }

    // MARK: - Validation
    private var isFormValid: Bool {
        !selectedImages.isEmpty &&
        !(subjectButton.title(for: .normal)?.contains("Select") ?? true) &&
        !doubtTextView.text.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func updateUploadButtonState() {

        print("Images:", selectedImages.count)
        print("Subject:", subjectButton.title(for: .normal) ?? "")
        print("Language:", languageButton.title(for: .normal) ?? "")
        print("Text:", doubtTextView.text ?? "")

        uploadActionButton.isEnabled = isFormValid
        uploadActionButton.alpha = isFormValid ? 1.0 : 0.4
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        contentStack.axis = .vertical
        contentStack.spacing = 24
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 40, right: 20)
        contentStack.isLayoutMarginsRelativeArrangement = true

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        setupUploadCard()
        setupImagePreview()
        setupDropdown(subjectButton, title: "Subject")
        setupDropdown(languageButton, title: "Language of Communication")

        doubtTextView.heightAnchor.constraint(equalToConstant: 160).isActive = true
        uploadActionButton.heightAnchor.constraint(equalToConstant: 52).isActive = true

        contentStack.addArrangedSubview(uploadCard)
        contentStack.addArrangedSubview(imageScrollView)
        contentStack.addArrangedSubview(section("Subject"))
        contentStack.addArrangedSubview(subjectButton)
        contentStack.addArrangedSubview(section("Language of Communication"))
        contentStack.addArrangedSubview(languageButton)
        contentStack.addArrangedSubview(section("Describe your doubt"))
        contentStack.addArrangedSubview(doubtTextView)
        contentStack.addArrangedSubview(uploadActionButton)

        view.addSubview(activeDoubtOverlayView)
        activeDoubtOverlayView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activeDoubtOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            activeDoubtOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            activeDoubtOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            activeDoubtOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupUploadCard() {
        uploadCard.backgroundColor = .secondarySystemBackground
        uploadCard.layer.cornerRadius = 16
        uploadCard.addSubview(uploadButton)

        uploadButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            uploadCard.heightAnchor.constraint(equalToConstant: 140),
            uploadButton.centerXAnchor.constraint(equalTo: uploadCard.centerXAnchor),
            uploadButton.centerYAnchor.constraint(equalTo: uploadCard.centerYAnchor)
        ])
    }

    private func setupImagePreview() {
        imageScrollView.isHidden = true
        imageScrollView.heightAnchor.constraint(equalToConstant: 120).isActive = true
        imageScrollView.showsHorizontalScrollIndicator = false

        imageStack.axis = .horizontal
        imageStack.spacing = 12

        imageScrollView.addSubview(imageStack)
        imageStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageStack.topAnchor.constraint(equalTo: imageScrollView.topAnchor),
            imageStack.leadingAnchor.constraint(equalTo: imageScrollView.leadingAnchor),
            imageStack.trailingAnchor.constraint(equalTo: imageScrollView.trailingAnchor),
            imageStack.bottomAnchor.constraint(equalTo: imageScrollView.bottomAnchor),
            imageStack.heightAnchor.constraint(equalTo: imageScrollView.heightAnchor)
        ])
    }

    private func setupDropdown(_ button: UIButton, title: String) {
        button.setTitle("Select \(title)", for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 12
        button.contentHorizontalAlignment = .left
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        button.configuration = config
    }

    private func section(_ title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        return label
    }

    // MARK: - Menus
    private func setupMenus() {
        subjectButton.menu = UIMenu(children: [
            UIAction(title: "Mathematics") { [weak self] _ in self?.setSubject("Mathematics") },
            UIAction(title: "Physics") { [weak self] _ in self?.setSubject("Physics") },
            UIAction(title: "Chemistry") { [weak self] _ in self?.setSubject("Chemistry") }
        ])
        subjectButton.showsMenuAsPrimaryAction = true

        languageButton.menu = UIMenu(children: [
            UIAction(title: "English") { [weak self] _ in self?.setLanguage("English") },
            UIAction(title: "Hindi") { [weak self] _ in self?.setLanguage("Hindi") },
            UIAction(title: "Telugu") { [weak self] _ in self?.setLanguage("Telugu") },
            UIAction(title: "Tamil") { [weak self] _ in self?.setLanguage("Tamil") },
            UIAction(title: "Kannada") { [weak self] _ in self?.setLanguage("Kannada") },
            UIAction(title: "Malayalam") { [weak self] _ in self?.setLanguage("Malayalam") },
            UIAction(title: "Bengali") { [weak self] _ in self?.setLanguage("Bengali") },
            UIAction(title: "Marathi") { [weak self] _ in self?.setLanguage("Marathi") },
            UIAction(title: "Gujarati") { [weak self] _ in self?.setLanguage("Gujarati") },
            UIAction(title: "Punjabi") { [weak self] _ in self?.setLanguage("Punjabi") },
            UIAction(title: "Odia") { [weak self] _ in self?.setLanguage("Odia") },
            UIAction(title: "Urdu") { [weak self] _ in self?.setLanguage("Urdu") }
        ])
        languageButton.showsMenuAsPrimaryAction = true
    }

    private func setSubject(_ value: String) {
        subjectButton.setTitle(value, for: .normal)
        subjectButton.setTitleColor(.label, for: .normal)
        updateUploadButtonState()
    }

    private func setLanguage(_ value: String) {
        languageButton.setTitle(value, for: .normal)
        languageButton.setTitleColor(.label, for: .normal)
        updateUploadButtonState()
    }

    // MARK: - Actions
    private func setupActions() {
        uploadButton.addTarget(self, action: #selector(openGallery), for: .touchUpInside)
        uploadActionButton.addTarget(self, action: #selector(handleUpload), for: .touchUpInside)
    }

    @objc private func openGallery() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 5

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func handleUpload() {
        
        print("UPLOAD BUTTON TAPPED")

        print("Images:", selectedImages.count)
        print("Subject:", subjectButton.title(for: .normal) ?? "")
        print("Language:", languageButton.title(for: .normal) ?? "")
        print("Text:", doubtTextView.text ?? "")

        guard isFormValid else { return }

        uploadActionButton.isEnabled = false

        Task {
            // Check credit balance before uploading
            do {
                let canAfford = try await CreditsManager.shared.canAffordSession()
                if !canAfford {
                    DispatchQueue.main.async {
                        self.uploadActionButton.isEnabled = true
                        let alert = UIAlertController(
                            title: "Insufficient Creds",
                            message: "You need at least 30 Creds to submit a doubt. Visit the Creds Store to purchase more.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "Buy Creds", style: .default) { _ in
                            self.navigationController?.pushViewController(CreditStoreViewController(), animated: true)
                        })
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                        self.present(alert, animated: true)
                    }
                    return
                }
            } catch {
                print("Balance check error:", error)
            }
            // Generate a unique ID for this doubt to track it
            let doubtId = UUID()
            self.currentDoubtId = doubtId
            self.doubtUploadTime = Date()

            do {

                var imageURLs: [String]?

                // 1️⃣ Upload all images to Supabase Storage
                if !selectedImages.isEmpty {
                    imageURLs = try await SupabaseManager.shared.uploadImages(selectedImages)
                }

                // 2️⃣ Insert doubt into Supabase DB
                var actualName = "Student"
                var actualPicUrl: String? = nil
                
                if let currentUser = try? await SupabaseManager.shared.getCurrentUser() {
                   if let nameValue = currentUser.userMetadata["name"]?.stringValue {
                       actualName = nameValue
                   }
                   if let picValue = currentUser.userMetadata["profile_image_url"]?.stringValue {
                       actualPicUrl = picValue
                   }
                }
                
                try await SupabaseManager.shared.uploadDoubt(
                    id: doubtId,
                    studentName: actualName,
                    studentImageUrl: actualPicUrl,
                    subject: subjectButton.title(for: .normal) ?? "",
                    description: doubtTextView.text,
                    imageURLs: imageURLs,
                    language: languageButton.title(for: .normal)
                )

                // 3️⃣ Continue your existing UI flow
                DispatchQueue.main.async {
                    self.showUploadSuccess()
                }

            } catch {
                print("Upload failed:", error)
                self.currentDoubtId = nil
                
                DispatchQueue.main.async {
                    self.uploadActionButton.isEnabled = true
                    let alert = UIAlertController(title: "Upload Failed", message: "There was an error uploading your doubt. Please ensure your database rules allow this upload. Details: \(error.localizedDescription)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    // MARK: - Upload Flow
    private func showUploadSuccess() {
        hideTabBar()
        hideNavigationBar()

        let successView = UploadSuccessView(frame: view.bounds)
        view.addSubview(successView)

        successView.play { [weak self] in
            guard let self else { return }

            // 1️⃣ Prepare next overlay FIRST
            let searchingView = SearchingSolverView(frame: self.view.bounds)
            searchingView.alpha = 0
            self.view.addSubview(searchingView)

            // 2️⃣ Fade in searching view
            UIView.animate(withDuration: 0.25) {
                searchingView.alpha = 1
            } completion: { _ in
                // 3️⃣ NOW remove success view
                successView.removeFromSuperview()
            }

            // 4️⃣ Finish searching later
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                searchingView.hide {
                    searchingView.removeFromSuperview()
                    self.restoreAfterSearching()
                }
            }
        }
    }

    private func showSearchingSolver() {
        let searchingView = SearchingSolverView(frame: view.bounds)
        view.addSubview(searchingView)
        searchingView.show()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            searchingView.hide {
                searchingView.removeFromSuperview()
                self.restoreAfterSearching()
            }
        }
    }

    // MARK: - FINAL RESTORE
    private func restoreAfterSearching() {
        resetForm()
        showNavSpinner()
        showNavigationBar()
        showTabBar()
        
        // Start polling for doubt status changes
        startStatusPolling()

        // Show overlay so user can't upload again
        showActiveDoubtOverlay()
    }

    private func showActiveDoubtOverlay() {
        view.bringSubviewToFront(activeDoubtOverlayView)
        UIView.animate(withDuration: 0.3) {
            self.activeDoubtOverlayView.alpha = 1
        }
    }

    private func hideActiveDoubtOverlay() {
        UIView.animate(withDuration: 0.3) {
            self.activeDoubtOverlayView.alpha = 0
        }
    }

    private func showNavSpinner() {
        spinnerButton = SpinnerButton()
        spinnerButton.addTarget(self, action: #selector(spinnerTapped), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinnerButton)
    }
    
    // MARK: - Poll for Doubt Status Changes (every 3 seconds)
    
    private func startStatusPolling() {
        stopStatusPolling() // Ensure no duplicate timers
        
        statusPollingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.checkDoubtStatus()
        }
    }
    
    private func stopStatusPolling() {
        statusPollingTimer?.invalidate()
        statusPollingTimer = nil
    }
    
    private func checkDoubtStatus() {
        guard let doubtId = currentDoubtId else {
            stopStatusPolling()
            return
        }
        
        // MARK: - 15-minute timeout check
        if let uploadTime = doubtUploadTime,
           Date().timeIntervalSince(uploadTime) >= 900 { // 900 seconds = 15 minutes
            // Only expire if doubt hasn't moved to an active session
            if acceptedDoubt == nil {
                handleDoubtExpired(doubtId: doubtId)
                return
            }
        }
        
        Task {
            do {
                let doubt = try await SupabaseManager.shared.fetchDoubtById(doubtId: doubtId)
                
                guard let doubt = doubt else { return }
                
                DispatchQueue.main.async {
                    if doubt.status == "accepted" && self.acceptedDoubt == nil {
                        // Solver just accepted! Show the solver info
                        // Keep polling so we can detect if solver later declines
                        self.acceptedDoubt = doubt
                        self.showSolverAccepted(doubt: doubt)
                        
                        // Auto-show the popup immediately
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            self.showSolverPopup(doubt: doubt)
                        }
                    } else if doubt.status == "declined" {
                        // Solver declined the request
                        self.stopStatusPolling()
                        
                        // Dismiss any solver popup that might be showing
                        if let window = self.view.window {
                            for subview in window.subviews {
                                if let popup = subview as? SolverPopupView {
                                    popup.hide()
                                }
                            }
                        }
                        
                        // Reset solver-specific state
                        self.acceptedDoubt = nil
                        self.solverAcceptedButton = nil
                        self.showNavSpinner()
                        
                        // Show alert to student
                        let alert = UIAlertController(
                            title: "Request Declined",
                            message: "The solver has declined your connection request. Don't worry — we're looking for another solver for you!",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                            guard let self = self else { return }
                            // Reset doubt back to pending so other solvers can pick it up
                            Task {
                                do {
                                    try await SupabaseManager.shared.resetDoubtToPending(doubtId: doubtId)
                                } catch {
                                    print("Failed to reset doubt to pending:", error)
                                }
                            }
                            // Resume polling for new solver
                            self.startStatusPolling()
                        })
                        self.present(alert, animated: true)
                    }
                }
            } catch {
                print("Error polling doubt status:", error)
            }
        }
    }
    
    // MARK: - Solver Accepted → Replace Spinner with Profile Image
    
    private func showSolverAccepted(doubt: DoubtDB) {
        let button = SolverAcceptedButton()
        button.configure(
            name: doubt.solver_name ?? "Solver",
            institute: doubt.solver_institute ?? "",
            imageURL: doubt.solver_image_url
        )
        button.addTarget(self, action: #selector(solverAcceptedTapped), for: .touchUpInside)
        
        self.solverAcceptedButton = button
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
        button.animateAppearance()
    }
    
    private func showSolverPopup(doubt: DoubtDB) {
        let popup = SolverPopupView(
            solverName: doubt.solver_name ?? "Solver",
            solverInstitute: doubt.solver_institute ?? "",
            solverImageURL: doubt.solver_image_url
        )
        
        popup.onStart = { [weak self] in
            guard let self = self, let doubtId = self.currentDoubtId else { return }
            
            // First update DB status so solver gets the realtime event,
            // THEN start student countdown — keeps both sides in sync.
            Task {
                do {
                    try await SupabaseManager.shared.updateDoubtStatus(doubtId: doubtId, status: "countdown_started")
                    
                    // DB update succeeded — solver will receive the realtime event now.
                    // Present countdown on student side immediately after.
                    DispatchQueue.main.async {
                        let countdownVC = CountdownViewController(themeColor: .systemOrange, doubtId: doubtId)
                        countdownVC.modalPresentationStyle = .overFullScreen
                        countdownVC.modalTransitionStyle = .crossDissolve
                        countdownVC.onCountdownFinished = { [weak self] in
                            print("✅ Video call ended (Student Side) - Completed")
                            
                            guard let self = self, let doubt = self.acceptedDoubt else { return }
                            
                            // Deduct credits after a full successful session (> 2 min)
                            Task {
                                do {
                                    // doubt.solver_id is now correctly populated!
                                    try await CreditsManager.shared.deductForSession(
                                        doubtId: doubtId,
                                        solverId: doubt.solver_id ?? ""
                                    )
                                } catch {
                                    print("Credit deduction error:", error)
                                }
                            }
                            
                            let feedbackVC = FeedbackViewController(doubtId: doubtId, solverName: doubt.solver_name ?? "Solver")
                            
                            feedbackVC.onSubmitted = {
                                DispatchQueue.main.async {
                                    // Dismiss both FeedbackVC and CountdownVC
                                    self.dismiss(animated: true) {
                                        // Reset student UI state after call ends
                                        self.currentDoubtId = nil
                                        self.acceptedDoubt = nil
                                        self.solverAcceptedButton = nil
                                        self.navigationItem.rightBarButtonItem = nil
                                        self.hideActiveDoubtOverlay()
                                        
                                        let alert = UIAlertController(title: "Session Completed", message: "-30 Creds Deducted for the session", preferredStyle: .alert)
                                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                                        self.present(alert, animated: true)
                                    }
                                }
                            }
                            // Present feedbackVC from CountdownVC so the Upload UI remains hidden beneath
                            countdownVC.present(feedbackVC, animated: true)
                        }
                        
                        // MARK: - Buffer End (within 2 minutes — session too short)
                        countdownVC.onBufferEndCall = { [weak self] elapsedSeconds in
                            print("⏱️ Buffer end at \(elapsedSeconds)s — session too short")
                            guard let self = self else { return }
                            
                            // Dismiss the CountdownVC (which also dismissed the VideoCallVC)
                            self.dismiss(animated: true) {
                                // Show reason picker
                                let reasonVC = BufferEndReasonViewController(doubtId: doubtId)
                                reasonVC.onReasonSelected = { [weak self] reason in
                                    guard let self = self else { return }
                                    print("📋 Buffer end reason: \(reason)")
                                    
                                    // Show brief info alert, then return to upload page
                                    let infoAlert = UIAlertController(
                                        title: "Session Ended Early",
                                        message: "The session ended within the free window. Your doubt remains active — we'll find another solver!",
                                        preferredStyle: .alert
                                    )
                                    infoAlert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                                        guard let self = self else { return }
                                        // Return to doubt upload page — doubt remains uploaded with spinner
                                        self.acceptedDoubt = nil
                                        self.solverAcceptedButton = nil
                                        
                                        // Reset doubt status to pending so another solver can pick it up
                                        Task {
                                            do {
                                                try await SupabaseManager.shared.resetDoubtToPending(doubtId: doubtId)
                                            } catch {
                                                print("Failed to reset doubt status:", error)
                                            }
                                        }
                                        
                                        // Show spinner again — doubt is still uploaded, waiting for solver
                                        self.showNavSpinner()
                                        self.startStatusPolling()
                                    })
                                    self.present(infoAlert, animated: true)
                                }
                                self.present(reasonVC, animated: true)
                            }
                        }
                        
                        self.present(countdownVC, animated: true)
                    }
                } catch {
                    print("Failed to start countdown:", error)
                    DispatchQueue.main.async {
                        let alert = UIAlertController(
                            title: "Error",
                            message: "Could not start the session. Please try again.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                }
            }
        }
        
        popup.onRemoveDoubt = { [weak self] in
            self?.handleRemoveDoubt()
        }
        
        popup.onLookForAnotherSolver = { [weak self] in
            self?.handleLookForAnotherSolver()
        }
        
        popup.onDismiss = {
            // Just dismissed, do nothing
        }
        
        // Show in the window so it overlays everything
        if let window = view.window {
            popup.show(in: window)
        }
    }
    
    @objc private func solverAcceptedTapped() {
        guard let doubt = acceptedDoubt else { return }
        showSolverPopup(doubt: doubt)
    }
    
    // MARK: - Decline Actions
    
    private func handleRemoveDoubt() {
        guard let doubtId = currentDoubtId else { return }
        
        Task {
            do {
                try await SupabaseManager.shared.deleteDoubt(doubtId: doubtId)
                DispatchQueue.main.async {
                    self.stopStatusPolling()
                    self.currentDoubtId = nil
                    self.acceptedDoubt = nil
                    self.solverAcceptedButton = nil
                    self.doubtUploadTime = nil
                    self.navigationItem.rightBarButtonItem = nil
                    self.hideActiveDoubtOverlay()
                }
            } catch {
                print("Failed to remove doubt:", error)
            }
        }
    }
    
    // MARK: - 15-Minute Timeout
    
    private func handleDoubtExpired(doubtId: UUID) {
        stopStatusPolling()
        
        Task {
            do {
                try await SupabaseManager.shared.deleteDoubt(doubtId: doubtId)
            } catch {
                print("Failed to delete expired doubt:", error)
            }
            
            DispatchQueue.main.async {
                self.currentDoubtId = nil
                self.acceptedDoubt = nil
                self.solverAcceptedButton = nil
                self.doubtUploadTime = nil
                self.navigationItem.rightBarButtonItem = nil
                self.hideActiveDoubtOverlay()
                
                let alert = UIAlertController(
                    title: "No Solver Found",
                    message: "We couldn't find a solver for your doubt within 15 minutes. Please try again after some time.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }
    }
    
    private func handleLookForAnotherSolver() {
        guard let doubtId = currentDoubtId else { return }
        
        Task {
            do {
                // Reset doubt status to pending so other solvers can pick it up
                try await SupabaseManager.shared.updateDoubtStatus(doubtId: doubtId, status: "pending")
                DispatchQueue.main.async {
                    self.acceptedDoubt = nil
                    self.solverAcceptedButton = nil
                    // Show spinner again while waiting for new solver
                    self.showNavSpinner()
                    // Restart polling
                    self.startStatusPolling()
                }
            } catch {
                print("Failed to reset doubt status:", error)
            }
        }
    }
    
    @objc private func spinnerTapped() {
        // If we're actively waiting for a solver, show a simple message
        if currentDoubtId != nil {
            let alert = UIAlertController(
                title: "Looking for a solver",
                message: "Please wait while we find a solver for your doubt. You'll be notified when a solver accepts.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            alert.addAction(UIAlertAction(title: "Cancel Doubt", style: .destructive) { [weak self] _ in
                self?.handleRemoveDoubt()
            })
            present(alert, animated: true)
            return
        }
        
        let vc = UploadedDoubtsViewController()
        vc.modalPresentationStyle = .popover

        vc.onAllDoubtsDeleted = { [weak self] in
            self?.uploadedDoubts.removeAll()
            self?.removeNavSpinnerIfNeeded()
        }

        guard let popover = vc.popoverPresentationController,
              let navBar = navigationController?.navigationBar else { return }

        popover.delegate = self
        popover.sourceView = navBar
        popover.sourceRect = CGRect(
            x: navBar.bounds.width - 28,
            y: navBar.bounds.height,
            width: 1,
            height: 1
        )
        popover.permittedArrowDirections = .up

        present(vc, animated: true)
    }

    private func resetForm() {
        selectedImages.removeAll()
        imageStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        imageScrollView.isHidden = true
        uploadCard.isHidden = false
        doubtTextView.text = ""
        subjectButton.setTitle("Select Subject", for: .normal)
        subjectButton.setTitleColor(.secondaryLabel, for: .normal)
        languageButton.setTitle("Select Language of Communication", for: .normal)
        languageButton.setTitleColor(.secondaryLabel, for: .normal)
        updateUploadButtonState()
    }

    private func hideTabBar() {
        tabBarController?.tabBar.isHidden = true
    }

    private func showTabBar() {
        tabBarController?.tabBar.isHidden = false
    }
    
    func removeNavSpinnerIfNeeded() {
        if uploadedDoubts.isEmpty {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    // MARK: - Keyboard Handling
    private func setupKeyboardHandling() {
        // Add toolbar with Done button
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.items = [flexSpace, doneButton]
        doubtTextView.inputAccessoryView = toolbar

        // Tap gesture to dismiss
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        // Observers for scroll view insets
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height + 20, right: 0.0)
            scrollView.contentInset = contentInsets
            scrollView.scrollIndicatorInsets = contentInsets
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        let contentInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }

    deinit {
        statusPollingTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Delegates
extension UploadDoubtViewController: UITextViewDelegate, PHPickerViewControllerDelegate {

    func textViewDidChange(_ textView: UITextView) {
        updateUploadButtonState()
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard !results.isEmpty else { return }

        selectedImages.removeAll()
        imageStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        uploadCard.isHidden = true
        imageScrollView.isHidden = false

        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                guard let self, let image = object as? UIImage else { return }
                DispatchQueue.main.async {
                    self.selectedImages.append(image)
                    let iv = UIImageView(image: image)
                    iv.contentMode = .scaleAspectFill
                    iv.clipsToBounds = true
                    iv.layer.cornerRadius = 12
                    iv.widthAnchor.constraint(equalToConstant: 110).isActive = true
                    self.imageStack.addArrangedSubview(iv)
                    self.updateUploadButtonState()
                }
            }
        }
    }
    
    private func hideNavigationBar() {
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    private func showNavigationBar() {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
}

extension UploadDoubtViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(
        for controller: UIPresentationController
    ) -> UIModalPresentationStyle {
        .none
    }
}