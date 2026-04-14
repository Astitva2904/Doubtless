import UIKit

final class SolverWelcomeViewController: UIViewController {

    // MARK: - UI
    private let titleLabel = UILabel()
    private let cloudLeft = UIImageView()
    private let cloudRight = UIImageView()
    private let bottomImageView = UIImageView()

    private let createButton = UIButton(type: .system)
    private let loginButton = UIButton(type: .system)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = UIColor(red: 0.90, green: 0.97, blue: 1.0, alpha: 1)

        setupTitle()
        setupClouds()
        setupButtons()
        setupBottomImage()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateClouds()
    }

    // MARK: - Title
    private func setupTitle() {
        titleLabel.text = "Welcome To\nDoubtless!"
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .left

        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24)
        ])
    }

    // MARK: - Clouds
    private func setupClouds() {
        cloudLeft.image = UIImage(named: "clouds")
        cloudRight.image = UIImage(named: "clouds")

        cloudLeft.contentMode = .scaleAspectFit
        cloudRight.contentMode = .scaleAspectFit

        view.addSubview(cloudLeft)
        view.addSubview(cloudRight)

        cloudLeft.translatesAutoresizingMaskIntoConstraints = false
        cloudRight.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            cloudLeft.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -420),
            cloudLeft.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: -80),
            cloudLeft.widthAnchor.constraint(equalToConstant: 840),
            cloudLeft.heightAnchor.constraint(equalToConstant: 480),

            cloudRight.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 420),
            cloudRight.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            cloudRight.widthAnchor.constraint(equalToConstant: 840),
            cloudRight.heightAnchor.constraint(equalToConstant: 480)
        ])

        // Initial offscreen positions
        cloudLeft.transform = CGAffineTransform(translationX: -view.bounds.width, y: 0)
        cloudRight.transform = CGAffineTransform(translationX: view.bounds.width, y: 0)
    }

    private func animateClouds() {
        UIView.animate(
            withDuration: 1.2,
            delay: 0.15,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0.6,
            options: [.curveEaseInOut],
            animations: {
                self.cloudLeft.transform = .identity
                self.cloudRight.transform = .identity
            }
        )
    }

    // MARK: - Buttons
    private func setupButtons() {

        // Create Account Button
        createButton.setTitle("Create a Solver Account", for: .normal)
        createButton.setTitleColor(.white, for: .normal)
        createButton.backgroundColor = .black
        createButton.layer.cornerRadius = 14
        createButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)

        // Login Button (Attributed)
        let text = "Already have an account? Login"
        let attr = NSMutableAttributedString(string: text)

        attr.addAttributes([
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.gray
        ], range: NSRange(location: 0, length: text.count))

        if let range = text.range(of: "Login") {
            let nsRange = NSRange(range, in: text)
            attr.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: nsRange)
            attr.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 14), range: nsRange)
        }

        loginButton.setAttributedTitle(attr, for: .normal)
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)

        [createButton, loginButton].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            createButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            createButton.bottomAnchor.constraint(equalTo: loginButton.topAnchor, constant: -12),
            createButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            createButton.heightAnchor.constraint(equalToConstant: 50),

            loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    // MARK: - Actions
    @objc private func createTapped() {
        let vc = CreateSolverAccountViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func loginTapped() {
        let vc = SolverLoginViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Bottom Image
    private func setupBottomImage() {
        bottomImageView.image = UIImage(named: "No Booked Sessions Image")
        bottomImageView.contentMode = .scaleAspectFit

        view.addSubview(bottomImageView)
        bottomImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            bottomImageView.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 5),
            bottomImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottomImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.95),
            bottomImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.28),
            bottomImageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -1)
        ])
    }
}
