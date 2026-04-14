import UIKit

final class SolverOnboardingViewController: UIViewController {

    // MARK: - Data
    private struct Page {
        let image: String
        let text: String
        let button: String
    }

    private let pages: [Page] = [
        Page(
            image: "Solver Onboarding 1",
            text: "Confused about what to do\nnext in your career?",
            button: "NEXT"
        ),
        Page(
            image: "Solver Onboarding 2",
            text: "Solve doubts for JEE students\nlive, one-on-one sessions",
            button: "NEXT"
        ),
        Page(
            image: "Solver Onboarding 3",
            text: "Share your expertise\nand help students achieve their goals.",
            button: "START"
        )
    ]

    private var currentIndex = 0

    // MARK: - UI
    private let progressStack = UIStackView()
    private let contentContainer = UIView()

    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = UIColor(red: 0.85, green: 0.97, blue: 1.0, alpha: 1)

        
        navigationItem.hidesBackButton = true
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        setupProgress()
        setupButton()        // ⬅️ ADD BUTTON FIRST
        setupContent()       // ⬅️ THEN CONTENT
        updateUI(animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.layoutIfNeeded()   // 🔑 forces correct layout BEFORE display
    }

    // MARK: - Progress
    private func setupProgress() {
        progressStack.axis = .horizontal
        progressStack.spacing = 8
        progressStack.distribution = .fillEqually

        for _ in 0..<pages.count {
            let bar = UIView()
            bar.layer.cornerRadius = 3
            bar.backgroundColor = UIColor(white: 0.85, alpha: 1)
            bar.heightAnchor.constraint(equalToConstant: 6).isActive = true
            progressStack.addArrangedSubview(bar)
        }

        view.addSubview(progressStack)
        progressStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            progressStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100), // ⬇️ moved down
            progressStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressStack.widthAnchor.constraint(equalToConstant: 120)
        ])
    }
    
    private func applyLineLimit(for index: Int, label: UILabel) {
        if index == pages.count - 1 {
            label.numberOfLines = 2
            label.lineBreakMode = .byWordWrapping
        } else {
            label.numberOfLines = 0
        }
    }

    // MARK: - Button
    private func setupButton() {
        actionButton.backgroundColor = .black
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        actionButton.layer.cornerRadius = 26
        actionButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)

        view.addSubview(actionButton)
        actionButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -70),
            actionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            actionButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    // MARK: - Content
    private func setupContent() {
        view.addSubview(contentContainer)
        contentContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: progressStack.bottomAnchor, constant: 56), // ⬇️ more breathing space
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -160)
        ])

        imageView.contentMode = .scaleAspectFit

        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        contentContainer.addSubview(imageView)
        contentContainer.addSubview(titleLabel)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 50),
            imageView.heightAnchor.constraint(equalToConstant: 260),
            imageView.widthAnchor.constraint(equalTo: contentContainer.widthAnchor, multiplier: 0.8),

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 32),
            titleLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -32)
        ])
    }

    // MARK: - UI Update
    private func updateUI(animated: Bool) {
        let page = pages[currentIndex]

        // Progress bar
        for (i, bar) in progressStack.arrangedSubviews.enumerated() {
            bar.backgroundColor = i == currentIndex ? .black : UIColor(white: 0.85, alpha: 1)
        }

        actionButton.setTitle(page.button, for: .normal)

        guard animated else {
            imageView.image = UIImage(named: page.image)
            titleLabel.text = page.text
            applyLineLimit(for: currentIndex, label: titleLabel)
            return
        }

        let offset = view.bounds.width

        let newImage = UIImageView(image: UIImage(named: page.image))
        newImage.contentMode = .scaleAspectFit
        newImage.frame = imageView.frame
        newImage.transform = CGAffineTransform(translationX: offset, y: 0)

        let newLabel = UILabel(frame: titleLabel.frame)
        newLabel.text = page.text
        newLabel.font = titleLabel.font
        newLabel.textColor = .black
        newLabel.textAlignment = .center
        applyLineLimit(for: currentIndex, label: newLabel)
        newLabel.transform = CGAffineTransform(translationX: offset, y: 0)

        contentContainer.addSubview(newImage)
        contentContainer.addSubview(newLabel)

        UIView.animate(withDuration: 0.7, delay: 0, options: .curveEaseInOut) {
            self.imageView.transform = CGAffineTransform(translationX: -offset, y: 0)
            self.titleLabel.transform = CGAffineTransform(translationX: -offset, y: 0)

            newImage.transform = .identity
            newLabel.transform = .identity
        } completion: { _ in
            self.imageView.image = newImage.image
            self.titleLabel.text = newLabel.text

            self.imageView.transform = .identity
            self.titleLabel.transform = .identity

            newImage.removeFromSuperview()
            newLabel.removeFromSuperview()
        }
    }

    // MARK: - Actions
    @objc private func nextTapped() {
        if currentIndex < pages.count - 1 {
            currentIndex += 1
            updateUI(animated: true)
        } else {
            finishOnboarding()
        }
    }

    private func finishOnboarding() {

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }

        let tabBarController = MainTabBarController()
        let nav = SwipeableNavigationController(rootViewController: tabBarController)
        nav.navigationBar.isHidden = true

        UIView.transition(
            with: window,
            duration: 0.5,
            options: [.transitionCrossDissolve],
            animations: {
                window.rootViewController = nav
            }
        )
    }
}
