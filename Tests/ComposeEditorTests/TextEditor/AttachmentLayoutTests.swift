import Testing
import UIKit
@testable import ComposeEditor

@MainActor
@Suite
struct AttachmentLayoutTests {
    @Test
    func leadingAttachmentIntrinsicWidthChangeUpdatesTextInsetAfterLayoutInvalidation() {
        let textView = ComposeTextView(
            frame: CGRect(x: 0, y: 0, width: 320, height: 640)
        )
        let attachmentView = VariableIntrinsicSizeView(width: 34)
        textView.leadingAttachmentsView.addArrangedSubview(attachmentView)

        textView.layoutIfNeeded()
        let initialInset = textView.textContainerInset.left

        attachmentView.width = 42
        textView.leadingAttachmentsView.layoutIfNeeded()

        // This is the stale state observed when the attachment changes without
        // invalidating the owning editor.
        #expect(textView.textContainerInset.left == initialInset)

        textView.invalidateAttachmentLayout()
        textView.layoutIfNeeded()

        #expect(textView.textContainerInset.left == initialInset + 8)
    }

    @Test
    func leadingAttachmentColumnKeepsIntrinsicWidthInLandscape() {
        let textView = ComposeTextView(
            frame: CGRect(x: 0, y: 0, width: 844, height: 390)
        )
        let attachmentView = VariableIntrinsicSizeView(width: 42)
        textView.leadingAttachmentsView.layoutMargins = .init(
            top: 8,
            left: 8,
            bottom: 0,
            right: 8
        )
        textView.leadingAttachmentsView.addArrangedSubview(attachmentView)

        textView.invalidateAttachmentLayout()
        textView.layoutIfNeeded()

        #expect(textView.textContainerInset.left == 58)
    }
}

private final class VariableIntrinsicSizeView: UIView {
    var width: CGFloat {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    init(width: CGFloat) {
        self.width = width
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: width, height: 36)
    }
}
