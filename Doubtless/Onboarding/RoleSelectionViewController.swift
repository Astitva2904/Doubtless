import UIKit

final class RoleSelectionViewController: UIViewController {

    // MARK: - App Colors
    let onboardingBG = UIColor(red: 0.98, green: 0.94, blue: 0.87, alpha: 1)
    let studentColor = UIColor.systemOrange
    let solverColor  = UIColor.systemBlue

    // MARK: - UI Components
    private let illustrationImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let studentCard = UIView()
    private let solverCard  = UIView()

    private let studentAvatarView = UIImageView()
    private let solverAvatarView  = UIImageView()

    private let studentNameLabel = UILabel()
    private let solverNameLabel  = UILabel()

    private let startButton = UIButton(type: .system)

    // MARK: - State
    private enum Role { case student, solver }
    private var selectedRole: Role?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = onboardingBG

        setupIllustration()
        setupText()
        setupRoleCards()
        setupStartButton()
    }

    // MARK: - Illustration (transparent bg, blends directly)
    private func setupIllustration() {
        illustrationImageView.image = UIImage(named: "RoleIllustration")
        illustrationImageView.contentMode = .scaleAspectFit
        illustrationImageView.backgroundColor = .clear

        view.addSubview(illustrationImageView)
        illustrationImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            illustrationImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            illustrationImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            illustrationImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            illustrationImageView.heightAnchor.constraint(equalToConstant: 230)
        ])
    }

    // MARK: - Text
    private func setupText() {
        titleLabel.text = "Choose your role"
        titleLabel.font = .systemFont(ofSize: 32, weight: .black)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .black

        let sub = NSMutableAttributedString(
            string: "Select ", attributes: [.font: UIFont.systemFont(ofSize: 16), .foregroundColor: UIColor.darkGray]
        )
        sub.append(NSAttributedString(string: "Student", attributes: [.font: UIFont.systemFont(ofSize: 16, weight: .bold), .foregroundColor: UIColor.black]))
        sub.append(NSAttributedString(string: " if you want to learn\nor ", attributes: [.font: UIFont.systemFont(ofSize: 16), .foregroundColor: UIColor.darkGray]))
        sub.append(NSAttributedString(string: "Solver", attributes: [.font: UIFont.systemFont(ofSize: 16, weight: .bold), .foregroundColor: UIColor.black]))
        sub.append(NSAttributedString(string: " if you want to teach", attributes: [.font: UIFont.systemFont(ofSize: 16), .foregroundColor: UIColor.darkGray]))

        subtitleLabel.attributedText = sub
        subtitleLabel.numberOfLines = 2
        subtitleLabel.textAlignment = .center

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: illustrationImageView.bottomAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    // MARK: - Role Cards with Face Cutouts
    private func setupRoleCards() {
        // Configure each card
        configureCard(studentCard, avatar: studentAvatarView, nameLabel: studentNameLabel,
                      imageName: "StudentAvatar", title: "Student",
                      bgColor: studentColor.withAlphaComponent(0.12))

        configureCard(solverCard, avatar: solverAvatarView, nameLabel: solverNameLabel,
                      imageName: "SolverAvatar", title: "Solver",
                      bgColor: solverColor.withAlphaComponent(0.12))

        // Tap gestures
        let studentTap = UITapGestureRecognizer(target: self, action: #selector(studentTapped))
        studentCard.addGestureRecognizer(studentTap)

        let solverTap = UITapGestureRecognizer(target: self, action: #selector(solverTapped))
        solverCard.addGestureRecognizer(solverTap)

        let hStack = UIStackView(arrangedSubviews: [studentCard, solverCard])
        hStack.axis = .horizontal
        hStack.spacing = 20
        hStack.distribution = .fillEqually

        view.addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 30),
            hStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hStack.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            hStack.heightAnchor.constraint(equalToConstant: 155)
        ])
    }

    private func configureCard(_ card: UIView, avatar: UIImageView, nameLabel: UILabel,
                               imageName: String, title: String, bgColor: UIColor) {
        card.backgroundColor = bgColor
        card.layer.cornerRadius = 20
        card.layer.borderWidth = 2.5
        card.layer.borderColor = UIColor.clear.cgColor
        card.clipsToBounds = true
        card.isUserInteractionEnabled = true

        // Circular avatar with the face cutout
        avatar.image = UIImage(named: imageName)
        avatar.contentMode = .scaleAspectFill
        avatar.layer.cornerRadius = 35
        avatar.clipsToBounds = true
        avatar.isUserInteractionEnabled = false

        nameLabel.text = title
        nameLabel.font = .systemFont(ofSize: 18, weight: .bold)
        nameLabel.textColor = .black
        nameLabel.textAlignment = .center
        nameLabel.isUserInteractionEnabled = false

        card.addSubview(avatar)
        card.addSubview(nameLabel)

        avatar.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            avatar.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            avatar.topAnchor.constraint(equalTo: card.topAnchor, constant: 22),
            avatar.widthAnchor.constraint(equalToConstant: 70),
            avatar.heightAnchor.constraint(equalToConstant: 70),

            nameLabel.topAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 12),
            nameLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor)
        ])
    }

    // MARK: - Start Button
    private func setupStartButton() {
        startButton.setTitle("Get started", for: .normal)
        startButton.setTitleColor(.white, for: .normal)
        startButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        startButton.backgroundColor = UIColor.systemTeal
        startButton.layer.cornerRadius = 28
        startButton.isEnabled = false
        startButton.alpha = 0.4

        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)

        view.addSubview(startButton)
        startButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            startButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            startButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    // MARK: - Actions
    @objc private func studentTapped() {
        selectedRole = .student
        updateSelectionUI()
    }

    @objc private func solverTapped() {
        selectedRole = .solver
        updateSelectionUI()
    }

    private func updateSelectionUI() {
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            // Reset both cards
            self.studentCard.layer.borderColor = UIColor.clear.cgColor
            self.studentCard.transform = .identity
            self.studentCard.alpha = 0.65

            self.solverCard.layer.borderColor = UIColor.clear.cgColor
            self.solverCard.transform = .identity
            self.solverCard.alpha = 0.65

            if let role = self.selectedRole {
                self.startButton.isEnabled = true
                self.startButton.alpha = 1.0

                switch role {
                case .student:
                    self.studentCard.layer.borderColor = self.studentColor.cgColor
                    self.studentCard.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                    self.studentCard.alpha = 1.0
                    self.startButton.backgroundColor = self.studentColor
                case .solver:
                    self.solverCard.layer.borderColor = self.solverColor.cgColor
                    self.solverCard.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                    self.solverCard.alpha = 1.0
                    self.startButton.backgroundColor = self.solverColor
                }
            }
        }
    }

    @objc private func startTapped() {
        guard let role = selectedRole else { return }

        // Bounce animation
        UIView.animate(withDuration: 0.1, animations: {
            self.startButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.startButton.transform = .identity
            }
        }

        switch role {
        case .student:
            UserDefaults.standard.set("student", forKey: "selectedRole")
            navigationController?.pushViewController(StudentWelcomeViewController(), animated: true)
        case .solver:
            UserDefaults.standard.set("solver", forKey: "selectedRole")
            navigationController?.pushViewController(SolverWelcomeViewController(), animated: true)
        }
    }
}
