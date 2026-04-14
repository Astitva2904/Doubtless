import UIKit

// MARK: - SolverActivityViewController
final class SolverActivityViewController: UIViewController {

    // ──────────────────────────────────────────────
    // MARK: Properties
    // ──────────────────────────────────────────────
    private var solverName: String = ""
    private var stats: SolverStats?
    private var activityItems: [SolverActivityItem] = []
    private var leaderboardEntries: [LeaderboardEntry] = []
    private var isLeaderboardToday = true

    // ──────────────────────────────────────────────
    // MARK: UI Elements
    // ──────────────────────────────────────────────
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    // Stats Card
    private let statsCard = UIView()
    private let solvedTodayValueLabel = UILabel()
    private let ratingValueLabel = UILabel()
    private let totalSolvedValueLabel = UILabel()

    // Recent Activity
    private let activitySectionLabel = UILabel()
    private let recentHeaderStack = UIStackView()
    private let activityStackView = UIStackView()
    private let emptyActivityLabel = UILabel()

    // Leaderboard
    private let leaderboardSectionLabel = UILabel()
    private let segmentedControl = UISegmentedControl(items: ["Today", "All Time"])
    private let leaderboardStackView = UIStackView()
    private let emptyLeaderboardLabel = UILabel()

    // Loading
    private let refreshControl = UIRefreshControl()

    // ──────────────────────────────────────────────
    // MARK: Lifecycle
    // ──────────────────────────────────────────────
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "Activity"
        navigationController?.navigationBar.prefersLargeTitles = false

