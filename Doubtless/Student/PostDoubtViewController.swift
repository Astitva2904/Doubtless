//
//  PostDoubtViewController.swift
//  DoubtLess
//
//  Created by admin34 on 26/11/25.
//

import UIKit

class PostDoubtViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var uploadButton: UIButton!
  
    @IBOutlet weak var subjectButton: UIButton!
    
    @IBOutlet weak var languageButton: UIButton!
    
    @IBOutlet weak var submitButton: UIButton!
    private var pickedImage: UIImage?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
#if DEBUG
        if uploadButton == nil { print("[DEBUG] Warning: uploadButton IBOutlet is not connected.") }
        if imageView == nil { print("[DEBUG] Warning: imageView IBOutlet is not connected.") }
        if subjectButton == nil { print("[DEBUG] Warning: subjectButton IBOutlet is not connected.") }
        if languageButton == nil { print("[DEBUG] Warning: languageButton IBOutlet is not connected.") }
        if submitButton == nil { print("[DEBUG] Warning: submitButton IBOutlet is not connected.") }
#endif
        
        configureImageView()
        configureUploadButton()
        setupSubjectMenu()
        setupLanguageMenu()
        
        styleSelectorButton(subjectButton)
        styleSelectorButton(languageButton)
        

        // Do any additional setup after loading the view.
    }
    
    private func styleSelectorButton(_ button: UIButton) {
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 0.95, green: 0.62, blue: 0.13, alpha: 1).cgColor  // same orange
        button.contentHorizontalAlignment = .center
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
    }

    

    private func configureImageView() {
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 10
            imageView.backgroundColor = UIColor(white: 0.97, alpha: 1)
            imageView.isUserInteractionEnabled = true

            // optional: tap the image to change it
            let tap = UITapGestureRecognizer(target: self, action: #selector(uploadTapped(_:)))
            imageView.addGestureRecognizer(tap)
        }

        private func configureUploadButton() {
            uploadButton.layer.cornerRadius = 12
            uploadButton.layer.masksToBounds = true
            uploadButton.layer.borderWidth = 1
            uploadButton.layer.borderColor = UIColor(red: 0.95, green: 0.62, blue: 0.13, alpha: 1).cgColor

            if #available(iOS 15.0, *) {
                var config = UIButton.Configuration.plain()
                if let img = UIImage(named: "upload_icon") {
                    config.image = img.withRenderingMode(.alwaysOriginal)
                } else {
                    config.image = UIImage(systemName: "photo.on.rectangle")
                }
                config.title = "Upload Photo"
                config.imagePlacement = .top
                config.imagePadding = 12
                config.contentInsets = NSDirectionalEdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18)
                config.baseForegroundColor = .black
                uploadButton.configuration = config
                uploadButton.contentHorizontalAlignment = .center
            } else {
                let img = UIImage(named: "upload_icon") ?? UIImage(systemName: "photo.on.rectangle")
                uploadButton.setImage(img, for: .normal)
                uploadButton.setTitle("Upload Photo", for: .normal)
                uploadButton.tintColor = .black
                uploadButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
                uploadButton.contentHorizontalAlignment = .center
                uploadButton.imageView?.contentMode = .scaleAspectFit
            }
        }

        // MARK: - Menus (subject + language popups)
        func setupSubjectMenu() {
            let subjects = ["Mathematics", "Physics", "Chemistry"]
            let actions = subjects.map { subject in
                UIAction(title: subject) { [weak self] _ in
                    self?.subjectButton.setTitle(subject, for: .normal)
                }
            }
            subjectButton.menu = UIMenu(children: actions)
            subjectButton.showsMenuAsPrimaryAction = true
        }

        func setupLanguageMenu() {
            let languages = ["English", "Hindi"]
            let actions = languages.map { lang in
                UIAction(title: lang) { [weak self] _ in
                    self?.languageButton.setTitle(lang, for: .normal)
                }
            }
            languageButton.menu = UIMenu(children: actions)
            languageButton.showsMenuAsPrimaryAction = true
        }

        // MARK: - Actions
        @IBAction func uploadTapped(_ sender: Any) {
            presentPhotoOptions()
        }

        @IBAction func submitbuttonTapped(_ sender: UIButton) {
            // implement upload logic or validation here
            // use `pickedImage` and selected subject/language
        }

        // MARK: - Photo picker
        private func presentPhotoOptions() {
            let sheet = UIAlertController(title: "Add Photo", message: nil, preferredStyle: .actionSheet)

            // Camera (if available)
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                sheet.addAction(UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
                    self?.presentImagePicker(source: .camera)
                })
            }

            // Photo library
            sheet.addAction(UIAlertAction(title: "Choose from Library", style: .default) { [weak self] _ in
                self?.presentImagePicker(source: .photoLibrary)
            })

            sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            // iPad popover anchor
            if let pop = sheet.popoverPresentationController {
                if let btn = uploadButton {
                    pop.sourceView = btn
                    pop.sourceRect = btn.bounds
                } else {
                    pop.sourceView = view
                    pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
                }
            }

            present(sheet, animated: true)
        }

        private func presentImagePicker(source: UIImagePickerController.SourceType) {
            // Ensure Info.plist has NSCameraUsageDescription and NSPhotoLibraryUsageDescription
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = source
            picker.allowsEditing = true
            present(picker, animated: true)
        }
    
        // MARK: - UIImagePickerControllerDelegate and UINavigationControllerDelegate
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true, completion: nil)
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

            let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
            if let img = image {
                pickedImage = img
                imageView.image = img
            }
            picker.dismiss(animated: true, completion: nil)
        }
}

