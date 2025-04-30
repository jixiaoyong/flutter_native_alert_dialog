import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'native_alert_dialog_platform_interface.dart';

/// 通过方法通道实现与原生平台的通信
class MethodChannelNativeAlertDialog extends NativeAlertDialogPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('io.github.jixiaoyong.native_alert_dialog');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  /// 展示原生弹窗（支持纯文本或富文本内容）
  ///
  /// [title] 对话框标题
  /// [desText] 纯文本描述内容
  /// [desSpans] 富文本描述内容
  /// [cancelText] 取消按钮文本
  /// [confirmText] 确认按钮文本
  /// [onDesSpanTap] 富文本点击回调
  ///
  /// 返回用户选择结果，true 表示确认，false 表示取消
  @override
  Future<bool?> showDialog({
    required String title,
    String? desText,
    List<Map<String, dynamic>>? desSpans,
    String cancelText = '取消',
    String confirmText = '确定',
    void Function(String key)? onDesSpanTap,
  }) async {
    if (onDesSpanTap != null) {
      methodChannel.setMethodCallHandler((call) async {
        if (call.method == 'onDesSpanTap') {
          final key = call.arguments['key'] as String?;
          if (key != null) onDesSpanTap(key);
        }
      });
    }
    final args = <String, dynamic>{
      'title': title,
      if (desText != null) 'desText': desText,
      if (desSpans != null) 'desSpans': desSpans,
      'cancelText': cancelText,
      'confirmText': confirmText,
    };
    final result = await methodChannel.invokeMethod('showDialog', args);
    return result;
  }

  @override
  Future<void> showToast({required String message, int duration = 2000}) async {
    await methodChannel.invokeMethod<void>('showToast', {
      'message': message,
      'duration': duration,
    });
  }

  @override
  Future<void> openUrl({required String url, String? title}) async {
    await methodChannel.invokeMethod<void>('openUrl', {
      'url': url,
      'title': title,
    });
  }
}
