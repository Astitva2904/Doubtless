import UIKit
import Auth

// MARK: - StudentActivityViewController
final class StudentActivityViewController: UIViewController {

    // ──────────────────────────────────────────────
    // MARK: Properties
    // ──────────────────────────────────────────────
    private var studentName: String = ""
    private var stats: StudentStats?
    private var recentSolvedDoubts: [StudentDoubtItem] = []   // Only last 3 solved
    private var topStudents: [TopStudentEntry] = []
    private var topStudentsTimePeriod: String = "All Time"     // Current filter label

    // ──────────────────────────────────────────────
    // MARK: UI Elements
    // ──────────────────────────────────────────────
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    // Overview Card
    private let overviewCard = UIView()
    private let doubtsAskedValueLabel = UILabel()
    private let resolvedValueLabel = UILabel()
    private let avgRatingValueLabel = UILabel()

    // Recent Solved Doubts
    private let recentHeaderStack = UIStackView()
    private let doubtsStackView = UIStackView()
    private let emptyDoubtsLabel = UILabel()

    // Top Students
    private let topStudentsHeaderStack = UIStackView()
    private let topStudentsStackView = UIStackView()
    private let topStudentsFilterButton = UIButton(type: .system)

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
        setupOverviewCard()
        setupRecentSolvedSection()
        setupTopStudentsSection()

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
            do {
                let user = try await SupabaseManager.shared.getCurrentUser()
                if let nameVal = user?.userMetadata["name"]?.stringValue {
                    studentName = nameVal
                }

                async let statsResult = SupabaseManager.shared.fetchStudentStats(studentName: studentName)
                async let solvedResult = SupabaseManager.shared.fetchStudentDoubts(
                    studentName: studentName, statusFilter: "solved", limit: 3
                )
                async let topResult = SupabaseManager.shared.fetchTopStudents(sinceDate: sinceDate(for: topStudentsTimePeriod))

                let (s, d, t) = try await (statsResult, solvedResult, topResult)

                DispatchQueue.main.async {
                    self.stats = s
                    self.recentSolvedDoubts = d
                    self.topStudents = t
                    self.updateUI()
                    self.refreshControl.endRefreshing()
                }
            } catch {
                print("StudentActivity load error:", error)
                DispatchQueue.main.async {
                    self.refreshControl.endRefreshing()
                }
            }
        }
    }

    private func loadTopStudentsOnly() {
        Task {
            do {
                let students = try await SupabaseManager.shared.fetchTopStudents(
                    sinceDate: sinceDate(for: topStudentsTimePeriod)
                )
                DispatchQueue.main.async {
                    self.topStudents = students
                    self.updateTopStudentsUI()
                }
            } catch {
                print("Top students fetch error:", error)
            }
        }
    }

    @objc private func refreshData() {
        loadData()
    }

    // ──────────────────────────────────────────────
    // MARK: Time Period Helper
    // ──────────────────────────────────────────────
    private func sinceDate(for period: String) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        switch period {
        case "Today":
            return calendar.startOfDay(for: now)
        case "This Week":
            return calendar.date(byAdding: .day, value: -7, to: now)
        case "This Month":
            return calendar.date(byAdding: .month, value: -1, to: now)
        default: // "All Time"
            return nil
        }
    }

    // ──────────────────────────────────────────────
    // MARK: UI Update
    // ──────────────────────────────────────────────
    private func updateUI() {
        // Stats
        if let s = stats {
            doubtsAskedValueLabel.text = "\(s.doubtsAsked)"
            resolvedValueLabel.text = "\(s.resolved)"
            avgRatingValueLabel.text = s.averageRating > 0 ? String(format: "%.1f", s.averageRating) : "–"
        }

        updateRecentDoubtsUI()
        updateTopStudentsUI()
    }

    private func updateRecentDoubtsUI() {
        doubtsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if recentSolvedDoubts.isEmpty {
            emptyDoubtsLabel.isHidden = false
        } else {
            emptyDoubtsLabel.isHidden = true
            for item in recentSolvedDoubts {
                let cell = makeDoubtCell(item)
                doubtsStackView.addArrangedSubview(cell)
            }
        }
    }

    private func updateTopStudentsUI() {
        topStudentsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if topStudents.isEmpty {
            let emptyLbl = UILabel()
            emptyLbl.text = "No data for this period"
            emptyLbl.font = .preferredFont(forTextStyle: .subheadline)
            emptyLbl.textColor = .secondaryLabel
            emptyLbl.textAlignment = .center
            topStudentsStackView.addArrangedSubview(emptyLbl)
        } else {
            for student in topStudents {
                let row = makeTopStudentRow(student)
                topStudentsStackView.addArrangedSubview(row)
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
    // MARK: Setup — Overview Card
    // ──────────────────────────────────────────────
    private func setupOverviewCard() {
        overviewCard.backgroundColor = .secondarySystemBackground
        overviewCard.layer.cornerRadius = 16
        overviewCard.layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        overviewCard.layer.shadowOpacity = 1
        overviewCard.layer.shadowRadius = 8
        overviewCard.layer.shadowOffset = CGSize(width: 0, height: 2)

        let col1 = makeStatColumn(title: "Doubts Asked", valueLabel: doubtsAskedValueLabel, icon: nil)
        let col2 = makeStatColumn(title: "Resolved", valueLabel: resolvedValueLabel, icon: nil)
        let col3 = makeStatColumn(title: "Avg Rating", valueLabel: avgRatingValueLabel, icon: "star.fill")

        doubtsAskedValueLabel.text = "–"
        resolvedValueLabel.text = "–"
        avgRatingValueLabel.text = "–"

        let gridStack = UIStackView(arrangedSubviews: [col1, col2, col3])
        gridStack.axis = .horizontal
        gridStack.distribution = .fillEqually
        gridStack.spacing = 8
        gridStack.translatesAutoresizingMaskIntoConstraints = false

        overviewCard.addSubview(gridStack)
        NSLayoutConstraint.activate([
            gridStack.topAnchor.constraint(equalTo: overviewCard.topAnchor, constant: 16),
            gridStack.leadingAnchor.constraint(equalTo: overviewCard.leadingAnchor, constant: 16),
            gridStack.trailingAnchor.constraint(equalTo: overviewCard.trailingAnchor, constant: -16),
            gridStack.bottomAnchor.constraint(equalTo: overviewCard.bottomAnchor, constant: -16)
        ])

        stackView.addArrangedSubview(overviewCard)
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
    // MARK: Setup — Recent Solved Doubts
    // ──────────────────────────────────────────────
    private func setupRecentSolvedSection() {
        // Header: "Recent Solved" ... "See All >"
        let sectionLabel = UILabel()
        sectionLabel.text = "Recent Solved"
        sectionLabel.font = .preferredFont(forTextStyle: .headline)
        sectionLabel.textColor = .label

        let seeAllButton = UIButton(type: .system)
        seeAllButton.setTitle("See All", for: .normal)
        seeAllButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        seeAllButton.tintColor = .systemOrange
        seeAllButton.addTarget(self, action: #selector(seeAllTapped), for: .touchUpInside)

        recentHeaderStack.axis = .horizontal
        recentHeaderStack.alignment = .center
        recentHeaderStack.addArrangedSubview(sectionLabel)
        recentHeaderStack.addArrangedSubview(UIView()) // spacer
        recentHeaderStack.addArrangedSubview(seeAllButton)
        stackView.addArrangedSubview(recentHeaderStack)

        doubtsStackView.axis = .vertical
        doubtsStackView.spacing = 12
        stackView.addArrangedSubview(doubtsStackView)

        emptyDoubtsLabel.text = "No solved doubts yet 🚀"
        emptyDoubtsLabel.font = .preferredFont(forTextStyle: .subheadline)
        emptyDoubtsLabel.textColor = .secondaryLabel
        emptyDoubtsLabel.textAlignment = .center
        emptyDoubtsLabel.numberOfLines = 0
        emptyDoubtsLabel.isHidden = true
        stackView.addArrangedSubview(emptyDoubtsLabel)
    }

    @objc private func seeAllTapped() {
        let allVC = AllSolvedDoubtsViewController(studentName: studentName)
        navigationController?.pushViewController(allVC, animated: true)
    }

    // ──────────────────────────────────────────────
    // MARK: Setup — Top Students
    // ──────────────────────────────────────────────
    private func setupTopStudentsSection() {
        // Header: "Top Students" ... filter button
        let sectionLabel = UILabel()
        sectionLabel.text = "Top Students"
        sectionLabel.font = .preferredFont(forTextStyle: .headline)
        sectionLabel.textColor = .label

        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = .systemOrange
        config.imagePlacement = .trailing
        config.imagePadding = 4
        config.image = UIImage(systemName: "chevron.down")
        
        var attr = AttributeContainer()
        attr.font = .systemFont(ofSize: 14, weight: .semibold)
        config.attributedTitle = AttributedString("All Time", attributes: attr)
        
        topStudentsFilterButton.configuration = config
        topStudentsFilterButton.showsMenuAsPrimaryAction = true
        topStudentsFilterButton.menu = makeTimePeriodMenu()

        topStudentsHeaderStack.axis = .horizontal
        topStudentsHeaderStack.alignment = .center
        topStudentsHeaderStack.addArrangedSubview(sectionLabel)
        topStudentsHeaderStack.addArrangedSubview(UIView()) // spacer
        topStudentsHeaderStack.addArrangedSubview(topStudentsFilterButton)
        stackView.addArrangedSubview(topStudentsHeaderStack)

        topStudentsStackView.axis = .vertical
        topStudentsStackView.spacing = 8
        stackView.addArrangedSubview(topStudentsStackView)
    }

    private func makeTimePeriodMenu() -> UIMenu {
        let periods = ["Today", "This Week", "This Month", "All Time"]
        let actions = periods.map { period in
            UIAction(
                title: period,
                state: period == topStudentsTimePeriod ? .on : .off
            ) { [weak self] _ in
                guard let self = self else { return }
                self.topStudentsTimePeriod = period
                var attr = AttributeContainer()
                attr.font = .systemFont(ofSize: 14, weight: .semibold)
                self.topStudentsFilterButton.configuration?.attributedTitle = AttributedString(period, attributes: attr)
                self.topStudentsFilterButton.menu = self.makeTimePeriodMenu()
                self.loadTopStudentsOnly()
            }
        }
        return UIMenu(title: "Time Period", children: actions)
    }

    // ──────────────────────────────────────────────
    // MARK: Cell Builders
    // ──────────────────────────────────────────────
    private func makeDoubtCell(_ item: StudentDoubtItem) -> UIView {
        let card = UIView()
        let isSolved = (item.status == "completed" || item.status == "solved")
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

        // Description (2 lines)
        let descLabel = UILabel()
        descLabel.text = "\"\(item.descriptionText)\""
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.textColor = .label
        descLabel.numberOfLines = 2

        // Status badge
        let statusBadge = PaddedLabel()
        if isSolved {
            statusBadge.text = "  ✅ Solved  "
            statusBadge.textColor = .systemGreen
            statusBadge.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
        } else if item.status == "accepted" {
            statusBadge.text = "  🔄 In Progress  "
            statusBadge.textColor = .systemBlue
            statusBadge.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        } else {
            statusBadge.text = "  ⏳ Waiting for solver  "
            statusBadge.textColor = .systemOrange
            statusBadge.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.12)
        }
        statusBadge.font = .systemFont(ofSize: 12, weight: .semibold)
        statusBadge.layer.cornerRadius = 8
        statusBadge.clipsToBounds = true

        // Time
        let timeLabel = UILabel()
        timeLabel.text = item.createdAt.timeAgoDisplay()
        timeLabel.font = .systemFont(ofSize: 12)
        timeLabel.textColor = .secondaryLabel

        let topRow = UIStackView(arrangedSubviews: [subjectLabel, UIView(), statusBadge])
        topRow.axis = .horizontal
        topRow.alignment = .center

        let metaStack = UIStackView()
        metaStack.axis = .horizontal
        metaStack.spacing = 8
        metaStack.alignment = .center

        if isSolved {
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
            if let solverN = item.solverName, !solverN.isEmpty {
                let solverLabel = UILabel()
                solverLabel.text = "By \(solverN)"
                solverLabel.font = .systemFont(ofSize: 13, weight: .medium)
                // Use secondaryLabel or darkGray, .label is best readable but let's use .secondaryLabel
                solverLabel.textColor = .secondaryLabel
                metaStack.addArrangedSubview(solverLabel)
            }
        }
        metaStack.addArrangedSubview(UIView())
        metaStack.addArrangedSubview(timeLabel)

        let vStack = UIStackView(arrangedSubviews: [topRow, descLabel, metaStack])
        vStack.axis = .vertical
        vStack.spacing = 6
        vStack.translatesAutoresizingMaskIntoConstraints = false

        // Left accent stripe
        let stripe = UIView()
        stripe.backgroundColor = isSolved ? .systemGreen : (item.status == "accepted" ? .systemBlue : .systemOrange)
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

    private func makeTopStudentRow(_ student: TopStudentEntry) -> UIView {
        let row = UIView()
        row.backgroundColor = .secondarySystemBackground
        row.layer.cornerRadius = 12

        // Rank label
        let rankLabel = UILabel()
        if student.rank == 1 {
            rankLabel.text = "🥇"
            rankLabel.font = .systemFont(ofSize: 20)
        } else if student.rank == 2 {
            rankLabel.text = "🥈"
            rankLabel.font = .systemFont(ofSize: 20)
        } else if student.rank == 3 {
            rankLabel.text = "🥉"
            rankLabel.font = .systemFont(ofSize: 20)
        } else {
            rankLabel.text = "\(student.rank)."
            rankLabel.font = .systemFont(ofSize: 16, weight: .bold)
        }
        rankLabel.textColor = .secondaryLabel
        rankLabel.widthAnchor.constraint(equalToConstant: 28).isActive = true

        // Profile image
        let avatarView = UIImageView()
        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 20
        avatarView.backgroundColor = .systemGray5
        avatarView.image = UIImage(systemName: "person.circle.fill")?.withTintColor(.systemGray3, renderingMode: .alwaysOriginal)
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        avatarView.heightAnchor.constraint(equalToConstant: 40).isActive = true

        // Load profile image async
        if let urlStr = student.profileImageURL, let url = URL(string: urlStr) {
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            avatarView.image = image
                        }
                    }
                } catch {
                    print("Failed to load student avatar:", error)
                }
            }
        }

        // Name
        let nameLabel = UILabel()
        nameLabel.text = student.studentName
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .label

        // Doubts solved count
        let countLabel = UILabel()
        countLabel.text = "\(student.doubtsSolved) solved"
        countLabel.font = .systemFont(ofSize: 14, weight: .medium)
        countLabel.textColor = .systemOrange
        countLabel.textAlignment = .right

        let hStack = UIStackView(arrangedSubviews: [rankLabel, avatarView, nameLabel, UIView(), countLabel])
        hStack.axis = .horizontal
        hStack.spacing = 10
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: row.topAnchor, constant: 10),
            hStack.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 14),
            hStack.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -14),
            hStack.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -10)
        ])

        return row
    }
}
