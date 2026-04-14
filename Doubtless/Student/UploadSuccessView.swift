import UIKit

final class UploadSuccessView: UIView {

    private let circle = UIView()
    private let checkmark = UIImageView()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = .systemBackground
        alpha = 0

        // 🔥 Bigger circle
        circle.backgroundColor = .systemGreen
        circle.layer.cornerRadius = 80
        circle.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        circle.alpha = 0

        // 🔥 Bigger checkmark
        checkmark.image = UIImage(systemName: "checkmark",
                                  withConfiguration: UIImage.SymbolConfiguration(
                                    pointSize: 48,
                                    weight: .bold
                                  ))
        checkmark.tintColor = .white
        checkmark.alpha = 0

        // 🔥 Bigger text
        label.text = "Doubt Uploaded!"
        label.textColor = .systemGreen
        label.font = .systemFont(ofSize: 26, weight: .bold)
        label.alpha = 0

        addSubview(circle)
        circle.addSubview(checkmark)
        addSubview(label)

        circle.translatesAutoresizingMaskIntoConstraints = false
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            circle.centerXAnchor.constraint(equalTo: centerXAnchor),
            circle.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -30),
            circle.widthAnchor.constraint(equalToConstant: 160),
            circle.heightAnchor.constraint(equalToConstant: 160),

            checkmark.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            checkmark.centerYAnchor.constraint(equalTo: circle.centerYAnchor),
            checkmark.widthAnchor.constraint(equalToConstant: 70),
            checkmark.heightAnchor.constraint(equalToConstant: 70),

            label.topAnchor.constraint(equalTo: circle.bottomAnchor, constant: 24),
            label.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }

    func play(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
        }

        UIView.animate(
            withDuration: 0.45,
            delay: 0.15,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.8
        ) {
            self.circle.alpha = 1
            self.circle.transform = .identity
        }

        UIView.animate(withDuration: 0.3, delay: 0.35) {
            self.checkmark.alpha = 1
        }

        UIView.animate(withDuration: 0.3, delay: 0.45) {
            self.label.alpha = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4, execute: completion)
    }
}
