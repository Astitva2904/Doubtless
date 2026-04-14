import UIKit

final class InfoRow: UIView {

    private let iconView = UIImageView()
    private let label = UILabel()

    init(icon: String, text: String) {
        super.init(frame: .zero)
        setup(icon: icon, text: text)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup(icon: String, text: String) {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12

        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = .label

        label.text = text
        label.numberOfLines = 0

        addSubview(iconView)
        addSubview(label)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),

            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }

    func setText(_ text: String) {
        label.text = text
    }
}
