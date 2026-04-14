import UIKit

final class VerifyOTPViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Properties
    private let email: String
    private var otpFields: [UITextField] = []
    private let verifyButton = UIButton(type: .system)
    private let resendButton = UIButton(type: .system)

    private var resendTimer: Timer?
    private var resendCountdown = 60

    // MARK: - Init
    init(email: String) {
        self.email = email
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
        title = "Verify Code"

        setupUI()
        startResendTimer()

        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        otpFields.first?.becomeFirstResponder()
    }

    deinit {
        resendTimer?.invalidate()
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
        stack.alignment = .center
        contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -40)
        ])

        // Icon
        let icon = UIImageView(image: UIImage(systemName: "envelope.badge"))
        icon.tintColor = .black
        icon.contentMode = .scaleAspectFit
        icon.heightAnchor.constraint(equalToConstant: 70).isActive = true
        stack.addArrangedSubview(icon)

        // Title
        let title = UILabel()
        title.text = "Verify Your Email"
        title.font = .boldSystemFont(ofSize: 26)
        title.textAlignment = .center
        stack.addArrangedSubview(title)

        // Subtitle
        let subtitle = UILabel()
        subtitle.text = "We've sent a 4-digit verification code to\n\(email)"
        subtitle.font = .systemFont(ofSize: 15)
        subtitle.textColor = .darkGray
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0
        stack.addArrangedSubview(subtitle)
        stack.setCustomSpacing(32, after: subtitle)

        // OTP Fields
        let otpStack = UIStackView()
        otpStack.axis = .horizontal
        otpStack.spacing = 16
        otpStack.distribution = .fillEqually

        for i in 0..<4 {
            let field = UITextField()
            field.borderStyle = .none
            field.textAlignment = .center
            field.font = .boldSystemFont(ofSize: 28)
            field.keyboardType = .numberPad
            field.backgroundColor = .white
            field.layer.cornerRadius = 14
            field.layer.borderWidth = 2
            field.layer.borderColor = UIColor.lightGray.cgColor
            field.delegate = self
            field.tag = i
            field.addTarget(self, action: #selector(otpFieldChanged(_:)), for: .editingChanged)

            field.translatesAutoresizingMaskIntoConstraints = false
            field.widthAnchor.constraint(equalToConstant: 60).isActive = true
            field.heightAnchor.constraint(equalToConstant: 60).isActive = true

            otpFields.append(field)
            otpStack.addArrangedSubview(field)
        }

        stack.addArrangedSubview(otpStack)
        stack.setCustomSpacing(32, after: otpStack)

        // Verify button
        verifyButton.setTitle("Verify Code", for: .normal)
        verifyButton.backgroundColor = .black
        verifyButton.setTitleColor(.white, for: .normal)
        verifyButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        verifyButton.layer.cornerRadius = 28
        verifyButton.translatesAutoresizingMaskIntoConstraints = false
        verifyButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        verifyButton.addTarget(self, action: #selector(verifyTapped), for: .touchUpInside)

        stack.addArrangedSubview(verifyButton)
        verifyButton.leadingAnchor.constraint(equalTo: stack.leadingAnchor).isActive = true
        verifyButton.trailingAnchor.constraint(equalTo: stack.trailingAnchor).isActive = true

        // Resend button
        resendButton.setTitle("Resend Code (60s)", for: .normal)
        resendButton.titleLabel?.font = .systemFont(ofSize: 15)
        resendButton.isEnabled = false
        resendButton.setTitleColor(.gray, for: .disabled)
        resendButton.addTarget(self, action: #selector(resendTapped), for: .touchUpInside)
        stack.addArrangedSubview(resendButton)
    }

    // MARK: - OTP Field Handling
    @objc private func otpFieldChanged(_ textField: UITextField) {
        let text = textField.text ?? ""

        if text.count >= 1 {
            textField.text = String(text.prefix(1))
            textField.layer.borderColor = UIColor.black.cgColor

            // Move to next field
            if textField.tag < 3 {
                otpFields[textField.tag + 1].becomeFirstResponder()
            } else {
                textField.resignFirstResponder()
            }
        } else {
            textField.layer.borderColor = UIColor.lightGray.cgColor
        }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Handle backspace to move to previous field
        if string.isEmpty && (textField.text?.isEmpty ?? true) {
            if textField.tag > 0 {
                let prevField = otpFields[textField.tag - 1]
                prevField.text = ""
                prevField.layer.borderColor = UIColor.lightGray.cgColor
                prevField.becomeFirstResponder()
            }
            return false
        }

        // Allow only digits
        if string.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) != nil {
            return false
        }

        return true
    }

    // MARK: - Verify Action
    @objc private func verifyTapped() {
        let code = otpFields.map { $0.text ?? "" }.joined()

        guard code.count == 4 else {
            showAlert(title: "Incomplete", message: "Please enter the complete 4-digit code.")
            return
        }

        verifyButton.isEnabled = false
        verifyButton.setTitle("Verifying...", for: .normal)

        Task {
            do {
                let isValid = try await SupabaseManager.shared.verifyPasswordResetOTP(email: email, code: code)

                await MainActor.run {
                    self.verifyButton.isEnabled = true
                    self.verifyButton.setTitle("Verify Code", for: .normal)

                    if isValid {
                        let resetVC = ResetPasswordViewController(email: self.email, otpCode: code)
                        self.navigationController?.pushViewController(resetVC, animated: true)
                    } else {
                        self.showAlert(title: "Invalid Code", message: "The code you entered is incorrect or has expired. Please try again.")
                        // Shake animation on OTP fields
                        self.shakeFields()
                    }
                }
            } catch {
                await MainActor.run {
                    self.verifyButton.isEnabled = true
                    self.verifyButton.setTitle("Verify Code", for: .normal)
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Resend Timer
    private func startResendTimer() {
        resendCountdown = 60
        resendButton.isEnabled = false

        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.resendCountdown -= 1

            if self.resendCountdown <= 0 {
                self.resendTimer?.invalidate()
                self.resendButton.isEnabled = true
                self.resendButton.setTitle("Resend Code", for: .normal)
            } else {
                self.resendButton.setTitle("Resend Code (\(self.resendCountdown)s)", for: .normal)
            }
        }
    }

    @objc private func resendTapped() {
        resendButton.isEnabled = false
        resendButton.setTitle("Sending...", for: .normal)

        Task {
            do {
                try await SupabaseManager.shared.requestPasswordReset(email: email)

                await MainActor.run {
                    self.showAlert(title: "Code Sent", message: "A new verification code has been sent to \(self.email).")
                    self.startResendTimer()
                    // Clear OTP fields
                    for field in self.otpFields {
                        field.text = ""
                        field.layer.borderColor = UIColor.lightGray.cgColor
                    }
                    self.otpFields.first?.becomeFirstResponder()
                }
            } catch {
                await MainActor.run {
                    self.resendButton.isEnabled = true
                    self.resendButton.setTitle("Resend Code", for: .normal)
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Helpers
    private func shakeFields() {
        for field in otpFields {
            let shake = CAKeyframeAnimation(keyPath: "transform.translation.x")
            shake.timingFunction = CAMediaTimingFunction(name: .linear)
            shake.values = [-10, 10, -8, 8, -5, 5, 0]
            shake.duration = 0.4
            field.layer.add(shake, forKey: "shake")
            field.layer.borderColor = UIColor.systemRed.cgColor
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
