import UIKit

/// A circular button showing the solver's profile picture with a green tick overlay.
/// Replaces the SpinnerButton when a solver accepts a doubt.
final class SolverAcceptedButton: UIButton {
    
    private let profileImageView = UIImageView()
    private let tickBadge = UIImageView()
    
    private(set) var solverName: String = ""
    private(set) var solverInstitute: String = ""
    private(set) var solverImageURL: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        // Button size
        let size: CGFloat = 36
        frame = CGRect(x: 0, y: 0, width: size, height: size)
        
        // Profile image (circular)
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = size / 2
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.systemGreen.cgColor
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .systemGray3
        profileImageView.isUserInteractionEnabled = false
        
        addSubview(profileImageView)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: topAnchor),
            profileImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            profileImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            profileImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: size),
            profileImageView.heightAnchor.constraint(equalToConstant: size)
        ])
        
        // Green tick badge (bottom-right)
        let tickSize: CGFloat = 16
        tickBadge.image = UIImage(systemName: "checkmark.circle.fill")
        tickBadge.tintColor = .systemGreen
        tickBadge.backgroundColor = .white
        tickBadge.layer.cornerRadius = tickSize / 2
        tickBadge.clipsToBounds = true
        tickBadge.isUserInteractionEnabled = false
        
        addSubview(tickBadge)
        tickBadge.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tickBadge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 2),
            tickBadge.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 2),
            tickBadge.widthAnchor.constraint(equalToConstant: tickSize),
            tickBadge.heightAnchor.constraint(equalToConstant: tickSize)
        ])
    }
    
    func configure(name: String, institute: String, imageURL: String?) {
        self.solverName = name
        self.solverInstitute = institute
        self.solverImageURL = imageURL
        
        // Load profile image
        if let urlStr = imageURL, let url = URL(string: urlStr) {
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.profileImageView.image = image
                        }
                    }
                } catch {
                    print("Failed to load solver image:", error)
                }
            }
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = .systemOrange
        }
    }
    
    /// Animate the appearance with a pop effect
    func animateAppearance() {
        transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        alpha = 0
        
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.8,
            options: .curveEaseOut
        ) {
            self.transform = .identity
            self.alpha = 1
        }
    }
}
