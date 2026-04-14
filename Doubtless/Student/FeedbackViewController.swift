import UIKit

final class FeedbackViewController: UIViewController {

    private let doubtId: UUID
    private let solverName: String
    
    var onSubmitted: (() -> Void)?
    
    // Haptics
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    
    // UI Elements
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    // Rating
    private var ratingButtons: [UIButton] = []
    private var selectedRating: Int = 0
    private let ratingDescLabel = UILabel()
    
    // Resolved Segment
    private let resolvedSegment = UISegmentedControl(items: ["Yes", "No"])
    private var isResolved: String = "Yes"
    
    // Technical Issue Menu
    private let issueButton = UIButton(type: .system)
    private var technicalIssue: String = "No issues"
    
    // Comments
    private let commentsTextView = UITextView()
    private let commentsPlaceholder = UILabel()
    
    // Submit
    private let submitButton = UIButton(type: .system)
    
    // Rating descriptions
    private let ratingDescriptions = ["", "Poor", "Fair", "Good", "Great", "Excellent"]
    
    init(doubtId: UUID, solverName: String) {
        self.doubtId = doubtId
        self.solverName = solverName
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .coverVertical
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupMenus()
        
        // Dismiss keyboard on tap
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // ScrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        
        // Content stack
        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -30),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
        
        setupHeader()
        setupRatingCard()
        setupQuestionsCard()
        setupCommentsCard()
        setupSubmitButton()
        
