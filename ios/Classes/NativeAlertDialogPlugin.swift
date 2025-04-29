import Flutter
import UIKit

public class NativeAlertDialogPlugin: NSObject, FlutterPlugin {
  private var channel: FlutterMethodChannel?
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "native_alert_dialog", binaryMessenger: registrar.messenger())
    let instance = NativeAlertDialogPlugin()
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "showDialog":
      guard let args = call.arguments as? [String: Any],
            let title = args["title"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
        return
      }
      
      let cancelText = args["cancelText"] as? String ?? "取消"
      let confirmText = args["confirmText"] as? String ?? "确定"
      let desText = args["desText"] as? String
      let desSpans = args["desSpans"] as? [[String: Any]]
      DispatchQueue.main.async {
        self.showNativeDialog(
          title: title,
          desText: desText,
          desSpans: desSpans,
          cancelText: cancelText,
          confirmText: confirmText,
          channel: self.channel,
          completion: result
        )
      }
      
    case "showToast":
      guard let args = call.arguments as? [String: Any],
            let message = args["message"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
        return
      }
      
      let duration = args["duration"] as? Int ?? 2000
      
      DispatchQueue.main.async {
        self.showToast(message: message, duration: duration)
        result(nil)
      }
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func showNativeDialog(title: String, desText: String?, desSpans: [[String: Any]]?, cancelText: String, confirmText: String, channel: FlutterMethodChannel?, completion: @escaping FlutterResult) {
    // 获取当前最顶层的视图控制器
    guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else {
      completion(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Unable to find view controller", details: nil))
      return
    }
    var topController = rootVC
    while let presented = topController.presentedViewController {
      topController = presented
    }
    
    // 解析 desSpans
    var spans: [MessageSpan]? = nil
    if let desSpans = desSpans {
      spans = desSpans.compactMap { item in
        let text = item["text"] as? String ?? ""
        let clickable = item["clickable"] as? Bool ?? false
        let colorHex = item["color"] as? String
        let clickKey = item["clickKey"] as? String
          let color: UIColor? = colorHex != nil ? UIColor(named: colorHex!) : nil
        return MessageSpan(text: text, clickable: clickable, color: color, clickKey: clickKey)
      }
    }
    let dialogVC = DialogViewController(
      title: title,
      desText: desText,
      desSpans: spans,
      cancelText: cancelText,
      confirmText: confirmText,
      onDesSpanTap: { key in
        channel?.invokeMethod("onDesSpanTap", arguments: ["key": key])
      },
      completion: completion
    )
    topController.present(dialogVC, animated: true, completion: nil)
  }
  
  private func showToast(message: String, duration: Int) {
    guard let window = UIApplication.shared.keyWindow else { return }
    
    let screenWidth = window.frame.width
    let scale = screenWidth / 375.0
    let sideMargin: CGFloat = 30 * scale // 左右间距
    let bottomMargin: CGFloat = 80 * scale // 距离底部
    
    let toastLabel = UILabel()
    toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
    toastLabel.textColor = UIColor.white
    toastLabel.textAlignment = .center
    toastLabel.font = UIFont.systemFont(ofSize: 14 * scale)
    toastLabel.text = message
    toastLabel.alpha = 0
    toastLabel.layer.cornerRadius = 10 * scale
    toastLabel.clipsToBounds = true
    
    let maxSize = CGSize(width: screenWidth - 2 * sideMargin, height: 200 * scale)
    var expectedSize = toastLabel.sizeThatFits(maxSize)
    expectedSize.width = min(maxSize.width, expectedSize.width + 20 * scale)
    expectedSize.height = min(maxSize.height, expectedSize.height + 20 * scale)
    
    toastLabel.frame = CGRect(x: 0, y: 0, width: expectedSize.width, height: expectedSize.height)
    let centerX = screenWidth / 2
    let centerY = window.frame.height - bottomMargin - expectedSize.height / 2
    toastLabel.center = CGPoint(x: centerX, y: centerY)
    
    window.addSubview(toastLabel)
    
    UIView.animate(withDuration: 0.3, animations: {
      toastLabel.alpha = 1
    }, completion: { _ in
      UIView.animate(withDuration: 0.3, delay: Double(duration) / 1000, options: [], animations: {
        toastLabel.alpha = 0
      }, completion: { _ in
        toastLabel.removeFromSuperview()
      })
    })
  }
}
