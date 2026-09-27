import UIKit

final class AttachmentLayoutView: UIView {
    var onLayout: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?()
    }

    override func hitTest(_ location: CGPoint, with event: UIEvent?) -> UIView? {
        guard point(inside: location, with: event) else { return nil }

        for subview in subviews.reversed() {
            let pointInSubview = convert(location, to: subview)
            if let hitView = subview.hitTest(pointInSubview, with: event) {
                return hitView
            }
        }

        // The layout view is only a canvas. Let UITextView receive touches
        // everywhere that is not occupied by an attachment view.
        return nil
    }
}
