import XCTest
import UIKit
@testable import native_alert_dialog

final class NativeAlertDialogTests: XCTestCase {
  func testWebURLTrustBoundaryKeepsHTTP() {
    for value in ["http://example.com", "https://example.com/path", "HTTPS://example.com"] {
      XCTAssertTrue(NativeAlertDialogPlugin.isWebURL(URL(string: value)), value)
    }
    for value in ["file:///tmp/test.html", "javascript:alert(1)", "data:text/html,test", "//example.com", "https:"] {
      XCTAssertFalse(NativeAlertDialogPlugin.isWebURL(URL(string: value)), value)
    }
  }

  func testNestedArgumentsAndCodeupOptions() {
    XCTAssertTrue(NativeAlertDialogPlugin.validArguments([
      "title": "提示", "cancelText": NSNull(), "desTextAlign": "left",
      "isDismissOnTouchOutside": true,
      "desSpans": [["text": "链接", "clickable": true, "clickKey": "a/'\"?%#\n中文"]],
    ], method: "showDialog"))
    for spans: Any in [["not a map"], [["text": 1]], [["text": "x", "clickable": "true"]], [["text": "x", "clickKey": 1]]] {
      XCTAssertFalse(NativeAlertDialogPlugin.validArguments(["title": "提示", "desSpans": spans], method: "showDialog"))
    }
    XCTAssertFalse(NativeAlertDialogPlugin.validArguments(["title": "提示", "desText": "x", "desSpans": []], method: "showDialog"))
    XCTAssertTrue(NativeAlertDialogPlugin.validArguments(["message": NSNull(), "dismissOnTouchOutside": true], method: "showLoading"))
    XCTAssertFalse(NativeAlertDialogPlugin.validArguments(["dismissOnTouchOutside": 1], method: "showLoading"))
    XCTAssertFalse(NativeAlertDialogPlugin.validArguments(["message": "x", "duration": true], method: "showToast"))
  }

  func testSpecialClickKeyRoundTripsWithoutURLOrJSInterpolation() {
    let key = "a/'\"?%#\\\n\u{2028}中文"
    var callbacks: [String] = []
    let dialog = DialogViewController(
      title: "提示", desSpans: [MessageSpan(text: "链接", clickable: true, color: nil, clickKey: key)],
      confirmText: "确定", onDesSpanTap: { callbacks.append($0) }, completion: { _ in })
    XCTAssertFalse(dialog.textView(UITextView(), shouldInteractWith: URL(string: "nativealert://span/0")!, in: NSRange(location: 0, length: 1), interaction: .invokeDefaultAction))
    XCTAssertEqual(callbacks, [key])
    XCTAssertFalse(dialog.textView(UITextView(), shouldInteractWith: URL(string: "nativealert://span/99")!, in: NSRange(location: 0, length: 1), interaction: .invokeDefaultAction))
    XCTAssertEqual(callbacks.count, 1)
  }

  func testExternalDismissalCompletesOnlyOnce() {
    var results: [Bool] = []
    let dialog = DialogViewController(title: "提示", confirmText: "确定", completion: { results.append($0) })
    dialog.viewDidDisappear(false)
    dialog.viewDidDisappear(false)
    XCTAssertEqual(results, [false])
  }
}
