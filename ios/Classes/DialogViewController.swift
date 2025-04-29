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
    private let cancelText: String
    private let confirmText: String
    private let completion: (Bool) -> Void
    private let onDesSpanTap: ((String) -> Void)?
    
    /// desText/desSpans只能二选一
    init(title: String, desText: String? = nil, desSpans: [MessageSpan]? = nil, cancelText: String, confirmText: String, onDesSpanTap: ((String) -> Void)? = nil, completion: @escaping (Bool) -> Void) {
        self.titleText = title
        self.desText = desText
        self.desSpans = desSpans
        self.cancelText = cancelText
        self.confirmText = confirmText
        self.onDesSpanTap = onDesSpanTap
        self.completion = completion
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
        let blocker = UIButton(type: .custom)
        blocker.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        blocker.translatesAutoresizingMaskIntoConstraints = false
        blocker.addTarget(self, action: #selector(blockerTapped), for: .touchUpInside)
        blocker.isUserInteractionEnabled = true
        view.addSubview(blocker)
        NSLayoutConstraint.activate([
            blocker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blocker.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blocker.topAnchor.constraint(equalTo: view.topAnchor),
            blocker.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func blockerTapped() {}

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
        view.addSubview(dialog)
        
        // dialog constraints
        NSLayoutConstraint.activate([
            dialog.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            dialog.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: dialogMargin),
            dialog.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -dialogMargin)
        ])
        

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = stackTopBottomPadding
        stack.translatesAutoresizingMaskIntoConstraints = false
        dialog.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: dialog.topAnchor, constant: stackTopBottomPadding),
            stack.leadingAnchor.constraint(equalTo: dialog.leadingAnchor, constant: stackSidePadding),
            stack.trailingAnchor.constraint(equalTo: dialog.trailingAnchor, constant: -stackSidePadding)
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
            desLabel.textAlignment = .center
            desLabel.numberOfLines = 0
            desLabel.font = UIFont.systemFont(ofSize: 15 * scale)
            desLabel.textColor = UIColor(red: 0.67, green: 0.67, blue: 0.67, alpha: 1)
            stack.addArrangedSubview(desLabel)
        } else if let spans = desSpans, !spans.isEmpty {
            let textView = UITextView()
            textView.backgroundColor = .clear
            textView.isEditable = false
            textView.isScrollEnabled = false
            textView.textAlignment = .center
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
        
        // 取消按钮
        let cancelBtn = UIButton(type: .system)
        cancelBtn.setTitle(cancelText, for: .normal)
        cancelBtn.setTitleColor(UIColor(white: 0.67, alpha: 1), for: .normal)
        cancelBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16 * scale, weight: .medium)
        cancelBtn.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1)
        cancelBtn.layer.cornerRadius = buttonCornerRadius
        cancelBtn.addTarget(self, action: #selector(onCancel), for: .touchUpInside)
        buttonRow.addArrangedSubview(cancelBtn)
        
        // 确认按钮
        let confirmBtn = UIButton(type: .system)
        confirmBtn.setTitle(confirmText, for: .normal)
        confirmBtn.setTitleColor(.white, for: .normal)
        confirmBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16 * scale, weight: .medium)
        confirmBtn.backgroundColor = UIColor(red: 14/255.0, green: 182/255.0, blue: 152/255.0, alpha: 1) 
        confirmBtn.layer.cornerRadius = buttonCornerRadius
        confirmBtn.addTarget(self, action: #selector(onConfirm), for: .touchUpInside)
        buttonRow.addArrangedSubview(confirmBtn)
        
        // 按钮高度
        cancelBtn.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        confirmBtn.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true

        stack.addArrangedSubview(buttonRow)

        stack.bottomAnchor.constraint(equalTo: dialog.bottomAnchor, constant: -stackTopBottomPadding).isActive = true
    }
    
    // 构建富文本描述
    private func buildAttributedDes(scale: CGFloat) -> NSAttributedString {
        let attributed = NSMutableAttributedString()
        guard let spans = desSpans else { return attributed }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        for span in spans {
            // 默认颜色
            let defaultNormalColor = UIColor(red: 0x99/255.0, green: 0x99/255.0, blue: 0x99/255.0, alpha: 1) // #999999
            let defaultClickableColor = UIColor(red: 0x1A/255.0, green: 0x1A/255.0, blue: 0x1A/255.0, alpha: 1) // #1A1A1A
            let color: UIColor = {
                if let customColor = span.color {
                    return customColor
                } else if span.clickable {
                    return defaultClickableColor
                } else {
                    return defaultNormalColor
                }
            }()
            var attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 15 * scale),
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle
            ]
            if span.clickable, let clickKey = span.clickKey {
                attrs[.link] = "nativealert://span/" + clickKey
            }
            let sub = NSAttributedString(string: span.text, attributes: attrs)
            attributed.append(sub)
        }
        return attributed
    }

    // 拦截UITextView的链接点击，回调到Flutter
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if URL.scheme == "nativealert", URL.host == "span" {
            let clickKey = URL.path.replacingOccurrences(of: "/", with: "")
            onDesSpanTap?(clickKey)
            return false
        }
        return true
    }
    
    @objc private func onCancel() {
        dismiss(animated: true) {
            self.completion(false)
        }
    }
    
    @objc private func onConfirm() {
        dismiss(animated: true) {
            self.completion(true)
        }
    }
}
