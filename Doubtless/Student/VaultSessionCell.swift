import UIKit

final class VaultSessionCell: UITableViewCell {

    // MARK: - UI

    private let avatar = UIImageView()
    private let nameLabel = UILabel()
    private let instituteLabel = UILabel()
    private let infoButton = UIButton(type: .system)

    var infoAction: (() -> Void)?

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {

        selectionStyle = .none

        avatar.contentMode = .scaleAspectFill
        avatar.layer.cornerRadius = 22
        avatar.clipsToBounds = true

        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .label

        instituteLabel.font = .systemFont(ofSize: 14)
        instituteLabel.textColor = .secondaryLabel

        infoButton.setImage(UIImage(systemName: "info.circle"), for: .normal)
        infoButton.addTarget(self, action: #selector(infoTapped), for: .touchUpInside)

        let textStack = UIStackView(arrangedSubviews: [nameLabel, instituteLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let hStack = UIStackView(arrangedSubviews: [avatar, textStack, UIView(), infoButton])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 12
        hStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(hStack)

        NSLayoutConstraint.activate([
            avatar.widthAnchor.constraint(equalToConstant: 44),
            avatar.heightAnchor.constraint(equalToConstant: 44),

            hStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            hStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            hStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - Configure (🔥 FIXED)

    func configure(with session: Session) {

        nameLabel.text = "Solver \(session.solverId)"
        instituteLabel.text = "Institute data not available"

        // 👤 Solver profile image (NOT doubt image)
        avatar.image = UIImage(systemName: "person.circle")
    }

    // MARK: - Action

    @objc private func infoTapped() {
        infoAction?()
    }
}
