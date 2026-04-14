import UIKit
import Supabase
import Auth

final class SolverEditProfileViewController: UIViewController {

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    
    private var didSelectNewImage = false

    private let profileImageView = UIImageView()
    private let cameraButton = UIButton(type: .system)

    private let nameField = UITextField()
    private let phoneField = UITextField()
    private let addressField = UITextField()

    private let genderButton = UIButton(type: .system)
    private let yearButton = UIButton(type: .system)

    private let saveButton = UIButton(type: .system)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupNavigationBar()
        setupScrollView()
        setupContent()
        
        loadUserData()
    }

    // MARK: - Data Loading
    private func loadUserData() {
        // Name field is editable
        
        Task {
            do {
                if let user = try await SupabaseManager.shared.getCurrentUser() {
                    let meta = user.userMetadata
                    
                    DispatchQueue.main.async {
                        self.nameField.text = meta["name"]?.stringValue ?? ""
                        self.phoneField.text = meta["mobile"]?.stringValue ?? ""
                        self.addressField.text = meta["address"]?.stringValue ?? ""
                        
                        if let g = meta["gender"]?.stringValue, !g.isEmpty {
                            self.genderButton.setTitle(g, for: .normal)
                            self.genderButton.setTitleColor(.label, for: .normal)
                        }
                        if let y = meta["class"]?.stringValue, !y.isEmpty {
                            self.yearButton.setTitle(y, for: .normal)
                            self.yearButton.setTitleColor(.label, for: .normal)
                        }
                    }
                    
                    if let imageURLString = meta["profile_image_url"]?.stringValue,
                       let url = URL(string: imageURLString) {
                        do {
                            let (data, _) = try await URLSession.shared.data(from: url)
                            if let image = UIImage(data: data) {
                                DispatchQueue.main.async {
                                    self.profileImageView.image = image
                                }
                            }
                        } catch {
                            print("Failed to load edit profile image: \(error)")
                        }
                    }
                }
            } catch {
                print("Failed to load user data: \(error)")
            }
        }
    }

    // MARK: - Navigation
    private func setupNavigationBar() {
        title = "Edit Profile"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - ScrollView
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(contentView)
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
    }

    // MARK: - Content
    private func setupContent() {
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])

        stackView.addArrangedSubview(makeProfileHeader())
        setupFields()
        setupSaveButton()
    }

    // MARK: - Profile Header (FIXED)
    private func makeProfileHeader() -> UIView {
        let container = UIView()
        container.heightAnchor.constraint(equalToConstant: 140).isActive = true

        profileImageView.image = UIImage(systemName: "person.circle.fill")?.withTintColor(.systemGray3, renderingMode: .alwaysOriginal)
        profileImageView.backgroundColor = .systemGray5
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 60
        profileImageView.translatesAutoresizingMaskIntoConstraints = false

        cameraButton.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        cameraButton.tintColor = .white
        cameraButton.backgroundColor = .systemBlue
        cameraButton.layer.cornerRadius = 18
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        cameraButton.addTarget(self, action: #selector(openImagePicker), for: .touchUpInside)

        container.addSubview(profileImageView)
        container.addSubview(cameraButton)

        NSLayoutConstraint.activate([
            profileImageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            profileImageView.topAnchor.constraint(equalTo: container.topAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),

            cameraButton.widthAnchor.constraint(equalToConstant: 36),
            cameraButton.heightAnchor.constraint(equalToConstant: 36),
            cameraButton.trailingAnchor.constraint(equalTo: profileImageView.trailingAnchor),
            cameraButton.bottomAnchor.constraint(equalTo: profileImageView.bottomAnchor)
        ])

        return container
    }

    // MARK: - Image Picker
    @objc private func openImagePicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    // MARK: - Fields
    private func setupFields() {
        stackView.addArrangedSubview(makeLabeledField(title: "Name", field: nameField))
        stackView.addArrangedSubview(makeLabeledField(title: "Phone Number", field: phoneField))
        stackView.addArrangedSubview(makeLabeledField(title: "Address", field: addressField))

        configureDropdownButton(genderButton, placeholder: "Select gender")
        configureDropdownButton(yearButton, placeholder: "Select year")

        stackView.addArrangedSubview(makeLabeledButton(title: "Gender", button: genderButton))
        stackView.addArrangedSubview(makeLabeledButton(title: "Currently in", button: yearButton))

        genderButton.addTarget(self, action: #selector(selectGender), for: .touchUpInside)
        yearButton.addTarget(self, action: #selector(selectYear), for: .touchUpInside)
    }

    private func makeLabeledField(title: String, field: UITextField) -> UIView {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel

        field.borderStyle = .roundedRect
        field.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let stack = UIStackView(arrangedSubviews: [label, field])
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }

    private func makeLabeledButton(title: String, button: UIButton) -> UIView {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel

        button.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let stack = UIStackView(arrangedSubviews: [label, button])
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }

    private func configureDropdownButton(_ button: UIButton, placeholder: String) {
        button.setTitle(placeholder, for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.contentHorizontalAlignment = .left
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
        button.configuration = config

        let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))
        chevron.tintColor = .systemGray
        chevron.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(chevron)

        NSLayoutConstraint.activate([
            chevron.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -12),
            chevron.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
    }

    // MARK: - Save
    private func setupSaveButton() {
        saveButton.setTitle("Save Changes", for: .normal)
        saveButton.backgroundColor = .systemBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        saveButton.layer.cornerRadius = 14
        saveButton.heightAnchor.constraint(equalToConstant: 52).isActive = true

        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        stackView.addArrangedSubview(saveButton)
    }

    @objc private func saveTapped() {
        // Show loading state
        saveButton.setTitle("Saving...", for: .normal)
        saveButton.isEnabled = false
        
        Task {
            do {
                let user = try await SupabaseManager.shared.getCurrentUser()
                var newMetadata: [String: AnyJSON] = user?.userMetadata ?? [:]
                
                newMetadata["mobile"] = try AnyJSON(phoneField.text ?? "")
                newMetadata["address"] = try AnyJSON(addressField.text ?? "")
                
                let gender = genderButton.title(for: .normal)
                if gender != "Select gender" { newMetadata["gender"] = try AnyJSON(gender ?? "") }
                
                let solverYear = yearButton.title(for: .normal)
                if solverYear != "Select year" { newMetadata["class"] = try AnyJSON(solverYear ?? "") }
                
                if self.didSelectNewImage, let imageToUpload = profileImageView.image {
                    do {
                        let imageUrl = try await SupabaseManager.shared.uploadImage(imageToUpload)
                        newMetadata["profile_image_url"] = try AnyJSON(imageUrl)
                    } catch {
                        print("Failed to upload image: \(error)")
                    }
                }
                
                // Keep the old name intact
                if let name = nameField.text {
                    newMetadata["name"] = try AnyJSON(name)
                }
                
                // Dispatch update to Supabase Auth
                _ = try await SupabaseManager.shared.client.auth.update(
                    user: UserAttributes(data: newMetadata)
                )
                
                DispatchQueue.main.async { [weak self] in
                    self?.saveButton.setTitle("Saved", for: .normal)
                    self?.saveButton.backgroundColor = .systemGreen
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            } catch {
                print("Failed to update profile: \(error)")
                DispatchQueue.main.async {
                    self.saveButton.setTitle("Save Changes", for: .normal)
                    self.saveButton.isEnabled = true
                }
            }
        }
    }

    // MARK: - Dropdowns
    @objc private func selectGender() {
        showActionSheet(
            title: "Gender",
            options: ["Male", "Female", "Prefer not to say"]
        ) { [weak self] value in
            self?.genderButton.setTitle(value, for: .normal)
            self?.genderButton.setTitleColor(.label, for: .normal)
        }
    }

    @objc private func selectYear() {
        showActionSheet(
            title: "Currently in",
            options: ["1st Year", "2nd Year", "3rd Year", "4th Year"]
        ) { [weak self] value in
            self?.yearButton.setTitle(value, for: .normal)
            self?.yearButton.setTitleColor(.label, for: .normal)
        }
    }

    private func showActionSheet(
        title: String,
        options: [String],
        handler: @escaping (String) -> Void
    ) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)

        options.forEach { option in
            alert.addAction(UIAlertAction(title: option, style: .default) { _ in
                handler(option)
            })
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - Image Picker Delegate
extension SolverEditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        if let image = info[.editedImage] as? UIImage {
            profileImageView.image = image
            didSelectNewImage = true
        } else if let image = info[.originalImage] as? UIImage {
            profileImageView.image = image
            didSelectNewImage = true
        }
        dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}
