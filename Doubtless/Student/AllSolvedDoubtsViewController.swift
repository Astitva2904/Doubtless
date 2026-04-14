import UIKit

// MARK: - AllSolvedDoubtsViewController
/// Shows the full list of solved doubts for the current student.
final class AllSolvedDoubtsViewController: UIViewController {

    // MARK: - Properties
    private var studentName: String
    private var doubtItems: [StudentDoubtItem] = []

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let emptyLabel = UILabel()
    private let refreshControl = UIRefreshControl()

    // MARK: - Init
    init(studentName: String) {
        self.studentName = studentName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Solved Doubts"
        navigationController?.navigationBar.prefersLargeTitles = false

        setupScrollView()
        setupEmptyLabel()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        loadData()
    }

    // MARK: - Setup
    private func setupScrollView() {
        scrollView.alwaysBounceVertical = true
        scrollView.refreshControl = refreshControl
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.layoutMargins = UIEdgeInsets(top: 16, left: 20, bottom: 40, right: 20)
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

    private func setupEmptyLabel() {
        emptyLabel.text = "No solved doubts yet"
        emptyLabel.font = .preferredFont(forTextStyle: .subheadline)
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.isHidden = true
        stackView.addArrangedSubview(emptyLabel)
    }

    // MARK: - Data
    @objc private func refreshData() { loadData() }

    private func loadData() {
        Task {
            do {
                let doubts = try await SupabaseManager.shared.fetchStudentDoubts(
                    studentName: studentName, statusFilter: "solved", limit: 100
                )
                DispatchQueue.main.async {
                    self.doubtItems = doubts
                    self.updateUI()
                    self.refreshControl.endRefreshing()
                }
            } catch {
                print("AllSolvedDoubts load error:", error)
                DispatchQueue.main.async { self.refreshControl.endRefreshing() }
            }
        }
    }

    private func updateUI() {
        // Remove old cells (keep emptyLabel)
        for view in stackView.arrangedSubviews where view !== emptyLabel {
            view.removeFromSuperview()
        }

        if doubtItems.isEmpty {
            emptyLabel.isHidden = false
        } else {
            emptyLabel.isHidden = true
            for item in doubtItems {
                let cell = makeDoubtCell(item)
                stackView.addArrangedSubview(cell)
            }
        }
    }

    // MARK: - Cell Builder (same style as Activity tab)
    private func makeDoubtCell(_ item: StudentDoubtItem) -> UIView {
        let card = UIView()
        let isSolved = (item.status == "completed" || item.status == "solved")
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 12
        card.layer.shadowColor = UIColor.black.withAlphaComponent(0.05).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 4
        card.layer.shadowOffset = CGSize(width: 0, height: 1)

        let subjectLabel = UILabel()
        subjectLabel.text = item.subject
        subjectLabel.font = .systemFont(ofSize: 16, weight: .bold)
        subjectLabel.textColor = .label

        let descLabel = UILabel()
        descLabel.text = "\"\(item.descriptionText)\""
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.textColor = .label
        descLabel.numberOfLines = 2

        let statusBadge = PaddedLabel()
        statusBadge.text = "  ✅ Solved  "
        statusBadge.textColor = .systemGreen
        statusBadge.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
        statusBadge.font = .systemFont(ofSize: 12, weight: .semibold)
        statusBadge.layer.cornerRadius = 8
        statusBadge.clipsToBounds = true

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
}
