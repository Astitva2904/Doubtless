import UIKit

final class SessionDetailViewController: UIViewController {

    private let session: Session

    init(session: Session) {
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {

        // 📷 Doubt uploaded image (MAIN IMAGE)
        let doubtImageView = UIImageView()
        doubtImageView.image = UIImage(systemName: "photo")
        doubtImageView.contentMode = .scaleAspectFit
        doubtImageView.clipsToBounds = true
        doubtImageView.heightAnchor.constraint(equalToConstant: 200).isActive = true

        // 👤 Solver name
        let nameLabel = UILabel()
        nameLabel.text = "Solver \(session.solverId)"
        nameLabel.font = .boldSystemFont(ofSize: 22)
        nameLabel.textColor = .label

        // 🏫 Solver institute
        let instituteLabel = UILabel()
        instituteLabel.text = "Institute data not available"
        instituteLabel.textColor = .secondaryLabel
        instituteLabel.font = .systemFont(ofSize: 15)

        // 📝 Doubt description (NO outline)
        let notesLabel = UILabel()
        notesLabel.text = session.notes
        notesLabel.numberOfLines = 0
        notesLabel.font = .systemFont(ofSize: 16)
        notesLabel.textColor = .label

        // ⏱ Duration
        let durationLabel = UILabel()
        durationLabel.text = "Duration : \(session.duration)"
        durationLabel.font = .systemFont(ofSize: 15)
        durationLabel.textColor = .label

        // ⭐ Rating
        let ratingLabel = UILabel()
        ratingLabel.text = "Rating : \(String(repeating: "⭐️", count: session.rating))"
        ratingLabel.font = .systemFont(ofSize: 15)
        ratingLabel.textColor = .label

        // ▶️ Play button
        let playButton = UIButton(type: .system)
        playButton.setTitle("Play", for: .normal)
        playButton.backgroundColor = .systemOrange
        playButton.setTitleColor(.white, for: .normal)
        playButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        playButton.layer.cornerRadius = 18
        playButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

        // 📐 Stack
        let stack = UIStackView(arrangedSubviews: [
            doubtImageView,
            nameLabel,
            instituteLabel,
            notesLabel,
            durationLabel,
            ratingLabel,
            playButton
        ])

        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        // 🔽 Reduce spacing specifically between duration & rating
        stack.setCustomSpacing(4, after: durationLabel)

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
}
