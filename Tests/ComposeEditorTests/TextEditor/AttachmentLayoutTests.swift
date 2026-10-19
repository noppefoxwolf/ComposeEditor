import Testing
import UIKit
@testable import TextEditor

@MainActor
@Suite
struct AttachmentLayoutTests {
    @Test
    func preservesClientInsetsAndAddsAttachmentSizes() {
        let view = AttachmentTextView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let base = UIEdgeInsets(top: 16, left: 12, bottom: 20, right: 14)
        view.textContainerInset = base
        view.headerAttachmentsView.addArrangedSubview(box(width: nil, height: 30))
        view.topAttachmentsView.addArrangedSubview(box(width: nil, height: 40))
        view.bottomAttachmentsView.addArrangedSubview(box(width: nil, height: 50))
        view.leadingAttachmentsView.addArrangedSubview(box(width: 44, height: 44))
        settle(view)
        #expect(view.textContainerInset == UIEdgeInsets(top: 86, left: 56, bottom: 70, right: 14))

        let header = view.headerAttachmentsView.arrangedSubviews[0]
        view.headerAttachmentsView.removeArrangedSubview(header)
        header.removeFromSuperview()
        settle(view)
        #expect(view.textContainerInset.top == 56)

        view.textContainerInset = base
        settle(view)
        #expect(view.textContainerInset == UIEdgeInsets(top: 56, left: 56, bottom: 70, right: 14))
    }

    @Test
    func preservesDefaultInsetsWithoutAttachments() {
        let view = AttachmentTextView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let original = view.textContainerInset
        settle(view)
        #expect(view.textContainerInset == original)
    }

    @Test
    func updatesWrappedAttachmentAfterResizeAndContentChange() {
        let view = AttachmentTextView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let label = UILabel()
        label.numberOfLines = 0
        label.text = String(repeating: "Attachment text ", count: 20)
        view.topAttachmentsView.addArrangedSubview(label)
        settle(view)
        let wideHeight = view.textContainerInset.top
        view.frame.size.width = 160
        settle(view)
        #expect(view.textContainerInset.top > wideHeight)
        label.text = "Short"
        settle(view)
        #expect(view.textContainerInset.top < wideHeight)
        label.isHidden = true
        settle(view)
        #expect(view.textContainerInset.top == 8)
    }

    @Test
    func repeatedLayoutAndScrollingDoNotRewriteInsets() {
        let view = InsetTrackingTextView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        view.topAttachmentsView.addArrangedSubview(box(width: nil, height: 40))
        view.text = String(repeating: "Text\n", count: 100)
        settle(view)
        let expectedInsets = view.textContainerInset
        view.insetWriteCount = 0
        for offset in stride(from: 0, through: 100, by: 20) {
            view.contentOffset.y = CGFloat(offset)
            settle(view)
        }
        #expect(view.textContainerInset == expectedInsets)
        #expect(view.insetWriteCount == 0)
    }

    private func box(width: CGFloat?, height: CGFloat) -> UIView {
        let view = UIView()
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        if let width {
            view.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        return view
    }

    private func settle(_ view: UIView) {
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
}

@MainActor
private final class InsetTrackingTextView: AttachmentTextView {
    var insetWriteCount = 0

    override var textContainerInset: UIEdgeInsets {
        didSet { insetWriteCount += 1 }
    }
}
