import UIKit

final class ForgotPasswordViewController: UIViewController {

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stack = UIStackView()

    private let emailField = UITextField()
    private let sendCodeButton = UIButton(type: .system)

    var flowBackgroundColor: UIColor?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = flowBackgroundColor ?? UIColor(red: 0.98, green: 0.94, blue: 0.87, alpha: 1)
        title = "Forgot Password"

        setupScroll()
        setupStack()
        setupUI()

        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
    }

    // MARK: - Scroll
    private func setupScroll() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        let minHeight = contentView.heightAnchor.constraint(
            greaterThanOrEqualTo: scrollView.safeAreaLayoutGuide.heightAnchor
        )
        minHeight.priority = .defaultHigh

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            minHeight
        ])
    }

    // MARK: - Stack
    private func setupStack() {
        stack.axis = .vertical
        stack.spacing = 24
        contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24)
        ])
    }

    // MARK: - UI Setup
    private func setupUI() {
        // Icon
        let lockIcon = UIImageView(image: UIImage(systemName: "lock.rotation"))
        lockIcon.tintColor = .black
        lockIcon.contentMode = .scaleAspectFit
        lockIcon.translatesAutoresizingMaskIntoConstraints = false
        lockIcon.heightAnchor.constraint(equalToConstant: 80).isActive = true
        stack.addArrangedSubview(lockIcon)

        // Title
        let title = UILabel()
        title.text = "Forgot Password?"
        title.font = .boldSystemFont(ofSize: 28)
        title.textAlignment = .center
        stack.addArrangedSubview(title)

        // Subtitle
        let subtitle = UILabel()
        subtitle.text = "Enter your registered email address and we'll send you a 4-digit verification code to reset your password."
        subtitle.font = .systemFont(ofSize: 15)
        subtitle.textColor = .darkGray
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0
        stack.addArrangedSubview(subtitle)
        stack.setCustomSpacing(32, after: subtitle)

        // Email label
        let emailLabel = UILabel()
        emailLabel.text = "Email"
        emailLabel.font = .boldSystemFont(ofSize: 16)

        emailField.borderStyle = .roundedRect
        emailField.autocapitalizationType = .none
        emailField.keyboardType = .emailAddress
        emailField.placeholder = "you@example.com"
        emailField.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let emailStack = UIStackView(arrangedSubviews: [emailLabel, emailField])
        emailStack.axis = .vertical
        emailStack.spacing = 8
        stack.addArrangedSubview(emailStack)

        // Send Code button
        sendCodeButton.setTitle("Send Verification Code", for: .normal)
        sendCodeButton.backgroundColor = .black
        sendCodeButton.setTitleColor(.white, for: .normal)
        sendCodeButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        sendCodeButton.layer.cornerRadius = 28
        sendCodeButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        sendCodeButton.addTarget(self, action: #selector(sendCodeTapped), for: .touchUpInside)
        stack.addArrangedSubview(sendCodeButton)

        // Back to login link
        let backButton = UIButton(type: .system)
        backButton.setTitle("← Back to Login", for: .normal)
        backButton.titleLabel?.font = .systemFont(ofSize: 15)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        stack.addArrangedSubview(backButton)
    }

    // MARK: - Actions
    @objc private func sendCodeTapped() {
        guard let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty else {
            showAlert(title: "Error", message: "Please enter your email address.")
            return
        }

        // Basic email validation
        guard email.contains("@") && email.contains(".") else {
            showAlert(title: "Invalid Email", message: "Please enter a valid email address.")
            return
        }

        sendCodeButton.isEnabled = false
        sendCodeButton.setTitle("Sending...", for: .normal)

        Task {
            do {
                try await SupabaseManager.shared.requestPasswordReset(email: email)

                await MainActor.run {
                    self.sendCodeButton.isEnabled = true
                    self.sendCodeButton.setTitle("Send Verification Code", for: .normal)

                    // Navigate to OTP verification screen
                    let verifyVC = VerifyOTPViewController(email: email)
                    self.navigationController?.pushViewController(verifyVC, animated: true)
                }
            } catch {
                await MainActor.run {
                    self.sendCodeButton.isEnabled = true
                    self.sendCodeButton.setTitle("Send Verification Code", for: .normal)
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
