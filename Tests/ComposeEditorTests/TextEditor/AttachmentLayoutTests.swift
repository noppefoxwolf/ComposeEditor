import Testing
import UIKit
@testable import TextEditor

@MainActor
@Suite
struct AttachmentLayoutTests {
    @Test(arguments: [UIScrollView.ContentInsetAdjustmentBehavior.scrollableAxes, .automatic, .always, .never])
    func horizontalSafeAreaDoesNotDoubleCountScrollInsets(behavior: UIScrollView.ContentInsetAdjustmentBehavior) {
        let (window, controller, view) = makeWindow()
        defer { window.isHidden = true }
        view.contentInsetAdjustmentBehavior = behavior
        view.contentInset = UIEdgeInsets(top: 11, left: 7, bottom: 93, right: 9)
        let base = UIEdgeInsets(top: 16, left: 12, bottom: 20, right: 14)
        view.textContainerInset = base
        view.text = String(repeating: "Body text ", count: 100)
        view.topAttachmentsView.addArrangedSubview(box(width: nil, height: 40))
        view.bottomAttachmentsView.addArrangedSubview(box(width: nil, height: 50))
        for (size, left, right) in [
            (CGSize(width: 800, height: 600), CGFloat(44), CGFloat(24)),
            (CGSize(width: 400, height: 800), 0, 0),
            (CGSize(width: 600, height: 400), 18, 52),
        ] {
            window.frame.size = size
            controller.additionalSafeAreaInsets = UIEdgeInsets(top: 20, left: left, bottom: 30, right: right)
            settle(window)
            settle(view)
            let extraLeft = max(0, view.safeAreaInsets.left - view.adjustedContentInset.left)
            let extraRight = max(0, view.safeAreaInsets.right - view.adjustedContentInset.right)
            #expect(view.textContainerInset == UIEdgeInsets(top: 56, left: base.left + extraLeft, bottom: 70, right: base.right + extraRight))
            #expect(view.contentInset == UIEdgeInsets(top: 11, left: 7, bottom: 93, right: 9))
            let canvas = view.textInputView.bounds
            let top = view.topAttachmentsView.convert(view.topAttachmentsView.bounds, to: view.textInputView)
            #expect(abs(top.minX - extraLeft) < 0.01)
            #expect(abs(top.maxX - (canvas.maxX - extraRight)) < 0.01)
            #expect(view.textContainer.size.width <= view.bounds.width)
            let expected = view.textContainerInset
            let adjusted = view.adjustedContentInset
            view.contentOffset.y += 60
            settle(view)
            #expect(view.textContainerInset == expected)
            #expect(view.adjustedContentInset == adjusted)
        }
    }

