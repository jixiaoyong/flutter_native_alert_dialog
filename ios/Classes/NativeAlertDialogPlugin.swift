import Flutter
import UIKit
import WebKit
import CoreFoundation

public class WebViewController: UIViewController, WKNavigationDelegate {
  private var webView: WKWebView!
  private let titleLabel = UILabel()
  private let backButton = UIButton(type: .custom)
  private let titleBar = UIView()

  private let urlString: String
  private let pageTitle: String?

  public init(url: String, title: String?) {
    self.urlString = url
    self.pageTitle = title
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .white

    // 配置 WebView
    let configuration = WKWebViewConfiguration()
    let contentController = WKUserContentController()

    // 添加 viewport meta 标签
    let viewportScript = WKUserScript(
      source:
        "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'); document.getElementsByTagName('head')[0].appendChild(meta);",
      injectionTime: .atDocumentEnd,
      forMainFrameOnly: true
    )
    contentController.addUserScript(viewportScript)
    configuration.userContentController = contentController

    // 创建新的 WebView 实例
    webView = WKWebView(frame: .zero, configuration: configuration)
    webView.navigationDelegate = self

    // 设置 WebView 的其他属性
    webView.scrollView.bounces = true
    webView.scrollView.alwaysBounceVertical = true
    webView.allowsBackForwardNavigationGestures = true

    // 设置标题栏
    titleBar.backgroundColor = .white
    view.addSubview(titleBar)
    titleBar.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      titleBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      titleBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      titleBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      titleBar.heightAnchor.constraint(equalToConstant: 48),
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
      backButton.heightAnchor.constraint(equalToConstant: 48),
    ])

    // 独立关闭入口不依赖标题或网页历史记录。
    backButton.accessibilityLabel = "返回"
    let closeButton = UIButton(type: .system)
    closeButton.setTitle("关闭", for: .normal)
    closeButton.accessibilityLabel = "关闭网页"
    closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    closeButton.translatesAutoresizingMaskIntoConstraints = false
    titleBar.addSubview(closeButton)
    NSLayoutConstraint.activate([
      closeButton.trailingAnchor.constraint(equalTo: titleBar.trailingAnchor),
      closeButton.centerYAnchor.constraint(equalTo: titleBar.centerYAnchor),
      closeButton.widthAnchor.constraint(equalToConstant: 48),
      closeButton.heightAnchor.constraint(equalToConstant: 48),
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
      titleLabel.trailingAnchor.constraint(equalTo: titleBar.trailingAnchor, constant: -48),
    ])

    // 设置 WebView
    view.addSubview(webView)
    webView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      webView.topAnchor.constraint(equalTo: titleBar.bottomAnchor),
      webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    // 加载 URL
    if let url = URL(string: urlString) {
      var request = URLRequest(url: url)
      // 设置 User-Agent 为移动设备
      request.setValue(
        "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1",
        forHTTPHeaderField: "User-Agent")
      webView.load(request)
    }

    // 设置标题
    if let title = pageTitle {
      titleLabel.text = title
      titleLabel.isHidden = false
    } else {
      titleLabel.isHidden = true
    }
  }

  private func drawBackButton() -> UIImage? {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24))
    return renderer.image { context in
      let path = UIBezierPath()
      path.move(to: CGPoint(x: 15.5959, y: 4.40354))
      path.addCurve(
        to: CGPoint(x: 13.743, y: 4.35369), controlPoint1: CGPoint(x: 15.0895, y: 3.88539),
        controlPoint2: CGPoint(x: 14.2753, y: 3.86348))
      path.addLine(to: CGPoint(x: 7.89716, y: 9.7369))
      path.addCurve(
        to: CGPoint(x: 7.69572, y: 13.653), controlPoint1: CGPoint(x: 6.78464, y: 10.7614),
        controlPoint2: CGPoint(x: 6.69445, y: 12.5147))
      path.addCurve(
        to: CGPoint(x: 7.89716, y: 13.8591), controlPoint1: CGPoint(x: 7.75928, y: 13.7253),
        controlPoint2: CGPoint(x: 7.82653, y: 13.7941))
      path.addLine(to: CGPoint(x: 13.743, y: 19.2423))
      path.addCurve(
        to: CGPoint(x: 15.5959, y: 19.1925), controlPoint1: CGPoint(x: 14.2753, y: 19.7325),
        controlPoint2: CGPoint(x: 15.0895, y: 19.7106))
      path.addCurve(
        to: CGPoint(x: 15.6679, y: 17.2757), controlPoint1: CGPoint(x: 16.1057, y: 18.6709),
        controlPoint2: CGPoint(x: 16.137, y: 17.8357))
      path.addLine(to: CGPoint(x: 11.835, y: 12.7003))
      path.addCurve(
        to: CGPoint(x: 11.835, y: 10.8957), controlPoint1: CGPoint(x: 11.4, y: 12.1811),
        controlPoint2: CGPoint(x: 11.4, y: 11.4149))
      path.addLine(to: CGPoint(x: 15.6679, y: 6.32032))
      path.addCurve(
        to: CGPoint(x: 15.5959, y: 4.40354), controlPoint1: CGPoint(x: 16.137, y: 5.76029),
        controlPoint2: CGPoint(x: 16.1057, y: 4.92511))
      path.close()

      UIColor.black.setFill()
      path.fill()
    }
  }

  @objc private func closeButtonTapped() {
    dismiss(animated: true)
  }

  public func webView(
    _ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
  ) {
    // 仅允许明确的 HTTP(S) 页面，禁止跳转到本地文件或自定义执行协议。
    decisionHandler(NativeAlertDialogPlugin.isWebURL(navigationAction.request.url) ? .allow : .cancel)
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
    let channel = FlutterMethodChannel(
      name: "io.github.jixiaoyong.native_alert_dialog", binaryMessenger: registrar.messenger())
    let instance = NativeAlertDialogPlugin()
    instance.channel = channel
    instance.hostViewController = registrar.viewController
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  static func isWebURL(_ url: URL?) -> Bool {
    guard let url = url, let scheme = url.scheme?.lowercased(),
      ["http", "https"].contains(scheme), let host = url.host, !host.isEmpty
    else { return false }
    return true
  }

  // Flutter ARGB uint32；拒绝 bool、浮点数及越界值后再转换。
  static func themeColor(from value: Any?) -> UIColor? {
    guard let number = value as? NSNumber,
      CFGetTypeID(number) != CFBooleanGetTypeID(),
      ["c", "s", "i", "l", "q", "C", "S", "I", "L", "Q"].contains(String(cString: number.objCType)),
      number.int64Value >= 0, number.uint64Value <= UInt64(UInt32.max)
    else { return nil }
    let argb = number.uint32Value
    return UIColor(
      red: CGFloat((argb >> 16) & 0xff) / 255,
      green: CGFloat((argb >> 8) & 0xff) / 255,
      blue: CGFloat(argb & 0xff) / 255,
      alpha: CGFloat((argb >> 24) & 0xff) / 255)
  }

  // NSNull 是 StandardMessageCodec 的合法可选值；其它错误类型不静默降级。
  static func validArguments(_ args: [String: Any], method: String) -> Bool {
    func optional(_ key: String, _ check: (Any) -> Bool) -> Bool {
      guard let value = args[key], !(value is NSNull) else { return true }
      return check(value)
    }
    let string: (Any) -> Bool = { $0 is String }
    let bool: (Any) -> Bool = {
      guard let number = $0 as? NSNumber else { return false }
      return CFGetTypeID(number) == CFBooleanGetTypeID()
    }
    switch method {
    case "showDialog":
      guard args["title"] is String,
        ["desText", "cancelText", "confirmText", "desTextAlign"].allSatisfy({ optional($0, string) }),
        optional("isDismissOnTouchOutside", bool),
        optional("themeColor", { Self.themeColor(from: $0) != nil }),
        optional("desTextAlign", { ["left", "right", "center", "justify", "start", "end"].contains($0 as? String ?? "") })
      else { return false }
      if let raw = args["desSpans"], !(raw is NSNull) {
        guard args["desText"] == nil || args["desText"] is NSNull,
          let spans = raw as? [[String: Any]] else { return false }
        for span in spans {
          guard span["text"] is String else { return false }
          if let value = span["clickable"], !bool(value) { return false }
          for key in ["color", "clickKey"] {
            if let value = span[key], !(value is NSNull), !string(value) { return false }
          }
        }
      }
      return true
    case "openUrl":
      guard let raw = args["url"] as? String else { return false }
      return isWebURL(URL(string: raw)) && optional("title", string)
    case "showLoading":
      return optional("message", string) && optional("dismissOnTouchOutside", bool)
    case "showToast":
      return args["message"] is String && optional("duration", {
        guard let number = $0 as? NSNumber, !bool(number) else { return false }
        return number.doubleValue.isFinite && number.doubleValue >= 0
          && number.doubleValue.rounded() == number.doubleValue && number.doubleValue <= Double(Int32.max)
      })
    default:
      return true
    }
  }

  private weak var hostViewController: UIViewController?

  private func activeWindow() -> UIWindow? {
    if let host = hostViewController {
      guard let window = host.viewIfLoaded?.window else { return nil }
      if #available(iOS 13.0, *), window.windowScene?.activationState != .foregroundActive {
        return nil
      }
      return window
    }
    if #available(iOS 13.0, *) {
      let windows = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        .filter { $0.activationState == .foregroundActive }
        .flatMap { $0.windows }.filter { $0.isKeyWindow }
      // 无法归属到唯一 Scene 时拒绝猜测，避免跨窗口展示。
      return windows.count == 1 ? windows[0] : nil
    }
    return UIApplication.shared.keyWindow
  }

  private func presenter(_ result: FlutterResult) -> UIViewController? {
    guard let root = activeWindow()?.rootViewController else {
      result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "No unambiguous active window", details: nil))
      return nil
    }
    var top = root
    while let presented = top.presentedViewController {
      if presented is DialogViewController || presented is LoadingViewController || presented is WebViewController {
        result(FlutterError(code: "PRESENTATION_CONFLICT", message: "A native dialog is already presented", details: nil))
        return nil
      }
      if top.isBeingPresented || top.isBeingDismissed || presented.isBeingPresented || presented.isBeingDismissed {
        result(FlutterError(code: "PRESENTATION_CONFLICT", message: "Presentation is transitioning", details: nil))
        return nil
      }
      top = presented
    }
    guard top.viewIfLoaded?.window != nil, !top.isBeingPresented, !top.isBeingDismissed,
      top.transitionCoordinator == nil else {
      result(FlutterError(code: "PRESENTATION_CONFLICT", message: "View controller is not ready", details: nil))
      return nil
    }
    return top
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if ["showDialog", "showToast", "openUrl", "showLoading"].contains(call.method) {
      guard let args = call.arguments as? [String: Any], Self.validArguments(args, method: call.method) else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
        return
      }
    }
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "showDialog":
      guard let args = call.arguments as? [String: Any],
        let title = args["title"] as? String
      else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
        return
      }

      let cancelText = args["cancelText"] as? String ?? nil
      let confirmText = args["confirmText"] as? String ?? "确定"
      let desText = args["desText"] as? String
      let desSpans = args["desSpans"] as? [[String: Any]]
      let desTextAlign = args["desTextAlign"] as? String
      DispatchQueue.main.async {
        self.showDialog(
          title: title,
          desText: desText,
          desSpans: desSpans,
          cancelText: cancelText,
          confirmText: confirmText,
          desTextAlign: desTextAlign,
          themeColor: Self.themeColor(from: args["themeColor"]),
          isDismissOnTouchOutside: args["isDismissOnTouchOutside"] as? Bool,
          channel: self.channel,
          completion: result
        )
      }

    case "showToast":
      guard let args = call.arguments as? [String: Any],
        let message = args["message"] as? String
      else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
        return
      }

      let duration = args["duration"] as? Int ?? 2000

      DispatchQueue.main.async {
        guard let window = self.activeWindow() else {
          result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "No unambiguous active window", details: nil))
          return
        }
        self.showToast(message: message, duration: duration, window: window)
        result(nil)
      }

    case "openUrl":
      guard let args = call.arguments as? [String: Any],
        let url = args["url"] as? String
      else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
        return
      }

      let title = args["title"] as? String

      DispatchQueue.main.async {
        guard let presenter = self.presenter(result) else { return }
        let webVC = WebViewController(url: url, title: title)
        webVC.modalPresentationStyle = .fullScreen
        presenter.present(webVC, animated: true) { result(nil) }
      }

    case "showLoading":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
        return
      }
      let message = args["message"] as? String
      let dismissOnTouchOutside = args["dismissOnTouchOutside"] as? Bool ?? false
      DispatchQueue.main.async {
        guard let presenter = self.presenter(result) else { return }
        let vc = LoadingViewController(message: message, dismissOnTouchOutside: dismissOnTouchOutside)
        self.loadingVC = vc
        presenter.present(vc, animated: true) { result(nil) }
      }
    case "hideLoading":
      DispatchQueue.main.async {
        guard let vc = self.loadingVC, vc.presentingViewController != nil else {
          self.loadingVC = nil
          result(nil)
          return
        }
        guard !vc.isBeingPresented, !vc.isBeingDismissed else {
          result(FlutterError(code: "PRESENTATION_CONFLICT", message: "Loading is transitioning", details: nil))
          return
        }
        vc.dismiss(animated: true) {
          self.loadingVC = nil
          result(nil)
        }
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func showDialog(
    title: String, desText: String?, desSpans: [[String: Any]]?, cancelText: String?,
    confirmText: String, desTextAlign: String?, themeColor: UIColor?,
    isDismissOnTouchOutside: Bool?,
    channel: FlutterMethodChannel?,
    completion: @escaping FlutterResult
  ) {
    guard let topController = presenter(completion) else { return }

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
      desTextAlign: desTextAlign,
      themeColor: themeColor,
      onDesSpanTap: { key in
        channel?.invokeMethod("onDesSpanTap", arguments: ["key": key])
      },
      completion: completion,
      isDismissOnTouchOutside: isDismissOnTouchOutside
    )
    topController.present(dialogVC, animated: true, completion: nil)
  }

  private func showToast(message: String, duration: Int, window: UIWindow) {

    let screenWidth = window.frame.width
    let scale = screenWidth / 375.0
    let sideMargin: CGFloat = 30 * scale  // 左右间距
    let bottomMargin: CGFloat = 80 * scale  // 距离底部

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

    UIView.animate(
      withDuration: 0.3,
      animations: {
        toastLabel.alpha = 1
      },
      completion: { _ in
        UIView.animate(
          withDuration: 0.3, delay: Double(duration) / 1000, options: [],
          animations: {
            toastLabel.alpha = 0
          },
          completion: { _ in
            toastLabel.removeFromSuperview()
          })
      })
  }

  // UIKit 持有已展示的 Loading；外部关闭后不保留失效控制器。
  private weak var loadingVC: LoadingViewController?
}

