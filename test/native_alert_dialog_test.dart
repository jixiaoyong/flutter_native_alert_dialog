import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:native_alert_dialog/native_alert_dialog.dart';
import 'package:native_alert_dialog/native_alert_dialog_method_channel.dart';
import 'package:native_alert_dialog/native_alert_dialog_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNativeAlertDialogPlatform
    with MockPlatformInterfaceMixin
    implements NativeAlertDialogPlatform {
  String? method;
  Map<String, Object?>? arguments;
  void Function(String)? onTap;

  @override
  Future<String?> getPlatformVersion() async => '42';

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
    method = 'showDialog';
    onTap = onDesSpanTap;
    arguments = {
      'title': title,
      'desText': desText,
      'desSpans': desSpans,
      'cancelText': cancelText,
      'confirmText': confirmText,
      'desTextAlign': desTextAlign,
      'isDismissOnTouchOutside': isDismissOnTouchOutside,
      'themeColor': themeColor,
    };
    return true;
  }

  @override
  Future<void> showToast({required String message, int duration = 2000}) async {
    method = 'showToast';
    arguments = {'message': message, 'duration': duration};
  }

  @override
  Future<void> openUrl({required String url, String? title}) async {
    method = 'openUrl';
    arguments = {'url': url, 'title': title};
  }

  @override
  Future<void> showLoading({
    String? message,
    bool dismissOnTouchOutside = false,
  }) async {
    method = 'showLoading';
    arguments = {
      'message': message,
      'dismissOnTouchOutside': dismissOnTouchOutside,
    };
  }

  @override
  Future<void> hideLoading() async {
    method = 'hideLoading';
  }
}

void main() {
  final initialPlatform = NativeAlertDialogPlatform.instance;
  final plugin = NativeAlertDialog();
  late MockNativeAlertDialogPlatform fake;

  setUp(() {
    fake = MockNativeAlertDialogPlatform();
    NativeAlertDialogPlatform.instance = fake;
  });
  tearDown(() => NativeAlertDialogPlatform.instance = initialPlatform);

  test('$MethodChannelNativeAlertDialog is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNativeAlertDialog>());
  });

  test('getPlatformVersion', () async {
    expect(await plugin.getPlatformVersion(), '42');
  });

  test('dialog forwards rich spans, options and callback', () async {
    String? tapped;
    final span = MessageSpan(text: '链接', clickable: true, clickKey: 'key');
    expect(
      await plugin.showDialog(
        title: '标题',
        desText: '说明',
        desSpans: [span],
        cancelText: '取消',
        confirmText: '继续',
        desTextAlign: TextAlign.right,
        isDismissOnTouchOutside: true,
        themeColor: const Color(0xFF6750A4),
        onDesSpanTap: (key) => tapped = key,
      ),
      true,
    );
    expect(fake.arguments, {
      'title': '标题',
      'desText': '说明',
      'desSpans': [span.toJson()],
      'cancelText': '取消',
      'confirmText': '继续',
      'desTextAlign': TextAlign.right,
      'isDismissOnTouchOutside': true,
      'themeColor': const Color(0xFF6750A4),
    });
    fake.onTap!('key');
    expect(tapped, 'key');
    await plugin.showDialog(title: 'defaults');
    expect(fake.arguments!['cancelText'], null);
    expect(fake.arguments!['confirmText'], '确定');
    expect(fake.arguments!['isDismissOnTouchOutside'], false);
    expect(fake.arguments!['themeColor'], null);
  });

  test('loading methods forward optional parameters and defaults', () async {
    await plugin.showLoading(message: '加载中', dismissOnTouchOutside: true);
    expect(fake.method, 'showLoading');
    expect(fake.arguments, {'message': '加载中', 'dismissOnTouchOutside': true});
    await plugin.showLoading();
    expect(fake.arguments, {'message': null, 'dismissOnTouchOutside': false});
    await plugin.hideLoading();
    expect(fake.method, 'hideLoading');
  });

  test('toast and http/https URLs forward to platform', () async {
    await plugin.showToast(message: '提示');
    expect(fake.method, 'showToast');
    expect(fake.arguments, {'message': '提示', 'duration': 2000});
    await plugin.showToast(message: '提示', duration: 123);
    expect(fake.arguments!['duration'], 123);
    for (final url in ['http://example.com', 'https://example.com']) {
      await plugin.openUrl(url: url, title: '网页');
      expect(fake.method, 'openUrl');
      expect(fake.arguments, {'url': url, 'title': '网页'});
    }
  });

  test('MessageSpan serialization preserves special keys and defaults', () {
    const key = '"\'\\\n中文';
    final span = MessageSpan.fromJson({
      'text': '链接',
      'clickable': true,
      'clickKey': key,
    });
    expect(span.toJson(), {'text': '链接', 'clickable': true, 'clickKey': key});
    expect(MessageSpan.fromJson({'text': '文本'}).toJson(), {
      'text': '文本',
      'clickable': false,
    });
  });
}
