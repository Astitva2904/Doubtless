import UIKit
import Supabase
import Auth
import AuthenticationServices

final class SolverLoginViewController: UIViewController {

    // MARK: - UI
    private let stack = UIStackView()

    private let usernameField = UITextField()
    private let passwordField = UITextField()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = UIColor(red: 0.90, green: 0.97, blue: 1.0, alpha: 1)

        setupStack()
        setupUI()
    }

    // MARK: - Stack
    private func setupStack() {
        stack.axis = .vertical
        stack.spacing = 24

        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            stack.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    // MARK: - UI Setup
    private func setupUI() {
        setupTitle()
        setupUsername()
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

    private func resizedImage(named name: String, size: CGSize) -> UIImage? {
        guard let image = UIImage(named: name) else { return nil }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - Username
    private func setupUsername() {
        let label = UILabel()
        label.text = "College Mail ID"
        label.font = .boldSystemFont(ofSize: 16)

        usernameField.borderStyle = .roundedRect
        usernameField.autocapitalizationType = .none
        usernameField.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let vStack = UIStackView(arrangedSubviews: [label, usernameField])
        vStack.axis = .vertical
        vStack.spacing = 8

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
        vStack.spacing = 8

        stack.addArrangedSubview(vStack)
        stack.setCustomSpacing(24, after: vStack)
    }

    // MARK: - Login Button
    private func setupLoginButton() {
        let button = UIButton(type: .system)
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.layer.cornerRadius = 28
        button.heightAnchor.constraint(equalToConstant: 56).isActive = true

        button.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)

        stack.addArrangedSubview(button)
        stack.setCustomSpacing(40, after: button)
    }

    @objc private func forgotPasswordTapped() {
        let vc = ForgotPasswordViewController()
        vc.flowBackgroundColor = self.view.backgroundColor
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func loginTapped() {
        guard let email = usernameField.text, !email.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            let alert = UIAlertController(title: "Missing Fields", message: "Please enter your email and password.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        Task {
            do {
                let user = try await SupabaseManager.shared.logIn(email: email, password: password)
                
                // Check the role from the returned user first
                var role = SupabaseManager.shared.getUserRole(for: user)
                
                // If role is nil from the JWT, try fetching fresh from server
                if role == nil {
                    role = await SupabaseManager.shared.fetchCurrentUserRole()
                }
                
                print("🔍 Solver login - detected role: \(role ?? "nil")")
                
                if role == "student" {
                    // Sign them back out — they can't login as solver with a student account
                    try? await SupabaseManager.shared.logOut()
                    await MainActor.run {
                        let alert = UIAlertController(title: "Wrong Role", message: "This account is registered as a Student. Please use the Student login instead.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                    return
                }
                
                // If no role exists yet (old account), stamp as solver_pending now
                if role == nil {
                    print("📝 Stamping role as 'solver_pending' for existing account")
                    try? await SupabaseManager.shared.setUserRole("solver_pending")
                }
                
                await MainActor.run {
                    // Check if solver fully completed document upload phase
                    if role == "solver" {
                        self.navigateToDashboard()
                    } else {
                        // Incomplete account! Kick to document upload securely
                        let vc = SolverDocumentUploadViewController()
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    let alert = UIAlertController(title: "Login Failed", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    // MARK: - Navigate to Dashboard Directly
    private func navigateToDashboard() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let tabBar = MainTabBarController()
        let nav = SwipeableNavigationController(rootViewController: tabBar)
        nav.navigationBar.isHidden = true
        
        UIView.transition(with: window, duration: 0.35, options: [.transitionCrossDissolve]) {
            window.rootViewController = nav
        }
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
        vStack.spacing = 0

        stack.addArrangedSubview(vStack)
    }

    @objc private func openCreateAccount() {
        let vc = CreateSolverAccountViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Bottom Image
    private func setupBottomImage() {
        let bottomImageView = UIImageView(image: UIImage(named: "No Booked Sessions Image"))
        bottomImageView.contentMode = .scaleAspectFit
        bottomImageView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(bottomImageView)
        view.sendSubviewToBack(bottomImageView)

        NSLayoutConstraint.activate([
            bottomImageView.heightAnchor.constraint(equalToConstant: 220),
            bottomImageView.topAnchor.constraint(greaterThanOrEqualTo: stack.bottomAnchor, constant: 30),
            bottomImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottomImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -5)
        ])
    }
}
