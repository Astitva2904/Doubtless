import UIKit

final class UploadedDoubtsViewController: UIViewController {

    var onAllDoubtsDeleted: (() -> Void)?

    private let tableView = UITableView()

    // Now using Supabase model
    private var doubts: [DoubtDB] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        view.layoutMargins = .zero
        view.preservesSuperviewLayoutMargins = false
        additionalSafeAreaInsets = .zero

        tableView.register(
            UploadedDoubtCell.self,
            forCellReuseIdentifier: UploadedDoubtCell.reuseId
        )

        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 90
        tableView.separatorStyle = .none

        tableView.contentInset = .zero
        tableView.scrollIndicatorInsets = .zero
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.tableHeaderView = UIView(
            frame: CGRect(x: 0, y: 0, width: 0, height: 16)
        )

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // 🔥 Fetch doubts from Supabase
        Task {
            await loadDoubts()
        }
    }

    // MARK: Fetch Doubts

    private func loadDoubts() async {

        do {

            let result = try await SupabaseManager.shared.fetchPendingDoubts()

            DispatchQueue.main.async {
                self.doubts = result
                self.tableView.reloadData()
            }

        } catch {

            print("Fetch error:", error)

        }
    }

    // 🔥 Dynamic popover height
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePreferredSize()
    }

    private func updatePreferredSize() {

        tableView.layoutIfNeeded()

        tableView.layoutIfNeeded()

        let screenHeight = view.window?.bounds.height ?? 800
        let screenWidth = view.window?.bounds.width ?? 393
        let contentHeight = tableView.contentSize.height
        let maxHeight = screenHeight * 0.55
        let finalHeight = min(contentHeight, maxHeight)

        preferredContentSize = CGSize(
            width: screenWidth - 16,
            height: finalHeight
        )

        tableView.isScrollEnabled = contentHeight > maxHeight
    }
}

extension UploadedDoubtsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        doubts.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: UploadedDoubtCell.reuseId,
            for: indexPath
        ) as! UploadedDoubtCell

        let doubt = doubts[indexPath.row]

        // Convert DB model → UI model
        let uiDoubt = Doubt(
            id: doubt.id,
            studentName: doubt.student_name,
            subject: doubt.subject,
            description: doubt.description,
            image: nil,
            uploadedAt: doubt.createdAtDate
        )

        cell.configure(with: uiDoubt)

        cell.onCancel = { [weak self] in

            guard let self else { return }

            self.doubts.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)

            DispatchQueue.main.async {

                if self.doubts.isEmpty {
                    self.onAllDoubtsDeleted?()
                    self.dismiss(animated: true)
                } else {
                    self.updatePreferredSize()
                }
            }
        }

        return cell
    }

    func tableView(
        _ tableView: UITableView,
        heightForFooterInSection section: Int
    ) -> CGFloat {
        .leastNormalMagnitude
    }
}
