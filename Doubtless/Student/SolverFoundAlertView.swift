import UIKit

final class SolverFoundAlertView: UIView {
    
    // MARK: - Callbacks
    var onAccept: (() -> Void)?
    var onDecline: (() -> Void)?
    
    // MARK: - UI Elements
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let instituteLabel = UILabel()
    
    private let declineButton = UIButton(type: .system)
    private let startButton = UIButton(type: .system)
    
    // MARK: - Initialization
    init(solverName: String, solverInstitute: String, solverImage: String) {
        super.init(frame: .zero)
        setupUI()
        nameLabel.text = solverName
        instituteLabel.text = solverInstitute
        profileImageView.image = UIImage(named: solverImage) ?? UIImage(systemName: "person.circle.fill")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.4)
        alpha = 0
        
        cardView.backgroundColor = UIColor(red: 254/255, green: 234/255, blue: 162/255, alpha: 1.0)
        cardView.layer.cornerRadius = 24
        
        titleLabel.text = "Solver"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 35 // 70x70
        profileImageView.tintColor = .systemGray
        
        nameLabel.font = .systemFont(ofSize: 24, weight: .bold)
        nameLabel.textColor = .black
        
        instituteLabel.font = .systemFont(ofSize: 18, weight: .regular)
        instituteLabel.textColor = .darkGray
        
        // Buttons
        var declineConfig = UIButton.Configuration.filled()
        declineConfig.baseBackgroundColor = .systemRed
        declineConfig.baseForegroundColor = .white
        declineConfig.image = UIImage(systemName: "xmark")
        declineConfig.imagePadding = 6
        declineConfig.title = "Decline"
        declineConfig.cornerStyle = .capsule
        declineButton.configuration = declineConfig
        declineButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        declineButton.addTarget(self, action: #selector(declineTapped), for: .touchUpInside)
        
        var startConfig = UIButton.Configuration.filled()
        startConfig.baseBackgroundColor = .systemGreen
        startConfig.baseForegroundColor = .white
        startConfig.image = UIImage(systemName: "video")
        startConfig.imagePadding = 6
        startConfig.title = "Start"
        startConfig.cornerStyle = .capsule
        startButton.configuration = startConfig
        startButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)
        
        let buttonStack = UIStackView(arrangedSubviews: [declineButton, startButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 16
        buttonStack.distribution = .fillEqually
        
        // Layout
        addSubview(cardView)
        [titleLabel, profileImageView, nameLabel, instituteLabel, buttonStack].forEach {
            cardView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cardView.centerXAnchor.constraint(equalTo: centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: centerYAnchor),
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            
            profileImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            profileImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            profileImageView.widthAnchor.constraint(equalToConstant: 70),
            profileImageView.heightAnchor.constraint(equalToConstant: 70),
            
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            nameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor, constant: 4),
            
            instituteLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            instituteLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            instituteLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            
            buttonStack.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 24),
            buttonStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            buttonStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            buttonStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -24),
            buttonStack.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Actions
    @objc private func startTapped() {
        onAccept?()
    }
    
    @objc private func declineTapped() {
        onDecline?()
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
