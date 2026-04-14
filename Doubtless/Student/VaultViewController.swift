import UIKit

final class VaultViewController: UIViewController {

    private let subjectControl = UISegmentedControl(items: Subject.allCases.map { $0.rawValue })
    private let datePicker = UIDatePicker()
    private let tableView = UITableView()

    private var allSessions: [Session] = []
    private var filteredSessions: [Session] = []

    private var selectedSubject: Subject = .physics

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Vault"

        setupMockData()
        setupSubjectControl()
        setupDatePicker()
        setupTableView()

        setInitialSelection()
        applyFilters()
    }

    private func setInitialSelection() {
        // Pick a date that actually exists in mock data
        if let firstSession = allSessions.first {
            selectedSubject = firstSession.subject
            subjectControl.selectedSegmentIndex =
                Subject.allCases.firstIndex(of: firstSession.subject) ?? 0

            datePicker.date = firstSession.date
        }
    }

    private func setupMockData() {
        // allSessions = SessionsMockData.allSessions()
        allSessions = []
    }

    private func setupSubjectControl() {
        subjectControl.selectedSegmentIndex = 0
        subjectControl.addTarget(self, action: #selector(subjectChanged), for: .valueChanged)
        subjectControl.translatesAutoresizingMaskIntoConstraints = false

        subjectControl.backgroundColor = .secondarySystemBackground
        subjectControl.selectedSegmentTintColor = .systemBackground
        // 🔤 Text colors
        let normalText: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.systemFont(ofSize: 14, weight: .medium)
        ]

        let selectedText: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.systemOrange,
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
        ]

        subjectControl.setTitleTextAttributes(normalText, for: .normal)
        subjectControl.setTitleTextAttributes(selectedText, for: .selected)

        // 🟠 Rounded pill look
        subjectControl.layer.cornerRadius = 18
        subjectControl.layer.masksToBounds = true

        // ✨ Subtle floating effect (optional, matches your UI nicely)
        subjectControl.layer.shadowColor = UIColor.black.cgColor
        subjectControl.layer.shadowOpacity = 0.05
        subjectControl.layer.shadowOffset = CGSize(width: 0, height: 2)
        subjectControl.layer.shadowRadius = 6

        view.addSubview(subjectControl)

        NSLayoutConstraint.activate([
            subjectControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            subjectControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            subjectControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            subjectControl.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    private func setupDatePicker() {

        // 🧱 Card container (for rounded white background)
        let calendarCard = UIView()
        calendarCard.backgroundColor = .secondarySystemBackground
        calendarCard.layer.cornerRadius = 18
        calendarCard.layer.masksToBounds = false

        // ✨ Soft shadow like your Figma
        calendarCard.layer.shadowColor = UIColor.black.cgColor
        calendarCard.layer.shadowOpacity = 0.06
        calendarCard.layer.shadowOffset = CGSize(width: 0, height: 6)
        calendarCard.layer.shadowRadius = 12

        calendarCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(calendarCard)

        // 📅 Date picker config
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .inline

        // 🟠 Accent color (selected day + arrows)
        datePicker.tintColor = UIColor.systemOrange

        // 🤍 Transparent so card shows through
        datePicker.backgroundColor = .clear

        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        calendarCard.addSubview(datePicker)

        // 📐 Layout
        NSLayoutConstraint.activate([

            // Card position
            calendarCard.topAnchor.constraint(equalTo: subjectControl.bottomAnchor, constant: 16),
            calendarCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            calendarCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Picker inside card
            datePicker.topAnchor.constraint(equalTo: calendarCard.topAnchor, constant: 12),
            datePicker.leadingAnchor.constraint(equalTo: calendarCard.leadingAnchor, constant: 12),
            datePicker.trailingAnchor.constraint(equalTo: calendarCard.trailingAnchor, constant: -12),
            datePicker.bottomAnchor.constraint(equalTo: calendarCard.bottomAnchor, constant: -12)
        ])
    }

    private func setupTableView() {
        tableView.register(VaultSessionCell.self, forCellReuseIdentifier: "VaultSessionCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func subjectChanged() {
        selectedSubject = Subject.allCases[subjectControl.selectedSegmentIndex]
        applyFilters()
    }

    @objc private func dateChanged() {
        applyFilters()
    }

    private func applyFilters() {
        let calendar = Calendar.current
        filteredSessions = allSessions.filter { session in
            session.subject == selectedSubject &&
            calendar.isDate(session.date, inSameDayAs: datePicker.date)
        }
        tableView.reloadData()
    }
}

extension VaultViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredSessions.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "VaultSessionCell",
            for: indexPath
        ) as! VaultSessionCell

        let session = filteredSessions[indexPath.row]
        cell.configure(with: session)

        cell.infoAction = { [weak self] in
            let vc = SessionDetailViewController(session: session)
            vc.modalPresentationStyle = .pageSheet

            if let sheet = vc.sheetPresentationController {
                sheet.detents = [
                    .custom { context in
                        return context.maximumDetentValue * 0.60
                    }
                ]

                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 24
                sheet.largestUndimmedDetentIdentifier = nil
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            }

            self?.present(vc, animated: true)
        }

        return cell
    }
}