        impactFeedback.prepare()
        selectionFeedback.prepare()
    }
    
    // MARK: - Header
    
    private func setupHeader() {
        let headerStack = UIStackView()
        headerStack.axis = .vertical
        headerStack.spacing = 6
        headerStack.alignment = .center
        
        // Checkmark icon
        let checkContainer = UIView()
        checkContainer.translatesAutoresizingMaskIntoConstraints = false
        checkContainer.backgroundColor = .systemGreen.withAlphaComponent(0.15)
        checkContainer.layer.cornerRadius = 28
        
        let checkIcon = UIImageView()
        let checkConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
        checkIcon.image = UIImage(systemName: "checkmark", withConfiguration: checkConfig)
        checkIcon.tintColor = .systemGreen
        checkIcon.translatesAutoresizingMaskIntoConstraints = false
        checkContainer.addSubview(checkIcon)
        
        NSLayoutConstraint.activate([
            checkContainer.widthAnchor.constraint(equalToConstant: 56),
            checkContainer.heightAnchor.constraint(equalToConstant: 56),
            checkIcon.centerXAnchor.constraint(equalTo: checkContainer.centerXAnchor),
            checkIcon.centerYAnchor.constraint(equalTo: checkContainer.centerYAnchor)
        ])
        
        let titleLabel = UILabel()
        titleLabel.text = "Session Complete"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "How was your experience with \(solverName)?"
        subtitleLabel.font = .systemFont(ofSize: 15)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        
        headerStack.addArrangedSubview(checkContainer)
        headerStack.setCustomSpacing(14, after: checkContainer)
        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(subtitleLabel)
        
        contentStack.addArrangedSubview(headerStack)
    }
    
    // MARK: - Rating Card
    
    private func setupRatingCard() {
        let card = makeCard()
        let innerStack = UIStackView()
        innerStack.axis = .vertical
        innerStack.spacing = 12
        innerStack.alignment = .center
        innerStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(innerStack)
        pinToCard(innerStack, in: card)
        
        // Section label
        let sectionLabel = UILabel()
        sectionLabel.text = "Rate this session"
        sectionLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        sectionLabel.textColor = .secondaryLabel
        sectionLabel.textAlignment = .center
        innerStack.addArrangedSubview(sectionLabel)
        
        // Stars row
        let starsStack = UIStackView()
        starsStack.axis = .horizontal
        starsStack.spacing = 8
        starsStack.alignment = .center
        starsStack.distribution = .equalSpacing
        
        for i in 1...5 {
            let btn = UIButton(type: .system)
            btn.tag = i
            let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .regular)
            btn.setImage(UIImage(systemName: "star", withConfiguration: config), for: .normal)
            btn.tintColor = .systemGray4
            btn.addTarget(self, action: #selector(starTapped(_:)), for: .touchUpInside)
            
            // Fixed size to prevent compression
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.widthAnchor.constraint(equalToConstant: 44).isActive = true
            btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
            
            ratingButtons.append(btn)
            starsStack.addArrangedSubview(btn)
        }
        
        innerStack.addArrangedSubview(starsStack)
        
        // Rating description
        ratingDescLabel.text = "Tap a star to rate"
        ratingDescLabel.font = .systemFont(ofSize: 13)
        ratingDescLabel.textColor = .tertiaryLabel
        ratingDescLabel.textAlignment = .center
        innerStack.addArrangedSubview(ratingDescLabel)
        
        contentStack.addArrangedSubview(card)
    }
    
    // MARK: - Questions Card
    
    private func setupQuestionsCard() {
        let card = makeCard()
        let innerStack = UIStackView()
        innerStack.axis = .vertical
        innerStack.spacing = 20
        innerStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(innerStack)
        pinToCard(innerStack, in: card)
        
        // --- Resolved Question ---
        let resolvedWrapper = UIStackView()
        resolvedWrapper.axis = .vertical
        resolvedWrapper.spacing = 10
        
        let resolvedLabel = UILabel()
        resolvedLabel.text = "Did this session resolve your doubt?"
        resolvedLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        resolvedLabel.textColor = .label
        resolvedLabel.numberOfLines = 0
        
        resolvedSegment.selectedSegmentIndex = 0
        resolvedSegment.selectedSegmentTintColor = .systemOrange
        let normalAttr: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.label]
        let selectedAttr: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.white]
        resolvedSegment.setTitleTextAttributes(normalAttr, for: .normal)
        resolvedSegment.setTitleTextAttributes(selectedAttr, for: .selected)
        resolvedSegment.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        
        resolvedWrapper.addArrangedSubview(resolvedLabel)
        resolvedWrapper.addArrangedSubview(resolvedSegment)
        innerStack.addArrangedSubview(resolvedWrapper)
        
        // Thin divider
        innerStack.addArrangedSubview(makeThinDivider())
        
        // --- Technical Issues Question ---
        let issueWrapper = UIStackView()
        issueWrapper.axis = .vertical
        issueWrapper.spacing = 10
        
        let issueLabel = UILabel()
        issueLabel.text = "Were there any technical issues?"
        issueLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        issueLabel.textColor = .label
        issueLabel.numberOfLines = 0
        
        setupModernMenuButton(issueButton, title: technicalIssue)
        
        issueWrapper.addArrangedSubview(issueLabel)
        issueWrapper.addArrangedSubview(issueButton)
        innerStack.addArrangedSubview(issueWrapper)
        
        contentStack.addArrangedSubview(card)
    }
    
    // MARK: - Comments Card
    
    private func setupCommentsCard() {
        let card = makeCard()
        let innerStack = UIStackView()
        innerStack.axis = .vertical
        innerStack.spacing = 10
        innerStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(innerStack)
        pinToCard(innerStack, in: card)
        
        let commentsLabel = UILabel()
        commentsLabel.text = "Additional Feedback"
        commentsLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        commentsLabel.textColor = .label
        
        let optionalBadge = UILabel()
        optionalBadge.text = "Optional"
        optionalBadge.font = .systemFont(ofSize: 11, weight: .medium)
        optionalBadge.textColor = .secondaryLabel
        optionalBadge.backgroundColor = .systemGray5
        optionalBadge.layer.cornerRadius = 4
        optionalBadge.clipsToBounds = true
        optionalBadge.textAlignment = .center
        optionalBadge.translatesAutoresizingMaskIntoConstraints = false
        optionalBadge.widthAnchor.constraint(equalToConstant: 56).isActive = true
        optionalBadge.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        let labelRow = UIStackView(arrangedSubviews: [commentsLabel, optionalBadge])
        labelRow.axis = .horizontal
        labelRow.alignment = .center
        labelRow.spacing = 8
        
        commentsTextView.backgroundColor = .secondarySystemFill
        commentsTextView.layer.cornerRadius = 10
        commentsTextView.font = .systemFont(ofSize: 15)
        commentsTextView.textColor = .label
        commentsTextView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        commentsTextView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        commentsTextView.delegate = self
        
        commentsPlaceholder.text = "What went well or could be improved..."
        commentsPlaceholder.textColor = .tertiaryLabel
        commentsPlaceholder.font = .systemFont(ofSize: 15)
        commentsPlaceholder.numberOfLines = 0
        commentsPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        commentsTextView.addSubview(commentsPlaceholder)
        
        NSLayoutConstraint.activate([
            commentsPlaceholder.topAnchor.constraint(equalTo: commentsTextView.topAnchor, constant: 12),
            commentsPlaceholder.leadingAnchor.constraint(equalTo: commentsTextView.leadingAnchor, constant: 16),
            commentsPlaceholder.trailingAnchor.constraint(equalTo: commentsTextView.trailingAnchor, constant: -16)
        ])
        
        innerStack.addArrangedSubview(labelRow)
        innerStack.addArrangedSubview(commentsTextView)
        
        contentStack.addArrangedSubview(card)
    }
    
    // MARK: - Submit Button
    
    private func setupSubmitButton() {
        var submitConfig = UIButton.Configuration.filled()
        submitConfig.title = "Submit Feedback"
        submitConfig.baseBackgroundColor = .systemOrange
        submitConfig.baseForegroundColor = .white
        submitConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 17, weight: .bold)
            return outgoing
        }
        submitConfig.cornerStyle = .capsule
        submitButton.configuration = submitConfig
        submitButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        
        // Subtle shadow
        submitButton.layer.shadowColor = UIColor.systemOrange.cgColor
        submitButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        submitButton.layer.shadowRadius = 8
        submitButton.layer.shadowOpacity = 0.25
        
        contentStack.addArrangedSubview(submitButton)
    }
    
    // MARK: - Card Factory
    
    private func makeCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 0.5
        card.layer.borderColor = UIColor.separator.cgColor
        return card
    }
    
    private func pinToCard(_ view: UIView, in card: UIView) {
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            view.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            view.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            view.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
    }
    
    private func makeThinDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = .separator
        divider.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return divider
    }
    
    private func setupModernMenuButton(_ button: UIButton, title: String) {
        var config = UIButton.Configuration.tinted()
        config.title = title
        config.baseForegroundColor = .label
        config.baseBackgroundColor = .systemGray5
        config.image = UIImage(systemName: "chevron.up.chevron.down")
        config.imagePlacement = .trailing
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 11, weight: .medium)
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = UIFont.systemFont(ofSize: 15)
            return out
        }
        
        button.configuration = config
        button.contentHorizontalAlignment = .fill
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
    }
    
    private func setupMenus() {
        let updateTitle: (String) -> Void = { [weak self] newValue in
            self?.technicalIssue = newValue
            var updatedConfig = self?.issueButton.configuration
            updatedConfig?.title = newValue
            self?.issueButton.configuration = updatedConfig
        }
        
        issueButton.menu = UIMenu(children: [
            UIAction(title: "No issues", handler: { _ in updateTitle("No issues") }),
            UIAction(title: "Microphone/Camera not working", handler: { _ in updateTitle("Microphone/Camera not working") }),
            UIAction(title: "Text not visible", handler: { _ in updateTitle("Text not visible") }),
            UIAction(title: "Other connection problems", handler: { _ in updateTitle("Other connection problems") })
        ])
        issueButton.showsMenuAsPrimaryAction = true
    }
    
    // MARK: - Actions
    
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        selectionFeedback.selectionChanged()
        isResolved = sender.selectedSegmentIndex == 0 ? "Yes" : "No"
    }
    
    @objc private func starTapped(_ sender: UIButton) {
        impactFeedback.impactOccurred()
        setRating(sender.tag)
    }
    
    private func setRating(_ rating: Int) {
        selectedRating = rating
        
        let configFilled = UIImage.SymbolConfiguration(pointSize: 32, weight: .regular)
        let configEmpty = UIImage.SymbolConfiguration(pointSize: 32, weight: .regular)
        
        for (i, btn) in ratingButtons.enumerated() {
            let isFilled = i < rating
            
            UIView.transition(with: btn, duration: 0.2, options: .transitionCrossDissolve, animations: {
                if isFilled {
                    btn.setImage(UIImage(systemName: "star.fill", withConfiguration: configFilled), for: .normal)
                    btn.tintColor = .systemYellow
                    btn.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
                } else {
                    btn.setImage(UIImage(systemName: "star", withConfiguration: configEmpty), for: .normal)
                    btn.tintColor = .systemGray4
                    btn.transform = .identity
                }
            }) { _ in
                UIView.animate(withDuration: 0.1) {
                    btn.transform = .identity
                }
            }
        }
        
        // Update description
        UIView.transition(with: ratingDescLabel, duration: 0.2, options: .transitionCrossDissolve) {
            self.ratingDescLabel.text = self.ratingDescriptions[rating]
            self.ratingDescLabel.textColor = .systemYellow
        }
    }
    
    @objc private func submitTapped() {
        if selectedRating == 0 {
            let alert = UIAlertController(title: "Rating Required", message: "Please rate the session before submitting.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let comments = commentsTextView.text ?? ""
        
        submitButton.isEnabled = false
        submitButton.configuration?.showsActivityIndicator = true
        
        Task {
            do {
                try await SupabaseManager.shared.submitFeedback(
                    doubtId: doubtId,
                    solverName: solverName,
                    rating: selectedRating,
                    resolved: isResolved,
                    technicalIssue: technicalIssue,
                    comments: comments
                )
                
                DispatchQueue.main.async {
                    self.dismiss(animated: true) {
                        self.onSubmitted?()
                    }
                }
            } catch {
                print("Error saving feedback:", error)
                DispatchQueue.main.async {
                    self.submitButton.isEnabled = true
                    self.submitButton.configuration?.showsActivityIndicator = false
                    let alert = UIAlertController(title: "Error", message: "Failed to submit feedback.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}

// MARK: - UITextViewDelegate
extension FeedbackViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        commentsPlaceholder.isHidden = !textView.text.isEmpty
    }
}
