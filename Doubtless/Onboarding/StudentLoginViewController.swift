import UIKit

final class StudentLoginViewController: UIViewController {

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stack = UIStackView()

    private let emailField = UITextField()
    private let passwordField = UITextField()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = UIColor(red: 0.98, green: 0.94, blue: 0.87, alpha: 1)
        setupScroll()
        setupStack()
        setupUI()
    }

    // MARK: - Scroll
    private func setupScroll() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        let minHeight = contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.safeAreaLayoutGuide.heightAnchor)
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
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -40),
            stack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 40),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24)
        ])
    }

    // MARK: - UI Setup
    private func setupUI() {
        setupTitle()
        setupEmail()
        setupPassword()
        setupLoginButton()
        setupCreateAccount()
        setupBottomImage()
    }

    // MARK: - Title
    private func setupTitle() {
        let title = UILabel()
        title.text = "Log in"
        title.font = .boldSystemFont(ofSize: 28)
        title.textAlignment = .center
        stack.addArrangedSubview(title)
    }



    // MARK: - Email
    private func setupEmail() {
        let label = UILabel()
        label.text = "Email"
        label.font = .boldSystemFont(ofSize: 16)

        emailField.borderStyle = .roundedRect
        emailField.autocapitalizationType = .none
        emailField.keyboardType = .emailAddress
        emailField.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let vStack = UIStackView(arrangedSubviews: [label, emailField])
        vStack.axis = .vertical
        vStack.spacing = 8   // 👈 THIS controls the gap

        stack.addArrangedSubview(vStack)
    }

    // MARK: - Password
    private func setupPassword() {
        let label = UILabel()
        label.text = "Password"
        label.font = .boldSystemFont(ofSize: 16)

        let forgotButton = UIButton(type: .system)
        forgotButton.setTitle("Forgot Password?", for: .normal)
        forgotButton.titleLabel?.font = .systemFont(ofSize: 14)
        forgotButton.contentHorizontalAlignment = .trailing
        forgotButton.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)

        let headerHStack = UIStackView(arrangedSubviews: [label, UIView(), forgotButton])
        headerHStack.axis = .horizontal
        headerHStack.alignment = .fill

        passwordField.borderStyle = .roundedRect
        passwordField.isSecureTextEntry = true
        passwordField.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let vStack = UIStackView(arrangedSubviews: [headerHStack, passwordField])
        vStack.axis = .vertical
        vStack.spacing = 8   // 👈 smaller gap

        stack.addArrangedSubview(vStack)
        stack.setCustomSpacing(24, after: vStack)
    }

    // MARK: - Login Button
    private let loginActionButton = UIButton(type: .system)
    
    private func setupLoginButton() {
        loginActionButton.setTitle("Log In", for: .normal)
        loginActionButton.backgroundColor = .black
        loginActionButton.setTitleColor(.white, for: .normal)
        loginActionButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        loginActionButton.layer.cornerRadius = 28
        loginActionButton.heightAnchor.constraint(equalToConstant: 56).isActive = true

        loginActionButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)

        stack.addArrangedSubview(loginActionButton)
        stack.setCustomSpacing(40, after: loginActionButton)
    }
    
    @objc private func forgotPasswordTapped() {
        let vc = ForgotPasswordViewController()
        vc.flowBackgroundColor = self.view.backgroundColor
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func loginTapped() {
        guard let email = emailField.text, !email.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            showAlert(title: "Error", message: "Please fill in all fields.")
            return
        }

        loginActionButton.isEnabled = false
        loginActionButton.setTitle("Logging in...", for: .normal)

        Task {
            do {
                let user = try await SupabaseManager.shared.logIn(email: email, password: password)
                
                // Check the role from the returned user first
                var role = SupabaseManager.shared.getUserRole(for: user)
                
                // If role is nil from the JWT, try fetching fresh from server
                if role == nil {
                    role = await SupabaseManager.shared.fetchCurrentUserRole()
                }
                
                print("🔍 Student login - detected role: \(role ?? "nil")")
                
                if SupabaseManager.shared.isSolverSideRole(role) {
                    // Sign them back out — they can't login as student with a solver account
                    try? await SupabaseManager.shared.logOut()
                    await MainActor.run {
                        self.loginActionButton.isEnabled = true
                        self.loginActionButton.setTitle("Log In", for: .normal)
                        self.showAlert(title: "Wrong Role", message: "This account is registered as a Solver. Please use the Solver login instead.")
                    }
                    return
                }
                
                // If no role exists yet (old account), stamp as student now
                if role == nil {
                    print("📝 Stamping role as 'student' for existing account")
                    try? await SupabaseManager.shared.setUserRole("student")
                }

                await MainActor.run {
                    self.navigateToDashboard()
                }

            } catch {
                await MainActor.run {
                    self.loginActionButton.isEnabled = true
                    self.loginActionButton.setTitle("Log In", for: .normal)
                    self.showAlert(title: "Login Failed", message: error.localizedDescription)
                }
            }
        }
    }




    private func navigateToDashboard() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }

        let tabBar = MainTabBarControllerStudent()
        let nav = SwipeableNavigationController(rootViewController: tabBar)
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

    // MARK: - Create Account
    private func setupCreateAccount() {
        let info = UILabel()
        info.text = "Don’t have an account?"
        info.textAlignment = .center
        info.textColor = .gray
        info.font = .systemFont(ofSize: 18)

        let button = UIButton(type: .system)
        button.setTitle("Create an account", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.addTarget(self, action: #selector(openCreateAccount), for: .touchUpInside)

        let vStack = UIStackView(arrangedSubviews: [info, button])
        vStack.axis = .vertical
        vStack.alignment = .center
        vStack.spacing = 0   // 👈 THIS controls the distance you want

        stack.addArrangedSubview(vStack)
    }

    @objc private func openCreateAccount() {
        let vc = CreateStudentAccountViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Bottom Image
    private func setupBottomImage() {
        let image = UIImageView(image: UIImage(named: "No Booked Sessions Image"))
        image.contentMode = .scaleAspectFit
        image.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(image)
        
        NSLayoutConstraint.activate([
            image.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            image.heightAnchor.constraint(equalToConstant: 220),
            image.topAnchor.constraint(greaterThanOrEqualTo: stack.bottomAnchor, constant: 30),
            image.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5)
        ])
    }
}
