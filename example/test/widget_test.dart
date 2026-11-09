import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_alert_dialog_example/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('io.github.jixiaoyong.native_alert_dialog');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getPlatformVersion') return 'Test platform';
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('协议回调立即提示且保留特殊 key 校验结果', (tester) async {
    final dialogResult = Completer<bool>();
    final calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'getPlatformVersion') return 'Test platform';
      if (call.method == 'showDialog') return dialogResult.future;
      return null;
    });
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    // 直接触发入口，测试回调反馈，不依赖按钮水波纹的 GPU 着色器资源。
    tester
        .widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, '特殊 key 富文本回调'),
        )
        .onPressed!();
    await tester.pump();
    final args =
        calls.firstWhere((call) => call.method == 'showDialog').arguments
            as Map;
    final buttonContext = tester.element(
      find.widgetWithText(ElevatedButton, '特殊 key 富文本回调'),
    );
    expect(
      args['themeColor'],
      // ignore: deprecated_member_use
      Theme.of(buttonContext).colorScheme.primary.value,
    );
    final key = (args['desSpans'] as List).first['clickKey'];
    final delivered = Completer<void>();
    messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(
        MethodCall('onDesSpanTap', {'key': key}),
      ),
      (_) => delivered.complete(),
    );
    await delivered.future;
    await tester.pumpAndSettle();
    expect(calls.last.method, 'showToast');
    expect(calls.last.arguments['message'], '协议点击成功：特殊 key 完整一致');
    expect(find.textContaining('特殊 key 完整一致：true'), findsOneWidget);
    dialogResult.complete(true);
    await tester.pumpAndSettle();
  });

  testWidgets('显示中文验收入口和平台信息', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('原生弹窗独立验收'), findsOneWidget);
    expect(find.text('运行平台：Test platform'), findsOneWidget);
    expect(find.text('Dialog 确定 / 取消'), findsOneWidget);
    expect(find.text('特殊 key 富文本回调'), findsOneWidget);
  });
}
