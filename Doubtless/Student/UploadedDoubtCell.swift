import UIKit

final class UploadedDoubtCell: UITableViewCell {

    static let reuseId = "UploadedDoubtCell"

    var onCancel: (() -> Void)?

    private let containerView = UIView()
    private let subjectLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let timeLabel = UILabel()
    private let cancelButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // 🔹 Card container
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.08
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)

        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])

        // 🔤 Text styles
        subjectLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        subjectLabel.textColor = .label

        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 1

        timeLabel.font = .systemFont(ofSize: 12)
        timeLabel.textColor = .tertiaryLabel

        let textStack = UIStackView(arrangedSubviews: [
            subjectLabel,
            descriptionLabel,
            timeLabel
        ])
        textStack.axis = .vertical
        textStack.spacing = 6   // ⬅️ more air between lines

        // ❌ Cancel button
        let config = UIImage.SymbolConfiguration(
            pointSize: 22,      // 👈 REAL icon size
            weight: .bold
        )

        cancelButton.setImage(
            UIImage(systemName: "xmark.circle.fill", withConfiguration: config),
            for: .normal
        )

        cancelButton.tintColor = .systemRed.withAlphaComponent(0.9)
        var btnConfig = UIButton.Configuration.plain()
        btnConfig.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
        cancelButton.configuration = btnConfig
        
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        containerView.addSubview(textStack)
        containerView.addSubview(cancelButton)

        textStack.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Text stack
            textStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            textStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            textStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            textStack.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor, constant: -12),

            // Cancel button
            cancelButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            cancelButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            cancelButton.widthAnchor.constraint(equalToConstant: 36),
            cancelButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    @objc private func cancelTapped() {
        onCancel?()
    }

    func configure(with doubt: Doubt) {
        subjectLabel.text = doubt.subject

        let preview = doubt.description.count > 40
            ? String(doubt.description.prefix(40)) + "…"
            : doubt.description
        descriptionLabel.text = preview

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        if let date = doubt.uploadedAt {
            timeLabel.text = formatter.string(from: date)
        } else {
            timeLabel.text = ""
        }
    }
}
