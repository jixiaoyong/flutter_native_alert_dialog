import 'package:flutter_test/flutter_test.dart';
import 'package:native_alert_dialog/native_alert_dialog.dart';
import 'package:native_alert_dialog/native_alert_dialog_platform_interface.dart';
import 'package:native_alert_dialog/native_alert_dialog_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNativeAlertDialogPlatform
    with MockPlatformInterfaceMixin
    implements NativeAlertDialogPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final NativeAlertDialogPlatform initialPlatform = NativeAlertDialogPlatform.instance;

  test('$MethodChannelNativeAlertDialog is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNativeAlertDialog>());
  });

  test('getPlatformVersion', () async {
    NativeAlertDialog nativeAlertDialogPlugin = NativeAlertDialog();
    MockNativeAlertDialogPlatform fakePlatform = MockNativeAlertDialogPlatform();
    NativeAlertDialogPlatform.instance = fakePlatform;

    expect(await nativeAlertDialogPlugin.getPlatformVersion(), '42');
  });
}
