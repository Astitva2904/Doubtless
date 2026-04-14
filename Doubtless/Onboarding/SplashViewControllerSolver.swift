import UIKit

final class SplashViewControllerSolver: UIViewController {
    
    enum AppColors {
        static let onboardingBlue =
            UIColor(red: 0.85, green: 0.97, blue: 1.0, alpha: 1)
    }

    // MARK: - UI
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
        view.backgroundColor = UIColor(red: 0.851, green: 0.969, blue: 1.0, alpha: 1)

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
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {

            let onboardingVC = SolverOnboardingViewController()

            // Ensure same background (prevents black flash)
            onboardingVC.view.backgroundColor = AppColors.onboardingBlue

            // Fade transition using CATransition
            let transition = CATransition()
            transition.type = .fade
            transition.duration = 0.9
            transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            self.navigationController?.view.layer.add(transition, forKey: nil)
            self.navigationController?.pushViewController(onboardingVC, animated: false)
        }
    }
}
