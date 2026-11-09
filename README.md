# native_alert_dialog

Android / iOS 原生弹窗插件，提供 `showDialog`、`showToast`、`openUrl`、`showLoading`、`hideLoading` 和 `getPlatformVersion`。

## 行为约定

- `showDialog` 返回 `true` 表示确定，`false` 表示取消、返回或允许的背景关闭。`cancelText` 为 `null` 时隐藏取消按钮；`desTextAlign` 支持文本对齐；`isDismissOnTouchOutside` 默认关闭。
- 同一 Dart 方法通道同时只允许一个 `showDialog`。前一次未完成时再次调用会抛出 `PlatformException(code: 'busy')`，不会替换原弹窗的富文本回调；完成或异常后释放回调。原生展示冲突也可能返回平台错误，请处理 `PlatformException`。
- 富文本通过 `MessageSpan` 和 `onDesSpanTap` 传递原始 `clickKey`，允许引号、换行、中文和 URL 特殊字符。
- `showLoading` 的 `message` 可空，`dismissOnTouchOutside` 默认关闭；`hideLoading` 可重复调用。
- `openUrl` 只接受带主机名的绝对 HTTP / HTTPS 地址，页面导航同样限制为 HTTP(S)。为兼容已有业务仍接受 HTTP，但明文内容不可信；调用方应优先 HTTPS，并自行校验业务允许的域名。插件不是网页内容的可信认证或隔离机制。无标题页面保留关闭入口；HTTP 能否加载仍受操作系统默认网络策略限制。
- 无可用前台 Activity / 窗口或控制器展示冲突时返回明确的平台错误，不静默悬挂。Android 仍追踪应用内原生 Activity，以支持原生页面覆盖 Flutter 后展示。

## 弹窗主题色

`showDialog` 的可选 `themeColor` 同时设置确认按钮背景和可点击富文本文字颜色，保留原有无下划线外观。不传时，iOS 使用 `UIColor.systemBlue`，Android 使用 `#007AFF`；普通正文、取消按钮、Loading 等样式不变。

原生弹窗不能自动读取 Flutter 的 `Theme`。在有 `MaterialApp` 祖先的 `BuildContext` 中显式传入当前主题色：

```dart
await NativeAlertDialog().showDialog(
  title: '提示',
  desText: '是否继续？',
  cancelText: '取消',
  themeColor: Theme.of(context).colorScheme.primary,
);
```

也可传入固定 `Color`。确认按钮文字仍为白色，建议使用不透明、与白色有足够对比度的主题色。示例的普通和特殊 key 弹窗展示 Flutter 主题色；“仅确定按钮”入口不传颜色，可验收默认系统蓝。

## 示例验收

`example` 提供中文入口：确定/取消、背景取消、仅确定、特殊 key、重复调用、Loading 显隐、无标题网页关闭和 Toast。两个平台均使用独立示例标识 `io.github.jixiaoyong.nativealertdialog.lifecyclecheck`，不覆盖业务 App。

工具链版本以项目中的 Flutter、AGP、Kotlin 和 Gradle 配置及对应官方兼容要求为准，不将本次环境使用的版本视为插件的硬性下限。Flutter 自动将示例 iOS 最低版本更新至 15，并迁移 Scene 生命周期；插件自身的最低系统声明不因此提高。

首次检出后，先在根目录及 `example` 目录分别运行 `flutter pub get`。运行根目录 `flutter test`、`flutter analyze`；示例目录运行 `flutter test`。

Android 原生测试从 `example/android` 使用项目 wrapper 执行 `:native_alert_dialog:testDebugUnitTest`。当前仓库未跟踪 `gradlew` 和 wrapper JAR，首次检出不能假定它们已存在：先从 `example` 运行 `flutter build apk --debug`，由 Flutter 准备 wrapper 并构建示例，再执行原生测试。

iOS 从示例 Xcode workspace 的 `Runner` scheme 运行测试，真机需要现有有效签名。该 scheme 运行 `example/ios/RunnerTests`；`ios/Tests/NativeAlertDialogTests.swift` 属于 Podspec 的 `Tests` test subspec，当前示例 Podfile 未启用它，不计入 Runner scheme 的测试覆盖。
