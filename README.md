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

Android 原生测试从 `example/android` 使用项目 wrapper 执行 `:native_alert_dialog:testDebugUnitTest`。当前仓库未跟踪 `gradlew` 和 wrapper JAR，首次检出不能假定它们已存在：先从 `example` 运行 `flutter build apk --debug`，由 Flutter 准备 wrapper 并构建示例，再执行原生测试。若依赖下载受阻，可先使用下方 Flutter 镜像步骤完成准备；直接 Gradle 示例要求 wrapper 已生成。

iOS 从示例 Xcode workspace 的 `Runner` scheme 运行测试，真机需要现有有效签名。该 scheme 运行 `example/ios/RunnerTests`；`ios/Tests/NativeAlertDialogTests.swift` 属于 Podspec 的 `Tests` test subspec，当前示例 Podfile 未启用它，不计入 Runner scheme 的测试覆盖。

## Android 依赖下载出现 TLS 错误

本次排查中，Gradle 访问 Google Maven 下载 Android 依赖时出现 TLS 下载错误；将 Google Maven 地址临时替换为阿里云 Google 镜像后，下载得以继续。实际使用的 `/tmp/native-alert-dialog-repositories.init.gradle` 负责替换仓库地址，`~/.gradle/init.d/native-alert-dialog-temporary.gradle` 通过 `apply from` 加载它，使 Flutter 启动的 Gradle 也能应用镜像。

这是网络或 Gradle 仓库访问中的常见环境问题，不是该插件的通病。镜像可用说明更换访问路径解决了本次阻塞，但仅凭 TLS 提示不能断言是证书问题；代理、网络链路、TLS 握手或证书信任等均需结合具体错误排查。不要通过关闭 TLS 校验或改用 HTTP 解决。

先区分下载来源，避免改错配置：

- Kotlin Gradle 插件及相关制品通常来自 Maven Central（`mavenCentral()`）；本次脚本不替换 Central。若 Kotlin 下载失败，应检查报错中的实际仓库 URL，而不是只修改 Google 镜像。
- Android Gradle Plugin（AGP）等 Android 制品来自 Google Maven（`google()`）；下方仅替换这一路仓库。
- Android SDK 平台、Build Tools 等由 Android CLI 管理，可用 `android sdk list` 查看、`android sdk install --help` 确认安装参数；这不是 Maven 依赖下载，Gradle 仓库镜像不会改变 SDK 下载源。
- Maven 制品由项目的 Gradle wrapper 解析与下载，不由 Android CLI 安装。
- Flutter / Dart 的 `flutter pub get` 使用独立的 pub 依赖源；Gradle 镜像不影响 pub，pub 镜像也不解决 AGP / Kotlin 的 Maven 下载问题。

### 临时、仅限当前示例的仓库镜像

以下命令从插件仓库根目录执行。脚本保存在临时目录，并额外检查目标 Android 项目路径；不修改项目仓库配置，也不永久修改全局 Gradle 配置。镜像是可选的网络替代路径，可用性和制品同步情况需以实际下载为准。

```bash
export NATIVE_ALERT_ANDROID_DIR="$(pwd -P)/example/android"
export NATIVE_ALERT_INIT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/native-alert-init.XXXXXX")"
cat > "$NATIVE_ALERT_INIT_DIR/repositories.init.gradle" <<'GRADLE'
def routeRepository = { repository ->
    if (repository instanceof org.gradle.api.artifacts.repositories.MavenArtifactRepository) {
        def url = repository.url.toString()
        if (url.startsWith('https://dl.google.com') || url.startsWith('https://maven.google.com')) {
            repository.setUrl('https://maven.aliyun.com/repository/google')
        }
    }
}
gradle.beforeSettings { settings ->
    def target = System.getenv('NATIVE_ALERT_ANDROID_DIR')
    if (!target || settings.settingsDir.canonicalFile != new File(target).canonicalFile) {
        return
    }
    settings.pluginManagement.repositories.whenObjectAdded(routeRepository)
    settings.dependencyResolutionManagement.repositories.whenObjectAdded(routeRepository)
    gradle.beforeProject { project ->
        project.buildscript.repositories.all(routeRepository)
        project.repositories.all(routeRepository)
    }
    gradle.projectsEvaluated {
        gradle.rootProject.allprojects { project ->
            project.buildscript.repositories.all(routeRepository)
            project.repositories.all(routeRepository)
        }
    }
}
GRADLE

# 直接运行 Gradle 时，显式传入临时 init 脚本。
(cd "$NATIVE_ALERT_ANDROID_DIR" && ./gradlew \
  --init-script "$NATIVE_ALERT_INIT_DIR/repositories.init.gradle" \
  :native_alert_dialog:testDebugUnitTest)
```

`--init-script` 只作用于这次 Gradle 调用，不会被之后的 `flutter build` / `flutter run` 自动继承；Flutter 命令也不能直接接收这个 Gradle 参数。若需要通过 Flutter 构建，可在上面准备好脚本后，使用下面的临时 `init.d` 入口，让 Flutter 启动的 Gradle 自动加载同一脚本。导出的目标路径用于限制项目作用域；未设置它或运行其他 Android 项目时，脚本不替换仓库。

```bash
# 从插件仓库根目录，在同一终端执行；子 shell 退出时自动清理入口和临时脚本。
(
  set -e
  init_home="${GRADLE_USER_HOME:-$HOME/.gradle}/init.d"
  mkdir -p "$init_home"
  entry="$(mktemp "$init_home/native-alert-dialog-scoped.XXXXXX")"
  trap 'rm -f "$entry" "$entry.gradle"; rm -rf "$NATIVE_ALERT_INIT_DIR"' EXIT
  mv "$entry" "$entry.gradle"
  # init.d 只自动加载具有 .gradle 后缀的脚本。
  cp "$NATIVE_ALERT_INIT_DIR/repositories.init.gradle" "$entry.gradle"
  cd example
  flutter build apk --debug
  # 如需运行设备，可将上一条替换为 flutter run。
)
unset NATIVE_ALERT_ANDROID_DIR NATIVE_ALERT_INIT_DIR
```

`init.d` 是全局加载入口，因此这里只临时使用，并通过目标路径检查与退出清理避免影响其他项目；不要留下无作用域的永久镜像配置。若终端被强制关闭、进程被强杀等导致清理未执行，请删除本次生成的 `native-alert-dialog-scoped.*.gradle` 入口和临时目录。本次排查使用的 `~/.gradle/init.d/native-alert-dialog-temporary.gradle` 没有项目作用域限制，排查结束也应移除该临时入口，再清理其引用的 `/tmp/native-alert-dialog-repositories.init.gradle`，避免影响其他项目或因脚本缺失导致后续 Gradle 启动失败。仅使用直接 Gradle 命令、不运行上面的 Flutter 步骤时，可手动执行 `rm -rf "$NATIVE_ALERT_INIT_DIR"` 并取消这两个环境变量。
