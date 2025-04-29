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
    String cancelText = '取消',
    String confirmText = '确定',
    void Function(String key)? onDesSpanTap,
  }) {
    throw UnimplementedError('showDialog() has not been implemented.');
  }
  
  Future<void> showToast({
    required String message,
    int duration = 2000,
  }) {
    throw UnimplementedError('showToast() has not been implemented.');
  }
}
