import UIKit
import Supabase

final class SplashViewController: UIViewController {

    // MARK: - UI
    let onboardingBG = UIColor(red: 0.98, green: 0.94, blue: 0.87, alpha: 1)
    private let logoImageView = UIImageView()
    private let nameLabel = UILabel()

    // Constraints we will animate
    private var logoCenterXConstraint: NSLayoutConstraint!
    private var nameLeadingConstraint: NSLayoutConstraint!

    // Callback to SceneDelegate
    var onFinish: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = onboardingBG
        setupUI()
        animateLogo()
    }

    private func setupUI() {

        // Logo
        logoImageView.image = UIImage(named: "Logo - Doubtless")
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false

        // Text (ONLY "oubtless")
        nameLabel.text = "OUBTLESS"
        nameLabel.font = .systemFont(ofSize: 34, weight: .bold)
        nameLabel.textColor = .black
        nameLabel.alpha = 0          // 👈 start hidden
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(logoImageView)
        view.addSubview(nameLabel)

        // Logo starts centered
        logoCenterXConstraint =
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor)

        // Text starts just outside logo (will slide in)
        nameLeadingConstraint =
            nameLabel.leadingAnchor.constraint(
                equalTo: logoImageView.trailingAnchor,
                constant: 80              // 👈 start far right
            )

        NSLayoutConstraint.activate([
            logoCenterXConstraint,
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 220),
            logoImageView.heightAnchor.constraint(equalToConstant: 220),

            nameLabel.centerYAnchor.constraint(equalTo: logoImageView.centerYAnchor),
            nameLeadingConstraint
        ])
        
        // Start logo bigger before animation
        logoImageView.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
    }

    private func animateLogo() {

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {

            // Move logo left
            self.logoCenterXConstraint.constant = -90

            // Bring text next to logo
            self.nameLeadingConstraint.constant = -70

            UIView.animate(
                withDuration: 0.9,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.6,
                options: [.curveEaseInOut],
                animations: {
                    self.logoImageView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
                    self.nameLabel.alpha = 1
                    self.view.layoutIfNeeded()
                },
                completion: { _ in
                    self.finishSplash()
                }
            )
        }
    }
    
    private func finishSplash() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {

            let window = self.view.window ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }

            guard let window = window else { return }

            // Check if user is already logged in
            Task {
                let user = try? await SupabaseManager.shared.getCurrentUser()
                
                await MainActor.run {
                    let rootVC: UIViewController
                    
                    if let user = user {
                        // User is logged in — go to dashboard based on saved role
                        let savedRole = UserDefaults.standard.string(forKey: "selectedRole") ?? "student"
                        if savedRole == "solver" {
                            
                            // Check if the solver natively completely finished submitting documents
                            if let roleStatus = user.userMetadata["role"]?.stringValue, roleStatus == "solver" {
                                rootVC = MainTabBarController()
                            } else {
                                // They aggressively abandoned the app midway before uploading! Kick them mathematically back natively.
                                rootVC = SolverDocumentUploadViewController()
                            }
                        } else {
                            rootVC = MainTabBarControllerStudent()
                        }
                    } else {
                        // Not logged in — show role selection
                        rootVC = RoleSelectionViewController()
                    }
                    
                    let nav = SwipeableNavigationController(rootViewController: rootVC)
                    nav.navigationBar.isHidden = true
                    
                    UIView.transition(
                        with: window,
                        duration: 0.6,
                        options: [.transitionCrossDissolve],
                        animations: {
                            window.rootViewController = nav
                        }
                    )
                }
            }
        }
    }
}
