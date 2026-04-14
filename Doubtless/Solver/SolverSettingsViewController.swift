import UIKit
import Auth
import Supabase

final class SolverSettingsViewController: UIViewController {

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    
    
    private var darkModeSwitch: UISwitch?

    private let editProfileButton = UIButton(type: .custom)
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupNavigationBar()
        setupScrollView()
        setupContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        
        let isCurrentlyDark = traitCollection.userInterfaceStyle == .dark
        darkModeSwitch?.isOn = isCurrentlyDark
        UserDefaults.standard.set(isCurrentlyDark, forKey: "isDarkModeEnabled")
    }

    // MARK: - Navigation Bar
    private func setupNavigationBar() {
        title = "Settings"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - ScrollView
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),

            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    // MARK: - Content
    private func setupContent() {
        stackView.axis = .vertical
        stackView.spacing = 32
        stackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])

        setupEditProfileButton()

        stackView.addArrangedSubview(makeSection(
            title: "Appearance",
            items: [("Dark Mode", false)]
        ))

        stackView.addArrangedSubview(makeSection(
            title: "Solving Preferences",
            items: [
                ("Auto-accept doubts", false),
                ("Silent while solving", false)
            ]
        ))

        stackView.addArrangedSubview(makeSection(
            title: "Notifications",
            items: [
                ("Sound alerts", false),
                ("Vibration", false)
            ]
        ))

        stackView.addArrangedSubview(makeAccountSection())
    }

    // MARK: - Edit Profile Button
    private func setupEditProfileButton() {
        let glassyButton = makeGlassyButton(title: "Edit Profile")

        glassyButton.translatesAutoresizingMaskIntoConstraints = false
        glassyButton.heightAnchor.constraint(equalToConstant: 50).isActive = true

        glassyButton.addTarget(
            self,
            action: #selector(openEditProfile),
            for: .touchUpInside
        )

        stackView.addArrangedSubview(glassyButton)
    }

    @objc private func openEditProfile() {
        let vc = SolverEditProfileViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Sections
    private func makeSection(title: String, items: [(String, Bool)]) -> UIView {
        let container = UIView()

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)

        let sectionStack = UIStackView()
        sectionStack.axis = .vertical
        sectionStack.spacing = 16

        items.forEach {
            sectionStack.addArrangedSubview(makeToggleRow(title: $0.0, isOn: $0.1))
        }

        let mainStack = UIStackView(arrangedSubviews: [titleLabel, sectionStack])
        mainStack.axis = .vertical
        mainStack.spacing = 16
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: container.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func makeAccountSection() -> UIView {
        let container = UIView()

        let titleLabel = UILabel()
        titleLabel.text = "Account"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .left

        let changePasswordButton = makeGlassyActionButton(
            title: "Change Password",
            tintColor: .systemBlue
        )

        changePasswordButton.addTarget(
            self,
            action: #selector(changePasswordTapped),
            for: .touchUpInside
        )

        let deleteAccountButton = makeGlassyActionButton(
            title: "Delete Account",
            tintColor: .systemRed,
            isDestructive: true
        )

        deleteAccountButton.addTarget(
            self,
            action: #selector(deleteAccountTapped),
            for: .touchUpInside
        )

        let logoutButton = makeGlassyActionButton(
            title: "Log Out",
            tintColor: .systemRed,
            isDestructive: true
        )

        logoutButton.addTarget(
            self,
            action: #selector(logOutTapped),
            for: .touchUpInside
        )

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            changePasswordButton,
            logoutButton,
            deleteAccountButton
        ])

        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    // MARK: - Rows
    private func makeToggleRow(title: String, isOn: Bool) -> UIView {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16)

        let toggle = UISwitch()

        // 🔵 MAKE ALL TOGGLES BLUE
        toggle.onTintColor = .systemBlue

        // Default state
        toggle.isOn = isOn

        // Dark mode handling
        if title == "Dark Mode" {
            darkModeSwitch = toggle

            // Read the actual current interface style so the toggle is always in sync
            let isCurrentlyDark = traitCollection.userInterfaceStyle == .dark
            toggle.isOn = isCurrentlyDark

            toggle.addTarget(
                self,
                action: #selector(darkModeToggled(_:)),
                for: .valueChanged
            )
        }

        let stack = UIStackView(arrangedSubviews: [label, toggle])
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center

        return stack
    }
    
    @objc private func darkModeToggled(_ sender: UISwitch) {

        let isDark = sender.isOn
        UserDefaults.standard.set(isDark, forKey: "isDarkModeEnabled")

        let style: UIUserInterfaceStyle = isDark ? .dark : .light

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            scene.windows.forEach {
                $0.overrideUserInterfaceStyle = style
            }
        }
    }

    private func makeActionRow(title: String, isDestructive: Bool = false) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.contentHorizontalAlignment = .left
        button.setTitleColor(isDestructive ? .systemRed : .label, for: .normal)
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }
    
    private func makeGlassyButton(title: String) -> UIButton {
        let button = UIButton(type: .custom)
        button.clipsToBounds = true
        button.layer.cornerRadius = 14

        // Blur effect
        let blur = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blur)
        blurView.isUserInteractionEnabled = false
        blurView.translatesAutoresizingMaskIntoConstraints = false

        // Blue tint overlay
        let tintView = UIView()
        tintView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.18)
        tintView.translatesAutoresizingMaskIntoConstraints = false
        tintView.isUserInteractionEnabled = false

        // Title label
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .systemBlue
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        // Hierarchy
        button.addSubview(blurView)
        blurView.contentView.addSubview(tintView)
        button.addSubview(label)
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: button.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: button.bottomAnchor),

            tintView.topAnchor.constraint(equalTo: blurView.contentView.topAnchor),
            tintView.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor),
            tintView.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor),
            tintView.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor),

            label.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])

        return button
    }
    
    private func makeGlassyActionButton(
        title: String,
        tintColor: UIColor,
        isDestructive: Bool = false
    ) -> UIButton {

        let button = UIButton(type: .custom)
        button.clipsToBounds = true
        button.layer.cornerRadius = 14
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true

        // Blur
        let blur = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blur)
        blurView.isUserInteractionEnabled = false
        blurView.translatesAutoresizingMaskIntoConstraints = false

        // Tint
        let tintView = UIView()
        tintView.backgroundColor = tintColor.withAlphaComponent(0.18)
        tintView.translatesAutoresizingMaskIntoConstraints = false
        tintView.isUserInteractionEnabled = false

        // Title
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = tintColor
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        // Border
        button.layer.borderWidth = 0.6
        button.layer.borderColor = tintColor.withAlphaComponent(0.35).cgColor

        // Hierarchy
        button.addSubview(blurView)
        blurView.contentView.addSubview(tintView)
        button.addSubview(label)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: button.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: button.bottomAnchor),

            tintView.topAnchor.constraint(equalTo: blurView.contentView.topAnchor),
            tintView.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor),
            tintView.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor),
            tintView.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor),

            label.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])

        return button
    }
    
    @objc private func changePasswordTapped() {
        print("Change Password tapped")
        let alert = UIAlertController(title: "Change Password", message: "Enter your current password and a new password.", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Current Password"
            textField.isSecureTextEntry = true
        }
        alert.addTextField { textField in
            textField.placeholder = "New Password"
            textField.isSecureTextEntry = true
        }
        alert.addTextField { textField in
            textField.placeholder = "Confirm New Password"
            textField.isSecureTextEntry = true
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Update", style: .default) { [weak self] _ in
            guard let currentPass = alert.textFields?[0].text, !currentPass.isEmpty,
                  let newPass = alert.textFields?[1].text, !newPass.isEmpty,
                  let confirmPass = alert.textFields?[2].text, !confirmPass.isEmpty else {
                self?.showAlert(title: "Error", message: "Please fill in all fields.")
                return
            }
            
            if newPass != confirmPass {
                self?.showAlert(title: "Error", message: "New passwords do not match.")
                return
            }
            if newPass.count < 6 {
                self?.showAlert(title: "Error", message: "Password must be at least 6 characters.")
                return
            }
            
            self?.updatePassword(currentPassword: currentPass, newPassword: newPass)
        })
        present(alert, animated: true)
    }

    private func updatePassword(currentPassword: String, newPassword: String) {
        Task {
            do {
                try await SupabaseManager.shared.updatePassword(currentPassword: currentPassword, newPassword: newPassword)
                await MainActor.run {
                    self.showAlert(title: "Success", message: "Your password has been changed successfully.")
                }
            } catch {
                await MainActor.run {
                    let errorMessage = (error as NSError).domain == "GoTrue.APIError" ? "Incorrect current password." : error.localizedDescription
                    self.showAlert(title: "Error", message: errorMessage)
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        if presentedViewController == nil {
            present(alert, animated: true)
        } else {
            presentedViewController?.present(alert, animated: true)
        }
    }

    @objc private func logOutTapped() {
        let alert = UIAlertController(
            title: "Log Out",
            message: "Are you sure you want to log out?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { [weak self] _ in
            self?.performLogOut()
        })
        present(alert, animated: true)
    }

    private func performLogOut() {
        Task {
            do {
                try await SupabaseManager.shared.logOut()
                UserDefaults.standard.removeObject(forKey: "selectedRole")

                await MainActor.run {
                    guard let window = self.view.window
                        ?? UIApplication.shared.connectedScenes
                            .compactMap({ $0 as? UIWindowScene })
                            .flatMap({ $0.windows })
                            .first(where: { $0.isKeyWindow })
                    else { return }

                    let roleVC = RoleSelectionViewController()
                    let nav = UINavigationController(rootViewController: roleVC)
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
            } catch {
                await MainActor.run {
                    let errorAlert = UIAlertController(
                        title: "Error",
                        message: "Failed to log out: \(error.localizedDescription)",
                        preferredStyle: .alert
                    )
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(errorAlert, animated: true)
                }
            }
        }
    }

    // MARK: - Delete Account
    @objc private func deleteAccountTapped() {
        let alert = UIAlertController(
            title: "Delete Account",
            message: "This action is permanent and cannot be undone. All your data and history will be permanently deleted.\n\nEnter your password to confirm.",
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = "Enter your password"
            textField.isSecureTextEntry = true
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete Forever", style: .destructive) { [weak self] _ in
            guard let password = alert.textFields?.first?.text, !password.isEmpty else {
                self?.showAlert(title: "Error", message: "Please enter your password to confirm deletion.")
                return
            }
            self?.performDeleteAccount(password: password)
        })
        present(alert, animated: true)
    }

    private func performDeleteAccount(password: String) {
        let loadingAlert = UIAlertController(title: nil, message: "Deleting account...", preferredStyle: .alert)
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()
        loadingAlert.view.addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: loadingAlert.view.centerXAnchor),
            indicator.topAnchor.constraint(equalTo: loadingAlert.view.topAnchor, constant: 12)
        ])
        present(loadingAlert, animated: true)

        Task {
            do {
                guard let user = try await SupabaseManager.shared.getCurrentUser(),
                      let email = user.email else {
                    await MainActor.run {
                        loadingAlert.dismiss(animated: true) {
                            self.showAlert(title: "Error", message: "Could not verify your identity.")
                        }
                    }
                    return
                }

                _ = try await SupabaseManager.shared.client.auth.signIn(email: email, password: password)

                try await SupabaseManager.shared.deleteAccount()
                UserDefaults.standard.removeObject(forKey: "selectedRole")

                await MainActor.run {
                    loadingAlert.dismiss(animated: true) {
                        guard let window = self.view.window
                            ?? UIApplication.shared.connectedScenes
                                .compactMap({ $0 as? UIWindowScene })
                                .flatMap({ $0.windows })
                                .first(where: { $0.isKeyWindow })
                        else { return }

                        let roleVC = RoleSelectionViewController()
                        let nav = UINavigationController(rootViewController: roleVC)
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
            } catch {
                await MainActor.run {
                    loadingAlert.dismiss(animated: true) {
                        let message = error.localizedDescription.contains("Invalid") || error.localizedDescription.contains("invalid")
                            ? "Incorrect password. Please try again."
                            : "Failed to delete account: \(error.localizedDescription)"
                        self.showAlert(title: "Error", message: message)
                    }
                }
            }
        }
    }
}