    @Test(arguments: [false, true])
    func slotsCanExtendToFullWidthWhileTextAndCWStaySafe(rtl: Bool) throws {
        let (window, controller, view) = makeWindow()
        defer { window.isHidden = true }
        view.semanticContentAttribute = rtl ? .forceRightToLeft : .forceLeftToRight
        view.contentInsetAdjustmentBehavior = .scrollableAxes
        controller.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 44, bottom: 0, right: 24)
        view.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 20, right: 14)
        view.placeholder = "Write something inside the safe area…"
        view.headerAttachmentsView.addArrangedSubview(box(width: nil, height: 30))
        let profile = box(width: 48, height: 48)
        profile.backgroundColor = .systemOrange
        view.leadingAttachmentsView.addArrangedSubview(profile)
        let cw = UILabel()
        cw.text = "Content warning"
        cw.backgroundColor = .secondarySystemBackground
        view.topAttachmentsView.addArrangedSubview(cw)
        let media = UIScrollView()
        media.backgroundColor = .systemTeal
        media.heightAnchor.constraint(equalToConstant: 100).isActive = true
        media.contentSize = CGSize(width: 1200, height: 100)
        view.bottomAttachmentsView.addArrangedSubview(media)
        view.bottomAttachmentsHorizontalLayout = .fullWidth
        settle(window)
        settle(view)
        let safeLeft = view.safeAreaInsets.left
        let safeRight = view.safeAreaInsets.right
        #expect(view.textContainerInset.left == 12 + safeLeft + (rtl ? 0 : 48))
        #expect(view.textContainerInset.right == 14 + safeRight + (rtl ? 48 : 0))
        let safe = view.safeAreaLayoutGuide.layoutFrame
        let cwFrame = cw.convert(cw.bounds, to: view)
        #expect(cwFrame.minX >= safe.minX)
        #expect(cwFrame.maxX <= safe.maxX)
        let mediaFrame = media.convert(media.bounds, to: view)
        #expect(abs(mediaFrame.minX - view.bounds.minX) < 0.01)
        #expect(abs(mediaFrame.maxX - view.bounds.maxX) < 0.01)
        let mediaPoint = media.convert(CGPoint(x: 2, y: 50), to: view)
        #expect(view.hitTest(mediaPoint, with: nil) === media)
        media.contentOffset.x = 200
        settle(view)
        #expect(media.bounds.width == view.bounds.width)
        #expect(view.adjustedContentInset.left == 0)
        #expect(view.adjustedContentInset.right == 0)
        let caret = view.caretRect(for: view.beginningOfDocument)
        #expect(caret.minX >= safe.minX)
        #expect(caret.maxX <= safe.maxX)

        let image = UIGraphicsImageRenderer(bounds: controller.view.bounds).image { context in
            controller.view.layer.render(in: context.cgContext)
        }
        Attachment.record(try #require(image.pngData()), named: rtl ? "safe-area-rtl.png" : "safe-area-placeholder.png")

        view.text = String(repeating: "Body text wraps inside the safe area. ", count: 8)
        settle(view)
        if let range = view.textRange(from: view.beginningOfDocument, to: view.endOfDocument) {
            for rect in view.selectionRects(for: range) where rect.rect.width > 0 {
                #expect(rect.rect.minX >= safe.minX)
                #expect(rect.rect.maxX <= safe.maxX)
            }
        }
        let bodyImage = UIGraphicsImageRenderer(bounds: controller.view.bounds).image { context in
            controller.view.layer.render(in: context.cgContext)
        }
        Attachment.record(try #require(bodyImage.pngData()), named: rtl ? "safe-area-body-rtl.png" : "safe-area-body.png")
        let insets = view.textContainerInset
        view.bottomAttachmentsHorizontalLayout = .safeArea
        settle(view)
        #expect(view.textContainerInset == insets)
        let safeMedia = media.convert(media.bounds, to: view)
        #expect(safeMedia.minX >= safe.minX)
        #expect(safeMedia.maxX <= safe.maxX)
        view.headerAttachmentsHorizontalLayout = .fullWidth
        view.topAttachmentsHorizontalLayout = .fullWidth
        view.leadingAttachmentsHorizontalLayout = .fullWidth
        settle(view)
        let headerFrame = view.headerAttachmentsView.convert(view.headerAttachmentsView.bounds, to: view.textInputView)
        #expect(headerFrame.minX == 0)
        #expect(headerFrame.width == view.textInputView.bounds.width)
        let topFrame = view.topAttachmentsView.convert(view.topAttachmentsView.bounds, to: view.textInputView)
        #expect(topFrame.minX == 0)
        #expect(topFrame.width == view.textInputView.bounds.width)
        #expect(view.textContainerInset.left >= safeLeft + 12)
        #expect(view.textContainerInset.right >= safeRight + 14)
    }

    @Test
    func horizontalChangesPreserveNavigationAndKeyboardInsets() {
        let controller = UIViewController()
        let navigation = UINavigationController(rootViewController: controller)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        window.rootViewController = navigation
        window.isHidden = false
        defer { window.isHidden = true }
        let view = AttachmentTextView(frame: controller.view.bounds)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.contentInsetAdjustmentBehavior = .scrollableAxes
        controller.view.addSubview(view)
        view.text = String(repeating: "Body text ", count: 100)
        for keyboardSpace: CGFloat in [0, 300, 0] {
            // App-owned bottom space, as used for keyboard/suggestion avoidance.
            view.contentInset.bottom = keyboardSpace
            controller.additionalSafeAreaInsets = .zero
            settle(window)
            settle(view)
            let adjusted = view.adjustedContentInset
            let textInsets = view.textContainerInset
            view.contentOffset.y = -adjusted.top
            controller.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 44, bottom: 0, right: 24)
            settle(window)
            settle(view)
            #expect(view.adjustedContentInset.top == adjusted.top)
            #expect(view.adjustedContentInset.bottom == adjusted.bottom)
            #expect(view.textContainerInset.top == textInsets.top)
            #expect(view.textContainerInset.bottom == textInsets.bottom)
            #expect(view.contentOffset.y == -adjusted.top)
            #expect(view.contentInset.bottom == keyboardSpace)
        }
    }

    @Test
    func wrappedCWUpdatesForSafeAreaOnlyChangesAndSmallFullWidthLeading() {
        let (window, controller, view) = makeWindow()
        defer { window.isHidden = true }
        view.contentInsetAdjustmentBehavior = .scrollableAxes
        let cw = UILabel()
        cw.numberOfLines = 0
        cw.text = String(repeating: "Content warning ", count: 30)
        view.topAttachmentsView.addArrangedSubview(cw)
        view.leadingAttachmentsView.addArrangedSubview(box(width: 10, height: 10))
        view.leadingAttachmentsHorizontalLayout = .fullWidth
        settle(window)
        settle(view)
        let originalTop = view.textContainerInset.top
        for rtl in [false, true] {
            view.semanticContentAttribute = rtl ? .forceRightToLeft : .forceLeftToRight
            controller.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 100, bottom: 0, right: 120)
            settle(window)
            settle(view)
            #expect(view.textContainerInset.top > originalTop)
            #expect(view.textContainerInset.left == 100)
            #expect(view.textContainerInset.right == 120)
            #expect(view.textContainerInset.top == 8 + cw.bounds.height)
        }
    }

    @Test
    func fullWidthSlotCanContainSafeAreaWrappedControls() {
        let (window, controller, view) = makeWindow()
        defer { window.isHidden = true }
        view.contentInsetAdjustmentBehavior = .scrollableAxes
        controller.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 44, bottom: 0, right: 24)
        view.bottomAttachmentsHorizontalLayout = .fullWidth
        let wrapper = UIView()
        let control = box(width: nil, height: 40)
        wrapper.addSubview(control)
        control.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            control.leadingAnchor.constraint(equalTo: wrapper.safeAreaLayoutGuide.leadingAnchor),
            control.trailingAnchor.constraint(equalTo: wrapper.safeAreaLayoutGuide.trailingAnchor),
            control.topAnchor.constraint(equalTo: wrapper.topAnchor),
            control.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
        ])
        view.bottomAttachmentsView.addArrangedSubview(wrapper)
        settle(window)
        settle(view)
        let frame = control.convert(control.bounds, to: view)
        #expect(frame.minX == view.safeAreaLayoutGuide.layoutFrame.minX)
        #expect(frame.maxX == view.safeAreaLayoutGuide.layoutFrame.maxX)
    }

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

    private func makeWindow() -> (UIWindow, UIViewController, AttachmentTextView) {
        let controller = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
        window.rootViewController = controller
        window.isHidden = false
        let view = AttachmentTextView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.addSubview(view)
        NSLayoutConstraint.activate([
            view.leftAnchor.constraint(equalTo: controller.view.leftAnchor),
            view.rightAnchor.constraint(equalTo: controller.view.rightAnchor),
            view.topAnchor.constraint(equalTo: controller.view.topAnchor),
            view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor),
        ])
        return (window, controller, view)
    }
}

@MainActor
private final class InsetTrackingTextView: AttachmentTextView {
    var insetWriteCount = 0

    override var textContainerInset: UIEdgeInsets {
        didSet { insetWriteCount += 1 }
    }
}
