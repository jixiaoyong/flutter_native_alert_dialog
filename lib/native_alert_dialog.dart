import 'dart:ui';

import 'native_alert_dialog_platform_interface.dart';

/// 富文本弹窗的span模型
class MessageSpan {
  final String text;
  final bool clickable;
  final String? clickKey;

  MessageSpan({required this.text, this.clickable = false, this.clickKey});

  Map<String, dynamic> toJson() => {
        'text': text,
        'clickable': clickable,
        if (clickKey != null) 'clickKey': clickKey,
      };

  factory MessageSpan.fromJson(Map<String, dynamic> json) => MessageSpan(
        text: json['text'] as String,
        clickable: json['clickable'] as bool? ?? false,
        clickKey: json['clickKey'] as String?,
      );
}

/// 原生弹窗插件实现类
class NativeAlertDialog {
  /// 获取平台版本信息
  Future<String?> getPlatformVersion() {
    return NativeAlertDialogPlatform.instance.getPlatformVersion();
  }

  /// 显示原生对话框（支持纯文本或富文本内容）
  ///
  /// [title] 对话框标题
  /// [desText] 纯文本描述内容
  /// [desSpans] 富文本描述内容；非空 desText 优先，否则使用 desSpans
  /// [cancelText] 取消按钮文本，为空标识不显示取消按钮
  /// [confirmText] 确认按钮文本
  /// [onDesSpanTap] 富文本点击回调
  /// [desTextAlign] 富文本描述内容对齐方式
  /// [isDismissOnTouchOutside] 是否点击背景关闭弹窗
  /// [themeColor] 确认按钮背景及可点击文字颜色，未传使用系统蓝。
  /// 可传入 Theme.of(context).colorScheme.primary 以跟随 Flutter 主题。
  ///
  /// 返回用户选择结果，true 表示确认，false 表示取消。
  /// 同一方法通道只允许一个未完成的弹窗；重复调用抛出 code 为 `busy`
  /// 的 PlatformException，不排队。弹窗完成或失败后释放富文本回调。
  Future<bool?> showDialog({
    required String title,
    String? desText,
    List<MessageSpan>? desSpans,
    String? cancelText,
    String confirmText = '确定',
    TextAlign? desTextAlign,
    void Function(String key)? onDesSpanTap,
    bool isDismissOnTouchOutside = false,
    Color? themeColor,
  }) async {
    return await NativeAlertDialogPlatform.instance.showDialog(
      title: title,
      desText: desText,
      desSpans: desSpans?.map((span) => span.toJson()).toList(),
      cancelText: cancelText,
      confirmText: confirmText,
      desTextAlign: desTextAlign,
      onDesSpanTap: onDesSpanTap,
      isDismissOnTouchOutside: isDismissOnTouchOutside,
      themeColor: themeColor,
    );
  }

  /// 显示 Toast 消息
  ///
  /// [message] 消息内容
  /// [duration] 显示时长（毫秒）
  Future<void> showToast({required String message, int duration = 2000}) async {
    return await NativeAlertDialogPlatform.instance.showToast(
      message: message,
      duration: duration,
    );
  }

  /// 打开网页
  ///
  /// [url] 要打开的网页地址
  /// [title] 网页标题，如果为空则不显示标题栏
  Future<void> openUrl({required String url, String? title}) async {
    return await NativeAlertDialogPlatform.instance.openUrl(
      url: url,
      title: title,
    );
  }

  /// 显示Loading弹窗
  /// [message] loading内容
  /// [dismissOnTouchOutside] 是否可点击其他区域关闭
  Future<void> showLoading({
    String? message,
    bool dismissOnTouchOutside = false,
  }) async {
    return await NativeAlertDialogPlatform.instance.showLoading(
      message: message,
      dismissOnTouchOutside: dismissOnTouchOutside,
    );
  }

  /// 隐藏Loading弹窗
  Future<void> hideLoading() async {
    return await NativeAlertDialogPlatform.instance.hideLoading();
  }
}