// 新增LoadingViewController
class LoadingViewController: UIViewController, UIGestureRecognizerDelegate {
  private weak var contentView: UIView?
  private let message: String?
  private let dismissOnTouchOutside: Bool

  init(message: String?, dismissOnTouchOutside: Bool) {
    self.message = message
    self.dismissOnTouchOutside = dismissOnTouchOutside
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .overFullScreen
    modalTransitionStyle = .crossDissolve
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor.black.withAlphaComponent(0.3)

    let container = UIView()
    contentView = container
    container.backgroundColor = UIColor.white
    container.layer.cornerRadius = 12
    container.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(container)

    let activity = UIActivityIndicatorView(style: .white)
    activity.color = .gray
    activity.startAnimating()
    activity.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(activity)

    var label: UILabel?
    if let message = message, !message.isEmpty {
      let lbl = UILabel()
      lbl.text = message
      lbl.textColor = .black
      lbl.font = .systemFont(ofSize: 16)
      lbl.textAlignment = .center
      lbl.numberOfLines = 0
      lbl.translatesAutoresizingMaskIntoConstraints = false
      container.addSubview(lbl)
      label = lbl
    }

    // 布局
    NSLayoutConstraint.activate([
      container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      container.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
      container.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
      activity.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      activity.topAnchor.constraint(equalTo: container.topAnchor, constant: 24),
    ])
    if let label = label {
      NSLayoutConstraint.activate([
        label.topAnchor.constraint(equalTo: activity.bottomAnchor, constant: 16),
        label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
        label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
        label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -24),
      ])
    } else {
      NSLayoutConstraint.activate([
        activity.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -24)
      ])
    }

    if dismissOnTouchOutside {
      let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
      tap.delegate = self
      view.addGestureRecognizer(tap)
    }
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    guard let contentView = contentView else { return false }
    return !contentView.bounds.contains(touch.location(in: contentView))
  }

  @objc private func dismissSelf() {
    guard !isBeingPresented, !isBeingDismissed else { return }
    dismiss(animated: true, completion: nil)
  }
}
