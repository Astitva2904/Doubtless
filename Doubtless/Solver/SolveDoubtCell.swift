import UIKit

final class SolveDoubtCell: UITableViewCell {

    static let identifier = "SolveDoubtCell"

    // MARK: - UI

    private let cardView = UIView()

    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let subjectLabel = UILabel()
    private let chevronImageView = UIImageView()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear

        setupCard()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupCard() {
        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.06
        cardView.layer.shadowRadius = 8
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)

        contentView.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    private func setupLayout() {
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 24

        nameLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        subjectLabel.font = .systemFont(ofSize: 14)
        subjectLabel.textColor = .secondaryLabel

        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = .tertiaryLabel

        let textStack = UIStackView(arrangedSubviews: [nameLabel, subjectLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let mainStack = UIStackView(arrangedSubviews: [
            avatarImageView,
            textStack,
            chevronImageView
        ])
        mainStack.axis = .horizontal
        mainStack.alignment = .center
        mainStack.spacing = 12

        cardView.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: 48),
            avatarImageView.heightAnchor.constraint(equalToConstant: 48),

            chevronImageView.widthAnchor.constraint(equalToConstant: 12),

            mainStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            mainStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
            mainStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - Configure

    func configure(with doubt: DoubtItem) {
        if let urlString = doubt.studentImageUrl, let url = URL(string: urlString) {
            // Because Kingfisher wasn't imported initially, if Kingfisher is used elsewhere we can assume it.
            // If not available, we use standard URL fetch to not break building
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.avatarImageView.image = image
                        }
                    } else {
                        DispatchQueue.main.async { self.avatarImageView.image = UIImage(named: doubt.imageName) ?? UIImage(systemName: doubt.imageName) }
                    }
                } catch {
                    DispatchQueue.main.async { self.avatarImageView.image = UIImage(named: doubt.imageName) ?? UIImage(systemName: doubt.imageName) }
                }
            }
        } else {
            avatarImageView.image = UIImage(named: doubt.imageName) ?? UIImage(systemName: doubt.imageName)
        }
        nameLabel.text = doubt.name
        subjectLabel.text = doubt.subject
    }
}
