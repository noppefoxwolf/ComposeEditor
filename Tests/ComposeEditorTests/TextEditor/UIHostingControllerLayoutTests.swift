import SwiftUI
import Testing
import UIKit
@testable import ComposeEditor

@MainActor
@Suite
struct UIHostingControllerLayoutTests {
    @Test
    func hostingControllerViewUpdatesIntrinsicContentSizeWhenRootViewChanges() {
        let hostingController = UIHostingController(
            rootView: ResizableSwiftUIView(width: 34)
        )
        hostingController.sizingOptions = .intrinsicContentSize

        let container = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 100))
        let hostingView = hostingController.view!
        container.addSubview(hostingView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hostingView.topAnchor.constraint(equalTo: container.topAnchor),
        ])

        container.layoutIfNeeded()
        let initialSize = hostingView.intrinsicContentSize

        hostingController.rootView = ResizableSwiftUIView(width: 42)
        container.layoutIfNeeded()

        #expect(initialSize.width == 34)
        #expect(hostingView.intrinsicContentSize.width == 42)
    }

    @Test
    func hostingViewWrapperReportsUpdatedFittingSizeWhenRootViewChanges() {
        let hostingView = HostingViewProbe(
            rootView: ResizableSwiftUIView(width: 34)
        )
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 100))
        container.addSubview(hostingView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hostingView.topAnchor.constraint(equalTo: container.topAnchor),
        ])

        container.layoutIfNeeded()
        let initialSize = hostingView.systemLayoutSizeFitting(
            UIView.layoutFittingCompressedSize
        )

        hostingView.rootView = ResizableSwiftUIView(width: 42)
        container.layoutIfNeeded()

        let updatedSize = hostingView.systemLayoutSizeFitting(
            UIView.layoutFittingCompressedSize
        )
        #expect(initialSize.width == 34)
        #expect(updatedSize.width == 42)
    }

    @Test
    func hostingViewWrapperDoesNotReceiveHostingViewIntrinsicInvalidation() {
        // Even when the outer wrapper forwards intrinsicContentSize, UIKit does
        // not call invalidateIntrinsicContentSize on it for the inner hosting
        // view's change.
        let hostingView = IntrinsicForwardingHostingView(
            rootView: ResizableSwiftUIView(width: 34)
        )
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 100))
        container.addSubview(hostingView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hostingView.topAnchor.constraint(equalTo: container.topAnchor),
        ])

        container.layoutIfNeeded()
        hostingView.resetIntrinsicInvalidationCount()

        hostingView.rootView = ResizableSwiftUIView(width: 42)
        container.layoutIfNeeded()

        #expect(hostingView.intrinsicContentSize.width == 42)
        #expect(hostingView.intrinsicInvalidationCount == 0)
    }

    @Test
    func hostingViewWidthChangeIsReflectedInTextKitAfterInvalidation() {
        let textView = ComposeTextView(
            frame: CGRect(x: 0, y: 0, width: 320, height: 640)
        )
        let hostingView = HostingViewProbe(
            rootView: ResizableSwiftUIView(width: 34)
        )
        textView.leadingAttachmentsView.addArrangedSubview(hostingView)

        textView.layoutIfNeeded()
        let initialInset = textView.textContainerInset.left

        hostingView.rootView = ResizableSwiftUIView(width: 42)
        hostingView.layoutIfNeeded()
        textView.leadingAttachmentsView.layoutIfNeeded()
        textView.textInputView.layoutIfNeeded()

        #expect(
            hostingView.systemLayoutSizeFitting(
                UIView.layoutFittingCompressedSize
            ).width == 42
        )

        textView.invalidateAttachmentLayout()
        textView.layoutIfNeeded()

        #expect(textView.textContainerInset.left == initialInset + 8)
    }

    @Test
    func hostingViewIntrinsicSizeChangeUsesTheNormalLayoutPass() {
        let textView = LayoutCountingAttachmentTextView(
            frame: CGRect(x: 0, y: 0, width: 320, height: 640)
        )
        let hostingView = HostingViewProbe(
            rootView: ResizableSwiftUIView(width: 34)
        )
        textView.leadingAttachmentsView.addArrangedSubview(hostingView)

        textView.layoutIfNeeded()
        let initialLayoutPassCount = textView.layoutPassCount
        let initialInset = textView.textContainerInset.left

        hostingView.rootView = ResizableSwiftUIView(width: 42)
        textView.textInputView.layoutIfNeeded()

        #expect(textView.layoutPassCount == initialLayoutPassCount)
        #expect(textView.textContainerInset.left == initialInset)

        textView.invalidateAttachmentLayout()
        textView.layoutIfNeeded()

        #expect(textView.textContainerInset.left == initialInset + 8)
    }

    @Test
    func hostingViewKeepsLeadingColumnContentSizedInLandscape() {
        let textView = ComposeTextView(
            frame: CGRect(x: 0, y: 0, width: 844, height: 390)
        )
        let hostingView = HostingViewProbe(
            rootView: ResizableSwiftUIView(width: 42)
        )
        textView.leadingAttachmentsView.addArrangedSubview(hostingView)

        textView.layoutIfNeeded()

        #expect(textView.textContainerInset.left == 42)
    }
}

private struct ResizableSwiftUIView: View {
    let width: CGFloat

    var body: some View {
        Color.clear
            .frame(width: width, height: 36)
    }
}

@MainActor
private class HostingViewProbe<Content: View>: UIView {
    fileprivate let viewController: UIHostingController<Content>

    var rootView: Content {
        get { viewController.rootView }
        set { viewController.rootView = newValue }
    }

    init(rootView: Content) {
        viewController = UIHostingController(rootView: rootView)
        super.init(frame: .null)

        viewController.sizingOptions = .intrinsicContentSize
        let contentView = viewController.view!
        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@MainActor
private final class IntrinsicForwardingHostingView<Content: View>: HostingViewProbe<Content> {
    private(set) var intrinsicInvalidationCount = 0

    override var intrinsicContentSize: CGSize {
        viewController.view.intrinsicContentSize
    }

    override func invalidateIntrinsicContentSize() {
        intrinsicInvalidationCount += 1
        super.invalidateIntrinsicContentSize()
    }

    func resetIntrinsicInvalidationCount() {
        intrinsicInvalidationCount = 0
    }
}

private final class LayoutCountingAttachmentTextView: AttachmentTextView {
    private(set) var layoutPassCount = 0

    override func layoutSubviews() {
        layoutPassCount += 1
        super.layoutSubviews()
    }
}
