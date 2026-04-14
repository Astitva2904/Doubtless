import UIKit
import StoreKit

/// Premium credit store screen where students can purchase Creds.
/// Uses the student's signature orange theme.
final class CreditStoreViewController: UIViewController {

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Balance
    private let balanceCard = UIView()
    private let balanceTitleLabel = UILabel()
    private let balanceValueLabel = UILabel()
    private let balanceUnitLabel = UILabel()
    private let balanceIconView = UIImageView()

    // Loading / Error state for packs
    private let packsSpinner = UIActivityIndicatorView(style: .medium)
    private let packsErrorLabel = UILabel()
    private let retryButton = UIButton(type: .system)

    // Packs
    private let packsHeaderLabel = UILabel()
    private let packsStack = UIStackView()

    // Info
    private let infoCard = UIView()

    // MARK: - State
    private var currentBalance: Int = 0
    private var products: [Product] = []

    // Pack definitions
    private let packDefinitions: [(id: String, creds: Int, sessions: String, badge: String?)] = [
        (StoreKitManager.creds100, 100, "~3 sessions", nil),
        (StoreKitManager.creds300, 300, "~10 sessions", "Popular"),
        (StoreKitManager.creds600, 600, "~20 sessions", "Best Value")
    ]

    // MARK: - Theme Color
    private let accentColor = UIColor.systemOrange

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Creds Store"
        navigationController?.navigationBar.prefersLargeTitles = false

        setupLayout()
        loadData()

        NotificationCenter.default.addObserver(
            self, selector: #selector(creditsUpdated),
            name: .creditsDidUpdate, object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Load Data
    private func loadData() {
        // Show spinner while loading
        packsSpinner.startAnimating()
        packsSpinner.isHidden = false
        packsErrorLabel.isHidden = true
        retryButton.isHidden = true

        Task {
            do {
                currentBalance = try await CreditsManager.shared.fetchBalance()
                updateBalanceUI()
            } catch {
                print("CreditStore: balance fetch error:", error)
            }

            await StoreKitManager.shared.fetchProducts()
            products = StoreKitManager.shared.products

            packsSpinner.stopAnimating()
            packsSpinner.isHidden = true

            if products.isEmpty {
                packsErrorLabel.text = "Unable to load prices.\nPlease check your connection and try again."
                packsErrorLabel.isHidden = false
                retryButton.isHidden = false
            } else {
                packsErrorLabel.isHidden = true
                retryButton.isHidden = true
                rebuildPackCards()
            }
        }
    }

    @objc private func creditsUpdated() {
        Task {
            currentBalance = try await CreditsManager.shared.fetchBalance()
            updateBalanceUI()
        }
    }

    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
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

        setupBalanceCard()
        setupPacksSection()
        setupInfoCard()
    }

    // MARK: - Balance Card (Orange Gradient)
    private func setupBalanceCard() {
        balanceCard.translatesAutoresizingMaskIntoConstraints = false
        balanceCard.layer.cornerRadius = 20
        balanceCard.clipsToBounds = true

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.systemOrange.cgColor,
            UIColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 40, height: 150)
        balanceCard.layer.insertSublayer(gradientLayer, at: 0)

        balanceCard.layer.shadowColor = UIColor.systemOrange.withAlphaComponent(0.35).cgColor
        balanceCard.layer.shadowOpacity = 0.8
        balanceCard.layer.shadowRadius = 16
        balanceCard.layer.shadowOffset = CGSize(width: 0, height: 8)

        balanceTitleLabel.text = "Your Balance"
        balanceTitleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        balanceTitleLabel.textColor = .white.withAlphaComponent(0.85)

        balanceValueLabel.text = "..."
        balanceValueLabel.font = .monospacedDigitSystemFont(ofSize: 48, weight: .bold)
        balanceValueLabel.textColor = .white

