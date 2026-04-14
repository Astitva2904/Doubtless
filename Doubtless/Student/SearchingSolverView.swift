import UIKit

final class SearchingSolverView: UIView {

    private let icon = UIImageView()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = .systemBackground
        alpha = 0

        // 🔥 Bigger icon with better weight
        icon.image = UIImage(systemName: "person.2.fill")
        icon.preferredSymbolConfiguration =
            UIImage.SymbolConfiguration(pointSize: 96, weight: .semibold)

        icon.tintColor = .systemOrange
        icon.contentMode = .scaleAspectFit

        // 🔥 Bigger, clearer text
        label.text = "Wait while we look for a solver"
        label.textColor = .systemOrange
        label.font = .systemFont(ofSize: 30, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 0

        addSubview(icon)
        addSubview(label)

        icon.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -40),
            icon.widthAnchor.constraint(equalToConstant: 200),
            icon.heightAnchor.constraint(equalToConstant: 200),

            label.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 1),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32)
        ])
    }

    func show() {
        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
        }
    }

    func hide(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
        }, completion: { _ in
            completion()
        })
    }
}
