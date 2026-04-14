import UIKit
import Supabase
import Auth
import AuthenticationServices

final class CreateSolverAccountViewController: UIViewController {

    // MARK: - UI
    private let stack = UIStackView()

    private let nameField = UITextField()
    private let emailField = UITextField()
    private let passwordField = UITextField()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = UIColor(red: 0.90, green: 0.97, blue: 1.0, alpha: 1)
        setupUI()
    }

    // MARK: - Setup
    private func setupUI() {
        setupStack()
        setupTitle()
        setupNameField()
        setupEmail()
        setupPasswordField()
        setupCreateAccountButton()
        setupLoginLink()
        setupBottomImage()
    }


    private func isValidEmail(_ email: String) -> Bool {
        let regex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }

    private func setupStack() {
        stack.axis = .vertical
        stack.spacing = 24

        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -80),
            stack.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func setupTitle() {
        let title = UILabel()
        title.text = "Create a Solver Account"
        title.font = .boldSystemFont(ofSize: 24)
        title.textAlignment = .center
        stack.addArrangedSubview(title)
    }



    // MARK: - Name Field
    private func setupNameField() {
        let label = UILabel()
        label.text = "Full Name"
        label.font = .boldSystemFont(ofSize: 16)

        nameField.borderStyle = .roundedRect
        nameField.autocapitalizationType = .words
        nameField.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let vStack = UIStackView(arrangedSubviews: [label, nameField])
        vStack.axis = .vertical
        vStack.spacing = 6
        stack.addArrangedSubview(vStack)
    }

    // MARK: - Email
    private func setupEmail() {
        let label = UILabel()
        label.text = "College Mail ID"
        label.font = .boldSystemFont(ofSize: 16)

        emailField.borderStyle = .roundedRect
        emailField.keyboardType = .emailAddress
        emailField.autocapitalizationType = .none
        emailField.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let emailStack = UIStackView(arrangedSubviews: [label, emailField])
        emailStack.axis = .vertical
        emailStack.spacing = 6

        stack.addArrangedSubview(emailStack)
    }

    // MARK: - Password Field
    private func setupPasswordField() {
        let label = UILabel()
        label.text = "Password"
        label.font = .boldSystemFont(ofSize: 16)

        passwordField.borderStyle = .roundedRect
        passwordField.isSecureTextEntry = true
        passwordField.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let vStack = UIStackView(arrangedSubviews: [label, passwordField])
        vStack.axis = .vertical
        vStack.spacing = 6
        stack.addArrangedSubview(vStack)
    }

    // MARK: - Create Account Button
    private func setupCreateAccountButton() {
        let button = UIButton(type: .system)
        button.setTitle("Create Account", for: .normal)
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 17)
        button.layer.cornerRadius = 26
        button.heightAnchor.constraint(equalToConstant: 52).isActive = true
        button.addTarget(self, action: #selector(manualSignUpTapped), for: .touchUpInside)
        stack.addArrangedSubview(button)
    }

    @objc private func manualSignUpTapped() {
        guard let name = nameField.text, !name.isEmpty,
              let email = emailField.text, !email.isEmpty, isValidEmail(email),
              let password = passwordField.text, !password.isEmpty else {
            let alert = UIAlertController(title: "Missing Fields", message: "Please fill in your name, a valid email, and password.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        Task {
            do {
                _ = try await SupabaseManager.shared.signUp(email: email, password: password, name: name, mobile: "", role: "solver_pending")
                // After sign-up, navigate to document upload screen
                DispatchQueue.main.async {
                    let vc = SolverDocumentUploadViewController()
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Sign-Up Failed", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    // MARK: - Login Link
    private func setupLoginLink() {
        let info = UILabel()
        info.text = "Already have an account?"
        info.textAlignment = .center
        info.textColor = .gray
        info.font = .systemFont(ofSize: 18)

        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.addTarget(self, action: #selector(openLogin), for: .touchUpInside)

        let vStack = UIStackView(arrangedSubviews: [info, button])
        vStack.axis = .vertical
        vStack.alignment = .center
        vStack.spacing = 0

        stack.addArrangedSubview(vStack)
    }

    @objc private func openLogin() {
        let vc = SolverLoginViewController()
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
            bottomImageView.heightAnchor.constraint(equalToConstant: 280),
            bottomImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottomImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1.0),
            bottomImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10)
        ])
    }
}