        balanceUnitLabel.text = "Creds"
        balanceUnitLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        balanceUnitLabel.textColor = .white.withAlphaComponent(0.7)

        balanceIconView.image = UIImage(systemName: "creditcard.fill")
        balanceIconView.tintColor = .white.withAlphaComponent(0.2)
        balanceIconView.contentMode = .scaleAspectFit

        [balanceTitleLabel, balanceValueLabel, balanceUnitLabel, balanceIconView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            balanceCard.addSubview($0)
        }
        contentView.addSubview(balanceCard)

        NSLayoutConstraint.activate([
            balanceCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            balanceCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            balanceCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            balanceCard.heightAnchor.constraint(equalToConstant: 150),

            balanceTitleLabel.topAnchor.constraint(equalTo: balanceCard.topAnchor, constant: 24),
            balanceTitleLabel.leadingAnchor.constraint(equalTo: balanceCard.leadingAnchor, constant: 24),

            balanceValueLabel.topAnchor.constraint(equalTo: balanceTitleLabel.bottomAnchor, constant: 8),
            balanceValueLabel.leadingAnchor.constraint(equalTo: balanceCard.leadingAnchor, constant: 24),

            balanceUnitLabel.lastBaselineAnchor.constraint(equalTo: balanceValueLabel.lastBaselineAnchor),
            balanceUnitLabel.leadingAnchor.constraint(equalTo: balanceValueLabel.trailingAnchor, constant: 8),

            balanceIconView.centerYAnchor.constraint(equalTo: balanceCard.centerYAnchor),
            balanceIconView.trailingAnchor.constraint(equalTo: balanceCard.trailingAnchor, constant: -24),
            balanceIconView.widthAnchor.constraint(equalToConstant: 56),
            balanceIconView.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    // MARK: - Packs Section
    private func setupPacksSection() {
        packsHeaderLabel.text = "Buy Creds"
        packsHeaderLabel.font = .systemFont(ofSize: 22, weight: .bold)
        packsHeaderLabel.textColor = .label
        packsHeaderLabel.translatesAutoresizingMaskIntoConstraints = false

        packsStack.axis = .vertical
        packsStack.spacing = 14
        packsStack.translatesAutoresizingMaskIntoConstraints = false

        // Spinner shown while products load
        packsSpinner.hidesWhenStopped = true
        packsSpinner.color = accentColor
        packsSpinner.translatesAutoresizingMaskIntoConstraints = false

        // Error label for when products can't be fetched
        packsErrorLabel.text = "Unable to load prices."
        packsErrorLabel.font = .systemFont(ofSize: 14, weight: .medium)
        packsErrorLabel.textColor = .secondaryLabel
        packsErrorLabel.textAlignment = .center
        packsErrorLabel.numberOfLines = 0
        packsErrorLabel.isHidden = true
        packsErrorLabel.translatesAutoresizingMaskIntoConstraints = false

        // Retry button
        var retryConfig = UIButton.Configuration.tinted()
        retryConfig.baseBackgroundColor = accentColor
        retryConfig.baseForegroundColor = accentColor
        retryConfig.title = "Retry"
        retryConfig.image = UIImage(systemName: "arrow.clockwise")
        retryConfig.imagePadding = 6
        retryConfig.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20)
        retryButton.configuration = retryConfig
        retryButton.isHidden = true
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.addTarget(self, action: #selector(retryLoadProducts), for: .touchUpInside)

        contentView.addSubview(packsHeaderLabel)
        contentView.addSubview(packsStack)
        contentView.addSubview(packsSpinner)
        contentView.addSubview(packsErrorLabel)
        contentView.addSubview(retryButton)

        NSLayoutConstraint.activate([
            packsHeaderLabel.topAnchor.constraint(equalTo: balanceCard.bottomAnchor, constant: 28),
            packsHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),

            packsSpinner.topAnchor.constraint(equalTo: packsHeaderLabel.bottomAnchor, constant: 30),
            packsSpinner.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            packsErrorLabel.topAnchor.constraint(equalTo: packsHeaderLabel.bottomAnchor, constant: 24),
            packsErrorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            packsErrorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),

            retryButton.topAnchor.constraint(equalTo: packsErrorLabel.bottomAnchor, constant: 14),
            retryButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            packsStack.topAnchor.constraint(equalTo: packsHeaderLabel.bottomAnchor, constant: 14),
            packsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            packsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }

    @objc private func retryLoadProducts() {
        loadData()
    }

    private func rebuildPackCards() {
        packsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for def in packDefinitions {
            let product = products.first(where: { $0.id == def.id })
            let card = makePackCard(
                creds: def.creds,
                sessions: def.sessions,
                price: product?.displayPrice,
                badge: def.badge,
                productId: def.id
            )
            packsStack.addArrangedSubview(card)
        }
    }

    private func makePackCard(creds: Int, sessions: String, price: String?, badge: String?, productId: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 16
        card.translatesAutoresizingMaskIntoConstraints = false
        card.clipsToBounds = false

        // Left: cred icon
        let iconBg = UIView()
        iconBg.backgroundColor = accentColor.withAlphaComponent(0.12)
        iconBg.layer.cornerRadius = 22
        iconBg.translatesAutoresizingMaskIntoConstraints = false

        let iconImg = UIImageView(image: UIImage(systemName: "c.circle.fill"))
        iconImg.tintColor = accentColor
        iconImg.contentMode = .scaleAspectFit
        iconImg.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(iconImg)

        // Text
        let credLabel = UILabel()
        credLabel.text = "\(creds) Creds"
        credLabel.font = .systemFont(ofSize: 17, weight: .bold)
        credLabel.textColor = .label

        let sessionLabel = UILabel()
        sessionLabel.text = sessions
        sessionLabel.font = .systemFont(ofSize: 12, weight: .regular)
        sessionLabel.textColor = .secondaryLabel

        let textStack = UIStackView(arrangedSubviews: [credLabel, sessionLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        // Buy button with price
        let buyBtn = UIButton(type: .system)
        var btnConfig = UIButton.Configuration.filled()
        btnConfig.baseBackgroundColor = accentColor
        btnConfig.baseForegroundColor = .white
        let attrTitle = AttributedString(price ?? "Loading...", attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 14, weight: .bold)]))
        btnConfig.attributedTitle = attrTitle
        btnConfig.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 18)
        buyBtn.configuration = btnConfig
        
        buyBtn.layer.cornerRadius = 16
        buyBtn.clipsToBounds = true
        buyBtn.translatesAutoresizingMaskIntoConstraints = false
        buyBtn.tag = creds
        buyBtn.accessibilityIdentifier = productId
        buyBtn.addTarget(self, action: #selector(packBuyTapped(_:)), for: .touchUpInside)

        card.addSubview(iconBg)
        card.addSubview(textStack)
        card.addSubview(buyBtn)

        // Badge
        if let badgeText = badge {
            let badgeLabel = UILabel()
            badgeLabel.text = "  \(badgeText)  "
            badgeLabel.font = .systemFont(ofSize: 9, weight: .bold)
            badgeLabel.textColor = .white
            badgeLabel.backgroundColor = accentColor
            badgeLabel.layer.cornerRadius = 6
            badgeLabel.clipsToBounds = true
            badgeLabel.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(badgeLabel)

            NSLayoutConstraint.activate([
                badgeLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
                badgeLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
                badgeLabel.heightAnchor.constraint(equalToConstant: 16)
            ])
        }

        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 76),

            iconBg.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iconBg.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            iconBg.widthAnchor.constraint(equalToConstant: 44),
            iconBg.heightAnchor.constraint(equalToConstant: 44),

            iconImg.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            iconImg.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            iconImg.widthAnchor.constraint(equalToConstant: 24),
            iconImg.heightAnchor.constraint(equalToConstant: 24),

            textStack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            textStack.leadingAnchor.constraint(equalTo: iconBg.trailingAnchor, constant: 14),

            buyBtn.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            buyBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            buyBtn.heightAnchor.constraint(equalToConstant: 32)
        ])

        return card
    }

    // MARK: - Info Card
    private func setupInfoCard() {
        infoCard.backgroundColor = .secondarySystemBackground
        infoCard.layer.cornerRadius = 16
        infoCard.translatesAutoresizingMaskIntoConstraints = false

        let infoHeaderLabel = UILabel()
        infoHeaderLabel.text = "How Creds Work"
        infoHeaderLabel.font = .systemFont(ofSize: 20, weight: .bold)
        infoHeaderLabel.textColor = .label
        infoHeaderLabel.translatesAutoresizingMaskIntoConstraints = false

        let infoStack = UIStackView()
        infoStack.axis = .vertical
        infoStack.spacing = 16
        infoStack.translatesAutoresizingMaskIntoConstraints = false

        let items: [(String, String)] = [
            ("gift.fill", "Get 60 free Creds when you sign up"),
            ("book.fill", "Each doubt session costs 30 Creds"),
            ("clock.fill", "Sessions under 2 minutes are free"),
            ("cart.fill", "Buy more Creds anytime from this store")
        ]

        for (icon, text) in items {
            let row = makeInfoRow(icon: icon, text: text)
            infoStack.addArrangedSubview(row)
        }

        infoCard.addSubview(infoHeaderLabel)
        infoCard.addSubview(infoStack)
        contentView.addSubview(infoCard)

        NSLayoutConstraint.activate([
            infoCard.topAnchor.constraint(equalTo: packsStack.bottomAnchor, constant: 28),
            infoCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            infoCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            infoCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),

            infoHeaderLabel.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 20),
            infoHeaderLabel.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 20),

            infoStack.topAnchor.constraint(equalTo: infoHeaderLabel.bottomAnchor, constant: 16),
            infoStack.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 20),
            infoStack.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -20),
            infoStack.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -20)
        ])
    }

    private func makeInfoRow(icon: String, text: String) -> UIView {
        let container = UIView()

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = accentColor
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = .systemFont(ofSize: 14, weight: .medium)
        textLabel.textColor = .secondaryLabel
        textLabel.numberOfLines = 0
        textLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(iconView)
        container.addSubview(textLabel)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),
            textLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            textLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textLabel.topAnchor.constraint(equalTo: container.topAnchor),
            textLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    // MARK: - Update UI
    private func updateBalanceUI() {
        balanceValueLabel.text = "\(currentBalance)"
        balanceValueLabel.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5) {
            self.balanceValueLabel.transform = .identity
        }
    }

    // MARK: - Actions
    @objc private func packBuyTapped(_ sender: UIButton) {
        guard let productId = sender.accessibilityIdentifier,
              let product = products.first(where: { $0.id == productId }) else {
            showAlert(title: "Store Unavailable", message: "Unable to connect to the App Store. Please try again later.")
            return
        }

        let originalTitle = sender.title(for: .normal)
        sender.setTitle("...", for: .normal)
        sender.isEnabled = false

        Task {
            do {
                let success = try await StoreKitManager.shared.purchase(product)
                if success {
                    currentBalance = try await CreditsManager.shared.fetchBalance()
                    updateBalanceUI()
                    showAlert(title: "Purchase Successful! 🎉", message: "\(sender.tag) Creds have been added to your balance.")
                }
            } catch {
                showAlert(title: "Purchase Failed", message: error.localizedDescription)
            }

            sender.setTitle(originalTitle, for: .normal)
            sender.isEnabled = true
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Gradient Fix
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let gradient = balanceCard.layer.sublayers?.first as? CAGradientLayer {
            gradient.frame = balanceCard.bounds
        }
    }
}
