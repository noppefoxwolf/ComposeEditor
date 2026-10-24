import Testing
import UIKit
@testable import TokenTextView

@Suite
@MainActor
struct UndoSelectionTests {
    private final class UndoTextView: TokenTextView {
        let history = UndoManager()

        override var undoManager: UndoManager? { history }
    }

    @Test(arguments: [false, true])
    func undoAndRedoRestoreTextAttributesAndSelection(selectsRange: Bool) {
        let textView = UndoTextView(frame: .zero, textContainer: nil)
        let original = NSAttributedString(string: "😀 original", attributes: [.foregroundColor: UIColor.systemOrange])
        let edited = NSAttributedString(string: "😀 edited", attributes: [.foregroundColor: UIColor.systemGreen])
        let originalSelection = NSRange(location: 3, length: selectsRange ? 4 : 0)
        let editedSelection = NSRange(location: 2, length: selectsRange ? 3 : 0)
        textView.attributedText = edited
        textView.selectedRange = editedSelection
        textView.history.removeAllActions()
        textView.history.groupsByEvent = false
        textView.history.beginUndoGrouping()
        textView.registerUndo(toRestore: original, selection: originalSelection)
        textView.history.endUndoGrouping()

        textView.history.undo()

        #expect(textView.attributedText.isEqual(to: original))
        #expect(textView.selectedRange == originalSelection)
        #expect(textView.history.canRedo)

        textView.history.redo()

        #expect(textView.attributedText.isEqual(to: edited))
        #expect(textView.selectedRange == editedSelection)
    }
}
