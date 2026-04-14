import UIKit

final class ResetPasswordViewController: UIViewController {

    // MARK: - Properties
    private let email: String
    private let otpCode: String

    private let newPasswordField = UITextField()
    private let confirmPasswordField = UITextField()
    private let resetButton = UIButton(type: .system)

    // MARK: - Init
    init(email: String, otpCode: String) {
        self.email = email
        self.otpCode = otpCode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = UIColor(red: 0.98, green: 0.94, blue: 0.87, alpha: 1)
        title = "Reset Password"

        // Disable back navigation (user must complete reset or cancel explicitly)
        navigationItem.hidesBackButton = true

        setupUI()

        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
    }

    // MARK: - UI Setup
    private func setupUI() {
        let scrollView = UIScrollView()
        let contentView = UIView()
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24
        contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -40)
        ])

        // Icon
        let icon = UIImageView(image: UIImage(systemName: "lock.shield"))
        icon.tintColor = .black
        icon.contentMode = .scaleAspectFit
        icon.heightAnchor.constraint(equalToConstant: 70).isActive = true
        stack.addArrangedSubview(icon)

        // Title
        let title = UILabel()
        title.text = "Create New Password"
        title.font = .boldSystemFont(ofSize: 26)
        title.textAlignment = .center
        stack.addArrangedSubview(title)

        // Subtitle
        let subtitle = UILabel()
        subtitle.text = "Your new password must be at least 6 characters long."
        subtitle.font = .systemFont(ofSize: 15)
        subtitle.textColor = .darkGray
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0
        stack.addArrangedSubview(subtitle)
        stack.setCustomSpacing(32, after: subtitle)

        // New Password
        let newLabel = UILabel()
        newLabel.text = "New Password"
        newLabel.font = .boldSystemFont(ofSize: 16)

        newPasswordField.borderStyle = .roundedRect
        newPasswordField.isSecureTextEntry = true
        newPasswordField.placeholder = "Enter new password"
        newPasswordField.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let newStack = UIStackView(arrangedSubviews: [newLabel, newPasswordField])
        newStack.axis = .vertical
        newStack.spacing = 8
        stack.addArrangedSubview(newStack)

        // Confirm Password
        let confirmLabel = UILabel()
        confirmLabel.text = "Confirm Password"
        confirmLabel.font = .boldSystemFont(ofSize: 16)

        confirmPasswordField.borderStyle = .roundedRect
        confirmPasswordField.isSecureTextEntry = true
        confirmPasswordField.placeholder = "Re-enter new password"
        confirmPasswordField.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let confirmStack = UIStackView(arrangedSubviews: [confirmLabel, confirmPasswordField])
        confirmStack.axis = .vertical
        confirmStack.spacing = 8
        stack.addArrangedSubview(confirmStack)
        stack.setCustomSpacing(32, after: confirmStack)

        // Reset Button
        resetButton.setTitle("Reset Password", for: .normal)
        resetButton.backgroundColor = .black
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        resetButton.layer.cornerRadius = 28
        resetButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        stack.addArrangedSubview(resetButton)

        // Cancel button
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 15)
        cancelButton.setTitleColor(.systemRed, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        stack.addArrangedSubview(cancelButton)
    }

    // MARK: - Actions
    @objc private func resetTapped() {
        guard let newPass = newPasswordField.text, !newPass.isEmpty,
              let confirmPass = confirmPasswordField.text, !confirmPass.isEmpty else {
            showAlert(title: "Error", message: "Please fill in both password fields.")
            return
        }

        guard newPass.count >= 6 else {
            showAlert(title: "Too Short", message: "Password must be at least 6 characters long.")
            return
        }

        guard newPass == confirmPass else {
            showAlert(title: "Mismatch", message: "Passwords do not match. Please try again.")
            return
        }

        resetButton.isEnabled = false
        resetButton.setTitle("Resetting...", for: .normal)

        Task {
            do {
                try await SupabaseManager.shared.resetPassword(email: email, otpCode: otpCode, newPassword: newPass)

                await MainActor.run {
                    self.resetButton.isEnabled = true
                    self.resetButton.setTitle("Reset Password", for: .normal)
                    self.showSuccessAndPopToLogin()
                }
            } catch {
                await MainActor.run {
                    self.resetButton.isEnabled = true
                    self.resetButton.setTitle("Reset Password", for: .normal)
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }

    @objc private func cancelTapped() {
        // Pop all the way back to login
        navigationController?.popToRootViewController(animated: true)
    }

    private func showSuccessAndPopToLogin() {
        let alert = UIAlertController(
            title: "Password Reset Successful! ✅",
            message: "Your password has been updated. Please log in with your new password.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Go to Login", style: .default) { [weak self] _ in
            self?.navigationController?.popToRootViewController(animated: true)
        })
        present(alert, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
