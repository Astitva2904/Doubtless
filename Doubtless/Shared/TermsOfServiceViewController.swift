import UIKit

final class TermsOfServiceViewController: UIViewController {

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
        buildContent()
    }

    // MARK: - Layout
    private func setupLayout() {
        // Close button
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .tertiaryLabel
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30)
        ])

        // Scroll view
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    // MARK: - Build Content
    private func buildContent() {
        addTitle("Terms of Service — Doubtless")
        addMeta("Application Name: Doubtless")
        addMeta("Platform: iOS")
        addMeta("Last Updated: April 12, 2026")
        addMeta("Effective Date: April 12, 2026")
        addSpacer(24)
        addDivider()

        // 1. Acceptance
        addSectionHeader("1. Acceptance of Terms")
        addBody("""
        By downloading, installing, or using the Doubtless application ("App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, you must not use the App.

        We reserve the right to update or modify these Terms at any time. Continued use of the App after any modifications constitutes your acceptance of the revised Terms.
        """)

        // 2. Description
        addSectionHeader("2. Description of Service")
        addBody("""
        Doubtless is an academic doubt-resolution platform that connects students with verified solvers (tutors) through real-time one-to-one video sessions. Students use an in-app virtual currency called "Creds" to pay for sessions. Solvers earn real money for completed sessions and can withdraw via UPI.
        """)

        // 3. Eligibility
        addSectionHeader("3. Eligibility")
        addBullet("You must be at least 13 years old to use the App.")
        addBullet("Users between 13 and 18 years of age should use the App under parental or guardian supervision.")
        addBullet("By using the App, you represent that you meet these eligibility requirements.")

        // 4. Account Registration
        addSectionHeader("4. Account Registration")
        addBullet("You must provide accurate and complete information during registration.")
        addBullet("You are responsible for maintaining the confidentiality of your login credentials.")
        addBullet("You are responsible for all activities that occur under your account.")
        addBullet("You must notify us immediately of any unauthorized use of your account.")

        // 5. In-App Purchases & Creds
        addSectionHeader("5. In-App Purchases & Creds")
        addBody("""
        Doubtless uses a virtual currency system called "Creds" (1 Cred = ₹1 in value). Creds are used to pay for doubt-solving sessions.
        """)
        addBullet("New users receive 60 free Creds upon signing up (one-time welcome bonus).")
        addBullet("Additional Creds can be purchased via Apple's In-App Purchase system in packs of 100, 300, or 600.")
        addBullet("Each doubt-solving session costs a flat 30 Creds. Sessions under 2 minutes are free.")
        addBullet("Creds are non-transferable and have no cash value outside the App.")
        addBullet("Creds purchases are final and non-refundable, except as required by Apple's refund policy or applicable law.")
        addBullet("Unused Creds are forfeited upon account deletion.")

        // 6. Solver Earnings & Payouts
        addSectionHeader("6. Solver Earnings & Payouts")
        addBullet("Solvers earn ₹20.40 per completed session (sessions lasting over 2 minutes).")
        addBullet("Earnings accumulate in the solver's in-app wallet.")
        addBullet("Solvers can withdraw earnings via UPI. Payouts are processed through our secure third-party payout provider.")
        addBullet("Minimum withdrawal amount is ₹1.")
        addBullet("Doubtless reserves the right to withhold payouts in case of suspected fraud or Terms violations.")

        // 7. User Conduct
        addSectionHeader("7. User Conduct")
        addBody("You agree NOT to:")
        addBullet("Use the App for any unlawful purpose or in violation of any applicable laws.")
        addBullet("Upload inappropriate, offensive, or non-academic content.")
        addBullet("Harass, abuse, or harm other users during video sessions.")
        addBullet("Attempt to gain unauthorized access to other users' accounts or data.")
        addBullet("Use the App to distribute spam, malware, or any harmful content.")
        addBullet("Impersonate any person or entity, or misrepresent your affiliation.")
        addBullet("Record, screenshot, or distribute video sessions without consent.")
        addBullet("Attempt to manipulate, exploit, or reverse-engineer the Creds system.")

        // 8. Solver Responsibilities
        addSectionHeader("8. Solver Responsibilities")
        addBullet("Solvers must provide accurate academic credentials during verification.")
        addBullet("Solvers must provide genuine, helpful, and accurate academic guidance.")
        addBullet("Solvers must maintain professional conduct during all sessions.")
        addBullet("Fraudulent credentials or misleading academic advice will result in immediate account termination and forfeiture of pending earnings.")

        // 9. Intellectual Property
        addSectionHeader("9. Intellectual Property")
        addBody("""
        All content, features, and functionality of the App — including but not limited to text, graphics, logos, icons, images, and software — are owned by Doubtless and are protected by intellectual property laws. You may not reproduce, distribute, or create derivative works from the App without our explicit written permission.
        """)

        // 10. Content
        addSectionHeader("10. User-Generated Content")
        addBullet("You retain ownership of content you submit (doubt descriptions, images).")
        addBullet("By submitting content, you grant Doubtless a non-exclusive, royalty-free license to use, display, and process your content for the purpose of providing the Service.")
        addBullet("We reserve the right to remove any content that violates these Terms or is deemed inappropriate.")

        // 11. Privacy
        addSectionHeader("11. Privacy")
        addBody("Your use of the App is also governed by our Privacy Policy, which describes how we collect, use, and protect your personal information. Please review our Privacy Policy for details.")

        // 12. Disclaimers
        addSectionHeader("12. Disclaimers")
        addBody("""
        The App is provided on an "AS IS" and "AS AVAILABLE" basis. Doubtless makes no warranties, express or implied, regarding the accuracy, reliability, or completeness of any content provided through the platform.

        We do not guarantee that solutions provided by Solvers are error-free or complete. Doubtless is a facilitation platform and does not take responsibility for the quality of academic guidance provided by individual Solvers.
        """)

        // 13. Limitation of Liability
        addSectionHeader("13. Limitation of Liability")
        addBody("""
        To the maximum extent permitted by applicable law, Doubtless shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of the App, including but not limited to loss of data, academic performance, Creds, or any other intangible losses.
        """)

        // 14. Termination
        addSectionHeader("14. Termination")
        addBullet("You may delete your account at any time through Settings → Delete Account.")
        addBullet("We may suspend or terminate your account at our discretion if you violate these Terms.")
        addBullet("Upon termination, your right to use the App ceases immediately.")
        addBullet("Unused Creds and pending solver earnings are forfeited upon account termination for Terms violations.")
        addBullet("Data deletion will be handled in accordance with our Privacy Policy.")

        // 15. Governing Law
        addSectionHeader("15. Governing Law")
        addBody("These Terms shall be governed by and construed in accordance with the laws of India. Any disputes arising from these Terms shall be subject to the exclusive jurisdiction of the courts in India.")

        // 16. Contact
        addSectionHeader("16. Contact Us")
        addBody("If you have any questions about these Terms, please contact us at:")
        addSpacer(8)
        addContactBox()
        addSpacer(24)
        addDivider()
        addSpacer(16)

        let footerLabel = UILabel()
        footerLabel.text = "© 2026 Doubtless. All rights reserved."
        footerLabel.font = .systemFont(ofSize: 13, weight: .regular)
        footerLabel.textColor = .tertiaryLabel
        footerLabel.textAlignment = .center
        stackView.addArrangedSubview(footerLabel)
    }

    // MARK: - Component Builders

    private func addTitle(_ text: String) {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 26, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        stackView.addArrangedSubview(label)
        addSpacer(8)
    }

    private func addMeta(_ text: String) {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        stackView.addArrangedSubview(label)
        addSpacer(2)
    }

    private func addSectionHeader(_ text: String) {
        addSpacer(24)
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        stackView.addArrangedSubview(label)
        addSpacer(12)
    }

    private func addBody(_ text: String) {
        let label = UILabel()
        label.numberOfLines = 0

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4

        label.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: 15, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel,
                .paragraphStyle: paragraphStyle
            ]
        )

        stackView.addArrangedSubview(label)
        addSpacer(6)
    }

    private func addBullet(_ text: String) {
        let label = UILabel()
        label.numberOfLines = 0

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3
        paragraphStyle.headIndent = 16

        label.attributedText = NSAttributedString(
            string: "•  \(text)",
            attributes: [
                .font: UIFont.systemFont(ofSize: 15, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel,
                .paragraphStyle: paragraphStyle
            ]
        )

        stackView.addArrangedSubview(label)
        addSpacer(4)
    }

    private func addSpacer(_ height: CGFloat) {
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
        stackView.addArrangedSubview(spacer)
    }

    private func addDivider() {
        let line = UIView()
        line.backgroundColor = .separator
        line.translatesAutoresizingMaskIntoConstraints = false
        line.heightAnchor.constraint(equalToConstant: 1).isActive = true
        stackView.addArrangedSubview(line)
    }

    private func addContactBox() {
        let box = UIView()
        box.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
        box.layer.cornerRadius = 12

        let emailLabel = UILabel()
        emailLabel.text = "📧  contactusdoubtless@gmail.com"
        emailLabel.font = .systemFont(ofSize: 15, weight: .medium)
        emailLabel.textColor = .systemBlue
        emailLabel.numberOfLines = 0

        box.addSubview(emailLabel)
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emailLabel.topAnchor.constraint(equalTo: box.topAnchor, constant: 14),
            emailLabel.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 16),
            emailLabel.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -16),
            emailLabel.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -14)
        ])

        stackView.addArrangedSubview(box)
    }
}
