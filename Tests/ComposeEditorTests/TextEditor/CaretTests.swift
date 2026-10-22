import Testing
import UIKit
@testable import ComposeEditor

@MainActor
@Suite
struct UITextViewCaretTests {
    @Test
    func testVisualText() throws {
        let textView = ComposeTextView()
        
        let attributedText = NSMutableAttributedString("👨‍👩‍👧‍👦Hello, World!")
        attributedText.append(NSAttributedString(attachment: TextAttachment("⭐")))
        textView.attributedText = attributedText
        
        textView.selectedTextRange = textView.textRange(
            from: textView.beginningOfDocument,
            to: textView.endOfDocument
        )
        #expect(textView.visualText == "[👨‍👩‍👧‍👦Hello, World!⭐]")
    }
    
    @Test
    func testReplaceText() async throws {
        let textView = ComposeTextView()
        
        let attributedText = NSMutableAttributedString("👨‍👩‍👧‍👦Hello, World!")
        attributedText.append(NSAttributedString(attachment: TextAttachment("⭐")))
        textView.attributedText = attributedText
        
        let textRange = textView.textRange(
            from: textView.endOfDocument,
            to: textView.endOfDocument
        )!
        textView.selectedTextRange = textRange
        
        #expect(textView.visualText == "👨‍👩‍👧‍👦Hello, World!⭐[]")
        
        textView.virtualKeyboard.replaceText(textRange, withText: "Hello")
        
        #expect(textView.visualText == "👨‍👩‍👧‍👦Hello, World!⭐Hello[]")
    }
    
    @Test
    func testInsertText() async throws {
        let textView = ComposeTextView()
        
        let attributedText = NSMutableAttributedString("👨‍👩‍👧‍👦Hello, World!")
        attributedText.append(NSAttributedString(attachment: TextAttachment("⭐")))
        textView.attributedText = attributedText
        
        let textRange = textView.textRange(
            from: textView.endOfDocument,
            to: textView.endOfDocument
        )!
        textView.selectedTextRange = textRange
        
        #expect(textView.visualText == "👨‍👩‍👧‍👦Hello, World!⭐[]")
        
        textView.virtualKeyboard.insertText("Hello")
        
        #expect(textView.visualText == "👨‍👩‍👧‍👦Hello, World!⭐Hello[]")
    }
    
    @Test
    func testInsertTextWithSpace() async throws {
        let textView = ComposeTextView()
        
        let attributedText = NSMutableAttributedString("👨‍👩‍👧‍👦Hello, World!")
        attributedText.append(NSAttributedString(attachment: TextAttachment("⭐")))
        textView.attributedText = attributedText
        
        let textRange = textView.textRange(
            from: textView.endOfDocument,
            to: textView.endOfDocument
        )!
        textView.selectedTextRange = textRange
        
        #expect(textView.visualText == "👨‍👩‍👧‍👦Hello, World!⭐[]")
        
        textView.virtualKeyboard.insertText("Hello", smartInsert: true)
        
        #expect(textView.visualText == "👨‍👩‍👧‍👦Hello, World!⭐ Hello[]")
    }
    
    @Test
    func testInsertTextBetweenEmoji() async throws {
        let textView = ComposeTextView()
        
        let attributedText = NSMutableAttributedString("")
        attributedText.append(NSAttributedString(attachment: TextAttachment("1️⃣")))
        attributedText.append(NSAttributedString(attachment: TextAttachment("2️⃣")))
        textView.attributedText = attributedText
        
        let position = textView.position(from: textView.beginningOfDocument, offset: 1)!
        let textRange = textView.textRange(
            from: position,
            to: position
        )!
        textView.selectedTextRange = textRange
        
        #expect(textView.visualText == "1️⃣[]2️⃣")
        
        textView.virtualKeyboard.insertText("3️⃣")
        
        #expect(textView.visualText == "1️⃣3️⃣[]2️⃣")
    }
    
    @Test
    func testAppendText() async throws {
        let textView = ComposeTextView()
        
        let attributedText = NSMutableAttributedString("👨‍👩‍👧‍👦Hello, World!")
        attributedText.append(NSAttributedString(attachment: TextAttachment("⭐")))
        textView.attributedText = attributedText
        
        let textRange = textView.textRange(
            from: textView.endOfDocument,
            to: textView.endOfDocument
        )!
        textView.selectedTextRange = textRange
        
        #expect(textView.visualText == "👨‍👩‍👧‍👦Hello, World!⭐[]")
        
        textView.virtualKeyboard.appendText("Hello")
        
        #expect(textView.visualText == "👨‍👩‍👧‍👦Hello, World!⭐[]Hello")
    }
}

final class TextAttachment: NSTextAttachment {
    
    let emoji: String
    
    init(_ emoji: String) {
        self.emoji = emoji
        super.init(data: nil, ofType: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func image(
        forBounds imageBounds: CGRect,
        textContainer: NSTextContainer?,
        characterIndex charIndex: Int
    ) -> UIImage? {
        UIImage(systemName: "apple.logo")
    }
}

extension UITextView {
    var visualText: String {
        
        let attributedText = NSMutableAttributedString(attributedString: attributedText!)
        let selectedAttributedText = NSMutableAttributedString(
            attributedString: attributedText.attributedSubstring(from: selectedRange)
        )
        selectedAttributedText.insert(NSAttributedString("["), at: 0)
        selectedAttributedText.append(NSAttributedString("]"))
        
        attributedText.replaceCharacters(in: selectedRange, with: selectedAttributedText)
        
        var output = ""
        let range = NSRange(location: 0, length: attributedText.length)
        attributedText.enumerateAttributes(
            in: range,
            using: { attributes, range, _ in
                if let attachment = attributes[.attachment] {
                    output += (attachment as!TextAttachment).emoji
                } else {
                    output += attributedText.attributedSubstring(from: range).string
                }
            }
        )
        return output
    }
}
