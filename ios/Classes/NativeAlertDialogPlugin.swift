import Flutter
import UIKit
import WebKit

class WebViewController: UIViewController {
    private let webView = WKWebView(frame: .zero)
    private let titleLabel = UILabel()
    private let backButton = UIButton(type: .custom)
    private let titleBar = UIView()
    
    private let urlString: String
    private let pageTitle: String?
    
    init(url: String, title: String?) {
        self.urlString = url
        self.pageTitle = title
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        // 设置标题栏
        titleBar.backgroundColor = .white
        view.addSubview(titleBar)
        titleBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            titleBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            titleBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            titleBar.heightAnchor.constraint(equalToConstant: 48)
        ])
        
        // 设置返回按钮
        let backImage = drawBackButton()
        backButton.setImage(backImage, for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        titleBar.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: titleBar.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: titleBar.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 48),
            backButton.heightAnchor.constraint(equalToConstant: 48)
        ])
        
        // 设置标题
        titleLabel.textAlignment = .center
        titleLabel.textColor = .black
        titleLabel.font = .systemFont(ofSize: 17)
        titleBar.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: titleBar.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: titleBar.trailingAnchor, constant: -48)
        ])
        
        // 设置 WebView
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: pageTitle != nil ? titleBar.bottomAnchor : view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 加载 URL
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        
        // 设置标题栏可见性
        titleBar.isHidden = pageTitle == nil
        if let title = pageTitle {
            titleLabel.text = title
        }
    }
    
    private func drawBackButton() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24))
        return renderer.image { context in
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 15.5959, y: 4.40354))
            path.addCurve(to: CGPoint(x: 13.743, y: 4.35369), controlPoint1: CGPoint(x: 15.0895, y: 3.88539), controlPoint2: CGPoint(x: 14.2753, y: 3.86348))
            path.addLine(to: CGPoint(x: 7.89716, y: 9.7369))
            path.addCurve(to: CGPoint(x: 7.69572, y: 13.653), controlPoint1: CGPoint(x: 6.78464, y: 10.7614), controlPoint2: CGPoint(x: 6.69445, y: 12.5147))
            path.addCurve(to: CGPoint(x: 7.89716, y: 13.8591), controlPoint1: CGPoint(x: 7.75928, y: 13.7253), controlPoint2: CGPoint(x: 7.82653, y: 13.7941))
            path.addLine(to: CGPoint(x: 13.743, y: 19.2423))
            path.addCurve(to: CGPoint(x: 15.5959, y: 19.1925), controlPoint1: CGPoint(x: 14.2753, y: 19.7325), controlPoint2: CGPoint(x: 15.0895, y: 19.7106))
            path.addCurve(to: CGPoint(x: 15.6679, y: 17.2757), controlPoint1: CGPoint(x: 16.1057, y: 18.6709), controlPoint2: CGPoint(x: 16.137, y: 17.8357))
            path.addLine(to: CGPoint(x: 11.835, y: 12.7003))
            path.addCurve(to: CGPoint(x: 11.835, y: 10.8957), controlPoint1: CGPoint(x: 11.4, y: 12.1811), controlPoint2: CGPoint(x: 11.4, y: 11.4149))
            path.addLine(to: CGPoint(x: 15.6679, y: 6.32032))
            path.addCurve(to: CGPoint(x: 15.5959, y: 4.40354), controlPoint1: CGPoint(x: 16.137, y: 5.76029), controlPoint2: CGPoint(x: 16.1057, y: 4.92511))
            path.close()
            
            UIColor.black.setFill()
            path.fill()
        }
    }
    
    @objc private func backButtonTapped() {
        if webView.canGoBack {
            webView.goBack()
        } else {
            dismiss(animated: true)
        }
    }
}

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
      
    case "openUrl":
      guard let args = call.arguments as? [String: Any],
            let url = args["url"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
        return
      }
      
      let title = args["title"] as? String
      
      DispatchQueue.main.async {
        self.openUrl(url: url, title: title)
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
  
  private func openUrl(url: String, title: String?) {
    guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else { return }
    var topController = rootVC
    while let presented = topController.presentedViewController {
      topController = presented
    }
    
    let webVC = WebViewController(url: url, title: title)
    webVC.modalPresentationStyle = .fullScreen
    topController.present(webVC, animated: true)
  }
}
