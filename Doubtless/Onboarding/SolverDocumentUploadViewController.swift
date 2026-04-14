import UIKit
import UniformTypeIdentifiers
import Supabase
import Auth

final class SolverDocumentUploadViewController: UIViewController,
                                                UIDocumentPickerDelegate {

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stack = UIStackView()

    private let startDateButton = UIButton(type: .system)
    private let endDateButton = UIButton(type: .system)

    private let submitButton = UIButton(type: .system)

    // MARK: - Upload labels
    private let collegeIDLabel = UILabel()
    private let jeeLabel = UILabel()
    private let marksheetLabel = UILabel()

    // MARK: - Enums
    private enum DateType { case start, end }
    private enum UploadType { case collegeID, jee, marksheet }

    private var activeDateType: DateType?
    private var activeUploadType: UploadType?

    // MARK: - Validation State
    private var selectedStartDate: Date?
    private var selectedEndDate: Date?

    private var selectedSubjects: Set<String> = []

    private var uploadedCollegeID: URL?
    private var uploadedJEE: URL?
    private var uploadedMarksheet: URL?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = UIColor(red: 0.90, green: 0.97, blue: 1.0, alpha: 1)
        
        navigationItem.hidesBackButton = true
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupUI()
        setupCustomCancelButton()
        validateForm()
    }
    
    // MARK: - Custom Cancel Button
    private func setupCustomCancelButton() {
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = .systemBlue
        config.image = UIImage(systemName: "chevron.left", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))
        config.imagePadding = 4
        
        var attr = AttributeContainer()
        attr.font = .systemFont(ofSize: 17, weight: .semibold)
        config.attributedTitle = AttributedString("Cancel", attributes: attr)
        
        let cancelBtn = UIButton(configuration: config)
        cancelBtn.addTarget(self, action: #selector(cancelSignup), for: .touchUpInside)
        
        view.addSubview(cancelBtn)
        cancelBtn.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cancelBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            cancelBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        ])
    }

    // MARK: - Setup
    private func setupUI() {
        setupScroll()
        setupStack()
        setupTitle()
        setupDateCards()
        setupSubjects()
        setupUploads()
        setupSubmit()
    }

    private func setupScroll() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    private func setupStack() {
        stack.axis = .vertical
        stack.spacing = 24

        contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 60), // Extra top padding for the custom Cancel button
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    private func setupTitle() {
        let title = UILabel()
        title.text = "Upload Required Documents"
        title.font = .boldSystemFont(ofSize: 24)
        title.textAlignment = .center
        stack.addArrangedSubview(title)
        
        let subtitle = UILabel()
        subtitle.text = "Complete your registration by uploading the documents below."
        subtitle.font = .systemFont(ofSize: 15)
        subtitle.textColor = .darkGray
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0
        stack.addArrangedSubview(subtitle)
    }


    // MARK: - Date Cards
    private func setupDateCards() {
        stack.addArrangedSubview(card(dateRow(title: "Starting month of college", button: startDateButton, type: .start)))
        stack.addArrangedSubview(card(dateRow(title: "Ending month of college", button: endDateButton, type: .end)))
    }

    // MARK: - Subjects
    private func setupSubjects() {
        let title = UILabel()
        title.text = "Choose subject(s) of specialization"
        title.font = .boldSystemFont(ofSize: 16)

        let subjects = ["Mathematics", "Physics", "Chemistry"].map(subjectPill)

        let vStack = UIStackView(arrangedSubviews: subjects)
        vStack.axis = .vertical
        vStack.spacing = 12

        let content = UIStackView(arrangedSubviews: [title, vStack])
        content.axis = .vertical
        content.spacing = 16

        stack.addArrangedSubview(card(content))
    }

    private func subjectPill(title: String) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.cornerStyle = .capsule
        config.baseBackgroundColor = UIColor(white: 0.93, alpha: 1)
        config.baseForegroundColor = .systemBlue

        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(toggleSubject(_:)), for: .touchUpInside)
        return button
    }

    @objc private func toggleSubject(_ sender: UIButton) {
        guard let title = sender.configuration?.title else { return }

        sender.isSelected.toggle()

        if sender.isSelected {
            selectedSubjects.insert(title)
            sender.configuration?.baseBackgroundColor = .systemBlue
            sender.configuration?.baseForegroundColor = .white
        } else {
            selectedSubjects.remove(title)
            sender.configuration?.baseBackgroundColor = UIColor(white: 0.93, alpha: 1)
            sender.configuration?.baseForegroundColor = .systemBlue
        }
        
        validateForm()
    }

    // MARK: - Uploads
    private func setupUploads() {
        stack.addArrangedSubview(uploadCard(title: "Upload College ID Card", label: collegeIDLabel, type: .collegeID))
        stack.addArrangedSubview(uploadCard(title: "Upload JEE Rank Card", label: jeeLabel, type: .jee))
        stack.addArrangedSubview(uploadCard(title: "Upload 12th Marksheet", label: marksheetLabel, type: .marksheet))
    }

    private func uploadCard(title: String, label: UILabel, type: UploadType) -> UIView {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.addAction(UIAction { _ in
            self.activeUploadType = type
            self.openDocumentPicker()
        }, for: .touchUpInside)

        label.text = "No file selected"
        label.textAlignment = .center
        label.textColor = .darkGray
        label.font = .systemFont(ofSize: 13)

        let stack = UIStackView(arrangedSubviews: [button, label])
        stack.axis = .vertical
        stack.spacing = 8

        return card(stack)
    }

    // MARK: - Submit
    private func setupSubmit() {
        submitButton.setTitle("Submit Documents", for: .normal)
        submitButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        submitButton.backgroundColor = .black
        submitButton.setTitleColor(.white, for: .normal)

        submitButton.layer.cornerRadius = 26
        submitButton.heightAnchor.constraint(equalToConstant: 58).isActive = true

        submitButton.layer.shadowColor = UIColor.black.cgColor
        submitButton.layer.shadowOpacity = 0.15
        submitButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        submitButton.layer.shadowRadius = 10

        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)

        stack.addArrangedSubview(submitButton)
    }

    @objc private func submitTapped() {
        submitButton.isEnabled = false
        submitButton.setTitle("Uploading...", for: .normal)
        submitButton.backgroundColor = .systemGray
        
        Task {
            do {
                guard let collegeURL = uploadedCollegeID,
                      let jeeURL = uploadedJEE,
                      let marksheetURL = uploadedMarksheet else {
                    throw NSError(domain: "Missing Documents", code: 0)
                }

                let collegeIDUrlString = try await SupabaseManager.shared.uploadDocument(collegeURL)
                let jeeUrlString = try await SupabaseManager.shared.uploadDocument(jeeURL)
                let marksheetUrlString = try await SupabaseManager.shared.uploadDocument(marksheetURL)
                
                if let currentUser = try await SupabaseManager.shared.getCurrentUser() {
                    
                    // 1. Store core documents inside the solver_details database table!
                    let data = SupabaseManager.SolverDocumentData(
                        solver_id: currentUser.id.uuidString,
                        college_start_month: self.startDateButton.title(for: .normal) ?? "",
                        college_end_month: self.endDateButton.title(for: .normal) ?? "",
                        subjects: Array(self.selectedSubjects),
                        college_id_url: collegeIDUrlString,
                        jee_rank_url: jeeUrlString,
                        marksheet_12th_url: marksheetUrlString,
                        is_approved: false
                    )
                    
                    try await SupabaseManager.shared.saveSolverDocuments(data: data)
                    
                    // 2. Keep the core identity role in Auth Metadata so the system knows they are a solver
                    let roleMetadata: [String: AnyJSON] = [
                        "role": AnyJSON("solver"),
                        "is_approved": AnyJSON(false)
                    ]
                    
                    let mergedMetadata = currentUser.userMetadata.merging(roleMetadata) { _, new in new }
                    try await SupabaseManager.shared.client.auth.update(user: UserAttributes(data: mergedMetadata))
                }
                
                await MainActor.run {
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let window = windowScene.windows.first else { return }

                    let vc = SplashViewControllerSolver()
                    let nav = UINavigationController(rootViewController: vc)
                    nav.navigationBar.isHidden = true

                    UIView.transition(with: window, duration: 0.35, options: [.transitionCrossDissolve]) {
                        window.rootViewController = nav
                    }
                }
            } catch {
                await MainActor.run {
                    self.submitButton.isEnabled = true
                    self.submitButton.setTitle("Submit Documents", for: .normal)
                    self.submitButton.backgroundColor = .black
                    
                    let alert = UIAlertController(title: "Upload Failed", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    @objc private func cancelSignup() {
        Task {
            try? await SupabaseManager.shared.logOut()
            await MainActor.run {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let window = windowScene.windows.first else { return }
                
                let nav = UINavigationController(rootViewController: RoleSelectionViewController())
                nav.navigationBar.isHidden = true
                
                UIView.transition(with: window, duration: 0.35, options: [.transitionCrossDissolve]) {
                    window.rootViewController = nav
                }
            }
        }
    }

    // MARK: - Helpers
    private func card(_ content: UIView) -> UIView {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.addSubview(content)

        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: v.topAnchor, constant: 16),
            content.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -16),
            content.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -16)
        ])

        return v
    }

    private func dateRow(title: String, button: UIButton, type: DateType) -> UIView {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 15)

        button.setTitle("Select", for: .normal)
        button.addTarget(self, action: #selector(openDatePicker(_:)), for: .touchUpInside)

        let row = UIStackView(arrangedSubviews: [label, button])
        row.axis = .horizontal
        row.distribution = .equalSpacing
        return row
    }

    // MARK: - Pickers
    @objc private func openDatePicker(_ sender: UIButton) {
        let pickerVC = MonthYearPickerViewController()
        pickerVC.modalPresentationStyle = .pageSheet

        if let sheet = pickerVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }

        pickerVC.onDone = { [weak self] date in
            guard let self = self else { return }
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            sender.setTitle(formatter.string(from: date), for: .normal)
            
            self.validateForm()
        }

        present(pickerVC, animated: true)
    }

    private func openDocumentPicker() {
        let types: [UTType] = [.pdf, .image]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = self
        present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController,
                        didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        let shouldStopAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let newURL = tempDir.appendingPathComponent(UUID().uuidString + "_" + url.lastPathComponent)
        do {
            try FileManager.default.copyItem(at: url, to: newURL)
            let name = url.lastPathComponent
            
            switch activeUploadType {
            case .collegeID:
                collegeIDLabel.text = name
                uploadedCollegeID = newURL
            case .jee:
                jeeLabel.text = name
                uploadedJEE = newURL
            case .marksheet:
                marksheetLabel.text = name
                uploadedMarksheet = newURL
            case .none: break
            }
            
            validateForm()
        } catch {
            print("Copy error: \(error)")
        }
    }

    private func validateForm() {
        let isStartValid = startDateButton.title(for: .normal) != "Select" && startDateButton.title(for: .normal) != nil
        let isEndValid = endDateButton.title(for: .normal) != "Select" && endDateButton.title(for: .normal) != nil
        let hasSubjects = !selectedSubjects.isEmpty
        let hasCollegeID = uploadedCollegeID != nil
        let hasJEE = uploadedJEE != nil
        let hasMarksheet = uploadedMarksheet != nil

        let isValid = isStartValid && isEndValid && hasSubjects && hasCollegeID && hasJEE && hasMarksheet

        submitButton.isEnabled = isValid
        submitButton.backgroundColor = isValid ? .black : .systemGray3
    }
}
