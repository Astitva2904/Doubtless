import UIKit

final class PaddedLabel: UILabel {

    private var contentInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)

    func setPadding(_ top: CGFloat, _ left: CGFloat, _ bottom: CGFloat, _ right: CGFloat) {
        contentInsets = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
        invalidateIntrinsicContentSize()
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInsets.left + contentInsets.right,
            height: size.height + contentInsets.top + contentInsets.bottom
        )
    }
}
