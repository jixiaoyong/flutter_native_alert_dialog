import Flutter
import UIKit
import XCTest


@testable import native_alert_dialog

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {

  func testURLTrustBoundaryAndNestedArguments() {
    XCTAssertTrue(NativeAlertDialogPlugin.isWebURL(URL(string: "http://example.com")))
    XCTAssertTrue(NativeAlertDialogPlugin.isWebURL(URL(string: "https://example.com")))
    XCTAssertFalse(NativeAlertDialogPlugin.isWebURL(URL(string: "javascript:alert(1)")))
    XCTAssertFalse(NativeAlertDialogPlugin.validArguments(["title": "错误参数", "desSpans": [42]], method: "showDialog"))
    XCTAssertTrue(NativeAlertDialogPlugin.validArguments(["title": "提示", "cancelText": NSNull(), "isDismissOnTouchOutside": true], method: "showDialog"))
  }

  func testSpecialKeyCallbackAndSingleCompletion() {
    let key = "协议/'\"&?#\\\n中文"
    var callbacks: [String] = []
    var results: [Bool] = []
    let dialog = DialogViewController(title: "提示", desSpans: [MessageSpan(text: "链接", clickable: true, color: nil, clickKey: key)], confirmText: "确定", onDesSpanTap: { callbacks.append($0) }, completion: { results.append($0) })
    XCTAssertFalse(dialog.textView(UITextView(), shouldInteractWith: URL(string: "nativealert://span/0")!, in: NSRange(location: 0, length: 1), interaction: .invokeDefaultAction))
    XCTAssertEqual(callbacks, [key])
    dialog.viewDidDisappear(false)
    dialog.viewDidDisappear(false)
    XCTAssertEqual(results, [false])
  }

  func testClickableSpanKeepsOriginalStyleAndIndexOnlyURL() {
    let dialog = DialogViewController(title: "提示", desSpans: [
      MessageSpan(text: "点击此协议链接", clickable: true, color: nil, clickKey: "协议'\"&?#中文/换行\n结束")
    ], confirmText: "确定", completion: { _ in })
    dialog.loadViewIfNeeded()
    func textView(in view: UIView) -> UITextView? {
      if let text = view as? UITextView { return text }
      return view.subviews.compactMap { textView(in: $0) }.first
    }
    guard let text = textView(in: dialog.view) else { return XCTFail("缺少原生富文本") }
    XCTAssertNil(text.attributedText.attribute(.underlineStyle, at: 0, effectiveRange: nil))
    XCTAssertEqual(text.attributedText.attribute(.link, at: 0, effectiveRange: nil) as? String, "nativealert://span/0")
  }

  func testThemeColorArgumentsAndARGBDecoding() {
    for value: Any in [NSNumber(value: UInt32(0)), NSNumber(value: UInt32.max), NSNumber(value: Int64(0x80123456))] {
      XCTAssertTrue(NativeAlertDialogPlugin.validArguments(["title": "提示", "themeColor": value], method: "showDialog"))
    }
    XCTAssertTrue(NativeAlertDialogPlugin.validArguments(["title": "提示", "themeColor": NSNull()], method: "showDialog"))
    let invalid: [Any] = [true, false, -1, Int64(0x100000000), UInt64.max, 1.5,
      NSNumber(value: 4294967295.0), Double.nan, Double.infinity, "0xff123456", [], [:]]
    for value in invalid {
      XCTAssertNil(NativeAlertDialogPlugin.themeColor(from: value), "\(value)")
      XCTAssertFalse(NativeAlertDialogPlugin.validArguments(["title": "提示", "themeColor": value], method: "showDialog"), "\(value)")
      var received: FlutterError?
      NativeAlertDialogPlugin().handle(FlutterMethodCall(methodName: "showDialog", arguments: ["title": "提示", "themeColor": value])) {
        received = $0 as? FlutterError
      }
      XCTAssertEqual(received?.code, "INVALID_ARGUMENTS")
    }
    let color = NativeAlertDialogPlugin.themeColor(from: NSNumber(value: Int64(0x80123456)))!
    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
    XCTAssertTrue(color.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
    XCTAssertEqual(red, 0x12 / 255.0, accuracy: 0.00001)
    XCTAssertEqual(green, 0x34 / 255.0, accuracy: 0.00001)
    XCTAssertEqual(blue, 0x56 / 255.0, accuracy: 0.00001)
    XCTAssertEqual(alpha, 0x80 / 255.0, accuracy: 0.00001)
  }

  func testDefaultThemeColorAndUnchangedStyles() {
    assertThemeColor(nil, expected: .systemBlue)
  }

  func testCustomThemeColorAndUnchangedStyles() {
    let color = NativeAlertDialogPlugin.themeColor(from: NSNumber(value: Int64(0x80123456)))!
    assertThemeColor(color, expected: color)
  }

  private func assertThemeColor(_ color: UIColor?, expected: UIColor, file: StaticString = #file, line: UInt = #line) {
    let dialog = DialogViewController(title: "提示", desSpans: [
      MessageSpan(text: "正文", clickable: false, color: nil, clickKey: nil),
      MessageSpan(text: "链接", clickable: true, color: .red, clickKey: "协议")
    ], cancelText: "取消", confirmText: "确定", themeColor: color, completion: { _ in })
    dialog.loadViewIfNeeded()
    func descendants(_ view: UIView) -> [UIView] { [view] + view.subviews.flatMap { descendants($0) } }
    let views = descendants(dialog.view)
    guard let text = views.compactMap({ $0 as? UITextView }).first,
      let confirm = views.compactMap({ $0 as? UIButton }).first(where: { $0.title(for: .normal) == "确定" }),
      let cancel = views.compactMap({ $0 as? UIButton }).first(where: { $0.title(for: .normal) == "取消" })
    else { return XCTFail("缺少原生弹窗控件", file: file, line: line) }
    XCTAssertEqual(confirm.backgroundColor, expected, file: file, line: line)
    XCTAssertEqual(confirm.titleColor(for: .normal), .white, file: file, line: line)
    XCTAssertEqual(cancel.backgroundColor, UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1), file: file, line: line)
    XCTAssertEqual(cancel.titleColor(for: .normal), UIColor(white: 0.67, alpha: 1), file: file, line: line)
    XCTAssertEqual(text.attributedText.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor,
      UIColor(red: 0x99 / 255.0, green: 0x99 / 255.0, blue: 0x99 / 255.0, alpha: 1), file: file, line: line)
    XCTAssertEqual(text.attributedText.attribute(.foregroundColor, at: 2, effectiveRange: nil) as? UIColor, expected, file: file, line: line)
    XCTAssertNil(text.attributedText.attribute(.underlineStyle, at: 2, effectiveRange: nil), file: file, line: line)
    XCTAssertTrue(text.linkTextAttributes.isEmpty, file: file, line: line)
  }

  func testGetPlatformVersion() {
    let plugin = NativeAlertDialogPlugin()

    let call = FlutterMethodCall(methodName: "getPlatformVersion", arguments: [])

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertEqual(result as! String, "iOS " + UIDevice.current.systemVersion)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

}
