import UIKit
import Supabase
import Auth

// MARK: - Data Models

struct WithdrawalRow: Codable, Sendable {
    let id: String
    let amount: Double
    let upi_id: String
    let status: String
    let created_at: String
}

/// Professional Solver Earnings & Withdrawal screen.
/// Matches the app's native iOS design language with blue accents.
final class SolverWithdrawalViewController: UIViewController {

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Earnings Card
    private let earningsCard = UIView()
    private let earningsTitleLabel = UILabel()
    private let totalValueLabel = UILabel()
    private let totalUnitLabel = UILabel()
    private let earningsIconView = UIImageView()
    private let pendingRow = UIView()
    private let pendingTitleLabel = UILabel()
    private let pendingValueLabel = UILabel()
    private let sessionsLabel = UILabel()

    // Withdraw Card
    private let withdrawCard = UIView()
    private let withdrawHeaderLabel = UILabel()
    private let upiTextField = UITextField()
    private let withdrawButton = UIButton(type: .system)
    private let withdrawSpinner = UIActivityIndicatorView(style: .medium)
    private let withdrawInfoLabel = UILabel()

    // History Card
    private let historyCard = UIView()
    private let historyHeaderLabel = UILabel()
    private let historyStack = UIStackView()
    private let emptyHistoryLabel = UILabel()

    // MARK: - State
    private var totalEarnings: Double = 0
    private var pendingEarnings: Double = 0

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Earnings"
        navigationController?.navigationBar.prefersLargeTitles = false

        setupLayout()
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    // MARK: - Load Data
    private func loadData() {
        Task {
            do {
                let (total, pending) = try await CreditsManager.shared.fetchSolverEarnings()
                totalEarnings = total
                pendingEarnings = pending
                updateEarningsUI()
            } catch {
                print("Withdrawal: earnings fetch error:", error)
            }

            do {
                let userId = try await SupabaseManager.shared.client.auth.session.user.id.uuidString.lowercased()
                let history: [WithdrawalRow] = try await SupabaseManager.shared.client
                    .from("withdrawal_requests")
                    .select("id, amount, upi_id, status, created_at")
                    .eq("solver_id", value: userId)
                    .order("created_at", ascending: false)
                    .limit(10)
                    .execute()
                    .value
                updateHistoryUI(history)
            } catch {
                print("Withdrawal: history fetch error:", error)
            }
        }
    }

    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .onDrag

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

