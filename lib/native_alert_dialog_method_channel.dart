import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'native_alert_dialog_platform_interface.dart';

/// 通过方法通道实现与原生平台的通信
class MethodChannelNativeAlertDialog extends NativeAlertDialogPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(
    'io.github.jixiaoyong.native_alert_dialog',
  );

  // 所有实例使用同一通道，因此展示状态也必须共享。
  static bool _dialogActive = false;

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
  /// [cancelText] 取消按钮文本,为空标识不显示取消按钮
  /// [confirmText] 确认按钮文本
  /// [onDesSpanTap] 富文本点击回调
  /// [isDismissOnTouchOutside] 是否点击背景关闭弹窗
  ///
  /// 返回用户选择结果，true 表示确认，false 表示取消
  @override
  Future<bool?> showDialog({
    required String title,
    String? desText,
    List<Map<String, dynamic>>? desSpans,
    String? cancelText,
    String confirmText = '确定',
    TextAlign? desTextAlign,
    void Function(String key)? onDesSpanTap,
    bool isDismissOnTouchOutside = false,
    Color? themeColor,
  }) async {
    if (_dialogActive) {
      throw PlatformException(
        code: 'busy',
        message: 'A dialog is already being shown on this channel.',
      );
    }
    if (desSpans != null) {
      for (final span in desSpans) {
        if (span['text'] is! String ||
            (span['clickable'] != null && span['clickable'] is! bool) ||
            (span['clickKey'] != null && span['clickKey'] is! String)) {
          throw ArgumentError.value(
            desSpans,
            'desSpans',
            'Invalid span fields',
          );
        }
      }
    }
    final args = <String, dynamic>{
      'title': title,
      if (desText != null && (desText.isNotEmpty || desSpans == null))
        'desText': desText,
      if ((desText == null || desText.isEmpty) && desSpans != null)
        'desSpans': desSpans,
      'cancelText': cancelText,
      'confirmText': confirmText,
      if (desTextAlign != null) 'desTextAlign': desTextAlign.name,
      'isDismissOnTouchOutside': isDismissOnTouchOutside,
      // 使用 value 保持对 Flutter 3.0 的兼容，通道传递 32 位 ARGB。
      // ignore: deprecated_member_use
      if (themeColor != null) 'themeColor': themeColor.value,
    };
    _dialogActive = true;
    try {
      methodChannel.setMethodCallHandler((call) async {
        if (call.method == 'onDesSpanTap') {
          final arguments = call.arguments;
          final key = arguments is Map ? arguments['key'] : null;
          if (key is String) onDesSpanTap?.call(key);
        }
      });
      return await methodChannel.invokeMethod<bool>('showDialog', args);
    } finally {
      methodChannel.setMethodCallHandler(null);
      _dialogActive = false;
    }
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

  @override
  Future<void> showLoading({
    String? message,
    bool dismissOnTouchOutside = false,
  }) async {
    await methodChannel.invokeMethod<void>('showLoading', {
      'message': message,
      'dismissOnTouchOutside': dismissOnTouchOutside,
    });
  }

  @override
  Future<void> hideLoading() async {
    await methodChannel.invokeMethod<void>('hideLoading');
  }
}
