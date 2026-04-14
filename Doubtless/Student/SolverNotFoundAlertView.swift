import UIKit

final class SolverNotFoundAlertView: UIView {
    
    // MARK: - Callbacks
    var onDismiss: (() -> Void)?
    
    // MARK: - UI Elements
    private let cardView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let dismissButton = UIButton(type: .system)
    
    // MARK: - Initialization
    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.4)
        alpha = 0
        
        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = 24
        
        iconImageView.image = UIImage(systemName: "clock.badge.exclamationmark")
        iconImageView.tintColor = .systemRed
        iconImageView.contentMode = .scaleAspectFit
        
        titleLabel.text = "Timeout"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = .center
        
        subtitleLabel.text = "Try again after sometime..."
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        
        var dsConfig = UIButton.Configuration.filled()
        dsConfig.baseBackgroundColor = .systemGray5
        dsConfig.baseForegroundColor = .label
        dsConfig.title = "Okay"
        dsConfig.cornerStyle = .capsule
        dismissButton.configuration = dsConfig
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        
        addSubview(cardView)
        [iconImageView, titleLabel, subtitleLabel, dismissButton].forEach {
            cardView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cardView.centerXAnchor.constraint(equalTo: centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: centerYAnchor),
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
            
            iconImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 32),
            iconImageView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 60),
            iconImageView.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            dismissButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            dismissButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            dismissButton.widthAnchor.constraint(equalToConstant: 120),
            dismissButton.heightAnchor.constraint(equalToConstant: 44),
            dismissButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -24),
        ])
    }
    
    @objc private func dismissTapped() {
        onDismiss?()
    }
    
    // MARK: - Animations
    func show(in view: UIView) {
        frame = view.bounds
        view.addSubview(self)
        
        cardView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.alpha = 1
            self.cardView.transform = .identity
        }
    }
    
    func hide(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0
            self.cardView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            self.removeFromSuperview()
            completion?()
        }
    }
}
