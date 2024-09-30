
import Testing
import UIKit
@testable import ComposeEditor

@MainActor
@Suite
struct DelegateTest {
    @Test
    func checkCallDelegates() {
        class Delegator: NSObject, UITextViewDelegate {
            var textViewDidChange: Int = 0
            var shouldChangeTextIn: Int = 0
            
            func textViewDidChange(_ textView: UITextView) {
                textViewDidChange += 1
            }
            
            func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
                shouldChangeTextIn += 1
                return true
            }
        }
        
        let delegator = Delegator()
        let textView = UITextView()
        textView.delegate = delegator
        
        textView.text = "Original"
        let textRage = textView.textRange(from: textView.beginningOfDocument, to: textView.endOfDocument)!
        textView.replace(textRage, withText: "Changed")
        
        #expect(delegator.textViewDidChange == 1)
        #expect(delegator.shouldChangeTextIn == 0)
    }
    
    @Test
    func checkCallDelegates2() {
        class Delegator: NSObject, UITextViewDelegate {
            var textViewDidChange: Int = 0
            var shouldChangeTextIn: Int = 0
            
            func textViewDidChange(_ textView: UITextView) {
                textViewDidChange += 1
            }
            
            func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
                shouldChangeTextIn += 1
                return true
            }
        }
        
        let delegator = Delegator()
        let textView = ComposeTextView()
        textView.delegate = delegator
        
        textView.text = "Original"
        let textRage = textView.textRange(from: textView.beginningOfDocument, to: textView.endOfDocument)!
        textView.virtualKeyboard.replaceText(textRage, withText: "Changed")
        
        #expect(delegator.textViewDidChange == 1)
        #expect(delegator.shouldChangeTextIn == 1)
    }
}