        setupEarningsCard()
        setupWithdrawCard()
        setupHistoryCard()
    }

    // MARK: - Earnings Card
    private func setupEarningsCard() {
        earningsCard.translatesAutoresizingMaskIntoConstraints = false
        earningsCard.layer.cornerRadius = 20
        earningsCard.clipsToBounds = true

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.systemBlue.cgColor,
            UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 40, height: 200)
        earningsCard.layer.insertSublayer(gradientLayer, at: 0)

        earningsCard.layer.shadowColor = UIColor.systemBlue.withAlphaComponent(0.35).cgColor
        earningsCard.layer.shadowOpacity = 0.8
        earningsCard.layer.shadowRadius = 16
        earningsCard.layer.shadowOffset = CGSize(width: 0, height: 8)

        // Title
        earningsTitleLabel.text = "Total Earnings"
        earningsTitleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        earningsTitleLabel.textColor = .white.withAlphaComponent(0.8)

        // Value
        totalValueLabel.text = "₹0.00"
        totalValueLabel.font = .monospacedDigitSystemFont(ofSize: 42, weight: .bold)
        totalValueLabel.textColor = .white

        // Icon
        earningsIconView.image = UIImage(systemName: "indianrupeesign.circle.fill")
        earningsIconView.tintColor = .white.withAlphaComponent(0.2)
        earningsIconView.contentMode = .scaleAspectFit

        // Divider
        let divider = UIView()
        divider.backgroundColor = .white.withAlphaComponent(0.15)
        divider.translatesAutoresizingMaskIntoConstraints = false

        // Pending row
        pendingTitleLabel.text = "Available to Withdraw"
        pendingTitleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        pendingTitleLabel.textColor = .white.withAlphaComponent(0.75)

        pendingValueLabel.text = "₹0.00"
        pendingValueLabel.font = .monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        pendingValueLabel.textColor = .white

        sessionsLabel.text = "0 sessions"
        sessionsLabel.font = .systemFont(ofSize: 11, weight: .regular)
        sessionsLabel.textColor = .white.withAlphaComponent(0.5)
        sessionsLabel.textAlignment = .right

        [earningsTitleLabel, totalValueLabel, earningsIconView, divider,
         pendingTitleLabel, pendingValueLabel, sessionsLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            earningsCard.addSubview($0)
        }
        contentView.addSubview(earningsCard)

        NSLayoutConstraint.activate([
            earningsCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            earningsCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            earningsCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            earningsCard.heightAnchor.constraint(equalToConstant: 200),

            earningsTitleLabel.topAnchor.constraint(equalTo: earningsCard.topAnchor, constant: 24),
            earningsTitleLabel.leadingAnchor.constraint(equalTo: earningsCard.leadingAnchor, constant: 24),

            totalValueLabel.topAnchor.constraint(equalTo: earningsTitleLabel.bottomAnchor, constant: 6),
            totalValueLabel.leadingAnchor.constraint(equalTo: earningsCard.leadingAnchor, constant: 24),

            earningsIconView.topAnchor.constraint(equalTo: earningsCard.topAnchor, constant: 20),
            earningsIconView.trailingAnchor.constraint(equalTo: earningsCard.trailingAnchor, constant: -20),
            earningsIconView.widthAnchor.constraint(equalToConstant: 60),
            earningsIconView.heightAnchor.constraint(equalToConstant: 60),

            divider.topAnchor.constraint(equalTo: totalValueLabel.bottomAnchor, constant: 16),
            divider.leadingAnchor.constraint(equalTo: earningsCard.leadingAnchor, constant: 24),
            divider.trailingAnchor.constraint(equalTo: earningsCard.trailingAnchor, constant: -24),
            divider.heightAnchor.constraint(equalToConstant: 1),

            pendingTitleLabel.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 14),
            pendingTitleLabel.leadingAnchor.constraint(equalTo: earningsCard.leadingAnchor, constant: 24),

            pendingValueLabel.centerYAnchor.constraint(equalTo: pendingTitleLabel.centerYAnchor),
            pendingValueLabel.trailingAnchor.constraint(equalTo: earningsCard.trailingAnchor, constant: -24),

            sessionsLabel.bottomAnchor.constraint(equalTo: earningsCard.bottomAnchor, constant: -10),
            sessionsLabel.trailingAnchor.constraint(equalTo: earningsCard.trailingAnchor, constant: -24)
        ])
    }

    // MARK: - Withdraw Card
    private func setupWithdrawCard() {
        withdrawCard.backgroundColor = .secondarySystemBackground
        withdrawCard.layer.cornerRadius = 16
        withdrawCard.translatesAutoresizingMaskIntoConstraints = false

        withdrawHeaderLabel.text = "Withdraw to UPI"
        withdrawHeaderLabel.font = .systemFont(ofSize: 20, weight: .bold)
        withdrawHeaderLabel.textColor = .label
        withdrawHeaderLabel.translatesAutoresizingMaskIntoConstraints = false

        // UPI TextField
        upiTextField.placeholder = "Enter UPI ID (e.g. name@upi)"
        upiTextField.font = .systemFont(ofSize: 16)
        upiTextField.borderStyle = .none
        upiTextField.backgroundColor = .tertiarySystemBackground
        upiTextField.layer.cornerRadius = 12
        upiTextField.leftView = makeTextFieldIcon("at")
        upiTextField.leftViewMode = .always
        upiTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        upiTextField.rightViewMode = .always
        upiTextField.autocapitalizationType = .none
        upiTextField.autocorrectionType = .no
        upiTextField.keyboardType = .emailAddress
        upiTextField.translatesAutoresizingMaskIntoConstraints = false

        // Withdraw button
        withdrawButton.setTitle("Withdraw All", for: .normal)
        withdrawButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        withdrawButton.setTitleColor(.white, for: .normal)
        withdrawButton.backgroundColor = .systemBlue
        withdrawButton.layer.cornerRadius = 12
        withdrawButton.translatesAutoresizingMaskIntoConstraints = false
        withdrawButton.addTarget(self, action: #selector(withdrawTapped), for: .touchUpInside)

        withdrawSpinner.hidesWhenStopped = true
        withdrawSpinner.color = .white
        withdrawSpinner.translatesAutoresizingMaskIntoConstraints = false
        withdrawButton.addSubview(withdrawSpinner)

        withdrawInfoLabel.text = "Payouts via UPI typically arrive within 24 hours."
        withdrawInfoLabel.font = .systemFont(ofSize: 12, weight: .regular)
        withdrawInfoLabel.textColor = .tertiaryLabel
        withdrawInfoLabel.numberOfLines = 0
        withdrawInfoLabel.translatesAutoresizingMaskIntoConstraints = false

        [withdrawHeaderLabel, upiTextField, withdrawButton, withdrawInfoLabel].forEach {
            withdrawCard.addSubview($0)
        }
        contentView.addSubview(withdrawCard)

        NSLayoutConstraint.activate([
            withdrawCard.topAnchor.constraint(equalTo: earningsCard.bottomAnchor, constant: 24),
            withdrawCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            withdrawCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            withdrawHeaderLabel.topAnchor.constraint(equalTo: withdrawCard.topAnchor, constant: 20),
            withdrawHeaderLabel.leadingAnchor.constraint(equalTo: withdrawCard.leadingAnchor, constant: 20),

            upiTextField.topAnchor.constraint(equalTo: withdrawHeaderLabel.bottomAnchor, constant: 16),
            upiTextField.leadingAnchor.constraint(equalTo: withdrawCard.leadingAnchor, constant: 16),
            upiTextField.trailingAnchor.constraint(equalTo: withdrawCard.trailingAnchor, constant: -16),
            upiTextField.heightAnchor.constraint(equalToConstant: 48),

            withdrawButton.topAnchor.constraint(equalTo: upiTextField.bottomAnchor, constant: 14),
            withdrawButton.leadingAnchor.constraint(equalTo: withdrawCard.leadingAnchor, constant: 16),
            withdrawButton.trailingAnchor.constraint(equalTo: withdrawCard.trailingAnchor, constant: -16),
            withdrawButton.heightAnchor.constraint(equalToConstant: 48),

            withdrawSpinner.centerXAnchor.constraint(equalTo: withdrawButton.centerXAnchor),
            withdrawSpinner.centerYAnchor.constraint(equalTo: withdrawButton.centerYAnchor),

            withdrawInfoLabel.topAnchor.constraint(equalTo: withdrawButton.bottomAnchor, constant: 12),
            withdrawInfoLabel.leadingAnchor.constraint(equalTo: withdrawCard.leadingAnchor, constant: 20),
            withdrawInfoLabel.trailingAnchor.constraint(equalTo: withdrawCard.trailingAnchor, constant: -20),
            withdrawInfoLabel.bottomAnchor.constraint(equalTo: withdrawCard.bottomAnchor, constant: -16)
        ])
    }

    private func makeTextFieldIcon(_ systemName: String) -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 48))
        let icon = UIImageView(image: UIImage(systemName: systemName))
        icon.tintColor = .tertiaryLabel
        icon.contentMode = .scaleAspectFit
        icon.frame = CGRect(x: 14, y: 14, width: 20, height: 20)
        container.addSubview(icon)
        return container
    }

    // MARK: - History Card
    private func setupHistoryCard() {
        historyCard.backgroundColor = .secondarySystemBackground
        historyCard.layer.cornerRadius = 16
        historyCard.translatesAutoresizingMaskIntoConstraints = false

        historyHeaderLabel.text = "Withdrawal History"
        historyHeaderLabel.font = .systemFont(ofSize: 20, weight: .bold)
        historyHeaderLabel.textColor = .label
        historyHeaderLabel.translatesAutoresizingMaskIntoConstraints = false

        historyStack.axis = .vertical
        historyStack.spacing = 0
        historyStack.translatesAutoresizingMaskIntoConstraints = false

        emptyHistoryLabel.text = "No withdrawals yet.\nStart earning by solving doubts!"
        emptyHistoryLabel.font = .systemFont(ofSize: 14)
        emptyHistoryLabel.textColor = .tertiaryLabel
        emptyHistoryLabel.numberOfLines = 0
        emptyHistoryLabel.textAlignment = .center
        emptyHistoryLabel.translatesAutoresizingMaskIntoConstraints = false

        historyCard.addSubview(historyHeaderLabel)
        historyCard.addSubview(historyStack)
        historyCard.addSubview(emptyHistoryLabel)
        contentView.addSubview(historyCard)

        NSLayoutConstraint.activate([
            historyCard.topAnchor.constraint(equalTo: withdrawCard.bottomAnchor, constant: 24),
            historyCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            historyCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            historyCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),

            historyHeaderLabel.topAnchor.constraint(equalTo: historyCard.topAnchor, constant: 20),
            historyHeaderLabel.leadingAnchor.constraint(equalTo: historyCard.leadingAnchor, constant: 20),

            historyStack.topAnchor.constraint(equalTo: historyHeaderLabel.bottomAnchor, constant: 12),
            historyStack.leadingAnchor.constraint(equalTo: historyCard.leadingAnchor, constant: 16),
            historyStack.trailingAnchor.constraint(equalTo: historyCard.trailingAnchor, constant: -16),
            historyStack.bottomAnchor.constraint(equalTo: historyCard.bottomAnchor, constant: -16),

            emptyHistoryLabel.topAnchor.constraint(equalTo: historyHeaderLabel.bottomAnchor, constant: 20),
            emptyHistoryLabel.leadingAnchor.constraint(equalTo: historyCard.leadingAnchor, constant: 24),
            emptyHistoryLabel.trailingAnchor.constraint(equalTo: historyCard.trailingAnchor, constant: -24),
            emptyHistoryLabel.bottomAnchor.constraint(equalTo: historyCard.bottomAnchor, constant: -24)
        ])
    }

    // MARK: - Update UI
    private func updateEarningsUI() {
        totalValueLabel.text = String(format: "₹%.2f", totalEarnings)
        pendingValueLabel.text = String(format: "₹%.2f", pendingEarnings)

        let sessions = Int(totalEarnings / 20.40)
        sessionsLabel.text = "\(sessions) session\(sessions == 1 ? "" : "s") completed"

        if pendingEarnings >= 1 {
            withdrawButton.setTitle(String(format: "Withdraw ₹%.2f", pendingEarnings), for: .normal)
            withdrawButton.isEnabled = true
            withdrawButton.backgroundColor = .systemBlue
        } else {
            withdrawButton.setTitle("No funds to withdraw", for: .normal)
            withdrawButton.isEnabled = false
            withdrawButton.backgroundColor = .systemGray3
        }

        totalValueLabel.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5) {
            self.totalValueLabel.transform = .identity
        }
    }

    private func updateHistoryUI(_ history: [WithdrawalRow]) {
        historyStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        emptyHistoryLabel.isHidden = !history.isEmpty
        historyStack.isHidden = history.isEmpty

        for item in history {
            let row = makeHistoryRow(item)
            historyStack.addArrangedSubview(row)
        }
    }

    private func makeHistoryRow(_ item: WithdrawalRow) -> UIView {
        let container = UIView()
        container.heightAnchor.constraint(equalToConstant: 58).isActive = true

        let amountLabel = UILabel()
        amountLabel.text = String(format: "₹%.2f", item.amount)
        amountLabel.font = .monospacedDigitSystemFont(ofSize: 16, weight: .semibold)
        amountLabel.textColor = .label
        amountLabel.translatesAutoresizingMaskIntoConstraints = false

        let upiLabel = UILabel()
        upiLabel.text = item.upi_id
        upiLabel.font = .systemFont(ofSize: 12)
        upiLabel.textColor = .secondaryLabel
        upiLabel.translatesAutoresizingMaskIntoConstraints = false

        let statusBadge = UILabel()
        statusBadge.font = .systemFont(ofSize: 11, weight: .bold)
        statusBadge.textAlignment = .center
        statusBadge.layer.cornerRadius = 8
        statusBadge.clipsToBounds = true
        statusBadge.translatesAutoresizingMaskIntoConstraints = false

        switch item.status {
        case "completed":
            statusBadge.text = " ✓ Paid "
            statusBadge.textColor = .systemGreen
            statusBadge.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
        case "processing":
            statusBadge.text = " Processing "
            statusBadge.textColor = .systemBlue
            statusBadge.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        case "failed":
            statusBadge.text = " Failed "
            statusBadge.textColor = .systemRed
            statusBadge.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
        default:
            statusBadge.text = " Pending "
            statusBadge.textColor = .secondaryLabel
            statusBadge.backgroundColor = UIColor.secondaryLabel.withAlphaComponent(0.1)
        }

        let separator = UIView()
        separator.backgroundColor = .separator.withAlphaComponent(0.3)
        separator.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(amountLabel)
        container.addSubview(upiLabel)
        container.addSubview(statusBadge)
        container.addSubview(separator)

        NSLayoutConstraint.activate([
            amountLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            amountLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            upiLabel.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 2),
            upiLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            statusBadge.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            statusBadge.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
            statusBadge.heightAnchor.constraint(equalToConstant: 22),
            separator.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5)
        ])

        return container
    }

    // MARK: - Withdraw Action
    @objc private func withdrawTapped() {
        guard let upiId = upiTextField.text?.trimmingCharacters(in: .whitespaces),
              !upiId.isEmpty else {
            showAlert(title: "UPI ID Required", message: "Please enter your UPI ID (e.g. name@upi, phone@paytm).")
            return
        }

        guard upiId.contains("@") else {
            showAlert(title: "Invalid UPI ID", message: "A valid UPI ID looks like name@bankname or phone@upi.")
            return
        }

        guard pendingEarnings >= 1 else {
            showAlert(title: "Insufficient Balance", message: "You need at least ₹1 in pending earnings to withdraw.")
            return
        }

        let confirmAlert = UIAlertController(
            title: "Confirm Withdrawal",
            message: String(format: "Withdraw ₹%.2f to %@?", pendingEarnings, upiId),
            preferredStyle: .alert
        )
        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        confirmAlert.addAction(UIAlertAction(title: "Withdraw", style: .default) { [weak self] _ in
            self?.processWithdrawal(upiId: upiId)
        })
        present(confirmAlert, animated: true)
    }

    private func processWithdrawal(upiId: String) {
        withdrawButton.setTitle("", for: .normal)
        withdrawSpinner.startAnimating()
        withdrawButton.isEnabled = false
        upiTextField.isEnabled = false

        Task {
            do {
                let userId = try await SupabaseManager.shared.client.auth.session.user.id.uuidString.lowercased()
                let amountToWithdraw = pendingEarnings

                // Create the withdrawal request in the database via RPC
                let _: String = try await SupabaseManager.shared.client
                    .rpc("request_withdrawal", params: [
                        "p_solver_id": AnyJSON.string(userId),
                        "p_upi_id": AnyJSON.string(upiId)
                    ])
                    .execute()
                    .value

                DispatchQueue.main.async {
                    self.showAlert(
                        title: "Payment Requested! 🎉",
                        message: String(format: "₹%.2f will be sent to %@ within 24–48 hours.", amountToWithdraw, upiId)
                    )
                    self.loadData()
                }

            } catch {
                let userMessage: String
                if error.localizedDescription.contains("Insufficient") {
                    userMessage = "You don't have enough pending earnings to withdraw."
                } else {
                    userMessage = "Could not submit your withdrawal request. Please check your connection and try again."
                }
                DispatchQueue.main.async {
                    self.showAlert(title: "Withdrawal Failed", message: userMessage)
                }
            }

            DispatchQueue.main.async {
                self.withdrawButton.setTitle("Withdraw All", for: .normal)
                self.withdrawSpinner.stopAnimating()
                self.withdrawButton.isEnabled = true
                self.upiTextField.isEnabled = true
            }
        }
    }

    // MARK: - Helpers
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let gradient = earningsCard.layer.sublayers?.first as? CAGradientLayer {
            gradient.frame = earningsCard.bounds
        }
    }
}
