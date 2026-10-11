import UIKit

/// Receives notifications from a ``TokenTextView``.
@MainActor
public protocol TokenTextViewDelegate: AnyObject {
    /// Called after text or selection changes so the host can update editor-adjacent UI.
    func tokenTextViewDidChangeEditingState(_ textView: TokenTextView)

    /// Called after text changes. `changedRange` is in the updated text; `nil` means the full text changed.
    func tokenTextView(_ textView: TokenTextView, didChangeTextIn changedRange: NSRange?)
}

public extension TokenTextViewDelegate {
    func tokenTextViewDidChangeEditingState(_ textView: TokenTextView) {}

    func tokenTextView(_ textView: TokenTextView, didChangeTextIn changedRange: NSRange?) {}
}
