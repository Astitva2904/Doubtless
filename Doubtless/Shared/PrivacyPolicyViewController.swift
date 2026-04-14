import UIKit

/// Displays the full Doubtless Privacy Policy in a scrollable, natively styled screen.
final class PrivacyPolicyViewController: UIViewController {

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    private let handleBar = UIView()
    private let closeButton = UIButton(type: .system)
    private let headerView = UIView()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        setupHeader()
        setupScrollView()
        buildContent()
    }

    // MARK: - Header (Drag Handle + Close)
    private func setupHeader() {
        // Handle bar
        handleBar.backgroundColor = UIColor.separator
        handleBar.layer.cornerRadius = 2.5
        handleBar.translatesAutoresizingMaskIntoConstraints = false

        // Close button
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        let xImage = UIImage(systemName: "xmark", withConfiguration: config)
        closeButton.setImage(xImage, for: .normal)
        closeButton.tintColor = .secondaryLabel
        closeButton.backgroundColor = UIColor.secondarySystemFill
        closeButton.layer.cornerRadius = 15
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        // Title label in header
        let titleLabel = UILabel()
        titleLabel.text = "Privacy Policy"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        headerView.addSubview(handleBar)
        headerView.addSubview(titleLabel)
        headerView.addSubview(closeButton)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            handleBar.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10),
            handleBar.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            handleBar.widthAnchor.constraint(equalToConstant: 40),
            handleBar.heightAnchor.constraint(equalToConstant: 5),

            titleLabel.topAnchor.constraint(equalTo: handleBar.bottomAnchor, constant: 14),
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -12),

            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    // MARK: - Scroll View
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
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

    // MARK: - Build Content
    private func buildContent() {
        // App header
        addTitle("Privacy Policy — Doubtless")
        addMeta("Application Name: Doubtless")
        addMeta("Platform: iOS (Apple iPhone & iPad)")
        addMeta("Last Updated: April 12, 2026")
        addMeta("Effective Date: April 12, 2026")
        addSpacer(24)
        addDivider()

        // Section 1
        addSectionHeader("1. Introduction")
        addBody("""
        Welcome to Doubtless ("we", "our", "us", or the "Company"). Doubtless is a mobile application designed to connect students with qualified solvers (tutors) for real-time academic doubt resolution via live video sessions. This Privacy Policy explains how we collect, use, store, share, and protect your personal information when you use our iOS application and related services (collectively, the "Service").

        By creating an account, accessing, or using Doubtless, you acknowledge that you have read, understood, and agree to be bound by this Privacy Policy. If you do not agree with this Privacy Policy, please do not use the Service.
        """)

        // Section 2
        addSectionHeader("2. Definitions")
        addBullet("Student — A user who posts academic doubts and seeks solutions through the platform.")
        addBullet("Solver — A verified tutor or expert who accepts and resolves student doubts via live video sessions.")
        addBullet("Doubt — An academic question or problem posted by a Student on the platform.")
        addBullet("Session — A live video call between a Student and a Solver to resolve a doubt.")
        addBullet("Creds — The in-app virtual currency used by Students to pay for sessions (1 Cred = ₹1).")
        addBullet("Personal Data — Any information that identifies or can be used to identify an individual.")

        // Section 3
        addSectionHeader("3. Information We Collect")

        addSubSectionHeader("3.1 Information You Provide Directly")

        addSubSectionHeader("3.1.1 Student Account Registration")
        addBody("When you register as a Student, we collect:")
        addBullet("Full Name")
        addBullet("Email Address")
        addBullet("Password (stored in hashed form)")
        addBullet("Mobile Phone Number")
        addBullet("Profile Picture (optional)")

        addSubSectionHeader("3.1.2 Solver Account Registration")
        addBody("When you register as a Solver, we collect:")
        addBullet("Full Name")
        addBullet("Email Address (college mail ID)")
        addBullet("Password (stored in hashed form)")

        addSubSectionHeader("3.1.3 Solver Verification Documents")
        addBody("To verify solver credentials, we collect and store:")
        addBullet("College ID Card (PDF or image)")
        addBullet("JEE Rank Card (PDF or image)")
        addBullet("12th Standard Marksheet (PDF or image)")
        addBullet("College Start and End Dates (month and year)")
        addBullet("Subject(s) of Specialization (Mathematics, Physics, Chemistry)")

        addSubSectionHeader("3.1.4 Profile Information (Editable)")
        addBody("Users may update their profiles with additional information:")
        addBullet("Phone Number")
        addBullet("Address")
        addBullet("Gender (Male, Female, Prefer not to say)")
        addBullet("Current Academic Class (Class 9, 10, 11th, 12th, Dropper)")
        addBullet("Updated Profile Picture")
        addBullet("College / Institute Name (Solver)")

        addSubSectionHeader("3.1.5 Doubt Submissions")
        addBody("When a Student posts a doubt, we collect:")
        addBullet("Subject Category")
        addBullet("Written Description of the doubt")
        addBullet("Images of the doubt")

        addSubSectionHeader("3.1.6 Feedback & Reviews")
        addBody("After each session, we collect:")
        addBullet("Star Rating (1–5 scale)")
        addBullet("Resolution Status (Yes/No)")
        addBullet("Technical Issue Report")
        addBullet("Written Comments (optional)")

        addSubSectionHeader("3.2 Information Collected Automatically")

        addSubSectionHeader("3.2.1 Device & Usage Information")
        addBullet("Device Identifiers (model, OS version)")
        addBullet("App Session Duration & Timestamps")
        addBullet("Feature Usage Patterns")
        addBullet("Error Logs & Crash Reports")

        addSubSectionHeader("3.2.2 Video & Audio Session Data")
        addBullet("Real-time video and audio streams (transmitted between Student and Solver)")
        addBullet("Session Duration (tracked in-app)")
        addBullet("Connection State Logs")
        addSpacer(8)
        addInfoBox("Video and audio streams are transmitted in real-time and are NOT recorded or stored by Doubtless or on our servers. The streams exist only for the duration of the live session.")

        addSubSectionHeader("3.2.3 Payment & Transaction Data")
        addBullet("Creds purchase history and transaction IDs (via Apple In-App Purchase)")
        addBullet("Creds balance and session deduction records")
        addBullet("Solver earnings and withdrawal history")
        addBullet("UPI ID (provided by Solvers for payout withdrawal)")
        addSpacer(8)
        addInfoBox("We do NOT store credit card, debit card, or bank account details. All purchase payments are handled securely by Apple's In-App Purchase. Solver payouts are processed via our secure payout provider using only the UPI ID you provide.")

        addSubSectionHeader("3.2.4 Local Preferences")
        addBullet("Dark Mode preference (UserDefaults)")
        addBullet("Selected Role (Student or Solver)")
        addBullet("Authentication Session Tokens (Supabase SDK)")



        // Section 4
        addSectionHeader("4. How We Use Your Information")

        addSubSectionHeader("4.1 Service Delivery & Core Functionality")
        addBullet("Account Creation & Authentication — To create and manage your user account, verify your identity, and maintain secure login sessions.")
        addBullet("Doubt Posting & Matching — To enable Students to post doubts and match them with available Solvers in real-time.")
        addBullet("Live Video Sessions — To facilitate 1-on-1 video calls between Students and Solvers using the Agora Video SDK.")
        addBullet("Solver Verification — To verify Solver qualifications by reviewing uploaded academic documents.")
        addBullet("Real-Time Notifications — To send notifications about doubt status changes, solver availability, and session updates.")

        addSubSectionHeader("4.2 User Experience & Personalization")
        addBullet("Profile Display — To display your name, profile picture, and institute on the platform.")
        addBullet("Activity Tracking — To show your activity history, including solved doubts and streaks.")
        addBullet("Leaderboards — To feature top-performing Students and Solvers based on doubt statistics.")
        addBullet("Daily Tracker & Streaks — To display your activity streaks and daily engagement patterns.")

        addSubSectionHeader("4.3 Quality Assurance & Safety")
        addBullet("Feedback Analysis — To evaluate Solver performance based on Student ratings and feedback.")
        addBullet("Technical Issue Tracking — To identify and resolve platform technical issues.")
        addBullet("Content Moderation — To monitor uploaded doubt content for appropriateness.")

        addSubSectionHeader("4.4 Communication")
        addBullet("OTP Verification Emails — To send one-time password (OTP) codes for password reset requests.")
        addBullet("Account-Related Notices — To send important account updates and service announcements.")

        addSubSectionHeader("4.5 Legal & Compliance")
        addBullet("To comply with applicable laws, regulations, and legal processes.")
        addBullet("To enforce our Terms of Service.")
        addBullet("To protect the rights, property, or safety of Doubtless, our users, or the public.")

        // Section 5
        addSectionHeader("5. How We Share Your Information")

        addSubSectionHeader("5.1 With Other Users on the Platform")
        addBullet("Student Name & Profile Picture — Displayed to Solvers when a doubt is posted and during sessions.")
        addBullet("Solver Name, Institute & Profile Picture — Displayed to Students when a Solver accepts a doubt and during sessions.")
        addBullet("Star Ratings — Aggregated ratings may be displayed on Solver profiles and leaderboards.")

        addSubSectionHeader("5.2 With Third-Party Service Providers")

        addSubSectionHeader("Supabase (Backend Infrastructure)")
        addBullet("Purpose: Authentication, database storage, file storage, real-time data synchronization, and Edge Functions.")
        addBullet("Data Shared: Account information, doubt records, feedback, uploaded images and documents, OTP codes.")


        addSubSectionHeader("Agora (Video Calling)")
        addBullet("Purpose: Real-time 1-on-1 video and audio calling during doubt-solving sessions.")
        addBullet("Data Shared: Video and audio streams (real-time only, not stored), channel identifiers.")

        addSubSectionHeader("Payout Provider (Solver Payouts)")
        addBullet("Purpose: Processing outgoing payouts to Solvers via UPI.")
        addBullet("Data Shared: Solver name, UPI ID, payout amount, and withdrawal request ID.")

        addSubSectionHeader("5.3 Legal Disclosures")
        addBody("We may disclose your information if required to do so by law, or if we believe in good faith that such disclosure is necessary to:")
        addBullet("Comply with a legal obligation, court order, or regulatory request.")
        addBullet("Protect and defend the rights or property of Doubtless.")
        addBullet("Prevent fraud or address security issues.")
        addBullet("Protect the personal safety of users or the public.")

        addSubSectionHeader("5.4 Business Transfers")
        addBody("In the event of a merger, acquisition, reorganization, bankruptcy, or sale of all or a portion of our assets, your personal information may be transferred as part of that transaction. We will notify you of any such change in ownership or control.")

        addSubSectionHeader("5.5 No Sale of Personal Data")
        addHighlightBox("We do NOT sell, rent, or trade your personal information to third parties for their marketing purposes.")

        // Section 6
        addSectionHeader("6. Data Storage & Security")

        addSubSectionHeader("6.1 Where Your Data Is Stored")
        addBullet("Cloud Backend: User accounts, doubt records, and feedback are stored on Supabase cloud infrastructure.")
        addBullet("File Storage: Profile pictures, doubt images, and solver verification documents are stored in Supabase Storage buckets.")
        addBullet("Local Device Storage: User preferences (dark mode, selected role) and authentication session tokens are stored locally on your iOS device.")

        addSubSectionHeader("6.2 Security Measures")
        addBullet("Encrypted Transit: All data transmitted between the app and our backend is encrypted using HTTPS/TLS.")
        addBullet("Hashed Passwords: User passwords are hashed by Supabase Auth and never stored in plaintext.")
        addBullet("JWT Authentication: API requests are authenticated using JSON Web Tokens issued by Supabase Auth.")
        addBullet("Row-Level Security: Supabase database tables are configured with row-level security policies.")
        addBullet("Temporary OTP Codes: Password reset OTP codes expire after 10 minutes and are marked as used after verification.")
        addBullet("Secure File Upload: Document uploads are transmitted over secure connections with unique file identifiers (UUIDs).")
        addSpacer(8)
        addWarningBox("While we employ commercially reasonable security measures, no method of transmission over the Internet or method of electronic storage is 100% secure. We cannot guarantee the absolute security of your data.")

        // Section 7
        addSectionHeader("7. Data Retention")
        addBullet("Account Information (name, email, mobile) — Retained for as long as your account is active, plus 30 days after account deletion.")
        addBullet("Profile Information (photo, address, gender, class) — Retained for as long as your account is active.")
        addBullet("Doubt Records (subject, description, images) — Retained indefinitely for activity history, leaderboard, and analytics.")
        addBullet("Session Feedback (ratings, comments) — Retained indefinitely for quality assurance.")
        addBullet("Solver Verification Documents — Retained while the Solver account is active plus 90 days after deactivation.")
        addBullet("OTP Codes (password reset) — Expire after 10 minutes; marked as used upon verification.")
        addBullet("Video/Audio Streams — Not stored; exist only during the live session.")
        addBullet("Local Preferences (dark mode, role) — Stored on device until app is uninstalled or data is cleared.")
        addBullet("Creds Transaction Records — Retained for as long as your account is active, plus 90 days after account deletion for audit purposes.")
        addBullet("Solver Earnings & Withdrawal Records — Retained for 7 years after the transaction date for tax and regulatory compliance.")
        addBullet("UPI IDs — Retained only for the duration of payout processing; not stored permanently.")

        // Section 8
        addSectionHeader("8. Your Rights & Choices")

        addSubSectionHeader("8.1 Access & Update Your Data")
        addBullet("You can view and update your profile information at any time through the Edit Profile screen in the app's Settings.")
        addBullet("Solver verification documents can be updated by contacting our support team.")

        addSubSectionHeader("8.2 Account Deletion")
        addBullet("You may request deletion of your account by contacting us at contactusdoubtless@gmail.com.")
        addBody("Upon receiving a verified deletion request, we will:")
        addBullet("Delete your account and personal information from our active databases within 30 days.")
        addBullet("Remove your profile picture and uploaded documents from our storage.")
        addBullet("Retain anonymized records as required for compliance.")

        addSubSectionHeader("8.3 Password Management")
        addBullet("You can change your password at any time through Settings > Account > Change Password.")
        addBullet("Use the Forgot Password flow to receive a 4-digit OTP via email for secure password reset.")

        addSubSectionHeader("8.4 Notification Preferences")
        addBullet("You can manage notification preferences (sound alerts, vibration, doubt reminders) through the Settings screen.")

        addSubSectionHeader("8.5 Appearance Preferences")
        addBullet("Toggle between light and dark mode via Settings > Appearance > Dark Mode.")

        addSubSectionHeader("8.6 Log Out")
        addBullet("You can log out at any time from Settings > Account > Log Out, which will clear your local session data.")



        // Section 9
        addSectionHeader("9. Children's Privacy")
        addBody("""
        Doubtless is intended for use by students who may be minors (including those in Class 9 and above, typically aged 14 years and older).

        We do not knowingly collect personal information from children under the age of 13 without verifiable parental consent. If you are a parent or guardian and believe your child under 13 has provided us with personal information without your consent, please contact us immediately and we will take steps to delete such information.

        For users between the ages of 13 and 18, we recommend that parents or guardians review this Privacy Policy and supervise their child's use of the app.
        """)

        // Section 10
        addSectionHeader("10. Camera & Microphone Permissions")
        addBullet("Camera — To enable live video during doubt-solving sessions and to capture profile photos. Requested when starting a video session or updating profile picture.")
        addBullet("Microphone — To enable live audio during doubt-solving sessions. Requested when starting a video session.")
        addBullet("Photo Library — To select profile pictures and doubt images from your device. Requested when uploading a profile picture or doubt images.")
        addSpacer(8)
        addBody("You may grant or revoke these permissions at any time through your iOS device's Settings > Doubtless. Denying camera or microphone access will prevent you from participating in live video sessions. You can toggle your camera on/off and mute/unmute your microphone during a session using in-app controls.")

        // Section 11
        addSectionHeader("11. Cookies & Tracking Technologies")
        addSubSectionHeader("11.1 No Third-Party Advertising or Analytics SDKs")
        addBody("Doubtless does NOT currently integrate any third-party advertising networks, analytics SDKs (such as Firebase Analytics, Google Analytics, or Mixpanel), or tracking pixels. We do not track you across other apps or websites.")

        // Section 12
        addSectionHeader("12. International Data Transfers")
        addBody("Your data may be processed and stored on servers located outside of India, depending on the infrastructure of our third-party service providers (Supabase, Agora). By using Doubtless, you consent to the transfer of your information to countries that may have different data protection laws than your country of residence. We ensure that such transfers are conducted in compliance with applicable data protection requirements and that appropriate safeguards are in place.")

        // Section 13
        addSectionHeader("13. Changes to This Privacy Policy")
        addBody("We may update this Privacy Policy from time to time to reflect changes in our practices, technology, legal requirements, or other factors. When we make material changes:")
        addBullet("We will update the \"Last Updated\" date at the top of this policy.")
        addBullet("We will notify you through the app or via email for significant changes.")
        addBullet("Continued use of the Service after the effective date of any changes constitutes your acceptance of the updated Privacy Policy.")
        addSpacer(4)
        addBody("We encourage you to review this Privacy Policy periodically to stay informed about how we protect your information.")

        // Section 14
        addSectionHeader("14. Contact Us")
        addBody("If you have any questions, concerns, or requests regarding this Privacy Policy or our data handling practices, please contact us at:")
        addSpacer(8)
        addContactBox()
        addSpacer(8)
        addBody("For data access, correction, or deletion requests, please email us with the subject line: \"Privacy Request — [Your Request Type]\"")
        addSpacer(4)
        addBody("We will respond to all legitimate requests within 30 business days.")

        // Section 15
        addSectionHeader("15. Governing Law")
        addBody("This Privacy Policy shall be governed by and construed in accordance with the laws of India, including but not limited to:")
        addBullet("Information Technology Act, 2000 and its amendments")
        addBullet("Information Technology (Reasonable Security Practices and Procedures and Sensitive Personal Data or Information) Rules, 2011")
        addBullet("Digital Personal Data Protection Act, 2023 (as applicable and when enforced)")
        addSpacer(4)
        addBody("Any disputes arising from this Privacy Policy shall be subject to the exclusive jurisdiction of the courts in India.")

        // Section 16
        addSectionHeader("16. Summary of Third-Party Services")
        addServiceRow(service: "Supabase", purpose: "Authentication, data storage, real-time sync")
        addServiceRow(service: "Agora", purpose: "Live 1-on-1 video sessions")
        addServiceRow(service: "Payout Provider", purpose: "Solver payout processing via UPI")
        addServiceRow(service: "Apple IAP", purpose: "In-app Creds purchases")

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

    private func addSubSectionHeader(_ text: String) {
        addSpacer(14)
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 0
        stackView.addArrangedSubview(label)
        addSpacer(6)
    }

    private func addBody(_ text: String) {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondaryLabel
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
        paragraphStyle.headIndent = 20
        paragraphStyle.firstLineHeadIndent = 0

        let bulletString = "•  \(text)"

        label.attributedText = NSAttributedString(
            string: bulletString,
            attributes: [
                .font: UIFont.systemFont(ofSize: 15, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel,
                .paragraphStyle: paragraphStyle
            ]
        )

        stackView.addArrangedSubview(label)
        addSpacer(4)
    }

    private func addDivider() {
        let divider = UIView()
        divider.backgroundColor = .separator
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        stackView.addArrangedSubview(divider)
    }

    private func addSpacer(_ height: CGFloat) {
        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
        stackView.addArrangedSubview(spacer)
    }

    /// An orange-tinted highlight box for important notices.
    private func addHighlightBox(_ text: String) {
        let container = UIView()
        container.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.1)
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.3).cgColor

        let iconLabel = UILabel()
        iconLabel.text = "⚠️"
        iconLabel.font = .systemFont(ofSize: 18)
        iconLabel.setContentHuggingPriority(.required, for: .horizontal)

        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = .systemFont(ofSize: 14, weight: .medium)
        textLabel.textColor = .label
        textLabel.numberOfLines = 0

        let hStack = UIStackView(arrangedSubviews: [iconLabel, textLabel])
        hStack.axis = .horizontal
        hStack.spacing = 10
        hStack.alignment = .top
        hStack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            hStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14),
            hStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            hStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14)
        ])

        stackView.addArrangedSubview(container)
        addSpacer(8)
    }

    /// A blue-tinted info box.
    private func addInfoBox(_ text: String) {
        let container = UIView()
        container.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.25).cgColor

        let iconLabel = UILabel()
        iconLabel.text = "ℹ️"
        iconLabel.font = .systemFont(ofSize: 18)
        iconLabel.setContentHuggingPriority(.required, for: .horizontal)

        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = .systemFont(ofSize: 14, weight: .medium)
        textLabel.textColor = .label
        textLabel.numberOfLines = 0

        let hStack = UIStackView(arrangedSubviews: [iconLabel, textLabel])
        hStack.axis = .horizontal
        hStack.spacing = 10
        hStack.alignment = .top
        hStack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            hStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14),
            hStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            hStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14)
        ])

        stackView.addArrangedSubview(container)
        addSpacer(8)
    }

    /// A red-tinted warning box.
    private func addWarningBox(_ text: String) {
        let container = UIView()
        container.backgroundColor = UIColor.systemRed.withAlphaComponent(0.08)
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.25).cgColor

        let iconLabel = UILabel()
        iconLabel.text = "🔴"
        iconLabel.font = .systemFont(ofSize: 16)
        iconLabel.setContentHuggingPriority(.required, for: .horizontal)

        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = .systemFont(ofSize: 14, weight: .medium)
        textLabel.textColor = .label
        textLabel.numberOfLines = 0

        let hStack = UIStackView(arrangedSubviews: [iconLabel, textLabel])
        hStack.axis = .horizontal
        hStack.spacing = 10
        hStack.alignment = .top
        hStack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            hStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14),
            hStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            hStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14)
        ])

        stackView.addArrangedSubview(container)
        addSpacer(8)
    }

    /// Contact information card.
    private func addContactBox() {
        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 14

        let titleLabel = UILabel()
        titleLabel.text = "Doubtless Support Team"
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .label

        let emailLabel = UILabel()
        emailLabel.text = "📧  contactusdoubtless@gmail.com"
        emailLabel.font = .systemFont(ofSize: 15)
        emailLabel.textColor = .secondaryLabel

        let vStack = UIStackView(arrangedSubviews: [titleLabel, emailLabel])
        vStack.axis = .vertical
        vStack.spacing = 8
        vStack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(vStack)
        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            vStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
            vStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            vStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])

        stackView.addArrangedSubview(container)
    }

    /// Third-party service summary row.
    private func addServiceRow(service: String, purpose: String) {
        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 10

        let nameLabel = UILabel()
        nameLabel.text = service
        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.setContentHuggingPriority(.required, for: .horizontal)

        let purposeLabel = UILabel()
        purposeLabel.text = purpose
        purposeLabel.font = .systemFont(ofSize: 14)
        purposeLabel.textColor = .secondaryLabel
        purposeLabel.numberOfLines = 0
        purposeLabel.textAlignment = .right

        let hStack = UIStackView(arrangedSubviews: [nameLabel, purposeLabel])
        hStack.axis = .horizontal
        hStack.spacing = 12
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            hStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
            hStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            hStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14)
        ])

        stackView.addArrangedSubview(container)
        addSpacer(6)
    }
}