        setupScrollView()
        setupStatsCard()
        setupRecentActivitySection()
        setupLeaderboardSection()

        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }

    // ──────────────────────────────────────────────
    // MARK: Data Loading
    // ──────────────────────────────────────────────
    private func loadData() {
        Task {
            let solverInfoOpt = try? await SupabaseManager.shared.getCurrentSolverInfo()
            guard let solverInfo = solverInfoOpt else {
                print("SolverActivity load error: No solver info")
                DispatchQueue.main.async { self.refreshControl.endRefreshing() }
                return
            }
            solverName = solverInfo.name

            async let statsResult = try? SupabaseManager.shared.fetchSolverStats(solverName: solverName)
            async let activityResult = try? SupabaseManager.shared.fetchSolverRecentActivity(solverName: solverName)
            async let leaderboardResult = try? SupabaseManager.shared.fetchLeaderboard(
                todayOnly: isLeaderboardToday, currentSolverName: solverName
            )

            let s = await statsResult
            let a = await activityResult ?? []
            let l = await leaderboardResult ?? []

            DispatchQueue.main.async {
                if let s = s {
                    self.stats = s
                }
                self.activityItems = a
                self.leaderboardEntries = l
                self.updateUI()
                self.refreshControl.endRefreshing()
            }
        }
    }

    @objc private func refreshData() {
        loadData()
    }

    // ──────────────────────────────────────────────
    // MARK: UI Update
    // ──────────────────────────────────────────────
    private func updateUI() {
        // Stats
        if let s = stats {
            solvedTodayValueLabel.text = "\(s.solvedToday)"
            ratingValueLabel.text = s.averageRating > 0 ? String(format: "%.1f", s.averageRating) : "–"
            totalSolvedValueLabel.text = "\(s.totalSolved)"
        }

        // Recent Activity
        activityStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if activityItems.isEmpty {
            emptyActivityLabel.isHidden = false
        } else {
            emptyActivityLabel.isHidden = true
            // Only show up to 3 most recent activities in the summary view
            for item in activityItems.prefix(3) {
                let cell = makeSolverActivityCell(item)
                activityStackView.addArrangedSubview(cell)
            }
        }

        // Leaderboard
        updateLeaderboardUI()
    }

    private func updateLeaderboardUI() {
        leaderboardStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if leaderboardEntries.isEmpty {
            emptyLeaderboardLabel.isHidden = false
        } else {
            emptyLeaderboardLabel.isHidden = true
            for entry in leaderboardEntries {
                let row = makeLeaderboardRow(entry)
                leaderboardStackView.addArrangedSubview(row)
            }
        }
    }

    // ──────────────────────────────────────────────
    // MARK: Setup — Scroll View
    // ──────────────────────────────────────────────
    private func setupScrollView() {
        scrollView.alwaysBounceVertical = true
        scrollView.refreshControl = refreshControl
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 40, right: 20)
        stackView.isLayoutMarginsRelativeArrangement = true
        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    // ──────────────────────────────────────────────
    // MARK: Setup — Stats Card
    // ──────────────────────────────────────────────
    private func setupStatsCard() {
        statsCard.backgroundColor = .secondarySystemBackground
        statsCard.layer.cornerRadius = 16
        statsCard.layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        statsCard.layer.shadowOpacity = 1
        statsCard.layer.shadowRadius = 8
        statsCard.layer.shadowOffset = CGSize(width: 0, height: 2)

        // Three columns
        let col1 = makeStatColumn(title: "Solved Today", valueLabel: solvedTodayValueLabel, icon: nil)
        let col2 = makeStatColumn(title: "Rating", valueLabel: ratingValueLabel, icon: "star.fill")
        let col3 = makeStatColumn(title: "Total Solved", valueLabel: totalSolvedValueLabel, icon: nil)

        solvedTodayValueLabel.text = "–"
        ratingValueLabel.text = "–"
        totalSolvedValueLabel.text = "–"

        let gridStack = UIStackView(arrangedSubviews: [col1, col2, col3])
        gridStack.axis = .horizontal
        gridStack.distribution = .fillEqually
        gridStack.spacing = 8
        gridStack.translatesAutoresizingMaskIntoConstraints = false

        statsCard.addSubview(gridStack)
        NSLayoutConstraint.activate([
            gridStack.topAnchor.constraint(equalTo: statsCard.topAnchor, constant: 16),
            gridStack.leadingAnchor.constraint(equalTo: statsCard.leadingAnchor, constant: 16),
            gridStack.trailingAnchor.constraint(equalTo: statsCard.trailingAnchor, constant: -16),
            gridStack.bottomAnchor.constraint(equalTo: statsCard.bottomAnchor, constant: -16)
        ])

        stackView.addArrangedSubview(statsCard)
    }

    private func makeStatColumn(title: String, valueLabel: UILabel, icon: String?) -> UIView {
        let container = UIView()

        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = .preferredFont(forTextStyle: .caption1)
        titleLbl.textColor = .secondaryLabel
        titleLbl.textAlignment = .center

        valueLabel.font = .systemFont(ofSize: 26, weight: .bold)
        valueLabel.textColor = .label
        valueLabel.textAlignment = .center

        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.alignment = .center
        vStack.spacing = 4

        if let iconName = icon {
            // Value + icon side by side
            let iconView = UIImageView(image: UIImage(systemName: iconName))
            iconView.tintColor = .systemOrange
            iconView.contentMode = .scaleAspectFit
            iconView.widthAnchor.constraint(equalToConstant: 18).isActive = true
            iconView.heightAnchor.constraint(equalToConstant: 18).isActive = true

            let hStack = UIStackView(arrangedSubviews: [iconView, valueLabel])
            hStack.axis = .horizontal
            hStack.spacing = 4
            hStack.alignment = .center

            vStack.addArrangedSubview(titleLbl)
            vStack.addArrangedSubview(hStack)
        } else {
            vStack.addArrangedSubview(titleLbl)
            vStack.addArrangedSubview(valueLabel)
        }

        container.addSubview(vStack)
        vStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: container.topAnchor),
            vStack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            vStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            vStack.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        return container
    }

    // ──────────────────────────────────────────────
    // MARK: Setup — Recent Activity
    // ──────────────────────────────────────────────
    private func setupRecentActivitySection() {
        activitySectionLabel.text = "Recent Activity"
        activitySectionLabel.font = .preferredFont(forTextStyle: .headline)
        activitySectionLabel.textColor = .label

        let seeAllButton = UIButton(type: .system)
        seeAllButton.setTitle("See All", for: .normal)
        seeAllButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        seeAllButton.tintColor = .systemBlue
        seeAllButton.addTarget(self, action: #selector(seeAllTapped), for: .touchUpInside)

        recentHeaderStack.axis = .horizontal
        recentHeaderStack.alignment = .center
        recentHeaderStack.addArrangedSubview(activitySectionLabel)
        recentHeaderStack.addArrangedSubview(UIView())
        recentHeaderStack.addArrangedSubview(seeAllButton)
        stackView.addArrangedSubview(recentHeaderStack)

        activityStackView.axis = .vertical
        activityStackView.spacing = 12
        stackView.addArrangedSubview(activityStackView)

        // Empty state
        emptyActivityLabel.text = "No activity yet\nStart solving doubts to see your progress 🚀"
        emptyActivityLabel.font = .preferredFont(forTextStyle: .subheadline)
        emptyActivityLabel.textColor = .secondaryLabel
        emptyActivityLabel.textAlignment = .center
        emptyActivityLabel.numberOfLines = 0
        emptyActivityLabel.isHidden = true
        stackView.addArrangedSubview(emptyActivityLabel)
    }

    @objc private func seeAllTapped() {
        let allVC = SolverAllSolvedDoubtsViewController(solverName: solverName)
        navigationController?.pushViewController(allVC, animated: true)
    }

    // ──────────────────────────────────────────────
    // MARK: Setup — Leaderboard
    // ──────────────────────────────────────────────
    private func setupLeaderboardSection() {
        leaderboardSectionLabel.text = "Leaderboard"
        leaderboardSectionLabel.font = .preferredFont(forTextStyle: .headline)
        leaderboardSectionLabel.textColor = .label
        stackView.addArrangedSubview(leaderboardSectionLabel)

        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.selectedSegmentTintColor = .systemBlue
        let normalAttr: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.label]
        let selectedAttr: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.white]
        segmentedControl.setTitleTextAttributes(normalAttr, for: .normal)
        segmentedControl.setTitleTextAttributes(selectedAttr, for: .selected)
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        stackView.addArrangedSubview(segmentedControl)

        leaderboardStackView.axis = .vertical
        leaderboardStackView.spacing = 8
        stackView.addArrangedSubview(leaderboardStackView)

        // Empty state
        emptyLeaderboardLabel.text = "No leaderboard data yet"
        emptyLeaderboardLabel.font = .preferredFont(forTextStyle: .subheadline)
        emptyLeaderboardLabel.textColor = .secondaryLabel
        emptyLeaderboardLabel.textAlignment = .center
        emptyLeaderboardLabel.isHidden = true
        stackView.addArrangedSubview(emptyLeaderboardLabel)
    }

    @objc private func segmentChanged() {
        isLeaderboardToday = (segmentedControl.selectedSegmentIndex == 0)
        Task {
            do {
                let entries = try await SupabaseManager.shared.fetchLeaderboard(
                    todayOnly: isLeaderboardToday, currentSolverName: solverName
                )
                DispatchQueue.main.async {
                    self.leaderboardEntries = entries
                    self.updateLeaderboardUI()
                }
            } catch {
                print("Leaderboard fetch error:", error)
            }
        }
    }

    // ──────────────────────────────────────────────
    // MARK: Cell Builders
    // ──────────────────────────────────────────────

    private func makeSolverActivityCell(_ item: SolverActivityItem) -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 12
        card.layer.shadowColor = UIColor.black.withAlphaComponent(0.05).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 4
        card.layer.shadowOffset = CGSize(width: 0, height: 1)

        // Subject
        let subjectLabel = UILabel()
        subjectLabel.text = item.subject
        subjectLabel.font = .systemFont(ofSize: 16, weight: .bold)
        subjectLabel.textColor = .label

        // Solved badge
        let solvedBadge = PaddedLabel()
        solvedBadge.text = "  ✓ Solved  "
        solvedBadge.textColor = .systemGreen
        solvedBadge.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
        solvedBadge.font = .systemFont(ofSize: 12, weight: .semibold)
        solvedBadge.layer.cornerRadius = 8
        solvedBadge.clipsToBounds = true

        let topRow = UIStackView(arrangedSubviews: [subjectLabel, UIView(), solvedBadge])
        topRow.axis = .horizontal
        topRow.alignment = .center

        // Feedback text
        let feedbackLabel = UILabel()
        if let fb = item.feedbackText, !fb.isEmpty {
            feedbackLabel.text = "\"\(fb)\""
        } else {
            feedbackLabel.text = "No feedback provided"
        }
        feedbackLabel.font = .systemFont(ofSize: 14)
        feedbackLabel.textColor = .label
        feedbackLabel.numberOfLines = 2

        // Meta Stack
        let metaStack = UIStackView()
        metaStack.axis = .horizontal
        metaStack.spacing = 8
        metaStack.alignment = .center

        if let r = item.rating {
            let ratingLabel = UILabel()
            let starAttachment = NSTextAttachment()
            starAttachment.image = UIImage(systemName: "star.fill")?.withTintColor(.systemOrange, renderingMode: .alwaysOriginal)
            starAttachment.bounds = CGRect(x: 0, y: -2, width: 14, height: 14)
            let ratingStr = NSMutableAttributedString(attachment: starAttachment)
            ratingStr.append(NSAttributedString(string: " \(String(format: "%.1f", r))"))
            ratingLabel.attributedText = ratingStr
            ratingLabel.font = .systemFont(ofSize: 13, weight: .medium)
            ratingLabel.textColor = .label
            metaStack.addArrangedSubview(ratingLabel)
        }

        let timeLabel = UILabel()
        timeLabel.text = item.solvedAt.timeAgoDisplay()
        timeLabel.font = .systemFont(ofSize: 12)
        timeLabel.textColor = .secondaryLabel

        metaStack.addArrangedSubview(UIView())
        metaStack.addArrangedSubview(timeLabel)

        let vStack = UIStackView(arrangedSubviews: [topRow, feedbackLabel, metaStack])
        vStack.axis = .vertical
        vStack.spacing = 6
        vStack.translatesAutoresizingMaskIntoConstraints = false

        // Left accent stripe
        let stripe = UIView()
        stripe.backgroundColor = .systemGreen
        stripe.layer.cornerRadius = 2
        stripe.translatesAutoresizingMaskIntoConstraints = false
        stripe.widthAnchor.constraint(equalToConstant: 4).isActive = true

        let hStack = UIStackView(arrangedSubviews: [stripe, vStack])
        hStack.axis = .horizontal
        hStack.spacing = 10
        hStack.alignment = .fill
        hStack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            hStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            hStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            hStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10)
        ])

        return card
    }

    private func makeLeaderboardRow(_ entry: LeaderboardEntry) -> UIView {
        let row = UIView()
        row.backgroundColor = entry.isCurrentUser
            ? UIColor.systemBlue.withAlphaComponent(0.1)
            : .secondarySystemBackground
        row.layer.cornerRadius = 10

        let rankLabel = UILabel()
        if entry.rank == 1 {
            rankLabel.text = "🥇"
            rankLabel.font = .systemFont(ofSize: 20)
        } else if entry.rank == 2 {
            rankLabel.text = "🥈"
            rankLabel.font = .systemFont(ofSize: 20)
        } else if entry.rank == 3 {
            rankLabel.text = "🥉"
            rankLabel.font = .systemFont(ofSize: 20)
        } else {
            rankLabel.text = "\(entry.rank)."
            rankLabel.font = .systemFont(ofSize: 16, weight: entry.isCurrentUser ? .bold : .medium)
        }
        rankLabel.textColor = .label
        rankLabel.widthAnchor.constraint(equalToConstant: 30).isActive = true

        let avatarView = UIImageView()
        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 20
        avatarView.backgroundColor = .systemGray5
        avatarView.image = UIImage(systemName: "person.circle.fill")?.withTintColor(.systemGray3, renderingMode: .alwaysOriginal)
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        avatarView.heightAnchor.constraint(equalToConstant: 40).isActive = true

        if let urlStr = entry.profileImageURL, let url = URL(string: urlStr) {
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            avatarView.image = image
                        }
                    }
                } catch {
                    print("Failed to load solver avatar:", error)
                }
            }
        }

        let nameLabel = UILabel()
        nameLabel.text = entry.isCurrentUser ? "You" : entry.solverName
        nameLabel.font = .systemFont(ofSize: 16, weight: entry.isCurrentUser ? .bold : .regular)
        nameLabel.textColor = .label

        let countLabel = UILabel()
        countLabel.text = "\(entry.doubtsSolved) doubts"
        countLabel.font = .systemFont(ofSize: 14, weight: .medium)
        countLabel.textColor = .secondaryLabel
        countLabel.textAlignment = .right

        let hStack = UIStackView(arrangedSubviews: [rankLabel, avatarView, nameLabel, UIView(), countLabel])
        hStack.axis = .horizontal
        hStack.spacing = 8
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: row.topAnchor, constant: 12),
            hStack.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 14),
            hStack.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -14),
            hStack.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -12)
        ])

        return row
    }
}

// MARK: - Date Extension (Time Ago)
extension Date {
    func timeAgoDisplay() -> String {
        let seconds = Int(-self.timeIntervalSinceNow)
        if seconds < 60 { return "just now" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        let days = hours / 24
        if days < 7 { return "\(days)d ago" }
        let weeks = days / 7
        return "\(weeks)w ago"
    }
}
