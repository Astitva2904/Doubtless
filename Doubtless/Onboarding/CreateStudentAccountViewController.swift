import UIKit

final class CreateStudentAccountViewController: UIViewController {

    // MARK: - UI
    private let stack = UIStackView()

    private let nameField = UITextField()
    private let emailField = UITextField()
    private let passwordField = UITextField()
    private let mobileField = UITextField()

    private let createAccountButton = UIButton(type: .system)

    private let bottomImageView = UIImageView()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = UIColor(red: 0.98, green: 0.94, blue: 0.87, alpha: 1)

        setupStack()
        setupUI()
        setupBottomImage()
    }

    // MARK: - Stack
    private func setupStack() {
        stack.axis = .vertical
        stack.spacing = 20

        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -80),
            stack.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    // MARK: - UI
    private func setupUI() {
        setupTitle()
        setupTextField(title: "Name", field: nameField, capitalization: .words)
        setupTextField(title: "Email", field: emailField, keyboard: .emailAddress, capitalization: .none)
        setupPassword()
        setupTextField(title: "Mobile Number", field: mobileField, keyboard: .phonePad)
        setupCreateAccountButton()
        setupLoginLink()
    }

    // MARK: - Title
    private func setupTitle() {
        let title = UILabel()
        title.text = "Create Student Account"
        title.font = .boldSystemFont(ofSize: 26)
        title.textAlignment = .center
        stack.addArrangedSubview(title)
    }



    // MARK: - Text Fields
    private func setupTextField(
        title: String,
        field: UITextField,
        keyboard: UIKeyboardType = .default,
        capitalization: UITextAutocapitalizationType = .sentences
    ) {
        let label = UILabel()
        label.text = title
        label.font = .boldSystemFont(ofSize: 16)

        field.borderStyle = .roundedRect
        field.keyboardType = keyboard
        field.autocapitalizationType = capitalization
        field.autocorrectionType = .no
        field.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let vStack = UIStackView(arrangedSubviews: [label, field])
        vStack.axis = .vertical
        vStack.spacing = 6

        stack.addArrangedSubview(vStack)
    }

    private func setupPassword() {
        passwordField.isSecureTextEntry = true
        setupTextField(title: "Password", field: passwordField)
    }



    // MARK: - Create Account Button
    private func setupCreateAccountButton() {
        createAccountButton.setTitle("Create Account", for: .normal)
        createAccountButton.setTitleColor(.white, for: .normal)
        createAccountButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        createAccountButton.layer.cornerRadius = 28
        createAccountButton.heightAnchor.constraint(equalToConstant: 56).isActive = true

        createAccountButton.isEnabled = true
        createAccountButton.backgroundColor = .black

        // ✅ ADD THIS
        createAccountButton.addTarget(
            self,
            action: #selector(createAccountTapped),
            for: .touchUpInside
        )

        stack.addArrangedSubview(createAccountButton)
    }
    
    @objc private func createAccountTapped() {
        guard let name = nameField.text, !name.isEmpty,
              let email = emailField.text, !email.isEmpty,
              let password = passwordField.text, !password.isEmpty,
              let mobile = mobileField.text, !mobile.isEmpty else {
            showAlert(title: "Error", message: "Please fill in all fields.")
            return
        }

        createAccountButton.isEnabled = false
        createAccountButton.setTitle("Creating...", for: .normal)

        Task {
            do {
                _ = try await SupabaseManager.shared.signUp(
                    email: email,
                    password: password,
                    name: name,
                    mobile: mobile,
                    profileImageUrl: nil
                )




                DispatchQueue.main.async {
                    self.navigateToSplash()
                }

            } catch {
                DispatchQueue.main.async {
                    self.createAccountButton.isEnabled = true
                    self.createAccountButton.setTitle("Create Account", for: .normal)
                    self.showAlert(title: "Signup Failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func navigateToSplash() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }

        let splashVC = SplashViewControllerStudent()
        let nav = UINavigationController(rootViewController: splashVC)
        nav.navigationBar.isHidden = true

        UIView.transition(
            with: window,
            duration: 0.35,
            options: [.transitionCrossDissolve],
            animations: {
                window.rootViewController = nav
            }
        )
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }





    // MARK: - Login Link
    private func setupLoginLink() {
        let info = UILabel()
        info.text = "Already have an account?"
        info.textColor = .gray
        info.textAlignment = .center

        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)

        // ✅ ADD THIS
        button.addTarget(self, action: #selector(openLogin), for: .touchUpInside)

        let vStack = UIStackView(arrangedSubviews: [info, button])
        vStack.axis = .vertical
        vStack.alignment = .center
        vStack.spacing = 0

        stack.addArrangedSubview(vStack)
    }
    
    @objc private func openLogin() {
        let vc = StudentLoginViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Bottom Image
    private func setupBottomImage() {
        bottomImageView.image = UIImage(named: "No Booked Sessions Image")
        bottomImageView.contentMode = .scaleAspectFit
        bottomImageView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(bottomImageView)
        view.sendSubviewToBack(bottomImageView)

        NSLayoutConstraint.activate([
            bottomImageView.heightAnchor.constraint(equalToConstant: 280),
            bottomImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottomImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1.0),
            bottomImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10)
        ])
    }
}

