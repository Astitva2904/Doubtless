import UIKit

final class MonthYearPickerViewController: UIViewController {

    // MARK: - Public
    var onDone: ((Date) -> Void)?

    // MARK: - Data
    private let months = Calendar.current.monthSymbols
    private let years = Array(1990...2035)

    // MARK: - UI
    private let containerView = UIView()
    private let picker = UIPickerView()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - UI Setup
    private func setupUI() {
        // 🔹 Completely transparent background
        view.backgroundColor = .clear

        // 🔹 White floating card
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 20
        containerView.clipsToBounds = true
        containerView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        containerView.alpha = 0

        view.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false

        // Header
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)

        let titleLabel = UILabel()
        titleLabel.text = "Select Month & Year"
        titleLabel.font = .boldSystemFont(ofSize: 17)
        titleLabel.textAlignment = .center

        let doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)

        let header = UIStackView(arrangedSubviews: [
            cancelButton,
            titleLabel,
            doneButton
        ])
        header.axis = .horizontal
        header.alignment = .center

        cancelButton.widthAnchor.constraint(equalToConstant: 70).isActive = true
        doneButton.widthAnchor.constraint(equalToConstant: 70).isActive = true

        // Divider
        let divider = UIView()
        divider.backgroundColor = UIColor.systemGray5
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true

        // Picker
        picker.dataSource = self
        picker.delegate = self

        // Content stack
        let contentStack = UIStackView(arrangedSubviews: [
            header,
            divider,
            picker
        ])
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        contentStack.isLayoutMarginsRelativeArrangement = true

        containerView.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 320),
            containerView.heightAnchor.constraint(equalToConstant: 300),

            contentStack.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
    }

    // MARK: - Animations
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.5,
                       options: []) {
            self.containerView.alpha = 1
            self.containerView.transform = .identity
        }
    }

    // MARK: - Actions
    @objc private func dismissSelf() {
        UIView.animate(withDuration: 0.2, animations: {
            self.containerView.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            self.dismiss(animated: false)
        }
    }

    @objc private func doneTapped() {
        let monthIndex = picker.selectedRow(inComponent: 0)
        let yearIndex = picker.selectedRow(inComponent: 1)

        var components = DateComponents()
        components.month = monthIndex + 1
        components.year = years[yearIndex]

        let date = Calendar.current.date(from: components) ?? Date()
        onDone?(date)
        dismissSelf()
    }
}

// MARK: - UIPickerView
extension MonthYearPickerViewController: UIPickerViewDataSource, UIPickerViewDelegate {

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 2 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        component == 0 ? months.count : years.count
    }

    func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String? {
        component == 0 ? months[row] : "\(years[row])"
    }

    func pickerView(_ pickerView: UIPickerView,
                    widthForComponent component: Int) -> CGFloat {
        140
    }
}
