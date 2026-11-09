import 'dart:ui';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'native_alert_dialog_method_channel.dart';

abstract class NativeAlertDialogPlatform extends PlatformInterface {
  /// Constructs a NativeAlertDialogPlatform.
  NativeAlertDialogPlatform() : super(token: _token);

  static final Object _token = Object();

  static NativeAlertDialogPlatform _instance = MethodChannelNativeAlertDialog();

  /// The default instance of [NativeAlertDialogPlatform] to use.
  ///
  /// Defaults to [MethodChannelNativeAlertDialog].
  static NativeAlertDialogPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NativeAlertDialogPlatform] when
  /// they register themselves.
  static set instance(NativeAlertDialogPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

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
  }) {
    throw UnimplementedError('showDialog() has not been implemented.');
  }

  Future<void> showToast({required String message, int duration = 2000}) {
    throw UnimplementedError('showToast() has not been implemented.');
  }

  Future<void> openUrl({required String url, String? title}) {
    throw UnimplementedError('openUrl() has not been implemented.');
  }

  /// 显示Loading弹窗
  /// [message] loading内容
  /// [dismissOnTouchOutside] 是否可点击其他区域关闭
  Future<void> showLoading({
    String? message,
    bool dismissOnTouchOutside = false,
  }) {
    throw UnimplementedError('showLoading() has not been implemented.');
  }

  /// 隐藏Loading弹窗
  Future<void> hideLoading() {
    throw UnimplementedError('hideLoading() has not been implemented.');
  }
}
