import UIKit

/// Presented when the student ends the call within the 2-minute buffer.
/// Shows three reason options in the center of the screen.
final class BufferEndReasonViewController: UIViewController {
    
    /// Called with the selected reason string after the student taps an option.
    var onReasonSelected: ((_ reason: String) -> Void)?
    
    private let doubtId: UUID
    
    // MARK: - UI
    
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 20
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.15
        v.layer.shadowRadius = 20
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
        return v
    }()
    
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Why are you ending\nthe session?"
        lbl.font = .systemFont(ofSize: 22, weight: .bold)
        lbl.textColor = .label
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        return lbl
    }()
    
    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "This helps us improve the experience"
        lbl.font = .systemFont(ofSize: 14)
        lbl.textColor = .secondaryLabel
        lbl.textAlignment = .center
        return lbl
    }()
    
    // MARK: - Init
    
    init(doubtId: UUID) {
        self.doubtId = doubtId
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Animate container in
        containerView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        containerView.alpha = 0
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.containerView.transform = .identity
            self.containerView.alpha = 1
        }
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
        
        // Stack
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 28),
            stack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24)
        ])
        
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(subtitleLabel)
        stack.setCustomSpacing(24, after: subtitleLabel)
        
        // Reason buttons
        let reasons = [
            "Poor connection / Technical Issue",
            "Solver not able to help",
            "Other"
        ]
        
        for reason in reasons {
            let btn = makeReasonButton(title: reason)
            stack.addArrangedSubview(btn)
        }
    }
    
    private func makeReasonButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = .secondarySystemBackground
        config.baseForegroundColor = .label
        config.cornerStyle = .large
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            return outgoing
        }
        btn.configuration = config
        btn.contentHorizontalAlignment = .leading
        
        // Add chevron
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .tertiaryLabel
        chevron.translatesAutoresizingMaskIntoConstraints = false
        btn.addSubview(chevron)
        NSLayoutConstraint.activate([
            chevron.trailingAnchor.constraint(equalTo: btn.trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: btn.centerYAnchor)
        ])
        
        btn.heightAnchor.constraint(equalToConstant: 56).isActive = true
        btn.addAction(UIAction { [weak self] _ in
            self?.reasonSelected(title)
        }, for: .touchUpInside)
        
        return btn
    }
    
    private func reasonSelected(_ reason: String) {
        // Haptic
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Animate out
        UIView.animate(withDuration: 0.25, animations: {
            self.containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self.containerView.alpha = 0
            self.view.backgroundColor = .clear
        }) { _ in
            self.dismiss(animated: false) {
                self.onReasonSelected?(reason)
            }
        }
    }
}
