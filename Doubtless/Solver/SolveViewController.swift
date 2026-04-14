import UIKit

final class SolveViewController: UIViewController {

    // MARK: - UI

    private let availabilitySwitch = UISwitch()
    
    private let emptyStateImageView = UIImageView()
    private let emptyStateLabel = UILabel()

    private let tableView = UITableView()
    
    // MARK: - Filter UI
    private let segmentedControl = UISegmentedControl(items: ["All", "Physics", "Chemistry", "Maths"])
    
    private var allDoubts: [DoubtItem] = []
    private var doubts: [DoubtItem] = []
    private var selectedSubject: String? = nil

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupNavigationBar()
        setupFilters()
        setupEmptyState()
        setupTableView()
        updateUI()
    }

    // MARK: - Header

    private func setupNavigationBar() {
        navigationItem.title = "Solve a Doubt"
        availabilitySwitch.onTintColor = .systemBlue

        availabilitySwitch.addTarget(
            self,
            action: #selector(toggleChanged),
            for: .valueChanged
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            customView: availabilitySwitch
        )
    }

    // MARK: - Empty State

    private func setupEmptyState() {
        emptyStateImageView.image = UIImage(named: "solve_placeholder")
        emptyStateImageView.contentMode = .scaleAspectFit
        emptyStateImageView.alpha = 1
        emptyStateLabel.alpha = 1

        emptyStateLabel.text = "Switch to Available to solve doubts"
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.font = .systemFont(ofSize: 18, weight: .medium)
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0

        view.addSubview(emptyStateImageView)
        view.addSubview(emptyStateLabel)

        emptyStateImageView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            emptyStateImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 220),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 220),

            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 24),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }

    // MARK: - Filters

    private func setupFilters() {
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        
        // Setting segmented control appearance to closely match native vibes
        segmentedControl.selectedSegmentTintColor = .systemBlue
        
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        segmentedControl.setTitleTextAttributes(titleTextAttributes, for: .selected)
        
        let defaultTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label]
        segmentedControl.setTitleTextAttributes(defaultTextAttributes, for: .normal)
        
        view.addSubview(segmentedControl)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        // Hide filters initially until switch is On
        segmentedControl.isHidden = true
        segmentedControl.alpha = 0
    }
    
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        let title = sender.titleForSegment(at: sender.selectedSegmentIndex) ?? "All"
        
        if title == "All" {
            selectedSubject = nil
        } else if title == "Maths" {
            selectedSubject = "Mathematics"
        } else {
            selectedSubject = title
        }
        
        applyFilter()
    }
    
    private func applyFilter() {
        if let subject = selectedSubject {
            doubts = allDoubts.filter { $0.subject.lowercased() == subject.lowercased() }
        } else {
            doubts = allDoubts
        }
        tableView.reloadData()
    }

    // MARK: - TableView

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.isHidden = true

        tableView.register(
            SolveDoubtCell.self,
            forCellReuseIdentifier: SolveDoubtCell.identifier
        )

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(
                equalTo: segmentedControl.bottomAnchor,
                constant: 10
            ),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Toggle Logic

    @objc private func toggleChanged() {
        updateUI()

        if availabilitySwitch.isOn {
            startListening()
        } else {
            SupabaseManager.shared.unsubscribeFromDoubts()
        }
    }
    
    private func startListening() {

        SupabaseManager.shared.subscribeToDoubts { [weak self] (dbDoubts: [DoubtDB]) in

            guard let self = self else { return }

            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none

            let newDoubts = dbDoubts.map { (doubt: DoubtDB) -> DoubtItem in
                
                let timeString: String
                if let date = doubt.createdAtDate {
                    timeString = formatter.string(from: date)
                } else {
                    timeString = doubt.created_at
                }

                return DoubtItem(
                    id: doubt.id,
                    name: doubt.student_name,
                    subject: doubt.subject,
                    imageName: "person.circle.fill",
                    studentImageUrl: doubt.student_image_url,
                    time: timeString,
                    description: doubt.description,
                    imageURLs: doubt.image_urls ?? [],
                    language: doubt.language
                )
            }
            
            // Extract IDs to prevent jitter: only reload when list naturally changes
            let oldIds = self.allDoubts.map { $0.id }
            let newIds = newDoubts.map { $0.id }
            
            if oldIds != newIds {
                self.allDoubts = newDoubts
                self.applyFilter()
            }
        }
    }

    private func updateUI() {
        let isAvailable = availabilitySwitch.isOn

        if isAvailable {
            // Fade OUT empty state
            UIView.animate(withDuration: 0.35, animations: {
                self.emptyStateImageView.alpha = 0
                self.emptyStateLabel.alpha = 0
            }) { _ in
                self.emptyStateImageView.isHidden = true
                self.emptyStateLabel.isHidden = true

                // Prepare tableView and filter
                self.tableView.alpha = 0
                self.tableView.isHidden = false
                self.segmentedControl.isHidden = false

                // Fade IN tableView and filter
                UIView.animate(withDuration: 0.35) {
                    self.tableView.alpha = 1
                    self.segmentedControl.alpha = 1
                }
            }
        } else {
            // Fade OUT tableView and filter
            UIView.animate(withDuration: 0.35, animations: {
                self.tableView.alpha = 0
                self.segmentedControl.alpha = 0
            }) { _ in
                self.tableView.isHidden = true
                self.segmentedControl.isHidden = true

                // Prepare empty state
                self.emptyStateImageView.alpha = 0
                self.emptyStateLabel.alpha = 0
                self.emptyStateImageView.isHidden = false
                self.emptyStateLabel.isHidden = false

                // Fade IN empty state
                UIView.animate(withDuration: 0.35) {
                    self.emptyStateImageView.alpha = 1
                    self.emptyStateLabel.alpha = 1
                }
            }
        }
    }
}

// MARK: - TableView

extension SolveViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        // Initial state
        cell.transform = CGAffineTransform(translationX: 0, y: 40)
        cell.alpha = 0

        // Animate
        UIView.animate(
            withDuration: 0.45,
            delay: Double(indexPath.row) * 0.04, // stagger effect
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0.6,
            options: [.curveEaseOut],
            animations: {
                cell.transform = .identity
                cell.alpha = 1
            },
            completion: nil
        )
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        doubts.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: SolveDoubtCell.identifier,
            for: indexPath
        ) as! SolveDoubtCell

        cell.configure(with: doubts[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let doubt = doubts[indexPath.row]
        let detailVC = DoubtDetailViewController(doubt: doubt)
        present(detailVC, animated: true)
    }
}
