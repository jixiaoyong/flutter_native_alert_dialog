import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'native_alert_dialog_platform_interface.dart';

/// 富文本弹窗的span模型
class MessageSpan {
  final String text;
  final bool clickable;
  final String? clickKey;

  MessageSpan({
    required this.text,
    this.clickable = false,
    this.clickKey,
  });

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
  /// [desSpans] 富文本描述内容
  /// [cancelText] 取消按钮文本
  /// [confirmText] 确认按钮文本
  /// [onDesSpanTap] 富文本点击回调
  /// 
  /// 返回用户选择结果，true 表示确认，false 表示取消
  Future<bool?> showDialog({
    required String title,
    String? desText,
    List<MessageSpan>? desSpans,
    String cancelText = '取消',
    String confirmText = '确定',
    void Function(String key)? onDesSpanTap,
  }) async {
    return await NativeAlertDialogPlatform.instance.showDialog(
      title: title,
      desText: desText,
      desSpans: desSpans?.map((span) => span.toJson()).toList(),
      cancelText: cancelText,
      confirmText: confirmText,
      onDesSpanTap: onDesSpanTap,
    );
  }
  
  /// 显示 Toast 消息
  /// 
  /// [message] 消息内容
  /// [duration] 显示时长（毫秒）
  Future<void> showToast({
    required String message,
    int duration = 2000,
  }) async {
    return await NativeAlertDialogPlatform.instance.showToast(
      message: message,
      duration: duration,
    );
  }
}
