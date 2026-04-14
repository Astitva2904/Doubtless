import UIKit
import Auth

final class StudentProfileViewController: UIViewController {

    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let greetingLabel = UILabel()
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let infoLabel = UILabel()

    private let contributionView = UIView()
    private let contributionLabel = UILabel()

    private let topCard = UIView()
    private let bottomCard = UIView()
    


    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        navigationItem.title = "" // Removed "Profile" text
        navigationController?.setNavigationBarHidden(true, animated: false) // Hide standard nav bar for native large title look

        setupScrollView()
        setupProfileSection()
        setupContributionSection()
        setupCards()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        loadUserData()
    }
    
    // MARK: - Greeting Helper
    private func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<8:
            return ["Rise and shine,", "Early bird!", "Fresh start,"].randomElement()!
        case 8..<12:
            return ["Good morning,", "Hello sunshine,", "Ready to learn?"].randomElement()!
        case 12..<14:
            return ["Good afternoon,", "Afternoon grind,", "Lunch break learner,"].randomElement()!
        case 14..<17:
            return ["Keep it up,", "Crushing it,", "Afternoon push,"].randomElement()!
        case 17..<20:
            return ["Good evening,", "Evening study sesh,", "Winding down?"].randomElement()!
        case 20..<23:
            return ["Hey night owl,", "Burning the midnight oil,", "Late night grind,"].randomElement()!
        default:
            return ["Still up?", "Hello night owl,", "Midnight scholar,"].randomElement()!
        }
    }
    

    
    // MARK: - User Data Fetch
    private func loadUserData() {
        Task {
            do {
                if let currentUser = try await SupabaseManager.shared.getCurrentUser(),
                   let nameValue = currentUser.userMetadata["name"] {
                    
                    let name = nameValue.stringValue ?? "Solver"
                    DispatchQueue.main.async {
                        self.nameLabel.text = name
                        // Load class info dynamically
                        if let classInfo = currentUser.userMetadata["class"]?.stringValue, !classInfo.isEmpty {
                            self.infoLabel.text = classInfo
                        }
                    }
                    
                    if let imageURLString = currentUser.userMetadata["profile_image_url"]?.stringValue,
                       let url = URL(string: imageURLString) {
                        do {
                            let (data, _) = try await URLSession.shared.data(from: url)
                            if let image = UIImage(data: data) {
                                DispatchQueue.main.async {
                                    self.profileImageView.image = image
                                }
                            }
                        } catch {
                            print("Failed to load dashboard profile image: \(error)")
                        }
                    }
                    
                    // Fetch real-time streak data (Past 12 Months)
                    do {
                        let daysTotal = 365
                        let stats = try await SupabaseManager.shared.fetchStreakStats(studentName: name, daysBack: daysTotal)
                        
                        DispatchQueue.main.async {
                            self.dailyTrackerView.configure(with: stats, daysTotal: daysTotal)
                        }
                    } catch {
                        print("Failed fetching streak stats:", error)
                    }
                }
            } catch {
                print("Could not load user data:", error)
            }
        }
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

    // MARK: - Profile Section
    private func setupProfileSection() {
        greetingLabel.text = getGreeting()
        greetingLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        greetingLabel.textColor = .secondaryLabel
        
        nameLabel.text = "Student" // Default until fetched
        nameLabel.font = .systemFont(ofSize: 34, weight: .bold)
        nameLabel.textColor = .label
        nameLabel.textAlignment = .left
        
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .systemGray4
        profileImageView.backgroundColor = .systemGray6
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 90

        infoLabel.text = "" // Will be loaded dynamically from user metadata
        infoLabel.font = .systemFont(ofSize: 16)
        infoLabel.textColor = .secondaryLabel
        infoLabel.textAlignment = .center

        [greetingLabel, nameLabel, profileImageView, infoLabel].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            greetingLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            greetingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            greetingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            nameLabel.topAnchor.constraint(equalTo: greetingLabel.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            profileImageView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 32),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 180),
            profileImageView.heightAnchor.constraint(equalToConstant: 180),

            infoLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            infoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }

    // MARK: - Contribution
    private let dailyTrackerView = DailyTrackerView()

    private func setupContributionSection() {
        contributionView.backgroundColor = .clear

        contributionView.addSubview(dailyTrackerView)
        contentView.addSubview(contributionView)

        contributionView.translatesAutoresizingMaskIntoConstraints = false
        dailyTrackerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contributionView.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 16),
            contributionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contributionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            contributionView.heightAnchor.constraint(equalToConstant: 190),

            dailyTrackerView.topAnchor.constraint(equalTo: contributionView.topAnchor),
            dailyTrackerView.bottomAnchor.constraint(equalTo: contributionView.bottomAnchor),
            dailyTrackerView.leadingAnchor.constraint(equalTo: contributionView.leadingAnchor),
            dailyTrackerView.trailingAnchor.constraint(equalTo: contributionView.trailingAnchor)
        ])
        
        // Default empty configuration; loadUserData() will populate this
        let daysTotal = 365 
        dailyTrackerView.configure(with: [:], daysTotal: daysTotal)
    }

    // MARK: - Cards
    private func setupCards() {
        configureCard(topCard)
        configureCard(bottomCard)

        let credsButton = makeRowButton(
            title: "Creds Store",
            icon: "creditcard",
            action: #selector(openCredStore)
        )

        let notificationsButton = makeRowButton(
            title: "Notifications",
            icon: "bell",
            action: #selector(openNotifications)
        )

        let settingsButton = makeRowButton(
            title: "Settings",
            icon: "gear",
            action: #selector(openSettings)
        )

        let helpButton = makeRowButton(
            title: "FAQs",
            icon: "questionmark.circle",
            action: #selector(openFAQs)
        )

        let contactButton = makeRowButton(
            title: "Contact us",
            icon: "phone",
            action: #selector(openContact)
        )

        let privacyButton = makeRowButton(
            title: "Privacy policy",
            icon: "lock",
            action: #selector(openPrivacy)
        )

        let termsButton = makeRowButton(
            title: "Terms of Service",
            icon: "doc.text",
            action: #selector(openTerms)
        )

        let stack1 = UIStackView(arrangedSubviews: [
            credsButton,
            notificationsButton,
            settingsButton
        ])

        let stack2 = UIStackView(arrangedSubviews: [
            helpButton,
            contactButton,
            privacyButton,
            termsButton
        ])

        [stack1, stack2].forEach {
            $0.axis = .vertical
            $0.spacing = 12
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        topCard.addSubview(stack1)
        bottomCard.addSubview(stack2)
        contentView.addSubview(topCard)
        contentView.addSubview(bottomCard)

        NSLayoutConstraint.activate([
            topCard.topAnchor.constraint(equalTo: contributionView.bottomAnchor, constant: 24),
            topCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            topCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            stack1.topAnchor.constraint(equalTo: topCard.topAnchor, constant: 16),
            stack1.leadingAnchor.constraint(equalTo: topCard.leadingAnchor, constant: 16),
            stack1.trailingAnchor.constraint(equalTo: topCard.trailingAnchor, constant: -16),
            stack1.bottomAnchor.constraint(equalTo: topCard.bottomAnchor, constant: -16),

            bottomCard.topAnchor.constraint(equalTo: topCard.bottomAnchor, constant: 16),
            bottomCard.leadingAnchor.constraint(equalTo: topCard.leadingAnchor),
            bottomCard.trailingAnchor.constraint(equalTo: topCard.trailingAnchor),
            bottomCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),

            stack2.topAnchor.constraint(equalTo: bottomCard.topAnchor, constant: 16),
            stack2.leadingAnchor.constraint(equalTo: bottomCard.leadingAnchor, constant: 16),
            stack2.trailingAnchor.constraint(equalTo: bottomCard.trailingAnchor, constant: -16),
            stack2.bottomAnchor.constraint(equalTo: bottomCard.bottomAnchor, constant: -16)
        ])
    }

    // MARK: - Actions
    @objc private func openCredStore() {
        navigationController?.pushViewController(CreditStoreViewController(), animated: true)
    }

    @objc private func openNotifications() {
        navigationController?.pushViewController(StudentNotificationsViewController(), animated: true)
    }


    @objc private func openSettings() {
        navigationController?.pushViewController(StudentSettingsViewController(), animated: true)
    }
    @objc private func openFAQs() {
        navigationController?.pushViewController(FAQViewController(type: .student), animated: true)
    }
    @objc private func openContact() {
        if let url = URL(string: "mailto:contactusdoubtless@gmail.com"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    @objc private func openPrivacy() {
        let privacyVC = PrivacyPolicyViewController()
        privacyVC.modalPresentationStyle = .pageSheet
        if let sheet = privacyVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.preferredCornerRadius = 24
        }
        present(privacyVC, animated: true)
    }
    @objc private func openTerms() {
        let termsVC = TermsOfServiceViewController()
        termsVC.modalPresentationStyle = .pageSheet
        if let sheet = termsVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.preferredCornerRadius = 24
        }
        present(termsVC, animated: true)
    }

    // MARK: - Helpers
    private func makeRowButton(
        title: String,
        value: String? = nil,
        icon: String,
        action: Selector? = nil
    ) -> UIButton {

        let button = UIButton(type: .system)
        button.heightAnchor.constraint(equalToConstant: 52).isActive = true
        button.backgroundColor = .clear
        button.contentHorizontalAlignment = .fill

        if let action {
            button.addTarget(self, action: action, for: .touchUpInside)
        }

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .systemOrange

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = .label

        let spacer = UIView()

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        valueLabel.textColor = .label

        let stack = UIStackView(arrangedSubviews: value == nil
            ? [iconView, titleLabel, spacer]
            : [iconView, titleLabel, spacer, valueLabel])

        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
        stack.isUserInteractionEnabled = false

        button.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            stack.topAnchor.constraint(equalTo: button.topAnchor),
            stack.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])

        return button
    }

    private func configureCard(_ view: UIView) {
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 14
        view.layer.shadowColor = UIColor.black.withAlphaComponent(0.15).cgColor
        view.layer.shadowOpacity = 0.6
        view.layer.shadowRadius = 6
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.translatesAutoresizingMaskIntoConstraints = false
    }

}
