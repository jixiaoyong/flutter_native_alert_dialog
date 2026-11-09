import UIKit

public struct MessageSpan {
  let text: String
  let clickable: Bool
  let color: UIColor?
  let clickKey: String?
}

public class DialogViewController: UIViewController, UITextViewDelegate {
  private let titleText: String
  private let desText: String?
  private let desSpans: [MessageSpan]?
  private let cancelText: String?
  private let confirmText: String
  private let desTextAlign: String?
  private let themeColor: UIColor
  private let isDismissOnTouchOutside: Bool
  private let completion: (Bool) -> Void
  private let onDesSpanTap: ((String) -> Void)?
  private var didComplete = false

  private func finish(_ confirmed: Bool) {
    guard !didComplete else { return }
    didComplete = true
    view.isUserInteractionEnabled = false
    dismiss(animated: true) { self.completion(confirmed) }
  }

  public override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    if presentingViewController == nil && !didComplete {
      didComplete = true
      completion(false)
    }
  }

  /// desText/desSpans只能二选一
  init(
    title: String, desText: String? = nil, desSpans: [MessageSpan]? = nil,
    cancelText: String? = nil, confirmText: String, desTextAlign: String? = nil,
    themeColor: UIColor? = nil,
    onDesSpanTap: ((String) -> Void)? = nil, completion: @escaping (Bool) -> Void,
    isDismissOnTouchOutside: Bool? = nil
  ) {
    self.titleText = title
    self.desText = desText
    self.desSpans = desSpans
    self.cancelText = cancelText
    self.confirmText = confirmText
    self.desTextAlign = desTextAlign
    self.themeColor = themeColor ?? .systemBlue
    self.onDesSpanTap = onDesSpanTap
    self.completion = completion
    self.isDismissOnTouchOutside = isDismissOnTouchOutside ?? false
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .overFullScreen
    modalTransitionStyle = .crossDissolve
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    setupBackground()
    setupDialogUI()
  }

  private func setupBackground() {
    let blocker = UIView()
    blocker.backgroundColor = UIColor.black.withAlphaComponent(0.3)
    blocker.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(blocker)
    NSLayoutConstraint.activate([
      blocker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      blocker.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      blocker.topAnchor.constraint(equalTo: view.topAnchor),
      blocker.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    // 添加点击手势识别器
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(blockerTapped))
    blocker.addGestureRecognizer(tapGesture)
    blocker.isUserInteractionEnabled = true
  }

  @objc private func blockerTapped() {
    if isDismissOnTouchOutside {
      finish(false)
    }
  }

  private func convertTextAlignment(_ align: String?) -> NSTextAlignment {
    switch align {
    case "left":
      return .left
    case "right":
      return .right
    case "center":
      return .center
    case "justify":
      return .justified
    case "start":
      return .natural
    case "end":
      return .natural
    default:
      return .center
    }
  }

  private func setupDialogUI() {
    let screenWidth = UIScreen.main.bounds.width
    let scale = screenWidth / 375.0
    let dialogCornerRadius = 16 * scale
    let dialogMargin = 36 * scale
    let stackTopBottomPadding = 24 * scale
    let stackSidePadding = 20 * scale
    let buttonHeight = 48 * scale
    let buttonCornerRadius = 16 * scale
    let buttonSpacing = 13 * scale

    let dialog = UIView()
    dialog.translatesAutoresizingMaskIntoConstraints = false
    dialog.backgroundColor = .white
    dialog.layer.cornerRadius = dialogCornerRadius
    dialog.clipsToBounds = true
    dialog.isUserInteractionEnabled = true

    // 添加点击手势识别器到 dialog
    let dialogTapGesture = UITapGestureRecognizer(target: self, action: #selector(dialogTapped))
    dialogTapGesture.cancelsTouchesInView = false
    dialog.addGestureRecognizer(dialogTapGesture)

    view.addSubview(dialog)

    // dialog constraints
    NSLayoutConstraint.activate([
      dialog.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      dialog.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: dialogMargin),
      dialog.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -dialogMargin),
    ])

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = stackTopBottomPadding
    stack.translatesAutoresizingMaskIntoConstraints = false
    dialog.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: dialog.topAnchor, constant: stackTopBottomPadding),
      stack.leadingAnchor.constraint(equalTo: dialog.leadingAnchor, constant: stackSidePadding),
      stack.trailingAnchor.constraint(equalTo: dialog.trailingAnchor, constant: -stackSidePadding),
    ])

    // title
    let titleLabel = UILabel()
    titleLabel.text = titleText
    titleLabel.textAlignment = .center
    titleLabel.font = UIFont.systemFont(ofSize: 17 * scale, weight: .medium)
    titleLabel.textColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
    titleLabel.numberOfLines = 0
    stack.addArrangedSubview(titleLabel)

    // des内容
    if let des = desText {
      let desLabel = UILabel()
      desLabel.text = des
      desLabel.textAlignment = convertTextAlignment(desTextAlign)
      desLabel.numberOfLines = 0
      desLabel.font = UIFont.systemFont(ofSize: 15 * scale)
      desLabel.textColor = UIColor(red: 0.67, green: 0.67, blue: 0.67, alpha: 1)
      stack.addArrangedSubview(desLabel)
    } else if let spans = desSpans, !spans.isEmpty {
      let textView = UITextView()
      textView.backgroundColor = .clear
      textView.isEditable = false
      textView.isScrollEnabled = false
      textView.textAlignment = convertTextAlignment(desTextAlign)
      textView.attributedText = buildAttributedDes(scale: scale)
      textView.delegate = self
      textView.dataDetectorTypes = []
      textView.linkTextAttributes = [:]
      stack.addArrangedSubview(textView)
    }

    // 按钮区
    let buttonRow = UIStackView()
    buttonRow.axis = .horizontal
    buttonRow.spacing = buttonSpacing
    buttonRow.distribution = .fillEqually
    buttonRow.alignment = .center

    // 取消按钮
    if cancelText != nil {
      let cancelBtn = UIButton(type: .system)
      cancelBtn.setTitle(cancelText, for: .normal)
      cancelBtn.setTitleColor(UIColor(white: 0.67, alpha: 1), for: .normal)
      cancelBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16 * scale, weight: .medium)
      cancelBtn.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1)
      cancelBtn.layer.cornerRadius = buttonCornerRadius
      cancelBtn.addTarget(self, action: #selector(onCancel), for: .touchUpInside)
      buttonRow.addArrangedSubview(cancelBtn)
      cancelBtn.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
    }

    // 确认按钮
    let confirmBtn = UIButton(type: .system)
    confirmBtn.setTitle(confirmText, for: .normal)
    confirmBtn.setTitleColor(.white, for: .normal)
    confirmBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16 * scale, weight: .medium)
    confirmBtn.backgroundColor = themeColor
    confirmBtn.layer.cornerRadius = buttonCornerRadius
    confirmBtn.addTarget(self, action: #selector(onConfirm), for: .touchUpInside)
    buttonRow.addArrangedSubview(confirmBtn)
    confirmBtn.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true

    // 如果没有取消按钮，设置确认按钮的宽度约束
    if cancelText == nil {
      let containerView = UIView()
      containerView.translatesAutoresizingMaskIntoConstraints = false
      buttonRow.addArrangedSubview(containerView)

      confirmBtn.removeFromSuperview()
      containerView.addSubview(confirmBtn)

      NSLayoutConstraint.activate([
        confirmBtn.widthAnchor.constraint(equalTo: buttonRow.widthAnchor, multiplier: 0.6),
        confirmBtn.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
        confirmBtn.topAnchor.constraint(equalTo: containerView.topAnchor),
        confirmBtn.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
      ])
    }

    stack.addArrangedSubview(buttonRow)

    stack.bottomAnchor.constraint(equalTo: dialog.bottomAnchor, constant: -stackTopBottomPadding)
      .isActive = true
  }

  // 构建富文本描述
  private func buildAttributedDes(scale: CGFloat) -> NSAttributedString {
    let attributed = NSMutableAttributedString()
    guard let spans = desSpans else { return attributed }
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = convertTextAlignment(desTextAlign)
    for (index, span) in spans.enumerated() {
      // 默认颜色
      let defaultNormalColor = UIColor(
        red: 0x99 / 255.0, green: 0x99 / 255.0, blue: 0x99 / 255.0, alpha: 1)  // #999999
      let color: UIColor = {
        if span.clickable {
          return themeColor
        } else if let customColor = span.color {
          return customColor
        } else {
          return defaultNormalColor
        }
      }()
      var attrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 15 * scale),
        .foregroundColor: color,
        .paragraphStyle: paragraphStyle,
      ]
      // 只把索引放进 URL，原始 key 不拼接到 URL 或 JavaScript。
      if span.clickable, span.clickKey != nil {
        attrs[.link] = "nativealert://span/\(index)"
      }
      let sub = NSAttributedString(string: span.text, attributes: attrs)
      attributed.append(sub)
    }
    return attributed
  }

  // 拦截UITextView的链接点击，回调到Flutter
  public func textView(
    _ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange,
    interaction: UITextItemInteraction
  ) -> Bool {
    if URL.scheme == "nativealert", URL.host == "span" {
      if !didComplete, let index = Int(URL.lastPathComponent), let spans = desSpans,
        spans.indices.contains(index), spans[index].clickable, let key = spans[index].clickKey {
        onDesSpanTap?(key)
      }
    }
    return false
  }

  @objc private func onCancel() {
    finish(false)
  }

  @objc private func onConfirm() {
    finish(true)
  }

  @objc private func dialogTapped() {
    // 点击 dialog 时不关闭弹窗，仅阻止事件穿透
  }
}
